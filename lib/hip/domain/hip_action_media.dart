/// Theme-matched action media: which bundled picture to show for the theme
/// in effect.
///
/// Source of truth is `assets/hip/action-media.json`, written by
/// `tools/media/build_themed_media.py` from the Pose-Hub alpha masters. Per
/// Pose-Hub action id it lists the dark asset (the frozen v0.2.0 release on
/// the `#101013` stage) and its light counterpart (same frames on the neutral
/// light stage, beside it in a `light/` folder), each with SHA-256, size,
/// duration and frame rate; the self-test stills are listed the same way.
///
/// The content pack and the action kits keep naming the dark asset; this
/// class maps it to the light one. A path without a light counterpart is
/// returned unchanged, so a new clip shows its dark stage until the pipeline
/// has run for it (and `test/hip/hip_action_media_test.dart` fails meanwhile).
class HipActionMedia {
  HipActionMedia._(this._light, this.byId);

  static const assetPath = 'assets/hip/action-media.json';

  /// No light assets (before the manifest is loaded, or if it is missing).
  static final empty = HipActionMedia._(const {}, const {});

  /// Dark asset path -> light asset path (videos, posters, stills).
  final Map<String, String> _light;

  /// Pose-Hub action id (`h-squat`, `supine-cross-demo`, `a-thomas/thomas-a`)
  /// -> its theme pair, for the action kits.
  final Map<String, HipThemedMedia> byId;

  factory HipActionMedia.fromJson(Map<String, dynamic> json) {
    final light = <String, String>{};
    final byId = <String, HipThemedMedia>{};
    String asset(Object? e) => (e as Map)['asset'] as String;
    final actions = (json['actions'] as Map?) ?? const {};
    for (final MapEntry(:key, :value) in actions.entries) {
      final a = value as Map;
      final dark = a['dark'] as Map, lite = a['light'] as Map;
      final pair = HipThemedMedia(
        darkVideo: asset(dark['video']),
        darkPoster: asset(dark['poster']),
        lightVideo: asset(lite['video']),
        lightPoster: asset(lite['poster']),
      );
      byId[key as String] = pair;
      light[pair.darkVideo!] = pair.lightVideo!;
      light[pair.darkPoster] = pair.lightPoster;
    }
    final stills = (json['stills'] as Map?) ?? const {};
    for (final MapEntry(key: set, :value) in stills.entries) {
      final items = ((value as Map)['items'] as Map?) ?? const {};
      for (final MapEntry(:key, value: it) in items.entries) {
        final m = it as Map;
        final pair = HipThemedMedia(
          darkPoster: asset(m['dark']),
          lightPoster: asset(m['light']),
        );
        byId['$set/$key'] = pair;
        light[pair.darkPoster] = pair.lightPoster;
      }
    }
    return HipActionMedia._(Map.unmodifiable(light), Map.unmodifiable(byId));
  }

  /// The light counterpart of [darkAsset], if bundled.
  String? lightOf(String? darkAsset) =>
      darkAsset == null ? null : _light[darkAsset];

  bool hasLight(String? darkAsset) => lightOf(darkAsset) != null;

  /// [asset] for the dark theme, its light counterpart (when there is one)
  /// for the light theme.
  String resolve(String asset, {required bool dark}) =>
      dark ? asset : (_light[asset] ?? asset);

  /// Every dark asset that has a light counterpart.
  Iterable<String> get darkAssets => _light.keys;
}

/// One action's assets in both themes. Stills have no video.
class HipThemedMedia {
  const HipThemedMedia({
    this.darkVideo,
    required this.darkPoster,
    this.lightVideo,
    required this.lightPoster,
  });
  final String? darkVideo;
  final String darkPoster;
  final String? lightVideo;
  final String lightPoster;

  String poster({required bool dark}) => dark ? darkPoster : lightPoster;
  String? video({required bool dark}) => dark ? darkVideo : lightVideo;
}
