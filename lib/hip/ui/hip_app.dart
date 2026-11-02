import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../coach/hip_coach_chat.dart';
import '../coach/usage_store.dart';
import '../control/hip_store.dart';
import '../data/hip_action_media_loader.dart';
import '../data/hip_content_loader.dart';
import '../domain/hip_models.dart';
import '../domain/hip_progress.dart';
import '../domain/hip_session.dart';
import '../voice/hip_voice.dart';
import '../voice/just_audio_output.dart';
import '../voice/session_script.dart';
import '../voice/voice_library.dart';
import 'hip_assessment_page.dart';
import 'hip_calm.dart';
import 'hip_icons.dart';
import 'hip_more_page.dart';
import 'hip_player_page.dart';
import 'hip_privacy_page.dart';
import 'hip_routes.dart';
import 'hip_segmented.dart';
import 'hip_theme.dart';
import 'hip_widgets.dart';
import 'library/library_actions.dart';

const hipAppName = '开胯训练助手';

/// Root of the HipLab app (entry: lib/main.dart).
class HipApp extends StatefulWidget {
  const HipApp({
    super.key,
    this.store,
    this.videoEnabled = true,
    this.voice,
    this.coach,
  });

  /// Injected in tests; otherwise loaded from assets + SharedPreferences.
  final HipStore? store;
  final bool videoEnabled;

  /// Injected in tests; otherwise real playback (silent when video is off,
  /// i.e. in widget tests).
  final HipVoice? voice;

  /// AI 定制 (docs/ai-coach.md). Injected in tests (SDK fake client);
  /// otherwise built from external configuration (unconfigured → hidden).
  final HipCoachChat? coach;

  @override
  State<HipApp> createState() => _HipAppState();
}

class _HipAppState extends State<HipApp> {
  late Future<(HipStore, HipVoice)> _loading = _load();

