// HipLab configuration for the SDK public media policy.
import 'package:flutter/services.dart';
import 'package:ugk_trainer_runtime/ugk_trainer_runtime.dart' as trainer;

import 'hip_action_scope.dart';
import 'hip_public_catalog.dart';
import 'posehub_catalog_updates.dart';

abstract final class HipPublicMedia {
  static const posterRoot = 'assets/public_posters/';
  static const artworkRoot = '${posterRoot}r2-v11/';
  static trainer.TrainingMediaPolicy? current;

  static String? coverAssetFor(String id) =>
      hiplabCoachAuthorizedActionIds.contains(id)
      ? '${artworkRoot}cover/$id.webp'
      : null;

  static String? thumbnailAssetFor(String id) =>
      hiplabCoachAuthorizedActionIds.contains(id)
      ? '${artworkRoot}thumbnail/$id.webp'
      : null;

  static trainer.TrainingMediaPolicy forLibrary(
    trainer.TrainingMediaPolicy policy,
  ) => policy is _HipPublicMediaPolicy ? policy.library : policy;

  static Future<trainer.TrainingMediaPolicy> load({
    String? rootDirectory,
    bool prefetchBeforeTraining = true,
  }) async {
    final catalog = await loadHipPublicCatalog();
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final standing = manifest.listAssets().where((path) {
      if (!path.startsWith(posterRoot)) return false;
      final name = path.substring(posterRoot.length);
      return !name.contains('/') && name.endsWith('.webp');
    }).toSet();
    final repository = await trainer.TrainingMediaRepository.fromCatalog(
      catalog: catalog,
      catalogRevision: poseHubCatalogRevisionOf(catalog),
      // The pack follows the catalogue in use (r2-v11 baseline or hot update).
      mediaBaseUrls: [trainer.PoseHubActionLibrary.mediaBaseUriFor(catalog)],
      rootDirectory: rootDirectory,
    );
    return _HipPublicMediaPolicy(
      repository: repository,
      standing: standing,
      prefetchBeforeTraining: prefetchBeforeTraining,
    );
  }
}

class _HipPublicMediaPolicy extends trainer.TrainingMediaPolicy {
  _HipPublicMediaPolicy({
    required super.repository,
    required super.prefetchBeforeTraining,
    required this.standing,
    this.preferCover = false,
  });

  final Set<String> standing;
  final bool preferCover;

  late final library = _HipPublicMediaPolicy(
    repository: repository,
    prefetchBeforeTraining: prefetchBeforeTraining,
    standing: standing,
    preferCover: true,
  );

  @override
  String? posterAssetFor(String id) {
    final poster = super.posterAssetFor(id);
    if (poster == null) return null;
    // Keep authored home/training first-frame images and the self-test demo.
    if (!preferCover && standing.contains(poster)) return poster;
    return HipPublicMedia.coverAssetFor(id) ??
        (standing.contains(poster) ? poster : null);
  }
}
