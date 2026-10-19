// PR #22 F7: one rule for the sets a side really plays, shared by the voice
// script and the player's pain-halving guard.
import 'package:flutter_test/flutter_test.dart';
import 'package:hiplab/hip/domain/hip_assessment.dart';
import 'package:hiplab/hip/domain/hip_library.dart';
import 'package:hiplab/hip/domain/hip_session.dart';
import 'package:hiplab/hip/voice/session_script.dart';

import 'hip_domain_test.dart' show loadContent;
import 'hip_voice_test.dart' show loadVoiceLibrary;

void main() {
  final content = loadContent();
  final planner = TrainingPlanner(content);
  final lib = loadVoiceLibrary();
  SessionScript script() => SessionScript(
    lib: lib,
    lang: 'zh',
    routineIds: const [],
    restSeconds: 15,
    kits: content.kits,
  );

  PlanStep groupStep(String id, LibraryDose dose, {HipSide? tight}) {
    final kit = content.kit(id)!;
    final dir = content.drill(id).directions.first;
    return planner
        .customPlan(
          CustomRoutine(
            id: 'f7',
            name: 'F7',
            steps: [CustomStep.fromDose(kit, dose)],
          ),
          TrainingProfile(asymmetry: tight == null ? const {} : {dir: tight}),
        )!
        .steps
        .single;
  }

  group('F7 countedSetsOn: the sets each side really plays', () {
    for (final sets in [2, 3]) {
      test('F7 unsided h-squat × $sets 组: $sets sets, never a tight extra', () {
        final s = planner
            .singlePlan(
              content.drill('h-squat'),
              LibraryDose(reps: 1, sets: sets),
              const TrainingProfile(),
            )!
            .steps
            .single;
        expect(s.countedSetsOn(null), sets);
        final work = script().phases([s]).where((p) => p.isWork).single;
        expect(SessionScript.setsOf(work, s), sets);
      });
    }

    test('F7 sided glute-max-A × 2 组, no tight side: 2 / 2', () {
      final s = groupStep('glute-max-A', const LibraryDose(reps: 3, sets: 2));
      expect(s.countedSetsOn(HipSide.right), 2);
      expect(s.countedSetsOn(HipSide.left), 2);
    });

    test('F7 sided glute-max-A × 3 组, left tight: right 3 / left 4 (+1 组), '
        'same as the script on each work phase', () {
      final s = groupStep(
        'glute-max-A',
        const LibraryDose(reps: 3, sets: 3),
        tight: HipSide.left,
      );
      expect(s.countedSetsOn(HipSide.right), 3);
      expect(s.countedSetsOn(HipSide.left), 4);
      for (final p in script().phases([s]).where((p) => p.isWork)) {
        expect(SessionScript.setsOf(p, s), s.countedSetsOn(p.side));
      }
    });

    test('F7 built-in routine tight side keeps the old 1 → 2 sets', () {
      final tight = [
        for (final routine in content.routines.where((r) => !r.micro))
          ...planner
              .planFor(
                [routine],
                TrainingProfile(
                  asymmetry: {
                    for (final st in routine.steps)
                      content.drill(st.drillId).directions.first: HipSide.left,
                  },
                ),
              )
              .steps
              .where(
                (s) =>
                    s.extraSide == HipSide.left &&
                    (content.kit(s.drill.id)?.kind.counted ?? false),
              ),
      ];
      expect(tight, isNotEmpty);
      for (final s in tight) {
        expect(s.sets, 1);
        expect(s.countedSetsOn(HipSide.right), 1);
        expect(s.countedSetsOn(HipSide.left), 2);
      }
    });
  });

  test('F7 pain guard ≡ script: noFullRep exactly when some halved work '
      'phase would play no cues', () {
    final s0 = script();
    var skipped = 0, kept = 0;
    for (final id in ['h-squat', 'glute-max-A']) {
      final kit = content.kit(id)!;
      for (var reps = 1; reps <= 6; reps++) {
        for (var sets = 1; sets <= 3; sets++) {
          for (final tight in [null, HipSide.left, HipSide.right]) {
            final s = groupStep(
              id,
              LibraryDose(reps: reps, sets: sets),
              tight: tight,
            );
            final half = s.copyWith(seconds: (s.seconds / 2).ceil());
            final silent = s0
                .phases([half])
                .where((p) => p.isWork)
                .any((p) => s0.cues(p, [half]).isEmpty);
            expect(
              SessionScript.noFullRep(half, kit),
              silent,
              reason: '$id reps $reps sets $sets tight $tight',
            );
            silent ? skipped++ : kept++;
          }
        }
      }
    }
    expect(skipped, greaterThan(0));
    expect(kept, greaterThan(0));
  });
}
