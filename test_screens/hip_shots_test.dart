// HipLab visual check (not part of `flutter test`): renders the key screens
// at 390×844 (plus 360-wide / large-text variants) in dark and light themes
// with real fonts and writes PNGs for review.
//
//   flutter test --no-pub test_screens/hip_shots_test.dart
//
// Output: test/_shots/hip/<theme>/*.png (git-ignored, not committed).
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

const _dir = 'test/_shots/hip';

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

  Future<void> openAssessment(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey('tab-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('assessment-start')));
    await tester.pumpAndSettle();
  }

  Future<void> pick(WidgetTester tester, int s, {String? follow}) async {
    await tester.tap(find.byKey(ValueKey('option-$s')));
    await tester.pump();
    if (follow != null) {
      await tester.tap(find.byKey(ValueKey('follow-$follow')));
      await tester.pump();
    }
    await tester.tap(find.byKey(const ValueKey('assessment-next')));
    await tester.pumpAndSettle();
  }

  for (final theme in [HipThemeChoice.dark, HipThemeChoice.light]) {
    final t = theme.id;

    testWidgets('$t onboarding', (tester) async {
      await boot(tester, theme: theme, onboarded: false);
      await _shot(tester, '$t/01-onboarding-1');
      await tester.tap(find.byKey(const ValueKey('safety-no')));
      await tester.pumpAndSettle();
      await _shot(tester, '$t/01-onboarding-2');
      await tester.tap(find.byKey(const ValueKey('safety-no')));
      await tester.pumpAndSettle();
      await _shot(tester, '$t/01-onboarding-3');
      await tester.tap(find.byKey(const ValueKey('safety-no')));
      await tester.pumpAndSettle();
      await _shot(tester, '$t/01-onboarding-identity');
    });

    testWidgets('$t home', (tester) async {
      await boot(tester, theme: theme);
      await _shot(tester, '$t/02-home');
    });

    testWidgets('$t assessment intro + items', (tester) async {
      await boot(tester, theme: theme);
      await tester.tap(find.byKey(const ValueKey('tab-1')));
      await tester.pumpAndSettle();
      await _shot(tester, '$t/03-assessment-intro');
      await tester.tap(find.byKey(const ValueKey('assessment-start')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('option-2')));
      await tester.pump(const Duration(seconds: 1));
      await _shot(tester, '$t/04-assessment-1-selected');
      await tester.tap(find.byKey(const ValueKey('assessment-next')));
      await tester.pumpAndSettle();
      await pick(tester, 2); // 90/90 left
      await tester.tap(find.byKey(const ValueKey('option-0')));
      await tester.pump();
      await _shot(tester, '$t/05-assessment-2-followup');
      await tester.tap(find.byKey(const ValueKey('follow-back')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('assessment-next')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('option-1')));
      await tester.pump();
      await _shot(tester, '$t/06-assessment-3-left');
      await tester.tap(find.byKey(const ValueKey('assessment-next')));
      await tester.pump(const Duration(milliseconds: 500));
      await _shot(tester, '$t/07-assessment-3-switch-right');
      await tester.pumpAndSettle();
      await pick(tester, 1);
      await pick(tester, 1);
      await pick(tester, 1);
      await pick(tester, 2);
      await pick(tester, 2);
      await _shot(tester, '$t/08-result');
      await tester.drag(find.byType(ListView).first, const Offset(0, -400));
      await tester.pumpAndSettle();
      await _shot(tester, '$t/08-result-scrolled');
    });

    testWidgets('$t player', (tester) async {
      await boot(tester, theme: theme);
      await tester.tap(find.byKey(const ValueKey('start-today')));
      await tester.pump(const Duration(seconds: 3));
      await _shot(tester, '$t/09-player-prep');
      await tester.tap(find.byKey(const ValueKey('player-skip')));
      await tester.pump(const Duration(seconds: 6));
      await _shot(tester, '$t/10-player-work-sided');
      await tester.tap(find.byKey(const ValueKey('player-skip')));
      await tester.pump(const Duration(seconds: 2));
      await _shot(tester, '$t/11-player-rest');
      await tester.tap(find.byKey(const ValueKey('player-skip')));
      await tester.pump(const Duration(seconds: 2));
      await _shot(tester, '$t/12-player-work-unsided');
    });

    testWidgets('$t settings', (tester) async {
      await boot(tester, theme: theme);
      await tester.tap(find.byKey(const ValueKey('tab-2')));
      await tester.pumpAndSettle();
      await _shot(tester, '$t/13-progress');
      await tester.drag(find.byType(ListView).first, const Offset(0, -600));
      await tester.pumpAndSettle();
      await _shot(tester, '$t/14-settings');
    });
  }

  // Small screen + large text (#4): every item, 360 wide, text ×1.3 / ×1.5.
  for (final scale in [1.3, 1.5]) {
    testWidgets('large text $scale on 360', (tester) async {
      await boot(
        tester,
        theme: HipThemeChoice.dark,
        size: const Size(360, 740),
        textScale: scale,
      );
      await openAssessment(tester);
      Future<void> choose() async {
        await tester.ensureVisible(find.byKey(const ValueKey('option-1')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('option-1')));
        await tester.pump();
      }

      for (var i = 1; i <= 6; i++) {
        await choose();
        await _shot(tester, 'scale/item$i-x$scale');
        await tester.tap(find.byKey(const ValueKey('assessment-next')));
        await tester.pumpAndSettle();
        if (_onRight(tester)) {
          await choose();
          await tester.tap(find.byKey(const ValueKey('assessment-next')));
          await tester.pumpAndSettle();
        }
      }
      await _shot(tester, 'scale/result-x$scale');
    });
  }
}

bool _onRight(WidgetTester tester) {
  final title = find.byKey(const ValueKey('assessment-title'));
  if (title.evaluate().isEmpty) return false;
  final w = tester.widget<Text>(title);
  return w.textSpan?.toPlainText().contains('右边') ?? false;
}
