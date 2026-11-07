import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hiplab/hip/data/hip_action_scope.dart';
import 'package:hiplab/hip/data/hip_public_display.dart';
import 'package:hiplab/hip/data/hip_public_text_en.dart';

void main() {
  final source =
      jsonDecode(
            File('assets/public_media/catalog/catalog.json').readAsStringSync(),
          )
          as Map<String, dynamic>;
  final definitions = {
    for (final row in source['drills'] as List)
      (row as Map<String, dynamic>)['id'] as String: row,
  };
  final chinese = RegExp(r'[\u3400-\u9fff]');

  test(
    'every authorized public action has complete display-only English copy',
    () {
      expect(hipPublicTextEn.keys.toSet(), hiplabCoachAuthorizedActionIds);
      var cueCount = 0, cautionCount = 0, contraindicationCount = 0;
      for (final id in hiplabCoachAuthorizedActionIds) {
        final original = definitions[id]!;
        final copy = hipPublicTextEn[id]!;
        final cues = (original['cues'] as Map)['zh'] as List;
        expect(copy.cues.length, cues.length, reason: '$id cue coverage');
        expect(
          copy.cautions.length,
          (original['cautions'] as List).length,
          reason: '$id caution coverage',
        );
        expect(
          copy.contraindications.length,
          (original['contraindications'] as List).length,
          reason: '$id contraindication coverage',
        );
        for (final text in [
          copy.purpose,
          ...copy.cues,
          ...copy.cautions,
          ...copy.contraindications,
        ]) {
          expect(text.trim(), isNotEmpty, reason: id);
          expect(chinese.hasMatch(text), isFalse, reason: '$id: $text');
        }
        cueCount += copy.cues.length;
        cautionCount += copy.cautions.length;
        contraindicationCount += copy.contraindications.length;
      }
      expect(cueCount, 689);
      expect(cautionCount, 289);
      expect(contraindicationCount, 200);
    },
  );

  test(
    'English metadata covers the actual catalogue taxonomy without changing IDs',
    () {
      for (final id in hiplabCoachAuthorizedActionIds) {
        final definition = definitions[id]!;
        for (final muscle in definition['muscleGroups'] as List) {
          expect(
            HipPublicDisplay.muscles.containsKey(muscle),
            isTrue,
            reason: '$id muscle $muscle',
          );
        }
        for (final item in definition['equipment'] as List) {
          expect(
            HipPublicDisplay.equipment.containsKey(item),
            isTrue,
            reason: '$id equipment $item',
          );
        }
        expect(
          HipPublicDisplay.categories.containsKey(definition['category']),
          isTrue,
        );
        expect(
          chinese.hasMatch(HipPublicDisplay.metadata(definition)),
          isFalse,
        );
        expect((definition['name'] as Map)['en'], isNotEmpty);
      }
    },
  );

  test(
    'stop conditions and authored side counting remain explicit in English',
    () {
      final support = hipPublicTextEn['abs-B']!;
      expect(support.cautions.join(' ').toLowerCase(), contains('stop'));
      expect(support.cautions.join(' ').toLowerCase(), contains('numb'));
      expect(
        hipPublicTextEn['adductors-A']!.cues.join(' ').toLowerCase(),
        contains('both sides'),
      );
      expect(
        hipPublicTextEn['n-pelvis-circle']!.cautions.join(' ').toLowerCase(),
        contains('stop'),
      );
    },
  );
}
