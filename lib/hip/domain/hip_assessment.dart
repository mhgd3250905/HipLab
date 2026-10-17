import 'hip_models.dart';

/// One side (or the only side) of one assessment item.
class SideAnswer {
  const SideAnswer.choice(int this.score, {this.followUp})
    : pain = false,
      skipped = false;
  const SideAnswer.pain()
    : score = null,
      followUp = null,
      pain = true,
      skipped = false;
  const SideAnswer.skipped()
    : score = null,
      followUp = null,
      pain = false,
      skipped = true;

  /// 2 = 松 (A), 1 = 一般 (B), 0 = 紧 (C).
  final int? score;

  /// 90/90 only, after 紧: `front` or `back` (which knee lifts).
  final String? followUp;
  final bool pain;
  final bool skipped;

  Map<String, Object?> toJson() => {
    if (score != null) 'score': score,
    if (followUp != null) 'followUp': followUp,
    if (pain) 'pain': true,
    if (skipped) 'skipped': true,
  };

  factory SideAnswer.fromJson(Map<String, dynamic> j) {
    if (j['pain'] == true) return const SideAnswer.pain();
    if (j['skipped'] == true) return const SideAnswer.skipped();
    return SideAnswer.choice(
      j['score'] as int,
      followUp: j['followUp'] as String?,
    );
  }
}

enum HipSide { left, right }

/// The answers for one item: `single` for one-sided items, left/right otherwise.
class ItemAnswer {
  const ItemAnswer.single(SideAnswer this.single) : left = null, right = null;
  const ItemAnswer.sided({
    required SideAnswer this.left,
    required SideAnswer this.right,
  }) : single = null;
  final SideAnswer? single;
  final SideAnswer? left;
  final SideAnswer? right;

  List<SideAnswer> get sides => [?single, ?left, ?right];
  bool get pain => sides.any((s) => s.pain);
  bool get skipped => sides.any((s) => s.skipped) && !pain;

  Map<String, Object?> toJson() => {
    if (single != null) 'single': single!.toJson(),
    if (left != null) 'left': left!.toJson(),
    if (right != null) 'right': right!.toJson(),
  };

  factory ItemAnswer.fromJson(Map<String, dynamic> j) => j['single'] != null
      ? ItemAnswer.single(
          SideAnswer.fromJson(Map<String, dynamic>.from(j['single'] as Map)),
        )
      : ItemAnswer.sided(
          left: SideAnswer.fromJson(
            Map<String, dynamic>.from(j['left'] as Map),
          ),
          right: SideAnswer.fromJson(
            Map<String, dynamic>.from(j['right'] as Map),
          ),
        );
}

class ItemScore {
  const ItemScore({
    required this.score,
    required this.parts,
    required this.pain,
    required this.skipped,
    this.tightSide,
  });

  /// 0–2, counted in the 0–12 total. Pain counts as 0.
  final int score;

  /// `score`, plus `front` / `back` for 90/90.
  final Map<String, int> parts;
  final bool pain;
  final bool skipped;

  /// Set when left and right differ by ≥ 1 grade ("左右不一样").
  final HipSide? tightSide;
}

class AssessmentResult {
  const AssessmentResult({
    required this.items,
    required this.directionScores,
    required this.radar,
    required this.total,
    required this.level,
    required this.painDirections,
    required this.untestedDirections,
    required this.asymmetry,
    required this.lowest,
    required this.tightest,
    required this.best,
    required this.route,
    required this.dancerUnlocked,
  });

  final Map<String, ItemScore> items;

  /// Weighted 0–2 per direction.
  final Map<HipDirection, double> directionScores;

  /// 25 / 60 / 90 radar values (100 is left for retest progress).
  final Map<HipDirection, double> radar;
  final int total;
  final LevelBand level;

  /// "先别练这里": locked to L1 relax-only until the item is retested pain-free.
  final Set<HipDirection> painDirections;
  final Set<HipDirection> untestedDirections;

  /// Direction → the tighter side, for "紧的一侧多做一组".
  final Map<HipDirection, HipSide> asymmetry;

  /// The focus direction (lowest non-painful, ties broken by priority).
  final HipDirection? lowest;

  /// Up to two lowest directions for the result chips.
  final List<HipDirection> tightest;
  final HipDirection? best;
  final RouteSuggestion? route;
  final bool dancerUnlocked;
}

/// 自测设计.md §3. Pure function of rules + answers + identity.
class HipAssessmentScorer {
  const HipAssessmentScorer(this.rules);
  final AssessmentRules rules;

  static const _eps = 1e-6;

