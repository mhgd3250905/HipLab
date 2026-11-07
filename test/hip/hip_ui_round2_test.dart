// Round-2 UI polish (2026-10-18): segmented control, the custom icon set,
// clean thumbnails and directional page transitions. The shared-element
// heroes were removed by the transition-quality pass (audit 2026-10-18):
// every transition now has one main move, see test/hip/hip_transition_test.dart.
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiplab/hip/control/hip_store.dart';
import 'package:hiplab/hip/domain/hip_models.dart';
import 'package:hiplab/hip/ui/hip_app.dart';
import 'package:hiplab/hip/ui/hip_glass.dart';
import 'package:hiplab/hip/ui/hip_icons.dart';
import 'package:hiplab/hip/ui/hip_page_kit.dart';
import 'package:hiplab/hip/ui/hip_routes.dart';
import 'package:hiplab/hip/ui/hip_segmented.dart';
import 'package:hiplab/hip/ui/hip_theme.dart';
import 'package:hiplab/hip/ui/hip_widgets.dart';

import 'package:ugk_trainer_runtime/ugk_trainer.dart' as trainer;

import 'hip_domain_test.dart' show MemoryStorage, loadContent;
import 'checkup_entry.dart';
import 'home_nav.dart';
import 'public_media_fixture.dart';
import 'trainer_test_pump.dart';

Future<void> expectPausedClock(WidgetTester tester) async {
  // Paused controls intentionally keep breathing; wait only for their morph.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  expect(
    tester
        .widget<trainer.UgkPlayPauseButton>(find.byKey(const ValueKey('pause')))
        .isPlaying,
    isFalse,
  );
  final digits = find.byType(trainer.TrainerCountdownDigits);
  expect(tester.widget<trainer.TrainerCountdownDigits>(digits).dim, isTrue);
  final before = tester.widget<trainer.TrainerCountdownDigits>(digits).value;
  await tester.pump(const Duration(seconds: 2));
  expect(tester.widget<trainer.TrainerCountdownDigits>(digits).value, before);
}

