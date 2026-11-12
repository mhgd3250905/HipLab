// 练习库 shared pieces. Flat everywhere (docs/tactile-design-rationale-2026-
// 10-19.md): tactile material only in HipSegmented's thumb; primary =
// HipPrimaryButton (flat jade fill), secondary = HipSecondaryButton
// (outline), in-card actions = tinted pills / text links.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/hip_library.dart';
import '../../domain/hip_models.dart';
import '../hip_icons.dart';
import '../hip_content_text.dart';
import '../hip_theme.dart';
import '../hip_widgets.dart';
import 'lib_text.dart';

// ───────────────────────── names ─────────────────────────

String routineShortName(HipRoutine r, [String lang = 'zh']) => lang == 'en'
    ? HipContentText.en.routineName(r)
    : r.name.replaceAll(RegExp(r'\s*\d+\s*分钟$'), '');

Map<String, dynamic>? _display(HipContent c, String id) {
  final d = c.kit(id)?.raw['display'];
  return d is Map ? Map<String, dynamic>.from(d) : null;
}

String _pick(Object? m, String lang) =>
    m is Map ? ((m[lang] ?? m['zh']) as String? ?? '') : '';

/// Drill name in [lang] (action kit display.name), content name as fallback.
String drillName(HipContent c, HipDrill d, String lang) {
  if (lang == 'zh') return d.name;
  final n = _pick(_display(c, d.id)?['name'], lang);
  return n.isEmpty ? HipContentText(lang).drillName(d) : n;
}

/// The other language's name (shown small under the title).
String drillAltName(HipContent c, HipDrill d, String lang) =>
    _pick(_display(c, d.id)?['name'], lang == 'zh' ? 'en' : 'zh');

String drillPoint(HipContent c, HipDrill d, String lang) =>
    _pick(_display(c, d.id)?['point'], lang);

/// System text at ≥1.6× (PR #22 P3: 360 wide ×2.0 cut the 练习 page's
/// key text): cards stack or go one per row and copy wraps instead.
bool libLargeText(BuildContext context) =>
    MediaQuery.textScalerOf(context).scale(10) >= 16;

// ───────────────────────── filter ─────────────────────────

/// 动作大全 filter: 练哪里 chip, search text and the 筛选 sheet. Within a
/// group the choices are OR, groups are AND.
class LibraryFilter {
  const LibraryFilter({
    this.direction,
    this.query = '',
    this.scenes = const {},
    this.methods = const {},
    this.levels = const {},
  });
  final HipDirection? direction;
  final String query;
  final Set<HipScene> scenes;
  final Set<HipMethod> methods;

  /// true = 进阶, false = 入门.
  final Set<bool> levels;

  int get sheetCount => scenes.length + methods.length + levels.length;
  bool get isEmpty => direction == null && query.isEmpty && sheetCount == 0;

  LibraryFilter copyWith({
    HipDirection? direction,
    bool clearDirection = false,
    String? query,
    Set<HipScene>? scenes,
    Set<HipMethod>? methods,
    Set<bool>? levels,
  }) => LibraryFilter(
    direction: clearDirection ? null : direction ?? this.direction,
    query: query ?? this.query,
    scenes: scenes ?? this.scenes,
    methods: methods ?? this.methods,
    levels: levels ?? this.levels,
  );

  LibraryFilter get withoutSheet =>
      LibraryFilter(direction: direction, query: query);

  bool matchesSheet(HipDrill d) =>
      (scenes.isEmpty || d.scenes.any(scenes.contains)) &&
      (methods.isEmpty || d.methods.any(methods.contains)) &&
      (levels.isEmpty || levels.contains(d.advanced));

  bool matches(HipContent c, HipDrill d) {
    if (direction != null && !d.directions.contains(direction)) return false;
    if (!matchesSheet(d)) return false;
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    final names = [
      d.name,
      drillName(c, d, 'en'),
      _pick(_display(c, d.id)?['name'], 'zh'),
    ];
    return names.any((n) => n.toLowerCase().contains(q));
  }

  List<HipDrill> apply(HipContent c, List<HipDrill> all) => [
    for (final d in all)
      if (matches(c, d)) d,
  ];
}

// ───────────────────────── chips / pills ─────────────────────────

Color tintOf(Color c) => c.withValues(alpha: HipColors.isDark ? .18 : .12);

/// Small tinted label ("为你推荐", "左右各做").
Widget tintTag(String text, {Color? color}) {
  final c = color ?? HipColors.jadeText;
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: tintOf(color ?? HipColors.jade),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      text,
      maxLines: 1,
      style: TextStyle(fontSize: 12, color: c, fontWeight: FontWeight.w600),
    ),
  );
}

/// Translucent pill on media (same as the player's area chip).
Widget mediaPill(String text, {Color? dot, HipGlyph? icon, Color? color}) =>
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: .5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot != null) ...[
            CircleAvatar(radius: 3.5, backgroundColor: dot),
            const SizedBox(width: 5),
          ],
          if (icon != null) ...[
            HipIcon(icon, size: 13, color: color ?? Colors.white70),
            if (text.isNotEmpty) const SizedBox(width: 3),
          ],
          if (text.isNotEmpty)
            Text(
              text,
              style: TextStyle(
                fontSize: 11.5,
                height: 1.2,
                fontWeight: FontWeight.w600,
                color: color ?? Colors.white.withValues(alpha: .9),
              ),
            ),
        ],
      ),
    );

