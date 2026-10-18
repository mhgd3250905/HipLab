import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiplab/hip/control/hip_store.dart';
import 'package:hiplab/hip/domain/hip_models.dart';
import 'package:hiplab/hip/ui/hip_app.dart';
import 'package:hiplab/hip/ui/hip_privacy_page.dart';
import 'package:hiplab/hip/ui/hip_theme.dart';

import 'hip_domain_test.dart' show MemoryStorage, loadContent;

void main() {
  for (final platform in [TargetPlatform.iOS, TargetPlatform.android]) {
    testWidgets('$platform privacy content and copied URL match the device', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final previousPalette = HipColors.palette;
      HipColors.palette = HipPalette.light;
      addTearDown(() => HipColors.palette = previousPalette);
      String? copiedUrl;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copiedUrl = (call.arguments as Map)['text'] as String;
          }
          return null;
        },
      );
      addTearDown(() {
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        );
      });
      await tester.pumpWidget(
        MaterialApp(
          theme: hipTheme(HipPalette.light).copyWith(platform: platform),
          home: const HipPrivacyPage(),
        ),
      );
      await tester.pumpAndSettle();
      final ios = platform == TargetPlatform.iOS;
      final scrollable = find.byType(Scrollable).first;
      final backup = find.textContaining(ios ? 'iCloud 或电脑备份' : 'Android 系统可能');
      await tester.scrollUntilVisible(backup, 300, scrollable: scrollable);
      expect(backup, findsOneWidget);
      final networking = find.textContaining(
        ios ? 'HealthKit' : 'Android 的网络权限',
      );
      await tester.scrollUntilVisible(networking, 300, scrollable: scrollable);
      expect(networking, findsOneWidget);
      final copy = find.byKey(const ValueKey('copy-privacy-url'));
      await tester.scrollUntilVisible(copy, 300, scrollable: scrollable);
      await tester.pumpAndSettle();
      final expectedUrl = ios
          ? HipPrivacyPage.iosPolicyUrl
          : HipPrivacyPage.policyUrl;
      expect(find.text(expectedUrl), findsOneWidget);
      await tester.tap(copy);
      await tester.pumpAndSettle();
      expect(copiedUrl, expectedUrl);
      expect(find.text('已复制隐私政策链接'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('progress keeps the published privacy policy reachable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final store = HipStore(content: loadContent(), storage: MemoryStorage());
    await store.initialize();
    store.safety = {'pregnancy': false, 'surgery': false, 'acute': false};
    store.identity = HipIdentity.office;
    await tester.pumpWidget(HipApp(store: store, videoEnabled: false));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('tab-2')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('隐私政策'), 400);
    await tester.tap(find.text('隐私政策'));
    await tester.pumpAndSettle();
    expect(find.byType(HipPrivacyPage), findsOneWidget);
    await tester.scrollUntilVisible(
      find.textContaining('mhgd3250905@gmail.com'),
      400,
      scrollable: find
          .descendant(
            of: find.byType(HipPrivacyPage),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(find.textContaining('mhgd3250905@gmail.com'), findsOneWidget);
  });
}
