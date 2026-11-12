import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:ugk_trainer_runtime/ugk_trainer_runtime.dart' as trainer;

import '../../core/media/drill_media.dart';
import '../../core/media/media_controller.dart';
import '../data/hip_public_media.dart';
import '../data/hip_shared_library.dart';
import '../domain/hip_action_media.dart';
import '../domain/hip_models.dart';
import 'hip_icons.dart';
import 'hip_tactile.dart';
import 'hip_glass.dart';
import 'hip_theme.dart';
import 'hip_text.dart';

export 'hip_tactile.dart';

/// The v2 paper background shared by the home and host navigation pages.
class HipPageBackdrop extends StatelessWidget {
  const HipPageBackdrop({super.key});

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [HipColors.background, HipColors.pageBottom],
        ),
        image: const DecorationImage(
          image: AssetImage('assets/hip/ui-v2-grain.png'),
          repeat: ImageRepeat.repeat,
          opacity: .03,
          filterQuality: FilterQuality.none,
        ),
      ),
      child: const SizedBox.expand(),
    ),
  );
}

/// Shared v2 white material, with the same inset highlight at every radius.
class HipCard extends StatelessWidget {
  const HipCard({
    super.key,
    required this.child,
    this.radius = 16,
    this.padding = EdgeInsets.zero,
    this.innerHighlight = true,
    this.shadows,
  });

  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;
  final bool innerHighlight;
  final List<BoxShadow>? shadows;

  @override
  Widget build(BuildContext context) {
    final dark = HipColors.isDark;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: dark
              ? [HipColors.surfaceHigh, HipColors.surface]
              : const [Colors.white, Color(0xfffafbfa)],
        ),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: (dark ? Colors.white : Colors.black).withValues(alpha: .06),
          width: .5,
        ),
        boxShadow: shadows == null
            ? HipColors.cardShadow
            : HipColors.shadows(shadows),
      ),
      child: Stack(
        children: [
          if (innerHighlight)
            Positioned.fill(
              left: 1,
              right: 1,
              top: 1,
              bottom: 1,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(radius - 1),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: dark ? .08 : .78),
                      width: .5,
                    ),
                  ),
                ),
              ),
            ),
          Padding(padding: padding, child: child),
        ],
      ),
    );
  }
}

/// Video playback is off in widget tests (no platform view host there).
class HipMediaPolicy extends InheritedWidget {
  const HipMediaPolicy({
    super.key,
    required this.videoEnabled,
    required super.child,
  });
  final bool videoEnabled;
  static bool of(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<HipMediaPolicy>()
          ?.videoEnabled ??
      true;
  @override
  bool updateShouldNotify(HipMediaPolicy old) =>
      old.videoEnabled != videoEnabled;
}

/// Theme-matched action media (#14, 2026-10-19). Every clip, poster and
/// self-test still has a light-stage counterpart listed in
/// `assets/hip/action-media.json` (tools/media/build_themed_media.py); in the
/// light theme those are shown, so no dark box sits on the light pages. The
/// content pack keeps naming the dark asset.
abstract final class HipMediaVariants {
  /// Loaded once at startup (HipApp); empty until then / in bare widget tests.
  static HipActionMedia media = HipActionMedia.empty;

  static String? lightPoster(String? poster) => media.lightOf(poster);

  static bool hasLightVideo(String? video) => media.hasLight(video);

  /// [asset] for the theme in effect ([HipColors.isDark] unless [dark]).
  static String themed(String asset, {bool? dark}) =>
      media.resolve(asset, dark: dark ?? HipColors.isDark);

  /// Media stage behind [asset] in the theme in effect: the light stage only
  /// when a light counterpart is actually shown, else the dark stage it was
  /// rendered on (so a not-yet-built clip still letterboxes cleanly).
  static Color stageFor(String? asset) =>
      HipColors.isDark || asset == null || !media.hasLight(asset)
      ? HipPalette.dark.mediaBackdrop
      : HipPalette.light.mediaBackdrop;
}

/// A rounded media box whose border is painted *over* the clipped content,
/// so neither the picture nor a badge can hide the stroke or the corners
/// (#1). Use for every picture / video area.
class HipMediaFrame extends StatelessWidget {
  const HipMediaFrame({
    super.key,
    required this.child,
    this.radius = 22,
    this.borderColor,
    this.borderWidth = 1,
    this.color,
    this.shadow,
    this.overlays = const [],
  });
  final Widget child;
  final double radius;
  final Color? borderColor;
  final double borderWidth;
  final Color? color;
  final List<BoxShadow>? shadow;

  /// Laid out inside the border (badges, pills); never on top of the stroke.
  final List<Widget> overlays;

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(radius);
    return AnimatedContainer(
      duration: HipMotion.fast,
      curve: HipMotion.curve,
      decoration: BoxDecoration(
        color: color ?? HipColors.mediaBackdrop,
        borderRadius: r,
        boxShadow: HipColors.shadows(shadow),
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: r,
        border: Border.all(
          color: borderColor ?? HipColors.line,
          width: borderWidth,
          strokeAlign: BorderSide.strokeAlignInside,
        ),
      ),
      child: ClipRRect(
        borderRadius: r,
        child: overlays.isEmpty
            ? child
            : Stack(fit: StackFit.expand, children: [child, ...overlays]),
      ),
    );
  }
}

