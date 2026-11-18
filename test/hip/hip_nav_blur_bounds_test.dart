import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiplab/hip/ui/hip_page_kit.dart';
import 'package:hiplab/hip/ui/hip_routes.dart';
import 'package:hiplab/hip/ui/hip_theme.dart';

void main() {
  const topInset = 47.0;
  const phoneSize = Size(394, 853);
  const maskKey = ValueKey('hip-nav-mask');
  const firstRowKey = ValueKey('first-row');

  setUp(() {
    final previous = HipColors.palette;
    addTearDown(() => HipColors.palette = previous);
  });

  Future<void> pumpShell(
    WidgetTester tester, {
    required HipPalette palette,
    required Widget home,
    bool highContrast = false,
  }) async {
    HipColors.palette = palette;
    tester.view
      ..physicalSize = phoneSize
      ..devicePixelRatio = 1
      ..padding = const FakeViewPadding(top: topInset, bottom: 34);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: hipTheme(palette),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(highContrast: highContrast),
          child: child!,
        ),
        home: home,
      ),
    );
    await tester.pumpAndSettle();
  }

  void expectMask(WidgetTester tester, Finder mask, double band) {
    expect(mask, findsOneWidget);
    expect(tester.getSize(mask), Size(phoneSize.width, band));
    final decoration =
        tester.widget<DecoratedBox>(mask).decoration as BoxDecoration;
    expect(decoration.color, isNull);
    expect(decoration.border, isNull);
    expect(decoration.boxShadow, isNull);
    final gradient = decoration.gradient as LinearGradient;
    expect(gradient.begin, Alignment.topCenter);
    expect(gradient.end, Alignment.bottomCenter);
    expect(gradient.colors.first, HipColors.background);
    expect(gradient.colors.last.a, 0);
    expect(gradient.colors.length, 13);
    for (var i = 1; i < gradient.colors.length; i++) {
      expect(gradient.colors[i].a, lessThan(gradient.colors[i - 1].a));
    }
    expect(gradient.colors[7].a, closeTo(.86, .01));
    expect(
      find.descendant(of: mask, matching: find.byType(BackdropFilter)),
      findsNothing,
    );
  }

  for (final palette in [HipPalette.light, HipPalette.dark]) {
    final theme = palette.isDark ? 'dark' : 'light';
    for (final subtitle in [null, '提醒与声音']) {
      for (final scrollUnder in [false, true]) {
        testWidgets('mask stays over the full bar ($theme, $subtitle, '
            'scroll under $scrollUnder)', (tester) async {
          final band = topInset + (subtitle == null ? 44 : 52) + 24;
          await pumpShell(
            tester,
            palette: palette,
            home: Builder(
              builder: (context) => HipNavPage(
                title: '设置',
                subtitle: subtitle,
                bodyScrollsUnderBar: scrollUnder,
                body: ListView(
                  padding: EdgeInsets.only(
                    top: scrollUnder
                        ? hipNavInset(context, hasSubtitle: subtitle != null)
                        : 0,
                  ),
                  children: const [
                    SizedBox(height: 65, key: firstRowKey),
                    SizedBox(height: 1500),
                  ],
                ),
              ),
            ),
          );

          final mask = find.byKey(maskKey);
          final row = find.byKey(firstRowKey);
          expectMask(tester, mask, band);
          expect(tester.getTopLeft(mask), Offset.zero);
          expect(tester.getTopLeft(row).dy, band);
          final title = tester.widget<Text>(find.text('设置'));
          expect(title.style?.fontSize, 17);
          expect(title.style?.fontWeight, FontWeight.w600);

          final chip = find.byType(HipNavBackChip);
          final filters = find.byType(BackdropFilter);
          expect(filters, findsOneWidget);
          final capsule = find.descendant(
            of: chip,
            matching: find.byType(ClipOval),
          );
          expect(tester.getSize(capsule), const Size.square(44));
          expect(find.ancestor(of: filters, matching: capsule), findsOneWidget);
          expect(tester.getTopLeft(chip), const Offset(16, topInset));

          // The mask itself must pass a drag to the full-height viewport.
          final drag = await tester.startGesture(
            Offset(200, scrollUnder ? band - 10 : band + 30),
          );
          await drag.moveBy(const Offset(0, -40));
          await tester.pump();
          await drag.moveBy(const Offset(0, -10));
          await tester.pump();
          final position = tester
              .state<ScrollableState>(find.byType(Scrollable))
              .position;
          expect(position.pixels, greaterThan(0));
          expect(tester.getTopLeft(mask), Offset.zero);
          expectMask(tester, mask, band);
          await drag.up();
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        });
      }
    }

    testWidgets('high contrast removes capsule sampling ($theme)', (
      tester,
    ) async {
      await pumpShell(
        tester,
        palette: palette,
        highContrast: true,
        home: const HipNavPage(title: '设置', body: Text('高对比度内容')),
      );
      expectMask(tester, find.byKey(maskKey), topInset + 44 + 24);
      expect(find.byType(BackdropFilter), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'nested page masks move with their surfaces while the chip pins',
    (tester) async {
      const settingsKey = ValueKey('settings');
      const nextKey = ValueKey('next');
      Widget settings(BuildContext context) => HipNavPage(
        title: '设置',
        body: Center(
          child: TextButton(
            key: nextKey,
            onPressed: () => Navigator.of(context).push(
              HipRoute.content<void>(
                (_) => const HipNavPage(
                  title: '隐私政策',
                  subtitle: '条款',
                  body: Text('隐私政策正文'),
                ),
              ),
            ),
            child: const Text('打开隐私政策'),
          ),
        ),
      );
      await pumpShell(
        tester,
        palette: HipPalette.light,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                key: settingsKey,
                onPressed: () => Navigator.of(
                  context,
                ).push(HipRoute.content<void>(settings, pinLeading: false)),
                child: const Text('打开设置'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(settingsKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(nextKey));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));

      final masks = find.byKey(maskKey);
      expect(masks, findsNWidgets(2));
      expectMask(tester, masks.at(0), topInset + 44 + 24);
      expectMask(tester, masks.at(1), topInset + 52 + 24);
      expect(tester.getTopLeft(masks.at(0)).dx, lessThan(0));
      expect(tester.getTopLeft(masks.at(1)).dx, greaterThan(0));
      final chip = find.byType(HipNavBackChip);
      expect(chip, findsOneWidget);
      expect(tester.getTopLeft(chip), const Offset(16, topInset));
      expect(tester.takeException(), isNull);

      await tester.pumpAndSettle();
      await tester.tap(chip);
      await tester.pumpAndSettle();
      expect(find.text('隐私政策'), findsNothing);
      expect(find.text('设置'), findsOneWidget);
    },
  );
}
