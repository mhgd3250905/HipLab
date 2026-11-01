import 'package:ugk_trainer_runtime/engine.dart' as trainer;

import '../domain/hip_models.dart';

/// The HipLab SDK execution configuration. The profile duration callback and
/// player share this builder, including the loaded voice's side-switch margin.
trainer.SessionBuilder hipSdkSessionBuilder(
  HipContent content, {
  trainer.SwitchSeconds? switchSecondsFor,
}) => trainer.SessionBuilder(
  rhythms: {
    for (final kit in content.kits.values)
      kit.id: trainer.Rhythm.fromActionKitJson(kit.raw),
  },
  prepSeconds: 15,
  transitionSeconds: 15,
  switchSecondsFor: switchSecondsFor,
);
