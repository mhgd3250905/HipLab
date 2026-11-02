// Tactile material (button audit 2026-10-18, curated 2026-10-19): tokens,
// which buttons are (not) tactile, press feedback, reduce motion and the 开始
// shared training entry.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ugk_trainer_runtime/ugk_trainer_runtime.dart' as trainer;
import 'package:hiplab/hip/control/hip_store.dart';
import 'package:hiplab/hip/domain/hip_models.dart';
import 'package:hiplab/hip/ui/hip_app.dart';
import 'package:hiplab/hip/ui/hip_icons.dart';
import 'package:hiplab/hip/ui/hip_player_page.dart';
import 'package:hiplab/hip/ui/hip_theme.dart';
import 'package:hiplab/hip/ui/hip_widgets.dart';

import 'hip_domain_test.dart' show MemoryStorage, loadContent;
import 'public_media_fixture.dart';

bool _isGlow(Color c) {
  // A shadow is "coloured" when its hue channel stands out: green clearly
  // above red and blue (the old jade glow), rather than near-black.
  final r = c.r, g = c.g, b = c.b;
  return g - r > .25 && g - b > .1;
}

void main() {
  setUpAll(warmHipAppAssets);
  group('tokens', () {
    test('neutral dark is the settings thumb it was distilled from', () {
      final s = HipTactileStyle.neutral(HipPalette.dark);
      expect(s.base, HipPalette.dark.thumb);
      // The thumb's 8 % top light (thumbHighlight 0x14 over the fill).
      expect(s.lighten, closeTo(HipPalette.dark.thumbHighlight.a, .01));
      expect(s.highlight.a, greaterThan(0));
      expect(s.shadows, hasLength(2));
    });

    for (final p in [HipPalette.dark, HipPalette.light]) {
      final t = p.isDark ? 'dark' : 'light';
      test('accent ($t): brand fill, lit top, darker bottom, no glow', () {
        final s = HipTactileStyle.accent(p);
        expect(s.base, p.jade);
        expect(
          s.top.computeLuminance(),
          greaterThan(s.base.computeLuminance()),
        );
        expect(
          s.bottom.computeLuminance(),
          lessThan(s.base.computeLuminance()),
        );
        expect(s.highlight.a, greaterThan(.2));
        for (final sh in s.shadows) {
          expect(_isGlow(sh.color), isFalse, reason: 'no coloured glow');
          // Tight: nothing like the old 24–31 px soft halos.
          expect(sh.blur, lessThanOrEqualTo(8));
          expect(sh.dy, lessThanOrEqualTo(4));
        }
      });

      test('pressed ($t): light drops, shadow tucks in', () {
        for (final s in [
          HipTactileStyle.accent(p),
          HipTactileStyle.neutral(p),
        ]) {
          final d = s.pressed();
          expect(d.lighten, lessThan(s.lighten + 1e-9));
          expect(d.highlight.a, lessThan(s.highlight.a + 1e-9));
          expect(d.shadows.first.dy, lessThan(s.shadows.first.dy));
          expect(d.shadows.first.blur, lessThan(s.shadows.first.blur));
          expect(d.shadows.last.color.a, 0);
        }
      });
    }

    test('lerp hits both ends', () {
      final a = HipTactileStyle.accent(HipPalette.dark);
      expect(HipTactileStyle.lerp(a, a.pressed(), 0), a);
      expect(HipTactileStyle.lerp(a, a.pressed(), 1), a.pressed());
    });
  });

  group('only the curated elements are tactile (rationale 2026-10-19)', () {
    Future<void> show(WidgetTester tester, Widget child) => tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: Center(child: child)),
      ),
    );

    for (final p in [HipPalette.dark, HipPalette.light]) {
      final t = p.isDark ? 'dark' : 'light';
      testWidgets('primary ($t): flat filled jade, no shadow or glow (R3)', (
        tester,
      ) async {
        HipColors.palette = p;
        addTearDown(() => HipColors.palette = HipPalette.dark);
        await show(tester, HipPrimaryButton(label: '开始自测', onPressed: () {}));
        expect(find.byType(HipTactile), findsNothing);
        final faces = tester
            .widgetList<DecoratedBox>(
              find.descendant(
                of: find.byType(HipPrimaryButton),
                matching: find.byType(DecoratedBox),
              ),
            )
            .map((d) => d.decoration)
            .toList();
        expect(faces, hasLength(1));
        final face = faces.single as ShapeDecoration;
        expect(face.color, p.jade);
        expect(face.gradient, isNull);
        expect(face.shadows, anyOf(isNull, isEmpty));
        // No ink splash: nothing repaints mid-tap (container transform).
        expect(
          find.descendant(
            of: find.byType(HipPrimaryButton),
            matching: find.byType(InkWell),
          ),
          findsNothing,
        );
      });

      testWidgets('secondary and circle ($t): flat, no tactile (R4, R5)', (
        tester,
      ) async {
        HipColors.palette = p;
        addTearDown(() => HipColors.palette = HipPalette.dark);
        await show(
          tester,
          SizedBox(
            width: 200,
            child: HipSecondaryButton(label: '有', onPressed: () {}),
          ),
        );
        expect(find.byType(HipTactile), findsNothing);
        final edge =
            tester
                    .widget<DecoratedBox>(
                      find.descendant(
                        of: find.byType(HipSecondaryButton),
                        matching: find.byType(DecoratedBox),
                      ),
                    )
                    .decoration
                as ShapeDecoration;
        expect(edge.color, p.surface);
        expect((edge.shape as StadiumBorder).side.color, p.line);
        expect(edge.shadows, anyOf(isNull, isEmpty));

        await show(
          tester,
          HipCircleButton(icon: HipGlyph.close, onPressed: () {}),
        );
        expect(find.byType(HipTactile), findsNothing);
        final disc = tester.widget<Container>(
          find.descendant(
            of: find.byType(HipCircleButton),
            matching: find.byType(Container),
          ),
        );
        final d = disc.decoration! as BoxDecoration;
        expect(d.color, p.surfaceHigh);
        expect(d.boxShadow, isNull, reason: 'tonal only, no soft shadow');
        if (p.isDark) {
          expect(d.border, isNull);
        } else {
          expect((d.border! as Border).top.color, p.line, reason: 'hairline');
        }
      });
    }

    testWidgets('开始 has no halo or radial glow', (tester) async {
      await show(tester, HipStartButton(onTap: () {}, stage: HipPalette.dark));
      final radial = find.byWidgetPredicate(
        (w) =>
            w is DecoratedBox &&
            w.decoration is BoxDecoration &&
            (w.decoration as BoxDecoration).gradient is RadialGradient,
      );
      expect(radial, findsNothing);
      final face = tester.widget<HipTactile>(find.byType(HipTactile));
      expect(face.circle, isTrue);
      expect(face.style, HipTactileStyle.accent(HipPalette.dark));
      // Nothing is painted far outside the button any more.
      expect(tester.getSize(find.byType(HipStartButton)), const Size(104, 104));
    });
  });

  group('press', () {
    Future<void> show(WidgetTester tester, {bool reduce = false}) =>
        tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(disableAnimations: reduce),
              child: Scaffold(
                body: Center(
                  child: HipStartButton(
                    buttonKey: const ValueKey('b'),
                    stage: HipPalette.dark,
                    onTap: () {},
                  ),
                ),
              ),
            ),
          ),
        );

    double scale(WidgetTester tester) => tester
        .widget<AnimatedScale>(
          find.descendant(
            of: find.byKey(const ValueKey('b')),
            matching: find.byType(AnimatedScale),
          ),
        )
        .scale;

    HipTactilePainter painter(WidgetTester tester) =>
        tester
                .widget<CustomPaint>(
                  find.descendant(
                    of: find.byType(HipTactile),
                    matching: find.byWidgetPredicate(
                      (w) => w is CustomPaint && w.painter is HipTactilePainter,
                    ),
                  ),
                )
                .painter!
            as HipTactilePainter;

    testWidgets('开始 sinks to 0.97 in ~100 ms and comes back', (tester) async {
      HipColors.palette = HipPalette.dark;
      await show(tester);
      final idle = painter(tester).style;
      final g = await tester.startGesture(
        tester.getCenter(find.byKey(const ValueKey('b'))),
      );
      await tester.pump();
      expect(scale(tester), HipMotion.pressScale);
      expect(HipMotion.pressScale, .97);
      expect(HipMotion.press, const Duration(milliseconds: 100));
      await tester.pump(HipMotion.press);
      final down = painter(tester).style;
      expect(down, idle.pressed());
      expect(down.highlight.a, lessThan(idle.highlight.a));
      await g.up();
      await tester.pumpAndSettle();
      expect(scale(tester), 1);
      expect(painter(tester).style, idle);
    });

    testWidgets('reduce motion: no scale, the disc still sinks', (
      tester,
    ) async {
      HipColors.palette = HipPalette.dark;
      await show(tester, reduce: true);
      final idle = painter(tester).style;
      final g = await tester.startGesture(
        tester.getCenter(find.byKey(const ValueKey('b'))),
      );
      await tester.pump();
      expect(scale(tester), 1);
      await tester.pump(HipMotion.press);
      expect(painter(tester).style, idle.pressed());
      await g.up();
      await tester.pumpAndSettle();
    });
  });

  testWidgets('开始 delegates the complete training page to the shared route', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final store = HipStore(
      content: loadContent(),
      storage: MemoryStorage(),
      clock: () => DateTime(2026, 10, 16, 9, 41),
    );
    await store.initialize();
    store
      ..safety = {'pregnancy': false, 'surgery': false, 'acute': false}
      ..identity = HipIdentity.dancer
      ..minutes = 10
      ..scene = HipScene.home;
    await tester.pumpWidget(
      HipApp(
        mediaPolicy: installPublicMediaFixture().policy,
        store: store,
        videoEnabled: false,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('start-today')));
    await tester.pumpAndSettle();
    final route = ModalRoute.of(
      tester.element(find.byType(HipPlayerPage, skipOffstage: false)),
    );
    expect(route, isA<trainer.TrainerSlideRoute>());
    expect(find.byType(trainer.TrainerPlayer), findsOneWidget);
    expect(find.byKey(const ValueKey('training-slide')), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
