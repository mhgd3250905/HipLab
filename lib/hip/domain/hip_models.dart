/// HipLab content models. Pure data, no Flutter imports, so the scoring,
/// recommendation and pain rules can be unit-tested without widgets.
library;

enum HipDirection {
  flexion('flexion', '屈'),
  extension('extension', '伸'),
  abduction('abduction', '外展'),
  adduction('adduction', '内收'),
  internalRotation('internal_rotation', '内旋'),
  externalRotation('external_rotation', '外旋');

  const HipDirection(this.id, this.zh);
  final String id;
  final String zh;

  static HipDirection byId(String id) => values.firstWhere(
    (d) => d.id == id,
    orElse: () => throw FormatException('direction $id'),
  );
}

enum HipMethod {
  relax('relax', '放松'),
  flexibility('flexibility', '柔韧'),
  control('control', '主动控制'),
  strength('strength', '力量');

  const HipMethod(this.id, this.zh);
  final String id;
  final String zh;
  static HipMethod byId(String id) => values.firstWhere((m) => m.id == id);
}

/// MVP scenes. The gym scene is hidden until phase 2 (开哥 2026-10-16).
enum HipScene {
  chair('chair', '办公椅'),
  home('home', '居家');

  const HipScene(this.id, this.zh);
  final String id;
  final String zh;
  static HipScene byId(String id) => values.firstWhere((s) => s.id == id);
}

/// Who the user said they are on first launch (3 picture cards).
enum HipIdentity {
  office('office', '坐办公室的人'),
  dancer('dancer', '跳舞的人'),
  other('other', '都不是');

  const HipIdentity(this.id, this.zh);
  final String id;
  final String zh;
  static HipIdentity byId(String id) =>
      values.firstWhere((s) => s.id == id, orElse: () => HipIdentity.other);
}

enum HipMediaStatus { video, poster, pending }

class HipDrill {
  const HipDrill({
    required this.id,
    required this.name,
    required this.directions,
    required this.methods,
    required this.scenes,
    required this.advanced,
    required this.mvp,
    required this.cautions,
    required this.mediaStatus,
    this.video,
    this.poster,
    this.duration,
    this.posterTime = 0,
    this.alternative,
    this.note = '',
  });

  final String id;
  final String name;
  final List<HipDirection> directions;
  final List<HipMethod> methods;
  final List<HipScene> scenes;
  final bool advanced;
  final bool mvp;
  final List<String> cautions;
  final HipMediaStatus mediaStatus;
  final String? video;
  final String? poster;

  /// Loop length of [video] in seconds, from the content pack; null when the
  /// drill has no video yet.
  final double? duration;
  final double posterTime;
  final String? alternative;
  final String note;

  bool get isRelax => methods.contains(HipMethod.relax);

  factory HipDrill.fromJson(Map<String, dynamic> j) {
    final media = Map<String, dynamic>.from(j['media'] as Map);
    return HipDrill(
      id: j['id'] as String,
      name: j['name'] as String,
      directions: [
        for (final d in j['directions'] as List) HipDirection.byId(d as String),
      ],
      methods: [
        for (final m in j['methods'] as List) HipMethod.byId(m as String),
      ],
      scenes: [for (final s in j['scenes'] as List) HipScene.byId(s as String)],
      advanced: j['level'] == 'advanced',
      mvp: j['mvp'] == true,
      cautions: [for (final c in j['cautions'] as List) c as String],
      mediaStatus: HipMediaStatus.values.byName(media['status'] as String),
      video: media['video'] as String?,
      poster: media['poster'] as String?,
      duration: (media['duration_seconds'] as num?)?.toDouble(),
      posterTime: (media['poster_time_seconds'] as num? ?? 0).toDouble(),
      alternative: j['alternative'] as String?,
      note: (j['note'] as String?) ?? '',
    );
  }
}

class HipRoutineStep {
  const HipRoutineStep({
    required this.drillId,
    required this.dose,
    required this.seconds,
    required this.sided,
    this.alternative,
    this.tip = '',
  });
  final String drillId;
  final String dose;
  final int seconds;
  final bool sided;
  final String? alternative;
  final String tip;

  factory HipRoutineStep.fromJson(Map<String, dynamic> j) => HipRoutineStep(
    drillId: j['drill'] as String,
    dose: j['dose'] as String,
    seconds: j['seconds'] as int,
    sided: j['sided'] == true,
    alternative: j['alternative'] as String?,
    tip: (j['tip'] as String?) ?? '',
  );
}

