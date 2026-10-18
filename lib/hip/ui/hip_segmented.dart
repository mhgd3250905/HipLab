import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'hip_theme.dart';
import 'hip_widgets.dart' show HipPressable, HipTactile, HipTactileStyle;

/// Builds one segment's content. [fg] is the colour to paint text / glyphs
/// in (already blended between the idle and selected colours), [t] how
/// selected the segment is right now (0 idle … 1 under the thumb), following
/// the thumb as it slides.
typedef HipSegmentBuilder<T> = Widget Function(T value, Color fg, double t);

/// Segmented control with one inset track and a sliding thumb (round 2 #1).
///
/// * The thumb is concentric with the track: its radius is the track radius
///   minus the inset, so the corners run parallel.
/// * The selection is a raised tactile tile ([HipTactileStyle.neutral]):
///   on dark a lighter step above the surface (lit top, 1px top light,
///   hairline edge, tight shadow); on light a white chip over a recessed
///   grey track in both placements. No accent outline.
/// * The thumb slides with a small spring; every segment's colour follows
///   the thumb's position, so text and glyphs cross-fade in step with it.
/// * Tap a segment or drag along the track.
///
/// [standalone] controls sit directly on the page and are their own card
/// (card stroke / shadow); on light, both placements use the recessed
/// [HipColors.track] so the white thumb remains distinct.
class HipSegmented<T> extends StatefulWidget {
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

  @override
  State<HipSegmented<T>> createState() => _HipSegmentedState<T>();
}

class _HipSegmentedState<T> extends State<HipSegmented<T>> {
  int? _pressedIndex;
  bool _dragging = false;
  bool _pointerInside = true;

  void _press(int i, bool down) {
    if (down) {
      if (_pressedIndex != i) setState(() => _pressedIndex = i);
    } else if (_pressedIndex == i) {
      setState(() => _pressedIndex = null);
    }
  }

  void _release() {
    if (_pressedIndex != null || _dragging) {
      setState(() {
        _pressedIndex = null;
        _dragging = false;
      });
    }
  }

  void _inside(Offset local, Size size) {
    final inside = (Offset.zero & size).contains(local);
    if (inside != _pointerInside) setState(() => _pointerInside = inside);
  }

  Color get _selectedFg =>
      widget.standalone ? HipColors.jadeText : HipColors.text;

  BoxDecoration get _trackDecoration => BoxDecoration(
    color: widget.standalone && HipColors.isDark
        ? HipColors.surface
        : HipColors.track,
    borderRadius: BorderRadius.circular(widget.radius),
    border: widget.standalone && HipColors.isDark
        ? Border.all(color: HipColors.line)
        : null,
    boxShadow: widget.standalone ? HipColors.cardShadow : null,
  );

  /// The selection thumb is the reference tactile tile the app's buttons
  /// were distilled from (button audit 2026-10-18): lit from above, a 1px
  /// top light, a hairline edge and a tight contact shadow.
  Widget _thumb(bool pressed) => HipTactile(
    style: HipTactileStyle.neutral(),
    radius: widget.thumbRadius,
    pressed: pressed,
  );

  void _select(int i) {
    if (i < 0 ||
        i >= widget.values.length ||
        widget.values[i] == widget.selected) {
      return;
    }
    HapticFeedback.selectionClick();
    widget.onChanged(widget.values[i]);
  }

  @override
  Widget build(BuildContext context) {
    final index = widget.values
        .indexOf(widget.selected)
        .clamp(0, widget.values.length - 1);
    final pressed = _pointerInside && (_dragging || _pressedIndex == index);
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final idle = HipColors.muted;
    final on = _selectedFg;
    return Container(
      height: widget.height,
      decoration: _trackDecoration,
      padding: EdgeInsets.all(widget.inset),
      child: LayoutBuilder(
        builder: (context, c) {
          final segW = c.maxWidth / widget.values.length;
          final trackSize = Size(c.maxWidth, c.maxHeight);
          int at(double dx) =>
              (dx / segW).floor().clamp(0, widget.values.length - 1);
          return Listener(
            onPointerDown: (event) => _inside(event.localPosition, trackSize),
            onPointerMove: (event) => _inside(event.localPosition, trackSize),
            onPointerUp: (_) => _release(),
            onPointerCancel: (_) => _release(),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragStart: (d) {
                setState(() => _dragging = true);
                _select(at(d.localPosition.dx));
              },
              onHorizontalDragUpdate: (d) => _select(at(d.localPosition.dx)),
              onHorizontalDragEnd: (_) => _release(),
              onHorizontalDragCancel: _release,
              child: TweenAnimationBuilder<double>(
                tween: Tween(end: pressed ? 1.0 : 0.0),
                duration: pressed ? HipMotion.press : HipMotion.release,
                curve: pressed ? Curves.easeOut : Curves.easeOutCubic,
                builder: (context, press, _) => TweenAnimationBuilder<double>(
                  tween: Tween(end: index.toDouble()),
                  duration: HipMotion.segment,
                  curve: HipMotion.spring,
                  builder: (context, pos, _) => Stack(
                    children: [
                      Positioned(
                        key: ValueKey('${widget.keyPrefix}-thumb'),
                        left: pos * segW,
                        top: 0,
                        bottom: 0,
                        width: segW,
                        child: Transform.scale(
                          key: ValueKey('${widget.keyPrefix}-thumb-scale'),
                          scale: reduceMotion
                              ? 1
                              : 1 - (1 - HipMotion.pressScale) * press,
                          child: _thumb(pressed),
                        ),
                      ),
                      Row(
                        children: [
                          for (final (i, v) in widget.values.indexed)
                            Expanded(
                              child: _segment(
                                i,
                                v,
                                (1 - (pos - i).abs()).clamp(0.0, 1.0),
                                idle,
                                on,
                                reduceMotion ? 0 : press,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _segment(int i, T v, double t, Color idle, Color on, double press) {
    final fg = Color.lerp(idle, on, t)!;
    final isOn = v == widget.selected;
    return HipPressable(
      selected: isOn,
      inMutuallyExclusiveGroup: true,
      key: ValueKey('${widget.keyPrefix}-$v'),
      scale: 1,
      onPressChanged: (down) => _press(i, down),
      onTap: () => _select(i),
      child: Transform.scale(
        key: ValueKey('${widget.keyPrefix}-label-scale-$v'),
        scale: 1 - (1 - HipMotion.pressScale) * press * t,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: widget.itemBuilder != null
                  ? widget.itemBuilder!(v, fg, t)
                  : Text(
                      widget.label!(v),
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
      ),
    );
  }
}
