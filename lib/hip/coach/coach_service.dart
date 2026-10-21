// AI 定制：SDK 工具会话 + HipLab 的范围交集、预设回落、记账、免责标记。
// 结构沿用 3D-Body feat/ai-coach `app/lib/coach/coach_service.dart`（PR #122），
// 数据换成 HipLab 的内容包 / 动作包 / 内置套路。
import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:ugk_coach/ugk_coach.dart' as uc;

import '../../core/storage/local_state_storage.dart';
import '../domain/hip_library.dart';
import '../domain/hip_models.dart';
import 'coach_auth.dart';
import 'coach_config.dart';
import 'coach_device_id.dart';
import 'template_fallback.dart';
import 'usage_store.dart';

typedef AssetReader = Future<String> Function(String path);

/// 一轮问答在 App 里的结果。
class CoachAnswer {
  const CoachAnswer({
    required this.status,
    this.text = '',
    this.plan,
    this.actions,
    this.presetReason,
    this.tokens = 0,
    this.submissions = 0,
  });

  final uc.TurnStatus status;
  final String text;
  final uc.ValidatedPlan? plan;
  final uc.ValidatedActions? actions;

  /// 非 null = 这是 App 内置预设方案（或离线安全提示），不是 AI 生成的。
  final PresetReason? presetReason;
  final int tokens;
  final int submissions;

  bool get cancelled => status == uc.TurnStatus.cancelled;
  bool get preset => presetReason != null;
  bool get rewritten => submissions > 1;
}

/// HipLab 的 AI 训练助理。
///
/// - 目录：随包 `assets/coach/catalog.json`（Pose-Hub 目录的 hiplab 范围快照），
///   配了 `UGK_COACH_CATALOG_URL` 时可远端更新（SDK 校验大小 / sha256 / 版本后才切换）。
/// - 范围：hiplab profile 白名单 ∩ 动作大全（内容包里有视频、有动作包、不是自测演示）；
///   运行 profile 固定可训练 id 交集，提示词和门禁都排除自测及未随包动作。
class CoachService {
  CoachService({
    this.config = CoachConfig.fromEnvironment,
    required this.content,
    uc.LlmClient? client,
    CoachUsageStore? usage,
    LocalStateStorage? storage,
    AssetReader? readAsset,
    Future<String> Function()? deviceId,
  }) : _configured = client != null || config.configured,
       _client =
           client ?? _clientFor(config, deviceId ?? CoachDeviceId.device.load),
       usage = usage ?? CoachUsageStore.device(),
       _storage = storage ?? SharedPreferencesLocalStateStorage(),
       _read = readAsset ?? rootBundle.loadString;

  static const catalogAsset = 'assets/coach/catalog.json';
  static const profileAsset = 'assets/coach/hiplab.json';
  static const storageKey = 'hip.coach.v1';

  final CoachConfig config;
  final HipContent content;
  final CoachUsageStore usage;

  final bool _configured;
  final uc.LlmClient _client;
  final LocalStateStorage _storage;
  final AssetReader _read;

  late final uc.CatalogRepository _repo;
  late final uc.CoachProfile _profile;
  late final TemplateFallback templates = TemplateFallback(content);
  uc.CoachSession? _session;
  Future<void>? _loading;
  final List<String> _userHistory = [];
  int _generation = 0;
  bool _disclaimerAccepted = false;
  Set<String> _excluded = const {};

  static uc.LlmClient _clientFor(
    CoachConfig c,
    Future<String> Function() deviceId,
  ) {
    if (!c.configured) return const _UnconfiguredLlmClient();
    return uc.OpenAiCompatibleClient(
      config: uc.LlmConfig.ugkWorker.copyWith(
        baseUrl: c.baseUrl,
        model: c.model,
      ),
      auth: CoachRelayAuth(appKey: c.appKey, deviceId: deviceId),
    );
  }

  /// 有模型可调；false 时入口显示「未配置」，问什么都给预设方案。
  bool get configured => _configured;
  bool get disclaimerAccepted => _disclaimerAccepted;

  /// profile 范围里、但不在动作大全（没视频 / 没动作包 / 自测演示）而排除的 id。
  Set<String> get excludedIds => _excluded;
  uc.CoachProfile get profile => _profile;
  uc.Catalog get catalog => _repo.current;

  Future<void> load() => _loading ??= _load().onError((Object error, stack) {
    _loading = null;
    Error.throwWithStackTrace(error, stack);
  });

