// UI r2 M3 (#4 #5 #6): one action list for 动作库 and 添加动作 and one filter
// for both. Data = the SDK scope HipLab exposes (the same ids the SDK library
// listed: content.publicCatalog ∩ the HipLab scope), plus any HipLab drill
// outside it, deduped by id. Facets come from the public definition; nothing
// unreleased is added.
import 'package:flutter/material.dart';
import 'package:ugk_trainer_runtime/ugk_trainer_runtime.dart' as trainer;

import '../../data/hip_action_scope.dart';
import '../../data/hip_public_media.dart';
import '../../data/hip_shared_library.dart';
import '../../domain/hip_library.dart';
import '../../domain/hip_models.dart';
import '../hip_icons.dart';
import '../hip_theme.dart';
import '../hip_widgets.dart';
import 'lib_text.dart';
import 'library_widgets.dart';

String _z(LibText t, String zh, String en) => t.lang == 'en' ? en : zh;

// ───────────────────────── facets ─────────────────────────

/// HipLab body-part words for the SDK muscle groups (hip words first).
const hipPartOf = <String, String>{
  'glute-max': '臀部',
  'hamstrings': '大腿后侧',
  'hip-flexors': '髋前侧',
  'adductors': '大腿内侧',
  'hip-abductors': '髋外侧',
  'quadriceps': '大腿前侧',
  'calves': '小腿',
  'tibialis': '小腿',
  'abs': '核心',
  'obliques': '核心',
  'lats': '背',
  'erectors': '背',
  'scapular': '背',
  'deltoids': '肩',
  'rotator-cuff': '肩',
  'serratus': '肩',
  'chest': '胸',
  'biceps': '手臂',
  'triceps': '手臂',
  'forearms': '手臂',
};

/// Display order of body parts (quick chips take the first ones present).
const hipPartOrder = [
  '臀部',
  '大腿后侧',
  '髋前侧',
  '大腿内侧',
  '髋外侧',
  '大腿前侧',
  '小腿',
  '核心',
  '背',
  '肩',
  '胸',
  '手臂',
];

/// HipLab direction → the body part word its 看放松 jump filters to.
String? hipPartForDirection(HipDirection d) => switch (d) {
  HipDirection.flexion => '大腿后侧',
  HipDirection.extension => '髋前侧',
  HipDirection.abduction => '大腿内侧',
  HipDirection.adduction => '髋外侧',
  _ => null,
};

const hipBodyweight = '徒手';
const hipTypeRelax = '拉伸放松';
const hipTypeStrength = '力量';
const hipPlaceOrder = ['椅子可做', '居家', '办公室', '健身房'];

/// One action as both pages show and filter it.
class HipActionItem {
  const HipActionItem({
    required this.id,
    required this.name,
    required this.parts,
    required this.equipment,
    required this.type,
    required this.places,
    required this.level,
    required this.dose,
    this.aliases = const [],
    this.drill,
    this.poster,
  });
  final String id;
  final String name;
  final List<String> aliases;

  /// Ordered as [hipPartOrder]; the first is the card's tag.
  final List<String> parts;

  /// Labels; empty = 徒手.
  final List<String> equipment;
  final String type;
  final Set<String> places;

  /// 1 入门 · 2 基础 · 3 进阶; null = unknown.
  final int? level;

  /// The definition's own dose ("3 组 × 每侧 8 次").
  final String dose;

  /// HipLab drill with an action kit (can join a local training group).
  final HipDrill? drill;
  final String? poster;

  bool get canAddToGroup => drill != null;
  String get tag => parts.isNotEmpty ? parts.first : type;
}

String _sdkDose(LibText t, int sets, bool reps, int? n, bool side) {
  final v = n ?? 0;
  final unit = reps ? _z(t, '次', ' reps') : _z(t, '秒', 's');
  final each = side ? _z(t, '每侧 ', ' each side') : '';
  final body = t.lang == 'en' ? '$v$unit$each' : '$each$v $unit';
  return sets > 1 ? _z(t, '$sets 组 × $body', '$sets × $body') : body;
}

