import 'package:ugk_trainer_runtime/engine.dart' as trainer;

import '../domain/hip_models.dart';

/// The HipLab SDK execution configuration. The profile duration callback and
/// player share this builder, including the loaded voice's side-switch margin.
trainer.SessionBuilder hipSdkSessionBuilder(
  HipContent content, {
  trainer.SwitchSeconds? switchSecondsFor,
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
  transitionSeconds: 15,
  switchSecondsFor: switchSecondsFor,
);
