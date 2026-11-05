// UI r2 (2026-11-03): the shared page kit — one navigation bar, one grouped
// list language for every HipLab page that is not 首页 or SDK UI.
// UI r4 (开哥 2026-11-05, reference iOS Settings 搜索页): the bar is an iOS
// floating frost, not a Material app bar — see HipNavBar.
//
//   HipNavBar     44 high: 44pt iOS-style back chip on the left edge,
//                 centred 17 w600 title. Always a translucent blur; [fade]
//                 extra points of blur + gradient below the row so the body
//                 reads as sliding under the glass. No hairline.
//   HipNavPage    backdrop + safe area + body + the bar overlaid on top; the
//                 body's viewport starts at the row, so its top [kHipNavFade]
//                 points sit behind the glass.
//   HipSection    12 w600 muted group title, 24 above / 8 below.
//   HipListGroup  flat panel, radius 12, no border, no shadow, inset hairlines.
//   HipListRow    32×32 tinted icon, 16 w500 title, 13 muted subtitle,
//                 14 faint meta + chevron, or a trailing control.
import 'dart:ui' as ui;

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

/// How far the bar's material reaches below its row before it is fully gone.
/// [HipNavPage] lets the body's viewport start at the row, so this much of the
/// content passes behind the frost and thins out there instead of hitting a
/// hard edge.
const double kHipNavFade = 24;

/// Top inset a page's scrollable must add when [HipNavPage.bodyScrollsUnderBar]
/// is on: the body then starts at the top of the screen (iOS behaviour), so the
/// content itself has to clear the bar row — the equivalent of a table view's
/// top content inset.
const double kHipNavInset = HipNavBar.height;

