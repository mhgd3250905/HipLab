import 'dart:convert';
import 'dart:io';

import 'package:hiplab/core/storage/local_state_storage.dart';
import 'package:hiplab/hip/control/hip_store.dart';
import 'package:hiplab/hip/domain/hip_assessment.dart';
import 'package:hiplab/hip/domain/hip_models.dart';
import 'package:hiplab/hip/domain/hip_pain.dart';
import 'package:hiplab/hip/domain/hip_progress.dart';
import 'package:hiplab/hip/domain/hip_session.dart';
import 'package:flutter_test/flutter_test.dart';

HipContent loadContent() => HipContent.fromJson(
  jsonDecode(File('assets/hip/hip-content.json').readAsStringSync())
      as Map<String, dynamic>,
);

class MemoryStorage implements LocalStateStorage {
  final values = <String, String>{};
  @override
  Future<String?> read(String key) async => values[key];
  @override
  Future<void> write(String key, String value) async => values[key] = value;
}

ItemAnswer one(int s) => ItemAnswer.single(SideAnswer.choice(s));
ItemAnswer two(int l, int r, {String? fl, String? fr}) => ItemAnswer.sided(
  left: SideAnswer.choice(l, followUp: fl),
  right: SideAnswer.choice(r, followUp: fr),
);

Map<String, ItemAnswer> all(int s) => {
  'butterfly': one(s),
  'ninety_ninety': two(s, s),
  'thomas': two(s, s),
  'supine_cross': two(s, s),
  'seated_fold': one(s),
  'deep_squat': one(s),
};