/// A drill / pose thumbnail (round 2 #3): the picture clipped to a rounded
/// rect on the media backdrop, with no stroke of its own. Thumbnails sit on
/// cards that already carry the edge; a second frame read as boxes in boxes.
/// When it sits in a card's corner, pass radius = card radius − padding so
/// the corners run concentric.
class HipThumb extends StatelessWidget {
  const HipThumb({super.key, required this.child, this.size, this.radius = 12});
  final Widget child;
  final double? size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final thumb = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: ColoredBox(color: HipColors.mediaBackdrop, child: child),
    );
    return size == null
        ? thumb
        : SizedBox.square(dimension: size, child: thumb);
  }
}

/// Shows the [focus] part of a square still (fractions of the image) filling
/// the box with a small margin, so thumbnails of different poses are framed
/// alike (#2): same subject size, centred, no stray backdrop strips.
class HipFocusImage extends StatelessWidget {
  const HipFocusImage({
    super.key,
    required this.asset,
    required this.focus,
    this.margin = .1,
    this.aspect = 1,
  });
  final String asset;
  final Rect focus;
  final double margin;

  /// Width / height of the source image.
  final double aspect;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final w = c.maxWidth, h = c.maxHeight;
      // Displayed image size so that the focus rect fits with the margin.
      final fw = focus.width * aspect, fh = focus.height;
      final scale = math.min(w / fw, h / fh) * (1 - margin * 2);
      final imgH = scale, imgW = scale * aspect;
      final cx = focus.center.dx * imgW, cy = focus.center.dy * imgH;
      var left = w / 2 - cx, top = h / 2 - cy;
      // Never reveal an edge of the picture (centre it if it is smaller).
      left = imgW < w ? (w - imgW) / 2 : left.clamp(w - imgW, 0.0).toDouble();
      top = imgH < h ? (h - imgH) / 2 : top.clamp(h - imgH, 0.0).toDouble();
      return ClipRect(
        child: Stack(
          children: [
            Positioned(
              left: left,
              top: top,
              width: imgW,
              height: imgH,
              child: Image.asset(
                asset,
                fit: BoxFit.fill,
                gaplessPlayback: true,
                errorBuilder: (_, _, _) => const HipPendingArt(),
              ),
            ),
          ],
        ),
      );
    },
  );
}

/// Retires one exact preview surface before the SDK starts another surface.
class HipDrillArtHandle {
  final _surface = GlobalKey<_HipDrillArtState>();
  Future<void>? _retirement;

  Key get key => _surface;

  /// Includes the frame that detaches the platform view, rather than merely
  /// pausing a retained decoder behind the next preview or training route.
  Future<void> retire() =>
      _surface.currentState?._retire() ?? _retirement ?? Future.value();

  Future<void> _track(Future<void> retiring) {
    final pending = Future.wait<void>([
      ?_retirement,
      retiring,
    ]).then<void>((_) {});
    _retirement = pending;
    void clear() {
      if (identical(_retirement, pending)) _retirement = null;
    }

    unawaited(
      pending.then<void>(
        (_) => clear(),
        onError: (Object _, StackTrace _) => clear(),
      ),
    );
    return pending;
  }
}

/// A drill's picture: its poster at once, the looping clip faded in over it
/// only after the clip's first frame is on screen (#3/#12) — no black box,
/// no native play/pause placeholder, no jump between poster and video.
class HipDrillArt extends StatefulWidget {
  const HipDrillArt({
    super.key,
    required this.drill,
    this.play = false,
    this.holdVideo = false,
    this.revealPausedFrame = true,
    this.stage,
    this.onFrameReadyChanged,
    this.fit = BoxFit.cover,
    this.showPendingLabel = true,
    this.alignment = Alignment.center,
    this.mirror = false,
    this.mediaViewBuilder,
    this.retirementHandle,
  });
  final HipDrill drill;

  /// Loop the clip (when the drill has one and video is enabled). Turning
  /// this off pauses on the current frame instead of tearing the view down.
  final bool play;

  /// Keep one decoded, paused video surface between compact and expanded views.
  /// Ordinary library artwork keeps its existing poster-only behavior.
  final bool holdVideo;
  final bool revealPausedFrame;
  final Color? stage;
  final ValueChanged<bool>? onFrameReadyChanged;
  final BoxFit fit;
  final bool showPendingLabel;
  final Alignment alignment;

  /// Flip horizontally (the other side of a sided move).
  final bool mirror;

  /// Optional explicit release used by SDK guide previews. Ordinary pause
  /// keeps its existing frame; retiring also removes the native media view.
  final HipDrillArtHandle? retirementHandle;

  /// Replaces the native view in widget tests, retaining the real playback
  /// controller and widget lifecycle without requiring a mobile WebView.
  @visibleForTesting
  final Widget Function(DrillMedia media, DrillMediaController controller)?
  mediaViewBuilder;

  @override
  State<HipDrillArt> createState() => _HipDrillArtState();
}

class _HipDrillArtState extends State<HipDrillArt> {
  bool _retired = false;

