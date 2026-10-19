// HipLab transition capture (not part of `flutter test`): every page
// transition recorded frame by frame at 60 fps, 390×844 phone, real fonts.
//
//   CAPTURE_OUT=test/_shots/capture/after \
//     flutter test --no-pub test_screens/hip_transition_capture_test.dart
//   python3 tools/transitions/render.py test/_shots/capture/after
//
// One testWidgets per transition so a single one can be re-run with
// `--plain-name`. Each transition is played once untimed first so its
// images are decoded (a capture never waits for real time), then recorded.
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiplab/hip/control/hip_store.dart';
import 'package:hiplab/hip/domain/hip_assessment.dart';
import 'package:hiplab/hip/domain/hip_models.dart';
import 'package:hiplab/hip/ui/hip_app.dart';
import 'package:hiplab/hip/ui/hip_player_page.dart';
import 'package:hiplab/hip/ui/hip_routes.dart';
import 'package:hiplab/hip/ui/hip_theme.dart';
import 'package:hiplab/hip/ui/hip_widgets.dart';

import '../test/hip/hip_domain_test.dart' show MemoryStorage, loadContent;
import 'support/frame_capture.dart';
import '../test/hip/checkup_entry.dart';

const _root = ValueKey('capture-root');
final _out =
    Platform.environment['CAPTURE_OUT'] ?? 'test/_shots/capture/latest';
final _theme = Platform.environment['CAPTURE_THEME'] == 'light'
    ? HipThemeChoice.light
    : HipThemeChoice.dark;

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
  final icons = File(
    '$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  );
  if (icons.existsSync()) await load('MaterialIcons', icons.path);
}

/// Decodes every image currently in the tree.
Future<void> _precache(WidgetTester tester) async {
  for (var i = 0; i < 2; i++) {
    await tester.runAsync(() async {
      for (final e in find.byType(Image).evaluate()) {
        await precacheImage((e.widget as Image).image, e);
      }
    });
    await tester.pump(const Duration(milliseconds: 50));
  }
  await tester.pumpAndSettle();
}

const _long = Duration(milliseconds: 700);

