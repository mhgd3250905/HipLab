import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiplab/core/media/media_controller.dart';
import 'package:hiplab/hip/ui/hip_widgets.dart';

import 'hip_domain_test.dart' show loadContent;

void main() {
  testWidgets('entering work keeps playback requested after the next frame', (
    tester,
  ) async {
    final drill = loadContent().drill('s-kneel-hipflex');
    DrillMediaController? controller;

    Future<void> show({required bool play}) => tester.pumpWidget(
      MaterialApp(
        home: SizedBox.square(
          dimension: 240,
          child: HipDrillArt(
            key: const ValueKey('same-drill'),
            drill: drill,
            play: play,
            mediaViewBuilder: (_, c) {
              controller = c;
              return const SizedBox.expand();
            },
          ),
        ),
      ),
    );

    await show(play: false); // Prep/rest: no native view yet.
    expect(controller, isNull);

    await show(play: true); // Work: didUpdateWidget creates the view.
    final retained = controller!;
    expect(retained.wantsPlay, isTrue);
    await tester.pump(); // Flush any deferred playback request.
    expect(retained.wantsPlay, isTrue);

    final commands = <Map<String, Object?>>[];
    retained.attach(commands.add);
    retained.receive({'source': 'drill-media', 'type': 'ready'});
    expect(commands.last['type'], 'play');

    for (var i = 0; i < 2; i++) {
      await show(play: false);
      await tester.pump();
      expect(controller, same(retained));
      expect(retained.wantsPlay, isFalse);
      expect(commands.last['type'], 'pause');

      await show(play: true);
      await tester.pump();
      expect(controller, same(retained));
      expect(retained.wantsPlay, isTrue);
      expect(commands.last['type'], 'play');
    }

    await tester.pumpWidget(const SizedBox());
  });
}
