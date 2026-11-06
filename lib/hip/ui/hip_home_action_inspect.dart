import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../domain/hip_models.dart';
import 'hip_icons.dart';
import 'hip_theme.dart';
import 'hip_widgets.dart';

/// A shared printed face for the whole deck. The front alone owns a live video;
/// its media subtree stays mounted while the editorial layout opens around it.
class HipHomeActionFace extends StatefulWidget {
  const HipHomeActionFace({
    super.key,
    required this.drill,
    required this.number,
    required this.restingSize,
    this.stackDepth = 0,
    this.front = true,
    this.warmVideo = false,
    this.mediaKey,
    this.mediaLabelKey,
    this.revealPausedFrame = true,
    this.onFrameReadyChanged,
    this.expansion = 0,
    this.expanded = false,
    this.paused = true,
    this.onClose,
    this.onToggle,
    this.informationScroll,
    this.compact = false,
    this.dose = '',
    this.cue = '',
    this.description = '',
  });

  final HipDrill drill;
  final int number;
  final Size restingSize;
  final double stackDepth;
  final double expansion;
  final bool front, expanded, paused, compact;
  final bool warmVideo, revealPausedFrame;
  final Key? mediaKey, mediaLabelKey;
  final ValueChanged<bool>? onFrameReadyChanged;
  final ScrollController? informationScroll;
  final VoidCallback? onClose, onToggle;
  final String dose, cue, description;

  @override
  State<HipHomeActionFace> createState() => _HipHomeActionFaceState();
}

class _TypeMetrics {
  const _TypeMetrics(this.key, this.title, this.dose, this.cue);
  final Object key;
  final double title, dose, cue;
}

class _LabelMetrics {
  const _LabelMetrics(this.key, this.size);
  final Object key;
  final Size size;
}

class _HipHomeActionFaceState extends State<HipHomeActionFace> {
  _TypeMetrics? _types;
  final _labels = <String, _LabelMetrics>{};

  static TextStyle _titleStyle(Color color) => TextStyle(
    fontFamily: hipFontFamily,
    fontSize: 30,
    height: 1.18,
    fontWeight: FontWeight.w700,
    letterSpacing: -.8,
    color: color,
  );
  static TextStyle _doseStyle(Color color) => TextStyle(
    fontFamily: hipFontFamily,
    fontSize: 16,
    height: 1.35,
    fontWeight: FontWeight.w600,
    color: color,
  );
  static TextStyle _cueStyle(Color color) => TextStyle(
    fontFamily: hipFontFamily,
    fontSize: 13,
    height: 1.5,
    color: color,
  );

