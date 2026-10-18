import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;

export '../domain/hip_settings.dart' show HipThemeChoice;

/// Bundled Noto Sans SC (assets/fonts/NotoSansSC.ttf, OFL).
const hipFontFamily = 'NotoSansSC';

/// One complete set of colour tokens. Two instances: [dark] (the FlareLab
/// graphite stage with a jade accent) and [light] (paper white, deeper jade
/// so text and strokes keep AA contrast on white).
@immutable
class HipPalette {
  const HipPalette({
    required this.brightness,
    required this.background,
    required this.surface,
    required this.surfaceHigh,
    required this.line,
    required this.jade,
    required this.jadeDeep,
    required this.onJade,
    required this.glow,
    required this.text,
    required this.muted,
    required this.faint,
    required this.tight,
    required this.pain,
    required this.scrim,
    required this.shadow,
    required this.mediaBackdrop,
    required this.track,
    required this.thumb,
    required this.thumbHighlight,
  });

  final Brightness brightness;

  /// Page.
  final Color background;

  /// Cards, sheets.
  final Color surface;

  /// Raised controls inside cards (circle buttons, segment tracks, footers).
  final Color surfaceHigh;

  /// Hairline strokes.
  final Color line;

  /// Accent.
  final Color jade;
  final Color jadeDeep;

  /// Text / icons on a jade fill.
  final Color onJade;

  /// Muscle-highlight dot colour (matches the renders' cyan glow).
  final Color glow;
  final Color text;
  final Color muted;
  final Color faint;
  final Color tight;
  final Color pain;

  /// Translucent fill for chips floating on media.
  final Color scrim;

  /// Card shadow (light theme only really shows it).
  final Color shadow;

  /// What sits behind a drill render (so letterboxing matches the art).
  final Color mediaBackdrop;

  /// Inset track of a segmented control / switch-like group: a step *below*
  /// the surface it sits on, so the group reads as recessed.
  final Color track;

  /// The sliding selection thumb: a step *above* the surface (raised).
  final Color thumb;

  /// 1px top light on the thumb (dark theme only; transparent on light).
  final Color thumbHighlight;

  bool get isDark => brightness == Brightness.dark;

  static const dark = HipPalette(
    brightness: Brightness.dark,
    background: Color(0xff0c0d0f),
    surface: Color(0xff16171a),
    surfaceHigh: Color(0xff1f2124),
    line: Color(0xff2a2c30),
    jade: Color(0xff3ccfa4),
    jadeDeep: Color(0xff1f6f59),
    onJade: Color(0xff07261d),
    glow: Color(0xff7be8ff),
    text: Color(0xfff2f3f5),
    muted: Color(0xff8c9096),
    faint: Color(0xff5b5f66),
    tight: Color(0xfff3a443),
    pain: Color(0xffef5a5a),
    scrim: Color(0x990c0d0f),
    shadow: Color(0x66000000),
    mediaBackdrop: Color(0xff101013),
    track: Color(0xff0f1012),
    thumb: Color(0xff26292d),
    thumbHighlight: Color(0x14ffffff),
  );

  static const light = HipPalette(
    brightness: Brightness.light,
    background: Color(0xfff4f5f3),
    surface: Color(0xffffffff),
    surfaceHigh: Color(0xffeef0ee),
    line: Color(0xffe1e4e1),
    jade: Color(0xff14a37b),
    jadeDeep: Color(0xff0d6e53),
    onJade: Color(0xffffffff),
    glow: Color(0xff1aa6cf),
    text: Color(0xff121614),
    muted: Color(0xff5d6661),
    faint: Color(0xff9aa29e),
    tight: Color(0xffd27a1e),
    pain: Color(0xffd43f3f),
    scrim: Color(0xccffffff),
    shadow: Color(0x121d2b25),
    // Light media stage (2026-10-19): every clip/poster/still has a light
    // render baked on exactly this colour (tools/media/build_themed_media.py
    // STAGE['light']). Neutral grey on purpose: R=G=B decodes to the same
    // value under BT.601 and BT.709, so the video never shows a tinted box
    // against this Flutter-painted backdrop. Change both together.
    mediaBackdrop: Color(0xffefefef),
    track: Color(0xffeceeec),
    thumb: Color(0xffffffff),
    thumbHighlight: Color(0x00ffffff),
  );
}