/// The single list both pages use. Cached per content + language.
List<HipActionItem> hipActionItems(HipContent c, LibText t) {
  final key = (c, t.lang, HipSharedLibrary.current);
  if (identical(_cacheKey?.$1, key.$1) &&
      _cacheKey?.$2 == key.$2 &&
      identical(_cacheKey?.$3, key.$3)) {
    return _cache;
  }
  final scope =
      HipSharedLibrary.current?.allowedActionIds ??
      hiplabCoachAuthorizedActionIds;
  final out = <HipActionItem>[];
  final seen = <String>{};
  final posterRoot = HipPublicMedia.posterRoot;
  for (final d in c.publicCatalog?.drills ?? const []) {
    if (!scope.contains(d.id) || assessmentOnlyDrills.contains(d.id)) {
      continue;
    }
    if (!seen.add(d.id)) continue;
    final parts = {
      for (final m in d.muscleGroups) ?hipPartOf[m],
      if (c.drills[d.id] case final local?)
        for (final dir in local.directions) ?hipPartForDirection(dir),
    };
    final equipment = [
      for (final e in d.equipment) trainer.poseHubEquipmentLabels[e] ?? '其他器械',
    ];
    final places = <String>{
      if (d.equipment.contains('chair') || d.scenes.contains('office')) '椅子可做',
      if (d.scenes.contains('home')) '居家',
      if (d.scenes.contains('office')) '办公室',
      if (d.scenes.contains('gym')) '健身房',
    };
    final dose = d.defaultDose;
    final reps = dose.mode.name == 'reps';
    out.add(
      HipActionItem(
        id: d.id,
        name: t.lang == 'en' ? d.name.of('en') : d.name.of('zh'),
        aliases: [d.name.of('zh'), d.name.of('en')],
        parts: [
          for (final p in hipPartOrder)
            if (parts.contains(p)) p,
        ],
        equipment: equipment.toSet().toList(),
        type: switch (d.category) {
          'stretch' || 'mobility' => hipTypeRelax,
          _ => hipTypeStrength,
        },
        places: places,
        level: d.level >= 1 && d.level <= 3 ? d.level : null,
        dose: _sdkDose(
          t,
          dose.sets,
          reps,
          reps ? dose.reps : dose.seconds,
          d.unilateral,
        ),
        drill: inLibrary(c, d.id) ? c.drills[d.id] : null,
        poster: '$posterRoot${d.id}.webp',
      ),
    );
  }
  // HipLab drills outside the public catalog (old pure-data packs).
  for (final d in libraryDrills(c)) {
    if (!seen.add(d.id)) continue;
    final k = c.kit(d.id)!;
    out.add(
      HipActionItem(
        id: d.id,
        name: drillName(c, d, t.lang),
        aliases: [d.name, drillAltName(c, d, t.lang)],
        parts: [
          for (final p in hipPartOrder)
            if (d.directions.map(hipPartForDirection).contains(p)) p,
        ],
        equipment: const [],
        type: d.methods.every((m) => m == HipMethod.strength)
            ? hipTypeStrength
            : hipTypeRelax,
        places: {
          if (d.scenes.contains(HipScene.chair)) '椅子可做',
          if (d.scenes.contains(HipScene.home)) '居家',
        },
        level: d.advanced ? 3 : 1,
        dose: doseText(
          k,
          DoseRules.singleDefault(k),
          single: true,
          lang: t.lang,
        ),
        drill: d,
      ),
    );
  }
  _cacheKey = key;
  _cache = List.unmodifiable(out);
  return _cache;
}

(HipContent, String, Object?)? _cacheKey;
List<HipActionItem> _cache = const [];

// ───────────────────────── filter ─────────────────────────

