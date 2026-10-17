import 'package:flutter/material.dart';

import '../control/hip_store.dart';
import '../domain/hip_assessment.dart';
import '../domain/hip_models.dart';
import '../domain/hip_session.dart';
import 'hip_theme.dart';
import 'hip_widgets.dart';

/// The 自测 tab: one card and one button.
class HipAssessmentIntro extends StatelessWidget {
  const HipAssessmentIntro({
    super.key,
    required this.store,
    required this.onStart,
  });
  final HipStore store;
  final VoidCallback onStart;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          '开胯体检',
          style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        const Text(
          '6 项 · 约 3 分 30 秒',
          style: TextStyle(color: HipColors.muted),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: HipPanel(
            padding: const EdgeInsets.all(12),
            child: GridView.count(
              crossAxisCount: 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                for (final item in store.content.rules.items)
                  Column(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: HipDrillArt(
                            drill:
                                item.demoArt(store.content.drills) ??
                                store.content.mvpDrills.first,
                            showPendingLabel: false,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${item.order} ${item.title}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        HipPrimaryButton(
          key: const ValueKey('assessment-start'),
          label: store.blocked ? '先问问医生再来' : '开始自测',
          icon: Icons.play_arrow_rounded,
          onPressed: store.blocked ? null : onStart,
        ),
      ],
    ),
  );
}

class HipAssessmentPage extends StatefulWidget {
  const HipAssessmentPage({
    super.key,
    required this.store,
    required this.onStartPlan,
  });
  final HipStore store;
  final Future<void> Function(TrainingPlan plan) onStartPlan;
  @override
  State<HipAssessmentPage> createState() => _HipAssessmentPageState();
}

class _HipAssessmentPageState extends State<HipAssessmentPage>
    with SingleTickerProviderStateMixin {
  final _answers = <String, ItemAnswer>{};
  int _index = 0;
  HipSide? _side;
  SideAnswer? _leftAnswer;
  int? _choice;
  String? _follow;
  AssessmentResult? _result;
  late final AnimationController _timer = AnimationController(vsync: this);

  List<AssessmentItem> get _items => widget.store.content.rules.items;
  AssessmentItem get _item => _items[_index];

  @override
  void initState() {
    super.initState();
    _beginItem();
  }

  void _beginItem() {
    _side = _item.sided ? HipSide.left : null;
    _leftAnswer = null;
    _restartTimer();
  }

  void _restartTimer() {
    _choice = null;
    _follow = null;
    _timer
      ..duration = Duration(seconds: _item.seconds)
      ..forward(from: 0);
  }

  @override
  void dispose() {
    _timer.dispose();
    super.dispose();
  }

  bool get _needsFollow => _item.followUp.isNotEmpty && _choice == 0;
  bool get _canNext => _choice != null && (!_needsFollow || _follow != null);

  Future<void> _record(SideAnswer answer) async {
    if (_side == HipSide.left) {
      _leftAnswer = answer;
      setState(() {
        _side = HipSide.right;
        _restartTimer();
      });
      return;
    }
    _answers[_item.id] = _side == HipSide.right
        ? ItemAnswer.sided(left: _leftAnswer!, right: answer)
        : ItemAnswer.single(answer);
    await _advance();
  }

  Future<void> _advance() async {
    if (_index < _items.length - 1) {
      setState(() {
        _index++;
        _beginItem();
      });
      return;
    }
    _timer.stop();
    final result = await widget.store.saveAssessment(_answers);
    if (mounted) setState(() => _result = result);
  }

  Future<void> _skipItem() async {
    _answers[_item.id] = _item.sided
        ? const ItemAnswer.sided(
            left: SideAnswer.skipped(),
            right: SideAnswer.skipped(),
          )
        : const ItemAnswer.single(SideAnswer.skipped());
    await _advance();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: _result == null ? _itemScreen() : _resultScreen(_result!),
    ),
  );

  Widget _header({required Widget center, String? trailing}) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 8, 20, 8),
    child: Row(
      children: [
        HipCircleButton(
          icon: Icons.close_rounded,
          tooltip: '关闭',
          onPressed: () => Navigator.of(context).pop(),
        ),
        Expanded(child: Center(child: center)),
        SizedBox(
          width: 44,
          child: Text(
            trailing ?? '',
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 16, color: HipColors.muted),
          ),
        ),
      ],
    ),
  );

  Widget _itemScreen() {
    final item = _item;
    final demo = item.demoArt(widget.store.content.drills);
    return Column(
      children: [
        _header(
          trailing: '${_index + 1}/${_items.length}',
          center: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < _items.length; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: i == _index ? 26 : 7,
                  height: 7,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: i <= _index ? HipColors.jade : HipColors.surfaceHigh,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            children: [
              Container(
                height: 300,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: HipColors.surface,
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: HipColors.line),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Until the demo loop is rendered, show the middle comparison
                    // still when there is one (same model, same camera).
                    if (demo != null &&
                        (demo.mediaStatus != HipMediaStatus.pending ||
                            item.options[1].image == null))
                      HipDrillArt(drill: demo, play: true)
                    else if (item.options[1].image != null)
                      Image.asset(item.options[1].image!, fit: BoxFit.cover)
                    else
                      const HipPendingArt(label: '动画待渲染'),
                    Positioned(
                      left: 14,
                      top: 14,
                      child: _pill(Icons.repeat_rounded, '跟着做一遍'),
                    ),
                    if (_side != null)
                      Positioned(
                        right: 14,
                        top: 14,
                        child: _pill(
                          Icons.swap_horiz_rounded,
                          _side == HipSide.left ? '左边' : '右边',
                        ),
                      ),
                    Positioned(
                      left: 24,
                      right: 24,
                      bottom: 16,
                      child: AnimatedBuilder(
                        animation: _timer,
                        builder: (_, _) => ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: _timer.value,
                            minHeight: 4,
                            color: HipColors.text,
                            backgroundColor: HipColors.text.withValues(
                              alpha: .18,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Text(
                '${item.title} · ${_needsFollow ? item.followUpQuestion! : item.question}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _needsFollow ? '点一下' : '我像哪个',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, color: HipColors.muted),
              ),
              const SizedBox(height: 16),
              _needsFollow ? _followRow(item) : _optionRow(item),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton.icon(
                    key: const ValueKey('assessment-pain'),
                    onPressed: () => _record(const SideAnswer.pain()),
                    icon: const Icon(
                      Icons.bolt_rounded,
                      color: HipColors.pain,
                      size: 18,
                    ),
                    label: const Text(
                      '做的时候疼',
                      style: TextStyle(color: HipColors.pain),
                    ),
                  ),
                  const Text('·', style: TextStyle(color: HipColors.faint)),
                  TextButton(
                    key: const ValueKey('assessment-skip'),
                    onPressed: _skipItem,
                    child: const Text(
                      '做不了 · 跳过',
                      style: TextStyle(color: HipColors.muted),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: HipPrimaryButton(
            key: const ValueKey('assessment-next'),
            label: _index == _items.length - 1 && _side != HipSide.left
                ? '看结果'
                : '下一项',
            trailing: Icons.chevron_right_rounded,
            onPressed: _canNext
                ? () => _record(SideAnswer.choice(_choice!, followUp: _follow))
                : null,
          ),
        ),
      ],
    );
  }

  Widget _pill(IconData icon, String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: HipColors.background.withValues(alpha: .6),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: HipColors.line),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: HipColors.muted),
        const SizedBox(width: 5),
        Text(text, style: const TextStyle(fontSize: 13, color: HipColors.text)),
      ],
    ),
  );

  Widget _optionRow(AssessmentItem item) => Row(
    children: [
      for (final (i, o) in item.options.indexed) ...[
        if (i > 0) const SizedBox(width: 10),
        Expanded(
          child: _choiceCard(
            key: ValueKey('option-${o.score}'),
            selected: _choice == o.score,
            onTap: () => setState(() => _choice = o.score),
            image: o.image,
            footer: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                HipLevelBars(
                  level: o.score + 1,
                  color: _choice == o.score ? HipColors.jade : HipColors.text,
                ),
                const SizedBox(width: 6),
                Text(
                  o.label,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: _choice == o.score ? HipColors.jade : HipColors.text,
                  ),
                ),
              ],
            ),
            semantic: '${o.label}：${o.description}',
          ),
        ),
      ],
    ],
  );

  Widget _followRow(AssessmentItem item) => Row(
    children: [
      for (final (i, o) in item.followUp.indexed) ...[
        if (i > 0) const SizedBox(width: 10),
        Expanded(
          child: _choiceCard(
            key: ValueKey('follow-${o.id}'),
            selected: _follow == o.id,
            onTap: () => setState(() => _follow = o.id),
            image: o.image,
            footer: Text(
              o.label,
              style: TextStyle(
                fontSize: 15,
                color: _follow == o.id ? HipColors.jade : HipColors.text,
              ),
            ),
            semantic: o.label,
          ),
        ),
      ],
    ],
  );

  Widget _choiceCard({
    required Key key,
    required bool selected,
    required VoidCallback onTap,
    required Widget footer,
    required String semantic,
    String? image,
  }) => Semantics(
    button: true,
    selected: selected,
    label: semantic,
    child: GestureDetector(
      key: key,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 186,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: HipColors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected ? HipColors.jade : HipColors.line,
            width: selected ? 3 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: HipColors.jade.withValues(alpha: .25),
                    blurRadius: 18,
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  image == null
                      ? const HipPendingArt(label: '对比图待渲染')
                      : Image.asset(
                          image,
                          fit: BoxFit.cover,
                          alignment: const Alignment(0, .3),
                        ),
                  if (selected)
                    const Positioned(
                      right: 8,
                      top: 8,
                      child: CircleAvatar(
                        radius: 13,
                        backgroundColor: HipColors.jade,
                        child: Icon(
                          Icons.check_rounded,
                          size: 18,
                          color: Color(0xff07261d),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Container(
              height: 48,
              color: HipColors.surfaceHigh.withValues(alpha: selected ? .4 : 1),
              alignment: Alignment.center,
              child: footer,
            ),
          ],
        ),
      ),
    ),
  );

  // ───────── result ─────────

  Widget _resultScreen(AssessmentResult r) {
    final store = widget.store;
    final routine = r.route == null
        ? null
        : store.content.routine(r.route!.routineId);
    final plan = routine == null
        ? null
        : store.planner.planFor([routine], store.profile);
    return Column(
      children: [
        _header(center: const SizedBox()),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            children: [
              const Text(
                '自测完成',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: HipColors.jade,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Text(
                '你的髋部',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
              ),
              SizedBox(
                height: 300,
                child: Center(
                  child: HipRadar(
                    values: r.radar,
                    highlight: r.tightest.toSet(),
                    warn: r.painDirections,
                  ),
                ),
              ),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (r.tightest.isNotEmpty)
                    _resultChip(
                      HipColors.tight,
                      '最紧：${r.tightest.map((d) => d.zh).join(' · ')}',
                    ),
                  if (r.best != null)
                    _resultChip(HipColors.jade, '最好：${r.best!.zh}'),
                  if (r.painDirections.isNotEmpty)
                    _resultChip(
                      HipColors.pain,
                      '先别练这里：${r.painDirections.map((d) => d.zh).join(' · ')}',
                    ),
                  if (r.untestedDirections.isNotEmpty)
                    _resultChip(
                      HipColors.faint,
                      '未测：${r.untestedDirections.map((d) => d.zh).join(' · ')}',
                    ),
                ],
              ),
              if (r.lowest != null) ...[
                const SizedBox(height: 10),
                Text(
                  '你的${_area(r.lowest!)}最紧，先从这里开始。',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: HipColors.muted),
                ),
              ],
              const SizedBox(height: 16),
              if (r.route != null && routine != null)
                _routeCard(r.route!, routine, plan),
              if (r.dancerUnlocked) ...[
                const SizedBox(height: 10),
                Center(child: _resultChip(HipColors.jade, '已解锁托马斯动作库')),
              ],
            ],
          ),
        ),
        if (plan != null && plan.steps.isNotEmpty) ...[
          TextButton(
            onPressed: _chooseOther,
            child: const Text(
              '换一条路线',
              style: TextStyle(color: HipColors.muted),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: HipPrimaryButton(
              key: const ValueKey('result-start'),
              label: '开始这条路线',
              icon: Icons.play_arrow_rounded,
              onPressed: () => _start(plan),
            ),
          ),
        ],
      ],
    );
  }

  static String _area(HipDirection d) => switch (d) {
    HipDirection.flexion => '大腿后侧',
    HipDirection.extension => '髋前侧',
    HipDirection.abduction => '大腿内侧',
    HipDirection.adduction => '髋外侧',
    HipDirection.internalRotation => '髋内旋',
    HipDirection.externalRotation => '髋外旋',
  };

  Future<void> _start(TrainingPlan plan) async {
    Navigator.of(context).pop();
    await widget.onStartPlan(plan);
  }

  Future<void> _chooseOther() async {
    final store = widget.store;
    final routine = await showModalBottomSheet<HipRoutine>(
      context: context,
      backgroundColor: HipColors.surface,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final r in store.content.routines.where((r) => !r.micro))
              ListTile(
                title: Text(r.name),
                subtitle: Text(
                  r.audience,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Text(
                  r.scene.zh,
                  style: const TextStyle(color: HipColors.muted),
                ),
                onTap: () => Navigator.of(context).pop(r),
              ),
          ],
        ),
      ),
    );
    if (routine != null) {
      await _start(store.planner.planFor([routine], store.profile));
    }
  }

  Widget _resultChip(Color color, String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: BoxDecoration(
      color: HipColors.surface,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ],
    ),
  );

  Widget _routeCard(RouteSuggestion s, HipRoutine routine, TrainingPlan? plan) {
    final hero = plan?.steps
        .where((p) => p.drill.poster != null)
        .firstOrNull
        ?.drill;
    return Container(
      height: 210,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: HipColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: HipColors.jade.withValues(alpha: .45)),
      ),
      child: Stack(
        children: [
          if (hero != null)
            Positioned(
              right: -20,
              top: 0,
              bottom: 0,
              width: 190,
              child: HipDrillArt(drill: hero),
            ),
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  stops: [.45, .75],
                  colors: [HipColors.surface, Color(0x0016171a)],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '为你推荐',
                  style: TextStyle(
                    fontSize: 13,
                    color: HipColors.jade,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  width: 210,
                  child: Text(
                    s.route,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${routine.name} · ${plan?.steps.length ?? 0} 个动作',
                  style: const TextStyle(fontSize: 13, color: HipColors.muted),
                ),
                const Spacer(),
                Row(
                  children: [
                    for (final p in (plan?.steps ?? const <PlanStep>[]).take(3))
                      Container(
                        width: 46,
                        height: 46,
                        margin: const EdgeInsets.only(right: 6),
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: HipColors.line),
                        ),
                        child: HipDrillArt(
                          drill: p.drill,
                          showPendingLabel: false,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
