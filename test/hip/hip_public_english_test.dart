import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hiplab/hip/data/hip_action_scope.dart';
import 'package:hiplab/hip/data/hip_public_display.dart';
import 'package:hiplab/hip/data/hip_public_text_en.dart';
import 'package:hiplab/hip/data/hip_shared_library.dart';
import 'package:ugk_coach/ugk_coach.dart' as coach;

void main() {
  final semantics = File('assets/public_media/catalog/catalog.json');
  final source =
      jsonDecode(semantics.readAsStringSync()) as Map<String, dynamic>;
  final delivery = coach.PoseHubAppTestCatalog.fromBytes(
    File('assets/public_media/catalog.json').readAsBytesSync(),
    semanticCatalogBytes: semantics.readAsBytesSync(),
  );
  final definitions = {
    for (final row in source['drills'] as List)
      (row as Map<String, dynamic>)['id'] as String: row,
  };
  final chinese = RegExp(r'[\u3400-\u9fff]');
  final blockedEnglish = RegExp(
    r'\b(?:rehab|rehabilitation|therapy|treatment|physical therapy|medical)\b',
    caseSensitive: false,
  );

  test(
    'English translations retain every authored line for 248 actions and the self-test demo',
    () {
      expect(hiplabCoachAuthorizedActionIds, hasLength(248));
      expect(hipPublicTextEn.keys.toSet(), {
        ...hiplabCoachAuthorizedActionIds,
        'n-thomas-test',
      });
      var cueCount = 0, cautionCount = 0, contraindicationCount = 0;
      for (final id in hipPublicTextEn.keys) {
        final original = definitions[id]!;
        final copy = hipPublicEnglishTextFor(id, catalog: delivery)!;
        final authored = delivery.tryGet(id)!.raw;
        expect(copy.purpose, authored['purposeEn'], reason: id);
        expect(copy.cues, authored['cuesEn'], reason: id);
        expect(copy.cautions, authored['cautionsEn'], reason: id);
        expect(copy.contraindications, hipPublicTextEn[id]!.contraindications);
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
          expect(blockedEnglish.hasMatch(text), isFalse, reason: '$id: $text');
        }
        cueCount += copy.cues.length;
        cautionCount += copy.cautions.length;
        contraindicationCount += copy.contraindications.length;
      }
      expect(cueCount, 825);
      expect(cautionCount, 353);
      expect(contraindicationCount, 253);
    },
  );

  test('all library actions show English labels and guidance', () {
    final display = hipEnglishPublicDisplay(
      delivery.toAiCatalog(),
      delivery: delivery,
    )!;
    for (final id in hiplabCoachAuthorizedActionIds) {
      final original = definitions[id]!;
      final text = display(id)!;
      final copy = hipPublicEnglishTextFor(id, catalog: delivery)!;
      expect(text.name, (original['name'] as Map)['en'], reason: id);
      expect(text.metadata, isNotEmpty, reason: id);
      expect(text.cues, copy.cues, reason: id);
      expect(text.cautions, [
        ...copy.cautions,
        if (copy.contraindications.isNotEmpty)
          'Caution areas: ${copy.contraindications.join(', ')}.',
      ], reason: id);
      for (final value in [
        text.name!,
        text.metadata!,
        text.muscles!,
        ...text.cues!,
        ...text.cautions!,
      ]) {
        expect(chinese.hasMatch(value), isFalse, reason: '$id: $value');
        expect(blockedEnglish.hasMatch(value), isFalse, reason: '$id: $value');
      }
    }
  });

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
      final support = hipPublicEnglishTextFor('abs-B')!;
      expect(support, same(hipPublicTextEn['abs-B']));
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
