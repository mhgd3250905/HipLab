// UI r2 (2026-11-03): the shared page kit — one navigation bar, one grouped
// list language for every HipLab page that is not 首页 or SDK UI.
//
//   HipNavBar     52 high, 40pt glass round back/close (48 hit), centred
//                 17 w600 title.
//   HipNavPage    backdrop + safe area + HipNavBar + a scrolling body; the bar
//                 gains a hairline and a faint fill once the body scrolls.
//   HipSection    12 w600 muted group title, 24 above / 8 below.
//   HipListGroup  flat panel, radius 16, 0.5pt rim, no shadow, inset hairlines.
//   HipListRow    32×32 tinted icon, 16 w500 title, 13 muted subtitle,
//                 14 faint meta + chevron, or a trailing control.
import 'package:flutter/material.dart';

import 'hip_glass.dart';
import 'hip_icons.dart';
import 'hip_theme.dart';
import 'hip_widgets.dart';

/// Horizontal content edge of every kit page.
const double kHipPageEdge = 20;

/// Inner left padding of a row inside a [HipListGroup].
const double kHipRowPad = 16;

/// Where a row's text starts when it has an icon (16 + 32 + 12).
const double kHipRowTextInset = kHipRowPad + 32 + 12;

enum HipNavLeading { back, close, none }

class HipNavBar extends StatelessWidget {
  const HipNavBar({
    super.key,
    this.title,
    this.subtitle,
    this.leading = HipNavLeading.back,
    this.onLeading,
    this.leadingKey,
    this.trailing,
    this.scrolled = false,
  });

  final String? title;

  /// Small grey line under the title (12 muted), e.g. 「加到 训练组 1」.
  final String? subtitle;
  final HipNavLeading leading;

  /// Defaults to popping the route.
  final VoidCallback? onLeading;
  final Key? leadingKey;

  /// One text or icon action on the right (keep it ≤ 44 wide-ish).
  final Widget? trailing;

  /// After the body scrolls: hairline under the bar and a faint fill.
  final bool scrolled;

  static const double height = 52;

  @override
  Widget build(BuildContext context) {
    final fill = HipColors.isDark
        ? Colors.white.withValues(alpha: .04)
        : Colors.white.withValues(alpha: .55);
    final close = leading == HipNavLeading.close;
    final label = close ? '关闭' : '返回';
    return AnimatedContainer(
      duration: HipMotion.fast,
      height: height,
      decoration: BoxDecoration(
        color: scrolled ? fill : Colors.transparent,
        border: Border(
          bottom: BorderSide(
            width: .5,
            color: scrolled
                ? HipColors.text.withValues(alpha: .12)
                : Colors.transparent,
          ),
        ),
      ),
      child: Stack(
        children: [
          if (title != null)
            Positioned.fill(
              left: 64,
              right: 64,
              // Like a system bar, the title caps its text growth so title
              // + subtitle always fit the 52pt bar.
              child: MediaQuery.withClampedTextScaling(
                maxScaleFactor: 1.3,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 17,
                          height: 1.2,
                          fontWeight: FontWeight.w600,
                          color: HipColors.text,
                        ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.25,
                            color: HipColors.muted,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          if (leading != HipNavLeading.none)
            Positioned(
              // 40pt glass round button (same family as 首页 换一套) in a 48
              // hit area, its outer edge on the 20pt content margin (G2).
              left: kHipPageEdge - 4,
              top: (height - 48) / 2,
              child: Tooltip(
                message: label,
                child: HipNavButton(
                  key: leadingKey,
                  glyph: close ? HipGlyph.close : HipGlyph.back,
                  semanticLabel: label,
                  onTap: onLeading ?? () => Navigator.of(context).maybePop(),
                ),
              ),
            ),
          if (trailing != null)
            Positioned(
              right: kHipPageEdge - 4,
              top: 0,
              bottom: 0,
              child: Center(child: trailing),
            ),
        ],
      ),
    );
  }
}

/// A pushed page: backdrop, [HipNavBar], scrolling [body]. The bar shows its
/// hairline once the body (any vertical scrollable at depth 0) is scrolled.
class HipNavPage extends StatefulWidget {
  const HipNavPage({
    super.key,
    required this.body,
    this.title,
    this.subtitle,
    this.leading = HipNavLeading.back,
    this.leadingKey,
    this.trailing,
    this.backdrop,
  });
  final Widget body;
  final String? title;
  final String? subtitle;
  final HipNavLeading leading;
  final Key? leadingKey;
  final Widget? trailing;

  /// Defaults to the plain depth gradient.
  final Widget? backdrop;

  @override
  State<HipNavPage> createState() => _HipNavPageState();
}

class _HipNavPageState extends State<HipNavPage> {
  bool _scrolled = false;

  bool _onScroll(ScrollNotification n) {
    if (n.depth != 0 || n.metrics.axis != Axis.vertical) return false;
    final s = n.metrics.pixels > 0.5;
    if (s != _scrolled) setState(() => _scrolled = s);
    return false;
  }

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      widget.backdrop ?? const HipGlassBackdrop(),
      Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              HipNavBar(
                title: widget.title,
                subtitle: widget.subtitle,
                leading: widget.leading,
                leadingKey: widget.leadingKey,
                trailing: widget.trailing,
                scrolled: _scrolled,
              ),
              Expanded(
                child: NotificationListener<ScrollNotification>(
                  onNotification: _onScroll,
                  child: SafeArea(top: false, child: widget.body),
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

/// Group title above a [HipListGroup].
class HipSection extends StatelessWidget {
  const HipSection(this.title, {super.key, this.first = false, this.trailing});
  final String title;

  /// First section on a page: smaller top gap (the bar already spaces it).
  final bool first;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(4, first ? 8 : 24, 4, 8),
    child: Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12,
              height: 1.2,
              letterSpacing: .3,
              fontWeight: FontWeight.w600,
              color: HipColors.muted,
            ),
          ),
        ),
        ?trailing,
      ],
    ),
  );
}

