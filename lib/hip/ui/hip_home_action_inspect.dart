import 'dart:math' as math;
import 'dart:ui' show ImageFilter, lerpDouble;

import 'package:flutter/material.dart';

import '../data/hip_home_poster_bounds.dart';
import '../data/hip_public_media.dart';
import '../domain/hip_models.dart';
import 'hip_icons.dart';
import 'hip_content_text.dart';
import 'hip_theme.dart';
import 'hip_widgets.dart';

/// A shared printed face for the whole deck. The front alone owns a live video;
/// its media subtree stays mounted while the editorial layout opens around it.
class HipHomeActionFace extends StatefulWidget {
  const HipHomeActionFace({
    super.key,
    required this.drill,
    required this.number,
    required this.total,
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
  final int number, total;
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
    fontWeight: FontWeight.w700,
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
      final copy = HipContentText.of(context);
      final displayName = copy.drillName(drill);
      final classification = [
        drill.methods.map((method) => copy.text(method.zh)).join(' · '),
        drill.directions
            .map(
              (direction) => copy.isEn
                  ? switch (direction) {
                      HipDirection.flexion => 'Flex',
                      HipDirection.extension => 'Ext',
                      HipDirection.abduction => 'Abd',
                      HipDirection.adduction => 'Add',
                      HipDirection.internalRotation => 'IR',
                      HipDirection.externalRotation => 'ER',
                    }
                  : direction.zh,
            )
            .join(' / '),
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
      final inset = lerpDouble(compact ? 10 : 20, 26, t)!;
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
        displayName,
        widget.dose,
        widget.cue,
      );
      if (_types?.key != key) {
        _types = _TypeMetrics(
          key,
          _measure(
            displayName,
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
      final titleScale = math.min(typeScale, lerpDouble(23 / 30, 1, t)!);
      final doseIndent = 10 * (1 - t);
      final doseScale = math.min(
        (w - 2 * inset - doseIndent) / typeWidth,
        lerpDouble(12.5 / 16, 1, t)!,
      );
      final titleHeight = types.title * titleScale;
      final doseHeight = types.dose * doseScale;
      final cueHeight = types.cue * typeScale;
      final doseGap = widget.dose.isEmpty ? 0.0 : lerpDouble(7, 11, t)!;
      final cueGap = widget.cue.isEmpty ? 0.0 : 9 * t;
      final sourceScale = (source.width - 2 * (compact ? 10 : 20)) / typeWidth;
      final sourceFooter =
          types.title * math.min(sourceScale, 23 / 30) +
          types.dose * math.min(sourceScale, 12.5 / 16) +
          (widget.dose.isEmpty ? 0 : 7) +
          (compact ? 14 : 29);
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
      final artSide = math.min(media.width, media.height);
      final artBounds = Rect.fromCenter(
        center: media.center,
        width: artSide,
        height: artSide,
      );
      final poster = front && t < 1
          ? HipPublicMedia.current?.posterAssetFor(drill.id)
          : null;
      final silhouette = homeContactShadowBounds[poster];
      final titleTop = media.bottom + lerpDouble(11, 18, t)!;
      final doseTop = titleTop + titleHeight + doseGap;
      final cueTop = doseTop + doseHeight + cueGap;
      final articleTop = cueTop + cueHeight * t + lerpDouble(8, 20, t)!;
      final radius = lerpDouble(26, 28, t)!;
      final description =
          (widget.description.trim().isNotEmpty
                  ? widget.description
                  : copy.isEn
                  ? ''
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
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: HipColors.isDark
                ? [HipColors.surfaceHigh, HipColors.surface]
                : front
                ? const [Colors.white, Color(0xfffafbfa)]
                : List.filled(
                    2,
                    Color.lerp(
                      const Color(0xfffbfcfb),
                      const Color(0xfff6f7f6),
                      (2 * depth - 1).clamp(0, 1),
                    )!,
                  ),
          ),
          borderRadius: BorderRadius.circular(radius),
          boxShadow: HipColors.shadows([
            const BoxShadow(
              color: Color(0x2114281f),
              blurRadius: 44,
              offset: Offset(0, 14),
            ),
            const BoxShadow(
              color: Color(0x0d14281f),
              blurRadius: 3,
              offset: Offset(0, 1),
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
                child: LayoutBuilder(
                  builder: (context, header) => FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.topLeft,
                    child: SizedBox(
                      width: header.maxWidth,
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
                                lerpDouble(compact ? 8 : 9.5, 11, t)! / 11,
                              ),
                              SizedBox(width: 12 * t),
                              Expanded(
                                child: Opacity(
                                  opacity: t,
                                  child: Text(
                                    copy.isEn ? 'MOVEMENT STUDY' : '动作研习',
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
                                classification.isEmpty
                                    ? (copy.isEn ? 'Movement practice' : '动作练习')
                                    : classification,
                                TextStyle(fontSize: 11, color: HipColors.muted),
                                1,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                key: const ValueKey('face-number'),
                left: lerpDouble(w - inset - 48, w - 132, t),
                top: lerpDouble(compact ? 8 : 24, 21, t),
                width: lerpDouble(48, 66, t),
                height: lerpDouble(28, 56, t),
                child: Stack(
                  children: [
                    Positioned(
                      left: 0,
                      right: 20 * (1 - t),
                      top: 0,
                      child: Align(
                        alignment: Alignment.topRight,
                        child: _printedLabel(
                          context,
                          'number',
                          widget.number.toString().padLeft(2, '0'),
                          TextStyle(
                            fontSize: 46,
                            height: 1,
                            fontWeight: FontWeight.w400,
                            letterSpacing: -.8,
                            color: Color.lerp(
                              HipColors.text,
                              HipColors.jadeText.withValues(alpha: .65),
                              t,
                            ),
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                          lerpDouble(compact ? 10 : 15, 46, t)! / 46,
                          key: front
                              ? const ValueKey('home-deck-position')
                              : ValueKey('back-position-${widget.number}'),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      width: 20,
                      top: 2,
                      child: Opacity(
                        opacity: 1 - t,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Text(
                            '/ ${widget.total.toString().padLeft(2, '0')}',
                            style: TextStyle(
                              fontSize: 10,
                              color: HipColors.faint,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
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
                            tooltip: copy.isEn ? 'Close move card' : '收起动作卡片',
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
              if (front && !HipColors.isDark)
                Positioned.fromRect(
                  rect: media,
                  child: IgnorePointer(
                    child: Opacity(
                      opacity: 1 - t,
                      child: Center(
                        child: ImageFiltered(
                          imageFilter: ImageFilter.blur(sigmaX: 34, sigmaY: 34),
                          child: Container(
                            width: media.width * .68,
                            height: media.height * .66,
                            decoration: BoxDecoration(
                              color: const Color(0xffe8eeeb),
                              borderRadius: BorderRadius.all(
                                Radius.elliptical(media.width, media.height),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              if (silhouette != null)
                Positioned.fromRect(
                  key: const ValueKey('face-contact-shadow'),
                  rect: Rect.fromCenter(
                    center: Offset(
                      artBounds.left + silhouette.center.dx * artSide,
                      artBounds.top + silhouette.bottom * artSide,
                    ),
                    width: silhouette.width * artSide * .6,
                    height: 10,
                  ),
                  child: IgnorePointer(
                    child: Opacity(
                      opacity: 1 - t,
                      child: ImageFiltered(
                        imageFilter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: const Color(
                              0xff14281f,
                            ).withValues(alpha: .22),
                            borderRadius: BorderRadius.all(
                              Radius.elliptical(
                                silhouette.width * artSide * .3,
                                5,
                              ),
                            ),
                          ),
                        ),
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
                      ? (widget.paused
                            ? (copy.isEn ? 'Play move demonstration' : '播放动作示范')
                            : (copy.isEn
                                  ? 'Pause move demonstration'
                                  : '暂停动作示范'))
                      : displayName,
                  value: widget.paused || !widget.expanded
                      ? (copy.isEn ? 'Paused' : '已暂停')
                      : (copy.isEn ? 'Looping automatically' : '自动循环播放'),
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
                        dimension: artSide,
                        child: HipDrillArt(
                          key: widget.mediaKey,
                          drill: drill,
                          play: widget.expanded && !widget.paused,
                          holdVideo: front || widget.warmVideo,
                          revealPausedFrame: widget.revealPausedFrame,
                          onFrameReadyChanged: widget.onFrameReadyChanged,
                          showPendingLabel: false,
                          stage: Colors.transparent,
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
                right: lerpDouble(inset, w - inset - 26, t),
                height: lerpDouble(.5, 2, t),
                child: IgnorePointer(
                  child: ColoredBox(
                    color: Color.lerp(
                      HipColors.cardDivider,
                      HipColors.jadeText,
                      t,
                    )!,
                  ),
                ),
              ),
              Positioned(
                key: const ValueKey('face-title'),
                left: inset,
                width: titleScale * typeWidth,
                top: titleTop,
                height: titleHeight,
                child: _type(
                  displayName,
                  _titleStyle(HipColors.text),
                  typeWidth,
                  types.title,
                  2,
                  key: front
                      ? const ValueKey('home-deck-caption')
                      : ValueKey('back-caption-${widget.number}'),
                ),
              ),
              if (widget.dose.isNotEmpty) ...[
                Positioned(
                  left: inset,
                  top: doseTop + (doseHeight - 5) / 2,
                  child: Opacity(
                    opacity: 1 - t,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: HipColors.jade,
                        shape: BoxShape.circle,
                      ),
                      child: const SizedBox.square(dimension: 5),
                    ),
                  ),
                ),
                Positioned(
                  key: const ValueKey('face-dose'),
                  left: inset + doseIndent,
                  width: doseScale * typeWidth,
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
              ],
              if (widget.cue.isNotEmpty)
                Positioned(
                  key: const ValueKey('face-cue'),
                  left: inset,
                  right: inset,
                  top: cueTop,
                  height: cueHeight,
                  child: Opacity(
                    opacity: t,
                    child: _type(
                      widget.cue,
                      _cueStyle(HipColors.muted),
                      typeWidth,
                      types.cue,
                      2,
                    ),
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
                                      copy.isEn ? 'TECHNIQUE NOTES' : '动作要领',
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
                                      '${copy.isEn ? 'Mind' : '留意'} · ${drill.cautions.map(copy.text).join(copy.isEn ? ', ' : '、')}',
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
