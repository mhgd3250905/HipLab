import 'dart:math' as math;

import 'package:ugk_trainer/engine.dart' as trainer;
import 'package:ugk_coach/ugk_coach.dart' as coach;
import 'package:ugk_trainer/engine.dart' show VoiceCue, CuePriority;

import '../domain/hip_assessment.dart';
import '../domain/hip_models.dart';
import '../domain/hip_session.dart';
import 'voice_library.dart';

export 'package:ugk_trainer/engine.dart' show CuePriority, VoiceCue;

enum PhaseKind { prep, work, switchSide, rest, done }

/// A stretch of the session with a fixed length: lead-in before the first
/// drill, one side (or the whole) of a drill, the side-switch gap, the rest
/// between drills, and the end.
class SessionPhase {
  const SessionPhase(
    this.kind,
    this.step,
    this.seconds, {
    this.side,
    this.segment = 0,
    this.segments = 1,
    this.set = 0,
    this.totalSets = 0,
  });
  final PhaseKind kind;
  final int step;
  final double seconds;
  final HipSide? side;
  final int segment;
  final int segments;
  final int set;
  final int totalSets;

  bool get isWork => kind == PhaseKind.work;
  bool get lastSegment => segment == segments - 1;

  @override
  String toString() =>
      '${kind.name}#$step${side == null ? '' : '/${side!.name}'} ${seconds}s';
}

/// Repetition count spoken while the drill runs ("每侧 8 次" → 1…8); null
/// for holds, circles both ways, and mixed doses.
int? repsOf(String dose) {
  final s = dose.replaceAll(RegExp(r'（.*?）'), '').trim();
  final m = RegExp(
    r'^(?:每侧\s*)?(?:慢呼吸|左右交替|左右慢慢倒|左右|慢开慢合)?\s*(\d+)\s*(次|圈)$',
  ).firstMatch(s);
  if (m == null) return null;
  final n = int.parse(m[1]!);
  return n >= 1 && n <= 10 ? n : null;
}

/// Builds the phases of a training session and the voice cues of each
/// phase. Pure and deterministic: the player and the tests share it.
class SessionScript {
  SessionScript({
    required this.lib,
    required this.lang,
    required this.routineIds,
    required this.restSeconds,
    this.prepSeconds = 15,
    this.switchSeconds = 5,
    this.kits = const {},
  });

  final VoiceLibrary lib;

  /// Action kits by action id: each drill's rhythm and voice script
  /// (docs/action-kit-spec-v1.md). A drill without a kit is timed as a hold.
  final Map<String, ActionKit> kits;
  final String lang;
  final List<String> routineIds;
  final int restSeconds;
  final int prepSeconds;
  final int switchSeconds;

  // ── phases ────────────────────────────────────────────────────────────

  List<SessionPhase> workPhases(int i, PlanStep s) {
    final segs = s.segments;
    return [
      for (final (k, (side, secs)) in segs.indexed) ...[
        if (k > 0)
          SessionPhase(
            PhaseKind.switchSide,
            i,
            switchSecondsFor(s, side),
            side: side,
          ),
        SessionPhase(
          PhaseKind.work,
          i,
          secs.toDouble(),
          side: side,
          segment: k,
          segments: segs.length,
        ),
      ],
    ];
  }

  /// Room kept between the end of the switch line and the 3-2-1, so the
  /// line is not still sounding when 「三」 comes (playback starts a little
  /// after the cue on a real device).
  static const switchMargin = 0.4;

  /// What is said when the side switches: 慢慢还原 after a hold, then
  /// 换左边 / 换右边.
  List<String> switchClips(PlanStep s, HipSide? side) {
    final kit = _kit(s);
    return [
      'chime.end',
      if (kit != null && !kit.kind.counted) kit.voice.end,
      side == HipSide.left ? 'p.switch_left' : 'p.switch_right',
    ];
  }

  /// The side-switch gap: [switchSeconds], longer when the switch line
  /// would not end [switchMargin] before the 3-2-1 (Android voice fix
  /// 2026-10-19: in English 「Slowly come out of it. Switch to the left
  /// side」 is 2.6 s and the 「three」 at 2 s used to cut its last half
  /// second). Whole seconds, so the ring still counts down evenly.
  double switchSecondsFor(PlanStep s, HipSide? side) {
    final need = (_len(switchClips(s, side)) + switchMargin).ceil() + 3;
    return math.max(switchSeconds, need).toDouble();
  }

