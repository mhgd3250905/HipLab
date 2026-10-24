// HipLab owns the agent, trusted mapping and navigation. Shared conversation
// layout, bubbles, clarification controls and routine cards are SDK widgets.
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:ugk_coach/ugk_coach.dart' as uc;
import 'package:ugk_coach_ui/ugk_coach_ui.dart' as ui;

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

/// Keep the existing platform/language scope; a missing key hides all entries.
bool aiCoachAvailable(BuildContext context, {bool? configured}) =>
    (configured ?? CoachConfig.fromEnvironment.configured) &&
    Theme.of(context).platform != TargetPlatform.iOS &&
    (Localizations.maybeLocaleOf(context)?.languageCode ?? 'zh') == 'zh';

class CoachMessage {
  const CoachMessage.user(String this.text, {required this.at})
    : answer = null,
      resultId = -1;
  const CoachMessage.answer(
    CoachAnswer this.answer,
    this.resultId, {
    required this.at,
  }) : text = null;
  final String? text;
  final CoachAnswer? answer;
  final DateTime at;
  final int resultId;
  bool get isUser => text != null;
}

/// The App shell retains one conversation and one agent across page/route hops.
class AiCoachSession extends ChangeNotifier {
  AiCoachSession(this.service, {DateTime Function()? now})
    : _now = now ?? DateTime.now {
    _events = service.events.listen((event) {
      // askUser is progress only. Never expose an answerable question until
      // await service.ask (and therefore await agent.send) has returned.
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
        _notify();
      }
    });
  }

  final CoachService service;
  final DateTime Function() _now;
  late final StreamSubscription<uc.AgentEvent> _events;
  uc.CoachConversation conversation = uc.CoachConversation();
  final List<CoachMessage> messages = [];
  final Map<int, String> saved = {};
  final Map<int, List<String>> answeredChoices = {};
  final Set<int> answeredQuestions = {};
  int? awaitingQuestionId;
  int _nextResult = 0;
  int _generation = 0;
  uc.CancelToken? _cancel;
  DateTime? _startedAt;
  bool _loaded = false;
  bool _disposed = false;
  String? cancelledText;
  String progress = '正在理解你的需求…';

  bool get busy => _cancel != null;
  DateTime? get startedAt => _startedAt;
  bool get loaded => _loaded;
  bool get showDisclaimer => _loaded && !service.disclaimerAccepted;

  Future<void> load() async {
    await service.load();
    _loaded = true;
    _notify();
  }

  Future<void> acceptDisclaimer() async {
    await service.acceptDisclaimer();
    _notify();
  }

  bool questionEnabled(int id) =>
      !_disposed && !busy && awaitingQuestionId == id;

  CoachMessage? _question(int id) => messages
      .where((m) => !m.isUser && m.resultId == id && m.answer?.question != null)
      .firstOrNull;

  Future<void> answerText(int id, String raw) async {
    final q = _question(id)?.answer?.question;
    final answer = raw.trim();
    if (!questionEnabled(id) ||
        q?.mode != uc.AskUserMode.text ||
        answer.isEmpty ||
        answer.runes.length > 300) {
      return;
    }
    answeredQuestions.add(id);
    // send closes the old question synchronously before its first await.
    await send(answer);
  }

  Future<void> answerChoices(int id, List<String> values) async {
    final q = _question(id)?.answer?.question;
    if (!questionEnabled(id) || q?.mode != uc.AskUserMode.choice) return;
    final question = q!;
    if (values.isEmpty ||
        values.toSet().length != values.length ||
        values.any((v) => !question.options.contains(v)) ||
        (!question.multiple && values.length != 1)) {
      return;
    }
    final ordered = [
      for (final v in question.options)
        if (values.contains(v)) v,
    ];
    answeredChoices[id] = List.unmodifiable(ordered);
    answeredQuestions.add(id);
    await send(ordered.join('、'));
  }

  Future<void> send(String raw) async {
    final text = raw.trim();
    if (text.isEmpty || busy || _disposed) return;
    awaitingQuestionId = null;
    final generation = _generation;
    final cancel = uc.CancelToken();
    _cancel = cancel;
    _startedAt = _now();
    progress = '正在理解你的需求…';
    messages.add(CoachMessage.user(text, at: _now()));
    _notify();
    CoachAnswer answer;
    try {
      answer = await service.ask(text, conversation, cancel: cancel);
    } on Object {
      answer = const CoachAnswer(
        reply: uc.CoachReply.text('出了点问题，没能排出计划。请稍后再试。'),
      );
    }
    if (_disposed || generation != _generation) return;
    _cancel = null;
    _startedAt = null;
    if (answer.cancelled) {
      if (messages.isNotEmpty && messages.last.isUser) messages.removeLast();
      cancelledText = text;
    } else {
      final id = _nextResult++;
      messages.add(CoachMessage.answer(answer, id, at: _now()));
      if (answer.question != null) awaitingQuestionId = id;
    }
    _notify();
  }

  void stop() {
    awaitingQuestionId = null;
    _cancel?.cancel();
    service.reset();
    _notify();
  }

  /// Leaving a question/history does not restore a pending SDK task later.
  void expireQuestion() {
    if (awaitingQuestionId != null) {
      awaitingQuestionId = null;
      service.reset();
      _notify();
    }
  }

  void reset() {
    _generation++;
    _cancel?.cancel();
    _cancel = null;
    _startedAt = null;
    awaitingQuestionId = null;
    cancelledText = null;
    service.reset();
    conversation = uc.CoachConversation();
    messages.clear();
    saved.clear();
    answeredQuestions.clear();
    answeredChoices.clear();
    _notify();
  }

  /// Restored snapshots are display history, never a reconstructed agent task.
  void restoreHistory(Iterable<CoachMessage> history) {
    reset();
    messages.addAll(history);
    _nextResult = messages.fold(0, (n, m) => math.max(n, m.resultId + 1));
    _notify();
  }

  void markSaved(int resultId, String routineId) {
    saved[resultId] = routineId;
    _notify();
  }

  CustomRoutine? savedRoutine(int resultId, HipStore store) {
    final id = saved[resultId];
    return id == null ? null : store.customRoutine(id);
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    awaitingQuestionId = null;
    _cancel?.cancel();
    unawaited(_events.cancel());
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
  String _entryId(CoachMessage message) =>
      'message-${identityHashCode(message)}';

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
    if (value.isEmpty || session.busy) return;
    _input.clear();
    FocusScope.of(context).unfocus();
    unawaited(session.send(value));
  }

  Future<void> _save(uc.TrainingPlan plan, int resultId) async {
    final store = widget.actions.store;
    final mapping = CoachPlanMapper(
      store.content,
    ).map(plan, id: store.newCustomId(), at: store.now());
    final routine = await store.saveCustomRoutine(mapping.routine);
    if (!mounted) return;
    session.markSaved(resultId, routine.id);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('已保存到「我的」训练组：${routine.name}')));
  }

  Future<void> _start(
    uc.TrainingPlan plan,
    int resultId,
    BuildContext? from,
  ) async {
    final store = widget.actions.store;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    final routine =
        session.savedRoutine(resultId, store) ??
        CoachPlanMapper(
          store.content,
        ).map(plan, id: 'ai_${plan.id}', at: store.now()).routine;
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
              Expanded(
                child: ui.CoachChatList(
                  key: const ValueKey('coach-list'),
                  controller: _scroll,
                  dockHeight: 0,
                  topColor: HipColors.background,
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
                    if (session.messages.isEmpty)
                      ui.CoachChatEntry(
                        id: 'intro',
                        at: DateTime.now(),
                        isUser: false,
                        greeting: true,
                        child: _Intro(
                          configured: session.service.configured,
                          onExample: session.busy ? null : _send,
                        ),
                      ),
                    for (final (i, m) in session.messages.indexed)
                      ui.CoachChatEntry(
                        id: _entryId(m),
                        at: m.at,
                        isUser: m.isUser,
                        isCard: m.answer?.plan != null,
                        child: KeyedSubtree(
                          key: ValueKey('coach-msg-$i'),
                          child: m.isUser
                              ? _bubble(m.text!, user: true, id: 'user-$i')
                              : _answer(m),
                        ),
                      ),
                  ],
                ),
              ),
              _Composer(controller: _input, busy: session.busy, onSend: _send),
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

  Widget _answer(CoachMessage message) {
    final answer = message.answer!;
    final question = answer.question;
    final id = message.resultId;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (question != null)
          ui.CoachQuestionBubble(
            key: ValueKey('coach-question-$id'),
            question: ui.CoachQuestionData(
              id: '$id',
              question: question.question,
              mode: question.mode == uc.AskUserMode.text
                  ? ui.CoachQuestionMode.text
                  : ui.CoachQuestionMode.choice,
              options: question.options,
              multiple: question.multiple,
              answered: session.answeredQuestions.contains(id),
              answeredChoices: session.answeredChoices[id] ?? const [],
            ),
            enabled: session.questionEnabled(id),
            onTextAnswer: (text) => session.answerText(id, text),
            onChoiceAnswer: (choices) => session.answerChoices(id, choices),
          )
        else if (answer.reply?.text.isNotEmpty ?? false)
          _bubble(answer.reply!.text, id: 'answer-$id'),
        if (answer.plan case final admitted?) _planCard(admitted, answer, id),
        if (answer.actions case final admitted?)
          for (final action in admitted.items)
            TextButton(
              onPressed: () => Navigator.of(context).push(
                HipRoute.push<Object?>(
                  (_) => DrillDetailPage(
                    actions: widget.actions,
                    drillId: action.id,
                  ),
                ),
              ),
              child: Text(
                '${widget.actions.store.content.drill(action.id).name}${action.note == null ? '' : ' · ${action.note}'}',
              ),
            ),
        if (answer.status == uc.TurnStatus.limitReached)
          TextButton(onPressed: session.reset, child: const Text('对话已满，开始新对话')),
      ],
    );
  }

  Widget _planCard(
    uc.ValidatedPlan admitted,
    CoachAnswer answer,
    int resultId,
  ) {
    final plan = admitted.plan;
    final store = widget.actions.store;
    final mapper = CoachPlanMapper(store.content);
    final original = mapper.map(plan, id: 'preview', at: store.now());
    final saved = session.savedRoutine(resultId, store);
    final mapping = saved == null
        ? original
        : mapper.fromRoutine(saved, original);
    if (mapping.entries.isEmpty) return const SizedBox.shrink();
    return Column(
      key: const ValueKey('coach-plan-card'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            answer.preset ? '预设方案' : 'AI 定制',
            key: ValueKey(
              answer.preset ? 'coach-badge-preset' : 'coach-badge-ai',
            ),
            style: TextStyle(
              color: HipColors.jadeText,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (answer.preset)
          const Text(
            '这是 App 内置的套路，不是 AI 按你的需求生成的。',
            key: ValueKey('coach-preset-note'),
          ),
        ui.CoachPlanCard(
          key: ValueKey('coach-plan-$resultId'),
          plan: ui.CoachRoutine(
            id: mapping.routine.id,
            title: mapping.routine.name,
            items: [
              for (final entry in mapping.entries)
                ui.CoachRoutineItem(
                  exerciseId: entry.drill.id,
                  dose: entry.doseText,
                ),
            ],
            durationLabel:
                '约 ${math.max(1, (mapping.seconds(store.content) / 60).round())} 分钟',
            gearLabel: '按动作准备器材',
            levelLabel: '舒适范围',
            metaLabel: '${mapping.entries.length} 个动作',
            adjustmentsLabel: mapping.adjusted ? '剂量已按动作包的训练参数换算' : null,
          ),
          library: hipCoachLibrary(store),
          saved: saved != null,
          onSave: () {
            if (saved == null) unawaited(_save(plan, resultId));
          },
          onStart: (_) {
            if (!store.blocked) unawaited(_start(plan, resultId, null));
          },
          onOpen: () => showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            builder: (_) => SafeArea(
              child: SizedBox(
                height: MediaQuery.sizeOf(context).height * .8,
                child: ListView(
                  key: const ValueKey('coach-plan-details'),
                  padding: const EdgeInsets.all(20),
                  children: [
                    Text(
                      plan.title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    for (final entry in mapping.entries)
                      ListTile(
                        title: Text(entry.drill.name),
                        subtitle: Text(entry.doseText),
                        onTap: () => Navigator.of(context).push(
                          HipRoute.push<Object?>(
                            (_) => DrillDetailPage(
                              actions: widget.actions,
                              drillId: entry.drill.id,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
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
      surface: HipColors.surface,
      thumb: HipColors.thumb,
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
      mediaScrim: HipColors.scrim,
      landingHighlight: HipColors.jade,
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
            'AI 还没配置：现在会直接给出 App 内置的预设方案。',
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
