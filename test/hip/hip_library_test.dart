// 练习库 domain (docs/training-library-2026-10-19.md): library inclusion,
// dose rules (拍板 2), custom_routines v1, streak (拍板 3), safety / lock /
// advanced rules (拍板 4) and sets in the voice script.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hiplab/hip/control/hip_store.dart';
import 'package:hiplab/hip/domain/hip_assessment.dart';
import 'package:hiplab/hip/domain/hip_library.dart';
import 'package:hiplab/hip/domain/hip_models.dart';
import 'package:hiplab/hip/domain/hip_pain.dart';
import 'package:hiplab/hip/domain/hip_progress.dart';
import 'package:hiplab/hip/domain/hip_session.dart';
import 'package:hiplab/hip/ui/library/lib_text.dart';
import 'package:hiplab/hip/voice/session_script.dart';

import 'hip_domain_test.dart' show MemoryStorage, loadContent;
import 'hip_voice_test.dart' show loadVoiceLibrary;

void main() {
  final content = loadContent();
  final planner = TrainingPlanner(content);
  ActionKit kit(String id) => content.kit(id)!;

  group('动作大全', () {
    test('45 drills: clip + action kit, n-thomas-test excluded', () {
      final lib = libraryDrills(content);
      expect(lib.length, 45);
      expect(lib.map((d) => d.id), isNot(contains('n-thomas-test')));
      expect(lib.map((d) => d.id), contains('w-feet-on-chair-bridge'));
      for (final d in lib) {
        expect(d.mediaStatus, HipMediaStatus.video, reason: d.id);
        expect(d.video, isNotNull, reason: d.id);
        expect(content.kit(d.id), isNotNull, reason: d.id);
      }
      expect(inLibrary(content, 'n-thomas-test'), isFalse);
      expect(inLibrary(content, 'no-such-drill'), isFalse);
    });
  });

  group('剂量 (拍板 2)', () {
    test('单练 default: timed 60 s per side, counted 10 per side, 1 set', () {
      // hold, sided
      expect(
        DoseRules.singleDefault(kit('s-pigeon')),
        const LibraryDose(seconds: 60),
      );
      expect(
        DoseRules.stepSeconds(
          kit('s-pigeon'),
          const LibraryDose(seconds: 60),
          single: true,
        ),
        120,
      );
      // hold, unsided
      expect(
        DoseRules.stepSeconds(
          kit('s-butterfly'),
          const LibraryDose(seconds: 60),
          single: true,
        ),
        60,
      );
      // counted, sided: 10 reps each side at the kit's pace
      final glute = kit('glute-max-A');
      expect(DoseRules.singleDefault(glute), const LibraryDose(reps: 10));
      final side = (glute.lead + 10 * glute.cycleFor(const KitDose()) - 1e-9)
          .ceil();
      expect(
        DoseRules.stepSeconds(glute, const LibraryDose(reps: 10), single: true),
        side * 2,
      );
      expect(
        doseText(glute, const LibraryDose(reps: 10), single: true),
        '每侧 10 次',
      );
      expect(
        doseText(kit('s-pigeon'), const LibraryDose(seconds: 60), single: true),
        '每侧 60 秒',
      );
      expect(
        doseText(
          kit('s-butterfly'),
          const LibraryDose(seconds: 60, sets: 2),
          single: true,
        ),
        '停 60 秒 × 2 组',
      );
    });

    test('单练: breath and hold-rep rhythms are timed, reps fill the time', () {
      for (final id in ['h-knee-hug', 'h-sumo-pry', 'n-seated-knee-lift']) {
        final k = kit(id);
        expect(DoseRules.unit(k, single: true), DoseUnit.seconds, reason: id);
        expect(DoseRules.singleDefault(k), const LibraryDose(seconds: 60));
        final kd = DoseRules.kitDose(
          k,
          const LibraryDose(seconds: 60),
          single: true,
        );
        expect(kd.reps, greaterThanOrEqualTo(1));
        // Every rep fits inside the 60 s and the side lasts exactly 60 s.
        expect(
          k.lead + kd.reps! * k.cycleFor(const KitDose()),
          lessThanOrEqualTo(60),
        );
        expect(
          DoseRules.setSeconds(k, const LibraryDose(seconds: 60), single: true),
          60,
        );
      }
      // In a custom group the same kits keep counting reps (kit defaults).
      expect(DoseRules.unit(kit('h-knee-hug'), single: false), DoseUnit.reps);
    });

    test('单练 ranges: reps 1–20, seconds 30–120 in 5 s, sets 1–3', () {
      final r = DoseRules.range(kit('glute-max-A'), single: true);
      expect([r.min, r.max, r.step], [1, 20, 1]);
      final s = DoseRules.range(kit('s-pigeon'), single: true);
      expect([s.min, s.max, s.step], [30, 120, 5]);
      expect(DoseRules.setRange.clamp(5), 3);
      expect(DoseRules.setRange.clamp(0), 1);
    });

    test(
      'group steps: kit defaults, reps 1–2×, seconds ½–2× by 5 s, min 10',
      () {
        expect(
          DoseRules.kitDefault(kit('s-pigeon')),
          const LibraryDose(seconds: 35),
        );
        final s = DoseRules.range(kit('s-pigeon'), single: false);
        expect([s.min, s.max, s.step], [20, 70, 5]);
        final fig4 = DoseRules.range(kit('o-seated-fig4'), single: false); // 25
        expect([fig4.min, fig4.max], [15, 50]);
        final reps = DoseRules.range(kit('glute-max-A'), single: false); // 6
        expect([reps.min, reps.max], [1, 12]);
        // Out of range → clamped; off-grid seconds snap to 5 s.
        expect(
          DoseRules.clamp(
            kit('s-pigeon'),
            const LibraryDose(seconds: 7, sets: 9),
            single: false,
          ),
          const LibraryDose(seconds: 20, sets: 3),
        );
        expect(
          DoseRules.clamp(
            kit('s-pigeon'),
            const LibraryDose(seconds: 33),
            single: false,
          ),
          const LibraryDose(seconds: 35),
        );
        expect(
          DoseRules.clamp(
            kit('glute-max-A'),
            const LibraryDose(reps: 40),
            single: false,
          ),
          const LibraryDose(reps: 12),
        );
        for (final k in libraryDrills(content).map((d) => kit(d.id))) {
          final r = DoseRules.range(k, single: false);
          expect(r.min, greaterThanOrEqualTo(1), reason: k.id);
          expect(
            r.contains(r.base),
            isTrue,
            reason: '${k.id} default in range',
          );
          if (DoseRules.unit(k, single: false) == DoseUnit.seconds) {
            expect(r.min, greaterThanOrEqualTo(10), reason: k.id);
            expect(r.min % 5, 0, reason: k.id);
          }
        }
      },
    );

    test('sets multiply time; holds rest 5 s between sets', () {
      final pigeon = kit('s-pigeon');
      const one = LibraryDose(seconds: 35);
      const three = LibraryDose(seconds: 35, sets: 3);
      expect(DoseRules.sideSeconds(pigeon, one, single: false), 35);
      expect(
        DoseRules.sideSeconds(pigeon, three, single: false),
        35 * 3 + 2 * 5,
      );
      final glute = kit('glute-max-A');
      final per = DoseRules.setSeconds(
        glute,
        const LibraryDose(reps: 6),
        single: false,
      );
      expect(
        DoseRules.sideSeconds(
          glute,
          const LibraryDose(reps: 6, sets: 2),
          single: false,
        ),
        per * 2,
      );
    });
  });

  group('custom_routines v1', () {
    test('only overrides are stored; round trip', () {
      final r = CustomRoutine(
        id: 'c_20261019_8f3a',
        name: '下班腿后侧',
        restSeconds: 15,
        createdAt: DateTime(2026, 10, 19, 20, 10),
        updatedAt: DateTime(2026, 10, 19, 20, 14),
        steps: [
          CustomStep.fromDose(
            kit('n-pelvis-circle'),
            DoseRules.kitDefault(kit('n-pelvis-circle')),
          ),
          CustomStep.fromDose(
            kit('o-seated-ham'),
            const LibraryDose(seconds: 45),
          ),
          CustomStep.fromDose(
            kit('n-leg-circles'),
            const LibraryDose(reps: 4, sets: 2),
          ),
        ],
      );
      final j = jsonDecode(jsonEncode(CustomRoutinesCodec.encode([r]))) as Map;
      expect(j['v'], 1);
      final steps = (j['items'] as List).single['steps'] as List;
      expect(steps[0], {'kitId': 'n-pelvis-circle'});
      expect(steps[1], {'kitId': 'o-seated-ham', 'seconds': 45});
      expect(steps[2], {'kitId': 'n-leg-circles', 'sets': 2});
      final back = CustomRoutinesCodec.decode(j, content).single;
      expect(back.id, r.id);
      expect(back.name, r.name);
      expect(back.restSeconds, 15);
      expect(back.steps, r.steps);
      expect(back.createdAt, r.createdAt);
      expect(back.removed, 0);
      expect(back.seconds(content), r.seconds(content));
    });

    test(
      'load-time validation: delisted dropped, clamp, rest, 20 steps, name',
      () {
        final j = {
          'v': 1,
          'items': [
            {
              'id': 'c1',
              'name': '一二三四五六七八九十一二三四',
              'restSeconds': 17,
              'steps': [
                {'kitId': 'n-thomas-test'},
                {'kitId': 'gone-from-pack'},
                {'kitId': 's-pigeon', 'seconds': 500, 'sets': 7},
                {'kitId': 'glute-max-A', 'reps': 0},
                for (var i = 0; i < 25; i++) {'kitId': 'h-squat'},
              ],
            },
            {'id': 'c1', 'name': 'dup'},
            'junk',
            {'name': 'no id'},
          ],
        };
        final list = CustomRoutinesCodec.decode(j, content);
        expect(list.length, 1);
        final g = list.single;
        expect(g.removed, 2);
        expect(g.name.runes.length, CustomRoutine.maxName);
        expect(g.restSeconds, 15);
        expect(g.steps.length, CustomRoutine.maxSteps);
        expect(g.steps[0], const CustomStep('s-pigeon', seconds: 70, sets: 3));
        expect(g.steps[1], const CustomStep('glute-max-A', reps: 1));
        expect(
          CustomRoutinesCodec.decode({'v': 2, 'items': []}, content),
          isEmpty,
        );
        expect(CustomRoutinesCodec.decode(null, content), isEmpty);
      },
    );

    test('store persists groups and history under hiplab.state.v1', () async {
      final storage = MemoryStorage();
      final store = HipStore(
        content: content,
        storage: storage,
        clock: () => DateTime(2026, 10, 19, 20),
      );
      await store.initialize();
      final id = store.newCustomId();
      expect(id, matches(RegExp(r'^c_20261019_[0-9a-f]{4}$')));
      expect(store.nextCustomName(), '我的训练组 1');
      await store.saveCustomRoutine(
        CustomRoutine(
          id: id,
          name: '  早上醒髋  ',
          restSeconds: 10,
          steps: const [
            CustomStep('n-leg-circles'),
            CustomStep('h-squat', reps: 10),
          ],
        ),
      );
      expect(storage.values.keys, [HipStore.storageKey]);
      final again = HipStore(
        content: content,
        storage: storage,
        clock: () => DateTime(2026, 10, 19, 21),
      );
      await again.initialize();
      final g = again.customRoutines.single;
      expect(g.name, '早上醒髋');
      expect(g.restSeconds, 10);
      expect(g.steps.length, 2);
      expect(g.createdAt, DateTime(2026, 10, 19, 20));
      expect(again.nextCustomName(), '我的训练组 2');
      await again.deleteCustomRoutine(id);
      expect(again.customRoutines, isEmpty);
    });

    test('copy from a routine keeps the authored steps (no level swap)', () {
      final f = content.routine('F');
      final g = copyRoutine(
        f,
        content,
        id: 'c',
        name: 'F（我的）',
        at: DateTime(2026, 10, 19),
      );
      expect(g.fromRoutine, 'F');
      expect(g.steps.map((s) => s.kitId), [
        for (final s in f.steps)
          if (inLibrary(content, s.drillId)) s.drillId,
      ]);
      expect(g.steps.length, lessThanOrEqualTo(CustomRoutine.maxSteps));
    });
  });

  group('连续天数 (拍板 3)', () {
    Future<HipStore> fresh() async {
      final s = HipStore(
        content: content,
        storage: MemoryStorage(),
        clock: () => DateTime(2026, 10, 19, 9),
      );
      await s.initialize();
      return s;
    }

    test('单练 is logged but never counts for the streak', () async {
      final store = await fresh();
      final plan = planner.singlePlan(
        content.drill('s-figure4'),
        const LibraryDose(seconds: 60),
        store.profile,
      )!;
      expect(plan.source, PlanSource.single);
      await store.completeSession(SessionPainLadder(content), plan: plan);
      expect(store.doneDays, isEmpty);
      expect(store.streak, 0);
      final r = store.sessions.single;
      expect(
        [r.source, r.completed, r.refId, r.title],
        [PlanSource.single, true, 's-figure4', content.drill('s-figure4').name],
      );
      // A 单练 left before the end: logged as unfinished, still no streak.
      await store.recordLadder(SessionPainLadder(content), plan: plan);
      expect(store.sessions.last.completed, isFalse);
      expect(store.doneDays, isEmpty);
    });

    test('套路 and 我的训练组 count as before', () async {
      final store = await fresh();
      final routine = planner.routinePlan(content.routine('A'), store.profile)!;
      await store.completeSession(SessionPainLadder(content), plan: routine);
      expect(store.doneDays, {dayKey(DateTime(2026, 10, 19))});
      final store2 = await fresh();
      final custom = planner.customPlan(
        const CustomRoutine(id: 'c', name: 'x', steps: [CustomStep('h-squat')]),
        store2.profile,
      )!;
      await store2.completeSession(SessionPainLadder(content), plan: custom);
      expect(store2.streak, 1);
      expect(store2.sessions.single.source, PlanSource.custom);
    });

    test('history keeps the last 365 sessions', () async {
      final store = await fresh();
      final plan = planner.singlePlan(
        content.drill('s-figure4'),
        const LibraryDose(seconds: 60),
        store.profile,
      )!;
      for (var i = 0; i < SessionRecord.keep + 5; i++) {
        await store.completeSession(SessionPainLadder(content), plan: plan);
      }
      expect(store.sessions.length, SessionRecord.keep);
    });
  });

  group('安全规则', () {
    const base = TrainingProfile();

    test('blocked: no single, routine or custom plan', () {
      const blocked = TrainingProfile(blocked: true);
      expect(
        planner.singlePlan(
          content.drill('s-figure4'),
          const LibraryDose(seconds: 60),
          blocked,
        ),
        isNull,
      );
      expect(planner.routinePlan(content.routine('A'), blocked), isNull);
      expect(
        planner.customPlan(
          const CustomRoutine(
            id: 'c',
            name: 'x',
            steps: [CustomStep('h-squat')],
          ),
          blocked,
        ),
        isNull,
      );
    });

    test(
      'relax-only direction: non-relax single refused, relax allowed, group skips',
      () {
        const locked = TrainingProfile(
          lockedDirections: {HipDirection.extension},
        );
        // s-kneel-hipflex: extension, flexibility → refused
        expect(
          TrainingPlanner.lockedOut(content.drill('s-kneel-hipflex'), locked),
          isTrue,
        );
        expect(
          planner.singlePlan(
            content.drill('s-kneel-hipflex'),
            const LibraryDose(seconds: 60),
            locked,
          ),
          isNull,
        );
        // n-pelvis-circle: flexion first, relax → fine anyway; s-figure4 other direction
        expect(
          planner.singlePlan(
            content.drill('s-figure4'),
            const LibraryDose(seconds: 60),
            locked,
          ),
          isNotNull,
        );
        const g = CustomRoutine(
          id: 'c',
          name: 'x',
          steps: [
            CustomStep('s-kneel-hipflex'),
            CustomStep('o-stand-lunge'),
            CustomStep('s-figure4'),
          ],
        );
        expect(planner.customSkipped(g, locked).length, 2);
        expect(planner.customPlan(g, locked)!.steps.map((s) => s.drill.id), [
          's-figure4',
        ]);
        expect(planner.customPlan(g, base)!.steps.length, 3);
      },
    );

    test('level 1 + advanced: hint only, never swapped (拍板 4)', () {
      final adv = content.drill('h-9090-liftoff');
      expect(adv.advanced, isTrue);
      expect(planner.needsEasier(adv, base), isTrue);
      final single = planner.singlePlan(
        adv,
        const LibraryDose(reps: 10),
        base,
      )!;
      expect(single.steps.single.drill.id, 'h-9090-liftoff');
      expect(single.steps.single.replaced, isNull);
      final custom = planner.customPlan(
        const CustomRoutine(
          id: 'c',
          name: 'x',
          steps: [CustomStep('h-9090-liftoff')],
        ),
        base,
      )!;
      expect(custom.steps.single.drill.id, 'h-9090-liftoff');
      // The built-in routines still swap at level 1.
      final f = planner.planFor([content.routine('F')], base);
      expect(f.steps.any((s) => s.replaced != null), isTrue);
      expect(
        planner.needsEasier(adv, const TrainingProfile(level: 2)),
        isFalse,
      );
    });

    test('「最近疼过」: any 疼 in 7 days; does not lock', () {
      final now = DateTime(2026, 10, 19, 9);
      final h = PainHistory([
        PainEvent(
          now.subtract(const Duration(days: 3)),
          HipDirection.extension,
          'pain',
        ),
        PainEvent(
          now.subtract(const Duration(days: 9)),
          HipDirection.flexion,
          'pain',
        ),
        PainEvent(
          now.subtract(const Duration(days: 2)),
          HipDirection.abduction,
          'pain',
        ),
        PainEvent(
          now.subtract(const Duration(days: 1)),
          HipDirection.abduction,
          'pain',
        ),
      ]);
      expect(h.recentPain(now), {
        HipDirection.extension,
        HipDirection.abduction,
      });
      expect(h.lockedUntil(now), isEmpty);
    });

    test('store records every 疼 as a pain event', () async {
      final store = HipStore(
        content: content,
        storage: MemoryStorage(),
        clock: () => DateTime(2026, 10, 19, 9),
      );
      await store.initialize();
      await store.recordPain(HipDirection.extension);
      expect(store.painEvents.single.type, 'pain');
      expect(store.recentPainDirections, {HipDirection.extension});
      expect(store.lockedDirections, isEmpty);
    });
  });

  group('sets in the session', () {
    final lib = loadVoiceLibrary();
    SessionScript script() => SessionScript(
      lib: lib,
      lang: 'zh',
      routineIds: const [],
      restSeconds: 15,
      kits: content.kits,
    );

    test('counted step with 2 sets: two rep plans, 再来一组 between', () {
      final plan = planner.singlePlan(
        content.drill('h-squat'),
        const LibraryDose(reps: 10, sets: 2),
        base0,
      )!;
      final step = plan.steps.single;
      expect(step.sets, 2);
      final s = script();
      final phases = s.phases(plan.steps);
      final work = phases.firstWhere((p) => p.isWork);
      expect(SessionScript.setsOf(work, step), 2);
      final cues = s.cues(work, plan.steps);
      final again = cues
          .where((c) => c.clips.contains(kit('h-squat').voice.nextSet))
          .toList();
      expect(again.length, 1);
      expect(again.single.at, closeTo(work.seconds / 2, .01));
      // 10 counts per set, the last of the 2nd set is 最后一次.
      expect(
        cues
            .where((c) => c.clips.contains(kit('h-squat').voice.lastRep))
            .length,
        1,
      );
    });

    test('hold with 2 sets: 慢慢还原, 5 s, 再来一组; each set counts down', () {
      final pigeon = kit('s-pigeon');
      final plan = planner.customPlan(
        CustomRoutine(
          id: 'c',
          name: 'x',
          steps: [
            CustomStep.fromDose(
              pigeon,
              const LibraryDose(seconds: 40, sets: 2),
            ),
          ],
        ),
        base0,
      )!;
      final s = script();
      final work = s.phases(plan.steps).firstWhere((p) => p.isWork);
      expect(work.seconds, 85); // 40 + 5 + 40 per side
      final cues = s.cues(work, plan.steps);
      final end = cues.where((c) => c.clips.contains(pigeon.voice.end)).single;
      expect(end.at, closeTo(40, .01));
      final again = cues
          .where((c) => c.clips.contains(pigeon.voice.nextSet))
          .single;
      expect(again.at, closeTo(45, .01));
      expect(cues.where((c) => c.clips.contains('n.1')).length, 2);
    });

    test('tight side gets one more set in a custom group', () {
      const p = TrainingProfile(
        asymmetry: {HipDirection.extension: HipSide.left},
      );
      final g = CustomRoutine(
        id: 'c',
        name: 'x',
        steps: [
          CustomStep.fromDose(kit('glute-max-A'), const LibraryDose(reps: 6)),
        ],
      );
      final step = planner.customPlan(g, p)!.steps.single;
      expect(step.extraSide, HipSide.left);
      final per = DoseRules.setSeconds(
        kit('glute-max-A'),
        const LibraryDose(reps: 6),
        single: false,
      );
      expect(step.segments, [(HipSide.right, per), (HipSide.left, per * 2)]);
      final s = script();
      final left = s.phases([step]).where((x) => x.isWork).last;
      expect(SessionScript.setsOf(left, step), 2);
    });

    test('counts above 10 say only the phase word (no missing clip)', () {
      final plan = planner.singlePlan(
        content.drill('h-squat'),
        const LibraryDose(reps: 12),
        base0,
      )!;
      final s = script();
      final work = s.phases(plan.steps).firstWhere((p) => p.isWork);
      for (final c in s.cues(work, plan.steps)) {
        for (final clip in c.voiceClips) {
          expect(lib.has(clip), isTrue, reason: clip);
        }
      }
    });

    test('library hold preview says 每侧 + seconds from stock clips', () {
      final plan = planner.singlePlan(
        content.drill('s-pigeon'),
        const LibraryDose(seconds: 60),
        base0,
      )!;
      final s = script();
      final prep = s.phases(plan.steps).first;
      final clips = [for (final c in s.cues(prep, plan.steps)) ...c.clips];
      expect(
        clips,
        containsAllInOrder(['drill.s-pigeon', 'p.each_side', 'sec.60']),
      );
    });
  });

  test('中英双语: English strings and dose texts carry no Chinese', () {
    final cjk = RegExp(r'[\u4e00-\u9fff]');
    const en = LibText.en;
    final lines = [
      en.practice,
      en.segActions,
      en.segRoutines,
      en.segMine,
      en.myHip,
      en.checkTitle,
      en.checkStart,
      en.checkRetest,
      en.searchHint.split('(').first,
      en.actionsCount(45),
      en.noticePain,
      en.noticeAdvanced,
      en.noticeBlocked,
      en.noticeLocked(en.area(HipDirection.extension)),
      en.addToGroup,
      en.startPractice,
      en.copyAsGroup,
      en.newGroupHint,
      en.editGroup,
      en.reorderHint,
      en.addMoves,
      en.save,
      en.discardTitle,
      en.addN(3),
      en.willHave(9),
      en.singleNoStreak,
      en.duration(475),
      for (final d in HipDirection.values) en.area(d),
      for (final m in HipMethod.values) en.method(m),
    ];
    for (final l in lines) {
      expect(cjk.hasMatch(l), isFalse, reason: l);
    }
    for (final d in libraryDrills(content)) {
      final k = kit(d.id);
      for (final single in [true, false]) {
        final dose = single
            ? DoseRules.singleDefault(k)
            : DoseRules.kitDefault(k);
        expect(
          cjk.hasMatch(
            doseText(k, dose.copyWith(sets: 2), single: single, lang: 'en'),
          ),
          isFalse,
          reason: d.id,
        );
      }
      final names = k.raw['display']['name'] as Map;
      expect(names['en'], isNotEmpty, reason: d.id);
      expect(names['zh'], isNotEmpty, reason: d.id);
    }
    expect(LibText.zh.practice, '练习');
  });
}

const base0 = TrainingProfile();
