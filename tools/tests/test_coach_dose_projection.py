"""Coach catalog contracts at the HipLab action-kit / SDK boundary."""
import copy
import hashlib
import importlib.util
import json
import subprocess
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SPEC = importlib.util.spec_from_file_location('hiplab_coach_sync', ROOT / 'tools/coach/sync_coach_assets.py')
SYNC = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(SYNC)


class CoachDoseProjectionTest(unittest.TestCase):
    def setUp(self):
        self.catalog = json.loads((ROOT / 'assets/coach/catalog.json').read_text(encoding='utf-8'))
        self.drills = {drill['id']: drill for drill in self.catalog['drills']}

    def test_all_46_doses_match_authored_action_kits(self):
        kits, kit_sha = SYNC.load_kits()
        self.assertEqual(len(self.drills), 46)
        self.assertEqual(set(self.drills), set(kits))
        self.assertEqual(kit_sha, self.catalog['source']['hiplabDoseSource']['sha256'])
        for action_id, training in kits.items():
            with self.subTest(action_id=action_id):
                dose = self.drills[action_id]['defaultDose']
                defaults = training['defaults']
                self.assertEqual(dose['sets'], defaults['sets'])
                self.assertEqual(dose['restSeconds'], defaults['restSeconds'])
                self.assertEqual(self.drills[action_id]['unilateral'], training['sided'])
                if training['kind'] == 'hold':
                    self.assertEqual(dose['mode'], 'time')
                    self.assertEqual(dose['seconds'], defaults['seconds'])
                    self.assertNotIn('reps', dose)
                else:
                    self.assertEqual(dose['mode'], 'reps')
                    self.assertEqual(dose['reps'], defaults['reps'])
                    self.assertEqual(dose.get('holdSeconds'), defaults['holdSeconds'])
                    self.assertNotIn('seconds', dose)

    def test_eight_upstream_unit_corrections_include_rep_holds(self):
        expected = {
            'h-adductor-rock': ('reps', 5, None),
            'h-knee-hug': ('reps', 6, None),
            'h-sumo-pry': ('reps', 3, 10),
            'n-pelvis-circle': ('reps', 4, None),
            'n-seated-ir-drop': ('time', 30, None),
            'n-seated-knee-lift': ('reps', 3, 5),
            'n-seated-squeeze': ('reps', 8, None),
            'n-squat-shift': ('reps', 8, None),
        }
        self.assertEqual(set(SYNC.UNIT_CORRECTIONS), set(expected))
        for action_id, (mode, amount, hold) in expected.items():
            with self.subTest(action_id=action_id):
                dose = self.drills[action_id]['defaultDose']
                self.assertEqual(dose, {
                    'mode': mode, 'sets': 1,
                    'reps' if mode == 'reps' else 'seconds': amount,
                    'restSeconds': 15,
                    **({'holdSeconds': hold} if hold is not None else {}),
                })
        source = self.catalog['source']['hiplabDoseSource']['alignedCatalog']
        self.assertEqual(source['sdkCommit'], '66dd98a549c1ff5fedecb626a7c88583090a1440')
        self.assertGreaterEqual(tuple(map(int, source['version'].split('.'))), (0, 2, 0))
        self.assertEqual(set(source['unitCorrections']), set(expected))

    def test_projection_preserves_media_taxonomy_safety_and_id_order(self):
        kits, kit_sha = SYNC.load_kits()
        before = copy.deepcopy(self.catalog)
        after = SYNC.align_catalog(before, kits, kit_sha)
        self.assertEqual(before, self.catalog)
        self.assertEqual([d['id'] for d in before['drills']], [d['id'] for d in after['drills']])
        for action_id in self.drills:
            original = self.drills[action_id]
            regenerated = next(d for d in after['drills'] if d['id'] == action_id)
            for key in set(original) - {'defaultDose', 'doseRange', 'unilateral'}:
                self.assertEqual(original[key], regenerated[key], (action_id, key))
        self.assertEqual(before['taxonomy'], after['taxonomy'])

    def test_sdk_rep_seconds_uses_complete_authored_cycle_including_hold(self):
        kits, _ = SYNC.load_kits()
        counted = 0
        for action_id, training in kits.items():
            if training['kind'] == 'hold':
                continue
            counted += 1
            hold = training['defaults']['holdSeconds']
            cycle = sum(hold if phase['id'] == 'hold' and hold is not None else phase['seconds']
                        for phase in training['cycle']['phases'])
            videos = self.drills[action_id]['assets']['video']['sources']
            sdk_rep_seconds = next(video['repSeconds'] for video in videos if video.get('repSeconds', 0) > 0)
            self.assertAlmostEqual(sdk_rep_seconds, cycle, places=6, msg=action_id)
        self.assertEqual(counted, 25)
        self.assertEqual(self.drills['h-sumo-pry']['assets']['video']['sources'][0]['repSeconds'], 12.35)
        self.assertEqual(self.drills['n-seated-knee-lift']['assets']['video']['sources'][0]['repSeconds'], 7.0)

    def test_check_is_read_only_and_does_not_overwrite_profile(self):
        paths = [ROOT / 'assets/coach/catalog.json', ROOT / 'assets/coach/hiplab.json']
        hashes = [hashlib.sha256(path.read_bytes()).hexdigest() for path in paths]
        subprocess.run([sys.executable, str(ROOT / 'tools/coach/sync_coach_assets.py'), '--align-local', '--check'],
                       cwd=ROOT, check=True, capture_output=True, text=True)
        self.assertEqual(hashes, [hashlib.sha256(path.read_bytes()).hexdigest() for path in paths])


if __name__ == '__main__':
    unittest.main()
