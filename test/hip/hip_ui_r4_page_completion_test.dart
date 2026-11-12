import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiplab/hip/control/hip_store.dart';
import 'package:hiplab/hip/domain/hip_models.dart';
import 'package:hiplab/hip/domain/hip_library.dart';
import 'package:hiplab/hip/domain/hip_session.dart';
import 'package:hiplab/hip/ui/hip_page_kit.dart';
import 'package:hiplab/hip/ui/hip_assessment_page.dart';
import 'package:hiplab/hip/ui/hip_privacy_page.dart';
import 'package:hiplab/hip/ui/hip_routes.dart';
import 'package:hiplab/hip/ui/hip_theme.dart';
import 'package:hiplab/hip/ui/hip_widgets.dart';
import 'package:hiplab/hip/ui/library/action_filter.dart';
import 'package:hiplab/hip/ui/library/drill_detail_page.dart';
import 'package:hiplab/hip/ui/library/group_editor_page.dart';
import 'package:hiplab/hip/ui/library/library_actions.dart';
import 'package:hiplab/hip/ui/library/library_widgets.dart';
import 'package:hiplab/hip/ui/library/lib_text.dart';
import 'package:hiplab/hip/ui/library/practice_page.dart';
import 'package:hiplab/hip/ui/library/routine_detail_page.dart';

import 'hip_domain_test.dart' show MemoryStorage, loadContent;
import 'public_media_fixture.dart';

