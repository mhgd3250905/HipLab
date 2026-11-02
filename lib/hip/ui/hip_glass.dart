// Translucent glass (theme redesign m2, 开哥 2026-11-02: "半透明玻璃的效果"),
// after his iOS liquid-glass reference. m4 (开哥 19:17: "玻璃材质上的组件尽量
// 扁平有层级"): three flat levels only —
//   1. base glass: blur + a low flat fill, a 0.5pt hairline rim, at most a
//      tiny soft shadow;
//   2. selected / raised: a slightly brighter flat fill (no rim, no shadow);
//   3. content: text and glyphs.
// No gradients, sheens, glows or inner shadows stacked on top.
//
// Performance rules:
// * Blur ([HipGlass.blur]) only where something interesting is behind
//   (controls floating on the 首页 cover, panels over the 更多 backdrop) and
//   only on few, small regions: never full-screen, never per list item
//   (one glass panel per group).
// * Everywhere else the same look without sampling: translucent fill + rim
//   ([HipGlass.blur] false, the default).
// * Each glass is its own layer (RepaintBoundary).
// * High contrast: more opaque fill, stronger rim.
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'hip_theme.dart';
import 'hip_widgets.dart';

enum HipGlassShape { rounded, capsule, circle }

/// One glass surface. [child] is clipped to the shape.
class HipGlass extends StatelessWidget {
  const HipGlass({
    super.key,
    this.child,
    this.shape = HipGlassShape.rounded,
    this.radius = 24,
    this.blur = false,
    this.sigma = 20,
    this.padding = EdgeInsets.zero,
    this.shadow = true,
    this.tint,
  });

  final Widget? child;
  final HipGlassShape shape;

  /// Corner radius for [HipGlassShape.rounded].
  final double radius;

  /// Sample and blur what is behind (BackdropFilter). Only over content.
  final bool blur;
  final double sigma;
  final EdgeInsets padding;
  final bool shadow;

  /// Optional colour tint mixed into the fill (e.g. jade for the AI card).
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final dark = HipColors.isDark;
    final high = MediaQuery.maybeHighContrastOf(context) ?? false;
    return LayoutBuilder(
      builder: (context, c) {
        final r = _radius(c);
        final rr = BorderRadius.all(Radius.circular(r));
        final fill = HipGlassStyle.fill(
          dark: dark,
          high: high,
          blur: blur,
          tint: tint,
        );
        Widget body = DecoratedBox(
          decoration: BoxDecoration(gradient: fill),
          child: CustomPaint(
            foregroundPainter: HipGlassRimPainter(
              radius: r,
              dark: dark,
              high: high,
            ),
            child: Padding(padding: padding, child: child),
          ),
        );
        if (blur && !high) {
          body = BackdropFilter(
            filter: HipGlassStyle.filter(sigma, dark: dark),
            child: body,
          );
        }
        return RepaintBoundary(
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: rr,
              boxShadow: shadow ? HipGlassStyle.shadow(dark: dark) : null,
            ),
            child: ClipRRect(borderRadius: rr, child: body),
          ),
        );
      },
    );
  }

  double _radius(BoxConstraints c) => switch (shape) {
    HipGlassShape.rounded => radius,
    // Unbounded side: fall back to [radius]; capsule/circle are sized.
    HipGlassShape.capsule ||
    HipGlassShape.circle => c.hasBoundedHeight ? c.maxHeight / 2 : radius,
  };
}

/// The brighter inner glass pill that marks the selected item.
class HipGlassPill extends StatelessWidget {
  const HipGlassPill({
    super.key,
    this.radius = 999,
    this.child,
    this.strength = 1,
  });
  final double radius;
  final Widget? child;

  /// Below 1: a quieter secondary pill (e.g. 换一套 beside 开始).
  final double strength;

  @override
  Widget build(BuildContext context) {
    final dark = HipColors.isDark;
    final high = MediaQuery.maybeHighContrastOf(context) ?? false;
    return LayoutBuilder(
      builder: (context, c) {
        final r = radius.clamp(0, c.maxHeight / 2).toDouble();
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(r),
            color: HipGlassStyle.raised(
              dark: dark,
              high: high,
              strength: strength,
            ),
          ),
          child: child,
        );
      },
    );
  }
}

/// Round glass button (⋯, back), 40pt by default.
class HipGlassRoundButton extends StatelessWidget {
  const HipGlassRoundButton({
    super.key,
    required this.child,
    required this.onTap,
    required this.semanticLabel,
    this.size = 40,
    this.blur = false,
  });
  final Widget child;
  final VoidCallback? onTap;
  final String semanticLabel;
  final double size;
  final bool blur;

  @override
  Widget build(BuildContext context) => HipPressable(
    semanticLabel: semanticLabel,
    onTap: onTap,
    scale: .94,
    child: SizedBox.square(
      dimension: size,
      child: HipGlass(
        shape: HipGlassShape.circle,
        blur: blur,
        sigma: 16,
        child: Center(child: child),
      ),
    ),
  );
}

