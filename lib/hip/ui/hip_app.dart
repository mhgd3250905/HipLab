import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:ugk_trainer_runtime/ugk_trainer.dart' as trainer;

import '../coach/hip_coach_chat.dart';
import '../coach/usage_store.dart';
import '../control/hip_store.dart';
import '../data/hip_action_media_loader.dart';
import '../data/hip_content_loader.dart';
import '../data/hip_public_media.dart';
import '../data/hip_shared_library.dart';
import '../data/hip_action_scope.dart';
import '../coach/hip_coach_profile.dart' show loadHipCoachCatalog;
import '../domain/hip_models.dart';
import '../domain/hip_progress.dart';
import '../domain/hip_session.dart';
import '../voice/hip_voice.dart';
import '../voice/just_audio_output.dart';
import '../voice/session_script.dart';
import '../voice/voice_library.dart';
import 'hip_assessment_page.dart';
import 'hip_calm.dart';
import 'hip_glass.dart';
import 'hip_icons.dart';
import 'hip_more_page.dart';
import 'hip_page_kit.dart';
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
    this.mediaPolicy,
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
  final trainer.TrainingMediaPolicy? mediaPolicy;

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
    HipPublicMedia.current = widget.mediaPolicy ?? await HipPublicMedia.load();
    HipSharedLibrary.current = hipSharedLibraryConfig(
      hipActionScope(
        store.content.publicCatalog ?? await loadHipCoachCatalog(),
      ),
    );
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
    builder: (context, child) {
      Widget content = HipMediaPolicy(
        videoEnabled: widget.videoEnabled,
        child: child!,
      );
      if (HipPublicMedia.current case final policy?) {
        content = trainer.TrainingMediaPolicyScope(
          policy: policy,
          child: content,
        );
      }
      return _PaletteScope(child: content);
    },
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
    final body = Padding(
      padding: EdgeInsets.fromLTRB(24, widget.review ? 4 : 12, 24, 20),
      child: HipFadeSwitcher(
        child: KeyedSubtree(
          key: ValueKey(_onIdentity ? 'identity' : 'card'),
          child: _onIdentity ? _identity(blocked) : _safetyCard(),
        ),
      ),
    );
    return Scaffold(
      body: SafeArea(
        // UI r2 (#9): opened again from 设置 it has a back and a title;
        // first launch keeps none (the cards must be answered).
        child: widget.review
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const HipNavBar(
                    key: ValueKey('safety-nav'),
                    title: '安全提示',
                  ),
                  Expanded(child: body),
                ],
              )
            : body,
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

  /// HipLab supplies the plan; the SDK owns trainer entry and media.
  Future<void> _startPlan(
    TrainingPlan plan, {
    BuildContext? from,
    double radius = 31,
    Color? originColor,
  }) async {
    final policy = HipPublicMedia.current;
    final first = plan.steps.firstOrNull?.drill.id;
    await trainer.TrainerLauncher.open<void>(
      context,
      builder: (_) => HipPlayerPage(store: store, plan: plan),
      firstPosterAsset: first == null ? null : policy?.posterAssetFor(first),
      mediaPolicy: policy,
      theme: HipSharedLibrary.theme(context),
      planActionIds: plan.steps.map((step) => step.drill.id),
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
        cover: _heroDrill == null
            ? null
            : HipPublicMedia.current?.posterAssetFor(_heroDrill!.id),
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

  HipDrill? get _heroDrill {
    final r = _routine;
    if (r == null) return null;
    final plan = store.planForRoutine(r);
    if (plan == null) return null;
    return (plan.steps.where((s) => s.drill.poster != null).firstOrNull ??
            plan.steps.firstOrNull)
        ?.drill;
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
    final canRotate = store.sceneRoutines(store.scene).length > 1;
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Full-bleed cover, edge to edge and under the status bar: the
          // text sits straight on it and the dock has something to blur.
          if (hero != null)
            Positioned.fill(
              child: _HomeHeroArt(
                drill: hero,
                id: '${store.scene.id}-${routine!.id}',
              ),
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: _topBar(),
                  ),
                  const Spacer(),
                  for (final a in alerts) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: a,
                    ),
                    const SizedBox(height: 10),
                  ],
                  if (plan == null)
                    _blockedHero()
                  else
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(child: _headline(routine!, plan)),
                          if (canRotate) ...[
                            const SizedBox(width: 12),
                            _rotateButton(),
                          ],
                        ],
                      ),
                    ),
                  const SizedBox(height: 20),
                  _dock(plan),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// The reference dock: one floating liquid-glass capsule (办公 / 居家 with
  /// a sliding inner pill, 更多) and, apart from it, the round jade glass
  /// 开始 — the only accent.
  Widget _dock(TrainingPlan? plan) {
    // m4 (开哥 19:17: "操作栏不要这么大，要精致有质感"): 54pt.
    const h = 54.0;
    final idle = HipColors.text.withValues(alpha: .62);
    return SizedBox(
      height: h,
      child: Row(
        children: [
          Expanded(
            child: HipGlass(
              key: const ValueKey('home-dock'),
              shape: HipGlassShape.capsule,
              blur: true,
              sigma: 20,
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  Expanded(flex: 2, child: _scenePicker(h - 8)),
                  Expanded(
                    child: HipPressable(
                      key: const ValueKey('home-more'),
                      semanticLabel: '更多',
                      onTap: _openMore,
                      scale: .94,
                      child: _dockItem(HipGlyph.grid, '更多', idle, 0),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (plan != null) ...[
            const SizedBox(width: 8),
            _startButton(plan, h),
          ],
        ],
      ),
    );
  }

  // FittedBox: at large text sizes (×2.0) the 46pt dock row would overflow by
  // a pixel; scale the glyph + label down instead (no change at ×1).
  Widget _dockItem(HipGlyph glyph, String label, Color fg, double t) => Center(
    child: FittedBox(
      fit: BoxFit.scaleDown,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          HipIcon(glyph, size: 20, filled: t > .5, color: fg),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            softWrap: false,
            style: TextStyle(
              fontSize: 10.5,
              height: 1.2,
              letterSpacing: .3,
              fontWeight: t > .5 ? FontWeight.w600 : FontWeight.w500,
              color: fg,
            ),
          ),
        ],
      ),
    ),
  );

  /// 换一套: a 32pt glass icon button beside the title (m4: no label).
  Widget _rotateButton() => HipGlassRoundButton(
    key: const ValueKey('home-rotate'),
    semanticLabel: '换一套',
    blur: true,
    size: 32,
    onTap: _rotate,
    child: HipIcon(HipGlyph.shuffle, size: 16, color: HipColors.text),
  );

  Widget _topBar() => Row(
    children: [
      Expanded(
        child: Text(
          _greeting(store.now()),
          key: const ValueKey('home-greeting'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13,
            height: 1.3,
            letterSpacing: .3,
            fontWeight: FontWeight.w500,
            color: HipColors.text.withValues(alpha: .72),
          ),
        ),
      ),
      const SizedBox(width: 12),
      _streakChip(),
    ],
  );

  /// 打卡: a tiny glass chip, not a panel.
  Widget _streakChip() => Semantics(
    label: '连续打卡 ${store.streak} 天',
    child: ExcludeSemantics(
      child: SizedBox(
        height: 24,
        child: HipGlass(
          key: const ValueKey('home-streak'),
          shape: HipGlassShape.capsule,
          radius: 12,
          blur: true,
          sigma: 14,
          shadow: false,
          padding: const EdgeInsets.fromLTRB(8, 0, 10, 0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              HipIcon(
                HipGlyph.flame,
                size: 12,
                filled: true,
                color: HipColors.tight,
              ),
              const SizedBox(width: 4),
              Text(
                '${store.streak} 天',
                style: TextStyle(
                  fontSize: 12,
                  height: 1.2,
                  fontWeight: FontWeight.w600,
                  color: HipColors.text,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
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
              fontSize: 11,
              height: 1.2,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w600,
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
              fontSize: 31,
              height: 1.12,
              letterSpacing: 1,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '${plan.minutes} 分钟',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: HipColors.text.withValues(alpha: .85),
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                TextSpan(text: '  ·  $how'),
              ],
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              letterSpacing: .2,
              color: HipColors.text.withValues(alpha: .7),
            ),
          ),
        ],
      ),
    );
  }

  /// 开始: the round jade glass button beside the dock.
  Widget _startButton(TrainingPlan plan, double size) => HipStartButton(
    key: _startKey,
    buttonKey: const ValueKey('start-today'),
    stage: HipColors.palette,
    size: size,
    glass: true,
    onTap: plan.steps.isEmpty
        ? null
        : () => _startPlan(
            plan,
            from: _startKey.currentContext,
            radius: size / 2,
            originColor: HipColors.jade,
          ),
  );

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

  /// 办公 | 居家 inside the dock: icon + label, the brighter inner pill
  /// slides between them.
  Widget _scenePicker(double height) => HipSegmented<HipScene>(
    keyPrefix: 'scene',
    glass: true,
    bare: true,
    duration: HipCalmMotion.swap,
    curve: HipCalmMotion.curve,
    height: height,
    radius: height / 2,
    inset: 0,
    values: const [HipScene.chair, HipScene.home],
    selected: store.scene,
    label: (v) => v == HipScene.chair ? '办公' : '居家',
    itemBuilder: (v, fg, t) => _dockItem(
      v == HipScene.chair ? HipGlyph.desk : HipGlyph.home,
      v == HipScene.chair ? '办公' : '居家',
      fg,
      t,
    ),
    onChanged: store.pickScene,
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
            // Faint jade glow low behind the figure (and the dock).
            Align(
              alignment: const Alignment(0, .62),
              child: FractionallySizedBox(
                widthFactor: 1,
                heightFactor: .5,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        HipColors.jade.withValues(
                          alpha: HipColors.isDark ? .2 : .12,
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
                  // Lower than centre: the head clears the greeting line.
                  alignment: const Alignment(0, .25),
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -.05),
                  radius: 1.1,
                  stops: const [.5, 1],
                  colors: [bg.withValues(alpha: 0), bg],
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  // Top: a scrim so the greeting reads over the head.
                  // Bottom: the title and how-to sit on a soft fade.
                  stops: const [0, .16, .5, .78, 1],
                  colors: [
                    bg.withValues(alpha: .9),
                    bg.withValues(alpha: 0),
                    bg.withValues(alpha: 0),
                    bg.withValues(alpha: .6),
                    bg.withValues(alpha: .8),
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
      padding: EdgeInsets.fromLTRB(
        20,
        section == HipProgressSection.settings ? 0 : 12,
        20,
        24,
      ),
      children: [
        if (section == HipProgressSection.all) ...[
          const Text(
            '进度',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),
        ],
        if (records) ...[
          HipFlatGroup(
            title: '坚持',
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 15, 4, 15),
                child: Row(
                  children: [
                    HipIcon(
                      HipGlyph.flame,
                      size: 18,
                      filled: true,
                      color: HipColors.tight,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '连续 ${store.streak} 天',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '共 ${store.doneDays.length} 天',
                      style: TextStyle(fontSize: 13, color: HipColors.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (result != null)
            HipFlatGroup(
              title: '最近一次自测',
              trailing: Text(
                '${result.level.name} · ${result.total}/12',
                style: TextStyle(fontSize: 12, color: HipColors.jadeText),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: SizedBox(
                    height: 210,
                    child: HipRadar(
                      values: result.radar,
                      highlight: result.tightest.toSet(),
                      warn: result.painDirections,
                    ),
                  ),
                ),
              ],
            )
          else if (section == HipProgressSection.records)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                '还没有自测记录。在「更多 · 髋部自测」花 3 分半测一次。',
                style: TextStyle(fontSize: 13, color: HipColors.muted),
              ),
            ),
          const SizedBox(height: 24),
        ],
        if (settings) ...[
          const HipSection('提醒', first: true),
          HipListGroup(
            key: const ValueKey('reminder-settings'),
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  HipListRow(
                    glyph: HipGlyph.bell,
                    title: '久坐提醒',
                    subtitle: !reminder.enabled
                        ? null
                        : store.reminders.deliversNotifications
                        ? '工作日 ${reminder.startHour}:00–${reminder.endHour}:00'
                        : '时间已记下，暂不推送系统通知',
                    trailing: _HipSmallSwitch(
                      child: Switch(
                        key: const ValueKey('reminder-switch'),
                        value: reminder.enabled,
                        onChanged: (v) =>
                            store.setReminder(reminder.copyWith(enabled: v)),
                      ),
                    ),
                  ),
                  if (reminder.enabled)
                    HipListSubRow(
                      label: '间隔',
                      child: SizedBox(
                        width: 156,
                        // The same tactile thumb as every other either/or
                        // choice (button audit 2026-10-18), not a Material chip.
                        child: HipSegmented<int>(
                          keyPrefix: 'reminder-interval',
                          height: 30,
                          radius: 8,
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
                ],
              ),
              RepaintBoundary(
                key: tileKey,
                child: HipListRow(
                  key: const ValueKey('micro-break'),
                  glyph: HipGlyph.chair,
                  title: '2 分钟椅边放松',
                  subtitle: '现在就做一组，不用起身',
                  onTap: () {
                    final plan = store.microPlan;
                    if (plan == null) return;
                    final policy = HipPublicMedia.current;
                    final first = plan.steps.firstOrNull?.drill.id;
                    trainer.TrainerLauncher.open<void>(
                      context,
                      builder: (_) => HipPlayerPage(store: store, plan: plan),
                      firstPosterAsset: first == null
                          ? null
                          : policy?.posterAssetFor(first),
                      mediaPolicy: policy,
                      theme: HipSharedLibrary.theme(context),
                      planActionIds: plan.steps.map((step) => step.drill.id),
                    );
                  },
                ),
              ),
            ],
          ),
          HipVoiceSettingsPanel(store: store),
          HipAppearancePanel(store: store),
          const HipSection('其他'),
          HipListGroup(
            children: [
              HipListRow(
                key: const ValueKey('safety-review'),
                glyph: HipGlyph.shield,
                title: '重新看安全提示',
                onTap: () => Navigator.of(context).push(
                  HipRoute.push<void>(
                    (_) => HipOnboarding(store: store, review: true),
                  ),
                ),
              ),
              HipListRow(
                key: const ValueKey('privacy-policy'),
                glyph: HipGlyph.clipboard,
                title: '隐私政策',
                subtitle: '离线阅读 · 数据保存在设备上',
                onTap: () => Navigator.of(
                  context,
                ).push(HipRoute.push<void>((_) => const HipPrivacyPage())),
              ),
            ],
          ),
          const SizedBox(height: 12),
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

/// 设置 as its own page (UI r2): [HipNavBar] + the grouped settings list.
/// Opened from 更多 and from the AI coach.
class HipSettingsPage extends StatelessWidget {
  const HipSettingsPage({super.key, required this.store});
  final HipStore store;
  @override
  Widget build(BuildContext context) => HipNavPage(
    title: '设置',
    // A pushed route is not rebuilt by the app root: follow the store so
    // switches and choices show their new state.
    body: ListenableBuilder(
      listenable: store,
      builder: (_, _) =>
          HipProgressPage(store: store, section: HipProgressSection.settings),
    ),
  );
}

String reminderLabel(ReminderSettings r) =>
    r.enabled ? '每 ${r.intervalMinutes} 分钟' : '关闭';

// ───────────────────────── settings: voice + appearance ─────────────────────

/// 语音播报: voice on/off, chimes on/off, language, volume, preview (#13).
class HipVoiceSettingsPanel extends StatelessWidget {
  const HipVoiceSettingsPanel({super.key, required this.store});
  final HipStore store;

  @override
  Widget build(BuildContext context) {
    final v = store.voice;
    // The iOS base release only opens background audio for guided
    // exercise sessions. The shared settings preview has no session
    // lifetime, so do not expose it on iOS.
    final preview = Theme.of(context).platform != TargetPlatform.iOS;
    return Column(
      key: const ValueKey('voice-settings'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const HipSection('语音播报'),
        HipListGroup(
          children: [
            HipListRow(
              glyph: HipGlyph.voice,
              title: '人声口令',
              subtitle: '动作预告、倒数、换边、要点提醒',
              trailing: _HipSmallSwitch(
                child: Switch(
                  key: const ValueKey('voice-switch'),
                  value: v.voice,
                  onChanged: (x) => store.setVoice(v.copyWith(voice: x)),
                ),
              ),
            ),
            HipListRow(
              glyph: HipGlyph.today,
              title: '提示音',
              subtitle: '开始、结束和倒数的“滴”声',
              trailing: _HipSmallSwitch(
                child: Switch(
                  key: const ValueKey('chime-switch'),
                  value: v.chimes,
                  onChanged: (x) => store.setVoice(v.copyWith(chimes: x)),
                ),
              ),
            ),
            HipListRow(
              glyph: HipGlyph.subtitles,
              title: '语言',
              trailing: SizedBox(
                width: 196,
                child: HipSegmented<VoiceLanguage>(
                  keyPrefix: 'voice-lang',
                  height: 30,
                  radius: 8,
                  values: VoiceLanguage.values,
                  selected: v.language,
                  label: (l) => l.label,
                  onChanged: (l) => store.setVoice(v.copyWith(language: l)),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(kHipRowPad, 6, 4, 6),
              child: Row(
                children: [
                  const HipRowIcon(HipGlyph.volume),
                  const SizedBox(width: 12),
                  Text(
                    '音量',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: HipColors.text,
                    ),
                  ),
                  Expanded(
                    child: Slider(
                      key: const ValueKey('voice-volume'),
                      value: v.volume,
                      onChanged: (x) => store.setVoice(v.copyWith(volume: x)),
                    ),
                  ),
                  if (preview)
                    Tooltip(
                      message: '试听',
                      child: HipPressable(
                        key: const ValueKey('voice-preview'),
                        semanticLabel: '试听',
                        scale: .9,
                        onTap: v.voice || v.chimes
                            ? () => _preview(context)
                            : null,
                        child: SizedBox.square(
                          dimension: 44,
                          child: Center(
                            child: HipIcon(
                              HipGlyph.play,
                              size: 16,
                              filled: true,
                              color: v.voice || v.chimes
                                  ? HipColors.jadeText
                                  : HipColors.faint,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ],
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
}

/// 外观: 跟随系统 / 浅色 / 深色 (#14).
class HipAppearancePanel extends StatelessWidget {
  const HipAppearancePanel({super.key, required this.store});
  final HipStore store;
  @override
  Widget build(BuildContext context) => Column(
    key: const ValueKey('appearance-settings'),
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const HipSection('外观'),
      HipListGroup(
        children: [
          HipListRow(
            glyph: HipGlyph.contrast,
            title: '颜色',
            trailing: SizedBox(
              width: 210,
              child: HipSegmented<HipThemeChoice>(
                keyPrefix: 'theme',
                height: 30,
                radius: 8,
                values: HipThemeChoice.values,
                selected: store.theme,
                label: (c) => c.zh,
                onChanged: store.setTheme,
              ),
            ),
          ),
        ],
      ),
    ],
  );
}

/// m5: Material's switch at ~80 % — proportionate to 15 pt rows.
class _HipSmallSwitch extends StatelessWidget {
  const _HipSmallSwitch({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 44,
    height: 28,
    child: FittedBox(fit: BoxFit.contain, child: child),
  );
}
