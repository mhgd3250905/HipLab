import 'hip_assessment.dart';
import 'hip_library.dart';
import 'hip_models.dart';

export 'hip_library.dart' show PlanSource;

/// Inputs that shape today's training. Built from the latest assessment,
/// pain history and the safety answers.
class TrainingProfile {
  const TrainingProfile({
    this.level = 1,
    this.identity = HipIdentity.other,
    this.lockedDirections = const {},
    this.asymmetry = const {},
    this.directionScores = const {},
    this.recommendedRoutine,
    this.dancerUnlocked = false,
    this.blocked = false,
  });

  /// 1 = 入门, 2 = 基础, 3 = 进阶. No assessment yet → 入门.
  final int level;
  final HipIdentity identity;

  /// Relax-only directions (pain in assessment, or a 7-day lock).
  final Set<HipDirection> lockedDirections;
  final Map<HipDirection, HipSide> asymmetry;
  final Map<HipDirection, double> directionScores;
  final String? recommendedRoutine;
  final bool dancerUnlocked;

  /// A safety card was answered "有": browse only, no generated training.
  final bool blocked;

  factory TrainingProfile.from(
    AssessmentResult? r, {
    HipIdentity identity = HipIdentity.other,
    Set<HipDirection> extraLocks = const {},
    bool blocked = false,
  }) => TrainingProfile(
    level: r?.level.level ?? 1,
    identity: identity,
    lockedDirections: {...?r?.painDirections, ...extraLocks},
    asymmetry: r?.asymmetry ?? const {},
    directionScores: r?.directionScores ?? const {},
    recommendedRoutine: r?.route?.routineId,
    dancerUnlocked: r?.dancerUnlocked ?? false,
    blocked: blocked,
  );
}

class PlanStep {
  const PlanStep({
    required this.drill,
    required this.dose,
    required this.seconds,
    required this.sided,
    this.extraSide,
    this.extraSeconds = 0,
    this.replaced,
    this.tip = '',
    this.alternative,
    this.kitDose = const KitDose(),
    this.sets = 1,
  });
  final HipDrill drill;

  /// Sets per side (1–3, 练习库). The tight side does one more (D-01).
  final int sets;

  /// The routine's overrides of the action kit (reps / hold / seconds).
  final KitDose kitDose;
  final String dose;
  final int seconds;
  final bool sided;

  /// "右边多做一组" when the assessment found an asymmetry.
  final HipSide? extraSide;

  /// Seconds added for the tight side (already included in [seconds]); the
  /// player gives them to [extraSide] only (D-01): 70 s → right 35 + left 35,
  /// left tight → 105 s = right 35 + left 70.
  final int extraSeconds;

  /// Per-side seconds, in play order (right first, 成套训练 编排规则 2), or a
  /// single segment with a null side for unsided drills.
  List<(HipSide?, int)> get segments {
    if (!sided) return [(null, seconds)];
    final base = seconds - extraSeconds;
    final right = base ~/ 2 + (extraSide == HipSide.right ? extraSeconds : 0);
    final left =
        base - base ~/ 2 + (extraSide == HipSide.left ? extraSeconds : 0);
    return [(HipSide.right, right), (HipSide.left, left)];
  }

  PlanStep copyWith({HipDrill? drill, int? seconds, String? replaced}) {
    final scale = seconds == null || this.seconds == 0
        ? 1.0
        : seconds / this.seconds;
    return PlanStep(
      drill: drill ?? this.drill,
      dose: dose,
      seconds: seconds ?? this.seconds,
      sided: sided,
      extraSide: extraSide,
      extraSeconds: (extraSeconds * scale).round(),
      replaced: replaced ?? this.replaced,
      tip: tip,
      alternative: alternative,
      kitDose: kitDose,
      sets: sets,
    );
  }

  /// The original drill when this step was swapped (L1 / gate / lock).
  final String? replaced;
  final String tip;
  final String? alternative;
}

class TrainingPlan {
  const TrainingPlan({
    required this.routines,
    required this.steps,
    required this.transitionSeconds,
    this.source = PlanSource.recommended,
    this.refId,
    this.name,
  });
  final List<HipRoutine> routines;
  final List<PlanStep> steps;
  final int transitionSeconds;

  /// 首页推荐 / 套路 / 我的训练组 / 单练.
  final PlanSource source;

  /// Routine id, custom group id or drill id (单练).
  final String? refId;

  /// Title of a custom group or a single drill (routines are named by
  /// [routines]).
  final String? name;