  /// Phases from step [from] on. [lead] is the phase in front of that step:
  /// prep (session start), rest (between drills) or none (resume mid-way).
  List<SessionPhase> phases(
    List<PlanStep> steps, {
    int from = 0,
    PhaseKind? lead = PhaseKind.prep,
  }) {
    final out = <SessionPhase>[];
    for (var i = from; i < steps.length; i++) {
      if (i == from && lead == PhaseKind.prep) {
        out.add(SessionPhase(PhaseKind.prep, i, prepSeconds.toDouble()));
      } else if (i > from || lead == PhaseKind.rest) {
        out.add(SessionPhase(PhaseKind.rest, i, restSeconds.toDouble()));
      }
      out.addAll(workPhases(i, steps[i]));
    }
    out.add(SessionPhase(PhaseKind.done, steps.length, 0));
    return out;
  }

  // ── cues ──────────────────────────────────────────────────────────────

  double _len(List<String> clips) => lib.total(clips, lang: lang);

  /// The dose said in the preview: the authored line when there is one; a
  /// library hold says 「每侧 + N 秒」 from the stock clips; else the step
  /// length (legacy).
  List<String> _dose(PlanStep s) {
    final key = lib.textKey('dose', s.dose);
    if (key != null) return [key];
    final kit = _kit(s);
    final per = s.kitDose.seconds;
    if (kit != null && !kit.kind.counted && per != null) {
      if (lib.has('sec.$per', lang: lang)) {
        return [if (s.sided) 'p.each_side', 'sec.$per'];
      }
      return const [];
    }
    if (kit != null &&
        (s.sets > 1 || !lib.has('sec.${s.seconds}', lang: lang))) {
      return const [];
    }
    return ['sec.${s.seconds}'];
  }

  List<String> _preview(List<PlanStep> steps, int i, {required bool first}) {
    final s = steps[i];
    return [
      first
          ? 'p.first'
          : i == steps.length - 1
          ? 'p.last'
          : 'p.next',
      'drill.${s.drill.id}',
      ..._dose(s),
      if (s.sided) ?kits[s.drill.id]?.voice.firstSide,
    ];
  }

  ActionKit? _kit(PlanStep s) => kits[s.drill.id];

  /// What is said when [s] ends: 慢慢还原 after a hold, 很好 after reps.
  String _endClip(PlanStep s) => _kit(s)?.voice.end ?? 'p.nice';

  /// Lines said one after another from [start]; a line that would not finish
  /// before [until] is left out (never squeezed under the countdown).
  List<VoiceCue> _sequence(
    double start,
    double until,
    List<(List<String>, CuePriority)> lines,
  ) {
    final out = <VoiceCue>[];
    var t = start;
    for (final (clips, prio) in lines) {
      final len = _len(clips);
      if (t + len > until) {
        if (prio == CuePriority.coach) continue;
        // information still goes out; the queue lets the count cut it.
      }
      out.add(VoiceCue(t, clips, prio, subtitle: _subtitle(clips)));
      t += len + .3;
    }
    return out;
  }

  String? _subtitle(List<String> clips) {
    for (final c in clips) {
      if (c.startsWith('point.') ||
          c.startsWith('cue.') ||
          c.startsWith('tip.')) {
        return lib.line(c, lang: 'zh');
      }
    }
    return null;
  }

  List<VoiceCue> _countdown(double end, {int from = 3, bool ready = false}) => [
    if (ready) VoiceCue(end - from - 1, const ['p.ready'], CuePriority.call),
    for (var k = from; k >= 1; k--)
      VoiceCue(end - k, ['chime.tick', 'n.$k'], CuePriority.count),
  ];