/// Flat panel of rows: surface tint by opacity, radius 16 (panel tier), a
/// 0.5pt rim (G4), no shadow; 0.5pt dividers start where the row text starts.
class HipListGroup extends StatelessWidget {
  const HipListGroup({
    super.key,
    required this.children,
    this.inset = kHipRowTextInset,
  });
  final List<Widget> children;

  /// Left start of the dividers (row text start).
  final double inset;

  static Color fill() => HipColors.isDark
      ? Colors.white.withValues(alpha: .06)
      : Colors.white.withValues(alpha: .7);

  @override
  Widget build(BuildContext context) => CustomPaint(
    foregroundPainter: const HipRimPainter(radius: HipRadius.panel),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(HipRadius.panel),
      child: ColoredBox(
        color: fill(),
        child: Material(
        type: MaterialType.transparency,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (i, c) in children.indexed) ...[
              if (i > 0)
                Padding(
                  padding: EdgeInsets.only(left: inset),
                  child: Divider(
                    height: .5,
                    thickness: .5,
                    color: HipColors.text.withValues(alpha: .1),
                  ),
                ),
              c,
            ],
          ],
        ),
        ),
      ),
    ),
  );
}

/// 0.5pt [HipColors.rim] hairline around a rounded rect.
class HipRimPainter extends CustomPainter {
  const HipRimPainter({required this.radius, this.color});
  final double radius;
  final Color? color;
  @override
  void paint(Canvas canvas, Size size) {
    final r = radius.clamp(0, size.shortestSide / 2).toDouble();
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        (Offset.zero & size).deflate(.25),
        Radius.circular((r - .25).clamp(0, r).toDouble()),
      ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = .5
        ..color = color ?? HipColors.rim,
    );
  }

  @override
  bool shouldRepaint(HipRimPainter old) =>
      old.radius != radius || old.color != color;
}

