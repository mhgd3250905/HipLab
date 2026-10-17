import 'dart:async';

import 'package:flutter/material.dart';

import '../control/hip_store.dart';
import '../domain/hip_assessment.dart';
import '../domain/hip_models.dart';
import '../domain/hip_pain.dart';
import '../domain/hip_session.dart';
import 'hip_theme.dart';
import 'hip_widgets.dart';

enum _Phase { work, transition, done, stopped }

/// Full-screen follow-along player: animation, countdown ring, side switch,
/// pause / skip, one subtitle line, no arrows. Pain walks the ladder.
class HipPlayerPage extends StatefulWidget {
  const HipPlayerPage({super.key, required this.store, required this.plan});
  final HipStore store;
  final TrainingPlan plan;
  @override
  State<HipPlayerPage> createState() => _HipPlayerPageState();
}

class _HipPlayerPageState extends State<HipPlayerPage> {
  late final List<PlanStep> _steps = [...widget.plan.steps];
  late final SessionPainLadder _ladder = SessionPainLadder(
    widget.store.content,
  );
  int _index = 0;
  late int _total = _steps.first.seconds;
  late int _left = _total;
  int _transitionLeft = 0;
  bool _paused = false;
  _Phase _phase = _Phase.work;
  String? _ladderCue;
  int _completed = 0;
  Timer? _ticker;

  PlanStep get _step => _steps[_index];
  PlanStep? get _next => _index + 1 < _steps.length ? _steps[_index + 1] : null;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _tick() {
    if (_paused || !mounted) return;
    setState(() {
      switch (_phase) {
        case _Phase.work:
          _left--;
          if (_left <= 0) _finishStep();
        case _Phase.transition:
          _transitionLeft--;
          if (_transitionLeft <= 0) _startStep(_index + 1);
        case _Phase.done || _Phase.stopped:
          break;
      }
    });
  }

  void _finishStep() {
    _completed++;
    if (_next == null) {
      _phase = _Phase.done;
      widget.store.completeSession(_ladder);
      return;
    }
    _phase = _Phase.transition;
    _transitionLeft = widget.plan.transitionSeconds;
  }

  void _startStep(int i, {int? seconds}) {
    if (i >= _steps.length) {
      _phase = _Phase.done;
      widget.store.completeSession(_ladder);
      return;
    }
    _index = i;
    _total = seconds ?? _steps[i].seconds;
    _left = _total;
    _phase = _Phase.work;
    if (seconds == null) _ladderCue = null;
  }

  void _skip() => setState(() {
    if (_phase == _Phase.transition) {
      _startStep(_index + 1);
    } else {
      _finishStep();
    }
  });

  /// Side for sided drills: right first, then left (成套训练 编排规则 2).
  HipSide? get _side {
    if (!_step.sided || _phase != _Phase.work) return null;
    return _left > _total / 2 ? HipSide.right : HipSide.left;
  }

  int get _secondsToSwitch => (_left - (_total / 2).floor()).clamp(0, _total);

  String get _cue {
    if (_ladderCue != null) return _ladderCue!;
    if (_step.extraSide != null) {
      return '${_step.extraSide == HipSide.right ? '右' : '左'}边多做一组';
    }
    if (_step.tip.isNotEmpty) return _step.tip;
    final m = _step.drill.methods.first;
    return switch (m) {
      HipMethod.relax => '慢慢呼吸，放松',
      HipMethod.flexibility => '呼气，再沉一点',
      HipMethod.control => '慢一点，控制住',
      HipMethod.strength => '稳住，别憋气',
    };
  }

