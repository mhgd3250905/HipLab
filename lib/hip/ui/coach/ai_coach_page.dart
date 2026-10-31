// The SDK owns coaching and admission. HipLab supplies trusted content,
// persistence, navigation, localized copy and theme.
import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:ugk_coach/ugk_coach.dart' as uc;
import 'package:ugk_coach_ui/ugk_coach_ui.dart' as ui;

import '../../../core/storage/local_state_storage.dart';
import '../../coach/coach_service.dart';
import '../../coach/coach_config.dart';
import '../../coach/plan_mapping.dart';
import '../../control/hip_store.dart';
import '../../domain/hip_library.dart';
import '../hip_icons.dart';
import '../hip_routes.dart';
import '../hip_theme.dart';
import '../hip_widgets.dart';
import '../library/drill_detail_page.dart';
import '../library/library_actions.dart';
import '../library/library_widgets.dart';
import '../library/practice_page.dart' show startGroup;
import 'coach_history.dart';

/// Keep the existing platform/language scope; a missing key hides all entries.
bool aiCoachAvailable(BuildContext context, {bool? configured}) =>
    (configured ?? CoachConfig.fromEnvironment.configured) &&
    Theme.of(context).platform == TargetPlatform.android &&
    (Localizations.maybeLocaleOf(context)?.languageCode ?? 'zh') == 'zh';

/// App presentation only. The SDK controller owns messages and question state.
class AiCoachSession extends ChangeNotifier with WidgetsBindingObserver {
  AiCoachSession(
    this.service, {
    DateTime Function()? now,
    LocalStateStorage? storage,
  }) : _now = now ?? DateTime.now,
       _storage = storage ?? SharedPreferencesLocalStateStorage();

  static const storageKey = 'hip.coach.session.v2';
  final CoachService service;
  final DateTime Function() _now;
  final LocalStateStorage _storage;
  Future<void> _writes = Future.value();
  Future<void>? _loading;
  StreamSubscription<uc.AgentEvent>? _events;
  final Map<String, String> saved = {};
  // Badges/status belong to the App; these never determine question validity.
  final Map<String, ({uc.TurnStatus status, String? userEntryId})> _turns = {};
  uc.CoachConversationMessage? _draft;
  DateTime? _startedAt;
  bool _loaded = false;
  bool _resetBeforeLoad = false;
  bool _disposed = false;
  bool persistenceFailed = false;
  String? cancelledText;
  String progress = '正在理解你的需求…';

  uc.CoachConversationController? get conversation => service.conversation;
  List<uc.CoachConversationMessage> get messages =>
      conversation?.state.messages ?? const [];
  uc.CoachConversationMessage? get draft => _draft;
  bool get busy => conversation?.state.isWaiting ?? false;
  DateTime? get startedAt => _startedAt;
  bool get loaded => _loaded;
  bool get showDisclaimer => _loaded && !service.disclaimerAccepted;
  uc.TurnStatus? statusFor(uc.CoachConversationMessage message) =>
      _turns[message.turnId]?.status;
  String entryIdFor(uc.CoachConversationMessage message) => message.isUser
      ? _turns[message.turnId]?.userEntryId ?? message.id
      : message.id;

  Future<void> load() => _loading ??= _load();

