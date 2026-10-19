"""Themed media pipeline: path rules, neutral light stage, bundle check."""
import importlib.util
import contextlib
import copy
import io
from pathlib import Path
import subprocess
import sys
import unittest
from unittest import mock

ROOT = Path(__file__).resolve().parents[2]
SPEC = importlib.util.spec_from_file_location(
    'build_themed_media', ROOT / 'tools/media/build_themed_media.py')
tm = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(tm)


class ThemedMediaTest(unittest.TestCase):
    def test_light_assets_sit_beside_the_dark_ones(self):
        self.assertEqual(tm.light_path('assets/drill_media/hip-h-squat.mp4'),
                         'assets/drill_media/light/hip-h-squat.mp4')
        self.assertEqual(tm.light_path('assets/hip/assessment/thomas-a.webp'),
                         'assets/hip/assessment/light/thomas-a.webp')
        self.assertEqual(tm.light_to_dark('assets/drill_media/light/hip-x.jpg'),
                         'assets/drill_media/hip-x.jpg')

    def test_light_stage_is_neutral_and_matches_the_palette(self):
        stage = tm.STAGE['light']
        self.assertEqual(len({stage[0:2], stage[2:4], stage[4:6]}), 1)
        theme = (ROOT / 'lib/hip/ui/hip_theme.dart').read_text(encoding='utf-8')
        self.assertIn(f'mediaBackdrop: Color(0xff{stage.lower()})', theme)

    def test_graph_composites_in_rgb(self):
        g = tm.composite_graph(tm.STAGE['light'], True)
        self.assertIn('format=rgb', g)
        self.assertIn(f'color=0x{tm.STAGE["light"]}', g)

    def test_bundle_matches_manifest(self):
        out = subprocess.run([sys.executable, str(ROOT / 'tools/media/build_themed_media.py'),
                              'check'], capture_output=True, text=True)
        self.assertEqual(out.returncode, 0, out.stdout + out.stderr)

    def test_changed_poster_time_requires_rebuilding_the_poster(self):
        load = tm.load_json
        content = copy.deepcopy(load(tm.CONTENT))
        content['drills'][0]['media']['poster_time_seconds'] += .1
        output = io.StringIO()
        with mock.patch.object(tm, 'load_json', side_effect=lambda path:
                               content if path == tm.CONTENT else load(path)):
            with contextlib.redirect_stdout(output), self.assertRaises(SystemExit) as error:
                tm.cmd_check(None)
        self.assertEqual(error.exception.code, 1)
        self.assertIn('poster_time_seconds changed', output.getvalue())


if __name__ == '__main__':
    unittest.main()
