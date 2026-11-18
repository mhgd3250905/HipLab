import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiplab/hip/data/hip_action_scope.dart';
import 'package:hiplab/hip/data/hip_public_catalog.dart';
import 'package:hiplab/hip/data/hip_public_media.dart';
import 'package:hiplab/hip/data/hip_shared_library.dart';
import 'package:ugk_coach/ugk_coach.dart' as coach;
import 'package:ugk_trainer_runtime/ugk_trainer_runtime.dart' as trainer;

/// Uses the real public manifest while keeping host widget tests off disk,
/// network and native video channels. SDK tests own decoder/cache behavior.
class PublicMediaFixture implements trainer.CatalogMediaRepository {
  PublicMediaFixture({coach.PoseHubAppTestCatalog? catalog})
    : catalog =
          catalog ??
          coach.PoseHubAppTestCatalog.fromBytes(
            File(hipPublicCatalogAsset).readAsBytesSync(),
            semanticCatalogBytes: File(
              hipPublicSemanticsAsset,
            ).readAsBytesSync(),
          );

  @override
  final coach.PoseHubAppTestCatalog catalog;
  final requested = <String>[];
  final requestedArtwork = <coach.PoseHubPackFile>[];
  late final _videoPaths = {
    for (final action in catalog.allActions) ...[
      action.video.path,
      for (final media in action.themedMedia.values) media.video.path,
    ],
  };
  final _states = <String, ValueNotifier<trainer.CatalogMediaDownloadState>>{};
  late final policy = trainer.TrainingMediaPolicy(
    repository: this,
    posterAssetRoot: HipPublicMedia.posterRoot,
    prefetchBeforeTraining: false,
  );

  PublicMediaFixture withUpdatedThumbnail(String id, String sourceId) {
    final thumbnail = catalog.tryGet(id)!.thumbnail;
    final sha256 = catalog.tryGet(sourceId)!.thumbnail.sha256;
    return PublicMediaFixture(
      catalog: coach.PoseHubAppTestCatalog.fromJson({
        ...catalog.raw,
        'actions': [
          for (final raw in catalog.raw['actions']! as List)
            if ((raw as Map<String, Object?>)['id'] == id)
              {
                ...raw,
                'files': {
                  ...raw['files']! as Map<String, Object?>,
                  'thumbnail': {...thumbnail.raw, 'sha256': sha256},
                },
              }
            else
              raw,
        ],
      }),
    );
  }

  @override
  Uri get mediaBaseUri => Uri.parse('file:///host-test-public-media/');

  bool isVideoFile(coach.PoseHubPackFile file) =>
      _videoPaths.contains(file.path);

  @override
  Future<Uri> ensureFile(coach.PoseHubPackFile file) {
    if (isVideoFile(file)) {
      requested.add(file.path);
    } else {
      requestedArtwork.add(file);
    }
    return Future.error(
      StateError('Host tests use the bundled media fallback'),
    );
  }

  @override
  Future<Uri> ensureAction(String actionId) =>
      ensureFile(catalog.tryGet(actionId)!.video);

  @override
  ValueListenable<trainer.CatalogMediaDownloadState> watchFile(
    coach.PoseHubPackFile file,
  ) => _states.putIfAbsent(
    file.path,
    () => ValueNotifier(
      const trainer.CatalogMediaDownloadState(
        phase: trainer.CatalogMediaDownloadPhase.idle,
      ),
    ),
  );

  @override
  ValueListenable<trainer.CatalogMediaDownloadState> watchAction(String id) =>
      watchFile(catalog.tryGet(id)!.video);

  @override
  Future<Uri?> cachedVideo(String actionId) async => null;
  @override
  VoidCallback retainVideo(String actionId) => () {};
  @override
  Future<int> videoCacheBytes() async => 0;
  @override
  Future<void> clearVideoCache() async {}
  @override
  void dispose() {
    for (final state in _states.values) {
      state.dispose();
    }
  }
}

/// HipLab has no SDK standing index. Resolve that absence inside the fake
/// clock so the artwork request can be asserted without real asset I/O.
class MediaArtworkTestScope extends StatelessWidget {
  MediaArtworkTestScope({required this.policy, required this.child, super.key});

  final ValueListenable<trainer.TrainingMediaPolicy> policy;
  final Widget child;
  final _bundle = _NoStandingIndexBundle();

  @override
  Widget build(BuildContext context) => DefaultAssetBundle(
    bundle: _bundle,
    child: ValueListenableBuilder(
      valueListenable: policy,
      builder: (context, value, child) =>
          trainer.TrainingMediaPolicyScope(policy: value, child: child!),
      child: child,
    ),
  );
}

class _NoStandingIndexBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) => rootBundle.load(key);

  @override
  Future<String> loadString(String key, {bool cache = true}) =>
      key == '${trainer.PoseHubActionLibrary.standingAssetRoot}index.json'
      ? SynchronousFuture('{"schema":1,"actions":{}}')
      : super.loadString(key, cache: cache);
}

class _UnsupportedPlatform extends trainer.PackedAlphaPlatform {
  @override
  bool get isSupported => false;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

PublicMediaFixture installPublicMediaFixture({bool sharedLibrary = false}) {
  final oldPolicy = HipPublicMedia.current;
  final oldLibrary = HipSharedLibrary.current;
  final oldPlatform = trainer.UgkPackedAlphaVideo.debugPlatform;
  final fixture = PublicMediaFixture();
  HipPublicMedia.current = fixture.policy;
  HipSharedLibrary.current = sharedLibrary
      ? hipSharedLibraryConfig(hipActionScope(fixture.catalog.toAiCatalog()))
      : null;
  trainer.UgkPackedAlphaVideo.debugPlatform = _UnsupportedPlatform();
  addTearDown(() {
    HipPublicMedia.current = oldPolicy;
    HipSharedLibrary.current = oldLibrary;
    trainer.UgkPackedAlphaVideo.debugPlatform = oldPlatform;
    fixture.dispose();
  });
  return fixture;
}
