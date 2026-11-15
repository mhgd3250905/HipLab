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
    'all 248 public training actions survive durable restore and execution',
    () {
      expect(catalog.length, 249);
      expect(builder.rhythms.keys.toSet(), catalog.ids.toSet());
      final trainingActions = catalog.drills
          .where((action) => !assessmentOnlyDrills.contains(action.id))
          .toList();
      expect(trainingActions, hasLength(248));
      var actionsOutsideLegacy = 0;
      for (final action in trainingActions) {
        expect(inSdkLibrary(content, action.id), isTrue, reason: action.id);
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

  test('unadmitted actions cannot restore a playable SDK preview or plan', () {
    // r2-v11 has no pending rows; r1-v3 ids it removed stand in as the
    // unadmitted ids a stale saved payload can still carry.
    expect(pack.pendingActions, isEmpty);
    const removed = ['h-sleeper-stretch', 'scapular-C'];
    for (final id in removed) {
      expect(pack.tryGet(id), isNull, reason: id);
    }
    final complete = _defaultItem(catalog.drills.first);
    for (final partial in [
      ...pack.pendingActions.map((action) => action.id),
      ...removed,
    ].map((id) => (id: id))) {
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
  });

  test('stored direct and segmented self-test actions remain non-playable', () {
    final admitted = _defaultItem(catalog['h-squat']!);
    expect(catalog.contains('n-thomas-test'), isTrue);
    for (final id in assessmentOnlyDrills) {
      expect(inSdkLibrary(content, id), isFalse, reason: id);
      expect(canJoinGroup(content, id), isFalse, reason: id);
      expect(CustomStep.sdk(content, id), isNull, reason: id);
      expect(CustomStep(id).planItem(content), isNull, reason: id);
      for (final item in [
        admitted.copyWith(exerciseId: id),
        admitted.copyWith(
          segments: [
            coach.PlanSegment(
              id: 'self-test',
              exerciseId: id,
              mode: coach.DoseMode.time,
              workSeconds: 30,
            ),
          ],
        ),
      ]) {
        final original = _plan(item);
        final saved = _stored(original);
        final encoded = jsonDecode(
          jsonEncode(CustomRoutinesCodec.encode([saved])),
        );
        final restored = CustomRoutinesCodec.decode(encoded, content).single;
        expect(restored.coachPlan, saved.coachPlan, reason: id);
        if (catalog.contains(item.exerciseId)) {
          expect(restored.toJson(), saved.toJson(), reason: id);
          expect(restored.removed, 0, reason: id);
        }
        expect(restored.seconds(content), 0, reason: id);
        expect(
          planner.customPlan(restored, const TrainingProfile()),
          isNull,
          reason: id,
        );
        expect(
          planner.customSkipped(restored, const TrainingProfile()).single.kitId,
          id,
        );
      }
    }
  });

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
      for (final id in legacy.drills.keys.where(
        (id) => inSdkLibrary(content, id),
      )) {
        expect(hipSdkDrill(content, id), same(legacy.drill(id)), reason: id);
      }
      final demo = legacy.drill('n-thomas-test');
      final demoKit = legacy.kit(demo.id)!;
      expect(hipSdkDrill(content, demo.id), isNull);
      expect(
        localPlanner.singlePlan(
          demo,
          DoseRules.singleDefault(demoKit),
          const TrainingProfile(),
        ),
        isNull,
      );
      expect(
        content.rules.items
            .firstWhere((item) => item.id == 'thomas')
            .demoArt(content.drills),
        same(demo),
      );
    },
  );
}
