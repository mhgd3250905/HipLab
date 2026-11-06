import 'dart:math' as math;
import 'dart:ui' show ImageFilter, lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';

import '../domain/hip_models.dart';
import 'hip_icons.dart';
import 'hip_home_action_inspect.dart';
import 'hip_theme.dart';
import 'hip_widgets.dart';

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

  @override
  State<HipHomeActionDeck> createState() => _HipHomeActionDeckState();
}

class _HipHomeActionDeckState extends State<HipHomeActionDeck>
    with TickerProviderStateMixin {
  late final AnimationController _position;
  late final AnimationController _vertical;
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
      _generation++;
      _position.stop();
      _vertical.stop();
      _position.value = 0;
      _vertical.value = 0;
      _finishFloating();
      _resetInspection();
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
    super.dispose();
  }

  int _at(int offset) => (_index + offset) % widget.drills.length;

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
      setState(() {});
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
      _paused = false;
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
    _floatFront();
  }

  void _dragUpdate(DragUpdateDetails details) {
    if (_committing || _expanded || _expansion.value > 0) return;
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
    if (!_multiple || _committing || _expanded || _expansion.value > 0) return;
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
    return PopScope<void>(
      canPop: !_expanded && !_expansion.isAnimating,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _closeCard();
      },
      child: Semantics(
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
                  overlayChildBuilder: (context, info) => _liveFront(
                    info.childPaintTransform,
                    constraints.maxWidth,
                    cardHeight,
                  ),
                  child: SizedBox(
                    key: const ValueKey('home-deck-stage'),
                    height: cardHeight + 100,
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
        ..translateByDouble(
          (width - _cardWidth) / 2 - 18 + x,
          74 - lift * 18 + y,
          0,
          1,
        )
        ..translateByDouble(pivot.dx, pivot.dy, 0, 1)
        ..rotateZ(-.025 + travel * .18)
        ..multiply(Matrix4.identity()..setEntry(3, 2, .0012))
        ..rotateX(.018 + (y / _cardWidth).clamp(-1, 1) * -.04)
        ..rotateY(-.10 + travel * .19)
        ..scaleByDouble(1 + lift * .018, 1 + lift * .018, 1, 1)
        ..translateByDouble(-pivot.dx, -pivot.dy, 0, 1);
      final view = MediaQuery.of(context);
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
                                    HipHomeActionFace(
                                      key: const ValueKey(
                                        'home-deck-live-face',
                                      ),
                                      drill: widget.drills[_index],
                                      number: _index + 1,
                                      expansion: t,
                                      expanded: _expanded,
                                      paused: _paused,
                                      compact: height < 330,
                                      dose:
                                          widget.doses.elementAtOrNull(
                                            _index,
                                          ) ??
                                          '',
                                      cue:
                                          widget.cues.elementAtOrNull(_index) ??
                                          '',
                                      description:
                                          widget.descriptions.elementAtOrNull(
                                            _index,
                                          ) ??
                                          '',
                                      onClose: _closeCard,
                                      onToggle: () {
                                        if (_expanded) {
                                          setState(() => _paused = !_paused);
                                        }
                                      },
                                      informationScroll: _informationScroll,
                                      multiple: _multiple,
                                      previous: _arrow(-1),
                                      next: _arrow(1),
                                    ),
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
        for (var layer = count - 1; layer >= 1; layer--)
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
                  child: RepaintBoundary(
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
