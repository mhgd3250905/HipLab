import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hiplab/hip/ui/hip_home_routine_folder.dart';
import 'package:hiplab/hip/ui/hip_theme.dart';
import 'package:ugk_trainer_runtime/ugk_trainer_runtime.dart' as trainer;

import 'hip_domain_test.dart' show loadContent;
import 'public_media_fixture.dart';

const _shot = ValueKey('routine-folder-component-shot');
const _entry = ValueKey('home-rotate');
const _panel = ValueKey('home-routine-folder-panel');
const _surface = ValueKey('home-routine-folder-surface');
const _source = ValueKey('home-routine-folder-source');

class _FolderHost extends StatefulWidget {
  const _FolderHost({
    super.key,
    required this.choices,
    required this.onSelected,
    required this.navigatorKey,
    this.reduced = false,
    this.onChooseGroups,
  });
  final List<HipHomeRoutineChoice> choices;
  final ValueChanged<String> onSelected;
  final GlobalKey<NavigatorState> navigatorKey;
  final bool reduced;
  final VoidCallback? onChooseGroups;

  @override
  State<_FolderHost> createState() => _FolderHostState();
}

class _FolderHostState extends State<_FolderHost> {
  late List<HipHomeRoutineChoice> choices = widget.choices;
  String scene = '居家';
  bool visible = true;

