import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiplab/hip/control/hip_store.dart';
import 'package:hiplab/hip/data/hip_public_media.dart';
import 'package:hiplab/hip/domain/hip_models.dart';
import 'package:hiplab/hip/ui/hip_app.dart';
import 'package:hiplab/hip/ui/hip_home_action_deck.dart';
import 'package:hiplab/hip/ui/hip_player_page.dart';
import 'package:hiplab/hip/ui/hip_theme.dart';
import 'package:hiplab/hip/ui/hip_widgets.dart';
import 'package:ugk_trainer_runtime/ugk_trainer_runtime.dart' as trainer;

import 'hip_domain_test.dart' show MemoryStorage, loadContent;
import 'home_deck_playback_fixture.dart';
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
    return find.byKey(const ValueKey('home-deck-front'));
  }

  double keyedOpacity(WidgetTester tester, String key) {
    final finder = find.byKey(ValueKey(key));
    return finder.evaluate().isEmpty
        ? 0
        : tester.widget<Opacity>(finder).opacity;
  }

  void expectCardPainted(WidgetTester tester) {
    final face = find.byKey(const ValueKey('home-deck-front'));
    expect(face, findsOneWidget);
    expect(keyedOpacity(tester, 'home-deck-opacity-0'), 1);
    final rect = tester.getRect(face);
    expect(rect.width, greaterThan(0));
    expect(rect.height, greaterThan(0));
  }

  double closeOpacity(WidgetTester tester) {
    final close = find.byKey(const ValueKey('home-deck-expanded-close'));
    final opacity = find
        .ancestor(of: close, matching: find.byType(Opacity))
        .first;
    return tester.widget<Opacity>(opacity).opacity;
  }

  Finder frontMedia() => find.descendant(
    of: find.byKey(const ValueKey('home-hero')),
    matching: find.byType(trainer.TrainingActionMedia),
  );

  void expectNoDecoderChurn(HomeDeckPlaybackPlatform platform) {
    expect(platform.sources, hasLength(1));
    expect(
      platform.commands.where((c) => c.$2 == 'prime-first-frame'),
      hasLength(1),
    );
    expect(
      platform.commands.where(
        (c) =>
            c.$2 == 'dispose' ||
            c.$2.contains('seek') ||
            c.$2.contains('return-to-start'),
      ),
      isEmpty,
    );
  }

  Future<void> openActionCard(WidgetTester tester) async {
    await tester.tapAt(
      tester.getCenter(find.byKey(const ValueKey('home-hero'))),
    );
    await tester.pump();
  }

  Future<HomeDeckPlaybackPlatform> readyCompactPlaybackCard(
    WidgetTester tester,
  ) async {
    final repository = HomeDeckPlaybackRepository();
    final platform = HomeDeckPlaybackPlatform();
    final previousFilter = trainer.UgkPackedAlphaVideo.debugFilterBuilder;
    HipPublicMedia.current = repository.policy;
    trainer.UgkPackedAlphaVideo.debugPlatform = platform;
    trainer.UgkPackedAlphaVideo.debugFilterBuilder = (input) => input;
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await platform.dispose();
      repository.dispose();
      trainer.UgkPackedAlphaVideo.debugFilterBuilder = previousFilter;
    });
    await showDeck(tester, videoEnabled: true);
    await tester.pump();
    await tester.pump();
    expect(platform.sources, hasLength(1));
    platform.emit(1, 'ready');
    await tester.pump();
    await tester.pump();
    expect(
      platform.commands.where((c) => c.$2 == 'prime-first-frame'),
      hasLength(1),
    );
    platform.emit(1, 'first-frame');
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
    final surface = tester.widget<trainer.UgkPackedAlphaVideo>(
      find.byType(trainer.UgkPackedAlphaVideo),
    );
    expect(surface.controller.ready, isTrue);
    expect(surface.controller.hasFrame, isTrue);
    expect(
      tester.widget<trainer.TrainingActionMedia>(frontMedia()).paused,
      isTrue,
    );
    expect(find.byKey(const ValueKey('home-deck-expanded')), findsNothing);
    return platform;
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
        expect(closeOpacity(tester), lessThan(.01));
      }
    }
    for (var i = 0; i < 2; i++) {
      await tester.pump();
      expectCardPainted(tester);
    }
    expect(keyedOpacity(tester, 'home-deck-opacity-0'), 1);
    expect(find.byKey(const ValueKey('home-deck-expanded')), findsNothing);
    expect(closeOpacity(tester), 0);
    expect(arrow('收起动作卡片').hitTestable(), findsNothing);
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
    // Measure the actual rotation pivot. The bounding-box center also moves
    // when the card tilts, even with continuous screen-space translation.
    Offset pivot() {
      final box = tester.renderObject<RenderBox>(visualFront());
      return box.localToGlobal(
        Offset(box.size.width / 2, box.size.height * .9),
      );
    }

    final returningCenter = pivot();
    final reverse = await tester.startGesture(tester.getCenter(area));
    await reverse.moveBy(const Offset(30, 0));
    await tester.pump(const Duration(milliseconds: 16));
    final caughtCenter = pivot();
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
        tester.getRect(visualFront()).center.dy,
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
      final moved = tester.getRect(visualFront());
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
      find.byKey(const ValueKey('home-deck-stage')),
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
    expect(tester.getRect(visualFront()).top, lessThan(deckBounds.top));
    drag.onPanUpdate!(
      DragUpdateDetails(
        globalPosition: Offset.zero,
        delta: const Offset(0, 440),
      ),
    );
    await tester.pump();
    expect(
      tester.getRect(visualFront()).bottom,
      greaterThan(deckBounds.bottom),
    );
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

  testWidgets('the compact front primes one decoded frame and starts paused', (
    tester,
  ) async {
    phone(tester);
    final platform = await readyCompactPlaybackCard(tester);
    final media = tester.widget<trainer.TrainingActionMedia>(frontMedia());
    expect(media.playing, isTrue);
    expect(media.paused, isTrue);
    expect(media.prepareFirstFrame, isTrue);
    expect(platform.commands.where((c) => c.$2 == 'play'), isEmpty);
    await tester.pump(const Duration(milliseconds: 500));
    expectNoDecoderChurn(platform);
    expectCardPainted(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'one painted video surface survives every frame of expanding and collapsing',
    (tester) async {
      phone(tester);
      final platform = await readyCompactPlaybackCard(tester);
      final mediaState = tester.state(frontMedia());
      final artElement = tester.element(
        find.byKey(const ValueKey('home-hero')),
      );
      final surface = find.byType(trainer.UgkPackedAlphaVideo);
      final surfaceElement = tester.element(surface);
      final controller = tester
          .widget<trainer.UgkPackedAlphaVideo>(surface)
          .controller;
      final compactRect = tester.getRect(visualFront());
      Iterable<Layer> descendantLayers(Layer layer) sync* {
        yield layer;
        if (layer is ContainerLayer) {
          for (
            Layer? child = layer.firstChild;
            child != null;
            child = child.nextSibling
          ) {
            yield* descendantLayers(child);
          }
        }
      }

      void sameSurface() {
        expectCardPainted(tester);
        expect(tester.state(frontMedia()), same(mediaState));
        expect(
          tester.element(find.byKey(const ValueKey('home-hero'))),
          same(artElement),
        );
        expect(tester.element(surface), same(surfaceElement));
        expect(
          tester.widget<trainer.UgkPackedAlphaVideo>(surface).controller,
          same(controller),
        );
        expect(tester.widget<Texture>(find.byType(Texture)).textureId, 101);
        // Inspect the painted layer tree, not only Transform.filterQuality.
        // The card's pose must wrap the composed texture in a matrix filter,
        // keeping its perspective out of the packed RGB/alpha input space.
        final pose = tester.renderObject<RenderTransform>(
          find.byKey(const ValueKey('home-deck-pose')),
        );
        expect(pose.debugLayer, isA<ImageFilterLayer>());
        final poseLayer = pose.debugLayer! as ImageFilterLayer;
        expect(poseLayer.attached, isTrue);
        final textureLayer = descendantLayers(
          poseLayer,
        ).whereType<TextureLayer>().where((layer) => layer.textureId == 101);
        expect(textureLayer, hasLength(1));
        expect(textureLayer.single.attached, isTrue);
        expectNoDecoderChurn(platform);
      }

      sameSurface();
      await openActionCard(tester);
      for (var elapsed = 0; elapsed < 416; elapsed += 16) {
        await tester.pump(const Duration(milliseconds: 16));
        sameSurface();
      }
      expect(find.byKey(const ValueKey('home-deck-expanded')), findsOneWidget);
      expect(
        tester.widget<trainer.TrainingActionMedia>(frontMedia()).paused,
        isFalse,
      );
      await dismissActionCard(tester, 'close');
      await tester.pump();
      expect(
        tester.widget<trainer.TrainingActionMedia>(frontMedia()).paused,
        isTrue,
      );
      for (var elapsed = 0; elapsed < 416; elapsed += 16) {
        await tester.pump(const Duration(milliseconds: 16));
        sameSurface();
      }
      expect(find.byKey(const ValueKey('home-deck-expanded')), findsNothing);
      expect(closeOpacity(tester), 0);
      final restored = tester.getRect(visualFront());
      expect(restored.left, closeTo(compactRect.left, .01));
      expect(restored.top, closeTo(compactRect.top, .01));
      expect(restored.width, closeTo(compactRect.width, .01));
      expect(restored.height, closeTo(compactRect.height, .01));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'close, barrier, back and rapid reopening retain the same compact decoder',
    (tester) async {
      phone(tester);
      final platform = await readyCompactPlaybackCard(tester);
      final mediaState = tester.state(frontMedia());
      final surface = find.byType(trainer.UgkPackedAlphaVideo);
      final surfaceElement = tester.element(surface);
      for (final method in ['close', 'barrier', 'back']) {
        await openActionCard(tester);
        await tester.pumpAndSettle();
        expect(
          tester.widget<trainer.TrainingActionMedia>(frontMedia()).paused,
          isFalse,
        );
        await dismissActionCard(tester, method);
        await expectFrameSafeDismissal(tester);
        expect(tester.state(frontMedia()), same(mediaState));
        expect(tester.element(surface), same(surfaceElement));
        expect(
          tester.widget<trainer.TrainingActionMedia>(frontMedia()).paused,
          isTrue,
        );
        expectNoDecoderChurn(platform);
      }
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
      await openActionCard(tester);
      await tester.pumpAndSettle();
      expect(tester.state(frontMedia()), same(mediaState));
      expect(tester.element(surface), same(surfaceElement));
      await dismissActionCard(tester, 'back');
      await expectFrameSafeDismissal(tester);
      expectNoDecoderChurn(platform);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'closing a paused demonstration keeps its current decoder paused',
    (tester) async {
      phone(tester);
      final platform = await readyCompactPlaybackCard(tester);
      final mediaState = tester.state(frontMedia());
      await openActionCard(tester);
      await tester.pumpAndSettle();
      final mediaTap = find.byKey(const ValueKey('home-deck-expanded-media'));
      await tester.tap(mediaTap);
      await tester.pump();
      expect(
        tester.widget<trainer.TrainingActionMedia>(frontMedia()).paused,
        isTrue,
      );
      final commandStart = platform.commands.length;
      await dismissActionCard(tester, 'close');
      await expectFrameSafeDismissal(tester);
      expect(tester.state(frontMedia()), same(mediaState));
      expect(
        tester.widget<trainer.TrainingActionMedia>(frontMedia()).paused,
        isTrue,
      );
      expect(
        platform.commands.skip(commandStart).where((c) => c.$2 == 'play'),
        isEmpty,
      );
      expectNoDecoderChurn(platform);
      await openActionCard(tester);
      await tester.pumpAndSettle();
      expect(
        tester.widget<trainer.TrainingActionMedia>(frontMedia()).paused,
        isFalse,
      );
      expect(tester.state(frontMedia()), same(mediaState));
      expectNoDecoderChurn(platform);
      await dismissActionCard(tester, 'close');
      await expectFrameSafeDismissal(tester);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('reduced motion keeps the same card for every close path', (
    tester,
  ) async {
    phone(tester);
    await showDeck(tester, reduced: true);
    await tester.pumpAndSettle();
    final artElement = tester.element(find.byKey(const ValueKey('home-hero')));
    for (final method in ['close', 'barrier', 'back']) {
      await openActionCard(tester);
      await tester.pumpAndSettle();
      expectCardPainted(tester);
      await dismissActionCard(tester, method);
      await tester.pump();
      expectCardPainted(tester);
      expect(
        tester.element(find.byKey(const ValueKey('home-hero'))),
        same(artElement),
      );
      await tester.pump(const Duration(milliseconds: 16));
      expectCardPainted(tester);
      expect(find.byKey(const ValueKey('home-deck-expanded')), findsNothing);
      expect(closeOpacity(tester), 0);
      expect(position(tester), '01');
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets(
    'a small source card expands complete information and resets its description scroll on close',
    (tester) async {
      phone(tester);
      const dose = '每侧 40 秒';
      const cue = '动作提示：保持自然呼吸，不要耸肩。';
      final description = List.generate(
        24,
        (i) => '动作说明 ${i + 1}：保持骨盆稳定，缓慢完成动作，在舒适的范围内停留。',
      ).join('\n');
      await showDeck(
        tester,
        height: 240,
        doses: [dose],
        cues: [cue],
        descriptions: [description],
      );
      await tester.pumpAndSettle();
      final caption = find.byKey(const ValueKey('home-deck-caption'));
      expect(caption.hitTestable(), findsOneWidget);
      await openActionCard(tester);
      await tester.pumpAndSettle();
      expect(find.text(dose).hitTestable(), findsOneWidget);
      expect(find.text(cue).hitTestable(), findsOneWidget);
      expect(tester.widget<Text>(find.text(cue)).maxLines, isNull);
      expect(tester.widget<Text>(find.text(description)).maxLines, isNull);
      final information = find.byKey(
        const ValueKey('home-deck-expanded-description'),
      );
      final controller = tester
          .widget<SingleChildScrollView>(information)
          .controller!;
      expect(controller.position.maxScrollExtent, greaterThan(0));
      expect(
        tester.getTopLeft(find.text(description)).dy,
        lessThan(tester.getRect(information).bottom),
      );
      await tester.drag(information, const Offset(0, -220));
      await tester.pumpAndSettle();
      expect(controller.offset, greaterThan(0));
      await dismissActionCard(tester, 'close');
      await tester.pump();
      expect(controller.offset, 0);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('home-deck-expanded')), findsNothing);
      expect(caption.hitTestable(), findsOneWidget);
      expect(tester.widget<Text>(caption).data, drills.first.name);
      expect(fixture.requested, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Escape and a second back during collapse keep Home and blank taps do not open a card',
    (tester) async {
      phone(tester);
      await showDeck(tester);
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      final expanded = find.byKey(const ValueKey('home-deck-expanded'));
      expect(expanded, findsNothing);
      await openActionCard(tester);
      await tester.pumpAndSettle();
      expect(expanded, findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump(const Duration(milliseconds: 16));
      await tester.binding.handlePopRoute();
      await tester.pump(const Duration(milliseconds: 16));
      expect(find.byType(HipHomeActionDeck), findsOneWidget);
      expect(find.byKey(const ValueKey('home-hero')), findsOneWidget);
      await tester.pumpAndSettle();
      expect(expanded, findsNothing);
      expect(closeOpacity(tester), 0);
      expect(position(tester), '01');
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(expanded, findsNothing);
      expect(find.byType(HipHomeActionDeck), findsOneWidget);
      expect(fixture.requested, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

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
        find.descendant(of: visualFront(), matching: find.text(description)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: visualFront(), matching: find.text(cue)),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: visualFront(),
          matching: find.text(drills.first.name),
        ),
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
      expect(mediaState.mounted, isTrue);
      expect(tester.state(media), same(mediaState));
      expect(tester.widget<trainer.TrainingActionMedia>(media).paused, isTrue);
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
      expect(
        tester.widget<trainer.TrainingActionMedia>(frontMedia()).stage,
        HipPalette.light.mediaBackdrop,
      );
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
            of: find.byType(HipHomeActionDeck),
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
