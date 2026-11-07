import 'package:flutter_test/flutter_test.dart';
import 'package:hiplab/hip/ui/hip_content_text.dart';
import 'package:hiplab/hip/ui/library/action_filter.dart';
import 'package:hiplab/hip/ui/library/lib_text.dart';
import 'package:ugk_trainer_runtime/ugk_trainer_runtime.dart' as trainer;

import 'hip_domain_test.dart' show loadContent;

void main() {
  final content = loadContent();
  final chinese = RegExp(r'[\u4e00-\u9fff]');
  test(
    'all authored routines and display doses have explicit English copy',
    () {
      for (final routine in content.routines) {
        expect(HipContentText.routineNames, contains(routine.id));
        expect(HipContentText.en.routineName(routine), isNot(matches(chinese)));
        expect(
          HipContentText.en.routineAudience(routine),
          isNot(matches(chinese)),
        );
        expect(HipContentText.zh.routineName(routine), routine.name);
        for (final step in routine.steps) {
          for (final authored in [step.dose, step.tip]) {
            expect(HipContentText.english, contains(authored));
            expect(HipContentText.en.text(authored), isNot(matches(chinese)));
            expect(HipContentText.zh.text(authored), authored);
          }
        }
      }
    },
  );
  test('all local move names and cautions are translated only for display', () {
    for (final drill in content.drills.values) {
      expect(HipContentText.drillNames, contains(drill.id));
      expect(HipContentText.en.drillName(drill), isNot(matches(chinese)));
      expect(HipContentText.zh.drillName(drill), drill.name);
      for (final caution in drill.cautions) {
        expect(HipContentText.en.text(caution), isNot(matches(chinese)));
      }
    }
  });
  test(
    'facet display labels localize while original filter values stay stable',
    () {
      for (final value in [
        ...hipPartOrder,
        ...hipPlaceOrder,
        hipTypeRelax,
        hipTypeStrength,
        hipBodyweight,
        ...trainer.poseHubEquipmentLabels.values,
      ]) {
        expect(hipFacetLabel(LibText.en, value), isNot(matches(chinese)));
        expect(hipFacetLabel(LibText.zh, value), value);
      }
    },
  );
}
