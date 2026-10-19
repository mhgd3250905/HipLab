// PR #22 review (2026-10-19, 合并审核：需要修改) domain regressions:
// F2 copied routine keeps its hold override and pace, F5 the tight side of
// a 1-set custom hold is a real 2nd set (5 s gap) while built-in routines
// keep the longer continuous hold, F6 an unsided hold never announces a
// tight-side extra set.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hiplab/hip/domain/hip_assessment.dart';
import 'package:hiplab/hip/domain/hip_library.dart';
import 'package:hiplab/hip/domain/hip_models.dart';
import 'package:hiplab/hip/domain/hip_session.dart';
import 'package:hiplab/hip/voice/session_engine.dart';
import 'package:hiplab/hip/voice/session_script.dart';

import 'hip_domain_test.dart' show loadContent;
import 'hip_voice_test.dart' show loadVoiceLibrary;

void main() {
  final content = loadContent();
  final planner = TrainingPlanner(content);
  final lib = loadVoiceLibrary();
  ActionKit kit(String id) => content.kit(id)!;
  SessionScript script() => SessionScript(
    lib: lib,
    lang: 'zh',
    routineIds: const [],
    restSeconds: 15,
    kits: content.kits,
  );

  group('F2 copyRoutine keeps the hold override', () {
    // 等级 3、舞者解锁、abduction = 2: F plays h-sumo-pry as authored.
    const profile = TrainingProfile(
      level: 3,
      dancerUnlocked: true,
      directionScores: {HipDirection.abduction: 2},
    );
    CustomRoutine copyF() => copyRoutine(
      content.routine('F'),
      content,
      id: 'f-copy',
      name: 'F（我的）',
      at: DateTime(2026, 10, 19),
    );

    test('F2 copied F: h-sumo-pry hold stays 15 s and the step 60 s', () {
      final authored = content
          .routine('F')
          .steps
          .firstWhere((s) => s.drillId == 'h-sumo-pry');
      expect(authored.kit.holdSeconds, 15);
      expect(authored.seconds, 60);
      final routineStep = planner
          .routinePlan(content.routine('F'), profile)!
          .steps
          .firstWhere((s) => s.drill.id == 'h-sumo-pry');
      expect(routineStep.seconds, 60);

      final g = copyF();
      final step = g.steps.firstWhere((s) => s.kitId == 'h-sumo-pry');
      expect(step.holdSeconds, 15);
      final planStep = planner
          .customPlan(g, profile)!
          .steps
          .firstWhere((s) => s.drill.id == 'h-sumo-pry');
      expect(planStep.kitDose.holdSeconds, 15);
      expect(planStep.kitDose.reps, 3);
      expect(planStep.seconds, 60);
      expect(planStep.seconds, routineStep.seconds);
      expect(planStep.dose, '3 次 × 停 15 秒');
      // The voice holds 15 s on every rep.
      final s = script();
      final work = s.phases([planStep]).firstWhere((p) => p.isWork);
      expect(work.seconds, 60);
      final plan = kit(
        'h-sumo-pry',
      ).repPlan(planStep.kitDose, work.seconds, sets: 1);
      expect(plan.phases.firstWhere((p) => p.id == 'hold').seconds, 15);
    });

    test('F2 holdSeconds survives custom_routines v1 round trip; old v1 '
        'data without it reads as the kit default', () {
      final g = copyF();
      final json = jsonDecode(jsonEncode(CustomRoutinesCodec.encode([g])));
      final back = CustomRoutinesCodec.decode(json, content).single;
      expect(back.steps, g.steps);
      final sumo = back.steps.firstWhere((s) => s.kitId == 'h-sumo-pry');
      expect(sumo.holdSeconds, 15);
      expect(sumo.toJson()['holdSeconds'], 15);
      // v1 written before F2: no holdSeconds / paceSeconds keys.
      final old = CustomRoutinesCodec.decode({
        'v': 1,
        'items': [
          {
            'id': 'old',
            'name': '旧组',
            'restSeconds': 15,
            'steps': [
              {'kitId': 'h-sumo-pry'},
              {'kitId': 'h-sumo-pry', 'reps': 4},
            ],
          },
        ],
      }, content).single;
      expect(old.steps.first.holdSeconds, isNull);
      expect(old.steps.first.paceSeconds, isNull);
      expect(old.steps.first.toJson().containsKey('holdSeconds'), isFalse);
      expect(
        old.steps.first.dose(kit('h-sumo-pry')).holdSeconds,
        isNull,
        reason: 'null = the kit default hold',
      );
      // Out-of-range stored holds are clamped, not trusted.
      final bad = CustomRoutinesCodec.decode({
        'v': 1,
        'items': [
          {
            'id': 'bad',
            'name': 'x',
            'steps': [
              {'kitId': 'h-sumo-pry', 'holdSeconds': 999},
              {'kitId': 'h-sumo-pry', 'holdSeconds': -3},
              {'kitId': 's-pigeon', 'holdSeconds': 20},
            ],
          },
        ],
      }, content).single;
      expect(bad.steps[0].holdSeconds, LibraryDose.maxHold);
      expect(bad.steps[1].holdSeconds, isNull);
      expect(bad.steps[2].holdSeconds, isNull, reason: 'not a rep_hold kit');
    });

    test('F2 changing reps keeps the hold, drops the pace; 恢复默认 clears '
        'both', () {
      final k = kit('h-sumo-pry');
      final copied = copyF().steps.firstWhere((s) => s.kitId == 'h-sumo-pry');
      final d = copied.dose(k);
      expect(d.holdSeconds, 15);
      // The dose panel's reps stepper (library_widgets LibDosePanel).
      final more = CustomStep.fromDose(
        k,
        LibraryDose(reps: 4, sets: d.sets, holdSeconds: d.holdSeconds),
      );
      expect(more.holdSeconds, 15);
      expect(more.paceSeconds, isNull);
      expect(
        DoseRules.stepSeconds(k, more.dose(k), single: false),
        (k.lead + 4 * k.cycleFor(const KitDose(holdSeconds: 15)) - 1e-9).ceil(),
      );
      final reset = CustomStep.fromDose(k, DoseRules.kitDefault(k));
      expect(reset.holdSeconds, isNull);
      expect(reset.paceSeconds, isNull);
      expect(reset.adjusted, isFalse);
    });
  });

  group('F5 tight side of a hold uses its real set count', () {
    final pigeon = kit('s-pigeon');
    final dir = content.drill('s-pigeon').directions.first;

    test('F5 custom 鸽子式 35 s × 1 + tight set: 40 s extra, 2 sets with a '
        '5 s gap (慢慢还原 → 5 秒 → 再来一组)', () {
      final p = TrainingProfile(asymmetry: {dir: HipSide.left});
      final step = planner
          .customPlan(
            CustomRoutine(
              id: 'c',
              name: 'x',
              steps: [
                CustomStep.fromDose(pigeon, const LibraryDose(seconds: 35)),
              ],
            ),
            p,
          )!
          .steps
          .single;
      expect(step.extraSide, HipSide.left);
      expect(step.extraSet, isTrue);
      expect(step.extraSeconds, 40);
      expect(step.segments, [(HipSide.right, 35), (HipSide.left, 75)]);
      final s = script();
      final works = s.phases([step]).where((x) => x.isWork).toList();
      final right = works.first, left = works.last;
      expect(SessionScript.holdSetsOf(right, step), 1);
      expect(SessionScript.holdSetsOf(left, step), 2);
      final cues = s.cues(left, [step]);
      final end = cues.where((c) => c.clips.contains(pigeon.voice.end));
      expect(end.single.at, closeTo(35, .01));
      final again = cues.where((c) => c.clips.contains(pigeon.voice.nextSet));
      expect(again.single.at, closeTo(40, .01));
      expect(cues.where((c) => c.clips.contains('n.1')).length, 2);
      expect(
        cues.where((c) => c.clips.contains('cue.extra_left')).length,
        1,
        reason: 'said once, on the first set',
      );
      // The right side stays one plain hold.
      final rc = s.cues(right, [step]);
      expect(rc.where((c) => c.clips.contains(pigeon.voice.nextSet)), isEmpty);
      expect(
        rc.where((c) => c.clips.any((x) => x.startsWith('cue.extra'))),
        isEmpty,
      );
    });

    test(
      'F5 extra-set budget: holds always add the 5 s gap, counted never',
      () {
        expect(
          DoseRules.extraSetSeconds(
            pigeon,
            const LibraryDose(seconds: 35),
            single: false,
          ),
          40,
        );
        expect(
          DoseRules.extraSetSeconds(
            pigeon,
            const LibraryDose(seconds: 35, sets: 2),
            single: false,
          ),
          40,
        );
        final glute = kit('glute-max-A');
        expect(
          DoseRules.extraSetSeconds(
            glute,
            const LibraryDose(reps: 6),
            single: false,
          ),
          DoseRules.setSeconds(
            glute,
            const LibraryDose(reps: 6),
            single: false,
          ),
        );
      },
    );

    test('F5 built-in routine keeps the continuous longer hold on the tight '
        'side (legacy D-01, extraSet false)', () {
      // A sided hold step in a built-in routine.
      late HipRoutine routine;
      late HipRoutineStep authored;
      outer:
      for (final r in content.routines) {
        for (final st in r.steps) {
          final k = content.kit(st.drillId);
          final d = content.drills[st.drillId];
          if (k != null &&
              !k.kind.counted &&
              st.sided &&
              d != null &&
              !d.advanced &&
              d.alternative == null) {
            routine = r;
            authored = st;
            break outer;
          }
        }
      }
      final d = content.drill(authored.drillId);
      final p = TrainingProfile(
        level: 3,
        dancerUnlocked: true,
        asymmetry: {d.directions.first: HipSide.right},
      );
      final step = planner
          .planFor([routine], p)
          .steps
          .firstWhere((s) => s.drill.id == authored.drillId);
      expect(step.extraSide, HipSide.right);
      expect(step.extraSet, isFalse);
      final base = step.seconds - step.extraSeconds;
      expect(step.extraSeconds, base ~/ 2);
      final s = script();
      final tight = s
          .phases([step])
          .firstWhere((x) => x.isWork && x.side == HipSide.right);
      expect(SessionScript.holdSetsOf(tight, step), 1);
      final cues = s.cues(tight, [step]);
      final k = kit(authored.drillId);
      expect(cues.where((c) => c.clips.contains(k.voice.nextSet)), isEmpty);
      expect(cues.where((c) => c.clips.contains('n.1')).length, 1);
      expect(cues.where((c) => c.clips.contains('cue.extra_right')).length, 1);
    });
  });

  group('F6 unsided hold never says a tight-side extra set', () {
    test('F6 蝴蝶式 20 s × 3, pain halved to 35 s: continuous fallback, no '
        'cue.extra_left', () {
      final butterfly = kit('s-butterfly');
      expect(butterfly.sided, isFalse);
      // Even with an asymmetry on its direction: unsided → no extra side.
      final p = TrainingProfile(
        asymmetry: {
          content.drill('s-butterfly').directions.first: HipSide.left,
        },
      );
      final full = planner
          .customPlan(
            CustomRoutine(
              id: 'b',
              name: 'x',
              steps: [
                CustomStep.fromDose(
                  butterfly,
                  const LibraryDose(seconds: 20, sets: 3),
                ),
              ],
            ),
            p,
          )!
          .steps
          .single;
      expect(full.extraSide, isNull);
      expect(full.seconds, 70);
      // The pain ladder's 幅度小一点 halves the step (SessionPainLadder).
      final halved = full.copyWith(seconds: 35);
      final s = script();
      final work = s.phases([halved]).firstWhere((x) => x.isWork);
      expect(work.side, isNull);
      expect(work.seconds, 35);
      final cues = s.cues(work, [halved]);
      final clips = [for (final c in cues) ...c.clips];
      expect(clips, isNot(contains('cue.extra_left')));
      expect(clips, isNot(contains('cue.extra_right')));
      // < 10 s a set → one continuous hold (one countdown, no 再来一组).
      expect(clips, isNot(contains(butterfly.voice.nextSet)));
      expect(cues.where((c) => c.clips.contains('n.1')).length, 1);
      // Unhalved: 3 real sets, still no extra-side cue.
      final fc = s.cues(s.phases([full]).firstWhere((x) => x.isWork), [full]);
      expect(
        fc.where((c) => c.clips.contains(butterfly.voice.nextSet)).length,
        2,
      );
      expect(
        fc.where((c) => c.clips.any((x) => x.startsWith('cue.extra'))),
        isEmpty,
      );
    });

    test('F6 normal multi-set sided hold: the non-tight side has no extra '
        'cue', () {
      final pigeon = kit('s-pigeon');
      final step = planner
          .customPlan(
            CustomRoutine(
              id: 'p',
              name: 'x',
              steps: [
                CustomStep.fromDose(
                  pigeon,
                  const LibraryDose(seconds: 30, sets: 2),
                ),
              ],
            ),
            const TrainingProfile(),
          )!
          .steps
          .single;
      expect(step.extraSide, isNull);
      final s = script();
      for (final w in s.phases([step]).where((x) => x.isWork)) {
        final cues = s.cues(w, [step]);
        expect(
          cues.where((c) => c.clips.any((x) => x.startsWith('cue.extra'))),
          isEmpty,
          reason: '${w.side}',
        );
        expect(
          cues.where((c) => c.clips.contains(pigeon.voice.nextSet)).length,
          1,
        );
      }
    });
  });

  test('session engine still runs a copied F end to end', () {
    final g = copyRoutine(
      content.routine('F'),
      content,
      id: 'f',
      name: 'F',
      at: DateTime(2026, 10, 19),
    );
    final plan = planner.customPlan(
      g,
      const TrainingProfile(level: 3, dancerUnlocked: true),
    )!;
    final engine = SessionEngine(script: script(), steps: plan.steps);
    var t = 0.0;
    while (!engine.done && t < 3600) {
      engine.update(t);
      t += .5;
    }
    expect(engine.done, isTrue);
  });
}
