// AI 定制 screenshots for docs/ai-coach.md (not part of `flutter test`):
// rendered by the widget test renderer with the SDK's FakeLlmClient.
//
//   flutter test --no-pub test_screens/hip_ai_coach_shots_test.dart
//
// Output: docs/ai-coach/*.png (committed with the docs).
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiplab/hip/coach/coach_config.dart';
import 'package:hiplab/hip/coach/coach_service.dart';
import 'package:hiplab/hip/coach/usage_store.dart';
import 'package:hiplab/hip/control/hip_store.dart';
import 'package:hiplab/hip/domain/hip_models.dart';
import 'package:hiplab/hip/ui/hip_app.dart';
import 'package:hiplab/hip/ui/hip_theme.dart';
import 'package:ugk_coach/ugk_coach.dart' as uc;

import '../test/hip/hip_ai_coach_test.dart' show validPlanEnvelope, readAsset;
import '../test/hip/hip_domain_test.dart' show MemoryStorage, loadContent;

const _dir = 'docs/ai-coach';

Future<void> _loadFonts() async {
  final bytes = File('assets/fonts/NotoSansSC.ttf').readAsBytesSync();
  await (FontLoader(
    'NotoSansSC',
  )..addFont(Future.value(ByteData.view(bytes.buffer)))).load();
}

Future<void> _shot(WidgetTester tester, String name) async {
  for (var i = 0; i < 2; i++) {
    await tester.runAsync(() async {
      for (final e in find.byType(Image).evaluate()) {
        await precacheImage((e.widget as Image).image, e);
      }
    });
    await tester.pump(const Duration(milliseconds: 400));
  }
  await tester.runAsync(() async {
    final boundary =
        find.byType(RepaintBoundary).first.evaluate().first.renderObject!
            as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    File('$_dir/$name.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(data!.buffer.asUint8List());
  });
}

void main() {
  final content = loadContent();
  setUpAll(() async {
    await _loadFonts();
    HipColors.flatShadows = true;
  });

  CoachService coach(List<Object> script) => CoachService(
    config: script.isEmpty
        ? const CoachConfig()
        : const CoachConfig(apiKey: 'test'),
    content: content,
    client: script.isEmpty ? null : uc.FakeLlmClient(script),
    usage: CoachUsageStore(),
    storage: MemoryStorage(),
    readAsset: readAsset,
  );

  Future<void> boot(
    WidgetTester tester,
    CoachService c, {
    required bool dark,
    Size size = const Size(390, 844),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final store = HipStore(
      content: content,
      storage: MemoryStorage(),
      clock: () => DateTime(2026, 10, 20, 9, 30),
    );
    await store.initialize();
    store
      ..safety = {'pregnancy': false, 'surgery': false, 'acute': false}
      ..identity = HipIdentity.office
      ..theme = dark ? HipThemeChoice.dark : HipThemeChoice.light;
    await tester.pumpWidget(
      RepaintBoundary(
        child: HipApp(store: store, videoEnabled: false, coach: c),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('tab-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('practice-2')));
    await tester.pumpAndSettle();
  }

  Future<void> open(WidgetTester tester, {bool accept = true}) async {
    await tester.tap(find.byKey(const ValueKey('practice-ai-coach')));
    await tester.pumpAndSettle();
    if (accept) {
      await tester.tap(find.byKey(const ValueKey('coach-disclaimer-ok')));
      await tester.pumpAndSettle();
    }
  }

  Future<void> say(
    WidgetTester tester,
    String text, {
    bool settle = true,
  }) async {
    await tester.enterText(find.byKey(const ValueKey('coach-input')), text);
    await tester.tap(find.byKey(const ValueKey('coach-send')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    if (settle) await tester.pumpAndSettle();
  }

  testWidgets('1 练习页「我的」入口（浅色）', (tester) async {
    await boot(tester, coach([validPlanEnvelope()]), dark: false);
    await _shot(tester, '1-practice-entry-light');
  });

  testWidgets('2 等待态（深色）', (tester) async {
    await boot(
      tester,
      coach([
        (uc.LlmRequest r) async {
          await Future<void>.delayed(const Duration(seconds: 60));
          return jsonEncode(validPlanEnvelope());
        },
      ]),
      dark: true,
    );
    await open(tester, accept: false);
    await say(tester, '睡前 12 分钟，开开胯', settle: false);
    await tester.pump(const Duration(seconds: 12));
    await _shot(tester, '2-thinking-disclaimer-dark');
    await tester.tap(find.byKey(const ValueKey('coach-stop')));
    await tester.pump(const Duration(seconds: 60));
    await tester.pumpAndSettle();
  });

  testWidgets('3 计划卡（浅色）', (tester) async {
    await boot(
      tester,
      coach([validPlanEnvelope()]),
      dark: false,
      size: const Size(390, 1400),
    );
    await open(tester);
    await say(tester, '睡前 12 分钟，开开胯');
    await _shot(tester, '3-plan-card-light');
  });

  testWidgets('4 未配置 → 预设方案（深色）', (tester) async {
    await boot(
      tester,
      coach(const []),
      dark: true,
      size: const Size(390, 1100),
    );
    await open(tester);
    await say(tester, '在办公室工位上做一组');
    await _shot(tester, '4-preset-unconfigured-dark');
  });
}
