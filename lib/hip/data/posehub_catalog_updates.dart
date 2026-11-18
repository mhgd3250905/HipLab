import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ugk_coach/ugk_coach.dart' as coach;
import 'package:ugk_trainer_runtime/ugk_trainer_runtime.dart'
    show
        PoseHubActionLibrary,
        PoseHubCatalogChannel,
        PoseHubCatalogStore,
        PoseHubCatalogHttpClient,
        PoseHubCatalogHttpResponse,
        PoseHubCatalogProgressHttpClient,
        PoseHubCatalogUpdateConfig,
        PoseHubCatalogUpdateEvent,
        PoseHubCatalogUpdateOutcome,
        PoseHubCatalogUpdater,
        createPoseHubCatalogFileStore,
        createPoseHubCatalogHttpClient,
        poseHubPackVersionOf;

const hipBundledPoseHubPack = 'r2-v18';
const hipBundledPoseHubCatalogSha256 =
    '1de7303f94fe0441ed4d006d4a4aa7ceac0e160b1c2527ae0f875b112bb52203';

/// Action-library hot update (SDK `PoseHubCatalogUpdater`).
///
/// Checks the channel pointer once per launch and again on resume once a day
/// has passed. The SDK atomically activates a newer catalogue after its
/// display assets have all been verified.
///
/// The channel is fixed at build time: `--dart-define=POSEHUB_CATALOG_CHANNEL=
/// dev|beta|stable`, defaulting to `stable`.
class PoseHubCatalogUpdates with WidgetsBindingObserver {
  PoseHubCatalogUpdates._(this.updater, this._http);

  static const channelName = String.fromEnvironment(
    'POSEHUB_CATALOG_CHANNEL',
    defaultValue: 'stable',
  );

  static PoseHubCatalogChannel get channel =>
      PoseHubCatalogChannel.values.firstWhere(
        (c) => c.name == channelName,
        orElse: () => PoseHubCatalogChannel.stable,
      );

  static PoseHubCatalogUpdateConfig get buildConfig =>
      PoseHubCatalogUpdateConfig(channel: channel);

  final PoseHubCatalogUpdater updater;
  final _DisplayUpdateHttp _http;

  /// The verified cache opened by [start]; null when updates are disabled.
  static PoseHubCatalogStore? activeStore;

  /// Opens the verified cache before the first catalogue load. The UI calls
  /// [onAppReady] after its dialog host has subscribed to the update stream.
  /// Returns null on web or when the support directory is unavailable.
  static Future<PoseHubCatalogUpdates?> start({
    void Function(PoseHubCatalogUpdateEvent event)? onEvent,
    void Function(PoseHubCatalogUpdateOutcome outcome)? onOutcome,
    PoseHubCatalogStore? store,
    PoseHubCatalogHttpClient? http,
    String? assetRootDirectory,
    Future<coach.PoseHubAppTestCatalog> Function()? loadLocal,
  }) async {
    if (kIsWeb && store == null) return null;
    try {
      final resolved =
          store ??
          createPoseHubCatalogFileStore(
            '${(await getApplicationSupportDirectory()).path}/posehub-display-catalog',
          );
      PoseHubActionLibrary.useVerifiedCache(resolved);
      activeStore = resolved;
      final config = buildConfig;
      final client = _DisplayUpdateHttp(
        http ?? createPoseHubCatalogHttpClient(),
        config.pointerUri,
      );
      final updates = PoseHubCatalogUpdates._(
        PoseHubCatalogUpdater.withPersistentAssets(
          config: config,
          store: resolved,
          http: client,
          assetRootDirectory: assetRootDirectory,
          loadLocal: loadLocal,
          onEvent: onEvent,
        ),
        client,
      );
      updates._onOutcome = onOutcome;
      WidgetsBinding.instance.addObserver(updates);
      return updates;
    } on Object catch (error) {
      debugPrint('PoseHub catalogue updates disabled: $error');
      return null;
    }
  }

  void Function(PoseHubCatalogUpdateOutcome outcome)? _onOutcome;

