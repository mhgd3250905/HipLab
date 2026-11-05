import 'dart:ui' show SemanticsAction;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiplab/hip/control/hip_store.dart';
import 'package:hiplab/hip/domain/hip_models.dart';
import 'package:hiplab/hip/ui/hip_app.dart';
import 'package:hiplab/hip/ui/hip_home_action_deck.dart';
import 'package:hiplab/hip/ui/hip_player_page.dart';
import 'package:hiplab/hip/ui/hip_theme.dart';
import 'package:hiplab/hip/ui/hip_widgets.dart';
import 'package:ugk_trainer_runtime/ugk_trainer_runtime.dart' as trainer;

import 'hip_domain_test.dart' show MemoryStorage, loadContent;
import 'public_media_fixture.dart';
import 'trainer_test_pump.dart';

void main() {
  final content = loadContent();
  late PublicMediaFixture fixture;
  late List<HipDrill> drills;

  setUp(() {
    final previousPalette = HipColors.palette;
    final previousVariants = HipMediaVariants.media;
    fixture = installPublicMediaFixture(sharedLibrary: true);
    drills = content.drills.values
        .where((drill) => fixture.policy.actionFor(drill.id) != null)
        .take(6)
        .toList();
    addTearDown(() {
      HipColors.palette = previousPalette;
      HipMediaVariants.media = previousVariants;
    });
  });

  void phone(WidgetTester tester) {
    tester.view
      ..physicalSize = const Size(394, 853)
      ..devicePixelRatio = 1
      ..padding = const FakeViewPadding(top: 47, bottom: 34);
    addTearDown(tester.view.reset);
  }

  Future<void> showDeck(
    WidgetTester tester, {
    String identity = 'day/home/A',
    List<HipDrill>? items,
    List<String> doses = const [],
    HipPalette palette = HipPalette.dark,
    bool reduced = false,
    double height = 600,
  }) async {
    HipColors.palette = palette;
    await tester.pumpWidget(
      MaterialApp(
        theme: hipTheme(palette),
        themeAnimationDuration: Duration.zero,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
          child: HipMediaPolicy(videoEnabled: false, child: child!),
        ),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 394,
              height: height,
              child: HipHomeActionDeck(
                key: const ValueKey('deck-under-test'),
                identity: identity,
                drills: items ?? drills,
                doses: doses,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Finder arrow(String label) => find.byWidgetPredicate(
    (widget) => widget is HipPressable && widget.semanticLabel == label,
  );

  Future<void> next(WidgetTester tester) async {
    await tester.tap(arrow('下一个动作'));
    await tester.pumpAndSettle();
  }

  String frontId(WidgetTester tester) => tester
      .widget<HipDrillArt>(find.byKey(const ValueKey('home-hero')))
      .drill
      .id;

  String position(WidgetTester tester) => tester
      .widget<Text>(find.byKey(const ValueKey('home-deck-position')))
      .data!;

  GestureDetector deckDrag(WidgetTester tester) => tester
      .widget<GestureDetector>(find.byKey(const ValueKey('home-deck-gesture')));

  void moveCard(GestureDetector drag, double delta) =>
      drag.onHorizontalDragUpdate!(
        DragUpdateDetails(
          globalPosition: Offset.zero,
          delta: Offset(delta, 0),
          primaryDelta: delta,
        ),
      );

  Finder artFor(HipDrill drill) => find.byWidgetPredicate(
    (widget) => widget is HipDrillArt && widget.drill.id == drill.id,
  );

  testWidgets('three visible action cards cycle through every ordered action', (
    tester,
  ) async {
    phone(tester);
    expect(drills, hasLength(6));
    await showDeck(tester);
    await tester.pumpAndSettle();
    for (var i = 0; i < drills.length; i++) {
      expect(find.byType(HipDrillArt), findsNWidgets(3));
      expect(find.byKey(const ValueKey('home-hero')), findsOneWidget);
      expect(frontId(tester), drills[i].id);
      expect(position(tester), '0${i + 1}');
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('home-deck-caption')))
            .data,
        drills[i].name,
      );
      expect(
        tester
            .widgetList<HipDrillArt>(find.byType(HipDrillArt))
            .every((art) => !art.play),
        isTrue,
      );
      await next(tester);
    }
    expect(frontId(tester), drills.first.id);
    await tester.tap(arrow('上一个动作'));
    await tester.pumpAndSettle();
    expect(frontId(tester), drills.last.id);
    expect(fixture.requested, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'front card carries its name, position and dose with the preview image',
    (tester) async {
      phone(tester);
      final doses = [for (var i = 0; i < drills.length; i++) '每侧 ${i + 2} 次'];
      await showDeck(tester, doses: doses);
      await tester.pumpAndSettle();
      final front = find.byKey(const ValueKey('home-deck-front'));
      for (var i = 0; i < drills.length; i++) {
        expect(
          find.descendant(
            of: front,
            matching: find.byKey(const ValueKey('home-deck-caption')),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: front,
            matching: find.byKey(const ValueKey('home-deck-position')),
          ),
          findsOneWidget,
        );
        final image = find.descendant(
          of: front,
          matching: find.byKey(const ValueKey('home-hero')),
        );
        expect(tester.widget<HipDrillArt>(image).drill.id, drills[i].id);
        expect(
          tester
              .widget<Text>(find.byKey(const ValueKey('home-deck-caption')))
              .data,
          drills[i].name,
        );
        expect(position(tester), '0${i + 1}');
        expect(
          find.descendant(of: front, matching: find.text(doses[i])),
          findsOneWidget,
        );
        await next(tester);
      }
      expect(frontId(tester), drills.first.id);
      expect(
        find.descendant(of: front, matching: find.text(doses.first)),
        findsOneWidget,
      );
      expect(fixture.requested, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'new bottom card emerges behind the moving stack before the turn commits',
    (tester) async {
      phone(tester);
      await showDeck(tester);
      await tester.pumpAndSettle();
      final replenishing = find.byKey(const ValueKey('home-deck-opacity-3'));
      expect(replenishing, findsNothing);
      expect(artFor(drills[3]), findsNothing);
      final previousBottom = tester.getRect(artFor(drills[2]));
      final width = tester
          .widget<Positioned>(find.byKey(const ValueKey('home-deck-card-0')))
          .width!;
      final drag = deckDrag(tester);
      drag.onHorizontalDragStart!(DragStartDetails());
      moveCard(drag, -width * .08);
      await tester.pump();
      expect(frontId(tester), drills.first.id);
      expect(find.byType(HipDrillArt), findsNWidgets(4));
      expect(replenishing, findsOneWidget);
      final beginningOpacity = tester.widget<Opacity>(replenishing).opacity;
      expect(beginningOpacity, greaterThan(0));
      expect(beginningOpacity, lessThan(1));
      final incomingRect = tester.getRect(artFor(drills[3]));
      final incomingOpacityElement = tester.element(replenishing);
      final incomingArtElement = tester.element(artFor(drills[3]));
      final incomingMediaElement = tester.element(
        find.descendant(
          of: artFor(drills[3]),
          matching: find.byType(trainer.TrainingLibraryActionArt),
        ),
      );

      moveCard(drag, -width * .97);
      await tester.pump();
      expect(frontId(tester), drills.first.id);
      expect(tester.widget<Opacity>(replenishing).opacity, 1);
      expect(tester.getRect(artFor(drills[3])), incomingRect);
      expect(tester.getRect(artFor(drills[2])), isNot(previousBottom));
      // The incoming artwork is already in its final bottom position. Committing
      // the turn must keep that pose rather than suddenly adding another card.
      drag.onHorizontalDragEnd!(
        DragEndDetails(
          velocity: const Velocity(pixelsPerSecond: Offset(-800, 0)),
          primaryVelocity: -800,
        ),
      );
      await tester.pumpAndSettle();
      expect(frontId(tester), drills[1].id);
      expect(replenishing, findsOneWidget);
      expect(tester.element(replenishing), same(incomingOpacityElement));
      expect(tester.element(artFor(drills[3])), same(incomingArtElement));
      expect(
        tester.element(
          find.descendant(
            of: artFor(drills[3]),
            matching: find.byType(trainer.TrainingLibraryActionArt),
          ),
        ),
        same(incomingMediaElement),
      );
      expect(find.byType(HipDrillArt), findsNWidgets(3));
      final settledRect = tester.getRect(artFor(drills[3]));
      expect(settledRect.left, closeTo(incomingRect.left, .01));
      expect(settledRect.top, closeTo(incomingRect.top, .01));
      expect(settledRect.right, closeTo(incomingRect.right, .01));
      expect(settledRect.bottom, closeTo(incomingRect.bottom, .01));
      expect(fixture.requested, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('cancelled drags withdraw the new bottom card in both directions', (
    tester,
  ) async {
    phone(tester);
    await showDeck(tester);
    await tester.pumpAndSettle();
    final replenishing = find.byKey(const ValueKey('home-deck-opacity-3'));
    final width = tester
        .widget<Positioned>(find.byKey(const ValueKey('home-deck-card-0')))
        .width!;
    final rest = tester.getRect(artFor(drills[2]));
    for (final direction in [-1, 1]) {
      final drag = deckDrag(tester);
      drag.onHorizontalDragStart!(DragStartDetails());
      moveCard(drag, direction * width * .15);
      await tester.pump();
      expect(replenishing, findsOneWidget);
      expect(find.byType(HipDrillArt), findsNWidgets(4));
      drag.onHorizontalDragCancel!();
      await tester.pumpAndSettle();
      expect(position(tester), '01');
      expect(frontId(tester), drills.first.id);
      expect(replenishing, findsNothing);
      expect(find.byType(HipDrillArt), findsNWidgets(3));
      // The rightward preview uses the reverse ordered stack. It may remain
      // ordered that way after cancellation, but the next left drag must restore
      // the same card geometry and never leave an extra card mounted.
      if (direction == -1) expect(tester.getRect(artFor(drills[2])), rest);
      expect(tester.takeException(), isNull);
    }
    expect(fixture.requested, isEmpty);
  });

  testWidgets(
    'two and three action loops replenish without duplicate card keys',
    (tester) async {
      phone(tester);
      for (final count in [2, 3]) {
        final items = drills.take(count).toList();
        await showDeck(tester, identity: 'short/$count', items: items);
        await tester.pumpAndSettle();
        var expectedIndex = 0;
        for (final direction in [1, 1, -1, -1]) {
          final width = tester
              .widget<Positioned>(
                find.byKey(ValueKey('home-deck-card-$expectedIndex')),
              )
              .width!;
          final drag = deckDrag(tester);
          drag.onHorizontalDragStart!(DragStartDetails());
          moveCard(drag, -direction * width * 1.05);
          await tester.pump();
          final reserve = find.byKey(
            ValueKey('home-deck-card-$expectedIndex-reserve'),
          );
          expect(reserve, findsOneWidget);
          expect(find.byType(HipDrillArt), findsNWidgets(count + 1));
          expect(tester.takeException(), isNull);
          drag.onHorizontalDragEnd!(
            DragEndDetails(
              velocity: Velocity(
                pixelsPerSecond: Offset(-direction * 800.0, 0),
              ),
              primaryVelocity: -direction * 800.0,
            ),
          );
          await tester.pumpAndSettle();
          expectedIndex = (expectedIndex + direction) % count;
          expect(frontId(tester), items[expectedIndex].id);
          expect(position(tester), '0${expectedIndex + 1}');
          expect(find.byType(HipDrillArt), findsNWidgets(count));
          expect(reserve, findsNothing);
          expect(tester.takeException(), isNull);
        }
      }
      expect(fixture.requested, isEmpty);
    },
  );

  testWidgets('named arrow actions are independently accessible at 44 points', (
    tester,
  ) async {
    phone(tester);
    final semantics = tester.ensureSemantics();
    await showDeck(tester);
    await tester.pumpAndSettle();
    for (final label in ['上一个动作', '下一个动作']) {
      expect(tester.getSize(arrow(label)), const Size(44, 44));
      expect(find.semantics.byLabel(label), findsOneWidget);
    }
    tester.semantics.tap(find.semantics.byLabel('下一个动作'));
    await tester.pumpAndSettle();
    expect(frontId(tester), drills[1].id);
    tester.semantics.tap(find.semantics.byLabel('上一个动作'));
    await tester.pumpAndSettle();
    expect(frontId(tester), drills.first.id);
    expect(fixture.requested, isEmpty);
    semantics.dispose();
  });

  testWidgets('empty and single-action plans have no navigable extra cards', (
    tester,
  ) async {
    phone(tester);
    await showDeck(tester, items: const []);
    expect(find.byKey(const ValueKey('home-hero')), findsNothing);
    expect(find.byKey(const ValueKey('home-deck-gesture')), findsNothing);
    await showDeck(tester, items: [drills.first]);
    await tester.pumpAndSettle();
    expect(find.byType(HipDrillArt), findsOneWidget);
    expect(position(tester), '01');
    expect(arrow('上一个动作'), findsNothing);
    expect(arrow('下一个动作'), findsNothing);
    await tester.drag(
      find.byKey(const ValueKey('home-deck-gesture')),
      const Offset(-220, 0),
    );
    await tester.pumpAndSettle();
    expect(frontId(tester), drills.first.id);
    expect(fixture.requested, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'semantic adjustment describes and changes the previewed action',
    (tester) async {
      phone(tester);
      final semantics = tester.ensureSemantics();
      await showDeck(tester);
      await tester.pumpAndSettle();
      final preview = find.semantics.byLabel('训练动作预览');
      final data = preview.evaluate().single.getSemanticsData();
      expect(data.value, contains(drills.first.name));
      expect(data.value, contains('共 ${drills.length} 个'));
      expect(data.increasedValue, contains(drills[1].name));
      expect(data.decreasedValue, contains(drills.last.name));
      tester.semantics.performAction(preview, SemanticsAction.increase);
      await tester.pumpAndSettle();
      expect(frontId(tester), drills[1].id);
      tester.semantics.performAction(preview, SemanticsAction.decrease);
      await tester.pumpAndSettle();
      expect(frontId(tester), drills.first.id);
      semantics.dispose();
    },
  );

  testWidgets(
    'a compact available hero height keeps its caption and controls within bounds',
    (tester) async {
      phone(tester);
      await showDeck(tester, height: 240);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('home-deck-caption')), findsOneWidget);
      expect(tester.getSize(arrow('下一个动作')), const Size(44, 44));
      await next(tester);
      expect(frontId(tester), drills[1].id);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('repeated action occurrences remain distinct preview positions', (
    tester,
  ) async {
    phone(tester);
    await showDeck(tester, items: [drills[0], drills[1], drills[0]]);
    await tester.pumpAndSettle();
    expect(position(tester), '01');
    await next(tester);
    expect(frontId(tester), drills[1].id);
    await next(tester);
    expect(frontId(tester), drills[0].id);
    expect(position(tester), '03');
    await next(tester);
    expect(position(tester), '01');
    expect(tester.takeException(), isNull);
  });

  testWidgets('a cancelled return can be caught and reversed without a jump', (
    tester,
  ) async {
    phone(tester);
    await showDeck(tester);
    await tester.pumpAndSettle();
    final area = find.byKey(const ValueKey('home-deck-gesture'));
    final first = await tester.startGesture(tester.getCenter(area));
    await first.moveBy(const Offset(-50, 0));
    await tester.pump(const Duration(milliseconds: 16));
    await first.cancel();
    await tester.pump(const Duration(milliseconds: 16));
    expect(position(tester), '01');
    final returningCenter = tester
        .getRect(find.byKey(const ValueKey('home-deck-front')))
        .center;
    final reverse = await tester.startGesture(tester.getCenter(area));
    await reverse.moveBy(const Offset(30, 0));
    await tester.pump(const Duration(milliseconds: 16));
    final caughtCenter = tester
        .getRect(find.byKey(const ValueKey('home-deck-front')))
        .center;
    expect((caughtCenter.dx - returningCenter.dx).abs(), lessThanOrEqualTo(32));
    await reverse.moveBy(const Offset(210, 0));
    await tester.pump(const Duration(milliseconds: 16));
    await reverse.up();
    await tester.pumpAndSettle();
    expect(frontId(tester), drills.last.id);
    expect(position(tester), '06');
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'a far left preview flicked back right returns without committing',
    (tester) async {
      phone(tester);
      await showDeck(tester);
      await tester.pumpAndSettle();
      final front = find.byKey(const ValueKey('home-deck-front'));
      final rest = tester.getRect(front);
      final drag = tester.widget<GestureDetector>(
        find.byKey(const ValueKey('home-deck-gesture')),
      );
      drag.onHorizontalDragStart!(DragStartDetails());
      drag.onHorizontalDragUpdate!(
        DragUpdateDetails(
          globalPosition: Offset.zero,
          delta: const Offset(-190, 0),
          primaryDelta: -190,
        ),
      );
      await tester.pump();
      expect(tester.getRect(front).center.dx, lessThan(rest.center.dx - 20));
      // Supply the final velocity explicitly: the card is already far left,
      // while this release is a deliberate flick back toward its original stack.
      drag.onHorizontalDragEnd!(
        DragEndDetails(
          velocity: const Velocity(pixelsPerSecond: Offset(1200, 0)),
          primaryVelocity: 1200,
        ),
      );
      await tester.pumpAndSettle();
      expect(frontId(tester), drills.first.id);
      expect(position(tester), '01');
      expect(tester.getRect(front).center.dx, closeTo(rest.center.dx, .5));
      await next(tester);
      expect(frontId(tester), drills[1].id);
      expect(fixture.requested, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'in-flight commits cannot overwrite a new identity or disposed deck',
    (tester) async {
      phone(tester);
      await showDeck(tester);
      await tester.pumpAndSettle();
      await tester.tap(arrow('下一个动作'));
      await tester.pump(const Duration(milliseconds: 32));
      await showDeck(
        tester,
        identity: 'next-day/chair/M',
        items: [drills.last],
      );
      await tester.pumpAndSettle();
      expect(frontId(tester), drills.last.id);
      expect(position(tester), '01');
      await showDeck(tester, identity: 'another-plan');
      await tester.pumpAndSettle();
      await tester.tap(arrow('下一个动作'));
      await tester.pump(const Duration(milliseconds: 32));
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 2));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'initial empty and hidden low-height decks unmount without creating a late ticker',
    (tester) async {
      phone(tester);
      for (final (items, height) in [(<HipDrill>[], 600.0), (drills, 100.0)]) {
        await showDeck(tester, items: items, height: height);
        expect(find.byKey(const ValueKey('home-hero')), findsNothing);
        expect(find.byKey(const ValueKey('home-deck-gesture')), findsNothing);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        expect(tester.takeException(), isNull);
      }
      expect(fixture.requested, isEmpty);
    },
  );

  testWidgets(
    'a viewport width change settles a committing card once at the new geometry',
    (tester) async {
      phone(tester);
      await showDeck(tester);
      await tester.pumpAndSettle();
      await tester.tap(arrow('下一个动作'));
      await tester.pump(const Duration(milliseconds: 32));
      expect(frontId(tester), drills.first.id);
      tester.view.physicalSize = const Size(360, 853);
      await tester.pump();
      expect(frontId(tester), drills[1].id);
      expect(position(tester), '02');
      final viewport = tester.getRect(
        find.byKey(const ValueKey('home-deck-gesture')),
      );
      final front = tester.getRect(
        find.byKey(const ValueKey('home-deck-front')),
      );
      expect(front.center.dx, greaterThan(viewport.left));
      expect(front.center.dx, lessThan(viewport.right));
      await tester.pump(const Duration(seconds: 1));
      expect(position(tester), '02');
      await next(tester);
      expect(frontId(tester), drills[2].id);
      expect(position(tester), '03');
      expect(fixture.requested, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'ordered actions reset while equivalent lists and themes preserve preview',
    (tester) async {
      phone(tester);
      await showDeck(tester);
      await tester.pumpAndSettle();
      await next(tester);
      await showDeck(tester, items: [...drills], palette: HipPalette.light);
      await tester.pumpAndSettle();
      expect(frontId(tester), drills[1].id);
      expect(position(tester), '02');
      for (final art in tester.widgetList<trainer.TrainingLibraryActionArt>(
        find.byType(trainer.TrainingLibraryActionArt),
      )) {
        expect(art.theme!.brightness, Brightness.light);
        expect(art.theme!.mediaStage, HipPalette.light.mediaBackdrop);
        expect(art.playing, isFalse);
      }
      await showDeck(
        tester,
        items: drills.reversed.toList(),
        palette: HipPalette.light,
      );
      await tester.pumpAndSettle();
      expect(frontId(tester), drills.last.id);
      expect(position(tester), '01');
      expect(fixture.requested, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'reduced motion keeps cards still during drag and changes on release',
    (tester) async {
      phone(tester);
      await showDeck(tester, reduced: true);
      await tester.pumpAndSettle();
      final front = find.byKey(const ValueKey('home-deck-front'));
      final before = tester.getRect(front);
      final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(const ValueKey('home-deck-gesture'))),
      );
      await gesture.moveBy(const Offset(-220, 0));
      await tester.pump(const Duration(milliseconds: 16));
      expect(tester.getRect(front), before);
      expect(frontId(tester), drills.first.id);
      await gesture.up();
      await tester.pump();
      expect(frontId(tester), drills[1].id);
      expect(tester.getRect(front), before);
      expect(fixture.requested, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('enabling reduced motion settles an in-flight turn immediately', (
    tester,
  ) async {
    phone(tester);
    await showDeck(tester);
    await tester.pumpAndSettle();
    await tester.tap(arrow('下一个动作'));
    await tester.pump(const Duration(milliseconds: 80));
    await showDeck(tester, reduced: true);
    await tester.pump();
    expect(frontId(tester), drills[1].id);
    await tester.tap(arrow('下一个动作'));
    await tester.pump();
    expect(frontId(tester), drills[2].id);
    expect(tester.takeException(), isNull);
  });

  Future<HipStore> showHome(
    WidgetTester tester,
    MemoryStorage storage, {
    DateTime Function()? clock,
  }) async {
    phone(tester);
    final store = HipStore(
      content: content,
      storage: storage,
      clock: clock ?? () => DateTime(2026, 11, 6, 10),
    );
    await store.initialize();
    store
      ..safety = {'pregnancy': false, 'surgery': false, 'acute': false}
      ..identity = HipIdentity.office
      ..scene = HipScene.home
      ..theme = HipThemeChoice.dark;
    await store.choose();
    await tester.pumpWidget(
      HipApp(store: store, mediaPolicy: fixture.policy, videoEnabled: false),
    );
    await tester.pumpAndSettle();
    addTearDown(store.dispose);
    return store;
  }

  testWidgets(
    'home clips cards at the real screen edges outside its 16 point padding',
    (tester) async {
      final store = await showHome(tester, MemoryStorage());
      final deck = find.byType(HipHomeActionDeck);
      expect(tester.getTopLeft(deck).dx, 16);
      final clipping = find
          .descendant(
            of: find.byKey(const ValueKey('home-deck-gesture')),
            matching: find.byWidgetPredicate(
              (widget) => widget is ClipRect && widget.clipper != null,
            ),
          )
          .first;
      final widget = tester.widget<ClipRect>(clipping);
      final localClip = widget.clipper!.getClip(tester.getSize(clipping));
      final box = tester.renderObject<RenderBox>(clipping);
      expect(box.localToGlobal(localClip.topLeft).dx, closeTo(0, .01));
      expect(box.localToGlobal(localClip.topRight).dx, closeTo(394, .01));
      final title = tester
          .widget<Text>(find.byKey(const ValueKey('home-title')))
          .data;
      await tester.tap(find.byKey(const ValueKey('home-rotate')));
      await tester.pumpAndSettle();
      expect(
        tester.widget<Text>(find.byKey(const ValueKey('home-title'))).data,
        isNot(title),
      );
      await tester.tap(find.byKey(ValueKey('scene-${HipScene.chair}')));
      await tester.pumpAndSettle();
      expect(store.scene, HipScene.chair);
      expect(
        find.byKey(const ValueKey('start-today')).hitTestable(),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('home-more')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('more-list')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('more-back')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('start-today')).hitTestable(),
        findsOneWidget,
      );
      expect(fixture.requested, isEmpty);
      await tester.pumpWidget(const SizedBox.shrink());
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'home preview leaves persisted choices and actual training order unchanged',
    (tester) async {
      final storage = MemoryStorage();
      final store = await showHome(tester, storage);
      final routine = store.sceneRoutines(store.scene).first;
      final expected = store.planForRoutine(routine)!;
      expect(expected.steps.length, greaterThan(1));
      final persisted = Map<String, String>.of(storage.values);
      final scene = store.scene;
      final minutes = store.minutes;
      await tester.drag(
        find.byKey(const ValueKey('home-deck-gesture')),
        const Offset(-190, 0),
      );
      await tester.pumpAndSettle();
      expect(position(tester), isNot('01'));
      expect(store.scene, scene);
      expect(store.minutes, minutes);
      expect(storage.values, persisted);
      expect(fixture.requested, isEmpty);
      await tester.tap(find.byKey(const ValueKey('start-today')));
      await pumpTrainerReady(tester);
      final player = tester.widget<HipPlayerPage>(
        find.byType(HipPlayerPage, skipOffstage: false),
      );
      expect(player.plan.refId, expected.refId);
      expect(
        player.plan.steps.map((step) => step.drill.id),
        expected.steps.map((step) => step.drill.id),
      );
      expect(player.plan.seconds, expected.seconds);
      final experience = trainer.TrainerExperienceScope.maybeOf(
        tester.element(find.byType(HipPlayerPage, skipOffstage: false)),
      )!;
      expect(
        experience.firstPosterAsset,
        fixture.policy.posterAssetFor(expected.steps.first.drill.id),
      );
      expect(storage.values, persisted);
      expect(fixture.requested, isEmpty);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'home resets on day, routine and scene changes but preserves theme preview',
    (tester) async {
      var now = DateTime(2026, 11, 6, 10);
      final store = await showHome(tester, MemoryStorage(), clock: () => now);
      await next(tester);
      final second = frontId(tester);
      await store.setTheme(HipThemeChoice.light);
      await tester.pumpAndSettle();
      expect(frontId(tester), second);
      expect(position(tester), '02');
      await store.choose();
      await tester.pumpAndSettle();
      expect(position(tester), '02');
      now = now.add(const Duration(days: 1));
      await store.choose();
      await tester.pumpAndSettle();
      expect(position(tester), '01');
      await next(tester);
      final identity = tester
          .widget<HipHomeActionDeck>(find.byType(HipHomeActionDeck))
          .identity;
      await tester.tap(find.byKey(const ValueKey('home-rotate')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<HipHomeActionDeck>(find.byType(HipHomeActionDeck))
            .identity,
        isNot(identity),
      );
      expect(position(tester), '01');
      await next(tester);
      await tester.tap(find.byKey(ValueKey('scene-${HipScene.chair}')));
      await tester.pumpAndSettle();
      expect(store.scene, HipScene.chair);
      expect(position(tester), '01');
      await store.setSafety({
        'pregnancy': false,
        'surgery': false,
        'acute': true,
      });
      await tester.pumpAndSettle();
      expect(find.byType(HipHomeActionDeck), findsNothing);
      expect(find.byKey(const ValueKey('start-today')), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
