import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiplab/hip/ui/hip_icons.dart';
import 'package:hiplab/hip/ui/hip_page_kit.dart';
import 'package:hiplab/hip/ui/hip_row_icons.dart';
import 'package:hiplab/hip/ui/hip_theme.dart';
import 'package:hiplab/hip/ui/hip_widgets.dart';

const _shot = ValueKey('row-icons-component-shot');
const _labels = <HipRowSymbol, String>{
  HipRowSymbol.groups: '我的训练组',
  HipRowSymbol.library: '动作库',
  HipRowSymbol.assessment: '髋部自测',
  HipRowSymbol.records: '训练记录',
  HipRowSymbol.settings: '设置',
  HipRowSymbol.reminder: '练习提醒',
  HipRowSymbol.chair: '椅边练习',
  HipRowSymbol.voice: '语音',
  HipRowSymbol.sound: '训练提示音',
  HipRowSymbol.language: '语言',
  HipRowSymbol.volume: '音量',
  HipRowSymbol.appearance: '外观',
  HipRowSymbol.safety: '安全提示',
  HipRowSymbol.privacy: '隐私政策',
  HipRowSymbol.addGroup: '新建训练组',
  HipRowSymbol.coach: 'AI教练',
  HipRowSymbol.completed: '已完成',
  HipRowSymbol.paused: '已暂停',
};

Widget _board() => Padding(
  padding: const EdgeInsets.all(24),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'HipLab · 行前图标',
        style: TextStyle(
          color: HipColors.text,
          fontSize: 24,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 6),
      Text(
        '70 展示尺寸 / 30 实际尺寸 · 组件渲染',
        style: TextStyle(color: HipColors.muted, fontSize: 12),
      ),
      const SizedBox(height: 28),
      Wrap(
        spacing: 12,
        runSpacing: 22,
        children: [
          for (final symbol in HipRowSymbol.values)
            SizedBox(
              width: 132,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      HipRowEmblem(symbol: symbol, size: 70),
                      const SizedBox(width: 12),
                      HipRowEmblem(symbol: symbol),
                    ],
                  ),
                  const SizedBox(height: 9),
                  Text(
                    _labels[symbol]!,
                    style: TextStyle(color: HipColors.text, fontSize: 12),
                  ),
                ],
              ),
            ),
        ],
      ),
    ],
  ),
);

