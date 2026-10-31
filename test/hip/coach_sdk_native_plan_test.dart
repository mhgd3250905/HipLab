import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hiplab/hip/coach/plan_mapping.dart';
import 'package:hiplab/hip/domain/hip_assessment.dart';
import 'package:hiplab/hip/domain/hip_library.dart';
import 'package:hiplab/hip/domain/hip_session.dart';
import 'package:hiplab/hip/trainer/hip_trainer_plan.dart';
import 'package:hiplab/hip/voice/session_script.dart';
import 'package:ugk_coach/ugk_coach.dart' as coach;
import 'package:ugk_trainer/engine.dart' as trainer;

import '../../tools/coach/coach_v2_native_metrics.dart'
    show loadCoachMetricVoiceScript, measureCoachPlanTiming;
import 'hip_domain_test.dart' show loadContent;
import 'hip_voice_test.dart' show loadVoiceLibrary;

coach.TrainingPlan fullPlan() => const coach.TrainingPlan(
  id: 'complete-ai-plan',
  source: 'ai',
  title: 'SDK complete plan',
  summary: 'Preserve every dose and phase',
  goal: 'mobility',
  scene: 'home',
  level: 3,
  targetMinutes: 5,
  equipment: ['mat'],
  blocks: [
    coach.PlanBlock(
      id: 'main',
      name: 'Main',
      type: coach.BlockType.main,
      items: [
        coach.PlanItem(
          exerciseId: 's-figure4',
          mode: coach.DoseMode.time,
          sets: 2,
          workSeconds: 23,
          perSide: false,
          restSeconds: 17,
          note: 'Do not add a second side',
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
  final planner = TrainingPlanner(content);
  trainer.SessionBuilder builder() => trainer.SessionBuilder(
    prepSeconds: 15,
    rhythms: {
      for (final kit in content.kits.values)
        kit.id: trainer.Rhythm.fromActionKitJson(kit.raw),
    },
  );
  CustomRoutine routine() => CoachPlanMapper(
    content,
  ).map(fullPlan(), id: 'saved-ai', at: DateTime(2026, 10, 31)).routine;
  final catalog = coach.Catalog.fromJson(
    jsonDecode(File('assets/coach/catalog.json').readAsStringSync()),
  );
  coach.TrainingPlan timingPlan({int targetMinutes = 5}) => coach.TrainingPlan(
    id: 'timing-diagnostic',
    source: 'ai',
    title: 'Timing diagnostic',
    summary: 'A timed action and a counted action',
    goal: 'mobility',
    scene: 'home',
    level: 1,
    targetMinutes: targetMinutes,
    equipment: const [],
    blocks: const [
      coach.PlanBlock(
        id: 'main',
        name: 'Main',
        type: coach.BlockType.main,
        items: [
          coach.PlanItem(
            exerciseId: 's-figure4',
            mode: coach.DoseMode.time,
            workSeconds: 265,
            sets: 1,
            restSeconds: 0,
            perSide: false,
          ),
          coach.PlanItem(
            exerciseId: 'h-squat',
            mode: coach.DoseMode.reps,
            reps: 2,
            sets: 1,
            restSeconds: 0,
            perSide: false,
          ),
        ],
      ),
    ],
  );
  trainer.SessionBuilder manualBuilder() => trainer.SessionBuilder(
    prepSeconds: 15,
    // Deliberately far from target: an estimate cannot certify elapsed time.
    selfPacedRepEstimate: 200,
    rhythms: {'h-squat': trainer.Rhythm.selfPacedReps},
  );

  test(
    'saved AI plan roundtrips and native execution retains full SDK data',
    () {
      final original = fullPlan();
      final loaded = CustomRoutine.fromJson(routine().toJson(), content)!;
      final native = planner.customPlan(loaded, const TrainingProfile())!;
      expect(native.sdkPlan, isNotNull);
      expect(toTrainerPlan(native).toJson(), original.toJson());
      expect(native.steps, hasLength(3)); // one main + two circuit occurrences
      final phases = builder().phases(toTrainerPlan(native));
      final mainWork = phases
          .where((p) => p.isWork && p.blockIndex == 0)
          .toList();
      expect(mainWork.map((p) => p.seconds), [23, 23]);
      expect(mainWork.every((p) => p.side == null), isTrue);
      expect(
        phases
            .where(
              (p) =>
                  p.kind == trainer.PhaseKind.rest && p.nextExerciseId == null,
            )
            .single
            .seconds,
        17,
      );
      expect(
        phases
            .where((p) => p.kind == trainer.PhaseKind.roundRest)
            .single
            .seconds,
        31,
      );
      final circuit = phases
          .where((p) => p.isWork && p.blockIndex == 1)
          .toList();
      expect(circuit, hasLength(8)); // two segments x two sides x two rounds
      expect(circuit.map((p) => p.itemIndex).toSet(), {1, 2});
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
    },
  );

  test(
    'saved AI main rounds execute all sets without changing the saved plan',
    () {
      final json = fullPlan().toJson();
      final main = (json['blocks'] as List).first as Map;
      main['rounds'] = 2;
      main['restBetweenRoundsSeconds'] = 29;
      final original = const coach.PlanCodec().decodeStrict(json).plan!;
      final saved = CoachPlanMapper(content)
          .map(original, id: 'saved-main-rounds', at: DateTime(2026, 10, 31))
          .routine;
      final native = planner.customPlan(
        CustomRoutine.fromJson(saved.toJson(), content)!,
        const TrainingProfile(),
      )!;
      expect(toTrainerPlan(native).toJson(), original.toJson());
      expect(native.steps, hasLength(4)); // two main + two circuit occurrences
      final phases = builder().phases(toTrainerPlan(native));
      final work = phases
          .where((phase) => phase.isWork && phase.blockIndex == 0)
          .toList();
      expect(work.map((phase) => phase.seconds), [23, 23, 23, 23]);
      expect(work.map((phase) => phase.round), [1, 1, 2, 2]);
      expect(work.map((phase) => phase.set), [1, 2, 1, 2]);
      expect(
        phases
            .where((phase) => phase.kind == trainer.PhaseKind.roundRest)
            .map((phase) => phase.seconds),
        [29, 31],
      );
      final total = phases.fold<double>(0, (sum, phase) => sum + phase.seconds);
      final engine = trainer.SessionEngine(phases)..update(total + .001);
      expect(engine.done, isTrue);
      expect(engine.fullyCompletedExercises, 4);
      expect(
        engine.visits.fold<double>(0, (sum, visit) => sum + visit.seconds),
        closeTo(total, .000001),
      );
      expect(saved.coachPlan, original.toJson());
    },
  );

  test(
    'offline bundled Chinese switch timing matches the actual AI player script',
    () {
      final metricScript = loadCoachMetricVoiceScript(content);
      final actualScript = HipSessionScript(
        lib: loadVoiceLibrary(),
        lang: 'zh',
        steps: const [],
        kits: content.kits,
        useSdkPhases: true,
      );
      for (final kit in content.kits.values) {
        final item = coach.PlanItem(
          exerciseId: kit.id,
          mode: coach.DoseMode.time,
          sets: 1,
          restSeconds: 0,
          workSeconds: 30,
          perSide: true,
        );
        final rhythm = trainer.Rhythm.fromActionKitJson(kit.raw);
        for (final side in trainer.Side.values) {
          expect(
            metricScript.switchSecondsFor(item, rhythm, side),
            actualScript.switchSecondsFor(item, rhythm, side),
            reason: '${kit.id} ${side.name}',
          );
        }
      }
    },
  );

  test(
    'timed diagnostics retain natural completion and the strict duration gate',
    () {
      final plan = timingPlan();
      final timing = measureCoachPlanTiming(
        plan: plan,
        content: content,
        catalog: catalog,
      );
      expect(timing['isEstimate'], isFalse);
      expect(timing['manualCountingPhases'], isEmpty);
      expect(timing['manualEstimatedSeconds'], 0);
      expect(timing['timedPhaseSeconds'], timing['nativeTotalSeconds']);
      expect(timing['engineNaturallyCompleted'], isTrue);
      expect(timing['engineReplayStatus'], 'naturally_completed');
      expect(timing['nativeEngineVisitSeconds'], timing['nativeTotalSeconds']);
      expect(timing['fullyCompletedOccurrences'], 2);
      expect(timing['nativeWithinTolerance'], isTrue);
      expect(timing['durationGatePassed'], isTrue);

      final excessiveRest = measureCoachPlanTiming(
        plan: plan,
        content: content,
        catalog: catalog,
        executionBuilder: trainer.SessionBuilder(
          prepSeconds: 15,
          transitionSeconds: 500,
        ),
      );
      expect(excessiveRest['engineNaturallyCompleted'], isTrue);
      expect(excessiveRest['nativeWithinTolerance'], isFalse);
      expect(excessiveRest['nativeDurationGatePassed'], isFalse);
      expect(excessiveRest['withinTolerance'], isFalse);
      expect(excessiveRest['durationGatePassed'], isFalse);
    },
  );

  test(
    'manual diagnostics expose nominal phases without claiming engine completion',
    () {
      final plan = timingPlan();
      final original = jsonEncode(plan.toJson());
      final timing = measureCoachPlanTiming(
        plan: plan,
        content: content,
        catalog: catalog,
        executionBuilder: manualBuilder(),
      );
      expect(timing['completePlanPreserved'], isTrue);
      expect(jsonEncode(plan.toJson()), original);
      expect(timing['isEstimate'], isTrue);
      final manual = (timing['manualCountingPhases'] as List).single as Map;
      expect(manual['exerciseId'], 'h-squat');
      expect(manual['phaseIndex'], 3);
      expect(manual['itemIndex'], 1);
      expect(manual['blockIndex'], 0);
      expect(manual['set'], 1);
      expect(manual['round'], 0);
      expect(manual['side'], isNull);
      expect(manual['reps'], 2);
      expect(manual['nominalSeconds'], 400);
      expect(manual['estimateSecondsPerRep'], 200);
      expect(manual['estimateBasis'], contains('SessionBuilder.workSeconds'));
      expect(timing['timedPhaseSeconds'], 295);
      expect(timing['manualEstimatedSeconds'], 400);
      expect(timing['nativeTotalSeconds'], 695);
      expect(timing['nativeWithinTolerance'], isNull);
      expect(timing['nativeDurationErrorRatio'], isNull);
      expect(timing['nativeEstimateDurationErrorRatio'], greaterThan(1));
      expect(timing['nativeEngineVisitSeconds'], isNull);
      expect(timing['fullyCompletedOccurrences'], isNull);
      expect(timing['engineNaturallyCompleted'], isNull);
      expect(timing['engineReplayStatus'], 'not_applicable_manual_counting');
      expect(timing['nativeDurationGatePassed'], isTrue);
      expect(
        timing['nativeDurationGateReason'],
        'manual_counting_estimate_exempt_by_user',
      );
      expect(timing['withinTolerance'], isNull);
      expect(timing['cardWithinTolerance'], isTrue);
      expect(timing['durationGatePassed'], isTrue);

      final engine = trainer.SessionEngine(manualBuilder().phases(plan))
        ..update(100000);
      expect(engine.done, isFalse);
      expect(engine.awaitingCompletion, isTrue);
    },
  );

  test('manual timing exemption does not bypass the card estimate gate', () {
    final timing = measureCoachPlanTiming(
      plan: timingPlan(targetMinutes: 1),
      content: content,
      catalog: catalog,
      executionBuilder: manualBuilder(),
    );
    expect(timing['isEstimate'], isTrue);
    expect(timing['nativeDurationGatePassed'], isTrue);
    expect(timing['cardWithinTolerance'], isFalse);
    expect(timing['durationGatePassed'], isFalse);
  });

  test(
    'AI native plan does not add asymmetry sets or impose kit sidedness',
    () {
      final direction = content.drill('s-figure4').directions.first;
      final native = planner.customPlan(
        routine(),
        TrainingProfile(asymmetry: {direction: HipSide.left}),
      )!;
      final work = builder()
          .phases(toTrainerPlan(native))
          .where((p) => p.isWork && p.blockIndex == 0);
      expect(work, hasLength(2));
      expect(work.every((p) => p.side == null && p.sets == 2), isTrue);
      expect(native.steps.first.extraSeconds, 0);
      expect(native.steps.first.sided, isFalse);
    },
  );

  test(
    'App pain-direction locks apply at playback without rewriting saved AI plan',
    () {
      final saved = routine();
      final original = saved.coachPlan;
      final locked = content.drill('n-seated-knee-lift').directions.first;
      final profile = TrainingProfile(lockedDirections: {locked});
      final skipped = planner.customSkipped(saved, profile);
      expect(skipped.any((step) => step.kitId == 'n-seated-knee-lift'), isTrue);
      final native = planner.customPlan(saved, profile)!;
      expect(
        native.sdkPlan!.exerciseIds,
        isNot(contains('n-seated-knee-lift')),
      );
      expect(saved.coachPlan, original);
      expect(
        planner.customPlan(saved, const TrainingProfile(blocked: true)),
        isNull,
      );
    },
  );

  test(
    'bad full SDK data cannot silently fall back to lossy library preview',
    () {
      final invalid = CustomRoutine(
        id: 'bad',
        name: 'bad',
        steps: const [CustomStep('s-figure4')],
        coachPlan: const {'schemaVersion': 999},
      );
      expect(planner.customPlan(invalid, const TrainingProfile()), isNull);
    },
  );

  test(
    'SDK safety reduction preserves segment identities and rest durations',
    () {
      final sdk = fullPlan();
      final base = builder().phases(sdk);
      final modified = sdkSafetyPhases(builder(), sdk, workScale: {1: .5});
      expect(modified, hasLength(base.length));
      for (var i = 0; i < base.length; i++) {
        final before = base[i];
        final after = modified[i];
        expect(after.itemIndex, before.itemIndex);
        expect(after.segmentId, before.segmentId);
        expect(after.round, before.round);
        expect(
          after.seconds,
          before.isWork && before.itemIndex == 1
              ? (before.seconds * .5).ceilToDouble()
              : before.seconds,
        );
      }
      expect(
        sdkSafetyPhases(
          builder(),
          sdk,
          omitted: {1},
        ).any((p) => p.isWork && p.itemIndex == 1),
        isFalse,
      );
      expect(sdk.toJson(), fullPlan().toJson());
    },
  );

  test(
    'SDK safety substitution preserves rounds doses rests and saved original',
    () {
      final original = fullPlan();
      final substitute = substituteSdkExercise(
        original,
        'h-sumo-pry',
        'h-squat',
      );
      final old = original.blocks[1].items.single.segments.last;
      final changed = substitute.blocks[1].items.single.segments.last;
      expect(changed.exerciseId, 'h-squat');
      expect(changed.id, old.id);
      expect(changed.reps, old.reps);
      expect(changed.holdSeconds, old.holdSeconds);
      expect(substitute.blocks[1].rounds, 2);
      expect(substitute.blocks[1].restBetweenRoundsSeconds, 31);
      expect(substitute.blocks[0].toJson(), original.blocks[0].toJson());
      expect(original.toJson(), fullPlan().toJson());
    },
  );

  test(
    'AI voice uses SDK phases including round rests and segment hold calls',
    () {
      final native = planner.customPlan(routine(), const TrainingProfile())!;
      final script = HipSessionScript(
        lib: loadVoiceLibrary(),
        lang: 'zh',
        steps: native.steps,
        kits: content.kits,
        useSdkPhases: true,
      );
      final phases = builder().phases(toTrainerPlan(native));
      for (final phase in phases) {
        expect(
          () => script.cues(phase, planSeconds: native.seconds.toDouble()),
          returnsNormally,
        );
      }
      final hover = phases.firstWhere(
        (p) => p.isWork && p.segmentId == 'hover',
      );
      final calls = script.cues(hover, planSeconds: native.seconds.toDouble());
      expect(calls, isNotEmpty);
      expect(calls.expand((cue) => cue.clips), contains('n.1'));
    },
  );
}
