// 练习库 UI (拍板 2026-10-19): 3 tabs with the check-up card on 练习,
// 动作大全 / detail / 单练, safety notices, 我的 → picker → editor.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiplab/hip/control/hip_store.dart';
import 'package:hiplab/hip/data/hip_action_scope.dart';
import 'package:hiplab/hip/data/hip_library_poster_bounds.dart';
import 'package:hiplab/hip/data/hip_public_media.dart';
import 'package:hiplab/hip/data/hip_shared_library.dart';
import 'package:hiplab/hip/domain/hip_library.dart';
import 'package:hiplab/hip/domain/hip_models.dart';
import 'package:hiplab/hip/domain/hip_pain.dart';
import 'package:hiplab/hip/ui/hip_app.dart';
import 'package:hiplab/hip/ui/hip_assessment_page.dart';
import 'package:hiplab/hip/ui/hip_player_page.dart';
import 'package:hiplab/hip/ui/hip_page_kit.dart';
import 'package:hiplab/hip/ui/hip_widgets.dart';
import 'package:hiplab/hip/ui/library/action_filter.dart';
import 'package:hiplab/hip/ui/library/group_editor_page.dart';
import 'package:ugk_coach/ugk_coach.dart' as coach;
import 'package:ugk_trainer_runtime/ugk_trainer_runtime.dart' as trainer;

