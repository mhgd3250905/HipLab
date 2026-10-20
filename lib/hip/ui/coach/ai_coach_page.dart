// AI 定制（docs/ai-coach.md）：描述需求 → 最多追问一次 → 计划卡 →「开始训练」/
// 「保存为自定义训练组」。交互沿用 3D-Body feat/ai-coach `app/lib/ui/ai_coach_page.dart`
// （PR #122），换成 HipLab 的组件与配色（HipPanel / HipPrimaryButton / LibChip …）。
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:ugk_coach/ugk_coach.dart' as uc;

import '../../coach/coach_service.dart';
import '../../coach/plan_mapping.dart';
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
  const CoachMessage.user(String this.text) : answer = null;
  const CoachMessage.answer(CoachAnswer this.answer) : text = null;
  final String? text;
  final CoachAnswer? answer;
  bool get isUser => text != null;
}

/// 一次 AI 定制对话的状态。由首页外壳持有：进训练、看动作再回来，对话还在。
class AiCoachSession extends ChangeNotifier {
  AiCoachSession(this.service, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final CoachService service;
  final DateTime Function() _now;
  final uc.CoachConversation conversation = uc.CoachConversation();
  final List<CoachMessage> messages = [];

  /// 已保存的计划：计划 id → 训练组 id。
  final Map<String, String> saved = {};
  uc.CancelToken? _cancel;
  DateTime? _startedAt;
  bool _loaded = false;
  bool _disposed = false;

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

  Future<void> send(String raw) async {
    final text = raw.trim();
    if (text.isEmpty || busy) return;
    final cancel = uc.CancelToken();
    _cancel = cancel;
    _startedAt = _now();
    messages.add(CoachMessage.user(text));
    _notify();
    CoachAnswer answer;
    try {
      answer = await service.ask(text, conversation, cancel: cancel);
    } on Object {
      answer = const CoachAnswer(
        reply: uc.CoachReply.text('出了点问题，没能排出计划。请稍后再试。'),
      );
    }
    if (_disposed) return;
    _cancel = null;
    _startedAt = null;
    if (answer.cancelled) {
      // 停止：撤回这句话，页面把它放回输入框。
      if (messages.isNotEmpty && messages.last.isUser) messages.removeLast();
      cancelledText = text;
    } else {
      messages.add(CoachMessage.answer(answer));
    }
    _notify();
  }

  /// 停止正在进行的请求（HTTP 真正中止，不回落、不记进对话）。
  void stop() => _cancel?.cancel();

  void markSaved(String planId, String routineId) {
    saved[planId] = routineId;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
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

  Future<void> _save(uc.TrainingPlan plan) async {
    final store = widget.actions.store;
    final mapping = CoachPlanMapper(
      store.content,
    ).map(plan, id: store.newCustomId(), at: store.now());
    final routine = await store.saveCustomRoutine(mapping.routine);
    if (!mounted) return;
    session.markSaved(plan.id, routine.id);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('已保存到「我的」训练组：${routine.name}')));
  }

  Future<void> _start(uc.TrainingPlan plan, BuildContext? from) async {
    final store = widget.actions.store;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    final saved = session.saved[plan.id];
    final routine =
        (saved == null ? null : store.customRoutine(saved)) ??
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
                        child: m.isUser
                            ? _UserBubble(m.text!)
                            : _answer(m.answer!, i),
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

  Widget _answer(CoachAnswer answer, int index) {
    final reply = answer.reply;
    if (reply == null) return const SizedBox.shrink();
    final latest = index == session.messages.length - 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (reply.text.isNotEmpty)
          _CoachBubble(
            text: reply.text,
            preset: answer.preset && reply.plan == null,
          ),
        if (reply.kind == uc.ReplyKind.ask && reply.options.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final (i, option) in reply.options.indexed)
                  LibChip(
                    option,
                    key: ValueKey('coach-option-$i'),
                    onTap: latest && !session.busy ? () => _send(option) : null,
                  ),
              ],
            ),
          ),
        if (reply.plan case final plan?) _planCard(plan, answer),
      ],
    );
  }

  Widget _planCard(uc.TrainingPlan plan, CoachAnswer answer) {
    final store = widget.actions.store;
    final mapping = CoachPlanMapper(
      store.content,
    ).map(plan, id: 'preview', at: store.now());
    final saved = session.saved.containsKey(plan.id);
    final empty = mapping.entries.isEmpty;
    return _PlanCard(
      key: ValueKey('coach-plan-${plan.id}'),
      plan: plan,
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
      onSave: saved || empty ? null : () => _save(plan),
      onStart: empty || store.blocked ? null : (from) => _start(plan, from),
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

/// 推理模型出一份计划约 30–40 秒：分步提示 + 已用时 + 进度条 + 可停止。
class _Thinking extends StatelessWidget {
  const _Thinking({super.key, required this.seconds, required this.onStop});
  final int seconds;
  final VoidCallback onStop;

  static (String, String) stage(int seconds) => switch (seconds) {
    < 6 => ('正在理解你的需求…', '第 1 步 / 共 3 步'),
    < 22 => ('正在从动作大全里挑动作、配剂量…', '第 2 步 / 共 3 步'),
    < 45 => ('正在核对动作范围、剂量和安全…', '第 3 步 / 共 3 步'),
    _ => ('比平时久一点，可以继续等，或停止后改改需求再发', '仍在等待'),
  };

  @override
  Widget build(BuildContext context) {
    final (title, step) = stage(seconds);
    final progress = (seconds / 40).clamp(.04, .94);
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
                  value: progress,
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
                    '$step · 已用 $seconds 秒，通常 30–40 秒',
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
                  label: Text('停止', style: TextStyle(color: HipColors.tight)),
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
  final uc.TrainingPlan plan;
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
