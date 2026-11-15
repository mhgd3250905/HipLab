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
import 'package:hiplab/hip/data/hip_public_catalog.dart';
import 'package:ugk_coach/ugk_coach.dart' as coach;
import 'package:hiplab/hip/domain/hip_library.dart';
import 'package:hiplab/hip/domain/hip_assessment.dart';
import 'package:hiplab/hip/domain/hip_models.dart';
import 'package:hiplab/hip/domain/hip_progress.dart';
import 'package:hiplab/hip/ui/hip_app.dart';
import 'package:hiplab/hip/ui/hip_theme.dart';

import 'hip_domain_test.dart' show MemoryStorage, loadContent;
import 'home_nav.dart';
import 'public_media_fixture.dart';

final _shot = GlobalKey();

void main() {
  final content = loadContent();
  final shots = Platform.environment['HIPLAB_SHOTS'];

  HipContent? publicCache;
  HipContent publicContent() {
    if (publicCache != null) return publicCache!;
    final pack = coach.PoseHubAppTestCatalog.fromBytes(
      File(hipPublicCatalogAsset).readAsBytesSync(),
      semanticCatalogBytes: File(hipPublicSemanticsAsset).readAsBytesSync(),
    );
    final rhythms = hipPublicRhythms(pack);
    return publicCache = content.withPublicTraining(
      hipCoachCatalogFromPublic(pack, rhythms: rhythms),
      rhythms,
    );
  }

  Future<HipStore> pump(
    WidgetTester tester, {
    HipThemeChoice theme = HipThemeChoice.dark,
    double height = 852,
    bool reminder = true,
    bool groups = false,
    bool mixed = false,
    bool public = false,
    bool records = false,
    bool emptyRecords = false,
    bool assessed = false,
    double textScale = 1,
  }) async {
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    tester.view.physicalSize = Size(393 * 2, height * 2);
    tester.view.devicePixelRatio = 2;
    tester.view.padding = const FakeViewPadding(top: 118, bottom: 68);
    addTearDown(tester.view.reset);
    final time = DateTime(2026, 11, 2, 14, 15);
    final store = HipStore(
      content: public ? publicContent() : content,
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
    if (emptyRecords) store.doneDays.clear();
    if (records) {
      // M4: ~20 trained days, current streak 8 (10/26–11/02, so 3 and 7
      // are earned), with timed sessions of varying length.
      final days = <DateTime>[
        for (var d = 1; d <= 5; d++) DateTime(2026, 10, d),
        for (final d in [12, 13, 15, 18, 20, 22, 23]) DateTime(2026, 10, d),
        for (var d = 0; d < 8; d++) DateTime(2026, 10, 26 + d),
      ];
      final titles = ['久坐舒展', '下班放松', '舞前开胯', '睡前十分钟'];
      store.doneDays
        ..clear()
        ..addAll([for (final d in days) dayKey(d)]);
      for (final (i, d) in days.indexed) {
        store.sessions.add(
          SessionRecord(
            at: DateTime(d.year, d.month, d.day, 8 + i % 12, 10 + i % 40),
            source: PlanSource.recommended,
            title: titles[i % titles.length],
            seconds: [180, 420, 600, 900, 1500][i % 5],
            completed: true,
          ),
        );
      }
    }
    if (assessed) {
      ItemAnswer one(int s) => ItemAnswer.single(SideAnswer.choice(s));
      ItemAnswer two(int l, int r) => ItemAnswer.sided(
        left: SideAnswer.choice(l),
        right: SideAnswer.choice(r),
      );
      store.assessments.add((
        at: DateTime(2026, 10, 28, 20, 5),
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
    if (mixed) {
      // M6: a mixed group — SDK-only actions with local kit drills.
      final c = store.content;
      final sdk = [
        for (final d in c.publicCatalog!.drills)
          if (isSdkGroupStep(c, d.id)) d.id,
      ];
      store.customRoutines.insert(
        0,
        CustomRoutine(
          id: 'c_mix',
          name: '全身混合',
          restSeconds: 20,
          steps: [
            CustomStep(sdk[0]),
            const CustomStep('h-9090-liftoff'),
            CustomStep(sdk[5]),
            CustomStep(sdk[12]),
            const CustomStep('h-adductor-rock'),
          ],
        ),
      );
    }
    await tester.pumpWidget(
      RepaintBoundary(
        key: _shot,
        child: HipApp(
          store: store,
          mediaPolicy: installPublicMediaFixture(sharedLibrary: public).policy,
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
    // ── M3 动作库 + 统一筛选 ──
    for (final t in [HipThemeChoice.dark, HipThemeChoice.light]) {
      final n = t == HipThemeChoice.dark ? 'dark' : 'light';
      testWidgets('m3 动作库 top $n', (tester) async {
        await pump(tester, theme: t, public: true);
        await openPractice(tester);
        await _capture(tester, '$shots/m3/library-$n.png');
      });
      testWidgets('m3 筛选 sheet $n', (tester) async {
        await pump(tester, theme: t, public: true);
        await openPractice(tester);
        await tester.tap(find.byKey(const ValueKey('action-part-大腿后侧')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('action-filter')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('filter-part-髋前侧')));
        await tester.pumpAndSettle();
        await _capture(tester, '$shots/m3/sheet-$n.png');
        await tester.ensureVisible(
          find.byKey(const ValueKey('filter-type-拉伸放松')),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('filter-type-拉伸放松')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('filter-apply')));
        await tester.pumpAndSettle();
        await _capture(tester, '$shots/m3/filtered-$n.png');
      });
      testWidgets('m3 添加动作 all $n', (tester) async {
        await pump(tester, theme: t, groups: true, public: true);
        await openGroups(tester);
        await tester.tap(find.byKey(const ValueKey('new-group')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('action-part-臀部')));
        await tester.pumpAndSettle();
        await _capture(tester, '$shots/m3/picker-$n.png');
      });
    }
    // ── M6 训练组支持全部 SDK 动作 ──
    testWidgets('m6 添加动作 SDK selectable dark', (tester) async {
      await pump(tester, groups: true, public: true);
      await openGroups(tester);
      await tester.tap(find.byKey(const ValueKey('new-group')));
      await tester.pumpAndSettle();
      final c = publicContent();
      final ids = [
        for (final d in c.publicCatalog!.drills)
          if (isSdkGroupStep(c, d.id)) d.id,
      ];
      await tester.tap(find.byKey(const ValueKey('action-part-臀部')));
      await tester.pumpAndSettle();
      final cards = find.byWidgetPredicate(
        (w) =>
            w.key is ValueKey<String> &&
            ids.contains(
              (w.key! as ValueKey<String>).value.replaceFirst('pick-', ''),
            ) &&
            (w.key! as ValueKey<String>).value.startsWith('pick-'),
      );
      await tester.tap(cards.at(0));
      await tester.pump();
      await tester.tap(cards.at(1));
      await tester.pumpAndSettle();
      await _capture(tester, '$shots/m6/picker-dark.png');
    });
    testWidgets('m6 组编辑 mixed dark', (tester) async {
      await pump(tester, groups: true, mixed: true, public: true);
      await openGroups(tester);
      await tester.tap(find.byKey(const ValueKey('group-card-c_mix')));
      await tester.pumpAndSettle();
      await _capture(tester, '$shots/m6/editor-dark.png');
    });
    testWidgets('m6 训练组 card dark', (tester) async {
      await pump(tester, groups: true, mixed: true, public: true);
      await openGroups(tester);
      await _capture(tester, '$shots/m6/groups-dark.png');
    });
    // ── M4 训练记录 + 自测雷达 ──
    for (final t in [HipThemeChoice.dark, HipThemeChoice.light]) {
      final n = t == HipThemeChoice.dark ? 'dark' : 'light';
      testWidgets('m4 训练记录 $n', (tester) async {
        await pump(tester, theme: t, records: true, height: 1500);
        await openRecords(tester);
        await _capture(tester, '$shots/m4/records-$n.png');
      });
      testWidgets('m4 训练记录 empty $n', (tester) async {
        await pump(tester, theme: t, emptyRecords: true);
        await openRecords(tester);
        await _capture(tester, '$shots/m4/records-empty-$n.png');
      });
      testWidgets('m4 自测说明 radar $n', (tester) async {
        await pump(tester, theme: t, assessed: true, height: 1100);
        await openMore(tester);
        await tester.tap(find.byKey(const ValueKey('more-checkup')));
        await tester.pumpAndSettle();
        await _capture(tester, '$shots/m4/intro-radar-$n.png');
      });
    }
    testWidgets('m4 自测说明 radar 1.5x', (tester) async {
      await pump(tester, assessed: true, height: 1100, textScale: 1.5);
      await openMore(tester);
      await tester.tap(find.byKey(const ValueKey('more-checkup')));
      await tester.pumpAndSettle();
      await _capture(tester, '$shots/m4/intro-radar-dark-1.5x.png');
    });
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
    // ── M5 final: every changed page, dark + light; 1.5× overflow pass ──
    for (final t in [HipThemeChoice.dark, HipThemeChoice.light]) {
      final n = t == HipThemeChoice.dark ? 'dark' : 'light';
      final dir = '$shots/final';
      testWidgets('final 更多 $n', (tester) async {
        await pump(tester, theme: t);
        await openMore(tester);
        await _capture(tester, '$dir/more-$n.png');
      });
      testWidgets('final 设置 $n', (tester) async {
        await pump(tester, theme: t);
        await openSettings(tester);
        await _capture(tester, '$dir/settings-$n.png');
      });
      testWidgets('final 训练组 $n', (tester) async {
        await pump(tester, theme: t, groups: true);
        await openGroups(tester);
        await _capture(tester, '$dir/groups-$n.png');
      });
      testWidgets('final 组编辑 $n', (tester) async {
        await pump(tester, theme: t, groups: true);
        await openGroups(tester);
        await tester.tap(find.byKey(const ValueKey('group-card-c_1')));
        await tester.pumpAndSettle();
        await _capture(tester, '$dir/editor-$n.png');
      });
      testWidgets('final 添加动作 $n', (tester) async {
        await pump(tester, theme: t, groups: true, public: true);
        await openGroups(tester);
        await tester.tap(find.byKey(const ValueKey('new-group')));
        await tester.pumpAndSettle();
        await _capture(tester, '$dir/picker-empty-$n.png');
      });
      testWidgets('final 动作库 $n', (tester) async {
        await pump(tester, theme: t, public: true);
        await openPractice(tester);
        await _capture(tester, '$dir/library-$n.png');
      });
      testWidgets('final 套路详情 $n', (tester) async {
        await pump(tester, theme: t);
        await openGroups(tester);
        await tester.tap(find.byKey(const ValueKey('practice-1')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('routine-card-A')));
        await tester.pumpAndSettle();
        await _capture(tester, '$dir/routine-$n.png');
      });
      testWidgets('final 训练记录 empty $n', (tester) async {
        await pump(tester, theme: t, emptyRecords: true);
        await openRecords(tester);
        await _capture(tester, '$dir/records-empty-$n.png');
      });
      testWidgets('final 自测说明 $n', (tester) async {
        await pump(tester, theme: t, assessed: true);
        await openMore(tester);
        await tester.tap(find.byKey(const ValueKey('more-checkup')));
        await tester.pumpAndSettle();
        await _capture(tester, '$dir/intro-$n.png');
      });
    }
    final scaled = <String, Future<void> Function(WidgetTester)>{
      'more': openMore,
      'settings': openSettings,
      'library': openPractice,
      'records': openRecords,
    };
    for (final MapEntry(key: name, value: open) in scaled.entries) {
      testWidgets('final 1.5x $name', (tester) async {
        await pump(tester, public: name == 'library', textScale: 1.5);
        await open(tester);
        await _capture(tester, '$shots/final/x15-$name-dark.png');
      });
    }
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
