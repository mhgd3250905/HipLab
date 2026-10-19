// PR #22 F7: the pain-halving short-rep guard must use the sets the session
// script really plays on each side (PlanStep.sets + the tight side's extra
// set), not a fixed 1 / 2. Rule: if any side / set cannot fit one full rep,
// the current action is skipped.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiplab/hip/control/hip_store.dart';
import 'package:hiplab/hip/domain/hip_assessment.dart';
import 'package:hiplab/hip/domain/hip_library.dart';
import 'package:hiplab/hip/domain/hip_models.dart';
import 'package:hiplab/hip/domain/hip_session.dart';
import 'package:hiplab/hip/ui/hip_app.dart';
import 'package:hiplab/hip/ui/hip_player_page.dart';
import 'package:hiplab/hip/ui/hip_widgets.dart';

import 'hip_domain_test.dart' show MemoryStorage, loadContent;

int _secondsLeft(WidgetTester tester) => int.parse(
  tester
      .widget<HipCountdownRing>(find.byKey(const ValueKey('player-ring')))
      .label,
);

Future<HipStore> _store() async {
  final store = HipStore(
    content: loadContent(),
    storage: MemoryStorage(),
    clock: () => DateTime(2026, 10, 19, 10),
  );
  await store.initialize();
  store
    ..safety = {'pregnancy': false, 'surgery': false, 'acute': false}
    ..identity = HipIdentity.office
    ..scene = HipScene.chair
    ..minutes = 5;
  return store;
}

Future<void> _open(
  WidgetTester tester,
  HipStore store,
  TrainingPlan plan,
) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(HipApp(store: store, videoEnabled: false));
  await tester.pumpAndSettle();
  tester
      .state<NavigatorState>(find.byType(Navigator))
      .push<void>(
        MaterialPageRoute(
          builder: (_) => HipPlayerPage(store: store, plan: plan),
        ),
      );
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('player-skip'))); // prep -> work
  await tester.pumpAndSettle();
  expect(find.text(plan.steps.first.drill.name), findsOneWidget);
}

Future<void> _pinch(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('player-pain')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('pain-pinch')));
  await tester.pumpAndSettle();
}

Future<void> _dispose(WidgetTester tester) async {
  expect(tester.takeException(), isNull);
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpAndSettle();
}

/// After the skip: the rest before [next] runs with optional feedback, then
/// [next] starts normally.
Future<void> _restThenNext(
  WidgetTester tester,
  TrainingPlan plan,
  String next,
) async {
  expect(find.text(next), findsOneWidget);
  expect(find.text('2/${plan.steps.length}'), findsOneWidget);
  expect(find.byKey(const ValueKey('player-pain')), findsNothing);
  expect(find.byKey(const ValueKey('feel-ok')), findsOneWidget);
  final before = _secondsLeft(tester);
  expect(
    before,
    inInclusiveRange(plan.transitionSeconds - 2, plan.transitionSeconds),
  );
  await tester.pump(const Duration(seconds: 2));
  expect(_secondsLeft(tester), inInclusiveRange(before - 3, before - 1));
  await tester.tap(find.byKey(const ValueKey('feel-ok')));
  await tester.pump(const Duration(milliseconds: 300));
  expect(find.text('已记录'), findsOneWidget);
  await tester.pump(Duration(seconds: _secondsLeft(tester) + 1));
  await tester.pump(const Duration(milliseconds: 400));
  expect(find.byKey(const ValueKey('feel-ok')), findsNothing);
  expect(find.byKey(const ValueKey('player-pain')), findsOneWidget);
  expect(find.text(next), findsOneWidget);
  expect(find.text('2/${plan.steps.length}'), findsOneWidget);
}

TrainingPlan _group(
  HipStore store,
  List<(String, LibraryDose)> steps, {
  TrainingProfile profile = const TrainingProfile(),
}) {
  final c = store.content;
  return store.planner.customPlan(
    CustomRoutine(
      id: 'f7',
      name: 'F7',
      steps: [
        for (final (id, dose) in steps) CustomStep.fromDose(c.kit(id)!, dose),
      ],
    ),
    profile,
  )!;
}

