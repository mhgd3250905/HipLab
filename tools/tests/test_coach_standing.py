"""Verify the original bytes of HipLab's 45 historical chat cutouts."""
import hashlib
import json
from pathlib import Path
import re
import unittest


ROOT = Path(__file__).resolve().parents[2]


class CoachStandingTests(unittest.TestCase):
    def test_historical_cutouts_keep_original_bytes_within_current_scope(self):
        source = (ROOT / 'lib/hip/data/hip_action_scope.dart').read_text(encoding='utf-8')
        block = source.split('const hiplabCoachAuthorizedActionIds = <String>{', 1)[1].split('};', 1)[0]
        action_ids = re.findall(r"'([^']+)'", block)
        self.assertEqual(len(action_ids), len(set(action_ids)))
        manifest = json.loads((ROOT / 'assets/coach/standing-manifest.json').read_text(encoding='utf-8'))
        # These retained cutouts predate the public poster bundle. Their source
        # manifest describes the historical 45, not the expanded active scope.
        historical_ids = [entry['actionId'] for entry in manifest['assets']]
        self.assertEqual(len(historical_ids), 45)
        self.assertEqual(len(set(historical_ids)), 45)
        self.assertTrue(set(historical_ids).issubset(action_ids))
        self.assertEqual(manifest['sourceCommit'], '0a6c3aaea9e3890d938799703f97819d5986ee7d')
        self.assertEqual(
            manifest['allowlistSha256'],
            hashlib.sha256(('\n'.join(sorted(historical_ids)) + '\n').encode()).hexdigest(),
        )
        expected_paths = set()
        for entry in manifest['assets']:
            path = ROOT / entry['asset']
            expected_paths.add(path)
            data = path.read_bytes()
            self.assertEqual(len(data), entry['bytes'], entry['actionId'])
            self.assertEqual(hashlib.sha256(data).hexdigest(), entry['sha256'], entry['actionId'])
            self.assertEqual(data[:4], b'RIFF', entry['actionId'])
            self.assertEqual(data[8:12], b'WEBP', entry['actionId'])
        self.assertEqual(set((ROOT / 'assets/coach/standing').glob('*.webp')), expected_paths)


if __name__ == '__main__':
    unittest.main()
