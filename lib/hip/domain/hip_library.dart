/// Training library (练习库, docs/training-library-2026-10-19.md): which
/// drills are in 动作大全, the dose rules of 单练 and custom training groups,
/// custom_routines v1 persistence and the practice history. Pure Dart.
library;

import 'dart:math' as math;

import 'hip_models.dart';

// ───────────────────────── 动作大全 ─────────────────────────

/// Assessment-only demo drills (开哥 2026-10-19): `n-thomas-test` exists only
/// to demo the 托马斯 check item, is in no routine and is named 测试演示; its
/// training form is `h-knee-hug`.
const assessmentOnlyDrills = {'n-thomas-test'};

/// 动作大全: the content pack's own drills (never new Pose-Hub moves) that
/// have a clip and an action kit, minus assessment-only demos. Content
/// order is kept.
List<HipDrill> libraryDrills(HipContent c) => [
  for (final d in c.drills.values)
    if (d.mediaStatus == HipMediaStatus.video &&
        d.video != null &&
        c.kit(d.id) != null &&
        !assessmentOnlyDrills.contains(d.id))
      d,
];

bool inLibrary(HipContent c, String id) {
  final d = c.drills[id];
  return d != null &&
      d.mediaStatus == HipMediaStatus.video &&
      d.video != null &&
      c.kit(id) != null &&
      !assessmentOnlyDrills.contains(id);
}

// ───────────────────────── doses ─────────────────────────

/// What a dose stepper changes.
enum DoseUnit { reps, seconds }

/// A dose the user tunes: reps (counted) or seconds (timed), and sets.
///
/// Counted kits may also carry what a built-in routine step authored on top
/// of the kit default (PR #22 F2, kept by 「复制成我的训练组」):
/// [holdSeconds], the hold of a 带停留 rep (h-sumo-pry 15 s in F), and
/// [paceSeconds], the routine's seconds per side the reps are paced into.
class LibraryDose {
  const LibraryDose({
    this.reps,
    this.seconds,
    this.sets = 1,
    this.holdSeconds,
    this.paceSeconds,
  });
  final int? reps;
  final int? seconds;
  final int sets;

  /// Hold of one rep (rep_hold kits); null = the kit's default hold.
  final int? holdSeconds;

  /// Seconds per side the reps are spread over (a copied routine step's
  /// pace); null = the reps at the kit's own pace. Dropped when the reps
  /// change.
  final int? paceSeconds;

  /// Hold / pace above this are not a dose (stored data is clamped to it).
  static const maxHold = 60;
  static const maxPace = 300;

  LibraryDose copyWith({int? reps, int? seconds, int? sets}) => LibraryDose(
    reps: reps ?? this.reps,
    seconds: seconds ?? this.seconds,
    sets: sets ?? this.sets,
    holdSeconds: holdSeconds,
    paceSeconds: paceSeconds,
  );

  @override
  bool operator ==(Object other) =>
      other is LibraryDose &&
      other.reps == reps &&
      other.seconds == seconds &&
      other.sets == sets &&
      other.holdSeconds == holdSeconds &&
      other.paceSeconds == paceSeconds;

  @override
  int get hashCode =>
      Object.hash(reps, seconds, sets, holdSeconds, paceSeconds);

  @override
  String toString() =>
      'LibraryDose(reps: $reps, seconds: $seconds, '
      'sets: $sets, holdSeconds: $holdSeconds, paceSeconds: $paceSeconds)';
}

/// Allowed values of one stepper.
class DoseRange {
  const DoseRange(this.min, this.max, this.step, this.base);
  final int min;
  final int max;
  final int step;

  /// The default the range is built around.
  final int base;

  int clamp(int v) {
    final c = v.clamp(min, max);
    if (step <= 1) return c;
    // Snap to the step grid (5 s), staying inside the range.
    final snapped = (c / step).round() * step;
    return snapped.clamp(min, max);
  }

  bool contains(int v) => v >= min && v <= max && clamp(v) == v;
}

/// Dose rules (开哥 2026-10-19, 拍板 2):
///
/// * 单练 default has real training volume: timed 60 s per side (60 s when
///   unsided), counted 10 reps per side; 保持 / 呼吸 / 带停留 rhythms are
///   timed. Sets default 1, 1–3.
/// * Custom group steps start from the action kit's `training.defaults`;
///   reps 1…2× default, seconds ½…2× default in 5 s steps (min 10 s),
///   sets 1–3.
/// * The single-practice steppers use the same rule around their own
///   default (reps 1–20, seconds 30–120).
///
/// The action kit stays the dose source: the voice counts by the kit's
/// cycle, the clip only demonstrates.
abstract final class DoseRules {
  static const singleSeconds = 60;
  static const singleReps = 10;
  static const maxSets = 3;