Widget _listExamples() => Padding(
  padding: const EdgeInsets.all(20),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        '条目示例 · 更多／设置',
        style: TextStyle(
          color: HipColors.text,
          fontSize: 23,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 20),
      HipListGroup(
        children: [
          HipListRow(title: '我的训练组', glyph: HipGlyph.grip, onTap: () {}),
          HipListRow(title: '动作库', glyph: HipGlyph.library, onTap: () {}),
          HipListRow(title: '髋部自测', glyph: HipGlyph.radar, onTap: () {}),
          HipListRow(title: '训练记录', glyph: HipGlyph.progress, onTap: () {}),
          HipListRow(
            title: '设置',
            glyph: HipGlyph.contrast,
            rowSymbol: HipRowSymbol.settings,
            onTap: () {},
          ),
        ],
      ),
      const SizedBox(height: 28),
      HipListGroup(
        children: [
          HipListRow(title: '练习提醒', glyph: HipGlyph.bell, onTap: () {}),
          HipListRow(title: '椅边练习', glyph: HipGlyph.chair, onTap: () {}),
          HipListRow(title: '语音', glyph: HipGlyph.voice, onTap: () {}),
          HipListRow(title: '训练提示音', glyph: HipGlyph.today, onTap: () {}),
          HipListRow(title: '语言', glyph: HipGlyph.subtitles, onTap: () {}),
          HipListRow(title: '外观', glyph: HipGlyph.contrast, onTap: () {}),
          HipListRow(title: '安全提示', glyph: HipGlyph.shield, onTap: () {}),
          HipListRow(title: '隐私政策', glyph: HipGlyph.clipboard, onTap: () {}),
        ],
      ),
    ],
  ),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final artifact = Platform.environment['HIPLAB_ROW_ICON_ARTIFACT_DIR'];

  setUpAll(() async {
    if (artifact != null) {
      final font = FontLoader(hipFontFamily)
        ..addFont(rootBundle.load('assets/fonts/NotoSansSC.ttf'));
      await font.load();
    }
  });

  setUp(() {
    final previous = HipColors.palette;
    addTearDown(() => HipColors.palette = previous);
  });

  Future<void> mount(
    WidgetTester tester,
    Widget child, {
    HipPalette palette = HipPalette.dark,
    Size size = const Size(480, 900),
  }) async {
    tester.view
      ..physicalSize = size
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    HipColors.palette = palette;
    await tester.pumpWidget(
      RepaintBoundary(
        key: _shot,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: hipTheme(palette),
          themeAnimationDuration: Duration.zero,
          home: Scaffold(backgroundColor: palette.background, body: child),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<List<int>> pixels(WidgetTester tester, Key key) async =>
      (await tester.runAsync(() async {
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(key),
        );
        final image = await boundary.toImage(pixelRatio: 3);
        final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
        final result = List<int>.of(data!.buffer.asUint8List());
        image.dispose();
        return result;
      }))!;

  int differentPixels(List<int> a, List<int> b) {
    expect(a.length, b.length);
    var count = 0;
    for (var index = 0; index < a.length; index += 4) {
      final delta =
          (a[index] - b[index]).abs() +
          (a[index + 1] - b[index + 1]).abs() +
          (a[index + 2] - b[index + 2]).abs() +
          (a[index + 3] - b[index + 3]).abs();
      if (delta > 8) count++;
    }
    return count;
  }

  Future<void> export(WidgetTester tester, String name) async {
    if (artifact == null) return;
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(_shot),
    );
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      Directory(artifact).createSync(recursive: true);
      File('$artifact/$name.png').writeAsBytesSync(data!.buffer.asUint8List());
      image.dispose();
    });
  }

  testWidgets(
    'all eighteen roles paint statically at the existing thirty point size in both themes',
    (tester) async {
      expect(HipRowSymbol.values.length, 18);
      for (final palette in [HipPalette.dark, HipPalette.light]) {
        await mount(
          tester,
          Center(
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final symbol in HipRowSymbol.values)
                  HipRowEmblem(key: ValueKey(symbol), symbol: symbol),
              ],
            ),
          ),
          palette: palette,
        );
        for (final symbol in HipRowSymbol.values) {
          expect(
            tester.getSize(find.byKey(ValueKey(symbol))),
            const Size.square(30),
          );
        }
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is CustomPaint && widget.painter is HipRowEmblemPainter,
          ),
          findsNWidgets(18),
        );
        expect(find.byType(Image), findsNothing);
        expect(find.byType(Texture), findsNothing);
        expect(find.byType(BackdropFilter), findsNothing);
        expect(tester.binding.transientCallbackCount, 0);
        await tester.pump(const Duration(seconds: 1));
        expect(tester.binding.transientCallbackCount, 0);
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets(
    'core meanings and settings versus appearance have distinct rendered pixels',
    (tester) async {
      const symbols = [
        HipRowSymbol.groups,
        HipRowSymbol.library,
        HipRowSymbol.assessment,
        HipRowSymbol.settings,
        HipRowSymbol.appearance,
      ];
      final rendered = <HipPalette, Map<HipRowSymbol, List<int>>>{};
      for (final palette in [HipPalette.dark, HipPalette.light]) {
        await mount(
          tester,
          Center(
            child: Wrap(
              spacing: 12,
              children: [
                for (final symbol in symbols)
                  RepaintBoundary(
                    key: ValueKey(symbol),
                    child: HipRowEmblem(symbol: symbol),
                  ),
              ],
            ),
          ),
          palette: palette,
        );
        final captures = <HipRowSymbol, List<int>>{};
        for (final symbol in symbols) {
          captures[symbol] = await pixels(tester, ValueKey(symbol));
        }
        rendered[palette] = captures;
        for (final pair in [
          (HipRowSymbol.groups, HipRowSymbol.library),
          (HipRowSymbol.groups, HipRowSymbol.assessment),
          (HipRowSymbol.library, HipRowSymbol.assessment),
          (HipRowSymbol.settings, HipRowSymbol.appearance),
        ]) {
          final changed = differentPixels(
            captures[pair.$1]!,
            captures[pair.$2]!,
          );
          debugPrint(
            'row-icon-diff ${palette == HipPalette.dark ? 'dark' : 'light'} '
            '${pair.$1.name}/${pair.$2.name}: $changed pixels',
          );
          expect(
            changed,
            greaterThan(24),
            reason: '${pair.$1} and ${pair.$2} must convey distinct objects',
          );
        }
        expect(tester.takeException(), isNull);
      }
      expect(
        differentPixels(
          rendered[HipPalette.dark]![HipRowSymbol.groups]!,
          rendered[HipPalette.light]![HipRowSymbol.groups]!,
        ),
        greaterThan(24),
        reason: 'the emblem must respond to the host theme',
      );
    },
  );

  testWidgets(
    'row glyph defaults map centrally and explicit settings does not reuse appearance',
    (tester) async {
      const mapping = <HipGlyph, HipRowSymbol>{
        HipGlyph.grip: HipRowSymbol.groups,
        HipGlyph.library: HipRowSymbol.library,
        HipGlyph.radar: HipRowSymbol.assessment,
        HipGlyph.progress: HipRowSymbol.records,
        HipGlyph.contrast: HipRowSymbol.appearance,
        HipGlyph.bell: HipRowSymbol.reminder,
        HipGlyph.chair: HipRowSymbol.chair,
        HipGlyph.voice: HipRowSymbol.voice,
        HipGlyph.today: HipRowSymbol.sound,
        HipGlyph.subtitles: HipRowSymbol.language,
        HipGlyph.volume: HipRowSymbol.volume,
        HipGlyph.shield: HipRowSymbol.safety,
        HipGlyph.clipboard: HipRowSymbol.privacy,
        HipGlyph.plus: HipRowSymbol.addGroup,
        HipGlyph.bolt: HipRowSymbol.coach,
        HipGlyph.checkCircle: HipRowSymbol.completed,
        HipGlyph.pause: HipRowSymbol.paused,
      };
      await mount(
        tester,
        Wrap(
          spacing: 8,
          children: [
            for (final glyph in mapping.keys)
              HipRowIcon(glyph, key: ValueKey(glyph)),
            const HipRowIcon(
              HipGlyph.contrast,
              key: ValueKey('explicit-settings'),
              symbol: HipRowSymbol.settings,
            ),
            const HipRowIcon(HipGlyph.flame, key: ValueKey('fallback-flame')),
          ],
        ),
      );
      for (final entry in mapping.entries) {
        final wrapper = find.byKey(ValueKey(entry.key));
        final emblem = find.descendant(
          of: wrapper,
          matching: find.byType(HipRowEmblem),
        );
        expect(tester.widget<HipRowEmblem>(emblem).symbol, entry.value);
        expect(tester.getSize(wrapper), const Size.square(30));
      }
      expect(
        tester
            .widget<HipRowEmblem>(
              find.descendant(
                of: find.byKey(const ValueKey('explicit-settings')),
                matching: find.byType(HipRowEmblem),
              ),
            )
            .symbol,
        HipRowSymbol.settings,
      );
      final fallback = find.byKey(const ValueKey('fallback-flame'));
      expect(
        find.descendant(of: fallback, matching: find.byType(HipRowEmblem)),
        findsNothing,
      );
      expect(
        tester
            .widget<HipIcon>(
              find.descendant(of: fallback, matching: find.byType(HipIcon)),
            )
            .glyph,
        HipGlyph.flame,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'emblems remain decorative and preserve row layout, pointer and keyboard actions',
    (tester) async {
      var groups = 0;
      var settings = 0;
      await mount(
        tester,
        Center(
          child: HipListGroup(
            children: [
              HipListRow(
                key: const ValueKey('groups-row'),
                title: '我的训练组',
                glyph: HipGlyph.grip,
                onTap: () => groups++,
              ),
              HipListRow(
                key: const ValueKey('settings-row'),
                title: '设置',
                glyph: HipGlyph.contrast,
                rowSymbol: HipRowSymbol.settings,
                onTap: () => settings++,
              ),
            ],
          ),
        ),
      );
      final groupRow = find.byKey(const ValueKey('groups-row'));
      final settingsRow = find.byKey(const ValueKey('settings-row'));
      expect(tester.getSize(groupRow).height, 52);
      expect(tester.getSize(settingsRow).height, 52);
      expect(
        tester.getTopLeft(find.text('我的训练组')).dx -
            tester.getTopLeft(groupRow).dx,
        kHipRowTextInset,
      );
      expect(find.byType(HipPressable), findsNWidgets(2));
      for (final emblem in find.byType(HipRowEmblem).evaluate()) {
        final artwork = find.byElementPredicate(
          (element) => identical(element, emblem),
        );
        expect(
          find.descendant(of: artwork, matching: find.byType(GestureDetector)),
          findsNothing,
        );
        expect(
          find.descendant(of: artwork, matching: find.byType(HipPressable)),
          findsNothing,
        );
        expect(
          find.descendant(of: artwork, matching: find.byType(Semantics)),
          findsNothing,
        );
        final excluded = find.descendant(
          of: artwork,
          matching: find.byType(ExcludeSemantics),
        );
        expect(excluded, findsOneWidget);
        expect(tester.widget<ExcludeSemantics>(excluded).excluding, isTrue);
        final paint = tester.widget<CustomPaint>(
          find.descendant(of: artwork, matching: find.byType(CustomPaint)),
        );
        expect(paint.painter!.semanticsBuilder, isNull);
      }
      final semantics = tester.ensureSemantics();
      try {
        await tester.pump();
        expect(
          tester.getSemantics(groupRow),
          isSemantics(label: '我的训练组', isButton: true, hasTapAction: true),
        );
        expect(
          tester.getSemantics(settingsRow),
          isSemantics(label: '设置', isButton: true, hasTapAction: true),
        );
      } finally {
        semantics.dispose();
      }
      await tester.tap(find.byType(HipRowIcon).first);
      await tester.pumpAndSettle();
      expect(groups, 1);
      await tester.tap(find.text('设置'));
      await tester.pumpAndSettle();
      expect(settings, 1);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(groups, 2);
      expect(settings, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'complete icon boards and representative lists render in both themes',
    (tester) async {
      for (final palette in [HipPalette.dark, HipPalette.light]) {
        final name = palette == HipPalette.dark ? 'dark' : 'light';
        await mount(tester, _board(), palette: palette);
        expect(find.byType(HipRowEmblem), findsNWidgets(36));
        for (final label in _labels.values) {
          expect(find.text(label), findsOneWidget);
        }
        expect(tester.takeException(), isNull);
        await export(tester, 'row-icons-$name');
        await mount(
          tester,
          _listExamples(),
          palette: palette,
          size: const Size(430, 1050),
        );
        expect(find.byType(HipRowEmblem), findsNWidgets(13));
        expect(tester.takeException(), isNull);
        await export(tester, 'row-icons-list-$name');
      }
    },
  );
}
