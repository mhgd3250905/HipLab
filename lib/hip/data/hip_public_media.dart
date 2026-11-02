// HipLab configuration for the SDK public media policy.
import 'package:flutter/services.dart';
import 'package:ugk_coach/ugk_coach.dart' as coach;
import 'package:ugk_trainer_runtime/ugk_trainer_runtime.dart' as trainer;

abstract final class HipPublicMedia {
  static const catalogAsset = 'assets/public_media/catalog.json';
  static const semanticsAsset = 'assets/public_media/catalog/catalog.json';
  static const posterRoot = 'assets/public_posters/';
  static trainer.TrainingMediaPolicy? current;

  static Future<trainer.TrainingMediaPolicy> load({
    String? rootDirectory,
    bool prefetchBeforeTraining = true,
  }) async {
    final raw = await rootBundle.load(catalogAsset);
    final semantics = await rootBundle.load(semanticsAsset);
    final catalog = coach.PoseHubAppTestCatalog.fromBytes(
      raw.buffer.asUint8List(raw.offsetInBytes, raw.lengthInBytes),
      semanticCatalogBytes: semantics.buffer.asUint8List(
        semantics.offsetInBytes,
        semantics.lengthInBytes,
      ),
    );
    final repository = await trainer.TrainingMediaRepository.fromCatalog(
      catalog: catalog,
      catalogRevision: trainer.PoseHubActionLibrary.catalogSha256,
      mediaBaseUrls: [
        Uri.parse(trainer.PoseHubActionLibrary.mediaReleaseBaseUri),
      ],
      rootDirectory: rootDirectory,
    );
    return trainer.TrainingMediaPolicy(
      repository: repository,
      posterAssetRoot: posterRoot,
      prefetchBeforeTraining: prefetchBeforeTraining,
    );
  }
}
