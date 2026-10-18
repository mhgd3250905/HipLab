// Prep / rest screens of the player (rep-rhythm PR): the next drill's demo
// in the media area, the feedback row under it, and what a feedback tap does.
// Visual check only (not part of `flutter test`):
//
//   flutter test --no-pub test_screens/hip_phase_shots_test.dart
//
// Output: test/_shots/phases/<theme>/*.png (git-ignored).
import 'dart:io';
import 'dart:ui' as ui;

import 'package:hiplab/hip/control/hip_store.dart';
import 'package:hiplab/hip/domain/hip_assessment.dart';
import 'package:hiplab/hip/domain/hip_models.dart';
import 'package:hiplab/hip/domain/hip_settings.dart';
import 'package:hiplab/hip/ui/hip_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test/hip/hip_domain_test.dart' show MemoryStorage, loadContent;

const _dir = String.fromEnvironment('SHOTS', defaultValue: 'test/_shots/phases');

Future<void> _loadFonts() async {
  Future<void> load(String family, String path) async {
    final bytes = File(path).readAsBytesSync();
    await (FontLoader(
      family,
    )..addFont(Future.value(ByteData.view(bytes.buffer)))).load();
  }

  await load('NotoSansSC', 'assets/fonts/NotoSansSC.ttf');
  final root =
      Platform.environment['FLUTTER_ROOT'] ??
      '${Platform.environment['HOME']}/fl/flutter';
  await load(
    'MaterialIcons',
    '$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  );
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
  setUpAll(_loadFonts);

  Future<HipStore> boot(
    WidgetTester tester, {
    required HipThemeChoice theme,
    bool onboarded = true,
    Size size = const Size(390, 844),
    double textScale = 1,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 47, bottom: 34);
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final now = DateTime(2026, 10, 16, 9, 41);
    final store = HipStore(
      content: content,
      storage: MemoryStorage(),
      clock: () => now,
    );
    await store.initialize();
    store.theme = theme;
    if (onboarded) {
      store
        ..safety = {'pregnancy': false, 'surgery': false, 'acute': false}
        ..identity = HipIdentity.dancer
        ..minutes = 10
        ..scene = HipScene.home;
      for (var i = 1; i <= 7; i++) {
        store.doneDays.add('2026-10-${(16 - i).toString().padLeft(2, '0')}');
      }
      ItemAnswer one(int s) => ItemAnswer.single(SideAnswer.choice(s));
      ItemAnswer two(int l, int r, {String? f}) => ItemAnswer.sided(
        left: SideAnswer.choice(l, followUp: f),
        right: SideAnswer.choice(r, followUp: f),
      );
      store.assessments.add((
        at: now,
        answers: {
          'butterfly': one(1),
          'ninety_ninety': two(0, 1, f: 'back'),
          'thomas': two(0, 1),
          'supine_cross': two(1, 1),
          'seated_fold': one(2),
          'deep_squat': one(2),
        },
      ));
    }
    await tester.pumpWidget(
      RepaintBoundary(child: HipApp(store: store, videoEnabled: false)),
    );
    await tester.pumpAndSettle();
    return store;
  }

  for (final theme in [HipThemeChoice.dark, HipThemeChoice.light]) {
    final t = theme.name;
    testWidgets('$t prep / rest', (tester) async {
      await boot(tester, theme: theme);
      await tester.tap(find.byKey(const ValueKey('start-today')));
      await tester.pump(const Duration(seconds: 3));
      await _shot(tester, '$t/1-prep');
      await tester.tap(find.byKey(const ValueKey('player-skip')));
      await tester.pump(const Duration(seconds: 6));
      await tester.tap(find.byKey(const ValueKey('player-skip')));
      await tester.pump(const Duration(seconds: 2));
      await _shot(tester, '$t/2-rest');
      final ok = find.byKey(const ValueKey('feel-ok'));
      if (ok.evaluate().isNotEmpty) {
        await tester.tap(ok);
        await tester.pump(const Duration(seconds: 1));
      }
      await _shot(tester, '$t/3-after-feedback-tap');
    });
  }
}
