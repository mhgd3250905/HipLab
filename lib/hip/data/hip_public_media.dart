// HipLab configuration for the SDK public media policy.
import 'package:ugk_trainer_runtime/ugk_trainer_runtime.dart' as trainer;

import 'hip_public_catalog.dart';
import 'posehub_catalog_updates.dart';

abstract final class HipPublicMedia {
  static const posterRoot = 'assets/public_posters/';
  static trainer.TrainingMediaPolicy? current;

  static Future<trainer.TrainingMediaPolicy> load({
    String? rootDirectory,
    bool prefetchBeforeTraining = true,
  }) async {
    final catalog = await loadHipPublicCatalog();
    final repository = await trainer.TrainingMediaRepository.fromCatalog(
      catalog: catalog,
      catalogRevision: poseHubCatalogRevisionOf(catalog),
      // The pack follows the catalogue in use (r2-v10 baseline or hot update).
      mediaBaseUrls: [trainer.PoseHubActionLibrary.mediaBaseUriFor(catalog)],
      rootDirectory: rootDirectory,
    );
    return trainer.TrainingMediaPolicy(
      repository: repository,
      posterAssetRoot: posterRoot,
      prefetchBeforeTraining: prefetchBeforeTraining,
    );
  }
}
