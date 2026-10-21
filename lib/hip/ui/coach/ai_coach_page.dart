// AI 定制：SDK 0.2 工具会话。仅渲染门禁后的文字、ValidatedActions 和
// ValidatedPlan；计划保存/开练沿用 HipLab 的剂量映射与共享训练播放器。
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:ugk_coach/ugk_coach.dart' as uc;

import '../../coach/coach_service.dart';
import '../../coach/plan_mapping.dart';
import '../../control/hip_store.dart';
import '../../domain/hip_library.dart';
import '../../domain/hip_models.dart';
import '../hip_icons.dart';
import '../hip_routes.dart';
import '../hip_theme.dart';
import '../hip_widgets.dart';
import '../library/drill_detail_page.dart';
import '../library/lib_text.dart';
import '../library/library_actions.dart';
import '../library/library_widgets.dart';
import '../library/practice_page.dart' show startGroup;

/// AI 定制只做中文（模型、目录文案都是中文），其他语言界面不显示入口。
bool aiCoachAvailable(BuildContext context) =>
    (Localizations.maybeLocaleOf(context)?.languageCode ?? 'zh') == 'zh';

/// 对话里的一条。
class CoachMessage {
  const CoachMessage.user(String this.text) : answer = null, resultId = -1;
  const CoachMessage.answer(CoachAnswer this.answer, this.resultId)
    : text = null;
  final String? text;
  final CoachAnswer? answer;

  /// 应用给每份回答分配的身份（会话内唯一），保存状态按它绑定，不依赖模型给的 plan id。
  final int resultId;
  bool get isUser => text != null;
}

