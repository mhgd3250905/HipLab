import 'package:flutter_test/flutter_test.dart';
import 'package:hiplab/hip/domain/hip_assessment.dart';
import 'package:hiplab/hip/domain/hip_library.dart';
import 'package:hiplab/hip/domain/hip_session.dart';
import 'package:hiplab/hip/trainer/hip_trainer_plan.dart';
import 'package:hiplab/hip/voice/session_script.dart';
import 'package:ugk_coach/ugk_coach.dart' as coach;
import 'package:ugk_trainer_runtime/engine.dart' as trainer;

import 'hip_domain_test.dart' show loadContent;
import 'hip_voice_test.dart' show loadVoiceLibrary;

coach.TrainingPlan _completePlan() => const coach.TrainingPlan(
  id: 'sdk-structure',
  source: 'ai',
  title: 'SDK structure',
  goal: 'mobility',
  scene: 'home',
  level: 1,
  targetMinutes: 5,
  blocks: [
    coach.PlanBlock(
      id: 'main',
      name: 'Main',
      type: coach.BlockType.main,
      rounds: 2,
      restBetweenRoundsSeconds: 29,
      items: [
        coach.PlanItem(
          exerciseId: 's-figure4',
          mode: coach.DoseMode.time,
          sets: 2,
          workSeconds: 23,
          perSide: false,
          restSeconds: 17,
        ),
      ],
    ),
    coach.PlanBlock(
      id: 'circuit',
      name: 'Circuit',
      type: coach.BlockType.circuit,
      rounds: 2,
      restBetweenRoundsSeconds: 31,
      items: [
        coach.PlanItem(
          exerciseId: 'n-seated-knee-lift',
          mode: coach.DoseMode.reps,
          sets: 1,
          reps: 2,
          perSide: true,
          restSeconds: 19,
          segments: [
            coach.PlanSegment(
              id: 'hover',
              exerciseId: 'n-seated-knee-lift',
              mode: coach.DoseMode.reps,
              reps: 2,
              holdSeconds: 4,
            ),
            coach.PlanSegment(
              id: 'pry',
              exerciseId: 'h-sumo-pry',
              mode: coach.DoseMode.reps,
              reps: 2,
              holdSeconds: 7,
            ),
          ],
        ),
      ],
    ),
  ],
);