  Future<void> _load() async {
    await service.load();
    if (_disposed || _loaded) return;
    String? encoded;
    try {
      encoded = await _storage.read(storageKey);
    } on Object {
      persistenceFailed = true;
    }
    if (_disposed) return;
    if (encoded != null && conversation != null && !_resetBeforeLoad) {
      try {
        final data = jsonDecode(encoded) as Map<String, dynamic>;
        final restored = <uc.CoachConversationMessage>[];
        for (final row in data['messages'] as List? ?? const []) {
          try {
            restored.add(
              coachMessageFromJson(
                Map<String, dynamic>.from(row as Map),
                service.gate,
              ),
            );
          } on Object {
            // Keep the remaining display history when one legacy row is bad.
          }
        }
        if (data['snapshot'] == null) {
          conversation!.restoreHistory(restored);
        } else {
          conversation!.restoreSession(
            uc.CoachSessionSnapshot.fromJson(data['snapshot']),
            restored,
          );
          // Reopening history never makes an old question actionable again.
          conversation!.invalidateQuestion();
        }
        saved.addAll(
          (data['saved'] as Map? ?? const {}).cast<String, String>(),
        );
      } on Object {
        // Unreadable persistence must not prevent starting a new conversation.
      }
    }
    if (_resetBeforeLoad) conversation?.newConversation();
    _loaded = true;
    WidgetsBinding.instance.addObserver(this);
    conversation?.addListener(_changed);
    _events = conversation?.events.listen((event) {
      if (event.kind != uc.AgentEventKind.askUser &&
          event.kind != uc.AgentEventKind.done &&
          busy) {
        progress = switch (event.kind) {
          uc.AgentEventKind.reading || uc.AgentEventKind.listing => '正在查阅动作资料…',
          uc.AgentEventKind.checking => '正在核对训练方案…',
          uc.AgentEventKind.retrying => '网络不稳，正在重试…',
          uc.AgentEventKind.slow => '仍在准备回复，可以继续等待或停止',
          _ => '正在理解你的需求…',
        };
        _persist();
        _notify();
      }
    });
    if (_resetBeforeLoad) {
      _resetBeforeLoad = false;
      _persist();
    }
    _notify();
  }

  Future<void> acceptDisclaimer() async {
    await service.acceptDisclaimer();
    _notify();
  }

  void _changed() {
    if (conversation?.state.lastResult case final result?) {
      _turns.putIfAbsent(
        result.turnId,
        () => (status: result.status, userEntryId: _draft?.id),
      );
    }
    if (busy) {
      _startedAt ??= _now();
    } else {
      _startedAt = null;
      _draft = null;
    }
    _persist();
    _notify();
  }

  Future<void> send(String text) async {
    if (!_loaded) return;
    final controller = conversation;
    if (controller == null || _disposed) return;
    await _submit(text, () => controller.send(text));
  }

  Future<void> answerText(String id, String text) async {
    final controller = conversation;
    if (controller == null || !controller.canAnswer(id)) return;
    await _submit(text, () => controller.answerText(id, text));
  }

  Future<void> answerChoices(String id, List<String> choices) async {
    final controller = conversation;
    final text = controller?.choiceText(id, choices);
    if (text == null) return;
    await _submit(text, () => controller!.answerChoices(id, choices));
  }

  Future<void> answerForm(String id, Map<String, List<String>> answers) async {
    final controller = conversation;
    if (controller == null || !controller.canAnswer(id)) return;
    await _submit(
      answers.values.expand((values) => values).join('、'),
      () => controller.answerForm(id, answers),
    );
  }

  Future<void> skipQuestion(String id) async {
    final controller = conversation;
    if (controller == null || !controller.canAnswer(id)) return;
    await _submit(
      controller.state.pendingQuestion!.question!.skipLabel,
      () => controller.skipQuestion(id),
    );
  }

  // The pending input is a visual draft until SDK messages are committed.
  // No local history, question IDs, answer validation or cancellation tokens.
  Future<void> _submit(
    String text,
    Future<uc.CoachTurnResult?> Function() submit,
  ) async {
    if (_disposed || busy || text.trim().isEmpty) return;
    progress = '正在理解你的需求…';
    _draft = uc.CoachConversationMessage(
      id: 'pending-input-${_now().microsecondsSinceEpoch}',
      at: _now(),
      isUser: true,
      text: text.trim(),
    );
    try {
      await submit();
    } on Object {
      // The controller publishes errors. Presentation never invents a result.
    }
    await flush();
  }

  void stop() {
    if (busy) cancelledText = _draft?.text;
    conversation?.cancel();
  }

  void expireQuestion() => conversation?.invalidateQuestion();

  void reset() {
    if (!_loaded) _resetBeforeLoad = true;
    cancelledText = null;
    saved.clear();
    _turns.clear();
    conversation?.newConversation();
  }

  /// Legacy display restoration delegates question and active-plan state to SDK.
  void restoreHistory(Iterable<uc.CoachConversationMessage> history) {
    final controller = conversation;
    if (controller == null) return;
    cancelledText = null;
    saved.clear();
    controller.restoreHistory(history.toList());
  }