  ItemScore scoreItem(AssessmentItem item, ItemAnswer answer) {
    final has9090 = item.followUp.isNotEmpty;
    Map<String, int> partsOf(SideAnswer s) {
      if (s.pain) {
        return {'score': 0, if (has9090) 'front': 0, if (has9090) 'back': 0};
      }
      final v = s.skipped ? rules.skipScore : s.score!;
      if (!has9090) return {'score': v};
      if (s.skipped || v > 0) return {'score': v, 'front': v, 'back': v};
      final f = item.followUp.where((o) => o.id == s.followUp).firstOrNull;
      // 紧 without saying which knee: count both as tight (conservative).
      return {'score': 0, 'front': f?.front ?? 0, 'back': f?.back ?? 0};
    }

    final sides = answer.sides;
    final parts = <String, int>{};
    for (final s in sides) {
      partsOf(s).forEach(
        (k, v) => parts[k] = parts.containsKey(k)
            ? (v < parts[k]! ? v : parts[k]!)
            : v,
      );
    }
    HipSide? tight;
    if (answer.left != null &&
        answer.right != null &&
        !answer.pain &&
        !answer.skipped) {
      final l = answer.left!.score!, r = answer.right!.score!;
      if ((l - r).abs() >= 1) tight = l < r ? HipSide.left : HipSide.right;
    }
    return ItemScore(
      score: parts['score']!,
      parts: parts,
      pain: answer.pain,
      skipped: answer.skipped,
      tightSide: tight,
    );
  }

  double radarValue(double score) {
    final m = rules.radarMap;
    if (score <= 0) return m[0]!;
    if (score >= 2) return m[2]!;
    final lo = score.floor(), hi = lo + 1;
    return m[lo]! + (m[hi]! - m[lo]!) * (score - lo);
  }

  LevelBand levelFor(int total) => rules.levels.firstWhere(
    (b) => total >= b.min && total <= b.max,
    orElse: () => rules.levels.first,
  );

  AssessmentResult score(
    Map<String, ItemAnswer> answers,
    HipIdentity identity,
  ) {
    final items = <String, ItemScore>{};
    for (final item in rules.items) {
      final a =
          answers[item.id] ??
          (item.sided
              ? const ItemAnswer.sided(
                  left: SideAnswer.skipped(),
                  right: SideAnswer.skipped(),
                )
              : const ItemAnswer.single(SideAnswer.skipped()));
      items[item.id] = scoreItem(item, a);
    }
    final pain = <HipDirection>{};
    final untested = <HipDirection>{};
    final asym = <HipDirection, HipSide>{};
    for (final item in rules.items) {
      final s = items[item.id]!;
      if (s.pain) pain.addAll(item.directions);
      if (s.skipped) untested.addAll(item.directions);
      if (s.tightSide != null) {
        for (final d in item.directions) {
          asym.putIfAbsent(d, () => s.tightSide!);
        }
      }
    }
    final scores = <HipDirection, double>{
      for (final d in HipDirection.values)
        d: rules.weights[d]!.fold(
          0.0,
          (sum, t) => sum + t.weight * items[t.item]!.parts[t.part]!,
        ),
    };
    final total = items.values.fold(0, (sum, s) => sum + s.score);
    final candidates = HipDirection.values
        .where((d) => !pain.contains(d))
        .toList();
    int byPriority(HipDirection a, HipDirection b) =>
        rules.tiePriority.indexOf(a).compareTo(rules.tiePriority.indexOf(b));
    final ascending = [...candidates]
      ..sort((a, b) {
        final c = scores[a]! - scores[b]!;
        return c.abs() < _eps ? byPriority(a, b) : c.sign.toInt();
      });
    final lowest = ascending.firstOrNull;
    final tightest = <HipDirection>[
      for (final d in ascending.take(2))
        if (lowest != null && (scores[d]! - scores[lowest]!).abs() < _eps) d,
    ];
    final best = ascending.isEmpty || ascending.length < 2
        ? null
        : ascending.last;
    final key = identity == HipIdentity.dancer ? 'dancer' : 'office';
    return AssessmentResult(
      items: items,
      directionScores: scores,
      radar: {for (final e in scores.entries) e.key: radarValue(e.value)},
      total: total,
      level: levelFor(total),
      painDirections: pain,
      untestedDirections: untested,
      asymmetry: asym,
      lowest: lowest,
      tightest: tightest,
      best:
          best != null &&
              lowest != null &&
              scores[best]! > scores[lowest]! + _eps
          ? best
          : null,
      route: lowest == null ? null : rules.recommendations[key]![lowest],
      dancerUnlocked:
          identity == HipIdentity.dancer && total >= rules.dancerUnlockTotal,
    );
  }
}
