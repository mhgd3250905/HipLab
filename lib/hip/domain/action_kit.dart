import 'dart:math' as math;

/// Action kit v1 (docs/action-kit-spec-v1.md): one action's display, media
/// references, training rhythm and voice script, keyed by the Pose-Hub
/// action id. Built by tools/action_kits/build_action_kits.py into
/// `assets/action_kits/<id>.json`; routines reference a kit and only
/// override the dose ([KitDose]).
enum ActionKind {
  /// 计数·双相起落: count + "go" word, "back" word at the return.
  repUpdown('rep_updown'),

  /// 计数·正反循环: one count = one loop in both directions.
  repCycle('rep_cycle'),

  /// 计数·左右交替: each count is one side; the go word rotates.
  repAlternate('rep_alternate'),

  /// 计数·带停留: a rep with a timed hold at the top.
  repHold('rep_hold'),

  /// 呼吸配合: exhale / inhale phases.
  repBreath('rep_breath'),

  /// 保持计时.
  hold('hold');

  const ActionKind(this.id);
  final String id;
  bool get counted => this != hold;
  static ActionKind byId(String id) =>
      values.firstWhere((k) => k.id == id, orElse: () => hold);
}

/// One phase of a rep: go / hold / back / rest.
class KitPhase {
  const KitPhase(this.id, this.seconds, this.cues, {this.cueAt = 0});
  final String id;
  final double seconds;

  /// How far into the phase its word is said (a hold word waits a beat so
  /// the count before it has room).
  final double cueAt;

  /// Word clip(s) said when the phase starts; several rotate with the count
  /// (右/左, 开门/关门). Empty: silent phase.
  final List<String> cues;

  String? cueFor(int count) =>
      cues.isEmpty ? null : cues[(count - 1) % cues.length];

  factory KitPhase.fromJson(Map<String, dynamic> j) {
    final c = j['cue'];
    return KitPhase(
      j['id'] as String,
      (j['seconds'] as num).toDouble(),
      c == null
          ? const []
          : c is List
          ? [for (final x in c) x as String]
          : [c as String],
      cueAt: (j['cueAt'] as num? ?? 0).toDouble(),
    );
  }
}

/// The dose a routine step asks for (overrides of the kit defaults).
class KitDose {
  const KitDose({this.reps, this.holdSeconds, this.seconds});
  final int? reps;
  final int? holdSeconds;
  final int? seconds;

  factory KitDose.fromJson(Map<String, dynamic>? j) => j == null
      ? const KitDose()
      : KitDose(
          reps: j['reps'] as int?,
          holdSeconds: j['holdSeconds'] as int?,
          seconds: j['seconds'] as int?,
        );
}

/// When each rep of one set starts and each of its phases begins.
class RepPlan {
  const RepPlan({
    required this.lead,
    required this.reps,
    required this.sets,
    required this.phases,
  });

  /// Seconds before the first count of each set ("开始" / "再来一组").
  final double lead;
  final int reps;
  final int sets;
  final List<KitPhase> phases;

  double get cycle => phases.fold(0.0, (s, p) => s + p.seconds);
  double get setSeconds => lead + reps * cycle;
  double get seconds => sets * setSeconds;

  /// Start of rep [k] (1-based) of set [set] (0-based).
  double repStart(int set, int k) => set * setSeconds + lead + (k - 1) * cycle;
}

class ActionKit {
  const ActionKit({
    required this.id,
    required this.kind,
    required this.sided,
    required this.lead,
    required this.phases,
    required this.defaultReps,
    required this.defaultSeconds,
    required this.defaultHold,
    required this.entrySeconds,
    required this.voice,
    this.raw = const {},
  });

  final String id;
  final ActionKind kind;
  final bool sided;
  final double lead;
  final List<KitPhase> phases;
  final int? defaultReps;
  final int? defaultSeconds;
  final int? defaultHold;

  /// Hold kits: seconds the demo takes to get into the position.
  final double entrySeconds;
  final KitVoice voice;
  final Map<String, dynamic> raw;

  factory ActionKit.fromJson(Map<String, dynamic> j) {
    if (j['schema'] != 'action-kit@1') {
      throw FormatException('action kit schema ${j['schema']}');
    }
    final t = Map<String, dynamic>.from(j['training'] as Map);
    final d = Map<String, dynamic>.from(t['defaults'] as Map);
    final cyc = t['cycle'] as Map?;
    return ActionKit(
      id: j['id'] as String,
      kind: ActionKind.byId(t['kind'] as String),
      sided: t['sided'] == true,
      lead: (t['leadSeconds'] as num? ?? 1).toDouble(),
      phases: [
        for (final p in (cyc?['phases'] as List?) ?? const [])
          KitPhase.fromJson(Map<String, dynamic>.from(p as Map)),
      ],
      defaultReps: d['reps'] as int?,
      defaultSeconds: d['seconds'] as int?,
      defaultHold: d['holdSeconds'] as int?,
      entrySeconds: ((t['hold'] as Map?)?['entrySeconds'] as num? ?? 2)
          .toDouble(),
      voice: KitVoice.fromJson(Map<String, dynamic>.from(j['voice'] as Map)),
      raw: j,
    );
  }