/// What a page's scrollable really has to clear when the body scrolls under
/// the bar: the status bar (content now passes beneath it too) plus the row.
double hipNavInset(BuildContext context) =>
    MediaQuery.paddingOf(context).top + HipNavBar.height;

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
    this.fade = 0,
    this.topInset = 0,
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

  /// Extra points of material below the row (0 for a bar that is not overlaid
  /// on scrolling content).
  final double fade;

  /// Height of the status bar. The material runs up through it, so scrolled
  /// content disappears under the system icons the way it does in iOS.
  final double topInset;

  static const double height = 44;

  /// A title + subtitle bar is the system's two-line case: the row grows
  /// instead of clipping the caption (1.3× text needs ~46pt for both lines).
  static const double heightWithSubtitle = 52;

  /// The back / close chip.
  static const double chip = 44;

  /// Its left edge: iOS parks the back control at the content margin.
  static const double chipEdge = 16;

  double get row => subtitle == null ? height : heightWithSubtitle;

  @override
  Widget build(BuildContext context) {
    final close = leading == HipNavLeading.close;
    final label = close ? '关闭' : '返回';
    final band = topInset + row + fade;
    return SizedBox(
      height: band,
      child: Stack(
        children: [
          Positioned.fill(child: _HipBarGlass(band: band)),
          if (title != null)
            Positioned(
              top: topInset,
              left: 60,
              right: 60,
              height: row,
              // Like a system bar, the title caps its text growth so title
              // + subtitle always fit the row.
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
              // A 44pt hit target centred on the chip, so the whole left edge
              // is live the way the system back control is.
              left: chipEdge,
              top: topInset + (row - 44) / 2,
              child: SizedBox.square(
                dimension: 44,
                child: Tooltip(
                  message: label,
                  child: HipPressable(
                    key: leadingKey,
                    semanticLabel: label,
                    scale: .9,
                    onTap: onLeading ?? () => Navigator.of(context).maybePop(),
                    child: Center(
                      child: _HipChipSurface(
                        child: SizedBox.square(
                          dimension: chip,
                          child: Center(
                            child: HipIcon(
                              close ? HipGlyph.close : HipGlyph.back,
                              size: 32,
                              strokeWidth: 2,
                              color: HipColors.text,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          if (trailing != null)
            Positioned(
              right: chipEdge,
              top: topInset,
              height: row,
              child: Center(child: trailing),
            ),
        ],
      ),
    );
  }
}

/// The bar's glass — a frosted strip painted as a colour gradient.
///
/// 开哥 2026-11-05: opaque at the top of the screen, then a shallow ease down
/// to a slightly translucent strip by 60% of the band, and a parabola from
/// there to fully clear at the bottom (just below the back button). The strip
/// is opaque *paint*, not a masked copy of the page backdrop — a ShaderMask
/// over a RepaintBoundary was letting the body's text bleed through on
/// Impeller. Three masked blurs under it keep what passes through frosted.
class _HipBarGlass extends StatelessWidget {
  const _HipBarGlass({required this.band});

  /// Total painted height: status bar + control row + the transition strip.
  final double band;

  /// Points sampled along the gradient; enough for a smooth curve.
  static const int _samples = 12;

  /// The curve holds near-full strength until here, then accelerates away
  /// (开哥 2026-11-05: "在 60% 左右的区域开始加速").
  static const double _knee = .6;

  /// Alpha at the knee: the strip above it is never fully opaque — it stays
  /// slightly translucent so the frosted content glows through (开哥
  /// 2026-11-05: "0~60 过渡慢一点，有些许透明，透光模糊").
  static const double _kneeAlpha = .86;

  /// Opaque at the top, easing down to [_kneeAlpha] by [_knee], then a
  /// parabola that accelerates to zero by [reach].
  static double _fade(double t, double reach) {
    if (reach <= 0) return 0;
    final knee = _knee < reach ? _knee : reach;
    if (t <= knee) {
      final u = knee == 0 ? 1.0 : t / knee;
      return 1 - (1 - _kneeAlpha) * u * u;
    }
    final u = ((t - knee) / (reach - knee)).clamp(0.0, 1.0);
    return _kneeAlpha * (1 - u * u);
  }

  @override
  Widget build(BuildContext context) {
    final high = MediaQuery.maybeHighContrastOf(context) ?? false;
    final bg = HipColors.background;
    return RepaintBoundary(
      child: IgnorePointer(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Frost that follows the same curve: the heaviest layer fades out
            // highest, the lightest reaches the bottom, so the blur thins with
            // the strip instead of ending on a line.
            if (!high) ...[
              _frost(34, reach: .78),
              _frost(20, reach: .9),
              _frost(9, reach: 1),
            ],
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    for (var i = 0; i <= _samples; i++)
                      bg.withValues(alpha: _fade(i / _samples, 1)),
                  ],
                  stops: [for (var i = 0; i <= _samples; i++) i / _samples],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _frost(double sigma, {required double reach}) => ShaderMask(
    blendMode: BlendMode.dstIn,
    shaderCallback: (r) => LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        for (var i = 0; i <= _samples; i++)
          Colors.white.withValues(
            alpha: _fade(i / _samples, reach).clamp(0.0, 1.0),
          ),
      ],
      stops: [for (var i = 0; i <= _samples; i++) i / _samples],
    ).createShader(r),
    child: BackdropFilter(
      filter: ui.ImageFilter.blur(
        sigmaX: sigma,
        sigmaY: sigma,
        tileMode: TileMode.mirror,
      ),
      child: const ColoredBox(color: Color(0x00000000)),
    ),
  );
}

/// The back / close chip: flat frosted glass — a uniform translucent tint
/// over a backdrop blur and one hairline rim. No gradient, no shadow.
class _HipChipSurface extends StatelessWidget {
  const _HipChipSurface({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dark = HipColors.isDark;
    final high = MediaQuery.maybeHighContrastOf(context) ?? false;
    // Flat frosted glass (开哥 2026-11-05): one uniform translucent tint over
    // a real backdrop blur and one hairline rim. No gradient body, no bevel,
    // no shadow — the chip sits in the bar plane, it is not a raised button.
    final fill = high
        ? (dark ? const Color(0xFF1C1C1E) : Colors.white)
        : (dark
              ? Colors.white.withValues(alpha: .12)
              : Colors.white.withValues(alpha: .38));
    final rim = dark
        ? Colors.white.withValues(alpha: high ? .45 : .16)
        : Colors.black.withValues(alpha: high ? .35 : .10);
    return DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: rim, width: high ? 1 : .75),
      ),
      child: ClipOval(
        child: high
            ? ColoredBox(color: fill, child: child)
            : BackdropFilter(
                filter: ui.ImageFilter.blur(
                  sigmaX: 12,
                  sigmaY: 12,
                  tileMode: TileMode.mirror,
                ),
                child: ColoredBox(color: fill, child: child),
              ),
      ),
    );
  }
}

/// A pushed page: backdrop, body, and [HipNavBar] overlaid on top of it. With
/// [bodyScrollsUnderBar] the body reaches the top of the screen and the page's
/// scrollable clears [hipNavInset]; otherwise a spacer keeps the body below
/// the row.
class HipNavPage extends StatefulWidget {
  const HipNavPage({
    super.key,
    required this.body,
    this.title,
    this.subtitle,
    this.leading = HipNavLeading.back,
    this.onLeading,
    this.leadingKey,
    this.trailing,
    this.backdrop,
    this.bodyScrollsUnderBar = false,
  });
  final Widget body;
  final String? title;
  final String? subtitle;
  final HipNavLeading leading;
  final VoidCallback? onLeading;
  final Key? leadingKey;
  final Widget? trailing;

  /// iOS behaviour: the body's viewport starts at the top of the safe area and
  /// the bar floats over it, so content is visible through the glass while it
  /// scrolls past. The page's own scrollable must then start its content
  /// [kHipNavInset] down; otherwise the first rows sit behind the bar.
  final bool bodyScrollsUnderBar;

  /// Defaults to the plain depth gradient.
  final Widget? backdrop;

  @override
  State<HipNavPage> createState() => _HipNavPageState();
}

class _HipNavPageState extends State<HipNavPage> {
  @override
  Widget build(BuildContext context) {
    final backdrop = widget.backdrop ?? const HipGlassBackdrop();
    return Stack(
      fit: StackFit.expand,
      children: [
        backdrop,
        Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            children: [
              Positioned.fill(
                // No SafeArea here: with the bar floating over the body the
                // viewport has to reach the very top of the screen, so the
                // content slides under the status bar too (Gemini-style,
                // 开哥 2026-11-05). Pages clear the bar themselves with
                // [hipNavInset]; the inner SafeArea still handles the bottom.
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      height: widget.bodyScrollsUnderBar
                          ? 0
                          : MediaQuery.paddingOf(context).top +
                                (widget.subtitle == null
                                    ? HipNavBar.height
                                    : HipNavBar.heightWithSubtitle),
                    ),
                    Expanded(child: SafeArea(top: false, child: widget.body)),
                  ],
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: HipNavBar(
                  title: widget.title,
                  subtitle: widget.subtitle,
                  leading: widget.leading,
                  onLeading: widget.onLeading,
                  leadingKey: widget.leadingKey,
                  trailing: widget.trailing,
                  fade: kHipNavFade,
                  // Not inside SafeArea: the band has to reach the top of the
                  // screen, while its row still sits below the status bar.
                  topInset: MediaQuery.paddingOf(context).top,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
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

/// Flat panel of rows: surface tint by opacity, radius 12, no border, no
/// shadow; 0.5pt dividers start where the row text starts.
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
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(12),
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
                    style: TextStyle(fontSize: 14, color: HipColors.faint),
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