class HipRoutine {
  const HipRoutine({
    required this.id,
    required this.name,
    required this.audience,
    required this.scene,
    required this.seconds,
    required this.steps,
    this.micro = false,
  });
  final String id;
  final String name;
  final String audience;
  final HipScene scene;
  final int seconds;
  final List<HipRoutineStep> steps;

  /// The 2-minute reminder routine (套 M); never offered as "today's training".
  final bool micro;

  int get minutes => (seconds / 60).round();

  factory HipRoutine.fromJson(Map<String, dynamic> j) => HipRoutine(
    id: j['id'] as String,
    name: j['name'] as String,
    audience: (j['audience'] as String?) ?? '',
    scene: HipScene.byId(j['scene'] as String),
    seconds: j['seconds'] as int,
    steps: [
      for (final s in j['steps'] as List)
        HipRoutineStep.fromJson(Map<String, dynamic>.from(s as Map)),
    ],
    micro: j['kind'] == 'micro',
  );
}

class AssessmentOption {
  const AssessmentOption({
    required this.score,
    required this.label,
    required this.description,
    this.image,
  });
  final int score;
  final String label;
  final String description;
  final String? image;
}

class AssessmentFollowUpOption {
  const AssessmentFollowUpOption({
    required this.id,
    required this.label,
    required this.front,
    required this.back,
    this.image,
  });
  final String id;
  final String label;
  final int front;
  final int back;
  final String? image;
}

class AssessmentItem {
  const AssessmentItem({
    required this.id,
    required this.order,
    required this.title,
    required this.question,
    required this.cue,
    required this.demoDrill,
    required this.seconds,
    required this.sided,
    required this.directions,
    required this.options,
    this.followUpQuestion,
    this.followUp = const [],
    this.dancerNote,
    this.demoMedia,
    this.aka,
    this.area = '',
  });
  final String id;
  final int order;
  final String title;
  final String question;
  final String cue;
  final String demoDrill;
  final int seconds;
  final bool sided;
  final List<HipDirection> directions;

  /// Displayed left→right as in the prototype: 紧 · 一般 · 松.
  final List<AssessmentOption> options;
  final String? followUpQuestion;
  final List<AssessmentFollowUpOption> followUp;
  final String? dancerNote;

  /// Clinical / alternative name shown under the plain title (屈髋肌测试 →
  /// "又称托马斯测试（Thomas test）…").
  final String? aka;

  /// Body area the item looks at (content key `glow`), e.g. 髋前侧.
  final String area;

  /// Optional demo clip of its own (e.g. the cross-over part of
  /// n-leg-circles); otherwise the demo is [demoDrill]'s loop.
  final HipDrill? demoMedia;

  /// The art to loop above the options: [demoMedia] when present.
  HipDrill? demoArt(Map<String, HipDrill> drills) =>
      demoMedia ?? drills[demoDrill];

  factory AssessmentItem.fromJson(Map<String, dynamic> j) {
    final follow = j['follow_up'] as Map?;
    return AssessmentItem(
      id: j['id'] as String,
      order: j['order'] as int,
      title: j['title'] as String,
      question: j['question'] as String,
      cue: j['cue'] as String,
      demoDrill: j['demo_drill'] as String,
      seconds: j['seconds'] as int,
      sided: j['sided'] == true,
      directions: [
        for (final d in j['directions'] as List) HipDirection.byId(d as String),
      ],
      options: [
        for (final o in j['options'] as List)
          AssessmentOption(
            score: (o as Map)['score'] as int,
            label: o['label'] as String,
            description: o['description'] as String,
            image: o['image'] as String?,
          ),
      ],
      followUpQuestion: follow?['question'] as String?,
      followUp: [
        if (follow != null)
          for (final o in follow['options'] as List)
            AssessmentFollowUpOption(
              id: (o as Map)['id'] as String,
              label: o['label'] as String,
              front: o['front'] as int,
              back: o['back'] as int,
              image: o['image'] as String?,
            ),
      ],
      dancerNote: j['note_for_dancer'] as String?,
      aka: j['aka'] as String?,
      area: j['glow'] as String? ?? '',
      demoMedia: j['demo_media'] == null
          ? null
          : HipDrill.fromJson(
              Map<String, dynamic>.from(j['demo_media'] as Map),
            ),
    );
  }
}

class WeightTerm {
  const WeightTerm(this.item, this.part, this.weight);
  final String item;

  /// `score` for the item's own score; `front` / `back` for 90/90 sub-scores.
  final String part;
  final double weight;
}

class LevelBand {
  const LevelBand(this.level, this.name, this.min, this.max, this.mix);
  final int level;
  final String name;
  final int min;
  final int max;
  final Map<HipMethod, int> mix;
}