/// In-card tertiary action: tinted pill ("▶ 开始", "重测").
class LibPill extends StatelessWidget {
  const LibPill({
    super.key,
    required this.label,
    required this.onTap,
    this.semanticLabel,
    this.icon,
    this.height = 28,
    this.radius = 14,
    this.foreground,
    this.background,
  });
  final String label;
  final String? semanticLabel;
  final HipGlyph? icon;
  final VoidCallback? onTap;

  /// UI r2 compact action pill: 32 high, radius 8.
  final double height;
  final double radius;

  /// Optional enabled-state colours. Defaults keep the jade action tint.
  final Color? foreground;
  final Color? background;
  @override
  Widget build(BuildContext context) {
    final on = onTap != null;
    final fg = on ? (foreground ?? HipColors.jadeText) : HipColors.faint;
    return HipPressable(
      semanticLabel: semanticLabel ?? label,
      onTap: onTap,
      scale: .95,
      child: Container(
        height: height,
        padding: EdgeInsets.symmetric(horizontal: height > 28 ? 12 : 10),
        decoration: BoxDecoration(
          color: on
              ? (background ?? tintOf(HipColors.jade))
              : HipColors.surfaceHigh,
          borderRadius: BorderRadius.circular(radius),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              HipIcon(icon!, size: 12, filled: true, color: fg),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────── search + chips row ─────────────────────────

class LibSearchField extends StatelessWidget {
  const LibSearchField({
    super.key,
    required this.controller,
    required this.onChanged,
    this.libraryStyle = false,
  });
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final bool libraryStyle;
  @override
  Widget build(BuildContext context) {
    final t = LibText.of(context);
    final content = Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 2, 4),
      child: Row(
        children: [
          HipIcon(HipGlyph.search, size: 16, color: HipColors.muted),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              key: const ValueKey('lib-search'),
              controller: controller,
              onChanged: onChanged,
              textInputAction: TextInputAction.search,
              style: TextStyle(fontSize: 14, color: HipColors.text),
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: libLargeText(context)
                    ? t.searchHintShort
                    : t.searchHint,
                hintStyle: TextStyle(
                  fontSize: libraryStyle ? 13 : 14,
                  color: HipColors.faint,
                ),
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            HipPressable(
              semanticLabel: t.clear,
              onTap: () {
                controller.clear();
                onChanged('');
              },
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: HipIcon(
                  HipGlyph.close,
                  size: 16,
                  color: HipColors.muted,
                ),
              ),
            ),
        ],
      ),
    );
    return libraryStyle
        ? HipCard(radius: 14, child: content)
        : Container(
            constraints: const BoxConstraints(minHeight: 36),
            decoration: BoxDecoration(
              color: HipColors.track,
              borderRadius: BorderRadius.circular(10),
            ),
            child: content,
          );
  }
}

// ───────────────────────── notices / footer / thumbs ─────────────────────

/// Info / warning strip (疼过、进阶、锁定、安全筛查): flat card, tinted edge,
/// optional text-link action.
class LibNotice extends StatelessWidget {
  const LibNotice({
    super.key,
    required this.text,
    required this.color,
    this.action,
    this.onAction,
    this.icon = HipGlyph.info,
  });
  final String text;
  final Color color;
  final String? action;
  final VoidCallback? onAction;
  final HipGlyph icon;
  @override
  Widget build(BuildContext context) => HipPanel(
    borderColor: color,
    padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HipIcon(icon, size: 20, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(text, style: const TextStyle(fontSize: 14, height: 1.4)),
              if (action != null) ...[
                const SizedBox(height: 4),
                HipPressable(
                  semanticLabel: action,
                  onTap: onAction,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          action!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: HipColors.jadeText,
                          ),
                        ),
                      ),
                      HipIcon(
                        HipGlyph.chevronRight,
                        size: 16,
                        color: HipColors.jadeText,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}

/// Sticky footer above the home indicator (detail / editor / picker).
class LibFooter extends StatelessWidget {
  const LibFooter({super.key, required this.children, this.above});
  final List<Widget> children;
  final Widget? above;
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(color: HipColors.background),
    child: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ?above,
            Row(children: children),
          ],
        ),
      ),
    ),
  );
}

