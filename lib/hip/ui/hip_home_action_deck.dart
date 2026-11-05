import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';

import '../domain/hip_models.dart';
import 'hip_icons.dart';
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
  });

  final String identity;
  final List<HipDrill> drills;
  final List<String> doses;
  final List<String> cues;

  @override
  State<HipHomeActionDeck> createState() => _HipHomeActionDeckState();
}

class _HipHomeActionDeckState extends State<HipHomeActionDeck>
    with SingleTickerProviderStateMixin {
  late final AnimationController _position;
  int _index = 0;
  int _toward = 1;
  int _generation = 0;
  bool _committing = false;
  double _cardWidth = 1;
  double _exitDistance = 1;
  bool _lastReduced = false;
  Size? _viewport;
  bool get _multiple => widget.drills.length > 1;
  bool get _reduced => MediaQuery.disableAnimationsOf(context);

  @override
  void initState() {
    super.initState();
    _position = AnimationController.unbounded(vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final viewport = MediaQuery.sizeOf(context);
    final resized = _viewport != null && _viewport != viewport;
    if ((_reduced && !_lastReduced) || resized) {
      _generation++;
      _position.stop();
      if (_committing) _index = _at(_toward);
      _committing = false;
      _position.value = 0;
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
      _position.value = 0;
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
    super.dispose();
  }

  int _at(int offset) => (_index + offset) % widget.drills.length;

  void _dragStart(DragStartDetails details) {
    if (!_multiple || _committing) return;
    // Catch a returning card where it is, rather than jumping it to rest.
    _generation++;
    _position.stop();
  }

  void _dragUpdate(DragUpdateDetails details) {
    if (!_multiple || _committing) return;
    final next = (_position.value + details.primaryDelta!).clamp(
      -_cardWidth * 1.25,
      _cardWidth * 1.25,
    );
    if (next.abs() > 1) _toward = next < 0 ? 1 : -1;
    _position.value = next;
  }

  void _dragEnd(DragEndDetails details) {
    if (!_multiple || _committing) return;
    final velocity = details.primaryVelocity ?? 0;
    final distance = _position.value;
    final far = distance.abs() > _cardWidth * .24;
    final flick = velocity.abs() > 650;
    if (far && flick && velocity * distance < 0) {
      // A deliberate flick back toward the stack cancels this preview.
      _returnCard(velocity);
      return;
    }
    if (far || flick) {
      // Once the next card is exposed, a last-moment velocity reversal must
      // not replace it with a different image under the user's hand.
      final direction = far ? _toward : (velocity < 0 ? 1 : -1);
      _turn(direction, velocity: velocity);
    } else {
      _returnCard(velocity);
    }
  }

  void _returnCard([double velocity = 0]) {
    if (_committing) return;
    if (_reduced) {
      _position.value = 0;
      return;
    }
    _position.animateWith(
      SpringSimulation(
        const SpringDescription(mass: 1, stiffness: 310, damping: 29),
        _position.value,
        0,
        velocity.clamp(-1800.0, 1800.0),
        tolerance: const Tolerance(distance: .2, velocity: 2),
      ),
    );
  }

  Future<void> _turn(int direction, {double velocity = 0}) async {
    if (!_multiple || _committing) return;
    _toward = direction;
    final generation = ++_generation;
    _position.stop();
    if (!_reduced) {
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
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.drills.isEmpty) return const SizedBox.shrink();
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: '训练动作预览',
      value: _description(_index),
      increasedValue: _multiple ? _description(_at(1)) : null,
      decreasedValue: _multiple ? _description(_at(-1)) : null,
      hint: _multiple ? '左右滑动预览，不改变训练顺序' : null,
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
            final cardHeight = math.min(available, _cardWidth * 1.62);
            return Align(
              alignment: const Alignment(0, .2),
              child: SizedBox(
                height: cardHeight + 100,
                child: GestureDetector(
                  key: const ValueKey('home-deck-gesture'),
                  behavior: HitTestBehavior.opaque,
                  onHorizontalDragStart: _multiple ? _dragStart : null,
                  onHorizontalDragUpdate: _multiple ? _dragUpdate : null,
                  onHorizontalDragEnd: _multiple ? _dragEnd : null,
                  onHorizontalDragCancel: _multiple ? _returnCard : null,
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
                      animation: _position,
                      builder: (context, _) =>
                          _cards(constraints.maxWidth, cardHeight),
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
        for (var layer = count - 1; layer >= 0; layer--)
          _card(
            _at(layer * _toward),
            layer == 0 ? 0 : layer - progress,
            width,
            height,
            offset: layer == 0 ? offset : 0,
            front: layer == 0,
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
  }) {
    final travel = (offset / _cardWidth).clamp(-1.5, 1.5);
    final lift = front ? math.sin(travel.abs().clamp(0, 1) * math.pi) : 0.0;
    final angle = -.025 + depth * .105 + (front ? travel * .18 : 0);
    final dark = HipColors.isDark;
    final high = MediaQuery.highContrastOf(context);
    final tilt = Matrix4.identity()
      ..setEntry(3, 2, .0012)
      ..rotateX(.018 + lift * .035)
      ..rotateY(-.10 + (front ? travel * .19 : 0));
    return Positioned(
      key: ValueKey('home-deck-card-$index'),
      left: (width - _cardWidth) / 2 - 18 + depth * 16 + offset,
      top: 74 - depth * 26 - lift * 18,
      width: _cardWidth,
      height: height,
      child: Transform.rotate(
        key: front ? const ValueKey('home-deck-front') : null,
        alignment: const Alignment(0, .8),
        angle: angle,
        child: Transform(
          alignment: const Alignment(0, .8),
          transform: tilt,
          child: Transform.scale(
            scale: (1 - depth * .045) * (1 + lift * .018),
            alignment: const Alignment(0, .8),
            child: ExcludeSemantics(
              excluding: !front,
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
                          child: _poster(index, front: front),
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
    );
  }

  Widget _poster(int index, {required bool front}) {
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
                      key: front ? const ValueKey('home-deck-position') : null,
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
                    key: front ? const ValueKey('home-hero') : null,
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
                      key: front ? const ValueKey('home-deck-caption') : null,
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
                        key: front ? const ValueKey('home-deck-dose') : null,
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
