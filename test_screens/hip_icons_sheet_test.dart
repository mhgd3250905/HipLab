// HipLab icon overview (not part of `flutter test`): every HipGlyph in its
// outline and filled state, at 24 px on the 24-unit grid (with the 2-unit
// safe margin drawn) and at 48 px, on the dark and light surfaces.
//
//   flutter test --no-pub test_screens/hip_icons_sheet_test.dart
//
// Output: test/_shots/icons-sheet.png and test/_shots/components-{dark,light}.png
// (the countdown ring at several points, the start button, round buttons
// and segmented controls in both themes). Git-ignored.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiplab/hip/ui/hip_icons.dart';
import 'package:hiplab/hip/ui/hip_segmented.dart';
import 'package:hiplab/hip/ui/hip_theme.dart';
import 'package:hiplab/hip/ui/hip_widgets.dart';

Future<void> _loadFonts() async {
  final bytes = File('assets/fonts/NotoSansSC.ttf').readAsBytesSync();
  await (FontLoader(
    'NotoSansSC',
  )..addFont(Future.value(ByteData.view(bytes.buffer)))).load();
}

const _names = {
  HipGlyph.play: '播放',
  HipGlyph.pause: '暂停',
  HipGlyph.skipNext: '下一个',
  HipGlyph.close: '关闭',
  HipGlyph.back: '返回',
  HipGlyph.chevronRight: '进入',
  HipGlyph.check: '勾',
  HipGlyph.checkCircle: '完成',
  HipGlyph.loop: '预览/循环',
  HipGlyph.chair: '办公椅',
  HipGlyph.home: '居家',
  HipGlyph.flame: '连续',
  HipGlyph.today: '今日',
  HipGlyph.checkup: '体检',
  HipGlyph.progress: '进度',
  HipGlyph.radar: '雷达',
  HipGlyph.bolt: '疼',
  HipGlyph.pinch: '夹着疼',
  HipGlyph.volume: '语音',
  HipGlyph.volumeLow: '音量小',
  HipGlyph.subtitles: '字幕',
  HipGlyph.info: '提示',
  HipGlyph.clipboard: '就医',
  HipGlyph.shield: '安全',
  HipGlyph.bell: '提醒',
  HipGlyph.voice: '播报',
  HipGlyph.contrast: '外观',
  HipGlyph.stop: '停下',
  HipGlyph.figure: '动作',
  HipGlyph.dancer: '舞者',
  HipGlyph.person: '其他',
  HipGlyph.bandage: '受伤',
};

class _Grid extends CustomPainter {
  _Grid(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 24;
    final p = Paint()
      ..color = color
      ..strokeWidth = .5
      ..style = PaintingStyle.stroke;
    canvas.drawRect(Offset.zero & size, p);
    canvas.drawRect(Rect.fromLTWH(2 * k, 2 * k, 20 * k, 20 * k), p);
    canvas.drawLine(Offset(12 * k, 0), Offset(12 * k, size.height), p);
    canvas.drawLine(Offset(0, 12 * k), Offset(size.width, 12 * k), p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

Widget _cell(HipGlyph g, HipPalette p) => SizedBox(
  width: 150,
  child: Column(
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (final filled in [false, true]) ...[
            CustomPaint(
              foregroundPainter: _Grid(p.faint.withValues(alpha: .35)),
              child: HipIcon(g, size: 48, color: p.text, filled: filled),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
      const SizedBox(height: 6),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          HipIcon(g, size: 24, color: p.muted),
          const SizedBox(width: 8),
          HipIcon(g, size: 24, color: p.jade, filled: true),
          const SizedBox(width: 8),
          HipIcon(g, size: 16, color: p.text),
        ],
      ),
      const SizedBox(height: 4),
      Text(
        '${_names[g]} · ${g.name}',
        style: TextStyle(fontSize: 11, color: p.muted),
      ),
    ],
  ),
);

Widget _sheet(HipPalette p) => Container(
  color: p.background,
  padding: const EdgeInsets.all(24),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        'HipLab 图标 · ${p.isDark ? '深色' : '浅色'}',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: p.text,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        '24 栅格 · 2 单位安全边 · 1.75 笔画 · 圆角端点 · 描边/填充两态（上排 48px，下排 24px 描边 / 24px 填充 / 16px）',
        style: TextStyle(fontSize: 12, color: p.muted),
      ),
      const SizedBox(height: 16),
      Wrap(
        spacing: 6,
        runSpacing: 18,
        children: [for (final g in HipGlyph.values) _cell(g, p)],
      ),
    ],
  ),
);

