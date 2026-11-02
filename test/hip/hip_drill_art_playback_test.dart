import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiplab/hip/data/hip_public_media.dart';
import 'package:hiplab/hip/data/hip_shared_library.dart';
import 'package:hiplab/hip/ui/hip_widgets.dart';
import 'package:ugk_trainer_runtime/ugk_trainer_runtime.dart' as trainer;

import 'hip_domain_test.dart' show loadContent;
import 'public_media_fixture.dart';

void main() {
  testWidgets('host playback and mirror requests reach the SDK public media', (
    tester,
  ) async {
    final fixture = installPublicMediaFixture();
    final drill = loadContent().drill('s-kneel-hipflex');
    Future<void> show({
      required bool play,
      bool video = true,
      bool mirror = false,
    }) => tester.pumpWidget(
      MaterialApp(
        home: HipMediaPolicy(
          videoEnabled: video,
          child: SizedBox.square(
            dimension: 240,
            child: HipDrillArt(
              key: const ValueKey('same-drill'),
              drill: drill,
              play: play,
              mirror: mirror,
            ),
          ),
        ),
      ),
    );
    trainer.TrainingActionMedia media() =>
        tester.widget(find.byType(trainer.TrainingActionMedia));

    await show(play: false);
    expect(media().policy, same(fixture.policy));
    expect(media().actionId, drill.id);
    expect(media().playing, isFalse);
    expect(media().paused, isTrue);
    await show(play: true, mirror: true);
    expect(media().playing, isTrue);
    expect(media().paused, isFalse);
    expect(media().mirrored, isTrue);
    await tester.pump();
    expect(media().playing, isTrue);
    await show(play: true, video: false);
    expect(media().playing, isFalse);
    await show(play: true);
    expect(media().playing, isTrue);
    expect(fixture.requested, isEmpty);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('shared artwork receives the host config and public policy', (
    tester,
  ) async {
    final fixture = installPublicMediaFixture(sharedLibrary: true);
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox.square(
          dimension: 240,
          child: HipDrillArt(
            drill: loadContent().drill('s-kneel-hipflex'),
            play: true,
            mirror: true,
          ),
        ),
      ),
    );
    final art = tester.widget<trainer.TrainingLibraryActionArt>(
      find.byType(trainer.TrainingLibraryActionArt),
    );
    expect(art.config, same(HipSharedLibrary.current));
    expect(art.mediaPolicy, same(fixture.policy));
    expect(art.playing, isTrue);
    expect(art.mirrored, isTrue);
    expect(find.byType(trainer.TrainingActionMedia), findsOneWidget);
    expect(fixture.requested, isEmpty);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('missing public policy shows the host placeholder', (
    tester,
  ) async {
    installPublicMediaFixture();
    HipPublicMedia.current = null;
    await tester.pumpWidget(
      MaterialApp(
        home: HipDrillArt(
          drill: loadContent().drill('s-kneel-hipflex'),
          play: true,
        ),
      ),
    );
    expect(find.byType(HipPendingArt), findsOneWidget);
    expect(find.byType(trainer.TrainingActionMedia), findsNothing);
  });
}
