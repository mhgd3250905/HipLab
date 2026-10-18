import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/widgets.dart';

import 'hip_theme.dart';

/// Light skeuomorphic ("tactile") surfaces: the one button material of the
/// app (button audit 2026-10-18).
///
/// Distilled from the raised thumb of the settings segmented control
/// ([HipSegmented], round 2), which reads as a small physical tile rather
/// than as a glow:
///
/// * a fill lit from above: lighter at the top edge, the base colour at the
///   middle, a touch darker at the bottom;
/// * a 1 px inner highlight along the top edge that fades out down the
///   sides;
/// * a hairline stroke;
/// * a tight, dark contact shadow plus a small ambient one, no coloured
///   glow and no large soft halo;
/// * pressed: the top light and highlight drop, the shadow tucks in under
///   the tile and the fill darkens slightly, as if pushed into the page.
///
/// Shadows are painted as a few stacked, inflated shapes (a linear falloff
/// over the blur distance) instead of a blur filter: they look the same on
/// a device and in widget-test screenshots, and cost a handful of RRect
/// fills — no offscreen blur pass, which matters on low-end GPUs.
@immutable
class HipTactileShadow {
  const HipTactileShadow(this.color, {required this.blur, this.dy = 0});
  final Color color;

  /// Distance over which the shadow fades out (≈ BoxShadow.blurRadius).
  final double blur;
  final double dy;

  HipTactileShadow scaled({double alpha = 1, double blur = 1, double dy = 1}) =>
      HipTactileShadow(
        color.withValues(alpha: (color.a * alpha).clamp(0.0, 1.0)),
        blur: this.blur * blur,
        dy: this.dy * dy,
      );

  static HipTactileShadow lerp(
    HipTactileShadow a,
    HipTactileShadow b,
    double t,
  ) => HipTactileShadow(
    Color.lerp(a.color, b.color, t)!,
    blur: lerpDouble(a.blur, b.blur, t)!,
    dy: lerpDouble(a.dy, b.dy, t)!,
  );

  @override
  bool operator ==(Object other) =>
      other is HipTactileShadow &&
      other.color == color &&
      other.blur == blur &&
      other.dy == dy;

  @override
  int get hashCode => Object.hash(color, blur, dy);
}

/// One tactile material. Build one with [HipTactileStyle.neutral],
/// [HipTactileStyle.accent], [HipTactileStyle.glass] or
/// [HipTactileStyle.flat]; [pressed] derives the pushed-in state.
@immutable
class HipTactileStyle {
  const HipTactileStyle({
    required this.base,
    this.lighten = 0,
    this.darken = 0,
    this.highlight = const Color(0x00ffffff),
    this.stroke = const Color(0x00000000),
    this.strokeBottom,
    this.shadows = const [],
  });

  /// Fill at the vertical middle.
  final Color base;

  /// How far the top edge is lifted toward white (0–1).
  final double lighten;

  /// How far the bottom edge is lowered toward black (0–1).
  final double darken;

  /// 1 px inner light along the top edge (fades down the sides).
  final Color highlight;

  /// Hairline stroke at the top; [strokeBottom] (default: [stroke]) at the
  /// bottom, so the lower edge can read a touch darker.
  final Color stroke;
  final Color? strokeBottom;

  /// Contact shadow first, then ambient.
  final List<HipTactileShadow> shadows;

  Color get top => Color.lerp(base, const Color(0xffffffff), lighten)!;
  Color get bottom => Color.lerp(base, const Color(0xff000000), darken)!;

  // ── tokens ──────────────────────────────────────────────────────────────

  /// Neutral raised tile: secondary buttons, icon buttons, the segmented
  /// thumb, the selected tab. Dark: the settings thumb (#26292d, its 8 %
  /// top light); light: a white tile with a hairline edge.
  factory HipTactileStyle.neutral([HipPalette? palette]) {
    final p = palette ?? HipColors.palette;
    return p.isDark
        ? HipTactileStyle(
            base: p.thumb,
            lighten: .08,
            darken: .10,
            highlight: const Color(0x24ffffff),
            stroke: const Color(0x0fffffff),
            strokeBottom: const Color(0x05ffffff),
            shadows: const [
              HipTactileShadow(Color(0x73000000), blur: 2, dy: 1),
              HipTactileShadow(Color(0x40000000), blur: 6, dy: 3),
            ],
          )
        : const HipTactileStyle(
            base: Color(0xffffffff),
            darken: .035,
            highlight: Color(0xffffffff),
            stroke: Color(0x120d2a20),
            strokeBottom: Color(0x240d2a20),
            shadows: [
              HipTactileShadow(Color(0x240d2a20), blur: 2, dy: 1),
              HipTactileShadow(Color(0x140d2a20), blur: 7, dy: 3),
            ],
          );
  }