  double _measure(
    String text,
    TextStyle style,
    double width,
    int lines,
    TextScaler scaler,
    TextDirection direction,
  ) {
    if (text.isEmpty) return 0;
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: lines,
      textDirection: direction,
      textScaler: scaler,
    )..layout(maxWidth: width);
    final height = painter.height;
    painter.dispose();
    return height;
  }

  // A fixed typography canvas scales with the paper, keeping line breaks stable.
  Widget _type(
    String text,
    TextStyle style,
    double width,
    double height,
    int lines, {
    Key? key,
  }) => FittedBox(
    alignment: Alignment.topLeft,
    fit: BoxFit.contain,
    child: SizedBox(
      width: width,
      height: height,
      child: Text(
        text,
        key: key,
        maxLines: lines,
        overflow: TextOverflow.ellipsis,
        style: style,
      ),
    ),
  );

  // Keep the printed glyphs at their final size, and scale their canvas rather
  // than shaping another paragraph at every fractional animation font size.
  Widget _printedLabel(
    BuildContext context,
    String slot,
    String text,
    TextStyle style,
    double scale, {
    Key? key,
  }) {
    final inheritedStyle = DefaultTextStyle.of(context).style.merge(style);
    final scaler = MediaQuery.textScalerOf(context);
    final direction = Directionality.of(context);
    final metricsKey = (
      text,
      inheritedStyle.copyWith(color: const Color(0xff000000)),
      scaler,
      direction,
    );
    var metrics = _labels[slot];
    if (metrics?.key != metricsKey) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: inheritedStyle),
        maxLines: 1,
        textDirection: direction,
        textScaler: scaler,
      )..layout();
      metrics = _LabelMetrics(metricsKey, painter.size);
      _labels[slot] = metrics;
      painter.dispose();
    }
    final size = metrics!.size;
    return SizedBox(
      width: size.width * scale,
      height: size.height * scale,
      child: ClipRect(
        child: OverflowBox(
          alignment: Alignment.topLeft,
          minWidth: size.width,
          maxWidth: size.width,
          minHeight: size.height,
          maxHeight: size.height,
          child: Transform.scale(
            alignment: Alignment.topLeft,
            scale: scale,
            child: Text(
              text,
              key: key,
              maxLines: 1,
              softWrap: false,
              style: style,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final drill = widget.drill;
      final classification = [
        drill.methods.map((method) => method.zh).join(' · '),
        drill.directions.map((direction) => direction.zh).join(' / '),
      ].where((value) => value.isNotEmpty).join(' · ');
      final t = widget.expansion;
      final front = widget.front;
      final active = front && (widget.expanded || t > 0);
      final compact = widget.compact;
      final w = box.maxWidth;
      final view = MediaQuery.of(context);
      final expandedWidth = math.min(
        460.0,
        math.max(0.0, view.size.width - 40),
      );
      final expandedHeight = math.min(
        720.0,
        math.max(0.0, view.size.height - view.padding.vertical - 48),
      );
      final source = widget.restingSize;
      final inset = lerpDouble(compact ? 10 : 22, 26, t)!;
      final typeWidth = math.max(
        100.0,
        math.min(460.0, MediaQuery.sizeOf(context).width - 40) - 52,
      );
      final scaler = MediaQuery.textScalerOf(context);
      final direction = Directionality.of(context);
      final key = (
        typeWidth,
        scaler.scale(30),
        scaler.scale(16),
        scaler.scale(13),
        direction,
        drill.name,
        widget.dose,
        widget.cue,
      );
      if (_types?.key != key) {
        _types = _TypeMetrics(
          key,
          _measure(
            drill.name,
            _titleStyle(HipColors.text),
            typeWidth,
            2,
            scaler,
            direction,
          ),
          _measure(
            widget.dose,
            _doseStyle(HipColors.jadeText),
            typeWidth,
            1,
            scaler,
            direction,
          ),
          _measure(
            widget.cue,
            _cueStyle(HipColors.muted),
            typeWidth,
            2,
            scaler,
            direction,
          ),
        );
      }
      final types = _types!;
      final typeScale = (w - 2 * inset) / typeWidth;
      final titleHeight = types.title * typeScale;
      final doseHeight = types.dose * typeScale;
      final cueHeight = types.cue * typeScale;
      final doseGap = widget.dose.isEmpty ? 0.0 : lerpDouble(7, 11, t)!;
      final cueGap = widget.cue.isEmpty ? 0.0 : lerpDouble(5, 9, t)!;
      final sourceScale = (source.width - 2 * (compact ? 10 : 22)) / typeWidth;
      final sourceFooter =
          (types.title + types.dose + types.cue) * sourceScale +
          (widget.dose.isEmpty ? 0 : 7) +
          (widget.cue.isEmpty ? 0 : 5) +
          (compact ? 12 : 22);
      final header = compact ? 28.0 : 60.0;
      final smallMedia = Rect.fromLTWH(
        0,
        header,
        source.width,
        math.max(0, source.height - header - sourceFooter - 4),
      );
      final expandedMeta =
          types.title +
          types.dose +
          types.cue +
          (widget.dose.isEmpty ? 0 : 11) +
          (widget.cue.isEmpty ? 0 : 9);
      // Reserve readable article space even for two-line names and cues.
      final mediaLimit = expandedHeight - 90 - 18 - expandedMeta - 20 - 48 - 80;
      final largeMedia = Rect.fromLTWH(
        10,
        90,
        expandedWidth - 20,
        math.max(
          60,
          math.min(
            math.min(expandedWidth - 20, expandedHeight * .46),
            mediaLimit,
          ),
        ),
      );
      final media = Rect.lerp(smallMedia, largeMedia, t)!;
      final titleTop = media.bottom + lerpDouble(4, 18, t)!;
      final doseTop = titleTop + titleHeight + doseGap;
      final cueTop = doseTop + doseHeight + cueGap;
      final articleTop = cueTop + cueHeight + lerpDouble(8, 20, t)!;
      final radius = lerpDouble(22, 28, t)!;
      final description =
          (widget.description.trim().isNotEmpty
                  ? widget.description
                  : drill.note)
              .trim();
      final body = description == widget.cue.trim() ? '' : description;
      final depth = (widget.stackDepth / 2).clamp(0.0, 1.0);
      final detailsOpacity = const Interval(
        .45,
        1,
        curve: Curves.easeOut,
      ).transform(t);
      final ruleColor = HipColors.jadeText.withValues(alpha: .18);

      return DecoratedBox(
        decoration: BoxDecoration(
          color: HipColors.mediaBackdrop,
          borderRadius: BorderRadius.circular(radius),
          boxShadow: HipColors.shadows([
            BoxShadow(
              color: Colors.black.withValues(
                alpha: HipColors.isDark ? .32 : .085,
              ),
              blurRadius: lerpDouble(lerpDouble(20, 12, depth), 34, t)!,
              offset: Offset(0, lerpDouble(lerpDouble(7, 4, depth), 14, t)!),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: .035),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ]),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned(
                key: const ValueKey('face-header'),
                left: inset,
                right: 130 * t + inset * (1 - t),
                top: lerpDouble(compact ? 8 : 20, 26, t)!,
                height: 44,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _printedLabel(
                          context,
                          'masthead',
                          'HIPLAB',
                          TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2.5,
                            color: HipColors.jadeText,
                          ),
                          lerpDouble(compact ? 8 : 10, 11, t)! / 11,
                        ),
                        SizedBox(width: 12 * t),
                        Expanded(
                          child: Opacity(
                            opacity: t,
                            child: Text(
                              '动作研习',
                              maxLines: 1,
                              style: TextStyle(
                                fontSize: 9,
                                letterSpacing: 1,
                                color: HipColors.muted,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (!compact)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: _printedLabel(
                          context,
                          'classification',
                          classification.isEmpty ? '动作练习' : classification,
                          TextStyle(fontSize: 11, color: HipColors.muted),
                          lerpDouble(10, 11, t)! / 11,
                        ),
                      ),
                  ],
                ),
              ),
              Positioned(
                key: const ValueKey('face-number'),
                left: lerpDouble(w - inset - 44, w - 132, t),
                top: lerpDouble(compact ? 8 : 24, 21, t),
                width: lerpDouble(44, 66, t),
                height: lerpDouble(28, 56, t),
                child: Align(
                  alignment: Alignment.topRight,
                  child: _printedLabel(
                    context,
                    'number',
                    widget.number.toString().padLeft(2, '0'),
                    TextStyle(
                      fontSize: 46,
                      height: 1,
                      fontWeight: FontWeight.w300,
                      letterSpacing: -.8,
                      color: Color.lerp(
                        HipColors.muted,
                        HipColors.jadeText.withValues(alpha: .65),
                        t,
                      ),
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                    lerpDouble(compact ? 10 : 17, 46, t)! / 46,
                    key: front
                        ? const ValueKey('home-deck-position')
                        : ValueKey('back-position-${widget.number}'),
                  ),
                ),
              ),
              if (front)
                Positioned(
                  key: const ValueKey('face-close'),
                  right: 12,
                  top: 20,
                  width: 44,
                  height: 44,
                  child: IgnorePointer(
                    ignoring: !widget.expanded || !front,
                    child: ExcludeSemantics(
                      excluding: !widget.expanded || !front,
                      child: Opacity(
                        opacity: t,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: HipColors.surface.withValues(alpha: .7),
                            border: Border.all(color: HipColors.line),
                          ),
                          child: HipCircleButton(
                            key: front
                                ? const ValueKey('home-deck-expanded-close')
                                : null,
                            icon: HipGlyph.close,
                            tooltip: '收起动作卡片',
                            onPressed: widget.onClose,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              Positioned(
                key: const ValueKey('face-masthead-rule'),
                left: inset,
                right: inset,
                top: media.top - 11,
                height: 2,
                child: IgnorePointer(
                  child: Opacity(
                    opacity: t,
                    child: Row(
                      children: [
                        SizedBox(
                          width: 22,
                          height: 2,
                          child: ColoredBox(color: HipColors.jadeText),
                        ),
                        Expanded(
                          child: Center(
                            child: Container(height: .5, color: ruleColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned.fromRect(
                key: const ValueKey('face-media'),
                rect: media,
                child: Semantics(
                  key:
                      widget.mediaLabelKey ??
                      (front
                          ? const ValueKey('home-hero')
                          : ValueKey('back-art-${widget.number}')),
                  button: widget.expanded,
                  label: widget.expanded
                      ? (widget.paused ? '播放动作示范' : '暂停动作示范')
                      : drill.name,
                  value: widget.paused || !widget.expanded ? '已暂停' : '自动循环播放',
                  onTap: widget.expanded ? widget.onToggle : null,
                  child: GestureDetector(
                    key: front
                        ? const ValueKey('home-deck-expanded-media')
                        : null,
                    behavior: HitTestBehavior.opaque,
                    excludeFromSemantics: true,
                    onTap: widget.expanded ? widget.onToggle : null,
                    child: Center(
                      child: SizedBox.square(
                        dimension: math.min(media.width, media.height),
                        child: HipDrillArt(
                          key: widget.mediaKey,
                          drill: drill,
                          play: widget.expanded && !widget.paused,
                          holdVideo: front || widget.warmVideo,
                          revealPausedFrame: widget.revealPausedFrame,
                          onFrameReadyChanged: widget.onFrameReadyChanged,
                          showPendingLabel: false,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                key: const ValueKey('face-side-note'),
                left: inset - 8,
                top: 112,
                width: 10,
                height: 120,
                child: IgnorePointer(
                  child: ExcludeSemantics(
                    child: Opacity(
                      opacity: t * .65,
                      child: RotatedBox(
                        quarterTurns: 3,
                        child: Text(
                          'HIP MOBILITY',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 8,
                            letterSpacing: 2,
                            color: HipColors.muted,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                key: const ValueKey('face-title-rule'),
                left: inset,
                top: titleTop - 11,
                width: 26,
                height: 2,
                child: IgnorePointer(
                  child: Opacity(
                    opacity: t,
                    child: ColoredBox(color: HipColors.jadeText),
                  ),
                ),
              ),
              Positioned(
                key: const ValueKey('face-title'),
                left: inset,
                right: inset,
                top: titleTop,
                height: titleHeight,
                child: _type(
                  drill.name,
                  _titleStyle(HipColors.text),
                  typeWidth,
                  types.title,
                  2,
                  key: front
                      ? const ValueKey('home-deck-caption')
                      : ValueKey('back-caption-${widget.number}'),
                ),
              ),
              if (widget.dose.isNotEmpty)
                Positioned(
                  key: const ValueKey('face-dose'),
                  left: inset,
                  right: inset,
                  top: doseTop,
                  height: doseHeight,
                  child: _type(
                    widget.dose,
                    _doseStyle(HipColors.jadeText),
                    typeWidth,
                    types.dose,
                    1,
                    key: front
                        ? const ValueKey('home-deck-dose')
                        : ValueKey('back-dose-${widget.number}'),
                  ),
                ),
              if (widget.cue.isNotEmpty)
                Positioned(
                  key: const ValueKey('face-cue'),
                  left: inset,
                  right: inset,
                  top: cueTop,
                  height: cueHeight,
                  child: _type(
                    widget.cue,
                    _cueStyle(HipColors.muted),
                    typeWidth,
                    types.cue,
                    2,
                  ),
                ),
              Positioned(
                key: const ValueKey('face-information'),
                left: inset,
                right: inset,
                top: articleTop,
                bottom: 48,
                child: IgnorePointer(
                  ignoring: !widget.expanded,
                  child: ExcludeSemantics(
                    excluding: !widget.expanded,
                    child: Opacity(
                      opacity: detailsOpacity,
                      child: ClipRect(
                        child: OverflowBox(
                          alignment: Alignment.topLeft,
                          minWidth: typeWidth,
                          maxWidth: typeWidth,
                          child: Transform.scale(
                            alignment: Alignment.topLeft,
                            scale: typeScale,
                            child: SingleChildScrollView(
                              key: front
                                  ? const ValueKey(
                                      'home-deck-expanded-description',
                                    )
                                  : null,
                              controller: front
                                  ? widget.informationScroll
                                  : null,
                              primary: false,
                              physics: widget.expanded
                                  ? null
                                  : const NeverScrollableScrollPhysics(),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (body.isNotEmpty) ...[
                                    Text(
                                      '动作要领',
                                      style: TextStyle(
                                        fontSize: 10,
                                        height: 1.4,
                                        letterSpacing: 1.4,
                                        fontWeight: FontWeight.w600,
                                        color: HipColors.jadeText,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      body,
                                      style: TextStyle(
                                        fontSize: 14,
                                        height: 1.7,
                                        color: HipColors.text,
                                      ),
                                    ),
                                  ],
                                  if (drill.cautions.isNotEmpty) ...[
                                    const SizedBox(height: 14),
                                    Container(height: .5, color: ruleColor),
                                    const SizedBox(height: 10),
                                    Text(
                                      '留意 · ${drill.cautions.join('、')}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        height: 1.5,
                                        color: HipColors.muted,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                key: const ValueKey('face-signature'),
                left: inset,
                right: inset,
                bottom: 18,
                height: 17,
                child: IgnorePointer(
                  child: ExcludeSemantics(
                    child: Opacity(
                      opacity: t,
                      child: FittedBox(
                        alignment: Alignment.centerLeft,
                        fit: BoxFit.scaleDown,
                        child: SizedBox(
                          width: math.max(240, typeWidth),
                          height: 17,
                          child: Row(
                            children: [
                              Text(
                                'HIPLAB / MOTION NOTES',
                                style: TextStyle(
                                  fontSize: 8,
                                  letterSpacing: 1.1,
                                  color: HipColors.muted,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Container(height: .5, color: ruleColor),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                width: 4,
                                height: 4,
                                color: HipColors.jadeText,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                key: const ValueKey('face-border'),
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(radius),
                      border: Border.all(
                        color: MediaQuery.highContrastOf(context)
                            ? HipColors.text
                            : Colors.white.withValues(
                                alpha: HipColors.isDark ? .13 : .8,
                              ),
                        width: MediaQuery.highContrastOf(context) ? 1.5 : 1,
                      ),
                    ),
                  ),
                ),
              ),
              if (active)
                const Positioned.fill(
                  key: ValueKey('face-expanded-marker'),
                  child: IgnorePointer(
                    child: SizedBox(key: ValueKey('home-deck-expanded')),
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
}