  @override
  void didUpdateWidget(HipDrillArt oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.drill.id != widget.drill.id ||
        (!oldWidget.play && widget.play)) {
      _retired = false;
    }
  }

  Future<void> _retire() {
    if (_retired) return Future.value();
    _retired = true;
    if (mounted) setState(() {});
    final detached = WidgetsBinding.instance.endOfFrame;
    return widget.retirementHandle?._track(detached) ?? detached;
  }

  @override
  Widget build(BuildContext context) {
    final policy = HipPublicMedia.current;
    if (policy == null || policy.actionFor(widget.drill.id) == null) {
      return HipPendingArt(
        label: widget.showPendingLabel
            ? HipText.of(context).pick('暂无公共动作示范', 'Demonstration unavailable')
            : null,
      );
    }
    final config = HipSharedLibrary.current;
    if (!widget.holdVideo && config != null) {
      return trainer.TrainingLibraryActionArt(
        actionId: widget.drill.id,
        mirrored: widget.mirror,
        config: config,
        mediaPolicy: policy,
        theme: HipSharedLibrary.theme(context),
        playing: widget.play && !_retired && HipMediaPolicy.of(context),
      );
    }
    return trainer.TrainingActionMedia(
      actionId: widget.drill.id,
      policy: policy,
      playing:
          (widget.play || widget.holdVideo) &&
          !_retired &&
          HipMediaPolicy.of(context),
      paused: !widget.play,
      prepareFirstFrame: widget.holdVideo,
      showLoadingIndicator: !widget.holdVideo,
      retainPausedSurfaceWhileCovered: widget.holdVideo,
      nativeAlpha: widget.holdVideo,
      revealPausedFrame: widget.revealPausedFrame,
      onFrameReadyChanged: widget.onFrameReadyChanged,
      mirrored: widget.mirror,
      radius: 0,
      stage: widget.stage ?? HipColors.mediaBackdrop,
    );
  }
}

/// Warms the image cache for the posters a screen is about to show (the next
/// drill, the next assessment item) so they appear on the first frame —
/// in the variant of the theme in effect.
void hipPrecache(BuildContext context, Iterable<String?> assets) {
  for (final a in assets) {
    if (a != null && !a.startsWith('assets/drill_media/')) {
      precacheImage(AssetImage(HipMediaVariants.themed(a)), context).ignore();
    }
  }
}

