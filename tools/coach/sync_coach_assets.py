#!/usr/bin/env python3
"""Align the trusted coach catalog dose projection with HipLab action kits.

python tools/coach/sync_coach_assets.py /path/to/sdk --sdk-ref <pinned-commit>
python tools/coach/sync_coach_assets.py --align-local --check

The SDK's shipped Pose-Hub catalog (0.2.0+) verifies the eight historical unit
corrections. HipLab's action kits remain the dose source. Existing taxonomy,
media, safety metadata and IDs are retained; this is not a media/catalog upgrade.
The profile is authored separately and is never overwritten by this tool.
"""
import argparse
import copy
import hashlib
import json
import math
import subprocess
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
SDK_CATALOG = 'packages/ugk_trainer/assets/pose_hub/app-test-pack-r1/catalog/catalog.json'
UNIT_CORRECTIONS = (
    'h-adductor-rock', 'h-knee-hug', 'h-sumo-pry', 'n-pelvis-circle',
    'n-seated-ir-drop', 'n-seated-knee-lift', 'n-seated-squeeze', 'n-squat-shift',
)


def load_kits(root=ROOT):
    index = json.loads((root / 'assets/action_kits/index.json').read_text(encoding='utf-8'))
    kit_hash = hashlib.sha256()
    kits = {}
    for path in sorted(index['kits']):
        raw = (root / path).read_bytes()
        kit_hash.update(path.encode('utf-8') + b'\0' + raw)
        kit = json.loads(raw)
        kits[kit['id']] = kit['training']
    return kits, kit_hash.hexdigest()


def kit_dose(training):
    defaults = training['defaults']
    counted = training['kind'] != 'hold'
    unit = 'reps' if counted else 'seconds'
    amount = defaults[unit]
    if not isinstance(amount, int) or amount < 1:
        raise ValueError(f'Invalid authored {unit}: {amount}')
    dose = {
        'mode': 'reps' if counted else 'time', 'sets': defaults['sets'],
        unit: amount, 'restSeconds': defaults['restSeconds'],
    }
    hold = defaults.get('holdSeconds')
    if hold is not None:
        if not counted or not isinstance(hold, int) or hold < 1:
            raise ValueError(f'Invalid authored holdSeconds: {hold}')
        dose['holdSeconds'] = hold
    minimum = 1 if counted else max(10, math.floor(amount / 10 + .5) * 5)
    dose_range = {
        'sets': [1, 3], unit: [minimum, max(10, amount * 2) if not counted else amount * 2],
        'restSeconds': [0, 60],
    }
    return dose, dose_range


def kit_rep_seconds(training):
    if training['kind'] == 'hold':
        return None
    hold = training['defaults'].get('holdSeconds')
    seconds = sum(hold if phase['id'] == 'hold' and hold is not None else phase['seconds']
                  for phase in training['cycle']['phases'])
    if seconds <= 0:
        raise ValueError(f'Invalid authored rep cycle: {seconds}')
    return round(seconds, 6)


def align_catalog(catalog, kits, kit_sha):
    result = copy.deepcopy(catalog)
    for drill in result['drills']:
        training = kits.get(drill['id'])
        if training is None:
            raise ValueError(f'Catalog action has no HipLab kit: {drill["id"]}')
        drill['defaultDose'], drill['doseRange'] = kit_dose(training)
        drill['unilateral'] = training['sided']
        rep_seconds = kit_rep_seconds(training)
        if rep_seconds is not None:
            # SDK PlanDuration uses the first available video repSeconds. This
            # scoped catalog projects HipLab training cadence onto that field;
            # the media path, checksum and demo loop duration are unchanged.
            sources = drill['assets']['video']['sources']
            if not sources:
                raise ValueError(f'Counted action has no trusted video: {drill["id"]}')
            sources[0]['repSeconds'] = rep_seconds
    result.setdefault('source', {}).setdefault('hiplabDoseSource', {}).update({
        'path': 'assets/action_kits/index.json', 'sha256': kit_sha,
        'rules': 'HipLab action-kit training defaults including holdSeconds; first video repSeconds is the complete kit cycle; no motion IDs added',
    })
    return result


def verify_upstream(sdk, ref, kits):
    commit = subprocess.check_output(
        ['git', '-C', str(sdk), 'rev-parse', f'{ref}^{{commit}}'], text=True).strip()
    raw = subprocess.check_output(['git', '-C', str(sdk), 'show', f'{commit}:{SDK_CATALOG}'])
    catalog = json.loads(raw)
    if tuple(map(int, catalog['version'].split('.'))) < (0, 2, 0):
        raise ValueError('Use the shipped Pose-Hub catalog 0.2.0+, not the legacy test fixture.')
    drills = {drill['id']: drill for drill in catalog['drills']}
    for action_id in UNIT_CORRECTIONS:
        expected, _ = kit_dose(kits[action_id])
        if drills[action_id]['defaultDose'] != expected:
            raise ValueError(f'Upstream and HipLab dose disagree: {action_id}')
    return {
        'sdkCommit': commit, 'path': SDK_CATALOG, 'version': catalog['version'],
        'sha256': hashlib.sha256(raw).hexdigest(), 'unitCorrections': list(UNIT_CORRECTIONS),
    }


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('sdk', nargs='?')
    parser.add_argument('--sdk-ref', default='HEAD', help='Read the exact committed SDK catalog, never working-tree files.')
    parser.add_argument('--align-local', action='store_true', help='Use the recorded upstream verification without fetching it again.')
    parser.add_argument('--check', action='store_true', help='Verify generated doses without writing assets.')
    args = parser.parse_args(argv)
    if not args.align_local and args.sdk is None:
        parser.error('Pass the SDK directory and pinned --sdk-ref, or --align-local.')
    path = ROOT / 'assets/coach/catalog.json'
    catalog = json.loads(path.read_text(encoding='utf-8'))
    kits, kit_sha = load_kits()
    result = align_catalog(catalog, kits, kit_sha)
    if not args.align_local:
        result['source']['hiplabDoseSource']['alignedCatalog'] = verify_upstream(
            Path(args.sdk), args.sdk_ref, kits)
    if args.check:
        if result != catalog:
            raise SystemExit('Coach catalog dose projection drifted; regenerate it.')
    else:
        path.write_text(json.dumps(result, ensure_ascii=False, indent=1) + '\n', encoding='utf-8', newline='\n')
    print(f'catalog {catalog["version"]} doses={len(catalog["drills"])} check={args.check}')


if __name__ == '__main__':
    main()
