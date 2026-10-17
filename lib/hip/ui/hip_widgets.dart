import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/media/drill_media.dart';
import '../../core/media/media_controller.dart';
import '../../core/media/media_view.dart';
import '../domain/hip_models.dart';
import 'hip_theme.dart';

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

/// A drill's picture: looping video when one exists in the repo, a rendered
/// still (prototype art) when one exists, otherwise a "待渲染" placeholder.
class HipDrillArt extends StatefulWidget {
  const HipDrillArt({
    super.key,
    required this.drill,
    this.play = false,
    this.fit = BoxFit.cover,
    this.showPendingLabel = true,
    this.alignment = Alignment.center,
  });
  final HipDrill drill;
  final bool play;
  final BoxFit fit;
  final bool showPendingLabel;
  final Alignment alignment;

  @override
  State<HipDrillArt> createState() => _HipDrillArtState();
}

class _HipDrillArtState extends State<HipDrillArt> {
  DrillMediaController? _controller;
  DrillMedia? _media;

  bool _wantsVideo(BuildContext context) =>
      widget.play &&
      widget.drill.mediaStatus == HipMediaStatus.video &&
      HipMediaPolicy.of(context);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(HipDrillArt old) {
    super.didUpdateWidget(old);
    if (old.drill.id != widget.drill.id || old.play != widget.play) {
      _controller?.dispose();
      _controller = null;
      _media = null;
      _sync();
    }
  }

  /// Every clip (`assets/drill_media/hip-<id>.mp4`) carries its loop length in
  /// the content pack; drills without one show their poster only.
  static DrillMedia? _ownMedia(HipDrill d) {
    final video = d.video, poster = d.poster, seconds = d.duration;
    if (video == null || poster == null || seconds == null) return null;
    final m = RegExp(r'^assets/drill_media/(hip-[a-z0-9]+(?:-[a-z0-9]+)*)\.mp4$').firstMatch(video);
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
    if (!_wantsVideo(context) || _controller != null) return;
    final own = _ownMedia(widget.drill);
    if (own == null) return;
    final controller = _controller = DrillMediaController();
    _media = own;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _controller == controller) controller.toggle();
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.drill;
    final poster = d.poster;
    final still = poster == null
        ? HipPendingArt(label: widget.showPendingLabel ? '动画待渲染' : null)
        : Image.asset(
            poster,
            fit: widget.fit,
            alignment: widget.alignment,
            errorBuilder: (_, _, _) => const HipPendingArt(label: '动画待渲染'),
          );
    final media = _media;
    final controller = _controller;
    if (media == null || controller == null) return still;
    return Stack(
      fit: StackFit.expand,
      children: [
        still,
        DrillMediaPlatformView(
          key: ValueKey(d.id),
          media: media,
          controller: controller,
          labels: const {
            'title': '动作示范',
            'play': '播放',
            'pause': '暂停',
            'error': '示范加载失败',
            'disabled': '示范已暂停',
          },
        ),
      ],
    );
  }
}

