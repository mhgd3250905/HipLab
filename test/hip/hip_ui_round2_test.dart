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
import 'package:hiplab/hip/ui/hip_icons.dart';
import 'package:hiplab/hip/ui/hip_routes.dart';
import 'package:hiplab/hip/ui/hip_segmented.dart';
import 'package:hiplab/hip/ui/hip_theme.dart';
import 'package:hiplab/hip/ui/hip_widgets.dart';

import 'package:ugk_trainer/ugk_trainer.dart' as trainer;

import 'hip_domain_test.dart' show MemoryStorage, loadContent;
import 'checkup_entry.dart';

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
    await tester.pumpWidget(HipApp(store: store, videoEnabled: false));
    await tester.pumpAndSettle();
    return store;
  }

  group('segmented control', () {
    for (final theme in [HipThemeChoice.dark, HipThemeChoice.light]) {
      testWidgets('home pickers slide one concentric thumb (${theme.id})', (
        tester,
      ) async {
        final store = await pumpApp(tester, theme: theme);
        final picker = find.byWidgetPredicate(
          (w) => w is HipSegmented<int> && w.keyPrefix == 'minutes',
        );
        expect(picker, findsOneWidget);
        final seg = tester.widget<HipSegmented<int>>(picker);
        // Concentric corners: inner radius = outer radius − inset.
        expect(seg.thumbRadius, seg.radius - seg.inset);
        final thumb = find.byKey(const ValueKey('minutes-thumb'));
        expect(thumb, findsOneWidget);
        // The selection is the shared neutral tactile tile (no accent
        // outline), its corners concentric with the track.
        final face = tester.widget<HipTactile>(
          find.descendant(of: thumb, matching: find.byType(HipTactile)),
        );
        expect(face.style, HipTactileStyle.neutral());
        expect(face.radius, seg.thumbRadius);

        final x0 = tester.getRect(thumb).left;
        final target = tester.getRect(find.byKey(const ValueKey('minutes-15')));
        await tester.tap(find.byKey(const ValueKey('minutes-15')));
        await tester.pump();
        await tester.pump(HipMotion.segment ~/ 3);
        final mid = tester.getRect(thumb).left;
        // Mid-flight: the thumb is travelling, not jumping.
        expect(mid, greaterThan(x0 + 1));
        expect(mid, lessThan(target.left - 1));
        await tester.pumpAndSettle();
        expect(store.minutes, 15);
        expect(tester.getRect(thumb).center.dx, closeTo(target.center.dx, 1));

        // The scene picker is the same control.
        await tester.tap(find.byKey(ValueKey('scene-${HipScene.home}')));
        await tester.pumpAndSettle();
        expect(store.scene, HipScene.home);
        final scene = tester.widget<HipSegmented<HipScene>>(
          find.byWidgetPredicate((w) => w is HipSegmented<HipScene>),
        );
        expect(scene.radius, seg.radius);
        expect(scene.inset, seg.inset);
        expect(scene.height, seg.height);
      });
    }

    testWidgets('dragging along the track selects', (tester) async {
      final store = await pumpApp(tester);
      final from = tester.getCenter(find.byKey(const ValueKey('minutes-5')));
      final to = tester.getCenter(find.byKey(const ValueKey('minutes-15')));
      await tester.dragFrom(from, to - from);
      await tester.pumpAndSettle();
      expect(store.minutes, 15);
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
      for (final tab in [1, 2]) {
        await tester.tap(find.byKey(ValueKey('tab-$tab')));
        await tester.pumpAndSettle();
        expect(find.byType(Icon), findsNothing, reason: 'tab $tab');
      }
      await tester.tap(find.byKey(const ValueKey('tab-0')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('start-today')));
      await tester.pumpAndSettle();
      expect(find.byType(trainer.TrainerCountdownRing), findsOneWidget);
      // The training package owns the playback controls and its icon set.
      expect(find.byType(trainer.TrainerPlayer), findsOneWidget);
      expect(find.byKey(const ValueKey('pause')), findsOneWidget);
      expect(find.byKey(const ValueKey('skip')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('pause')));
      await tester.pumpAndSettle();
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
    final panel = tester.widget<HipPanel>(row);
    final thumb = tester.widget<HipThumb>(
      find.descendant(of: row, matching: find.byType(HipThumb)),
    );
    expect(thumb.radius, panel.radius - panel.padding.left);
  });

  group('page transitions', () {
    HipRoute<dynamic> topRoute(WidgetTester tester) {
      HipRoute<dynamic>? top;
      Navigator.of(tester.element(find.byType(Scaffold).last)).popUntil((r) {
        top ??= r is HipRoute ? r : null;
        return true;
      });
      return top!;
    }

    testWidgets('开始 grows the player out of the button; home sinks back', (
      tester,
    ) async {
      await pumpApp(tester);
      final button = tester.getRect(find.byKey(const ValueKey('start-today')));
      await tester.tap(find.byKey(const ValueKey('start-today')));
      await tester.pump();
      await tester.pump(HipMotion.expand ~/ 4);
      final route = topRoute(tester);
      expect(route.transition, HipTransition.expand);
      expect(route.origin!.center.dx, closeTo(button.center.dx, 2));
      expect(route.transitionDuration, HipMotion.expand);
      // The covered home answers (a dim), not a plain fade.
      expect(find.byType(HipCoveredTransition), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.byType(trainer.TrainerCountdownRing), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('pause')));
      await tester.pumpAndSettle();
    });

    testWidgets('tabs slide toward the tapped side', (tester) async {
      await pumpApp(tester);
      double incomingDx() {
        final slide = tester.widget<SlideTransition>(
          find
              .ancestor(
                of: find.byKey(const ValueKey('tab-body-2')),
                matching: find.byType(SlideTransition),
              )
              .first,
        );
        return slide.position.value.dx;
      }

      await tester.tap(find.byKey(const ValueKey('tab-2')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 40));
      expect(incomingDx(), greaterThan(0)); // from the right
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('tab-0')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 40));
      final incoming = tester.widget<SlideTransition>(
        find
            .ancestor(
              of: find.byKey(const ValueKey('tab-body-0')),
              matching: find.byType(SlideTransition),
            )
            .first,
      );
      expect(incoming.position.value.dx, lessThan(0)); // from the left
      await tester.pumpAndSettle();
    });

    testWidgets(
      'drill-down pages push from the right and swipe back on iOS',
      (tester) async {
        await pumpApp(tester);
        await tester.tap(find.byKey(const ValueKey('tab-2')));
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
        expect(route.transition, HipTransition.push);
        // Mid-flight the new page is still partly off to the right.
        final slide = tester.widget<SlideTransition>(
          find
              .ancestor(
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
      await tester.pumpAndSettle();
      expect(find.byType(trainer.TrainerCountdownRing), findsOneWidget);
      expect(find.byType(Hero, skipOffstage: false), findsNothing);
      await tester.tap(find.byKey(const ValueKey('pause')));
      await tester.pumpAndSettle();
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
      await tester.tap(find.byType(HipCircleButton).first);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('intro-item-butterfly')),
        findsOneWidget,
      );
    });
  });
}
