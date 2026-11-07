// Development-only recipe launcher. It does not replace lib/main.dart.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hiplab/hip/ui/hip_routes.dart';
import 'package:hiplab/hip/ui/hip_text.dart';
import 'package:hiplab/hip/ui/hip_theme.dart';
import 'package:hiplab/hip/ui/hip_widgets.dart';

import 'controls_example.dart';
import 'media_handoff_example.dart';
import 'navigation_example.dart';

void main() {
  const dark = bool.fromEnvironment('UI_KIT_DARK');
  const language = String.fromEnvironment(
    'UI_KIT_LANGUAGE',
    defaultValue: 'zh',
  );
  runApp(
    UiKitGalleryApp(
      brightness: dark ? Brightness.dark : Brightness.light,
      locale: Locale(language == 'en' ? 'en' : 'zh'),
    ),
  );
}

/// One fixed theme/locale per gallery session; no store, auth, or media backend.
/// Production theme changes use the host's existing inherited theme adapter.
class UiKitGalleryApp extends StatelessWidget {
  const UiKitGalleryApp({
    super.key,
    this.brightness = Brightness.light,
    this.locale = const Locale('zh'),
  });

  final Brightness brightness;
  final Locale locale;

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: hipTheme(HipPalette.light),
    darkTheme: hipTheme(HipPalette.dark),
    themeMode: brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
    themeAnimationDuration: Duration.zero,
    locale: locale,
    supportedLocales: const [Locale('zh'), Locale('en')],
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    builder: (context, child) {
      final dark = Theme.of(context).brightness == Brightness.dark;
      HipColors.palette = dark ? HipPalette.dark : HipPalette.light;
      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: (dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
            .copyWith(
              statusBarColor: Colors.transparent,
              systemNavigationBarColor: HipColors.background,
              systemNavigationBarIconBrightness: dark
                  ? Brightness.light
                  : Brightness.dark,
            ),
        child: child!,
      );
    },
    home: const _GalleryLanding(),
  );
}

class _GalleryLanding extends StatelessWidget {
  const _GalleryLanding();

  @override
  Widget build(BuildContext context) {
    final t = HipText.of(context);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              t.pick('UI 实现样例', 'UI implementation recipes'),
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Text(
              t.pick(
                '这是参考画廊；设置不会写入业务数据，媒体页不使用真实视频。',
                'A reference gallery: settings are local and media is simulated.',
              ),
              style: TextStyle(color: HipColors.muted, fontSize: 14),
            ),
            const SizedBox(height: 28),
            HipPrimaryButton(
              key: const ValueKey('recipe-nav'),
              label: t.pick('导航与返回键', 'Navigation and back control'),
              onPressed: () => Navigator.of(
                context,
              ).push(HipRoute.push<void>((_) => const NavigationRecipeHome())),
            ),
            const SizedBox(height: 16),
            HipPrimaryButton(
              key: const ValueKey('recipe-controls'),
              label: t.pick('设置与控件', 'Settings and controls'),
              onPressed: () => Navigator.of(context).push(
                HipRoute.content<void>(
                  (_) => const ControlsRecipePage(),
                  pinLeading: false,
                ),
              ),
            ),
            const SizedBox(height: 16),
            HipPrimaryButton(
              key: const ValueKey('recipe-media'),
              label: t.pick('媒体身份与展开', 'Media identity and expansion'),
              onPressed: () => Navigator.of(context).push(
                HipRoute.content<void>(
                  (_) => const MediaHandoffRecipePage(),
                  pinLeading: false,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              t.pick('从样例返回画廊可使用系统返回。', 'Use Back to return here.'),
              style: TextStyle(color: HipColors.muted, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
