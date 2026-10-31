import 'package:flutter/material.dart';
import 'package:ugk_coach_ui/ugk_coach_ui.dart' as ui;

import '../../domain/hip_library.dart' show libraryDrills;
import '../../domain/hip_models.dart';
import '../hip_icons.dart';
import '../hip_theme.dart';

/// SmartFit@3eb2a9e task roles with HipLab's existing brand palette. The SDK
/// retains geometry, animation and controls; other host colour roles survive.
ui.CoachUiColors hipCoachTaskColors(
  ui.CoachUiColors base, {
  HipPalette? palette,
}) {
  final p = palette ?? HipColors.palette;
  final contrast = p.isDark ? Colors.white : Colors.black;
  return base.copyWith(
    brightness: p.brightness,
    taskAccent: p.jade,
    taskCardSurface: p.surface,
    taskCardBorder: contrast.withValues(alpha: p.isDark ? .08 : .06),
    taskGlow: p.jade.withValues(alpha: p.isDark ? .10 : .06),
    taskText: p.text,
    taskMuted: p.muted,
    taskChipSurface: p.jade.withValues(alpha: p.isDark ? .18 : .10),
    taskOrbFill: p.jade.withValues(alpha: p.isDark ? .14 : .08),
    taskProgressTrack: contrast.withValues(alpha: p.isDark ? .10 : .08),
    taskChipBorder: contrast.withValues(alpha: p.isDark ? .12 : .10),
    taskHalo: p.jade.withValues(alpha: .15),
    taskShadowNear: Colors.black.withValues(alpha: .04),
    taskShadowFar: Colors.black.withValues(alpha: .06),
  );
}

/// Reuses the SDK's verified transparent first frames for the 45 HipLab library
/// actions. These neutral RGBA images work on both themes; the App's baked
/// light/dark poster images are deliberately not treated as transparent art.
ui.CoachTaskCutoutBuilder hipCoachTaskCutouts(HipContent content) {
  final safeId = RegExp(r'^[A-Za-z0-9_-]+$');
  final drills = {
    for (final drill in libraryDrills(content))
      if (safeId.hasMatch(drill.id)) drill.id: drill,
  };
  final cache = <(String, String, Size, Brightness), Widget>{};
  return (_, id, size, brightness) {
    final drill = drills[id];
    if (drill == null) return SizedBox.fromSize(size: size);
    final asset =
        'packages/ugk_trainer/assets/pose_hub/app-test-pack-r1/standing/$id.webp';
    return cache.putIfAbsent(
      (asset, drill.name, size, brightness),
      () => ClipOval(
        child: SizedBox.fromSize(
          size: size,
          child: Image.asset(
            asset,
            fit: BoxFit.contain,
            alignment: Alignment.center,
            semanticLabel: drill.name,
            gaplessPlayback: true,
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
          ),
        ),
      ),
    );
  };
}

/// HipLab has a clipboard glyph for its saved groups. Reuse it for the SDK's
/// bookmark role rather than introduce another icon family or draw new art.
Widget hipCoachPlanFocusIcon(BuildContext context, double size, Color color) =>
    HipIcon(HipGlyph.clipboard, size: size, color: color);

Widget hipCoachPlanFocusClearIcon(
  BuildContext context,
  double size,
  Color color,
) => HipIcon(HipGlyph.close, size: size, color: color);

Widget hipCoachIconBuilder(BuildContext context, ui.CoachIcon icon) => HipIcon(
  switch (icon.glyph) {
    ui.CoachGlyph.bookmark => HipGlyph.clipboard,
    ui.CoachGlyph.chevronRight => HipGlyph.chevronRight,
    ui.CoachGlyph.play => HipGlyph.play,
    ui.CoachGlyph.stop => HipGlyph.stop,
  },
  size: icon.size,
  color: icon.color ?? ui.CoachUiTheme.of(context).colors.text,
  filled: icon.filled,
  strokeWidth: icon.strokeWidth,
);
