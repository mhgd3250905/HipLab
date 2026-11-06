import 'package:ugk_trainer_runtime/engine.dart' as trainer;

import '../domain/hip_models.dart';

/// The HipLab SDK execution configuration. The profile duration callback and
/// player share this builder, including the loaded voice's side-switch margin.
trainer.SessionBuilder hipSdkSessionBuilder(
  HipContent content, {
  trainer.SwitchSeconds? switchSecondsFor,
  // The voice script's prep sizing (SDK: fits the intro before 3-2-1).
  trainer.PrepSeconds? prepSecondsFor,
  // A mixed training group (M6) rests its own 10/15/20/30 s between actions.
  int transitionSeconds = 15,
}) => trainer.SessionBuilder(
  // Production SDK plans use the public catalog's execution semantics. The
  // local action kits only belong to HipLab's earlier, authored routines.
  rhythms: content.publicCatalog != null
      ? content.publicRhythms
      : {
          for (final kit in content.kits.values)
            kit.id: trainer.Rhythm.fromActionKitJson(kit.raw),
        },
  known: content.publicCatalog?.contains,
  prepSeconds: 15,
  transitionSeconds: transitionSeconds,
  switchSecondsFor: switchSecondsFor,
  prepSecondsFor: prepSecondsFor,
  // Estimate allowance per side switch (SDK v0.6.0, user 2026-11-03).
  sideSwitchMarginSeconds:
      trainer.SessionBuilder.recommendedSideSwitchMarginSeconds,
);
