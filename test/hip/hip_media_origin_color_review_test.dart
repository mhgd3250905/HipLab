// HipLab passes its actual theme to the shared training launcher.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiplab/hip/control/hip_store.dart';
import 'package:hiplab/hip/domain/hip_models.dart';
import 'package:hiplab/hip/ui/hip_app.dart';
import 'package:hiplab/hip/ui/hip_player_page.dart';
import 'package:hiplab/hip/ui/hip_theme.dart';
import 'package:hiplab/hip/ui/hip_widgets.dart';
import 'package:ugk_trainer_runtime/ugk_trainer_runtime.dart' as trainer;

import 'hip_domain_test.dart' show MemoryStorage, loadContent;
import 'public_media_fixture.dart';

void main() {
  testWidgets('light home start passes its stage to the shared route', (
    tester,
  ) async {
    final fixture = installPublicMediaFixture();
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final oldPalette = HipColors.palette;
    final oldMedia = HipMediaVariants.media;
    addTearDown(() {
      HipColors.palette = oldPalette;
      HipMediaVariants.media = oldMedia;
    });
    final store = HipStore(
      content: loadContent(),
      storage: MemoryStorage(),
      clock: () => DateTime(2026, 10, 19, 9),
    );
    await store.initialize();
    store
      ..safety = {'pregnancy': false, 'surgery': false, 'acute': false}
      ..identity = HipIdentity.dancer
      ..minutes = 10
      ..scene = HipScene.home
      ..theme = HipThemeChoice.light;
    await tester.pumpWidget(
      HipApp(store: store, videoEnabled: false, mediaPolicy: fixture.policy),
    );
    await tester.pumpAndSettle();
    final start = find.byType(HipStartButton);
    final button = tester.widget<HipStartButton>(start);
    expect(
      button.stage.isDark,
      isFalse,
      reason: 'the fixture must load the actual bundled light media stage',
    );
    await tester.tap(find.byKey(const ValueKey('start-today')));
    await tester.pump();
    final route =
        ModalRoute.of(
              tester.element(find.byType(HipPlayerPage, skipOffstage: false)),
            )!
            as trainer.TrainerSlideRoute;
    expect(route.trainerTheme!.brightness, Brightness.light);
    expect(route.trainerTheme!.mediaStage, HipPalette.light.mediaBackdrop);
    expect(route.trainerTheme!.accent, button.stage.jade);
    final experience = trainer.TrainerExperienceScope.maybeOf(
      tester.element(find.byType(HipPlayerPage, skipOffstage: false)),
    )!;
    expect(experience.firstPosterAsset, startsWith('assets/public_posters/'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpWidget(const SizedBox());
  });
}
