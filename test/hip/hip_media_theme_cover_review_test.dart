import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiplab/hip/ui/hip_theme.dart';
import 'package:hiplab/hip/ui/hip_widgets.dart';
import 'package:ugk_trainer_runtime/ugk_trainer_runtime.dart' as trainer;

import 'hip_domain_test.dart' show loadContent;
import 'public_media_fixture.dart';

void main() {
  testWidgets(
    'theme changes delegate the host stage to shared public artwork',
    (tester) async {
      final fixture = installPublicMediaFixture(sharedLibrary: true);
      final oldPalette = HipColors.palette;
      addTearDown(() => HipColors.palette = oldPalette);
      Future<void> show(HipPalette palette) {
        HipColors.palette = palette;
        return tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(brightness: palette.brightness),
            themeAnimationDuration: Duration.zero,
            home: SizedBox.square(
              dimension: 240,
              child: HipDrillArt(
                key: const ValueKey('same-public-art'),
                drill: loadContent().drill('s-kneel-hipflex'),
                play: true,
              ),
            ),
          ),
        );
      }

      for (final palette in [HipPalette.dark, HipPalette.light]) {
        await show(palette);
        final art = tester.widget<trainer.TrainingLibraryActionArt>(
          find.byType(trainer.TrainingLibraryActionArt),
        );
        expect(art.actionId, 's-kneel-hipflex');
        expect(art.mediaPolicy, same(fixture.policy));
        expect(art.theme!.brightness, palette.brightness);
        expect(art.theme!.mediaStage, palette.mediaBackdrop);
        final media = tester.widget<trainer.TrainingActionMedia>(
          find.byType(trainer.TrainingActionMedia),
        );
        expect(media.stage, palette.mediaBackdrop);
        final poster = tester.widget<trainer.TrainerPoster>(
          find.byType(trainer.TrainerPoster),
        );
        expect(poster.asset, 'assets/public_posters/s-kneel-hipflex.webp');
      }
      expect(fixture.requested, isEmpty);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
