import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';

import '../domain/hip_models.dart';
import 'hip_icons.dart';
import 'hip_home_action_inspect.dart';
import 'hip_card_snapshot.dart';
import 'hip_theme.dart';
import 'hip_widgets.dart';

/// A bounded, poster-only preview of the actual plan, in its original order.
/// The local index never leaves this widget or changes a training plan.
class HipHomeActionDeck extends StatefulWidget {
  const HipHomeActionDeck({
    super.key,
    required this.identity,
    required this.drills,
    this.doses = const [],
    this.cues = const [],
    this.descriptions = const [],
  });

  final String identity;
  final List<HipDrill> drills;
  final List<String> doses;
  final List<String> cues;
  final List<String> descriptions;

  @override
  State<HipHomeActionDeck> createState() => _HipHomeActionDeckState();
}

class _HipHomeActionDeckState extends State<HipHomeActionDeck>
    with TickerProviderStateMixin {
  late final AnimationController _position;
  late final AnimationController _vertical;
  final _overlay = OverlayPortalController();
  final _frontAnchor = GlobalKey();
  bool _floating = false;
  bool _expanded = false;
  bool _opening = false;
  int _inspectionGeneration = 0;
  int _index = 0;
  int _toward = 1;
  int _generation = 0;
  bool _committing = false;
  double _cardWidth = 1;
  double _exitDistance = 1;
  double _switchDistance = 1;
  bool _lastReduced = false;
  Size? _viewport;
  bool get _multiple => widget.drills.length > 1;
  bool get _reduced => MediaQuery.disableAnimationsOf(context);

  @override
  void initState() {
    super.initState();
    _position = AnimationController.unbounded(vsync: this);
    _vertical = AnimationController.unbounded(vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final viewport = MediaQuery.sizeOf(context);
    final resized = _viewport != null && _viewport != viewport;
    if ((_reduced && !_lastReduced) || resized) {
      _generation++;
      _position.stop();
      _vertical.stop();
      if (_committing) _index = _at(_toward);
      _committing = false;
      _position.value = 0;
      _vertical.value = 0;
      _finishFloating();
    }
    _lastReduced = _reduced;
    _viewport = viewport;
  }

  @override
  void didUpdateWidget(HipHomeActionDeck oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.identity != widget.identity ||
        !listEqualsIds(oldWidget.drills, widget.drills)) {
      _generation++;
      _position.stop();
      _vertical.stop();
      _position.value = 0;
      _vertical.value = 0;
      _finishFloating();
      _index = 0;
      _toward = 1;
      _committing = false;
    }
  }

  static bool listEqualsIds(List<HipDrill> a, List<HipDrill> b) =>
      a.length == b.length &&
      Iterable.generate(a.length).every((i) => a[i].id == b[i].id);

  @override
  void dispose() {
    _generation++;
    _position.dispose();
    _vertical.dispose();
    super.dispose();
  }

  int _at(int offset) => (_index + offset) % widget.drills.length;

  void _floatFront() {
    if (_reduced || _floating) return;
    setState(() => _floating = true);
    _overlay.show();
  }

  void _finishFloating() {
    _floating = false;
    if (!_overlay.isShowing) return;
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      // Identity/viewport changes arrive during build; the portal cannot be
      // hidden in that phase. Its builder already paints nothing this frame.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_floating && _overlay.isShowing) _overlay.hide();
      });
    } else {
      _overlay.hide();
    }
  }

  Future<void> _openCard([TapUpDetails? details]) async {
    if (_expanded || _opening || _floating || _position.isAnimating) return;
    final box = _frontAnchor.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final rect = MatrixUtils.transformRect(
      box.getTransformTo(null),
      Offset.zero & box.size,
    );
    if (details != null && !rect.contains(details.globalPosition)) return;
    final index = _index;
    final generation = _generation;
    final inspection = ++_inspectionGeneration;
    final overlayContext = Overlay.of(context, rootOverlay: true).context;
    final pixelRatio = MediaQuery.devicePixelRatioOf(context);
    _opening = true;
    HipCardSnapshot? snapshot;
    void restoreSource() {
      if (mounted && inspection == _inspectionGeneration && _expanded) {
        setState(() => _expanded = false);
      }
    }

    try {
      snapshot = HipCardSnapshotBoundary.captureFrom(
        _frontAnchor.currentContext!,
        overlayContext,
        pixelRatio: pixelRatio,
      );
      if (snapshot == null) {
        // An image completing its first paint can dirty the boundary on tap.
        // Keep the live card visible while waiting for that paint to finish.
        await WidgetsBinding.instance.endOfFrame;
        if (!mounted || generation != _generation || index != _index) return;
        final anchor = _frontAnchor.currentContext;
        if (anchor != null && anchor.mounted && overlayContext.mounted) {
          snapshot = HipCardSnapshotBoundary.captureFrom(
            anchor,
            overlayContext,
            pixelRatio: pixelRatio,
          );
        }
      }
      if (!mounted || generation != _generation || index != _index) return;
      _opening = false;
      setState(() => _expanded = true);
      await showHipHomeActionCard(
        context,
        sourceRect: rect,
        drill: widget.drills[index],
        number: index + 1,
        dose: widget.doses.elementAtOrNull(index) ?? '',
        cue: widget.cues.elementAtOrNull(index) ?? '',
        description: widget.descriptions.elementAtOrNull(index) ?? '',
        sourceSnapshot: snapshot,
        onSourceRestored: restoreSource,
      );
    } finally {
      if (inspection == _inspectionGeneration) _opening = false;
      snapshot?.dispose();
      restoreSource();
    }
  }

  void _dragStart(DragStartDetails details) {
    if (_committing || _expanded || _opening) return;
    // Catch a returning card where it is, rather than jumping it to rest.
    _generation++;
    _position.stop();
    _vertical.stop();
    _floatFront();
  }

  void _dragUpdate(DragUpdateDetails details) {
    if (_committing || _expanded || _opening) return;
    final next = _position.value + details.delta.dx;
    final nextVertical = _vertical.value + details.delta.dy;
    // Small sideways drift while lifting vertically must not swap the rear
    // faces under the finger. Change browsing direction only for a lateral drag.
    if (next.abs() > 8 && next.abs() > nextVertical.abs()) {
      _toward = next < 0 ? 1 : -1;
    }
    _position.value = next;
    _vertical.value = nextVertical;
  }

  void _dragEnd(DragEndDetails details) {
    if (_committing || _expanded) return;
    final velocity = details.velocity.pixelsPerSecond.dx;
    final verticalVelocity = details.velocity.pixelsPerSecond.dy;
    final distance = _position.value;
    // A diagonal trip toward the top/bottom is still a vertical gesture, even
    // if it happens to cross a horizontal boundary on the way.
    final far =
        _multiple &&
        distance.abs() > _switchDistance &&
        distance.abs() > _vertical.value.abs();
    final flick = velocity.abs() > 650;
    if (far && flick && velocity * distance < 0) {
      // A deliberate flick back toward the stack cancels this preview.
      _returnCard(velocity, verticalVelocity);
      return;
    }
    if (far) {
      // Once the next card is exposed, a last-moment velocity reversal must
      // not replace it with a different image under the user's hand.
      final direction = _toward;
      _turn(direction, velocity: velocity);
    } else {
      _returnCard(velocity, verticalVelocity);
    }
  }

  Future<void> _returnCard([
    double velocity = 0,
    double verticalVelocity = 0,
  ]) async {
    if (_committing) return;
    // The pan recognizer is also cancelled when a tap wins the gesture arena.
    // Starting a zero-distance spring there would block the tap-to-open action.
    if (!_floating && _position.value == 0 && _vertical.value == 0) return;
    if (_reduced) {
      _position.value = 0;
      _vertical.value = 0;
      setState(_finishFloating);
      return;
    }
    final generation = ++_generation;
    try {
      await Future.wait([
        _vertical
            .animateWith(
              SpringSimulation(
                const SpringDescription(mass: 1, stiffness: 310, damping: 29),
                _vertical.value,
                0,
                verticalVelocity.clamp(-1800.0, 1800.0),
                tolerance: const Tolerance(distance: .2, velocity: 2),
              ),
            )
            .orCancel,
        _position
            .animateWith(
              SpringSimulation(
                const SpringDescription(mass: 1, stiffness: 310, damping: 29),
                _position.value,
                0,
                velocity.clamp(-1800.0, 1800.0),
                tolerance: const Tolerance(distance: .2, velocity: 2),
              ),
            )
            .orCancel,
      ]);
    } on TickerCanceled {
      return;
    }
    // A spring stops within tolerance, not necessarily at zero. Finish exactly
    // at rest so the hidden reserve is removed after a cancelled drag.
    if (mounted && generation == _generation && !_committing) {
      _position.value = 0;
      _vertical.value = 0;
      setState(_finishFloating);
    }
  }

  Future<void> _turn(int direction, {double velocity = 0}) async {
    if (!_multiple || _committing || _opening || _expanded) return;
    _toward = direction;
    final generation = ++_generation;
    _position.stop();
    _vertical.stop();
    if (!_reduced) {
      _floatFront();
      _committing = true;
      try {
        await _position
            .animateWith(
              _DeckExitSpring(
                _position.value,
                -direction * _exitDistance * 1.12,
                velocity.clamp(-2400.0, 2400.0),
                _exitDistance,
              ),
            )
            .orCancel;
      } on TickerCanceled {
        return;
      }
    }
    if (!mounted || generation != _generation) return;
    setState(() {
      _index = _at(direction);
      _committing = false;
      _position.value = 0;
      _vertical.value = 0;
      _finishFloating();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.drills.isEmpty) return const SizedBox.shrink();
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: '训练动作预览',
      onTap: _openCard,
      value: _description(_index),
      increasedValue: _multiple ? _description(_at(1)) : null,
      decreasedValue: _multiple ? _description(_at(-1)) : null,
      hint: '轻点展开动作，拖到左右区域切换，上下拖动松手回位',
      onIncrease: _multiple ? () => _turn(1) : null,
      onDecrease: _multiple ? () => _turn(-1) : null,
      child: FocusableActionDetector(
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.arrowLeft): _DeckTurnIntent(-1),
          SingleActivator(LogicalKeyboardKey.arrowRight): _DeckTurnIntent(1),
        },
        actions: {
          _DeckTurnIntent: CallbackAction<_DeckTurnIntent>(
            onInvoke: (intent) {
              _turn(intent.direction);
              return null;
            },
          ),
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            final available = math.max(0.0, constraints.maxHeight - 110);
            if (available < 110) return const SizedBox.shrink();
            _cardWidth = math.min(
              constraints.maxWidth * .78,
              math.max(156, available / 1.62),
            );
            _exitDistance = (constraints.maxWidth + _cardWidth) / 2 + 70;
            _switchDistance = MediaQuery.sizeOf(context).width * .26;
            final cardHeight = math.min(available, _cardWidth * 1.62);
            return Align(
              alignment: const Alignment(0, .2),
              child: OverlayPortal.overlayChildLayoutBuilder(
                controller: _overlay,
                overlayLocation: OverlayChildLocation.rootOverlay,
                overlayChildBuilder: (context, info) {
                  if (!_floating) return const SizedBox.shrink();
                  return Positioned.fromRect(
                    rect: MatrixUtils.transformRect(
                      info.childPaintTransform,
                      Offset.zero & info.childSize,
                    ),
                    child: IgnorePointer(
                      child: AnimatedBuilder(
                        animation: Listenable.merge([_position, _vertical]),
                        builder: (context, _) => Stack(
                          clipBehavior: Clip.none,
                          fit: StackFit.expand,
                          children: [
                            _card(
                              _index,
                              0,
                              constraints.maxWidth,
                              cardHeight,
                              offset: _reduced ? 0 : _position.value,
                              front: true,
                              floatingCopy: true,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
                child: SizedBox(
                  height: cardHeight + 100,
                  child: GestureDetector(
                    key: const ValueKey('home-deck-gesture'),
                    behavior: HitTestBehavior.opaque,
                    dragStartBehavior: DragStartBehavior.down,
                    onPanStart: _dragStart,
                    onPanUpdate: _dragUpdate,
                    onPanEnd: _dragEnd,
                    onPanCancel: _returnCard,
                    onTapUp: _openCard,
                    child: ClipRect(
                      clipper: _DeckViewportClip(
                        math.max(
                          0,
                          (MediaQuery.sizeOf(context).width -
                                  constraints.maxWidth) /
                              2,
                        ),
                      ),
                      child: AnimatedBuilder(
                        animation: Listenable.merge([_position, _vertical]),
                        builder: (context, _) =>
                            _cards(constraints.maxWidth, cardHeight),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  String _description(int index) {
    final dose = widget.doses.elementAtOrNull(index) ?? '';
    return '第 ${index + 1} 个，共 ${widget.drills.length} 个，${widget.drills[index].name}'
        '${dose.isEmpty ? '' : '，$dose'}';
  }

  Widget _arrow(int direction) => SizedBox.square(
    dimension: 44,
    child: _multiple
        ? HipPressable(
            semanticLabel: direction == 1 ? '下一个动作' : '上一个动作',
            onTap: () => _turn(direction),
            child: Center(
              child: HipIcon(
                direction == 1 ? HipGlyph.chevronRight : HipGlyph.back,
                size: 15,
                color: HipColors.muted,
              ),
            ),
          )
        : const SizedBox.shrink(),
  );

  Widget _cards(double width, double height) {
    final raw = _position.value;
    final offset = _reduced ? 0.0 : raw;
    final progress = (offset.abs() / _cardWidth).clamp(0.0, 1.0);
    final count = math.min(3, widget.drills.length);
    return Stack(
      clipBehavior: Clip.none,
      fit: StackFit.expand,
      children: [
        // Replenish underneath the last card while the stack advances. Starting
        // at that card's resting pose lets its movement uncover the new face;
        // the final pose is already correct when the front index commits.
        if (count > 1 && progress > 0)
          _card(
            _at(count * _toward),
            (count - 1).toDouble(),
            width,
            height,
            offset: 0,
            front: false,
            replenishing: true,
            opacity: Curves.easeOut.transform((progress / .3).clamp(0, 1)),
          ),
        for (var layer = count - 1; layer >= 0; layer--)
          _card(
            _at(layer * _toward),
            layer == 0 ? 0 : layer - progress,
            width,
            height,
            offset: layer == 0 ? offset : 0,
            front: layer == 0,
            opacity: layer == 0 && (_floating || _expanded) ? 0 : 1,
          ),
      ],
    );
  }

  Widget _card(
    int index,
    double depth,
    double width,
    double height, {
    required double offset,
    required bool front,
    bool replenishing = false,
    double opacity = 1,
    bool floatingCopy = false,
  }) {
    final travel = (offset / _cardWidth).clamp(-1.5, 1.5);
    final vertical = _reduced ? 0.0 : _vertical.value;
    final lift = front
        ? math.sin(
            (Offset(offset, vertical).distance / _cardWidth).clamp(0, 1) *
                math.pi /
                2,
          )
        : 0.0;
    final angle = -.025 + depth * .105 + (front ? travel * .18 : 0);
    final dark = HipColors.isDark;
    final high = MediaQuery.highContrastOf(context);
    final tilt = Matrix4.identity()
      ..setEntry(3, 2, .0012)
      ..rotateX(
        .018 + (front ? (vertical / _cardWidth).clamp(-1, 1) * -.04 : 0),
      )
      ..rotateY(-.10 + (front ? travel * .19 : 0));
    return Positioned(
      key: ValueKey(
        '${floatingCopy ? 'home-deck-floating-card' : 'home-deck-card'}-$index'
        '${replenishing && widget.drills.length <= 3 ? '-reserve' : ''}',
      ),
      left: (width - _cardWidth) / 2 - 18 + depth * 16 + offset,
      top: 74 - depth * 26 - lift * 18 + (front ? vertical : 0),
      width: _cardWidth,
      height: height,
      child: Opacity(
        key: floatingCopy
            ? const ValueKey('home-deck-floating-front')
            : ValueKey('home-deck-opacity-$index'),
        opacity: opacity,
        child: Transform.rotate(
          key: front && !floatingCopy
              ? const ValueKey('home-deck-front')
              : null,
          alignment: const Alignment(0, .8),
          angle: angle,
          child: Transform(
            alignment: const Alignment(0, .8),
            transform: tilt,
            child: Transform.scale(
              scale: (1 - depth * .045) * (1 + lift * .018),
              alignment: const Alignment(0, .8),
              child: ExcludeSemantics(
                excluding: !front || floatingCopy,
                child: IgnorePointer(
                  ignoring: !front,
                  child: HipCardSnapshotBoundary(
                    key: front && !floatingCopy ? _frontAnchor : null,
                    child: Stack(
                      clipBehavior: Clip.none,
                      fit: StackFit.expand,
                      children: [
                        // A quiet contact shadow, without a painted grey ledge.
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(22),
                              boxShadow: HipColors.shadows([
                                BoxShadow(
                                  color: Colors.black.withValues(
                                    alpha: dark ? .32 : .085,
                                  ),
                                  blurRadius: front ? 20 + lift * 10 : 12,
                                  offset: Offset(0, front ? 7 + lift * 6 : 4),
                                ),
                                BoxShadow(
                                  color: Colors.black.withValues(
                                    alpha: dark ? .2 : .035,
                                  ),
                                  blurRadius: 3,
                                  offset: const Offset(0, 1),
                                ),
                              ]),
                            ),
                          ),
                        ),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: HipColors.mediaBackdrop,
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(22),
                            child: _poster(
                              index,
                              front: front,
                              keyed: !floatingCopy,
                            ),
                          ),
                        ),
                        IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: high
                                    ? HipColors.text
                                    : Colors.white.withValues(
                                        alpha: dark ? .13 : .8,
                                      ),
                                width: high ? 1.5 : 1,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _poster(int index, {required bool front, bool keyed = true}) {
    final drill = widget.drills[index];
    final dose = widget.doses.elementAtOrNull(index) ?? '';
    final cue = widget.cues.elementAtOrNull(index) ?? '';
    return LayoutBuilder(
      builder: (context, box) {
        final compact = box.maxHeight < 330;
        final inset = compact ? 10.0 : 22.0;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ExcludeSemantics(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  inset,
                  compact ? 8 : 20,
                  inset,
                  compact ? 2 : 8,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'HIPLAB',
                            style: TextStyle(
                              fontSize: compact ? 8 : 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2.4,
                              color: HipColors.jadeText,
                            ),
                          ),
                          if (!compact) ...[
                            const SizedBox(height: 4),
                            Text(
                              drill.methods.firstOrNull?.zh ?? '动作练习',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10,
                                color: HipColors.muted,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Text(
                      (index + 1).toString().padLeft(2, '0'),
                      key: front && keyed
                          ? const ValueKey('home-deck-position')
                          : null,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: compact ? 10 : 17,
                        fontWeight: FontWeight.w500,
                        letterSpacing: .5,
                        color: HipColors.muted,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ExcludeSemantics(
                child: IgnorePointer(
                  child: HipDrillArt(
                    key: front && keyed ? const ValueKey('home-hero') : null,
                    drill: drill,
                    showPendingLabel: false,
                  ),
                ),
              ),
            ),
            ExcludeSemantics(
              child: Padding(
                padding: EdgeInsets.fromLTRB(inset, compact ? 0 : 4, inset, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      drill.name,
                      key: front && keyed
                          ? const ValueKey('home-deck-caption')
                          : null,
                      maxLines: compact ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: compact ? 12 : 23,
                        height: 1.22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -.3,
                        color: HipColors.text,
                      ),
                    ),
                    if (!compact && dose.isNotEmpty) ...[
                      const SizedBox(height: 7),
                      Text(
                        dose,
                        key: front && keyed
                            ? const ValueKey('home-deck-dose')
                            : null,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: HipColors.jadeText,
                        ),
                      ),
                    ],
                    if (!compact && cue.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        cue,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          height: 1.4,
                          color: HipColors.muted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (front && _multiple)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: compact ? 4 : 10),
                child: Row(
                  children: [
                    _arrow(-1),
                    Expanded(
                      child: ExcludeSemantics(
                        child: Text(
                          '左右翻阅',
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: compact ? 8 : 9,
                            letterSpacing: 1.2,
                            color: HipColors.muted,
                          ),
                        ),
                      ),
                    ),
                    _arrow(1),
                  ],
                ),
              )
            else
              SizedBox(height: _multiple ? 44 : (compact ? 8 : 18)),
          ],
        );
      },
    );
  }
}

class _DeckTurnIntent extends Intent {
  const _DeckTurnIntent(this.direction);
  final int direction;
}

/// Commit as soon as the outgoing card is outside the viewport; waiting for
/// an invisible spring tail would leave the caption and the next drag locked.
class _DeckExitSpring extends SpringSimulation {
  _DeckExitSpring(double start, double end, double velocity, this.exitDistance)
    : super(
        const SpringDescription(mass: 1, stiffness: 240, damping: 31),
        start,
        end,
        velocity,
        tolerance: const Tolerance(distance: .4, velocity: 3),
      );

  final double exitDistance;

  @override
  bool isDone(double time) =>
      x(time).abs() >= exitDistance || super.isDone(time);
}

/// Home content has a 16pt inset; cards can fan out to the window edge.
class _DeckViewportClip extends CustomClipper<Rect> {
  const _DeckViewportClip(this.bleed);
  final double bleed;

  @override
  Rect getClip(Size size) =>
      Rect.fromLTRB(-bleed, 0, size.width + bleed, size.height);

  @override
  bool shouldReclip(_DeckViewportClip oldClipper) => oldClipper.bleed != bleed;
}
