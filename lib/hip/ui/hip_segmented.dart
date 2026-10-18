import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'hip_theme.dart';
import 'hip_widgets.dart' show HipPressable;

/// Builds one segment's content. [fg] is the colour to paint text / glyphs
/// in (already blended between the idle and selected colours), [t] how
/// selected the segment is right now (0 idle … 1 under the thumb), following
/// the thumb as it slides.
typedef HipSegmentBuilder<T> = Widget Function(T value, Color fg, double t);

/// Segmented control with one inset track and a sliding thumb (round 2 #1).
///
/// * The thumb is concentric with the track: its radius is the track radius
///   minus the inset, so the corners run parallel.
/// * No outline on the selection: on dark the thumb is a raised step above
///   the surface (lighter fill, 1px top light, soft shadow); on light it is a
///   soft jade wash ([standalone]) or a white raised chip (inside a card).
/// * The thumb slides with a small spring; every segment's colour follows
///   the thumb's position, so text and glyphs cross-fade in step with it.
/// * Tap a segment or drag along the track.
///
/// [standalone] controls sit directly on the page and are their own card
/// (surface fill + the card stroke / shadow); nested ones sit inside a card
/// and use the recessed [HipColors.track].
class HipSegmented<T> extends StatelessWidget {
  const HipSegmented({
    super.key,
    required this.values,
    required this.selected,
    required this.onChanged,
    this.label,
    this.itemBuilder,
    this.keyPrefix = 'seg',
    this.height = 44,
    this.radius = 14,
    this.inset = 4,
    this.standalone = false,
  }) : assert(label != null || itemBuilder != null);

  final List<T> values;
  final T selected;
  final ValueChanged<T> onChanged;

  /// Plain text segments.
  final String Function(T)? label;

  /// Custom segments (number + unit, glyph + label …).
  final HipSegmentBuilder<T>? itemBuilder;
  final String keyPrefix;
  final double height;
  final double radius;
  final double inset;
  final bool standalone;

  /// Thumb corner radius: concentric with the track.
  double get thumbRadius => (radius - inset).clamp(0, radius).toDouble();

  bool get _washThumb => standalone && !HipColors.isDark;

  Color get _selectedFg => _washThumb
      ? HipColors.jadeDeep
      : (standalone ? HipColors.jade : HipColors.text);

  BoxDecoration get _trackDecoration => BoxDecoration(
    color: standalone ? HipColors.surface : HipColors.track,
    borderRadius: BorderRadius.circular(radius),
    border: standalone && HipColors.isDark
        ? Border.all(color: HipColors.line)
        : null,
    boxShadow: standalone ? HipColors.cardShadow : null,
  );

  BoxDecoration get _thumbDecoration => _washThumb
      ? BoxDecoration(
          color: HipColors.jade.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(thumbRadius),
        )
      : BoxDecoration(
          color: HipColors.thumb,
          borderRadius: BorderRadius.circular(thumbRadius),
          boxShadow: HipColors.thumbShadow,
          // A light catching the top edge (transparent in the light theme):
          // reads as a raised surface, not as an outline.
          gradient: HipColors.isDark
              ? LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color.alphaBlend(HipColors.thumbHighlight, HipColors.thumb),
                    HipColors.thumb,
                  ],
                  stops: const [0, .5],
                )
              : null,
        );

  void _select(int i) {
    if (i < 0 || i >= values.length || values[i] == selected) return;
    HapticFeedback.selectionClick();
    onChanged(values[i]);
  }

  @override
  Widget build(BuildContext context) {
    final index = values.indexOf(selected).clamp(0, values.length - 1);
    final idle = HipColors.muted;
    final on = _selectedFg;
    return Container(
      height: height,
      decoration: _trackDecoration,
      padding: EdgeInsets.all(inset),
      child: LayoutBuilder(
        builder: (context, c) {
          final segW = c.maxWidth / values.length;
          int at(double dx) => (dx / segW).floor().clamp(0, values.length - 1);
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragStart: (d) => _select(at(d.localPosition.dx)),
            onHorizontalDragUpdate: (d) => _select(at(d.localPosition.dx)),
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: index.toDouble()),
              duration: HipMotion.segment,
              curve: HipMotion.spring,
              builder: (context, pos, _) => Stack(
                children: [
                  Positioned(
                    key: ValueKey('$keyPrefix-thumb'),
                    left: pos * segW,
                    top: 0,
                    bottom: 0,
                    width: segW,
                    child: DecoratedBox(decoration: _thumbDecoration),
                  ),
                  Row(
                    children: [
                      for (final (i, v) in values.indexed)
                        Expanded(
                          child: _segment(
                            i,
                            v,
                            (1 - (pos - i).abs()).clamp(0.0, 1.0),
                            idle,
                            on,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _segment(int i, T v, double t, Color idle, Color on) {
    final fg = Color.lerp(idle, on, t)!;
    final isOn = v == selected;
    return HipPressable(
      selected: isOn,
      inMutuallyExclusiveGroup: true,
      key: ValueKey('$keyPrefix-$v'),
      scale: 1,
      onTap: () => _select(i),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: itemBuilder != null
                ? itemBuilder!(v, fg, t)
                : Text(
                    label!(v),
                    maxLines: 1,
                    softWrap: false,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isOn ? FontWeight.w700 : FontWeight.w500,
                      color: Color.lerp(idle, HipColors.text, t),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