import 'hip_domain_test.dart' show MemoryStorage, loadContent;
import 'home_nav.dart';
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
    // UI r2: 0 is 动作库; 1 推荐套路 / 2 我的 live on 训练组.
    if (segment == 0) {
      await openPractice(tester);
    } else {
      await openGroups(tester);
    }
    await tester.pumpAndSettle();
    if (segment != 0) {
      await tester.tap(find.byKey(ValueKey('practice-$segment')));
      await tester.pumpAndSettle();
    }
  }

  Future<void> openDrill(WidgetTester tester, String id) async {
    // UI r2 M3: HipLab 动作库 → the SDK detail.
    final policy = HipPublicMedia.current!;
    await tester.enterText(
      find.byKey(const ValueKey('lib-search')),
      policy.actionFor(id)!.nameZh,
    );
    await tester.pumpAndSettle();
    final card = find.byKey(ValueKey('drill-card-$id'));
    await tester.ensureVisible(card);
    await tester.pumpAndSettle();
    final prepared = await tester.runAsync(
      () => trainer.TrainingPosterImages.prepareAsset(
        tester.element(card),
        policy.posterAssetFor(id)!,
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

  group('tabs (拍板 1)', () {
    // Home r1 (2026-11-02): no tab bar; 更多 holds the former tabs.
    testWidgets('no tab bar; 更多 lists the entries; no 自测 tab', (tester) async {
      await pumpApp(tester);
      expect(find.byKey(const ValueKey('tab-0')), findsNothing);
      await openMore(tester);
      for (final label in ['我的训练组', '动作库', '髋部自测', '训练记录', '设置']) {
        expect(find.text(label), findsOneWidget, reason: label);
      }
      expect(find.text('自测'), findsNothing);
      // UI r2: 训练组 is 我的 / 推荐套路 — no 自测 card, no 动作 tab.
      await toPractice(tester, segment: 2);
      expect(find.byKey(const ValueKey('hip-check-card')), findsNothing);
      for (final s in ['我的', '推荐套路']) {
        expect(find.text(s), findsOneWidget);
      }
      expect(find.text('动作'), findsNothing);
      expect(find.byKey(const ValueKey('practice-0')), findsNothing);
    });

    testWidgets('更多 髋部自测 → intro page → the check-up', (tester) async {
      await pumpApp(tester);
      await openMore(tester);
      await tester.tap(find.byKey(const ValueKey('more-checkup')));
      await tester.pumpAndSettle();
      // The former 自测 tab content is kept as the intro page.
      expect(find.text('髋部自测'), findsOneWidget);
      expect(find.text('开始自测'), findsOneWidget);
      for (final item in content.rules.items) {
        expect(find.byKey(ValueKey('intro-item-${item.id}')), findsOneWidget);
      }
      await tester.tap(find.byKey(const ValueKey('assessment-start')));
      await tester.pumpAndSettle();
      expect(find.byType(HipAssessmentPage), findsOneWidget);
    });

    // UI r2: the 自测 card left 训练组; the last result's radar moves to
    // the intro page in M4.
  });

  group('SDK 动作库与宿主单练', () {
    testWidgets('248 scoped actions (测试演示 excluded); search and 怎么练 filter', (
      tester,
    ) async {
      await pumpApp(tester);
      await toPractice(tester);
      expect(find.byType(trainer.TrainingLibraryPage), findsNothing);

      final cards = find.byType(ActionCard);
      final first = tester.getRect(cards.at(0));
      final second = tester.getRect(cards.at(1));
      expect(first.size, const Size(154, 196));
      expect(second.size, first.size);
      expect(second.top, first.top);
      expect(second.left - first.right, 12);
      final artwork = find.descendant(
        of: cards.first,
        matching: find.byType(ClipRect),
      );
      final id = tester.widget<ActionCard>(cards.first).item.id;
      final fitted = applyBoxFit(
        BoxFit.contain,
        libraryPosterBounds[id]!.size,
        const Size(126, 88),
      ).destination;
      final artworkRect = tester.getRect(artwork);
      expect(artworkRect.width, closeTo(fitted.width, .001));
      expect(artworkRect.height, closeTo(fitted.height, .001));
      expect(artworkRect.center.dx, closeTo(first.center.dx, .001));
      expect(artworkRect.center.dy, closeTo(first.top + 88, .001));
      final image = tester.widget<Image>(
        find.descendant(of: artwork, matching: find.byType(Image)),
      );
      expect(
        (image.image as AssetImage).assetName,
        HipPublicMedia.thumbnailAssetFor(id),
      );

      String count() => tester
          .widget<Text>(find.byKey(const ValueKey('actions-count')))
          .data!;
      final config = HipSharedLibrary.current!;
      expect(config.allowedActionIds, hiplabCoachAuthorizedActionIds);
      expect(count(), '248 个动作');
      for (final id in assessmentOnlyDrills) {
        expect(find.byKey(ValueKey('drill-card-$id')), findsNothing);
      }
      await tester.enterText(
        find.byKey(const ValueKey('lib-search')),
        HipPublicMedia.current!.actionFor('s-pigeon')!.nameZh,
      );
      await tester.pumpAndSettle();
      expect(count(), '1 个动作');
      expect(find.byKey(const ValueKey('drill-card-s-pigeon')), findsOneWidget);
      await tester.enterText(find.byKey(const ValueKey('lib-search')), '');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('action-filter')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('filter-group-part')), findsOneWidget);
      await tester.ensureVisible(
        find.byKey(const ValueKey('filter-type-拉伸放松')),
      );
      await tester.tap(find.byKey(const ValueKey('filter-type-拉伸放松')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('filter-apply')));
      await tester.pumpAndSettle();
      final expected = config
          .actions(HipPublicMedia.current!.catalog)
          .where(
            (action) =>
                !assessmentOnlyDrills.contains(action.id) &&
                trainer.PoseHubActionFacets.type(action) == '拉伸放松',
          )
          .length;
      expect(expected, greaterThan(0));
      expect(count(), '$expected 个动作');
      expect(find.byKey(const ValueKey('action-filter-badge')), findsOneWidget);
    });

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
      'legacy safety answers leave SDK start enabled and details browsable',
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
        expect(startButton(tester).onPressed, isNotNull);
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
      tester.view.padding = const FakeViewPadding(top: 47, bottom: 34);
      await tester.pumpAndSettle();
      await toPractice(tester, segment: 2);
      final leadingRect = tester.getRect(find.byType(HipNavBackChip));
      expect(leadingRect, const Rect.fromLTWH(16, 47, 44, 44));
      expect(find.byKey(const ValueKey('mine-empty')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('new-group')));
      await tester.pumpAndSettle();
      expect(find.byType(DrillPickerPage), findsOneWidget);
      expect(tester.getRect(find.byType(HipNavBackChip)), leadingRect);
      for (final id in ['h-9090-liftoff', 'h-adductor-rock']) {
        await tapCard(tester, ValueKey('pick-$id'));
        await tester.pump();
      }
      expect(
        tester.widget<Text>(find.byKey(const ValueKey('picker-count'))).data,
        '组里会有 2/20 个',
      );
      await tester.tap(find.byKey(const ValueKey('picker-add')));
      await tester.pumpAndSettle();
      expect(find.byType(GroupEditorPage), findsOneWidget);
      expect(tester.getRect(find.byType(HipNavBackChip)), leadingRect);
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
      expect(tester.getRect(find.byType(HipNavBackChip)), leadingRect);
      // Home r1: groups moved from 首页 to 更多 › 我的训练组.
      await openMore(tester);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('more-groups')),
          matching: find.text('1 组'),
        ),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('more-groups')));
      await tester.pumpAndSettle();
      expect(find.byKey(ValueKey('group-card-${g.id}')), findsOneWidget);
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
      await tester.tap(find.byKey(const ValueKey('editor-close')));
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

    testWidgets('legacy safety answers do not disable group or routine start', (
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
        isNotNull,
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
        isNotNull,
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
      await tapCard(tester, const ValueKey('pick-h-adductor-rock'));
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
    // UI r2: the groups live on 训练组, not on 动作库.
    await toPractice(tester, segment: 2);
    await tester.tap(find.byKey(const ValueKey('group-card-c_1')));
    await tester.pumpAndSettle();
    expect(find.byType(GroupEditorPage), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('editor-add')));
    await tester.pumpAndSettle();
    expect(find.byType(DrillPickerPage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
