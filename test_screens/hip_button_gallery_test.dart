// HipLab button gallery (not part of `flutter test`): every shared button
// type on one page, dark and light, plus a frame-by-frame press capture.
// Used for the tactile-button before/after review (docs/
// button-style-audit-2026-10-18.md).
//
//   BUTTONS_OUT=test/_shots/buttons/after \
//     flutter test --no-pub test_screens/hip_button_gallery_test.dart
//   python3 tools/transitions/render.py test/_shots/buttons/after/<theme>
//
// Writes <out>/<theme>/gallery.png and <out>/<theme>/press/ (frames +
// frames.json for render.py).
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

import 'support/frame_capture.dart';

const _root = ValueKey('gallery-root');
final _out =
    Platform.environment['BUTTONS_OUT'] ?? 'test/_shots/buttons/latest';

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

Widget _label(String s) => Padding(
  padding: const EdgeInsets.fromLTRB(0, 18, 0, 8),
  child: Text(
    s,
    style: TextStyle(
      fontSize: 12,
      color: HipColors.muted,
      fontWeight: FontWeight.w600,
    ),
  ),
);

class _Gallery extends StatefulWidget {
  const _Gallery();
  @override
  State<_Gallery> createState() => _GalleryState();
}

class _GalleryState extends State<_Gallery> {
  int minutes = 10;
  String lang = '中文';
  int interval = 45;
  bool on = true;

  @override
  Widget build(BuildContext context) {
    const stage = HipPalette.dark;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _label('首页「开始」（深色媒体舞台）'),
              SizedBox(
                height: 160,
                child: HipMediaFrame(
                  radius: 26,
                  color: stage.surface,
                  borderColor: HipColors.isDark
                      ? stage.line
                      : const Color(0x00000000),
                  shadow: HipColors.cardShadow,
                  child: Stack(
                    children: [
                      Positioned(
                        left: 20,
                        bottom: 24,
                        child: Text(
                          '今日训练',
                          style: TextStyle(
                            color: stage.text,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Positioned(
                        right: 22,
                        bottom: 26,
                        child: HipStartButton(
                          buttonKey: const ValueKey('g-start'),
                          stage: stage,
                          onTap: () {},
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _label('主按钮 / 禁用'),
              HipPrimaryButton(
                key: const ValueKey('g-primary'),
                label: '开始自测',
                icon: HipGlyph.play,
                onPressed: () {},
              ),
              const SizedBox(height: 10),
              const HipPrimaryButton(label: '先问问医生再来', onPressed: null),
              _label('次按钮 + 主按钮（引导页）'),
              Row(
                children: [
                  Expanded(
                    child: HipSecondaryButton(
                      key: const ValueKey('g-secondary'),
                      label: '有',
                      onPressed: () {},
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: HipPrimaryButton(label: '没有', onPressed: () {}),
                  ),
                ],
              ),
              _label('圆形图标按钮（顶栏 44 / 播放器 64）'),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  HipCircleButton(
                    key: const ValueKey('g-close'),
                    icon: HipGlyph.close,
                    tooltip: '关闭',
                    onPressed: () {},
                  ),
                  HipCircleButton(
                    key: const ValueKey('g-pause'),
                    icon: HipGlyph.pause,
                    size: 64,
                    tooltip: '暂停',
                    onPressed: () {},
                  ),
                  HipCircleButton(
                    icon: HipGlyph.skipNext,
                    size: 64,
                    tooltip: '跳过',
                    onPressed: () {},
                  ),
                ],
              ),
              _label('分段控件（首页独立 / 设置卡片内）'),
              HipSegmented<int>(
                keyPrefix: 'g-min',
                standalone: true,
                height: 74,
                radius: 22,
                inset: 5,
                values: const [5, 10, 15],
                selected: minutes,
                onChanged: (v) => setState(() => minutes = v),
                itemBuilder: (v, fg, t) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$v',
                      style: TextStyle(
                        fontSize: 22,
                        height: 1.15,
                        fontWeight: FontWeight.w700,
                        color: Color.lerp(HipColors.text, fg, t),
                      ),
                    ),
                    Text(
                      '分',
                      style: TextStyle(fontSize: 11, height: 1.3, color: fg),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              HipPanel(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text('久坐提醒', style: TextStyle(fontSize: 15)),
                        ),
                        Switch(
                          value: on,
                          onChanged: (v) => setState(() => on = v),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        for (final m in [45, 60])
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text('$m 分钟'),
                              selected: interval == m,
                              onSelected: (_) => setState(() => interval = m),
                            ),
                          ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () {},
                          icon: const HipIcon(HipGlyph.today, size: 20),
                          label: const Text('试听'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    HipSegmented<String>(
                      keyPrefix: 'g-lang',
                      values: const ['跟随 App', '中文', 'English'],
                      selected: lang,
                      label: (l) => l,
                      onChanged: (l) => setState(() => lang = l),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _save(WidgetTester tester, String path) async {
  await tester.runAsync(() async {
    final boundary =
        find.byKey(_root).evaluate().first.renderObject!
            as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    File(path)
      ..createSync(recursive: true)
      ..writeAsBytesSync(data!.buffer.asUint8List());
  });
}

void main() {
  setUpAll(() async {
    await _loadFonts();
    HipColors.flatShadows = false;
  });

  for (final palette in [HipPalette.dark, HipPalette.light]) {
    final name = palette.isDark ? 'dark' : 'light';

    Future<void> boot(WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 1000);
      tester.view.devicePixelRatio = 1;
      tester.view.padding = const FakeViewPadding(top: 20, bottom: 20);
      addTearDown(tester.view.reset);
      HipColors.palette = palette;
      await tester.pumpWidget(
        RepaintBoundary(
          key: _root,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: hipTheme(palette),
            home: const _Gallery(),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('$name gallery', (tester) async {
      await boot(tester);
      await _save(tester, '$_out/$name/gallery.png');
    });

    testWidgets('$name press', (tester) async {
      await boot(tester);
      // Press and hold each button in turn, then release: 开始, 主按钮,
      // 次按钮, 圆形 64. ~0.5 s per button at 60 fps.
      final targets = [
        find.byKey(const ValueKey('g-start')),
        find.byKey(const ValueKey('g-primary')),
        find.byKey(const ValueKey('g-secondary')),
        find.byKey(const ValueKey('g-pause')),
      ];
      const per = 30; // frames per button
      const hold = 14; // frames held down
      TestGesture? g;
      await FrameCapture(tester, outDir: '$_out/$name', rootKey: _root).record(
        'press',
        act: () async {},
        total: const Duration(milliseconds: per * 4 * 1000 ~/ 60),
        onFrame: (i) async {
          final k = (i - 1) ~/ per, f = (i - 1) % per;
          if (k >= targets.length) return;
          if (f == 2) {
            g = await tester.startGesture(tester.getCenter(targets[k]));
          } else if (f == 2 + hold) {
            await g?.up();
            g = null;
          }
        },
      );
      await tester.pumpAndSettle();
    });
  }
}
