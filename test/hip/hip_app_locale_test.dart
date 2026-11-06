import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiplab/hip/control/hip_store.dart';
import 'package:hiplab/hip/domain/hip_models.dart';
import 'package:hiplab/hip/domain/hip_settings.dart';
import 'package:hiplab/hip/ui/hip_app.dart';
import 'package:hiplab/hip/ui/hip_theme.dart';
import 'package:hiplab/hip/voice/voice_library.dart';

import 'hip_domain_test.dart' show MemoryStorage, loadContent;
import 'home_nav.dart';
import 'public_media_fixture.dart';

void main() {
  final content = loadContent();
  const captureKey = ValueKey('english-app-capture');
  final artifactDirectory = Platform.environment['HIPLAB_ENGLISH_ARTIFACT_DIR'];

  setUpAll(() async {
    // English line wrapping must use the bundled App font, not the square
    // glyphs of Flutter's Ahem test font, even when no screenshots are saved.
    final font = FontLoader(hipFontFamily)
      ..addFont(rootBundle.load('assets/fonts/NotoSansSC.ttf'));
    await font.load();
  });

  Future<HipStore> mount(
    WidgetTester tester, {
    HipLanguage language = HipLanguage.en,
    HipThemeChoice theme = HipThemeChoice.dark,
    bool onboarded = true,
  }) async {
    tester.view
      ..physicalSize = const Size(394, 853)
      ..devicePixelRatio = 1
      ..padding = const FakeViewPadding(top: 47, bottom: 34);
    addTearDown(tester.view.reset);
    final oldPalette = HipColors.palette;
    addTearDown(() => HipColors.palette = oldPalette);
    final policy = installPublicMediaFixture(sharedLibrary: true).policy;
    final store = HipStore(
      content: content,
      storage: MemoryStorage(),
      clock: () => DateTime(2026, 11, 7, 9, 30),
    );
    await store.initialize();
    store
      ..language = language
      ..theme = theme;
    if (onboarded) {
      store
        ..safety = {'pregnancy': false, 'surgery': false, 'acute': false}
        ..identity = HipIdentity.office
        ..scene = HipScene.chair;
    }
    await tester.pumpWidget(
      RepaintBoundary(
        key: captureKey,
        child: HipApp(store: store, videoEnabled: false, mediaPolicy: policy),
      ),
    );
    await tester.pumpAndSettle();
    return store;
  }

  Future<void> capture(WidgetTester tester, String name) async {
    expect(tester.takeException(), isNull, reason: name);
    if (artifactDirectory == null) return;
    // Asset decoding runs outside the test clock. Give it a real event-loop
    // turn before capturing, then paint the resolved image frame.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 80)),
    );
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(captureKey),
      );
      final image = await boundary.toImage(pixelRatio: 2);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      final folder = Directory(artifactDirectory)..createSync(recursive: true);
      File(
        '${folder.path}/$name.png',
      ).writeAsBytesSync(data!.buffer.asUint8List());
      image.dispose();
    });
  }

  test(
    'interface language persists independently of voice and old data',
    () async {
      final storage = MemoryStorage();
      storage.values[HipStore.storageKey] = jsonEncode({
        'v': 1,
        'voice': {
          'language': 'en',
          'voice': true,
          'chimes': true,
          'volume': .6,
        },
      });
      final store = HipStore(content: content, storage: storage);
      await store.initialize();
      expect(store.language, HipLanguage.zh);
      expect(store.voice.language, VoiceLanguage.en);
      await store.setLanguage(HipLanguage.en);
      final restored = HipStore(content: content, storage: storage);
      await restored.initialize();
      expect(restored.language, HipLanguage.en);
      expect(restored.voice.language, VoiceLanguage.en);
      expect(restored.voice.volume, .6);
      expect(store.nextCustomName(language: 'en'), 'My group 1');
      expect(store.nextCustomName(), '我的训练组 1');
    },
  );

  testWidgets('settings changes the live interface without closing its route', (
    tester,
  ) async {
    final store = await mount(tester, language: HipLanguage.zh);
    await openSettings(tester);
    final english = find.byKey(const ValueKey('app-language-HipLanguage.en'));
    await tester.ensureVisible(english);
    await tester.pumpAndSettle();
    await tester.tap(english);
    await tester.pumpAndSettle();
    expect(store.language, HipLanguage.en);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.byType(HipSettingsPage), findsOneWidget);
    expect(find.text('App language'), findsOneWidget);
    await backHome(tester);
    expect(find.text('Office Reset'), findsOneWidget);
    expect(find.text('Office'), findsOneWidget);
    await capture(tester, 'live-language-home');
  });

  testWidgets(
    'follow-system resolves English, Chinese and unsupported locales',
    (tester) async {
      tester.platformDispatcher.localesTestValue = const [Locale('en', 'US')];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);
      await mount(tester, language: HipLanguage.system);
      expect(find.text('Office Reset'), findsOneWidget);
      tester.platformDispatcher.localesTestValue = const [Locale('zh', 'TW')];
      await tester.pumpAndSettle();
      expect(find.text('工位放松'), findsOneWidget);
      tester.platformDispatcher.localesTestValue = const [Locale('fr', 'FR')];
      await tester.pumpAndSettle();
      expect(find.text('工位放松'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  for (final theme in [HipThemeChoice.dark, HipThemeChoice.light]) {
    testWidgets(
      'English main flows render with full page copy in ${theme.id}',
      (tester) async {
        await mount(tester, theme: theme);
        await capture(tester, '${theme.id}-home');
        await openMore(tester);
        expect(find.text('更多'), findsNothing);
        await capture(tester, '${theme.id}-more');
        await openSettings(tester);
        expect(find.text('Settings'), findsOneWidget);
        await capture(tester, '${theme.id}-settings-top');
        final privacy = find.byKey(const ValueKey('privacy-policy'));
        if (privacy.evaluate().isEmpty) {
          await tester.scrollUntilVisible(
            privacy,
            250,
            scrollable: find.byType(Scrollable).last,
          );
        }
        await tester.ensureVisible(privacy);
        await tester.pumpAndSettle();
        await capture(tester, '${theme.id}-settings-language');
        await tester.tap(privacy);
        await tester.pumpAndSettle();
        expect(find.text('隐私政策'), findsNothing);
        await capture(tester, '${theme.id}-privacy');
        await openRecords(tester);
        expect(find.text('训练记录'), findsNothing);
        await capture(tester, '${theme.id}-records');
        await openGroups(tester);
        expect(find.text('新建训练组'), findsNothing);
        await capture(tester, '${theme.id}-groups');
        await tester.tap(find.byKey(const ValueKey('new-group')));
        await tester.pumpAndSettle();
        expect(find.text('添加动作'), findsNothing);
        await capture(tester, '${theme.id}-picker');
        await tester.tap(find.byKey(const ValueKey('picker-close')));
        await tester.pumpAndSettle();
        await openPractice(tester);
        expect(find.text('动作库'), findsNothing);
        await capture(tester, '${theme.id}-library');
      },
    );

    testWidgets('English first-launch safety remains usable in ${theme.id}', (
      tester,
    ) async {
      await mount(tester, theme: theme, onboarded: false);
      await capture(tester, '${theme.id}-onboarding');
      for (var index = 0; index < content.safetyCards.length; index++) {
        await tester.tap(find.byKey(const ValueKey('safety-no')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
      expect(find.text('What brings you here?'), findsOneWidget);
      await capture(tester, '${theme.id}-identity');
    });
  }
}