  /// Seconds between two sets of a hold (慢慢还原 → 再来一组).
  static const holdSetGap = 5;

  /// Rhythms timed in 单练 (拍板 2: 保持类 / 呼吸类按时长处理; 带停留 is a
  /// hold rhythm too).
  static bool singleTimed(ActionKit k) =>
      k.kind == ActionKind.hold ||
      k.kind == ActionKind.repBreath ||
      k.kind == ActionKind.repHold;

  static DoseUnit unit(ActionKit k, {required bool single}) =>
      (single ? singleTimed(k) : !k.kind.counted)
      ? DoseUnit.seconds
      : DoseUnit.reps;

  static LibraryDose singleDefault(ActionKit k) =>
      unit(k, single: true) == DoseUnit.seconds
      ? const LibraryDose(seconds: singleSeconds)
      : const LibraryDose(reps: singleReps);

  static LibraryDose kitDefault(ActionKit k) => k.kind.counted
      ? LibraryDose(reps: k.defaultReps ?? 1)
      : LibraryDose(seconds: k.defaultSeconds ?? 30);

  static DoseRange repRange(int base) => DoseRange(1, 2 * base, 1, base);

  static DoseRange secondRange(int base) => DoseRange(
    math.max(10, (base / 2 / 5).round() * 5),
    math.max(10, base * 2),
    5,
    base,
  );

  static DoseRange range(ActionKit k, {required bool single}) {
    final d = single ? singleDefault(k) : kitDefault(k);
    return unit(k, single: single) == DoseUnit.reps
        ? repRange(d.reps!)
        : secondRange(d.seconds!);
  }

  static const setRange = DoseRange(1, maxSets, 1, 1);

  /// The one value the stepper shows for [d].
  static int value(ActionKit k, LibraryDose d, {required bool single}) {
    final base = single ? singleDefault(k) : kitDefault(k);
    return unit(k, single: single) == DoseUnit.reps
        ? (d.reps ?? base.reps!)
        : (d.seconds ?? base.seconds!);
  }

  /// [d] brought inside the allowed ranges (unknown values → default).
  static LibraryDose clamp(ActionKit k, LibraryDose d, {required bool single}) {
    final r = range(k, single: single);
    final v = r.clamp(value(k, d, single: single));
    final sets = setRange.clamp(d.sets);
    int? within(int? x, int max) =>
        x == null || x < 1 ? null : math.min(x, max);
    return unit(k, single: single) == DoseUnit.reps
        ? LibraryDose(
            reps: v,
            sets: sets,
            holdSeconds: k.kind == ActionKind.repHold
                ? within(d.holdSeconds, LibraryDose.maxHold)
                : null,
            paceSeconds: within(d.paceSeconds, LibraryDose.maxPace),
          )
        : LibraryDose(seconds: v, sets: sets);
  }

  /// The kit dose the player and the voice run on.
  static KitDose kitDose(ActionKit k, LibraryDose d, {required bool single}) {
    final v = value(k, d, single: single);
    if (unit(k, single: single) == DoseUnit.reps) {
      return KitDose(reps: v, holdSeconds: d.holdSeconds);
    }
    if (!k.kind.counted) return KitDose(seconds: v);
    // A timed counted rhythm (单练 呼吸 / 带停留): as many full reps as fit.
    final cycle = k.cycleFor(const KitDose());
    final reps = cycle <= 0 ? 1 : math.max(1, ((v - k.lead) / cycle).floor());
    return KitDose(reps: reps);
  }

  /// Seconds of one set on one side.
  static int setSeconds(ActionKit k, LibraryDose d, {required bool single}) {
    final kd = kitDose(k, d, single: single);
    final budget = unit(k, single: single) == DoseUnit.seconds
        ? value(k, d, single: single)
        : (d.paceSeconds ?? 0);
    return k.sideSeconds(kd, budget);
  }

  /// Seconds of one side with every set (holds rest [holdSetGap] between).
  static int sideSeconds(ActionKit k, LibraryDose d, {required bool single}) {
    final per = setSeconds(k, d, single: single);
    final n = math.max(1, d.sets);
    return n * per + (k.kind.counted ? 0 : (n - 1) * holdSetGap);
  }

