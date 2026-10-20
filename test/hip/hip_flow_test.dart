import 'package:hiplab/hip/control/hip_store.dart';
import 'package:hiplab/hip/domain/hip_models.dart';
import 'package:hiplab/hip/ui/hip_app.dart';
import 'package:hiplab/hip/ui/hip_privacy_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ugk_trainer/ugk_trainer.dart' as trainer;

import 'hip_domain_test.dart' show MemoryStorage, loadContent;
import 'checkup_entry.dart';

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
    await openCheckupIntro(tester);
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
    // The package preparation label precedes the first drill.
    expect(find.text('准备 · 第一个动作'), findsOneWidget);
    expect(find.text(plan.steps.first.drill.name), findsWidgets);
    expect(find.text('1 / ${plan.steps.length}'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('skip')));
    await tester.pumpAndSettle();
    expect(find.text(plan.steps.first.drill.name), findsOneWidget);
    // Pain once → smaller range, half time, "别勉强".
    await tester.tap(find.byKey(const ValueKey('discomfort')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('pain-pinch')));
    await tester.pumpAndSettle();
    expect(find.text('幅度小一点，别勉强'), findsOneWidget);
    final half = (plan.steps.first.seconds / 2).ceil();
    final player = tester.widget<trainer.TrainerPlayer>(
      find.byType(trainer.TrainerPlayer),
    );
    final work = player.sessionBuilder!
        .phases(player.plan)
        .where((p) => p.isWork && p.itemIndex == 0);
    expect(work, isNotEmpty);
    expect(
      work.fold<double>(0, (sum, p) => sum + p.seconds),
      closeTo(half, .001),
    );
    // Complete real work: skipping every drill must not earn a streak.
    for (var i = 0; i < plan.seconds + 120; i++) {
      if (find.byKey(const ValueKey('finish')).evaluate().isNotEmpty) {
        break;
      }
      await tester.pump(const Duration(seconds: 1));
    }
    await tester.pumpAndSettle();
    expect(find.text('训练完成！'), findsOneWidget);
    expect(store.streak, 1);
    await tester.tap(find.byKey(const ValueKey('finish')));
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
    await tester.tap(find.byKey(const ValueKey('skip'))); // lead-in
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('discomfort')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('pain-nerve')));
    await tester.pumpAndSettle();
    expect(find.text('先停下来'), findsOneWidget);
    expect(store.askNumbness, isTrue);
    await tester.tap(find.byKey(const ValueKey('finish')));
    await tester.pumpAndSettle();
    expect(find.text('现在还麻吗？'), findsOneWidget);
  });

  testWidgets('progress opens offline privacy policy and copies public URL', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    String? copiedUrl;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copiedUrl = (call.arguments as Map)['text'] as String;
        }
        return null;
      },
    );
    addTearDown(() {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      );
    });
    await pumpApp(
      tester,
      seed: (s) {
        s.safety = {'pregnancy': false, 'surgery': false, 'acute': false};
        s.identity = HipIdentity.office;
      },
    );
    await tester.tap(find.byKey(const ValueKey('tab-2')));
    await tester.pumpAndSettle();
    final entry = find.byKey(const ValueKey('privacy-policy'));
    await tester.scrollUntilVisible(
      entry,
      200,
      scrollable: find.descendant(
        of: find.byType(HipProgressPage),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.tap(entry);
    await tester.pumpAndSettle();
    expect(find.byType(HipPrivacyPage), findsOneWidget);
    expect(find.text('开胯训练助手 HipLab'), findsOneWidget);
    expect(find.textContaining('不收集、上传、出售'), findsOneWidget);

    final copy = find.byKey(const ValueKey('copy-privacy-url'));
    await tester.scrollUntilVisible(
      copy,
      400,
      scrollable: find
          .descendant(
            of: find.byType(HipPrivacyPage),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(copy);
    await tester.pumpAndSettle();
    await tester.tap(copy);
    await tester.pumpAndSettle();
    expect(copiedUrl, HipPrivacyPage.policyUrl);
    expect(find.text('已复制隐私政策链接'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.bySemanticsLabel('返回'));
    await tester.pumpAndSettle();
    expect(find.byType(HipPrivacyPage), findsNothing);
    semantics.dispose();
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
