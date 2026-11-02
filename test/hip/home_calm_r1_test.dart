// Home redesign r1 (开哥 2026-11-02): scene by time of day, one routine with
// 「换一套」, a small 打卡 chip, the dock's 更多 → 「更多」 with AI first (gated).
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiplab/hip/coach/coach_config.dart';
import 'package:hiplab/hip/coach/hip_coach_chat.dart';
import 'package:hiplab/hip/control/hip_store.dart';
import 'package:hiplab/hip/domain/hip_models.dart';
import 'package:hiplab/hip/domain/hip_pain.dart';
import 'package:hiplab/hip/ui/hip_app.dart';
import 'package:hiplab/hip/ui/hip_theme.dart';

import 'hip_domain_test.dart' show MemoryStorage, loadContent;
import 'home_nav.dart';
import 'public_media_fixture.dart';

void main() {
  final content = loadContent();

  group('scene by time of day', () {
    test('weekday daytime is 办公, evenings and weekends 居家', () {
      // 2026-11-02 is a Monday.
      expect(
        HipStore.sceneForTime(DateTime(2026, 11, 2, 14, 15)),
        HipScene.chair,
      );
      expect(
        HipStore.sceneForTime(DateTime(2026, 11, 2, 21, 40)),
        HipScene.home,
      );
      expect(
        HipStore.sceneForTime(DateTime(2026, 11, 2, 6, 30)),
        HipScene.home,
      );
      expect(
        HipStore.sceneForTime(DateTime(2026, 11, 7, 14, 0)),
        HipScene.home,
      );
    });

    test('a hand choice holds for the day and is saved', () async {
      var now = DateTime(2026, 11, 2, 14, 15);
      final disk = MemoryStorage();
      final store = HipStore(content: content, storage: disk, clock: () => now);
      store.applyTimeScene();
      expect(store.scene, HipScene.chair);
      await store.pickScene(HipScene.home);
      store.applyTimeScene();
      expect(store.scene, HipScene.home, reason: 'same day keeps the choice');

      final reopened = HipStore(
        content: content,
        storage: disk,
        clock: () => now,
      );
      await reopened.initialize();
      reopened.applyTimeScene();
      expect(reopened.scene, HipScene.home, reason: 'persisted');

      now = DateTime(2026, 11, 3, 10, 0);
      reopened.applyTimeScene();
      expect(reopened.scene, HipScene.chair, reason: 'next day: by time');
    });

    test('each scene offers its routines; 办公 rotates to the chair set', () {
      final store = HipStore(content: content, storage: MemoryStorage())
        ..identity = HipIdentity.office;
      expect(store.sceneRoutines(HipScene.chair).map((r) => r.id), ['A', 'M']);
      final home = store.sceneRoutines(HipScene.home).map((r) => r.id);
      expect(home, containsAll(['B', 'C', 'D', 'E']));
      expect(home, isNot(contains('F')), reason: 'Breaking only for dancers');
    });
  });

  Future<HipStore> pumpHome(
    WidgetTester tester, {
    HipThemeChoice theme = HipThemeChoice.dark,
    HipScene scene = HipScene.chair,
    DateTime? at,
    HipCoachChat? Function(HipStore)? coach,
    void Function(HipStore)? setup,
  }) async {
    tester.view.physicalSize = const Size(780, 1688);
    tester.view.devicePixelRatio = 2;
    tester.view.padding = const FakeViewPadding(top: 94, bottom: 68);
    addTearDown(tester.view.reset);
    final time = at ?? DateTime(2026, 11, 2, 14, 15);
    final store = HipStore(
      content: content,
      storage: MemoryStorage(),
      clock: () => time,
    );
    await store.initialize();
    store
      ..safety = {'pregnancy': false, 'surgery': false, 'acute': false}
      ..identity = HipIdentity.office
      ..scene = scene
      ..theme = theme
      ..doneDays.addAll(['2026-11-01', '2026-10-31', '2026-10-30']);
    setup?.call(store);
    await tester.pumpWidget(
      RepaintBoundary(
        key: _shot,
        child: HipApp(
          store: store,
          mediaPolicy: installPublicMediaFixture().policy,
          videoEnabled: false,
          coach: coach?.call(store),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return store;
  }

  testWidgets('home: no tab bar, one start, small streak chip, 换一套', (
    tester,
  ) async {
    final store = await pumpHome(tester, scene: HipScene.home);
    expect(find.byKey(const ValueKey('tab-0')), findsNothing);
    expect(find.byKey(const ValueKey('minutes-5')), findsNothing);
    expect(find.byKey(const ValueKey('start-today')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('home-streak')),
        matching: find.text('${store.streak} 天'),
      ),
      findsOneWidget,
    );
    String title() =>
        tester.widget<Text>(find.byKey(const ValueKey('home-title'))).data!;
    final first = title();
    await tester.tap(find.byKey(const ValueKey('home-rotate')));
    await tester.pumpAndSettle();
    expect(title(), isNot(first));
    expect(tester.takeException(), isNull);
  });

  testWidgets('更多: rows in order; AI card only when available', (tester) async {
    await pumpHome(tester);
    await openMore(tester);
    expect(find.byKey(const ValueKey('more-ai-coach')), findsNothing);
    double y(String k) => tester.getTopLeft(find.byKey(ValueKey(k))).dy;
    expect(y('more-groups'), lessThan(y('more-practice')));
    expect(y('more-practice'), lessThan(y('more-checkup')));
    expect(y('more-checkup'), lessThan(y('more-records')));
    expect(y('more-records'), lessThan(y('more-settings')));
    await openRecords(tester);
    expect(find.byKey(const ValueKey('reminder-switch')), findsNothing);
    await openSettings(tester);
    expect(find.byKey(const ValueKey('reminder-switch')), findsOneWidget);
  });

  testWidgets('更多: configured coach puts AI on top', (tester) async {
    await pumpHome(
      tester,
      coach: (s) => HipCoachChat(
        store: s,
        config: const CoachConfig(appKey: 'test'),
      ),
    );
    await openMore(tester);
    final ai = find.byKey(const ValueKey('more-ai-coach'));
    expect(ai, findsOneWidget);
    expect(
      tester.getTopLeft(ai).dy,
      lessThan(tester.getTopLeft(find.byKey(const ValueKey('more-groups'))).dy),
    );
  });

  testWidgets('home keeps numbness and multiple lock alerts reachable', (
    tester,
  ) async {
    final store = await pumpHome(
      tester,
      setup: (store) {
        store.askNumbness = true;
        for (final direction in HipDirection.values) {
          store.painEvents.addAll([
            PainEvent(
              store.now().subtract(const Duration(days: 1)),
              direction,
              'skip',
            ),
            PainEvent(store.now(), direction, 'skip'),
          ]);
        }
      },
    );
    expect(store.lockedDirections, hasLength(6));
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('现在还麻吗？'));
    await tester.pumpAndSettle();
    expect(find.text('现在还麻吗？').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.byKey(const ValueKey('home-more')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('home-more')).hitTestable(),
      findsOneWidget,
    );
  });

  // Verification screenshots (not goldens): written only when
  // HIPLAB_SHOTS=<dir> is set, e.g.
  // HIPLAB_SHOTS=/tmp/shots flutter test test/hip/home_calm_r1_test.dart
  final shots = Platform.environment['HIPLAB_SHOTS'];
  group('screenshots', () {
    setUpAll(() async {
      final font = FontLoader(hipFontFamily)
        ..addFont(rootBundle.load('assets/fonts/NotoSansSC.ttf'));
      await font.load();
      // flutter_tester draws BoxShadow without blur (hard shelves).
      HipColors.flatShadows = true;
    });
    tearDownAll(() => HipColors.flatShadows = false);

    testWidgets('1 home office dark', (tester) async {
      await pumpHome(tester);
      await _capture(tester, '$shots/home-office-dark.png');
    });
    testWidgets('2 home 居家 light', (tester) async {
      await pumpHome(
        tester,
        theme: HipThemeChoice.light,
        scene: HipScene.home,
        at: DateTime(2026, 11, 2, 21, 40),
      );
      await _capture(tester, '$shots/home-home-light.png');
    });
    testWidgets('3 更多 dark', (tester) async {
      await pumpHome(
        tester,
        coach: (s) => HipCoachChat(
          store: s,
          config: const CoachConfig(appKey: 'test'),
        ),
      );
      await openMore(tester);
      await _capture(tester, '$shots/more-dark.png');
    });
    testWidgets('4 更多 light', (tester) async {
      await pumpHome(
        tester,
        theme: HipThemeChoice.light,
        scene: HipScene.home,
        at: DateTime(2026, 11, 2, 21, 40),
        coach: (s) => HipCoachChat(
          store: s,
          config: const CoachConfig(appKey: 'test'),
        ),
      );
      await openMore(tester);
      await _capture(tester, '$shots/more-light.png');
    });
    testWidgets('5 练习 dark', (tester) async {
      await pumpHome(tester);
      await openPractice(tester);
      await _capture(tester, '$shots/practice-dark.png');
    });
    testWidgets('6 套路详情 dark', (tester) async {
      await pumpHome(tester);
      await openPractice(tester);
      await tester.tap(find.byKey(const ValueKey('practice-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('routine-card-A')));
      await tester.pumpAndSettle();
      await _capture(tester, '$shots/routine-dark.png');
    });
    testWidgets('7 设置 dark', (tester) async {
      await pumpHome(tester);
      await openSettings(tester);
      await _capture(tester, '$shots/settings-dark.png');
    });
    testWidgets('8 训练记录 dark', (tester) async {
      await pumpHome(tester);
      await openRecords(tester);
      await _capture(tester, '$shots/records-dark.png');
    });
    testWidgets('9 自测 start dark', (tester) async {
      await pumpHome(tester);
      await openMore(tester);
      await tester.tap(find.byKey(const ValueKey('more-checkup')));
      await tester.pumpAndSettle();
      await _capture(tester, '$shots/checkup-dark.png');
    });
    testWidgets('10 自测结果 dark', (tester) async {
      await pumpHome(tester);
      await openMore(tester);
      await tester.tap(find.byKey(const ValueKey('more-checkup')));
      await tester.pumpAndSettle();
      for (var n = 0; n < 14; n++) {
        if (find.text('你的髋部').evaluate().isNotEmpty) break;
        final f = find.byKey(ValueKey('option-${n.isEven ? 1 : 2}'));
        await tester.ensureVisible(f);
        await tester.pumpAndSettle();
        await tester.tap(f);
        await tester.pump();
        await tester.tap(find.byKey(const ValueKey('assessment-next')));
        await tester.pumpAndSettle();
      }
      await _capture(tester, '$shots/result-dark.png');
    });
    testWidgets('12 自测 intro dark', (tester) async {
      await pumpHome(tester);
      await openPractice(tester);
      await tester.tap(find.byKey(const ValueKey('hip-check-card')));
      await tester.pumpAndSettle();
      await _capture(tester, '$shots/intro-dark.png');
    });
    testWidgets('11 设置 light', (tester) async {
      await pumpHome(
        tester,
        theme: HipThemeChoice.light,
        scene: HipScene.home,
        at: DateTime(2026, 11, 2, 21, 40),
      );
      await openSettings(tester);
      await _capture(tester, '$shots/settings-light.png');
    });
  }, skip: shots == null);
}

final _shot = GlobalKey();

Future<void> _capture(WidgetTester tester, String path) async {
  // Let asset images decode (real IO), then paint them.
  for (var i = 0; i < 4; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 250)),
    );
    await tester.pump();
  }
  await tester.pumpAndSettle();
  await tester.runAsync(() async {
    final boundary =
        _shot.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File(path)..createSync(recursive: true);
    file.writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}
