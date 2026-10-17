import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../control/hip_store.dart';
import '../data/hip_content_loader.dart';
import '../domain/hip_models.dart';
import '../domain/hip_progress.dart';
import '../domain/hip_session.dart';
import '../voice/hip_voice.dart';
import '../voice/just_audio_output.dart';
import '../voice/session_script.dart';
import '../voice/voice_library.dart';
import 'hip_assessment_page.dart';
import 'hip_icons.dart';
import 'hip_player_page.dart';
import 'hip_segmented.dart';
import 'hip_theme.dart';
import 'hip_widgets.dart';

const hipAppName = '开胯训练助手';

/// Root of the HipLab app (entry: lib/main.dart).
class HipApp extends StatefulWidget {
  const HipApp({super.key, this.store, this.videoEnabled = true, this.voice});

  /// Injected in tests; otherwise loaded from assets + SharedPreferences.
  final HipStore? store;
  final bool videoEnabled;

  /// Injected in tests; otherwise real playback (silent when video is off,
  /// i.e. in widget tests).
  final HipVoice? voice;

  @override
  State<HipApp> createState() => _HipAppState();
}

class _HipAppState extends State<HipApp> {
  late Future<(HipStore, HipVoice)> _loading = _load();

  Future<(HipStore, HipVoice)> _load() async {
    final store = widget.store ?? HipStore(content: await loadHipContent());
    if (widget.store == null) await store.initialize();
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      HipMediaVariants.assets = manifest.listAssets().toSet();
    } on Object {
      HipMediaVariants.assets = const {};
    }
    HipVoice voice;
    if (widget.voice != null) {
      voice = widget.voice!;
    } else if (!widget.videoEnabled) {
      voice = HipVoice.silent;
    } else {
      voice = HipVoice(
        lib: await VoiceLibrary.load(),
        output: JustAudioVoiceOutput(),
        settingsOf: () => store.voice,
      );
    }
    return (store, voice);
  }

  static ThemeMode _mode(HipThemeChoice c) => switch (c) {
    HipThemeChoice.light => ThemeMode.light,
    HipThemeChoice.dark => ThemeMode.dark,
    HipThemeChoice.system => ThemeMode.system,
  };

  @override
  Widget build(BuildContext context) => FutureBuilder<(HipStore, HipVoice)>(
    future: _loading,
    builder: (context, snap) {
      final loaded = snap.data;
      if (loaded == null) {
        return _shell(
          ThemeMode.system,
          snap.hasError
              ? Scaffold(
                  body: Center(
                    child: TextButton(
                      onPressed: () => setState(() => _loading = _load()),
                      child: const Text('读取失败，点一下重试'),
                    ),
                  ),
                )
              : const Scaffold(body: SizedBox.expand()),
        );
      }
      final (store, voice) = loaded;
      return ListenableBuilder(
        listenable: store,
        builder: (context, _) => HipVoiceScope(
          voice: voice,
          child: _shell(
            _mode(store.theme),
            store.onboarded
                ? HipHome(store: store)
                : HipOnboarding(store: store),
          ),
        ),
      );
    },
  );

  Widget _shell(ThemeMode mode, Widget home) => MaterialApp(
    title: hipAppName,
    debugShowCheckedModeBanner: false,
    theme: hipTheme(HipPalette.light),
    darkTheme: hipTheme(HipPalette.dark),
    themeMode: mode,
    themeAnimationDuration: Duration.zero,
    locale: const Locale('zh'),
    supportedLocales: const [Locale('zh')],
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    builder: (context, child) => _PaletteScope(
      child: HipMediaPolicy(videoEnabled: widget.videoEnabled, child: child!),
    ),
    home: home,
  );
}

/// Points [HipColors] at the palette of the theme in effect and, when it
/// changes (settings or the system switching light/dark), rebuilds every
/// widget below in the same frame — pages, sheets and pushed routes keep
/// their state (#14).
class _PaletteScope extends StatefulWidget {
  const _PaletteScope({required this.child});
  final Widget child;
  @override
  State<_PaletteScope> createState() => _PaletteScopeState();
}

class _PaletteScopeState extends State<_PaletteScope> {
  Brightness? _applied;