  /// Cues for [phase] in a session of [steps] (times relative to the start
  /// of the phase). [bySkip]: the phase was entered with 跳过, so it does not
  /// praise the drill that was skipped.
  List<VoiceCue> cues(
    SessionPhase phase,
    List<PlanStep> steps, {
    bool bySkip = false,
  }) {
    switch (phase.kind) {
      case PhaseKind.prep:
        final s = steps[phase.step];
        final minutes = math.max(1, (_planSeconds(steps) / 60).round());
        final intro = [
          'p.welcome',
          for (final r in routineIds) 'routine.$r',
          'p.total',
          'min.$minutes',
        ];
        return [
          ..._sequence(0, phase.seconds - 4.2, [
            (intro, CuePriority.info),
            (_preview(steps, phase.step, first: true), CuePriority.info),
            (['point.${s.drill.id}'], CuePriority.coach),
          ]),
          ..._countdown(phase.seconds, ready: true),
        ];
      case PhaseKind.rest:
        final s = steps[phase.step];
        final tip = s.tip.isEmpty ? null : lib.textKey('tip', s.tip);
        final prev = phase.step > 0 ? steps[phase.step - 1] : null;
        final head = <String>[
          'chime.end',
          if (!bySkip && prev != null) _endClip(prev),
          'p.rest',
          'sec.${phase.seconds.round()}',
        ];
        return [
          ..._sequence(0, phase.seconds - 3.2, [
            (head, CuePriority.call),
            (_preview(steps, phase.step, first: false), CuePriority.info),
            (['point.${s.drill.id}'], CuePriority.coach),
            if (tip != null) ([tip], CuePriority.coach),
          ]),
          ..._countdown(phase.seconds),
        ];
      case PhaseKind.switchSide:
        final s = steps[phase.step];
        return [
          VoiceCue(0, switchClips(s, phase.side), CuePriority.call),
          ..._countdown(phase.seconds),
        ];
      case PhaseKind.done:
        return const [
          VoiceCue(0, ['chime.finish', 'p.finish'], CuePriority.call),
        ];
      case PhaseKind.work:
        return _workCues(phase, steps[phase.step]);
    }
  }

  int _planSeconds(List<PlanStep> steps) =>
      steps.fold(0, (s, p) => s + p.seconds) +
      restSeconds * math.max(0, steps.length - 1);

  List<VoiceCue> _workCues(SessionPhase phase, PlanStep s) {
    final kit = _kit(s);
    final source = _HipSource(lib, kits, step: s, side: phase.side);
    final script = trainer.SessionScript(source: source, lang: lang);
    final counted = kit?.kind.counted ?? false;
    final sets = phase.totalSets > 0
        ? 1
        : counted
        ? setsOf(phase, s)
        : holdSetsOf(phase, s);
    final gap = counted ? 0.0 : 5.0;
    var n = sets;
    var per = (phase.seconds - (n - 1) * gap) / n;
    if (!counted && per < 10) {
      n = 1;
      per = phase.seconds;
    }
    final reps = kit == null ? repsOf(s.dose) : null;
    final rhythm = kit == null
        ? (reps == null
              ? trainer.Rhythm.timedHold
              : trainer.Rhythm.fromRepSeconds(phase.seconds / reps))
        : trainer.Rhythm.fromActionKitJson(kit.raw);
    final out = <VoiceCue>[];
    for (var set = 0; set < n; set++) {
      final offset = set * (per + gap);
      final p = trainer.SessionPhase(
        kind: trainer.PhaseKind.work,
        seconds: per,
        exerciseId: s.drill.id,
        itemIndex: phase.step,
        side: phase.side == null
            ? null
            : phase.side == HipSide.right
            ? trainer.Side.right
            : trainer.Side.left,
        set: set + 1,
        sets: n,
        rhythm: rhythm,
        reps: kit == null ? reps : s.kitDose.reps ?? kit.defaultReps,
        repSeconds: kit == null && reps != null ? phase.seconds / reps : null,
        holdSeconds: s.kitDose.holdSeconds ?? kit?.defaultHold,
      );
      for (final cue in script.cues(p, planSeconds: phase.seconds)) {
        final clips = (set > 0 || phase.set > 1) && cue.at == 0 && kit != null
            ? ['chime.start', kit.voice.nextSet]
            : cue.clips;
        final finalSet =
            set == n - 1 &&
            (phase.totalSets == 0 || phase.set == phase.totalSets);
        final actualReps = rhythm
            .repPlan(
              reps: s.kitDose.reps,
              hold: s.kitDose.holdSeconds,
              seconds: per,
            )
            .reps;
        final spoken = kit != null && !finalSet
            ? [
                for (final clip in clips)
                  clip == kit.voice.lastRep
                      ? kit.voice.countClip(actualReps)
                      : clip,
              ]
            : clips;
        out.add(
          VoiceCue(
            offset + cue.at,
            spoken,
            cue.priority,
            subtitle: cue.subtitle,
          ),
        );
      }
      if (set < n - 1 && !counted && kit != null) {
        out.add(
          VoiceCue(offset + per, [
            'chime.end',
            kit.voice.end,
          ], CuePriority.call),
        );
      }
    }
    if (!counted && tightSide(phase, s) && phase.set <= 1) {
      final go =
          kit?.voice.go ??
          (phase.side == HipSide.right ? 'p.go_right' : 'p.go');
      final at = _len([go]) + .3;
      final clip = s.extraSide == HipSide.right
          ? 'cue.extra_right'
          : 'cue.extra_left';
      // The App's D-01 call reserves its own space before flexible coaching.
      final end = at + _len([clip]) + .3;
      out.removeWhere((c) => c.priority == CuePriority.coach && c.at < end);
      out.add(VoiceCue(at, [clip], CuePriority.info, subtitle: lib.line(clip)));
    }
    out.sort((a, b) => a.at.compareTo(b.at));
    return out;
  }

