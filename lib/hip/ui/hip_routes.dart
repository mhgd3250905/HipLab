import 'dart:math' as math;
import 'dart:ui' as ui show Image;
import 'dart:ui' show lerpDouble;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'hip_theme.dart';
import 'hip_widgets.dart' show HipMediaPolicy;

/// How a page enters (round 2 #4, reworked after the 2026-10-18 transition
/// audit). One transition has one main move: the page on top moves, the
/// page below only answers quietly (see [HipRoute.delegatedTransition]):
/// a parallax drift under a push, a dim under a rise or an expand — never
/// a second scale or slide of its own.
enum HipTransition {
  /// Drill-down (list → detail): slides in from the right edge; the page
  /// below moves left with parallax. iOS keeps the edge swipe back.
  push,

  /// A task page with no origin on screen: rises from the bottom; the page
  /// below only dims.
  rise,

  /// Container transform: the control that opened the page (the 开始
  /// button, a tile) grows into it — its shape and colour spread into the
  /// page background, then the page fades in over the second half — and
  /// shrinks back into the control on close. No Hero flies alongside.
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
    this.originImage,
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
  /// not laid out (e.g. it scrolled away). [color] is the control's fill;
  /// when the control is (or wraps) a [RepaintBoundary] of its own size,
  /// a snapshot of it is drawn at the start of the grow so frame 0 looks
  /// exactly like the control, then fades out as the shape spreads.
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
      originImage: _snapshot(box, from!),
    );
  }

  /// A picture of the control at its current state, or null.
  static ui.Image? _snapshot(RenderBox box, BuildContext context) {
    RenderRepaintBoundary? found;
    void visit(RenderObject o) {
      if (found != null) return;
      if (o is RenderRepaintBoundary && o.hasSize && o.size == box.size) {
        found = o;
        return;
      }
      o.visitChildren(visit);
    }

    visit(box);
    final boundary = found;
    if (boundary == null) return null;
    try {
      return boundary.toImageSync(
        pixelRatio: MediaQuery.maybeDevicePixelRatioOf(context) ?? 2,
      );
    } on Object {
      return null;
    }
  }

  final WidgetBuilder builder;
  final HipTransition transition;

  /// Global rect of the control an [HipTransition.expand] grows from.
  final Rect? origin;
  final double originRadius;

  /// Fill of that control; it turns into the page background as it grows.
  final Color? originColor;

  /// Snapshot of that control (see [expandFrom]); owned and disposed by
  /// the route.
  final ui.Image? originImage;

  @override
  void dispose() {
    originImage?.dispose();
    super.dispose();
  }

  /// The platform's "reduce motion" / "remove animations" setting. The
  /// framework already runs route controllers at 5 % of their duration
  /// then; this also swaps every move for a plain cross-fade.
  bool _reduceMotion(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

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
    final gesture =
        transition == HipTransition.push &&
        Theme.of(context).platform == TargetPlatform.iOS;
    if (_reduceMotion(context)) {
      return FadeTransition(
        opacity: animation,
        child: gesture ? _HipBackGesture(route: this, child: child) : child,
      );
    }
    final curved = linear
        ? animation
        : CurvedAnimation(
            parent: animation,
            curve: HipMotion.enter,
            reverseCurve: HipMotion.exit.flipped,
          );
    switch (transition) {
      case HipTransition.push:
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
        return _ExpandTransition(
          animation: animation,
          origin: origin!,
          originRadius: originRadius,
          originColor: originColor ?? HipColors.jade,
          originImage: originImage,
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
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final Animation<double> a = linear || reduce
        ? animation
        : CurvedAnimation(
            parent: animation,
            curve: kind == HipTransition.expand
                ? HipMotion.container
                : HipMotion.enter,
            reverseCurve: kind == HipTransition.expand
                ? HipMotion.container
                : HipMotion.exit.flipped,
          );
    // Only a push drifts (parallax, like iOS); a rise or an expand covers
    // the page in place, so the page below just dims. No scale: a second
    // moving layer is what made the old transitions feel busy.
    final drift = kind == HipTransition.push && !reduce;
    final dim = HipColors.isDark ? .32 : .14;
    return AnimatedBuilder(
      animation: a,
      builder: (context, child) {
        final t = a.value;
        return FractionalTranslation(
          translation: Offset(drift ? -.28 * t : 0, 0),
          child: Stack(
            fit: StackFit.passthrough,
            children: [
              child!,
              if (t > 0)
                Positioned.fill(
                  child: IgnorePointer(
                    child: ColoredBox(color: Color.fromRGBO(0, 0, 0, dim * t)),
                  ),
                ),
            ],
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

/// Container transform. On one clock (linear [animation], 0 → 1 open and
/// 1 → 0 close, so closing is the exact reverse):
///
/// * bounds: [origin] → full screen on [HipMotion.container], the corner
///   radius following the same progress;
/// * fill: the control's colour → the page background, t 0.05–0.45;
/// * the control's snapshot (its icon / label) fades out, t 0–0.20;
/// * the page fades in, t 0.35–0.85 (the second half of the grow), drawn
///   at the container's width so it grows with it instead of being
///   uncovered by the clip.
class _ExpandTransition extends StatelessWidget {
  const _ExpandTransition({
    required this.animation,
    required this.origin,
    required this.originRadius,
    required this.originColor,
    required this.originImage,
    required this.child,
  });
  final Animation<double> animation;
  final Rect origin;
  final double originRadius;
  final Color originColor;
  final ui.Image? originImage;
  final Widget child;

  static const _fill = Interval(.05, .45, curve: Curves.easeInOut);
  static const _originOut = Interval(0, .20, curve: Curves.easeOut);
  static const _contentIn = Interval(.35, .85, curve: Curves.easeInOut);

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: animation,
    builder: (context, child) {
      final t = animation.value.clamp(0.0, 1.0);
      final p = HipMotion.container.transform(t);
      final size = MediaQuery.sizeOf(context);
      final full = Offset.zero & size;
      final rect = Rect.lerp(origin, full, p)!;
      final radius = lerpDouble(originRadius, 0, p)!;
      final fill = Color.lerp(
        originColor,
        HipColors.background,
        _fill.transform(t),
      )!;
      final scale = size.width == 0 ? 1.0 : rect.width / size.width;
      final originOpacity = 1 - _originOut.transform(t);
      final image = originImage;
      // Fit the snapshot's width to the container while it fades.
      final k = origin.width == 0 ? 1.0 : rect.width / origin.width;
      return ClipPath(
        clipper: _RRectClipper(rect, radius),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: fill),
            Positioned(
              left: rect.left,
              top: rect.top,
              width: size.width,
              height: size.height,
              child: Transform.scale(
                scale: scale,
                alignment: Alignment.topLeft,
                child: Opacity(opacity: _contentIn.transform(t), child: child),
              ),
            ),
            if (image != null && originOpacity > 0)
              Positioned.fromRect(
                rect: Rect.fromCenter(
                  center: rect.center,
                  width: origin.width * k,
                  height: origin.height * k,
                ),
                child: IgnorePointer(
                  child: Opacity(
                    opacity: originOpacity,
                    child: RawImage(image: image, fit: BoxFit.fill),
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

/// Bottom-tab body switch, a fade through: the old tab fades out quickly
/// (first 35 % of [HipMotion.tab]) without moving, then the new one fades
/// in while drifting a short way in from the tapped tab's side (higher
/// index from the right, lower from the left). The two never show at
/// half opacity together (the old cross-fade read as a double exposure).
class HipTabSwitcher extends StatefulWidget {
  const HipTabSwitcher({
    super.key,
    required this.index,
    required this.direction,
    required this.child,
  });

  final int index;
  final int direction;
  final Widget child;
  static const shift = .08;

  static const _out = Interval(0, .35, curve: Curves.easeIn);
  static const _in = Interval(.35, 1, curve: Curves.easeOut);
  static const _drift = Interval(.2, 1, curve: HipMotion.enter);

  @override
  State<HipTabSwitcher> createState() => _HipTabSwitcherState();
}

class _HipTabSwitcherState extends State<HipTabSwitcher> {
  final _pages = <int, Widget>{};
  final _visible = <int>{};
  final _directions = <int, int>{};
  late final int _initialIndex;

  @override
  void initState() {
    super.initState();
    _initialIndex = widget.index;
    _pages[widget.index] = widget.child;
    _visible.add(widget.index);
    _directions[widget.index] = widget.direction;
  }

  @override
  void didUpdateWidget(HipTabSwitcher old) {
    super.didUpdateWidget(old);
    // One persistent slot per tab. Returning before an outgoing animation
    // ends updates that same slot instead of mounting its GlobalKeys twice.
    _pages[widget.index] = widget.child;
    if (old.index != widget.index) {
      _visible.add(widget.index);
      _directions[old.index] = -widget.direction;
      _directions[widget.index] = widget.direction;
    }
  }

  void _settled(int index) {
    if (index != widget.index && _visible.contains(index) && mounted) {
      setState(() => _visible.remove(index));
    }
  }

  @override
  Widget build(BuildContext context) {
    final videosAllowed =
        HipMediaPolicy.of(context) && ModalRoute.isCurrentOf(context) != false;
    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          for (final entry in _pages.entries)
            TweenAnimationBuilder<double>(
              key: ValueKey('tab-slot-${entry.key}'),
              tween: Tween(
                begin: entry.key == _initialIndex ? 1.0 : 0.0,
                end: entry.key == widget.index ? 1.0 : 0.0,
              ),
              duration: HipMotion.tab,
              onEnd: () => _settled(entry.key),
              builder: (context, v, child) {
                // [v] runs linearly: 0 → 1 for the tab coming in, 1 → 0 for
                // the one going out.
                final incoming = entry.key == widget.index;
                final reduce =
                    MediaQuery.maybeDisableAnimationsOf(context) ?? false;
                final opacity = incoming
                    ? HipTabSwitcher._in.transform(v)
                    : 1 - HipTabSwitcher._out.transform(1 - v);
                final dx = incoming && !reduce
                    ? (_directions[entry.key] ?? 1) *
                          HipTabSwitcher.shift *
                          (1 - HipTabSwitcher._drift.transform(v))
                    : 0.0;
                return Offstage(
                  offstage: !_visible.contains(entry.key),
                  child: IgnorePointer(
                    ignoring: entry.key != widget.index,
                    child: ExcludeSemantics(
                      excluding: entry.key != widget.index,
                      child: FocusScope(
                        canRequestFocus: entry.key == widget.index,
                        child: HeroMode(
                          enabled: entry.key == widget.index,
                          child: SlideTransition(
                            position: AlwaysStoppedAnimation(Offset(dx, 0)),
                            child: FadeTransition(
                              opacity: AlwaysStoppedAnimation(opacity),
                              child: TickerMode(
                                enabled: entry.key == widget.index,
                                child: HipMediaPolicy(
                                  videoEnabled:
                                      videosAllowed &&
                                      entry.key == widget.index,
                                  child: child!,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
              child: entry.value,
            ),
        ],
      ),
    );
  }
}
