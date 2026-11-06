import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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
    List<String> cues = const [],
    List<String> descriptions = const [],
    HipPalette palette = HipPalette.dark,
    bool reduced = false,
    bool videoEnabled = false,
    double height = 600,
  }) async {
    HipColors.palette = palette;
    await tester.pumpWidget(
      MaterialApp(
        theme: hipTheme(palette),
        themeAnimationDuration: Duration.zero,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
          child: HipMediaPolicy(videoEnabled: videoEnabled, child: child!),
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
                cues: cues,
                descriptions: descriptions,
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

  void moveCard(GestureDetector drag, double delta) => drag.onPanUpdate!(
    DragUpdateDetails(
      globalPosition: Offset.zero,
      delta: Offset(delta, 0),
      primaryDelta: delta,
    ),
  );

  Finder artFor(HipDrill drill) => find.byWidgetPredicate(
    (widget) => widget is HipDrillArt && widget.drill.id == drill.id,
  );

  Finder sourceCards() => find.byWidgetPredicate(
    (widget) =>
        widget is Positioned &&
        widget.key is ValueKey<String> &&
        (widget.key! as ValueKey<String>).value.startsWith('home-deck-card-'),
  );

  Finder visualFront() {
    final floating = find.byKey(const ValueKey('home-deck-floating-front'));
    return floating.evaluate().isEmpty
        ? find.byKey(const ValueKey('home-deck-front'))
        : floating;
  }

  double keyedOpacity(WidgetTester tester, String key) {
    final finder = find.byKey(ValueKey(key));
    return finder.evaluate().isEmpty
        ? 0
        : tester.widget<Opacity>(finder).opacity;
  }

  void expectCardPainted(WidgetTester tester) {
    final source = keyedOpacity(tester, 'home-deck-opacity-0');
    final snapshot = keyedOpacity(tester, 'home-deck-closing-stand-in');
    final expanded = keyedOpacity(tester, 'home-deck-expanded-opacity');
    final surface = keyedOpacity(tester, 'home-deck-flight-surface');
    // Complementary face opacities alone still expose the background. Check
    // their composited coverage together with the physical card surface.
    final coverage = 1 - (1 - snapshot) * (1 - expanded) * (1 - surface);
    expect(
      source >= .99 || coverage >= .99,
      isTrue,
      reason:
          'No complete card face is painted: source=$source, '
          'snapshot=$snapshot, expanded=$expanded, surface=$surface',
    );
    if (snapshot > 0) {
      final image = find.descendant(
        of: find.byKey(const ValueKey('home-deck-closing-stand-in')),
        matching: find.byType(RawImage),
      );
      expect(image, findsOneWidget);
      expect(tester.widget<RawImage>(image).image, isNotNull);
    }
  }

  Future<void> openActionCard(WidgetTester tester) async {
    await tester.tapAt(
      tester.getCenter(find.byKey(const ValueKey('home-hero'))),
    );
    await tester.pump();
  }

  Future<void> dismissActionCard(WidgetTester tester, String method) async {
    if (method == 'close') {
      await tester.tap(arrow('收起动作卡片'));
    } else if (method == 'barrier') {
      final rect = tester.getRect(
        find.byKey(const ValueKey('home-deck-expanded')),
      );
      await tester.tapAt(Offset(3, rect.center.dy));
    } else {
      await tester.binding.handlePopRoute();
    }
  }

  Future<void> expectFrameSafeDismissal(WidgetTester tester) async {
    await tester.pump();
    expectCardPainted(tester);
    for (var elapsed = 0; elapsed < 448; elapsed += 16) {
      await tester.pump(const Duration(milliseconds: 16));
      expectCardPainted(tester);
      // In the final compact frames the expanded layout and its close glyph
      // must no longer be painted over the source card.
      if (elapsed >= 368) {
        expect(
          keyedOpacity(tester, 'home-deck-expanded-opacity'),
          lessThan(.01),
        );
      }
    }
    for (var i = 0; i < 2; i++) {
      await tester.pump();
      expectCardPainted(tester);
    }
    expect(keyedOpacity(tester, 'home-deck-opacity-0'), 1);
    expect(find.byKey(const ValueKey('home-deck-expanded')), findsNothing);
    expect(
      find.byKey(const ValueKey('home-deck-closing-stand-in')),
      findsNothing,
    );
    expect(position(tester), '01');
    expect(tester.takeException(), isNull);
  }

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
      drag.onPanStart!(DragStartDetails());
      moveCard(drag, -width * .08);
      await tester.pump();
      expect(frontId(tester), drills.first.id);
      expect(sourceCards(), findsNWidgets(4));
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
      drag.onPanEnd!(
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
      drag.onPanStart!(DragStartDetails());
      moveCard(drag, direction * width * .15);
      await tester.pump();
      expect(replenishing, findsOneWidget);
      expect(sourceCards(), findsNWidgets(4));
      drag.onPanCancel!();
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
          drag.onPanStart!(DragStartDetails());
          moveCard(drag, -direction * width * 1.05);
          await tester.pump();
          final reserve = find.byKey(
            ValueKey('home-deck-card-$expectedIndex-reserve'),
          );
          expect(reserve, findsOneWidget);
          expect(sourceCards(), findsNWidgets(count + 1));
          expect(tester.takeException(), isNull);
          drag.onPanEnd!(
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
    final returningCenter = tester.getRect(visualFront()).center;
    final reverse = await tester.startGesture(tester.getCenter(area));
    await reverse.moveBy(const Offset(30, 0));
    await tester.pump(const Duration(milliseconds: 16));
    final caughtCenter = tester.getRect(visualFront()).center;
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
    'a fast flick inside the central region returns without committing',
    (tester) async {
      phone(tester);
      await showDeck(tester);
      await tester.pumpAndSettle();
      final front = find.byKey(const ValueKey('home-deck-front'));
      final rest = tester.getRect(front);
      final drag = tester.widget<GestureDetector>(
        find.byKey(const ValueKey('home-deck-gesture')),
      );
      drag.onPanStart!(DragStartDetails());
      drag.onPanUpdate!(
        DragUpdateDetails(
          globalPosition: Offset.zero,
          delta: const Offset(-55, 0),
        ),
      );
      await tester.pump();
      expect(
        tester.getRect(visualFront()).center.dx,
        lessThan(rest.center.dx - 20),
      );
      // Velocity alone cannot turn a card that remains in the central region.
      drag.onPanEnd!(
        DragEndDetails(
          velocity: const Velocity(pixelsPerSecond: Offset(-2400, 0)),
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
    'vertical and diagonal drags follow the hand and return on cancel',
    (tester) async {
      phone(tester);
      await showDeck(tester);
      await tester.pumpAndSettle();
      final rest = tester.getRect(visualFront());
      final drag = deckDrag(tester);
      drag.onPanStart!(DragStartDetails());
      drag.onPanUpdate!(
        DragUpdateDetails(
          globalPosition: Offset.zero,
          delta: const Offset(0, 170),
        ),
      );
      await tester.pump();
      final floating = find.byKey(const ValueKey('home-deck-floating-front'));
      expect(floating, findsOneWidget);
      expect(
        tester.getRect(floating).center.dy,
        greaterThan(rest.center.dy + 120),
      );
      expect(position(tester), '01');
      drag.onPanEnd!(DragEndDetails());
      await tester.pumpAndSettle();
      expect(frontId(tester), drills.first.id);
      expect(floating, findsNothing);
      expect(
        tester.getRect(visualFront()).center.dy,
        closeTo(rest.center.dy, .5),
      );

      final diagonal = deckDrag(tester);
      diagonal.onPanStart!(DragStartDetails());
      diagonal.onPanUpdate!(
        DragUpdateDetails(
          globalPosition: Offset.zero,
          delta: const Offset(65, -130),
        ),
      );
      await tester.pump();
      final moved = tester.getRect(floating);
      expect(moved.center.dx, greaterThan(rest.center.dx + 35));
      expect(moved.center.dy, lessThan(rest.center.dy - 90));
      diagonal.onPanCancel!();
      await tester.pumpAndSettle();
      expect(position(tester), '01');
      expect(floating, findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('dragged front floats beyond both vertical edges of the deck', (
    tester,
  ) async {
    phone(tester);
    await showDeck(tester, height: 360);
    await tester.pumpAndSettle();
    final deckBounds = tester.getRect(
      find.byKey(const ValueKey('home-deck-gesture')),
    );
    final floating = find.byKey(const ValueKey('home-deck-floating-front'));
    final drag = deckDrag(tester);
    drag.onPanStart!(DragStartDetails());
    drag.onPanUpdate!(
      DragUpdateDetails(
        globalPosition: Offset.zero,
        delta: const Offset(0, -210),
      ),
    );
    await tester.pump();
    expect(tester.getRect(floating).top, lessThan(deckBounds.top));
    drag.onPanUpdate!(
      DragUpdateDetails(
        globalPosition: Offset.zero,
        delta: const Offset(0, 440),
      ),
    );
    await tester.pump();
    expect(tester.getRect(floating).bottom, greaterThan(deckBounds.bottom));
    expect(find.byKey(const ValueKey('home-hero')), findsOneWidget);
    expect(find.byKey(const ValueKey('home-deck-position')), findsOneWidget);
    drag.onPanCancel!();
    await tester.pumpAndSettle();
    expect(floating, findsNothing);
    expect(position(tester), '01');
    expect(tester.takeException(), isNull);
  });

  testWidgets('only the horizontal side regions commit a released card', (
    tester,
  ) async {
    phone(tester);
    await showDeck(tester);
    await tester.pumpAndSettle();
    for (final (distance, expected) in [
      (-75.0, '01'),
      (-140.0, '02'),
      (140.0, '01'),
      (75.0, '01'),
    ]) {
      final drag = deckDrag(tester);
      drag.onPanStart!(DragStartDetails());
      moveCard(drag, distance);
      await tester.pump();
      drag.onPanEnd!(DragEndDetails());
      await tester.pumpAndSettle();
      expect(position(tester), expected);
      expect(
        find.byKey(const ValueKey('home-deck-floating-front')),
        findsNothing,
      );
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'vertical-dominant releases return even after crossing a horizontal threshold',
    (tester) async {
      phone(tester);
      await showDeck(tester);
      await tester.pumpAndSettle();
      final rest = tester.getRect(visualFront());
      final floating = find.byKey(const ValueKey('home-deck-floating-front'));
      for (final delta in [const Offset(130, 500), const Offset(-130, -500)]) {
        final drag = deckDrag(tester);
        drag.onPanStart!(DragStartDetails());
        drag.onPanUpdate!(
          DragUpdateDetails(globalPosition: Offset.zero, delta: delta),
        );
        await tester.pump();
        expect(floating, findsOneWidget);
        expect(position(tester), '01');
        // Vertical drift must keep the same rear faces, including when the
        // horizontal component exceeds the lateral switch threshold.
        expect(find.byKey(const ValueKey('home-deck-card-1')), findsOneWidget);
        expect(find.byKey(const ValueKey('home-deck-card-2')), findsOneWidget);
        drag.onPanEnd!(DragEndDetails());
        await tester.pumpAndSettle();
        expect(frontId(tester), drills.first.id);
        expect(position(tester), '01');
        expect(floating, findsNothing);
        final settled = tester.getRect(visualFront());
        expect(settled.center.dx, closeTo(rest.center.dx, .5));
        expect(settled.center.dy, closeTo(rest.center.dy, .5));
        expect(tester.takeException(), isNull);
      }
      expect(fixture.requested, isEmpty);
    },
  );

  testWidgets(
    'close, barrier and system back keep a card painted through every dismissal frame',
    (tester) async {
      phone(tester);
      await showDeck(tester);
      await tester.pumpAndSettle();
      final sourceElement = tester.element(
        find.byKey(const ValueKey('home-hero')),
      );
      for (final method in ['close', 'barrier', 'back']) {
        await openActionCard(tester);
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('home-deck-expanded')),
          findsOneWidget,
        );
        expectCardPainted(tester);
        await dismissActionCard(tester, method);
        await expectFrameSafeDismissal(tester);
        expect(
          tester.element(find.byKey(const ValueKey('home-hero'))),
          same(sourceElement),
        );
      }
      expect(fixture.requested, isEmpty);
    },
  );

  testWidgets(
    'the closing snapshot keeps the original compact artwork and projected pose',
    (tester) async {
      phone(tester);
      await showDeck(tester);
      await tester.pumpAndSettle();
      final boundaryFinder = find
          .descendant(
            of: find.byKey(const ValueKey('home-deck-front')),
            matching: find.byElementPredicate(
              (element) =>
                  element is RenderObjectElement &&
                  element.renderObject is RenderRepaintBoundary,
            ),
          )
          .first;
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        boundaryFinder,
      );
      final size = boundary.size;
      final localCorners = [
        Offset.zero,
        Offset(size.width, 0),
        Offset(0, size.height),
        Offset(size.width, size.height),
      ];
      final compactCorners = [
        for (final corner in localCorners) boundary.localToGlobal(corner),
      ];
      await openActionCard(tester);
      await tester.pumpAndSettle();
      final standIn = find.byKey(const ValueKey('home-deck-closing-stand-in'));
      final imageFinder = find.descendant(
        of: standIn,
        matching: find.byType(RawImage),
      );
      expect(imageFinder, findsOneWidget);
      final snapshot = tester.widget<RawImage>(imageFinder).image;
      expect(snapshot, isNotNull);
      final imageBox = tester.renderObject<RenderBox>(imageFinder);
      expect(imageBox.size.width, closeTo(size.width + 96, .01));
      expect(imageBox.size.height, closeTo(size.height + 96, .01));

      await dismissActionCard(tester, 'close');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 378));
      for (var lastMillisecond = 0; lastMillisecond < 2; lastMillisecond++) {
        expectCardPainted(tester);
        expect(
          keyedOpacity(tester, 'home-deck-expanded-opacity'),
          lessThan(.01),
        );
        expect(tester.widget<RawImage>(imageFinder).image, same(snapshot));
        final box = tester.renderObject<RenderBox>(imageFinder);
        for (var i = 0; i < localCorners.length; i++) {
          // The 48pt capture padding includes the real source shadow, while
          // its content corners must converge to the source's full transform.
          final projected = box.localToGlobal(
            localCorners[i] + const Offset(48, 48),
          );
          expect((projected - compactCorners[i]).distance, lessThan(4));
        }
        await tester.pump(const Duration(milliseconds: 1));
      }
      // At dismissed, the source is restored in this very frame; it cannot wait
      // for a later route.completed callback or another frame's rebuild.
      expectCardPainted(tester);
      expect(keyedOpacity(tester, 'home-deck-opacity-0'), 1);
      for (var i = 0; i < localCorners.length; i++) {
        expect(
          (boundary.localToGlobal(localCorners[i]) - compactCorners[i])
              .distance,
          lessThan(.01),
        );
      }
      await tester.pump();
      expectCardPainted(tester);
      expect(keyedOpacity(tester, 'home-deck-opacity-0'), 1);
      // Zero value can precede dismissed by one ticker step. The source is
      // already visible; route disposal itself waits for an advancing frame.
      await tester.pump(const Duration(milliseconds: 16));
      expectCardPainted(tester);
      expect(standIn, findsNothing);
      expect(find.byKey(const ValueKey('home-deck-expanded')), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'quick and repeated close hands the same card back and can reopen',
    (tester) async {
      phone(tester);
      await showDeck(tester);
      await tester.pumpAndSettle();
      final sourceElement = tester.element(
        find.byKey(const ValueKey('home-hero')),
      );
      await openActionCard(tester);
      await tester.pump(const Duration(milliseconds: 32));
      final close = tester
          .widget<HipCircleButton>(
            find.byKey(const ValueKey('home-deck-expanded-close')),
          )
          .onPressed!;
      close();
      close();
      await expectFrameSafeDismissal(tester);
      expect(
        tester.element(find.byKey(const ValueKey('home-hero'))),
        same(sourceElement),
      );
      await openActionCard(tester);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('home-deck-expanded')), findsOneWidget);
      await dismissActionCard(tester, 'back');
      await expectFrameSafeDismissal(tester);
      expect(
        tester.element(find.byKey(const ValueKey('home-hero'))),
        same(sourceElement),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('reduced motion restores the compact card for every close path', (
    tester,
  ) async {
    phone(tester);
    await showDeck(tester, reduced: true);
    await tester.pumpAndSettle();
    for (final method in ['close', 'barrier', 'back']) {
      await openActionCard(tester);
      await tester.pumpAndSettle();
      expectCardPainted(tester);
      await dismissActionCard(tester, method);
      await tester.pump();
      expectCardPainted(tester);
      expect(keyedOpacity(tester, 'home-deck-opacity-0'), 1);
      await tester.pump(const Duration(milliseconds: 16));
      expectCardPainted(tester);
      expect(find.byKey(const ValueKey('home-deck-expanded')), findsNothing);
      expect(
        find.byKey(const ValueKey('home-deck-closing-stand-in')),
        findsNothing,
      );
      expect(position(tester), '01');
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets(
    'tapping a card opens a bounded action preview that pauses without rebuilding media',
    (tester) async {
      phone(tester);
      const description = '动作介绍：保持骨盆稳定，缓慢完成动作。';
      const cue = '动作提示：不要屏住呼吸';
      await showDeck(
        tester,
        descriptions: [description],
        cues: [cue],
        doses: ['每侧 40 秒'],
        videoEnabled: true,
      );
      await tester.pumpAndSettle();
      await tester.tapAt(
        tester.getCenter(find.byKey(const ValueKey('home-hero'))),
      );
      await tester.pumpAndSettle();
      final expanded = find.byKey(const ValueKey('home-deck-expanded'));
      expect(expanded, findsOneWidget);
      final bounds = tester.getRect(expanded);
      expect(bounds.left, greaterThan(0));
      expect(bounds.right, lessThan(394));
      expect(bounds.top, greaterThan(0));
      expect(bounds.bottom, lessThan(853));
      expect(
        find.descendant(of: expanded, matching: find.text(description)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: expanded, matching: find.text(cue)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: expanded, matching: find.text(drills.first.name)),
        findsOneWidget,
      );
      final mediaTap = find.byKey(const ValueKey('home-deck-expanded-media'));
      final media = find.descendant(
        of: mediaTap,
        matching: find.byType(trainer.TrainingActionMedia),
      );
      final mediaElement = tester.element(media);
      final mediaState = tester.state(media);
      expect(tester.widget<trainer.TrainingActionMedia>(media).playing, isTrue);
      expect(tester.widget<trainer.TrainingActionMedia>(media).paused, isFalse);
      await tester.tap(mediaTap);
      await tester.pump();
      expect(tester.element(media), same(mediaElement));
      expect(tester.widget<trainer.TrainingActionMedia>(media).playing, isTrue);
      expect(tester.widget<trainer.TrainingActionMedia>(media).paused, isTrue);
      await tester.tap(mediaTap);
      await tester.pump();
      expect(tester.element(media), same(mediaElement));
      expect(tester.widget<trainer.TrainingActionMedia>(media).paused, isFalse);
      await tester.tap(arrow('收起动作卡片'));
      await tester.pumpAndSettle();
      expect(expanded, findsNothing);
      expect(mediaState.mounted, isFalse);
      expect(position(tester), '01');
      expect(fixture.requested, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'action preview dismisses outside and unmounts cleanly while open',
    (tester) async {
      phone(tester);
      await showDeck(tester, videoEnabled: true);
      await tester.pumpAndSettle();
      final expanded = find.byKey(const ValueKey('home-deck-expanded'));
      await tester.tapAt(
        tester.getCenter(find.byKey(const ValueKey('home-hero'))),
      );
      await tester.pumpAndSettle();
      expect(expanded, findsOneWidget);
      final bounds = tester.getRect(expanded);
      await tester.tapAt(Offset(3, bounds.center.dy));
      await tester.pumpAndSettle();
      expect(expanded, findsNothing);
      await tester.tapAt(
        tester.getCenter(find.byKey(const ValueKey('home-hero'))),
      );
      await tester.pumpAndSettle();
      final media = find.descendant(
        of: find.byKey(const ValueKey('home-deck-expanded-media')),
        matching: find.byType(trainer.TrainingActionMedia),
      );
      final state = tester.state(media);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      expect(state.mounted, isFalse);
      expect(expanded, findsNothing);
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
