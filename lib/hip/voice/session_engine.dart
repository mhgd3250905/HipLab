import 'package:ugk_trainer/engine.dart' as trainer;
import '../domain/hip_assessment.dart';
import '../domain/hip_session.dart';
import 'session_script.dart';

/// Compatibility view used by the retained timeline and dose regressions.
/// The production player and this bridge use the package clock and runner.
class FiredCue {
  const FiredCue(this.time, this.cue, this.phase);
  final double time;
  final VoiceCue cue;
  final SessionPhase phase;
}

class SessionEngine {
  SessionEngine({required this.script, required List<PlanStep> steps})
    : steps = [...steps] {
    _load();
    _engine = trainer.SessionEngine(_mapped);
    _runner = trainer.SessionRunner(_engine, _ScriptBridge(this));
  }
  final SessionScript script;
  final List<PlanStep> steps;
  late trainer.SessionEngine _engine;
  late trainer.SessionRunner _runner;
  late List<SessionPhase> _phases;
  late List<trainer.SessionPhase> _mapped;
  final Map<trainer.SessionPhase, SessionPhase> _views = {};
  void _load() {
    _phases = script.phases(steps);
    _mapped = [
      for (final p in _phases)
        trainer.SessionPhase(
          kind: trainer.PhaseKind.values.byName(p.kind.name),
          seconds: p.seconds,
          itemIndex: p.step,
          exerciseId: p.step < steps.length ? steps[p.step].drill.id : null,
          side: p.side == null
              ? null
              : p.side == HipSide.right
              ? trainer.Side.right
              : trainer.Side.left,
        ),
    ];
    for (var i = 0; i < _mapped.length; i++) {
      _views[_mapped[i]] = _phases[i];
    }
  }

  SessionPhase get phase => _views[_engine.phase]!;
  List<SessionPhase> get phases => [for (final p in _engine.phases) _views[p]!];
  bool get done => _engine.done;
  PlanStep get step => steps[stepIndex];
  int get stepIndex => phase.step.clamp(0, steps.length - 1);
  double get phaseStart => _engine.phaseStart;
  int get completed => _engine.completedExercises;
  double elapsedIn(double t) => _engine.elapsedIn(t);
  double remainingIn(double t) => _engine.remainingIn(t);
  int secondsLeft(double t) => _engine.secondsLeft(t);
  List<FiredCue> update(double t) => [
    for (final f in _runner.update(t)) FiredCue(f.time, f.cue, phase),
  ];
  void skip(double t) => _runner.skip(t);
  void finish(double t) => _runner.finish(t);
  void replaceFrom(
    int from,
    List<PlanStep> newSteps,
    double t, {
    bool withRest = false,
  }) {
    steps
      ..removeRange(from, steps.length)
      ..addAll(newSteps);
    _load();
    if (withRest) {
      final first = _mapped.indexWhere((p) => p.itemIndex == from && p.isWork);
      if (first >= 0) {
        final p = trainer.SessionPhase(
          kind: trainer.PhaseKind.work,
          seconds: script.restSeconds.toDouble(),
          itemIndex: from,
        );
        _views[p] = SessionPhase(
          PhaseKind.rest,
          from,
          script.restSeconds.toDouble(),
        );
        _mapped.insert(first, p);
      }
    }
    _runner.restartWith(_mapped, t);
  }

  bool get enteredBySkip => _engine.enteredBySkip;
}

class _ScriptBridge extends trainer.SessionScript {
  _ScriptBridge(this.host)
    : super(source: host.script.lib, lang: host.script.lang);
  final SessionEngine host;
  @override
  List<VoiceCue> cues(
    trainer.SessionPhase p, {
    required double planSeconds,
    bool bySkip = false,
  }) => host.script.cues(host._views[p]!, host.steps, bySkip: bySkip);
}
