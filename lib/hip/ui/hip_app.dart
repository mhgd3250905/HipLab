import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:ugk_trainer_runtime/ugk_trainer.dart' as trainer;

import '../coach/hip_coach_chat.dart';
import '../control/hip_ai_consent.dart';
import '../control/hip_membership.dart';
import '../control/hip_store.dart';
import '../data/hip_action_media_loader.dart';
import '../data/hip_content_loader.dart';
import '../data/hip_public_media.dart';
import '../data/hip_shared_library.dart';
import '../data/hip_action_scope.dart';
import '../coach/hip_coach_profile.dart' show loadHipCoachCatalog;
import '../domain/hip_models.dart';
import '../domain/hip_settings.dart';
import '../domain/hip_progress.dart' show dayKey;
import '../domain/hip_session.dart';
import '../voice/hip_voice.dart';
import '../voice/just_audio_output.dart';
import '../voice/session_script.dart';
import '../voice/voice_library.dart';
import '../voice/voice_queue.dart';
import 'hip_ai_consent_scope.dart';
import 'hip_assessment_page.dart';
import 'hip_calm.dart';
import 'hip_glass.dart';
import 'hip_icons.dart';
import 'hip_home_action_deck.dart';
import 'hip_home_routine_folder.dart';
import 'hip_membership_scope.dart';
import 'hip_more_page.dart';
import 'hip_page_kit.dart';
import 'hip_player_page.dart';
import 'hip_privacy_page.dart';
import 'hip_records_page.dart';
import 'hip_routes.dart';
import 'hip_segmented.dart';
import 'hip_theme.dart';
import 'hip_text.dart';
import 'hip_widgets.dart';
import 'library/lib_text.dart';
import 'library/library_actions.dart';
import 'library/practice_page.dart';
import 'hip_content_text.dart';
import 'library/library_widgets.dart' show drillPoint;

const hipAppName = '开胯训练助手';

/// Root of the HipLab app (entry: lib/main.dart).
class HipApp extends StatefulWidget {
  const HipApp({
    super.key,
    this.store,
    this.videoEnabled = true,
    this.voice,
    this.coach,
    this.membership,
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
  final HipMembership? membership;
  final trainer.TrainingMediaPolicy? mediaPolicy;

  @override
  State<HipApp> createState() => _HipAppState();
}

class _HipAppState extends State<HipApp> {
  final _audioRoutes = RouteObserver<ModalRoute<dynamic>>();
  late final _aiConsent = widget.coach?.consent ?? HipAiConsent();
  HipLanguage _loadingLanguage = HipLanguage.zh;
  late Future<(HipStore, HipVoice)> _loading = _load();

  AppLifecycleListener? _membershipLifecycle;

  @override
  void initState() {
    super.initState();
    if (widget.membership case final membership?) {
      unawaited(membership.refresh());
      _membershipLifecycle = AppLifecycleListener(
        onResume: () => unawaited(membership.refresh()),
      );
    }
  }

  @override
  void dispose() {
    _membershipLifecycle?.dispose();
    widget.membership?.dispose();
    super.dispose();
  }

  Future<(HipStore, HipVoice)> _load() async {
    final store = widget.store ?? HipStore(content: await loadHipContent());
    if (widget.store == null) {
      await store.initialize();
      // 办公 by weekday daytime, 居家 otherwise, unless picked today
      // (home r1). Injected test stores keep the scene they were given.
      store.applyTimeScene();
    }
    _loadingLanguage = store.language;
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
      final lib = await VoiceLibrary.load();
      voice = HipVoice(
        lib: lib,
        output: JustAudioVoiceOutput(),
        settingsOf: () => store.voice,
        online: await trainer.withPoseHubCatalogVoice(
          lib,
          catalog: HipPublicMedia.current!.catalog,
        ),
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
              ? Builder(
                  builder: (errorContext) => Scaffold(
                    body: Center(
                      child: TextButton(
                        onPressed: () => setState(() => _loading = _load()),
                        child: Text(
                          HipText.of(
                            errorContext,
                          ).pick("读取失败，点一下重试", "Could not load. Tap to retry."),
                        ),
                      ),
                    ),
                  ),
                )
              : const Scaffold(body: SizedBox.expand()),
          language: widget.store?.language ?? _loadingLanguage,
        );
      }
      final (store, voice) = loaded;
      return ListenableBuilder(
        listenable: store,
        builder: (context, _) => HipVoiceScope(
          voice: voice,
          child: _shell(
            _mode(store.theme),
            HipHome(
              store: store,
              coach: widget.coach,
              membership: widget.membership,
              aiConsent: _aiConsent,
            ),
            language: store.language,
          ),
        ),
      );
    },
  );

