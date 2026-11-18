import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiplab/hip/control/hip_store.dart';
import 'package:hiplab/hip/data/hip_public_catalog.dart';
import 'package:hiplab/hip/data/hip_public_media.dart';
import 'package:hiplab/hip/data/posehub_catalog_updates.dart';
import 'package:hiplab/hip/ui/hip_app.dart';
import 'package:ugk_coach/ugk_coach.dart' as coach;
import 'package:ugk_coach_ui/ugk_coach_ui.dart' show PoseHubDisplayUpdateDialog;
import 'package:ugk_trainer_runtime/ugk_trainer_runtime.dart' as trainer;

import 'hip_domain_test.dart' show loadContent, MemoryStorage;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('r2-v11 updates display assets once and relaunch reuses them', () async {
    final directory = await Directory('.dart_tool').createTemp('posehub-test-');
    addTearDown(() async {
      trainer.PoseHubActionLibrary.useVerifiedCache(null);
      PoseHubCatalogUpdates.activeStore = null;
      await directory.delete(recursive: true);
    });
    trainer.PoseHubCatalogStore openStore() =>
        trainer.createPoseHubCatalogFileStore('${directory.path}/catalog');

    final catalogBytes = await File(hipPublicCatalogAsset).readAsBytes();
    final semanticsBytes = await File(hipPublicSemanticsAsset).readAsBytes();
    final published = coach.PoseHubAppTestCatalog.fromBytes(
      catalogBytes,
      semanticCatalogBytes: semanticsBytes,
    );
    final previous = coach.PoseHubAppTestCatalog.fromBytes(
      utf8.encode(jsonEncode({...published.raw, 'pack': 'r2-v11'})),
      semanticCatalogBytes: semanticsBytes,
    );
    const pack = 'r2-v18';
    expect(trainer.poseHubPackVersionOf(published), pack);
    expect(hipBundledPoseHubPack, trainer.PoseHubActionLibrary.packVersion);
    expect(coach.sha256Hex(catalogBytes), hipBundledPoseHubCatalogSha256);
    expect(
      hipBundledPoseHubCatalogSha256,
      trainer.PoseHubActionLibrary.catalogSha256,
    );
    final pointer = PoseHubCatalogUpdates.buildConfig.pointerUri;
    final catalog = pointer.resolve('../$pack/catalog.json');
    final mediaBase = trainer.PoseHubActionLibrary.mediaBaseUriFor(published);
    final artwork = {
      for (final action in published.allActions) ...{
        action.cover.resolve(mediaBase): HipPublicMedia.coverAssetFor(
          action.id,
        )!,
        action.thumbnail.resolve(mediaBase): HipPublicMedia.thumbnailAssetFor(
          action.id,
        )!,
      },
    };
    final http = _CatalogFixtureHttp(pointer, {
      pointer: () async => utf8.encode(
        jsonEncode({
          'schema': 1,
          'pack': pack,
          'catalog': catalog.toString(),
          'catalog_bytes': catalogBytes.length,
          'catalog_sha256': coach.sha256Hex(catalogBytes),
          'min_sdk': '0.8.0',
          'published_at': '2026-11-18T11:35:15+08:00',
        }),
      ),
      catalog: () async => catalogBytes,
      catalog.resolve(published.semanticCatalogFile.path): () async =>
          semanticsBytes,
      for (final entry in artwork.entries)
        entry.key: () => File(entry.value).readAsBytes(),
    });

    Future<PoseHubCatalogUpdates> launch() async {
      final store = openStore();
      return (await PoseHubCatalogUpdates.start(
        store: store,
        http: http,
        assetRootDirectory: directory.path,
        loadLocal: () async =>
            await trainer.readVerifiedPoseHubCatalog(store) ?? previous,
      ))!;
    }

    final first = await launch();
    final progress = <coach.PoseHubDisplayUpdateProgress>[];
    final changes = <coach.PoseHubAppTestCatalog>[];
    final progressSub = first.updater.displayProgress.listen(progress.add);
    final changesSub = first.updater.catalogChanges.listen(changes.add);
    try {
      expect(
        await first.checkNow(),
        trainer.PoseHubCatalogUpdateOutcome.updated,
      );
    } finally {
      await progressSub.cancel();
      await changesSub.cancel();
      first.dispose();
    }
    expect(progress.first.phase, coach.PoseHubDisplayUpdatePhase.downloading);
    expect(progress.last.phase, coach.PoseHubDisplayUpdatePhase.completed);
    expect(progress.last.completedFiles, 500);
    expect(progress.last.receivedBytes, progress.last.totalBytes);
    expect(changes.map(trainer.poseHubPackVersionOf), [pack]);

    final firstRequests = http.requests.toList();
    expect(firstRequests, containsAll([pointer, catalog, ...artwork.keys]));
    expect(firstRequests, hasLength(501));
    expect(firstRequests.where((uri) => uri.path.endsWith('.mp4')), isEmpty);
    expect(firstRequests.where((uri) => uri.path.endsWith('.m4a')), isEmpty);

    final active = (await trainer.readVerifiedPoseHubCatalog(openStore()))!;
    expect(trainer.poseHubPackVersionOf(active), pack);
    final action = active.tryGet('s-pigeon')!;
    final cache = trainer.PoseHubImageCache(
      rootDirectory: directory.path,
      loadBytes: (_, _) => throw StateError('Display file was not persisted'),
    );
    final firstFrame = await cache.ensureFile(
      action.cover,
      mediaBaseUri: mediaBase,
    );
    expect(
      coach.sha256Hex(await File.fromUri(firstFrame).readAsBytes()),
      action.cover.sha256,
    );

    http.requests.clear();
    final second = await launch();
    progress.clear();
    final secondProgress = second.updater.displayProgress.listen(progress.add);
    try {
      expect(
        await second.checkNow(),
        trainer.PoseHubCatalogUpdateOutcome.notModified,
      );
    } finally {
      await secondProgress.cancel();
      second.dispose();
    }
    expect(http.requests, [pointer]);
    expect(progress, isEmpty);
  });

  testWidgets('startup dialog reports a failed display update and can retry', (
    tester,
  ) async {
    final pointer = PoseHubCatalogUpdates.buildConfig.pointerUri;
    final downloadStarted = Completer<void>();
    final interruptDownload = Completer<void>();
    var hasNewerVersion = true;
    final situation = (await tester.runAsync(() async {
      final root = await Directory('.dart_tool').createTemp('posehub-dialog-');
      final bytes = await File(hipPublicCatalogAsset).readAsBytes();
      final baseline = await loadHipBundledPublicCatalog();
      const nextPack = 'r2-v19';
      final nextCatalog = pointer.resolve('../r2-v19/catalog.json');
      final http = _CatalogFixtureHttp(pointer, {
        pointer: () async {
          final pack = hasNewerVersion ? nextPack : hipBundledPoseHubPack;
          return utf8.encode(
            jsonEncode({
              'schema': 1,
              'pack': pack,
              'catalog': pointer.resolve('../$pack/catalog.json').toString(),
              'catalog_bytes': bytes.length,
              'catalog_sha256': coach.sha256Hex(bytes),
              'min_sdk': '0.8.0',
              'published_at': '2026-11-18T11:35:15+08:00',
            }),
          );
        },
        nextCatalog: () async {
          downloadStarted.complete();
          await interruptDownload.future;
          throw const SocketException('fixture transfer interrupted');
        },
      });
      final store = trainer.MemoryPoseHubCatalogStore();
      final updates = (await PoseHubCatalogUpdates.start(
        store: store,
        http: http,
        assetRootDirectory: root.path,
        loadLocal: () async => baseline,
      ))!;
      final policy = await HipPublicMedia.load(
        activeCatalog: baseline,
        rootDirectory: root.path,
      );
      return (root: root, assets: store, updates: updates, policy: policy);
    }))!;
    final store = HipStore(content: loadContent(), storage: MemoryStorage());

    try {
      await tester.pumpWidget(
        HipApp(
          store: store,
          mediaPolicy: situation.policy,
          catalogUpdates: situation.updates,
          videoEnabled: false,
        ),
      );
      for (var i = 0; i < 80 && !downloadStarted.isCompleted; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)),
        );
        await tester.pump(const Duration(milliseconds: 16));
      }
      expect(downloadStarted.isCompleted, isTrue);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(PoseHubDisplayUpdateDialog), findsOneWidget);
      expect(find.text('r2-v19'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);

      interruptDownload.complete();
      final failed = await tester.runAsync(situation.updates.checkNow);
      expect(failed, trainer.PoseHubCatalogUpdateOutcome.failed);
      await tester.pumpAndSettle();
      expect(find.text('重试'), findsOneWidget);
      expect(
        await trainer.readVerifiedPoseHubCatalog(situation.assets),
        isNull,
      );
      expect(
        trainer.poseHubPackVersionOf(situation.policy.catalog),
        hipBundledPoseHubPack,
      );

      hasNewerVersion = false;
      await tester.tap(find.text('重试'));
      await tester.runAsync(situation.updates.checkNow);
      await tester.pumpAndSettle();
      expect(find.byType(PoseHubDisplayUpdateDialog), findsNothing);
      expect(find.byKey(const ValueKey('home-more')), findsOneWidget);
    } finally {
      if (!interruptDownload.isCompleted) interruptDownload.complete();
      await tester.pumpWidget(const SizedBox.shrink());
      situation.updates.dispose();
      situation.policy.repository.dispose();
      HipPublicMedia.current = null;
      PoseHubCatalogUpdates.activeStore = null;
      trainer.PoseHubActionLibrary.useVerifiedCache(null);
      store.dispose();
      await tester.runAsync(() => situation.root.delete(recursive: true));
    }
  });
}

class _CatalogFixtureHttp implements trainer.PoseHubCatalogHttpClient {
  _CatalogFixtureHttp(this.pointer, this.files);
  final Uri pointer;
  final Map<Uri, Future<List<int>> Function()> files;
  final requests = <Uri>[];

  @override
  Future<trainer.PoseHubCatalogHttpResponse> get(
    Uri uri, {
    Map<String, String> headers = const {},
    int maxBytes = 64 * 1024 * 1024,
  }) async {
    requests.add(uri);
    if (uri == pointer && headers['If-None-Match'] == 'fixture-etag') {
      return trainer.PoseHubCatalogHttpResponse(304, Uint8List(0));
    }
    final read = files[uri];
    if (read == null) throw StateError('Unexpected fixture request $uri');
    final bytes = await read();
    if (bytes.length > maxBytes) {
      throw StateError('Fixture exceeds request cap');
    }
    return trainer.PoseHubCatalogHttpResponse(
      200,
      Uint8List.fromList(bytes),
      etag: uri == pointer ? 'fixture-etag' : null,
    );
  }
}
