import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hiplab/hip/control/hip_store.dart';
import 'package:hiplab/hip/coach/coach_config.dart';
import 'package:hiplab/hip/domain/hip_models.dart';
import 'package:hiplab/hip/ui/hip_app.dart';
import 'package:hiplab/hip/ui/hip_privacy_page.dart';

import 'hip_domain_test.dart' show MemoryStorage, loadContent;
import 'home_nav.dart';
import 'public_media_fixture.dart';

void main() {
  for (final mode in ['worker', 'bearer']) {
    testWidgets('configured iOS privacy discloses $mode AI requests', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('zh'),
          supportedLocales: const [Locale('zh'), Locale('en')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          theme: ThemeData(platform: TargetPlatform.iOS),
          home: HipPrivacyPage(
            coachConfig: CoachConfig(
              authMode: mode,
              appKey: mode == 'worker' ? 'local-test-fixture' : '',
              token: mode == 'bearer' ? 'local-test-fixture' : '',
            ),
          ),
        ),
      );
      await tester.scrollUntilVisible(
        find.text('AI 定制与设备标识'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.textContaining('你输入的需求和当前对话会发送给 AI 服务'), findsOneWidget);
      expect(
        find.textContaining(
          mode == 'worker' ? '随机生成并保存在本机的安装标识' : '此连接模式不附带 AI 安装标识',
        ),
        findsOneWidget,
      );
      expect(find.text('在线 AI 未启用'), findsNothing);
    });
  }

  for (final mode in ['worker', 'bearer']) {
    testWidgets('English iOS privacy discloses $mode identifier behavior', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          theme: ThemeData(platform: TargetPlatform.iOS),
          home: HipPrivacyPage(
            coachConfig: CoachConfig(
              authMode: mode,
              appKey: mode == 'worker' ? 'local-test-fixture' : '',
              token: mode == 'bearer' ? 'local-test-fixture' : '',
            ),
          ),
        ),
      );
      await tester.scrollUntilVisible(
        find.text('AI training and installation identifier'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        find.textContaining(
          mode == 'worker'
              ? 'randomly generated installation identifier'
              : 'does not attach an AI installation identifier',
        ),
        findsOneWidget,
      );
      expect(find.text('Online AI is not enabled'), findsNothing);
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
    await tester.pumpWidget(
      HipApp(
        mediaPolicy: installPublicMediaFixture().policy,
        store: store,
        videoEnabled: false,
      ),
    );
    await tester.pumpAndSettle();
    await openSettings(tester);
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
