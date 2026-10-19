// HipLab transition frames (not part of `flutter test`): each page
// transition captured at evenly spaced points, iPhone 15 Pro size, dark.
//
//   flutter test --no-pub test_screens/hip_transitions_frames_test.dart
//
// Output: test/_shots/transitions/<name>-<i>.png (git-ignored); stitch with
// ImageMagick (one row per transition).
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiplab/hip/control/hip_store.dart';
import 'package:hiplab/hip/domain/hip_assessment.dart';
import 'package:hiplab/hip/domain/hip_models.dart';
import 'package:hiplab/hip/ui/hip_app.dart';
import 'package:hiplab/hip/ui/hip_theme.dart';
import 'package:hiplab/hip/ui/hip_widgets.dart';

import '../test/hip/hip_domain_test.dart' show MemoryStorage, loadContent;

const _dir = 'test/_shots/transitions';
const _frames = 6;

Future<void> _loadFonts() async {
  final bytes = File('assets/fonts/NotoSansSC.ttf').readAsBytesSync();
  await (FontLoader(
    'NotoSansSC',
  )..addFont(Future.value(ByteData.view(bytes.buffer)))).load();
}

Future<void> _grab(WidgetTester tester, String name) async {
  await tester.runAsync(() async {
    final boundary =
        find.byKey(const ValueKey('frames-root')).evaluate().first.renderObject!
            as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    File('$_dir/$name.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(data!.buffer.asUint8List());
  });
}

/// Starts a transition with [act], then captures [_frames] frames across
/// [total] (first frame right after the tap, last when it has landed).
Future<void> _sequence(
  WidgetTester tester,
  String name,
  Duration total,
  Future<void> Function() act,
) async {
  await act();
  await tester.pump();
  await _grab(tester, '$name-0');
  final step = total ~/ (_frames - 1);
  for (var i = 1; i < _frames; i++) {
    await tester.pump(step);
    await _grab(tester, '$name-$i');
  }
}

void main() {
  final content = loadContent();
  setUpAll(() async {
    await _loadFonts();
    HipColors.flatShadows = true;
  });

  Future<HipStore> boot(WidgetTester tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    const pad = FakeViewPadding(top: 59, bottom: 34);
    tester.view.padding = pad;
    tester.view.viewPadding = pad;
    addTearDown(tester.view.reset);
    final now = DateTime(2026, 10, 16, 9, 41);
    final store = HipStore(
      content: content,
      storage: MemoryStorage(),
      clock: () => now,
    );
    await store.initialize();
    store
      ..theme = HipThemeChoice.dark
      ..safety = {'pregnancy': false, 'surgery': false, 'acute': false}
      ..identity = HipIdentity.dancer
      ..minutes = 10
      ..scene = HipScene.home;
    ItemAnswer one(int s) => ItemAnswer.single(SideAnswer.choice(s));
    store.assessments.add((
      at: now,
      answers: {for (final i in content.rules.items) i.id: one(1)},
    ));
    await tester.pumpWidget(
      RepaintBoundary(
        key: const ValueKey('frames-root'),
        child: HipApp(store: store, videoEnabled: false),
      ),
    );
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      for (final e in find.byType(Image).evaluate()) {
        await precacheImage((e.widget as Image).image, e);
      }
    });
    await tester.pumpAndSettle();
    return store;
  }

  testWidgets('frames', (tester) async {
    await boot(tester);
    // 1. 开始 → player grows out of the button.
    await _sequence(
      tester,
      '1-start-expand',
      HipMotion.expand,
      () => tester.tap(find.byKey(const ValueKey('start-today'))),
    );
    await tester.pumpAndSettle();
    // 2. Close the player → shrinks back into the button.
    await _sequence(
      tester,
      '2-close-shrink',
      HipMotion.expandReverse,
      () => tester.tap(find.byType(HipCircleButton).first),
    );
    await tester.pumpAndSettle();
    // 3. Tab 今日 → 进度 (slides in from the right).
    await _sequence(
      tester,
      '3-tab-right',
      HipMotion.tab,
      () => tester.tap(find.byKey(const ValueKey('tab-2'))),
    );
    await tester.pumpAndSettle();
    // 4. Drill-down push from the right (重新看安全提示).
    await tester.drag(find.byType(ListView).first, const Offset(0, -900));
    await tester.pumpAndSettle();
    await _sequence(
      tester,
      '4-push',
      HipMotion.page,
      () => tester.tap(find.text('重新看安全提示')),
    );
    await tester.pumpAndSettle();
    await _sequence(tester, '4b-pop', HipMotion.pageReverse, () async {
      Navigator.of(tester.element(find.byType(HipOnboarding))).pop();
    });
    await tester.pumpAndSettle();
    // 5. Tab 进度 → 练习 (slides in from the left), then start the check.
    await _sequence(
      tester,
      '5-tab-left',
      HipMotion.tab,
      () => tester.tap(find.byKey(const ValueKey('tab-1'))),
    );
    await tester.pumpAndSettle();
    // 自测 is a card on 练习 now (拍板 2026-10-19): open its intro page.
    await tester.tap(find.byKey(const ValueKey('hip-check-card')));
    await tester.pumpAndSettle();
    await _sequence(
      tester,
      '6-check-expand',
      HipMotion.expand,
      () => tester.tap(find.byKey(const ValueKey('assessment-start'))),
    );
    await tester.pumpAndSettle();
  });
}