/// Tokens shared by every glass surface.
abstract final class HipGlassStyle {
  /// Fill gradient, top → bottom. Over blur the fill is thinner (the blur
  /// carries the frost); without blur it is a touch denser so the panel
  /// still separates from a plain page.
  static LinearGradient fill({
    required bool dark,
    bool high = false,
    bool blur = false,
    Color? tint,
  }) {
    // Flat: one opacity, top to bottom (both stops equal).
    final double a = high
        ? (dark ? .22 : .96)
        : dark
        ? (blur ? .10 : .06)
        : (blur ? .55 : .72);
    var c = Colors.white.withValues(alpha: a);
    if (tint != null) {
      c = Color.alphaBlend(tint.withValues(alpha: dark ? .14 : .08), c);
    }
    return LinearGradient(colors: [c, c]);
  }

  /// Level 2: the selected / raised fill on a glass surface.
  static Color raised({
    required bool dark,
    bool high = false,
    double strength = 1,
  }) => dark
      ? Colors.white.withValues(alpha: high ? .3 : .16 * strength)
      : Colors.black.withValues(alpha: high ? .12 : .06 * strength);

  /// At most a tiny soft shadow under the base level.
  static List<BoxShadow>? shadow({required bool dark}) => HipColors.shadows([
    BoxShadow(
      color: dark ? const Color(0x2e000000) : const Color(0x0f1d2b25),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ]);

  /// Blur plus a slight saturation lift (the "liquid" look: colour behind
  /// glass reads richer, not washed out).
  static ui.ImageFilter filter(double sigma, {required bool dark}) {
    const s = 1.35;
    const r = .2126 * (1 - s), g = .7152 * (1 - s), b = .0722 * (1 - s);
    final k = dark ? 1.0 : 1.04;
    return ui.ImageFilter.compose(
      outer: ui.ImageFilter.blur(
        sigmaX: sigma,
        sigmaY: sigma,
        tileMode: TileMode.mirror,
      ),
      inner: ui.ColorFilter.matrix([
        (r + s) * k, g * k, b * k, 0, 0, //
        r * k, (g + s) * k, b * k, 0, 0, //
        r * k, g * k, (b + s) * k, 0, 0, //
        0, 0, 0, 1, 0,
      ]),
    );
  }
}

/// The base level's 0.5pt hairline rim: one flat colour, no sheen.
class HipGlassRimPainter extends CustomPainter {
  const HipGlassRimPainter({
    required this.radius,
    required this.dark,
    this.high = false,
    this.strength = 1,
  });
  final double radius;
  final bool dark;
  final bool high;
  final double strength;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final r = radius.clamp(0, size.shortestSide / 2).toDouble();
    final rrect = RRect.fromRectAndRadius(
      rect.deflate(.25),
      Radius.circular((r - .25).clamp(0, r).toDouble()),
    );
    final a = ((high ? .6 : .18) * strength).clamp(0, 1).toDouble();
    // Light: white glass on a light page needs a faint dark edge instead.
    final color = dark
        ? Colors.white.withValues(alpha: a)
        : (high ? HipColors.line : Colors.black.withValues(alpha: a * .4));
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = high ? 1 : .5
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(HipGlassRimPainter old) =>
      old.radius != radius ||
      old.dark != dark ||
      old.high != high ||
      old.strength != strength;
}

/// Page depth behind glass: the current routine cover, tiny-decoded (so
/// upscaling blurs it for free — no ImageFilter), darkened/lightened toward
/// the page colour, plus a vignette. Static, its own layer.
class HipGlassBackdrop extends StatelessWidget {
  const HipGlassBackdrop({super.key, this.image});

  /// Asset path of the cover (already themed), or null for the plain depth
  /// gradient.
  final String? image;

  @override
  Widget build(BuildContext context) {
    final bg = HipColors.background;
    final dark = HipColors.isDark;
    return RepaintBoundary(
      child: IgnorePointer(
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: bg),
            if (image != null)
              Opacity(
                opacity: dark ? .55 : .5,
                child: Image.asset(
                  image!,
                  fit: BoxFit.cover,
                  cacheWidth: 18,
                  filterQuality: FilterQuality.medium,
                  alignment: const Alignment(0, -.3),
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
            // Soft jade glow top-left, deeper corners: depth to refract.
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(-.7, -.85),
                  radius: 1.1,
                  colors: [
                    HipColors.jade.withValues(alpha: dark ? .16 : .1),
                    HipColors.jade.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(.8, .9),
                  radius: 1,
                  colors: [
                    HipColors.glow.withValues(alpha: dark ? .07 : .06),
                    HipColors.glow.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0, .45, 1],
                  colors: [
                    bg.withValues(alpha: .15),
                    bg.withValues(alpha: .55),
                    bg.withValues(alpha: .9),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
