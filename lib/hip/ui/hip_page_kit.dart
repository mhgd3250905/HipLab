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
import 'package:flutter/services.dart';

import 'hip_glass.dart';
import 'hip_icons.dart';
import 'hip_routes.dart';
import 'hip_theme.dart';
import 'hip_widgets.dart';

/// Horizontal content edge of every kit page.
const double kHipPageEdge = 20;

/// Inner left padding of a row inside a [HipListGroup].
const double kHipRowPad = 16;

/// Where a row's text starts when it has an icon (16 + 30 + 12).
const double kHipRowTextInset = kHipRowPad + 30 + 12;

/// How far the bar's material reaches below its row before it is fully gone.
/// [HipNavPage] lets the body's viewport start at the row, so this much of the
/// content passes behind the frost and thins out there instead of hitting a
/// hard edge.
const double kHipNavFade = 24;

/// What a page's scrollable really has to clear when the body scrolls under
/// the bar: the status bar, the row, and the transition strip. Content at rest
/// must start below the strip, otherwise the first line sits in the fading
/// glass and reads as blurred (开哥 2026-11-05, routine detail).
double hipNavInset(BuildContext context, {bool hasSubtitle = false}) =>
    MediaQuery.paddingOf(context).top +
    (hasSubtitle ? HipNavBar.heightWithSubtitle : HipNavBar.height) +
    kHipNavFade;

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
    this.showLeading = true,
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

  /// False when the caller paints [HipNavBackChip] itself (HipNavPage keeps
  /// that one control still while this bar slides with the page).
  final bool showLeading;

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
              child: IgnorePointer(
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
            ),
          if (leading != HipNavLeading.none && showLeading)
            Positioned(
              // A 44pt hit target centred on the chip, so the whole left edge
              // is live the way the system back control is.
              left: chipEdge,
              top: topInset + (row - 44) / 2,
              child: _HipUncoveredLeading(
                child: HipNavBackChip(
                  leading: leading,
                  onLeading: onLeading,
                  leadingKey: leadingKey,
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

/// The back / close chip on its own 44pt hit target.
///
/// [HipNavPage] keeps this one control still while the rest of the page —
/// including the bar's glass, title and trailing action — slides with the
/// route, so navigation always has a fixed anchor (开哥 2026-11-05).
class HipNavBackChip extends StatelessWidget {
  const HipNavBackChip({
    super.key,
    this.leading = HipNavLeading.back,
    this.onLeading,
    this.leadingKey,
  });

  final HipNavLeading leading;

  /// Defaults to popping the route.
  final VoidCallback? onLeading;
  final Key? leadingKey;

  @override
  Widget build(BuildContext context) {
    if (leading == HipNavLeading.none) return const SizedBox.shrink();
    final close = leading == HipNavLeading.close;
    final label = close ? '关闭' : '返回';
    return SizedBox.square(
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
                dimension: HipNavBar.chip,
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
    );
  }
}

/// A covered page hides its leading control in both layouts: inline in the
/// sliding bar and pinned above the surface. The top page owns the chip until
/// its reverse transition has completely revealed this page again.
class _HipUncoveredLeading extends StatelessWidget {
  const _HipUncoveredLeading({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final secondary = ModalRoute.of(context)?.secondaryAnimation;
    if (secondary == null) return child;
    return AnimatedBuilder(
      animation: secondary,
      builder: (context, child) =>
          secondary.value > 0 ? const SizedBox.shrink() : child!,
      child: child,
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
      // BackdropFilter uses the ancestor paint clip, not its child's layout
      // bounds. Limit all three frost passes to this band; without this clip,
      // two sliding navigation bars can each read back the whole viewport.
      child: ClipRect(
        key: const ValueKey('hip-nav-frost-clip'),
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
    this.bottomBar,
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
  /// [hipNavInset] down; otherwise the first rows sit behind the bar.
  final bool bodyScrollsUnderBar;

  /// Fixed action bar under the content (library footers). Owns the bottom
  /// safe area; the body then skips its own bottom inset.
  final Widget? bottomBar;

  /// Defaults to the plain depth gradient.
  final Widget? backdrop;

  @override
  State<HipNavPage> createState() => _HipNavPageState();
}

class _HipNavPageState extends State<HipNavPage> {
  CurvedAnimation? _curve;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    final parent =
        route is HipRoute && route.transition == HipTransition.content
        ? route.animation
        : null;
    if (identical(_curve?.parent, parent)) return;
    _curve?.dispose();
    _curve = parent == null
        ? null
        : CurvedAnimation(
            parent: parent,
            curve: HipMotion.enter,
            reverseCurve: HipMotion.exit.flipped,
          );
  }

  @override
  void dispose() {
    _curve?.dispose();
    super.dispose();
  }

  /// A shared-bar route keeps only the back chip still: the whole page
  /// surface — backdrop, body, footer, and the bar's glass/title/trailing —
  /// slides in horizontally, so the page underneath is revealed on pop
  /// instead of a flash of empty background.
  Widget _enter(Widget child, Animation<double> curve) => SlideTransition(
    position: Tween(begin: const Offset(1, 0), end: Offset.zero).animate(curve),
    child: child,
  );

  @override
  Widget build(BuildContext context) {
    final backdrop = widget.backdrop ?? const HipGlassBackdrop();
    final route = ModalRoute.of(context);
    final hip = route is HipRoute ? route : null;
    final shared = hip?.transition == HipTransition.content;
    // Pin the chip only when both pages have one (the source sets
    // [HipRoute.pinLeading] false for the bar-less home shell).
    final pin = shared && (hip?.pinLeading ?? false);
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final anim = shared ? hip?.animation : null;
    final curve = anim == null || reduce
        ? null
        : route is HipRoute && route.popGestureInProgress
        ? anim
        : _curve;
    Widget content = Column(
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
        Expanded(
          child: SafeArea(
            top: false,
            bottom: widget.bottomBar == null,
            child: widget.body,
          ),
        ),
      ],
    );
    final topInset = MediaQuery.paddingOf(context).top;
    final row = widget.subtitle == null
        ? HipNavBar.height
        : HipNavBar.heightWithSubtitle;
    Widget page = Stack(
      fit: StackFit.expand,
      children: [
        backdrop,
        Scaffold(
          backgroundColor: Colors.transparent,
          // Scaffold resizes its body for the keyboard, but leaves a bottom
          // navigation bar at the screen edge. Lift that shared action area
          // here; pages still own only their ordinary bottom SafeArea.
          bottomNavigationBar: widget.bottomBar == null
              ? null
              : Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.viewInsetsOf(context).bottom,
                  ),
                  child: widget.bottomBar,
                ),
          // No SafeArea here: with the bar floating over the body the
          // viewport has to reach the very top of the screen, so the content
          // slides under the status bar too (Gemini-style, 开哥 2026-11-05).
          // Pages clear the bar themselves with [hipNavInset]; the inner
          // SafeArea still handles the bottom.
          body: content,
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          // The bar is no longer inside the Scaffold, so it needs its own
          // Material text style (otherwise WidgetsApp's error style paints a
          // yellow underline under the title).
          child: Material(
            type: MaterialType.transparency,
            child: HipNavBar(
              title: widget.title,
              subtitle: widget.subtitle,
              leading: widget.leading,
              onLeading: widget.onLeading,
              leadingKey: widget.leadingKey,
              trailing: widget.trailing,
              // Only a body that scrolls under the bar needs the extra
              // transition strip; a spacer layout ends at the row.
              fade: widget.bodyScrollsUnderBar ? kHipNavFade : 0,
              // Not inside SafeArea: the band has to reach the top of the
              // screen, while its row still sits below the status bar.
              topInset: topInset,
              // A pinned chip is painted outside this sliding layer; when
              // there is nothing to stay aligned with, it rides in the bar.
              showLeading: !pin,
            ),
          ),
        ),
      ],
    );
    if (curve != null) page = _enter(page, curve);
    final chip = widget.leading == HipNavLeading.none
        ? null
        : HipNavBackChip(
            leading: widget.leading,
            onLeading: widget.onLeading,
            leadingKey: widget.leadingKey,
          );
    return Stack(
      fit: StackFit.expand,
      children: [
        page,
        if (pin && chip != null)
          Positioned(
            left: HipNavBar.chipEdge,
            top: topInset + (row - 44) / 2,
            // The one fixed control: the bar's glass, title and trailing
            // action slide with their page, the chip stays put.
            child: _HipUncoveredLeading(child: chip),
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

/// Flat panel of rows: surface tint by opacity, radius 10 (iOS inset group),
/// no border, no shadow; 0.5pt dividers start where the row text starts.
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
    borderRadius: BorderRadius.circular(10),
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

/// The 30×30 tinted icon container of a row (iOS Settings icon step).
class HipRowIcon extends StatelessWidget {
  const HipRowIcon(this.glyph, {super.key});
  final HipGlyph glyph;
  @override
  Widget build(BuildContext context) => Container(
    width: 30,
    height: 30,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(7),
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
      constraints: BoxConstraints(minHeight: subtitle == null ? 52 : 60),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(kHipRowPad, 10, kHipRowPad, 10),
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
                      fontSize: 17,
                      height: 1.25,
                      fontWeight: FontWeight.w400,
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
              HipIcon(
                HipGlyph.chevronRight,
                size: 15,
                strokeWidth: 2,
                color: HipColors.faint,
              ),
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

/// The iOS switch: a 51×31 capsule with a 27pt white knob, jade when on and
/// system grey when off. Flat track, one tight knob shadow — the row's own
/// material carries the surface, the switch does not add another layer.
class HipSwitch extends StatefulWidget {
  const HipSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.semanticLabel,
    this.focusNode,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final String? semanticLabel;
  final FocusNode? focusNode;

  static const double width = 51;
  static const double height = 31;
  static const double _knob = 27;
  static const double _inset = 2;
  static const Duration _slide = Duration(milliseconds: 200);

  @override
  State<HipSwitch> createState() => _HipSwitchState();
}

class _HipSwitchState extends State<HipSwitch> {
  bool _showFocus = false;

  void _activate() {
    HapticFeedback.selectionClick();
    widget.onChanged(!widget.value);
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final duration = reduce ? Duration.zero : HipSwitch._slide;
    final track = widget.value
        ? HipColors.jade
        : (HipColors.isDark
              ? const Color(0xFF39393D)
              : const Color(0xFFE9E9EA));
    return Semantics(
      container: true,
      toggled: widget.value,
      enabled: true,
      label: widget.semanticLabel,
      onTap: _activate,
      child: FocusableActionDetector(
        focusNode: widget.focusNode,
        onShowFocusHighlight: (show) => setState(() => _showFocus = show),
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
        },
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              _activate();
              return null;
            },
          ),
        },
        child: GestureDetector(
          excludeFromSemantics: true,
          behavior: HitTestBehavior.opaque,
          onTap: _activate,
          child: DecoratedBox(
            position: DecorationPosition.foreground,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(11),
              border: _showFocus
                  ? Border.all(color: HipColors.jadeText, width: 2)
                  : null,
            ),
            // 51×44 touch target; the capsule stays 51×31 and centred.
            child: SizedBox(
              width: HipSwitch.width,
              height: 44,
              child: Center(
                child: AnimatedContainer(
                  duration: duration,
                  curve: Curves.easeOutCubic,
                  width: HipSwitch.width,
                  height: HipSwitch.height,
                  padding: const EdgeInsets.all(HipSwitch._inset),
                  decoration: BoxDecoration(
                    color: track,
                    borderRadius: BorderRadius.circular(HipSwitch.height / 2),
                  ),
                  child: AnimatedAlign(
                    duration: duration,
                    curve: Curves.easeOutCubic,
                    alignment: widget.value
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      width: HipSwitch._knob,
                      height: HipSwitch._knob,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: HipColors.isDark ? .32 : .16,
                            ),
                            blurRadius: 3,
                            offset: const Offset(0, 1.5),
                          ),
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
    );
  }
}

/// The iOS slider: a 4pt track and a 26pt white knob with one soft shadow.
/// The active track is jade; the inactive track is the system grey step used
/// by the switches, so every control on a settings card reads as one family.
class HipSlider extends StatelessWidget {
  const HipSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.semanticLabel,
  });

  final double value;
  final ValueChanged<double> onChanged;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) => Semantics(
    label: semanticLabel,
    child: SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 4,
        activeTrackColor: HipColors.jade,
        inactiveTrackColor: HipColors.isDark
            ? const Color(0xFF39393D)
            : const Color(0xFFE9E9EA),
        trackShape: const RoundedRectSliderTrackShape(),
        thumbColor: Colors.white,
        thumbShape: const _HipSliderThumbShape(),
        overlayColor: Colors.transparent,
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
        tickMarkShape: SliderTickMarkShape.noTickMark,
        showValueIndicator: ShowValueIndicator.never,
      ),
      child: Slider(value: value, onChanged: onChanged),
    ),
  );
}

class _HipSliderThumbShape extends SliderComponentShape {
  const _HipSliderThumbShape();

  static const double _radius = 13;

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) =>
      const Size.fromRadius(_radius);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final canvas = context.canvas;
    canvas.drawCircle(
      center.translate(0, 1),
      _radius,
      Paint()
        ..color = Colors.black.withValues(alpha: .18)
        ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 3),
    );
    canvas.drawCircle(center, _radius, Paint()..color = Colors.white);
    canvas.drawCircle(
      center,
      _radius - .25,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = .5
        ..color = Colors.black.withValues(alpha: .08),
    );
  }
}

/// iOS alert: a compact card with a centred title, optional message and one
/// or two flat actions split by hairlines. Returns true for the confirm
/// action, false for cancel and null when dismissed by the barrier.
Future<bool?> showHipConfirmDialog(
  BuildContext context, {
  String? title,
  String? message,
  Key? messageKey,
  required String cancelLabel,
  String? confirmLabel,
  bool destructive = false,
  Key? cancelKey,
  Key? confirmKey,
}) => showGeneralDialog<bool>(
  context: context,
  barrierDismissible: true,
  barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
  barrierColor: Colors.black.withValues(alpha: .36),
  transitionDuration: (MediaQuery.maybeDisableAnimationsOf(context) ?? false)
      ? Duration.zero
      : const Duration(milliseconds: 180),
  pageBuilder: (_, _, _) => _HipConfirmDialog(
    title: title,
    message: message,
    messageKey: messageKey,
    cancelLabel: cancelLabel,
    confirmLabel: confirmLabel,
    destructive: destructive,
    cancelKey: cancelKey,
    confirmKey: confirmKey,
  ),
  transitionBuilder: (context, animation, _, child) {
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) return child;
    final t = Curves.easeOutCubic.transform(animation.value);
    return FadeTransition(
      opacity: animation,
      child: Transform.scale(scale: .96 + .04 * t, child: child),
    );
  },
);

class _HipConfirmDialog extends StatelessWidget {
  const _HipConfirmDialog({
    this.title,
    this.message,
    this.messageKey,
    required this.cancelLabel,
    this.confirmLabel,
    required this.destructive,
    this.cancelKey,
    this.confirmKey,
  });

  final String? title;
  final String? message;
  final Key? messageKey;
  final String cancelLabel;
  final String? confirmLabel;
  final bool destructive;
  final Key? cancelKey;
  final Key? confirmKey;

  @override
  Widget build(BuildContext context) {
    final hasMessage = message != null && message!.isNotEmpty;
    final line = HipColors.text.withValues(alpha: .10);
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 320,
          maxHeight: MediaQuery.sizeOf(context).height * .78,
        ),
        // A dialog route sits above the page Material; without this layer its
        // raw Texts inherit WidgetsApp's error style (yellow underline).
        child: Material(
          type: MaterialType.transparency,
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: HipColors.surface,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .18),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      22,
                      hasMessage ? 22 : 20,
                      22,
                      hasMessage ? 20 : 20,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (title != null)
                          Text(
                            title!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: HipColors.text,
                            ),
                          ),
                        if (title != null && hasMessage)
                          const SizedBox(height: 6),
                        if (hasMessage)
                          Text(
                            message!,
                            key: messageKey,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.45,
                              color: HipColors.muted,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Divider(height: .5, thickness: .5, color: line),
                IntrinsicHeight(
                  child: Row(
                    children: [
                      Expanded(
                        child: _HipDialogAction(
                          key: cancelKey,
                          label: cancelLabel,
                          color: HipColors.text,
                          weight: FontWeight.w400,
                          onTap: () => Navigator.of(context).pop(false),
                        ),
                      ),
                      if (confirmLabel != null) ...[
                        VerticalDivider(width: .5, thickness: .5, color: line),
                        Expanded(
                          child: _HipDialogAction(
                            key: confirmKey,
                            label: confirmLabel!,
                            color: destructive
                                ? HipColors.pain
                                : HipColors.jadeText,
                            weight: FontWeight.w600,
                            onTap: () => Navigator.of(context).pop(true),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HipDialogAction extends StatelessWidget {
  const _HipDialogAction({
    super.key,
    required this.label,
    required this.color,
    required this.weight,
    required this.onTap,
  });

  final String label;
  final Color color;
  final FontWeight weight;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => HipPressable(
    semanticLabel: label,
    scale: .98,
    onTap: onTap,
    child: SizedBox(
      height: 50,
      child: Builder(
        builder: (context) {
          final down = HipPressedScope.of(context);
          return AnimatedContainer(
            duration: HipMotion.press,
            color: down
                ? HipColors.text.withValues(alpha: .05)
                : Colors.transparent,
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(fontSize: 17, fontWeight: weight, color: color),
            ),
          );
        },
      ),
    ),
  );
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