  Future<void> _load() async {
    final manifest = config.catalogManifestUrl;
    final repo = uc.CatalogRepository(
      bundled: uc.BundledCatalogSource(() => _read(catalogAsset)),
      remote: manifest.isEmpty
          ? null
          : uc.RemoteCatalogSource(manifestUrl: Uri.parse(manifest)),
    );
    final catalog = await repo.load();
    final profileJson = Map<String, Object?>.from(
      jsonDecode(await _read(profileAsset)) as Map,
    );
    final scope = uc.CoachProfile.fromJson(profileJson).scope(catalog);
    _excluded = {
      for (final d in scope)
        if (!inLibrary(content, d.id)) d.id,
    };
    final allowed = {
      for (final d in scope)
        if (inLibrary(content, d.id)) d.id,
    };
    final originalSelect = Map<String, Object?>.from(
      profileJson['select'] as Map,
    );
    // Explicit ids keep future remote catalog additions outside the shipped
    // App's playable library. Selector fields form a union, so do not retain
    // the broader apps/tags selectors alongside these ids.
    profileJson['select'] = {
      'ids': allowed.toList()..sort(),
      'exclude': [
        ...((originalSelect['exclude'] as List?) ?? const []),
        ...assessmentOnlyDrills,
        ...(_excluded.toList()..sort()),
      ],
    };
    final profile = uc.CoachProfile.fromJson(profileJson);
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
    _repo = repo;
    _profile = profile;
    uc.Catalog sessionCatalog() => allowed.isEmpty
        ? uc.Catalog(
            version: repo.current.version,
            taxonomy: repo.current.taxonomy,
            drills: const [],
          )
        : repo.current;
    _session = uc.CoachSession(
      client: _client,
      catalog: sessionCatalog,
      profile: profile,
      // The local unconfigured client is not a provider call. Keep those SDK
      // fallback records out of the App's real model-call usage ledger.
      usage: configured ? usage : uc.MemoryUsageSink(),
      appId: 'hiplab-app',
      fallback: (request) => templates.reply(
        request.userText,
        reason: configured
            ? PresetReason.of(request.reason)
            : PresetReason.notConfigured,
        history: _userHistory,
        context: request.context,
        catalog: sessionCatalog(),
        profile: profile,
      ),
    );
    // 远端目录：后台检查一次，失败保持随包目录。
    if (manifest.isNotEmpty) {
      unawaited(repo.refresh().then((_) {}, onError: (_) {}));
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

  /// Send one turn through SDK tools and its gate, including local presets.
  Future<CoachAnswer> send(
    String text, {
    uc.CoachContext context = const uc.CoachContext(),
    uc.CancelToken? cancel,
  }) async {
    final generation = _generation;
    bool dead() => generation != _generation || (cancel?.isCancelled ?? false);
    if (dead()) return const CoachAnswer(status: uc.TurnStatus.cancelled);
    try {
      await load();
    } on Object {
      return dead()
          ? const CoachAnswer(status: uc.TurnStatus.cancelled)
          : const CoachAnswer(
              status: uc.TurnStatus.error,
              text: '暂时无法读取训练目录，请稍后再试。',
            );
    }
    // reset/cancel may happen while catalog, identity or local usage is loading.
    // Such a turn must never enter the newly initialized SDK conversation.
    if (dead()) return const CoachAnswer(status: uc.TurnStatus.cancelled);
    final result = await _session!.send(text, context: context, cancel: cancel);
    final tokens = result.usage.promptTokens + result.usage.completionTokens;
    if (dead() || result.status == uc.TurnStatus.cancelled) {
      return CoachAnswer(
        status: uc.TurnStatus.cancelled,
        tokens: tokens,
        submissions: result.submissions,
      );
    }
    if (result.status == uc.TurnStatus.ok ||
        result.status == uc.TurnStatus.fallback) {
      _userHistory.add(text.trim());
    }
    return CoachAnswer(
      status: result.status,
      text: switch (result.status) {
        uc.TurnStatus.inputTooLong =>
          '每条最多输入 ${_session!.maxInputChars} 个字符，请缩短后再发送。',
        uc.TurnStatus.limitReached => '本次对话已到上限，请重新开始后继续。',
        uc.TurnStatus.busy => '正在处理上一条消息，请等回复后再发送。',
        uc.TurnStatus.error => '暂时无法提供可用方案，请稍后再试。',
        _ => result.text,
      },
      plan: result.plan,
      actions: result.actions,
      presetReason: result.status == uc.TurnStatus.fallback
          ? (configured
                ? PresetReason.of(result.fallbackReason!)
                : PresetReason.notConfigured)
          : null,
      tokens: tokens,
      submissions: result.submissions,
    );
  }

  void reset() {
    _generation++;
    _session?.reset();
    _userHistory.clear();
  }

  @visibleForTesting
  uc.CoachSession? get session => _session;
}

/// Local failures deliberately enter the same SDK fallback and validation path;
/// this client never performs HTTP or exposes an upstream credential.
class _UnconfiguredLlmClient implements uc.LlmClient {
  const _UnconfiguredLlmClient();

  @override
  String get model => 'unconfigured';

  @override
  uc.Pricing? get pricing => null;

  @override
  Future<uc.LlmResponse> complete(
    uc.LlmRequest request, {
    uc.CancelToken? cancel,
  }) async => throw uc.LlmException(
    (cancel?.isCancelled ?? false)
        ? uc.LlmErrorKind.cancelled
        : uc.LlmErrorKind.auth,
    'AI is not configured',
    httpAttempts: 0,
  );
}