  void markSaved(String messageId, String routineId) {
    saved[messageId] = routineId;
    _persist();
    _notify();
  }

  /// The SDK checks the full saved plan before accepting its external identity.
  Future<uc.CoachPlanFocusResult?> focusRoutine(
    CustomRoutine routine,
    HipStore store,
  ) async {
    await load();
    final controller = conversation;
    if (controller == null) return null;
    uc.TrainingPlan? plan;
    try {
      final encoded = store.coachPlanJson[routine.id];
      plan = encoded == null
          ? CoachPlanMapper(store.content).toSdkPlan(
              routine,
              service.catalog,
              scene: store.scene.name == 'chair' ? 'office' : store.scene.name,
            )
          : const uc.PlanCodec().decodeStrict(jsonDecode(encoded)).plan;
    } on Object {
      return null;
    }
    if (plan == null) return null;
    final result = controller.focusExternalPlan(
      externalId: routine.id,
      plan: plan,
      title: routine.name,
    );
    await flush();
    return result;
  }

  /// One queued write contains both portable facts and the matching display.
  void _persist() {
    final controller = conversation;
    if (!_loaded || controller == null || _disposed) return;
    final encoded = jsonEncode({
      'snapshot': controller.exportSession().toJson(),
      'messages': [for (final message in messages) coachMessageJson(message)],
      'saved': Map<String, String>.of(saved),
    });
    _writes = _writes.catchError((Object _) {}).then((_) async {
      await _storage.write(storageKey, encoded);
      if (persistenceFailed) {
        persistenceFailed = false;
        _notify();
      }
    });
    unawaited(
      _writes.catchError((Object _) {
        persistenceFailed = true;
        _notify();
        debugPrint('HipLab coach: session could not be persisted');
      }),
    );
  }

  Future<void> flush() async {
    try {
      await _writes;
    } on Object {
      // The save error is observable without rejecting an admitted SDK turn.
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _persist();
  }

  CustomRoutine? savedRoutine(String messageId, HipStore store) {
    final id = saved[messageId];
    return id == null ? null : store.customRoutine(id);
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _persist();
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    conversation?.removeListener(_changed);
    unawaited(_events?.cancel());
    unawaited(service.dispose());
    super.dispose();
  }
}

/// 练习页「我的」里的入口卡（新建训练组下面）。
class AiCoachEntryCard extends StatelessWidget {
  const AiCoachEntryCard({super.key, required this.actions});
  final LibraryActions actions;

  @override
  Widget build(BuildContext context) {
    final session = actions.coach!;
    final configured = session.service.configured;
    return HipPressable(
      key: const ValueKey('practice-ai-coach'),
      semanticLabel: 'AI 定制训练',
      scale: .98,
      onTap: () => Navigator.of(
        context,
      ).push(HipRoute.push<void>((_) => AiCoachPage(actions: actions))),
      child: HipPanel(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: tintOf(HipColors.jade),
              ),
              alignment: Alignment.center,
              child: HipIcon(
                HipGlyph.bolt,
                size: 22,
                filled: true,
                color: HipColors.jadeText,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text(
                        'AI 定制训练',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (!configured)
                        KeyedSubtree(
                          key: const ValueKey('practice-ai-unconfigured'),
                          child: tintTag('未配置', color: HipColors.tight),
                        ),
                    ],
                  ),
                  Text(
                    '说说想怎么练，用动作大全里的动作排一组',
                    style: TextStyle(fontSize: 13, color: HipColors.muted),
                  ),
                ],
              ),
            ),
            HipIcon(HipGlyph.chevronRight, size: 18, color: HipColors.muted),
          ],
        ),
      ),
    );
  }
}

class AiCoachPage extends StatefulWidget {
  const AiCoachPage({super.key, required this.actions});
  final LibraryActions actions;

  static const examples = ['睡前 10 分钟，放松髋部', '久坐腰胯紧，在办公室做', '想练横叉，15 分钟'];

  @override
  State<AiCoachPage> createState() => _AiCoachPageState();
}

