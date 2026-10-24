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
import 'coach_auth.dart';
import 'coach_config.dart';
import 'coach_device_id.dart';
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
    this.plan,
    this.actions,
    this.question,
    this.status = uc.TurnStatus.ok,
  });

  /// 给用户的回复（取消时为 null）。
  final uc.CoachReply? reply;

  /// Only SDK-admitted output can become a training or exercise card.
  final uc.ValidatedPlan? plan;
  final uc.ValidatedActions? actions;
  final uc.AskUserQuestion? question;
  final uc.TurnStatus status;

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
///   本轮只用随包可信快照，不从远端扩展范围或替换动作元数据。
/// - 范围：hiplab profile 白名单 ∩ 动作大全（内容包里有视频、有动作包、不是自测演示）；
///   不在交集里的 id 写进 profile.select.exclude，提示词目录表和校验器都排除（E_SCOPE）。
Iterable<uc.PlanIssue> hiplabDoseRule(
  uc.TrainingPlan plan,
  uc.Catalog catalog,
  uc.CoachContext context,
) sync* {
  for (final (index, item) in plan.items.indexed) {
    if (item.segments.isNotEmpty) {
      yield uc.PlanIssue(
        uc.IssueCodes.schema,
        'HipLab 动作包每组只有一种剂量，不支持一组内多段动作。',
        path: 'items[$index].segments',
        expected: '不带 segments 的单动作剂量',
        actual: '${item.segments.length} 段',
        fix: '把每个动作作为独立 item，使用动作包支持的 reps 或 workSeconds。',
      );
    }
  }
}

class CoachService {
  CoachService({
    this.config = CoachConfig.fromEnvironment,
    required this.content,
    uc.LlmClient? client,
    CoachUsageStore? usage,
    LocalStateStorage? storage,
    AssetReader? readAsset,
    Future<String> Function()? deviceId,
    this.maxRequestRetries = 4,
  }) : _client = !config.configured
           ? null
           : client ??
                 _clientFor(config, deviceId ?? CoachDeviceId.device.load),
       usage = usage ?? CoachUsageStore.device(),
       _storage = storage ?? SharedPreferencesLocalStateStorage(),
       _read = readAsset ?? rootBundle.loadString;

  static const catalogAsset = 'assets/coach/catalog.json';
  static const profileAsset = 'assets/coach/hiplab.json';
  static const storageKey = 'hip.coach.v1';

  final CoachConfig config;
  final int maxRequestRetries;
  final HipContent content;
  final CoachUsageStore usage;

  final uc.LlmClient? _client;
  final LocalStateStorage _storage;
  final AssetReader _read;

  late final uc.CatalogRepository _repo;
  late final uc.CoachProfile _profile;
  late final TemplateFallback templates = TemplateFallback(
    content,
    catalog: catalog,
  );
  uc.CoachAgent? _agent;
  uc.CoachConversation? _conversation;
  final _events = StreamController<uc.AgentEvent>.broadcast(sync: true);
  StreamSubscription<uc.AgentEvent>? _agentEvents;
  bool _disposed = false;

  Stream<uc.AgentEvent> get events => _events.stream;
  uc.CoachAgent? get agent => _agent;
  uc.ToolGate get gate => uc.ToolGate(
    catalog: catalog,
    profile: profile,
    extraRules: [hiplabDoseRule],
  );
  Future<void>? _loading;
  bool _disclaimerAccepted = false;
  Set<String> _excluded = const {};

  static uc.LlmClient? _clientFor(
    CoachConfig c,
    Future<String> Function() deviceId,
  ) {
    if (!c.configured) return null;
    return uc.OpenAiCompatibleClient(
      config: uc.LlmConfig.deepSeekOpenCsg.copyWith(
        baseUrl: c.baseUrl,
        model: c.model,
      ),
      auth: CoachRelayAuth(appKey: c.appKey, deviceId: deviceId),
    );
  }

  /// No credential means every AI entry stays hidden; no model is created.
  bool get configured => _client != null;
  bool get disclaimerAccepted => _disclaimerAccepted;

  /// profile 范围里、但不在动作大全（没视频 / 没动作包 / 自测演示）而排除的 id。
  Set<String> get excludedIds => _excluded;
  uc.CoachProfile get profile => _profile;
  uc.Catalog get catalog => _repo.current;

  Future<void> load() => _loading ??= _load();

