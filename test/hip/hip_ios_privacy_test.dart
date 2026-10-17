import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiplab/hip/ui/hip_privacy_page.dart';

void main() {
  testWidgets('iOS privacy disclosure links and copies its platform policy', (
    tester,
  ) async {
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
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: TargetPlatform.iOS),
        home: const HipPrivacyPage(),
      ),
    );
    final policyScroll = find
        .descendant(
          of: find.byType(ListView),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(
      find.textContaining('“卸载 App”'),
      300,
      scrollable: policyScroll,
    );
    expect(find.textContaining('iCloud'), findsOneWidget);
    expect(find.textContaining('Android 系统'), findsNothing);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('copy-privacy-url')),
      300,
      scrollable: policyScroll,
    );
    await tester.tap(find.byKey(const ValueKey('copy-privacy-url')));
    await tester.pump();
    expect(copiedUrl, 'https://mhgd3250905.github.io/HipLab/ios/');
  });
}
