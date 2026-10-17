import '../domain/hip_session.dart';
import 'session_script.dart';

/// Something the session wants said now.
class FiredCue {
  const FiredCue(this.time, this.cue, this.phase);

  /// Active session time (seconds, pauses excluded) when it fired.
  final double time;
  final VoiceCue cue;
  final SessionPhase phase;
  @override
  String toString() => '${time.toStringAsFixed(2)} ${cue.clips.join('+')}';
}

/// The training clock (#12/#13): a list of fixed-length phases driven by an
/// absolute active time, so dropped frames, a throttled timer or a few
/// seconds in the background never drift the count — the next update simply
/// lands in the right phase. Cues that are already stale when the clock gets
/// there (e.g. after a long background stretch) are dropped instead of being
/// read out late.
class SessionEngine {
  SessionEngine({required this.script, required List<PlanStep> steps})
    : steps = [...steps] {
    _phases = script.phases(this.steps);
    _enter(0, 0);
  }

  final SessionScript script;
  final List<PlanStep> steps;
  late List<SessionPhase> _phases;
  int _index = 0;
  double _phaseStart = 0;
  List<VoiceCue> _cues = const [];
  final Set<int> _fired = {};
  bool _enteredBySkip = false;

  /// Drills finished (fully or by moving past them).
  int completed = 0;

  SessionPhase get phase => _phases[_index];
  List<SessionPhase> get phases => List.unmodifiable(_phases);
  bool get done => phase.kind == PhaseKind.done;
  PlanStep get step => steps[phase.step.clamp(0, steps.length - 1)];

  /// The step on screen: the upcoming drill during prep/rest.
  int get stepIndex => phase.step.clamp(0, steps.length - 1);
  double get phaseStart => _phaseStart;

  double elapsedIn(double t) => (t - _phaseStart).clamp(0, phase.seconds);
  double remainingIn(double t) => phase.seconds - elapsedIn(t);

  /// Whole seconds left as shown on the ring (ceil, so "1" shows until 0).
  int secondsLeft(double t) => remainingIn(t).ceil();

  static double _tolerance(VoiceCue c) => switch (c.priority) {
    CuePriority.count => .6,
    CuePriority.call => 1.5,
    CuePriority.info => 2.5,
    CuePriority.coach => 2.0,
  };

  void _enter(int index, double at, {bool bySkip = false}) {
    final leaving = _phases[_index];
    if (index != _index &&
        leaving.isWork &&
        leaving.lastSegment &&
        _phases[index].step != leaving.step) {
      completed++;
    }
    _index = index;
    _phaseStart = at;
    _enteredBySkip = bySkip;
    _cues = script.cues(phase, steps, bySkip: bySkip);
    _fired.clear();
  }

  /// Advance to active time [t]; returns the cues due now.
  List<FiredCue> update(double t) {
    final out = <FiredCue>[];
    while (!done && t - _phaseStart >= phase.seconds) {
      _enter(_index + 1, _phaseStart + phase.seconds);
    }
    final local = t - _phaseStart;
    for (var i = 0; i < _cues.length; i++) {
      final c = _cues[i];
      if (_fired.contains(i) || c.at > local + 1e-9) continue;
      _fired.add(i);
      if (local - c.at <= _tolerance(c)) {
        out.add(FiredCue(_phaseStart + c.at, c, phase));
      }
    }
    return out;
  }

  /// 跳过: from a drill (either side) or the side switch → the rest before
  /// the next drill (or the end); from prep/rest → straight into the drill.
  void skip(double t) {
    if (done) return;
    final p = phase;
    int target;
    if (p.kind == PhaseKind.prep || p.kind == PhaseKind.rest) {
      target = _index + 1;
    } else {
      target = _index + 1;
      while (target < _phases.length - 1 && _phases[target].step == p.step) {
        target++;
      }
      completed++;
    }
    _index = target;
    _phaseStart = t;
    _enteredBySkip = true;
    _cues = script.cues(phase, steps, bySkip: true);
    _fired.clear();
  }

  /// Replace the steps from [from] on (pain ladder: substitute / half range /
  /// skip a direction) and restart at that step's first side, or at the rest
  /// before it when [withRest].
  void replaceFrom(
    int from,
    List<PlanStep> newSteps,
    double t, {
    bool withRest = false,
  }) {
    steps
      ..removeRange(from, steps.length)
      ..addAll(newSteps);
    final head = _phases.sublist(0, _index).where((p) => p.step < from);
    _phases = [
      ...head,
      ...script.phases(
        steps,
        from: from,
        lead: withRest ? PhaseKind.rest : null,
      ),
    ];
    _index = head.length;
    _phaseStart = t;
    _cues = script.cues(phase, steps, bySkip: true);
    _fired.clear();
  }

  /// End now (麻/刺 stop or closing the player).
  void finish(double t) {
    _index = _phases.length - 1;
    _phaseStart = t;
    _cues = const [];
    _fired.clear();
  }

  bool get enteredBySkip => _enteredBySkip;
}