/// Row of 40 pt drill thumbnails with a +N tile when they do not fit.
class LibThumbStrip extends StatelessWidget {
  const LibThumbStrip({
    super.key,
    required this.drills,
    this.size = 40,
    this.gap = 6,
  });
  final List<HipDrill> drills;
  final double size;
  final double gap;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final fit = ((c.maxWidth + gap) / (size + gap)).floor();
      final show = drills.length > fit ? fit - 1 : drills.length;
      final r = size <= 32 ? 8.0 : 10.0;
      return Row(
        children: [
          for (final (j, d) in drills.take(show).indexed)
            Padding(
              padding: EdgeInsets.only(left: j == 0 ? 0 : gap),
              child: HipThumb(
                size: size,
                radius: r,
                child: HipDrillArt(drill: d, showPendingLabel: false),
              ),
            ),
          if (show < drills.length) ...[
            SizedBox(width: gap),
            Container(
              width: size,
              height: size,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: HipColors.surfaceHigh,
                borderRadius: BorderRadius.circular(r),
              ),
              child: Text(
                '+${drills.length - show}',
                style: TextStyle(
                  fontSize: 12,
                  color: HipColors.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      );
    },
  );
}

// ───────────────────────── dose stepper ─────────────────────────

/// The dose card used by 动作详情 (单练) and the group editor's sheet: one
/// stepper for reps or seconds, one for sets.
class LibDosePanel extends StatelessWidget {
  const LibDosePanel({
    super.key,
    required this.kit,
    required this.dose,
    required this.single,
    required this.onChanged,
    this.showTotal = true,
  });
  final ActionKit kit;
  final LibraryDose dose;
  final bool single;
  final ValueChanged<LibraryDose> onChanged;
  final bool showTotal;

  @override
  Widget build(BuildContext context) {
    final t = LibText.of(context);
    final unit = DoseRules.unit(kit, single: single);
    final r = DoseRules.range(kit, single: single);
    final v = DoseRules.value(kit, dose, single: single);
    final timed = unit == DoseUnit.seconds;
    // Shown estimate includes the 5 s side switch (not in TrainingPlan time).
    final total =
        DoseRules.stepSeconds(kit, dose, single: single) + (kit.sided ? 5 : 0);
    void set(int nv) {
      final c = r.clamp(nv);
      onChanged(
        timed
            ? LibraryDose(seconds: c, sets: dose.sets)
            // Keeps a copied step's hold; its pace was for the old reps.
            : LibraryDose(
                reps: c,
                sets: dose.sets,
                holdSeconds: dose.holdSeconds,
              ),
      );
    }

    return HipPanel(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                t.dose,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              if (kit.sided) tintTag(t.bothSides),
              const SizedBox(width: 8),
              // Wraps under large text instead of overflowing (390 ×1.5,
              // sided drills: 5 px, found by the PR #22 F3 test).
              Expanded(
                child: showTotal
                    ? Text(
                        t.about(t.duration(total)),
                        key: const ValueKey('dose-total'),
                        textAlign: TextAlign.end,
                        style: TextStyle(fontSize: 13, color: HipColors.muted),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _stepper(
            context,
            id: 'value',
            label: timed ? t.secondsLabel(kit.sided) : t.repsLabel(kit.sided),
            value: timed ? t.secondsValue(v) : t.repsValue(v),
            hint: t.rangeHint(r.base, r.min, r.max, seconds: timed),
            onDown: v > r.min ? () => set(v - r.step) : null,
            onUp: v < r.max ? () => set(v + r.step) : null,
          ),
          Divider(height: 20, color: HipColors.line),
          _stepper(
            context,
            id: 'sets',
            label: t.setsLabel,
            value: t.setsValue(dose.sets),
            hint: t.setsHint,
            onDown: dose.sets > 1
                ? () => onChanged(dose.copyWith(sets: dose.sets - 1))
                : null,
            onUp: dose.sets < DoseRules.maxSets
                ? () => onChanged(dose.copyWith(sets: dose.sets + 1))
                : null,
          ),
        ],
      ),
    );
  }

  Widget _stepper(
    BuildContext context, {
    required String id,
    required String label,
    required String value,
    required String hint,
    required VoidCallback? onDown,
    required VoidCallback? onUp,
  }) {
    final t = LibText.of(context);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 15)),
              Text(
                hint,
                style: TextStyle(fontSize: 12, color: HipColors.faint),
              ),
            ],
          ),
        ),
        HipCircleButton(
          key: ValueKey('dose-$id-down'),
          icon: HipGlyph.minus,
          size: 38,
          tooltip: t.less,
          onPressed: onDown == null
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  onDown();
                },
        ),
        SizedBox(
          width: 72,
          child: Text(
            value,
            key: ValueKey('dose-$id'),
            textAlign: TextAlign.center,
            maxLines: 1,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ),
        HipCircleButton(
          key: ValueKey('dose-$id-up'),
          icon: HipGlyph.plus,
          size: 38,
          tooltip: t.more,
          onPressed: onUp == null
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  onUp();
                },
        ),
      ],
    );
  }
}

/// Bottom sheet frame used by the library (filter, add-to-group, dose).
Future<T?> showLibSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) => showModalBottomSheet<T>(
  context: context,
  isScrollControlled: true,
  sheetAnimationStyle: HipMotion.sheet,
  // m5: smaller top corners on HipLab's own sheets (the theme's 28 stays
  // for SDK-owned sheets, which inherit it).
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
  ),
  builder: (context) => SafeArea(
    child: Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        4,
        20,
        8 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: builder(context),
    ),
  ),
);

Widget sheetTitle(String title, {Widget? trailing}) => Row(
  children: [
    Expanded(
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
      ),
    ),
    ?trailing,
  ],
);
