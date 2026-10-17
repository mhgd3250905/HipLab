// HipLab iOS visual check (not part of `flutter test`): the key screens on an
// iPhone 15 Pro (393×852 pt, Dynamic Island top inset 59, Home indicator 34)
// and an iPhone SE (375×667, insets 20/0) with the iOS target platform, in
// dark and light themes. The status bar, Dynamic Island and Home indicator
// are drawn on top so overlaps are visible at a glance.
//
//   flutter test --no-pub test_screens/hip_ios_shots_test.dart
//
// Output: test/_shots/ios/<phone>/<theme>/*.png (git-ignored, not committed).
import 'dart:io';
import 'dart:ui' as ui;

import 'package:hiplab/hip/control/hip_store.dart';
import 'package:hiplab/hip/domain/hip_assessment.dart';
import 'package:hiplab/hip/domain/hip_models.dart';
import 'package:hiplab/hip/domain/hip_settings.dart';
import 'package:hiplab/hip/ui/hip_app.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test/hip/hip_domain_test.dart' show MemoryStorage, loadContent;

const _dir = 'test/_shots/ios';

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
    required _Phone phone,
    double textScale = 1,
  }) async {
    tester.view.physicalSize = phone.size;
    tester.view.devicePixelRatio = 1;
    final pad = FakeViewPadding(top: phone.top, bottom: phone.bottom);
    tester.view.padding = pad;
    tester.view.viewPadding = pad;
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
      RepaintBoundary(
        child: Stack(
          textDirection: TextDirection.ltr,
          children: [
            HipApp(store: store, videoEnabled: false),
            IgnorePointer(
              child: CustomPaint(
                size: phone.size,
                painter: _IosChrome(
                  phone,
                  dark: store.theme != HipThemeChoice.light,
                ),
              ),
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    return store;
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

  for (final phone in _phones) {
    for (final theme in [HipThemeChoice.dark, HipThemeChoice.light]) {
      final t = '${phone.id}/${theme.id}';

      testWidgets('$t onboarding', (tester) async {
        await boot(tester, theme: theme, phone: phone, onboarded: false);
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
      }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

      testWidgets('$t home', (tester) async {
        await boot(tester, theme: theme, phone: phone);
        await _shot(tester, '$t/02-home');
      }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

      testWidgets(
        '$t assessment intro + items',
        (tester) async {
          await boot(tester, theme: theme, phone: phone);
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
        },
        variant: TargetPlatformVariant.only(TargetPlatform.iOS),
      );

      testWidgets('$t player', (tester) async {
        await boot(tester, theme: theme, phone: phone);
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
      }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

      testWidgets('$t settings', (tester) async {
        await boot(tester, theme: theme, phone: phone);
        await tester.tap(find.byKey(const ValueKey('tab-2')));
        await tester.pumpAndSettle();
        await _shot(tester, '$t/13-progress');
        await tester.drag(find.byType(ListView).first, const Offset(0, -600));
        await tester.pumpAndSettle();
        await _shot(tester, '$t/14-settings');
      }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));
    }
  }
}

class _Phone {
  const _Phone(this.id, this.size, this.top, this.bottom, {this.island = true});
  final String id;
  final Size size;
  final double top;
  final double bottom;
  final bool island;
}

const _phones = [
  _Phone('iphone15pro', Size(393, 852), 59, 34),
  _Phone('iphoneSE', Size(375, 667), 20, 0, island: false),
];

/// Status bar clock, Dynamic Island and Home indicator as iOS draws them,
/// plus faint safe-area guides.
class _IosChrome extends CustomPainter {
  _IosChrome(this.phone, {required this.dark});
  final _Phone phone;
  final bool dark;
  @override
  void paint(Canvas canvas, Size size) {
    final fg = dark ? const Color(0xffffffff) : const Color(0xff000000);
    final guide = Paint()
      ..color = const Color(0x55ff3b30)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, phone.top), Offset(size.width, phone.top), guide);
    if (phone.bottom > 0) {
      final y = size.height - phone.bottom;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), guide);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(size.width / 2, size.height - 8),
            width: 134,
            height: 5,
          ),
          const Radius.circular(3),
        ),
        Paint()..color = fg,
      );
    }
    if (phone.island) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(size.width / 2, 11 + 18.5),
            width: 126,
            height: 37,
          ),
          const Radius.circular(19),
        ),
        Paint()..color = const Color(0xff000000),
      );
    }
    final tp = TextPainter(
      text: TextSpan(
        text: '9:41',
        style: TextStyle(
          color: fg,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          fontFamily: 'NotoSansSC',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(phone.island ? 50 : 16, phone.island ? 18 : 1));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