  /// Work seconds of the step (both sides, all sets) – PlanStep.seconds
  /// without a tight-side extra set.
  static int stepSeconds(ActionKit k, LibraryDose d, {required bool single}) =>
      sideSeconds(k, d, single: single) * (k.sided ? 2 : 1);

  /// The extra set on the tight side (assessment asymmetry): one set of one
  /// side, plus the hold gap in front of it.
  static int extraSetSeconds(
    ActionKit k,
    LibraryDose d, {
    required bool single,
  }) =>
      setSeconds(k, d, single: single) +
      (k.kind.counted || d.sets <= 1 ? 0 : holdSetGap);
}

/// Short dose text for cards, rows and the player ("每侧 60 秒 × 2 组").
String doseText(
  ActionKit k,
  LibraryDose d, {
  required bool single,
  String lang = 'zh',
}) {
  final en = lang == 'en';
  final v = DoseRules.value(k, d, single: single);
  final timed = DoseRules.unit(k, single: single) == DoseUnit.seconds;
  final String base;
  if (timed) {
    base = en
        ? (k.sided ? '${v}s each side' : '${v}s')
        : (k.sided ? '每侧 $v 秒' : (k.kind.counted ? '$v 秒' : '停 $v 秒'));
  } else {
    final hold = d.holdSeconds ?? k.defaultHold;
    base = switch (k.kind) {
      ActionKind.repHold =>
        en
            ? '$v × ${hold}s hold${k.sided ? ' each side' : ''}'
            : '${k.sided ? '每侧 ' : ''}$v 次 × 停 $hold 秒',
      ActionKind.repCycle =>
        en
            ? '$v circles${k.sided ? ' each side' : ''}'
            : '${k.sided ? '每侧 ' : ''}$v 圈',
      ActionKind.repBreath => en ? '$v slow breaths' : '慢呼吸 $v 次',
      ActionKind.repAlternate =>
        en
            ? (k.sided ? '$v each side' : '$v alternating')
            : (k.sided ? '每侧 $v 次' : '左右交替 $v 次'),
      _ =>
        en
            ? '$v reps${k.sided ? ' each side' : ''}'
            : '${k.sided ? '每侧 ' : ''}$v 次',
    };
  }
  if (d.sets <= 1) return base;
  return en ? '$base × ${d.sets} sets' : '$base × ${d.sets} 组';
}

// ───────────────────────── custom_routines v1 ─────────────────────────

/// One step of a custom training group. Only what differs from the action
/// kit default is stored; null means "the kit's default" so a later change
/// of the kit's default carries over.
class CustomStep {
  const CustomStep(
    this.kitId, {
    this.reps,
    this.seconds,
    this.sets,
    this.holdSeconds,
    this.paceSeconds,
  });
  final String kitId;
  final int? reps;
  final int? seconds;
  final int? sets;

  /// Hold of a 带停留 rep when it differs from the kit (copied routine
  /// step, e.g. F's h-sumo-pry 15 s). Optional in v1; null = kit default.
  final int? holdSeconds;

  /// A copied routine step's seconds per side (its rep pace). Optional in
  /// v1; null = the kit's own pace.
  final int? paceSeconds;

  bool get adjusted =>
      reps != null ||
      seconds != null ||
      (sets ?? 1) != 1 ||
      holdSeconds != null ||
      paceSeconds != null;

  LibraryDose dose(ActionKit k) => LibraryDose(
    reps: k.kind.counted ? (reps ?? k.defaultReps ?? 1) : null,
    seconds: k.kind.counted ? null : (seconds ?? k.defaultSeconds ?? 30),
    sets: sets ?? 1,
    holdSeconds: k.kind.counted ? holdSeconds : null,
    paceSeconds: k.kind.counted ? paceSeconds : null,
  );

  /// The step for [d], storing only what differs from the kit default.
  factory CustomStep.fromDose(ActionKit k, LibraryDose d) {
    final c = DoseRules.clamp(k, d, single: false);
    return CustomStep(
      k.id,
      reps: k.kind.counted && c.reps != k.defaultReps ? c.reps : null,
      seconds: !k.kind.counted && c.seconds != k.defaultSeconds
          ? c.seconds
          : null,
      sets: c.sets != 1 ? c.sets : null,
      holdSeconds: c.holdSeconds != k.defaultHold ? c.holdSeconds : null,
      paceSeconds: c.paceSeconds,
    );
  }

