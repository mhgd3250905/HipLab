"""Themed media pipeline: path rules, neutral light stage, bundle check."""
import importlib.util
import contextlib
import copy
import io
from pathlib import Path
import hashlib
import json
from urllib.parse import unquote, urlparse
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

    def test_public_posters_and_retained_stills_match_their_manifests(self):
        packages = json.loads((ROOT / '.dart_tool/package_config.json').read_text(encoding='utf-8'))['packages']
        sdk = next(package for package in packages if package['name'] == 'ugk_coach')
        uri = urlparse(sdk['rootUri'])
        sdk_root = Path(unquote(uri.path).lstrip('/') if uri.scheme == 'file' else ROOT / '.dart_tool' / sdk['rootUri'])
        index = sdk_root / 'packages/ugk_trainer/assets/pose_hub/app-test-pack-r1/standing/index.json'
        catalog = json.loads(index.read_text(encoding='utf-8'))
        covers = {action['id']: action for action in catalog['actions']}
        posters = list((ROOT / 'assets/public_posters').glob('*.webp'))
        self.assertEqual(len(posters), 46)
        for poster in posters:
            cover = covers[poster.stem]
            data = poster.read_bytes()
            self.assertEqual(len(data), cover['bytes'], poster.name)
            self.assertEqual(hashlib.sha256(data).hexdigest(), cover['sha256'], poster.name)
            self.assertTrue(cover['alpha'], poster.name)
            self.assertEqual(cover['sourceVideo']['frameIndex'], 0, poster.name)
        manifest = tm.load_json(tm.MANIFEST)
        still_count = 0
        for still_set in manifest['stills'].values():
            for item in still_set['items'].values():
                still_count += 1
                for theme in ('dark', 'light'):
                    entry = item[theme]
                    data = (ROOT / entry['asset']).read_bytes()
                    self.assertEqual(len(data), entry['bytes'], entry['asset'])
                    self.assertEqual(hashlib.sha256(data).hexdigest(), entry['sha256'], entry['asset'])
        self.assertEqual(still_count, 20)
        self.assertEqual(list((ROOT / 'assets/drill_media').rglob('*.mp4')), [])

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
