// AI 定制：SDK（ugk_coach）拥有教练决策；App 只接配置、资产、记账与免责标记。
// 结构沿用 3D-Body feat/ai-coach `app/lib/coach/coach_service.dart`（PR #122），
// 本轮移除 App 的范围交集、剂量规则和自动预设回落，统一采用 Coach Agent v2。
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:ugk_coach/ugk_coach.dart' as uc;

import '../../core/storage/local_state_storage.dart';
import '../domain/hip_models.dart';
import 'coach_config.dart';
import 'coach_device_id.dart';
import 'usage_store.dart';

typedef AssetReader = Future<String> Function(String path);

/// HipLab 的 AI 训练助理。
///
/// - 目录：随包 `assets/coach/catalog.json`（Pose-Hub 目录的 hiplab 范围快照），
///   本轮只用随包可信快照，不从远端扩展范围或替换动作元数据。
/// - 范围：profile 的 45 个动作 ID 白名单，由 SDK 在搜索和交付时执行。
///   App 不过滤模型结果、不提取意图或槽位，也不自动创建兜底计划。
class CoachService {
  CoachService({
    this.config = CoachConfig.fromEnvironment,
    required this.content,
    uc.LlmClient? client,
    CoachUsageStore? usage,
    LocalStateStorage? storage,
    AssetReader? readAsset,
    Future<String> Function()? deviceId,
    @visibleForTesting this.maxRequestRetries,
  }) : _client = !config.configured
           ? null
           : client ??
                 config.createClient(
                   deviceId: deviceId ?? CoachDeviceId.device.load,
                 ),
       usage = usage ?? CoachUsageStore.device(),
       _storage = storage ?? SharedPreferencesLocalStateStorage(),
       _read = readAsset ?? rootBundle.loadString;

  static const catalogAsset = 'assets/coach/catalog.json';
  static const profileAsset = 'assets/coach/hiplab.json';
  static const storageKey = 'hip.coach.v1';

  final CoachConfig config;
  final int? maxRequestRetries;
  final HipContent content;
  final CoachUsageStore usage;

  final uc.LlmClient? _client;
  final LocalStateStorage _storage;
  final AssetReader _read;

  late final uc.CatalogRepository _repo;
  late final uc.CoachProfile _profile;
  uc.CoachConversationController? _conversation;
  bool _disposed = false;

  uc.CoachConversationController? get conversation => _conversation;
  uc.ToolGate get gate => uc.ToolGate(catalog: catalog, profile: profile);
  Future<void>? _loading;
  bool _disclaimerAccepted = false;

  /// No credential means every AI entry stays hidden; no model is created.
  bool get configured => _client != null;
  bool get disclaimerAccepted => _disclaimerAccepted;

  uc.CoachProfile get profile => _profile;
  uc.Catalog get catalog => _repo.current;

  Future<void> load() => _loading ??= _load();

  Future<void> _load() async {
    // The bundled profile and the App library are the trust boundary. A remote
    // catalog must not expand or replace this release's admitted actions.
    _repo = uc.CatalogRepository(
      bundled: uc.BundledCatalogSource(() => _read(catalogAsset)),
    );
    await _repo.load();
    final profileJson =
        jsonDecode(await _read(profileAsset)) as Map<String, Object?>;
    if (_disposed) return;
    _profile = uc.CoachProfile.fromJson(profileJson);
    if (_client case final client?) {
      // Production uses the SDK's complete defaults. Only isolated failure
      // tests inject a retry budget so they need not wait through backoff.
      final agent = maxRequestRetries == null
          ? uc.CoachAgent(
              client: client,
              catalog: () => _repo.current,
              profile: _profile,
              usage: usage,
              appId: 'hiplab-app',
            )
          : uc.CoachAgent(
              client: client,
              catalog: () => _repo.current,
              profile: _profile,
              usage: usage,
              appId: 'hiplab-app',
              maxRequestRetries: maxRequestRetries!,
            );
      _conversation = uc.CoachConversationController(agent: agent);
    }
    await usage.load();
    try {
      final raw = await _storage.read(storageKey);
      if (raw != null) {
        _disclaimerAccepted =
            (jsonDecode(raw) as Map)['disclaimerAccepted'] == true;
      }
    } on Object {
      _disclaimerAccepted = false;
    }
  }

  Future<void> acceptDisclaimer() async {
    _disclaimerAccepted = true;
    try {
      await _storage.write(
        storageKey,
        jsonEncode({'disclaimerAccepted': true}),
      );
    } on Object {
      // 写不进去下次再提示一次即可。
    }
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await _conversation?.dispose();
    if (_client case final uc.OpenAiCompatibleClient client) client.close();
  }

  @visibleForTesting
  uc.PlanValidator get validator =>
      uc.PlanValidator(catalog: catalog, profile: profile);
}