class RouteSuggestion {
  const RouteSuggestion(this.route, this.routineId);
  final String route;
  final String routineId;
}

class AssessmentRules {
  const AssessmentRules({
    required this.items,
    required this.weights,
    required this.radarMap,
    required this.skipScore,
    required this.levels,
    required this.dancerUnlockTotal,
    required this.tiePriority,
    required this.recommendations,
  });
  final List<AssessmentItem> items;
  final Map<HipDirection, List<WeightTerm>> weights;
  final Map<int, double> radarMap;
  final int skipScore;
  final List<LevelBand> levels;
  final int dancerUnlockTotal;
  final List<HipDirection> tiePriority;

  /// `office` (also used for `other`) and `dancer`.
  final Map<String, Map<HipDirection, RouteSuggestion>> recommendations;

  factory AssessmentRules.fromJson(Map<String, dynamic> j) {
    final weights = Map<String, dynamic>.from(j['weights'] as Map);
    final recs = Map<String, dynamic>.from(j['recommendations'] as Map);
    return AssessmentRules(
      items: [
        for (final i in j['items'] as List)
          AssessmentItem.fromJson(Map<String, dynamic>.from(i as Map)),
      ]..sort((a, b) => a.order.compareTo(b.order)),
      weights: {
        for (final e in weights.entries)
          HipDirection.byId(e.key): [
            for (final t in e.value as List)
              WeightTerm(
                (t as List)[0] as String,
                t[1] as String,
                (t[2] as num).toDouble(),
              ),
          ],
      },
      radarMap: {
        for (final e in Map<String, dynamic>.from(
          j['radar_map'] as Map,
        ).entries)
          int.parse(e.key): (e.value as num).toDouble(),
      },
      skipScore: j['skip_score'] as int,
      levels: [
        for (final b in j['level_bands'] as List)
          LevelBand(
            (b as Map)['level'] as int,
            b['name'] as String,
            b['min'] as int,
            b['max'] as int,
            {
              for (final e in Map<String, dynamic>.from(
                b['mix'] as Map,
              ).entries)
                HipMethod.byId(e.key): e.value as int,
            },
          ),
      ],
      dancerUnlockTotal: j['dancer_unlock_total'] as int,
      tiePriority: [
        for (final d in j['tie_priority'] as List)
          HipDirection.byId(d as String),
      ],
      recommendations: {
        for (final e in recs.entries)
          e.key: {
            for (final r in Map<String, dynamic>.from(e.value as Map).entries)
              HipDirection.byId(r.key): RouteSuggestion(
                (r.value as Map)['route'] as String,
                r.value['routine'] as String,
              ),
          },
      },
    );
  }
}

class SafetyCard {
  const SafetyCard(this.id, this.title, this.icon);
  final String id;
  final String title;
  final String icon;
}

class HipContent {
  HipContent({
    required List<HipDrill> drills,
    required this.routines,
    required this.rules,
    required this.safetyCards,
  }) : drills = {for (final d in drills) d.id: d};

  final Map<String, HipDrill> drills;
  final List<HipRoutine> routines;
  final AssessmentRules rules;
  final List<SafetyCard> safetyCards;

  HipRoutine routine(String id) => routines.firstWhere((r) => r.id == id);
  HipDrill drill(String id) =>
      drills[id] ?? (throw StateError('unknown drill $id'));
  Iterable<HipDrill> get mvpDrills => drills.values.where((d) => d.mvp);

  factory HipContent.fromJson(Map<String, dynamic> j) {
    if (j['schema_version'] != 1) {
      throw const FormatException('hip content schema');
    }
    final content = HipContent(
      drills: [
        for (final d in j['drills'] as List)
          HipDrill.fromJson(Map<String, dynamic>.from(d as Map)),
      ],
      routines: [
        for (final r in j['routines'] as List)
          HipRoutine.fromJson(Map<String, dynamic>.from(r as Map)),
      ],
      rules: AssessmentRules.fromJson(
        Map<String, dynamic>.from(j['assessment'] as Map),
      ),
      safetyCards: [
        for (final c in j['safety_cards'] as List)
          SafetyCard(
            (c as Map)['id'] as String,
            c['title'] as String,
            c['icon'] as String,
          ),
      ],
    );
    // Every referenced drill must exist so the player never hits a hole.
    for (final r in content.routines) {
      for (final s in r.steps) {
        content.drill(s.drillId);
        if (s.alternative != null) content.drill(s.alternative!);
      }
    }
    return content;
  }
}
