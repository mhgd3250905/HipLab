// Read the public definitions through the SDK's action library.
import 'package:flutter/services.dart';
import 'package:ugk_coach/ugk_coach.dart' as coach;
import 'package:ugk_trainer_runtime/ugk_trainer_runtime.dart' as trainer;

import 'posehub_catalog_updates.dart';

const hipPublicCatalogAsset = 'assets/public_media/catalog.json';
const hipPublicSemanticsAsset = 'assets/public_media/catalog/catalog.json';

/// The catalogue in use: the SDK-verified hot-update cache when present, else
/// HipLab's bundled baseline copy (SDK r2-v10, identical bytes and SHA).
Future<coach.PoseHubAppTestCatalog> loadHipPublicCatalog({
  AssetBundle? bundle,
  trainer.PoseHubCatalogStore? verifiedCache,
}) async {
  final store = verifiedCache ?? PoseHubCatalogUpdates.activeStore;
  if (store != null) {
    final cached = await trainer.readVerifiedPoseHubCatalog(store);
    if (cached != null) return cached;
  }
  final assets = bundle ?? rootBundle;
  // Large loadString assets decode in an isolate outside widget fake clocks.
  // Read exact bytes; the SDK verifies the canonical semantics descriptor.
  final delivery = await assets.load(hipPublicCatalogAsset);
  final semantics = await assets.load(hipPublicSemanticsAsset);
  return coach.PoseHubAppTestCatalog.fromBytes(
    delivery.buffer.asUint8List(delivery.offsetInBytes, delivery.lengthInBytes),
    semanticCatalogBytes: semantics.buffer.asUint8List(
      semantics.offsetInBytes,
      semantics.lengthInBytes,
    ),
  );
}

/// Match SF's public-definition adapter: authored execution is authoritative;
/// a media loop never supplies a training cadence. Unknown reps stay manual.
Map<String, trainer.Rhythm> hipPublicRhythms(coach.PoseHubAppTestCatalog pack) {
  final catalog = pack.toAiCatalog();
  return Map.unmodifiable({
    for (final drill in catalog.drills)
      drill.id: _publicRhythm(pack.tryGet(drill.id)!, drill),
  });
}

trainer.Rhythm _publicRhythm(
  coach.PoseHubPackAction action,
  coach.Drill drill,
) {
  // Canonical legacy definitions do not contain the delivery's execution
  // extension. Read it from the verified row rather than dropping its timing.
  final metadata = action.raw['rhythm'] as Map?;
  final execution = metadata?['execution'];
  var rhythm = execution is Map
      ? trainer.Rhythm.fromJson(Map<String, dynamic>.from(execution))
      : drill.defaultDose.mode == coach.DoseMode.reps
      ? trainer.Rhythm.selfPacedReps
      : trainer.Rhythm.timedHold;
  // Dose's public typed model omits this extension. SF retains the exact raw
  // canonical/defaultDose value rather than deriving a hold from the video.
  final dose = drill.raw['defaultDose'] as Map?;
  final hold = dose?['holdSeconds'];
  if (hold is int && rhythm.counted) rhythm = rhythm.withHold(hold);
  return rhythm;
}

/// The fitter sees the same per-rep cycle as the player. One-off lead and full
/// phases remain on the SDK rhythm and are measured by executionTiming.
coach.Catalog hipCoachCatalogFromPublic(
  coach.PoseHubAppTestCatalog pack, {
  Map<String, trainer.Rhythm>? rhythms,
}) {
  final source = pack.toAiCatalog();
  final execution = rhythms ?? hipPublicRhythms(pack);
  final drills = <Map<String, Object?>>[];
  for (final drill in source.drills) {
    final rhythm = execution[drill.id];
    if (drill.defaultDose.mode != coach.DoseMode.reps ||
        rhythm == null ||
        !rhythm.counted) {
      drills.add(drill.raw);
      continue;
    }
    final cycle = rhythm.cycleFor();
    if (!cycle.isFinite || cycle <= 0) {
      drills.add(drill.raw);
      continue;
    }
    final assets = Map<String, Object?>.from(
      drill.raw['assets'] as Map? ?? const {},
    );
    final video = Map<String, Object?>.from(
      assets['video'] as Map? ?? const {},
    );
    final sources = List<Object?>.from(video['sources'] as List? ?? const []);
    final first = sources.indexWhere(
      (value) => coach.AssetSource.tryParse(value) != null,
    );
    if (first >= 0) {
      sources[first] = {
        ...Map<String, Object?>.from(sources[first] as Map),
        'repSeconds': cycle,
      };
    } else {
      // Only project an existing, SDK-verified public video source.
      final file = pack.tryGet(drill.id)?.video.raw;
      if (file == null) {
        drills.add(drill.raw);
        continue;
      }
      final projected = <String, Object?>{
        ...file,
        'app': 'pose-hub',
        'repSeconds': cycle,
      };
      if (coach.AssetSource.tryParse(projected) == null) {
        drills.add(drill.raw);
        continue;
      }
      sources.insert(0, projected);
    }
    drills.add({
      ...drill.raw,
      'assets': {
        ...assets,
        'video': {...video, 'sources': sources},
      },
    });
  }
  return coach.Catalog.fromJson({...source.raw, 'drills': drills});
}