void main() {
  setUpAll(_loadFonts);
  testWidgets('icon sheet', (tester) async {
    tester.view.physicalSize = const Size(1400, 1030);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(fontFamily: hipFontFamily),
        home: Material(
          child: RepaintBoundary(
            child: SingleChildScrollView(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _sheet(HipPalette.dark)),
                  Expanded(child: _sheet(HipPalette.light)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.runAsync(() async {
      final boundary =
          find.byType(RepaintBoundary).first.evaluate().first.renderObject!
              as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      File('test/_shots/icons-sheet.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(data!.buffer.asUint8List());
    });
  });

  testWidgets('components sheet', (tester) async {
    HipColors.flatShadows = true; // the test renderer cannot blur shadows
    tester.view.physicalSize = const Size(700, 520);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    Widget panel(HipPalette p) {
      return Container(
        color: p.background,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '组件 · ${p.isDark ? '深色' : '浅色'}',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: p.text,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                for (final (v, work) in [
                  (0.0, true),
                  (.35, true),
                  (.8, true),
                  (.5, false),
                ]) ...[
                  HipCountdownRing(
                    progress: v,
                    label: '${(30 * (1 - v)).round()}',
                    caption: work ? '秒' : '准备',
                    size: 130,
                    color: work ? p.jade : p.jade.withValues(alpha: .5),
                  ),
                  const SizedBox(width: 18),
                ],
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                HipCircleButton(
                  icon: HipGlyph.pause,
                  size: 64,
                  onPressed: () {},
                ),
                const SizedBox(width: 14),
                HipCircleButton(
                  icon: HipGlyph.skipNext,
                  size: 64,
                  onPressed: () {},
                ),
                const SizedBox(width: 14),
                HipCircleButton(icon: HipGlyph.close, onPressed: () {}),
                const SizedBox(width: 30),
                Container(
                  width: 190,
                  height: 170,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: HipPalette.dark.surface,
                    borderRadius: BorderRadius.circular(26),
                  ),
                  child: HipStartButton(onTap: () {}, stage: HipPalette.dark),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                SizedBox(
                  width: 280,
                  child: HipSegmented<int>(
                    values: const [5, 10, 15],
                    selected: 10,
                    onChanged: (_) {},
                    standalone: true,
                    height: 74,
                    radius: 22,
                    inset: 5,
                    itemBuilder: (v, fg, t) =>
                        Text('$v 分', style: TextStyle(fontSize: 18, color: fg)),
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  width: 300,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: p.surface,
                    borderRadius: BorderRadius.circular(22),
                    border: p.isDark ? Border.all(color: p.line) : null,
                  ),
                  child: HipSegmented<String>(
                    values: const ['跟随系统', '浅色', '深色'],
                    selected: '浅色',
                    label: (v) => v,
                    onChanged: (_) {},
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // One pump per theme: widgets read HipColors while building and laying
    // out, so each sheet renders alone (stitched by the caller).
    for (final p in [HipPalette.dark, HipPalette.light]) {
      HipColors.palette = p;
      await tester.pumpWidget(
        MaterialApp(
          key: ValueKey(p.brightness),
          debugShowCheckedModeBanner: false,
          theme: ThemeData(fontFamily: hipFontFamily),
          home: Material(child: RepaintBoundary(child: panel(p))),
        ),
      );
      await tester.pump();
      await tester.runAsync(() async {
        final boundary =
            find.byType(RepaintBoundary).first.evaluate().first.renderObject!
                as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 2);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        File('test/_shots/components-${p.isDark ? 'dark' : 'light'}.png')
          ..createSync(recursive: true)
          ..writeAsBytesSync(data!.buffer.asUint8List());
      });
    }
  });
}