class _AiCoachPageState extends State<AiCoachPage> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  Timer? _ticker;
  late final Set<String> _initiallySeen;
  final Set<String> _expandedPlans = {};
  String _entryId(uc.CoachConversationMessage message) =>
      session.entryIdFor(message);

  /// 本次等待已过的秒数（按 1 秒节拍累加）。
  int _elapsed = 0;

  AiCoachSession get session => widget.actions.coach!;

  @override
  void initState() {
    super.initState();
    _initiallySeen = {
      for (final message in session.messages) _entryId(message),
    };
    session.addListener(_changed);
    if (!session.loaded) unawaited(session.load());
    if (session.busy) _startTicker();
  }

  @override
  void dispose() {
    session.removeListener(_changed);
    session.expireQuestion();
    _ticker?.cancel();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _changed() {
    if (!mounted) return;
    if (session.busy) {
      _startTicker();
    } else {
      _ticker?.cancel();
      _ticker = null;
      // 停止后把原话放回输入框，方便改了再发。
      if (session.cancelledText case final text?) {
        session.cancelledText = null;
        if (_input.text.isEmpty) _input.text = text;
      }
    }
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) => _toEnd());
  }

  void _startTicker() {
    if (_ticker != null) return;
    final started = session.startedAt;
    _elapsed = started == null
        ? 0
        : DateTime.now().difference(started).inSeconds.clamp(0, 999);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsed++);
    });
  }

  void _toEnd() {
    if (!mounted || !_scroll.hasClients) return;
    _scroll.animateTo(
      0, // CoachChatList is a reverse viewport; newest rows are at offset zero.
      duration: MediaQuery.of(context).disableAnimations
          ? const Duration(milliseconds: 1)
          : HipMotion.medium,
      curve: HipMotion.curve,
    );
  }

  void _send([String? text]) {
    final value = (text ?? _input.text).trim();
    if (value.isEmpty || session.busy || !session.loaded) return;
    _input.clear();
    FocusScope.of(context).unfocus();
    unawaited(session.send(value));
  }

  Future<void> _save(
    uc.ValidatedPlan admitted,
    String resultId, {
    bool update = false,
  }) async {
    final store = widget.actions.store;
    final plan = admitted.plan;
    final externalId = update ? admitted.savedRef?.externalId : null;
    final existing = externalId == null
        ? null
        : store.customRoutine(externalId);
    if (update && existing == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('原计划已不存在，请另存一份。')));
      return;
    }
    final mapping = CoachPlanMapper(
      store.content,
    ).map(plan, id: externalId ?? store.newCustomId(), at: store.now());
    final routine = await store.saveCustomRoutine(
      mapping.routine,
      coachPlan: plan.toJson(),
    );
    if (!mounted) return;
    session.markSaved(resultId, routine.id);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            '${update ? '已更新「我的」计划' : '已保存到「我的」训练组'}：${routine.name}',
          ),
        ),
      );
  }

  Future<void> _start(
    uc.TrainingPlan plan,
    String resultId,
    BuildContext? from,
  ) async {
    final store = widget.actions.store;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    // A saved group can be edited independently. The immutable card always
    // starts the exact SDK plan displayed on that card.
    final routine = CoachPlanMapper(store.content)
        .map(
          plan,
          id: session.savedRoutine(resultId, store)?.id ?? 'ai_${plan.id}',
          at: store.now(),
        )
        .routine;
    await startGroup(context, widget.actions, routine, from: from);
  }

  @override
  Widget build(BuildContext context) {
    return ui.CoachUiTheme(
      style: hipCoachStyle(context, blocked: widget.actions.store.blocked),
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              HipTopBar(
                title: 'AI 定制训练',
                icon: HipGlyph.back,
                tooltip: '返回',
                trailing: TextButton(
                  key: const ValueKey('coach-reset'),
                  onPressed: session.reset,
                  child: const Text('新对话'),
                ),
              ),
              if (session.showDisclaimer)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _Disclaimer(onAccept: session.acceptDisclaimer),
                ),
              if (session.persistenceFailed)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 6,
                  ),
                  child: Text(
                    '对话暂时未能保存到本机，当前内容仍可继续使用。',
                    style: TextStyle(color: HipColors.tight, fontSize: 12),
                  ),
                ),
              Expanded(
                child: ui.CoachChatList(
                  key: const ValueKey('coach-list'),
                  controller: _scroll,
                  dockHeight: 0,
                  timeMarkBuilder: (at, now) => ui.CoachTimeMark(at, now: now),
                  initiallySeen: _initiallySeen,
                  typing: session.busy
                      ? ui.CoachTypingBubble(
                          key: const ValueKey('coach-thinking'),
                          progressLabel: '${session.progress} · 已用 $_elapsed 秒',
                          onCancel: session.stop,
                        )
                      : null,
                  entries: [
                    if (session.messages.isEmpty && session.draft == null)
                      ui.CoachChatEntry(
                        id: 'intro',
                        at: DateTime.now(),
                        isUser: false,
                        greeting: true,
                        child: _Intro(
                          configured: session.service.configured,
                          onExample: session.busy || !session.loaded
                              ? null
                              : _send,
                        ),
                      ),
                    for (final (i, m) in session.messages.indexed)
                      ui.CoachChatEntry(
                        id: _entryId(m),
                        at: m.at,
                        isUser: m.isUser,
                        isCard: m.plan != null || m.actions != null,
                        child: KeyedSubtree(
                          key: ValueKey('coach-msg-$i'),
                          child: m.isUser
                              ? _bubble(m.text, user: true, id: 'user-$i')
                              : _answer(m),
                        ),
                      ),
                    if (session.draft case final draft?)
                      ui.CoachChatEntry(
                        id: draft.id,
                        at: draft.at,
                        isUser: true,
                        child: _bubble(draft.text, user: true, id: draft.id),
                      ),
                    if (session.conversation?.state.lastResult?.status ==
                        uc.TurnStatus.limitReached)
                      ui.CoachChatEntry(
                        id: 'conversation-full',
                        at: DateTime.now(),
                        isUser: false,
                        child: TextButton(
                          onPressed: session.reset,
                          child: const Text('对话已满，开始新对话'),
                        ),
                      ),
                    if (session.conversation?.state case final state?)
                      if (state.error != null &&
                          state.lastResult == null &&
                          !state.isWaiting)
                        ui.CoachChatEntry(
                          id: 'conversation-error',
                          at: DateTime.now(),
                          isUser: false,
                          child: ui.CoachFailureBubble(
                            enabled: !session.busy,
                            onRetry: () => session.send('重试'),
                          ),
                        ),
                  ],
                ),
              ),
              _Composer(
                controller: _input,
                busy: session.busy || !session.loaded,
                onSend: _send,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bubble(String text, {bool user = false, required String id}) =>
      ui.CoachMessageBubble(
        message: ui.CoachBubbleData(id: id, text: text, isUser: user),
        optionsActive: false,
        onOption: (_) {},
      );

  Widget _answer(uc.CoachConversationMessage message) {
    final status = session.statusFor(message);
    final question = message.question;
    final id = message.id;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (message.isFailure) _failure(message),
        if (question != null)
          ui.CoachQuestionBubble(
            key: ValueKey('coach-question-$id'),
            question: ui.CoachQuestionData(
              id: id,
              question: question.question,
              mode: switch (question.mode) {
                uc.AskUserMode.text => ui.CoachQuestionMode.text,
                uc.AskUserMode.choice => ui.CoachQuestionMode.choice,
                uc.AskUserMode.form => ui.CoachQuestionMode.form,
              },
              options: question.options,
              multiple: question.multiple,
              answered: message.questionAnswered,
              answeredChoices: message.answeredChoices,
              answeredForm: message.answeredForm,
              isConfirmation: question.isConfirmation,
              focus: question.focus,
              defaultSelections: question.defaultSelections,
              skipLabel: question.skipLabel,
              fields: [
                for (final field in question.fields)
                  ui.CoachQuestionField(
                    key: field.key,
                    label: field.label,
                    options: field.options,
                    multiple: field.multiple,
                    initialSelections: field.preselected,
                    previousSelections: field.previousSelections,
                    optionsByScene: field.optionsByScene,
                  ),
              ],
            ),
            enabled: session.conversation!.canAnswer(id),
            onTextAnswer: (text) => session.answerText(id, text),
            onChoiceAnswer: (choices) => session.answerChoices(id, choices),
            onFormAnswer: (answers) => session.answerForm(id, answers),
            onSkip: () => session.skipQuestion(id),
          ),
        if (message.text.isNotEmpty &&
            !message.isFailure &&
            message.actions == null)
          _bubble(message.text, id: 'answer-$id'),
        if (message.plan case final admitted?) _planCard(admitted, status, id),
        if (message.actions case final admitted?)
          ui.CoachRecommendCard(
            actionIds: [for (final action in admitted.items) action.id],
            note: message.text,
            library: hipCoachLibrary(widget.actions.store),
            onOpenAction: (id) => Navigator.of(context).push(
              HipRoute.push<Object?>(
                (_) => DrillDetailPage(actions: widget.actions, drillId: id),
              ),
            ),
            onPlanFromActions: (_) => _send('请把刚才推荐的动作排成计划。'),
          ),
      ],
    );
  }

  Widget _failure(uc.CoachConversationMessage message) {
    final controller = session.conversation!;
    final current = session.messages.last.id == message.id;
    uc.TrainingPlan? candidate;
    if (current) {
      for (final encoded in widget.actions.store.coachPlanJson.values) {
        Object? raw;
        try {
          raw = jsonDecode(encoded);
        } on FormatException {
          continue;
        }
        final decoded = const uc.PlanCodec().decodeStrict(raw);
        if (decoded.plan case final plan?) {
          if (controller.canOfferPreset(plan)) {
            candidate = plan;
            break;
          }
        }
      }
    }
    final preset = candidate;
    return ui.CoachFailureBubble(
      enabled: current && !session.busy,
      onRetry: () => session.send('重试'),
      presetMatchesFocus: preset != null && controller.canOfferPreset(preset),
      onSecondary: preset == null
          ? null
          : () async {
              controller.requestPreset(preset);
              await session.flush();
            },
    );
  }

  Widget _planCard(
    uc.ValidatedPlan admitted,
    uc.TurnStatus? status,
    String resultId,
  ) {
    final preset =
        status == uc.TurnStatus.fallback ||
        (status == null && admitted.plan.source == 'template');
    final plan = admitted.plan;
    final store = widget.actions.store;
    final saved = session.savedRoutine(resultId, store);
    final external = admitted.savedRef;
    final expanded = _expandedPlans.contains(resultId);
    final duration = const uc.PlanDuration().estimateSeconds(
      plan,
      session.service.catalog,
    );
    return Column(
      key: const ValueKey('coach-plan-card'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            preset ? '预设方案' : 'AI 定制',
            key: ValueKey(preset ? 'coach-badge-preset' : 'coach-badge-ai'),
            style: TextStyle(
              color: HipColors.jadeText,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (preset)
          const Text(
            '这是已保存的预设计划，并非本轮 AI 新生成的。',
            key: ValueKey('coach-preset-note'),
          ),
        ui.CoachPlanExpanded(
          key: ValueKey('coach-plan-$resultId'),
          plan: ui.CoachRoutine(
            id: plan.id,
            title: plan.title,
            items: [
              for (final block in plan.blocks)
                for (final item in block.items)
                  ui.CoachRoutineItem(
                    exerciseId: item.exerciseId,
                    dose:
                        '${_itemDose(item)}'
                        '${block.rounds > 1 ? ' × ${block.rounds} 轮' : ''}',
                    detailDose:
                        '${block.name} · '
                        '${_itemDose(item)} · 休息 ${item.restSeconds} 秒'
                        '${block.rounds > 1 ? ' · ${block.rounds} 轮，轮间 ${block.restBetweenRoundsSeconds} 秒' : ''}',
                  ),
            ],
            durationLabel: '约 ${math.max(1, (duration / 60).round())} 分钟',
            gearLabel: '按动作准备器材',
            levelLabel: '舒适范围',
            metaLabel: '${plan.items.length} 个动作',
          ),
          library: hipCoachLibrary(store),
          expanded: expanded,
          onCollapse: () => setState(() => _expandedPlans.remove(resultId)),
          onToggle: () => setState(() {
            if (expanded) {
              _expandedPlans.remove(resultId);
            } else {
              _expandedPlans.add(resultId);
            }
          }),
          actionLabel: external != null
              ? '更新到我的计划'
              : saved != null
              ? '已保存到「我的」'
              : '保存为自定义训练组',
          onAction: saved != null && external == null
              ? null
              : () => unawaited(
                  _save(admitted, resultId, update: external != null),
                ),
          onStart: (_) {
            if (!store.blocked) unawaited(_start(plan, resultId, null));
          },
        ),
        if (external != null)
          TextButton(
            key: ValueKey('coach-save-copy-$resultId'),
            onPressed: () => _save(admitted, resultId),
            child: const Text('另存一份'),
          ),
        for (final note in {...plan.safetyNotes, '在不痛的范围内做，出现疼痛、麻木或头晕立即停止。'})
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              note,
              style: TextStyle(fontSize: 12, color: HipColors.muted),
            ),
          ),
        if (store.blocked)
          Text(
            '安全提示里有需要先问医生的情况，暂时不能开始训练。',
            key: const ValueKey('coach-blocked'),
            style: TextStyle(color: HipColors.pain),
          ),
      ],
    );
  }

  String _itemDose(uc.PlanItem item) {
    String scalar(uc.DoseMode mode, int? reps, int? seconds) =>
        mode == uc.DoseMode.reps ? '$reps 次' : '$seconds 秒';
    final work = item.segments.isEmpty
        ? scalar(item.mode, item.reps, item.workSeconds)
        : item.segments
              .map((segment) {
                final name = widget.actions.store.content
                    .drill(segment.exerciseId)
                    .name;
                return '$name ${scalar(segment.mode, segment.reps, segment.workSeconds)}'
                    '${segment.holdSeconds == null ? '' : '（停留 ${segment.holdSeconds} 秒）'}';
              })
              .join(' → ');
    return '${item.perSide ? '每侧 ' : ''}$work × ${item.sets} 组';
  }
}