  Future<PoseHubCatalogUpdateOutcome>? _running;

  void _check() => unawaited(_run(updater.maybeCheck));

  Future<PoseHubCatalogUpdateOutcome> checkNow() => _run(updater.checkNow);

  Future<PoseHubCatalogUpdateOutcome> _run(
    Future<PoseHubCatalogUpdateOutcome> Function() check,
  ) => _running ??= _finish(check).whenComplete(() {
    _running = null;
  });

  Future<PoseHubCatalogUpdateOutcome> _finish(
    Future<PoseHubCatalogUpdateOutcome> Function() check,
  ) async {
    final pointerBefore = _http.pointerRequests;
    final payloadBefore = _http.payloadRequests;
    final bytesBefore = _http.payloadBytes;
    final outcome = await check();
    if (outcome != PoseHubCatalogUpdateOutcome.throttled) {
      debugPrint(
        'PoseHubDisplayUpdate outcome=${outcome.name} '
        'pointerRequests=${_http.pointerRequests - pointerBefore} '
        'payloadRequests=${_http.payloadRequests - payloadBefore} '
        'payloadBytes=${_http.payloadBytes - bytesBefore}',
      );
    }
    if (_disposed) return outcome;
    if (outcome == PoseHubCatalogUpdateOutcome.updated) {
      PoseHubActionLibrary.resetForNextSession();
    }
    _onOutcome?.call(outcome);
    return outcome;
  }

  bool _disposed = false;
  bool _appReady = false;

  void onAppReady() {
    if (_appReady || _disposed) return;
    _appReady = true;
    _check();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_appReady && state == AppLifecycleState.resumed) _check();
  }

  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
  }
}

/// Tracks requests in the display updater only. Training downloads use the
/// SDK's separate, on-demand media and voice repositories.
class _DisplayUpdateHttp implements PoseHubCatalogProgressHttpClient {
  _DisplayUpdateHttp(this.client, this.pointer);

  final PoseHubCatalogHttpClient client;
  final Uri pointer;
  int pointerRequests = 0;
  int payloadRequests = 0;
  int payloadBytes = 0;

  @override
  Future<PoseHubCatalogHttpResponse> get(
    Uri uri, {
    Map<String, String> headers = const {},
    int maxBytes = 64 * 1024 * 1024,
  }) =>
      _count(uri, () => client.get(uri, headers: headers, maxBytes: maxBytes));

  @override
  Future<PoseHubCatalogHttpResponse> getWithProgress(
    Uri uri, {
    required Map<String, String> headers,
    required int maxBytes,
    required void Function(int receivedBytes) onBytes,
  }) => _count(uri, () async {
    final delegate = client;
    if (delegate is PoseHubCatalogProgressHttpClient) {
      return delegate.getWithProgress(
        uri,
        headers: headers,
        maxBytes: maxBytes,
        onBytes: onBytes,
      );
    }
    final response = await delegate.get(
      uri,
      headers: headers,
      maxBytes: maxBytes,
    );
    if (response.statusCode == 200) onBytes(response.body.length);
    return response;
  });

  Future<PoseHubCatalogHttpResponse> _count(
    Uri uri,
    Future<PoseHubCatalogHttpResponse> Function() request,
  ) async {
    final isPointer = uri == pointer;
    if (isPointer) {
      pointerRequests++;
    } else {
      payloadRequests++;
    }
    final response = await request();
    if (!isPointer && response.statusCode == 200) {
      payloadBytes += response.body.length;
    }
    return response;
  }
}

/// A 64-hex revision for the catalogue in use: the audited SHA for the
/// bundled baseline, else a content digest of the verified cached catalogue.
String poseHubCatalogRevisionOf(coach.PoseHubAppTestCatalog catalog) {
  if (poseHubPackVersionOf(catalog) == hipBundledPoseHubPack) {
    return hipBundledPoseHubCatalogSha256;
  }
  return coach.sha256Hex(utf8.encode(jsonEncode(catalog.raw)));
}