  int get seconds =>
      steps.fold(0, (s, p) => s + p.seconds) +
      transitionSeconds * (steps.isEmpty ? 0 : steps.length - 1);
  int get minutes => (seconds / 60).round();
  String get title =>
      name ??
      routines
          .map((r) => r.name.replaceAll(RegExp(r'\s*\d+\s*分钟$'), ''))
          .join(' + ');
}

/// 成套训练.md 编排规则 4–7 + 自测设计.md §3.3 / §4.6.
class TrainingPlanner {
  const TrainingPlanner(this.content);
  final HipContent content;

  static const durations = [5, 10, 15];
  static const restSeconds = 15;

  /// Picks one routine (or two chained for 15 min) for the scene, preferring
  /// the recommended routine when its length fits within ±3 minutes.
  List<HipRoutine> pickRoutines(
    int minutes,
    HipScene scene,
    TrainingProfile p,
  ) {
    final pool = content.routines
        .where((r) => !r.micro && r.scene == scene)
        .toList();
    if (pool.isEmpty) return const [];
    // Non-dancers do not get the Breaking set unless it was recommended.
    final candidates = pool
        .where(
          (r) =>
              r.id != 'F' ||
              p.identity == HipIdentity.dancer ||
              p.recommendedRoutine == 'F',
        )
        .toList();
    final list = candidates.isEmpty ? pool : candidates;
    HipRoutine? primary;
    final rec = list.where((r) => r.id == p.recommendedRoutine).firstOrNull;
    if (rec != null && (rec.minutes - minutes).abs() <= 3) primary = rec;
    primary ??=
        ([...list]..sort((a, b) {
              final c = (a.minutes - minutes).abs().compareTo(
                (b.minutes - minutes).abs(),
              );
              return c != 0 ? c : a.minutes.compareTo(b.minutes);
            }))
            .first;
    final picked = [primary];
    final remaining = minutes - primary.minutes;
    if (remaining >= 4) {
      final rest = list.where((r) => r != primary).toList()
        ..sort(
          (a, b) => (a.minutes - remaining).abs().compareTo(
            (b.minutes - remaining).abs(),
          ),
        );
      if (rest.isNotEmpty) picked.add(rest.first);
    } else if (remaining >= 2 && scene == HipScene.chair) {
      final micro = content.routines
          .where((r) => r.micro && r.scene == scene)
          .firstOrNull;
      if (micro != null) picked.add(micro);
    }
    return picked;
  }

  /// Gated drills (舞者解锁 / 方向分数) – see [needsEasier].
  bool gated(HipDrill d, TrainingProfile p) => _gated(d, p);

  /// The routines swap this drill for its easier version at this level
  /// (level 1 + advanced, or a gate). The library only advises (拍板 4).
  bool needsEasier(HipDrill d, TrainingProfile p) =>
      (p.level == 1 && d.advanced) || _gated(d, p);

  bool _gated(HipDrill d, TrainingProfile p) {
    final dir = d.directions.first;
    if (d.id.startsWith('t-')) return !p.dancerUnlocked;
    if (d.id == 'n-slider-lateral' || d.id == 'n-supported-front-split') {
      return (p.directionScores[dir] ?? 0) < 1 ||
          p.lockedDirections.contains(dir);
    }
    return false;
  }

  /// Returns null when the user is blocked by a safety card.
  TrainingPlan? plan({
    required int minutes,
    required HipScene scene,
    required TrainingProfile profile,
  }) {
    if (profile.blocked) return null;
    return planFor(pickRoutines(minutes, scene, profile), profile);
  }