  static void _rebuildAll(Element e) {
    e.markNeedsBuild();
    e.visitChildren(_rebuildAll);
  }

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    if (b != _applied) {
      final first = _applied == null;
      _applied = b;
      HipColors.palette = b == Brightness.dark
          ? HipPalette.dark
          : HipPalette.light;
      if (!first) (context as Element).visitChildren(_rebuildAll);
    }
    final p = HipColors.palette;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: (p.isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
          .copyWith(
            statusBarColor: const Color(0x00000000),
            systemNavigationBarColor: p.background,
            systemNavigationBarIconBrightness: p.isDark
                ? Brightness.light
                : Brightness.dark,
          ),
      child: widget.child,
    );
  }
}

// ───────────────────────── first launch: 3 safety cards + identity ─────────

class HipOnboarding extends StatefulWidget {
  const HipOnboarding({super.key, required this.store, this.review = false});
  final HipStore store;

  /// Opened again from settings: re-answer the cards, keep identity.
  final bool review;
  @override
  State<HipOnboarding> createState() => _HipOnboardingState();
}

class _HipOnboardingState extends State<HipOnboarding> {
  final _answers = <String, bool>{};
  int _index = 0;
  bool _busy = false;

  List<SafetyCard> get _cards => widget.store.content.safetyCards;
  bool get _onIdentity => _index >= _cards.length;

  static const _icons = {
    'pregnant_woman': HipGlyph.person,
    'healing': HipGlyph.bandage,
    'personal_injury': HipGlyph.clipboard,
  };