  /// Phases with the dose's hold length applied.
  List<KitPhase> phasesFor(KitDose dose) {
    final hold = dose.holdSeconds ?? defaultHold;
    return [
      for (final p in phases)
        p.id == 'hold' && hold != null
            ? KitPhase(p.id, hold.toDouble(), p.cues, cueAt: p.cueAt)
            : p,
    ];
  }

  double cycleFor(KitDose dose) =>
      phasesFor(dose).fold(0.0, (s, p) => s + p.seconds);

  /// Whole seconds of one side (or of the unsided set). Holds: the dose
  /// seconds (or [budget]). Counted kits keep the routine's [budget] when
  /// every rep fits in it at the kit's pace (the reps are then slowed down,
  /// see [stretch]) and grow to the lead plus every rep in full when they
  /// do not. Same formula as build_action_kits.side_seconds().
  int sideSeconds(KitDose dose, int budget) {
    if (!kind.counted) return dose.seconds ?? budget;
    final reps = dose.reps ?? defaultReps ?? 1;
    final need = (lead + reps * cycleFor(dose) - 1e-9).ceil();
    return math.max(budget, need);
  }

  /// Share of a slowed rep's extra time spent at the top (the rest goes to
  /// the pause at the bottom).
  static const stretchTop = .6;

  /// [ph] slowed to a cycle of [target] seconds: the movements keep the
  /// demo's speed, the pauses at the top / bottom take the extra time (a
  /// timed hold keeps its length, the pause after it grows); a loop
  /// (rep_cycle) slows down evenly. Mirrors stretch_phases() in Python.
  List<KitPhase> stretch(List<KitPhase> ph, double target) {
    final base = ph.fold(0.0, (s, p) => s + p.seconds);
    final extra = target - base;
    if (extra <= 1e-9) return ph;
    if (kind == ActionKind.repCycle) {
      final f = target / base;
      return [
        for (final p in ph)
          KitPhase(p.id, p.seconds * f, p.cues, cueAt: p.cueAt),
      ];
    }
    final hasRest = ph.any((p) => p.id == 'rest');
    // A timed hold (停 N 秒) is the dose itself: never longer than asked.
    final top = kind == ActionKind.repHold ? 0.0 : stretchTop;
    return [
      for (final p in ph)
        KitPhase(
          p.id,
          p.seconds +
              (p.id == 'hold'
                  ? extra * (hasRest ? top : 1)
                  : p.id == 'rest' && hasRest
                  ? extra * (1 - top)
                  : 0),
          p.cues,
          cueAt: p.cueAt,
        ),
    ];
  }

  /// The rep plan for a work phase of [seconds] with [sets] sets (2 on the
  /// tight side). Each set: the lead ("开始" / "再来一组"), then every rep
  /// in full – the last rep ends exactly when the phase ends. When the
  /// phase is longer than the reps need, the reps slow down to fill it;
  /// when it is shorter (pain ladder halves the time) reps are dropped.
  RepPlan repPlan(KitDose dose, double seconds, {int sets = 1}) {
    final ph = phasesFor(dose);
    final cycle = ph.fold(0.0, (s, p) => s + p.seconds);
    final per = seconds / sets;
    var reps = dose.reps ?? defaultReps ?? 1;
    if (per + 1e-9 >= lead + reps * cycle) {
      return RepPlan(
        lead: lead,
        reps: reps,
        sets: sets,
        phases: stretch(ph, (per - lead) / reps),
      );
    }
    // A shortened phase must never start a rep it cannot finish. The
    // player skips the action when pain reduction leaves no whole rep.
    reps = math.max(0, math.min(reps, ((per - lead + 1e-9) / cycle).floor()));
    return RepPlan(
      lead: math.max(0.0, per - reps * cycle),
      reps: reps,
      sets: sets,
      phases: ph,
    );
  }
}

/// The kit's voice script: which clips mark which moment.
class KitVoice {
  const KitVoice({
    required this.prepare,
    required this.go,
    required this.count,
    required this.lastRep,
    required this.nextSet,
    required this.end,
    required this.coach,
    this.firstSide,
    this.half,
    this.last10,
    this.countdown = 5,
  });
  final List<String> prepare;
  final String go;

  /// Clip pattern of a count, e.g. `n.{k}`.
  final String count;
  final String lastRep;
  final String nextSet;

  /// Said when the action ends (p.nice / p.release).
  final String end;
  final List<String> coach;
  final String? firstSide;
  final String? half;
  final String? last10;
  final int countdown;

  String countClip(int k) => count.replaceAll('{k}', '$k');

  factory KitVoice.fromJson(Map<String, dynamic> j) {
    final mid = j['midHold'] as Map?;
    return KitVoice(
      prepare: [for (final x in j['prepare'] as List) x as String],
      go: j['go'] as String,
      count: j['count'] as String,
      lastRep: j['lastRep'] as String,
      nextSet: j['nextSet'] as String,
      end: j['end'] as String,
      coach: [for (final x in (j['coach'] as List?) ?? const []) x as String],
      firstSide: j['firstSide'] as String?,
      half: mid?['half'] as String?,
      last10: mid?['last10'] as String?,
      countdown: (mid?['countdown'] as int?) ?? 5,
    );
  }
}