void main() {
  final content = loadContent();

  Future<HipStore> pumpApp(
    WidgetTester tester, {
    Size size = const Size(390, 844),
    HipThemeChoice theme = HipThemeChoice.dark,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final store = HipStore(
      content: content,
      storage: MemoryStorage(),
      clock: () => DateTime(2026, 10, 16, 9, 41),
    );
    await store.initialize();
    store
      ..safety = {'pregnancy': false, 'surgery': false, 'acute': false}
      ..identity = HipIdentity.office
      ..minutes = 5
      ..scene = HipScene.chair
      ..theme = theme;
    await tester.pumpWidget(
      HipApp(
        mediaPolicy: installPublicMediaFixture().policy,
        store: store,
        videoEnabled: false,
      ),
    );
    await tester.pumpAndSettle();
    return store;
  }

  group('segmented control', () {
    for (final theme in [HipThemeChoice.dark, HipThemeChoice.light]) {
      // Home r1: the 分钟 picker left 首页; the 办公/居家 switch is its one
      // segmented control and keeps the concentric sliding thumb.
      testWidgets(
        'home scene switch slides one concentric thumb (${theme.id})',
        (tester) async {
          final store = await pumpApp(tester, theme: theme);
          final picker = find.byWidgetPredicate(
            (w) => w is HipSegmented<HipScene> && w.keyPrefix == 'scene',
          );
          expect(picker, findsOneWidget);
          final seg = tester.widget<HipSegmented<HipScene>>(picker);
          // Concentric corners: inner radius = outer radius − inset.
          expect(seg.thumbRadius, seg.radius - seg.inset);
          final thumb = find.byKey(const ValueKey('scene-thumb'));
          expect(thumb, findsOneWidget);
          // Glass m2: the selected item is the brighter inner glass pill.
          final face = tester.widget<HipGlassPill>(
            find.descendant(of: thumb, matching: find.byType(HipGlassPill)),
          );
          expect(face.radius, seg.thumbRadius);

          final x0 = tester.getRect(thumb).left;
          final target = tester.getRect(
            find.byKey(ValueKey('scene-${HipScene.home}')),
          );
          await tester.tap(find.byKey(ValueKey('scene-${HipScene.home}')));
          await tester.pump();
          await tester.pump(HipMotion.segment ~/ 3);
          final mid = tester.getRect(thumb).left;
          // Mid-flight: the thumb is travelling, not jumping.
          expect(mid, greaterThan(x0 + 1));
          expect(mid, lessThan(target.left - 1));
          await tester.pumpAndSettle();
          expect(store.scene, HipScene.home);
          expect(tester.getRect(thumb).center.dx, closeTo(target.center.dx, 1));
        },
      );
    }

    testWidgets('dragging along the track selects', (tester) async {
      final store = await pumpApp(tester);
      final from = tester.getCenter(
        find.byKey(ValueKey('scene-${HipScene.chair}')),
      );
      final to = tester.getCenter(
        find.byKey(ValueKey('scene-${HipScene.home}')),
      );
      await tester.dragFrom(from, to - from);
      await tester.pumpAndSettle();
      expect(store.scene, HipScene.home);
    });
  });

  testWidgets('every glyph paints in both states, inside the 24 grid', (
    tester,
  ) async {
    final key = GlobalKey();
    for (final g in HipGlyph.values) {
      for (final filled in [false, true]) {
        await tester.pumpWidget(
          Center(
            child: RepaintBoundary(
              key: key,
              child: HipIcon(
                g,
                size: 48,
                filled: filled,
                color: const Color(0xff000000),
              ),
            ),
          ),
        );
        final ink = await tester.runAsync(() async {
          final boundary =
              key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          final image = await boundary.toImage();
          final data = await image.toByteData();
          final bytes = data!.buffer.asUint8List();
          var painted = 0, edge = 0;
          for (var y = 0; y < 48; y++) {
            for (var x = 0; x < 48; x++) {
              if (bytes[(y * 48 + x) * 4 + 3] > 40) {
                painted++;
                // Outside the 1-unit (2 px) outer margin of the grid.
                if (x < 2 || y < 2 || x > 45 || y > 45) edge++;
              }
            }
          }
          image.dispose();
          return (painted, edge);
        });
        expect(ink!.$1, greaterThan(40), reason: '$g filled=$filled is blank');
        expect(ink.$2, 0, reason: '$g filled=$filled bleeds out of the grid');
      }
    }
    // Ambient IconTheme colour and size are honoured (drop-in for Icon).
    await tester.pumpWidget(
      const IconTheme(
        data: IconThemeData(size: 30, color: Color(0xff3ccfa4)),
        child: Center(child: HipIcon(HipGlyph.play)),
      ),
    );
    expect(tester.getSize(find.byType(HipIcon)), const Size(30, 30));
    final painter =
        tester
                .widget<CustomPaint>(
                  find.descendant(
                    of: find.byType(HipIcon),
                    matching: find.byType(CustomPaint),
                  ),
                )
                .painter!
            as HipIconPainter;
    expect(painter.color, const Color(0xff3ccfa4));
  });

  testWidgets(
    'App tabs keep HipLab icons; training uses shared player controls',
    (tester) async {
      await pumpApp(tester);
      expect(find.byType(Icon), findsNothing);
      expect(find.byType(HipIcon), findsWidgets);
      // Home r1: former tabs open from 更多; the public SDK library owns
      // its own Material icons and must not be mistaken for host styling.
      for (final (name, open) in [
        ('more', openMore),
        ('practice', openPractice),
        ('settings', openSettings),
        ('records', openRecords),
      ]) {
        await open(tester);
        final hostIcons = find
            .byType(Icon)
            .evaluate()
            .where(
              (element) =>
                  element
                      .findAncestorWidgetOfExactType<
                        trainer.TrainingLibraryPage
                      >() ==
                  null,
            );
        expect(hostIcons, isEmpty, reason: 'host-owned icons in $name');
      }
      await backHome(tester);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('start-today')));
      await pumpTrainerReady(tester);
      expect(find.byType(trainer.TrainerCountdownDigits), findsOneWidget);
      // The training package owns the playback controls and its icon set.
      expect(find.byType(trainer.TrainerPlayer), findsOneWidget);
      expect(find.byKey(const ValueKey('pause')), findsOneWidget);
      expect(find.byKey(const ValueKey('skip')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('pause')));
      await expectPausedClock(tester);
    },
  );

  testWidgets('countdown ring draws no dot at 0 % and an arc later', (
    tester,
  ) async {
    HipColors.palette = HipPalette.dark;
    final key = GlobalKey();
    Future<List<int>> topPixel(double progress) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: RepaintBoundary(
              key: key,
              child: HipCountdownRing(
                progress: progress,
                label: '30',
                size: 100,
                color: const Color(0xff00ff00),
              ),
            ),
          ),
        ),
      );
      return (await tester.runAsync(() async {
        final b =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await b.toImage();
        final bytes = (await image.toByteData())!.buffer.asUint8List();
        // Just right of 12 o'clock on the ring (radius 44.4, stroke 5.2).
        const x = 53, y = 6;
        final i = (y * 100 + x) * 4;
        image.dispose();
        return bytes.sublist(i, i + 4);
      }))!;
    }

    final empty = await topPixel(0);
    expect(empty[1], lessThan(80), reason: 'no green dot at the top at 0 %');
    final started = await topPixel(.5);
    expect(started[1], greaterThan(60), reason: 'arc tail at the top');
  });

  testWidgets('hip-check thumbnails: one card edge, concentric clean crop', (
    tester,
  ) async {
    await pumpApp(tester);
    await openCheckupIntro(tester);
    final row = find.byKey(const ValueKey('intro-item-butterfly'));
    // No framed media box inside the row any more.
    expect(
      find.descendant(of: row, matching: find.byType(HipMediaFrame)),
      findsNothing,
    );
    // m6: flat hairline rows — no card around the row, small clean crop.
    expect(
      find.ancestor(of: row, matching: find.byType(HipPanel)),
      findsNothing,
    );
    final thumb = tester.widget<HipThumb>(
      find.descendant(of: row, matching: find.byType(HipThumb)),
    );
    expect(thumb.radius, lessThanOrEqualTo(8));
  });

  group('page transitions', () {
    testWidgets('开始 opens the shared training slide route', (tester) async {
      await pumpApp(tester);
      await tester.tap(find.byKey(const ValueKey('start-today')));
      await pumpTrainerReady(tester);
      final route = ModalRoute.of(
        tester.element(find.byType(trainer.TrainerPlayer)),
      );
      expect(route, isA<trainer.TrainerSlideRoute>());
      expect(route!.transitionDuration, const Duration(milliseconds: 300));
      expect(find.byKey(const ValueKey('training-slide')), findsOneWidget);
      expect(find.byType(trainer.TrainerCountdownDigits), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('pause')));
      await expectPausedClock(tester);
    });

    testWidgets('更多 slides in from the right and back out', (tester) async {
      await pumpApp(tester);
      double left() =>
          tester.getRect(find.byKey(const ValueKey('more-list'))).left;
      await tester.tap(find.byKey(const ValueKey('home-more')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 40));
      expect(left(), greaterThan(0)); // from the right
      await tester.pumpAndSettle();
      expect(left(), closeTo(0, 1));
      await tester.tap(find.byKey(const ValueKey('more-back')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      expect(left(), greaterThan(0)); // back out to the right
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('more-list')), findsNothing);
    });

    testWidgets(
      'shared-bar pages keep only the back chip still and swipe back on iOS',
      (tester) async {
        await pumpApp(tester);
        await openSettings(tester);
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(find.text('重新看安全提示'), 200);
        await tester.drag(find.byType(ListView).first, const Offset(0, -300));
        await tester.pumpAndSettle();
        await tester.tap(find.text('重新看安全提示'));
        await tester.pump();
        await tester.pump(HipMotion.page ~/ 3);
        expect(find.byType(HipOnboarding), findsOneWidget);
        final route =
            ModalRoute.of(tester.element(find.byType(HipOnboarding)))!
                as HipRoute;
        expect(route.transition, HipTransition.content);
        // 设置页有返回键，目标页的胶囊钉住。
        expect(route.pinLeading, isTrue);
        // The bar's glass and title slide with the page; only the back chip
        // stays fixed.
        expect(
          find.ancestor(
            of: find.byType(HipNavBar),
            matching: find.byType(SlideTransition),
          ),
          findsWidgets,
        );
        expect(
          find.ancestor(
            of: find.byType(HipNavBackChip),
            matching: find.byType(SlideTransition),
          ),
          findsNothing,
        );
        final bar = tester.getRect(
          find.descendant(
            of: find.byType(HipOnboarding),
            matching: find.byType(HipNavBar),
          ),
        );
        expect(bar.top, 0);
        final slide = tester.widget<SlideTransition>(
          find
              .descendant(
                of: find.byType(HipOnboarding),
                matching: find.byType(SlideTransition),
              )
              .first,
        );
        expect(slide.position.value.dx, greaterThan(0));
        await tester.pumpAndSettle();
        expect(find.byType(HipOnboarding), findsOneWidget);
        // Edge swipe back.
        final gesture = await tester.startGesture(const Offset(5, 400));
        await gesture.moveBy(const Offset(20, 0));
        await gesture.moveBy(const Offset(280, 0));
        await gesture.up();
        await tester.pumpAndSettle();
        expect(find.byType(HipOnboarding), findsNothing);
        expect(
          find.byKey(const ValueKey('appearance-settings')),
          findsOneWidget,
        );
      },
      variant: TargetPlatformVariant.only(TargetPlatform.iOS),
    );
  });

  testWidgets('a page from the bar-less home brings its chip in with it', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.tap(find.byKey(const ValueKey('home-more')));
    await tester.pump();
    await tester.pump(HipMotion.page ~/ 3);
    final route =
        ModalRoute.of(tester.element(find.byType(HipNavBar)))! as HipRoute;
    expect(route.transition, HipTransition.content);
    expect(route.pinLeading, isFalse);
    // The chip rides on the sliding bar instead of appearing pinned at
    // frame 0 over the home page, which has no back control.
    expect(
      find.ancestor(
        of: find.byType(HipNavBackChip),
        matching: find.byType(SlideTransition),
      ),
      findsWidgets,
    );
    expect(
      tester.getRect(find.byType(HipNavBackChip)).left,
      greaterThan(HipNavBar.chipEdge + 40),
    );
    await tester.pumpAndSettle();
    expect(
      tester.getRect(find.byType(HipNavBackChip)).left,
      HipNavBar.chipEdge,
    );
  });

  group('shared chip regression', () {
    Future<void> openMore(WidgetTester tester) async {
      await pumpApp(tester);
      await tester.tap(find.byKey(const ValueKey('home-more')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('more-back')), findsOneWidget);
    }

    Future<void> pushSettings(WidgetTester tester) async {
      await tester.tap(find.byKey(const ValueKey('more-settings')));
      await tester.pump();
    }

    void expectOnlySettingsChip(WidgetTester tester) {
      expect(find.byKey(const ValueKey('more-back')), findsNothing);
      expect(find.byType(HipNavBackChip), findsOneWidget);
      expect(
        tester.getRect(find.byType(HipNavBackChip)).left,
        closeTo(HipNavBar.chipEdge, .01),
      );
    }

    testWidgets('More hides its inline chip during Settings push', (
      tester,
    ) async {
      await openMore(tester);
      await pushSettings(tester);
      await tester.pump(const Duration(milliseconds: 20));
      expectOnlySettingsChip(tester);
      await tester.pumpAndSettle();
    });

    testWidgets('More restores its inline chip only after Settings pop', (
      tester,
    ) async {
      await openMore(tester);
      await pushSettings(tester);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(HipNavBackChip));
      await tester.pump();
      await tester.pump(
        HipMotion.pageReverse - const Duration(milliseconds: 20),
      );
      expectOnlySettingsChip(tester);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('more-back')), findsOneWidget);
      expect(find.byType(HipNavBackChip), findsOneWidget);
    });

    testWidgets(
      'cancelled Settings edge swipe keeps the covered More chip hidden',
      (tester) async {
        await openMore(tester);
        await pushSettings(tester);
        await tester.pumpAndSettle();
        final gesture = await tester.startGesture(const Offset(5, 400));
        await gesture.moveBy(const Offset(20, 0));
        await gesture.moveBy(const Offset(35, 0));
        await tester.pump();
        expectOnlySettingsChip(tester);
        await gesture.cancel();
        await tester.pumpAndSettle();
        expect(find.byType(HipSettingsPage), findsOneWidget);
        expectOnlySettingsChip(tester);
        await tester.tap(find.byType(HipNavBackChip));
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('more-back')), findsOneWidget);
      },
      variant: TargetPlatformVariant.only(TargetPlatform.iOS),
    );
  });

  group('one move per transition', () {
    testWidgets('开始 grows the player alone: no Hero flies alongside', (
      tester,
    ) async {
      await pumpApp(tester);
      expect(find.byType(Hero, skipOffstage: false), findsNothing);
      await tester.tap(find.byKey(const ValueKey('start-today')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));
      expect(find.byType(Hero, skipOffstage: false), findsNothing);
      await pumpTrainerReady(tester);
      expect(find.byType(trainer.TrainerCountdownDigits), findsOneWidget);
      expect(find.byType(Hero, skipOffstage: false), findsNothing);
      await tester.tap(find.byKey(const ValueKey('pause')));
      await expectPausedClock(tester);
    });

    testWidgets('the hip check grows from 开始自测 with no flying thumbnails', (
      tester,
    ) async {
      await pumpApp(tester);
      await openCheckupIntro(tester);
      await tester.tap(find.byKey(const ValueKey('assessment-start')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));
      expect(find.byType(Hero, skipOffstage: false), findsNothing);
      await tester.pumpAndSettle();
      // Back out cleanly into the list.
      expect(find.byType(HipNavBackChip), findsOneWidget);
      await tester.tap(find.byType(HipNavBackChip));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('intro-item-butterfly')),
        findsOneWidget,
      );
    });
  });
}
