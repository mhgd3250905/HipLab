import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show LogicalKeyboardKey;

import '../../core/media/drill_media.dart';
import '../../core/media/media_controller.dart';
import '../../core/media/media_view.dart';
import '../domain/hip_action_media.dart';
import '../domain/hip_models.dart';
import 'hip_icons.dart';
import 'hip_tactile.dart';
import 'hip_theme.dart';

export 'hip_tactile.dart';

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

/// A drill's picture: its poster at once, the looping clip faded in over it
/// only after the clip's first frame is on screen (#3/#12) — no black box,
/// no native play/pause placeholder, no jump between poster and video.
class HipDrillArt extends StatefulWidget {
  const HipDrillArt({
    super.key,
    required this.drill,
    this.play = false,
    this.fit = BoxFit.cover,
    this.showPendingLabel = true,
    this.alignment = Alignment.center,
    this.mirror = false,
    this.mediaViewBuilder,
  });
  final HipDrill drill;

  /// Loop the clip (when the drill has one and video is enabled). Turning
  /// this off pauses on the current frame instead of tearing the view down.
  final bool play;
  final BoxFit fit;
  final bool showPendingLabel;
  final Alignment alignment;

  /// Flip horizontally (the other side of a sided move).
  final bool mirror;

  /// Replaces the native view in widget tests, retaining the real playback
  /// controller and widget lifecycle without requiring a mobile WebView.
  @visibleForTesting
  final Widget Function(DrillMedia media, DrillMediaController controller)?
  mediaViewBuilder;

  @override
  State<HipDrillArt> createState() => _HipDrillArtState();
}

class _HipDrillArtState extends State<HipDrillArt> {
  DrillMediaController? _controller;
  DrillMedia? _media;
  bool _shown = false;

  /// Player variant the web view was created for ('light' or null = dark).
  String? _variant;

  /// 'light' when the light theme is in effect and this clip has a light
  /// render bundled; null plays the default (dark-stage) clip.
  String? get _wantedVariant =>
      !HipColors.isDark && HipMediaVariants.hasLightVideo(widget.drill.video)
      ? 'light'
      : null;

  /// Theme switched while the clip is up: the web view loaded the other
  /// stage's file, so build a fresh one. The new theme's poster covers the
  /// box (opacity 1) until the new clip reports its first frame, so the
  /// switch never shows an empty or wrong-colour stage.
  void _followTheme() {
    final wanted = _wantedVariant;
    if (wanted == _variant) return;
    _variant = wanted;
    final old = _controller;
    if (old == null) return;
    old.removeListener(_onMedia);
    // The old platform view detaches from it while unmounting this frame.
    WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
    _controller = null;
    _media = null;
    _shown = false;
    _sync();
  }

