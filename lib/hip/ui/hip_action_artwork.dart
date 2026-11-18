import 'package:flutter/material.dart';
import 'package:ugk_coach/ugk_coach.dart' as coach;
import 'package:ugk_trainer_runtime/ugk_trainer_runtime.dart' as trainer;

import '../data/hip_library_poster_bounds.dart';
import '../data/hip_public_media.dart';
import '../data/hip_shared_library.dart';
import 'hip_poster_bounds_fit.dart';

/// The active catalogue supplies the image; the existing local still covers
/// offline loading, decode failures and actions outside the public catalogue.
class HipActionArtwork extends StatelessWidget {
  const HipActionArtwork({
    super.key,
    required this.actionId,
    required this.fallback,
    this.thumbnail = false,
    this.preferCover = false,
    this.fit = BoxFit.contain,
    this.bundledThumbnailBounds,
  });

  final String? actionId;
  final Widget fallback;
  final bool thumbnail;
  final bool preferCover;
  final BoxFit fit;
  final Rect? bundledThumbnailBounds;

  static trainer.TrainingMediaPolicy? policyOf(BuildContext context) =>
      trainer.TrainingMediaPolicyScope.maybeOf(context) ??
      HipPublicMedia.current;

  @override
  Widget build(BuildContext context) {
    final bounds = bundledThumbnailBounds;
    Widget frame(Widget artwork) => bounds == null
        ? artwork
        : HipPosterBoundsFit(
            sourceSize: const Size.square(libraryPosterPixels),
            bounds: bounds,
            child: artwork,
          );
    final id = actionId;
    if (id == null) return frame(fallback);
    final policy = policyOf(context);
    final action = policy?.actionFor(id);
    if (action == null) return frame(fallback);
    final theme = HipSharedLibrary.theme(context);
    final mediaTheme = theme.isDark
        ? coach.PoseHubMediaTheme.dark
        : coach.PoseHubMediaTheme.light;
    final selected = action.mediaFor(mediaTheme);
    if (preferCover) {
      return trainer.PoseHubCatalogImage(
        id: action.id,
        name: action.nameZh,
        video: selected.video,
        cover: selected.cover,
        thumbnailFile: selected.thumbnail,
        preferCatalogArtwork: true,
        theme: theme,
        repository: policy!.repository,
        legacyFallback: fallback,
        fit: fit,
      );
    }
    final bundled = bounds == null
        ? null
        : HipPublicMedia.bundledActionFor(policy, id)?.thumbnail;
    final useBundledBounds =
        bundled != null && bundled.sha256 == selected.thumbnail.sha256;
    final artwork = trainer.PoseHubStandingImage(
      action: action,
      thumbnail: thumbnail,
      preferCatalogArtwork: true,
      fit: fit,
      theme: theme,
      repository: policy!.repository,
      legacyFallback: useBundledBounds ? fallback : frame(fallback),
    );
    return useBundledBounds ? frame(artwork) : artwork;
  }
}