void main() {
  final content = loadContent();
  setUpAll(() async {
    await _loadFonts();
    HipColors.flatShadows = false;
  });

  Future<HipStore> boot(WidgetTester tester, {bool assessed = true}) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    const pad = FakeViewPadding(top: 47, bottom: 34);
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
      ..theme = _theme
      ..safety = {'pregnancy': false, 'surgery': false, 'acute': false}
      ..identity = HipIdentity.dancer
      ..minutes = 10
      ..scene = HipScene.home;
    ItemAnswer one(int s) => ItemAnswer.single(SideAnswer.choice(s));
    if (assessed) {
      store.assessments.add((
        at: now,
        answers: {for (final i in content.rules.items) i.id: one(1)},
      ));
    }
    await tester.pumpWidget(
      RepaintBoundary(
        key: _root,
        child: HipApp(store: store, videoEnabled: false),
      ),
    );
    await tester.pumpAndSettle();
    await _precache(tester);
    return store;
  }

  FrameCapture cap(WidgetTester tester) =>
      FrameCapture(tester, outDir: _out, rootKey: _root);

  /// Plays [open] then [close] once (to decode the destination's images),
  /// leaving the app where it started.
  Future<void> warm(
    WidgetTester tester,
    Future<void> Function() open,
    Future<void> Function() close,
  ) async {
    await open();
    await tester.pumpAndSettle();
    await _precache(tester);
    await close();
    await tester.pumpAndSettle();
    await _precache(tester);
  }

  Future<void> tapStart(WidgetTester t) =>
      t.tap(find.byKey(const ValueKey('start-today')));
  Future<void> closePlayer(WidgetTester t) =>
      t.tap(find.byType(HipCircleButton).first);
  Future<void> closeCheck(WidgetTester t) =>
      t.tap(find.byType(HipCircleButton).first);

  testWidgets('01-start-expand + 02-player-close', (t) async {
    await boot(t);
    await warm(t, () => tapStart(t), () => closePlayer(t));
    await cap(
      t,
    ).record('01-start-expand', act: () => tapStart(t), total: _long);
    await t.pumpAndSettle();
    await cap(
      t,
    ).record('02-player-close', act: () => closePlayer(t), total: _long);
    await t.pumpAndSettle();
  });

  testWidgets('03-tab-right + 04-tab-left', (t) async {
    await boot(t);
    await warm(
      t,
      () => t.tap(find.byKey(const ValueKey('tab-2'))),
      () => t.tap(find.byKey(const ValueKey('tab-0'))),
    );
    await cap(t).record(
      '03-tab-right',
      act: () => t.tap(find.byKey(const ValueKey('tab-2'))),
      total: const Duration(milliseconds: 500),
    );
    await t.pumpAndSettle();
    await cap(t).record(
      '04-tab-left',
      act: () => t.tap(find.byKey(const ValueKey('tab-1'))),
      total: const Duration(milliseconds: 500),
    );
    await t.pumpAndSettle();
  });

  Future<void> toSettingsBottom(WidgetTester t) async {
    await t.tap(find.byKey(const ValueKey('tab-2')));
    await t.pumpAndSettle();
    await t.drag(find.byType(ListView).first, const Offset(0, -1200));
    await t.pumpAndSettle();
    await _precache(t);
  }

  testWidgets('05-push + 06-pop', (t) async {
    await boot(t);
    await toSettingsBottom(t);
    Future<void> open() => t.tap(find.text('隐私政策'));
    Future<void> back() async =>
        Navigator.of(t.element(find.byType(Scaffold).last)).maybePop();
    await warm(t, open, back);
    await cap(t).record('05-push', act: open, total: _long);
    await t.pumpAndSettle();
    await cap(t).record('06-pop', act: back, total: _long);
    await t.pumpAndSettle();
  });

  testWidgets('07-ios-swipe-back', (t) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    try {
      await boot(t);
      await toSettingsBottom(t);
      await t.tap(find.text('隐私政策'));
      await t.pumpAndSettle();
      await _precache(t);
      // A finger from the left edge, 12 px per frame (≈ 720 px/s) for 20
      // frames (≈ 60 % across), then lifted while moving: a fling that
      // completes the pop on the settle curve.
      late TestGesture g;
      const frame = Duration(microseconds: 16667);
      await cap(t).record(
        '07-ios-swipe-back',
        act: () async {
          g = await t.startGesture(const Offset(6, 420));
        },
        total: const Duration(milliseconds: 650),
        onFrame: (i) async {
          if (i <= 20) {
            await g.moveBy(const Offset(12, 0), timeStamp: frame * i);
          } else if (i == 21) {
            await g.up(timeStamp: frame * i);
          }
        },
      );
      await t.pumpAndSettle();
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('08-micro-expand + 09-micro-close', (t) async {
    await boot(t);
    await t.tap(find.byKey(const ValueKey('tab-2')));
    await t.pumpAndSettle();
    await t.ensureVisible(find.text('2 分钟椅边放松'));
    await t.pumpAndSettle();
    await t.drag(find.byType(ListView).first, const Offset(0, 300));
    await t.pumpAndSettle();
    await _precache(t);
    Future<void> open() => t.tap(find.text('2 分钟椅边放松'));
    await warm(t, open, () => closePlayer(t));
    await cap(t).record('08-micro-expand', act: open, total: _long);
    await t.pumpAndSettle();
    await cap(
      t,
    ).record('09-micro-close', act: () => closePlayer(t), total: _long);
    await t.pumpAndSettle();
  });

  testWidgets('10-check-expand + 11-check-close', (t) async {
    await boot(t);
    await openCheckupIntro(t);
    await _precache(t);
    Future<void> open() =>
        t.tap(find.byKey(const ValueKey('assessment-start')));
    await warm(t, open, () => closeCheck(t));
    await cap(t).record('10-check-expand', act: open, total: _long);
    await t.pumpAndSettle();
    await cap(
      t,
    ).record('11-check-close', act: () => closeCheck(t), total: _long);
    await t.pumpAndSettle();
  });

  testWidgets('13-rise + 14-rise-close', (t) async {
    final store = await boot(t);
    final plan = store.todayPlan!;
    Future<void> open() async {
      Navigator.of(t.element(find.byType(HipHome))).push(
        HipRoute.rise<void>((_) => HipPlayerPage(store: store, plan: plan)),
      );
    }

    await warm(t, open, () => closePlayer(t));
    await cap(t).record('13-rise', act: open, total: _long);
    await t.pumpAndSettle();
    await cap(
      t,
    ).record('14-rise-close', act: () => closePlayer(t), total: _long);
    await t.pumpAndSettle();
  });

  testWidgets('12-hip-tile-expand', (t) async {
    // The 我的髋部 tile opens the check only before the first result.
    await boot(t, assessed: false);
    Future<void> open() => t.tap(find.text('我的髋部'));
    await warm(t, open, () => closeCheck(t));
    await cap(t).record('12-hip-tile-expand', act: open, total: _long);
    await t.pumpAndSettle();
  });
}
