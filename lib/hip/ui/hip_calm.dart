// Calm surfaces and motion for 首页 / 更多 (home redesign r1, 2026-11-02),
// after the water-cup R29 spec (ui-theme-and-motion.md): restrained
// translucent surfaces painted locally — gradient + light shadow, never a
// BackdropFilter — one accent (jade), one motion rhythm, reduce-motion
// honoured.
import 'package:flutter/material.dart';

import 'hip_theme.dart';
import 'hip_widgets.dart';

abstract final class HipCalmMotion {
  static const expand = Duration(milliseconds: 260);
  static const swap = Duration(milliseconds: 300);
  static const page = Duration(milliseconds: 350);
  static const stagger = Duration(milliseconds: 65);
  static const curve = Curves.easeInOutCubic;
  static const enter = Curves.easeOutCubic;

  static bool reduced(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  static Duration of(BuildContext context, Duration d) =>
      reduced(context) ? Duration.zero : d;
}

/// A translucent control/list surface. Light comes from a painted vertical
/// gradient and a 1px edge; nothing behind it is sampled or blurred.
class HipCalmSurface extends StatelessWidget {
  const HipCalmSurface({
    super.key,
    required this.child,
    this.radius = 22,
    this.circle = false,
    this.selected = false,
  });
  final Widget child;
  final double radius;
  final bool circle;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final dark = HipColors.isDark;
    final high = MediaQuery.maybeHighContrastOf(context) ?? false;
    const tint = Colors.white;
    final List<double> a = high
        ? (dark ? const [.16, .12, .14] : const [.98, .96, .98])
        : (dark ? const [.09, .045, .065] : const [.86, .7, .78]);
    final shape = circle
        ? const CircleBorder()
        : RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius));
    return DecoratedBox(
      decoration: ShapeDecoration(
        shape: shape,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0, .5, 1],
          colors: [for (final x in a) tint.withValues(alpha: x)],
        ),
        shadows: HipColors.shadows([
          BoxShadow(
            color: dark ? const Color(0x33000000) : const Color(0x0f1d2b25),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ]),
      ),
      position: DecorationPosition.background,
      child: DecoratedBox(
        decoration: ShapeDecoration(
          shape: circle
              ? CircleBorder(side: BorderSide(color: _edge(dark, high)))
              : RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(radius),
                  side: BorderSide(color: _edge(dark, high)),
                ),
        ),
        position: DecorationPosition.foreground,
        child: ClipPath(
          clipper: ShapeBorderClipper(shape: shape),
          child: child,
        ),
      ),
    );
  }

  static Color _edge(bool dark, bool high) => dark
      ? Colors.white.withValues(alpha: high ? .3 : .09)
      : (high ? HipColors.line : Colors.white.withValues(alpha: .9));
}

/// Round 38pt control on a calm surface (⋯, back).
class HipCalmRoundButton extends StatelessWidget {
  const HipCalmRoundButton({
    super.key,
    required this.child,
    required this.onTap,
    required this.semanticLabel,
    this.size = 40,
  });
  final Widget child;
  final VoidCallback? onTap;
  final String semanticLabel;
  final double size;

  @override
  Widget build(BuildContext context) => HipPressable(
    semanticLabel: semanticLabel,
    onTap: onTap,
    scale: .94,
    child: SizedBox.square(
      dimension: size,
      child: HipCalmSurface(circle: true, child: Center(child: child)),
    ),
  );
}

/// Three dots (⋯) drawn as circles, as in the approved mockup.
class HipMoreDots extends StatelessWidget {
  const HipMoreDots({super.key, this.color});
  final Color? color;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (var i = 0; i < 3; i++)
        Container(
          width: 4,
          height: 4,
          margin: EdgeInsets.only(left: i == 0 ? 0 : 3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color ?? HipColors.text,
          ),
        ),
    ],
  );
}

/// List entrance: fade + 12px rise, 65ms apart, easeOutCubic; none under
/// reduce motion.
class HipCalmStagger extends StatefulWidget {
  const HipCalmStagger({super.key, required this.index, required this.child});
  final int index;
  final Widget child;
  @override
  State<HipCalmStagger> createState() => _HipCalmStaggerState();
}

class _HipCalmStaggerState extends State<HipCalmStagger>
    with SingleTickerProviderStateMixin {
  // One controller per item, its delay folded into an Interval (no timers).
  late final Duration _delay = HipCalmMotion.stagger * widget.index;
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: HipCalmMotion.page + _delay,
  );
  late final Animation<double> _t = CurvedAnimation(
    parent: _c,
    curve: Interval(
      _delay.inMicroseconds / _c.duration!.inMicroseconds,
      1,
      curve: HipCalmMotion.enter,
    ),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (HipCalmMotion.reduced(context)) {
      _c.value = 1;
    } else {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _t,
    child: widget.child,
    builder: (context, child) => Opacity(
      opacity: _t.value,
      child: Transform.translate(
        offset: Offset(0, 12 * (1 - _t.value)),
        child: child,
      ),
    ),
  );
}
