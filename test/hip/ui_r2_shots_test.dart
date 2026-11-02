// UI r2 verification screenshots (not goldens): 更多 / 设置 / 安全提示 with the
// shared page kit. Written only when HIPLAB_SHOTS=<dir> is set, e.g.
// HIPLAB_SHOTS=/tmp/r2 flutter test --no-pub test/hip/ui_r2_shots_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiplab/hip/control/hip_store.dart';
import 'package:hiplab/hip/domain/hip_library.dart';
import 'package:hiplab/hip/domain/hip_models.dart';
import 'package:hiplab/hip/ui/hip_app.dart';
import 'package:hiplab/hip/ui/hip_theme.dart';

import 'hip_domain_test.dart' show MemoryStorage, loadContent;
import 'home_nav.dart';
import 'public_media_fixture.dart';

final _shot = GlobalKey();

void main() {
  final content = loadContent();
  final shots = Platform.environment['HIPLAB_SHOTS'];

  Future<HipStore> pump(
    WidgetTester tester, {
    HipThemeChoice theme = HipThemeChoice.dark,
    double height = 852,
    bool reminder = true,
    bool groups = false,
  }) async {
    tester.view.physicalSize = Size(393 * 2, height * 2);
    tester.view.devicePixelRatio = 2;
    tester.view.padding = const FakeViewPadding(top: 118, bottom: 68);
    addTearDown(tester.view.reset);
    final time = DateTime(2026, 11, 2, 14, 15);
    final store = HipStore(
      content: content,
      storage: MemoryStorage(),
      clock: () => time,
    );
    await store.initialize();
    store
      ..safety = {'pregnancy': false, 'surgery': false, 'acute': false}
      ..identity = HipIdentity.office
      ..scene = HipScene.chair
      ..theme = theme
      ..doneDays.addAll(['2026-11-01', '2026-10-31', '2026-10-30']);
    if (reminder) {
      store.reminder = store.reminder.copyWith(enabled: true);
    }
    if (groups) {
      // M2: 2–3 seeded groups for 训练组 我的.
      final rs = content.routines;
      for (final (i, name) in ['下班放松', '舞前开胯', '睡前十分钟'].indexed) {
        final r = rs[i % rs.length];
        store.customRoutines.add(
          CustomRoutine(
            id: 'c_${i + 1}',
            name: name,
            fromRoutine: i == 1 ? r.id : null,
            steps: [
              for (final st in r.steps.take(i == 2 ? 3 : 8))
                CustomStep(st.drillId),
            ],
          ),
        );
      }
    }
    await tester.pumpWidget(
      RepaintBoundary(
        key: _shot,
        child: HipApp(
          store: store,
          mediaPolicy: installPublicMediaFixture().policy,
          videoEnabled: false,
        ),
      ),
    );
    await tester.pumpAndSettle();
    return store;
  }

  group('ui r2 screenshots', () {
    setUpAll(() async {
      final font = FontLoader(hipFontFamily)
        ..addFont(rootBundle.load('assets/fonts/NotoSansSC.ttf'));
      await font.load();
      HipColors.flatShadows = true;
    });
    tearDownAll(() => HipColors.flatShadows = false);

    for (final t in [HipThemeChoice.dark, HipThemeChoice.light]) {
      final n = t == HipThemeChoice.dark ? 'dark' : 'light';
      testWidgets('更多 $n', (tester) async {
        await pump(tester, theme: t);
        await openMore(tester);
        await _capture(tester, '$shots/more-$n.png');
      });
      testWidgets('设置 $n (full height)', (tester) async {
        await pump(tester, theme: t, height: 1240);
        await openSettings(tester);
        await _capture(tester, '$shots/settings-$n-full.png');
      });
      testWidgets('设置 $n (phone, scrolled)', (tester) async {
        await pump(tester, theme: t);
        await openSettings(tester);
        await tester.drag(find.byType(ListView).first, const Offset(0, -260));
        await tester.pumpAndSettle();
        await _capture(tester, '$shots/settings-$n-scrolled.png');
      });
    }
    // ── M2 ──
    for (final t in [HipThemeChoice.dark, HipThemeChoice.light]) {
      final n = t == HipThemeChoice.dark ? 'dark' : 'light';
      testWidgets('m2 训练组 我的 $n', (tester) async {
        await pump(tester, theme: t, groups: true);
        await openGroups(tester);
        await _capture(tester, '$shots/m2/groups-mine-$n.png');
      });
      testWidgets('m2 添加动作 2 selected $n', (tester) async {
        await pump(tester, theme: t, groups: true);
        await openGroups(tester);
        await tester.tap(find.byKey(const ValueKey('new-group')));
        await tester.pumpAndSettle();
        final cards = find.byWidgetPredicate(
          (w) =>
              w.key is ValueKey<String> &&
              (w.key! as ValueKey<String>).value.startsWith('pick-'),
        );
        await tester.tap(cards.at(0));
        await tester.pump();
        await tester.tap(cards.at(1));
        await tester.pumpAndSettle();
        await _capture(tester, '$shots/m2/picker-$n.png');
      });
    }
    testWidgets('m2 推荐套路 dark', (tester) async {
      await pump(tester);
      await openGroups(tester);
      await tester.tap(find.byKey(const ValueKey('practice-1')));
      await tester.pumpAndSettle();
      await _capture(tester, '$shots/m2/routines-dark.png');
    });
    testWidgets('m2 训练记录 dark', (tester) async {
      await pump(tester);
      await openRecords(tester);
      await _capture(tester, '$shots/m2/records-dark.png');
    });
    testWidgets('m2 自测说明 dark', (tester) async {
      await pump(tester);
      await openMore(tester);
      await tester.tap(find.byKey(const ValueKey('more-checkup')));
      await tester.pumpAndSettle();
      await _capture(tester, '$shots/m2/intro-dark.png');
    });
    testWidgets('m2 套路详情 dark', (tester) async {
      await pump(tester);
      await openGroups(tester);
      await tester.tap(find.byKey(const ValueKey('practice-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('routine-card-A')));
      await tester.pumpAndSettle();
      await _capture(tester, '$shots/m2/routine-dark.png');
    });
    testWidgets('m2 组编辑 dark', (tester) async {
      await pump(tester, groups: true);
      await openGroups(tester);
      await tester.tap(find.byKey(const ValueKey('group-card-c_1')));
      await tester.pumpAndSettle();
      await _capture(tester, '$shots/m2/editor-dark.png');
    });
    testWidgets('m2 安全提示 light', (tester) async {
      await pump(tester, theme: HipThemeChoice.light, height: 1240);
      await openSettings(tester);
      await tester.tap(find.byKey(const ValueKey('safety-review')));
      await tester.pumpAndSettle();
      await tester.binding.setSurfaceSize(null);
      tester.view.physicalSize = const Size(786, 1704);
      await tester.pumpAndSettle();
      await _capture(tester, '$shots/m2/safety-review-light.png');
    });
    testWidgets('安全提示 from 设置 dark', (tester) async {
      await pump(tester, height: 1240);
      await openSettings(tester);
      await tester.tap(find.byKey(const ValueKey('safety-review')));
      await tester.pumpAndSettle();
      await tester.binding.setSurfaceSize(null);
      tester.view.physicalSize = const Size(786, 1704);
      await tester.pumpAndSettle();
      await _capture(tester, '$shots/safety-review-dark.png');
    });
  }, skip: shots == null);
}

Future<void> _capture(WidgetTester tester, String path) async {
  for (var i = 0; i < 4; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 250)),
    );
    await tester.pump();
  }
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
  await tester.runAsync(() async {
    final boundary =
        _shot.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File(path)..createSync(recursive: true);
    file.writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}
