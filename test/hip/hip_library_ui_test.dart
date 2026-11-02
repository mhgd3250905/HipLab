// 练习库 UI (拍板 2026-10-19): 3 tabs with the check-up card on 练习,
// 动作大全 / detail / 单练, safety notices, 我的 → picker → editor.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiplab/hip/control/hip_store.dart';
import 'package:hiplab/hip/data/hip_action_scope.dart';
import 'package:hiplab/hip/domain/hip_assessment.dart';
import 'package:hiplab/hip/domain/hip_library.dart';
import 'package:hiplab/hip/domain/hip_models.dart';
import 'package:hiplab/hip/domain/hip_pain.dart';
import 'package:hiplab/hip/ui/hip_app.dart';
import 'package:hiplab/hip/ui/hip_assessment_page.dart';
import 'package:hiplab/hip/ui/hip_player_page.dart';
import 'package:hiplab/hip/ui/hip_widgets.dart';
import 'package:hiplab/hip/ui/library/group_editor_page.dart';
import 'package:ugk_coach/ugk_coach.dart' as coach;
import 'package:ugk_trainer_runtime/ugk_trainer_runtime.dart' as trainer;

import 'hip_domain_test.dart' show MemoryStorage, loadContent;
import 'public_media_fixture.dart';

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
    final fixture = installPublicMediaFixture(sharedLibrary: true);
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
    await tester.pumpWidget(
      HipApp(store: store, videoEnabled: false, mediaPolicy: fixture.policy),
    );
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
    final page = tester.widget<trainer.TrainingLibraryPage>(
      find.byType(trainer.TrainingLibraryPage),
    );
    await tester.enterText(
      find.byKey(const ValueKey('posehub-search')),
      page.mediaPolicy.actionFor(id)!.nameZh,
    );
    await tester.pumpAndSettle();
    final card = find.byKey(ValueKey('posehub-action-$id'));
    await tester.ensureVisible(card);
    await tester.pumpAndSettle();
    final prepared = await tester.runAsync(
      () => trainer.TrainingPosterImages.prepareAsset(
        tester.element(card),
        page.mediaPolicy.posterAssetFor(id)!,
      ),
    );
    expect(prepared, isTrue);
    await tester.tap(card);
    await tester.pumpAndSettle();
    expect(find.byType(trainer.TrainingLibraryDetail), findsOneWidget);
  }

  FilledButton startButton(WidgetTester tester) => tester.widget<FilledButton>(
    find.byKey(const ValueKey('library-detail-start')),
  );

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

  group('SDK 动作库与宿主单练', () {
    testWidgets(
      '45 scoped actions; SDK Chinese search and category filtering',
      (tester) async {
        await pumpApp(tester);
        await toPractice(tester);
        final page = tester.widget<trainer.TrainingLibraryPage>(
          find.byType(trainer.TrainingLibraryPage),
        );
        expect(page.config.allowedActionIds, hiplabCoachAuthorizedActionIds);
        expect(find.byKey(const ValueKey('lib-search')), findsNothing);
        int visibleCount() =>
            (tester
                        .widget<GridView>(
                          find.byKey(const ValueKey('posehub-action-list')),
                        )
                        .childrenDelegate
                    as SliverChildBuilderDelegate)
                .childCount!;
        expect(visibleCount(), 45);
        await tester.enterText(
          find.byKey(const ValueKey('posehub-search')),
          page.mediaPolicy.actionFor('s-pigeon')!.nameZh,
        );
        await tester.pumpAndSettle();
        expect(visibleCount(), 1);
        expect(
          find.byKey(const ValueKey('posehub-action-s-pigeon')),
          findsOneWidget,
        );
        await tester.enterText(
          find.byKey(const ValueKey('posehub-search')),
          '',
        );
        await tester.tap(find.byKey(const ValueKey('posehub-类型-拉伸放松')));
        await tester.pumpAndSettle();
        final expected = page.config
            .actions(page.mediaPolicy.catalog)
            .where(
              (action) => trainer.PoseHubActionFacets.type(action) == '拉伸放松',
            )
            .length;
        expect(visibleCount(), expected);
        expect(expected, greaterThan(0));
      },
    );

    testWidgets(
      'SDK detail starts host default dose; exit logs single without streak',
      (tester) async {
        final store = await pumpApp(tester);
        await toPractice(tester);
        await openDrill(tester, 's-figure4');
        final detail = tester.widget<trainer.TrainingLibraryDetail>(
          find.byType(trainer.TrainingLibraryDetail),
        );
        expect(detail.action.id, 's-figure4');
        expect(startButton(tester).onPressed, isNotNull);
        final start = find.byKey(const ValueKey('library-detail-start'));
        await tester.ensureVisible(start);
        await tester.tap(start);
        await tester.pumpAndSettle(const Duration(milliseconds: 100));
        final player = tester.widget<HipPlayerPage>(find.byType(HipPlayerPage));
        expect(player.plan.source, PlanSource.single);
        expect(player.plan.steps.single.sets, 1);
        expect(player.plan.steps.single.kitDose.seconds, 60);
        await tester.tap(find.byKey(const ValueKey('close')));
        await tester.pump(const Duration(milliseconds: 400));
        await tester.tap(find.byKey(const ValueKey('close-confirm')));
        await tester.pumpAndSettle();
        expect(find.byType(HipPlayerPage), findsNothing);
        expect(store.sessions.single.source, PlanSource.single);
        expect(store.doneDays, isEmpty);
      },
    );

    testWidgets(
      'host safety disables SDK start while details remain browsable',
      (tester) async {
        await pumpApp(
          tester,
          setup: (store) => store.safety = {
            'pregnancy': true,
            'surgery': false,
            'acute': false,
          },
        );
        await toPractice(tester);
        await openDrill(tester, 's-figure4');
        expect(startButton(tester).onPressed, isNull);
      },
    );

    testWidgets('host relaxation lock disables non-relax SDK action', (
      tester,
    ) async {
      await pumpApp(
        tester,
        setup: (store) => store.painEvents.addAll([
          PainEvent(DateTime(2026, 10, 16), HipDirection.extension, 'skip'),
          PainEvent(DateTime(2026, 10, 18), HipDirection.extension, 'skip'),
        ]),
      );
      await toPractice(tester);
      await openDrill(tester, 's-kneel-hipflex');
      expect(startButton(tester).onPressed, isNull);
    });

    testWidgets('recent pain retains the host allowed practice decision', (
      tester,
    ) async {
      await pumpApp(
        tester,
        setup: (store) => store.painEvents.add(
          PainEvent(DateTime(2026, 10, 17), HipDirection.extension, 'pain'),
        ),
      );
      await toPractice(tester);
      await openDrill(tester, 's-kneel-hipflex');
      expect(startButton(tester).onPressed, isNotNull);
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

  testWidgets(
    'add action protects complete coach plans while ordinary groups stay editable',
    (tester) async {
      final completePlan = coach.TrainingPlan(
        id: 'complete-native-plan',
        source: 'ai',
        title: '完整计划',
        goal: 'mobility',
        scene: 'home',
        level: 1,
        targetMinutes: 2,
        blocks: [
          coach.PlanBlock(
            id: 'circuit',
            name: '保留两轮',
            type: coach.BlockType.main,
            rounds: 2,
            items: [
              coach.PlanItem(
                exerciseId: 's-butterfly',
                mode: coach.DoseMode.time,
                sets: 1,
                workSeconds: 30,
                restSeconds: 7,
                perSide: false,
              ),
            ],
          ),
        ],
      ).toJson();
      final store = await pumpApp(
        tester,
        setup: (store) {
          store.customRoutines.addAll([
            CustomRoutine(
              id: 'sdk-plan',
              name: '完整计划',
              steps: const [CustomStep('s-butterfly', seconds: 30)],
              restSeconds: 7,
              coachPlan: completePlan,
            ),
            const CustomRoutine(
              id: 'ordinary-plan',
              name: '普通训练组',
              steps: [CustomStep('s-pigeon')],
            ),
          ]);
        },
      );
      await toPractice(tester, segment: 2);
      await tester.tap(find.byKey(const ValueKey('group-card-ordinary-plan')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('editor-add')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('pick-h-adductor-rock')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('picker-add')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('editor-save')));
      await tester.pumpAndSettle();
      expect(
        store.customRoutine('ordinary-plan')!.steps.map((step) => step.kitId),
        ['s-pigeon', 'h-adductor-rock'],
      );
      expect(store.customRoutine('sdk-plan')!.coachPlan, completePlan);
      expect(store.customRoutine('sdk-plan')!.steps, hasLength(1));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('SDK detail closes back to host group editor and picker', (
    tester,
  ) async {
    await pumpApp(
      tester,
      setup: (store) => store.customRoutines.add(
        const CustomRoutine(
          id: 'c_1',
          name: '我的组',
          steps: [CustomStep('s-pigeon')],
        ),
      ),
    );
    await toPractice(tester);
    await openDrill(tester, 's-pigeon');
    Navigator.of(
      tester.element(find.byType(trainer.TrainingLibraryDetail)),
    ).pop();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('practice-2')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('group-card-c_1')));
    await tester.pumpAndSettle();
    expect(find.byType(GroupEditorPage), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('editor-add')));
    await tester.pumpAndSettle();
    expect(find.byType(DrillPickerPage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
