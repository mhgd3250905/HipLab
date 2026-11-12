import 'dart:math' as math;
import 'dart:ui' show ImageFilter, PathFillType, lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';

import '../domain/hip_models.dart';
import 'hip_content_text.dart';
import 'hip_home_action_inspect.dart';
import 'hip_theme.dart';
import 'hip_widgets.dart' show HipDrillArt, HipMediaPolicy;

/// The ordered action deck with a persistent video front face.
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

  static const _paginationGap = 14.0;
  static const _dotHeight = 5.0;
  static const _minCardHeight = 400.0;

  static double minimumHeight(int cardCount) =>
      _minCardHeight + _paginationHeight(cardCount);

  static double _paginationHeight(int cardCount) =>
      cardCount > 1 ? _paginationGap + _dotHeight : 0;

  @override
  State<HipHomeActionDeck> createState() => _HipHomeActionDeckState();
}

class _HipHomeActionDeckState extends State<HipHomeActionDeck>
    with TickerProviderStateMixin {
  static const _aspect = .62;
  // HipHome already provides 14dp horizontal padding.
  static const _sideInset = 8.0;
  static const _rearAngle = 3.5 * math.pi / 180;

  late final AnimationController _position;
  late final AnimationController _vertical;
  late final AnimationController _flight;
  final _overlay = OverlayPortalController();
  late final AnimationController _expansion;
  Animation<double>? _covered;
  LocalHistoryEntry? _history;
  final _informationScroll = ScrollController();
  final _cardFocus = FocusScopeNode(debugLabel: 'Home action card');
  FocusNode? _previousFocus;
  bool _paused = true;
  bool _disposing = false;
  bool _floating = false;
  bool _expanded = false;
  int _index = 0;
  int _toward = 1;
  int _generation = 0;
  final _mediaKeys = <int, GlobalKey>{};
  final _readyCallbacks = <int, ValueChanged<bool>>{};
  final _readyFrames = <int>{};
  // The first visible cold card follows the same rule as a cold incoming card:
  // prepare underneath its still, but reveal only on an intentional opening.
  final _posterLocked = <int>{0};
  bool _committing = false;
  Offset _flightDirection = Offset.zero;
  Rect? _frontBounds;
  Offset _boundsOffset = Offset.zero;
  Rect? _paintedFlightBounds;
  int _paintedFlightGeneration = -1;
  double _cardWidth = 1;
  double _exitDistance = 1;
  double _switchDistance = 1;
  bool _lastReduced = false;
  Size? _viewport;
  bool get _multiple => widget.drills.length > 1;
  bool get _reduced => MediaQuery.disableAnimationsOf(context);
  bool get _videoEnabled => HipMediaPolicy.of(context);
  Set<int> get _warmIndices => {
    _index,
    if (_videoEnabled && _multiple) _at(1),
    if (_videoEnabled && _multiple) _at(-1),
  };

  GlobalKey _mediaKey(int index) => _mediaKeys.putIfAbsent(
    index,
    () => GlobalKey(debugLabel: 'Home action media $index'),
  );

  void _frameReady(int index, GlobalKey key, bool ready) {
    if (!mounted || _disposing || _mediaKeys[index] != key) return;
    final changed = ready
        ? _readyFrames.add(index)
        : _readyFrames.remove(index);
    final presentationChanged =
        !ready && index == _index && !_expanded && _posterLocked.add(index);
    if (changed || presentationChanged) setState(() {});
  }

  ValueChanged<bool> _readyCallback(int index) =>
      _readyCallbacks.putIfAbsent(index, () {
        final key = _mediaKey(index);
        return (ready) => _frameReady(index, key, ready);
      });

  void _lockIncomingPresentation(int direction) {
    final incoming = _at(direction);
    if (!_readyFrames.contains(incoming)) {
      _posterLocked.add(incoming);
    }
  }

  @override
  void initState() {
    super.initState();
    _position = AnimationController.unbounded(vsync: this);
    _vertical = AnimationController.unbounded(vsync: this);
    _flight = AnimationController.unbounded(vsync: this)
      ..addListener(() {
        _position.value = _flightDirection.dx * _flight.value;
        _vertical.value = _flightDirection.dy * _flight.value;
        // The last painted quad is at most one frame behind this tick. Stop
        // when it has cleared the window instead of waiting for an invisible
        // spring tail, particularly on a tall upward/downward release.
        if (_committing &&
            _flight.isAnimating &&
            _paintedFlightGeneration == _generation &&
            _paintedFlightBounds != null &&
            !((Offset.zero & MediaQuery.sizeOf(context)).overlaps(
              _paintedFlightBounds!,
            ))) {
          _flight.stop(canceled: false);
        }
      });
    _expansion = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    )..addStatusListener(_inspectionStatus);
    _overlay.show();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _covered = ModalRoute.of(context)?.secondaryAnimation;
    final viewport = MediaQuery.sizeOf(context);
    final resized = _viewport != null && _viewport != viewport;
    if ((_reduced && !_lastReduced) || resized) {
      _generation++;
      _position.stop();
      _vertical.stop();
      _flight.stop();
      if (_committing) _index = _at(_toward);
      _committing = false;
      _position.value = 0;
      _vertical.value = 0;
      _finishFloating();
      if (_reduced) _expansion.value = _expanded ? 1 : 0;
    }
    _lastReduced = _reduced;
    _viewport = viewport;
  }

  @override
  void didUpdateWidget(HipHomeActionDeck oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.identity != widget.identity ||
        !listEqualsIds(oldWidget.drills, widget.drills)) {
      // A scene/day/plan change need not discard the visible pose when its
      // action is also the new first action. Preserve only this one decoded
      // occurrence, not an unbounded cache of old plans or hidden neighbors.
      final previousKey = _mediaKeys[_index];
      final reuseVisible =
          widget.drills.isNotEmpty &&
          _index < oldWidget.drills.length &&
          oldWidget.drills[_index].id == widget.drills.first.id &&
          previousKey?.currentState != null &&
          _readyFrames.contains(_index);
      final wasPosterLocked = _posterLocked.contains(_index);
      _generation++;
      _position.stop();
      _vertical.stop();
      _flight.stop();
      _position.value = 0;
      _vertical.value = 0;
      _finishFloating();
      _resetInspection();
      _mediaKeys.clear();
      _readyCallbacks.clear();
      _readyFrames.clear();
      _posterLocked.clear();
      if (reuseVisible) {
        _mediaKeys[0] = previousKey!;
        _readyFrames.add(0);
        if (wasPosterLocked) _posterLocked.add(0);
      } else {
        _posterLocked.add(0);
      }
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
    _disposing = true;
    _resetInspection();
    _generation++;
    _cardFocus.dispose();
    _informationScroll.dispose();
    _expansion.dispose();
    _position.dispose();
    _vertical.dispose();
    _flight.dispose();
    super.dispose();
  }

  int _at(int offset) => (_index + offset) % widget.drills.length;

  double _cardLeft(double stageWidth) =>
      math.max(_sideInset, (stageWidth - _cardWidth) / 2 - 18);

  void _floatFront() {
    if (_reduced || _floating) return;
    setState(() => _floating = true);
  }

  void _finishFloating() => _floating = false;

  void _inspectionStatus(AnimationStatus status) {
    if (!_disposing &&
        mounted &&
        (status == AnimationStatus.dismissed ||
            status == AnimationStatus.completed)) {
      setState(() {
        // Keep the primed/current frame still while the large card and backdrop
        // transform. Native playback starts once that animation has settled.
        if (status == AnimationStatus.completed && _expanded) _paused = false;
      });
    }
  }

  void _resetInspection() {
    _expanded = false;
    _paused = true;
    final history = _history;
    _history = null;
    history?.remove();
    _expansion.stop();
    _expansion.value = 0;
  }

  void _openCard([TapUpDetails? details]) {
    if (_expanded || _floating || _committing || _position.isAnimating) return;
    _previousFocus = FocusManager.instance.primaryFocus;
    _cardFocus.requestFocus();
    setState(() {
      _expanded = true;
      _paused = true;
      _posterLocked.remove(_index);
    });
    _history = LocalHistoryEntry(
      impliesAppBarDismissal: false,
      onRemove: () {
        _history = null;
        if (!_disposing && mounted && _expanded) _collapseCard();
      },
    );
    ModalRoute.of(context)?.addLocalHistoryEntry(_history!);
    if (_reduced) {
      _expansion.value = 1;
    } else {
      _expansion.forward();
    }
  }

  void _closeCard() {
    if (!_expanded) return;
    final history = _history;
    if (history != null) {
      history.remove();
    } else {
      _collapseCard();
    }
  }

  void _collapseCard() {
    // Reset only the description; keep the video subtree and its current pose.
    if (_informationScroll.hasClients) _informationScroll.jumpTo(0);
    if (_previousFocus?.context != null) _previousFocus?.requestFocus();
    _previousFocus = null;
    setState(() {
      _expanded = false;
      _paused = true;
      // Closing before the first decoded frame must not allow that late frame
      // to swap the compact still after the inspection has already finished.
      if (!_readyFrames.contains(_index)) _posterLocked.add(_index);
    });
    if (_reduced) {
      _expansion.value = 0;
    } else {
      _expansion.reverse();
    }
  }

  void _dragStart(DragStartDetails details) {
    if (_committing || _expanded || _expansion.value > 0) return;
    // Catch a returning card where it is, rather than jumping it to rest.
    _generation++;
    _position.stop();
    _vertical.stop();
    _flight.stop();
    for (final neighbor in _warmIndices.where((i) => i != _index)) {
      if (_readyFrames.contains(neighbor)) _posterLocked.remove(neighbor);
    }
    _floatFront();
  }

  int _directionFor(Offset offset) {
    final dominant = offset.dx.abs() >= offset.dy.abs() ? offset.dx : offset.dy;
    return dominant < 0 ? 1 : -1;
  }

  void _setDragOffset(Offset offset) {
    if (_committing || _expanded || _expansion.value > 0) return;
    if (offset.distance > 8) {
      _toward = _directionFor(offset);
      _lockIncomingPresentation(_toward);
    }
    _position.value = offset.dx;
    _vertical.value = offset.dy;
  }

  void _dragUpdate(DragUpdateDetails details) {
    if (_committing || _expanded || _expansion.value > 0) return;
    _setDragOffset(Offset(_position.value, _vertical.value) + details.delta);
  }

  void _dragEnd(DragEndDetails details) {
    if (_committing || _expanded) return;
    final velocity = details.velocity.pixelsPerSecond;
    final offset = Offset(_position.value, _vertical.value);
    final far = _multiple && offset.distance > _switchDistance;
    final along = offset.distance == 0
        ? 0.0
        : (velocity.dx * offset.dx + velocity.dy * offset.dy) / offset.distance;
    if (far && along < -650) {
      // A deliberate flick back toward the stack cancels this preview.
      _returnCard(velocity.dx, velocity.dy);
      return;
    }
    if (far) {
      // Once the next card is exposed, a last-moment velocity reversal must
      // not replace it with a different image under the user's hand.
      final direction = _toward;
      _turn(
        direction,
        velocity: along,
        exitDirection: offset / offset.distance,
      );
    } else {
      _returnCard(velocity.dx, velocity.dy);
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

  Future<void> _turn(
    int direction, {
    double velocity = 0,
    Offset? exitDirection,
  }) async {
    if (!_multiple || _committing || _expanded || _expansion.value > 0) return;
    _lockIncomingPresentation(direction);
    _toward = direction;
    final generation = ++_generation;
    _position.stop();
    _vertical.stop();
    if (!_reduced) {
      _floatFront();
      _committing = true;
      _flightDirection = exitDirection ?? Offset(-direction.toDouble(), 0);
      // Follow the release ray until the card has cleared a screen edge. Use
      // one scalar simulation for both axes so a diagonal never bends sideways.
      final offset = Offset(_position.value, _vertical.value);
      final bounds = _frontBounds?.shift(offset - _boundsOffset);
      final view = MediaQuery.sizeOf(context);
      final horizontal = _flightDirection.dx.abs() < .001
          ? double.infinity
          : bounds == null
          ? _exitDistance / _flightDirection.dx.abs()
          : (_flightDirection.dx < 0
                    ? bounds.right + 48
                    : view.width - bounds.left + 48) /
                _flightDirection.dx.abs();
      final vertical = _flightDirection.dy.abs() < .001
          ? double.infinity
          : bounds == null
          ? (view.height + _cardWidth / _aspect) / _flightDirection.dy.abs()
          : (_flightDirection.dy < 0
                    ? bounds.bottom + 48
                    : view.height - bounds.top + 48) /
                _flightDirection.dy.abs();
      // A far-off target gives a spring a much stronger initial pull on a tall
      // screen. Aim just beyond the visible edge, preserving the actual flick
      // speed while a slightly underdamped vertical spring gives it a clear
      // lift-off and settling phase. Horizontal motion keeps its original feel.
      final exitDistance =
          offset.distance + math.max(0, math.min(horizontal, vertical));
      final verticalWeight = _flightDirection.dy.abs();
      _flight.value = offset.distance;
      try {
        await _flight
            .animateWith(
              _DeckExitSpring(
                _flight.value,
                exitDistance,
                velocity.clamp(0.0, 2400.0),
                exitDistance,
                stiffness: lerpDouble(240, 70, verticalWeight)!,
                dampingRatio: lerpDouble(1, .82, verticalWeight)!,
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
    return PopScope<void>(
      canPop: !_expanded && !_expansion.isAnimating,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _closeCard();
      },
      child: Semantics(
        container: true,
        explicitChildNodes: true,
        label: HipContentText.of(context).isEn
            ? 'Workout move preview'
            : '训练动作预览',
        onTap: _openCard,
        value: _description(_index),
        increasedValue: _multiple ? _description(_at(1)) : null,
        decreasedValue: _multiple ? _description(_at(-1)) : null,
        hint: HipContentText.of(context).isEn
            ? 'Tap to expand the move. Drag away in any direction to turn the card.'
            : '轻点展开动作，向任意方向拖远翻牌',
        onIncrease: _multiple ? () => _turn(1) : null,
        onDecrease: _multiple ? () => _turn(-1) : null,
        child: FocusableActionDetector(
          shortcuts: const {
            SingleActivator(LogicalKeyboardKey.arrowLeft): _DeckTurnIntent(-1),
            SingleActivator(LogicalKeyboardKey.arrowRight): _DeckTurnIntent(1),
            SingleActivator(LogicalKeyboardKey.arrowUp): _DeckTurnIntent(1),
            SingleActivator(LogicalKeyboardKey.arrowDown): _DeckTurnIntent(-1),
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
              final pagination = HipHomeActionDeck._paginationHeight(
                widget.drills.length,
              );
              final available = constraints.maxHeight - pagination;
              if (available < 110 || constraints.maxWidth <= 2 * _sideInset) {
                return const SizedBox.shrink();
              }
              _cardWidth = math.min(
                constraints.maxWidth - 2 * _sideInset,
                available * _aspect,
              );
              _exitDistance = (constraints.maxWidth + _cardWidth) / 2 + 70;
              _switchDistance = MediaQuery.sizeOf(context).width * .26;
              final cardHeight = _cardWidth / _aspect;
              return Align(
                alignment: Alignment.bottomCenter,
                child: OverlayPortal.overlayChildLayoutBuilder(
                  controller: _overlay,
                  overlayLocation: OverlayChildLocation.rootOverlay,
                  overlayChildBuilder: (context, info) => _liveFront(
                    info.childPaintTransform,
                    constraints.maxWidth,
                    cardHeight,
                  ),
                  child: SizedBox(
                    key: const ValueKey('home-deck-stage'),
                    height: cardHeight + pagination,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      dragStartBehavior: DragStartBehavior.down,
                      onPanStart: _dragStart,
                      onPanUpdate: _dragUpdate,
                      onPanEnd: _dragEnd,
                      onPanCancel: _returnCard,
                      child: ClipRect(
                        clipper: _DeckViewportClip(
                          math.max(
                            0,
                            (MediaQuery.sizeOf(context).width -
                                    constraints.maxWidth) /
                                2,
                          ),
                          MediaQuery.sizeOf(context).height,
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
      ),
    );
  }

  Widget _liveFront(
    Matrix4 anchor,
    double width,
    double height,
  ) => AnimatedBuilder(
    animation: Listenable.merge([
      _position,
      _vertical,
      _expansion,
      ?_covered,
      Navigator.of(context).userGestureInProgressNotifier,
    ]),
    builder: (context, _) {
      final t = Curves.easeOutCubic.transform(_expansion.value);
      final active = _expanded || t > 0;
      final x = _reduced ? 0.0 : _position.value;
      final y = _reduced ? 0.0 : _vertical.value;
      final travel = (x / _cardWidth).clamp(-1.5, 1.5);
      final lift = math.sin(
        (Offset(x, y).distance / _cardWidth).clamp(0, 1) * math.pi / 2,
      );
      final pivot = Offset(_cardWidth / 2, height * .9);
      final source = Matrix4.copy(anchor)
        ..translateByDouble(_cardLeft(width) + x, -lift * 18 + y, 0, 1)
        ..translateByDouble(pivot.dx, pivot.dy, 0, 1)
        ..rotateZ(travel * .18)
        ..multiply(Matrix4.identity()..setEntry(3, 2, .0012))
        ..rotateX((y / _cardWidth).clamp(-1, 1) * -.04)
        ..rotateY(travel * .19)
        ..scaleByDouble(1 + lift * .018, 1 + lift * .018, 1, 1)
        ..translateByDouble(-pivot.dx, -pivot.dy, 0, 1);
      final view = MediaQuery.of(context);
      _frontBounds = MatrixUtils.transformRect(
        source,
        Rect.fromLTWH(0, 0, _cardWidth, height),
      );
      _boundsOffset = Offset(x, y);
      if (_committing) {
        _paintedFlightBounds = _frontBounds;
        _paintedFlightGeneration = _generation;
      }
      final targetWidth = math.min(460.0, math.max(0.0, view.size.width - 40));
      final targetHeight = math.min(
        720.0,
        math.max(0.0, view.size.height - view.padding.vertical - 48),
      );
      final target = Matrix4.translationValues(
        (view.size.width - targetWidth) / 2,
        view.padding.top +
            (view.size.height - view.padding.vertical - targetHeight) / 2,
        0,
      );
      final pose = Matrix4.zero();
      for (var i = 0; i < 16; i++) {
        pose.storage[i] =
            source.storage[i] + (target.storage[i] - source.storage[i]) * t;
      }
      final covered = _reduced ? 0.0 : (_covered?.value ?? 0);
      // Recognize motion before the card's perspective transform, in screen
      // coordinates. A recognizer inside the tilt would distort finger deltas.
      return GestureDetector(
        key: const ValueKey('home-deck-gesture'),
        behavior: HitTestBehavior.deferToChild,
        dragStartBehavior: DragStartBehavior.down,
        onPanStart: _dragStart,
        onPanUpdate: _dragUpdate,
        onPanEnd: _dragEnd,
        onPanCancel: _returnCard,
        onTapUp: active ? null : _openCard,
        child: BlockSemantics(
          blocking: active,
          child: FocusScope(
            node: _cardFocus,
            child: Shortcuts(
              shortcuts: active
                  ? const {
                      SingleActivator(LogicalKeyboardKey.escape):
                          DismissIntent(),
                    }
                  : const {},
              child: Actions(
                actions: {
                  DismissIntent: CallbackAction<DismissIntent>(
                    onInvoke: (_) {
                      _closeCard();
                      return null;
                    },
                  ),
                },
                child: Stack(
                  fit: StackFit.expand,
                  clipBehavior: Clip.hardEdge,
                  children: [
                    if (active)
                      Positioned.fill(
                        child: GestureDetector(
                          key: const ValueKey('home-deck-inspect-barrier'),
                          behavior: HitTestBehavior.opaque,
                          onTap: _closeCard,
                          child: BackdropFilter(
                            filter: ImageFilter.blur(
                              sigmaX: 4 * t,
                              sigmaY: 4 * t,
                            ),
                            child: ColoredBox(
                              color: Colors.black.withValues(
                                alpha: (HipColors.isDark ? .42 : .18) * t,
                              ),
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      key: ValueKey('home-deck-card-$_index'),
                      left: 0,
                      top: 0,
                      width: lerpDouble(_cardWidth, targetWidth, t),
                      height: lerpDouble(height, targetHeight, t),
                      child: Transform(
                        key: const ValueKey('home-deck-pose'),
                        alignment: Alignment.topLeft,
                        transform: pose,
                        // Unpack RGB/alpha in the video's local coordinates,
                        // then transform the composed card as one GPU image.
                        filterQuality: FilterQuality.low,
                        child: IgnorePointer(
                          ignoring:
                              !(ModalRoute.isCurrentOf(context) ?? true) ||
                              Navigator.of(context).userGestureInProgress,
                          child: Opacity(
                            key: ValueKey('home-deck-opacity-$_index'),
                            opacity: 1,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              child: RepaintBoundary(
                                key: const ValueKey('home-deck-front'),
                                child: Stack(
                                  fit: StackFit.expand,
                                  clipBehavior: Clip.none,
                                  children: [
                                    _actionFace(_index, height, expansion: t),
                                    if (_floating)
                                      const Positioned.fill(
                                        child: IgnorePointer(
                                          child: SizedBox(
                                            key: ValueKey(
                                              'home-deck-floating-front',
                                            ),
                                          ),
                                        ),
                                      ),
                                    if (covered > 0)
                                      Positioned.fill(
                                        child: IgnorePointer(
                                          child: ColoredBox(
                                            color: Colors.black.withValues(
                                              alpha:
                                                  (HipColors.isDark
                                                      ? .32
                                                      : .14) *
                                                  covered,
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
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );

  String _description(int index) {
    final t = HipContentText.of(context);
    final dose = widget.doses.elementAtOrNull(index) ?? '';
    if (t.isEn) {
      return 'Move ${index + 1} of ${widget.drills.length}, ${t.drillName(widget.drills[index])}'
          '${dose.isEmpty ? '' : ', ${t.text(dose)}'}';
    }
    return '第 ${index + 1} 个，共 ${widget.drills.length} 个，${widget.drills[index].name}'
        '${dose.isEmpty ? '' : '，$dose'}';
  }

  Widget _actionFace(
    int index,
    double height, {
    double expansion = 0,
    bool rear = false,
    bool contactShadow = false,
  }) => KeyedSubtree(
    key: ValueKey(rear ? 'home-deck-next-face' : 'home-deck-live-face'),
    child: HipHomeActionFace(
      // Reparent the same face and media when the turn commits.
      key: GlobalObjectKey(_mediaKey(index)),
      drill: widget.drills[index],
      number: index + 1,
      total: widget.drills.length,
      mediaKey: _mediaKey(index),
      revealPausedFrame: !_posterLocked.contains(index),
      onFrameReadyChanged: _readyCallback(index),
      restingSize: Size(_cardWidth, height),
      expansion: expansion,
      expanded: !rear && _expanded,
      paused: rear || _paused,
      rear: rear,
      contactShadow: contactShadow,
      compact: height < 330,
      dose: widget.doses.elementAtOrNull(index) ?? '',
      cue: widget.cues.elementAtOrNull(index) ?? '',
      description: widget.descriptions.elementAtOrNull(index) ?? '',
      onClose: rear ? null : _closeCard,
      onToggle: rear
          ? null
          : () {
              if (_expanded && !_expansion.isAnimating) {
                setState(() => _paused = !_paused);
              }
            },
      informationScroll: rear ? null : _informationScroll,
    ),
  );

  Widget _cards(double width, double height) {
    final raw = Offset(_position.value, _vertical.value).distance;
    final offset = _reduced ? 0.0 : raw;
    final progress = (offset.abs() / _cardWidth).clamp(0.0, 1.0);
    final count = math.min(3, widget.drills.length);
    final next = count > 1 ? _at(_toward) : null;
    final bottomDepth = (count - 1).toDouble();
    final replenishing = count > 1 && progress > 0;
    return Stack(
      clipBehavior: Clip.none,
      fit: StackFit.expand,
      children: [
        // Keep decoded neighbors available for the next turn without painting
        // their content, card surfaces or shadows in the visual stack.
        for (final index in _warmIndices)
          if (index != _index && index != next) _warmMedia(index, height),
        if (count > 1 && !HipColors.flatShadows)
          _rearPose(
            depth: bottomDepth,
            width: width,
            height: height,
            child: const IgnorePointer(
              child: CustomPaint(
                key: ValueKey('home-deck-stack-shadow'),
                painter: _DeckSoftShadow(),
              ),
            ),
          ),
        if (replenishing)
          _rearCard(
            _at(count * _toward),
            bottomDepth,
            width,
            height,
            replenishing: true,
            bottom: true,
            opacity: Curves.easeOut.transform(progress),
          ),
        if (count == 3)
          _rearCard(
            _at(2 * _toward),
            2 - progress,
            width,
            height,
            bottom: !replenishing,
          ),
        if (next != null)
          _rearPose(
            key: ValueKey('home-deck-card-$next'),
            depth: 1 - progress,
            width: width,
            height: height,
            child: ExcludeSemantics(
              child: IgnorePointer(
                child: RepaintBoundary(
                  child: _actionFace(
                    next,
                    height,
                    rear: true,
                    contactShadow: count == 3 || replenishing,
                  ),
                ),
              ),
            ),
          ),
        if (_multiple)
          Positioned(
            key: const ValueKey('home-deck-pagination'),
            left: _cardLeft(width),
            bottom: 0,
            height: HipHomeActionDeck._dotHeight,
            width: _cardWidth,
            child: ExcludeSemantics(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  spacing: 12,
                  children: [
                    for (var index = 0; index < widget.drills.length; index++)
                      Container(
                        width: index == _index ? 14 : 5,
                        height: HipHomeActionDeck._dotHeight,
                        decoration: BoxDecoration(
                          color: index == _index
                              ? HipColors.text
                              : const Color(0xffcdd3d0),
                          borderRadius: BorderRadius.circular(2.5),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _warmMedia(int index, double height) => Positioned(
    key: ValueKey('home-deck-warm-$index'),
    left: 0,
    top: 0,
    width: math.min(_cardWidth, height),
    height: math.min(_cardWidth, height),
    child: ExcludeSemantics(
      child: IgnorePointer(
        child: Opacity(
          opacity: 0,
          child: HipDrillArt(
            key: _mediaKey(index),
            drill: widget.drills[index],
            holdVideo: true,
            revealPausedFrame: !_posterLocked.contains(index),
            onFrameReadyChanged: _readyCallback(index),
            showPendingLabel: false,
            stage: Colors.transparent,
          ),
        ),
      ),
    ),
  );

  Widget _rearCard(
    int index,
    double depth,
    double width,
    double height, {
    required bool bottom,
    bool replenishing = false,
    double opacity = 1,
  }) => _rearPose(
    key: ValueKey(
      'home-deck-card-$index${replenishing && widget.drills.length <= 3 ? '-reserve' : ''}',
    ),
    depth: depth,
    width: width,
    height: height,
    child: Opacity(
      key: ValueKey('home-deck-opacity-$index'),
      opacity: opacity,
      child: IgnorePointer(
        child: DecoratedBox(
          key: ValueKey('home-deck-paper-$index'),
          decoration: BoxDecoration(
            color: Color.lerp(
              const Color(0xfffbfcfb),
              const Color(0xfff6f7f6),
              (depth - 1).clamp(0, 1),
            ),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: Colors.black.withValues(alpha: .06),
              width: .5,
            ),
            boxShadow: bottom
                ? null
                : HipColors.shadows([
                    BoxShadow(
                      color: const Color(0xff14281f).withValues(alpha: .05),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ]),
          ),
          child: const SizedBox.expand(),
        ),
      ),
    ),
  );

  Widget _rearPose({
    Key? key,
    required double depth,
    required double width,
    required double height,
    required Widget child,
  }) => Positioned(
    key: key,
    left: _cardLeft(width) + depth * 16,
    top: -depth * 9,
    width: _cardWidth,
    height: height,
    child: Transform.rotate(
      alignment: const Alignment(0, .8),
      angle: -depth * _rearAngle,
      child: child,
    ),
  );
}

/// The bottom pose is shared by the resting card and its replacement. Paint
/// the broad shadow once, excluding the paper so the fading card cannot show
/// a dark silhouette from its own shadow.
class _DeckSoftShadow extends CustomPainter {
  const _DeckSoftShadow();

  @override
  void paint(Canvas canvas, Size size) {
    final paper = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(26),
    );
    final shadow = BoxShadow(
      color: const Color(0xff14281f).withValues(alpha: .13),
      blurRadius: 44,
      offset: const Offset(0, 14),
    );
    canvas.save();
    final outsidePaper = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect((Offset.zero & size).inflate(3 * shadow.blurRadius))
      ..addRRect(paper);
    canvas.clipPath(outsidePaper);
    canvas.drawRRect(paper.shift(shadow.offset), shadow.toPaint());
    canvas.restore();
  }

  @override
  bool shouldRepaint(_DeckSoftShadow oldDelegate) => false;
}

class _DeckTurnIntent extends Intent {
  const _DeckTurnIntent(this.direction);
  final int direction;
}

/// Commit as soon as the outgoing card is outside the viewport; waiting for
/// an invisible spring tail would leave the caption and the next drag locked.
class _DeckExitSpring extends SpringSimulation {
  _DeckExitSpring(
    double start,
    double end,
    double velocity,
    this.exitDistance, {
    required double stiffness,
    required double dampingRatio,
  }) : super(
         SpringDescription(
           mass: 1,
           stiffness: stiffness,
           damping: 2 * dampingRatio * math.sqrt(stiffness),
         ),
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

/// Clip cards at the side edges without cutting off the stack's soft shadows.
class _DeckViewportClip extends CustomClipper<Rect> {
  const _DeckViewportClip(this.horizontalBleed, this.windowHeight);

  final double horizontalBleed;
  final double windowHeight;

  @override
  Rect getClip(Size size) => Rect.fromLTRB(
    -horizontalBleed,
    -windowHeight,
    size.width + horizontalBleed,
    size.height + windowHeight,
  );

  @override
  bool shouldReclip(_DeckViewportClip oldClipper) =>
      oldClipper.horizontalBleed != horizontalBleed ||
      oldClipper.windowHeight != windowHeight;
}
