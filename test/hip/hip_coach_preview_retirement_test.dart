import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiplab/hip/ui/coach/hip_coach_visuals.dart';
import 'package:hiplab/hip/ui/hip_widgets.dart';
import 'package:ugk_trainer_runtime/ugk_trainer_runtime.dart' as trainer;

import 'hip_domain_test.dart' show loadContent;
import 'public_media_fixture.dart';

void main() {
  testWidgets('retirement waits for a frame and requires explicit restart', (
    tester,
  ) async {
    final fixture = installPublicMediaFixture();
    final drill = loadContent().drill('s-figure4');
    final handle = HipDrillArtHandle();
    Future<void> show(bool play, {Brightness brightness = Brightness.light}) =>
        tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(brightness: brightness),
            home: SizedBox.square(
              dimension: 240,
              child: HipDrillArt(
                key: handle.key,
                retirementHandle: handle,
                drill: drill,
                play: play,
              ),
            ),
          ),
        );
    bool playing() => tester
        .widget<trainer.TrainingActionMedia>(
          find.byType(trainer.TrainingActionMedia),
        )
        .playing;

    await show(true);
    expect(playing(), isTrue);
    var retired = false;
    final pending = handle.retire();
    unawaited(pending.then((_) => retired = true));
    expect(retired, isFalse);
    await tester.pump();
    await pending;
    expect(retired, isTrue);
    expect(playing(), isFalse);
    await show(true, brightness: Brightness.dark);
    expect(
      playing(),
      isFalse,
      reason: 'a rebuild cannot revive a retired preview',
    );
    await show(false);
    await show(true);
    expect(playing(), isTrue);
    expect(fixture.requested, isEmpty);
    await tester.pumpWidget(const SizedBox());
    await handle.retire();
  });

  testWidgets('retiring handle stays awaitable when its route is removed', (
    tester,
  ) async {
    installPublicMediaFixture();
    final handle = HipDrillArtHandle();
    await tester.pumpWidget(
      MaterialApp(
        home: HipDrillArt(
          key: handle.key,
          retirementHandle: handle,
          drill: loadContent().drill('s-figure4'),
          play: true,
        ),
      ),
    );
    final pending = handle.retire();
    await tester.pumpWidget(const SizedBox());
    await pending;
    await handle.retire();
    expect(tester.takeException(), isNull);
  });

  testWidgets('SDK host retirement targets the exact context and action', (
    tester,
  ) async {
    final fixture = installPublicMediaFixture();
    final visual = hipCoachChatVisuals(loadContent());
    final contexts = <BuildContext>[];
    Widget preview(int slot) => SizedBox.square(
      dimension: 160,
      child: Builder(
        builder: (context) {
          if (contexts.length == slot) contexts.add(context);
          return visual.previewBuilder!(context, 's-figure4', true);
        },
      ),
    );
    List<bool> playing() => tester
        .widgetList<trainer.TrainingActionMedia>(
          find.byType(trainer.TrainingActionMedia),
        )
        .map((media) => media.playing)
        .toList();

    await tester.pumpWidget(
      MaterialApp(home: Column(children: [preview(0), preview(1)])),
    );
    expect(playing(), [true, true]);
    final retired = visual.retirePreview!(contexts.first, 's-figure4');
    await tester.pump();
    await retired;
    expect(playing(), [false, true]);
    final last = visual.retirePreview!(contexts.last, 's-figure4');
    await tester.pump();
    await last;
    expect(playing(), [false, false]);
    await visual.retirePreview!(contexts.last, 'missing-preview');
    expect(fixture.requested, isEmpty);
    await tester.pumpWidget(const SizedBox());
  });
}
