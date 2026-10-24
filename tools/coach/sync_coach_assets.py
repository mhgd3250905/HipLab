#!/usr/bin/env python3
"""从 ugk-3d-pose-sdk 同步 AI 定制的内置资产（目录快照只取 hiplab 范围 + profile）。

用法：python3 tools/coach/sync_coach_assets.py /path/to/ugk-3d-pose-sdk
升级 SDK（pubspec.yaml 里 ugk_coach 的 ref）时，用同一提交的 SDK 仓库重跑一次。
剂量以本 App action-kit 为准，profile 支持内置 2 分钟套路。App 侧的范围交集（只用动作大全里有视频和动作包的动作）在运行时做，
见 lib/hip/coach/coach_service.dart 与 docs/ai-coach.md。
"""
import argparse
import hashlib
import math
import json
import subprocess
import sys
from pathlib import Path

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('sdk', nargs='?', default='../ugk-coach-sdk')
parser.add_argument('--align-local', action='store_true',
                    help='Align the existing trusted snapshot with HipLab action kits; no SDK fetch.')
args = parser.parse_args()
sdk = Path(args.sdk)
root = Path(__file__).resolve().parents[2]
out = root / 'assets' / 'coach'
out.mkdir(parents=True, exist_ok=True)
if args.align_local:
    catalog = json.loads((out / 'catalog.json').read_text(encoding='utf-8'))
    profile = json.loads((out / 'hiplab.json').read_text(encoding='utf-8'))
else:
    catalog = json.loads((sdk / 'test/fixtures/pose-hub-catalog.json').read_text(encoding='utf-8'))
    profile = json.loads((sdk / 'profiles/hiplab.json').read_text(encoding='utf-8'))
    apps = set(profile['select'].get('apps', []))
    catalog['drills'] = [d for d in catalog['drills'] if apps & set(d.get('apps', []))]
    if isinstance(catalog.get('apps'), dict):
        catalog['apps'] = {k: v for k, v in catalog['apps'].items() if k in apps or k == 'pose-hub'}
    sha = subprocess.check_output(['git', '-C', str(sdk), 'rev-parse', 'HEAD'], text=True).strip()
    catalog.setdefault('source', {})['hiplabSnapshot'] = {
        'sdkCommit': sha, 'filter': {'apps': sorted(apps)}}

# HipLab's authored action kit is the dose source, for both templates and AI.
# Keep the upstream snapshot IDs, scene/equipment metadata and provenance.
index = json.loads((root / 'assets/action_kits/index.json').read_text(encoding='utf-8'))
kit_hash = hashlib.sha256()
kits = {}
for path in sorted(index['kits']):
    raw = (root / path).read_bytes()
    kit_hash.update(path.encode('utf-8') + b'\0' + raw)
    kit = json.loads(raw)
    kits[kit['id']] = kit['training']
for drill in catalog['drills']:
    training = kits.get(drill['id'])
    if training is None:
        continue
    defaults = training['defaults']
    counted = training['kind'] != 'hold'
    amount = defaults.get('reps' if counted else 'seconds') or (1 if counted else 30)
    unit = 'reps' if counted else 'seconds'
    drill['defaultDose'] = {
        'mode': 'reps' if counted else 'time', 'sets': 1,
        unit: amount, 'restSeconds': defaults.get('restSeconds') or 15}
    minimum = 1 if counted else max(10, math.floor(amount / 10 + .5) * 5)
    drill['doseRange'] = {'sets': [1, 3], unit: [minimum, max(10, amount * 2) if not counted else amount * 2],
                          'restSeconds': [0, 60]}
    drill['unilateral'] = training['sided']
profile['limits']['minutes'][0] = 2  # Real built-in chair routine M.
catalog.setdefault('source', {})['hiplabDoseSource'] = {
    'path': 'assets/action_kits/index.json', 'sha256': kit_hash.hexdigest(),
    'rules': 'HipLab DoseRules kit defaults; no motion IDs added'}
sha = catalog['source'].get('hiplabSnapshot', {}).get('sdkCommit', 'unknown')
(out / 'catalog.json').write_text(json.dumps(catalog, ensure_ascii=False, indent=1) + '\n', encoding='utf-8', newline='\n')
(out / 'hiplab.json').write_text(json.dumps(profile, ensure_ascii=False, indent=1) + '\n', encoding='utf-8', newline='\n')
print(f"catalog {catalog['version']} drills={len(catalog['drills'])} sdk={sha[:7]} -> {out}")