void main() {
  group('F7 pain halving uses the real sets per side', () {
    for (final sets in [2, 3]) {
      testWidgets('F7 单练 h-squat 1 次 × $sets 组 (unsided): 疼 → 关节夹着疼 '
          'skips the action and reaches the end page', (tester) async {
        final store = await _store();
        final plan = store.planner.singlePlan(
          store.content.drill('h-squat'),
          LibraryDose(reps: 1, sets: sets),
          const TrainingProfile(),
        )!;
        expect(plan.steps.single.sets, sets);
        await _open(tester, store, plan);
        await _pinch(tester);
        // Halved, no set fits one full squat: no 8 s countdown without cues.
        expect(find.byKey(const ValueKey('player-ring')), findsNothing);
        expect(find.byKey(const ValueKey('player-done-note')), findsOneWidget);
        expect(find.text('练完了'), findsOneWidget);
        expect(find.byKey(const ValueKey('player-again')), findsOneWidget);
        await _dispose(tester);
      });
    }

    testWidgets('F7 group h-squat 1 次 × 3 组 → skip, rest + feedback, then the '
        'next step runs', (tester) async {
      final store = await _store();
      final plan = _group(store, [
        ('h-squat', const LibraryDose(reps: 1, sets: 3)),
        ('s-figure4', const LibraryDose(seconds: 30)),
      ]);
      await _open(tester, store, plan);
      await _pinch(tester);
      await _restThenNext(tester, plan, plan.steps[1].drill.name);
      await _dispose(tester);
    });

    testWidgets('F7 sided glute-max-A 1 次 × 2 组 (no tight side) → skip, rest '
        '+ feedback, then the next step runs', (tester) async {
      final store = await _store();
      final plan = _group(store, [
        ('glute-max-A', const LibraryDose(reps: 1, sets: 2)),
        ('s-figure4', const LibraryDose(seconds: 30)),
      ]);
      expect(plan.steps.first.extraSide, isNull);
      expect(plan.steps.first.sided, isTrue);
      await _open(tester, store, plan);
      expect(find.byKey(const ValueKey('side-indicator')), findsOneWidget);
      await _pinch(tester);
      await _restThenNext(tester, plan, plan.steps[1].drill.name);
      await _dispose(tester);
    });

    testWidgets('F7 sided glute-max-A 1 次 × 3 组, left tight (+1 组) → skip, '
        'rest + feedback, then the next step runs', (tester) async {
      final store = await _store();
      final dir = store.content.drill('glute-max-A').directions.first;
      final plan = _group(store, [
        ('glute-max-A', const LibraryDose(reps: 1, sets: 3)),
        ('s-figure4', const LibraryDose(seconds: 30)),
      ], profile: TrainingProfile(asymmetry: {dir: HipSide.left}));
      expect(plan.steps.first.extraSide, HipSide.left);
      await _open(tester, store, plan);
      await _pinch(tester);
      await _restThenNext(tester, plan, plan.steps[1].drill.name);
      await _dispose(tester);
    });

    testWidgets('F7 control: h-squat 4 次 × 2 组 still fits one rep per set '
        'after halving → keeps going at half range, not skipped', (
      tester,
    ) async {
      final store = await _store();
      final plan = store.planner.singlePlan(
        store.content.drill('h-squat'),
        const LibraryDose(reps: 4, sets: 2),
        const TrainingProfile(),
      )!;
      await _open(tester, store, plan);
      final full = _secondsLeft(tester);
      await _pinch(tester);
      expect(find.byKey(const ValueKey('player-done-note')), findsNothing);
      expect(find.text(plan.steps.single.drill.name), findsOneWidget);
      expect(_secondsLeft(tester), lessThan(full));
      expect(_secondsLeft(tester), greaterThan(0));
      await _dispose(tester);
    });
  });
}
