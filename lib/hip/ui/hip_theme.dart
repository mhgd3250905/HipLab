import 'package:flutter/material.dart';

/// Bundled Noto Sans SC (assets/fonts/NotoSansSC.ttf, OFL).
const hipFontFamily = 'NotoSansSC';

/// HipLab palette: the FlareLab graphite stage with a jade accent (#3ccfa4)
/// instead of FlareLab's ember. Dark only in the MVP, as in the prototype.
abstract final class HipColors {
  static const background = Color(0xff0c0d0f);
  static const surface = Color(0xff16171a);
  static const surfaceHigh = Color(0xff1f2124);
  static const line = Color(0xff2a2c30);
  static const jade = Color(0xff3ccfa4);
  static const jadeDeep = Color(0xff1f6f59);
  static const glow = Color(0xff7be8ff);
  static const text = Color(0xfff2f3f5);
  static const muted = Color(0xff8c9096);
  static const faint = Color(0xff5b5f66);
  static const tight = Color(0xfff3a443);
  static const pain = Color(0xffef5a5a);
}

ThemeData hipTheme() {
  final base = ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    fontFamily: hipFontFamily,
    scaffoldBackgroundColor: HipColors.background,
    colorScheme: const ColorScheme.dark(
      primary: HipColors.jade,
      onPrimary: Color(0xff07261d),
      secondary: HipColors.jade,
      surface: HipColors.surface,
      onSurface: HipColors.text,
      error: HipColors.pain,
    ),
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(
      bodyColor: HipColors.text,
      displayColor: HipColors.text,
    ),
    splashFactory: NoSplash.splashFactory,
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? HipColors.background
            : HipColors.muted,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? HipColors.jade
            : HipColors.surfaceHigh,
      ),
    ),
  );
}
