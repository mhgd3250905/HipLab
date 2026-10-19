import 'dart:async';

import 'package:clock/clock.dart';
import '../../core/platform/screen_awake.dart';
import 'package:flutter/material.dart';

import '../control/hip_store.dart';
import '../domain/hip_assessment.dart';
import '../domain/hip_models.dart';
import '../domain/hip_pain.dart';
import '../domain/hip_session.dart';
import '../voice/hip_voice.dart';
import '../voice/session_engine.dart';
import '../voice/session_script.dart';
import '../voice/voice_queue.dart';
import 'hip_icons.dart';
import 'hip_theme.dart';
import 'hip_widgets.dart';

/// Active (pause-excluded) seconds since the session started, from the wall
/// clock – never from counting timer ticks (#13: robust to dropped frames
/// and throttled timers).
class _ActiveClock {
  final DateTime _start = clock.now();
  Duration _pausedTotal = Duration.zero;
  DateTime? _pausedAt;

  bool get paused => _pausedAt != null;

  double get t {
    final now = _pausedAt ?? clock.now();
    return (now.difference(_start) - _pausedTotal).inMicroseconds / 1e6;
  }

  void pause() => _pausedAt ??= clock.now();

  void resume() {
    final at = _pausedAt;
    if (at == null) return;
    _pausedTotal += clock.now().difference(at);
    _pausedAt = null;
  }
}

/// Full-screen follow-along player: the drill, a countdown ring, side
/// switch, pause / skip, one subtitle line and full voice coaching.
/// Pain walks the ladder.
class HipPlayerPage extends StatefulWidget {
  const HipPlayerPage({super.key, required this.store, required this.plan});
  final HipStore store;
  final TrainingPlan plan;
  @override
  State<HipPlayerPage> createState() => _HipPlayerPageState();
}

class _HipPlayerPageState extends State<HipPlayerPage> {
  late final SessionPainLadder _ladder = SessionPainLadder(
    widget.store.content,
  );
  final _clock = _ActiveClock();
  late HipVoice _voice;
  late VoiceQueue _queue;
  late SessionEngine _engine;
  bool _ready = false;
  bool _stopped = false;
  bool _finished = false;
  String? _ladderCue;
  String? _subtitle;
  Timer? _ticker;
  StreamSubscription<AudioInterruption>? _interruptions;
  int _shownSecond = -1;
  SessionPhase? _shownPhase;

  /// Phase progress for the ring, updated every tick; only the ring
  /// repaints for it (the page rebuilds once a second).
  final _ringProgress = ValueNotifier<double>(0);

