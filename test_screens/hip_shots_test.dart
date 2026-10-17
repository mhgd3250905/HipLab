// HipLab visual check (not part of `flutter test`): renders the four key
// screens at 390×844 with real fonts and writes PNGs for comparison with the
// phase-0 prototype (s1-home / s2-assessment / s2-result / s3-player).
//
//   flutter test --no-pub test_screens/hip_shots_test.dart
//
// Output: test/_shots/hip/*.png (git-ignored, not committed).
import 'dart:io';
import 'dart:ui' as ui;

import 'package:hiplab/hip/control/hip_store.dart';
import 'package:hiplab/hip/domain/hip_assessment.dart';
import 'package:hiplab/hip/domain/hip_models.dart';
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
  await tester.runAsync(() async {
    for (final e in find.byType(Image).evaluate()) {
      await precacheImage((e.widget as Image).image, e);
    }
  });
  await tester.pump(const Duration(milliseconds: 300));
  await tester.runAsync(() async {
    final boundary =
        find.byType(RepaintBoundary).first.evaluate().first.renderObject!
            as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 3);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    File('$_dir/$name.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(data!.buffer.asUint8List());
  });
}

void main() {
  final content = loadContent();
  setUpAll(_loadFonts);

  Future<HipStore> boot(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 47, bottom: 34);
    addTearDown(tester.view.reset);
    final now = DateTime(2026, 10, 16, 9, 41);
    final store = HipStore(
      content: content,
      storage: MemoryStorage(),
      clock: () => now,
    );
    await store.initialize();
    store
      ..safety = {'pregnancy': false, 'surgery': false, 'acute': false}
      ..identity = HipIdentity.office
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
    await tester.pumpWidget(
      RepaintBoundary(child: HipApp(store: store, videoEnabled: false)),
    );
    await tester.pumpAndSettle();
    return store;
  }

  testWidgets('01 home', (tester) async {
    await boot(tester);
    await _shot(tester, 's1-home');
  });

  testWidgets('02 assessment item', (tester) async {
    await boot(tester);
    await tester.tap(find.byKey(const ValueKey('tab-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('assessment-start')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('option-1')));
    await tester.pump(const Duration(seconds: 5));
    await _shot(tester, 's2-assessment');
  });

  testWidgets('03 assessment result', (tester) async {
    await boot(tester);
    await tester.tap(find.byKey(const ValueKey('tab-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('assessment-start')));
    await tester.pumpAndSettle();
    Future<void> pick(int s, {String? follow}) async {
      await tester.tap(find.byKey(ValueKey('option-$s')));
      await tester.pump();
      if (follow != null) {
        await tester.tap(find.byKey(ValueKey('follow-$follow')));
        await tester.pump();
      }
      await tester.tap(find.byKey(const ValueKey('assessment-next')));
      await tester.pumpAndSettle();
    }

    await pick(1);
    await pick(0, follow: 'back');
    await pick(1);
    await pick(0);
    await pick(1);
    await pick(1);
    await pick(1);
    await pick(2);
    await pick(2);
    await _shot(tester, 's2-result');
  });

  testWidgets('04 player', (tester) async {
    await boot(tester);
    await tester.tap(find.byKey(const ValueKey('start-today')));
    await tester.pumpAndSettle();
    // Move to the 3rd drill (a sided one with a rendered still), a few seconds in.
    for (var i = 0; i < 4; i++) {
      await tester.tap(find.byKey(const ValueKey('player-skip')));
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.pump(const Duration(seconds: 7));
    await _shot(tester, 's3-player');
  });
}