  Map<String, Object?> toJson() => {
    'kitId': kitId,
    'reps': ?reps,
    'seconds': ?seconds,
    if (sets != null && sets != 1) 'sets': sets,
    'holdSeconds': ?holdSeconds,
    'paceSeconds': ?paceSeconds,
  };

  @override
  bool operator ==(Object other) =>
      other is CustomStep &&
      other.kitId == kitId &&
      other.reps == reps &&
      other.seconds == seconds &&
      (other.sets ?? 1) == (sets ?? 1) &&
      other.holdSeconds == holdSeconds &&
      other.paceSeconds == paceSeconds;

  @override
  int get hashCode =>
      Object.hash(kitId, reps, seconds, sets ?? 1, holdSeconds, paceSeconds);
}

class CustomRoutine {
  const CustomRoutine({
    required this.id,
    required this.name,
    required this.steps,
    this.restSeconds = 15,
    this.fromRoutine,
    this.createdAt,
    this.updatedAt,
    this.removed = 0,
  });

  final String id;
  final String name;
  final int restSeconds;
  final List<CustomStep> steps;

  /// Built-in routine id when copied (「复制成我的训练组」).
  final String? fromRoutine;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Steps dropped on load because their drill left the library (内容包更新
  /// 后下架); shown as 「N 个动作已下架」. Not stored.
  final int removed;

  static const maxSteps = 20;
  static const maxName = 12;
  static const rests = [10, 15, 20, 30];
  static const defaultRest = 15;

  CustomRoutine copyWith({
    String? name,
    int? restSeconds,
    List<CustomStep>? steps,
    DateTime? updatedAt,
    int? removed,
  }) => CustomRoutine(
    id: id,
    name: name ?? this.name,
    restSeconds: restSeconds ?? this.restSeconds,
    steps: steps ?? this.steps,
    fromRoutine: fromRoutine,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    removed: removed ?? this.removed,
  );

  /// Same as TrainingPlan.seconds: work plus rests between drills (no
  /// prep, no side switch).
  int seconds(HipContent c) {
    var s = 0;
    var n = 0;
    for (final st in steps) {
      final k = c.kit(st.kitId);
      if (k == null) continue;
      s += DoseRules.stepSeconds(k, st.dose(k), single: false);
      n++;
    }
    return s + restSeconds * math.max(0, n - 1);
  }

  /// Name trimmed and cut to [maxName] characters (runes, so 中文 counts 1).
  static String cleanName(String name) {
    final t = name.trim();
    final r = t.runes.toList();
    return r.length <= maxName ? t : String.fromCharCodes(r.take(maxName));
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'restSeconds': restSeconds,
    'fromRoutine': fromRoutine,
    'createdAt': ?createdAt?.toIso8601String(),
    'updatedAt': ?updatedAt?.toIso8601String(),
    'steps': [for (final s in steps) s.toJson()],
  };

  /// Reads and validates one stored group against the current content:
  /// unknown / delisted drills are dropped (counted in [removed]), doses are
  /// clamped, an unknown rest becomes 15 s, more than 20 steps are cut and
  /// the name is cut to 12 characters. Null when it cannot be read at all.
  static CustomRoutine? fromJson(Map<String, dynamic> j, HipContent c) {
    final id = j['id'];
    if (id is! String || id.isEmpty) return null;
    final rawSteps = j['steps'];
    final steps = <CustomStep>[];
    var removed = 0;
    for (final s in rawSteps is List ? rawSteps : const []) {
      if (s is! Map) {
        removed++;
        continue;
      }
      final kitId = s['kitId'];
      if (kitId is! String || !inLibrary(c, kitId)) {
        removed++;
        continue;
      }
      final k = c.kit(kitId)!;
      int? asInt(Object? v) => v is num ? v.round() : null;
      final stored = CustomStep(
        kitId,
        reps: asInt(s['reps']),
        seconds: asInt(s['seconds']),
        sets: asInt(s['sets']),
        holdSeconds: asInt(s['holdSeconds']),
        paceSeconds: asInt(s['paceSeconds']),
      );
      steps.add(CustomStep.fromDose(k, stored.dose(k)));
    }
    final rest = j['restSeconds'];
    DateTime? at(Object? v) => v is String ? DateTime.tryParse(v) : null;
    final name = j['name'] is String ? cleanName(j['name'] as String) : '';
    return CustomRoutine(
      id: id,
      name: name.isEmpty ? '我的训练组' : name,
      restSeconds: rests.contains(rest) ? rest as int : defaultRest,
      steps: steps.length > maxSteps ? steps.sublist(0, maxSteps) : steps,
      fromRoutine: j['fromRoutine'] is String
          ? j['fromRoutine'] as String
          : null,
      createdAt: at(j['createdAt']),
      updatedAt: at(j['updatedAt']),
      removed: removed,
    );
  }
}

/// `customRoutines` block of the stored state (version 1).
abstract final class CustomRoutinesCodec {
  static const version = 1;