void main() {
  final content = loadContent();
  final scorer = HipAssessmentScorer(content.rules);

  group('content pack', () {
    test(
      '45 MVP drills, 6 directions covered, 7 routines with stated lengths',
      () {
        expect(content.mvpDrills, hasLength(45));
        expect(content.routines.map((r) => r.id), [
          'A',
          'B',
          'C',
          'D',
          'E',
          'F',
          'M',
        ]);
        expect(
          {for (final r in content.routines) r.id: r.minutes},
          {'A': 5, 'B': 8, 'C': 6, 'D': 10, 'E': 7, 'F': 12, 'M': 2},
        );
        for (final d in HipDirection.values) {
          expect(
            content.mvpDrills.where((x) => x.directions.contains(d)),
            isNotEmpty,
            reason: d.zh,
          );
        }
        expect(content.rules.items.map((i) => i.id), [
          'butterfly',
          'ninety_ninety',
          'thomas',
          'supine_cross',
          'seated_fold',
          'deep_squat',
        ]);
        // MVP has no gym scene: every routine is chair or home.
        expect(
          content.routines
              .where((r) => r.id == 'A' || r.id == 'M')
              .every((r) => r.scene == HipScene.chair),
          isTrue,
        );
      },
    );
  });

  group('assessment scoring', () {
    test('all 松 → 12, L3; all 紧 → 0, L1; radar maps 0/1/2 to 25/60/90', () {
      final top = scorer.score(all(2), HipIdentity.office);
      expect(top.total, 12);
      expect(top.level.name, '进阶');
      expect(top.radar.values.toSet(), {90});
      final low = scorer.score(all(0), HipIdentity.office);
      expect(low.total, 0);
      expect(low.level.name, '入门');
      expect(low.radar.values.toSet(), {25});
      expect(scorer.score(all(1), HipIdentity.office).radar.values.toSet(), {
        60,
      });
    });

    test('level bands 0–5 / 6–9 / 10–12', () {
      expect(scorer.levelFor(5).level, 1);
      expect(scorer.levelFor(6).level, 2);
      expect(scorer.levelFor(9).level, 2);
      expect(scorer.levelFor(10).level, 3);
    });

    test('weights: 屈 = 前屈 60% + 深蹲 40%; 外旋 = 90/90 前腿 60% + 蝴蝶 40%', () {
      final a = all(2)
        ..['seated_fold'] = one(0)
        ..['ninety_ninety'] = two(0, 0, fl: 'front', fr: 'front');
      final r = scorer.score(a, HipIdentity.office);
      expect(r.directionScores[HipDirection.flexion], closeTo(0.8, 1e-9));
      // front knee lifts → 外旋 0 (×0.6) + 蝴蝶 2 (×0.4); 内旋 (back) stays 1.
      expect(
        r.directionScores[HipDirection.externalRotation],
        closeTo(0.8, 1e-9),
      );
      expect(
        r.directionScores[HipDirection.internalRotation],
        closeTo(1, 1e-9),
      );
      expect(r.radar[HipDirection.flexion], closeTo(25 + 35 * .8, 1e-9));
    });

    test('sided items take the lower side and record the tighter side', () {
      final a = all(2)..['thomas'] = two(2, 1);
      final r = scorer.score(a, HipIdentity.office);
      expect(r.items['thomas']!.score, 1);
      expect(r.total, 11);
      expect(r.asymmetry[HipDirection.extension], HipSide.right);
      expect(r.lowest, HipDirection.extension);
      expect(r.route!.routineId, 'D');
    });

    test(
      'pain: direction flagged, scores 0, excluded from the focus direction',
      () {
        final a = all(1)
          ..['thomas'] = const ItemAnswer.sided(
            left: SideAnswer.pain(),
            right: SideAnswer.choice(2),
          );
        final r = scorer.score(a, HipIdentity.office);
        expect(r.painDirections, {HipDirection.extension});
        expect(r.items['thomas']!.score, 0);
        expect(r.lowest, isNot(HipDirection.extension));
        // Ties among the rest break by priority 伸 > 内旋 > 外展 > 屈 > 外旋 > 内收.
        expect(r.lowest, HipDirection.internalRotation);
      },
    );

    test('skip counts as 一般 and is marked untested', () {
      final a = all(2)
        ..['seated_fold'] = const ItemAnswer.single(SideAnswer.skipped());
      final r = scorer.score(a, HipIdentity.office);
      expect(r.total, 11);
      expect(r.untestedDirections, {HipDirection.flexion});
    });

    test(
      'recommendation follows identity × lowest direction; dancer unlock at ≥ 10',
      () {
        final a = all(2)..['butterfly'] = one(1);
        final office = scorer.score(a, HipIdentity.office);
        expect(office.lowest, HipDirection.abduction);
        expect(office.route!.routineId, 'B');
        expect(office.dancerUnlocked, isFalse);
        final dancer = scorer.score(a, HipIdentity.dancer);
        expect(dancer.route!.routineId, 'F');
        expect(dancer.route!.route, contains('分腿'));
        expect(dancer.dancerUnlocked, isTrue);
        expect(
          scorer.score(all(1), HipIdentity.dancer).dancerUnlocked,
          isFalse,
        );
      },
    );

    test('内收 and 外展 both lowest → 外展 wins the route', () {
      final a = all(2)
        ..['butterfly'] = one(0)
        ..['deep_squat'] = one(0)
        ..['supine_cross'] = two(0, 0);
      final r = scorer.score(a, HipIdentity.office);
      expect(r.directionScores[HipDirection.abduction], 0);
      expect(r.directionScores[HipDirection.adduction], 0);
      expect(r.lowest, HipDirection.abduction);
    });
  });

  group('training planner', () {
    final planner = TrainingPlanner(content);

    test(
      'office chair 5 min → 套 A; L1 swaps advanced drills for their alternatives',
      () {
        final plan = planner.plan(
          minutes: 5,
          scene: HipScene.chair,
          profile: const TrainingProfile(),
        )!;
        expect(plan.routines.single.id, 'A');
        expect(plan.minutes, 5);
        final home = planner.plan(
          minutes: 10,
          scene: HipScene.home,
          profile: const TrainingProfile(),
        )!;
        expect(home.routines.first.id, 'D');
        expect(home.steps.any((s) => s.drill.advanced), isFalse);
        expect(
          home.steps.firstWhere((s) => s.replaced == 's-pigeon').drill.id,
          's-figure4',
        );
      },
    );

    test(
      'recommended routine wins when it fits; 15 min chains two routines',
      () {
        final p = const TrainingProfile(level: 2, recommendedRoutine: 'B');
        expect(
          planner
              .plan(minutes: 10, scene: HipScene.home, profile: p)!
              .routines
              .first
              .id,
          'B',
        );
        final long = planner.plan(
          minutes: 15,
          scene: HipScene.home,
          profile: const TrainingProfile(level: 2),
        )!;
        expect(long.routines, hasLength(2));
        expect(long.minutes, inInclusiveRange(13, 18));
      },
    );

    test('locked direction keeps only relax drills; asymmetry adds a set', () {
      final p = TrainingProfile(
        level: 2,
        lockedDirections: {HipDirection.extension},
        asymmetry: {HipDirection.externalRotation: HipSide.right},
      );
      final plan = planner.plan(minutes: 10, scene: HipScene.home, profile: p)!;
      for (final s in plan.steps.where(
        (s) => s.drill.directions.first == HipDirection.extension,
      )) {
        expect(s.drill.isRelax, isTrue, reason: s.drill.id);
      }
      final ninety = plan.steps.firstWhere((s) => s.drill.id == 's-9090');
      expect(ninety.extraSide, HipSide.right);
      expect(ninety.seconds, 70 + 35);
    });

    test('safety block → no plan; T series gated until dancer unlock', () {
      expect(
        planner.plan(
          minutes: 10,
          scene: HipScene.home,
          profile: const TrainingProfile(blocked: true),
        ),
        isNull,
      );
      final f = content.routine('F');
      final locked = planner.planFor([
        f,
      ], const TrainingProfile(level: 3, identity: HipIdentity.dancer));
      expect(
        locked.steps.map((s) => s.drill.id),
        isNot(contains('t-seated-straddle-lift-1leg')),
      );
      final open = planner.planFor(
        [f],
        const TrainingProfile(
          level: 3,
          identity: HipIdentity.dancer,
          dancerUnlocked: true,
          directionScores: {HipDirection.abduction: 2},
        ),
      );
      expect(
        open.steps.map((s) => s.drill.id),
        contains('t-seated-straddle-lift-1leg'),
      );
      expect(open.steps.map((s) => s.drill.id), contains('n-slider-lateral'));
    });
  });

  group('pain ladder', () {
    test('reduce → substitute → skip direction', () {
      final ladder = SessionPainLadder(content);
      final a = ladder.report('s-pigeon', PainKind.pinch);
      expect(a.type, PainActionType.reduceAmplitude);
      expect(a.cue, contains('别勉强'));
      final b = ladder.report('s-pigeon', PainKind.pinch);
      expect(b.type, PainActionType.substitute);
      expect(b.substituteId, 's-figure4');
      final c = ladder.report('s-figure4', PainKind.pinch);
      expect(c.type, PainActionType.skipDirection);
      expect(ladder.skippedDirections, {HipDirection.externalRotation});
    });

    test('second pain in the same direction swaps straight away', () {
      final ladder = SessionPainLadder(content);
      ladder.report('s-kneel-hipflex', PainKind.pinch);
      final next = ladder.report('h-couch-stretch', PainKind.pinch);
      expect(next.type, PainActionType.substitute);
      expect(next.substituteId, 's-kneel-hipflex');
    });

    test('nerve pain ends the session', () {
      final ladder = SessionPainLadder(content);
      expect(
        ladder.report('s-butterfly', PainKind.nerve).type,
        PainActionType.endSession,
      );
      expect(ladder.ended, isTrue);
    });

    test('two skips within 7 days lock the direction for 7 days', () {
      final t0 = DateTime(2026, 10, 1, 20);
      final h = PainHistory([
        PainEvent(t0, HipDirection.extension, 'skip'),
        PainEvent(
          t0.add(const Duration(days: 3)),
          HipDirection.extension,
          'skip',
        ),
        PainEvent(t0, HipDirection.flexion, 'skip'),
        PainEvent(
          t0.add(const Duration(days: 9)),
          HipDirection.flexion,
          'skip',
        ),
      ]);
      final locks = h.lockedUntil(t0.add(const Duration(days: 5)));
      expect(locks.keys, [HipDirection.extension]);
      expect(locks[HipDirection.extension], DateTime(2026, 10, 11, 20));
      expect(h.lockedUntil(DateTime(2026, 10, 12)), isEmpty);
    });
  });

  group('progress', () {
    test('streak counts back from today, or yesterday when today is open', () {
      final now = DateTime(2026, 10, 16, 21);
      expect(streakDays({'2026-10-14', '2026-10-15'}, now), 2);
      expect(streakDays({'2026-10-14', '2026-10-15', '2026-10-16'}, now), 3);
      expect(streakDays({'2026-10-13', '2026-10-15'}, now), 1);
      expect(streakDays({'2026-10-13'}, now), 0);
      expect(lastSevenDays({'2026-10-16', '2026-10-10'}, now), [
        true,
        false,
        false,
        false,
        false,
        false,
        true,
      ]);
    });

    test('reminder schedule stays in work hours on weekdays', () {
      const r = ReminderSettings(enabled: true, intervalMinutes: 45);
      final fri = DateTime(2026, 10, 16, 10, 0); // Friday
      expect(r.nextAfter(fri), DateTime(2026, 10, 16, 10, 30));
      expect(
        r.nextAfter(DateTime(2026, 10, 16, 17, 59)),
        DateTime(2026, 10, 16, 18),
      );
      expect(
        r.nextAfter(DateTime(2026, 10, 16, 18)),
        DateTime(2026, 10, 19, 9, 45),
      );
      expect(r.firesOn(DateTime(2026, 10, 17)), isEmpty); // Saturday
      expect(r.firesOn(DateTime(2026, 10, 19)).length, 12);
      expect(const ReminderSettings().nextAfter(fri), isNull);
    });
  });

  test('store persists onboarding, assessment, streak and reminder', () async {
    final storage = MemoryStorage();
    var clock = DateTime(2026, 10, 16, 9);
    final store = HipStore(
      content: content,
      storage: storage,
      clock: () => clock,
    );
    await store.initialize();
    expect(store.onboarded, isFalse);
    await store.setSafety({
      'pregnancy': false,
      'surgery': false,
      'acute': false,
    });
    await store.setIdentity(HipIdentity.dancer);
    await store.saveAssessment(all(2));
    await store.completeSession(SessionPainLadder(content));
    await store.setReminder(
      const ReminderSettings(enabled: true, intervalMinutes: 45),
    );
    clock = DateTime(2026, 10, 17, 9);
    final again = HipStore(
      content: content,
      storage: storage,
      clock: () => clock,
    );
    await again.initialize();
    expect(again.onboarded, isTrue);
    expect(again.latestResult!.total, 12);
    expect(again.latestResult!.dancerUnlocked, isTrue);
    expect(again.streak, 1);
    expect(again.reminder.intervalMinutes, 45);
    expect((again.reminders as PlannedReminderScheduler).next, isNotNull);
    expect(again.todayPlan, isNotNull);
    await again.setSafety({
      'pregnancy': true,
      'surgery': false,
      'acute': false,
    });
    expect(again.todayPlan, isNull);
  });
}
