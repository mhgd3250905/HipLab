import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hiplab/hip/data/hip_public_catalog.dart';
import 'package:hiplab/hip/domain/hip_library.dart';
import 'package:hiplab/hip/domain/hip_session.dart';
import 'package:hiplab/hip/trainer/hip_trainer_plan.dart';
import 'package:ugk_coach/ugk_coach.dart' as coach;
import 'package:ugk_trainer_runtime/engine.dart'
    show SessionBuilderPlanExecutionTiming;

import 'hip_domain_test.dart' show loadContent;

coach.PlanItem _defaultItem(coach.Drill drill) => coach.PlanItem(
  exerciseId: drill.id,
  mode: drill.defaultDose.mode,
  sets: drill.defaultDose.sets,
  reps: drill.defaultDose.reps,
  workSeconds: drill.defaultDose.seconds,
  perSide: drill.unilateral,
  restSeconds: drill.defaultDose.restSeconds,
);

coach.TrainingPlan _plan(coach.PlanItem item) => coach.TrainingPlan(
  id: 'public-${item.exerciseId}',
  source: 'ai',
  title: '公共动作训练',
  goal: 'training',
  scene: 'home',
  level: 1,
  targetMinutes: 5,
  blocks: [
    coach.PlanBlock(
      id: 'main',
      name: '训练',
      type: coach.BlockType.main,
      items: [item],
    ),
  ],
);

CustomRoutine _stored(coach.TrainingPlan plan) => CustomRoutine(
  id: plan.id,
  name: plan.title,
  steps: [
    for (final item in plan.items)
      CustomStep(
        item.exerciseId,
        reps: item.reps,
        seconds: item.workSeconds,
        sets: item.sets,
      ),
  ],
  coachPlan: plan.toJson(),
  coachSdkVersion: 1,
);

void main() {
  final legacy = loadContent();
  final pack = coach.PoseHubAppTestCatalog.fromBytes(
    File(hipPublicCatalogAsset).readAsBytesSync(),
    semanticCatalogBytes: File(hipPublicSemanticsAsset).readAsBytesSync(),
  );
  final rhythms = hipPublicRhythms(pack);
  final catalog = hipCoachCatalogFromPublic(pack, rhythms: rhythms);
  final content = legacy.withPublicTraining(catalog, rhythms);
  final builder = hipSdkSessionBuilder(content);
  final planner = TrainingPlanner(content);

  test(
    'all 211 complete SDK actions survive durable restore and execution',
    () {
      expect(catalog.length, 211);
      expect(builder.rhythms.keys.toSet(), catalog.ids.toSet());
      var actionsOutsideLegacy = 0;
      for (final action in catalog.drills) {
        final original = _plan(_defaultItem(action));
        final encoded = jsonDecode(
          jsonEncode(CustomRoutinesCodec.encode([_stored(original)])),
        );
        final restored = CustomRoutinesCodec.decode(encoded, content).single;
        expect(restored.steps.single.kitId, action.id, reason: action.id);
        expect(restored.removed, 0, reason: action.id);
        expect(restored.coachPlan, original.toJson(), reason: action.id);
        final executable = planner.customPlan(
          restored,
          const TrainingProfile(),
        );
        expect(executable, isNotNull, reason: action.id);
        expect(toTrainerPlan(executable!).toJson(), original.toJson());
        expect(executable.steps.single.drill.id, action.id);
        expect(
          planner.customSkipped(restored, const TrainingProfile()),
          isEmpty,
        );
        expect(
          executable.seconds,
          builder.executionTiming(original).totalSeconds.ceil(),
          reason: action.id,
        );
        expect(
          restored.seconds(content),
          executable.seconds,
          reason: action.id,
        );
        expect(builder.phases(original).any((phase) => phase.isWork), isTrue);
        if (!legacy.drills.containsKey(action.id)) {
          actionsOutsideLegacy++;
          final display = executable.steps.single.drill;
          expect(display.name, action.name.of('zh'));
          expect(display.directions, isEmpty);
          expect(display.methods, isEmpty);
          expect(display.scenes, isEmpty);
          expect(display.cautions, action.cautions);
        }
      }
      expect(actionsOutsideLegacy, greaterThan(150));
    },
  );

  test(
    'eight partial actions cannot restore a playable SDK preview or plan',
    () {
      expect(pack.pendingActions, hasLength(8));
      final complete = _defaultItem(catalog.drills.first);
      for (final partial in pack.pendingActions) {
        // Deliberately substitute an unadmitted id into otherwise valid plan
        // data. This models an incompatible/malicious saved payload, not a dose
        // definition for the incomplete action.
        final item = complete.copyWith(exerciseId: partial.id);
        final original = _plan(item);
        final restored = CustomRoutine.fromJson(
          _stored(original).toJson(),
          content,
        )!;
        expect(inSdkLibrary(content, partial.id), isFalse);
        expect(hipSdkDrill(content, partial.id), isNull);
        expect(restored.steps, isEmpty);
        expect(restored.removed, 1);
        expect(restored.coachPlan, original.toJson());
        expect(planner.customPlan(restored, const TrainingProfile()), isNull);
        expect(
          planner.customSkipped(restored, const TrainingProfile()).single.kitId,
          partial.id,
        );
        expect(restored.seconds(content), 0);
      }
    },
  );

  test(
    'legacy routine doses and assessment metadata stay on the local path',
    () {
      final localPlanner = TrainingPlanner(legacy);
      for (final routine in legacy.routines) {
        final before = localPlanner.planFor([routine], const TrainingProfile());
        final after = planner.planFor([routine], const TrainingProfile());
        expect(after.seconds, before.seconds, reason: routine.id);
        expect(
          after.steps.map((step) => [step.drill.id, step.dose, step.seconds]),
          before.steps.map((step) => [step.drill.id, step.dose, step.seconds]),
          reason: routine.id,
        );
      }
      for (final id in legacy.drills.keys.where(catalog.contains)) {
        expect(hipSdkDrill(content, id), same(legacy.drill(id)), reason: id);
      }
    },
  );
}
