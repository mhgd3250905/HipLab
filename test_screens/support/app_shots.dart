// App-owned screen captures. SDK player phases are tested by the SDK itself.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiplab/hip/control/hip_store.dart';
import 'package:hiplab/hip/data/hip_content_loader.dart';
import 'package:hiplab/hip/domain/hip_models.dart';
import 'package:hiplab/hip/ui/hip_app.dart';
import 'package:hiplab/hip/ui/hip_theme.dart';

import '../../test/hip/hip_ai_coach_test.dart' show FileAssetBundle;
import '../../test/hip/hip_domain_test.dart' show MemoryStorage;
import '../../test/hip/public_media_fixture.dart';

final shotRoot = GlobalKey();

Future<HipContent> loadShotContent() async {
  for (final font in {
    hipFontFamily: 'assets/fonts/NotoSansSC.ttf',
    'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
  }.entries) {
    await (FontLoader(font.key)..addFont(rootBundle.load(font.value))).load();
  }
  return loadHipContent(FileAssetBundle());
}

Future<void> mountShotApp(
  WidgetTester tester,
  HipContent content,
  HipThemeChoice theme, {
  void Function(HipStore)? setup,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  tester.view.padding = const FakeViewPadding(top: 24, bottom: 24);
  addTearDown(tester.view.reset);
  final fixture = installPublicMediaFixture(sharedLibrary: true);
  final store = HipStore(
    content: content,
    storage: MemoryStorage(),
    clock: () => DateTime(2026, 11, 2, 14, 15),
  );
  addTearDown(store.dispose);
  await store.initialize();
  store
    ..theme = theme
    ..identity = HipIdentity.office
    ..safety = {'pregnancy': false, 'surgery': false, 'acute': false};
  setup?.call(store);
  await tester.pumpWidget(
    RepaintBoundary(
      key: shotRoot,
      child: HipApp(
        store: store,
        videoEnabled: false,
        mediaPolicy: fixture.policy,
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(find.byKey(const ValueKey('home-more')), findsOneWidget);
}

Future<void> saveAppShot(WidgetTester tester, String path) async {
  await tester.runAsync(() async {
    for (final element in find.byType(Image).evaluate()) {
      await precacheImage((element.widget as Image).image, element);
    }
  });
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
  await tester.runAsync(() async {
    final boundary =
        shotRoot.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1);
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      await (File(path)..createSync(recursive: true)).writeAsBytes(
        data!.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      );
    } finally {
      image.dispose();
    }
  });
}
