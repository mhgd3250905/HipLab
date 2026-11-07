import 'dart:io';

import 'package:flutter/foundation.dart';
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
  PublicMediaFixture()
    : catalog = coach.PoseHubAppTestCatalog.fromBytes(
        File(hipPublicCatalogAsset).readAsBytesSync(),
        semanticCatalogBytes: File(
          hipPublicSemanticsAsset,
        ).readAsBytesSync(),
      );

  @override
  final coach.PoseHubAppTestCatalog catalog;
  final requested = <String>[];
  final _states = <String, ValueNotifier<trainer.CatalogMediaDownloadState>>{};
  late final policy = trainer.TrainingMediaPolicy(
    repository: this,
    posterAssetRoot: HipPublicMedia.posterRoot,
    prefetchBeforeTraining: false,
  );

  @override
  Uri get mediaBaseUri => Uri.parse('file:///host-test-public-media/');

  @override
  Future<Uri> ensureFile(coach.PoseHubPackFile file) {
    requested.add(file.path);
    return Future.error(StateError('Host tests must not request video files'));
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