  TrainingPlan planFor(
    List<HipRoutine> routines,
    TrainingProfile profile, {
    PlanSource source = PlanSource.recommended,
  }) {
    final steps = <PlanStep>[];
    final seen = <String>{};
    for (final r in routines) {
      for (final s in r.steps) {
        var drill = content.drill(s.drillId);
        String? replaced;
        final alt = s.alternative ?? drill.alternative;
        final needsSwap =
            (profile.level == 1 && drill.advanced) || _gated(drill, profile);
        if (needsSwap) {
          if (alt == null) continue;
          replaced = drill.id;
          drill = content.drill(alt);
        }
        final dir = drill.directions.first;
        if (profile.lockedDirections.contains(dir) && !drill.isRelax) continue;
        // A chained second routine should not repeat a drill already done.
        if (routines.length > 1 && !seen.add(drill.id)) continue;
        seen.add(drill.id);
        final extra = s.sided ? profile.asymmetry[dir] : null;
        // A swapped-in drill takes its own kit's rhythm for the same dose.
        final seconds = content.stepSeconds(
          drill.id,
          s.kit,
          s.sided,
          s.seconds,
        );
        steps.add(
          PlanStep(
            drill: drill,
            dose: s.dose,
            seconds: seconds + (extra != null ? seconds ~/ 2 : 0),
            sided: s.sided,
            extraSide: extra,
            extraSeconds: extra != null ? seconds ~/ 2 : 0,
            kitDose: s.kit,
            replaced: replaced,
            tip: s.tip,
            alternative: replaced == null ? alt : null,
          ),
        );
      }
    }
    // 15 s between drills: time for the voice preview of the next drill
    // ("休息 15 秒，下一个…" + key point) and a 3-2-1 lead-in (#13).
    return TrainingPlan(
      routines: routines,
      steps: steps,
      transitionSeconds: restSeconds,
      source: source,
      refId: routines.length == 1 ? routines.single.id : null,
    );
  }

  /// A routine picked in 练习 · 套路 (same rules as the home plan). Null when
  /// blocked by a safety card.
  TrainingPlan? routinePlan(HipRoutine r, TrainingProfile profile) =>
      profile.blocked
      ? null
      : planFor([r], profile, source: PlanSource.routine);

  /// Relax-only this week (pain in the assessment or a 7-day lock): only
  /// relax drills of that direction may run.
  static bool lockedOut(HipDrill d, TrainingProfile p) =>
      p.lockedDirections.contains(d.directions.first) && !d.isRelax;

  /// 单练: one step at the user's dose. Null when a safety card blocks
  /// training or the drill's direction is relax-only this week. Advanced /
  /// gated drills are not swapped (拍板 4: advise, still allowed); no
  /// tight-side extra set (the user picked the dose).
  TrainingPlan? singlePlan(
    HipDrill drill,
    LibraryDose dose,
    TrainingProfile profile,
  ) {
    final kit = content.kit(drill.id);
    if (kit == null || profile.blocked || lockedOut(drill, profile)) {
      return null;
    }
    final d = DoseRules.clamp(kit, dose, single: true);
    return TrainingPlan(
      routines: const [],
      steps: [
        PlanStep(
          drill: drill,
          dose: doseText(kit, d, single: true),
          seconds: DoseRules.stepSeconds(kit, d, single: true),
          sided: kit.sided,
          sets: d.sets,
          kitDose: DoseRules.kitDose(kit, d, single: true),
          alternative: drill.alternative,
        ),
      ],
      transitionSeconds: restSeconds,
      source: PlanSource.single,
      refId: drill.id,
      name: drill.name,
    );
  }

  /// Steps of [r] that will not run for [profile]: their direction is
  /// relax-only this week (or the drill left the library).
  List<CustomStep> customSkipped(CustomRoutine r, TrainingProfile profile) => [
    for (final s in r.steps)
      if (!inLibrary(content, s.kitId) ||
          lockedOut(content.drill(s.kitId), profile))
        s,
  ];

  /// 我的训练组: the steps as saved, minus relax-only directions. Advanced
  /// drills are not swapped (拍板 4). The tight side gets one more set, as
  /// in the routines. Null when blocked by a safety card.
  TrainingPlan? customPlan(CustomRoutine r, TrainingProfile profile) {
    if (profile.blocked) return null;
    final steps = <PlanStep>[];
    for (final s in r.steps) {
      if (!inLibrary(content, s.kitId)) continue;
      final drill = content.drill(s.kitId);
      if (lockedOut(drill, profile)) continue;
      final kit = content.kit(s.kitId)!;
      final d = s.dose(kit);
      final dir = drill.directions.first;
      final extra = kit.sided ? profile.asymmetry[dir] : null;
      final extraSeconds = extra == null
          ? 0
          : DoseRules.extraSetSeconds(kit, d, single: false);
      steps.add(
        PlanStep(
          drill: drill,
          dose: doseText(kit, d, single: false),
          seconds: DoseRules.stepSeconds(kit, d, single: false) + extraSeconds,
          sided: kit.sided,
          sets: d.sets,
          extraSide: extra,
          extraSeconds: extraSeconds,
          kitDose: DoseRules.kitDose(kit, d, single: false),
          alternative: drill.alternative,
        ),
      );
    }
    return TrainingPlan(
      routines: const [],
      steps: steps,
      transitionSeconds: r.restSeconds,
      source: PlanSource.custom,
      refId: r.id,
      name: r.name,
    );
  }
}
