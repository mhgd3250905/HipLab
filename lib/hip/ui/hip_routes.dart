import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'hip_theme.dart';

/// How a page enters (round 2 #4). The page that is covered always answers
/// in the opposite direction (see [HipRoute.delegatedTransition]): it drifts
/// back, shrinks a little and dims, so the two read as layers.
enum HipTransition {
  /// Drill-down (list → detail): slides in from the right edge; the page
  /// below moves left with parallax. iOS keeps the edge swipe back.
  push,

  /// A task page with no origin on screen: rises from the bottom; the page
  /// below sinks back.
  rise,

  /// Container transform: the page grows out of the control that opened it
  /// (the 开始 button, a tile) and shrinks back into it on close.
  expand,
}

/// The one page route of the app. Durations and curves come from
/// [HipMotion]; every push names its [transition].
class HipRoute<T> extends PageRoute<T> {
  HipRoute({
    required this.builder,
    this.transition = HipTransition.push,
    this.origin,
    this.originRadius = 28,
    this.originColor,
    super.settings,
  }) : assert(transition != HipTransition.expand || origin != null);

  /// Slide in from the right (drill-down).
  static HipRoute<T> push<T>(WidgetBuilder builder) =>
      HipRoute<T>(builder: builder);

  /// Rise from the bottom (no on-screen origin).
  static HipRoute<T> rise<T>(WidgetBuilder builder) =>
      HipRoute<T>(builder: builder, transition: HipTransition.rise);

  /// Grow out of the widget whose context is [from] (a tapped button's
  /// context, or `key.currentContext`); rises instead when that widget is
  /// not laid out (e.g. it scrolled away).
  static HipRoute<T> expandFrom<T>(
    BuildContext? from,
    WidgetBuilder builder, {
    double radius = 28,
    Color? color,
  }) {
    final box = from?.findRenderObject();
    if (box is! RenderBox || !box.hasSize || !box.attached) {
      return rise<T>(builder);
    }
    final rect = box.localToGlobal(Offset.zero) & box.size;
    return HipRoute<T>(
      builder: builder,
      transition: HipTransition.expand,
      origin: rect,
      originRadius: radius,
      originColor: color,
    );
  }

  final WidgetBuilder builder;
  final HipTransition transition;

  /// Global rect of the control an [HipTransition.expand] grows from.
  final Rect? origin;
  final double originRadius;

  /// Fill of that control; it cross-fades into the page as it grows.
  final Color? originColor;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration =>
      transition == HipTransition.expand ? HipMotion.expand : HipMotion.page;

  @override
  Duration get reverseTransitionDuration => transition == HipTransition.expand
      ? HipMotion.expandReverse
      : HipMotion.pageReverse;

  @override
  bool canTransitionTo(TransitionRoute<dynamic> nextRoute) =>
      nextRoute is ModalRoute && nextRoute.delegatedTransition != null;

  @override
  bool canTransitionFrom(TransitionRoute<dynamic> previousRoute) =>
      previousRoute is PageRoute;

