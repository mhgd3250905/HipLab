"""Action kits validate (python3 -m unittest tools/tests/test_action_kits.py).

Same checks as `build_action_kits.py check`: schema (when jsonschema is
installed), Pose-Hub alignment, phase sums, every spoken line fits its
phase in zh and en, routine coverage and kit-derived step seconds.
"""
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'action_kits'))
import build_action_kits as AK  # noqa: E402


class ActionKitTest(unittest.TestCase):
    def test_kits_are_valid(self):
        self.assertEqual(AK.problems(), [])

    def test_override_parsing(self):
        kit = {'id': 'x', 'training': {'kind': 'rep_updown'}}
        hold = {'id': 'y', 'training': {'kind': 'hold'}}
        self.assertEqual(AK.override_of('每侧 6 次', kit), {'reps': 6})
        self.assertEqual(AK.override_of('停 3 次 × 10 秒', kit), {'reps': 3, 'holdSeconds': 10})
        self.assertEqual(AK.override_of('每侧 3 次 × 停 5 秒', kit), {'reps': 3, 'holdSeconds': 5})
        self.assertEqual(AK.override_of('每侧 开 3 次 + 关 3 次', kit), {'reps': 6})
        self.assertEqual(AK.override_of('正反各 4 圈', kit), {'reps': 4})
        self.assertEqual(AK.override_of('慢呼吸 6 次', kit), {'reps': 6})
        self.assertEqual(AK.override_of('每侧 40 秒（用毛巾）', hold), {'seconds': 40})
        self.assertEqual(AK.override_of('停 60 秒', hold), {'seconds': 60})

    def test_training_parameters_win_over_animation(self):
        # 开哥 2026-10-19: the dose follows the training parameters, the demo only loops
        legs = AK.load_kits()['n-leg-circles']
        self.assertEqual(AK.override_of('每侧 正反各 4 圈', legs), {'reps': 4})
        for i, k in AK.load_kits().items():
            for f in k['review']['flags']:
                self.assertNotIn('animation', f.lower(), i)
                self.assertNotIn('动画', f, i)


if __name__ == '__main__':
    unittest.main()