/// Colour tokens for the theme in effect. The app sets [HipColors.palette]
/// from the resolved theme before building and rebuilds the whole tree when
/// it changes (see `HipApp`), so `HipColors.x` always reads the current set.
abstract final class HipColors {
  static HipPalette palette = HipPalette.dark;

  /// Screenshot harness only: the flutter_tester renderer draws BoxShadow
  /// without its blur (a hard offset copy of the shape), which would make
  /// review screenshots show harsh shelves that never appear on a device.
  /// test_screens/ sets this to drop blurred shadows; the app never does.
  static bool flatShadows = false;

  /// [s] unless [flatShadows] is set.
  static List<BoxShadow>? shadows(List<BoxShadow>? s) => flatShadows ? null : s;

  static bool get isDark => palette.isDark;
  static Color get background => palette.background;
  static Color get surface => palette.surface;
  static Color get surfaceHigh => palette.surfaceHigh;
  static Color get line => palette.line;
  static Color get jade => palette.jade;
  static Color get jadeDeep => palette.jadeDeep;

  /// Accent text on page/card backgrounds. Keep the brighter jade for fills
  /// and graphics; light-theme small text needs the deeper shade to read.
  static Color get jadeText => palette.isDark ? palette.jade : palette.jadeDeep;
  static Color get onJade => palette.onJade;
  static Color get glow => palette.glow;
  static Color get text => palette.text;
  static Color get muted => palette.muted;
  static Color get faint => palette.faint;
  static Color get tight => palette.tight;
  static Color get pain => palette.pain;
  static Color get scrim => palette.scrim;
  static Color get shadow => palette.shadow;
  static Color get mediaBackdrop => palette.mediaBackdrop;
  static Color get track => palette.track;
  static Color get thumb => palette.thumb;
  static Color get thumbHighlight => palette.thumbHighlight;