  void change({
    List<HipHomeRoutineChoice>? choices,
    String? scene,
    bool? visible,
  }) => setState(() {
    if (choices != null) this.choices = choices;
    if (scene != null) this.scene = scene;
    if (visible != null) this.visible = visible;
  });

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    key: _shot,
    child: MaterialApp(
      // These geometry/selection fixtures use authored Chinese copy.
      locale: const Locale('zh'),
      supportedLocales: const [Locale('zh')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      debugShowCheckedModeBanner: false,
      navigatorKey: widget.navigatorKey,
      theme: hipTheme(HipColors.palette),
      themeAnimationDuration: Duration.zero,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(disableAnimations: widget.reduced),
        child: child!,
      ),
      home: Scaffold(
        backgroundColor: HipColors.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Stack(
              children: [
                Positioned(
                  top: 14,
                  left: 4,
                  child: Text(
                    '今天的训练',
                    style: TextStyle(
                      color: HipColors.text,
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (visible)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: HipHomeRoutineFolder(
                      key: _entry,
                      choices: choices,
                      selectedId: widget.choices.firstOrNull?.id ?? '',
                      sceneLabel: scene,
                      onSelected: widget.onSelected,
                      onChooseGroups: widget.onChooseGroups,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  final content = loadContent();
  late PublicMediaFixture fixture;
  late List<HipHomeRoutineChoice> choices;

  setUpAll(() async {
    if (Platform.environment['HIPLAB_ROUTINE_FOLDER_ARTIFACT_DIR'] != null) {
      final font = FontLoader(hipFontFamily)
        ..addFont(rootBundle.load('assets/fonts/NotoSansSC.ttf'));
      await font.load();
    }
  });

  setUp(() {
    final previous = HipColors.palette;
    final previousShadows = HipColors.flatShadows;
    // flutter_tester does not blur BoxShadow. These component exports omit
    // shadows rather than presenting the tester's hard edge as device output.
    if (Platform.environment['HIPLAB_ROUTINE_FOLDER_ARTIFACT_DIR'] != null) {
      HipColors.flatShadows = true;
    }
    fixture = installPublicMediaFixture();
    final drills = content.drills.values
        .where((drill) => fixture.policy.actionFor(drill.id) != null)
        .take(10)
        .toList();
    const names = ['睡前开胯', '晨起唤醒', '久坐解压', '训练前激活', '舞前准备'];
    choices = [
      for (var i = 0; i < names.length; i++)
        HipHomeRoutineChoice(
          id: 'group-$i',
          title: names[i],
          subtitle: '跟着动作慢慢练',
          minutes: i + 5,
          drills: drills.sublist(i * 2, i * 2 + 2),
        ),
    ];
    addTearDown(() {
      HipColors.palette = previous;
      HipColors.flatShadows = previousShadows;
    });
  });

  Future<(GlobalKey<_FolderHostState>, GlobalKey<NavigatorState>, List<String>)>
  mount(
    WidgetTester tester, {
    Size size = const Size(394, 853),
    HipPalette palette = HipPalette.dark,
    bool reduced = false,
    List<HipHomeRoutineChoice>? items,
    VoidCallback? onChooseGroups,
  }) async {
    tester.view
      ..physicalSize = size
      ..devicePixelRatio = 1
      ..padding = const FakeViewPadding(top: 24, bottom: 24);
    addTearDown(tester.view.reset);
    HipColors.palette = palette;
    final host = GlobalKey<_FolderHostState>();
    final navigator = GlobalKey<NavigatorState>();
    final selected = <String>[];
    await tester.pumpWidget(
      _FolderHost(
        key: host,
        choices: items ?? choices,
        navigatorKey: navigator,
        reduced: reduced,
        onSelected: selected.add,
        onChooseGroups: onChooseGroups,
      ),
    );
    await tester.pumpAndSettle();
    return (host, navigator, selected);
  }

  Future<void> open(WidgetTester tester) async {
    await tester.tap(find.byKey(_entry));
    await tester.pumpAndSettle();
    expect(find.byKey(_panel), findsOneWidget);
  }

  double sourceOpacity(WidgetTester tester) =>
      tester.widget<Opacity>(find.byKey(_source)).opacity;

  Future<void> closeFrames(
    WidgetTester tester,
    ModalRoute<dynamic> route,
  ) async {
    for (var frame = 0; frame < 24; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
      if (route.animation!.status == AnimationStatus.dismissed ||
          find.byKey(_surface).evaluate().isEmpty) {
        expect(
          sourceOpacity(tester),
          1,
          reason:
              'the source must be visible in the same closing handoff frame',
        );
      }
    }
    await tester.pumpAndSettle();
    expect(find.byKey(_panel), findsNothing);
    expect(sourceOpacity(tester), 1);
  }

  Future<void> exportExpanded(WidgetTester tester, String name) async {
    final directory =
        Platform.environment['HIPLAB_ROUTINE_FOLDER_ARTIFACT_DIR'];
    if (directory == null) return;
    final context = tester.element(find.byKey(_entry));
    final assets = tester
        .widgetList<trainer.TrainerPoster>(find.byType(trainer.TrainerPoster))
        .map((poster) => poster.asset)
        .toSet();
    final width = trainer.TrainingPosterImages.decodeWidth(context);
    final bundle = DefaultAssetBundle.of(context);
    final configuration = createLocalImageConfiguration(context);
    var allDecoded = false;
    for (var attempt = 0; attempt < 100; attempt++) {
      final statuses = await tester.runAsync(
        () => Future.wait([
          for (final asset in assets)
            trainer.TrainingPosterImages.provider(
              asset,
              width,
              bundle: bundle,
            ).obtainCacheStatus(configuration: configuration),
        ]),
      );
      allDecoded = statuses!.every(
        (status) =>
            status != null &&
            !status.pending &&
            (status.keepAlive || status.live),
      );
      if (allDecoded) break;
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
    }
    expect(allDecoded, isTrue, reason: 'export actual decoded poster artwork');
    await tester.pump();
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(_shot),
    );
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      Directory(directory).createSync(recursive: true);
      File('$directory/$name.png').writeAsBytesSync(data!.buffer.asUint8List());
      image.dispose();
    });
  }

  testWidgets(
    'closed folder previews real groups in fixed row-first slots without invented cells',
    (tester) async {
      for (var count = 0; count <= 5; count++) {
        final items = choices.take(count).toList();
        await mount(tester, items: items);
        final source = tester.getRect(find.byKey(_source));
        final trigger = tester.getRect(find.byKey(_entry));
        expect(source.size, Size(64, count < 2 ? 36 : 64));
        expect(trigger.size, Size(64, count < 2 ? 44 : 64));
        expect(source.bottomRight, trigger.bottomRight);
        final shown = items.take(4).toList();
        expect(find.byType(trainer.TrainerPoster), findsNWidgets(shown.length));
        final posters = tester
            .widgetList<trainer.TrainerPoster>(
              find.byType(trainer.TrainerPoster),
            )
            .map((poster) => poster.asset);
        expect(posters, [
          for (final choice in shown)
            fixture.policy.posterAssetFor(choice.drills.first.id),
        ]);
        final cells = [
          for (final choice in shown)
            find.byKey(ValueKey('home-routine-preview-${choice.id}')),
        ];
        for (var i = 0; i < cells.length; i++) {
          expect(cells[i], findsOneWidget);
          expect(
            tester.getRect(cells[i]),
            Rect.fromLTWH(
              source.left + 6 + (i % 2) * 28,
              source.top + 6 + (i ~/ 2) * 28,
              24,
              24,
            ),
            reason: 'group count must not recenter the fixed folder slots',
          );
        }
        for (final absent in choices.skip(shown.length)) {
          expect(
            find.byKey(ValueKey('home-routine-preview-${absent.id}')),
            findsNothing,
          );
        }
        if (count == 2) {
          await exportExpanded(tester, 'folder-two-closed');
        } else if (count == 4) {
          await exportExpanded(tester, 'folder-four-closed');
        }
        expect(find.byType(trainer.TrainingActionMedia), findsNothing);
        expect(find.byType(trainer.UgkPackedAlphaVideo), findsNothing);
        expect(fixture.requested, isEmpty);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      }
    },
  );

  testWidgets(
    'changing two groups to four and back replaces preview cells without stale actions',
    (tester) async {
      final two = choices.take(2).toList();
      final (host, _, selected) = await mount(tester, items: two);
      final folder = tester.state(find.byType(HipHomeRoutineFolder));
      final original = tester.getRect(find.byKey(_entry));
      final originalCells = {
        for (final item in two)
          item.id: tester.getRect(
            find.byKey(ValueKey('home-routine-preview-${item.id}')),
          ),
      };
      for (final items in [choices.take(4).toList(), two]) {
        host.currentState!.change(choices: items);
        await tester.pumpAndSettle();
        expect(tester.state(find.byType(HipHomeRoutineFolder)), same(folder));
        expect(tester.getRect(find.byKey(_entry)), original);
        for (final entry in originalCells.entries) {
          expect(
            tester.getRect(
              find.byKey(ValueKey('home-routine-preview-${entry.key}')),
            ),
            entry.value,
          );
        }
        expect(find.byType(trainer.TrainerPoster), findsNWidgets(items.length));
        expect(
          tester
              .widgetList<trainer.TrainerPoster>(
                find.byType(trainer.TrainerPoster),
              )
              .map((poster) => poster.asset),
          [
            for (final choice in items)
              fixture.policy.posterAssetFor(choice.drills.first.id),
          ],
        );
        for (final item in choices) {
          expect(
            find.byKey(ValueKey('home-routine-preview-${item.id}')),
            items.any((choice) => choice.id == item.id)
                ? findsOneWidget
                : findsNothing,
          );
        }
      }
      expect(find.byType(trainer.TrainingActionMedia), findsNothing);
      expect(find.byType(trainer.UgkPackedAlphaVideo), findsNothing);
      expect(selected, isEmpty);
      expect(fixture.requested, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'folder keeps its source bottom-right fixed while opening up-left and closing along the same path',
    (tester) async {
      for (final scenario in [
        (const Size(320, 700), 5),
        (const Size(394, 853), 5),
        (const Size(740, 360), 5),
        (const Size(394, 853), 2),
        (const Size(394, 853), 1),
      ]) {
        final (size, count) = scenario;
        final items = choices.take(count).toList();
        final (_, navigator, selected) = await mount(
          tester,
          size: size,
          items: items,
        );
        final origin = tester.getRect(find.byKey(_source));
        final closedCells = {
          for (final choice in items.take(4))
            choice.id: tester.getRect(
              find.byKey(ValueKey('home-routine-preview-${choice.id}')),
            ),
        };
        final anchor = origin.bottomRight;
        expect(origin.size, Size(64, count < 2 ? 36 : 64));

        void anchored(Rect rect) {
          expect(rect.right, closeTo(anchor.dx, .01));
          expect(rect.bottom, closeTo(anchor.dy, .01));
          expect(rect.left, greaterThanOrEqualTo(20 - .01));
          expect(rect.top, greaterThanOrEqualTo(44 - .01));
          expect(rect.right, lessThan(size.width));
          expect(rect.bottom, lessThan(size.height));
        }

        if (size.width == 394 && count == 5) {
          await exportExpanded(tester, 'folder-anchor-closed');
        }
        await tester.tap(find.byKey(_entry));
        await tester.pump();
        final route = ModalRoute.of(tester.element(find.byKey(_panel)))!;
        expect(route.transitionDuration, const Duration(milliseconds: 360));
        final gridLayout = tester.getRect(find.byKey(_panel));
        anchored(gridLayout);
        var previous = tester.getRect(find.byKey(_surface));
        expect(previous, origin);
        for (final entry in closedCells.entries) {
          expect(
            tester.getRect(
              find.byKey(ValueKey('home-routine-flying-${entry.key}')),
            ),
            entry.value,
          );
        }
        expect(sourceOpacity(tester), 0);
        for (var frame = 0; frame < 24; frame++) {
          await tester.pump(const Duration(milliseconds: 16));
          final current = tester.getRect(find.byKey(_surface));
          anchored(current);
          expect(current.width, greaterThanOrEqualTo(previous.width - .01));
          expect(current.height, greaterThanOrEqualTo(previous.height - .01));
          expect(current.left, lessThanOrEqualTo(previous.left + .01));
          expect(current.top, lessThanOrEqualTo(previous.top + .01));
          expect(tester.getRect(find.byKey(_panel)), gridLayout);
          previous = current;
          if (size.width == 394 && count == 5 && frame == 7) {
            await exportExpanded(tester, 'folder-anchor-opening-128ms');
          }
        }
        expect(previous, gridLayout);
        expect(selected, isEmpty);
        if (size.width == 394 && count == 5) {
          await exportExpanded(tester, 'folder-anchor-open');
        }

        await tester.tapAt(const Offset(2, 2));
        await tester.pump();
        previous = gridLayout;
        for (var frame = 0; frame < 24; frame++) {
          await tester.pump(const Duration(milliseconds: 16));
          final floating = find.byKey(_surface);
          final current = floating.evaluate().isNotEmpty
              ? tester.getRect(floating)
              : tester.getRect(find.byKey(_source));
          anchored(current);
          expect(current.width, lessThanOrEqualTo(previous.width + .01));
          expect(current.height, lessThanOrEqualTo(previous.height + .01));
          expect(current.left, greaterThanOrEqualTo(previous.left - .01));
          expect(current.top, greaterThanOrEqualTo(previous.top - .01));
          if (route.animation!.status == AnimationStatus.dismissed ||
              floating.evaluate().isEmpty) {
            expect(sourceOpacity(tester), 1);
            for (final entry in closedCells.entries) {
              expect(
                tester.getRect(
                  find.byKey(ValueKey('home-routine-preview-${entry.key}')),
                ),
                entry.value,
              );
              final flying = find.byKey(
                ValueKey('home-routine-flying-${entry.key}'),
              );
              if (flying.evaluate().isNotEmpty) {
                expect(tester.getRect(flying), entry.value);
              }
            }
          }
          previous = current;
          if (size.width == 394 && count == 5 && frame == 7) {
            await exportExpanded(tester, 'folder-anchor-closing-128ms');
          }
        }
        await tester.pumpAndSettle();
        expect(find.byKey(_panel), findsNothing);
        expect(previous, origin);
        expect(tester.getRect(find.byKey(_source)), origin);
        expect(sourceOpacity(tester), 1);
        expect(navigator.currentState!.canPop(), isFalse);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      }
    },
  );

  testWidgets('barrier, Escape, Android back and early back cancel safely', (
    tester,
  ) async {
    final (_, navigator, selected) = await mount(tester);
    var exitRequests = 0;
    final messenger = tester.binding.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'SystemNavigator.pop') exitRequests++;
      return null;
    });
    addTearDown(
      () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
    );
    for (final method in ['barrier', 'escape', 'back', 'early-back']) {
      if (method == 'early-back') {
        await tester.tap(find.byKey(_entry));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 64));
      } else {
        await open(tester);
      }
      final route = ModalRoute.of(tester.element(find.byKey(_panel)))!;
      switch (method) {
        case 'barrier':
          await tester.tapAt(const Offset(5, 5));
        case 'escape':
          await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        case 'back' || 'early-back':
          await tester.binding.handlePopRoute();
          await tester.pump(const Duration(milliseconds: 32));
          await tester.binding.handlePopRoute();
          await tester.pump(const Duration(milliseconds: 16));
          await tester.binding.handlePopRoute();
      }
      await closeFrames(tester, route);
      expect(
        selected,
        isEmpty,
        reason: '$method must not choose a training group',
      );
      expect(navigator.currentState!.canPop(), isFalse);
      expect(find.text('今天的训练'), findsOneWidget);
      expect(
        exitRequests,
        0,
        reason: 'repeated closing Back must not exit Home',
      );
      expect(find.byType(trainer.TrainingActionMedia), findsNothing);
      expect(fixture.requested, isEmpty);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets(
    'selection reports once only after the return animation finishes',
    (tester) async {
      final (_, navigator, selected) = await mount(tester);
      await open(tester);
      final route = ModalRoute.of(tester.element(find.byKey(_panel)))!;
      expect(
        route.reverseTransitionDuration,
        const Duration(milliseconds: 300),
      );
      final choice = find.byKey(
        ValueKey('home-routine-choice-${choices[2].id}'),
      );
      await tester.ensureVisible(choice);
      await tester.pumpAndSettle();
      await tester.tap(choice);
      expect(selected, isEmpty);
      await tester.pump();
      for (var frame = 0; frame < 15; frame++) {
        await tester.pump(const Duration(milliseconds: 16));
        expect(selected, isEmpty);
      }
      await tester.pumpAndSettle();
      expect(selected, [choices[2].id]);
      expect(navigator.currentState!.canPop(), isFalse);
      expect(sourceOpacity(tester), 1);
      await tester.pump(const Duration(seconds: 1));
      expect(selected, [choices[2].id]);
      expect(fixture.requested, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'normal phones and landscape keep every group reachable in both themes',
    (tester) async {
      for (final palette in [HipPalette.dark, HipPalette.light]) {
        for (final size in [const Size(320, 700), const Size(394, 853)]) {
          final (_, navigator, selected) = await mount(
            tester,
            palette: palette,
            size: size,
          );
          await open(tester);
          final panel = tester.getRect(find.byKey(_panel));
          expect(panel.left, greaterThan(0));
          expect(panel.top, greaterThanOrEqualTo(44));
          expect(panel.right, lessThan(size.width));
          expect(panel.bottom, lessThanOrEqualTo(size.height - 44));
          for (final choice in choices) {
            final tile = find.byKey(
              ValueKey('home-routine-choice-${choice.id}'),
            );
            await tester.ensureVisible(tile);
            await tester.pumpAndSettle();
            expect(tile.hitTestable(), findsOneWidget);
          }
          if (size.width == 394) {
            await tester.drag(
              find.byKey(const ValueKey('home-routine-folder-grid')),
              const Offset(0, 1000),
            );
            await tester.pumpAndSettle();
            await exportExpanded(
              tester,
              palette == HipPalette.dark
                  ? 'folder-dark-expanded'
                  : 'folder-light-expanded',
            );
          }
          await tester.tapAt(const Offset(2, 2));
          await tester.pumpAndSettle();
          expect(selected, isEmpty);
          expect(navigator.currentState!.canPop(), isFalse);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
        }
      }
      final (_, _, selected) = await mount(tester, size: const Size(740, 360));
      await open(tester);
      final grid = find.byKey(const ValueKey('home-routine-folder-grid'));
      final scrollable = find.descendant(
        of: grid,
        matching: find.byType(Scrollable),
      );
      final scroll = tester.state<ScrollableState>(scrollable);
      expect(scroll.position.maxScrollExtent, greaterThan(0));
      final last = find.byKey(
        ValueKey('home-routine-choice-${choices.last.id}'),
      );
      await tester.scrollUntilVisible(last, 150, scrollable: scrollable);
      await tester.pumpAndSettle();
      expect(last.hitTestable(), findsOneWidget);
      await tester.tap(last);
      await tester.pumpAndSettle();
      expect(selected, [choices.last.id]);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('reduced motion opens and selects without a timed transition', (
    tester,
  ) async {
    final (_, navigator, selected) = await mount(tester, reduced: true);
    await tester.tap(find.byKey(_entry));
    await tester.pump();
    final route = ModalRoute.of(tester.element(find.byKey(_panel)))!;
    expect(route.transitionDuration, Duration.zero);
    expect(route.reverseTransitionDuration, Duration.zero);
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(ValueKey('home-routine-choice-${choices.first.id}')),
    );
    await tester.pumpAndSettle();
    expect(selected, [choices.first.id]);
    expect(navigator.currentState!.canPop(), isFalse);
    expect(find.byKey(_panel), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'corner add button opens the 训练组 entry; pure fixtures keep no close button',
    (tester) async {
      var opens = 0;
      await mount(tester, items: const [], onChooseGroups: () => opens++);
      await open(tester);
      final entry = find.byKey(const ValueKey('home-routine-choose-groups'));
      expect(entry, findsOneWidget);
      expect(
        find.byKey(const ValueKey('home-routine-folder-close')),
        findsNothing,
      );
      // The entry sits in the header, above the scrollable grid.
      expect(
        tester.getRect(entry).bottom,
        lessThanOrEqualTo(
          tester
              .getTopLeft(
                find.byKey(const ValueKey('home-routine-folder-grid')),
              )
              .dy,
        ),
      );
      await tester.tap(entry);
      await tester.pumpAndSettle();
      expect(find.byKey(_panel), findsNothing);
      expect(opens, 1);
      expect(find.byKey(_entry), findsOneWidget);

      // Component fixtures without the callback keep a pure selection panel.
      await tester.pumpWidget(const SizedBox.shrink());
      await mount(tester);
      await open(tester);
      expect(
        find.byKey(const ValueKey('home-routine-choose-groups')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'changed scene, unavailable choices and unmount retire the open snapshot',
    (tester) async {
      final (host, navigator, selected) = await mount(tester);
      await open(tester);
      host.currentState!.change(scene: '办公');
      await tester.pumpAndSettle();
      expect(find.byKey(_panel), findsNothing);
      expect(selected, isEmpty);
      expect(navigator.currentState!.canPop(), isFalse);

      await open(tester);
      host.currentState!.change(choices: choices.take(2).toList());
      await tester.pumpAndSettle();
      expect(find.byKey(_panel), findsNothing);
      expect(selected, isEmpty);
      expect(navigator.currentState!.canPop(), isFalse);

      await tester.tap(find.byKey(_entry));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));
      host.currentState!.change(visible: false);
      await tester.pumpAndSettle();
      expect(find.byType(HipHomeRoutineFolder), findsNothing);
      expect(find.byKey(_panel), findsNothing);
      expect(selected, isEmpty);
      expect(navigator.currentState!.canPop(), isFalse);
      expect(fixture.requested, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('scene chips name each 套路 and the header lists the scenes', (
    tester,
  ) async {
    const scenes = ['办公', '居家'];
    final pair = [
      for (var i = 0; i < scenes.length; i++)
        HipHomeRoutineChoice(
          id: 'scene-$i',
          sceneLabel: scenes[i],
          title: choices[i].title,
          subtitle: choices[i].subtitle,
          minutes: choices[i].minutes,
          drills: choices[i].drills,
        ),
    ];
    final (_, _, selected) = await mount(tester, items: pair);
    await open(tester);
    expect(find.text('首页训练组'), findsOneWidget);
    expect(find.text('居家 · 首页文件夹'), findsOneWidget);
    for (final scene in scenes) {
      expect(find.text(scene), findsOneWidget);
    }
    final grid = find.byKey(const ValueKey('home-routine-folder-grid'));
    final first = find.byKey(const ValueKey('home-routine-choice-scene-0'));
    final second = find.byKey(const ValueKey('home-routine-choice-scene-1'));
    // Two 套路 share one row: neither is stretched to the whole panel.
    expect(
      tester.getSize(first).width,
      closeTo((tester.getSize(grid).width - 40 - 14) / 2, .5),
    );
    expect(tester.getTopLeft(first).dy, tester.getTopLeft(second).dy);
    final semantics = tester.ensureSemantics();
    try {
      await tester.pump();
      expect(find.bySemanticsLabel(RegExp('居家，')), findsOneWidget);
    } finally {
      semantics.dispose();
    }
    await tester.tap(second);
    await tester.pumpAndSettle();
    expect(selected, ['scene-1']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a single 套路 occupies the first column of the two-column grid', (
    tester,
  ) async {
    final solo = [
      HipHomeRoutineChoice(
        id: 'only',
        title: choices.first.title,
        subtitle: choices.first.subtitle,
        minutes: choices.first.minutes,
        drills: choices.first.drills,
      ),
    ];
    final (_, _, selected) = await mount(tester, items: solo);
    await open(tester);
    final grid = find.byKey(const ValueKey('home-routine-folder-grid'));
    final tile = find.byKey(const ValueKey('home-routine-choice-only'));
    expect(
      tester.getSize(tile).width,
      closeTo((tester.getSize(grid).width - 40 - 14) / 2, .5),
    );
    // No scene chip: the header names the scene 首页 is already on.
    expect(find.text('居家 · 首页文件夹'), findsOneWidget);
    expect(tester.getRect(tile).left, tester.getRect(grid).left + 20);
    await tester.tap(tile);
    await tester.pumpAndSettle();
    expect(selected, ['only']);
    expect(tester.takeException(), isNull);
  });
}