  /// This phase is the tight side that does more (D-01). Checks the real
  /// [PlanStep.extraSide] against the side played – an unsided step or the
  /// other side never is (PR #22 F6).
  static bool tightSide(SessionPhase phase, PlanStep s) =>
      s.tightOn(phase.side);

  /// Sets of a counted step on this phase: the step's sets (练习库 1–3),
  /// plus one on the tight side (D-01). Same rule as the player's pain
  /// guard ([PlanStep.countedSetsOn], PR #22 F7).
  static int setsOf(SessionPhase phase, PlanStep s) =>
      s.countedSetsOn(phase.side);

  /// Sets of a hold on this phase, as actually done on this side (PR #22
  /// F5): a 练习库 group's tight side does one more set (1 set → 2 sets with
  /// a 5 s gap); a built-in routine's tight side keeps one longer hold.
  static int holdSetsOf(SessionPhase phase, PlanStep s) =>
      s.holdSetsOn(phase.side);

  /// A counted [s] leaves some side or set without one full rep (PR #22 F7):
  /// the script would play that side with no cues. The player skips the
  /// action instead (pain halving, 「任一侧/组放不下完整一次就跳过」).
  static bool noFullRep(PlanStep s, ActionKit kit) =>
      kit.kind.counted &&
      s.segments.any(
        (segment) =>
            kit
                .repPlan(
                  s.kitDose,
                  segment.$2.toDouble(),
                  sets: s.countedSetsOn(segment.$1),
                )
                .reps ==
            0,
      );

  /// Count clips exist for 1…10; a higher count says only its phase word.
  static const maxCountClip = 10;

  // ── assessment ────────────────────────────────────────────────────────

  /// Spoken lead-in before the hold timer of an assessment item starts:
  /// the instructions are read first, then the hold is counted.
  List<String> assessmentLeadIn(
    AssessmentItem item, {
    required bool first,
    HipSide? side,
  }) => [
    if (side == HipSide.right) ...[
      'a.switch_right',
    ] else ...[
      if (first) 'a.intro',
      'a.item.${item.id}',
      if (side == HipSide.left) 'a.left_first',
    ],
    'a.cue.${item.id}',
  ];

  double assessmentLeadSeconds(
    AssessmentItem item, {
    required bool first,
    HipSide? side,
  }) => _len(assessmentLeadIn(item, first: first, side: side)) + .6;

  List<VoiceCue> assessmentCues(
    AssessmentItem item, {
    required bool first,
    HipSide? side,
  }) {
    final lead = assessmentLeadSeconds(item, first: first, side: side);
    final end = lead + item.seconds;
    return [
      VoiceCue(
        0,
        assessmentLeadIn(item, first: first, side: side),
        CuePriority.info,
      ),
      VoiceCue(lead, const ['chime.start', 'a.hold'], CuePriority.call),
      ..._countdown(end),
      VoiceCue(end, const ['chime.end', 'a.choose'], CuePriority.call),
    ];
  }
}

