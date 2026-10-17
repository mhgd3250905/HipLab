import 'package:hiplab/hip/control/hip_store.dart';
import 'package:hiplab/hip/domain/hip_models.dart';
import 'package:hiplab/hip/ui/hip_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'hip_domain_test.dart' show MemoryStorage, loadContent;

void main() {
  final content = loadContent();

  Future<HipStore> pumpApp(
    WidgetTester tester, {
    void Function(HipStore)? seed,
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final store = HipStore(
      content: content,
      storage: MemoryStorage(),
      clock: () => DateTime(2026, 10, 16, 9, 41),
    );
    await store.initialize();
    seed?.call(store);
    await tester.pumpWidget(HipApp(store: store, videoEnabled: false));
    await tester.pumpAndSettle();
    return store;
  }

  testWidgets(
    'first launch: 3 safety cards, identity, then home with one start button',
    (tester) async {
      final store = await pumpApp(tester);
      for (var i = 0; i < 3; i++) {
        expect(find.text('你现在有这种情况吗？'), findsOneWidget);
        expect(find.text('这是运动练习，不能替代医生的建议。'), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('safety-no')));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.byKey(const ValueKey('identity-office')));
      await tester.pumpAndSettle();
      expect(store.onboarded, isTrue);
      expect(find.text('今日训练'), findsOneWidget);
      expect(find.byKey(const ValueKey('start-today')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('scene-HipScene.chair')));
      await tester.tap(find.byKey(const ValueKey('minutes-5')));
      await tester.pumpAndSettle();
      expect(store.todayPlan!.routines.single.id, 'A');
      expect(find.text('办公室'), findsOneWidget);
    },
  );

  testWidgets('a "有" safety answer blocks training but keeps browsing', (
    tester,
  ) async {
    final store = await pumpApp(tester);
    await tester.tap(find.byKey(const ValueKey('safety-yes')));
    await tester.pumpAndSettle();
    for (var i = 0; i < 2; i++) {
      await tester.tap(find.byKey(const ValueKey('safety-no')));
      await tester.pumpAndSettle();
    }
    expect(find.textContaining('先问问医生或专业人士'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('identity-other')));
    await tester.pumpAndSettle();
    expect(store.blocked, isTrue);
    expect(find.byKey(const ValueKey('start-today')), findsNothing);
    expect(find.text('先问问医生或专业人士，再开始练习'), findsOneWidget);
  });

  testWidgets('assessment: 6 items, sides, follow-up, pain → radar + route', (
    tester,
  ) async {
    final store = await pumpApp(
      tester,
      seed: (s) {
        s.safety = {'pregnancy': false, 'surgery': false, 'acute': false};
        s.identity = HipIdentity.office;
      },
    );
    await tester.tap(find.byKey(const ValueKey('tab-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('assessment-start')));
    await tester.pumpAndSettle();

    Future<void> pick(int score, {String? follow}) async {
      await tester.tap(find.byKey(ValueKey('option-$score')));
      await tester.pump();
      if (follow != null) {
        await tester.tap(find.byKey(ValueKey('follow-$follow')));
        await tester.pump();
      }
      await tester.tap(find.byKey(const ValueKey('assessment-next')));
      await tester.pumpAndSettle();
    }

    expect(find.text('1/6'), findsOneWidget);
    await pick(2); // 蝴蝶 松
    expect(find.text('左边'), findsOneWidget);
    await pick(2); // 90/90 左 松
    expect(find.text('右边'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('option-0')));
    await tester.pump();
    expect(find.textContaining('哪条腿的膝盖翘'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('follow-back')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('assessment-next')));
    await tester.pumpAndSettle();
    // 托马斯: left pain.
    await tester.tap(find.byKey(const ValueKey('assessment-pain')));
    await tester.pumpAndSettle();
    await pick(2);
    await pick(1); // 横跨 左
    await pick(1); // 横跨 右
    await tester.tap(find.byKey(const ValueKey('assessment-skip'))); // 前屈 跳过
    await tester.pumpAndSettle();
    await pick(2); // 深蹲
    expect(find.text('你的髋部'), findsOneWidget);
    final r = store.latestResult!;
    expect(r.painDirections, {HipDirection.extension});
    expect(r.lowest, HipDirection.internalRotation);
    expect(find.textContaining('先别练这里'), findsOneWidget);
    expect(find.textContaining('未测'), findsOneWidget);
    expect(find.text('内旋补强'), findsOneWidget);
    expect(find.byKey(const ValueKey('result-start')), findsOneWidget);
  });

  testWidgets('player: countdown, pain ladder, finish → streak', (
    tester,
  ) async {
    final store = await pumpApp(
      tester,
      seed: (s) {
        s.safety = {'pregnancy': false, 'surgery': false, 'acute': false};
        s.identity = HipIdentity.office;
        s.scene = HipScene.chair;
        s.minutes = 5;
      },
    );
    await tester.tap(find.byKey(const ValueKey('start-today')));
    await tester.pumpAndSettle();
    final plan = store.todayPlan!;
    expect(find.text(plan.steps.first.drill.name), findsOneWidget);
    expect(find.text('1/${plan.steps.length}'), findsOneWidget);
    // Pain once → smaller range, half time, "别勉强".
    await tester.tap(find.byKey(const ValueKey('player-pain')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('pain-pinch')));
    await tester.pumpAndSettle();
    expect(find.text('幅度小一点，别勉强'), findsOneWidget);
    final half = (plan.steps.first.seconds / 2).ceil();
    expect(
      find.byWidgetPredicate((w) {
        final v = w is Text ? int.tryParse(w.data ?? '') : null;
        return v != null && v <= half && v >= half - 2;
      }),
      findsOneWidget,
    );
    // Skip through every drill and transition.
    for (var i = 0; i < plan.steps.length * 2 + 2; i++) {
      if (find.byKey(const ValueKey('player-done')).evaluate().isNotEmpty) {
        break;
      }
      await tester.tap(find.byKey(const ValueKey('player-skip')));
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.pumpAndSettle();
    expect(find.text('今天练完了'), findsOneWidget);
    expect(store.streak, 1);
    await tester.tap(find.byKey(const ValueKey('player-done')));
    await tester.pumpAndSettle();
    expect(find.text('今日训练'), findsOneWidget);
  });

  testWidgets('nerve-type pain stops the session and asks next time', (
    tester,
  ) async {
    final store = await pumpApp(
      tester,
      seed: (s) {
        s.safety = {'pregnancy': false, 'surgery': false, 'acute': false};
        s.identity = HipIdentity.office;
      },
    );
    await tester.tap(find.byKey(const ValueKey('start-today')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('player-pain')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('pain-nerve')));
    await tester.pumpAndSettle();
    expect(find.text('先停下来'), findsOneWidget);
    expect(store.askNumbness, isTrue);
    await tester.tap(find.byKey(const ValueKey('player-stop-home')));
    await tester.pumpAndSettle();
    expect(find.text('现在还麻吗？'), findsOneWidget);
  });

  testWidgets('progress tab: reminder switch persists (schedule recorded)', (
    tester,
  ) async {
    final store = await pumpApp(
      tester,
      seed: (s) {
        s.safety = {'pregnancy': false, 'surgery': false, 'acute': false};
        s.identity = HipIdentity.dancer;
      },
    );
    await tester.tap(find.byKey(const ValueKey('tab-2')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('reminder-switch')));
    await tester.pumpAndSettle();
    expect(store.reminder.enabled, isTrue);
    expect(find.text('45 分钟'), findsOneWidget);
    expect(find.textContaining('接入通知组件后生效'), findsOneWidget);
  });
}