/// Graphite placeholder with a soft jade glow and a figure glyph.
class HipPendingArt extends StatelessWidget {
  const HipPendingArt({super.key, this.label});
  final String? label;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      gradient: RadialGradient(
        center: Alignment(0, -.1),
        radius: .9,
        colors: [Color(0xff1d2a27), HipColors.surface],
      ),
    ),
    child: LayoutBuilder(
      builder: (context, c) => Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.accessibility_new_rounded,
            size: math.min(c.maxWidth, c.maxHeight) * .42,
            color: HipColors.jade.withValues(alpha: .28),
          ),
          if (label != null && c.maxWidth > 90)
            Positioned(
              bottom: c.maxHeight > 200 ? 34 : 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: HipColors.background.withValues(alpha: .6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  label!,
                  style: const TextStyle(fontSize: 11, color: HipColors.muted),
                ),
              ),
            ),
        ],
      ),
    ),
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
  });
  final Map<HipDirection, double> values;
  final Set<HipDirection> highlight;
  final Set<HipDirection> warn;
  final bool compact;

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
      final r = size * (compact ? .3 : .34);
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
                painter: _RadarPainter(values, highlight, warn, r, compact),
              ),
            ),
            for (var i = 0; i < order.length; i++)
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
  _RadarPainter(this.values, this.highlight, this.warn, this.r, this.compact);
  final Map<HipDirection, double> values;
  final Set<HipDirection> highlight;
  final Set<HipDirection> warn;
  final double r;
  final bool compact;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    Offset at(int i, double f) {
      final a = -math.pi / 2 + i * math.pi / 3;
      return c + Offset(math.cos(a), math.sin(a)) * r * f;
    }

    final grid = Paint()
      ..style = PaintingStyle.stroke
      ..color = HipColors.line
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
      Paint()..color = HipColors.jade.withValues(alpha: .18),
    );
    canvas.drawPath(
      shape,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = compact ? 1.4 : 2.2
        ..strokeJoin = StrokeJoin.round
        ..color = HipColors.jade,
    );
    for (var i = 0; i < 6; i++) {
      final d = HipRadar.order[i];
      final color = warn.contains(d)
          ? HipColors.pain
          : highlight.contains(d)
          ? HipColors.tight
          : HipColors.jade;
      canvas.drawCircle(pts[i], compact ? 2.4 : 4.5, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(_RadarPainter old) =>
      old.values != values || old.highlight != highlight;
}

/// Countdown ring used by the player and assessment timers.
class HipCountdownRing extends StatelessWidget {
  const HipCountdownRing({
    super.key,
    required this.progress,
    required this.label,
    this.caption,
    this.size = 150,
  });
  final double progress;
  final String label;
  final String? caption;
  final double size;
  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(
      painter: _RingPainter(progress.clamp(0, 1)),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: size * .36,
                fontWeight: FontWeight.w700,
                height: 1,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            if (caption != null)
              Text(
                caption!,
                style: TextStyle(fontSize: size * .085, color: HipColors.muted),
              ),
          ],
        ),
      ),
    ),
  );
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.progress);
  final double progress;
  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * .065;
    final rect = (Offset.zero & size).deflate(stroke / 2 + 2);
    canvas.drawArc(
      rect,
      0,
      math.pi * 2,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = HipColors.surfaceHigh,
    );
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = HipColors.jade,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}

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
  final IconData? icon;
  final IconData? trailing;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 56,
    child: DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: onPressed == null
            ? null
            : [
                BoxShadow(
                  color: HipColors.jade.withValues(alpha: .28),
                  blurRadius: 24,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: HipColors.jade,
          foregroundColor: const Color(0xff07261d),
          disabledBackgroundColor: HipColors.surfaceHigh,
          shape: const StadiumBorder(),
          textStyle: const TextStyle(
            fontFamily: hipFontFamily,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 22),
              const SizedBox(width: 6),
            ],
            Text(label),
            if (trailing != null) ...[
              const SizedBox(width: 6),
              Icon(trailing, size: 22),
            ],
          ],
        ),
      ),
    ),
  );
}

class HipCircleButton extends StatelessWidget {
  const HipCircleButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.size = 44,
    this.tooltip,
  });
  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  final String? tooltip;
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: tooltip,
    child: Material(
      color: HipColors.surfaceHigh,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox.square(
          dimension: size,
          child: Icon(icon, size: size * .46, color: HipColors.text),
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
  });
  final Widget child;
  final EdgeInsets padding;
  final Color? borderColor;
  @override
  Widget build(BuildContext context) => Material(
    color: HipColors.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(22),
      side: BorderSide(color: borderColor ?? HipColors.line),
    ),
    clipBehavior: Clip.antiAlias,
    child: Padding(padding: padding, child: child),
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
