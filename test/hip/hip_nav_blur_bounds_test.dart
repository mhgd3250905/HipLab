import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiplab/hip/ui/hip_page_kit.dart';
import 'package:hiplab/hip/ui/hip_routes.dart';
import 'package:hiplab/hip/ui/hip_theme.dart';

void main() {
  const topInset = 47.0;
  const phoneSize = Size(394, 853);
  const clipKey = ValueKey('hip-nav-frost-clip');

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

  void expectLocalFrost(
    WidgetTester tester,
    Finder clip, {
    required double band,
    bool highContrast = false,
  }) {
    expect(clip, findsOneWidget);
    expect(tester.widget<ClipRect>(clip).clipBehavior, isNot(Clip.none));
    expect(tester.getSize(clip), Size(phoneSize.width, band));
    final render = tester.renderObject<RenderClipRect>(clip);
    // Verify that this is an actual paint clip, rather than only a SizedBox or
    // a Stack whose clip is conditional on child layout overflow.
    expect(
      render.describeApproximatePaintClip(render.child!),
      Offset.zero & Size(phoneSize.width, band),
    );
    final filters = find.descendant(
      of: clip,
      matching: find.byType(BackdropFilter),
    );
    expect(filters, highContrast ? findsNothing : findsNWidgets(3));
    // The chip's separately bounded 12-sigma ClipOval is deliberately excluded.
    for (final element in filters.evaluate()) {
      final filter = find.byElementPredicate(
        (item) => identical(item, element),
      );
      expect(
        find.ancestor(of: filter, matching: clip),
        findsOneWidget,
        reason: 'Every large bar blur must be beneath the explicit band clip',
      );
    }
  }

  for (final palette in [HipPalette.light, HipPalette.dark]) {
    final theme = palette.isDark ? 'dark' : 'light';
    for (final subtitle in [null, '提醒与声音']) {
      testWidgets('bar blur stays inside its local band ($theme, $subtitle)', (
        tester,
      ) async {
        await pumpShell(
          tester,
          palette: palette,
          home: HipNavPage(
            title: '设置',
            subtitle: subtitle,
            bodyScrollsUnderBar: true,
            body: ListView(
              children: const [SizedBox(height: 120), Text('设置内容')],
            ),
          ),
        );
        expectLocalFrost(
          tester,
          find.byKey(clipKey),
          band:
              topInset +
              (subtitle == null
                  ? HipNavBar.height
                  : HipNavBar.heightWithSubtitle) +
              kHipNavFade,
        );
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('high contrast avoids bar sampling ($theme)', (tester) async {
      await pumpShell(
        tester,
        palette: palette,
        highContrast: true,
        home: const HipNavPage(
          title: '设置',
          bodyScrollsUnderBar: true,
          body: Text('高对比度内容'),
        ),
      );
      expectLocalFrost(
        tester,
        find.byKey(clipKey),
        band: topInset + HipNavBar.height + kHipNavFade,
        highContrast: true,
      );
      expect(find.byType(BackdropFilter), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('both pages retain local blur clips throughout nested pushes', (
    tester,
  ) async {
    void push(BuildContext context, String title, String? next) {
      Navigator.of(context).push(
        HipRoute.content<void>(
          (context) => HipNavPage(
            title: title,
            bodyScrollsUnderBar: true,
            body: ListView(
              padding: EdgeInsets.only(top: hipNavInset(context) + 12),
              children: [
                if (next != null)
                  TextButton(
                    key: ValueKey('push-$next'),
                    onPressed: () => push(context, next, null),
                    child: Text(next),
                  )
                else
                  const Text('隐私政策正文'),
              ],
            ),
          ),
        ),
      );
    }

    await pumpShell(
      tester,
      palette: HipPalette.light,
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            key: const ValueKey('push-more'),
            onPressed: () => Navigator.of(context).push(
              HipRoute.content<void>(
                (context) => HipNavPage(
                  title: '更多',
                  bodyScrollsUnderBar: true,
                  body: ListView(
                    padding: EdgeInsets.only(top: hipNavInset(context) + 12),
                    children: [
                      TextButton(
                        key: const ValueKey('push-settings'),
                        onPressed: () => push(context, '设置', '隐私政策'),
                        child: const Text('设置'),
                      ),
                    ],
                  ),
                ),
                pinLeading: false,
              ),
            ),
            child: const Text('更多'),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('push-more')));
    await tester.pumpAndSettle();

    for (final target in ['settings', '隐私政策']) {
      await tester.tap(find.byKey(ValueKey('push-$target')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));
      final clips = find.byKey(clipKey);
      expect(clips, findsNWidgets(2));
      for (var i = 0; i < 2; i++) {
        expectLocalFrost(
          tester,
          clips.at(i),
          band: topInset + HipNavBar.height + kHipNavFade,
        );
      }
      expect(
        find.descendant(of: clips, matching: find.byType(BackdropFilter)),
        findsNWidgets(6),
      );
      expect(tester.takeException(), isNull);
      await tester.pumpAndSettle();
    }
  });
}