  Widget _shell(
    ThemeMode mode,
    Widget home, {
    HipLanguage language = HipLanguage.zh,
  }) => MaterialApp(
    navigatorObservers: [
      if (defaultTargetPlatform == TargetPlatform.iOS) _audioRoutes,
    ],
    onGenerateTitle: (context) =>
        HipText.of(context).pick(hipAppName, 'HipLab · Hip Mobility'),
    debugShowCheckedModeBanner: false,
    theme: hipTheme(HipPalette.light),
    darkTheme: hipTheme(HipPalette.dark),
    themeMode: mode,
    themeAnimationDuration: Duration.zero,
    locale: language == HipLanguage.system ? null : Locale(language.id),
    supportedLocales: const [Locale('zh'), Locale('en')],
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
      if (widget.membership case final membership?) {
        content = HipMembershipScope(membership: membership, child: content);
      }
      return _PaletteScope(
        child: HipAiConsentScope(consent: _aiConsent, child: content),
      );
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

// ───────────────────────── home ─────────────────────────
//
// Home redesign r1 (开哥 2026-11-02): not a dashboard. One scene switch,
// one recommended routine as a full-bleed picture, one 开始. Everything
// else lives in 「更多」 (top-right ⋯).

class HipHome extends StatefulWidget {
  const HipHome({
    super.key,
    required this.store,
    this.coach,
    this.membership,
    this.aiConsent,
  });
  final HipStore store;

  /// AI 定制 service; null = built from --dart-define.
  final HipCoachChat? coach;
  final HipMembership? membership;
  final HipAiConsent? aiConsent;
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
  bool _recordsOpening = false;
  HipStore get store => widget.store;

  AssetBundle? _posterBundle;
  int? _posterDecodeWidth;
  final _warmedPlanPosters = <String>{};

  // Warm only selectable plans' first covers, using the exact key TrainerPoster
  // will resolve. A cold image decode must not add a blank frame to scene swaps.
  void _warmPlanPosters() {
    final policy = HipPublicMedia.current;
    if (policy == null) return;
    final bundle = DefaultAssetBundle.of(context);
    final width = trainer.TrainingPosterImages.decodeWidth(context);
    if (!identical(bundle, _posterBundle) || width != _posterDecodeWidth) {
      _posterBundle = bundle;
      _posterDecodeWidth = width;
      _warmedPlanPosters.clear();
    }
    for (final scene in HipScene.values) {
      for (final id in store.homeRoutines(scene)) {
        final first = store.planForHomeRoutine(id)?.steps.firstOrNull;
        final asset = first == null
            ? null
            : policy.posterAssetFor(first.drill.id);
        if (asset == null || !_warmedPlanPosters.add(asset)) continue;
        precacheImage(
          trainer.TrainingPosterImages.provider(asset, width, bundle: bundle),
          context,
          onError: (_, _) {
            if (identical(bundle, _posterBundle) &&
                width == _posterDecodeWidth) {
              _warmedPlanPosters.remove(asset);
            }
          },
        ).ignore();
      }
    }
  }

  /// 练习库: segment and filter survive leaving and reopening it.
  final _practice = PracticeMemory();

  /// AI 定制 conversation: survives leaving the page and a session.
  late final _coach =
      widget.coach ??
      HipCoachChat(
        store: store,
        membership: widget.membership,
        consent: widget.aiConsent,
      );
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
      planActionIds: HipMediaPolicy.of(context)
          ? plan.steps.map((step) => step.drill.id)
          : const [],
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
    HipRoute.content<void>(
      (_) => HipMorePage(
        store: store,
        cover: _heroDrill == null
            ? null
            : HipPublicMedia.current?.posterAssetFor(_heroDrill!.id),
        actions: _library,
        practice: _practice,
        onStartAssessment: _startAssessment,
      ),
      // 首页没有返回键，更多页的返回键随页面滑入，不能先钉在左上角。
      pinLeading: false,
    ),
  );

  Future<void> _openRecords() async {
    if (_recordsOpening) return;
    _recordsOpening = true;
    final route = HipRoute.content<void>(
      (_) => HipNavPage(
        title: HipText.of(context).pick("训练记录", "Training history"),
        leadingKey: const ValueKey('home-records-back'),
        bodyScrollsUnderBar: true,
        body: ListenableBuilder(
          listenable: store,
          builder: (context, _) {
            final plan = _plan;
            return HipProgressPage(
              store: store,
              section: HipProgressSection.records,
              onStartPractice: plan == null || plan.steps.isEmpty
                  ? null
                  : () => _startPlan(plan),
            );
          },
        ),
      ),
      // Home has no back chip: the destination's chip enters with its page.
      pinLeading: false,
    );
    try {
      await Navigator.of(context).push<void>(route);
      await route.completed;
    } finally {
      _recordsOpening = false;
    }
  }

  /// The selected 首页 folder entry for the current scene, persisted.
  String? get _routineId => store.homeRoutineId(store.scene);

  TrainingPlan? get _plan {
    final id = _routineId;
    return id == null ? null : store.planForHomeRoutine(id);
  }

  HipDrill? get _heroDrill {
    final plan = _plan;
    if (plan == null) return null;
    return (plan.steps.where((s) => s.drill.poster != null).firstOrNull ??
            plan.steps.firstOrNull)
        ?.drill;
  }

  static const _weekdays = ['一', '二', '三', '四', '五', '六', '日'];

  String _greeting(DateTime now) {
    final h = now.hour;
    if (HipText.of(context).isEn) {
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      final line = store.scene == HipScene.chair
          ? (h < 12 ? 'Time to move' : 'Take a movement break')
          : (h >= 20 || h < 5
                ? 'Unwind before bed'
                : h < 10
                ? 'Wake up your hips'
                : 'A little movement at home');
      return '${days[now.weekday - 1]} · $line';
    }
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
    _warmPlanPosters();
    final routineId = _routineId ?? '';
    final plan = _plan;
    final alerts = [
      if (store.askNumbness) _numbnessCard(),
      for (final d in store.lockedDirections.keys) _lockCard(d),
    ];
    // The folder stays visible with just one 套路 because it also holds the
    // 「训练组选择」 entry.
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          key: const ValueKey('home-page-header'),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: _topBar(),
        ),
        for (final a in alerts) ...[
          Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: a),
          const SizedBox(height: 10),
        ],
        if (plan != null && plan.steps.isNotEmpty) ...[
          const SizedBox(height: 20),
          Expanded(
            // Tight intrinsic height establishes the scroll floor.
            // Expanded still gets all additional viewport space.
            child: SizedBox(
              height: HipHomeActionDeck.minimumHeight(plan.steps.length),
              child: HipHomeActionDeck(
                key: const ValueKey('home-deck'),
                identity: '${dayKey(store.now())}/${store.scene.id}/$routineId',
                drills: [for (final step in plan.steps) step.drill],
                doses: [
                  for (final step in plan.steps)
                    HipContentText.of(context).text(step.dose),
                ],
                cues: [
                  for (final step in plan.steps)
                    HipContentText.of(context).text(step.tip),
                ],
                descriptions: [
                  for (final step in plan.steps)
                    drillPoint(
                      store.content,
                      step.drill,
                      HipText.of(context).languageTag,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
        ] else
          const Spacer(),
        Padding(
          key: const ValueKey('home-routine-section'),
          padding: const EdgeInsets.only(left: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (plan != null)
                Expanded(child: _headline(routineId, plan))
              else
                Expanded(
                  child: Text(
                    LibText.of(context).homeFolderEmpty,
                    key: const ValueKey('home-title'),
                    style: TextStyle(fontSize: 15, color: HipColors.muted),
                  ),
                ),
              const SizedBox(width: 12),
              _routineFolder(),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _dock(plan),
      ],
    );
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const HipPageBackdrop(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 6, bottom: 18),
              child: LayoutBuilder(
                builder: (context, viewport) => SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: viewport.maxHeight,
                      ),
                      child: IntrinsicHeight(child: content),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dock(TrainingPlan? plan) => SizedBox(
    height: 52,
    child: Row(
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: 274,
              height: 48,
              child: HipGlass(
                key: const ValueKey('home-dock'),
                shape: HipGlassShape.capsule,
                blur: true,
                sigma: 20,
                dock: true,
                padding: const EdgeInsets.all(6),
                child: Row(
                  children: [
                    Expanded(flex: 2, child: _scenePicker(36)),
                    Expanded(
                      child: HipPressable(
                        key: const ValueKey('home-more'),
                        semanticLabel: HipText.of(context).pick('更多', 'More'),
                        onTap: _openMore,
                        scale: .94,
                        child: _dockItem(
                          HipGlyph.grid,
                          HipText.of(context).pick('更多', 'More'),
                          HipColors.muted,
                          0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (plan != null) ...[const SizedBox(width: 6), _startButton(plan, 52)],
      ],
    ),
  );

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
              fontWeight: t > .5 ? FontWeight.w700 : FontWeight.w500,
              color: fg,
            ),
          ),
        ],
      ),
    ),
  );

  String _sceneLabel(HipScene scene) => scene == HipScene.chair
      ? HipText.of(context).pick("办公", "Office")
      : HipText.of(context).pick("居家", "Home");

  /// The folder lists only the 编排套路 / 我的训练组 added to the current
  /// scene's 首页 folder. A plan the profile emptied is not offered.
  List<HipHomeRoutineChoice> _folderChoices() => [
    for (final id in store.homeRoutines(store.scene))
      if (store.planForHomeRoutine(id) case final plan?
          when plan.steps.isNotEmpty)
        HipHomeRoutineChoice(
          id: id,
          sceneLabel: _sceneLabel(store.scene),
          title: _homeDisplay(id).$2,
          subtitle: _homeDisplay(id).$3,
          minutes: plan.minutes,
          drills: [for (final step in plan.steps) step.drill],
        ),
  ];

  Widget _routineFolder() => HipHomeRoutineFolder(
    key: const ValueKey('home-rotate'),
    sceneLabel: _sceneLabel(store.scene),
    selectedId: _routineId ?? '',
    choices: _folderChoices(),
    onChooseGroups: _openGroupsForHome,
    onSelected: (id) async {
      if (!mounted || _routineId == id) return;
      await store.pickSceneRoutine(store.scene, id);
    },
  );

  /// 「训练组选择」: 训练组 opens on 推荐套路 with the current scene's add
  /// controls in view; changes are live via the store listener.
  void _openGroupsForHome() {
    _practice.segment = 1;
    Navigator.of(context).push(
      HipRoute.content<void>(
        (_) => PracticePage(
          actions: _library,
          memory: _practice,
          homeScene: store.scene,
          onStartAssessment: _startAssessment,
        ),
      ),
    );
  }

  Widget _topBar() => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _greeting(store.now()),
              key: const ValueKey('home-greeting'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.3,
                color: HipColors.muted,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              HipText.of(context).pick('今天练一会儿', 'A little movement today'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w700,
                height: 1.2,
                color: HipColors.text,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(width: 12),
      _streakChip(),
    ],
  );

  Widget _streakChip() => HipPressable(
    key: const ValueKey('home-streak-button'),
    semanticLabel: HipText.of(context).pick(
      '连续打卡 ${store.streak} 天，查看训练记录',
      '${store.streak}-day streak. View training history',
    ),
    onTap: _openRecords,
    scale: .96,
    child: ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      child: Center(
        widthFactor: 1,
        heightFactor: 1,
        child: SizedBox(
          key: const ValueKey('home-streak'),
          width: 56,
          height: 26,
          child: HipCard(
            radius: 13,
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      HipIcon(
                        HipGlyph.flame,
                        size: 13,
                        filled: true,
                        color: HipColors.tight,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        HipText.of(context).pick(
                          '${store.streak} 天',
                          "${store.streak} ${store.streak == 1 ? 'day' : 'days'}",
                        ),
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.2,
                          fontWeight: FontWeight.w700,
                          color: HipColors.text,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
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
  );

  (String, String, String) _homeDisplay(String id) {
    // 我的训练组 entries have no authored home copy: use the group name and
    // its move count, in both languages.
    final group = store.customRoutine(id);
    if (group != null) {
      final t = LibText.of(context);
      return (
        t.isEn ? 'MY GROUP' : '我的训练组',
        group.name,
        t.isEn
            ? '${t.movesCount(group.steps.length)} · ${t.duration(group.seconds(store.content))}'
            : '${t.movesCount(group.steps.length)} · ${t.duration(group.seconds(store.content))}',
      );
    }
    final r = store.content.routines.where((x) => x.id == id).firstOrNull;
    if (r == null) return ('', '', '');
    if (!HipText.of(context).isEn) {
      return _homeCopy[r.id] ?? (r.scene.zh, r.name, r.audience);
    }
    return switch (r.id) {
      'A' => ('STAY SEATED', 'Office Reset', 'No need to leave your chair'),
      'M' => (
        'TAKE TWO MINUTES',
        'Chair-Side Break',
        'A little space beside your chair',
      ),
      'B' => (
        'ROLL OUT A MAT',
        'Bedtime Unwind',
        'Lie down and gently ease into it',
      ),
      'C' => (
        'ROLL OUT A MAT',
        'Morning Mobility',
        'Wake up your hips with active control',
      ),
      'D' => (
        'ROLL OUT A MAT',
        'After-Sitting Relief',
        'Hip front, glutes and internal rotation',
      ),
      'E' => (
        'ROLL OUT A MAT',
        'Pre-Workout Activation',
        'Before a run, workout or dance session',
      ),
      'F' => (
        'ROLL OUT A MAT',
        'Breaking Hip Mobility',
        'For L-sits and windmills',
      ),
      _ => (
        LibText.of(context).scene(r.scene),
        HipContentText.of(context).routineName(r),
        HipContentText.of(context).routineAudience(r),
      ),
    };
  }

  Widget _headline(String id, TrainingPlan plan) {
    final (kicker, title, how) = _homeDisplay(id);
    return AnimatedSwitcher(
      duration: HipCalmMotion.of(context, HipCalmMotion.swap),
      switchInCurve: HipCalmMotion.curve,
      switchOutCurve: HipCalmMotion.curve,
      layoutBuilder: (current, previous) => Stack(
        alignment: Alignment.bottomLeft,
        children: [...previous, ?current],
      ),
      child: Column(
        key: ValueKey('headline-${store.scene.id}-$id'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            kicker,
            style: TextStyle(
              fontSize: 10,
              height: 1.2,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w700,
              color: HipColors.jade,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            key: const ValueKey('home-title'),
            maxLines: HipText.of(context).isEn ? 2 : 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 27,
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
                  text: HipText.of(
                    context,
                  ).pick('${plan.minutes} 分钟', '${plan.minutes} min'),
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: HipColors.muted,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                TextSpan(text: '  ·  $how'),
              ],
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              letterSpacing: .2,
              color: HipColors.muted,
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
    flatDisc: true,
    onTap: plan.steps.isEmpty
        ? null
        : () => _startPlan(
            plan,
            from: _startKey.currentContext,
            radius: size / 2,
            originColor: HipColors.primaryAction,
          ),
  );

  Widget _numbnessCard() => HipPanel(
    padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
    borderColor: HipColors.pain.withValues(alpha: .5),
    child: Row(
      children: [
        Expanded(
          child: Text(
            HipText.of(context).pick("现在还麻吗？", "Still feeling numb?"),
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        TextButton(
          onPressed: () => store.answerNumbness(stillNumb: true),
          child: Text(HipText.of(context).pick("是", "Yes")),
        ),
        TextButton(
          onPressed: () => store.answerNumbness(stillNumb: false),
          child: Text(HipText.of(context).pick("否", "No")),
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
            HipText.of(context).pick(
              '${d.zh}方向连续不舒服，这周只做放松。建议问问医生或专业人士。',
              'Repeated discomfort with ${LibText.of(context).area(d).toLowerCase()}. Keep to relaxation this week and ask a doctor or qualified professional.',
            ),
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
    accentSelection: true,
    duration: HipCalmMotion.swap,
    curve: HipCalmMotion.curve,
    height: height,
    radius: height / 2,
    inset: 0,
    values: const [HipScene.chair, HipScene.home],
    selected: store.scene,
    label: (v) => v == HipScene.chair
        ? HipText.of(context).pick("办公", "Office")
        : HipText.of(context).pick("居家", "Home"),
    itemBuilder: (v, fg, t) => _dockItem(
      v == HipScene.chair ? HipGlyph.desk : HipGlyph.home,
      v == HipScene.chair
          ? HipText.of(context).pick("办公", "Office")
          : HipText.of(context).pick("居家", "Home"),
      fg,
      t,
    ),
    onChanged: store.pickScene,
  );
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
    this.onStartPractice,
  });
  final HipStore store;
  final HipProgressSection section;

  /// Shows 「AI 定制用量」 in the settings when set (zh UI only).
  final HipCoachChat? coach;

  /// 训练记录 empty state's action (start today's training).
  final VoidCallback? onStartPractice;

  @override
  Widget build(BuildContext context) {
    final reminder = store.reminder;
    if (section == HipProgressSection.records) {
      return HipRecordsView(store: store, onStartPractice: onStartPractice);
    }
    final tileKey = GlobalObjectKey(store);
    final records = section != HipProgressSection.settings;
    final settings = section != HipProgressSection.records;
    return ListView(
      padding: EdgeInsets.fromLTRB(20, hipNavInset(context) + 12, 20, 24),
      children: [
        if (section == HipProgressSection.all) ...[
          Text(
            HipText.of(context).pick("进度", "Progress"),
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),
        ],
        if (records) ...[
          // UI r2 M4: the achievement view; the radar moved to 自测.
          HipRecordsView(store: store, embedded: true),
          const SizedBox(height: 24),
        ],
        if (settings) ...[
          HipListGroup(
            key: const ValueKey('reminder-settings'),
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  HipListRow(
                    glyph: HipGlyph.bell,
                    title: HipText.of(context).pick("久坐提醒", "Move reminders"),
                    subtitle: !reminder.enabled
                        ? null
                        : store.reminders.deliversNotifications
                        ? HipText.of(context).pick(
                            '工作日 ${reminder.startHour}:00–${reminder.endHour}:00',
                            'Weekdays ${reminder.startHour}:00–${reminder.endHour}:00',
                          )
                        : HipText.of(context).pick(
                            "时间已记下，暂不推送系统通知",
                            "Schedule saved. System notifications are not available yet.",
                          ),
                    trailing: HipSwitch(
                      key: const ValueKey('reminder-switch'),
                      semanticLabel: HipText.of(
                        context,
                      ).pick("久坐提醒", "Move reminders"),
                      value: reminder.enabled,
                      onChanged: (v) =>
                          store.setReminder(reminder.copyWith(enabled: v)),
                    ),
                  ),
                  if (reminder.enabled)
                    HipListSubRow(
                      label: HipText.of(context).pick("间隔", "Every"),
                      child: SizedBox(
                        width: 156,
                        // The same tactile thumb as every other either/or
                        // choice (button audit 2026-10-18), not a Material chip.
                        child: HipSegmented<int>(
                          keyPrefix: 'reminder-interval',
                          height: 32,
                          radius: 9,
                          inset: 2,
                          ios: true,
                          values: const [45, 60],
                          selected: reminder.intervalMinutes,
                          label: (m) =>
                              HipText.of(context).pick('$m 分钟', '$m min'),
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
                  title: HipText.of(
                    context,
                  ).pick("2 分钟椅边放松", "2-minute chair break"),
                  subtitle: HipText.of(
                    context,
                  ).pick("现在就做一组，不用起身", "A quick break, right from your chair"),
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
                      planActionIds: HipMediaPolicy.of(context)
                          ? plan.steps.map((step) => step.drill.id)
                          : const [],
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          HipVoiceSettingsPanel(store: store),
          const SizedBox(height: 28),
          HipAppearancePanel(store: store),
          const SizedBox(height: 28),
          HipLanguagePanel(store: store),
          const SizedBox(height: 28),
          HipListGroup(
            children: [
              HipListRow(
                key: const ValueKey('privacy-policy'),
                glyph: HipGlyph.clipboard,
                title: HipText.of(context).pick("隐私政策", "Privacy policy"),
                subtitle: HipText.of(context).pick(
                  "离线阅读 · 数据保存在设备上",
                  "Read offline · Your data stays on this device",
                ),
                onTap: () => Navigator.of(
                  context,
                ).push(HipRoute.content<void>((_) => const HipPrivacyPage())),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 16),
        Text(
          HipText.of(context).pick(
            "这是运动练习，不能替代医生的建议。",
            "Exercise guidance does not replace medical advice.",
          ),
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: HipColors.muted),
        ),
      ],
    );
  }
}

/// 设置 as its own page (UI r2): [HipNavBar] + the grouped settings list.
/// Opened from 更多 and from the AI coach.
class HipSettingsPage extends StatelessWidget {
  const HipSettingsPage({super.key, required this.store});
  final HipStore store;
  @override
  Widget build(BuildContext context) => HipNavPage(
    title: HipText.of(context).pick("设置", "Settings"),
    bodyScrollsUnderBar: true,
    // A pushed route is not rebuilt by the app root: follow the store so
    // switches and choices show their new state.
    body: ListenableBuilder(
      listenable: store,
      builder: (_, _) =>
          HipProgressPage(store: store, section: HipProgressSection.settings),
    ),
  );
}

// ───────────────────────── settings: voice + appearance ─────────────────────

/// 语音播报: voice on/off, chimes on/off, language, volume, preview (#13).
class HipVoiceSettingsPanel extends StatelessWidget {
  const HipVoiceSettingsPanel({super.key, required this.store});
  final HipStore store;

  @override
  Widget build(BuildContext context) {
    final v = store.voice;
    final ios = Theme.of(context).platform == TargetPlatform.iOS;
    return Column(
      key: const ValueKey('voice-settings'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HipListGroup(
          children: [
            HipListRow(
              glyph: HipGlyph.voice,
              title: HipText.of(context).pick("人声口令", "Voice cues"),
              subtitle: HipText.of(context).pick(
                "动作预告、倒数、换边、要点提醒",
                "Move previews, countdowns, side changes and technique cues",
              ),
              trailing: HipSwitch(
                key: const ValueKey('voice-switch'),
                semanticLabel: HipText.of(context).pick("人声口令", "Voice cues"),
                value: v.voice,
                onChanged: (x) => store.setVoice(v.copyWith(voice: x)),
              ),
            ),
            HipListRow(
              glyph: HipGlyph.today,
              title: HipText.of(context).pick("提示音", "Chimes"),
              subtitle: HipText.of(context).pick(
                "开始、结束和倒数的“滴”声",
                "Sounds for the start, finish and countdown",
              ),
              trailing: HipSwitch(
                key: const ValueKey('chime-switch'),
                semanticLabel: HipText.of(context).pick("提示音", "Chimes"),
                value: v.chimes,
                onChanged: (x) => store.setVoice(v.copyWith(chimes: x)),
              ),
            ),
            _settingsChoice(
              context,
              glyph: HipGlyph.subtitles,
              title: HipText.of(context).pick('口令语言', 'Voice language'),
              control: SizedBox(
                width: 196,
                child: HipSegmented<VoiceLanguage>(
                  keyPrefix: 'voice-lang',
                  height: 32,
                  radius: 9,
                  inset: 2,
                  ios: true,
                  values: VoiceLanguage.values,
                  selected: v.language,
                  label: (l) => l == VoiceLanguage.app
                      ? HipText.of(context).pick('跟随 App', 'App')
                      : l.label,
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
                    HipText.of(context).pick("音量", "Volume"),
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w400,
                      color: HipColors.text,
                    ),
                  ),
                  Expanded(
                    child: HipSlider(
                      key: const ValueKey('voice-volume'),
                      value: v.volume,
                      semanticLabel: HipText.of(context).pick("音量", "Volume"),
                      onChanged: (x) => store.setVoice(v.copyWith(volume: x)),
                    ),
                  ),
                  if (ios)
                    _HipIosVoicePreviewButton(settings: v)
                  else
                    Tooltip(
                      message: HipText.of(context).pick("试听", "Preview"),
                      child: HipPressable(
                        key: const ValueKey('voice-preview'),
                        semanticLabel: HipText.of(
                          context,
                        ).pick("试听", "Preview"),
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

/// A short foreground preview owns its audio lifetime on iOS.
class _HipIosVoicePreviewButton extends StatefulWidget {
  const _HipIosVoicePreviewButton({required this.settings});
  final VoiceSettings settings;

  @override
  State<_HipIosVoicePreviewButton> createState() =>
      _HipIosVoicePreviewButtonState();
}

class _HipIosVoicePreviewButtonState extends State<_HipIosVoicePreviewButton>
    with WidgetsBindingObserver, RouteAware {
  Timer? _timer;
  VoiceQueue? _queue;
  StreamSubscription<AudioInterruption>? _interruptions;
  RouteObserver<ModalRoute<dynamic>>? _routes;
  ModalRoute<dynamic>? _route;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    final routes = Navigator.maybeOf(context)?.widget.observers
        .whereType<RouteObserver<ModalRoute<dynamic>>>()
        .firstOrNull;
    if (_route != route || _routes != routes) {
      _routes?.unsubscribe(this);
      _route = route;
      _routes = routes;
      if (route != null) routes?.subscribe(this, route);
    }
    if (route?.isCurrent == false) _stopPreview();
  }

  // Release synchronously on navigation, before the new player is built.
  @override
  void didPushNext() => _stopPreview();

  @override
  void didPop() => _stopPreview();

  @override
  void didUpdateWidget(_HipIosVoicePreviewButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.settings != widget.settings) _stopPreview();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _stopPreview();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _routes?.unsubscribe(this);
    _stopPreview();
    super.dispose();
  }

  void _stopPreview() {
    final elapsed = (_timer?.tick ?? 0) * .05;
    _timer?.cancel();
    _timer = null;
    unawaited(_interruptions?.cancel());
    _interruptions = null;
    final queue = _queue;
    _queue = null;
    if (queue == null) return;
    queue.cancelAll(elapsed);
    // end invalidates this session synchronously; the SDK serializes its
    // release with the next begin, including an immediately opened workout.
    unawaited(queue.output.end());
  }

  void _preview() {
    _stopPreview();
    final voice = HipVoice.of(context);
    final q = _queue = voice.queue();
    unawaited(voice.output.begin());
    if (voice.output case final InterruptibleVoiceOutput output) {
      _interruptions = output.interruptions.listen((event) {
        if (event != AudioInterruption.ended) _stopPreview();
      });
    }
    final cues = [
      const VoiceCue(0, ['p.ready'], CuePriority.call),
      for (var k = 3; k >= 1; k--)
        VoiceCue(4.0 - k, ['chime.tick', 'n.$k'], CuePriority.count),
      const VoiceCue(4, ['chime.start', 'p.go'], CuePriority.call),
    ];
    var i = 0;
    _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      final t = timer.tick * .05;
      while (i < cues.length && cues[i].at <= t) {
        q.submit(cues[i++], t);
      }
      q.tick(t);
      if (i >= cues.length && t > 6) _stopPreview();
    });
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.settings.voice || widget.settings.chimes;
    return Tooltip(
      message: HipText.of(context).pick('试听', 'Preview'),
      child: HipPressable(
        key: const ValueKey('voice-preview'),
        semanticLabel: HipText.of(context).pick('试听', 'Preview'),
        scale: .9,
        onTap: enabled ? _preview : null,
        child: SizedBox.square(
          dimension: 44,
          child: Center(
            child: HipIcon(
              HipGlyph.play,
              size: 16,
              filled: true,
              color: enabled ? HipColors.jadeText : HipColors.faint,
            ),
          ),
        ),
      ),
    );
  }
}

/// 外观: 跟随系统 / 浅色 / 深色 (#14).
/// Choices get their own line in English, keeping full labels legible rather
/// than squeezing them against three segment controls.
Widget _settingsChoice(
  BuildContext context, {
  required HipGlyph glyph,
  required String title,
  required Widget control,
}) => HipText.of(context).isEn
    ? Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HipListRow(glyph: glyph, title: title),
          Padding(
            padding: const EdgeInsets.fromLTRB(kHipRowTextInset, 0, 16, 12),
            child: control,
          ),
        ],
      )
    : HipListRow(glyph: glyph, title: title, trailing: control);

class HipLanguagePanel extends StatelessWidget {
  const HipLanguagePanel({super.key, required this.store});
  final HipStore store;

  @override
  Widget build(BuildContext context) => HipListGroup(
    key: const ValueKey('app-language-settings'),
    children: [
      _settingsChoice(
        context,
        glyph: HipGlyph.subtitles,
        title: HipText.of(context).pick('界面语言', 'App language'),
        control: SizedBox(
          width: 196,
          child: HipSegmented<HipLanguage>(
            keyPrefix: 'app-language',
            height: 32,
            radius: 9,
            inset: 2,
            ios: true,
            values: HipLanguage.values,
            selected: store.language,
            label: (choice) => switch (choice) {
              HipLanguage.system => HipText.of(context).pick('系统', 'System'),
              HipLanguage.zh => '中文',
              HipLanguage.en => 'English',
            },
            onChanged: store.setLanguage,
          ),
        ),
      ),
    ],
  );
}

class HipAppearancePanel extends StatelessWidget {
  const HipAppearancePanel({super.key, required this.store});
  final HipStore store;
  @override
  Widget build(BuildContext context) => Column(
    key: const ValueKey('appearance-settings'),
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      HipListGroup(
        children: [
          _settingsChoice(
            context,
            glyph: HipGlyph.contrast,
            title: HipText.of(context).pick("颜色", "Appearance"),
            control: SizedBox(
              width: 210,
              child: HipSegmented<HipThemeChoice>(
                keyPrefix: 'theme',
                height: 32,
                radius: 9,
                inset: 2,
                ios: true,
                values: HipThemeChoice.values,
                selected: store.theme,
                label: (c) => HipText.of(context).pick(c.zh, switch (c) {
                  HipThemeChoice.system => 'System',
                  HipThemeChoice.light => 'Light',
                  HipThemeChoice.dark => 'Dark',
                }),
                onChanged: store.setTheme,
              ),
            ),
          ),
        ],
      ),
    ],
  );
}