  /// Brand-coloured tile: primary CTAs and the 开始 button. Same lighting
  /// as [neutral], with a deeper edge of the accent instead of a glow.
  factory HipTactileStyle.accent([HipPalette? palette, Color? color]) {
    final p = palette ?? HipColors.palette;
    final c = color ?? p.jade;
    return p.isDark
        ? HipTactileStyle(
            base: c,
            lighten: .16,
            darken: .10,
            highlight: const Color(0x73ffffff),
            stroke: Color.lerp(
              c,
              const Color(0xff000000),
              .30,
            )!.withValues(alpha: .55),
            strokeBottom: Color.lerp(
              c,
              const Color(0xff000000),
              .45,
            )!.withValues(alpha: .75),
            shadows: const [
              HipTactileShadow(Color(0x80000000), blur: 2, dy: 1.5),
              HipTactileShadow(Color(0x47000000), blur: 7, dy: 3.5),
            ],
          )
        : HipTactileStyle(
            base: c,
            lighten: .14,
            darken: .08,
            highlight: const Color(0x66ffffff),
            stroke: Color.lerp(
              c,
              const Color(0xff000000),
              .25,
            )!.withValues(alpha: .45),
            strokeBottom: Color.lerp(
              c,
              const Color(0xff000000),
              .40,
            )!.withValues(alpha: .55),
            shadows: const [
              HipTactileShadow(Color(0x470d2a20), blur: 2, dy: 1),
              HipTactileShadow(Color(0x1f0d2a20), blur: 7, dy: 3),
            ],
          );
  }

  /// Translucent tile floating on media (chips over a playing clip): the
  /// edge light and stroke without an opaque fill or a cast shadow.
  factory HipTactileStyle.glass() => const HipTactileStyle(
    base: Color(0x73000000),
    lighten: .06,
    highlight: Color(0x2effffff),
    stroke: Color(0x1fffffff),
    strokeBottom: Color(0x0affffff),
  );

  /// Disabled: no light, no lift (it cannot be pressed).
  factory HipTactileStyle.flat([HipPalette? palette]) {
    final p = palette ?? HipColors.palette;
    return HipTactileStyle(base: p.surfaceHigh, stroke: p.line);
  }

  /// The pushed-in state: top light and highlight mostly gone, contact
  /// shadow tucked under the tile, ambient shadow gone, fill a touch darker.
  HipTactileStyle pressed() => HipTactileStyle(
    base: Color.lerp(
      base,
      const Color(0xff000000),
      .05,
    )!.withValues(alpha: base.a),
    lighten: lighten * .3,
    darken: darken,
    highlight: highlight.withValues(alpha: highlight.a * .35),
    stroke: stroke,
    strokeBottom: strokeBottom,
    shadows: [
      for (final (i, s) in shadows.indexed)
        i == 0 ? s.scaled(blur: .6, dy: .4) : s.scaled(alpha: 0, dy: .5),
    ],
  );

  static HipTactileStyle lerp(HipTactileStyle a, HipTactileStyle b, double t) {
    if (t == 0) return a;
    if (t == 1) return b;
    final n = math.max(a.shadows.length, b.shadows.length);
    HipTactileShadow at(List<HipTactileShadow> l, int i) => i < l.length
        ? l[i]
        : HipTactileShadow(const Color(0x00000000), blur: 0);
    return HipTactileStyle(
      base: Color.lerp(a.base, b.base, t)!,
      lighten: lerpDouble(a.lighten, b.lighten, t)!,
      darken: lerpDouble(a.darken, b.darken, t)!,
      highlight: Color.lerp(a.highlight, b.highlight, t)!,
      stroke: Color.lerp(a.stroke, b.stroke, t)!,
      strokeBottom: Color.lerp(
        a.strokeBottom ?? a.stroke,
        b.strokeBottom ?? b.stroke,
        t,
      ),
      shadows: [
        for (var i = 0; i < n; i++)
          HipTactileShadow.lerp(at(a.shadows, i), at(b.shadows, i), t),
      ],
    );
  }