  bool _videoAllowed(BuildContext context) =>
      widget.drill.mediaStatus == HipMediaStatus.video &&
      HipMediaPolicy.of(context);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
    _syncPlayback();
  }

  @override
  void didUpdateWidget(HipDrillArt old) {
    super.didUpdateWidget(old);
    if (old.drill.id != widget.drill.id) {
      _teardown();
      _sync();
    } else if (old.play != widget.play) {
      _sync();
      _syncPlayback();
    }
  }

  void _syncPlayback() {
    final c = _controller;
    if (c == null) return;
    final allowed = _videoAllowed(context);
    c.setActive(allowed);
    if (allowed && widget.play && !c.wantsPlay) c.toggle();
    if ((!allowed || !widget.play) && c.wantsPlay) c.pause();
  }

  void _teardown() {
    _controller?.removeListener(_onMedia);
    _controller?.dispose();
    _controller = null;
    _media = null;
    _shown = false;
  }

  /// Every clip (`assets/drill_media/hip-<id>.mp4`) carries its loop length in
  /// the content pack; drills without one show their poster only.
  static DrillMedia? _ownMedia(HipDrill d) {
    final video = d.video, poster = d.poster, seconds = d.duration;
    if (video == null || poster == null || seconds == null) return null;
    final m = RegExp(
      r'^assets/drill_media/(hip-[a-z0-9]+(?:-[a-z0-9]+)*)\.mp4$',
    ).firstMatch(video);
    if (m == null || poster != 'assets/drill_media/${m[1]}.jpg') return null;
    return DrillMedia(
      id: m[1]!,
      videoAsset: video,
      posterAsset: poster,
      duration: seconds,
      posterTime: d.posterTime,
    );
  }

  void _sync() {
    // The web view is created once the clip should play and then kept: a
    // pause keeps the frame, so resuming never flashes.
    if (!widget.play || !_videoAllowed(context) || _controller != null) return;
    final own = _ownMedia(widget.drill);
    if (own == null) return;
    _variant = _wantedVariant;
    final controller = _controller = DrillMediaController()
      ..addListener(_onMedia);
    _media = own;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // didUpdateWidget may already have requested playback this frame.
      // Starting the same controller twice must not toggle it back to pause.
      if (mounted &&
          _controller == controller &&
          widget.play &&
          !controller.wantsPlay) {
        controller.toggle();
      }
    });
  }

  void _onMedia() {
    final c = _controller;
    if (c == null || !mounted) return;
    final shown = c.hasFrame && !c.failed;
    if (shown != _shown) setState(() => _shown = shown);
  }

  @override
  void dispose() {
    _teardown();
    super.dispose();
  }

  String? get _poster {
    final p = widget.drill.poster;
    return p == null ? null : HipMediaVariants.themed(p);
  }

  @override
  Widget build(BuildContext context) {
    _followTheme();
    final poster = _poster;
    Widget still = poster == null
        ? HipPendingArt(label: widget.showPendingLabel ? '动画待渲染' : null)
        : Image.asset(
            poster,
            fit: widget.fit,
            alignment: widget.alignment,
            gaplessPlayback: true,
            frameBuilder: (context, child, frame, sync) => sync
                ? child
                : AnimatedOpacity(
                    opacity: frame == null ? 0 : 1,
                    duration: HipMotion.fast,
                    child: child,
                  ),
            errorBuilder: (_, _, _) => const HipPendingArt(label: '动画待渲染'),
          );
    if (poster != null) {
      // Theme switch: cross-fade the two stages' posters instead of showing
      // the old one on the new backdrop until the new one has decoded.
      still = AnimatedSwitcher(
        duration: HipMotion.fast,
        layoutBuilder: (current, previous) =>
            Stack(fit: StackFit.expand, children: [...previous, ?current]),
        child: KeyedSubtree(key: ValueKey(poster), child: still),
      );
    }
    final media = _media;
    final controller = _controller;
    Widget out;
    if (media == null || controller == null) {
      out = still;
    } else {
      out = Stack(
        fit: StackFit.expand,
        children: [
          widget.mediaViewBuilder?.call(media, controller) ??
              DrillMediaPlatformView(
                key: ValueKey('${widget.drill.id}/${_variant ?? 'dark'}'),
                media: media,
                controller: controller,
                fit: widget.fit == BoxFit.contain ? 'contain' : 'cover',
                align: widget.alignment,
                variant: _variant,
                labels: const {
                  'title': '动作示范',
                  'play': '播放',
                  'pause': '暂停',
                  'error': '示范加载失败',
                  'disabled': '示范已暂停',
                },
              ),
          // The poster stays on top until the clip has a frame, then fades.
          IgnorePointer(
            child: AnimatedOpacity(
              // A new platform surface must start fully covered. Reusing the
              // old fade would animate from zero while the new clip is blank.
              key: ObjectKey(controller),
              opacity: _shown ? 0 : 1,
              duration: HipMotion.medium,
              curve: Curves.easeOut,
              child: still,
            ),
          ),
        ],
      );
    }
    if (widget.mirror) {
      out = Transform.flip(flipX: true, child: out);
    }
    return ColoredBox(
      color: HipMediaVariants.stageFor(widget.drill.poster),
      child: out,
    );
  }
}

