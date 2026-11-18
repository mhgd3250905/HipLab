// HipLab configuration for the SDK public media policy.
import 'package:flutter/services.dart';
import 'package:ugk_coach/ugk_coach.dart' as coach;
import 'package:ugk_trainer_runtime/ugk_trainer_runtime.dart' as trainer;

import 'hip_action_scope.dart';
import 'hip_public_catalog.dart';
import 'posehub_catalog_updates.dart';

abstract final class HipPublicMedia {
  static const posterRoot = 'assets/public_posters/';
  static const artworkRoot = '$posterRoot$hipBundledPoseHubPack/';
  static trainer.TrainingMediaPolicy? current;

  static bool _hasBundledArtwork(String id) =>
      id == 'n-thomas-test' || hiplabCoachAuthorizedActionIds.contains(id);

  static String? coverAssetFor(String id) =>
      _hasBundledArtwork(id) ? '${artworkRoot}cover/$id.webp' : null;

  static String? thumbnailAssetFor(String id) =>
      _hasBundledArtwork(id) ? '${artworkRoot}thumbnail/$id.webp' : null;

  static trainer.TrainingMediaPolicy forLibrary(
    trainer.TrainingMediaPolicy policy,
  ) => policy is _HipPublicMediaPolicy ? policy.library : policy;

  static coach.PoseHubPackAction? bundledActionFor(
    trainer.TrainingMediaPolicy? policy,
    String id,
  ) => policy is _HipPublicMediaPolicy ? policy.bundled.tryGet(id) : null;

  static Future<trainer.TrainingMediaPolicy> load({
    coach.PoseHubAppTestCatalog? activeCatalog,
    String? rootDirectory,
    bool prefetchBeforeTraining = false,
  }) async {
    final catalog = activeCatalog ?? await loadHipPublicCatalog();
    final bundled =
        trainer.poseHubPackVersionOf(catalog) == hipBundledPoseHubPack
        ? catalog
        : await loadHipBundledPublicCatalog();
    final assetsBySha = <String, String>{
      for (final action in bundled.allActions)
        action.cover.sha256: ?coverAssetFor(action.id),
      for (final action in bundled.allActions)
        action.thumbnail.sha256: ?thumbnailAssetFor(action.id),
    };
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final standing = manifest.listAssets().where((path) {
      if (!path.startsWith(posterRoot)) return false;
      final name = path.substring(posterRoot.length);
      return !name.contains('/') && name.endsWith('.webp');
    }).toSet();
    final repository = await trainer.TrainingMediaRepository.fromCatalog(
      catalog: catalog,
      catalogRevision: poseHubCatalogRevisionOf(catalog),
      mediaBaseUrls: [trainer.PoseHubActionLibrary.mediaBaseUriFor(catalog)],
      rootDirectory: rootDirectory,
      bundledFileLoader: (file) async {
        final path = assetsBySha[file.sha256];
        if (path == null) return null;
        final bytes = await rootBundle.load(path);
        return bytes.buffer.asUint8List(
          bytes.offsetInBytes,
          bytes.lengthInBytes,
        );
      },
    );
    return _HipPublicMediaPolicy(
      repository: repository,
      standing: standing,
      bundled: bundled,
      prefetchBeforeTraining: prefetchBeforeTraining,
    );
  }
}

class _HipPublicMediaPolicy extends trainer.TrainingMediaPolicy {
  _HipPublicMediaPolicy({
    required super.repository,
    required super.prefetchBeforeTraining,
    required this.standing,
    required this.bundled,
    this.preferCover = false,
  });

  final Set<String> standing;
  final coach.PoseHubAppTestCatalog bundled;
  final bool preferCover;

  late final library = _HipPublicMediaPolicy(
    repository: repository,
    prefetchBeforeTraining: prefetchBeforeTraining,
    standing: standing,
    bundled: bundled,
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
