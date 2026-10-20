// AI 定制：SDK（ugk_coach）+ HipLab 的范围交集、预设回落、记账、免责标记。
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
import 'coach_config.dart';
import 'template_fallback.dart';
import 'usage_store.dart';

typedef AssetReader = Future<String> Function(String path);

/// 一轮问答在 App 里的结果。
class CoachAnswer {
  const CoachAnswer({
    this.reply,
    this.presetReason,
    this.cancelled = false,
    this.rewritten = false,
    this.tokens = 0,
  });

  /// 给用户的回复（取消时为 null）。
  final uc.CoachReply? reply;

  /// 非 null = 这是 App 内置预设方案（或离线安全提示），不是 AI 生成的。
  final PresetReason? presetReason;
  final bool cancelled;

  /// 第一次输出没过校验、重写后通过。
  final bool rewritten;
  final int tokens;

  bool get preset => presetReason != null;
}

/// HipLab 的 AI 训练助理。
///
/// - 目录：随包 `assets/coach/catalog.json`（Pose-Hub 目录的 hiplab 范围快照），
///   配了 `UGK_COACH_CATALOG_URL` 时可远端更新（SDK 校验大小 / sha256 / 版本后才切换）。
/// - 范围：hiplab profile 白名单 ∩ 动作大全（内容包里有视频、有动作包、不是自测演示）；
///   不在交集里的 id 写进 profile.select.exclude，提示词目录表和校验器都排除（E_SCOPE）。
class CoachService {
  CoachService({
    this.config = CoachConfig.fromEnvironment,
    required this.content,
    uc.LlmClient? client,
    CoachUsageStore? usage,
    LocalStateStorage? storage,
    AssetReader? readAsset,
  }) : _client = client ?? _clientFor(config),
       usage = usage ?? CoachUsageStore.device(),
       _storage = storage ?? SharedPreferencesLocalStateStorage(),
       _read = readAsset ?? rootBundle.loadString;

  static const catalogAsset = 'assets/coach/catalog.json';
  static const profileAsset = 'assets/coach/hiplab.json';
  static const storageKey = 'hip.coach.v1';

  final CoachConfig config;
  final HipContent content;
  final CoachUsageStore usage;

  final uc.LlmClient? _client;
  final LocalStateStorage _storage;
  final AssetReader _read;

  late final uc.CatalogRepository _repo;
  late final uc.CoachProfile _profile;
  late final TemplateFallback templates = TemplateFallback(content);
  uc.CoachAssistant? _assistant;
  Future<void>? _loading;
  bool _disclaimerAccepted = false;
  Set<String> _excluded = const {};

  static uc.LlmClient? _clientFor(CoachConfig c) {
    if (!c.configured) return null;
    return uc.OpenAiCompatibleClient(
      config: uc.LlmConfig.deepSeekOpenCsg.copyWith(
        baseUrl: c.baseUrl,
        model: c.model,
      ),
      auth: uc.ApiKeyAuth(c.apiKey),
    );
  }

  /// 有模型可调；false 时入口显示「未配置」，问什么都给预设方案。
  bool get configured => _client != null;
  bool get disclaimerAccepted => _disclaimerAccepted;

  /// profile 范围里、但不在动作大全（没视频 / 没动作包 / 自测演示）而排除的 id。
  Set<String> get excludedIds => _excluded;
  uc.CoachProfile get profile => _profile;
  uc.Catalog get catalog => _repo.current;

  Future<void> load() => _loading ??= _load();

  Future<void> _load() async {
    final manifest = config.catalogManifestUrl;
    _repo = uc.CatalogRepository(
      bundled: uc.BundledCatalogSource(() => _read(catalogAsset)),
      remote: manifest.isEmpty
          ? null
          : uc.RemoteCatalogSource(manifestUrl: Uri.parse(manifest)),
    );
    final catalog = await _repo.load();
    final profileJson = Map<String, Object?>.from(
      jsonDecode(await _read(profileAsset)) as Map,
    );
    final scope = uc.CoachProfile.fromJson(profileJson).scope(catalog);
    _excluded = {
      for (final d in scope)
        if (!inLibrary(content, d.id)) d.id,
    };
    if (_excluded.isNotEmpty) {
      final select = Map<String, Object?>.from(profileJson['select'] as Map);
      select['exclude'] = [
        ...((select['exclude'] as List?) ?? const []),
        ...(_excluded.toList()..sort()),
      ];
      profileJson['select'] = select;
    }
    _profile = uc.CoachProfile.fromJson(profileJson);
    if (_client case final client?) {
      _assistant = uc.CoachAssistant(
        client: client,
        catalog: () => _repo.current,
        profile: _profile,
        usage: usage,
        appId: 'hiplab-app',
        fallback: uc.FallbackFn(
          (r) => templates.reply(r.userText, reason: PresetReason.of(r.reason)),
        ),
      );
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
    // 远端目录：后台检查一次，失败保持随包目录。
    if (manifest.isNotEmpty) {
      unawaited(_repo.refresh().then((_) {}, onError: (_) {}));
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

  /// 问一轮。
  Future<CoachAnswer> ask(
    String text,
    uc.CoachConversation conversation, {
    uc.CancelToken? cancel,
  }) async {
    await load();
    final assistant = _assistant;
    if (assistant == null) {
      return _preset(text, conversation, PresetReason.notConfigured, 0);
    }
    // 助理最多追问一次：上一条已经是追问，这轮要求直接出计划。
    final asked =
        conversation.turns.isNotEmpty &&
        conversation.turns.last.reply?.kind == uc.ReplyKind.ask;
    final result = await assistant.ask(
      text,
      conversation: conversation,
      cancel: cancel,
      context: uc.CoachContext(
        notes: asked
            ? const ['已经追问过一次：这一轮请直接给出计划，缺的条件用默认值并在 text 里说明。']
            : const [],
      ),
    );
    final tokens = result.usage.promptTokens + result.usage.completionTokens;
    return switch (result.outcome) {
      uc.TurnOutcome.cancelled => CoachAnswer(cancelled: true, tokens: tokens),
      uc.TurnOutcome.fallback => CoachAnswer(
        reply: result.reply,
        presetReason: PresetReason.of(result.fallbackReason!),
        tokens: tokens,
      ),
      uc.TurnOutcome.error => _preset(
        text,
        conversation,
        PresetReason.unavailable,
        tokens,
      ),
      _ => CoachAnswer(
        reply: result.reply,
        rewritten: result.outcome == uc.TurnOutcome.rewritten,
        tokens: tokens,
      ),
    };
  }

  CoachAnswer _preset(
    String text,
    uc.CoachConversation conversation,
    PresetReason reason,
    int tokens,
  ) {
    final reply = templates.reply(text, reason: reason);
    final now = DateTime.now();
    conversation
      ..addUser(text.trim(), now)
      ..addAssistant(reply, now);
    return CoachAnswer(reply: reply, presetReason: reason, tokens: tokens);
  }

  @visibleForTesting
  uc.CoachAssistant? get assistant => _assistant;
}
