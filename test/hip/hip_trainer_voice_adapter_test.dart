import 'package:flutter_test/flutter_test.dart';
import 'package:hiplab/hip/domain/hip_assessment.dart';
import 'package:hiplab/hip/domain/hip_library.dart';
import 'package:hiplab/hip/domain/hip_session.dart';
import 'package:hiplab/hip/trainer/hip_trainer_plan.dart';
import 'package:hiplab/hip/voice/session_script.dart';
import 'package:ugk_trainer/engine.dart' as trainer;
import 'hip_domain_test.dart' show loadContent;
import 'hip_voice_test.dart' show loadVoiceLibrary;

void main() {
  final content = loadContent();
  final planner = TrainingPlanner(content);
  for (final id in ['glute-max-A', 's-pigeon', 'n-seated-knee-lift']) {
    for (final lang in ['zh', 'en']) {
      test(
        'production $id $lang keeps all D-01 sets and the exact authored timeline',
        () {
          final kit = content.kit(id)!;
          final plan = planner.customPlan(
            CustomRoutine(
              id: 'test',
              name: 'test',
              steps: [
                CustomStep.fromDose(
                  kit,
                  const LibraryDose(
                    reps: 6,
                    seconds: 35,
                    sets: 3,
                    holdSeconds: 10,
                  ),
                ),
              ],
            ),
            TrainingProfile(
              level: 3,
              asymmetry: {content.drill(id).directions.first: HipSide.left},
            ),
          )!;
          final script = HipSessionScript(
            lib: loadVoiceLibrary(),
            lang: lang,
            steps: plan.steps,
            kits: content.kits,
            restSeconds: plan.transitionSeconds,
          );
          final coachPlan = toTrainerPlan(plan);
          final builder = HipSessionBuilder(
            script: script,
            transitionSeconds: plan.transitionSeconds,
          );
          final phases = builder.phases(coachPlan);
          final engine = trainer.SessionEngine(phases);
          final runner = trainer.SessionRunner(engine, script);
          final expected = <String>[];
          var offset = 0.0;
          final old = script.legacy;
          for (final p in old.phases(plan.steps)) {
            for (final cue in old.cues(p, plan.steps)) {
              expected.add(
                '${(offset + cue.at).toStringAsFixed(3)}:${cue.clips.join(',')}',
              );
            }
            offset += p.seconds;
          }
          final actual = <String>[];
          for (var tick = 0; tick <= (offset * 20).ceil(); tick++) {
            for (final fired in runner.update(tick / 20)) {
              actual.add(
                '${fired.time.toStringAsFixed(3)}:${fired.cue.clips.join(',')}',
              );
            }
          }
          expect(actual, expected);
          final works = phases.where((p) => p.isWork).toList();
          expect(works.where((p) => p.side == trainer.Side.right).length, 3);
          expect(works.where((p) => p.side == trainer.Side.left).length, 4);
          expect(
            works.every((p) => p.blockIndex == 0 && p.itemInBlock == 0),
            isTrue,
          );
          expect(
            works.where((p) => p.side == trainer.Side.left).map((p) => p.set),
            [1, 2, 3, 4],
          );
          expect(engine.done, isTrue);
          final result = trainer.SessionRecorder(
            plan: coachPlan,
            totalExercises: 1,
          ).finish(engine, activeSeconds: offset);
          // Trainer 0.2 counts every required unique set identity. The tight
          // side's fourth set is required even though the other side has 3.
          expect(result.items.single.plannedSets, 4);
          expect(result.items.single.completedSets, 4);
          expect(result.items.single.plannedSideSets, {'right': 3, 'left': 4});
          expect(result.items.single.completedSideSets, {
            'right': 3,
            'left': 4,
          });
          expect(result.full, isTrue);
          expect(engine.visits.where((v) => v.phase.isWork).length, 7);
          expect(
            result.items.single.activeSeconds,
            closeTo(
              plan.steps.single.seconds - (kit.kind.counted ? 0 : 25),
              .001,
            ),
          );
        },
      );
    }
  }

  test(
    'D-01 extra side set remains required when the final set is skipped',
    () {
      const id = 'glute-max-A';
      final kit = content.kit(id)!;
      final plan = planner.customPlan(
        CustomRoutine(
          id: 'asymmetric-result',
          name: 'asymmetric-result',
          steps: [
            CustomStep.fromDose(
              kit,
              const LibraryDose(reps: 6, sets: 3, holdSeconds: 10),
            ),
          ],
        ),
        TrainingProfile(
          level: 3,
          asymmetry: {content.drill(id).directions.first: HipSide.left},
        ),
      )!;
      final script = HipSessionScript(
        lib: loadVoiceLibrary(),
        lang: 'zh',
        steps: plan.steps,
        kits: content.kits,
      );
      final coachPlan = toTrainerPlan(plan);
      final phases = HipSessionBuilder(script: script).phases(coachPlan);
      final finalWork = phases.lastWhere((p) => p.isWork);
      expect(finalWork.side, trainer.Side.left);
      expect(finalWork.set, 4);
      final finalStart = phases
          .takeWhile((p) => !identical(p, finalWork))
          .fold(0.0, (sum, p) => sum + p.seconds);
      final engine = trainer.SessionEngine(phases)..update(finalStart);
      expect(engine.phase, same(finalWork));
      engine.skip(finalStart);
      final result = trainer.SessionRecorder(
        plan: coachPlan,
        totalExercises: 1,
      ).finish(engine, activeSeconds: finalStart);
      expect(result.full, isFalse);
      expect(result.completedExercises, 0);
      expect(result.items.single.plannedSets, 4);
      expect(result.items.single.completedSets, 3);
      expect(result.items.single.completedSideSets, {'right': 3, 'left': 3});
    },
  );
}