/// App-specific semantic source; lookup and durations remain in the package.
class _HipSource extends trainer.VoiceSource {
  _HipSource(this.lib, this.kits, {this.step, this.side});
  final VoiceLibrary lib;
  final Map<String, ActionKit> kits;
  final PlanStep? step;
  final HipSide? side;
  @override
  Set<String> get languages => lib.languages;
  @override
  bool has(String key, {required String lang}) => lib.has(key, lang: lang);
  @override
  double seconds(String key, {required String lang}) =>
      lib.seconds(key, lang: lang);
  @override
  String asset(String key, {required String lang}) =>
      lib.asset(key, lang: lang);
  @override
  String? line(String key, {required String lang}) => lib.line(key, lang: lang);
  @override
  String? call(trainer.VoiceCall c) => lib.call(c);
  @override
  String? drill(String id, trainer.DrillLine line) {
    if (line == trainer.DrillLine.cue1 &&
        step != null &&
        !kits.containsKey(id)) {
      final method = step!.drill.methods.isEmpty
          ? HipMethod.relax
          : step!.drill.methods.first;
      return 'cue.${method.id}.1';
    }
    return lib.drill(id, line);
  }

  @override
  List<String> secondsPhrase(int n) => lib.secondsPhrase(n);
  @override
  List<String> minutesPhrase(int n) => lib.minutesPhrase(n);
  @override
  trainer.KitVoice? kitVoice(String id) {
    final kit = kits[id];
    if (kit != null) return trainer.KitVoice.fromActionKitJson(kit.raw);
    // Pre-action-kit plans retain their documented timed-hold calls.
    if (step != null && repsOf(step!.dose) == null) {
      return trainer.KitVoice(
        prepare: const [],
        go: side == HipSide.right ? 'p.go_right' : 'p.go',
        count: 'n.{k}',
        lastRep: 'p.last_rep',
        nextSet: 'p.again',
        end: 'p.nice',
        coach: [
          for (final k in [1, 2])
            'cue.${step!.drill.methods.isEmpty ? HipMethod.relax.id : step!.drill.methods.first.id}.$k',
        ],
        half: 'p.half',
        last10: 'p.last10',
        countdown: 5,
      );
    }
    return null;
  }
}

/// Shared-player script with only HipLab's authored lines and D-01 mapping.
class HipSessionScript extends trainer.SessionScript {
  HipSessionScript({
    required this.lib,
    required super.lang,
    required this.steps,
    required this.kits,
    this.routineIds = const [],
    this.restSeconds = 15,
    this.useSdkPhases = false,
  }) : super(source: _HipSource(lib, kits));
  final VoiceLibrary lib;
  final List<PlanStep> steps;
  final Map<String, ActionKit> kits;
  final List<String> routineIds;
  final int restSeconds;
  final bool useSdkPhases;
  SessionScript get legacy => SessionScript(
    lib: lib,
    lang: lang,
    routineIds: routineIds,
    restSeconds: restSeconds,
    kits: kits,
  );
  @override
  List<VoiceCue> cues(
    trainer.SessionPhase p, {
    required double planSeconds,
    bool bySkip = false,
  }) {
    if (useSdkPhases) {
      return super.cues(p, planSeconds: planSeconds, bySkip: bySkip);
    }
    if (p.kind == trainer.PhaseKind.rest &&
        p.nextExerciseId == null &&
        p.set > 1) {
      final kit = kits[p.exerciseId];
      return [
        VoiceCue(0, [
          'chime.end',
          if (kit != null) kit.voice.end,
        ], CuePriority.call),
      ];
    }
    return legacy.cues(_fromTrainer(p, steps), steps, bySkip: bySkip);
  }
}

