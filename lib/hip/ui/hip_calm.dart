// Calm surfaces and motion for 首页 / 更多 (home redesign r1, 2026-11-02;
// glass m2): surfaces are the shared glass (hip_glass.dart) — blur only
// where content is behind — one accent (jade), one motion rhythm,
// reduce-motion honoured.
import 'package:flutter/material.dart';

import 'hip_glass.dart';
import 'hip_theme.dart';

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

/// A translucent control/list surface: the shared glass (hip_glass.dart).
/// [blur] only where content sits behind it (see HipGlass).
class HipCalmSurface extends StatelessWidget {
  const HipCalmSurface({
    super.key,
    required this.child,
    this.radius = 22,
    this.circle = false,
    this.selected = false,
    this.blur = false,
  });
  final Widget child;
  final double radius;
  final bool circle;
  final bool selected;
  final bool blur;

  @override
  Widget build(BuildContext context) => selected
      ? HipGlassPill(radius: circle ? 999 : radius, child: child)
      : HipGlass(
          shape: circle ? HipGlassShape.circle : HipGlassShape.rounded,
          radius: radius,
          blur: blur,
          child: child,
        );
}

/// Round 40pt control on glass (⋯, back).
class HipCalmRoundButton extends StatelessWidget {
  const HipCalmRoundButton({
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
  Widget build(BuildContext context) => HipGlassRoundButton(
    semanticLabel: semanticLabel,
    onTap: onTap,
    size: size,
    blur: blur,
    child: child,
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