  /// Hero art per card and theme: `assets/hip/onboarding/<id>-<dark|light>.webp`
  /// (tools/onboarding_art/import_onboarding_art.py; swap set A↔B there).
  static String heroAsset(String cardId, {required bool dark}) =>
      'assets/hip/onboarding/$cardId-${dark ? 'dark' : 'light'}.webp';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    hipPrecache(context, [
      for (final c in _cards) heroAsset(c.id, dark: HipColors.isDark),
    ]);
  }

  Future<void> _answer(bool yes) async {
    if (_busy) return;
    _busy = true;
    try {
      _answers[_cards[_index].id] = yes;
      if (_index == _cards.length - 1) {
        await widget.store.setSafety(_answers);
        if (widget.review && mounted) {
          Navigator.of(context).pop();
          return;
        }
      }
      if (mounted) setState(() => _index++);
    } finally {
      _busy = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final blocked = _answers.values.any((v) => v);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
          child: HipFadeSwitcher(
            child: KeyedSubtree(
              key: ValueKey(_onIdentity ? 'identity' : 'card'),
              child: _onIdentity ? _identity(blocked) : _safetyCard(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _safetyCard() {
    final card = _cards[_index];
    final hero = heroAsset(card.id, dark: HipColors.isDark);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            for (var i = 0; i < _cards.length; i++)
              Expanded(
                child: AnimatedContainer(
                  duration: HipMotion.medium,
                  height: 4,
                  margin: EdgeInsets.only(right: i < _cards.length - 1 ? 6 : 0),
                  decoration: BoxDecoration(
                    color: i <= _index ? HipColors.jade : HipColors.surfaceHigh,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Text(
              '开始之前 · 安全确认',
              style: TextStyle(
                fontSize: 14,
                color: HipColors.jade,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              '${_index + 1} / ${_cards.length}',
              style: TextStyle(fontSize: 14, color: HipColors.muted),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Large hero visual (4:3 art) at the top; on short screens it gives
        // way first, the question and buttons always stay whole.
        Expanded(
          child: LayoutBuilder(
            builder: (context, c) {
              // As tall as a square when there is room (cropping the 4:3
              // art's empty sides), never shorter than the art's own 4:3.
              final h = c.maxHeight.clamp(0.0, c.maxWidth).toDouble();
              return Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: c.maxWidth,
                  height: h,
                  child: HipMediaFrame(
                    key: const ValueKey('onboarding-hero'),
                    radius: 28,
                    color: HipColors.surface,
                    borderColor: HipColors.isDark
                        ? HipColors.line
                        : const Color(0x00000000),
                    shadow: HipColors.cardShadow,
                    child: HipFadeSwitcher(
                      duration: HipMotion.slow,
                      offset: 0,
                      expand: true,
                      child: Image.asset(
                        hero,
                        key: ValueKey(hero),
                        fit: BoxFit.cover,
                        gaplessPlayback: true,
                        errorBuilder: (_, _, _) => _heroPlaceholder(card),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 22),
        HipFadeSwitcher(
          alignment: AlignmentDirectional.bottomStart,
          child: Column(
            key: ValueKey(card.id),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '你现在有这种情况吗？',
                style: TextStyle(fontSize: 15, color: HipColors.muted),
              ),
              const SizedBox(height: 8),
              Text(
                card.title,
                style: const TextStyle(
                  fontSize: 23,
                  height: 1.4,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '如实选就好。选“有”也可以浏览动作，只是先不安排训练。',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: HipColors.muted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            Expanded(
              child: HipSecondaryButton(
                key: const ValueKey('safety-yes'),
                label: '有',
                onPressed: () => _answer(true),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: HipPrimaryButton(
                key: const ValueKey('safety-no'),
                label: '没有',
                onPressed: () => _answer(false),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          '这是运动练习，不能替代医生的建议。',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: HipColors.faint),
        ),
      ],
    );
  }

  /// Shown only if the art is missing from the bundle.
  Widget _heroPlaceholder(SafetyCard card) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: RadialGradient(
        radius: .9,
        colors: [HipColors.jade.withValues(alpha: .25), HipColors.surface],
      ),
    ),
    child: Center(
      child: HipIcon(
        _icons[card.icon] ?? HipGlyph.info,
        size: 96,
        color: HipColors.jade,
      ),
    ),
  );

  Widget _identity(bool blocked) {
    const choices = [
      (HipIdentity.office, HipGlyph.chair, '久坐上班，髋前侧和臀部发紧'),
      (HipIdentity.dancer, HipGlyph.dancer, '跳舞 / Breaking，要开胯和控制'),
      (HipIdentity.other, HipGlyph.person, '想让髋更灵活、更舒服'),
    ];
    return ListView(
      children: [
        if (blocked) ...[
          HipPanel(
            borderColor: HipColors.tight.withValues(alpha: .5),
            child: Row(
              children: [
                HipIcon(HipGlyph.clipboard, color: HipColors.tight),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    '先问问医生或专业人士，再开始练习。你可以先看看动作。',
                    style: TextStyle(fontSize: 15, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
        const SizedBox(height: 12),
        Text(
          '最后一步',
          style: TextStyle(
            fontSize: 14,
            color: HipColors.jade,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          '你是哪一种？',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 20),
        for (final (id, icon, line) in choices) ...[
          HipPanel(
            padding: EdgeInsets.zero,
            child: InkWell(
              key: ValueKey('identity-${id.id}'),
              onTap: () => widget.store.setIdentity(id),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: HipColors.jade.withValues(alpha: .12),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: HipIcon(icon, size: 30, color: HipColors.jade),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            id.zh,
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            line,
                            style: TextStyle(
                              fontSize: 13,
                              color: HipColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    HipIcon(
                      HipGlyph.chevronRight,
                      size: 20,
                      color: HipColors.faint,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

// ───────────────────────── home ─────────────────────────

class HipHome extends StatefulWidget {
  const HipHome({super.key, required this.store});
  final HipStore store;
  @override
  State<HipHome> createState() => _HipHomeState();
}

class _HipHomeState extends State<HipHome> {
  int _tab = 0;
  final _startKey = GlobalKey();
  HipStore get store => widget.store;

  void _selectTab(int i) {
    if (i == _tab) return;
    setState(() => _tab = i);
  }

  Future<void> _startPlan(TrainingPlan plan) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => HipPlayerPage(store: store, plan: plan),
      ),
    );
  }

  Future<void> _startAssessment() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) =>
            HipAssessmentPage(store: store, onStartPlan: _startPlan),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      bottom: false,
      child: HipFadeSwitcher(
        offset: .015,
        child: KeyedSubtree(
          key: ValueKey('tab-body-$_tab'),
          child: switch (_tab) {
            1 => HipAssessmentIntro(store: store, onStart: _startAssessment),
            2 => HipProgressPage(store: store),
            _ => _today(),
          },
        ),
      ),
    ),
    bottomNavigationBar: _nav(),
  );

  Widget _nav() => Container(
    decoration: BoxDecoration(
      color: HipColors.background,
      border: Border(top: BorderSide(color: HipColors.line)),
    ),
    child: SafeArea(
      top: false,
      child: SizedBox(
        height: 64,
        child: Row(
          children: [
            for (final (i, glyph, label) in [
              (0, HipGlyph.today, '今日'),
              (1, HipGlyph.checkup, '自测'),
              (2, HipGlyph.progress, '进度'),
            ])
              Expanded(
                child: Semantics(
                  button: true,
                  selected: _tab == i,
                  label: label,
                  child: GestureDetector(
                    key: ValueKey('tab-$i'),
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _selectTab(i),
                    child: ExcludeSemantics(child: _navItem(i, glyph, label)),
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );

  /// Selected tab: filled glyph in jade with a small settle; others outline.
  Widget _navItem(int i, HipGlyph glyph, String label) {
    final on = _tab == i;
    final color = on ? HipColors.jade : HipColors.muted;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedScale(
          scale: on ? 1 : .94,
          duration: HipMotion.medium,
          curve: HipMotion.spring,
          child: AnimatedSwitcher(
            duration: HipMotion.fast,
            child: HipIcon(
              glyph,
              key: ValueKey('$glyph-$on'),
              size: 24,
              filled: on,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 3),
        AnimatedDefaultTextStyle(
          duration: HipMotion.fast,
          style: TextStyle(
            fontFamily: hipFontFamily,
            fontSize: 11,
            fontWeight: on ? FontWeight.w600 : FontWeight.w400,
            color: color,
          ),
          child: Text(label),
        ),
      ],
    );
  }

  static const _weekdays = ['一', '二', '三', '四', '五', '六', '日'];

  Widget _today() {
    final now = store.now();
    final plan = store.todayPlan;
    final result = store.latestResult;
    final locks = store.lockedDirections;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '周${_weekdays[now.weekday - 1]} · ${now.month} 月 ${now.day} 日',
                    style: TextStyle(fontSize: 13, color: HipColors.muted),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    '今日训练',
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: HipColors.surface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  HipIcon(
                    HipGlyph.flame,
                    size: 18,
                    filled: true,
                    color: HipColors.tight,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${store.streak}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (store.askNumbness) ...[_numbnessCard(), const SizedBox(height: 12)],
        for (final d in locks.keys) ...[
          _lockCard(d),
          const SizedBox(height: 12),
        ],
        plan == null ? _blockedHero() : _hero(plan),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(child: _durationPicker()),
            const SizedBox(width: 12),
            Expanded(child: _scenePicker()),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          // Grows with the system text size: 150 at ×1.0, ~165 at ×1.5, so
          // the label + caption lines never squeeze the radar/icon out.
          height: 120 + MediaQuery.textScalerOf(context).scale(30),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _streakCard()),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: result == null
                      ? _startAssessment
                      : () => _selectTab(2),
                  child: HipPanel(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '我的髋部',
                          style: TextStyle(
                            fontSize: 13,
                            color: HipColors.muted,
                          ),
                        ),
                        Expanded(
                          child: result == null
                              ? Center(
                                  // Scales down instead of overflowing when
                                  // a very large text size outgrows the tile.
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        HipIcon(
                                          HipGlyph.radar,
                                          size: 40,
                                          color: HipColors.jade,
                                        ),
                                        SizedBox(height: 6),
                                        Text(
                                          '3 分半自测',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : Center(
                                  child: HipRadar(
                                    values: result.radar,
                                    highlight: result.tightest.toSet(),
                                    warn: result.painDirections,
                                    compact: true,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _hero(TrainingPlan plan) {
    final first = plan.steps.isEmpty ? null : plan.steps.first.drill;
    final hero =
        plan.steps.where((s) => s.drill.poster != null).firstOrNull?.drill ??
        first;
    // The hero stays a dark "stage" in both themes: the renders are dark,
    // and a dark tile on the light page reads as media, not as a grey card.
    const stage = HipPalette.dark;
    return SizedBox(
      height: 350,
      child: HipMediaFrame(
        radius: 26,
        color: stage.surface,
        borderColor: HipColors.isDark ? stage.line : const Color(0x00000000),
        shadow: HipColors.cardShadow,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hero != null)
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                height: 280,
                child: HipDrillArt(
                  drill: hero,
                  alignment: const Alignment(0, -.2),
                ),
              ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [.45, .8],
                  colors: [stage.surface.withValues(alpha: 0), stage.surface],
                ),
              ),
            ),
            Positioned(left: 14, top: 14, child: _chip(HipGlyph.loop, '预览')),
            Positioned(
              left: 20,
              right: 130,
              bottom: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plan.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                      color: stage.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${plan.minutes} 分钟 · ${plan.steps.length} 个动作',
                    style: TextStyle(fontSize: 14, color: stage.muted),
                  ),
                  const SizedBox(height: 10),
                  LayoutBuilder(
                    builder: (context, c) => Row(
                      children: [
                        for (final s in plan.steps.take(
                          ((c.maxWidth + 6) / 46).floor().clamp(0, 4),
                        ))
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: HipThumb(
                              size: 40,
                              radius: 10,
                              child: HipDrillArt(
                                drill: s.drill,
                                showPendingLabel: false,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              right: 18,
              bottom: 26,
              child: HipStartButton(
                key: _startKey,
                buttonKey: const ValueKey('start-today'),
                stage: stage,
                onTap: plan.steps.isEmpty ? null : () => _startPlan(plan),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _blockedHero() => HipPanel(
    borderColor: HipColors.tight.withValues(alpha: .5),
    child: SizedBox(
      height: 220,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          HipIcon(HipGlyph.clipboard, size: 48, color: HipColors.tight),
          const SizedBox(height: 14),
          const Text(
            '先问问医生或专业人士，再开始练习',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => HipOnboarding(store: store, review: true),
              ),
            ),
            child: const Text('重新选择安全提示'),
          ),
        ],
      ),
    ),
  );

  Widget _numbnessCard() => HipPanel(
    borderColor: HipColors.pain.withValues(alpha: .5),
    child: Row(
      children: [
        const Expanded(
          child: Text(
            '现在还麻吗？',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          ),
        ),
        TextButton(
          onPressed: () => store.answerNumbness(stillNumb: true),
          child: const Text('是'),
        ),
        TextButton(
          onPressed: () => store.answerNumbness(stillNumb: false),
          child: const Text('否'),
        ),
      ],
    ),
  );

  Widget _lockCard(HipDirection d) => HipPanel(
    borderColor: HipColors.tight.withValues(alpha: .5),
    child: Row(
      children: [
        HipIcon(HipGlyph.info, color: HipColors.tight),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            '${d.zh}方向连续不舒服，这周只做放松。建议问问医生或专业人士。',
            style: const TextStyle(fontSize: 14, height: 1.4),
          ),
        ),
      ],
    ),
  );

  Widget _chip(HipGlyph icon, String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: .45),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.white.withValues(alpha: .12)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        HipIcon(icon, size: 14, color: Colors.white70),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 12, color: Colors.white70)),
      ],
    ),
  );

  /// The two home pickers share one control style (round 2 #1): the control
  /// is its own card (radius 22, like its neighbours) and the thumb is
  /// concentric with it (22 − 5 = 17).
  Widget _durationPicker() => HipSegmented<int>(
    keyPrefix: 'minutes',
    standalone: true,
    height: 74,
    radius: 22,
    inset: 5,
    values: TrainingPlanner.durations,
    selected: store.minutes,
    onChanged: (v) => store.choose(minutes: v),
    itemBuilder: (v, fg, t) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$v',
          style: TextStyle(
            fontSize: 22,
            height: 1.15,
            fontWeight: FontWeight.w700,
            color: Color.lerp(HipColors.text, fg, t),
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        Text('分', style: TextStyle(fontSize: 11, height: 1.3, color: fg)),
      ],
    ),
  );

  Widget _scenePicker() => HipSegmented<HipScene>(
    keyPrefix: 'scene',
    standalone: true,
    height: 74,
    radius: 22,
    inset: 5,
    values: HipScene.values,
    selected: store.scene,
    onChanged: (v) => store.choose(scene: v),
    itemBuilder: (v, fg, t) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        HipIcon(
          v == HipScene.chair ? HipGlyph.chair : HipGlyph.home,
          size: 22,
          color: fg,
        ),
        const SizedBox(height: 3),
        Text(v.zh, style: TextStyle(fontSize: 11, height: 1.3, color: fg)),
      ],
    ),
  );

  Widget _streakCard() => HipPanel(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            HipIcon(
              HipGlyph.flame,
              size: 16,
              filled: true,
              color: HipColors.tight,
            ),
            SizedBox(width: 4),
            Text('连续', style: TextStyle(fontSize: 13, color: HipColors.muted)),
          ],
        ),
        const SizedBox(height: 4),
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '${store.streak}',
                    style: const TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  TextSpan(
                    text: ' 天',
                    style: TextStyle(fontSize: 15, color: HipColors.muted),
                  ),
                ],
              ),
            ),
          ),
        ),
        const Spacer(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (final (i, done) in store.week.indexed)
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done ? HipColors.jade : null,
                  border: Border.all(
                    color: done
                        ? HipColors.jade
                        : (i == 6 ? HipColors.jade : HipColors.faint),
                    width: 1.6,
                  ),
                ),
              ),
          ],
        ),
      ],
    ),
  );
}

// ───────────────────────── progress & settings ─────────────────────────

class HipProgressPage extends StatelessWidget {
  const HipProgressPage({super.key, required this.store});
  final HipStore store;

  @override
  Widget build(BuildContext context) {
    final result = store.latestResult;
    final reminder = store.reminder;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        const Text(
          '进度',
          style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 14),
        HipPanel(
          child: Row(
            children: [
              HipIcon(HipGlyph.flame, filled: true, color: HipColors.tight),
              const SizedBox(width: 10),
              Text(
                '连续 ${store.streak} 天',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                '共 ${store.doneDays.length} 天',
                style: TextStyle(color: HipColors.muted),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (result != null)
          HipPanel(
            child: Column(
              children: [
                Row(
                  children: [
                    Text('最近一次自测', style: TextStyle(color: HipColors.muted)),
                    const Spacer(),
                    Text(
                      '${result.level.name} · ${result.total}/12',
                      style: TextStyle(color: HipColors.jade),
                    ),
                  ],
                ),
                SizedBox(
                  height: 240,
                  child: HipRadar(
                    values: result.radar,
                    highlight: result.tightest.toSet(),
                    warn: result.painDirections,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        HipPanel(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  HipIcon(HipGlyph.bell, color: HipColors.jade),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      '久坐提醒',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Switch(
                    key: const ValueKey('reminder-switch'),
                    value: reminder.enabled,
                    onChanged: (v) =>
                        store.setReminder(reminder.copyWith(enabled: v)),
                  ),
                ],
              ),
              if (reminder.enabled) ...[
                Row(
                  children: [
                    const SizedBox(width: 34),
                    for (final m in [45, 60])
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text('$m 分钟'),
                          selected: reminder.intervalMinutes == m,
                          onSelected: (_) => store.setReminder(
                            reminder.copyWith(intervalMinutes: m),
                          ),
                        ),
                      ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(34, 6, 8, 8),
                  child: Text(
                    store.reminders.deliversNotifications
                        ? '工作日 ${reminder.startHour}:00–${reminder.endHour}:00 提醒，点开直接做 2 分钟椅边放松'
                        : '已记下提醒时间。系统通知将在接入通知组件后生效；现在可以在首页随时开始 2 分钟椅边放松。',
                    style: TextStyle(
                      fontSize: 12,
                      color: HipColors.muted,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
              ListTile(
                contentPadding: const EdgeInsets.only(left: 34, right: 8),
                title: const Text('2 分钟椅边放松'),
                trailing: const HipIcon(HipGlyph.chevronRight, size: 20),
                onTap: () {
                  final plan = store.microPlan;
                  if (plan == null) return;
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      fullscreenDialog: true,
                      builder: (_) => HipPlayerPage(store: store, plan: plan),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        HipVoiceSettingsPanel(store: store),
        const SizedBox(height: 12),
        HipAppearancePanel(store: store),
        const SizedBox(height: 12),
        HipPanel(
          padding: EdgeInsets.zero,
          child: ListTile(
            leading: HipIcon(HipGlyph.shield, color: HipColors.jade),
            title: const Text('重新看安全提示'),
            trailing: const HipIcon(HipGlyph.chevronRight, size: 20),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => HipOnboarding(store: store, review: true),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '这是运动练习，不能替代医生的建议。',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: HipColors.faint),
        ),
      ],
    );
  }
}

String reminderLabel(ReminderSettings r) =>
    r.enabled ? '每 ${r.intervalMinutes} 分钟' : '关闭';

// ───────────────────────── settings: voice + appearance ─────────────────────

Widget _settingsHeader(HipGlyph icon, String title, {String? hint}) => Padding(
  padding: const EdgeInsets.only(bottom: 10),
  child: Row(
    children: [
      HipIcon(icon, color: HipColors.jade),
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          title,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
      ),
      if (hint != null)
        Text(hint, style: TextStyle(fontSize: 12, color: HipColors.muted)),
    ],
  ),
);

/// 语音播报: voice on/off, chimes on/off, language, volume, preview (#13).
class HipVoiceSettingsPanel extends StatelessWidget {
  const HipVoiceSettingsPanel({super.key, required this.store});
  final HipStore store;

  @override
  Widget build(BuildContext context) {
    final v = store.voice;
    return HipPanel(
      key: const ValueKey('voice-settings'),
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _settingsHeader(HipGlyph.voice, '语音播报'),
          _switchRow(
            key: const ValueKey('voice-switch'),
            title: '人声口令',
            subtitle: '动作预告、倒数、换边、要点提醒',
            value: v.voice,
            onChanged: (x) => store.setVoice(v.copyWith(voice: x)),
          ),
          _switchRow(
            key: const ValueKey('chime-switch'),
            title: '提示音',
            subtitle: '开始、结束和倒数的“滴”声',
            value: v.chimes,
            onChanged: (x) => store.setVoice(v.copyWith(chimes: x)),
          ),
          const SizedBox(height: 8),
          Text('语言', style: TextStyle(fontSize: 13, color: HipColors.muted)),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: HipSegmented<VoiceLanguage>(
              keyPrefix: 'voice-lang',
              values: VoiceLanguage.values,
              selected: v.language,
              label: (l) => l.label,
              onChanged: (l) => store.setVoice(v.copyWith(language: l)),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              HipIcon(HipGlyph.volumeLow, size: 20, color: HipColors.muted),
              Expanded(
                child: Slider(
                  key: const ValueKey('voice-volume'),
                  value: v.volume,
                  onChanged: (x) => store.setVoice(v.copyWith(volume: x)),
                ),
              ),
              HipIcon(HipGlyph.volume, size: 20, color: HipColors.muted),
            ],
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              key: const ValueKey('voice-preview'),
              onPressed: v.voice || v.chimes ? () => _preview(context) : null,
              icon: const HipIcon(HipGlyph.today, size: 20),
              label: const Text('试听'),
            ),
          ),
        ],
      ),
    );
  }

  void _preview(BuildContext context) {
    final voice = HipVoice.of(context);
    final q = voice.queue();
    unawaited(voice.output.begin());
    final cues = [
      const VoiceCue(0, ['p.ready'], CuePriority.call),
      for (var k = 3; k >= 1; k--)
        VoiceCue(4.0 - k, ['chime.tick', 'n.$k'], CuePriority.count),
      const VoiceCue(4, ['chime.start', 'p.go'], CuePriority.call),
    ];
    final start = DateTime.now();
    var i = 0;
    Timer.periodic(const Duration(milliseconds: 50), (timer) {
      final t = DateTime.now().difference(start).inMilliseconds / 1000;
      while (i < cues.length && cues[i].at <= t) {
        q.submit(cues[i++], t);
      }
      q.tick(t);
      if (i >= cues.length && t > 6) timer.cancel();
    });
  }

  Widget _switchRow({
    required Key key,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 15)),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: HipColors.muted),
              ),
            ],
          ),
        ),
        Switch(key: key, value: value, onChanged: onChanged),
      ],
    ),
  );
}

/// 外观: 跟随系统 / 浅色 / 深色 (#14).
class HipAppearancePanel extends StatelessWidget {
  const HipAppearancePanel({super.key, required this.store});
  final HipStore store;
  @override
  Widget build(BuildContext context) => HipPanel(
    key: const ValueKey('appearance-settings'),
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _settingsHeader(HipGlyph.contrast, '外观'),
        HipSegmented<HipThemeChoice>(
          keyPrefix: 'theme',
          values: HipThemeChoice.values,
          selected: store.theme,
          label: (c) => c.zh,
          onChanged: store.setTheme,
        ),
      ],
    ),
  );
}