/// App dose/asymmetry adapter. The shared engine consumes these phases.
class HipSessionBuilder extends trainer.SessionBuilder {
  HipSessionBuilder({
    required this.script,
    super.prepSeconds = 15,
    super.transitionSeconds = 15,
    super.switchSideSeconds = 5,
  });
  final HipSessionScript script;
  @override
  List<trainer.SessionPhase> phases(coach.TrainingPlan plan) {
    final items = plan.blocks.expand((b) => b.items).toList();
    final s = SessionScript(
      lib: script.lib,
      lang: script.lang,
      routineIds: script.routineIds,
      restSeconds: transitionSeconds,
      prepSeconds: prepSeconds,
      switchSeconds: switchSideSeconds,
      kits: script.kits,
    );
    final out = <trainer.SessionPhase>[];
    for (final p in s.phases(script.steps)) {
      final item = p.step < items.length ? items[p.step] : null;
      if (!p.isWork) {
        out.add(_toTrainer(p, script.steps, item: item, kits: script.kits));
        continue;
      }
      final step = script.steps[p.step];
      final kit = script.kits[step.drill.id];
      final counted = kit?.kind.counted ?? false;
      var n = counted ? step.countedSetsOn(p.side) : step.holdSetsOn(p.side);
      final gap = counted ? 0.0 : 5.0;
      var per = (p.seconds - (n - 1) * gap) / n;
      if (!counted && per < 10) {
        n = 1;
        per = p.seconds;
      }
      for (var set = 1; set <= n; set++) {
        if (set > 1 && gap > 0) {
          out.add(
            _toTrainer(
              SessionPhase(
                PhaseKind.rest,
                p.step,
                gap,
                side: p.side,
                set: set,
                totalSets: n,
              ),
              script.steps,
              item: item,
            ),
          );
        }
        out.add(
          _toTrainer(
            SessionPhase(
              PhaseKind.work,
              p.step,
              per,
              side: p.side,
              segment: p.segment,
              segments: p.segments,
              set: set,
              totalSets: n,
            ),
            script.steps,
            item: item,
            kits: script.kits,
          ),
        );
      }
    }
    return out;
  }

  @override
  int occurrenceCount(coach.TrainingPlan plan) => script.steps.length;
}

trainer.SessionPhase _toTrainer(
  SessionPhase p,
  List<PlanStep> steps, {
  coach.PlanItem? item,
  Map<String, ActionKit> kits = const {},
}) {
  final s = p.step < steps.length ? steps[p.step] : null;
  final kit = s == null ? null : kits[s.drill.id];
  final rhythm = kit == null ? null : trainer.Rhythm.fromActionKitJson(kit.raw);
  final repPlan = p.isWork && rhythm != null && rhythm.counted
      ? rhythm.repPlan(
          reps: s?.kitDose.reps,
          hold: s?.kitDose.holdSeconds,
          seconds: p.seconds,
        )
      : null;
  return trainer.SessionPhase(
    rhythm: rhythm,
    reps: repPlan?.reps,
    repSeconds: repPlan?.cycle,
    holdSeconds: s?.kitDose.holdSeconds ?? kit?.defaultHold,
    kind: trainer.PhaseKind.values.byName(p.kind.name),
    seconds: p.seconds,
    exerciseId: s?.drill.id,
    item: item,
    itemIndex: p.step,
    set: p.set > 0 ? p.set : 1,
    sets: p.totalSets > 0 ? p.totalSets : s?.sets ?? 0,
    blockIndex: 0,
    itemInBlock: p.step,
    side: p.side == null
        ? null
        : p.side == HipSide.right
        ? trainer.Side.right
        : trainer.Side.left,
    nextExerciseId: p.kind == PhaseKind.rest && p.totalSets == 0
        ? s?.drill.id
        : null,
    doneExerciseId: p.kind == PhaseKind.rest && p.totalSets == 0 && p.step > 0
        ? steps[p.step - 1].drill.id
        : null,
  );
}

SessionPhase _fromTrainer(trainer.SessionPhase p, List<PlanStep> steps) {
  final side = p.side == null
      ? null
      : p.side == trainer.Side.right
      ? HipSide.right
      : HipSide.left;
  final step = p.itemIndex;
  return SessionPhase(
    PhaseKind.values.byName(p.kind.name),
    step,
    p.seconds,
    side: side,
    set: p.set,
    totalSets: p.sets,
    segment: side == HipSide.left ? 1 : 0,
    segments: step < steps.length && steps[step].sided ? 2 : 1,
  );
}