void main() {
  final content = loadContent();

  Future<LibraryActions> actions() async {
    final store = HipStore(content: content, storage: MemoryStorage());
    await store.initialize();
    store
      ..safety = {'pregnancy': false, 'surgery': false, 'acute': false}
      ..identity = HipIdentity.office;
    return LibraryActions(
      store: store,
      startPlan: (_, {from, radius = 31, originColor}) async {},
    );
  }

  Future<void> openPage(
    WidgetTester tester,
    Widget page, {
    Locale locale = const Locale('zh'),
  }) async {
    tester.view
      ..physicalSize = const Size(390, 844)
      ..devicePixelRatio = 1
      ..padding = const FakeViewPadding(top: 47, bottom: 34);
    addTearDown(tester.view.reset);
    installPublicMediaFixture();
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        supportedLocales: const [Locale('zh'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: hipTheme(),
        builder: (_, child) =>
            HipMediaPolicy(videoEnabled: false, child: child!),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(
                context,
              ).push(HipRoute.content<void>((_) => page, pinLeading: false)),
              child: const Text('open-page'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open-page'));
    await tester.pumpAndSettle();
  }

  void expectBelowBar(WidgetTester tester, Finder firstContent) {
    final bar = tester.getRect(find.byType(HipNavBar));
    expect(tester.getRect(firstContent).top, greaterThanOrEqualTo(bar.bottom));
    expect(tester.takeException(), isNull);
  }

  testWidgets('routine subtitle leaves the first content below the frost', (
    tester,
  ) async {
    final a = await actions();
    final routine = content.routines.first;
    await openPage(
      tester,
      RoutineDetailPage(actions: a, routineId: routine.id),
    );
    expectBelowBar(tester, find.text(routine.audience));
  });

  testWidgets('drill subtitle leaves its media below the frost', (
    tester,
  ) async {
    final a = await actions();
    await openPage(
      tester,
      DrillDetailPage(actions: a, drillId: 'h-adductor-rock'),
    );
    expectBelowBar(
      tester,
      find
          .descendant(
            of: find.byKey(const ValueKey('detail-list')),
            matching: find.byType(HipMediaFrame),
          )
          .first,
    );
  });

  testWidgets('picker subtitle leaves its filters below the frost', (
    tester,
  ) async {
    final a = await actions();
    await openPage(
      tester,
      DrillPickerPage(actions: a, groupName: 'A group', existing: const []),
    );
    expectBelowBar(tester, find.byType(ActionFilterBar));
  });

  testWidgets('copying a routine opens the shared-bar editor and saves it', (
    tester,
  ) async {
    final a = await actions();
    final routine = content.routines.first;
    await openPage(
      tester,
      RoutineDetailPage(actions: a, routineId: routine.id),
    );
    await tester.tap(find.byKey(const ValueKey('routine-copy')));
    await tester.pumpAndSettle();
    final route =
        ModalRoute.of(tester.element(find.byType(GroupEditorPage)))!
            as HipRoute;
    expect(route.transition, HipTransition.content);
    expect(route.pinLeading, isTrue);
    await tester.tap(find.byKey(const ValueKey('editor-save')));
    await tester.pumpAndSettle();
    expect(find.byType(GroupEditorPage), findsNothing);
    expect(find.byType(RoutineDetailPage), findsOneWidget);
    expect(
      a.store.customRoutines.single.steps.map((step) => step.kitId),
      routine.steps.map((step) => step.drillId),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'new group from a drill uses shared-bar editor and saves the drill',
    (tester) async {
      final a = await actions();
      await openPage(
        tester,
        DrillDetailPage(actions: a, drillId: 'h-adductor-rock'),
      );
      await tester.tap(find.byKey(const ValueKey('detail-add')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('add-new-group')));
      await tester.pumpAndSettle();
      final route =
          ModalRoute.of(tester.element(find.byType(GroupEditorPage)))!
              as HipRoute;
      expect(route.transition, HipTransition.content);
      expect(route.pinLeading, isTrue);
      await tester.tap(find.byKey(const ValueKey('editor-save')));
      await tester.pumpAndSettle();
      expect(find.byType(DrillDetailPage), findsOneWidget);
      expect(
        a.store.customRoutines.single.steps.single.kitId,
        'h-adductor-rock',
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('privacy explains downloading and offline cache limitations', (
    tester,
  ) async {
    await openPage(tester, const HipPrivacyPage());
    final media = find.textContaining('尚未缓存的视频在离线时可能无法播放');
    await tester.scrollUntilVisible(
      media,
      300,
      scrollable: find
          .descendant(
            of: find.byType(HipPrivacyPage),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(media, findsOneWidget);
    expect(find.textContaining('动作视频随应用内置'), findsNothing);
    expect(find.textContaining('127.0.0.1'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a group exports independent edit and named start actions', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final original = await actions();
    var starts = 0;
    final a = LibraryActions(
      store: original.store,
      startPlan: (plan, {from, radius = 31, originColor}) async {
        starts++;
        expect(plan.steps.single.drill.id, 'h-adductor-rock');
      },
    );
    const group = CustomRoutine(
      id: 'c_accessible',
      name: 'Named group',
      steps: [CustomStep('h-adductor-rock')],
    );
    await openPage(
      tester,
      Scaffold(
        body: Center(
          child: GroupCard(actions: a, group: group),
        ),
      ),
      locale: const Locale('en'),
    );
    final edit = find.semantics.byLabel(RegExp(r'^Named group$'));
    final start = find.semantics.byLabel(RegExp(r'^Start Named group$'));
    expect(edit, findsOneWidget);
    expect(start, findsOneWidget);
    final startNode = start.evaluate().single;
    // The pill merges its own icon/text, but never into the card's edit node.
    var exportedStart = startNode;
    while (exportedStart.isMergedIntoParent) {
      exportedStart = exportedStart.parent!;
    }
    expect(exportedStart.id, isNot(edit.evaluate().single.id));
    expect(startNode.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);

    tester.semantics.tap(start);
    await tester.pumpAndSettle();
    expect(starts, 1);
    expect(find.byType(GroupEditorPage), findsNothing);
    await tester.tap(find.byKey(const ValueKey('group-start-c_accessible')));
    await tester.pumpAndSettle();
    expect(starts, 2);
    expect(find.byType(GroupEditorPage), findsNothing);

    tester.semantics.tap(edit);
    await tester.pumpAndSettle();
    expect(find.byType(GroupEditorPage), findsOneWidget);
    expect(starts, 2);
    await tester.tap(find.byKey(const ValueKey('editor-close')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Named group'));
    await tester.pumpAndSettle();
    expect(find.byType(GroupEditorPage), findsOneWidget);
    expect(starts, 2);
    expect(tester.takeException(), isNull);
    handle.dispose();
  });

  testWidgets('推荐套路 offers all authored 套路 and home controls', (tester) async {
    final a = await actions();
    await openPage(
      tester,
      PracticePage(
        actions: a,
        memory: PracticeMemory()..segment = 1,
        homeScene: HipScene.chair,
        onStartAssessment: ({from, radius = 31, color}) {},
      ),
    );
    expect(a.store.libraryRoutines.map((r) => r.id), [
      'A',
      'B',
      'C',
      'D',
      'E',
      'F',
      'M',
    ]);
    expect(find.text(LibText.zh.routinesCount(7)), findsOneWidget);
    expect(find.byKey(const ValueKey('home-scene-note')), findsOneWidget);
    // A is the 办公 default; B is not yet in the folder.
    expect(find.byKey(const ValueKey('home-added-routine-A')), findsOneWidget);
    expect(find.byKey(const ValueKey('home-toggle-routine-A')), findsOneWidget);
    expect(find.byKey(const ValueKey('home-added-routine-B')), findsNothing);
    // Removing is a destructive action: red text, the add pill stays jade.
    Color pillText(String id) => tester
        .widget<Text>(
          find.descendant(
            of: find.byKey(ValueKey('home-toggle-routine-$id')),
            matching: find.byType(Text),
          ),
        )
        .style!
        .color!;
    expect(pillText('A'), HipColors.pain);
    expect(pillText('B'), HipColors.jadeText);
    final add = find.byKey(const ValueKey('home-toggle-routine-B'));
    await tester.ensureVisible(add);
    await tester.pumpAndSettle();
    await tester.tap(add);
    await tester.pumpAndSettle();
    expect(a.store.homeRoutines(HipScene.chair), ['A', 'B']);
    expect(find.byKey(const ValueKey('home-added-routine-B')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'routine card and detail show the same adapted timing and count',
    (tester) async {
      final a = await actions();
      final routine = content.routines.first;
      final plan = a.store.planner.planFor([routine], a.store.profile);
      await openPage(
        tester,
        PracticePage(
          actions: a,
          memory: PracticeMemory()..segment = 1,
          onStartAssessment: ({from, radius = 31, color}) {},
        ),
        locale: const Locale('en'),
      );
      final card = find.byKey(ValueKey('routine-card-${routine.id}'));
      await tester.ensureVisible(card);
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: card,
          matching: find.text(LibText.en.minutes(plan.minutes)),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: card,
          matching: find.textContaining(
            LibText.en.movesCount(plan.steps.length),
          ),
        ),
        findsOneWidget,
      );
      await tester.tap(card);
      await tester.pumpAndSettle();
      expect(find.byType(RoutineDetailPage), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('routine-minutes')),
          matching: find.text('${plan.minutes}'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('routine-moves')),
          matching: find.text('${plan.steps.length}'),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'assessment intro clears the bar, starts and closes back to intro',
    (tester) async {
      final a = await actions();
      await openPage(tester, AssessmentIntroPage(actions: a));
      expect(find.byType(HipNavPage), findsOneWidget);
      final page = tester.widget<HipNavPage>(find.byType(HipNavPage));
      expect(page.bodyScrollsUnderBar, isTrue);
      expectBelowBar(tester, find.textContaining('6 个动作 · 约 3 分 30 秒'));
      final start = find.byKey(const ValueKey('assessment-start'));
      expect(tester.getRect(start).bottom, lessThanOrEqualTo(844 - 34));
      final before = a.store.assessments.length;
      await tester.tap(start);
      await tester.pumpAndSettle();
      expect(find.byType(HipAssessmentPage), findsOneWidget);
      final close = find.descendant(
        of: find.byType(HipTopBar),
        matching: find.byType(HipNavBackChip),
      );
      expect(close, findsOneWidget);
      expect(tester.getRect(close).size, const Size(44, 44));
      await tester.tap(close);
      await tester.pumpAndSettle();
      expect(find.byType(HipAssessmentPage), findsNothing);
      expect(find.byType(AssessmentIntroPage), findsOneWidget);
      expect(a.store.assessments.length, before);
      await tester.tap(find.byKey(const ValueKey('intro-back')));
      await tester.pumpAndSettle();
      expect(find.text('open-page'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('assessment intro start stays enabled with legacy safety data', (
    tester,
  ) async {
    final a = await actions();
    a.store.safety = {'pregnancy': false, 'surgery': false, 'acute': true};
    await openPage(tester, AssessmentIntroPage(actions: a));
    final start = tester.widget<HipPrimaryButton>(
      find.byKey(const ValueKey('assessment-start')),
    );
    expect(start.onPressed, isNotNull);
    expect(start.label, isNot('先问问医生再来'));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'result route sheet cancels in place and starts the chosen plan',
    (tester) async {
      final a = await actions();
      final started = <TrainingPlan>[];
      await openPage(
        tester,
        HipAssessmentPage(
          store: a.store,
          onStartPlan: (plan) async => started.add(plan),
        ),
      );
      for (var attempt = 0; attempt < 12; attempt++) {
        if (find.byKey(const ValueKey('result-other')).evaluate().isNotEmpty) {
          break;
        }
        await tester.tap(find.byKey(const ValueKey('option-2')));
        await tester.pump();
        await tester.tap(find.byKey(const ValueKey('assessment-next')));
        await tester.pumpAndSettle();
      }
      expect(a.store.assessments, hasLength(1));
      final other = find.byKey(const ValueKey('result-other'));
      await tester.tap(other);
      await tester.pumpAndSettle();
      expect(find.text('换一条路线'), findsNWidgets(2));
      expect(find.text('选择路线后开始训练'), findsOneWidget);
      expect(find.byType(ListTile), findsNothing);
      tester.state<NavigatorState>(find.byType(Navigator).first).pop();
      await tester.pumpAndSettle();
      expect(other, findsOneWidget);
      expect(find.text('选择路线后开始训练'), findsNothing);
      expect(started, isEmpty);

      final routine = content.routines.firstWhere((r) => !r.micro);
      final expected = a.store.planner.planFor([routine], a.store.profile);
      await tester.tap(other);
      await tester.pumpAndSettle();
      final row = find.byKey(ValueKey('result-route-${routine.id}'));
      await tester.ensureVisible(row);
      expect(
        find.descendant(
          of: row,
          matching: find.text(routineShortName(routine)),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: row, matching: find.text('${expected.minutes} 分钟')),
        findsOneWidget,
      );
      await tester.tap(row);
      await tester.pumpAndSettle();
      expect(started, hasLength(1));
      expect(started.single.refId, expected.refId);
      expect(started.single.minutes, expected.minutes);
      expect(
        started.single.steps.map((step) => step.drill.id),
        expected.steps.map((step) => step.drill.id),
      );
      expect(find.byType(HipAssessmentPage), findsNothing);
      expect(find.text('open-page'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
