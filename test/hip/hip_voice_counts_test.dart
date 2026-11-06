// Custom rep counts go up to 30 (SDK PlanLimits reps 1–30; HipLab steppers
// ≤ 20), so every count 1…30 is recorded in both languages: the SDK says a
// count only when the clip exists (user report 2026-11-06: 15 reps went
// silent from 11 on).
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('count clips n.1…n.30 exist in zh and en', () {
    final m =
        jsonDecode(File('assets/voice/manifest.json').readAsStringSync())
            as Map<String, dynamic>;
    final clips = m['clips'] as Map<String, dynamic>;
    for (final lang in ['zh', 'en']) {
      final have = clips[lang] as Map<String, dynamic>;
      for (var n = 1; n <= 30; n++) {
        expect(have['n.$n'], isA<int>(), reason: '$lang n.$n in manifest');
        expect(
          File('assets/voice/$lang/n.$n.m4a').existsSync(),
          isTrue,
          reason: '$lang n.$n.m4a',
        );
      }
    }
  });
}