  Future<void> _pain({required bool afterStep}) async {
    final wasPaused = _paused;
    setState(() => _paused = true);
    final kind = await showModalBottomSheet<PainKind>(
      context: context,
      backgroundColor: HipColors.surface,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '哪种疼？',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  for (final (k, icon, label) in [
                    (PainKind.pinch, Icons.compress_rounded, '关节夹着疼'),
                    (PainKind.nerve, Icons.bolt_rounded, '麻、刺、往下窜'),
                  ]) ...[
                    if (k == PainKind.nerve) const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        key: ValueKey('pain-${k.name}'),
                        onTap: () => Navigator.of(context).pop(k),
                        child: HipPanel(
                          child: Column(
                            children: [
                              Icon(icon, size: 44, color: HipColors.pain),
                              const SizedBox(height: 8),
                              Text(label, style: const TextStyle(fontSize: 15)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted) return;
    if (kind == null) {
      setState(() => _paused = wasPaused);
      return;
    }
    final target = afterStep ? _steps[_index] : _step;
    final action = _ladder.report(
      target.drill.id,
      kind,
      alternative: target.alternative,
    );
    setState(() {
      _paused = false;
      _ladderCue = action.cue;
      _apply(action, target, afterStep: afterStep);
    });
    if (action.type == PainActionType.endSession) {
      await widget.store.recordNerve(action.direction!);
    }
  }

  void _apply(PainAction action, PlanStep target, {required bool afterStep}) {
    switch (action.type) {
      case PainActionType.endSession:
        _phase = _Phase.stopped;
      case PainActionType.reduceAmplitude:
        // Half the range and half the time; after a finished drill this only
        // shortens the drill's later appearances.
        if (!afterStep) {
          _startStep(_index, seconds: (target.seconds / 2).ceil());
        }
      case PainActionType.substitute:
        final alt = widget.store.content.drill(action.substituteId!);
        PlanStep swap(PlanStep s) => PlanStep(
          drill: alt,
          dose: s.dose,
          seconds: s.seconds,
          sided: s.sided,
          extraSide: s.extraSide,
          replaced: s.drill.id,
        );
        for (var i = afterStep ? _index + 1 : _index; i < _steps.length; i++) {
          if (_steps[i].drill.id == target.drill.id) {
            _steps[i] = swap(_steps[i]);
          }
        }
        if (!afterStep) _startStep(_index, seconds: _steps[_index].seconds);
      case PainActionType.skipDirection:
        final dir = action.direction!;
        final from = _index + 1;
        _steps.removeWhere(
          (s) =>
              _steps.indexOf(s) >= from &&
              s.drill.directions.first == dir &&
              !s.drill.isRelax,
        );
        if (!afterStep) {
          _completed++;
          _startStep(_index + 1);
        }
    }
  }

  Future<void> _close() async {
    _ticker?.cancel();
    if (_phase != _Phase.done) {
      if (_completed > 0) {
        await widget.store.completeSession(_ladder);
      } else {
        await widget.store.recordLadder(_ladder);
      }
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) _close();
    },
    child: Scaffold(
      body: SafeArea(
        child: switch (_phase) {
          _Phase.done => _finished(),
          _Phase.stopped => _stopped(),
          _ => _playing(),
        },
      ),
    ),
  );

  Widget _playing() {
    final transition = _phase == _Phase.transition;
    final shown = transition ? (_next ?? _step) : _step;
    final side = _side;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 20, 4),
          child: Row(
            children: [
              HipCircleButton(
                icon: Icons.close_rounded,
                tooltip: '结束',
                onPressed: _close,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  children: [
                    for (var i = 0; i < _steps.length; i++)
                      Expanded(
                        child: Container(
                          height: 4,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                            color: i < _index || (i == _index && transition)
                                ? HipColors.text.withValues(alpha: .75)
                                : i == _index
                                ? HipColors.jade
                                : HipColors.surfaceHigh,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${_index + 1}/${_steps.length}',
                style: const TextStyle(color: HipColors.muted, fontSize: 15),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 44,
          child: side == null
              ? null
              : Center(
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: HipColors.surface,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final s in [HipSide.left, HipSide.right])
                          Container(
                            width: 52,
                            height: 30,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: s == side ? HipColors.jade : null,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              s == HipSide.left ? '左' : '右',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: s == side
                                    ? const Color(0xff07261d)
                                    : HipColors.muted,
                              ),
                            ),
                          ),
                        if (side == HipSide.right) ...[
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.swap_horiz_rounded,
                            size: 16,
                            color: HipColors.muted,
                          ),
                          Text(
                            ' $_secondsToSwitch 秒后换边  ',
                            style: const TextStyle(
                              fontSize: 13,
                              color: HipColors.muted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
        ),
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              HipDrillArt(
                drill: shown.drill,
                play: !transition && !_paused,
                fit: BoxFit.cover,
              ),
              const Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 120,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x000c0d0f), HipColors.background],
                    ),
                  ),
                ),
              ),
              Positioned(left: 16, top: 8, child: _areaChip(shown.drill)),
              if (!transition)
                Positioned(
                  right: 16,
                  top: 8,
                  child: TextButton.icon(
                    key: const ValueKey('player-pain'),
                    style: TextButton.styleFrom(
                      backgroundColor: HipColors.background.withValues(
                        alpha: .6,
                      ),
                      shape: const StadiumBorder(
                        side: BorderSide(color: HipColors.line),
                      ),
                    ),
                    onPressed: () => _pain(afterStep: false),
                    icon: const Icon(
                      Icons.bolt_rounded,
                      color: HipColors.pain,
                      size: 16,
                    ),
                    label: const Text(
                      '疼',
                      style: TextStyle(color: HipColors.pain),
                    ),
                  ),
                ),
              if (transition) Positioned.fill(child: _transitionOverlay()),
            ],
          ),
        ),
        Text(
          shown.drill.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: HipColors.surface,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.volume_up_rounded,
                size: 16,
                color: HipColors.jade,
              ),
              const SizedBox(width: 6),
              Text(
                transition ? '准备下一个' : _cue,
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            HipCircleButton(
              key: const ValueKey('player-pause'),
              icon: _paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
              size: 64,
              tooltip: _paused ? '继续' : '暂停',
              onPressed: () => setState(() => _paused = !_paused),
            ),
            const SizedBox(width: 26),
            HipCountdownRing(
              progress: transition
                  ? 1 - _transitionLeft / widget.plan.transitionSeconds
                  : (_total - _left) / _total,
              label: '${transition ? _transitionLeft : _left}',
              caption: '秒',
              size: 140,
            ),
            const SizedBox(width: 26),
            HipCircleButton(
              key: const ValueKey('player-skip'),
              icon: Icons.skip_next_rounded,
              size: 64,
              tooltip: '跳过',
              onPressed: _skip,
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (!transition && _next != null) _nextCard(_next!),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _areaChip(HipDrill d) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: HipColors.background.withValues(alpha: .6),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: HipColors.line),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircleAvatar(radius: 4, backgroundColor: HipColors.glow),
        const SizedBox(width: 6),
        Text(_areaOf(d.directions.first), style: const TextStyle(fontSize: 13)),
      ],
    ),
  );

  static String _areaOf(HipDirection d) => switch (d) {
    HipDirection.flexion => '大腿后侧',
    HipDirection.extension => '髋屈肌',
    HipDirection.abduction => '大腿内侧',
    HipDirection.adduction => '髋外侧',
    HipDirection.internalRotation => '髋内旋',
    HipDirection.externalRotation => '臀部 · 髋外旋',
  };

  Widget _transitionOverlay() => ColoredBox(
    color: HipColors.background.withValues(alpha: .72),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '刚才「${_steps[_index].drill.name}」感觉怎么样？',
          style: const TextStyle(fontSize: 16, color: HipColors.muted),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (final (key, label, color) in [
              ('ok', '舒服', HipColors.jade),
              ('tight', '有点紧', HipColors.text),
              ('pain', '疼', HipColors.pain),
            ]) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: OutlinedButton(
                  key: ValueKey('feel-$key'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: color,
                    side: BorderSide(color: color.withValues(alpha: .5)),
                    minimumSize: const Size(92, 52),
                    shape: const StadiumBorder(),
                  ),
                  onPressed: () {
                    if (key == 'pain') {
                      _pain(afterStep: true);
                    } else {
                      setState(() => _startStep(_index + 1));
                    }
                  },
                  child: Text(label, style: const TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ],
        ),
      ],
    ),
  );

  Widget _nextCard(PlanStep next) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: HipPanel(
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
            child: HipDrillArt(drill: next.drill, showPendingLabel: false),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '下一个',
                  style: TextStyle(fontSize: 12, color: HipColors.muted),
                ),
                Text(
                  next.drill.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            mmss(next.seconds),
            style: const TextStyle(fontSize: 15, color: HipColors.muted),
          ),
          const SizedBox(width: 6),
        ],
      ),
    ),
  );

  Widget _finished() => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      children: [
        const Spacer(),
        const Icon(Icons.check_circle_rounded, size: 88, color: HipColors.jade),
        const SizedBox(height: 16),
        const Text(
          '今天练完了',
          style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          '连续 ${widget.store.streak} 天',
          style: const TextStyle(fontSize: 18, color: HipColors.muted),
        ),
        const Spacer(),
        HipPrimaryButton(
          key: const ValueKey('player-done'),
          label: '回首页',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    ),
  );

  Widget _stopped() => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      children: [
        const Spacer(),
        const Icon(
          Icons.pan_tool_alt_rounded,
          size: 80,
          color: HipColors.tight,
        ),
        const SizedBox(height: 16),
        const Text(
          '先停下来',
          style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        const Text(
          '麻、刺或往下窜的感觉不该出现在练习里。\n建议问问医生或专业人士。',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, height: 1.5, color: HipColors.muted),
        ),
        const Spacer(),
        HipPrimaryButton(
          key: const ValueKey('player-stop-home'),
          label: '回首页',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    ),
  );
}