/// Warms the image cache for the posters a screen is about to show (the next
/// drill, the next assessment item) so they appear on the first frame —
/// in the variant of the theme in effect.
void hipPrecache(BuildContext context, Iterable<String?> assets) {
  for (final a in assets) {
    if (a != null) {
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
    this.onClose,
    this.icon = HipGlyph.close,
    this.tooltip = '关闭',
  });
  final String? title;
  final String? subtitle;

  /// Centred content instead of a title (e.g. progress dots).
  final Widget? center;
  final Widget? trailing;
  final VoidCallback? onClose;
  final HipGlyph icon;
  final String tooltip;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
    child: ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: Row(
        children: [
          HipCircleButton(
            icon: icon,
            tooltip: tooltip,
            onPressed: onClose ?? () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: 12),
          Expanded(
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
                          fontSize: 20,
                          height: 1.25,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                  ],
                ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 44,
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
  Widget build(BuildContext context) => AnimatedSwitcher(
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
      final r = size * (!labels ? .42 : (compact ? .3 : .34));
      final labelStyle = TextStyle(
        fontSize: compact ? 10 : 15,
        color: HipColors.muted,
        height: 1,
      );
      return SizedBox(
        width: size,
        height: size,
        child: Stack(
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
                builder: (_) {
                  final a = -math.pi / 2 + i * math.pi / 3;
                  final lr = r + (compact ? 13 : 26);
                  final d = order[i];
                  final color = warn.contains(d)
                      ? HipColors.pain
                      : highlight.contains(d)
                      ? HipColors.tight
                      : HipColors.muted;
                  return Positioned(
                    left: size / 2 + math.cos(a) * lr - 30,
                    top: size / 2 + math.sin(a) * lr - 10,
                    width: 60,
                    height: 20,
                    child: Center(
                      child: Text(
                        d.zh,
                        style: labelStyle.copyWith(
                          color: color,
                          fontWeight: color == HipColors.muted
                              ? FontWeight.w400
                              : FontWeight.w700,
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
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
    this.selected,
    this.inMutuallyExclusiveGroup = false,
    this.onPressChanged,
  });
  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  final FocusNode? focusNode;
  final String? semanticLabel;
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
    return MergeSemantics(
      child: Semantics(
        container: true,
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
              duration: _down ? HipMotion.press : HipMotion.release,
              curve: _down ? Curves.easeOut : Curves.easeOutCubic,
              child: HipPressedScope(
                pressed: _down,
                child: widget.semanticLabel == null
                    ? widget.child
                    : ExcludeSemantics(child: widget.child),
              ),
            ),
          ),
        ),
      ),
    );
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
    this.border,
  });
  final Color color;
  final Color pressedColor;
  final Color? border;
  final Widget child;

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
          shape: StadiumBorder(
            side: border == null ? BorderSide.none : BorderSide(color: border!),
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
    final fg = enabled ? HipColors.onJade : HipColors.faint;
    final fill = enabled ? HipColors.jade : HipColors.surfaceHigh;
    return SizedBox(
      width: double.infinity,
      height: 56,
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
                      HipIcon(icon!, size: 20, filled: true, color: fg),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      label,
                      style: TextStyle(
                        fontFamily: hipFontFamily,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: fg,
                      ),
                    ),
                    if (trailing != null) ...[
                      const SizedBox(width: 4),
                      HipIcon(trailing!, size: 20, strokeWidth: 2.2, color: fg),
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
  });
  final String label;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 56,
    width: double.infinity,
    child: HipPressable(
      semanticLabel: label,
      onTap: onPressed,
      child: _HipFlatFace(
        color: HipColors.surface,
        pressedColor: HipColors.surfaceHigh,
        border: HipColors.line,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: hipFontFamily,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: onPressed == null ? HipColors.faint : HipColors.text,
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
      decoration: BoxDecoration(
        color: HipColors.surfaceHigh,
        shape: BoxShape.circle,
        // Light: a hairline instead of the old soft shadow, so the grey disc
        // still reads on the near-white page (R4, R6④). Dark needs none.
        border: HipColors.isDark ? null : Border.all(color: HipColors.line),
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
          color: onPressed == null ? HipColors.faint : HipColors.text,
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
    this.label = '开始',
  });
  final VoidCallback? onTap;

  /// Palette of what the button sits on (the dark media stage).
  final HipPalette stage;
  final Key? buttonKey;
  final double size;
  final String label;

  @override
  Widget build(BuildContext context) => HipPressable(
    semanticLabel: label,
    key: buttonKey,
    onTap: onTap,
    // Its own layer: the player's container transform starts from a
    // snapshot of this face (HipRoute.expandFrom).
    child: RepaintBoundary(
      child: SizedBox.square(
        dimension: size,
        child: HipTactile(
          style: HipTactileStyle.accent(stage),
          circle: true,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                HipIcon(
                  HipGlyph.play,
                  size: size * .32,
                  filled: true,
                  color: stage.onJade,
                ),
                SizedBox(height: size * .015),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: size * .14,
                    height: 1.2,
                    letterSpacing: size * .01,
                    fontWeight: FontWeight.w700,
                    color: stage.onJade,
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

class HipPanel extends StatelessWidget {
  const HipPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderColor,
    this.radius = 22,
  });
  final Widget child;
  final EdgeInsets padding;
  final Color? borderColor;
  final double radius;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      boxShadow: HipColors.cardShadow,
    ),
    child: Material(
      color: HipColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
        side: BorderSide(color: borderColor ?? HipColors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(padding: padding, child: child),
    ),
  );
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