  /// Soft elevation for cards: none on dark (strokes carry the shape), a
  /// faint two-layer shadow on light.
  static List<BoxShadow>? get cardShadow => palette.isDark || flatShadows
      ? null
      : [
          BoxShadow(
            color: palette.shadow,
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          const BoxShadow(
            color: Color(0x08000000),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ];
}

/// Motion tokens shared by every transition (#12, round 2). Every duration
/// and curve in the app comes from here so the whole UI moves alike.
abstract final class HipMotion {
  static const fast = Duration(milliseconds: 180);
  static const medium = Duration(milliseconds: 280);
  static const slow = Duration(milliseconds: 420);
  static const curve = Curves.easeOutCubic;

  /// Pressed-state feedback (a tactile tile sinking: scale 0.97, light and
  /// shadow drop) and its release. Short and without overshoot, so a press
  /// reads as "pushed in", not as a bounce (button audit 2026-10-18).
  static const press = Duration(milliseconds: 100);
  static const release = Duration(milliseconds: 180);

  /// Press scale for tactile buttons; 1 (no scale) under reduce motion.
  static const pressScale = .97;

  /// Segmented-control thumb slide.
  static const segment = Duration(milliseconds: 380);

  /// Push / pop of a page (horizontal), its reverse a touch quicker.
  static const page = Duration(milliseconds: 400);
  static const pageReverse = Duration(milliseconds: 340);

  /// Container transform (a button growing into a full-screen page): the
  /// one large move of the app, so it gets the longest time; closing is a
  /// little quicker.
  static const expand = Duration(milliseconds: 500);
  static const expandReverse = Duration(milliseconds: 420);

  /// Bottom tab switch (fade through: out, then in).
  static const tab = Duration(milliseconds: 300);

  /// Bottom sheets rise from the bottom on the page timing.
  static const sheet = AnimationStyle(
    duration: page,
    reverseDuration: pageReverse,
  );

  /// Material 3 emphasized easing: quick start, long gentle settle.
  ///
  /// Not for page moves: the three-point M3 curve is ~90 % done after a
  /// third of its time, so a 380 ms page move read as a cut followed by a
  /// long creep (transition audit 2026-10-18). Pages use [enter] /
  /// [exit] / [container] below.
  static const Curve emphasized = Curves.easeInOutCubicEmphasized;
  static const Curve emphasizedDecelerate = Cubic(0.05, 0.7, 0.1, 1.0);
  static const Curve emphasizedAccelerate = Cubic(0.3, 0.0, 0.8, 0.15);

  /// A page arriving (push, rise): a gentle first frame, half way at
  /// ~20 % of the time, then a long soft landing (M3 "emphasized" as a
  /// single cubic).
  static const Curve enter = Cubic(0.2, 0.0, 0.0, 1.0);

  /// A page leaving (pop), expressed as the distance travelled: starts
  /// promptly and decelerates out without a lingering sliver.
  static const Curve exit = Curves.fastOutSlowIn;

  /// Container transform bounds, both ways (Material's container easing).
  static const Curve container = Curves.fastOutSlowIn;

  /// A soft spring: settles with a small (≈4%) overshoot. Used for the
  /// segmented thumb and press release.
  static const Curve spring = Cubic(0.32, 1.28, 0.52, 1.0);
}

ThemeData hipTheme([HipPalette p = HipPalette.dark]) {
  final scheme = p.isDark
      ? ColorScheme.dark(
          primary: p.jade,
          onPrimary: p.onJade,
          secondary: p.jade,
          surface: p.surface,
          onSurface: p.text,
          error: p.pain,
        )
      : ColorScheme.light(
          primary: p.jade,
          onPrimary: p.onJade,
          secondary: p.jade,
          surface: p.surface,
          onSurface: p.text,
          error: p.pain,
        );
  final base = ThemeData(
    brightness: p.brightness,
    useMaterial3: true,
    fontFamily: hipFontFamily,
    scaffoldBackgroundColor: p.background,
    colorScheme: scheme,
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: HipPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.linux: HipPageTransitionsBuilder(),
        TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.windows: HipPageTransitionsBuilder(),
        TargetPlatform.fuchsia: HipPageTransitionsBuilder(),
      },
    ),
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(bodyColor: p.text, displayColor: p.text),
    iconTheme: IconThemeData(color: p.text),
    dividerColor: p.line,
    splashFactory: NoSplash.splashFactory,
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: p.surface,
      modalBackgroundColor: p.surface,
      showDragHandle: true,
      dragHandleColor: p.faint,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
    listTileTheme: ListTileThemeData(textColor: p.text, iconColor: p.muted),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: p.isDark ? p.jade : p.jadeDeep,
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: p.surfaceHigh,
      selectedColor: p.jade.withValues(alpha: p.isDark ? .22 : .16),
      side: BorderSide(color: p.line),
      labelStyle: TextStyle(color: p.text, fontFamily: hipFontFamily),
      checkmarkColor: p.jade,
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: p.jade,
      inactiveTrackColor: p.surfaceHigh,
      thumbColor: p.jade,
      overlayColor: p.jade.withValues(alpha: .12),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? (p.isDark ? p.background : Colors.white)
            : p.muted,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? p.jade : p.surfaceHigh,
      ),
      trackOutlineColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? p.jade : p.line,
      ),
    ),
  );
}

/// Fallback for any plain [PageRoute] (the app pushes `HipRoute`s, see
/// hip_routes.dart): the same horizontal push — in from the right on the
/// [HipMotion.enter] / [HipMotion.exit] curves, no white flash. iOS keeps Cupertino's (edge swipe).
class HipPageTransitionsBuilder extends PageTransitionsBuilder {
  const HipPageTransitionsBuilder();

  @override
  Duration get transitionDuration => HipMotion.page;

  @override
  Duration get reverseTransitionDuration => HipMotion.pageReverse;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: HipMotion.enter,
      reverseCurve: HipMotion.exit.flipped,
    );
    return SlideTransition(
      position: Tween(
        begin: const Offset(1, 0),
        end: Offset.zero,
      ).animate(curved),
      child: child,
    );
  }
}