/// Within a group the choices are OR, groups are AND. [parts] is shared by
/// the quick chips and the sheet's 部位 group.
class ActionFilter {
  const ActionFilter({
    this.query = '',
    this.parts = const {},
    this.equipment = const {},
    this.places = const {},
    this.types = const {},
    this.levels = const {},
  });
  final String query;
  final Set<String> parts;
  final Set<String> equipment;
  final Set<String> places;
  final Set<String> types;
  final Set<int> levels;

  /// What the 筛选 chip's badge counts (parts are visible in the row unless
  /// more than one is chosen; all sheet groups count).
  int get sheetCount =>
      parts.length +
      equipment.length +
      places.length +
      types.length +
      levels.length;
  bool get isEmpty => query.trim().isEmpty && sheetCount == 0;

  ActionFilter copyWith({
    String? query,
    Set<String>? parts,
    Set<String>? equipment,
    Set<String>? places,
    Set<String>? types,
    Set<int>? levels,
  }) => ActionFilter(
    query: query ?? this.query,
    parts: parts ?? this.parts,
    equipment: equipment ?? this.equipment,
    places: places ?? this.places,
    types: types ?? this.types,
    levels: levels ?? this.levels,
  );

  /// 重置 in the sheet: every group cleared, the search kept.
  ActionFilter get withoutSheet => ActionFilter(query: query);

  bool matches(HipActionItem a) {
    if (parts.isNotEmpty && !a.parts.any(parts.contains)) return false;
    if (equipment.isNotEmpty) {
      final own = a.equipment.isEmpty ? const [hipBodyweight] : a.equipment;
      if (!own.any(equipment.contains)) return false;
    }
    if (places.isNotEmpty && !a.places.any(places.contains)) return false;
    if (types.isNotEmpty && !types.contains(a.type)) return false;
    if (levels.isNotEmpty && !levels.contains(a.level)) return false;
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return [a.name, ...a.aliases].any((n) => n.toLowerCase().contains(q));
  }

  List<HipActionItem> apply(List<HipActionItem> all) => [
    for (final a in all)
      if (matches(a)) a,
  ];

  /// A detail page's 看放松: that direction's part, relax moves only.
  static ActionFilter fromJump(HipDirection d) => ActionFilter(
    parts: {?hipPartForDirection(d)},
    types: const {hipTypeRelax},
  );
}

/// The groups that have values in [all], in the spec order.
class ActionFacets {
  ActionFacets(List<HipActionItem> all)
    : parts = [
        for (final p in hipPartOrder)
          if (all.any((a) => a.parts.contains(p))) p,
      ],
      equipment = _equipment(all),
      places = [
        for (final p in hipPlaceOrder)
          if (all.any((a) => a.places.contains(p))) p,
      ],
      types = [
        for (final p in [hipTypeRelax, hipTypeStrength])
          if (all.any((a) => a.type == p)) p,
      ],
      levels = [
        for (final l in [1, 2, 3])
          if (all.any((a) => a.level == l)) l,
      ];
  final List<String> parts;
  final List<String> equipment;
  final List<String> places;
  final List<String> types;
  final List<int> levels;

  /// Quick-row parts: the hip words first, most used.
  List<String> get quick => parts.take(6).toList();

  static List<String> _equipment(List<HipActionItem> all) {
    final n = <String, int>{};
    for (final a in all) {
      for (final e
          in a.equipment.isEmpty ? const [hipBodyweight] : a.equipment) {
        n[e] = (n[e] ?? 0) + 1;
      }
    }
    final list = n.keys.toList()
      ..sort((a, b) {
        if (a == hipBodyweight) return -1;
        if (b == hipBodyweight) return 1;
        return n[b]!.compareTo(n[a]!);
      });
    return list.length > 1 ? list : const [];
  }
}

Set<T> _toggle<T>(Set<T> s, T v) =>
    s.contains(v) ? ({...s}..remove(v)) : {...s, v};