  /// What the page *below* does while this one enters or leaves. A fresh
  /// closure each time, so a [HipRoute] below a [HipRoute] still receives
  /// it (routes skip a delegate equal to their own).
  @override
  DelegatedTransitionBuilder? get delegatedTransition =>
      (context, animation, secondaryAnimation, allowSnapshotting, child) =>
          HipCoveredTransition(
            animation: secondaryAnimation,
            kind: transition,
            linear: popGestureInProgress,
            child: child,
          );

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) => Semantics(
    scopesRoute: true,
    explicitChildNodes: true,
    child: builder(context),
  );

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final linear = popGestureInProgress;
    final curved = linear
        ? animation
        : CurvedAnimation(
            parent: animation,
            curve: HipMotion.emphasizedDecelerate,
            reverseCurve: HipMotion.emphasizedAccelerate.flipped,
          );
    switch (transition) {
      case HipTransition.push:
        final gesture = Theme.of(context).platform == TargetPlatform.iOS;
        return SlideTransition(
          position: Tween(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(curved),
          child: _EdgeShadow(
            child: gesture ? _HipBackGesture(route: this, child: child) : child,
          ),
        );
      case HipTransition.rise:
        return SlideTransition(
          position: Tween(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        );
      case HipTransition.expand:
        // Container transform runs on the symmetric emphasized curve both
        // ways (Material's container-transform easing).
        return _ExpandTransition(
          animation: CurvedAnimation(
            parent: animation,
            curve: HipMotion.emphasized,
          ),
          origin: origin!,
          originRadius: originRadius,
          originColor: originColor ?? HipColors.jade,
          child: child,
        );
    }
  }

  // ── iOS edge swipe back (the same contract as Cupertino's) ──

  bool get _gestureEnabled => popGestureEnabled;

  void _gestureStart() => navigator!.didStartUserGesture();

  void _gestureUpdate(double delta) => controller!.value -= delta;

  void _gestureEnd(double velocity) {
    final c = controller!;
    final nav = navigator!;
    final bool forward;
    if (!isCurrent) {
      forward = isActive;
    } else if (velocity.abs() >= 1.0) {
      forward = velocity <= 0;
    } else {
      forward = c.value > .5;
    }
    const curve = Curves.fastEaseInToSlowEaseOut;
    final duration = Duration(
      milliseconds: math.max(
        120,
        (HipMotion.pageReverse.inMilliseconds *
                (forward ? 1 - c.value : c.value))
            .round(),
      ),
    );
    if (forward) {
      c.animateTo(1, duration: duration, curve: curve);
    } else {
      if (isCurrent) nav.pop();
      if (c.isAnimating) {
        c.animateBack(0, duration: duration, curve: curve);
      }
    }
    if (c.isAnimating) {
      late AnimationStatusListener done;
      done = (status) {
        nav.didStopUserGesture();
        c.removeStatusListener(done);
      };
      c.addStatusListener(done);
    } else {
      nav.didStopUserGesture();
    }
  }
}

