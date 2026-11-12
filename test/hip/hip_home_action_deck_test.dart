import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hiplab/hip/control/hip_store.dart';
import 'package:hiplab/hip/data/hip_public_media.dart';
import 'package:hiplab/hip/domain/hip_models.dart';
import 'package:hiplab/hip/ui/hip_app.dart';
import 'package:hiplab/hip/ui/hip_home_action_deck.dart';
import 'package:hiplab/hip/ui/hip_home_action_inspect.dart';
import 'package:hiplab/hip/ui/hip_page_kit.dart';
import 'package:hiplab/hip/ui/hip_player_page.dart';
import 'package:hiplab/hip/ui/hip_routes.dart';
import 'package:hiplab/hip/ui/hip_theme.dart';
import 'package:hiplab/hip/ui/hip_widgets.dart';
import 'package:hiplab/hip/voice/hip_voice.dart';
import 'package:ugk_trainer_runtime/ugk_trainer_runtime.dart' as trainer;

import 'hip_domain_test.dart' show MemoryStorage, loadContent;
import 'home_deck_playback_fixture.dart';
import 'public_media_fixture.dart';
import 'trainer_test_pump.dart';

class _CountingAssetBundle extends CachingAssetBundle {
  final loads = <String>[];

  @override
  Future<ByteData> load(String key) {
    loads.add(key);
    return rootBundle.load(key);
  }
}

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
        // This suite asserts the original Chinese captions and accessibility
        // actions; the App's English presentation has separate coverage.
        locale: const Locale('zh'),
        supportedLocales: const [Locale('zh')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
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

  void turnPreview(WidgetTester tester, int direction) {
    final preview = tester.widget<Semantics>(
      find.byWidgetPredicate(
        (widget) => widget is Semantics && widget.properties.label == '训练动作预览',
      ),
    );
    final action = direction > 0
        ? preview.properties.onIncrease
        : preview.properties.onDecrease;
    expect(action, isNotNull);
    action!();
  }

  Future<void> next(WidgetTester tester) async {
    turnPreview(tester, 1);
    await tester.pumpAndSettle();
  }

  String frontId(WidgetTester tester) => tester
      .widget<HipDrillArt>(
        find.descendant(
          of: find.byKey(const ValueKey('home-hero')),
          matching: find.byType(HipDrillArt),
        ),
      )
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

  Finder nextFace() => find.byKey(const ValueKey('home-deck-next-face'));

  Finder paperFor(int index) => find.byKey(ValueKey('home-deck-paper-$index'));

  Finder stackShadow() => find.byKey(const ValueKey('home-deck-stack-shadow'));

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

  Finder frontSurface({bool skipOffstage = true}) => find.descendant(
    of: find.byKey(const ValueKey('home-hero'), skipOffstage: skipOffstage),
    matching: find.byType(
      trainer.UgkPackedAlphaVideo,
      skipOffstage: skipOffstage,
    ),
    skipOffstage: skipOffstage,
  );

  int playerFor(WidgetTester tester, Finder media) =>
      tester
          .widget<Texture>(
            find.descendant(of: media, matching: find.byType(Texture)),
          )
          .textureId -
      100;

  Finder mediaOn(Finder card) => find.descendant(
    of: card,
    matching: find.byType(trainer.TrainingActionMedia),
  );

  double posterOpacity(WidgetTester tester, Finder media) => tester
      .widget<AnimatedOpacity>(
        find.descendant(
          of: media,
          matching: find.byKey(const ValueKey('public-action-poster')),
        ),
      )
      .opacity;

  void expectNoDecoderChurn(
    HomeDeckPlaybackPlatform platform, {
    int warmCount = 3,
  }) {
    expect(platform.sources, hasLength(warmCount));
    expect(
      platform.commands.where((c) => c.$2 == 'prime-first-frame'),
      hasLength(warmCount),
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
    WidgetTester tester, {
    List<HipDrill>? items,
    bool neighborsReady = true,
    bool openAndClose = true,
  }) async {
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
    await showDeck(tester, videoEnabled: true, items: items);
    await tester.pump();
    await tester.pump();
    final warmCount = (items ?? drills).length.clamp(0, 3);
    expect(platform.sources, hasLength(warmCount));
    void expectQuietPoster() {
      expect(
        tester
            .widget<trainer.TrainingActionMedia>(frontMedia())
            .showLoadingIndicator,
        isFalse,
      );
      expect(
        find.byKey(const ValueKey('public-action-progress')),
        findsNothing,
      );
      final poster = find.descendant(
        of: frontMedia(),
        matching: find.byKey(const ValueKey('public-action-poster')),
      );
      expect(tester.widget<AnimatedOpacity>(poster).opacity, 1);
    }

    expectQuietPoster();
    for (var id = 1; id <= platform.sources.length; id++) {
      platform.emit(id, 'ready');
    }
    await tester.pump();
    await tester.pump();
    expectQuietPoster();
    expect(
      platform.commands.where((c) => c.$2 == 'prime-first-frame'),
      hasLength(warmCount),
    );
    final currentId = playerFor(tester, frontMedia());
    for (var id = 1; id <= platform.sources.length; id++) {
      if (neighborsReady || id == currentId) platform.emit(id, 'first-frame');
    }
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
    final surface = tester.widget<trainer.UgkPackedAlphaVideo>(frontSurface());
    expect(surface.controller.ready, isTrue);
    expect(surface.controller.hasFrame, isTrue);
    expect(
      tester.widget<trainer.TrainingActionMedia>(frontMedia()).paused,
      isTrue,
    );
    expect(find.byKey(const ValueKey('home-deck-expanded')), findsNothing);
    expect(posterOpacity(tester, frontMedia()), 1);
    if (openAndClose) {
      // A decoded initial frame stays behind its poster until user intent.
      // Most existing surface-lifecycle tests begin from an already inspected
      // card, so establish that state through the actual interaction.
      await openActionCard(tester);
      await tester.pumpAndSettle();
      await tester.tap(arrow('收起动作卡片'));
      await tester.pumpAndSettle();
      expect(posterOpacity(tester, frontMedia()), 0);
    }
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
      expect(sourceCards(), findsNWidgets(3));
      expect(find.byType(HipDrillArt), findsNWidgets(2));
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
    turnPreview(tester, -1);
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
        expect(
          tester
              .widget<HipDrillArt>(
                find.descendant(of: image, matching: find.byType(HipDrillArt)),
              )
              .drill
              .id,
          drills[i].id,
        );
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
    'new bottom paper fades in without contents or another stack shadow',
    (tester) async {
      phone(tester);
      await showDeck(tester);
      await tester.pumpAndSettle();
      final replenishing = find.byKey(const ValueKey('home-deck-opacity-3'));
      final incoming = paperFor(3);
      expect(replenishing, findsNothing);
      expect(incoming, findsNothing);
      expect(stackShadow(), findsOneWidget);
      final previousBottom = tester.getRect(paperFor(2));
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
      expect(stackShadow(), findsOneWidget);
      expect(find.byType(HipDrillArt), findsNWidgets(2));
      final beginningOpacity = tester.widget<Opacity>(replenishing).opacity;
      expect(beginningOpacity, greaterThan(0));
      expect(beginningOpacity, lessThan(1));
      final incomingRect = tester.getRect(incoming);
      final incomingOpacityElement = tester.element(replenishing);
      final incomingPaperElement = tester.element(incoming);

      moveCard(drag, -width * .42);
      await tester.pump();
      final middleOpacity = tester.widget<Opacity>(replenishing).opacity;
      expect(middleOpacity, greaterThan(beginningOpacity));
      expect(middleOpacity, lessThan(1));
      expect(stackShadow(), findsOneWidget);

      moveCard(drag, -width * .55);
      await tester.pump();
      expect(frontId(tester), drills.first.id);
      expect(tester.widget<Opacity>(replenishing).opacity, 1);
      expect(tester.getRect(incoming), incomingRect);
      expect(tester.getRect(paperFor(2)), isNot(previousBottom));
      // The reserve paper is already in the final bottom pose at handoff.
      drag.onPanEnd!(
        DragEndDetails(
          velocity: const Velocity(pixelsPerSecond: Offset(-800, 0)),
          primaryVelocity: -800,
        ),
      );
      await tester.pumpAndSettle();
      expect(frontId(tester), drills[1].id);
      expect(tester.element(replenishing), same(incomingOpacityElement));
      expect(tester.element(incoming), same(incomingPaperElement));
      expect(sourceCards(), findsNWidgets(3));
      expect(find.byType(HipDrillArt), findsNWidgets(2));
      expect(stackShadow(), findsOneWidget);
      final settledRect = tester.getRect(incoming);
      expect(settledRect.left, closeTo(incomingRect.left, .01));
      expect(settledRect.top, closeTo(incomingRect.top, .01));
      expect(settledRect.right, closeTo(incomingRect.right, .01));
      expect(settledRect.bottom, closeTo(incomingRect.bottom, .01));
      expect(fixture.requested, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'only the next card renders content and keeps its face on promotion',
    (tester) async {
      phone(tester);
      final doses = [for (var i = 0; i < drills.length; i++) 'Dose ${i + 1}'];
      await showDeck(tester, palette: HipPalette.light, doses: doses);
      await tester.pumpAndSettle();

      expect(sourceCards(), findsNWidgets(3));
      expect(stackShadow(), findsOneWidget);
      final nextOpacity = tester.widgetList<Opacity>(
        find.ancestor(of: nextFace(), matching: find.byType(Opacity)),
      );
      expect(nextOpacity.every((opacity) => opacity.opacity == 1), isTrue);
      expect(keyedOpacity(tester, 'home-deck-opacity-2'), 1);
      final incomingFace = find.descendant(
        of: nextFace(),
        matching: find.byType(HipHomeActionFace),
      );
      final incomingElement = tester.element(incomingFace);
      final incomingArt = find.descendant(
        of: incomingFace,
        matching: find.byType(HipDrillArt),
      );
      expect(tester.widget<HipDrillArt>(incomingArt).drill.id, drills[1].id);

      final nextShadows = tester
          .widgetList<DecoratedBox>(
            find.descendant(
              of: incomingFace,
              matching: find.byType(DecoratedBox),
            ),
          )
          .expand(
            (box) => switch (box.decoration) {
              BoxDecoration(:final boxShadow?) => boxShadow,
              _ => const <BoxShadow>[],
            },
          );
      final contact = nextShadows.single;
      expect(contact.offset, const Offset(0, 1));
      expect(contact.blurRadius, 3);
      expect(contact.spreadRadius, 0);
      expect(contact.color.a, closeTo(.05, .003));

      final third = paperFor(2);
      for (final (rear, angle) in [(nextFace(), -3.5), (third, -7.0)]) {
        final rotation = tester.widget<Transform>(
          find.ancestor(of: rear, matching: find.byType(Transform)).first,
        );
        final matrix = rotation.transform;
        expect(
          math.atan2(matrix.entry(1, 0), matrix.entry(0, 0)),
          closeTo(angle * math.pi / 180, 1e-8),
        );
      }
      final decoration =
          tester.widget<DecoratedBox>(third).decoration as BoxDecoration;
      expect(decoration.color, const Color(0xfff6f7f6));
      expect(decoration.gradient, isNull);
      final border = (decoration.border! as Border).top;
      expect(border.width, .5);
      expect(border.color.withValues(alpha: 1), Colors.black);
      expect(border.color.a, closeTo(.06, .003));
      expect(decoration.boxShadow ?? const [], isEmpty);
      expect(
        find.descendant(of: third, matching: find.byType(HipDrillArt)),
        findsNothing,
      );
      expect(
        find.descendant(of: third, matching: find.byType(Text)),
        findsNothing,
      );
      expect(paperFor(3), findsNothing);

      final width = tester.getSize(visualFront()).width;
      final drag = deckDrag(tester);
      drag.onPanStart!(DragStartDetails());
      moveCard(drag, -width * .65);
      await tester.pump();
      expect(
        tester.getRect(nextFace()).right,
        greaterThan(tester.getRect(visualFront()).right + 30),
      );
      expect(tester.element(incomingFace), same(incomingElement));
      expect(
        find.descendant(of: incomingFace, matching: find.text(drills[1].name)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: incomingFace, matching: find.text(doses[1])),
        findsOneWidget,
      );

      drag.onPanEnd!(DragEndDetails());
      await tester.pumpAndSettle();
      expect(frontId(tester), drills[1].id);
      expect(
        tester.element(
          find.descendant(
            of: visualFront(),
            matching: find.byType(HipHomeActionFace),
          ),
        ),
        same(incomingElement),
      );
      expect(stackShadow(), findsOneWidget);
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
    final rest = tester.getRect(paperFor(2));
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
      expect(sourceCards(), findsNWidgets(3));
      expect(find.byType(HipDrillArt), findsNWidgets(2));
      // The rightward preview uses the reverse ordered stack. It may remain
      // ordered that way after cancellation, but the next left drag must restore
      // the same card geometry and never leave an extra card mounted.
      if (direction == -1) expect(tester.getRect(paperFor(2)), rest);
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
          expect(sourceCards(), findsNWidgets(count));
          expect(find.byType(HipDrillArt), findsNWidgets(2));
          expect(reserve, findsNothing);
          expect(tester.takeException(), isNull);
        }
      }
      expect(fixture.requested, isEmpty);
    },
  );

  testWidgets(
    'the swipe-only deck keeps semantic adjustment without a navigation row',
    (tester) async {
      phone(tester);
      final semantics = tester.ensureSemantics();
      await showDeck(tester);
      await tester.pumpAndSettle();
      for (final label in ['上一个动作', '下一个动作']) {
        expect(arrow(label), findsNothing);
        expect(find.semantics.byLabel(label), findsNothing);
      }
      expect(find.text('左右翻阅'), findsNothing);
      final preview = find.semantics.byLabel('训练动作预览');
      tester.semantics.performAction(preview, SemanticsAction.increase);
      await tester.pumpAndSettle();
      expect(frontId(tester), drills[1].id);
      expect(position(tester), '02');
      tester.semantics.performAction(preview, SemanticsAction.decrease);
      await tester.pumpAndSettle();
      expect(frontId(tester), drills.first.id);
      expect(position(tester), '01');
      expect(fixture.requested, isEmpty);
      semantics.dispose();
    },
  );

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
    for (final delta in [const Offset(-220, 0), const Offset(0, -220)]) {
      await tester.drag(find.byKey(const ValueKey('home-hero')), delta);
      await tester.pumpAndSettle();
      expect(frontId(tester), drills.first.id);
      expect(position(tester), '01');
    }
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
    'a compact available hero keeps its caption and semantic preview navigable',
    (tester) async {
      phone(tester);
      await showDeck(tester, height: 240);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('home-deck-caption')), findsOneWidget);
      expect(arrow('下一个动作'), findsNothing);
      expect(find.text('左右翻阅'), findsNothing);
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
      drag.onPanCancel!();
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

  testWidgets('crossing the radial threshold commits a released card', (
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
    'vertical exits unlock the next card as soon as the front clears the window',
    (tester) async {
      phone(tester);
      for (final y in [-150.0, 150.0]) {
        await showDeck(tester, identity: 'exit-$y');
        await tester.pumpAndSettle();
        final drag = deckDrag(tester);
        drag.onPanStart!(DragStartDetails());
        drag.onPanUpdate!(
          DragUpdateDetails(globalPosition: Offset.zero, delta: Offset(0, y)),
        );
        await tester.pump();
        drag.onPanEnd!(DragEndDetails());
        await tester.pump();
        var outsideFrames = 0;
        var frames = 0;
        while (position(tester) == '01' && frames++ < 60) {
          final front = tester.renderObject<RenderBox>(visualFront());
          // Include all four corners of the tilted paper; getRect's diagonal
          // alone can leave a still-visible corner out of this pacing check.
          final bounds = MatrixUtils.transformRect(
            front.getTransformTo(null),
            Offset.zero & front.size,
          );
          if (!const Rect.fromLTWH(0, 0, 394, 853).overlaps(bounds)) {
            outsideFrames++;
          }
          expect(outsideFrames, lessThanOrEqualTo(2));
          await tester.pump(const Duration(milliseconds: 16));
        }
        expect(position(tester), y < 0 ? '02' : '06');
        expect(
          find.byKey(const ValueKey('home-deck-floating-front')),
          findsNothing,
        );
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'all eight drag directions continue outward and turn by the dominant axis',
    (tester) async {
      phone(tester);
      final cases = [
        (const Offset(-150, 0), 1),
        (const Offset(150, 0), -1),
        (const Offset(0, -150), 1),
        (const Offset(0, 150), -1),
        (const Offset(-130, -170), 1),
        (const Offset(130, -170), 1),
        (const Offset(-130, 170), -1),
        (const Offset(170, 130), -1),
      ];
      for (var i = 0; i < cases.length; i++) {
        final (delta, direction) = cases[i];
        await showDeck(tester, identity: 'eight-directions/$i');
        await tester.pumpAndSettle();
        Offset pivot() {
          final box = tester.renderObject<RenderBox>(visualFront());
          return box.localToGlobal(
            Offset(box.size.width / 2, box.size.height * .9),
          );
        }

        final rest = pivot();
        final drag = deckDrag(tester);
        drag.onPanStart!(DragStartDetails());
        drag.onPanUpdate!(
          DragUpdateDetails(globalPosition: Offset.zero, delta: delta),
        );
        await tester.pump();
        expect(position(tester), '01');
        final beforeRelease = pivot();
        // Replenishment is driven by total travel, including purely vertical
        // movement; the incoming stack is present before releasing the finger.
        expect(sourceCards(), findsNWidgets(4));
        final nextIndex = direction > 0 ? 1 : drills.length - 1;
        expect(
          find.byKey(ValueKey('home-deck-card-$nextIndex')),
          findsOneWidget,
        );
        drag.onPanEnd!(DragEndDetails());
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 32));
        final afterRelease = pivot();
        final continued = afterRelease - beforeRelease;
        // The exit follows the original ray rather than turning an upward
        // swipe into an abrupt leftward animation at pointer-up.
        expect(
          continued.dx * delta.dx + continued.dy * delta.dy,
          greaterThan(0),
        );
        if (delta.dx == 0) {
          expect(afterRelease.dx, closeTo(beforeRelease.dx, 2));
        }
        if (delta.dy == 0) {
          expect(afterRelease.dy, closeTo(beforeRelease.dy, 2));
        }
        expect((beforeRelease - rest).distance, greaterThan(100));
        await tester.pumpAndSettle();
        expect(frontId(tester), drills[nextIndex].id);
        expect(position(tester), direction > 0 ? '02' : '06');
        expect(
          find.byKey(const ValueKey('home-deck-floating-front')),
          findsNothing,
        );
        expect(tester.takeException(), isNull);
      }
      expect(fixture.requested, isEmpty);
    },
  );

  testWidgets(
    'a short tap expands immediately while video playback waits for the opening motion',
    (tester) async {
      phone(tester);
      final platform = await readyCompactPlaybackCard(tester);
      final commandStart = platform.commands.length;
      final mediaState = tester.state(frontMedia());
      final surface = frontSurface();
      final surfaceElement = tester.element(surface);
      final finger = await tester.startGesture(
        tester.getCenter(find.byKey(const ValueKey('home-hero'))),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byKey(const ValueKey('home-deck-expanded')), findsNothing);
      await finger.up();
      await tester.pump();
      expect(find.byKey(const ValueKey('home-deck-expanded')), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 120));
      expect(
        tester.widget<trainer.TrainingActionMedia>(frontMedia()).paused,
        isTrue,
      );
      expect(
        platform.commands.skip(commandStart).where((c) => c.$2 == 'play'),
        isEmpty,
      );
      expect(tester.state(frontMedia()), same(mediaState));
      expect(tester.element(surface), same(surfaceElement));
      await tester.pumpAndSettle();
      expect(
        tester.widget<trainer.TrainingActionMedia>(frontMedia()).paused,
        isFalse,
      );
      expectNoDecoderChurn(platform);
      await dismissActionCard(tester, 'close');
      await expectFrameSafeDismissal(tester);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'holding still leaves the card at rest and release keeps the original tap to expand',
    (tester) async {
      phone(tester);
      final platform = await readyCompactPlaybackCard(tester);
      final mediaState = tester.state(frontMedia());
      final surface = frontSurface();
      final surfaceElement = tester.element(surface);
      List<double> pose() => tester
          .widget<Transform>(find.byKey(const ValueKey('home-deck-pose')))
          .transform
          .storage
          .toList();
      final rest = pose();
      final finger = await tester.startGesture(
        tester.getCenter(find.byKey(const ValueKey('home-hero'))),
      );
      for (var elapsed = 0; elapsed < 500; elapsed += 100) {
        await tester.pump(const Duration(milliseconds: 100));
        expect(pose(), orderedEquals(rest));
        expect(find.byKey(const ValueKey('home-deck-expanded')), findsNothing);
      }
      expect(position(tester), '01');
      expect(tester.state(frontMedia()), same(mediaState));
      expect(tester.element(surface), same(surfaceElement));
      expect(
        tester.widget<trainer.TrainingActionMedia>(frontMedia()).paused,
        isTrue,
      );
      await finger.up();
      await tester.pump();
      expect(find.byKey(const ValueKey('home-deck-expanded')), findsOneWidget);
      await tester.pumpAndSettle();
      expect(tester.state(frontMedia()), same(mediaState));
      expect(tester.element(surface), same(surfaceElement));
      expectNoDecoderChurn(platform);
      await dismissActionCard(tester, 'close');
      await expectFrameSafeDismissal(tester);
      expect(pose(), orderedEquals(rest));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'a finger held still can start an ordinary drag and cancel or turn without opening',
    (tester) async {
      phone(tester);
      await showDeck(tester);
      await tester.pumpAndSettle();
      Offset pivot() {
        final box = tester.renderObject<RenderBox>(visualFront());
        return box.localToGlobal(
          Offset(box.size.width / 2, box.size.height * .9),
        );
      }

      final rest = pivot();
      final finger = await tester.startGesture(
        tester.getCenter(find.byKey(const ValueKey('home-hero'))),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(pivot(), rest);
      await finger.moveBy(const Offset(25, -20));
      await tester.pump(const Duration(milliseconds: 16));
      final moved = pivot();
      expect(moved.dx - rest.dx, closeTo(25, 4));
      expect(moved.dy - rest.dy, closeTo(-20, 6));
      expect(find.byKey(const ValueKey('home-deck-expanded')), findsNothing);
      await finger.cancel();
      await tester.pumpAndSettle();
      final settled = pivot();
      expect(settled.dx, closeTo(rest.dx, .01));
      expect(settled.dy, closeTo(rest.dy, .01));
      expect(position(tester), '01');
      expect(find.byKey(const ValueKey('home-deck-expanded')), findsNothing);
      final turning = await tester.startGesture(
        tester.getCenter(find.byKey(const ValueKey('home-hero'))),
      );
      await tester.pump(const Duration(milliseconds: 500));
      await turning.moveBy(const Offset(0, -150));
      await tester.pump(const Duration(milliseconds: 16));
      await turning.up();
      await tester.pumpAndSettle();
      expect(frontId(tester), drills[1].id);
      expect(position(tester), '02');
      expect(find.byKey(const ValueKey('home-deck-expanded')), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'vertical release keeps a readable glide instead of accelerating out in the first frames',
    (tester) async {
      phone(tester);
      for (final y in [-150.0, 150.0]) {
        await showDeck(tester, identity: 'glide-$y');
        await tester.pumpAndSettle();
        Offset pivot() {
          final box = tester.renderObject<RenderBox>(visualFront());
          return box.localToGlobal(
            Offset(box.size.width / 2, box.size.height * .9),
          );
        }

        final drag = deckDrag(tester);
        drag.onPanStart!(DragStartDetails());
        drag.onPanUpdate!(
          DragUpdateDetails(globalPosition: Offset.zero, delta: Offset(0, y)),
        );
        await tester.pump();
        final release = pivot();
        final sign = y.sign;
        drag.onPanEnd!(DragEndDetails());
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 80));
        final at80 = (pivot().dy - release.dy) * sign;
        expect(at80, greaterThan(0));
        expect(at80, lessThan(120));
        expect(position(tester), '01');
        await tester.pump(const Duration(milliseconds: 40));
        final at120 = (pivot().dy - release.dy) * sign;
        expect(at120, greaterThan(at80));
        expect(at120, lessThan(180));
        await tester.pump(const Duration(milliseconds: 80));
        expect(position(tester), '01');
        expect(
          const Rect.fromLTWH(
            0,
            0,
            394,
            853,
          ).overlaps(tester.getRect(visualFront())),
          isTrue,
        );
        await tester.pumpAndSettle();
        expect(position(tester), y < 0 ? '02' : '06');
        expect(
          find.byKey(const ValueKey('home-deck-floating-front')),
          findsNothing,
        );
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'a vertical release accelerates and then gathers rather than following a flat speed plateau',
    (tester) async {
      phone(tester);
      await showDeck(tester);
      await tester.pumpAndSettle();
      double y() {
        final box = tester.renderObject<RenderBox>(visualFront());
        return box
            .localToGlobal(Offset(box.size.width / 2, box.size.height * .9))
            .dy;
      }

      final drag = deckDrag(tester);
      drag.onPanStart!(DragStartDetails());
      drag.onPanUpdate!(
        DragUpdateDetails(
          globalPosition: Offset.zero,
          delta: const Offset(0, -150),
        ),
      );
      await tester.pump();
      final release = y();
      drag.onPanEnd!(DragEndDetails());
      await tester.pump();
      final distances = <double>[0];
      for (var i = 0; i < 7; i++) {
        await tester.pump(const Duration(milliseconds: 40));
        expect(position(tester), '01');
        distances.add(release - y());
      }
      final steps = List.generate(
        distances.length - 1,
        (i) => distances[i + 1] - distances[i],
      );
      expect(steps.every((step) => step > 0), isTrue);
      // An inertial throw builds speed after a gentle release, then clearly
      // gathers before the visible card exits; equal-time travel is not flat.
      expect(steps[2], greaterThan(steps[0] * 1.5));
      expect(steps[6], lessThan(steps[3] * .95));
      await tester.pumpAndSettle();
      expect(position(tester), '02');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'vertical throws preserve distinct fast release velocities above the old cap',
    (tester) async {
      phone(tester);
      final travel = <double>[];
      // Both speeds were formerly clamped to 900 and produced one trajectory.
      for (final speed in [1200.0, 2200.0]) {
        await showDeck(tester, identity: 'speed-$speed');
        await tester.pumpAndSettle();
        double y() {
          final box = tester.renderObject<RenderBox>(visualFront());
          return box
              .localToGlobal(Offset(box.size.width / 2, box.size.height * .9))
              .dy;
        }

        final drag = deckDrag(tester);
        drag.onPanStart!(DragStartDetails());
        drag.onPanUpdate!(
          DragUpdateDetails(
            globalPosition: Offset.zero,
            delta: const Offset(0, -150),
          ),
        );
        await tester.pump();
        final release = y();
        drag.onPanEnd!(
          DragEndDetails(
            velocity: Velocity(pixelsPerSecond: Offset(0, -speed)),
          ),
        );
        await tester.pump();
        expect(y(), closeTo(release, .01));
        await tester.pump(const Duration(milliseconds: 80));
        expect(position(tester), '01');
        travel.add(release - y());
        await tester.pumpAndSettle();
        expect(position(tester), '02');
      }
      expect(travel[1], greaterThan(travel[0] + 30));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'vertical releases inside the center or flicked back toward the stack return',
    (tester) async {
      phone(tester);
      await showDeck(tester);
      await tester.pumpAndSettle();
      final before = tester.getRect(visualFront());
      for (final (delta, velocity) in [
        (const Offset(0, 75), const Offset(0, 2400)),
        (const Offset(0, -150), const Offset(0, 1600)),
      ]) {
        final drag = deckDrag(tester);
        drag.onPanStart!(DragStartDetails());
        drag.onPanUpdate!(
          DragUpdateDetails(globalPosition: Offset.zero, delta: delta),
        );
        await tester.pump();
        drag.onPanEnd!(
          DragEndDetails(velocity: Velocity(pixelsPerSecond: velocity)),
        );
        await tester.pumpAndSettle();
        expect(frontId(tester), drills.first.id);
        expect(position(tester), '01');
        final after = tester.getRect(visualFront());
        expect(after.left, closeTo(before.left, .01));
        expect(after.top, closeTo(before.top, .01));
        expect(sourceCards(), findsNWidgets(3));
        expect(find.byKey(const ValueKey('home-deck-expanded')), findsNothing);
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('the compact front primes one decoded frame and starts paused', (
    tester,
  ) async {
    phone(tester);
    final platform = await readyCompactPlaybackCard(
      tester,
      openAndClose: false,
    );
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
    'a cold incoming card keeps its poster after a late frame and reveals the same video only on opening',
    (tester) async {
      phone(tester);
      final platform = await readyCompactPlaybackCard(
        tester,
        neighborsReady: false,
      );
      final incomingMedia = mediaOn(nextFace());
      final incomingState = tester.state(incomingMedia);
      final incomingSurface = find.descendant(
        of: incomingMedia,
        matching: find.byType(trainer.UgkPackedAlphaVideo),
      );
      final surfaceElement = tester.element(incomingSurface);
      final incomingId = playerFor(tester, incomingMedia);
      final controller = tester
          .widget<trainer.UgkPackedAlphaVideo>(incomingSurface)
          .controller;
      expect(controller.hasFrame, isFalse);
      await next(tester);
      await tester.pump();
      expect(frontId(tester), drills[1].id);
      expect(tester.state(frontMedia()), same(incomingState));
      expect(tester.element(frontSurface()), same(surfaceElement));
      expect(posterOpacity(tester, frontMedia()), 1);
      platform.emit(incomingId, 'first-frame');
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(controller.hasFrame, isTrue);
      expect(posterOpacity(tester, frontMedia()), 1);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(tester.state(frontMedia()), same(incomingState));
      expect(tester.element(frontSurface()), same(surfaceElement));
      await openActionCard(tester);
      await tester.pumpAndSettle();
      expect(posterOpacity(tester, frontMedia()), 0);
      expect(tester.element(frontSurface()), same(surfaceElement));
      await dismissActionCard(tester, 'close');
      await tester.pumpAndSettle();
      expect(posterOpacity(tester, frontMedia()), 0);
      expect(
        tester.widget<trainer.UgkPackedAlphaVideo>(frontSurface()).controller,
        same(controller),
      );
      expect(
        platform.commands.where(
          (c) => c.$1 == incomingId && c.$2 == 'prime-first-frame',
        ),
        hasLength(1),
      );
      expect(
        platform.commands.where((c) => c.$1 == incomingId && c.$2 == 'dispose'),
        isEmpty,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'a warm incoming video keeps its decoded surface through both-direction promotion and a cancelled preview',
    (tester) async {
      phone(tester);
      final platform = await readyCompactPlaybackCard(tester);
      final originalState = tester.state(frontMedia());
      final originalSurface = tester.element(frontSurface());
      final incomingMedia = mediaOn(nextFace());
      final incomingState = tester.state(incomingMedia);
      final incomingSurface = tester.element(
        find.descendant(
          of: incomingMedia,
          matching: find.byType(trainer.UgkPackedAlphaVideo),
        ),
      );
      final incomingId = playerFor(tester, incomingMedia);
      expect(posterOpacity(tester, incomingMedia), 0);
      // A cancelled preview cannot replace or re-prime the already decoded rear face.
      var drag = deckDrag(tester);
      drag.onPanStart!(DragStartDetails());
      moveCard(drag, -65);
      await tester.pump();
      drag.onPanCancel!();
      await tester.pumpAndSettle();
      expect(tester.state(incomingMedia), same(incomingState));
      expect(platform.sources, hasLength(3));
      drag = deckDrag(tester);
      drag.onPanStart!(DragStartDetails());
      moveCard(drag, -190);
      await tester.pump();
      drag.onPanEnd!(DragEndDetails());
      await tester.pump();
      for (var frame = 0; frame < 70 && position(tester) == '01'; frame++) {
        expect(tester.state(incomingMedia), same(incomingState));
        expect(posterOpacity(tester, incomingMedia), 0);
        await tester.pump(const Duration(milliseconds: 16));
      }
      await tester.pumpAndSettle();
      expect(position(tester), '02');
      expect(tester.state(frontMedia()), same(incomingState));
      expect(tester.element(frontSurface()), same(incomingSurface));
      expect(posterOpacity(tester, frontMedia()), 0);
      expect(platform.sources, hasLength(4));
      expect(
        platform.commands.where(
          (c) => c.$1 == incomingId && c.$2 == 'prime-first-frame',
        ),
        hasLength(1),
      );
      expect(
        platform.commands.where((c) => c.$1 == incomingId && c.$2 == 'dispose'),
        isEmpty,
      );
      // Going back promotes the original paused occurrence, rather than rebuilding it.
      turnPreview(tester, -1);
      await tester.pumpAndSettle();
      expect(position(tester), '01');
      expect(tester.state(frontMedia()), same(originalState));
      expect(tester.element(frontSurface()), same(originalSurface));
      final disposed = platform.commands
          .where((c) => c.$2 == 'dispose')
          .map((c) => c.$1)
          .toSet();
      expect(platform.sources.length - disposed.length, 3);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'two and three occurrence warm pools retain repeated-action media identities through a full loop',
    (tester) async {
      phone(tester);
      for (final count in [2, 3]) {
        // Teardown the prior identity before measuring a separate bounded pool.
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        final platform = await readyCompactPlaybackCard(
          tester,
          items: List.filled(count, drills.first),
        );
        final states = <Object>{};
        for (var i = 0; i < count; i++) {
          states.add(tester.state(frontMedia()));
          await next(tester);
          expect(posterOpacity(tester, frontMedia()), 0);
          expect(platform.sources, hasLength(count));
        }
        expect(states, hasLength(count));
        expect(position(tester), '01');
        expect(tester.state(frontMedia()), same(states.first));
        expectNoDecoderChurn(platform, warmCount: count);
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets(
    'one painted video surface survives every frame of expanding and collapsing',
    (tester) async {
      phone(tester);
      final platform = await readyCompactPlaybackCard(tester);
      final mediaState = tester.state(frontMedia());
      final artElement = tester.element(
        find.byKey(const ValueKey('home-hero')),
      );
      final surface = frontSurface();
      final surfaceElement = tester.element(surface);
      final controller = tester
          .widget<trainer.UgkPackedAlphaVideo>(surface)
          .controller;
      final textureId = tester
          .widget<Texture>(
            find.descendant(of: surface, matching: find.byType(Texture)),
          )
          .textureId;
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
        expect(
          tester
              .widget<Texture>(
                find.descendant(of: surface, matching: find.byType(Texture)),
              )
              .textureId,
          textureId,
        );
        // Inspect the painted layer tree, not only Transform.filterQuality.
        // The card's pose must wrap the composed texture in a matrix filter,
        // keeping its perspective out of the packed RGB/alpha input space.
        final pose = tester.renderObject<RenderTransform>(
          find.byKey(const ValueKey('home-deck-pose')),
        );
        expect(pose.debugLayer, isA<ImageFilterLayer>());
        final poseLayer = pose.debugLayer! as ImageFilterLayer;
        expect(poseLayer.attached, isTrue);
        final textureLayer = descendantLayers(poseLayer)
            .whereType<TextureLayer>()
            .where((layer) => layer.textureId == textureId);
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
      final surface = frontSurface();
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
    'masthead and number keep one paragraph layout while normal and small cards scale',
    (tester) async {
      phone(tester);
      for (final height in [600.0, 300.0]) {
        await showDeck(tester, height: height, identity: 'printed-$height');
        await tester.pumpAndSettle();
        final face = find.byKey(const ValueKey('home-deck-live-face'));
        final labels = [
          find.byKey(const ValueKey('home-deck-position')),
          find.descendant(of: face, matching: find.text('HIPLAB')),
        ];
        final paragraphs = labels
            .map((label) => tester.renderObject<RenderParagraph>(label))
            .toList();
        final sizes = paragraphs.map((paragraph) => paragraph.size).toList();
        final numberPlacement = find.descendant(
          of: face,
          matching: find.byKey(const ValueKey('face-number')),
        );
        (double?, double?, double?, double?) placement() {
          final placed = tester.widget<Positioned>(numberPlacement);
          return (placed.left, placed.top, placed.width, placed.height);
        }

        List<double> inspectPrintedLabels() {
          expect(tester.widget<Text>(labels[0]).style!.fontSize, 46);
          expect(tester.widget<Text>(labels[1]).style!.fontSize, 11);
          final faceBox = tester.renderObject<RenderBox>(face);
          final scales = <double>[];
          for (var i = 0; i < labels.length; i++) {
            final paragraph = tester.renderObject<RenderParagraph>(labels[i]);
            expect(paragraph.size, sizes[i]);
            // Measure inside the paper so its perspective pose does not
            // disguise a paragraph relayout as changing printed size.
            scales.add(paragraph.getTransformTo(faceBox).storage[0]);
          }
          return scales;
        }

        final restingPlacement = placement();
        final restingScale = inspectPrintedLabels();
        expect(restingPlacement.$2, height == 300 ? 8 : 24);
        expect(restingPlacement.$3, 48);
        expect(restingPlacement.$4, 28);
        expect(restingScale[0], closeTo((height == 300 ? 10 : 15) / 46, 1e-8));
        expect(restingScale[1], closeTo((height == 300 ? 8 : 9.5) / 11, 1e-8));

        await openActionCard(tester);
        var previousScale = restingScale;
        for (var elapsed = 0; elapsed < 416; elapsed += 16) {
          await tester.pump(const Duration(milliseconds: 16));
          final scale = inspectPrintedLabels();
          for (var i = 0; i < scale.length; i++) {
            expect(scale[i], greaterThanOrEqualTo(previousScale[i] - 1e-8));
          }
          previousScale = scale;
        }
        for (final scale in previousScale) {
          expect(scale, closeTo(1, 1e-8));
        }
        expect(placement(), (222.0, 21.0, 66.0, 56.0));

        await dismissActionCard(tester, 'close');
        await tester.pump();
        for (var elapsed = 0; elapsed < 416; elapsed += 16) {
          await tester.pump(const Duration(milliseconds: 16));
          final scale = inspectPrintedLabels();
          for (var i = 0; i < scale.length; i++) {
            expect(scale[i], lessThanOrEqualTo(previousScale[i] + 1e-8));
          }
          previousScale = scale;
        }
        for (var i = 0; i < previousScale.length; i++) {
          expect(previousScale[i], closeTo(restingScale[i], 1e-8));
        }
        expect(placement(), restingPlacement);
        expect(find.byKey(const ValueKey('home-deck-expanded')), findsNothing);
        expect(tester.takeException(), isNull);
      }
    },
  );

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
      expect(tester.widget<Text>(find.text(cue)).maxLines, 2);
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
    'a normal small phone keeps a two-line title and cue above a readable article viewport',
    (tester) async {
      phone(tester);
      tester.view
        ..physicalSize = const Size(360, 740)
        ..padding = const FakeViewPadding(top: 24, bottom: 24);
      final longNames =
          content.drills.values
              .where(
                (drill) =>
                    fixture.policy.actionFor(drill.id) != null &&
                    drill.name.runes.length >= 10 &&
                    drill.name.runes.length <= 16,
              )
              .toList()
            ..sort((a, b) => b.name.length.compareTo(a.name.length));
      expect(longNames, isNotEmpty);
      final drill = longNames.first;
      const cue = '保持骨盆稳定，慢慢呼吸并放松肩膀，始终在舒适范围内停留。';
      final description = List.generate(
        14,
        (i) => '练习说明 ${i + 1}：保持自然呼吸，缓慢完成动作，感受髋部舒适的活动范围。',
      ).join('\n');
      await showDeck(
        tester,
        items: [drill],
        doses: ['每侧 40 秒'],
        cues: [cue],
        descriptions: [description],
      );
      await tester.pumpAndSettle();
      final mediaState = tester.state(frontMedia());
      await openActionCard(tester);
      await tester.pumpAndSettle();
      expect(tester.state(frontMedia()), same(mediaState));
      final caption = find.byKey(const ValueKey('home-deck-caption'));
      expect(tester.widget<Text>(caption).maxLines, 2);
      final title = tester.renderObject<RenderParagraph>(caption);
      expect(title.didExceedMaxLines, isFalse);
      expect(
        title
            .getBoxesForSelection(
              TextSelection(baseOffset: 0, extentOffset: drill.name.length),
            )
            .map((box) => box.top)
            .toSet(),
        hasLength(2),
      );
      final cueParagraph = tester.renderObject<RenderParagraph>(find.text(cue));
      expect(cueParagraph.didExceedMaxLines, isFalse);
      expect(
        cueParagraph
            .getBoxesForSelection(
              TextSelection(baseOffset: 0, extentOffset: cue.length),
            )
            .map((box) => box.top)
            .toSet(),
        hasLength(2),
      );
      final information = find.byKey(
        const ValueKey('home-deck-expanded-description'),
      );
      expect(tester.getSize(information).height, greaterThanOrEqualTo(60));
      expect(
        tester
            .widget<SingleChildScrollView>(information)
            .controller!
            .position
            .maxScrollExtent,
        greaterThan(0),
      );
      expect(tester.widget<Text>(find.text(description)).maxLines, isNull);
      await dismissActionCard(tester, 'close');
      await tester.pumpAndSettle();
      expect(tester.state(frontMedia()), same(mediaState));
      expect(find.byKey(const ValueKey('home-deck-expanded')), findsNothing);
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
      turnPreview(tester, 1);
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
      turnPreview(tester, 1);
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
      turnPreview(tester, 1);
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
      expect(find.byType(trainer.TrainingLibraryActionArt), findsNothing);
      expect(
        tester.widget<trainer.TrainingActionMedia>(frontMedia()).stage,
        Colors.transparent,
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
    'reduced motion keeps a resting touch still and vertical drags change on release',
    (tester) async {
      phone(tester);
      await showDeck(tester, reduced: true);
      await tester.pumpAndSettle();
      final front = find.byKey(const ValueKey('home-deck-front'));
      final before = tester.getRect(front);
      final held = await tester.startGesture(
        tester.getCenter(find.byKey(const ValueKey('home-hero'))),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.getRect(front), before);
      expect(find.byKey(const ValueKey('home-deck-expanded')), findsNothing);
      await held.up();
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('home-deck-expanded')), findsOneWidget);
      await dismissActionCard(tester, 'close');
      await tester.pumpAndSettle();
      expect(tester.getRect(front), before);
      final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(const ValueKey('home-deck-gesture'))),
      );
      await gesture.moveBy(const Offset(0, -220));
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
    turnPreview(tester, 1);
    await tester.pump(const Duration(milliseconds: 80));
    await showDeck(tester, reduced: true);
    await tester.pump();
    expect(frontId(tester), drills[1].id);
    turnPreview(tester, 1);
    await tester.pump();
    expect(frontId(tester), drills[2].id);
    expect(tester.takeException(), isNull);
  });

  Future<HipStore> showHome(
    WidgetTester tester,
    MemoryStorage storage, {
    DateTime Function()? clock,
    bool videoEnabled = false,
    trainer.TrainingMediaPolicy? mediaPolicy,
    AssetBundle? bundle,
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
    final app = HipApp(
      store: store,
      mediaPolicy: mediaPolicy ?? fixture.policy,
      videoEnabled: videoEnabled,
      voice: HipVoice.silent,
    );
    await tester.pumpWidget(
      bundle == null ? app : DefaultAssetBundle(bundle: bundle, child: app),
    );
    await tester.pumpAndSettle();
    addTearDown(store.dispose);
    return store;
  }

  Future<void> chooseHomeRoutine(WidgetTester tester, String routineId) async {
    await tester.tap(find.byKey(const ValueKey('home-rotate')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('home-routine-folder-panel')),
      findsOneWidget,
    );
    final choice = find.byKey(ValueKey('home-routine-choice-$routineId'));
    await tester.ensureVisible(choice);
    await tester.pumpAndSettle();
    await tester.tap(choice);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('home-routine-folder-panel')),
      findsNothing,
    );
  }

  (HomeDeckPlaybackRepository, HomeDeckPlaybackPlatform) homePlayback(
    WidgetTester tester,
  ) {
    final repository = HomeDeckPlaybackRepository();
    final platform = HomeDeckPlaybackPlatform(nativeRgba: true);
    final previousFilter = trainer.UgkPackedAlphaVideo.debugFilterBuilder;
    trainer.UgkPackedAlphaVideo.debugPlatform = platform;
    trainer.UgkPackedAlphaVideo.debugFilterBuilder = (input) => input;
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await platform.dispose();
      repository.dispose();
      trainer.UgkPackedAlphaVideo.debugFilterBuilder = previousFilter;
    });
    return (repository, platform);
  }

  Future<void> nativeFrames(
    WidgetTester tester,
    HomeDeckPlaybackPlatform platform,
    Iterable<int> ids,
  ) async {
    for (final id in ids) {
      platform.emit(id, 'ready');
    }
    await tester.pump();
    for (final id in ids) {
      platform.emit(id, 'first-frame');
    }
    await tester.pump();
    await tester.pump();
  }

  testWidgets(
    'home warms only candidate first posters with the bundle and decode key used when switching scenes',
    (tester) async {
      // A distinct bundle isolates these image-cache keys without evicting
      // images owned by other tests or actively mounted widgets.
      final bundle = _CountingAssetBundle();
      final store = await showHome(tester, MemoryStorage(), bundle: bundle);
      final candidates = <String>{
        for (final scene in [HipScene.chair, HipScene.home])
          for (final id in store.homeRoutines(scene))
            for (final routine in store.libraryRoutines.where(
              (r) => r.id == id,
            ))
              if (store.planForRoutine(routine) case final plan?)
                if (plan.steps.isNotEmpty)
                  fixture.policy.posterAssetFor(plan.steps.first.drill.id)!,
      };
      expect(candidates, isNotEmpty);
      final context = tester.element(find.byType(HipHomeActionDeck));
      expect(DefaultAssetBundle.of(context), same(bundle));
      final width = trainer.TrainingPosterImages.decodeWidth(context);
      expect(width, 394);
      final configuration = createLocalImageConfiguration(context);
      Future<List<ImageCacheStatus?>> statuses() async =>
          (await tester.runAsync(
            () => Future.wait([
              for (final asset in candidates)
                trainer.TrainingPosterImages.provider(
                  asset,
                  width,
                  bundle: bundle,
                ).obtainCacheStatus(configuration: configuration),
            ]),
          ))!;
      var cached = await statuses();
      bool decoded(ImageCacheStatus? status) =>
          status != null &&
          !status.pending &&
          (status.keepAlive || status.live);
      for (var i = 0; i < 100 && !cached.every(decoded); i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pump();
        cached = await statuses();
      }
      expect(cached, everyElement(predicate<ImageCacheStatus?>(decoded)));
      expect(bundle.loads.toSet(), containsAll(candidates));
      final rendered = tester
          .widgetList<trainer.TrainerPoster>(
            find.byType(trainer.TrainerPoster, skipOffstage: false),
          )
          .map((poster) => poster.asset)
          .toSet();
      final loadedPosters = bundle.loads
          .where((asset) => asset.startsWith(HipPublicMedia.posterRoot))
          .toSet();
      // The currently painted fan may load its own neighbors. Additional
      // warming is bounded by the finite set of routine first actions.
      expect(
        loadedPosters.difference(rendered),
        everyElement(isIn(candidates)),
      );
      expect(
        loadedPosters.difference(rendered).length,
        lessThanOrEqualTo(candidates.length),
      );
      expect(fixture.requested, isEmpty);
      final nextRoutine = store.libraryRoutines.firstWhere(
        (r) => r.id == store.homeRoutineId(HipScene.chair),
      );
      final nextAction = store.planForRoutine(nextRoutine)!.steps.first.drill;
      final nextPoster = fixture.policy.posterAssetFor(nextAction.id)!;
      final before = bundle.loads.where((asset) => asset == nextPoster).length;
      expect(before, 1);
      await tester.tap(find.byKey(ValueKey('scene-${HipScene.chair}')));
      await tester.pumpAndSettle();
      expect(frontId(tester), nextAction.id);
      expect(
        bundle.loads.where((asset) => asset == nextPoster),
        hasLength(before),
      );
      expect(fixture.requested, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'routine folder cancels without changing a preview and directly chooses an added plan without playing',
    (tester) async {
      final (repository, platform) = homePlayback(tester);
      final storage = MemoryStorage();
      final store = await showHome(
        tester,
        storage,
        videoEnabled: true,
        mediaPolicy: repository.policy,
      );
      // The folder starts with one 居家 套路; add a second so choosing is real.
      await store.setHomeRoutine(HipScene.home, 'C', added: true);
      await tester.pumpAndSettle();
      await store.pickSceneRoutine(HipScene.home, 'D');
      await tester.pumpAndSettle();
      await nativeFrames(
        tester,
        platform,
        Iterable.generate(platform.sources.length, (i) => i + 1),
      );
      await tester.pumpAndSettle();
      await next(tester);
      final selected = store.libraryRoutines.firstWhere(
        (r) => r.id == store.homeRoutineId(store.scene),
      );
      final persisted = Map<String, String>.of(storage.values);
      final minutes = store.minutes;
      final deckBefore = tester.widget<HipHomeActionDeck>(
        find.byType(HipHomeActionDeck),
      );
      final state = tester.state(frontMedia());
      final surface = tester.element(frontSurface());
      final creates = platform.sources.length;
      final requested = repository.requested.length;
      final preview = frontId(tester);
      await tester.tap(find.byKey(const ValueKey('home-rotate')));
      await tester.pumpAndSettle();
      final currentChoice = find.byKey(
        ValueKey('home-routine-choice-${selected.id}'),
      );
      final semantic = tester.ensureSemantics();
      try {
        await tester.pump();
        expect(
          tester.getSemantics(currentChoice),
          isSemantics(
            isButton: true,
            isSelected: true,
            isInMutuallyExclusiveGroup: true,
            hasEnabledState: true,
            isEnabled: true,
            hasTapAction: true,
          ),
        );
      } finally {
        semantic.dispose();
      }
      // The folder lists the current scene's added 套路 plus the groups tile.
      final choices = store.homeRoutines(store.scene);
      expect(choices, ['D', 'C']);
      for (final id in choices) {
        expect(find.byKey(ValueKey('home-routine-choice-$id')), findsOneWidget);
      }
      expect(
        find.byKey(const ValueKey('home-routine-choose-groups')),
        findsOneWidget,
      );
      expect(platform.sources, hasLength(creates));
      expect(repository.requested, hasLength(requested));
      expect(find.byType(HipPlayerPage), findsNothing);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('home-routine-folder-panel')),
        findsNothing,
      );
      expect(tester.state(frontMedia()), same(state));
      expect(tester.element(frontSurface()), same(surface));
      expect(frontId(tester), preview);
      expect(position(tester), '02');
      expect(
        tester
            .widget<HipHomeActionDeck>(find.byType(HipHomeActionDeck))
            .identity,
        deckBefore.identity,
      );
      expect(storage.values, persisted);

      final directId = choices.firstWhere((id) => id != selected.id);
      final direct = store.libraryRoutines.firstWhere((r) => r.id == directId);
      final expected = store.planForHomeRoutine(directId)!;
      await chooseHomeRoutine(tester, directId);
      final deck = tester.widget<HipHomeActionDeck>(
        find.byType(HipHomeActionDeck),
      );
      expect(deck.identity, endsWith('/${direct.id}'));
      expect(position(tester), '01');
      expect(frontId(tester), expected.steps.first.drill.id);
      expect(
        deck.drills.map((drill) => drill.id),
        expected.steps.map((step) => step.drill.id),
      );
      expect(store.scene, HipScene.home);
      expect(store.minutes, minutes);
      // Choosing is durable: only the selected id changes; the folder stays
      // in its scene (no implicit 办公/居家 switch).
      Map<String, dynamic> saved(Map<String, String> disk) =>
          Map<String, dynamic>.of(
            jsonDecode(disk[HipStore.storageKey]!) as Map<String, dynamic>,
          );
      final before = saved(persisted);
      final after = saved(storage.values);
      expect(after.remove('sceneRoutinePicks'), {'home': directId});
      expect(after.remove('homeRoutineIds'), {
        'chair': ['A'],
        'home': ['D', 'C'],
      });
      before
        ..remove('sceneRoutinePicks')
        ..remove('homeRoutineIds');
      expect(after, before);
      expect(
        platform.commands.where((command) => command.$2 == 'play'),
        isEmpty,
      );
      expect(find.byType(HipPlayerPage), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'the folder remembers its choice per scene and starts the complete plan',
    (tester) async {
      final storage = MemoryStorage();
      final store = await showHome(tester, storage);
      final home = store.libraryRoutines.firstWhere(
        (r) => r.id == store.homeRoutineId(HipScene.home),
      );
      final homePlan = store.planForRoutine(home)!;

      // Add a second 居家 套路, then select the original one: the choice is
      // saved to disk and the folder stays in the 居家 scene.
      await store.setHomeRoutine(HipScene.home, 'B', added: true);
      await tester.pumpAndSettle();
      await chooseHomeRoutine(tester, home.id);
      expect(store.scene, HipScene.home);
      expect(store.homeRoutineId(HipScene.home), 'D');
      expect(
        storage.values[HipStore.storageKey],
        contains('sceneRoutinePicks'),
      );
      expect(
        tester
            .widget<HipHomeActionDeck>(find.byType(HipHomeActionDeck))
            .identity,
        endsWith('/${home.id}'),
      );
      expect(position(tester), '01');
      expect(fixture.requested, isEmpty);
      expect(find.byType(HipPlayerPage), findsNothing);

      // Selecting the already-current 套路 closes the folder without losing
      // the user's inspected action; actual Start still uses the whole plan.
      await next(tester);
      final preview = frontId(tester);
      await chooseHomeRoutine(tester, home.id);
      expect(position(tester), '02');
      expect(frontId(tester), preview);
      await tester.tap(find.byKey(const ValueKey('start-today')));
      await pumpTrainerReady(tester);
      final player = tester.widget<HipPlayerPage>(
        find.byType(HipPlayerPage, skipOffstage: false),
      );
      expect(player.plan.refId, homePlan.refId);
      expect(
        player.plan.steps.map((step) => step.drill.id),
        homePlan.steps.map((step) => step.drill.id),
      );
      expect(player.plan.seconds, homePlan.seconds);
      expect(fixture.requested, isEmpty);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'scene, routine and day changes keep the new first card still until explicit opening',
    (tester) async {
      final (repository, platform) = homePlayback(tester);
      var now = DateTime(2026, 11, 6, 10);
      final store = await showHome(
        tester,
        MemoryStorage(),
        clock: () => now,
        videoEnabled: true,
        mediaPolicy: repository.policy,
      );
      await nativeFrames(
        tester,
        platform,
        Iterable.generate(platform.sources.length, (i) => i + 1),
      );
      await tester.pumpAndSettle();
      var prepared = platform.sources.length;

      Future<void> changedPlan(
        HipScene scene,
        int pick,
        Future<void> Function() change,
      ) async {
        final previousId = frontId(tester);
        final previousState = tester.state(frontMedia());
        final previousSurface = tester.element(frontSurface());
        final previousController = tester
            .widget<trainer.UgkPackedAlphaVideo>(frontSurface())
            .controller;
        final previousPoster = posterOpacity(tester, frontMedia());
        final commandStart = platform.commands.length;
        await change();
        await tester.pump();
        await tester.pump();
        final routine = store.libraryRoutines.firstWhere(
          (r) => r.id == store.homeRoutineId(scene),
        );
        final plan = store.planForRoutine(routine)!;
        final expected = plan.steps.first.drill;
        final deck = tester.widget<HipHomeActionDeck>(
          find.byType(HipHomeActionDeck),
        );
        expect(deck.identity, contains('/${scene.id}/'));
        expect(deck.identity, endsWith('/${routine.id}'));
        expect(frontId(tester), expected.id);
        expect(position(tester), '01');
        expect(
          tester
              .widget<Text>(find.byKey(const ValueKey('home-deck-caption')))
              .data,
          expected.name,
        );
        final state = tester.state(frontMedia());
        final surface = tester.element(frontSurface());
        final controller = tester
            .widget<trainer.UgkPackedAlphaVideo>(frontSurface())
            .controller;
        final reused = expected.id == previousId;
        final compactPoster = reused ? previousPoster : 1.0;
        if (reused) {
          expect(state, same(previousState));
          expect(surface, same(previousSurface));
          expect(controller, same(previousController));
        } else {
          expect(state, isNot(same(previousState)));
        }
        expect(posterOpacity(tester, frontMedia()), compactPoster);
        // The resolved URI mounts the surface before asynchronous native
        // creation supplies its texture. Observe that real creation boundary
        // without treating metadata or a fixed number of pumps as readiness.
        final texture = find.descendant(
          of: frontMedia(),
          matching: find.byType(Texture),
        );
        for (var i = 0; i < 12 && texture.evaluate().isEmpty; i++) {
          await tester.pump(const Duration(milliseconds: 16));
          expect(frontId(tester), expected.id);
          expect(posterOpacity(tester, frontMedia()), compactPoster);
          expect(tester.state(frontMedia()), same(state));
          expect(tester.element(frontSurface()), same(surface));
        }
        expect(texture, findsOneWidget);
        final current = playerFor(tester, frontMedia());
        final fresh = [
          for (var id = prepared + 1; id <= platform.sources.length; id++) id,
        ];
        for (final id in fresh) {
          platform.emit(id, 'ready');
        }
        await tester.pump();
        // Metadata alone cannot make a frame or replace the existing picture.
        expect(controller.hasFrame, reused);
        for (var i = 0; i < 8; i++) {
          await tester.pump(const Duration(milliseconds: 16));
          expect(frontId(tester), expected.id);
          expect(posterOpacity(tester, frontMedia()), compactPoster);
        }
        for (final id in fresh) {
          platform.emit(id, 'first-frame');
        }
        await tester.pump();
        await tester.pump();
        for (var i = 0; i < 24; i++) {
          await tester.pump(const Duration(milliseconds: 16));
          expect(posterOpacity(tester, frontMedia()), compactPoster);
          expect(tester.state(frontMedia()), same(state));
          expect(tester.element(frontSurface()), same(surface));
          expect(frontId(tester), expected.id);
        }
        expect(controller.hasFrame, isTrue);
        expect(
          platform.commands
              .skip(commandStart)
              .where((c) => c.$1 == current && c.$2 == 'play'),
          isEmpty,
        );
        expect(find.byType(CircularProgressIndicator), findsNothing);
        await openActionCard(tester);
        await tester.pumpAndSettle();
        expect(posterOpacity(tester, frontMedia()), 0);
        expect(tester.state(frontMedia()), same(state));
        expect(tester.element(frontSurface()), same(surface));
        await dismissActionCard(tester, 'close');
        await tester.pumpAndSettle();
        expect(posterOpacity(tester, frontMedia()), 0);
        expect(
          tester.widget<trainer.UgkPackedAlphaVideo>(frontSurface()).controller,
          same(controller),
        );
        prepared = platform.sources.length;
      }

      await changedPlan(HipScene.chair, 0, () async {
        await tester.tap(find.byKey(ValueKey('scene-${HipScene.chair}')));
      });
      await changedPlan(HipScene.home, 0, () async {
        await tester.tap(find.byKey(ValueKey('scene-${HipScene.home}')));
      });
      await changedPlan(HipScene.chair, 0, () async {
        await tester.tap(find.byKey(ValueKey('scene-${HipScene.chair}')));
        await tester.pumpAndSettle();
        // 办公 gains a second 套路 in this scene and the folder chooses it.
        await store.setHomeRoutine(HipScene.chair, 'B', added: true);
        await tester.pumpAndSettle();
        await chooseHomeRoutine(tester, 'B');
      });
      await changedPlan(HipScene.chair, 0, () async {
        now = now.add(const Duration(days: 1));
        await store.choose();
      });

      // An ordinary visual/route refresh must preserve the now-explicitly
      // revealed current frame rather than reapplying the new-plan poster lock.
      final state = tester.state(frontMedia());
      final surface = tester.element(frontSurface());
      final creates = platform.sources.length;
      await store.setTheme(HipThemeChoice.light);
      await tester.pumpAndSettle();
      expect(tester.state(frontMedia()), same(state));
      expect(tester.element(frontSurface()), same(surface));
      expect(posterOpacity(tester, frontMedia()), 0);
      await tester.tap(find.byKey(const ValueKey('home-more')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('more-back')));
      await tester.pumpAndSettle();
      expect(tester.state(frontMedia()), same(state));
      expect(tester.element(frontSurface()), same(surface));
      expect(posterOpacity(tester, frontMedia()), 0);
      expect(platform.sources, hasLength(creates));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'rapid scene A to B to A ignores late first frames from retired plans',
    (tester) async {
      final (repository, platform) = homePlayback(tester);
      await showHome(
        tester,
        MemoryStorage(),
        videoEnabled: true,
        mediaPolicy: repository.policy,
      );
      final original = tester.widget<HipHomeActionDeck>(
        find.byType(HipHomeActionDeck),
      );
      // A remains cold: returning to it cannot reuse a truly ready surface.
      await tester.tap(find.byKey(ValueKey('scene-${HipScene.chair}')));
      await tester.pump();
      await tester.pump();
      final retired = platform.sources.length;
      for (var id = 1; id <= retired; id++) {
        platform.emit(id, 'ready');
      }
      await tester.pump();
      // Queue B's real frame and leave before its post-frame notification can
      // be applied to the next plan's freshly reset occurrence keys.
      for (var id = 1; id <= retired; id++) {
        platform.emit(id, 'first-frame');
      }
      await tester.tap(find.byKey(ValueKey('scene-${HipScene.home}')));
      await tester.pump();
      await tester.pump();
      final latest = tester.widget<HipHomeActionDeck>(
        find.byType(HipHomeActionDeck),
      );
      expect(latest.identity, original.identity);
      expect(frontId(tester), original.drills.first.id);
      final state = tester.state(frontMedia());
      final surface = tester.element(frontSurface());
      final controller = tester
          .widget<trainer.UgkPackedAlphaVideo>(frontSurface())
          .controller;
      for (var id = 1; id <= retired; id++) {
        platform.emit(id, 'first-frame');
      }
      for (var i = 0; i < 12; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        expect(posterOpacity(tester, frontMedia()), 1);
        expect(controller.hasFrame, isFalse);
        expect(tester.state(frontMedia()), same(state));
      }
      await nativeFrames(tester, platform, [
        for (var id = retired + 1; id <= platform.sources.length; id++) id,
      ]);
      for (var i = 0; i < 24; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        expect(posterOpacity(tester, frontMedia()), 1);
        expect(tester.element(frontSurface()), same(surface));
      }
      expect(controller.hasFrame, isTrue);
      expect(platform.commands.where((c) => c.$2 == 'play'), isEmpty);
      await openActionCard(tester);
      await tester.pumpAndSettle();
      expect(posterOpacity(tester, frontMedia()), 0);
      expect(tester.element(frontSurface()), same(surface));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'changing ordered drills with the same identity locks the new first card without affecting theme refreshes',
    (tester) async {
      phone(tester);
      final platform = await readyCompactPlaybackCard(tester);
      final previous = platform.sources.length;
      final changed = [drills[2], drills[0], drills[1], ...drills.skip(3)];
      await showDeck(tester, items: changed, videoEnabled: true);
      await tester.pump();
      await tester.pump();
      expect(frontId(tester), changed.first.id);
      expect(position(tester), '01');
      final state = tester.state(frontMedia());
      final surface = tester.element(frontSurface());
      await nativeFrames(tester, platform, [
        for (var id = previous + 1; id <= platform.sources.length; id++) id,
      ]);
      for (var i = 0; i < 24; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        expect(posterOpacity(tester, frontMedia()), 1);
        expect(tester.state(frontMedia()), same(state));
        expect(tester.element(frontSurface()), same(surface));
      }
      await showDeck(
        tester,
        items: changed,
        videoEnabled: true,
        palette: HipPalette.light,
      );
      await tester.pumpAndSettle();
      expect(posterOpacity(tester, frontMedia()), 1);
      expect(tester.state(frontMedia()), same(state));
      await openActionCard(tester);
      await tester.pumpAndSettle();
      await dismissActionCard(tester, 'close');
      await tester.pumpAndSettle();
      await showDeck(
        tester,
        items: changed,
        videoEnabled: true,
        palette: HipPalette.dark,
      );
      await tester.pumpAndSettle();
      expect(posterOpacity(tester, frontMedia()), 0);
      expect(tester.state(frontMedia()), same(state));
      expect(tester.element(frontSurface()), same(surface));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'closing an opening cold card keeps late native frames hidden until the next inspection',
    (tester) async {
      final (repository, platform) = homePlayback(tester);
      await showHome(
        tester,
        MemoryStorage(),
        videoEnabled: true,
        mediaPolicy: repository.policy,
      );
      final prepared = platform.sources.length;
      for (var id = 1; id <= prepared; id++) {
        platform.emit(id, 'ready');
      }
      await tester.pump();
      final state = tester.state(frontMedia());
      final surface = tester.element(frontSurface());
      final controller = tester
          .widget<trainer.UgkPackedAlphaVideo>(frontSurface())
          .controller;
      expect(controller.hasFrame, isFalse);
      await openActionCard(tester);
      await tester.pump(const Duration(milliseconds: 80));
      await dismissActionCard(tester, 'close');
      await tester.pumpAndSettle();
      expect(posterOpacity(tester, frontMedia()), 1);
      for (var id = 1; id <= prepared; id++) {
        platform.emit(id, 'first-frame');
      }
      await tester.pump();
      await tester.pump();
      for (var i = 0; i < 24; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        expect(posterOpacity(tester, frontMedia()), 1);
        expect(tester.state(frontMedia()), same(state));
        expect(tester.element(frontSurface()), same(surface));
      }
      expect(controller.hasFrame, isTrue);
      expect(platform.sources, hasLength(prepared));
      expect(
        platform.commands.where(
          (c) => {'dispose', 'seek', 'return-to-first-frame'}.contains(c.$2),
        ),
        isEmpty,
      );
      await openActionCard(tester);
      await tester.pumpAndSettle();
      expect(posterOpacity(tester, frontMedia()), 0);
      expect(tester.element(frontSurface()), same(surface));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'a new plan keeps the ready visible occurrence when it becomes the first card',
    (tester) async {
      phone(tester);
      for (final inspected in [false, true]) {
        final platform = await readyCompactPlaybackCard(
          tester,
          neighborsReady: false,
          openAndClose: false,
        );
        await next(tester);
        expect(position(tester), '02');
        final current = playerFor(tester, frontMedia());
        platform.emit(current, 'first-frame');
        await tester.pump();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(posterOpacity(tester, frontMedia()), 1);
        if (inspected) {
          await openActionCard(tester);
          await tester.pumpAndSettle();
          await dismissActionCard(tester, 'close');
          await tester.pumpAndSettle();
        }
        final state = tester.state(frontMedia());
        final surface = tester.element(frontSurface());
        final controller = tester
            .widget<trainer.UgkPackedAlphaVideo>(frontSurface())
            .controller;
        expect(controller.hasFrame, isTrue);
        final expectedPoster = inspected ? 0.0 : 1.0;
        final commandStart = platform.commands.length;
        final changed = [drills[1], drills[2], drills[0], ...drills.skip(3)];
        await showDeck(
          tester,
          identity: 'new-plan/$inspected',
          items: changed,
          videoEnabled: true,
        );
        for (var i = 0; i < 24; i++) {
          await tester.pump(const Duration(milliseconds: 16));
          expect(frontId(tester), drills[1].id);
          expect(position(tester), '01');
          expect(tester.state(frontMedia()), same(state));
          expect(tester.element(frontSurface()), same(surface));
          expect(playerFor(tester, frontMedia()), current);
          expect(
            tester
                .widget<trainer.UgkPackedAlphaVideo>(frontSurface())
                .controller,
            same(controller),
          );
          expect(posterOpacity(tester, frontMedia()), expectedPoster);
        }
        expect(
          platform.commands
              .skip(commandStart)
              .where(
                (c) =>
                    c.$1 == current &&
                    {
                      'dispose',
                      'prime-first-frame',
                      'seek',
                      'return-to-first-frame',
                      'play',
                    }.contains(c.$2),
              ),
          isEmpty,
        );
        // The remapped occurrence can still be explicitly revealed. Its
        // readiness callback must now belong to index 0, not the old index 1.
        await openActionCard(tester);
        await tester.pumpAndSettle();
        expect(posterOpacity(tester, frontMedia()), 0);
        expect(tester.state(frontMedia()), same(state));
        await dismissActionCard(tester, 'close');
        await tester.pumpAndSettle();
        expect(posterOpacity(tester, frontMedia()), 0);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      }
    },
  );

  testWidgets(
    'opening More and Settings keeps the home card current frame throughout both route transitions',
    (tester) async {
      final repository = HomeDeckPlaybackRepository();
      final platform = HomeDeckPlaybackPlatform(nativeRgba: true);
      final previousFilter = trainer.UgkPackedAlphaVideo.debugFilterBuilder;
      trainer.UgkPackedAlphaVideo.debugPlatform = platform;
      trainer.UgkPackedAlphaVideo.debugFilterBuilder = (input) => input;
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        await platform.dispose();
        repository.dispose();
        trainer.UgkPackedAlphaVideo.debugFilterBuilder = previousFilter;
      });
      await showHome(
        tester,
        MemoryStorage(),
        videoEnabled: true,
        mediaPolicy: repository.policy,
      );
      expect(platform.sources, hasLength(3));
      expect(platform.nativeCreates, 3);
      for (var id = 1; id <= platform.sources.length; id++) {
        platform.emit(id, 'ready');
      }
      await tester.pump();
      for (var id = 1; id <= platform.sources.length; id++) {
        platform.emit(id, 'first-frame');
      }
      await tester.pumpAndSettle();
      final hero = find.byKey(const ValueKey('home-hero'), skipOffstage: false);
      final media = find.descendant(
        of: hero,
        matching: find.byType(trainer.TrainingActionMedia, skipOffstage: false),
        skipOffstage: false,
      );
      final surface = frontSurface(skipOffstage: false);
      final mediaState = tester.state(media);
      final surfaceElement = tester.element(surface);
      final controller = tester
          .widget<trainer.UgkPackedAlphaVideo>(surface)
          .controller;
      void sameHeldFrame() {
        expect(tester.state(media), same(mediaState));
        expect(tester.element(surface), same(surfaceElement));
        expect(
          tester.widget<trainer.UgkPackedAlphaVideo>(surface).controller,
          same(controller),
        );
        expect(controller.hasFrame, isTrue);
        expect(
          tester.widget<trainer.TrainingActionMedia>(media).paused,
          isTrue,
        );
        final poster = find.descendant(
          of: media,
          matching: find.byKey(
            const ValueKey('public-action-poster'),
            skipOffstage: false,
          ),
          skipOffstage: false,
        );
        expect(tester.widget<AnimatedOpacity>(poster).opacity, 1);
        expectNoDecoderChurn(platform);
      }

      Future<void> transition() async {
        await tester.pump();
        sameHeldFrame();
        for (var i = 0; i < 28; i++) {
          await tester.pump(const Duration(milliseconds: 16));
          sameHeldFrame();
        }
      }

      sameHeldFrame();
      await tester.tap(find.byKey(const ValueKey('home-more')));
      await transition();
      expect(find.byKey(const ValueKey('more-list')), findsOneWidget);
      // A second covered route must not replace the retained paused surface.
      await tester.tap(find.byKey(const ValueKey('more-settings')));
      await transition();
      await tester.binding.handlePopRoute();
      await transition();
      await tester.tap(find.byKey(const ValueKey('more-back')));
      await transition();
      expect(
        find.byKey(const ValueKey('home-more')).hitTestable(),
        findsOneWidget,
      );
      expect(platform.commands.where((c) => c.$2 == 'play'), isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'streak shortcut opens one records route and preserves the inspected second card through entry and return',
    (tester) async {
      final (repository, platform) = homePlayback(tester);
      await showHome(
        tester,
        MemoryStorage(),
        videoEnabled: true,
        mediaPolicy: repository.policy,
      );
      await nativeFrames(
        tester,
        platform,
        Iterable.generate(platform.sources.length, (i) => i + 1),
      );
      await tester.pumpAndSettle();
      final initiallyPrepared = platform.sources.length;
      await next(tester);
      // Turning exposes a new warm neighbor beyond the initially primed pool.
      // Give it a real composed frame before asserting the whole ready pool
      // stays retained; a cold covered neighbor may legitimately be released.
      await nativeFrames(
        tester,
        platform,
        Iterable.generate(
          platform.sources.length - initiallyPrepared,
          (i) => initiallyPrepared + i + 1,
        ),
      );
      await tester.pumpAndSettle();
      await openActionCard(tester);
      await tester.pumpAndSettle();
      await dismissActionCard(tester, 'close');
      await tester.pumpAndSettle();
      expect(position(tester), '02');
      expect(posterOpacity(tester, frontMedia()), 0);

      final hero = find.byKey(const ValueKey('home-hero'), skipOffstage: false);
      final media = find.descendant(
        of: hero,
        matching: find.byType(trainer.TrainingActionMedia, skipOffstage: false),
        skipOffstage: false,
      );
      final surface = frontSurface(skipOffstage: false);
      final state = tester.state(media);
      final element = tester.element(surface);
      final controller = tester
          .widget<trainer.UgkPackedAlphaVideo>(surface)
          .controller;
      final texture = find.descendant(
        of: media,
        matching: find.byType(Texture, skipOffstage: false),
        skipOffstage: false,
      );
      final textureElement = tester.element(texture);
      final textureId = tester.widget<Texture>(texture).textureId;
      final creates = platform.sources.length;
      final nativeCreates = platform.nativeCreates;
      final commandStart = platform.commands.length;
      final requested = repository.requested.length;
      final records = find.byType(HipProgressPage, skipOffstage: false);

      void sameHeldFrame() {
        expect(tester.state(media), same(state));
        expect(tester.element(surface), same(element));
        expect(tester.element(texture), same(textureElement));
        expect(tester.widget<Texture>(texture).textureId, textureId);
        expect(
          tester.widget<trainer.UgkPackedAlphaVideo>(surface).controller,
          same(controller),
        );
        expect(controller.hasFrame, isTrue);
        expect(
          tester.widget<trainer.TrainingActionMedia>(media).paused,
          isTrue,
        );
        final poster = find.descendant(
          of: media,
          matching: find.byKey(
            const ValueKey('public-action-poster'),
            skipOffstage: false,
          ),
          skipOffstage: false,
        );
        expect(tester.widget<AnimatedOpacity>(poster).opacity, 0);
        expect(
          tester
              .widget<Text>(
                find.byKey(
                  const ValueKey('home-deck-position'),
                  skipOffstage: false,
                ),
              )
              .data,
          '02',
        );
        expect(platform.sources, hasLength(creates));
        expect(platform.nativeCreates, nativeCreates);
        expect(repository.requested, hasLength(requested));
        expect(
          platform.commands
              .skip(commandStart)
              .where((command) => command.$2 == 'play'),
          isEmpty,
        );
      }

      Future<void> transition(int frames) async {
        await tester.pump();
        sameHeldFrame();
        for (var frame = 0; frame < frames; frame++) {
          await tester.pump(const Duration(milliseconds: 16));
          sameHeldFrame();
        }
      }

      // Two queued activations before the first route frame exercise the
      // double-tap guard without the second pointer hitting the entering page.
      final activate = tester
          .widget<HipPressable>(
            find.byKey(const ValueKey('home-streak-button')),
          )
          .onTap!;
      activate();
      activate();
      await transition(28);
      expect(records, findsOneWidget);
      expect(
        tester.widget<HipProgressPage>(records).section,
        HipProgressSection.records,
      );
      final route = ModalRoute.of(tester.element(records))! as HipRoute<void>;
      expect(route.transition, HipTransition.content);
      expect(route.pinLeading, isFalse);
      final navPage = tester.widget<HipNavPage>(
        find.ancestor(of: records, matching: find.byType(HipNavPage)),
      );
      expect(navPage.title, '训练记录');
      expect(navPage.bodyScrollsUnderBar, isTrue);
      expect(find.byType(HipPlayerPage), findsNothing);

      await tester.tap(find.byKey(const ValueKey('home-records-back')));
      await transition(24);
      expect(records, findsNothing);
      expect(
        find.byKey(const ValueKey('home-streak-button')).hitTestable(),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('home-streak-button')));
      await transition(28);
      expect(records, findsOneWidget);
      await tester.binding.handlePopRoute();
      await transition(24);
      expect(records, findsNothing);
      expect(position(tester), '02');
      sameHeldFrame();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'zero-day streak opens empty records whose start action uses the current folder selection',
    (tester) async {
      final store = await showHome(tester, MemoryStorage());
      expect(store.doneDays, isEmpty);
      expect(store.sessions, isEmpty);
      expect(store.streak, 0);
      final defaultPlan = store.todayPlan!;
      // Add a second 居家 套路 to this scene's folder, then choose it.
      await store.setHomeRoutine(store.scene, 'B', added: true);
      await tester.pumpAndSettle();
      final selected = store.libraryRoutines.firstWhere(
        (routine) => routine.id == 'B',
      );
      final expected = store.planForRoutine(selected)!;
      expect(expected.refId, isNot(defaultPlan.refId));
      await chooseHomeRoutine(tester, selected.id);
      expect(
        tester
            .widget<HipHomeActionDeck>(find.byType(HipHomeActionDeck))
            .identity,
        endsWith('/${selected.id}'),
      );

      final badge = find.byKey(const ValueKey('home-streak-button'));
      expect(tester.getSize(badge).height, greaterThanOrEqualTo(44));
      expect(
        tester.getSize(find.byKey(const ValueKey('home-streak'))).height,
        26,
      );
      final semantics = tester.ensureSemantics();
      try {
        await tester.pump();
        expect(
          tester.getSemantics(badge),
          isSemantics(
            isButton: true,
            hasTapAction: true,
            label: '连续打卡 0 天，查看训练记录',
          ),
        );
      } finally {
        semantics.dispose();
      }
      await tester.tap(badge);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('records-empty')), findsOneWidget);
      expect(find.byType(HipPlayerPage), findsNothing);
      final start = find.byKey(const ValueKey('records-start'));
      await tester.ensureVisible(start);
      await tester.pumpAndSettle();
      await tester.tap(start);
      await pumpTrainerReady(tester);
      final player = tester.widget<HipPlayerPage>(
        find.byType(HipPlayerPage, skipOffstage: false),
      );
      expect(player.plan.refId, expected.refId);
      expect(
        player.plan.routines.map((routine) => routine.id),
        expected.routines.map((routine) => routine.id),
      );
      expect(
        player.plan.steps.map((step) => step.drill.id),
        expected.steps.map((step) => step.drill.id),
      );
      expect(player.plan.seconds, expected.seconds);
      expect(fixture.requested, isEmpty);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('home shadow meets the visible poster and skips props', (
    tester,
  ) async {
    phone(tester);
    final bare = content.drills['n-pelvis-circle']!;
    final mat = content.drills['s-kneel-hipflex']!;
    final chair = content.drills['o-seated-fig4']!;
    final shadow = find.byKey(const ValueKey('face-contact-shadow'));

    await showDeck(tester, items: [bare], palette: HipPalette.light);
    await tester.pumpAndSettle();
    final media = tester.getRect(find.byKey(const ValueKey('home-hero')));
    final side = media.shortestSide;
    final art = Rect.fromCenter(
      center: media.center,
      width: side,
      height: side,
    );
    final contact = tester.getRect(shadow);
    // Bundled 640px pelvis-circle poster alpha bounds: (208, 42, 413, 599).
    expect(contact.width, closeTo(side * (413 - 208) / 640 * .6, .001));
    expect(contact.height, 10);
    expect(contact.center.dx, closeTo(art.left + side * 310.5 / 640, .001));
    expect(contact.center.dy, closeTo(art.top + side * 599 / 640, .001));

    for (final withProp in [mat, chair]) {
      await showDeck(tester, items: [withProp], palette: HipPalette.light);
      await tester.pumpAndSettle();
      expect(shadow, findsNothing);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('home deck grows to the height and side margins available', (
    tester,
  ) async {
    await showHome(tester, MemoryStorage());
    final header = find.byKey(const ValueKey('home-page-header'));
    final pagination = find.byKey(const ValueKey('home-deck-pagination'));
    final routine = find.byKey(const ValueKey('home-routine-section'));
    final start = find.byKey(const ValueKey('start-today'));

    // Exercise both the height limit and the width limit at the same width.
    for (final height in [780.0, 980.0]) {
      tester.view.physicalSize = Size(394, height);
      await tester.pumpAndSettle();

      final card = tester.getRect(visualFront());
      final dots = tester.getRect(pagination);
      final group = tester.getRect(routine);
      final headerBottom = tester.getRect(header).bottom;
      final availableHeight = group.top - 18 - 5 - 14 - (headerBottom + 20);
      final widthLimitedHeight = (394 - 44) / .62;
      expect(
        card.height,
        closeTo(math.min(availableHeight, widthLimitedHeight), .01),
      );
      expect(card.width / card.height, closeTo(.62, .001));
      expect(card.left, greaterThanOrEqualTo(22 - .01));
      expect(card.right, lessThanOrEqualTo(394 - 22 + .01));
      expect(dots.top - card.bottom, closeTo(14, .01));
      expect(dots.height, closeTo(5, .01));
      expect(group.top - dots.bottom, closeTo(18, .01));
      expect(tester.getRect(start).top - group.bottom, closeTo(20, .01));
      expect(tester.getRect(start).bottom, closeTo(height - 34 - 18, .01));
      for (final rear in [nextFace(), paperFor(2)]) {
        expect(tester.getSize(rear).width, closeTo(card.width, .01));
        expect(tester.getSize(rear).height, closeTo(card.height, .01));
      }
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('small home scrolls with a 400 point deck and full footer', (
    tester,
  ) async {
    await showHome(tester, MemoryStorage());
    final routine = find.byKey(const ValueKey('home-routine-section'));
    final start = find.byKey(const ValueKey('start-today'));
    final normalRoutineHeight = tester.getSize(routine).height;
    final normalStartSize = tester.getSize(start);

    tester.view.physicalSize = const Size(394, 520);
    await tester.pumpAndSettle();
    final card = tester.getRect(visualFront());
    expect(card.height, closeTo(400, .01));
    expect(card.width / card.height, closeTo(.62, .001));
    expect(tester.getSize(routine).height, closeTo(normalRoutineHeight, .01));
    expect(tester.getSize(start), normalStartSize);
    final scroll = tester.state<ScrollableState>(
      find.ancestor(of: routine, matching: find.byType(Scrollable)).first,
    );
    expect(scroll.position.maxScrollExtent, greaterThan(0));
    expect(start.hitTestable(), findsNothing);

    await tester.ensureVisible(start);
    await tester.pumpAndSettle();
    expect(scroll.position.pixels, greaterThan(0));
    expect(tester.getRect(routine).top, greaterThanOrEqualTo(47));
    expect(
      find.byKey(const ValueKey('home-rotate')).hitTestable(),
      findsOneWidget,
    );
    expect(start.hitTestable(), findsOneWidget);
    expect(
      tester.getRect(start).top - tester.getRect(routine).bottom,
      closeTo(20, .01),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'home clips cards at the real screen edges outside its 14 point padding',
    (tester) async {
      final store = await showHome(tester, MemoryStorage());
      final deck = find.byType(HipHomeActionDeck);
      expect(tester.getTopLeft(deck).dx, 14);
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
      expect(box.localToGlobal(localClip.topLeft).dy, lessThanOrEqualTo(0));
      expect(
        box.localToGlobal(localClip.bottomRight).dy,
        greaterThanOrEqualTo(853),
      );
      final title = tester
          .widget<Text>(find.byKey(const ValueKey('home-title')))
          .data;
      // Add a second 居家 套路 and switch the folder selection to it.
      await store.setHomeRoutine(HipScene.home, 'B', added: true);
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
      final routine = store.libraryRoutines.firstWhere(
        (r) => r.id == store.homeRoutineId(store.scene),
      );
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
      // Add a second 套路 and select it: the deck identity must change.
      await store.setHomeRoutine(HipScene.home, 'B', added: true);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<HipHomeActionDeck>(find.byType(HipHomeActionDeck))
            .identity,
        isNot(identity),
      );
      expect(position(tester), '01');
      await next(tester);
      // The scene switch still resolves each scene's remembered 套路.
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
      // Legacy safety answers are inert: the home deck stays available.
      expect(find.byType(HipHomeActionDeck), findsOneWidget);
      expect(find.byKey(const ValueKey('start-today')), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
