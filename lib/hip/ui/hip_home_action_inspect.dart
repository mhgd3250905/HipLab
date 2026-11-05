import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:ugk_trainer_runtime/ugk_trainer_runtime.dart' as trainer;

import '../data/hip_public_media.dart';
import '../domain/hip_models.dart';
import 'hip_icons.dart';
import 'hip_theme.dart';
import 'hip_widgets.dart';
import 'hip_card_snapshot.dart';

const _cardHandoffEpsilon = 1e-7;

/// Brings one action card closer without turning it into a full-screen page.
/// The existing SDK continues to own the video, its cache and its decoder.
Future<void> showHipHomeActionCard(
  BuildContext context, {
  required Rect sourceRect,
  required HipDrill drill,
  required int number,
  String dose = '',
  String cue = '',
  String description = '',
  HipCardSnapshot? sourceSnapshot,
  VoidCallback? onSourceRestored,
}) async {
  final videoEnabled = HipMediaPolicy.of(context);
  final reduced = MediaQuery.disableAnimationsOf(context);
  final policy = HipPublicMedia.current;
  final route = RawDialogRoute<void>(
    barrierDismissible: true,
    barrierLabel: '关闭动作预览',
    barrierColor: Colors.transparent,
    transitionDuration: reduced
        ? Duration.zero
        : const Duration(milliseconds: 380),
    settings: RouteSettings(name: 'home_action_card/${drill.id}'),
    pageBuilder: (context, animation, secondaryAnimation) => _ActionCardInspect(
      sourceRect: sourceRect,
      drill: drill,
      number: number,
      dose: dose,
      cue: cue,
      description: description,
      policy: policy,
      videoEnabled: videoEnabled,
      sourceSnapshot: sourceSnapshot,
    ),
    // The card animates its own rect; a route-wide fade would dim the artwork.
    transitionBuilder: (context, animation, secondaryAnimation, child) => child,
  );
  var restored = false;
  void restore() {
    if (restored) return;
    restored = true;
    onSourceRestored?.call();
  }

  void statusChanged(AnimationStatus status) {
    // Dismissal runs in the animation tick, before this frame's build/paint.
    // Restore the retained source in that frame, not after Overlay disposal.
    if (status == AnimationStatus.dismissed) restore();
  }

  final popped = Navigator.of(context, rootNavigator: true).push(route);
  final animation = route.animation!;
  void handoffAtRest() {
    // At duration the controller can reach zero one tick before dismissed.
    if (animation.status == AnimationStatus.reverse &&
        animation.value <= _cardHandoffEpsilon) {
      restore();
    }
  }

  animation.addStatusListener(statusChanged);
  animation.addListener(handoffAtRest);
  try {
    await popped;
    await route.completed;
  } finally {
    animation.removeStatusListener(statusChanged);
    animation.removeListener(handoffAtRest);
    restore();
  }
}

class _ActionCardInspect extends StatefulWidget {
  const _ActionCardInspect({
    required this.sourceRect,
    required this.drill,
    required this.number,
    required this.dose,
    required this.cue,
    required this.description,
    required this.policy,
    required this.videoEnabled,
    required this.sourceSnapshot,
  });

  final Rect sourceRect;
  final HipDrill drill;
  final int number;
  final String dose, cue, description;
  final trainer.TrainingMediaPolicy? policy;
  final bool videoEnabled;
  final HipCardSnapshot? sourceSnapshot;

  @override
  State<_ActionCardInspect> createState() => _ActionCardInspectState();
}

