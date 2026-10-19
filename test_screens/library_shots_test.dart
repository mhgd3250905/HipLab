// 练习库 key screens from the real app (not part of `flutter test`): drives
// HipApp at iPhone 15 Pro size (393×852 pt, safe area 59 / 34, @3x) in dark
// and light with the bundled Noto Sans SC and the real content + kits.
//
//   LIB_OUT=/workspace/work/hiplab-library/deliver-build/screens \
//     flutter test --no-pub test_screens/library_shots_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiplab/hip/control/hip_store.dart';
import 'package:hiplab/hip/domain/hip_assessment.dart';
import 'package:hiplab/hip/domain/hip_library.dart';
import 'package:hiplab/hip/domain/hip_models.dart';
import 'package:hiplab/hip/domain/hip_pain.dart';
import 'package:hiplab/hip/ui/hip_app.dart';
import 'package:hiplab/hip/ui/hip_theme.dart';

import '../test/hip/hip_domain_test.dart' show MemoryStorage, loadContent;

final _out = Platform.environment['LIB_OUT'] ?? 'test/_shots/library-impl';
final _only = Platform.environment['LIB_ONLY'];

Future<void> _loadFonts() async {
  final bytes = File('assets/fonts/NotoSansSC.ttf').readAsBytesSync();
  await (FontLoader(
    'NotoSansSC',
  )..addFont(Future.value(ByteData.view(bytes.buffer)))).load();
}

final _now = DateTime(2026, 10, 19, 20, 10);