/// Nav-bar action (‹, ×, 🗑…): a 40pt [HipGlassRoundButton] centred in a 48pt
/// hit area (audit r3 G2).
class HipNavButton extends StatelessWidget {
  const HipNavButton({
    super.key,
    required this.glyph,
    required this.semanticLabel,
    required this.onTap,
    this.color,
  });
  final HipGlyph glyph;
  final String semanticLabel;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: 48,
    child: Center(
      child: HipGlassRoundButton(
        semanticLabel: semanticLabel,
        onTap: onTap,
        child: HipIcon(glyph, size: 20, color: color ?? HipColors.text),
      ),
    ),
  );
}

/// The 32×32 tinted icon container of a row.
class HipRowIcon extends StatelessWidget {
  const HipRowIcon(this.glyph, {super.key});
  final HipGlyph glyph;
  @override
  Widget build(BuildContext context) => Container(
    width: 32,
    height: 32,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(8),
      color: HipColors.jade.withValues(alpha: .14),
    ),
    child: HipIcon(glyph, size: 18, color: HipColors.jadeText),
  );
}

class HipListRow extends StatelessWidget {
  const HipListRow({
    super.key,
    required this.title,
    this.glyph,
    this.subtitle,
    this.meta,
    this.trailing,
    this.onTap,
    this.chevron,
    this.semanticLabel,
  });
  final String title;
  final HipGlyph? glyph;
  final String? subtitle;

  /// Right grey text (14 faint), before the chevron.
  final String? meta;

  /// A control on the right (switch, segmented, button) instead of a chevron.
  final Widget? trailing;
  final VoidCallback? onTap;

  /// Defaults to: tappable and no [trailing].
  final bool? chevron;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final showChevron = chevron ?? (onTap != null && trailing == null);
    final row = ConstrainedBox(
      constraints: BoxConstraints(minHeight: subtitle == null ? 56 : 64),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(kHipRowPad, 10, 12, 10),
        child: Row(
          children: [
            if (glyph != null) ...[
              HipRowIcon(glyph!),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.25,
                      fontWeight: FontWeight.w500,
                      color: HipColors.text,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.3,
                        color: HipColors.muted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (meta != null && meta!.isNotEmpty)
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 140),
                child: Padding(
                  padding: const EdgeInsets.only(left: 8, right: 4),
                  child: Text(
                    meta!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: TextStyle(fontSize: 14, color: HipColors.meta),
                  ),
                ),
              ),
            if (trailing != null) ...[const SizedBox(width: 8), trailing!],
            if (showChevron)
              HipIcon(HipGlyph.chevronRight, size: 16, color: HipColors.faint),
          ],
        ),
      ),
    );
    if (onTap == null) return row;
    return HipPressable(
      semanticLabel: semanticLabel ?? title,
      scale: .99,
      onTap: onTap,
      child: row,
    );
  }
}

/// A secondary line inside a group, under its parent row (e.g. the reminder
/// interval): starts at the row text inset, control on the right.
class HipListSubRow extends StatelessWidget {
  const HipListSubRow({
    super.key,
    required this.label,
    required this.child,
    this.inset = kHipRowTextInset,
  });
  final String label;
  final Widget child;
  final double inset;
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(inset, 0, 12, 12),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 14, color: HipColors.muted),
          ),
        ),
        child,
      ],
    ),
  );
}

/// Step progress for 首启安全 / 安全提示 / 自测题 (audit r3 G7): a 3pt
/// segmented bar under the nav with "n/N" on the right.
class HipStepProgress extends StatelessWidget {
  const HipStepProgress({super.key, required this.index, required this.count});

  /// 0-based current step.
  final int index;
  final int count;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Row(
          children: [
            for (var i = 0; i < count; i++)
              Expanded(
                child: AnimatedContainer(
                  duration: HipMotion.medium,
                  height: 3,
                  margin: EdgeInsets.only(right: i < count - 1 ? 4 : 0),
                  decoration: BoxDecoration(
                    color: i <= index ? HipColors.jade : HipColors.surfaceHigh,
                    borderRadius: BorderRadius.circular(1.5),
                  ),
                ),
              ),
          ],
        ),
      ),
      const SizedBox(width: 12),
      Text(
        '${index + 1}/$count',
        key: const ValueKey('step-progress-count'),
        style: TextStyle(
          fontSize: 13,
          color: HipColors.meta,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    ],
  );
}
