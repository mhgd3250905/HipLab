"""Verify the original-byte closure of the 45 HipLab chat cutouts."""
import hashlib
import json
from pathlib import Path
import re
import unittest


ROOT = Path(__file__).resolve().parents[2]


class CoachStandingTests(unittest.TestCase):
    def test_original_byte_allowlist_closure(self):
        source = (ROOT / 'lib/hip/coach/hip_coach_profile.dart').read_text(encoding='utf-8')
        block = source.split('const hiplabCoachAuthorizedActionIds = <String>{', 1)[1].split('};', 1)[0]
        action_ids = re.findall(r"'([^']+)'", block)
        self.assertEqual(len(action_ids), 45)
        self.assertEqual(len(set(action_ids)), 45)
        manifest = json.loads((ROOT / 'assets/coach/standing-manifest.json').read_text(encoding='utf-8'))
        self.assertEqual(manifest['sourceCommit'], '0a6c3aaea9e3890d938799703f97819d5986ee7d')
        self.assertEqual(
            manifest['allowlistSha256'],
            hashlib.sha256(('\n'.join(sorted(action_ids)) + '\n').encode()).hexdigest(),
        )
        self.assertEqual({entry['actionId'] for entry in manifest['assets']}, set(action_ids))
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