  /// 舒服 / 有点紧 / 疼 per finished step (index), answered during the rest
  /// after it. Only recorded and confirmed – it never moves the session on.
  final Map<int, String> _felt = {};
  double? _feltAt;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ready) return;
    _ready = true;
    _voice = HipVoice.of(context);
    _queue = _voice.queue();
    _engine = SessionEngine(
      script: _voice.script(
        routineIds: [for (final r in widget.plan.routines) r.id],
        restSeconds: widget.plan.transitionSeconds,
        kits: widget.store.content.kits,
      ),
      steps: widget.plan.steps,
    );
    if (_voice.settings.voice || _voice.settings.chimes) {
      unawaited(_voice.output.begin());
    }
    if (_voice.output case final InterruptibleVoiceOutput out) {
      _interruptions = out.interruptions.listen(_onInterruption);
    }
    ScreenAwake.acquire();
    _ticker = Timer.periodic(const Duration(milliseconds: 33), (_) => _tick());
    _tick();
  }

  @override
  void dispose() {
    if (_ready) ScreenAwake.release();
    _ticker?.cancel();
    unawaited(_interruptions?.cancel());
    _queue.cancelAll(_clock.t);
    unawaited(_voice.output.end());
    _ringProgress.dispose();
    super.dispose();
  }

  List<PlanStep> get _steps => _engine.steps;
  SessionPhase get _phase => _engine.phase;
  PlanStep get _step => _steps[_engine.stepIndex];
  PlanStep? get _next {
    final i = _phase.isWork || _phase.kind == PhaseKind.switchSide
        ? _phase.step + 1
        : _phase.step;
    return i < _steps.length && i > _phase.step ? _steps[i] : null;
  }

  bool get _paused => _clock.paused;

  void _tick() {
    if (!mounted || _paused || _stopped) return;
    final t = _clock.t;
    for (final f in _engine.update(t)) {
      _queue.submit(f.cue, t);
      final sub = f.cue.subtitle;
      if (sub != null) _subtitle = sub;
    }
    _queue.tick(t);
    final phaseSeconds = _engine.phase.seconds;
    _ringProgress.value = phaseSeconds == 0
        ? 0
        : (_engine.elapsedIn(t) / phaseSeconds).clamp(0.0, 1.0);
    if (!identical(_engine.phase, _shownPhase)) {
      if (_engine.phase.step != _shownPhase?.step) {
        // A new drill: drop the previous drill's ladder note / tip line.
        _ladderCue = null;
        _subtitle = null;
      }
      _precacheNext();
    }
    if (_engine.done && !_stopped) _complete();
    final second = _engine.secondsLeft(t);
    if (second != _shownSecond || !identical(_engine.phase, _shownPhase)) {
      setState(() {
        _shownSecond = second;
        _shownPhase = _engine.phase;
      });
    }
  }

  void _precacheNext() {
    final i = _phase.step + 1;
    if (i >= _steps.length) return;
    hipPrecache(context, [_steps[i].drill.poster]);
  }

  void _complete() {
    if (_finished) return;
    _finished = true;
    widget.store.completeSession(_ladder);
  }

  /// A call, Siri, an alarm or unplugged headphones (iOS / Android audio
  /// session): pause silently so nothing is missed; the user resumes with
  /// 继续 once they are back. The interruption ending does not auto-resume.
  void _onInterruption(AudioInterruption e) {
    if (!mounted || _stopped || _engine.done) return;
    if (e == AudioInterruption.ended || _paused) return;
    _queue.cancelAll(_clock.t);
    _clock.pause();
    setState(() {});
  }

  void _togglePause() {
    final t = _clock.t;
    if (_paused) {
      if (_voice.output case final InterruptibleVoiceOutput out) {
        // Take the audio session back in case an interruption ended
        // without telling us (iOS does not always send the end event).
        unawaited(out.reactivate());
      }
      _clock.resume();
      _queue.submit(
        const VoiceCue(0, ['p.resume'], CuePriority.call),
        _clock.t,
      );
    } else {
      _queue.cancelAll(t);
      _queue.submit(const VoiceCue(0, ['p.paused'], CuePriority.call), t);
      _clock.pause();
    }
    setState(() {});
  }

  void _skip() {
    final t = _clock.t;
    _queue.cancelAll(t);
    _engine.skip(t);
    _subtitle = null;
    _tick();
    setState(() {});
  }

  String get _cue {
    if (_ladderCue != null) return _ladderCue!;
    if (_subtitle != null) return _subtitle!;
    final s = _step;
    if (s.extraSide != null) {
      return '${s.extraSide == HipSide.right ? '右' : '左'}边多做一组';
    }
    if (s.tip.isNotEmpty) return s.tip;
    final m = s.drill.methods.first;
    return switch (m) {
      HipMethod.relax => '慢慢呼吸，放松',
      HipMethod.flexibility => '呼气，再沉一点',
      HipMethod.control => '慢一点，控制住',
      HipMethod.strength => '稳住，别憋气',
    };
  }

  Future<void> _pain({required bool afterStep}) async {
    final wasPaused = _paused;
    _queue.cancelAll(_clock.t);
    _clock.pause();
    setState(() {});
    final kind = await showModalBottomSheet<PainKind>(
      context: context,
      sheetAnimationStyle: HipMotion.sheet,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
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
                    (PainKind.pinch, HipGlyph.pinch, '关节夹着疼'),
                    (PainKind.nerve, HipGlyph.bolt, '麻、刺、往下窜'),
                  ]) ...[
                    if (k == PainKind.nerve) const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        key: ValueKey('pain-${k.name}'),
                        onTap: () => Navigator.of(context).pop(k),
                        child: HipPanel(
                          child: Column(
                            children: [
                              HipIcon(icon, size: 40, color: HipColors.pain),
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
      if (!wasPaused) _clock.resume();
      setState(() {});
      return;
    }
    final current = _phase.step.clamp(0, _steps.length - 1);
    final targetIndex = afterStep ? current - 1 : current;
    final target = _steps[targetIndex.clamp(0, _steps.length - 1)];
    final action = _ladder.report(
      target.drill.id,
      kind,
      alternative: target.alternative,
    );
    _clock.resume();
    final t = _clock.t;
    setState(() {
      _ladderCue = action.cue;
      _apply(action, target, afterStep: afterStep, t: t);
    });
    if (action.type == PainActionType.endSession) {
      await widget.store.recordNerve(action.direction!);
    }
  }

  void _apply(
    PainAction action,
    PlanStep target, {
    required bool afterStep,
    required double t,
  }) {
    final i = _phase.step.clamp(0, _steps.length);
    switch (action.type) {
      case PainActionType.endSession:
        _stopped = true;
        _queue.cancelAll(t);
        _queue.submit(const VoiceCue(0, ['p.stop'], CuePriority.call), t);
        _engine.finish(t);
      case PainActionType.reduceAmplitude:
        // Half the range and half the time; after a finished drill this only
        // shortens the drill's later appearances.
        if (!afterStep) {
          final rest = _steps.sublist(i + 1);
          _engine.replaceFrom(i, [
            _steps[i].copyWith(seconds: (target.seconds / 2).ceil()),
            ...rest,
          ], t);
          _queue.submit(
            const VoiceCue(0, ['cue.half_range'], CuePriority.info),
            t,
          );
        }
      case PainActionType.substitute:
        final alt = widget.store.content.drill(action.substituteId!);
        final updated = [
          for (final s in _steps.sublist(i))
            s.drill.id == target.drill.id
                ? s.copyWith(drill: alt, replaced: s.drill.id)
                : s,
        ];
        _engine.replaceFrom(i, updated, t, withRest: afterStep);
      case PainActionType.skipDirection:
        final dir = action.direction!;
        final from = afterStep ? i : i + 1;
        final kept = [
          for (final s in _steps.sublist(from.clamp(0, _steps.length)))
            if (!(s.drill.directions.first == dir && !s.drill.isRelax)) s,
        ];
        if (!afterStep) _engine.completed++;
        _engine.replaceFrom(from, kept, t, withRest: kept.isNotEmpty);
        if (_engine.done) _complete();
    }
  }

  Future<void> _close() async {
    _ticker?.cancel();
    _queue.cancelAll(_clock.t);
    if (!_finished && !_stopped) {
      if (_engine.completed > 0) {
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
        child: HipFadeSwitcher(
          child: _stopped
              ? KeyedSubtree(
                  key: const ValueKey('stopped'),
                  child: _stoppedView(),
                )
              : _engine.done
              ? KeyedSubtree(
                  key: const ValueKey('done'),
                  child: _finishedView(),
                )
              : KeyedSubtree(key: const ValueKey('play'), child: _playing()),
        ),
      ),
    ),
  );

  Widget _playing() {
    final phase = _phase;
    final t = _clock.t;
    final work = phase.isWork;
    final shown = _step;
    final side = work || phase.kind == PhaseKind.switchSide ? phase.side : null;
    final left = _engine.secondsLeft(t);
    return Column(
      children: [
        HipTopBar(
          tooltip: '结束',
          onClose: _close,
          center: Row(
            children: [
              for (var i = 0; i < _steps.length; i++)
                Expanded(
                  child: AnimatedContainer(
                    duration: HipMotion.medium,
                    height: 4,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      color: i < phase.step
                          ? HipColors.text.withValues(alpha: .7)
                          : i == phase.step && work
                          ? HipColors.jade
                          : i == phase.step
                          ? HipColors.jade.withValues(alpha: .45)
                          : HipColors.surfaceHigh,
                    ),
                  ),
                ),
            ],
          ),
          trailing: Text(
            '${(phase.step + 1).clamp(1, _steps.length)}/${_steps.length}',
            style: TextStyle(color: HipColors.muted, fontSize: 15),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: HipMediaFrame(
              radius: 28,
              overlays: [
                Positioned(left: 14, top: 14, child: _areaChip(shown.drill)),
                if (work)
                  Positioned(
                    right: 14,
                    top: 14,
                    child: _mediaButton(
                      key: const ValueKey('player-pain'),
                      icon: HipGlyph.bolt,
                      label: '疼',
                      color: HipColors.pain,
                      onTap: () => _pain(afterStep: false),
                    ),
                  ),
                // Side indicator rides on the media, so unsided drills keep
                // no empty row (#9) and nothing shifts between drills.
                if (side != null && work)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 16,
                    child: Center(child: _sideIndicator(side, phase)),
                  ),
                // Prep / rest / side switch: the demo plays in full, undimmed;
                // only a small corner tag says what it is. Name, dose and
                // feedback live below the media.
                if (!work)
                  Positioned(right: 14, top: 14, child: _phaseTag(phase)),
              ],
              child: HipFadeSwitcher(
                duration: HipMotion.slow,
                offset: 0,
                expand: true,
                child: KeyedSubtree(
                  key: ValueKey('art-${shown.drill.id}'),
                  child: HipDrillArt(
                    drill: shown.drill,
                    // The next drill's demo already loops during prep /
                    // rest so the user can watch how it is done.
                    play: !_paused,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: AnimatedSwitcher(
            duration: HipMotion.medium,
            child: Text(
              shown.drill.name,
              key: ValueKey(shown.drill.id),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: HipColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: HipColors.line),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              HipIcon(
                _voice.settings.voice ? HipGlyph.volume : HipGlyph.subtitles,
                size: 16,
                color: HipColors.jade,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: AnimatedSwitcher(
                  duration: HipMotion.fast,
                  child: Text(
                    _subtitleText(phase),
                    key: ValueKey(_subtitleText(phase)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
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
              icon: _paused ? HipGlyph.play : HipGlyph.pause,
              size: 64,
              tooltip: _paused ? '继续' : '暂停',
              onPressed: _togglePause,
            ),
            const SizedBox(width: 26),
            HipCountdownRing(
              key: const ValueKey('player-ring'),
              progressListenable: _ringProgress,
              label: '$left',
              caption: _paused ? '已暂停' : '秒',
              size: 140,
              // Lead-in / rest count in a quieter tone of the same accent.
              color: work
                  ? HipColors.jade
                  : HipColors.jade.withValues(alpha: .5),
            ),
            const SizedBox(width: 26),
            HipCircleButton(
              key: const ValueKey('player-skip'),
              icon: HipGlyph.skipNext,
              size: 64,
              tooltip: '跳过',
              onPressed: _skip,
            ),
          ],
        ),
        const SizedBox(height: 14),
        // Fixed height whether or not there is a next drill: no jump. During
        // the rest it holds the light feedback on the drill just done.
        SizedBox(
          // 74 at normal text; a bit taller with large text so the next card
          // (two lines) fits – it overflowed by 8 px at ×1.5 before.
          height:
              74 +
              18 * (MediaQuery.textScalerOf(context).scale(1) - 1).clamp(0, 1),
          child: Stack(
            fit: StackFit.expand,
            children: [
              AnimatedOpacity(
                duration: HipMotion.medium,
                opacity: work && _next != null ? 1 : 0,
                child: _next == null ? const SizedBox() : _nextCard(_next!),
              ),
              if (_asksFeedback(phase))
                KeyedSubtree(
                  key: ValueKey('feel-row-${phase.step}'),
                  // Large text scales the row down instead of overflowing
                  // the fixed slot.
                  child: LayoutBuilder(
                    builder: (context, box) => FittedBox(
                      fit: BoxFit.scaleDown,
                      child: SizedBox(
                        width: box.maxWidth,
                        child: _feedbackRow(phase.step - 1, t),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  String _subtitleText(SessionPhase phase) => switch (phase.kind) {
    PhaseKind.prep => '准备开始 · ${_step.dose}',
    PhaseKind.rest =>
      _ladderCue ??
          '${phase.step == _steps.length - 1 ? '最后一个' : '下一个'} · ${_step.dose}',
    PhaseKind.switchSide => phase.side == HipSide.left ? '换左边' : '换右边',
    _ => _cue,
  };

  Widget _sideIndicator(HipSide side, SessionPhase phase) => Container(
    key: const ValueKey('side-indicator'),
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: .5),
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: Colors.white.withValues(alpha: .1)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Right first, then left (成套训练 编排规则 2).
        for (final s in [HipSide.right, HipSide.left])
          AnimatedContainer(
            duration: HipMotion.medium,
            width: 56,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: s == side ? HipColors.jade : null,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (s == HipSide.right && side == HipSide.left)
                  HipIcon(
                    HipGlyph.check,
                    size: 14,
                    strokeWidth: 2.4,
                    color: HipColors.jade,
                  ),
                Text(
                  s == HipSide.left ? '左' : '右',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: s == side ? HipColors.onJade : Colors.white70,
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );

  Widget _mediaButton({
    required Key key,
    required HipGlyph icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) => Material(
    color: Colors.black.withValues(alpha: .45),
    shape: StadiumBorder(
      side: BorderSide(color: Colors.white.withValues(alpha: .12)),
    ),
    child: InkWell(
      key: key,
      customBorder: const StadiumBorder(),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            HipIcon(icon, color: color, size: 16),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(color: color, fontSize: 14)),
          ],
        ),
      ),
    ),
  );

  Widget _areaChip(HipDrill d) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: .45),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.white.withValues(alpha: .12)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(radius: 4, backgroundColor: HipPalette.dark.glow),
        const SizedBox(width: 6),
        Text(
          _areaLabel(d),
          style: const TextStyle(fontSize: 13, color: Colors.white),
        ),
      ],
    ),
  );

  /// Area label on the media. Drills that work the hip in many directions
  /// (e.g. 四足髋关节画圈, 6 directions) are labelled as the joint, not by
  /// their first direction (#8 label part).
  static String _areaLabel(HipDrill d) =>
      d.directions.length >= 3 ? '髋关节周围' : _areaOf(d.directions.first);

  static String _areaOf(HipDirection d) => switch (d) {
    HipDirection.flexion => '大腿后侧',
    HipDirection.extension => '髋屈肌',
    HipDirection.abduction => '大腿内侧',
    HipDirection.adduction => '髋外侧',
    HipDirection.internalRotation => '髋内旋',
    HipDirection.externalRotation => '臀部 · 髋外旋',
  };

  /// Small tag in the media corner during prep / rest / side switch; the
  /// figure stays fully visible.
  Widget _phaseTag(SessionPhase phase) => Container(
    key: const ValueKey('phase-tag'),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: .45),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.white.withValues(alpha: .12)),
    ),
    child: Text(
      switch (phase.kind) {
        PhaseKind.prep => '准备',
        PhaseKind.rest => phase.step == _steps.length - 1 ? '最后一个' : '下一个',
        PhaseKind.switchSide => phase.side == HipSide.left ? '换左边' : '换右边',
        _ => '',
      },
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: HipPalette.dark.jade,
      ),
    ),
  );

  bool _asksFeedback(SessionPhase phase) =>
      phase.kind == PhaseKind.rest && phase.step > 0;

  /// 刚才感觉？ 舒服 / 有点紧 / 疼 – optional, under the media. A tap records
  /// the answer and confirms it (selected chip + 已记录); the rest countdown
  /// keeps running. 疼 opens the pain ladder as before. Starting early is
  /// the 跳过 button's job.
  Widget _feedbackRow(int doneStep, double t) {
    final picked = _felt[doneStep];
    final justSaved = _feltAt != null && t - _feltAt! < 2.5;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            picked != null && justSaved
                ? '已记录'
                : '刚才「${_steps[doneStep].drill.name}」感觉怎么样？',
            key: const ValueKey('feel-prompt'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              color: picked != null && justSaved
                  ? HipColors.jade
                  : HipColors.muted,
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final (key, label, color) in [
                  ('ok', '舒服', HipColors.jade),
                  ('tight', '有点紧', HipColors.text),
                  ('pain', '疼', HipColors.pain),
                ]) ...[
                  if (key != 'ok') const SizedBox(width: 8),
                  // #19 R5: colored outlined capsule (no tactile material).
                  Builder(
                    builder: (context) {
                      final c = picked == null || picked == key
                          ? color
                          : HipColors.muted;
                      return OutlinedButton(
                        key: ValueKey('feel-$key'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: c,
                          side: BorderSide(color: c.withValues(alpha: .55)),
                          minimumSize: const Size(76, 36),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          shape: const StadiumBorder(),
                        ),
                        onPressed: () => _feel(doneStep, key),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (picked == key) ...[
                              HipIcon(HipGlyph.check, size: 16, color: c),
                              const SizedBox(width: 4),
                            ],
                            Text(label, style: const TextStyle(fontSize: 14)),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _feel(int doneStep, String key) {
    setState(() {
      _felt[doneStep] = key;
      _feltAt = _clock.t;
    });
    if (key == 'pain') _pain(afterStep: true);
  }

  Widget _nextCard(PlanStep next) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: HipPanel(
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          // Concentric with the card: 22 − 10 padding.
          HipThumb(
            size: 52,
            radius: 12,
            child: HipDrillArt(drill: next.drill, showPendingLabel: false),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
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
            style: TextStyle(fontSize: 15, color: HipColors.muted),
          ),
          const SizedBox(width: 6),
        ],
      ),
    ),
  );

  Widget _finishedView() => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      children: [
        const Spacer(),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: .6, end: 1),
          duration: HipMotion.slow,
          curve: Curves.easeOutBack,
          builder: (_, v, child) => Transform.scale(scale: v, child: child),
          child: HipIcon(
            HipGlyph.checkCircle,
            filled: true,
            size: 88,
            color: HipColors.jade,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          '今天练完了',
          style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          '连续 ${widget.store.streak} 天',
          style: TextStyle(fontSize: 18, color: HipColors.muted),
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

  Widget _stoppedView() => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      children: [
        const Spacer(),
        HipIcon(HipGlyph.stop, size: 80, color: HipColors.tight),
        const SizedBox(height: 16),
        const Text(
          '先停下来',
          style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        Text(
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