void main() {
  final content = loadContent();
  setUpAll(() async {
    await _loadFonts();
    HipColors.flatShadows = true; // the test renderer cannot blur shadows
  });

  Future<HipStore> boot(
    WidgetTester tester,
    String theme, {
    bool tested = true,
    bool groups = true,
  }) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 59, bottom: 34);
    addTearDown(tester.view.reset);
    final store = HipStore(
      content: content,
      storage: MemoryStorage(),
      clock: () => _now,
    );
    await store.initialize();
    store
      ..theme = theme == 'dark' ? HipThemeChoice.dark : HipThemeChoice.light
      ..safety = {'pregnancy': false, 'surgery': false, 'acute': false}
      ..identity = HipIdentity.office
      ..minutes = 10
      ..scene = HipScene.home
      ..doneDays.addAll(['2026-10-17', '2026-10-18']);
    // 髋前侧 hurt once this week: the detail shows 「最近疼过」.
    store.painEvents.add(
      PainEvent(DateTime(2026, 10, 17, 21), HipDirection.extension, 'pain'),
    );
    if (tested) {
      ItemAnswer one(int v) => ItemAnswer.single(SideAnswer.choice(v));
      ItemAnswer two(int l, int r) => ItemAnswer.sided(
        left: SideAnswer.choice(l),
        right: SideAnswer.choice(r),
      );
      store.assessments.add((
        at: DateTime(2026, 10, 18, 20, 30),
        answers: {
          'butterfly': one(1),
          'ninety_ninety': two(1, 1),
          'thomas': two(0, 1),
          'supine_cross': two(1, 1),
          'seated_fold': one(2),
          'deep_squat': one(2),
        },
      ));
    }
    if (groups) {
      store.customRoutines.addAll([
        CustomRoutine(
          id: 'c_20261019_8f3a',
          name: '下班腿后侧',
          steps: const [
            CustomStep('n-pelvis-circle'),
            CustomStep('o-seated-ham', seconds: 45),
            CustomStep('s-seated-fold'),
            CustomStep('n-half-split'),
            CustomStep('h-knee-hug'),
            CustomStep('n-leg-circles', sets: 2),
          ],
        ),
        const CustomRoutine(
          id: 'c_20261019_1b20',
          name: '早上醒髋',
          restSeconds: 10,
          steps: [
            CustomStep('n-leg-circles'),
            CustomStep('h-adductor-rock'),
            CustomStep('s-kneel-hipflex'),
            CustomStep('h-squat'),
          ],
        ),
        copyRoutine(
          content.routine('F'),
          content,
          id: 'c_20261019_77aa',
          name: '练风车前',
          at: _now,
        ).copyWith(restSeconds: 20),
      ]);
    }
    await tester.pumpWidget(
      RepaintBoundary(child: HipApp(store: store, videoEnabled: false)),
    );
    await settle(tester);
    return store;
  }

  final screens = <String, Future<void> Function(WidgetTester, String)>{
    '01-practice-untested': (t, theme) async {
      await boot(t, theme, tested: false, groups: false);
      await tap(t, 'tab-1');
    },
    '02-practice-tested': (t, theme) async {
      await boot(t, theme);
      await tap(t, 'tab-1');
    },
    '03-actions': (t, theme) async {
      await boot(t, theme);
      await tap(t, 'tab-1');
      await tap(t, 'lib-dir-extension');
      await t.drag(
        find.byKey(const ValueKey('practice-list')),
        const Offset(0, -260),
      );
      await settle(t);
    },
    '04-detail': (t, theme) async {
      await boot(t, theme);
      await tap(t, 'tab-1');
      await tap(t, 'lib-dir-extension');
      await tap(t, 'drill-card-s-kneel-hipflex');
      await t.tap(find.byKey(const ValueKey('dose-sets-up')));
      await settle(t);
    },
    '05-single-player': (t, theme) async {
      await boot(t, theme);
      await tap(t, 'tab-1');
      await tap(t, 'lib-dir-extension');
      await tap(t, 'drill-card-s-kneel-hipflex');
      await t.tap(find.byKey(const ValueKey('detail-start')));
      for (var i = 0; i < 12; i++) {
        await t.pump(const Duration(milliseconds: 250));
      }
    },
    '06-routines': (t, theme) async {
      await boot(t, theme);
      await tap(t, 'tab-1');
      await tap(t, 'practice-1');
    },
    '07-routine-detail': (t, theme) async {
      await boot(t, theme);
      await tap(t, 'tab-1');
      await tap(t, 'practice-1');
      await t.scrollUntilVisible(
        find.byKey(const ValueKey('routine-card-F')),
        300,
        scrollable: find
            .descendant(
              of: find.byKey(const ValueKey('practice-list')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tap(t, 'routine-card-F');
    },
    '08-mine': (t, theme) async {
      await boot(t, theme);
      await tap(t, 'tab-1');
      await tap(t, 'practice-2');
    },
    '09-editor': (t, theme) async {
      await boot(t, theme);
      await tap(t, 'tab-1');
      await tap(t, 'practice-2');
      await tap(t, 'group-card-c_20261019_8f3a');
    },
    '10-picker': (t, theme) async {
      await boot(t, theme);
      await tap(t, 'tab-1');
      await tap(t, 'practice-2');
      await tap(t, 'group-card-c_20261019_8f3a');
      await tap(t, 'editor-add');
      for (final id in [
        'h-9090-liftoff',
        'h-adductor-rock',
        'h-band-leg-out',
      ]) {
        await tap(t, 'pick-$id');
      }
    },
    '11-home': (t, theme) async {
      await boot(t, theme);
    },
    '12-home-groups': (t, theme) async {
      await boot(t, theme);
      await t.drag(find.byType(Scrollable).first, const Offset(0, -400));
      await settle(t);
    },
  };

  for (final theme in ['dark', 'light']) {
    for (final e in screens.entries) {
      if (_only != null && !e.key.startsWith(_only!)) continue;
      testWidgets('$theme ${e.key}', (tester) async {
        await e.value(tester, theme);
        await precache(tester);
        await tester.runAsync(() async {
          final boundary =
              find.byType(RepaintBoundary).first.evaluate().first.renderObject!
                  as RenderRepaintBoundary;
          final image = await boundary.toImage(pixelRatio: 3);
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          File('$_out/$theme/${e.key}.png')
            ..createSync(recursive: true)
            ..writeAsBytesSync(data!.buffer.asUint8List());
        });
        // Leave nothing running (player timers) before the next test.
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 1));
        HipColors.palette = HipPalette.dark;
      });
    }
  }
}

Future<void> settle(WidgetTester t) async {
  for (var i = 0; i < 8; i++) {
    await t.pump(const Duration(milliseconds: 120));
  }
}

Future<void> tap(WidgetTester t, String key) async {
  final f = find.byKey(ValueKey(key));
  // Cards may sit under the tab bar: bring them up first. Controls that
  // are on screen are tapped where they are (no scroll in the shot).
  if (key.startsWith('drill-card') || key.startsWith('routine-card')) {
    await t.ensureVisible(f);
    await settle(t);
  }
  await t.tap(f);
  await settle(t);
}

Future<void> precache(WidgetTester tester) async {
  for (var i = 0; i < 2; i++) {
    await tester.runAsync(() async {
      for (final el in find.byType(Image).evaluate()) {
        await precacheImage((el.widget as Image).image, el);
      }
    });
    await tester.pump(const Duration(milliseconds: 400));
  }
}