/// 一次 AI 定制对话的状态。由首页外壳持有：进训练、看动作再回来，对话还在。
class AiCoachSession extends ChangeNotifier {
  AiCoachSession(this.service, {this.contextBuilder, DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final CoachService service;
  final uc.CoachContext Function()? contextBuilder;
  final DateTime Function() _now;
  final List<CoachMessage> messages = [];

  /// 已保存的回答：回答身份（[CoachMessage.resultId]）→ 训练组 id。
  /// 训练组可能已被删除，是否「已保存」以 store 里实际存在为准（[savedRoutine]）。
  final Map<int, String> saved = {};
  int _nextResult = 0;
  uc.CancelToken? _cancel;
  DateTime? _startedAt;
  bool _loaded = false;
  bool _disposed = false;
  int _generation = 0;

  /// 刚被停止的那句话（页面取走后清空）。
  String? cancelledText;

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

  Future<void> send(String raw, {uc.CoachContext? context}) async {
    final text = raw.trim();
    if (text.isEmpty || busy || _disposed) return;
    final generation = _generation;
    final cancel = uc.CancelToken();
    _cancel = cancel;
    _startedAt = _now();
    messages.add(CoachMessage.user(text));
    _notify();
    CoachAnswer answer;
    try {
      await service.load();
      if (_disposed || generation != _generation) return;
      answer = await service.send(
        text,
        context: context ?? contextBuilder?.call() ?? const uc.CoachContext(),
        cancel: cancel,
      );
    } on Object {
      answer = const CoachAnswer(
        status: uc.TurnStatus.error,
        text: '出了点问题，请稍后再试。',
      );
    }
    if (_disposed || generation != _generation || !identical(_cancel, cancel)) {
      return;
    }
    _cancel = null;
    _startedAt = null;
    if (answer.cancelled || cancel.isCancelled) {
      // 停止：撤回这句话，页面把它放回输入框。
      if (messages.isNotEmpty && messages.last.isUser) messages.removeLast();
      cancelledText = text;
    } else if (answer.status == uc.TurnStatus.busy) {
      if (messages.isNotEmpty && messages.last.isUser) messages.removeLast();
    } else {
      messages.add(CoachMessage.answer(answer, _nextResult++));
    }
    _notify();
  }

  /// 停止正在进行的请求（HTTP 真正中止，不回落、不记进对话）。
  void stop() => _cancel?.cancel();

  /// 显式开始新对话；旧请求晚到也不能影响新消息、保存身份或等待态。
  void newConversation() {
    _generation++;
    _cancel?.cancel();
    _cancel = null;
    _startedAt = null;
    service.reset();
    messages.clear();
    saved.clear();
    cancelledText = null;
    _notify();
  }

  void markSaved(int resultId, String routineId) {
    saved[resultId] = routineId;
    _notify();
  }

  /// 这份回答保存成的训练组（用户可能编辑过）；没保存或已删除 = null。
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
    _generation++;
    _cancel?.cancel();
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

  /// 本次等待已过的秒数（按 1 秒节拍累加）。
  int _elapsed = 0;

  AiCoachSession get session => widget.actions.coach!;

  @override
  void initState() {
    super.initState();
    session.addListener(_changed);
    if (!session.loaded) unawaited(session.load());
    if (session.busy) _startTicker();
  }

  @override
  void dispose() {
    session.removeListener(_changed);
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
      _scroll.position.maxScrollExtent,
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

  Future<void> _save(uc.ValidatedPlan validated, int resultId) async {
    final plan = validated.plan;
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
    uc.ValidatedPlan validated,
    int resultId,
    BuildContext? from,
  ) async {
    final plan = validated.plan;
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
    final configured = session.service.configured;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            HipTopBar(
              title: 'AI 定制训练',
              subtitle: configured ? null : '未配置 AI · 使用预设方案',
              icon: HipGlyph.back,
              tooltip: '返回',
              trailing: TextButton(
                key: const ValueKey('coach-new-conversation'),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(44, 44),
                ),
                onPressed: () {
                  _input.clear();
                  session.newConversation();
                },
                child: const Text('新对话', style: TextStyle(fontSize: 12)),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                key: const ValueKey('coach-list'),
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (session.showDisclaimer)
                      _Disclaimer(onAccept: session.acceptDisclaimer),
                    if (session.messages.isEmpty)
                      _Intro(
                        configured: configured,
                        onExample: session.busy ? null : _send,
                      ),
                    for (final (i, m) in session.messages.indexed)
                      KeyedSubtree(
                        key: ValueKey('coach-msg-$i'),
                        child: m.isUser ? _UserBubble(m.text!) : _answer(m),
                      ),
                    if (session.busy)
                      _Thinking(
                        key: const ValueKey('coach-thinking'),
                        seconds: _elapsed,
                        onStop: session.stop,
                      ),
                  ],
                ),
              ),
            ),
            _Composer(controller: _input, busy: session.busy, onSend: _send),
          ],
        ),
      ),
    );
  }

  Widget _answer(CoachMessage message) {
    final answer = message.answer!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (answer.text.isNotEmpty)
          _CoachBubble(
            text: answer.text,
            preset: answer.preset && answer.plan == null,
          ),
        if (answer.actions case final actions?)
          _ActionsCard(
            key: ValueKey('coach-actions-${message.resultId}'),
            actions: actions,
            content: widget.actions.store.content,
            onDrill: (id) => Navigator.of(context).push(
              HipRoute.push<Object?>(
                (_) => DrillDetailPage(actions: widget.actions, drillId: id),
              ),
            ),
          ),
        if (answer.plan case final plan?)
          _planCard(plan, answer, message.resultId),
      ],
    );
  }

  Widget _planCard(
    uc.ValidatedPlan validated,
    CoachAnswer answer,
    int resultId,
  ) {
    final plan = validated.plan;
    final store = widget.actions.store;
    final mapper = CoachPlanMapper(store.content);
    final original = mapper.map(plan, id: 'preview', at: store.now());
    // 保存后以「我的」里的训练组为准（含用户编辑）：卡片展示与开练是同一份。
    final routine = session.savedRoutine(resultId, store);
    final mapping = routine == null
        ? original
        : mapper.fromRoutine(routine, original);
    final saved = routine != null;
    final empty = mapping.entries.isEmpty;
    return _PlanCard(
      key: ValueKey('coach-plan-$resultId'),
      plan: validated,
      mapping: mapping,
      seconds: mapping.seconds(store.content),
      preset: answer.preset,
      saved: saved,
      blocked: store.blocked,
      onDrill: (id) => Navigator.of(context).push(
        HipRoute.push<Object?>(
          (_) => DrillDetailPage(actions: widget.actions, drillId: id),
        ),
      ),
      onSave: saved || empty ? null : () => _save(validated, resultId),
      onStart: empty || store.blocked
          ? null
          : (from) => _start(validated, resultId, from),
    );
  }
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

