// 练习库 UI (拍板 2026-10-19): 3 tabs with the check-up card on 练习,
// 动作大全 / detail / 单练, safety notices, 我的 → picker → editor.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiplab/hip/control/hip_store.dart';
import 'package:hiplab/hip/domain/hip_assessment.dart';
import 'package:hiplab/hip/domain/hip_library.dart';
import 'package:hiplab/hip/domain/hip_models.dart';
import 'package:hiplab/hip/domain/hip_pain.dart';
import 'package:hiplab/hip/ui/hip_app.dart';
import 'package:hiplab/hip/ui/hip_assessment_page.dart';
import 'package:hiplab/hip/ui/hip_player_page.dart';
import 'package:hiplab/hip/ui/hip_widgets.dart';
import 'package:hiplab/hip/ui/library/drill_detail_page.dart';
import 'package:hiplab/hip/ui/library/group_editor_page.dart';

import 'hip_domain_test.dart' show MemoryStorage, loadContent;

final _now = DateTime(2026, 10, 19, 9, 41);

void main() {
  final content = loadContent();

  Future<HipStore> pumpApp(
    WidgetTester tester, {
    Size size = const Size(390, 844),
    void Function(HipStore)? setup,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final store = HipStore(
      content: content,
      storage: MemoryStorage(),
      clock: () => _now,
    );
    await store.initialize();
    store
      ..safety = {'pregnancy': false, 'surgery': false, 'acute': false}
      ..identity = HipIdentity.office;
    setup?.call(store);
    await tester.pumpWidget(HipApp(store: store, videoEnabled: false));
    await tester.pumpAndSettle();
    return store;
  }

  Future<void> toPractice(WidgetTester tester, {int segment = 0}) async {
    await tester.tap(find.byKey(const ValueKey('tab-1')));
    await tester.pumpAndSettle();
    if (segment != 0) {
      await tester.tap(find.byKey(ValueKey('practice-$segment')));
      await tester.pumpAndSettle();
    }
  }

  Future<void> openDrill(WidgetTester tester, String id) async {
    final card = find.byKey(ValueKey('drill-card-$id'));
    await tester.scrollUntilVisible(
      card,
      400,
      scrollable: find
          .descendant(
            of: find.byKey(const ValueKey('practice-list')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.ensureVisible(card);
    await tester.pumpAndSettle();
    await tester.tap(card);
    await tester.pumpAndSettle();
    expect(find.byType(DrillDetailPage), findsOneWidget);
  }

  HipPrimaryButton startButton(WidgetTester tester) => tester
      .widget<HipPrimaryButton>(find.byKey(const ValueKey('detail-start')));

  void addAssessment(HipStore s) {
    ItemAnswer one(int v) => ItemAnswer.single(SideAnswer.choice(v));
    ItemAnswer two(int l, int r) => ItemAnswer.sided(
      left: SideAnswer.choice(l),
      right: SideAnswer.choice(r),
    );
    s.assessments.add((
      at: DateTime(2026, 10, 18, 20),
      answers: {
        'butterfly': one(1),
        'ninety_ninety': two(1, 1),
        'thomas': two(0, 1),
        'supine_cross': two(1, 1),
        'seated_fold': one(2),
        'deep_squat': one(2),
      },
    ));
  }

  group('tabs (拍板 1)', () {
    testWidgets('three tabs 今日 / 练习 / 进度; no 自测 tab', (tester) async {
      await pumpApp(tester);
      for (final (i, label) in [(0, '今日'), (1, '练习'), (2, '进度')]) {
        expect(
          find.descendant(
            of: find.byKey(ValueKey('tab-$i')),
            matching: find.text(label),
          ),
          findsOneWidget,
        );
      }
      expect(find.byKey(const ValueKey('tab-3')), findsNothing);
      expect(find.text('自测'), findsNothing);
      await toPractice(tester);
      expect(find.byKey(const ValueKey('hip-check-card')), findsOneWidget);
      for (final s in ['动作', '套路', '我的']) {
        expect(find.text(s), findsOneWidget);
      }
    });

    testWidgets('untested card → intro page → the check-up', (tester) async {
      await pumpApp(tester);
      await toPractice(tester);
      expect(find.text('开始自测'), findsOneWidget);
      expect(find.byKey(const ValueKey('check-radar')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('hip-check-card')));
      await tester.pumpAndSettle();
      // The former 自测 tab content is kept as the intro page.
      expect(find.text('开胯体检'), findsOneWidget);
      for (final item in content.rules.items) {
        expect(find.byKey(ValueKey('intro-item-${item.id}')), findsOneWidget);
      }
      await tester.tap(find.byKey(const ValueKey('assessment-start')));
      await tester.pumpAndSettle();
      expect(find.byType(HipAssessmentPage), findsOneWidget);
    });

    testWidgets('tested card: radar, last date, 重测 starts directly', (
      tester,
    ) async {
      await pumpApp(tester, setup: addAssessment);
      await toPractice(tester);
      expect(find.byKey(const ValueKey('check-radar')), findsOneWidget);
      expect(find.text('重测'), findsOneWidget);
      final caption = tester.widget<Text>(
        find.byKey(const ValueKey('check-caption')),
      );
      expect(caption.data, startsWith('上次 10 月 18 日'));
      await tester.tap(find.byKey(const ValueKey('check-start')));
      await tester.pumpAndSettle();
      expect(find.byType(HipAssessmentPage), findsOneWidget);
    });

    testWidgets('home 我的髋部 tile entry is kept', (tester) async {
      await pumpApp(tester);
      await tester.tap(find.text('3 分半自测'));
      await tester.pumpAndSettle();
      expect(find.byType(HipAssessmentPage), findsOneWidget);
    });
  });

  group('动作大全 + 单练', () {
    testWidgets('45 moves; search in English; direction chip', (tester) async {
      await pumpApp(tester);
      await toPractice(tester);
      expect(find.textContaining('45 个动作'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('lib-search')),
        'pigeon',
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('drill-card-s-pigeon')), findsOneWidget);
      expect(find.textContaining('1 个动作'), findsOneWidget);
      await tester.enterText(find.byKey(const ValueKey('lib-search')), '');
      await tester.tap(find.byKey(const ValueKey('lib-dir-extension')));
      await tester.pumpAndSettle();
      final n = libraryDrills(
        content,
      ).where((d) => d.directions.contains(HipDirection.extension)).length;
      expect(find.textContaining('$n 个动作'), findsOneWidget);
    });

    testWidgets('detail: 60 s default, ±5 s, sets; 开始练 → player; '
        'leaving logs 单练 without streak', (tester) async {
      final store = await pumpApp(tester);
      await toPractice(tester);
      await openDrill(tester, 's-figure4');
      Text text(String k) => tester.widget<Text>(find.byKey(ValueKey(k)));
      expect(text('dose-value').data, '60 秒');
      await tester.tap(find.byKey(const ValueKey('dose-value-up')));
      await tester.pump();
      expect(text('dose-value').data, '65 秒');
      await tester.tap(find.byKey(const ValueKey('dose-sets-up')));
      await tester.pump();
      expect(text('dose-sets').data, '2 组');
      expect(startButton(tester).onPressed, isNotNull);
      await tester.tap(find.byKey(const ValueKey('detail-start')));
      await tester.pumpAndSettle(const Duration(milliseconds: 100));
      expect(find.byType(HipPlayerPage), findsOneWidget);
      final player = tester.widget<HipPlayerPage>(find.byType(HipPlayerPage));
      expect(player.plan.source, PlanSource.single);
      expect(player.plan.steps.single.sets, 2);
      expect(player.plan.steps.single.kitDose.seconds, 65);
      await tester.tap(find.byKey(const ValueKey('close')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('close-confirm')));
      await tester.pumpAndSettle();
      expect(find.byType(HipPlayerPage), findsNothing);
      expect(store.sessions.single.source, PlanSource.single);
      expect(store.doneDays, isEmpty);
    });

    testWidgets('blocked: browse only, 先问问医生再来', (tester) async {
      await pumpApp(
        tester,
        setup: (s) =>
            s.safety = {'pregnancy': true, 'surgery': false, 'acute': false},
      );
      await toPractice(tester);
      await openDrill(tester, 's-figure4');
      expect(find.byKey(const ValueKey('notice-blocked')), findsOneWidget);
      expect(startButton(tester).label, '先问问医生再来');
      expect(startButton(tester).onPressed, isNull);
    });

    testWidgets('relax-only lock: non-relax disabled; 看放松 filters', (
      tester,
    ) async {
      await pumpApp(
        tester,
        setup: (s) => s.painEvents.addAll([
          PainEvent(DateTime(2026, 10, 16), HipDirection.extension, 'skip'),
          PainEvent(DateTime(2026, 10, 18), HipDirection.extension, 'skip'),
        ]),
      );
      await toPractice(tester);
      await openDrill(tester, 's-kneel-hipflex');
      expect(find.byKey(const ValueKey('notice-locked')), findsOneWidget);
      expect(startButton(tester).label, '这周先只做放松');
      expect(startButton(tester).onPressed, isNull);
      await tester.tap(find.text('看放松'));
      await tester.pumpAndSettle();
      expect(find.byType(DrillDetailPage), findsNothing);
      final n = libraryDrills(content)
          .where(
            (d) => d.directions.contains(HipDirection.extension) && d.isRelax,
          )
          .length;
      expect(find.textContaining('$n 个动作'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('drill-card-s-kneel-hipflex')),
        findsNothing,
      );
    });

    testWidgets('recent pain: hint, still allowed', (tester) async {
      await pumpApp(
        tester,
        setup: (s) => s.painEvents.add(
          PainEvent(DateTime(2026, 10, 17), HipDirection.extension, 'pain'),
        ),
      );
      await toPractice(tester);
      await openDrill(tester, 's-kneel-hipflex');
      expect(find.byKey(const ValueKey('notice-pain')), findsOneWidget);
      expect(startButton(tester).onPressed, isNotNull);
    });

    testWidgets('level 1 + advanced: hint with the easier move, allowed', (
      tester,
    ) async {
      await pumpApp(tester);
      await toPractice(tester);
      await openDrill(tester, 'h-9090-liftoff');
      expect(find.byKey(const ValueKey('notice-advanced')), findsOneWidget);
      expect(find.textContaining('侧卧反向蚌式'), findsWidgets);
      expect(startButton(tester).onPressed, isNotNull);
      expect(startButton(tester).label, '开始练');
    });
  });

  group('我的训练组', () {
    testWidgets('new group: picker → editor → save → card + home row', (
      tester,
    ) async {
      final store = await pumpApp(tester);
      await toPractice(tester, segment: 2);
      expect(find.byKey(const ValueKey('mine-empty')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('new-group')));
      await tester.pumpAndSettle();
      expect(find.byType(DrillPickerPage), findsOneWidget);
      for (final id in ['h-9090-liftoff', 'h-adductor-rock']) {
        await tester.tap(find.byKey(ValueKey('pick-$id')));
        await tester.pump();
      }
      expect(
        tester.widget<Text>(find.byKey(const ValueKey('picker-count'))).data,
        '组里会有 2/20 个',
      );
      await tester.tap(find.byKey(const ValueKey('picker-add')));
      await tester.pumpAndSettle();
      expect(find.byType(GroupEditorPage), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('rest-20')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('editor-save')));
      await tester.pumpAndSettle();
      final g = store.customRoutines.single;
      expect(g.name, '我的训练组 1');
      expect(g.restSeconds, 20);
      expect(g.steps.map((s) => s.kitId), [
        'h-9090-liftoff',
        'h-adductor-rock',
      ]);
      expect(find.byKey(ValueKey('group-card-${g.id}')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('tab-0')));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(ValueKey('home-group-${g.id}')),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.byKey(ValueKey('home-group-${g.id}')), findsOneWidget);
    });

    testWidgets('editor: dose sheet within kit range; discard asks first', (
      tester,
    ) async {
      final store = await pumpApp(
        tester,
        setup: (s) => s.customRoutines.add(
          const CustomRoutine(
            id: 'c_1',
            name: '早上醒髋',
            steps: [CustomStep('s-pigeon')],
          ),
        ),
      );
      await toPractice(tester, segment: 2);
      await tester.tap(find.byKey(const ValueKey('group-card-c_1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('editor-row-0')));
      await tester.pumpAndSettle();
      Text text(String k) => tester.widget<Text>(find.byKey(ValueKey(k)));
      expect(text('dose-value').data, '35 秒');
      for (var i = 0; i < 10; i++) {
        await tester.tap(find.byKey(const ValueKey('dose-value-up')));
        await tester.pump();
      }
      expect(text('dose-value').data, '70 秒'); // 2× default
      await tester.tap(find.byKey(const ValueKey('dose-done')));
      await tester.pumpAndSettle();
      expect(find.textContaining('已调整'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('取消').first);
      await tester.pumpAndSettle();
      expect(find.text('放弃修改？'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('editor-discard')));
      await tester.pumpAndSettle();
      expect(find.byType(GroupEditorPage), findsNothing);
      expect(store.customRoutines.single.steps.single.seconds, isNull);
    });

    testWidgets('routine → copy as my group opens the editor', (tester) async {
      final store = await pumpApp(tester);
      await toPractice(tester, segment: 1);
      await tester.tap(find.byKey(const ValueKey('routine-card-A')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('routine-copy')));
      await tester.pumpAndSettle();
      expect(find.byType(GroupEditorPage), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('editor-save')));
      await tester.pumpAndSettle();
      final g = store.customRoutines.single;
      expect(g.fromRoutine, 'A');
      expect(g.name, endsWith('（我的）'));
      expect(g.steps.length, content.routine('A').steps.length);
    });

    testWidgets('blocked: group ▶ 开始 disabled, routine 开始 disabled', (
      tester,
    ) async {
      await pumpApp(
        tester,
        setup: (s) {
          s.safety = {'pregnancy': true, 'surgery': false, 'acute': false};
          s.customRoutines.add(
            const CustomRoutine(
              id: 'c_1',
              name: 'x',
              steps: [CustomStep('h-squat')],
            ),
          );
        },
      );
      await toPractice(tester, segment: 2);
      expect(
        tester
            .widget<HipPressable>(
              find
                  .ancestor(
                    of: find.text('开始'),
                    matching: find.byType(HipPressable),
                  )
                  .first,
            )
            .onTap,
        isNull,
      );
      await tester.tap(find.byKey(const ValueKey('practice-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('routine-card-A')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<HipPrimaryButton>(
              find.byKey(const ValueKey('routine-start')),
            )
            .onPressed,
        isNull,
      );
    });
  });

  group('small screens', () {
    for (final (size, scale) in [
      (const Size(320, 568), 1.0),
      (const Size(360, 740), 1.5),
    ]) {
      testWidgets('no overflow at $size ×$scale: practice, detail, '
          'editor, picker', (tester) async {
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await pumpApp(
          tester,
          size: size,
          setup: (s) {
            addAssessment(s);
            s.customRoutines.add(
              const CustomRoutine(
                id: 'c_1',
                name: '一二三四五六七八九十一二',
                steps: [
                  CustomStep('t-seated-straddle-lift-1leg', sets: 3),
                  CustomStep('o-stand-crossreach', seconds: 60),
                ],
              ),
            );
          },
        );
        await tester.scrollUntilVisible(
          find.byKey(const ValueKey('home-group-c_1')),
          300,
          scrollable: find.byType(Scrollable).first,
        );
        expect(tester.takeException(), isNull, reason: 'home groups row');
        for (final seg in [0, 1, 2]) {
          await toPractice(tester, segment: seg);
          expect(tester.takeException(), isNull, reason: 'segment $seg');
        }
        await tester.tap(find.byKey(const ValueKey('practice-0')));
        await tester.pumpAndSettle();
        await openDrill(tester, 't-seated-straddle-lift-1leg');
        expect(tester.takeException(), isNull, reason: 'detail');
        Navigator.of(tester.element(find.byType(DrillDetailPage))).pop();
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.byKey(const ValueKey('practice-2')),
          -400,
          scrollable: find
              .descendant(
                of: find.byKey(const ValueKey('practice-list')),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        await tester.tap(find.byKey(const ValueKey('practice-2')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('group-card-c_1')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'editor');
        await tester.tap(find.byKey(const ValueKey('editor-add')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('pick-h-9090-liftoff')));
        await tester.pump();
        expect(tester.takeException(), isNull, reason: 'picker');
      });
    }
  });
}