class _ActionCardInspectState extends State<_ActionCardInspect> {
  Animation<double>? _animation;
  bool _paused = false;
  bool _closing = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final animation = ModalRoute.of(context)!.animation!;
    if (!identical(animation, _animation)) {
      _animation?.removeStatusListener(_statusChanged);
      _animation = animation..addStatusListener(_statusChanged);
    }
  }

  void _statusChanged(AnimationStatus status) {
    // Also handles Android back and barrier dismissal, before the shrink starts.
    if (status == AnimationStatus.reverse && !_closing && mounted) {
      setState(() {
        _closing = true;
        _paused = true;
      });
    }
  }

  void _close() {
    if (_closing) return;
    setState(() {
      _closing = true;
      _paused = true;
    });
    Navigator.of(context).pop();
  }

  void _toggle() {
    if (!_closing) setState(() => _paused = !_paused);
  }

  @override
  void dispose() {
    _animation?.removeStatusListener(_statusChanged);
    super.dispose();
  }

  // Matrix4Tween decomposes/recomposes and loses the card's perspective terms.
  // Keep the exact painted source matrix and interpolate all of its elements.
  Matrix4 _pose(Matrix4 source, Matrix4 target, double t) {
    if (t <= 0) return Matrix4.copy(source);
    if (t >= 1) return Matrix4.copy(target);
    final result = Matrix4.zero();
    for (var i = 0; i < 16; i++) {
      result.storage[i] =
          source.storage[i] + (target.storage[i] - source.storage[i]) * t;
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final view = MediaQuery.of(context);
    final width = math.min(460.0, math.max(0.0, view.size.width - 40));
    final availableHeight = math.max(
      0.0,
      view.size.height - view.padding.vertical - 48,
    );
    final height = math.min(720.0, availableHeight);
    final target = Rect.fromLTWH(
      (view.size.width - width) / 2,
      view.padding.top + 24 + (availableHeight - height) / 2,
      width,
      height,
    );
    return AnimatedBuilder(
      animation: _animation!,
      child: _surface(),
      builder: (context, child) {
        final t = Curves.easeOutCubic.transform(_animation!.value);
        final snapshot = widget.sourceSnapshot;
        final size = snapshot?.size ?? widget.sourceRect.size;
        final source =
            snapshot?.transform ??
            Matrix4.translationValues(
              widget.sourceRect.left,
              widget.sourceRect.top,
              0,
            );
        final destination =
            Matrix4.translationValues(target.left, target.top, 0)..multiply(
              Matrix4.diagonal3Values(
                target.width / size.width,
                target.height / size.height,
                1,
              ),
            );
        final pose = _pose(source, destination, t);
        final detailPose = Matrix4.copy(pose)
          ..multiply(
            Matrix4.diagonal3Values(
              size.width / target.width,
              size.height / target.height,
              1,
            ),
          );
        final handedOff =
            _animation!.status == AnimationStatus.dismissed ||
            (_animation!.status == AnimationStatus.reverse &&
                _animation!.value <= _cardHandoffEpsilon);
        final detailOpacity = handedOff
            ? 0.0
            : snapshot == null
            ? 1.0
            : const Interval(.35, .8, curve: Curves.easeInOut).transform(t);
        return Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                excludeFromSemantics: true,
                onTap: _close,
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 4 * t, sigmaY: 4 * t),
                  child: ColoredBox(
                    color: Colors.black.withValues(
                      alpha: (HipColors.isDark ? .42 : .18) * t,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              top: 0,
              width: target.width,
              height: target.height,
              child: Opacity(
                key: const ValueKey('home-deck-expanded-opacity'),
                opacity: detailOpacity,
                child: Transform(
                  alignment: Alignment.topLeft,
                  transform: detailPose,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: HipColors.shadows([
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: (HipColors.isDark ? .35 : .14) * t,
                          ),
                          blurRadius: 32,
                          offset: const Offset(0, 16),
                        ),
                      ]),
                    ),
                    child: child,
                  ),
                ),
              ),
            ),
            if (snapshot != null)
              Positioned(
                left: 0,
                top: 0,
                width: snapshot.paddedSize.width,
                height: snapshot.paddedSize.height,
                child: IgnorePointer(
                  child: ExcludeSemantics(
                    child: Opacity(
                      key: const ValueKey('home-deck-closing-stand-in'),
                      opacity: handedOff ? 0 : 1 - detailOpacity,
                      child: Transform(
                        key: const ValueKey('home-deck-snapshot-transform'),
                        alignment: Alignment.topLeft,
                        transform: Matrix4.copy(pose)
                          ..multiply(
                            Matrix4.translationValues(
                              -snapshot.padding,
                              -snapshot.padding,
                              0,
                            ),
                          ),
                        child: RawImage(
                          image: snapshot.image,
                          fit: BoxFit.fill,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _surface() => Material(
    key: const ValueKey('home-deck-expanded'),
    color: HipColors.mediaBackdrop,
    borderRadius: BorderRadius.circular(28),
    clipBehavior: Clip.antiAlias,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      excludeFromSemantics: true,
      onTap: () {},
      child: LayoutBuilder(
        builder: (context, box) {
          final mediaHeight = math.min(
            box.maxWidth * 1.05,
            math.max(0.0, box.maxHeight - 56) * .56,
          );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 6, 8, 6),
                child: Row(
                  children: [
                    Text(
                      'HIPLAB',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2.5,
                        color: HipColors.jadeText,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      widget.number.toString().padLeft(2, '0'),
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                        color: HipColors.muted,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(width: 8),
                    HipCircleButton(
                      key: const ValueKey('home-deck-expanded-close'),
                      icon: HipGlyph.close,
                      tooltip: '收起动作卡片',
                      onPressed: _close,
                    ),
                  ],
                ),
              ),
              SizedBox(height: mediaHeight, child: _media()),
              Expanded(
                child: SingleChildScrollView(
                  key: const ValueKey('home-deck-expanded-description'),
                  padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
                  child: _information(),
                ),
              ),
            ],
          );
        },
      ),
    ),
  );

  Widget _media() => Semantics(
    button: true,
    label: _paused ? '播放动作示范' : '暂停动作示范',
    value: _paused ? '已暂停' : '自动循环播放',
    onTap: _toggle,
    child: GestureDetector(
      key: const ValueKey('home-deck-expanded-media'),
      behavior: HitTestBehavior.opaque,
      excludeFromSemantics: true,
      onTap: _toggle,
      child: Stack(
        fit: StackFit.expand,
        children: [
          trainer.TrainingActionMedia(
            key: ValueKey('home-expanded-video-${widget.drill.id}'),
            actionId: widget.drill.id,
            policy: widget.policy,
            playing: widget.videoEnabled,
            paused: _paused,
            radius: 0,
            stage: HipColors.mediaBackdrop,
          ),
          Positioned(
            top: 8,
            right: 20,
            child: IgnorePointer(
              child: ExcludeSemantics(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: HipColors.surface.withValues(alpha: .8),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      HipIcon(
                        _paused ? HipGlyph.play : HipGlyph.pause,
                        size: 11,
                        color: HipColors.muted,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _paused ? '轻点继续' : '轻点暂停',
                        style: TextStyle(fontSize: 10, color: HipColors.muted),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _information() {
    final drill = widget.drill;
    final description = [widget.description, drill.note, widget.cue]
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .firstOrNull;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          drill.name,
          style: TextStyle(
            fontSize: 28,
            height: 1.2,
            letterSpacing: -.5,
            fontWeight: FontWeight.w700,
            color: HipColors.text,
          ),
        ),
        if (widget.dose.isNotEmpty) ...[
          const SizedBox(height: 9),
          Text(
            widget.dose,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: HipColors.jadeText,
            ),
          ),
        ],
        const SizedBox(height: 16),
        Text(
          [
            drill.methods.map((method) => method.zh).join(' · '),
            drill.directions.map((direction) => direction.zh).join(' / '),
          ].where((value) => value.isNotEmpty).join('  ·  '),
          style: TextStyle(fontSize: 11, height: 1.5, color: HipColors.muted),
        ),
        if (description != null) ...[
          const SizedBox(height: 12),
          Text(
            description,
            style: TextStyle(fontSize: 14, height: 1.65, color: HipColors.text),
          ),
        ],
        if (widget.cue.trim().isNotEmpty &&
            widget.cue.trim() != description) ...[
          const SizedBox(height: 12),
          Text(
            widget.cue,
            style: TextStyle(fontSize: 13, height: 1.6, color: HipColors.muted),
          ),
        ],
        if (drill.cautions.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text(
            '留意 · ${drill.cautions.join('、')}',
            style: TextStyle(fontSize: 12, height: 1.6, color: HipColors.muted),
          ),
        ],
      ],
    );
  }
}