  Future<(HipStore, HipVoice)> _load() async {
    final store = widget.store ?? HipStore(content: await loadHipContent());
    if (widget.store == null) {
      await store.initialize();
      // 办公 by weekday daytime, 居家 otherwise, unless picked today
      // (home r1). Injected test stores keep the scene they were given.
      store.applyTimeScene();
    }
    HipMediaVariants.media = await loadHipActionMedia();
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
                ? HipHome(store: store, coach: widget.coach)
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
                color: HipColors.jadeText,
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
          style: TextStyle(fontSize: 12, color: HipColors.muted),
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
            color: HipColors.jadeText,
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
//
// Home redesign r1 (开哥 2026-11-02): not a dashboard. One scene switch,
// one recommended routine as a full-bleed picture, one 开始. Everything
// else lives in 「更多」 (top-right ⋯).

class HipHome extends StatefulWidget {
  const HipHome({super.key, required this.store, this.coach});
  final HipStore store;

  /// AI 定制 service; null = built from --dart-define.
  final HipCoachChat? coach;
  @override
  State<HipHome> createState() => _HipHomeState();
}

/// 首页 copy per routine: (kicker, title, how). Titles shorter than the
/// library names so the magazine headline stays on one line.
const _homeCopy = <String, (String, String, String)>{
  'A': ('椅子上就能做', '工位放松', '不用起身，不用换衣服'),
  'M': ('起身 2 分钟', '椅边放松', '站在椅子边就能做'),
  'B': ('铺张垫子', '睡前开胯', '躺着做，越做越松'),
  'C': ('铺张垫子', '晨起唤醒', '主动控制，把髋叫醒'),
  'D': ('铺张垫子', '久坐解压', '髋前侧、臀部和内旋'),
  'E': ('铺张垫子', '训练前激活', '跑步健身跳舞之前做'),
  'F': ('铺张垫子', 'Breaking 开胯', '面向 L 撑、风车'),
};

class _HipHomeState extends State<HipHome> {
  final _startKey = GlobalKey();
  HipStore get store => widget.store;

  /// 「换一套」 position per scene (this launch only).
  final _pick = <HipScene, int>{};

  /// 练习库: segment and filter survive leaving and reopening it.
  final _practice = PracticeMemory();

  /// AI 定制 conversation: survives leaving the page and a session.
  late final _coach = widget.coach ?? HipCoachChat(store: store);
  late final _library = LibraryActions(
    store: store,
    startPlan: _startPlan,
    coach: _coach,
  );

  @override
  void dispose() {
    _coach.dispose();
    super.dispose();
  }

  /// The player grows out of the 开始 button (container transform); from
  /// the assessment result, which has already closed, it rises.
  Future<void> _startPlan(
    TrainingPlan plan, {
    BuildContext? from,
    double radius = 31,
    Color? originColor,
  }) async {
    Widget page(BuildContext _) => HipPlayerPage(store: store, plan: plan);
    await Navigator.of(context).push(
      from == null
          ? HipRoute.rise<void>(page)
          : HipRoute.expandFrom<void>(
              from,
              page,
              radius: radius,
              color: originColor ?? HipColors.jade,
            ),
    );
  }

  /// The check grows out of whatever started it (a 「更多」 row).
  Future<void> _startAssessment({
    BuildContext? from,
    double radius = 28,
    Color? color,
  }) async {
    await Navigator.of(context).push(
      HipRoute.expandFrom<void>(
        from,
        (_) => HipAssessmentPage(store: store, onStartPlan: _startPlan),
        radius: radius,
        color: color ?? HipColors.jade,
      ),
    );
  }

  void _openMore() => Navigator.of(context).push(
    HipRoute.push<void>(
      (_) => HipMorePage(
        store: store,
        actions: _library,
        practice: _practice,
        onStartAssessment: _startAssessment,
      ),
    ),
  );

  HipRoutine? get _routine {
    final list = store.sceneRoutines(store.scene);
    if (list.isEmpty) return null;
    return list[(_pick[store.scene] ?? 0) % list.length];
  }

  void _rotate() =>
      setState(() => _pick[store.scene] = (_pick[store.scene] ?? 0) + 1);

  static const _weekdays = ['一', '二', '三', '四', '五', '六', '日'];

  String _greeting(DateTime now) {
    final h = now.hour;
    final part = h < 5
        ? '凌晨'
        : h < 9
        ? '早上'
        : h < 12
        ? '上午'
        : h < 14
        ? '中午'
        : h < 18
        ? '下午'
        : '晚上';
    final line = store.scene == HipScene.chair
        ? (h < 12 ? '别坐太久' : '坐了大半天了')
        : (h >= 20 || h < 5
              ? '睡前放松一下'
              : h < 10
              ? '先把髋叫醒'
              : '在家练一会儿');
    return '周${_weekdays[now.weekday - 1]}$part · $line';
  }

  @override
  Widget build(BuildContext context) {
    final routine = _routine;
    final plan = routine == null ? null : store.planForRoutine(routine);
    final hero = plan == null
        ? null
        : (plan.steps.where((s) => s.drill.poster != null).firstOrNull ??
                  plan.steps.firstOrNull)
              ?.drill;
    final alerts = [
      if (store.askNumbness) _numbnessCard(),
      for (final d in store.lockedDirections.keys) _lockCard(d),
    ];
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, c) {
          final top = MediaQuery.paddingOf(context).top;
          return Stack(
            fit: StackFit.expand,
            children: [
              if (hero != null)
                Positioned(
                  left: 0,
                  right: 0,
                  top: top + 70,
                  height: c.maxHeight * .6,
                  child: _HomeHeroArt(
                    drill: hero,
                    id: '${store.scene.id}-${routine!.id}',
                  ),
                ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 10, 24, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _topBar(),
                      const SizedBox(height: 16),
                      Center(child: _scenePicker()),
                      const Spacer(),
                      for (final a in alerts) ...[
                        a,
                        const SizedBox(height: 10),
                      ],
                      if (plan == null)
                        _blockedHero()
                      else
                        _headline(routine!, plan),
                      const SizedBox(height: 26),
                      _startButton(plan),
                      const SizedBox(height: 6),
                      SizedBox(
                        height: 40,
                        child:
                            store.sceneRoutines(store.scene).length > 1 &&
                                plan != null
                            ? Center(
                                child: TextButton(
                                  key: const ValueKey('home-rotate'),
                                  onPressed: _rotate,
                                  style: TextButton.styleFrom(
                                    foregroundColor: HipColors.muted,
                                    textStyle: const TextStyle(
                                      fontFamily: hipFontFamily,
                                      fontSize: 14,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                  child: const Text('换一套'),
                                ),
                              )
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _topBar() => Row(
    children: [
      Expanded(
        child: Row(
          children: [
            Flexible(
              child: Text(
                _greeting(store.now()),
                key: const ValueKey('home-greeting'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  letterSpacing: .5,
                  color: HipColors.muted,
                ),
              ),
            ),
            const SizedBox(width: 10),
            _streakChip(),
          ],
        ),
      ),
      const SizedBox(width: 12),
      HipCalmRoundButton(
        key: const ValueKey('home-more'),
        semanticLabel: '更多',
        onTap: _openMore,
        child: const HipMoreDots(),
      ),
    ],
  );

  /// 打卡: a tiny chip, not a panel.
  Widget _streakChip() => Semantics(
    label: '连续打卡 ${store.streak} 天',
    child: ExcludeSemantics(
      child: Container(
        key: const ValueKey('home-streak'),
        padding: const EdgeInsets.fromLTRB(7, 3, 9, 3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: HipColors.tight.withValues(alpha: HipColors.isDark ? .12 : .1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            HipIcon(
              HipGlyph.flame,
              size: 13,
              filled: true,
              color: HipColors.tight,
            ),
            const SizedBox(width: 3),
            Text(
              '${store.streak} 天',
              style: TextStyle(
                fontSize: 12,
                height: 1.2,
                fontWeight: FontWeight.w600,
                color: HipColors.tight,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _headline(HipRoutine r, TrainingPlan plan) {
    final (kicker, title, how) =
        _homeCopy[r.id] ?? (r.scene.zh, plan.title, r.audience);
    return AnimatedSwitcher(
      duration: HipCalmMotion.of(context, HipCalmMotion.swap),
      switchInCurve: HipCalmMotion.curve,
      switchOutCurve: HipCalmMotion.curve,
      layoutBuilder: (current, previous) => Stack(
        alignment: Alignment.bottomLeft,
        children: [...previous, ?current],
      ),
      child: Column(
        key: ValueKey('headline-${store.scene.id}-${r.id}'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            kicker,
            style: TextStyle(
              fontSize: 13,
              letterSpacing: 2,
              color: HipColors.jadeText,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            key: const ValueKey('home-title'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 34,
              height: 1.2,
              letterSpacing: 1,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${plan.minutes} 分钟 · $how',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 15, height: 1.4, color: HipColors.muted),
          ),
        ],
      ),
    );
  }

  Widget _startButton(TrainingPlan? plan) {
    final enabled = plan != null && plan.steps.isNotEmpty;
    final fill = enabled ? HipColors.jade : HipColors.surfaceHigh;
    final fg = enabled ? HipColors.onJade : HipColors.faint;
    return HipPressable(
      key: const ValueKey('start-today'),
      semanticLabel: '开始',
      scale: .98,
      onTap: enabled
          ? () => _startPlan(plan, from: _startKey.currentContext)
          : null,
      // Its own layer: the player's container transform starts from a
      // snapshot of this face (HipRoute.expandFrom).
      child: RepaintBoundary(
        key: _startKey,
        child: AnimatedContainer(
          duration: HipCalmMotion.of(context, HipCalmMotion.swap),
          height: 62,
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(31),
            boxShadow: enabled
                ? HipColors.shadows([
                    BoxShadow(
                      color: HipColors.jade.withValues(
                        alpha: HipColors.isDark ? .28 : .22,
                      ),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ])
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              HipIcon(HipGlyph.play, size: 20, filled: true, color: fg),
              const SizedBox(width: 8),
              Text(
                '开始',
                style: TextStyle(
                  fontSize: 19,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w700,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _blockedHero() => HipPanel(
    borderColor: HipColors.tight.withValues(alpha: .5),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        HipIcon(HipGlyph.clipboard, size: 40, color: HipColors.tight),
        const SizedBox(height: 12),
        const Text(
          '先问问医生或专业人士，再开始练习',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        TextButton(
          onPressed: () => Navigator.of(context).push(
            HipRoute.push<void>(
              (_) => HipOnboarding(store: store, review: true),
            ),
          ),
          child: const Text('重新选择安全提示'),
        ),
      ],
    ),
  );

  Widget _numbnessCard() => HipPanel(
    padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
    borderColor: HipColors.pain.withValues(alpha: .5),
    child: Row(
      children: [
        const Expanded(
          child: Text(
            '现在还麻吗？',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
    padding: const EdgeInsets.all(12),
    borderColor: HipColors.tight.withValues(alpha: .5),
    child: Row(
      children: [
        HipIcon(HipGlyph.info, size: 20, color: HipColors.tight),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            '${d.zh}方向连续不舒服，这周只做放松。建议问问医生或专业人士。',
            style: const TextStyle(fontSize: 13, height: 1.4),
          ),
        ),
      ],
    ),
  );

  /// 办公 | 居家, small and centred under the greeting.
  Widget _scenePicker() => SizedBox(
    width: 168,
    child: HipSegmented<HipScene>(
      keyPrefix: 'scene',
      height: 38,
      radius: 19,
      inset: 3,
      values: const [HipScene.chair, HipScene.home],
      selected: store.scene,
      label: (v) => v == HipScene.chair ? '办公' : '居家',
      onChanged: store.pickScene,
    ),
  );
}

/// The recommended routine's picture, full-bleed: soft radial vignette and
/// a long fade into the page at top and bottom, a faint jade glow under the
/// figure. Cross-fades (300ms) when the scene or routine changes.
class _HomeHeroArt extends StatelessWidget {
  const _HomeHeroArt({required this.drill, required this.id});
  final HipDrill drill;
  final String id;

  @override
  Widget build(BuildContext context) {
    final bg = HipColors.background;
    return RepaintBoundary(
      child: IgnorePointer(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Align(
              alignment: const Alignment(0, .1),
              child: FractionallySizedBox(
                widthFactor: .75,
                heightFactor: .6,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        HipColors.jade.withValues(
                          alpha: HipColors.isDark ? .16 : .1,
                        ),
                        HipColors.jade.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            AnimatedSwitcher(
              duration: HipCalmMotion.of(context, HipCalmMotion.swap),
              switchInCurve: HipCalmMotion.curve,
              switchOutCurve: HipCalmMotion.curve,
              layoutBuilder: (current, previous) => Stack(
                fit: StackFit.expand,
                children: [...previous, ?current],
              ),
              child: KeyedSubtree(
                key: ValueKey(id),
                child: HipDrillArt(
                  key: const ValueKey('home-hero'),
                  drill: drill,
                  showPendingLabel: false,
                  alignment: const Alignment(0, -.1),
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -.1),
                  radius: .9,
                  stops: const [.45, .95],
                  colors: [bg.withValues(alpha: 0), bg],
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0, .14, .5, .88],
                  colors: [
                    bg,
                    bg.withValues(alpha: 0),
                    bg.withValues(alpha: 0),
                    bg,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────── progress & settings ─────────────────────────

/// Which half of [HipProgressPage] to show: 「更多」 opens 训练记录 and 设置
/// as two pages; the AI coach's 设置 link still opens [all].
enum HipProgressSection { all, records, settings }

class HipProgressPage extends StatelessWidget {
  const HipProgressPage({
    super.key,
    required this.store,
    this.coach,
    this.section = HipProgressSection.all,
  });
  final HipStore store;
  final HipProgressSection section;

  /// Shows 「AI 定制用量」 in the settings when set (zh UI only).
  final HipCoachChat? coach;

  @override
  Widget build(BuildContext context) {
    final result = store.latestResult;
    final reminder = store.reminder;
    final tileKey = GlobalObjectKey(store);
    final records = section != HipProgressSection.settings;
    final settings = section != HipProgressSection.records;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        if (section == HipProgressSection.all) ...[
          const Text(
            '进度',
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
        ],
        if (records) ...[
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
                        style: TextStyle(color: HipColors.jadeText),
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
            )
          else if (section == HipProgressSection.records)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                '还没有自测记录。在「更多 · 髋部自测」花 3 分半测一次。',
                style: TextStyle(fontSize: 13, color: HipColors.muted),
              ),
            ),
          const SizedBox(height: 12),
        ],
        if (settings) ...[
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
                  Padding(
                    padding: const EdgeInsets.fromLTRB(34, 2, 8, 0),
                    child: SizedBox(
                      width: 220,
                      // The same tactile thumb as every other either/or
                      // choice (button audit 2026-10-18), not a Material chip.
                      child: HipSegmented<int>(
                        keyPrefix: 'reminder-interval',
                        height: 40,
                        radius: 12,
                        inset: 3,
                        values: const [45, 60],
                        selected: reminder.intervalMinutes,
                        label: (m) => '$m 分钟',
                        onChanged: (m) => store.setReminder(
                          reminder.copyWith(intervalMinutes: m),
                        ),
                      ),
                    ),
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
                RepaintBoundary(
                  key: tileKey,
                  child: ListTile(
                    contentPadding: const EdgeInsets.only(left: 34, right: 8),
                    title: const Text('2 分钟椅边放松'),
                    trailing: const HipIcon(HipGlyph.chevronRight, size: 20),
                    onTap: () {
                      final plan = store.microPlan;
                      if (plan == null) return;
                      Navigator.of(context).push(
                        HipRoute.expandFrom<void>(
                          tileKey.currentContext,
                          (_) => HipPlayerPage(store: store, plan: plan),
                          radius: 12,
                          // The row sits on its panel: grow from the panel's
                          // colour, not a lighter one (a frame-1 flash).
                          color: HipColors.surface,
                        ),
                      );
                    },
                  ),
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
                HipRoute.push<void>(
                  (_) => HipOnboarding(store: store, review: true),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          HipPanel(
            padding: EdgeInsets.zero,
            child: ListTile(
              key: const ValueKey('privacy-policy'),
              leading: HipIcon(HipGlyph.shield, color: HipColors.jade),
              title: const Text('隐私政策'),
              subtitle: const Text('离线阅读 · 数据保存在设备上'),
              trailing: const HipIcon(HipGlyph.chevronRight),
              onTap: () => Navigator.of(
                context,
              ).push(HipRoute.push<void>((_) => const HipPrivacyPage())),
            ),
          ),
        ],
        const SizedBox(height: 16),
        Text(
          '这是运动练习，不能替代医生的建议。',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: HipColors.muted),
        ),
      ],
    );
  }
}

/// 设置 ·「AI 定制用量」: calls and tokens on this device (usage.jsonl).
class HipCoachUsagePanel extends StatefulWidget {
  const HipCoachUsagePanel({super.key, required this.usage});
  final CoachUsageStore usage;
  @override
  State<HipCoachUsagePanel> createState() => _HipCoachUsagePanelState();
}

class _HipCoachUsagePanelState extends State<HipCoachUsagePanel> {
  late final Future<void> _loaded = widget.usage.load();
  @override
  Widget build(BuildContext context) => FutureBuilder<void>(
    future: _loaded,
    builder: (context, _) {
      final t = widget.usage.totals;
      return HipPanel(
        key: const ValueKey('coach-usage'),
        padding: EdgeInsets.zero,
        child: ListTile(
          leading: HipIcon(HipGlyph.bolt, color: HipColors.jade),
          title: const Text('AI 定制用量'),
          subtitle: Text(
            t.calls == 0
                ? '本机还没有调用过 AI'
                : '本机累计调用 ${t.calls} 次 · 输入 ${t.promptTokens} / 输出 ${t.completionTokens} token',
          ),
        ),
      );
    },
  );
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
          // The iOS base release only opens background audio for guided
          // exercise sessions. The shared settings preview has no session
          // lifetime, so do not expose it on iOS.
          if (Theme.of(context).platform != TargetPlatform.iOS)
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
