// The transition-audit capture tool (test_screens/support/frame_capture.dart):
// one PNG per 60 fps frame from the trigger to the end, with frames.json.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../test_screens/support/frame_capture.dart';

void main() {
  testWidgets('records every frame of an animation with its time', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(100, 100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final out = Directory.systemTemp.createTempSync('frame-capture-');
    addTearDown(() => out.deleteSync(recursive: true));
    var wide = false;
    late StateSetter set;
    await tester.pumpWidget(
      RepaintBoundary(
        key: const ValueKey('root'),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: StatefulBuilder(
            builder: (context, setState) {
              set = setState;
              return Align(
                alignment: Alignment.topLeft,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 100),
                  width: wide ? 100 : 10,
                  height: 10,
                  color: const Color(0xff00ff00),
                ),
              );
            },
          ),
        ),
      ),
    );
    final cap = FrameCapture(
      tester,
      outDir: out.path,
      rootKey: const ValueKey('root'),
      pixelRatio: 1,
    );
    final moved = <int>[];
    final frames = await cap.record(
      'grow',
      act: () async => set(() => wide = true),
      total: const Duration(milliseconds: 100),
      tail: Duration.zero,
      onFrame: (i) async => moved.add(i),
    );
    // Frame 0 at the trigger, then one per 1000/60 ms through 100 ms.
    expect(frames.length, 7);
    expect(frames.first.ms, 0);
    expect(frames[1].ms, closeTo(16.667, .01));
    expect(frames.last.ms, closeTo(100, .01));
    expect(moved, [1, 2, 3, 4, 5, 6]);
    for (final f in frames) {
      expect(File(f.path).existsSync(), isTrue);
    }
    final meta =
        jsonDecode(File('${out.path}/grow/frames.json').readAsStringSync())
            as Map<String, dynamic>;
    expect(meta['fps'], 60);
    expect((meta['frames'] as List).length, 7);
    // The animation is visible in the files: the last frame differs.
    expect(
      File(frames.first.path).readAsBytesSync(),
      isNot(File(frames.last.path).readAsBytesSync()),
    );
  });
}