// ───────────────────────── bar ─────────────────────────

/// Search field + one scrolling row: 全部, common parts, then 筛选 (badge).
class ActionFilterBar extends StatelessWidget {
  const ActionFilterBar({
    super.key,
    required this.all,
    required this.filter,
    required this.search,
    required this.onChanged,
  });
  final List<HipActionItem> all;
  final ActionFilter filter;
  final TextEditingController search;
  final ValueChanged<ActionFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = LibText.of(context);
    final facets = ActionFacets(all);
    final quick = facets.quick;
    final n = filter.sheetCount;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 36,
          child: LibSearchField(
            controller: search,
            onChanged: (q) => onChanged(filter.copyWith(query: q)),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 30,
          child: ShaderMask(
            shaderCallback: (r) => const LinearGradient(
              colors: [Colors.white, Colors.white, Colors.transparent],
              stops: [0, .94, 1],
            ).createShader(r),
            blendMode: BlendMode.dstIn,
            child: ListView(
              key: const ValueKey('action-quick-row'),
              scrollDirection: Axis.horizontal,
              children: [
                HipFilterChip(
                  t.all,
                  key: const ValueKey('action-part-all'),
                  on: filter.parts.isEmpty,
                  onTap: () => onChanged(filter.copyWith(parts: const {})),
                ),
                for (final p in quick) ...[
                  const SizedBox(width: 8),
                  HipFilterChip(
                    p,
                    key: ValueKey('action-part-$p'),
                    on: filter.parts.contains(p),
                    onTap: () => onChanged(
                      filter.copyWith(parts: _toggle(filter.parts, p)),
                    ),
                  ),
                ],
                const SizedBox(width: 8),
                HipFilterChip(
                  t.filter,
                  key: const ValueKey('action-filter'),
                  icon: HipGlyph.filter,
                  badge: n,
                  on: n > 0,
                  onTap: () async {
                    final f = await showActionFilterSheet(
                      context,
                      all: all,
                      initial: filter,
                    );
                    if (f != null) onChanged(f);
                  },
                ),
                const SizedBox(width: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Flat chip of the r2 kit: 30 high, radius 8, no outline; selected = jade
/// tint + jadeText. [badge] > 0 shows a small count.
class HipFilterChip extends StatelessWidget {
  const HipFilterChip(
    this.label, {
    super.key,
    this.on = false,
    this.icon,
    this.badge = 0,
    required this.onTap,
  });
  final String label;
  final bool on;
  final HipGlyph? icon;
  final int badge;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final fg = on ? HipColors.jadeText : HipColors.text;
    return HipPressable(
      semanticLabel: badge > 0 ? '$label $badge' : label,
      selected: on,
      onTap: onTap,
      scale: .96,
      child: Container(
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: on ? tintOf(HipColors.jade) : HipColors.track,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              HipIcon(icon!, size: 14, color: fg),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                height: 1.2,
                fontWeight: on ? FontWeight.w600 : FontWeight.w400,
                color: fg,
              ),
            ),
            if (badge > 0) ...[
              const SizedBox(width: 5),
              Container(
                key: const ValueKey('action-filter-badge'),
                constraints: const BoxConstraints(minWidth: 16),
                height: 16,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: HipColors.jade,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$badge',
                  style: TextStyle(
                    fontSize: 10.5,
                    height: 1,
                    fontWeight: FontWeight.w700,
                    color: HipColors.onJade,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ───────────────────────── sheet ─────────────────────────

/// 筛选: 部位 / 器械 / 在哪做 / 怎么练 / 难度 (groups without values are
/// hidden), 重置 top-right, 显示 N 个动作 with the live count.
Future<ActionFilter?> showActionFilterSheet(
  BuildContext context, {
  required List<HipActionItem> all,
  required ActionFilter initial,
}) {
  final t = LibText.of(context);
  final facets = ActionFacets(all);
  var f = initial;
  return showLibSheet<ActionFilter>(
    context,
    builder: (context) => StatefulBuilder(
      builder: (context, setSheet) {
        final n = f.apply(all).length;
        Widget section(String id, String title, List<Widget> chips) => Padding(
          key: ValueKey('filter-group-$id'),
          padding: const EdgeInsets.only(bottom: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  color: HipColors.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: chips),
            ],
          ),
        );
        List<Widget> chips<T>(
          String id,
          List<T> values,
          Set<T> on,
          String Function(T) label,
          ActionFilter Function(Set<T>) set,
        ) => [
          for (final v in values)
            HipFilterChip(
              label(v),
              key: ValueKey('filter-$id-$v'),
              on: on.contains(v),
              onTap: () => setSheet(() => f = set(_toggle(on, v))),
            ),
        ];
        final maxH = MediaQuery.sizeOf(context).height * .72;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            sheetTitle(
              t.filter,
              trailing: HipPressable(
                key: const ValueKey('filter-reset'),
                semanticLabel: t.reset,
                onTap: () => setSheet(() => f = f.withoutSheet),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Text(
                    t.reset,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: HipColors.jadeText,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxH),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (facets.parts.isNotEmpty)
                      section(
                        'part',
                        _z(t, '部位', 'Body part'),
                        chips<String>(
                          'part',
                          facets.parts,
                          f.parts,
                          (v) => v,
                          (s) => f.copyWith(parts: s),
                        ),
                      ),
                    if (facets.equipment.isNotEmpty)
                      section(
                        'equipment',
                        _z(t, '器械', 'Equipment'),
                        chips<String>(
                          'equipment',
                          facets.equipment,
                          f.equipment,
                          (v) => v,
                          (s) => f.copyWith(equipment: s),
                        ),
                      ),
                    if (facets.places.isNotEmpty)
                      section(
                        'place',
                        t.sceneTitle,
                        chips<String>(
                          'place',
                          facets.places,
                          f.places,
                          (v) => v,
                          (s) => f.copyWith(places: s),
                        ),
                      ),
                    if (facets.types.length > 1)
                      section(
                        'type',
                        t.methodTitle,
                        chips<String>(
                          'type',
                          facets.types,
                          f.types,
                          (v) => v,
                          (s) => f.copyWith(types: s),
                        ),
                      ),
                    if (facets.levels.length > 1)
                      section(
                        'level',
                        t.levelTitle,
                        chips<int>(
                          'level',
                          facets.levels,
                          f.levels,
                          t.levelName,
                          (s) => f.copyWith(levels: s),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),
            HipPrimaryButton(
              key: const ValueKey('filter-apply'),
              label: t.showN(n),
              onPressed: () => Navigator.of(context).pop(f),
            ),
          ],
        );
      },
    ),
  );
}

// ───────────────────────── card ─────────────────────────

/// Picker / library card in the LibDrillCard style: poster, part tag, name,
/// dose. [check] null = browse; true/false = pick; [disabled] dims it.
class ActionCard extends StatelessWidget {
  const ActionCard({
    super.key,
    required this.item,
    required this.onTap,
    this.check,
    this.inGroup = false,
    this.disabled = false,
    this.dose,
  });
  final HipActionItem item;

  /// Overrides the definition's dose (the picker shows the group dose).
  final String? dose;
  final ValueChanged<BuildContext> onTap;
  final bool? check;
  final bool inGroup;
  final bool disabled;

  static const double _radius = 12;

  @override
  Widget build(BuildContext context) {
    final t = LibText.of(context);
    final on = check == true;
    final large = libLargeText(context);
    const nameStyle = TextStyle(
      fontSize: 14,
      height: 1.33,
      fontWeight: FontWeight.w600,
    );
    final chair = item.places.contains('椅子可做');
    final adv = item.level == 3;
    final art = item.poster != null
        ? Image.asset(
            item.poster!,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            errorBuilder: (_, _, _) => item.drill == null
                ? const SizedBox.shrink()
                : HipDrillArt(drill: item.drill!, showPendingLabel: false),
          )
        : item.drill != null
        ? HipDrillArt(drill: item.drill!, showPendingLabel: false)
        : const SizedBox.shrink();
    return Builder(
      builder: (cardContext) => HipPressable(
        semanticLabel: item.name,
        selected: check == null ? null : on,
        scale: .97,
        onTap: () => onTap(cardContext),
        child: Opacity(
          opacity: disabled ? .5 : 1,
          child: RepaintBoundary(
            child: Container(
              foregroundDecoration: on
                  ? BoxDecoration(
                      borderRadius: BorderRadius.circular(_radius),
                      border: Border.all(color: HipColors.jade, width: 2),
                    )
                  : null,
              decoration: BoxDecoration(
                color: HipColors.surface,
                borderRadius: BorderRadius.circular(_radius),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(_radius),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AspectRatio(
                      aspectRatio: 1.08,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          ColoredBox(
                            color: HipColors.mediaBackdrop,
                            child: art,
                          ),
                          Positioned(
                            left: 8,
                            bottom: 8,
                            right: 8,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: mediaPill(
                                item.tag,
                                dot: HipPalette.dark.glow,
                              ),
                            ),
                          ),
                          Positioned(
                            left: 8,
                            top: 8,
                            child: Row(
                              children: [
                                if (adv)
                                  mediaPill(
                                    t.advanced,
                                    color: HipPalette.dark.tight,
                                  ),
                                if (adv && chair) const SizedBox(width: 4),
                                if (chair)
                                  mediaPill(t.chair, icon: HipGlyph.chair),
                              ],
                            ),
                          ),
                          if (check != null && !disabled)
                            Positioned(
                              right: on ? 6 : 8,
                              top: on ? 6 : 8,
                              child: _checkDot(on),
                            ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (large)
                            Text(item.name, style: nameStyle)
                          else
                            SizedBox(
                              height: MediaQuery.textScalerOf(
                                context,
                              ).scale(38),
                              child: Text(
                                item.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: nameStyle,
                              ),
                            ),
                          const SizedBox(height: 3),
                          Text(
                            disabled
                                ? _z(t, '仅单练 · 暂不能加入训练组', 'Solo only')
                                : inGroup
                                ? t.inGroup(dose ?? item.dose)
                                : dose ?? item.dose,
                            maxLines: large ? null : 1,
                            overflow: large ? null : TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.3,
                              color: inGroup || disabled
                                  ? HipColors.faint
                                  : HipColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _checkDot(bool on) => Container(
    width: 28,
    height: 28,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: on ? HipPalette.dark.jade : Colors.black.withValues(alpha: .35),
      border: Border.all(
        color: on ? HipPalette.dark.jade : Colors.white.withValues(alpha: .85),
        width: 1.6,
      ),
    ),
    alignment: Alignment.center,
    child: on
        ? HipIcon(
            HipGlyph.check,
            size: 18,
            strokeWidth: 2.6,
            color: HipPalette.dark.onJade,
          )
        : null,
  );
}

/// No results: one line and 重置筛选.
class ActionEmpty extends StatelessWidget {
  const ActionEmpty({super.key, required this.onReset});
  final VoidCallback onReset;
  @override
  Widget build(BuildContext context) {
    final t = LibText.of(context);
    return Padding(
      key: const ValueKey('action-empty'),
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Text(
            t.noMatch,
            style: TextStyle(fontSize: 15, color: HipColors.muted),
          ),
          const SizedBox(height: 12),
          LibPill(
            key: const ValueKey('action-empty-reset'),
            label: _z(t, '重置筛选', 'Reset filters'),
            height: 32,
            radius: 8,
            onTap: onReset,
          ),
        ],
      ),
    );
  }
}