/// Graphite placeholder with a soft jade glow and a figure glyph.
class HipPendingArt extends StatelessWidget {
  const HipPendingArt({super.key, this.label});
  final String? label;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: RadialGradient(
        center: const Alignment(0, -.1),
        radius: .9,
        colors: [
          Color.lerp(HipColors.surface, HipColors.jade, .1)!,
          HipColors.surface,
        ],
      ),
    ),
    child: LayoutBuilder(
      builder: (context, c) => Stack(
        alignment: Alignment.center,
        children: [
          HipIcon(
            HipGlyph.figure,
            size: math.min(c.maxWidth, c.maxHeight) * .42,
            color: HipColors.jade.withValues(alpha: .28),
          ),
          if (label != null && c.maxWidth > 90)
            Positioned(
              bottom: c.maxHeight > 200 ? 34 : 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: HipColors.scrim,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  label!,
                  style: TextStyle(fontSize: 11, color: HipColors.muted),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

/// One row: back/close button, the page title in the same row, an optional
/// trailing widget (#7). Every page with a close or back button uses it.
class HipTopBar extends StatelessWidget {
  const HipTopBar({
    super.key,
    this.title,
    this.subtitle,
    this.center,
    this.trailing,
    this.leading,
    this.onClose,
    this.icon = HipGlyph.close,
    this.tooltip = '关闭',
  });
  final String? title;
  final String? subtitle;

  /// Centred content instead of a title (e.g. progress dots).
  final Widget? center;
  final Widget? trailing;

  /// Optional leading control for immersive pages with a custom header.
  final Widget? leading;
  final VoidCallback? onClose;
  final HipGlyph icon;
  final String tooltip;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
    child: ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Keep the immersive header's existing 48pt control rail. A tall
          // question heading must not pull the close control down with it.
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child:
                leading ??
                HipCircleButton(
                  icon: icon,
                  tooltip: tooltip == '关闭'
                      ? HipText.of(context).pick('关闭', 'Close')
                      : tooltip,
                  onPressed: onClose ?? () => Navigator.of(context).maybePop(),
                ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Align(
                alignment: Alignment.centerLeft,
                heightFactor: 1,
                // The question heading still owns the full middle column,
                // so its internally centred labels do not drift left.
                child: SizedBox(
                  width: double.infinity,
                  child:
                      center ??
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (subtitle != null)
                            Text(
                              subtitle!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                height: 1.2,
                                color: HipColors.jadeText,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          if (title != null)
                            Text(
                              title!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 17,
                                height: 1.25,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 44,
            height: 48,
            child: Align(
              alignment: Alignment.centerRight,
              child: trailing ?? const SizedBox(),
            ),
          ),
        ],
      ),
    ),
  );
}

/// Cross-fade with a short rise; the standard step / state transition (#12).
class HipFadeSwitcher extends StatelessWidget {
  const HipFadeSwitcher({
    super.key,
    required this.child,
    this.duration = HipMotion.medium,
    this.offset = .03,
    this.alignment = Alignment.topCenter,
    this.expand = false,
  });
  final Widget child;
  final Duration duration;
  final double offset;
  final AlignmentGeometry alignment;

  /// Fill the parent (media areas); otherwise size to the child.
  final bool expand;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) return child;
    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: HipMotion.curve,
      switchOutCurve: Curves.easeIn,
      layoutBuilder: (current, previous) => Stack(
        alignment: alignment,
        fit: expand ? StackFit.expand : StackFit.loose,
        children: [...previous, ?current],
      ),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween(
            begin: Offset(0, offset),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

/// The six-direction hip radar. Axis order follows the prototype:
/// 屈 top, then clockwise 外展, 外旋, 伸, 内旋, 内收.
class HipRadar extends StatelessWidget {
  const HipRadar({
    super.key,
    required this.values,
    this.highlight = const {},
    this.warn = const {},
    this.compact = false,
    this.labels = true,
  });
  final Map<HipDirection, double> values;
  final Set<HipDirection> highlight;
  final Set<HipDirection> warn;
  final bool compact;

  /// Direction labels around the chart; off for a thumbnail-sized radar
  /// (练习 · 我的髋部 card), which then fills its box.
  final bool labels;

  static const order = [
    HipDirection.flexion,
    HipDirection.abduction,
    HipDirection.externalRotation,
    HipDirection.extension,
    HipDirection.internalRotation,
    HipDirection.adduction,
  ];

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final size = math.min(c.maxWidth, c.maxHeight);
      final labelStyle = TextStyle(
        fontSize: compact ? 10 : 15,
        color: HipColors.muted,
        height: 1.2,
      );
      final scaler = MediaQuery.textScalerOf(context);
      String directionLabel(HipDirection d) => HipText.of(context).isEn
          ? switch (d) {
              HipDirection.flexion => 'Flexion',
              HipDirection.extension => 'Extension',
              HipDirection.abduction => 'Abduction',
              HipDirection.adduction => 'Adduction',
              HipDirection.internalRotation => 'Int. rot.',
              HipDirection.externalRotation => 'Ext. rot.',
            }
          : d.zh;
      final dir = Directionality.of(context);
      // Measure every label at the current text scale (bold = widest).
      Size measure(HipDirection d) {
        final tp = TextPainter(
          text: TextSpan(
            text: directionLabel(d),
            style: labelStyle.copyWith(fontWeight: FontWeight.w700),
          ),
          textDirection: dir,
          textScaler: scaler,
        )..layout();
        final s = tp.size;
        tp.dispose();
        return s;
      }

      final sizes = {for (final d in order) d: measure(d)};
      final gap = compact ? 5.0 : 8.0;
      var r = size * (!labels ? .42 : .4);
      if (labels) {
        // Reserve room so every label sits outside the polygon and inside
        // the box: side axes (cos ±0.87) need the label width, top/bottom
        // axes the label height.
        final w = sizes.values.map((s) => s.width).reduce(math.max);
        final h = sizes.values.map((s) => s.height).reduce(math.max);
        r = math.min(r, (size / 2 - gap - w - 2) / math.cos(math.pi / 6));
        r = math.min(r, size / 2 - gap - h - 2);
        r = math.max(r, size * .2);
      }
      final center = size / 2;
      return Center(
        child: SizedBox(
          width: size,
          height: size,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _RadarPainter(
                    values,
                    highlight,
                    warn,
                    r,
                    compact,
                    HipColors.palette,
                  ),
                ),
              ),
              for (var i = 0; labels && i < order.length; i++)
                Builder(
                  key: ValueKey('radar-label-${order[i].name}'),
                  builder: (_) {
                    final a = -math.pi / 2 + i * math.pi / 3;
                    final d = order[i];
                    final ls = sizes[d]!;
                    final cx = math.cos(a), sy = math.sin(a);
                    final ax = center + cx * (r + gap);
                    final ay = center + sy * (r + gap);
                    // Anchor by side: right of the chart starts at the
                    // anchor, left ends at it, top/bottom are centred.
                    final left = cx > .3
                        ? ax
                        : cx < -.3
                        ? ax - ls.width
                        : ax - ls.width / 2;
                    final top = sy < -.9
                        ? ay - ls.height
                        : sy > .9
                        ? ay
                        : ay - ls.height / 2;
                    final color = warn.contains(d)
                        ? HipColors.pain
                        : highlight.contains(d)
                        ? HipColors.tight
                        : HipColors.muted;
                    return Positioned(
                      left: left,
                      top: top,
                      width: ls.width + 1,
                      child: Text(
                        directionLabel(d),
                        maxLines: 1,
                        softWrap: false,
                        textAlign: cx > .3
                            ? TextAlign.left
                            : cx < -.3
                            ? TextAlign.right
                            : TextAlign.center,
                        style: labelStyle.copyWith(
                          color: color,
                          fontWeight: color == HipColors.muted
                              ? FontWeight.w400
                              : FontWeight.w700,
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      );
    },
  );
}

class _RadarPainter extends CustomPainter {
  _RadarPainter(
    this.values,
    this.highlight,
    this.warn,
    this.r,
    this.compact,
    this.p,
  );
  final Map<HipDirection, double> values;
  final Set<HipDirection> highlight;
  final Set<HipDirection> warn;
  final double r;
  final bool compact;
  final HipPalette p;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    Offset at(int i, double f) {
      final a = -math.pi / 2 + i * math.pi / 3;
      return c + Offset(math.cos(a), math.sin(a)) * r * f;
    }

    final grid = Paint()
      ..style = PaintingStyle.stroke
      ..color = p.line
      ..strokeWidth = compact ? .8 : 1;
    for (final f in [.25, .5, .75, 1.0]) {
      canvas.drawPath(
        Path()..addPolygon([for (var i = 0; i < 6; i++) at(i, f)], true),
        grid,
      );
    }
    for (var i = 0; i < 6; i++) {
      canvas.drawLine(c, at(i, 1), grid);
    }
    final pts = [
      for (var i = 0; i < 6; i++)
        at(i, ((values[HipRadar.order[i]] ?? 0) / 100).clamp(0, 1)),
    ];
    final shape = Path()..addPolygon(pts, true);
    canvas.drawPath(
      shape,
      Paint()..color = p.jade.withValues(alpha: p.isDark ? .18 : .14),
    );
    canvas.drawPath(
      shape,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = compact ? 1.4 : 2.2
        ..strokeJoin = StrokeJoin.round
        ..color = p.jade,
    );
    for (var i = 0; i < 6; i++) {
      final d = HipRadar.order[i];
      final color = warn.contains(d)
          ? p.pain
          : highlight.contains(d)
          ? p.tight
          : p.jade;
      canvas.drawCircle(pts[i], compact ? 2.4 : 4.5, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(_RadarPainter old) =>
      old.values != values ||
      old.highlight != highlight ||
      old.warn != warn ||
      old.p != p;
}

/// Countdown ring used by the player (round 2 #2): a hairline track, a
/// gradient progress arc with round caps and a small lit knob at its head.
/// Nothing is drawn at 0 % (no stray dot at the top). Pass
/// [progressListenable] to have only the ring repaint as time runs (the page
/// around it need not rebuild).
class HipCountdownRing extends StatefulWidget {
  const HipCountdownRing({
    super.key,
    this.progress = 0,
    this.progressListenable,
    required this.label,
    this.caption,
    this.size = 150,
    this.color,
  });
  final double progress;
  final ValueListenable<double>? progressListenable;
  final String label;
  final String? caption;
  final double size;
  final Color? color;

  @override
  State<HipCountdownRing> createState() => _HipCountdownRingState();
}

class _HipCountdownRingState extends State<HipCountdownRing> {
  // A plain [progress] is fed through a notifier so the painter has one
  // repaint source either way. (No animation controller here: the player
  // updates progress every tick, and a controller restarted that often
  // would keep the frame pump — and `pumpAndSettle` — from ever idling.)
  late final _own = ValueNotifier<double>(widget.progress);

  ValueListenable<double> get _source => widget.progressListenable ?? _own;

  @override
  void didUpdateWidget(HipCountdownRing old) {
    super.didUpdateWidget(old);
    _own.value = widget.progress;
  }

  @override
  void dispose() {
    _own.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    final color = widget.color ?? HipColors.jade;
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: HipRingPainter(
          _source,
          track: HipColors.surfaceHigh,
          color: color,
          knob: HipColors.isDark ? const Color(0xffffffff) : HipColors.surface,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: HipMotion.fast,
                transitionBuilder: (child, a) => FadeTransition(
                  opacity: a,
                  child: ScaleTransition(
                    scale: Tween(begin: .92, end: 1.0).animate(a),
                    child: child,
                  ),
                ),
                child: Text(
                  widget.label,
                  key: ValueKey(widget.label),
                  style: TextStyle(
                    fontSize: size * .34,
                    fontWeight: FontWeight.w700,
                    height: 1,
                    letterSpacing: -size * .012,
                    color: HipColors.text,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              if (widget.caption != null) ...[
                SizedBox(height: size * .035),
                Text(
                  widget.caption!,
                  style: TextStyle(
                    fontSize: size * .082,
                    height: 1.1,
                    letterSpacing: size * .006,
                    fontWeight: FontWeight.w500,
                    color: HipColors.muted,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class HipRingPainter extends CustomPainter {
  HipRingPainter(
    this.progress, {
    required this.track,
    required this.color,
    required this.knob,
  }) : super(repaint: progress);
  final ValueListenable<double> progress;
  final Color track;
  final Color color;
  final Color knob;

  @override
  void paint(Canvas canvas, Size size) {
    final p = progress.value.clamp(0.0, 1.0);
    final stroke = size.width * .052;
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - stroke / 2 - size.width * .03;
    final rect = Rect.fromCircle(center: center, radius: radius);
    // Hairline track: present but quiet.
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke * .42
        ..color = track,
    );
    if (p < .004) return;
    final sweep = math.pi * 2 * p;
    const start = -math.pi / 2;
    // Arc: from a softer tone at its tail to full colour at its head.
    final shader = SweepGradient(
      startAngle: 0,
      endAngle: math.max(sweep, .001),
      colors: [
        color.withValues(alpha: color.a * .38),
        color,
      ],
      transform: const GradientRotation(start),
    ).createShader(rect);
    // Butt ends + a round tail cap in the tail colour: a round cap on the
    // arc itself would sample the gradient's far end at the start.
    canvas.drawArc(
      rect,
      start,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.butt
        ..shader = shader,
    );
    canvas.drawCircle(
      center + Offset(math.cos(start), math.sin(start)) * radius,
      stroke / 2,
      Paint()..color = color.withValues(alpha: color.a * .38),
    );
    // Lit knob at the head: a soft glow and a small bright core.
    final head =
        center +
        Offset(math.cos(start + sweep), math.sin(start + sweep)) * radius;
    if (!HipColors.flatShadows) {
      canvas.drawCircle(
        head,
        stroke * .95,
        Paint()
          ..color = color.withValues(alpha: color.a * .45)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, stroke * .6),
      );
    }
    canvas.drawCircle(head, stroke * .5, Paint()..color = color);
    canvas.drawCircle(
      head,
      stroke * .24,
      Paint()..color = knob.withValues(alpha: .92),
    );
  }

  @override
  bool shouldRepaint(HipRingPainter old) =>
      old.progress != progress ||
      old.track != track ||
      old.color != color ||
      old.knob != knob;
}

/// The shared press feedback: while held, the child scales to [scale]
/// (default [HipMotion.pressScale]) over [HipMotion.press] and any
/// [HipTactile] inside sinks (via [HipPressedScope]); on release both
/// return over [HipMotion.release]. Under the platform's reduce-motion
/// setting the scale is dropped and only the tactile change remains.
class HipPressable extends StatefulWidget {
  const HipPressable({
    super.key,
    required this.child,
    this.onTap,
    this.scale = HipMotion.pressScale,
    this.focusNode,
    this.semanticLabel,
    this.preserveChildSemantics = false,
    this.selected,
    this.inMutuallyExclusiveGroup = false,
    this.onPressChanged,
  });
  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  final FocusNode? focusNode;
  final String? semanticLabel;

  /// Keep independently actionable children (for example a card's Start
  /// button) visible to accessibility instead of folding them into this tap.
  final bool preserveChildSemantics;
  final bool? selected;
  final bool inMutuallyExclusiveGroup;

  /// Reports pointer press/cancel changes when a shared face is painted
  /// outside this widget (for example a segmented control's sliding thumb).
  final ValueChanged<bool>? onPressChanged;
  @override
  State<HipPressable> createState() => _HipPressableState();
}

class _HipPressableState extends State<HipPressable> {
  bool _down = false;
  void _set(bool v) {
    if (_down != v && mounted) {
      setState(() => _down = v);
      widget.onPressChanged?.call(v);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final semantics = Semantics(
      container: true,
      explicitChildNodes: widget.preserveChildSemantics,
      button: true,
      enabled: widget.onTap != null,
      label: widget.semanticLabel,
      selected: widget.selected,
      inMutuallyExclusiveGroup: widget.inMutuallyExclusiveGroup,
      onTap: widget.onTap,
      child: FocusableActionDetector(
        focusNode: widget.focusNode,
        enabled: widget.onTap != null,
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
        },
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onTap?.call();
              return null;
            },
          ),
        },
        child: GestureDetector(
          excludeFromSemantics: true,
          behavior: HitTestBehavior.opaque,
          onTapDown: widget.onTap == null ? null : (_) => _set(true),
          onTapUp: widget.onTap == null ? null : (_) => _set(false),
          onTapCancel: () => _set(false),
          onTap: widget.onTap,
          child: AnimatedScale(
            scale: _down && !reduceMotion ? widget.scale : 1,
            duration: reduceMotion
                ? Duration.zero
                : _down
                ? HipMotion.press
                : HipMotion.release,
            curve: _down ? Curves.easeOut : Curves.easeOutCubic,
            child: HipPressedScope(
              pressed: _down,
              child:
                  widget.semanticLabel == null || widget.preserveChildSemantics
                  ? widget.child
                  : ExcludeSemantics(child: widget.child),
            ),
          ),
        ),
      ),
    );
    return widget.preserveChildSemantics
        ? semantics
        : MergeSemantics(child: semantics);
  }
}

/// A flat button face (no gradient, no light, no shadow) whose fill dips a
/// touch while the enclosing [HipPressable] is held — the press state for
/// the flat buttons (rationale 2026-10-19, R3–R5). It is not an ink
/// splash, so the face is never repainting mid-tap and the 开始自测
/// container transform can still snapshot it (HipRoute.expandFrom).
class _HipFlatFace extends StatelessWidget {
  const _HipFlatFace({
    required this.color,
    required this.pressedColor,
    required this.child,
    this.stadium = false,
  });
  final Color color;
  final Color pressedColor;
  final Widget child;

  /// iOS control geometry: 50 high with a 14 radius. The pill shape stays
  /// only where the button sits on an SDK-owned screen.
  final bool stadium;

  @override
  Widget build(BuildContext context) {
    final down = HipPressedScope.of(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(end: down ? 1 : 0),
      duration: down ? HipMotion.press : HipMotion.release,
      curve: down ? Curves.easeOut : Curves.easeOutCubic,
      builder: (context, t, child) => DecoratedBox(
        decoration: ShapeDecoration(
          color: Color.lerp(color, pressedColor, t),
          shape: stadium
              ? const StadiumBorder()
              : const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(14)),
                ),
        ),
        child: child,
      ),
      child: child,
    );
  }
}

/// Full-width primary CTA (开始自测, 下一项, 回首页 …): a flat brand-green
/// fill. Emphasis comes from colour, not height: no gradient, no shadow and
/// no coloured glow (tactile rationale 2026-10-19, rule R3 — only the home
/// 开始 disc is raised). Pressed: the shared [HipPressable] scale and a
/// slightly deeper fill.
class HipPrimaryButton extends StatelessWidget {
  const HipPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.trailing,
  });
  final String label;
  final VoidCallback? onPressed;
  final HipGlyph? icon;
  final HipGlyph? trailing;
  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final fg = enabled ? HipColors.onJade : HipColors.muted;
    final fill = enabled ? HipColors.primaryAction : HipColors.surfaceHigh;
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: HipPressable(
        semanticLabel: label,
        onTap: onPressed,
        child: _HipFlatFace(
          color: fill,
          pressedColor: Color.lerp(fill, const Color(0xff000000), .10)!,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      HipIcon(icon!, size: 18, filled: true, color: fg),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      label,
                      style: TextStyle(
                        fontFamily: hipFontFamily,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: fg,
                      ),
                    ),
                    if (trailing != null) ...[
                      const SizedBox(width: 4),
                      HipIcon(trailing!, size: 17, strokeWidth: 2.2, color: fg),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Stadium outline button paired with [HipPrimaryButton] (medium emphasis,
/// rule R5): surface fill and a hairline [HipColors.line] edge, as before
/// the tactile pass; pressed it dips toward [HipColors.surfaceHigh].
class HipSecondaryButton extends StatelessWidget {
  const HipSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.sdkScale = false,
  });
  final String label;
  final VoidCallback? onPressed;

  /// Keeps the pre-m5 56 / 18 size where the button is slotted into an
  /// SDK-owned screen (the trainer player's 再来一组), so it matches the
  /// SDK's own controls.
  final bool sdkScale;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: sdkScale ? 56 : 50,
    width: double.infinity,
    child: HipPressable(
      semanticLabel: label,
      onTap: onPressed,
      child: _HipFlatFace(
        // m3: fill only, no outline. UI r2: on dark the inset track was
        // near-black on near-black; a raised white α .10 fill reads.
        color: HipColors.isDark && !sdkScale
            ? Colors.white.withValues(alpha: .10)
            : HipColors.track,
        pressedColor: HipColors.surfaceHigh,
        stadium: sdkScale,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: hipFontFamily,
                  fontSize: sdkScale ? 18 : 17,
                  fontWeight: FontWeight.w500,
                  color: onPressed == null ? HipColors.muted : HipColors.text,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// Round icon button (top-bar close / back 44, player pause / skip 64): a
/// flat tonal disc ([HipColors.surfaceHigh], plus a hairline edge on light)
/// — a tool on the functional layer, not a raised object (rule R4); no
/// shadow.
class HipCircleButton extends StatelessWidget {
  const HipCircleButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.size = 44,
    this.tooltip,
  });
  final HipGlyph icon;
  final VoidCallback? onPressed;
  final double size;
  final String? tooltip;
  @override
  Widget build(BuildContext context) => HipPressable(
    semanticLabel: tooltip,
    onTap: onPressed,
    scale: .9,
    child: Container(
      width: size,
      height: size,
      // m3: top-bar sizes are a plain glyph (no disc); the player's big
      // transport keys keep their flat tonal disc.
      decoration: size <= 48
          ? null
          : BoxDecoration(
              color: HipColors.surfaceHigh,
              shape: BoxShape.circle,
              // Light: a hairline instead of the old soft shadow, so the grey disc
              // still reads on the near-white page (R4, R6④). Dark needs none.
              border: HipColors.isDark
                  ? null
                  : Border.all(color: HipColors.line),
            ),
      alignment: Alignment.center,
      child: AnimatedSwitcher(
        duration: HipMotion.fast,
        transitionBuilder: (child, a) => FadeTransition(
          opacity: a,
          child: ScaleTransition(
            scale: Tween(begin: .6, end: 1.0).animate(a),
            child: child,
          ),
        ),
        child: HipIcon(
          icon,
          key: ValueKey(icon),
          size: size * (size > 50 ? .42 : .45),
          color: onPressed == null ? HipColors.muted : HipColors.text,
          filled: true,
          strokeWidth: size > 50 ? 1.75 : 2,
        ),
      ),
    ),
  );
}

/// The home hero's round 开始 button: the app's one raised accent object
/// (tactile rationale 2026-10-19, rule R2) — a brand-green tactile disc with
/// no halo and no coloured glow, a rounded, optically centred play glyph,
/// and a press that sinks it.
class HipStartButton extends StatelessWidget {
  const HipStartButton({
    super.key,
    required this.onTap,
    required this.stage,
    this.buttonKey,
    this.size = 104,
    this.width,
    this.label = '开始',
    this.glass = false,
    this.flatDisc = false,
  });
  final VoidCallback? onTap;

  /// Jade liquid glass disc floating over imagery (首页 dock, m3): blurred
  /// backdrop, translucent jade fill, thin bright rim.
  final bool glass;
  final bool flatDisc;

  /// Palette of what the button sits on (the dark media stage).
  final HipPalette stage;
  final Key? buttonKey;

  /// Disc diameter, or the pill's height when [width] is set.
  final double size;

  /// Set for the wide pill (首页 r1, 2026-11-02): icon and label side by
  /// side; `double.infinity` fills the row.
  final double? width;
  final String label;

  @override
  Widget build(BuildContext context) {
    final pill = width != null;
    final label = this.label == '开始'
        ? HipText.of(context).pick('开始', 'Start')
        : this.label;
    final enabled = onTap != null;
    final fg = enabled ? stage.onJade : stage.faint;
    final glyph = HipIcon(
      HipGlyph.play,
      size: pill ? size * .32 : size * .32,
      filled: true,
      color: fg,
    );
    final text = Text(
      label,
      style: TextStyle(
        fontSize: pill ? size * .3 : size * .14,
        height: 1.2,
        letterSpacing: pill ? 2 : size * .01,
        fontWeight: FontWeight.w700,
        color: fg,
      ),
    );
    if (flatDisc && !pill) {
      return HipPressable(
        key: buttonKey,
        semanticLabel: label,
        onTap: onTap,
        child: RepaintBoundary(
          child: SizedBox.square(
            dimension: size,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: enabled
                    ? HipColors.primaryAction
                    : HipColors.surfaceHigh,
                shape: BoxShape.circle,
                boxShadow: enabled
                    ? HipColors.shadows([
                        BoxShadow(
                          color: HipColors.jade.withValues(alpha: .30),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ])
                    : null,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    HipIcon(
                      HipGlyph.play,
                      size: 18,
                      filled: true,
                      color: enabled ? Colors.white : fg,
                    ),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: enabled ? Colors.white : fg,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }
    if (glass && !pill) {
      return HipPressable(
        semanticLabel: label,
        key: buttonKey,
        onTap: onTap,
        scale: HipMotion.pressScale,
        child: RepaintBoundary(
          child: SizedBox.square(
            dimension: size,
            child: _GlassJadeDisc(
              enabled: enabled,
              stage: stage,
              // m4: matches the dock's items — glyph 20, label 10.5.
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: EdgeInsets.only(left: size * .02),
                    child: HipIcon(
                      HipGlyph.play,
                      size: size * 20 / 54,
                      filled: true,
                      color: fg,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    maxLines: 1,
                    softWrap: false,
                    style: TextStyle(
                      fontSize: size * 10.5 / 54,
                      height: 1.2,
                      letterSpacing: .3,
                      fontWeight: FontWeight.w600,
                      color: fg,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return HipPressable(
      semanticLabel: label,
      key: buttonKey,
      onTap: onTap,
      scale: pill ? .98 : HipMotion.pressScale,
      // Its own layer: the player's container transform starts from a
      // snapshot of this face (HipRoute.expandFrom).
      child: RepaintBoundary(
        child: SizedBox(
          width: width ?? size,
          height: size,
          child: HipTactile(
            style: enabled
                ? HipTactileStyle.accent(stage)
                : HipTactileStyle.neutral(stage),
            circle: !pill,
            radius: size / 2,
            child: Center(
              child: pill
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        glyph,
                        SizedBox(width: size * .12),
                        text,
                      ],
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        glyph,
                        SizedBox(height: size * .015),
                        text,
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassJadeDisc extends StatelessWidget {
  const _GlassJadeDisc({
    required this.enabled,
    required this.stage,
    required this.child,
  });
  final bool enabled;
  final HipPalette stage;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final high = MediaQuery.maybeHighContrastOf(context) ?? false;
    final dark = HipColors.isDark;
    final jade = enabled ? stage.jade : stage.faint;
    // m4: flat, solid-ish jade over a light blur — no glow halo, no
    // gradient, only the shared 0.5pt hairline.
    Widget body = DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: jade.withValues(alpha: high ? 1 : .9),
      ),
      child: CustomPaint(
        foregroundPainter: HipGlassRimPainter(
          radius: 999,
          dark: true,
          high: high,
          strength: .9,
        ),
        child: Center(child: child),
      ),
    );
    if (!high) {
      body = BackdropFilter(
        filter: HipGlassStyle.filter(20, dark: dark),
        child: body,
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: enabled ? HipGlassStyle.shadow(dark: dark) : null,
      ),
      child: ClipOval(child: body),
    );
  }
}

/// A flat section surface (m3, 开哥 2026-11-02: "不要搞那么多大圆角和边框"):
/// a subtle tonal fill, small corners (≤ 12), no border, rim or shadow.
/// [borderColor] (alerts) tints the fill instead of drawing an outline.
class HipPanel extends StatelessWidget {
  const HipPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderColor,
    this.radius = 12,
  });
  final Widget child;
  final EdgeInsets padding;
  final Color? borderColor;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final dark = HipColors.isDark;
    final high = MediaQuery.maybeHighContrastOf(context) ?? false;
    final rr = BorderRadius.circular(radius.clamp(0, 12).toDouble());
    final base = dark
        ? Colors.white.withValues(alpha: high ? .12 : .05)
        : Colors.black.withValues(alpha: high ? .08 : .035);
    final fill = borderColor == null
        ? base
        : Color.alphaBlend(
            borderColor!.withValues(alpha: dark ? .16 : .12),
            base,
          );
    return Material(
      color: fill,
      shape: RoundedRectangleBorder(
        borderRadius: rr,
        side: high
            ? BorderSide(color: borderColor ?? HipColors.line)
            : BorderSide.none,
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(padding: padding, child: child),
    );
  }
}

/// Signal-bar glyph from the prototype: 1 bar 紧, 2 一般, 3 松.
class HipLevelBars extends StatelessWidget {
  const HipLevelBars({super.key, required this.level, required this.color});
  final int level;
  final Color color;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      for (var i = 0; i < 3; i++)
        Container(
          width: 4,
          height: 7.0 + i * 4,
          margin: const EdgeInsets.only(right: 2),
          decoration: BoxDecoration(
            color: i < level ? color : HipColors.faint,
            borderRadius: BorderRadius.circular(1.5),
          ),
        ),
    ],
  );
}

String mmss(int seconds) =>
    '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';

/// m6: settings-style flat group — a small grey section header, then rows
/// divided by 0.5pt hairlines (no panel, no radius), like 「更多」.
class HipFlatGroup extends StatelessWidget {
  const HipFlatGroup({
    super.key,
    this.title,
    this.trailing,
    required this.children,
    this.indent = 0,
  });
  final String? title;
  final Widget? trailing;
  final List<Widget> children;

  /// Left inset of the dividers between rows (to clear a leading glyph).
  final double indent;

  @override
  Widget build(BuildContext context) {
    final line = Divider(
      height: 1,
      thickness: .5,
      color: HipColors.text.withValues(alpha: .12),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.2,
                      letterSpacing: 1,
                      fontWeight: FontWeight.w600,
                      color: HipColors.faint,
                    ),
                  ),
                ),
                ?trailing,
              ],
            ),
          ),
        line,
        for (final (i, c) in children.indexed) ...[
          if (i > 0)
            Padding(
              padding: EdgeInsets.only(left: indent),
              child: line,
            ),
          c,
        ],
        line,
      ],
    );
  }
}
