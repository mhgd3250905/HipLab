import 'dart:math' as math;

import '../domain/hip_assessment.dart';
import '../domain/hip_models.dart';
import '../domain/hip_session.dart';
import 'voice_library.dart';

/// Who wins when two lines want the air at once (#13): counts are never
/// interrupted and interrupt everything else; calls (开始 / 换边 / 还剩 10 秒)
/// beat information (预告) which beats coaching tips.
enum CuePriority { coach, info, call, count }

/// One thing to say (and/or a chime to play) at [at] seconds into a phase.
/// Clip keys are manifest keys; `chime.*` keys play on the chime channel.
class VoiceCue {
  const VoiceCue(this.at, this.clips, this.priority, {this.subtitle});
  final double at;
  final List<String> clips;
  final CuePriority priority;

  /// Shown under the drill name while it plays (coach / tip lines).
  final String? subtitle;

  List<String> get voiceClips =>
      clips.where((c) => !c.startsWith('chime.')).toList();
  List<String> get chimes =>
      clips.where((c) => c.startsWith('chime.')).toList();

  @override
  String toString() => '${at.toStringAsFixed(2)} ${clips.join('+')}';
}

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
  });
  final PhaseKind kind;
  final int step;
  final double seconds;
  final HipSide? side;
  final int segment;
  final int segments;

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

  String _dose(PlanStep s) => lib.textKey('dose', s.dose) ?? 'sec.${s.seconds}';

  List<String> _preview(List<PlanStep> steps, int i, {required bool first}) {
    final s = steps[i];
    return [
      first
          ? 'p.first'
          : i == steps.length - 1
          ? 'p.last'
          : 'p.next',
      'drill.${s.drill.id}',
      _dose(s),
      if (s.sided) ?kits[s.drill.id]?.voice.firstSide,
    ];
  }

  ActionKit? _kit(PlanStep s) => kits[s.drill.id];

  /// What is said when [s] ends: 慢慢还原 after a hold, 很好 after reps.
  String _endClip(PlanStep s) => _kit(s)?.voice.end ?? 'p.nice';

  String _methodCue(PlanStep s, int variant) {
    final m = s.drill.methods.isEmpty ? HipMethod.relax : s.drill.methods.first;
    return 'cue.${m.id}.$variant';
  }

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
    if (kit != null && kit.kind.counted) return _repCues(phase, s, kit);
    if (kit != null) return _holdCues(phase, s, kit);
    return _legacyWorkCues(phase, s);
  }

  /// Sets on this phase: the tight side does one extra set (D-01).
  static int setsOf(SessionPhase phase, PlanStep s) =>
      s.extraSide != null && s.extraSide == phase.side ? 2 : 1;

  /// Counted action (rep rhythm): "开始", then on every rep the count with
  /// the go word ("一，起"), the back word at the return ("落"), a hold word
  /// and 3-2-1 inside long holds. Rep k starts at a fixed beat and the last
  /// rep gets its full cycle: it ends exactly when the phase ends, so the
  /// next "很好 / 换边" never cuts it short.
  List<VoiceCue> _repCues(SessionPhase phase, PlanStep s, ActionKit kit) {
    final plan = kit.repPlan(s.kitDose, phase.seconds, sets: setsOf(phase, s));
    final v = kit.voice;
    if (plan.reps == 0) return const [];
    final out = <VoiceCue>[
      VoiceCue(0, ['chime.start', v.go], CuePriority.call),
    ];
    for (var set = 0; set < plan.sets; set++) {
      if (set > 0) {
        out.add(
          VoiceCue(set * plan.setSeconds, [
            'chime.start',
            v.nextSet,
          ], CuePriority.call),
        );
      }
      for (var k = 1; k <= plan.reps; k++) {
        var t = plan.repStart(set, k);
        final last = set == plan.sets - 1 && k == plan.reps && plan.reps >= 3;
        for (final (i, ph) in plan.phases.indexed) {
          final word = ph.cueFor(k);
          if (i == 0) {
            out.add(
              VoiceCue(t, [
                last ? v.lastRep : v.countClip(k),
                ?word,
              ], CuePriority.count),
            );
          } else if (word != null) {
            out.add(VoiceCue(t + ph.cueAt, [word], CuePriority.count));
          }
          if (ph.id == 'hold' && ph.seconds >= 6) {
            for (var n = 3; n >= 1; n--) {
              out.add(
                VoiceCue(t + ph.seconds - n, ['n.$n'], CuePriority.count),
              );
            }
          }
          t += ph.seconds;
        }
      }
    }
    out.sort((a, b) => a.at.compareTo(b.at));
    return out;
  }

  /// Hold (保持计时): start, coaching in the gaps, halfway, last 10 s, a
  /// 5-4-3-2-1; "慢慢还原" is said by the switch / rest that follows.
  List<VoiceCue> _holdCues(SessionPhase phase, PlanStep s, ActionKit kit) =>
      _timedHold(phase, s, kit.voice.coach, kit.voice);

  List<VoiceCue> _legacyWorkCues(SessionPhase phase, PlanStep s) {
    final w = phase.seconds;
    final out = <VoiceCue>[];
    final firstSided = phase.side == HipSide.right && phase.segment == 0;
    out.add(
      VoiceCue(0, [
        'chime.start',
        firstSided ? 'p.go_right' : 'p.go',
      ], CuePriority.call),
    );
    var busyUntil = _len([firstSided ? 'p.go_right' : 'p.go']) + .3;
    if (s.extraSide != null && s.extraSide == phase.side) {
      final clip = s.extraSide == HipSide.right
          ? 'cue.extra_right'
          : 'cue.extra_left';
      out.add(
        VoiceCue(busyUntil, [clip], CuePriority.info, subtitle: lib.line(clip)),
      );
      busyUntil += _len([clip]) + .3;
    }

    final reps = repsOf(s.dose);
    final interval = reps == null ? 0.0 : w / reps;
    if (reps != null && interval >= 2.2) {
      // Count the reps on the beat instead of a countdown.
      for (var k = 1; k <= reps; k++) {
        out.add(
          VoiceCue(math.max(busyUntil, k * interval - .5), [
            'n.$k',
          ], CuePriority.count),
        );
      }
      if (interval >= 6) {
        final t = interval + interval / 2 - _len([_methodCue(s, 1)]) / 2;
        out.add(
          VoiceCue(
            t,
            [_methodCue(s, 1)],
            CuePriority.coach,
            subtitle: lib.line(_methodCue(s, 1)),
          ),
        );
      }
      out.sort((a, b) => a.at.compareTo(b.at));
      return out;
    }

    // Timed hold: countdown, last-10, halfway, then coaching in the gaps.
    final fixed = <VoiceCue>[
      if (w >= 8) ...[
        for (var k = 5; k >= 1; k--)
          VoiceCue(w - k, ['chime.tick', 'n.$k'], CuePriority.count),
      ] else
        ..._countdown(w),
      if (w >= 20) VoiceCue(w - 10, const ['p.last10'], CuePriority.call),
      if (w >= 30) VoiceCue(w / 2, const ['p.half'], CuePriority.info),
    ];
    out.addAll(fixed);
    final windows = [
      (0.0, busyUntil),
      for (final c in fixed) (c.at - .4, c.at + _len(c.voiceClips) + .4),
    ];
    bool free(double a, double b) =>
        windows.every((win) => b <= win.$1 || a >= win.$2);
    final coach = <String>[_methodCue(s, 1), if (w >= 40) _methodCue(s, 2)];
    final targets = [w * .28, w * .72];
    for (final (k, clip) in coach.indexed) {
      final len = _len([clip]);
      double? placed;
      for (final shift in [0.0, -1.5, 1.5, -3.0, 3.0, -4.5, 4.5]) {
        final t = targets[k] + shift;
        if (t >= busyUntil && t + len <= w - 5.6 && free(t, t + len)) {
          placed = t;
          break;
        }
      }
      if (placed == null) continue;
      windows.add((placed, placed + len + .4));
      out.add(
        VoiceCue(placed, [clip], CuePriority.coach, subtitle: lib.line(clip)),
      );
    }
    out.sort((a, b) => a.at.compareTo(b.at));
    return out;
  }

  List<VoiceCue> _timedHold(
    SessionPhase phase,
    PlanStep s,
    List<String> coachClips,
    KitVoice v,
  ) {
    final w = phase.seconds;
    final out = <VoiceCue>[
      VoiceCue(0, ['chime.start', v.go], CuePriority.call),
    ];
    var busyUntil = _len([v.go]) + .3;
    final sets = setsOf(phase, s);
    if (sets > 1) {
      final clip = s.extraSide == HipSide.right
          ? 'cue.extra_right'
          : 'cue.extra_left';
      out.add(
        VoiceCue(busyUntil, [clip], CuePriority.info, subtitle: lib.line(clip)),
      );
      busyUntil += _len([clip]) + .3;
    }
    final fixed = <VoiceCue>[
      if (w >= 8) ...[
        for (var k = v.countdown; k >= 1; k--)
          VoiceCue(w - k, ['chime.tick', 'n.$k'], CuePriority.count),
      ] else
        ..._countdown(w),
      if (w >= 20 && v.last10 != null)
        VoiceCue(w - 10, [v.last10!], CuePriority.call),
      if (w >= 30 && v.half != null)
        VoiceCue(w / 2, [v.half!], CuePriority.info),
    ];
    out.addAll(fixed);
    final windows = [
      (0.0, busyUntil),
      for (final c in fixed) (c.at - .4, c.at + _len(c.voiceClips) + .4),
    ];
    bool free(double a, double b) =>
        windows.every((win) => b <= win.$1 || a >= win.$2);
    final coach = [
      if (coachClips.isNotEmpty) coachClips.first,
      if (w >= 40 && coachClips.length > 1) coachClips[1],
    ];
    final targets = [w * .28, w * .72];
    for (final (k, clip) in coach.indexed) {
      final len = _len([clip]);
      for (final shift in [0.0, -1.5, 1.5, -3.0, 3.0, -4.5, 4.5]) {
        final t = targets[k] + shift;
        if (t >= busyUntil && t + len <= w - 5.6 && free(t, t + len)) {
          windows.add((t, t + len + .4));
          out.add(
            VoiceCue(t, [clip], CuePriority.coach, subtitle: lib.line(clip)),
          );
          break;
        }
      }
    }
    out.sort((a, b) => a.at.compareTo(b.at));
    return out;
  }

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
