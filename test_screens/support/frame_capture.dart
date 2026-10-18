// Frame-by-frame capture of an animation in a widget test (transition
// audit tooling, not part of the app).
//
// A [FrameCapture] starts something with `act` (a tap, a push, a gesture),
// then pumps the test clock one display frame at a time (1000/60 ms by
// default) and saves every frame of the subtree under [rootKey] (a
// [RepaintBoundary]) as a PNG, plus `frames.json` with each frame's index
// and time. `tools/transitions/render.py` turns a capture folder into a
// labelled contact sheet and normal / slow-motion MP4s.
//
// Real time never passes between frames: images must already be decoded
// (warm the transition once, or precache) or they draw blank, exactly as
// a cold first frame would on a device.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// One saved frame: its index, its time since the trigger and its file.
typedef CapturedFrame = ({int index, double ms, String path});

class FrameCapture {
  FrameCapture(
    this.tester, {
    required this.outDir,
    required this.rootKey,
    this.pixelRatio = 2,
    this.fps = 60,
  });

  final WidgetTester tester;

  /// Each capture is written to `<outDir>/<name>/`.
  final String outDir;

  /// Key of the [RepaintBoundary] that wraps the app.
  final Key rootKey;

  /// Device pixels per logical pixel in the PNGs (the view itself renders
  /// at 1×; this re-rasterises the layer tree, so text stays sharp).
  final double pixelRatio;
  final int fps;

  Duration get frame => Duration(microseconds: (1000000 / fps).round());

  /// Runs [act], captures frame 0 (the first frame after the trigger) and
  /// then one frame per [frame] until [total] + [tail] has elapsed.
  /// [onFrame] runs before each later frame is pumped (use it to move a
  /// drag gesture along).
  Future<List<CapturedFrame>> record(
    String name, {
    required Future<void> Function() act,
    required Duration total,
    Duration tail = const Duration(milliseconds: 120),
    Future<void> Function(int index)? onFrame,
  }) async {
    final dir = Directory('$outDir/$name');
    if (dir.existsSync()) dir.deleteSync(recursive: true);
    dir.createSync(recursive: true);
    final frames = <CapturedFrame>[];
    await act();
    await tester.pump();
    var elapsed = Duration.zero;
    frames.add(await _save(dir.path, 0, elapsed));
    final count = ((total + tail).inMicroseconds / frame.inMicroseconds).ceil();
    for (var i = 1; i <= count; i++) {
      if (onFrame != null) await onFrame(i);
      await tester.pump(frame);
      elapsed += frame;
      frames.add(await _save(dir.path, i, elapsed));
    }
    File('${dir.path}/frames.json').writeAsStringSync(
      const JsonEncoder.withIndent(' ').convert({
        'name': name,
        'fps': fps,
        'frames': [
          for (final f in frames)
            {'index': f.index, 'ms': f.ms, 'file': f.path.split('/').last},
        ],
      }),
    );
    return frames;
  }

  Future<CapturedFrame> _save(String dir, int index, Duration at) async {
    final path = '$dir/f_${index.toString().padLeft(3, '0')}.png';
    await tester.runAsync(() async {
      final boundary =
          find.byKey(rootKey).evaluate().first.renderObject!
              as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: pixelRatio);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      File(path).writeAsBytesSync(data!.buffer.asUint8List());
    });
    return (index: index, ms: at.inMicroseconds / 1000, path: path);
  }
}