  Future<void> _load() async {
    // The bundled profile and the App library are the trust boundary. A remote
    // catalog must not expand or replace this release's admitted actions.
    _repo = uc.CatalogRepository(
      bundled: uc.BundledCatalogSource(() => _read(catalogAsset)),
    );
    final catalog = await _repo.load();
    final profileJson = Map<String, Object?>.from(
      jsonDecode(await _read(profileAsset)) as Map,
    );
    if (_disposed) return;
    final scope = uc.CoachProfile.fromJson(profileJson).scope(catalog);
    _excluded = {
      for (final d in scope)
        if (!inLibrary(content, d.id)) d.id,
    };
    // Profile selectors form a union, so replace apps/tags with the exact local
    // intersection instead of adding IDs alongside the broader app selector.
    profileJson['select'] = {
      'ids': [
        for (final d in scope)
          if (inLibrary(content, d.id)) d.id,
      ],
      'exclude': _excluded.toList()..sort(),
    };
    _profile = uc.CoachProfile.fromJson(profileJson);
    if (_client case final client?) {
      _agent = uc.CoachAgent(
        client: client,
        catalog: () => _repo.current,
        profile: _profile,
        usage: usage,
        appId: 'hiplab-app',
        extraRules: [hiplabDoseRule],
        // Long-term memory is a separate product choice. Conversation state
        // and ask_user tasks remain on this same agent between sends.
        enableUserMemory: false,
        maxRequestRetries: maxRequestRetries,
        fallback: (r) {
          final reply = templates.reply(
            r.userText,
            reason: PresetReason.of(r.reason),
            history: _conversation == null
                ? const []
                : TemplateFallback.userTexts(_conversation!),
          );
          return uc.SessionFallbackReply(reply.text, plan: reply.plan);
        },
      );
      _agentEvents = _agent!.events.listen((event) {
        if (!_disposed) _events.add(event);
      });
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

  /// 问一轮。
  Future<CoachAnswer> ask(
    String text,
    uc.CoachConversation conversation, {
    uc.CancelToken? cancel,
  }) async {
    await load();
    final agent = _agent;
    if (_disposed || (cancel?.isCancelled ?? false)) {
      return const CoachAnswer(cancelled: true);
    }
    if (agent == null) {
      return _preset(text, conversation, PresetReason.notConfigured, 0);
    }
    if (_conversation != null && !identical(_conversation, conversation)) {
      agent.reset();
    }
    _conversation = conversation;
    final result = await agent.send(text, cancel: cancel);
    final tokens = result.usage.totalTokens;
    if (result.status == uc.TurnStatus.cancelled) {
      return CoachAnswer(
        cancelled: true,
        tokens: tokens,
        status: result.status,
      );
    }
    final reply = result.plan != null
        ? uc.CoachReply.plan(result.text, result.plan!.plan)
        : uc.CoachReply.text(result.text);
    // This mirror is App-owned fallback context, not the agent's task state.
    final now = DateTime.now();
    conversation
      ..addUser(text.trim(), now)
      ..addAssistant(reply, now);
    return CoachAnswer(
      reply: reply,
      plan: result.plan,
      actions: result.actions,
      question: result.question,
      status: result.status,
      presetReason: result.status == uc.TurnStatus.fallback
          ? PresetReason.of(result.fallbackReason!)
          : null,
      tokens: tokens,
      rewritten: result.resubmits > 0,
    );
  }

  void reset() {
    _agent?.reset();
    _conversation = null;
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _agent?.reset();
    await _agentEvents?.cancel();
    await _agent?.dispose();
    await _events.close();
  }

  CoachAnswer _preset(
    String text,
    uc.CoachConversation conversation,
    PresetReason reason,
    int tokens,
  ) {
    final reply = templates.reply(
      text,
      reason: reason,
      history: TemplateFallback.userTexts(conversation),
    );
    final now = DateTime.now();
    conversation
      ..addUser(text.trim(), now)
      ..addAssistant(reply, now);
    final admitted = reply.plan == null
        ? null
        : gate.admitTemplate(reply.plan!);
    return CoachAnswer(
      reply: admitted == null ? uc.CoachReply.text(reply.text) : reply,
      plan: admitted,
      presetReason: reason,
      tokens: tokens,
      status: uc.TurnStatus.fallback,
    );
  }

  @visibleForTesting
  uc.PlanValidator get validator => uc.PlanValidator(
    catalog: catalog,
    profile: profile,
    extraRules: [hiplabDoseRule],
  );
}