/// Only App-resolved asset paths and locally admitted exercise IDs enter DTOs.
ui.CoachExerciseLibrary hipCoachLibrary(HipStore store) =>
    ui.CoachExerciseLibrary([
      for (final drill in store.content.drills.values)
        if (inLibrary(store.content, drill.id) && drill.poster != null)
          ui.CoachExercise(
            id: drill.id,
            name: drill.name,
            poster: HipMediaVariants.themed(drill.poster!),
            cues: [if (drill.note.isNotEmpty) drill.note],
            stage: ui.CoachMediaPalette(
              mediaStage: HipColors.mediaBackdrop,
              onStage: HipColors.text,
              onStageMuted: HipColors.muted,
            ),
          ),
    ]);

ui.CoachUiStyle hipCoachStyle(BuildContext context, {bool blocked = false}) {
  final theme = Theme.of(context);
  return ui.CoachUiStyle(
    colors: ui.CoachUiColors(
      brightness: theme.brightness,
      text: HipColors.text,
      muted: HipColors.muted,
      faint: HipColors.faint,
      background: HipColors.background,
      surface: HipColors.surface,
      surfaceRaised: HipColors.surfaceHigh,
      outline: HipColors.line,
      shadow: HipColors.shadow,
      accent: HipColors.jade,
      accentText: HipColors.jadeText,
      accentSoft: tintOf(HipColors.jade),
      onAccent: HipColors.onJade,
      userBubble: tintOf(HipColors.jade),
      assistantBubble: HipColors.surface,
      stage: ui.CoachMediaPalette(
        mediaStage: HipColors.mediaBackdrop,
        onStage: HipColors.text,
        onStageMuted: HipColors.muted,
      ),
      emphasis: HipColors.jade,
      onEmphasis: HipColors.onJade,
      onMedia: HipColors.text,
      mediaLabelSurface: HipColors.surfaceHigh,
    ),
    typography: ui.CoachUiTypography(
      body: const TextStyle(
        fontFamily: hipFontFamily,
        fontSize: 15,
        height: 1.5,
      ),
      callout: const TextStyle(
        fontFamily: hipFontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      label: const TextStyle(fontFamily: hipFontFamily, fontSize: 12),
      caption: const TextStyle(fontFamily: hipFontFamily, fontSize: 12),
      greeting: const TextStyle(
        fontFamily: hipFontFamily,
        fontSize: 24,
        fontWeight: FontWeight.w700,
      ),
    ),
    strings: ui.CoachUiStrings(
      expand: '展开',
      collapse: '收起',
      expandDetails: '展开动作',
      collapseDetails: '收起动作',
      save: '保存为自定义训练组',
      saved: '已保存到「我的」',
      start: '开始训练',
      cancel: '停止',
      preparing: '正在准备回复…',
      progressHint: '正在核对动作和训练方案',
      answerHint: '说说你的情况',
      submitAnswer: '继续',
      multipleHint: '可选择多项',
      planDetails: (title) => '训练详情：$title',
      timeLabel: (at, now) =>
          '${at.hour.toString().padLeft(2, '0')}:${at.minute.toString().padLeft(2, '0')}',
    ),
    builders: ui.CoachUiBuilders(
      startButton: (_, button) => HipCircleButton(
        key: const ValueKey('coach-start'),
        icon: HipGlyph.play,
        tooltip: '开始训练',
        onPressed: blocked ? null : button.onTap,
      ),
      textAction: (_, action) => TextButton(
        key: action.label.contains('保存') ? const ValueKey('coach-save') : null,
        onPressed: action.onPressed,
        child: Text(action.label),
      ),
    ),
  );
}

class _Disclaimer extends StatelessWidget {
  const _Disclaimer({required this.onAccept});
  final VoidCallback onAccept;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: HipPanel(
      key: const ValueKey('coach-disclaimer'),
      radius: 18,
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HipIcon(HipGlyph.shield, size: 18, color: HipColors.jadeText),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'AI 排的计划只作练习参考，不能代替医生或康复师的判断；'
                  '你写的需求会发给 AI 服务生成计划。练习中出现疼痛、麻木或头晕，请立即停止。',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: HipColors.muted,
                  ),
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              key: const ValueKey('coach-disclaimer-ok'),
              onPressed: onAccept,
              child: Text(
                '知道了',
                style: TextStyle(
                  color: HipColors.jadeText,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _Intro extends StatelessWidget {
  const _Intro({required this.configured, required this.onExample});
  final bool configured;
  final ValueChanged<String>? onExample;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 4, bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '说说你想怎么练',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          '场地、时长、想开哪里、哪里不舒服都可以讲。'
          '我只用动作大全里的动作排一组，排好可以直接开始，也可以存进「我的」训练组。',
          style: TextStyle(fontSize: 14, height: 1.5, color: HipColors.muted),
        ),
        if (!configured) ...[
          const SizedBox(height: 10),
          Text(
            'AI 服务还未配置，请稍后再试。',
            key: const ValueKey('coach-unconfigured-note'),
            style: TextStyle(
              fontSize: 13,
              height: 1.45,
              color: HipColors.tight,
            ),
          ),
        ],
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (i, example) in AiCoachPage.examples.indexed)
              LibChip(
                example,
                key: ValueKey('coach-example-$i'),
                onTap: onExample == null ? null : () => onExample!(example),
              ),
          ],
        ),
      ],
    ),
  );
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.busy,
    required this.onSend,
  });
  final TextEditingController controller;
  final bool busy;
  final VoidCallback onSend;
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: HipColors.background,
      border: Border(top: BorderSide(color: HipColors.line)),
    ),
    child: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 12, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                key: const ValueKey('coach-input'),
                controller: controller,
                enabled: !busy,
                minLines: 1,
                maxLines: 4,
                maxLength: 300,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                decoration: const InputDecoration(
                  hintText: '比如：睡前 10 分钟，膝盖不太好',
                  counterText: '',
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            HipCircleButton(
              key: const ValueKey('coach-send'),
              icon: HipGlyph.chevronRight,
              tooltip: '发送',
              onPressed: busy ? null : onSend,
            ),
          ],
        ),
      ),
    ),
  );
}