  @override
  bool operator ==(Object other) =>
      other is HipTactileStyle &&
      other.base == base &&
      other.lighten == lighten &&
      other.darken == darken &&
      other.highlight == highlight &&
      other.stroke == stroke &&
      other.strokeBottom == strokeBottom &&
      _listEq(other.shadows, shadows);

  static bool _listEq(List<HipTactileShadow> a, List<HipTactileShadow> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
    base,
    lighten,
    darken,
    highlight,
    stroke,
    strokeBottom,
    Object.hashAll(shadows),
  );
}

/// Whether the nearest [HipPressable] above is held down. [HipTactile]
/// reads it, so a tactile face inside a pressable sinks on its own.
class HipPressedScope extends InheritedWidget {
  const HipPressedScope({
    super.key,
    required this.pressed,
    required super.child,
  });
  final bool pressed;

  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<HipPressedScope>()?.pressed ??
      false;

  @override
  bool updateShouldNotify(HipPressedScope old) => old.pressed != pressed;
}

/// Paints a [HipTactileStyle] behind [child] in a rounded rect of
/// [radius] (use half the height for a stadium, [circle] for a disc).
/// Sinks when [pressed] (default: the enclosing [HipPressable]'s state),
/// over [HipMotion.press].
class HipTactile extends StatelessWidget {
  const HipTactile({
    super.key,
    required this.style,
    this.radius = 14,
    this.circle = false,
    this.pressed,
    this.child,
  });
  final HipTactileStyle style;
  final double radius;
  final bool circle;
  final bool? pressed;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final down = pressed ?? HipPressedScope.of(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(end: down ? 1 : 0),
      duration: HipMotion.press,
      curve: Curves.easeOut,
      builder: (context, t, child) => CustomPaint(
        painter: HipTactilePainter(
          HipTactileStyle.lerp(style, style.pressed(), t),
          radius: radius,
          circle: circle,
        ),
        child: child,
      ),
      child: child,
    );
  }
}

class HipTactilePainter extends CustomPainter {
  HipTactilePainter(this.style, {this.radius = 14, this.circle = false});
  final HipTactileStyle style;
  final double radius;
  final bool circle;

  /// Shadow layers per pixel of blur (at least 2, at most 8 layers).
  static int layersFor(double blur) => (blur * 1.2).ceil().clamp(2, 8);

  RRect _shape(Rect r) => RRect.fromRectAndRadius(
    r,
    Radius.circular(
      circle ? r.shortestSide / 2 : math.min(radius, r.shortestSide / 2),
    ),
  );

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final rect = Offset.zero & size;
    final shape = _shape(rect);
    final s = style;

    // Shadows: n stacked fills, inflated from 0 to blur, each at an alpha
    // such that n layers add up to the shadow colour under the tile.
    for (final sh in s.shadows) {
      if (sh.color.a <= 0 || sh.blur < 0) continue;
      final n = layersFor(sh.blur);
      final a = 1 - math.pow(1 - sh.color.a, 1 / n).toDouble();
      final paint = Paint()..color = sh.color.withValues(alpha: a);
      for (var i = 0; i < n; i++) {
        final grow = sh.blur * (i + .5) / n - sh.blur * .35;
        canvas.drawRRect(shape.shift(Offset(0, sh.dy)).inflate(grow), paint);
      }
    }

    // Fill: lit from above.
    canvas.drawRRect(
      shape,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [s.top, s.base, s.bottom],
          stops: const [0, .5, 1],
        ).createShader(rect),
    );

    // Hairline stroke (inside the edge).
    final edge = shape.deflate(.5);
    final bottom = s.strokeBottom ?? s.stroke;
    if (s.stroke.a > 0 || bottom.a > 0) {
      canvas.drawRRect(
        edge,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [s.stroke, bottom],
          ).createShader(rect),
      );
    }

    // Inner top highlight: a 1 px line just inside the top edge, fading
    // out as the edge turns down the sides.
    if (s.highlight.a > 0) {
      final reach = math.min(size.height * .5, math.max(shape.tlRadiusY, 8));
      canvas.save();
      canvas.clipRRect(shape);
      canvas.drawRRect(
        shape.deflate(1),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [s.highlight, s.highlight.withValues(alpha: 0)],
            stops: [0, (reach / size.height).clamp(.05, 1.0)],
          ).createShader(rect),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(HipTactilePainter old) =>
      old.style != style || old.radius != radius || old.circle != circle;
}