void main() {
  final content = loadContent();
  final script = HipSessionScript(
    lib: loadVoiceLibrary(),
    lang: 'zh',
    steps: const [],
    kits: content.kits,
    useSdkPhases: true,
  );
  final builder = hipSdkSessionBuilder(
    content,
    switchSecondsFor: script.switchSecondsFor,
  );
  final planner = TrainingPlanner(content, sdkBuilder: builder);
  CustomRoutine stored(coach.TrainingPlan plan) => CustomRoutine(
    id: 'sdk-saved',
    name: plan.title,
    restSeconds: 15,
    steps: const [CustomStep('s-figure4')],
    coachPlan: plan.toJson(),
  );

  test(
    'saved SDK plan retains rounds, segments, side and dose through playback',
    () {
      final original = _completePlan();
      final restored = CustomRoutine.fromJson(
        stored(original).toJson(),
        content,
      )!;
      final native = planner.customPlan(restored, const TrainingProfile())!;
      expect(toTrainerPlan(native).toJson(), original.toJson());
      final phases = builder.phases(toTrainerPlan(native));
      final mainWork = phases.where((p) => p.isWork && p.blockIndex == 0);
      expect(mainWork.map((p) => p.seconds), [23, 23, 23, 23]);
      expect(mainWork.map((p) => p.round), [1, 1, 2, 2]);
      expect(mainWork.map((p) => p.set), [1, 2, 1, 2]);
      expect(mainWork.every((p) => p.side == null), isTrue);
      final circuit = phases.where((p) => p.isWork && p.blockIndex == 1);
      expect(circuit, hasLength(8));
      expect(circuit.map((p) => p.segmentId).toSet(), {'hover', 'pry'});
      expect(
        circuit
            .where((p) => p.segmentId == 'hover')
            .every((p) => p.holdSeconds == 4),
        isTrue,
      );
      expect(
        circuit
            .where((p) => p.segmentId == 'pry')
            .every((p) => p.holdSeconds == 7),
        isTrue,
      );
      expect(
        phases
            .where((p) => p.kind == trainer.PhaseKind.roundRest)
            .map((p) => p.seconds),
        [29, 31],
      );
      expect(restored.coachPlan, original.toJson());
    },
  );

  test(
    'profile callback equals the exact voice-configured player phase sum',
    () {
      final original = _completePlan();
      final native = planner.customPlan(
        stored(original),
        const TrainingProfile(),
      )!;
      final timing = builder.executionTiming(original);
      final timeline = builder.phases(toTrainerPlan(native));
      expect(
        timing.totalSeconds,
        timeline.fold<double>(0, (sum, p) => sum + p.seconds),
      );
      expect(native.seconds, timing.totalSeconds.ceil());
      expect(timeline.first.kind, trainer.PhaseKind.prep);
      expect(timeline.first.seconds, 15);
      for (final (i, block) in timing.blocks.indexed) {
        expect(
          block.seconds,
          timeline
              .where((p) => p.blockIndex == i)
              .fold<double>(0, (sum, p) => sum + p.seconds),
        );
      }
    },
  );

  test('App asymmetry cannot add sides or sets to a complete SDK plan', () {
    final native = planner.customPlan(
      stored(_completePlan()),
      TrainingProfile(
        asymmetry: {content.drill('s-figure4').directions.first: HipSide.left},
      ),
    )!;
    final work = builder
        .phases(toTrainerPlan(native))
        .where((p) => p.isWork && p.blockIndex == 0);
    expect(work, hasLength(4));
    expect(work.every((p) => p.side == null && p.sets == 2), isTrue);
    expect(native.steps.first.extraSeconds, 0);
  });

  test(
    'a newly locked stored plan is refused whole without changing storage',
    () {
      final routine = stored(_completePlan());
      final original = routine.toJson();
      final direction = content.drill('n-seated-knee-lift').directions.first;
      final profile = TrainingProfile(lockedDirections: {direction});
      expect(planner.customSkipped(routine, profile), isNotEmpty);
      expect(planner.customPlan(routine, profile), isNull);
      expect(routine.toJson(), original);
    },
  );

  test('invalid full SDK data cannot fall back to the preview DTO', () {
    final invalid = CustomRoutine(
      id: 'invalid-sdk',
      name: 'Invalid SDK data',
      restSeconds: 15,
      steps: const [CustomStep('s-figure4')],
      coachPlan: const {'schemaVersion': 999},
    );
    expect(planner.customPlan(invalid, const TrainingProfile()), isNull);
  });

  test('SDK voice keeps segment counting and round-rest cues', () {
    final phases = builder.phases(_completePlan());
    for (final phase in phases) {
      expect(() => script.cues(phase, planSeconds: 300), returnsNormally);
    }
    final hover = phases.firstWhere((p) => p.isWork && p.segmentId == 'hover');
    expect(
      script.cues(hover, planSeconds: 300).expand((cue) => cue.clips),
      contains('n.1'),
    );
  });

  test(
    'pain reduction preserves SDK rests and only scales the requested occurrence',
    () {
      final plan = _completePlan();
      final baseline = builder.phases(plan);
      final adjusted = sdkSafetyPhases(builder, plan, workScale: {0: .5});
      expect(adjusted, hasLength(baseline.length));
      for (var i = 0; i < baseline.length; i++) {
        final before = baseline[i];
        final after = adjusted[i];
        expect(after.itemIndex, before.itemIndex);
        expect(after.round, before.round);
        expect(after.set, before.set);
        expect(
          after.seconds,
          before.isWork && before.itemIndex == 0
              ? (before.seconds * .5).ceilToDouble()
              : before.seconds,
        );
      }
      expect(plan.toJson(), _completePlan().toJson());
    },
  );

  test('pain skip retains later SDK occurrences and terminal phase', () {
    final adjusted = sdkSafetyPhases(builder, _completePlan(), omitted: {1});
    expect(adjusted.any((p) => p.isWork && p.itemIndex == 1), isFalse);
    expect(adjusted.where((p) => p.isWork).map((p) => p.itemIndex).toSet(), {
      0,
      2,
      3,
    });
    expect(adjusted.last.kind, trainer.PhaseKind.done);
  });

  test(
    'explicit pain substitution preserves the remaining dose and structure',
    () {
      final original = _completePlan();
      final replaced = substituteSdkExercise(
        original,
        'h-sumo-pry',
        'h-adductor-rock',
      );
      final before = original.toJson();
      final expected = original.toJson();
      for (final block in expected['blocks'] as List) {
        for (final item in block['items'] as List) {
          for (final segment in item['segments'] as List? ?? const []) {
            if (segment['exerciseId'] == 'h-sumo-pry') {
              segment['exerciseId'] = 'h-adductor-rock';
            }
          }
        }
      }
      expect(replaced.toJson(), expected);
      expect(original.toJson(), before);
    },
  );
}