class _UserBubble extends StatelessWidget {
  const _UserBubble(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerRight,
    child: Padding(
      padding: const EdgeInsets.only(left: 48, bottom: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: tintOf(HipColors.jade),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(18),
            bottomRight: Radius.circular(6),
          ),
        ),
        child: Text(text, style: const TextStyle(fontSize: 15, height: 1.45)),
      ),
    ),
  );
}

class _CoachBubble extends StatelessWidget {
  const _CoachBubble({required this.text, this.preset = false});
  final String text;
  final bool preset;
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: Padding(
      padding: const EdgeInsets.only(right: 32, bottom: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: HipColors.surface,
          border: Border.all(color: HipColors.line),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(6),
            bottomRight: Radius.circular(18),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 15,
            height: 1.5,
            color: preset ? HipColors.muted : HipColors.text,
          ),
        ),
      ),
    ),
  );
}

/// 看动作卡只接受 SDK 门禁产出的动作列表，不从模型 JSON 构造 UI。
class _ActionsCard extends StatelessWidget {
  const _ActionsCard({
    super.key,
    required this.actions,
    required this.content,
    required this.onDrill,
  });
  final uc.ValidatedActions actions;
  final HipContent content;
  final ValueChanged<String> onDrill;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: HipPanel(
      key: const ValueKey('coach-actions-card'),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '动作建议',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          for (final (i, action) in actions.items.indexed)
            HipPressable(
              key: ValueKey('coach-action-$i'),
              semanticLabel: content.drill(action.id).name,
              scale: .98,
              onTap: () => onDrill(action.id),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    HipThumb(
                      size: 52,
                      radius: 12,
                      child: HipDrillArt(
                        drill: content.drill(action.id),
                        showPendingLabel: false,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            content.drill(action.id).name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (action.note case final note?
                              when note.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              note,
                              style: TextStyle(
                                fontSize: 13,
                                color: HipColors.muted,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    HipIcon(
                      HipGlyph.chevronRight,
                      size: 18,
                      color: HipColors.faint,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

/// 首轮计划可能等待 75–120 秒；显示真实已用时，不伪造后台处理步骤。
class _Thinking extends StatelessWidget {
  const _Thinking({super.key, required this.seconds, required this.onStop});
  final int seconds;
  final VoidCallback onStop;

  static (String, String) stage(int seconds) => switch (seconds) {
    < 75 => ('正在等待 AI 回复…', '生成中'),
    < 120 => ('首轮计划需要较长时间，可以继续等，也可以取消', '仍在生成'),
    _ => ('仍在等待服务响应，可以取消后重试', '等待中'),
  };

  @override
  Widget build(BuildContext context) {
    final (title, step) = stage(seconds);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: HipPanel(
        radius: 18,
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  key: const ValueKey('coach-progress'),
                  minHeight: 5,
                  backgroundColor: HipColors.track,
                  color: HipColors.jade,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '$step · 已用 $seconds 秒，首轮计划可能需要 75–120 秒',
                    key: const ValueKey('coach-elapsed'),
                    style: TextStyle(fontSize: 12, color: HipColors.faint),
                  ),
                ),
                TextButton.icon(
                  key: const ValueKey('coach-stop'),
                  onPressed: onStop,
                  icon: HipIcon(
                    HipGlyph.stop,
                    size: 16,
                    color: HipColors.tight,
                  ),
                  label: Text('取消', style: TextStyle(color: HipColors.tight)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    super.key,
    required this.plan,
    required this.mapping,
    required this.seconds,
    required this.preset,
    required this.saved,
    required this.blocked,
    required this.onDrill,
    required this.onSave,
    required this.onStart,
  });
  final uc.ValidatedPlan plan;
  final CoachPlanMapping mapping;
  final int seconds;
  final bool preset;
  final bool saved;
  final bool blocked;
  final ValueChanged<String> onDrill;
  final VoidCallback? onSave;
  final void Function(BuildContext? from)? onStart;

  static const stopLine = '在不痛的范围内做，出现疼痛、麻木或头晕立即停止。';

  @override
  Widget build(BuildContext context) {
    final plan = this.plan.plan;
    final t = LibText.of(context);
    final entries = mapping.entries;
    final startKey = GlobalKey();
    String? lastBlock;
    final notes = <String>{
      if (plan.avoid.isNotEmpty) '已避开${plan.avoid.join('、')}受力较大的动作。',
      ...plan.safetyNotes,
      if (mapping.adjusted) '剂量已按动作包的训练参数换算（标 * 的动作）。',
      stopLine,
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: HipPanel(
        key: const ValueKey('coach-plan-card'),
        borderColor: preset ? null : HipColors.jade.withValues(alpha: .55),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                KeyedSubtree(
                  key: ValueKey(
                    preset ? 'coach-badge-preset' : 'coach-badge-ai',
                  ),
                  child: tintTag(
                    preset ? '预设方案' : 'AI 定制',
                    color: preset ? HipColors.tight : null,
                  ),
                ),
                Text(
                  '${t.movesCount(entries.length)} · 约 ${math.max(1, (seconds / 60).round())} 分钟',
                  key: const ValueKey('coach-plan-meta'),
                  style: TextStyle(fontSize: 13, color: HipColors.muted),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              plan.title,
              style: const TextStyle(
                fontSize: 19,
                height: 1.3,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (plan.summary.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                plan.summary,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  color: HipColors.muted,
                ),
              ),
            ],
            if (preset) ...[
              const SizedBox(height: 6),
              Text(
                '这是 App 内置的套路，不是 AI 按你的需求生成的。',
                key: const ValueKey('coach-preset-note'),
                style: TextStyle(
                  fontSize: 12,
                  height: 1.4,
                  color: HipColors.tight,
                ),
              ),
            ],
            const SizedBox(height: 10),
            for (final (i, entry) in entries.indexed) ...[
              if (entry.blockName != lastBlock && !preset)
                Padding(
                  padding: const EdgeInsets.only(top: 6, bottom: 2),
                  child: Text(
                    lastBlock = entry.blockName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: HipColors.jadeText,
                    ),
                  ),
                ),
              _EntryRow(
                key: ValueKey('coach-row-$i'),
                entry: entry,
                onTap: () => onDrill(entry.drill.id),
              ),
            ],
            const SizedBox(height: 4),
            for (final note in notes)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: HipIcon(
                        HipGlyph.info,
                        size: 14,
                        color: HipColors.faint,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        note,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.4,
                          color: HipColors.muted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (blocked) ...[
              const SizedBox(height: 8),
              Text(
                '安全提示里有需要先问医生的情况，暂时不能开始训练。',
                key: const ValueKey('coach-blocked'),
                style: TextStyle(
                  fontSize: 12,
                  height: 1.4,
                  color: HipColors.pain,
                ),
              ),
            ],
            const SizedBox(height: 14),
            KeyedSubtree(
              key: startKey,
              child: HipPrimaryButton(
                key: const ValueKey('coach-start'),
                icon: HipGlyph.play,
                label: '开始训练',
                onPressed: onStart == null
                    ? null
                    : () => onStart!(startKey.currentContext),
              ),
            ),
            const SizedBox(height: 10),
            HipSecondaryButton(
              key: const ValueKey('coach-save'),
              label: saved ? '已保存到「我的」' : '保存为自定义训练组',
              onPressed: onSave,
            ),
          ],
        ),
      ),
    );
  }
}

class _EntryRow extends StatelessWidget {
  const _EntryRow({super.key, required this.entry, required this.onTap});
  final CoachPlanEntry entry;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => HipPressable(
    semanticLabel: entry.drill.name,
    scale: .98,
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          HipThumb(
            size: 52,
            radius: 12,
            child: HipDrillArt(drill: entry.drill, showPendingLabel: false),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.drill.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.3,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  entry.adjusted ? '${entry.doseText} *' : entry.doseText,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.35,
                    color: HipColors.muted,
                  ),
                ),
              ],
            ),
          ),
          HipIcon(HipGlyph.chevronRight, size: 18, color: HipColors.faint),
        ],
      ),
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
                maxLength: 500,
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