  static Map<String, Object?> encode(List<CustomRoutine> items) => {
    'v': version,
    'items': [for (final r in items) r.toJson()],
  };

  /// Unknown versions and unreadable items are skipped, never thrown.
  static List<CustomRoutine> decode(Object? j, HipContent c) {
    if (j is! Map || j['v'] != version) return [];
    final items = j['items'];
    if (items is! List) return [];
    final out = <CustomRoutine>[];
    final ids = <String>{};
    for (final it in items) {
      if (it is! Map) continue;
      final r = CustomRoutine.fromJson(Map<String, dynamic>.from(it), c);
      if (r != null && ids.add(r.id)) out.add(r);
    }
    return out;
  }
}

/// Builds a custom group from a built-in routine, step by step as authored
/// (no level swap baked in: the swap is redone at play time, so a later
/// level-up gets the advanced drills back). Steps outside the library are
/// left out.
CustomRoutine copyRoutine(
  HipRoutine r,
  HipContent c, {
  required String id,
  required String name,
  required DateTime at,
}) {
  final steps = <CustomStep>[];
  for (final s in r.steps) {
    final k = c.kit(s.drillId);
    if (k == null || !inLibrary(c, s.drillId)) continue;
    // Counted: the authored reps, hold override and pace (the routine's
    // seconds per side) so the copy plays as long as the routine (F2).
    final LibraryDose d;
    if (k.kind.counted) {
      final reps = s.kit.reps ?? k.defaultReps;
      final pace = s.seconds ~/ (s.sided ? 2 : 1);
      final own = k.sideSeconds(
        KitDose(reps: reps, holdSeconds: s.kit.holdSeconds),
        0,
      );
      d = LibraryDose(
        reps: reps,
        holdSeconds: s.kit.holdSeconds,
        paceSeconds: pace > own ? pace : null,
      );
    } else {
      d = LibraryDose(seconds: s.kit.seconds ?? k.defaultSeconds);
    }
    steps.add(CustomStep.fromDose(k, d));
  }
  return CustomRoutine(
    id: id,
    name: CustomRoutine.cleanName(name),
    steps: steps.length > CustomRoutine.maxSteps
        ? steps.sublist(0, CustomRoutine.maxSteps)
        : steps,
    fromRoutine: r.id,
    createdAt: at,
    updatedAt: at,
  );
}

// ───────────────────────── practice history ─────────────────────────

/// Where a session came from.
enum PlanSource {
  recommended('recommended'),
  routine('routine'),
  custom('custom'),
  single('single');

  const PlanSource(this.id);
  final String id;
  static PlanSource byId(Object? id) =>
      values.firstWhere((s) => s.id == id, orElse: () => recommended);

  /// 单练 never counts for the streak (拍板 3); the rest do.
  bool get countsForStreak => this != single;
}

/// One practice session in the history (进度 · 最近练习).
class SessionRecord {
  const SessionRecord({
    required this.at,
    required this.source,
    required this.title,
    required this.seconds,
    required this.completed,
    this.refId,
  });
  final DateTime at;
  final PlanSource source;
  final String? refId;
  final String title;
  final int seconds;
  final bool completed;

  static const keep = 365;

  Map<String, Object?> toJson() => {
    'at': at.toIso8601String(),
    'source': source.id,
    'refId': refId,
    'title': title,
    'seconds': seconds,
    'completed': completed,
  };

  static SessionRecord? fromJson(Object? j) {
    if (j is! Map) return null;
    final at = j['at'] is String ? DateTime.tryParse(j['at'] as String) : null;
    if (at == null) return null;
    return SessionRecord(
      at: at,
      source: PlanSource.byId(j['source']),
      refId: j['refId'] as String?,
      title: (j['title'] as String?) ?? '',
      seconds: (j['seconds'] as num?)?.round() ?? 0,
      completed: j['completed'] == true,
    );
  }
}
