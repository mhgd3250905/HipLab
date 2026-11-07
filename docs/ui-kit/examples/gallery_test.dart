// Learning examples are verified explicitly; the App's test/ suite is unchanged.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiplab/hip/ui/hip_page_kit.dart';
import 'package:hiplab/hip/ui/hip_theme.dart';

import 'controls_example.dart';
import 'gallery.dart';
import 'media_handoff_example.dart';
import 'navigation_example.dart';

void main() {
  setUpAll(() async {
    final font = FontLoader(hipFontFamily)
      ..addFont(rootBundle.load('assets/fonts/NotoSansSC.ttf'));
    await font.load();
  });

  Future<void> mount(
    WidgetTester tester,
    Brightness brightness,
    String language,
  ) async {
    final previous = HipColors.palette;
    tester.view
      ..physicalSize = const Size(394, 853)
      ..devicePixelRatio = 1
      ..padding = const FakeViewPadding(top: 47, bottom: 34);
    addTearDown(() {
      tester.view.reset();
      HipColors.palette = previous;
    });
    await tester.pumpWidget(
      UiKitGalleryApp(brightness: brightness, locale: Locale(language)),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }

  for (final brightness in Brightness.values) {
    for (final language in ['zh', 'en']) {
      testWidgets('gallery routes and settings: $brightness / $language', (
        tester,
      ) async {
        await mount(tester, brightness, language);
        await tester.tap(find.byKey(const ValueKey('recipe-controls')));
        await tester.pumpAndSettle();
        expect(find.byType(ControlsRecipePage), findsOneWidget);
        final toggle = find.byKey(const ValueKey('recipe-switch'));
        await tester.ensureVisible(toggle);
        final before = tester.widget<HipSwitch>(toggle).value;
        await tester.tap(toggle);
        await tester.pumpAndSettle();
        expect(tester.widget<HipSwitch>(toggle).value, !before);
        final confirm = find.byKey(const ValueKey('recipe-confirm'));
        await tester.ensureVisible(confirm);
        await tester.tap(confirm);
        await tester.pumpAndSettle();
        await tester.tap(find.text(language == 'en' ? 'Cancel' : '取消'));
        await tester.pumpAndSettle();
        expect(
          tester.widget<Text>(find.byKey(const ValueKey('recipe-result'))).data,
          language == 'en' ? 'Cancelled' : '已取消',
        );
        await tester.tap(confirm);
        await tester.pumpAndSettle();
        await tester.tap(find.text(language == 'en' ? 'Confirm' : '确认'));
        await tester.pumpAndSettle();
        expect(
          tester.widget<Text>(find.byKey(const ValueKey('recipe-result'))).data,
          language == 'en' ? 'Confirmed' : '已确认',
        );
        expect(tester.takeException(), isNull);

        Navigator.of(tester.element(find.byType(ControlsRecipePage))).pop();
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('recipe-nav')));
        await tester.pumpAndSettle();
        expect(find.byType(NavigationRecipeHome), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('recipe-nav-open-more')));
        await tester.pumpAndSettle();
        final chip = find.byType(HipNavBackChip);
        expect(chip, findsOneWidget);
        final anchor = tester.getRect(chip);
        expect(anchor, const Rect.fromLTWH(16, 47, 44, 44));
        await tester.tap(find.byKey(const ValueKey('recipe-nav-open-caption')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 120));
        expect(chip, findsOneWidget);
        expect(tester.getRect(chip), anchor);
        await tester.pumpAndSettle();
        expect(tester.getRect(chip), anchor);
        await tester.tap(find.byKey(const ValueKey('recipe-nav-open-detail')));
        await tester.pumpAndSettle();
        expect(chip, findsOneWidget);
        expect(tester.getRect(chip), anchor);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('media subtree survives expand and collapse: $brightness', (
      tester,
    ) async {
      await mount(tester, brightness, 'en');
      await tester.tap(find.byKey(const ValueKey('recipe-media')));
      await tester.pumpAndSettle();
      expect(find.byType(MediaHandoffRecipePage), findsOneWidget);
      final surface = find.byKey(const ValueKey('recipe-media-surface'));
      final original = tester.element(surface);
      await tester.tap(find.byKey(const ValueKey('recipe-media-open')));
      await tester.pump(const Duration(milliseconds: 120));
      expect(identical(tester.element(surface), original), isTrue);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('recipe-media-close')));
      await tester.pump(const Duration(milliseconds: 120));
      expect(identical(tester.element(surface), original), isTrue);
      await tester.pumpAndSettle();
      expect(identical(tester.element(surface), original), isTrue);
      expect(tester.takeException(), isNull);
    });
  }
}