/// The covered page's answer to [HipRoute] entering on top of it. Public so
/// tests can find it.
class HipCoveredTransition extends StatelessWidget {
  const HipCoveredTransition({
    super.key,
    required this.animation,
    required this.kind,
    required this.child,
    this.linear = false,
  });
  final Animation<double> animation;
  final HipTransition kind;
  final bool linear;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final a = linear
        ? animation
        : CurvedAnimation(
            parent: animation,
            curve: HipMotion.emphasizedDecelerate,
            reverseCurve: HipMotion.emphasizedAccelerate.flipped,
          );
    final dim = HipColors.isDark ? .45 : .18;
    return AnimatedBuilder(
      animation: a,
      builder: (context, child) {
        final t = a.value;
        if (t == 0) return child!;
        final dx = kind == HipTransition.push ? -.28 * t : 0.0;
        final scale = kind == HipTransition.push ? 1 - .03 * t : 1 - .06 * t;
        // What shows around the shrunken page: black on dark, a deeper
        // paper tone on light (never the window's white).
        return ColoredBox(
          color: HipColors.isDark
              ? const Color(0xff000000)
              : const Color(0xffd9ddda),
          child: FractionalTranslation(
            translation: Offset(dx, 0),
            child: Transform.scale(
              scale: scale,
              child: Stack(
                fit: StackFit.passthrough,
                children: [
                  child!,
                  Positioned.fill(
                    child: IgnorePointer(
                      child: ColoredBox(
                        color: Color.fromRGBO(0, 0, 0, dim * t),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      child: child,
    );
  }
}

/// Soft shadow along the incoming page's leading edge while it slides (it
/// sits just off the page, so once the page has landed it is off-screen).
class _EdgeShadow extends StatelessWidget {
  const _EdgeShadow({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Stack(
    clipBehavior: Clip.none,
    fit: StackFit.passthrough,
    children: [
      const Positioned(
        left: -20,
        top: 0,
        bottom: 0,
        width: 20,
        child: IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0x00000000), Color(0x26000000)],
              ),
            ),
          ),
        ),
      ),
      child,
    ],
  );
}

/// Container transform: a rounded clip grows from [origin] to the full page
/// while the control's colour fades out and the page fades in over it.
class _ExpandTransition extends StatelessWidget {
  const _ExpandTransition({
    required this.animation,
    required this.origin,
    required this.originRadius,
    required this.originColor,
    required this.child,
  });
  final Animation<double> animation;
  final Rect origin;
  final double originRadius;
  final Color originColor;
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: animation,
    builder: (context, child) {
      final t = animation.value.clamp(0.0, 1.0);
      final size = MediaQuery.sizeOf(context);
      final full = Offset.zero & size;
      final rect = Rect.lerp(origin, full, t)!;
      // Rounded all the way, settling to the screen's own corner feel.
      final radius = lerpDouble(originRadius, 0, Curves.easeIn.transform(t))!;
      final contentIn = const Interval(.18, .7).transform(t);
      final tintOut = 1 - const Interval(0, .55).transform(t);
      return ClipPath(
        clipper: _RRectClipper(rect, radius),
        child: Stack(
          fit: StackFit.passthrough,
          children: [
            ColoredBox(
              color: HipColors.background,
              child: const SizedBox.expand(),
            ),
            Opacity(opacity: contentIn, child: child),
            if (tintOut > 0)
              Positioned.fill(
                child: IgnorePointer(
                  child: ColoredBox(
                    color: originColor.withValues(
                      alpha: originColor.a * tintOut,
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    },
    child: child,
  );
}

class _RRectClipper extends CustomClipper<Path> {
  _RRectClipper(this.rect, this.radius);
  final Rect rect;
  final double radius;
  @override
  Path getClip(Size size) =>
      Path()..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)));
  @override
  bool shouldReclip(_RRectClipper old) =>
      old.rect != rect || old.radius != radius;
}

/// Left-edge horizontal drag that drives the route back (iOS).
class _HipBackGesture extends StatefulWidget {
  const _HipBackGesture({required this.route, required this.child});
  final HipRoute<dynamic> route;
  final Widget child;
  @override
  State<_HipBackGesture> createState() => _HipBackGestureState();
}

class _HipBackGestureState extends State<_HipBackGesture> {
  HorizontalDragGestureRecognizer? _drag;
  bool _active = false;

  @override
  void initState() {
    super.initState();
    _drag = HorizontalDragGestureRecognizer(debugOwner: this)
      ..onStart = _start
      ..onUpdate = _update
      ..onEnd = _end
      ..onCancel = _cancel;
  }

  @override
  void dispose() {
    _drag?.dispose();
    if (_active) widget.route.navigator?.didStopUserGesture();
    super.dispose();
  }

  double get _width => context.size?.width ?? 1;

  void _start(DragStartDetails d) {
    _active = true;
    widget.route._gestureStart();
  }

  void _update(DragUpdateDetails d) {
    if (!_active) return;
    widget.route._gestureUpdate(d.primaryDelta! / _width);
  }

  void _end(DragEndDetails d) {
    if (!_active) return;
    _active = false;
    widget.route._gestureEnd(d.velocity.pixelsPerSecond.dx / _width);
  }

  void _cancel() {
    if (!_active) return;
    _active = false;
    widget.route._gestureEnd(0);
  }

  void _pointerDown(PointerDownEvent e) {
    if (widget.route._gestureEnabled) _drag?.addPointer(e);
  }

  @override
  Widget build(BuildContext context) {
    final edge = math.max(20.0, MediaQuery.paddingOf(context).left);
    return Stack(
      fit: StackFit.passthrough,
      children: [
        widget.child,
        PositionedDirectional(
          start: 0,
          width: edge,
          top: 0,
          bottom: 0,
          child: Listener(
            key: const ValueKey('hip-back-edge'),
            onPointerDown: _pointerDown,
            behavior: HitTestBehavior.translucent,
          ),
        ),
      ],
    );
  }
}

/// Bottom-tab body switch: slides toward the tapped tab's side (higher index
/// enters from the right, lower from the left) with a cross-fade.
class HipTabSwitcher extends StatelessWidget {
  const HipTabSwitcher({
    super.key,
    required this.index,
    required this.direction,
    required this.child,
  });

  /// Current tab; the child must be keyed by it.
  final int index;

  /// +1 when moving to a higher index, −1 to a lower one.
  final int direction;
  final Widget child;

  static const shift = .14;

  @override
  Widget build(BuildContext context) => ClipRect(
    child: AnimatedSwitcher(
      duration: HipMotion.tab,
      reverseDuration: HipMotion.tab,
      layoutBuilder: (current, previous) => Stack(
        alignment: Alignment.topCenter,
        children: [...previous, ?current],
      ),
      transitionBuilder: (child, animation) {
        final incoming = child.key == this.child.key;
        final dx = (incoming ? 1 : -1) * direction * shift;
        final curved = CurvedAnimation(
          parent: animation,
          curve: HipMotion.emphasizedDecelerate,
        );
        return IgnorePointer(
          ignoring: !incoming,
          child: FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: incoming ? const Interval(.1, 1) : const Interval(.35, 1),
            ),
            child: SlideTransition(
              position: Tween(
                begin: Offset(dx, 0),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          ),
        );
      },
      child: child,
    ),
  );
}
