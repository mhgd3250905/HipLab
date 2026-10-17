import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../control/hip_store.dart';
import '../data/hip_content_loader.dart';
import '../domain/hip_models.dart';
import '../domain/hip_progress.dart';
import '../domain/hip_session.dart';
import 'hip_assessment_page.dart';
import 'hip_player_page.dart';
import 'hip_privacy_page.dart';
import 'hip_theme.dart';
import 'hip_widgets.dart';

const hipAppName = '开胯训练助手';

/// Root of the HipLab app (entry: lib/main.dart).
class HipApp extends StatefulWidget {
  const HipApp({super.key, this.store, this.videoEnabled = true});

  /// Injected in tests; otherwise loaded from assets + SharedPreferences.
  final HipStore? store;
  final bool videoEnabled;

  @override
  State<HipApp> createState() => _HipAppState();
}

class _HipAppState extends State<HipApp> {
  late Future<HipStore> _loading = _load();

  Future<HipStore> _load() async {
    if (widget.store != null) return widget.store!;
    final store = HipStore(content: await loadHipContent());
    await store.initialize();
    return store;
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: hipAppName,
    debugShowCheckedModeBanner: false,
    theme: hipTheme(),
    locale: const Locale('zh'),
    supportedLocales: const [Locale('zh')],
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: const Color(0x00000000),
        systemNavigationBarColor: HipColors.background,
      ),
      child: HipMediaPolicy(videoEnabled: widget.videoEnabled, child: child!),
    ),
    home: FutureBuilder<HipStore>(
      future: _loading,
      builder: (context, snap) {
        if (snap.hasError) {
          return Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => setState(() => _loading = _load()),
                child: const Text('读取失败，点一下重试'),
              ),
            ),
          );
        }
        final store = snap.data;
        if (store == null) return const Scaffold(body: SizedBox.expand());
        return ListenableBuilder(
          listenable: store,
          builder: (context, _) => store.onboarded
              ? HipHome(store: store)
              : HipOnboarding(store: store),
        );
      },
    ),
  );
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

  List<SafetyCard> get _cards => widget.store.content.safetyCards;
  bool get _onIdentity => _index >= _cards.length;

  static const _icons = {
    'pregnant_woman': Icons.pregnant_woman_rounded,
    'healing': Icons.healing_rounded,
    'personal_injury': Icons.personal_injury_rounded,
  };

  Future<void> _answer(bool yes) async {
    _answers[_cards[_index].id] = yes;
    if (_index == _cards.length - 1) {
      await widget.store.setSafety(_answers);
      if (widget.review && mounted) {
        Navigator.of(context).pop();
        return;
      }
    }
    setState(() => _index++);
  }

  @override
  Widget build(BuildContext context) {
    final blocked = _answers.values.any((v) => v);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: _onIdentity ? _identity(blocked) : _safetyCard(),
        ),
      ),
    );
  }

  Widget _safetyCard() {
    final card = _cards[_index];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            for (var i = 0; i < _cards.length; i++)
              Expanded(
                child: Container(
                  height: 4,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: i <= _index ? HipColors.jade : HipColors.surfaceHigh,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 28),
        const Text(
          '开始之前',
          style: TextStyle(
            fontSize: 15,
            color: HipColors.jade,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          '你现在有这种情况吗？',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: HipPanel(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 132,
                  height: 132,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        HipColors.jade.withValues(alpha: .28),
                        HipColors.jade.withValues(alpha: 0),
                      ],
                    ),
                  ),
                  child: Icon(
                    _icons[card.icon] ?? Icons.info_outline,
                    size: 72,
                    color: HipColors.jade,
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  card.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 21,
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 56,
                child: OutlinedButton(
                  key: const ValueKey('safety-yes'),
                  onPressed: () => _answer(true),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: HipColors.text,
                    side: const BorderSide(color: HipColors.line),
                    shape: const StadiumBorder(),
                    textStyle: const TextStyle(
                      fontFamily: hipFontFamily,
                      fontSize: 18,
                    ),
                  ),
                  child: const Text('有'),
                ),
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
        const Text(
          '这是运动练习，不能替代医生的建议。',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: HipColors.faint),
        ),
      ],
    );
  }

  Widget _identity(bool blocked) {
    const choices = [
      (HipIdentity.office, Icons.chair_alt_rounded),
      (HipIdentity.dancer, Icons.sports_gymnastics_rounded),
      (HipIdentity.other, Icons.person_rounded),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (blocked) ...[
          HipPanel(
            borderColor: HipColors.tight.withValues(alpha: .5),
            child: const Row(
              children: [
                Icon(
                  Icons.medical_information_outlined,
                  color: HipColors.tight,
                ),
                SizedBox(width: 12),
                Expanded(
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
        const Text(
          '你是哪一种？',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 20),
        for (final (id, icon) in choices) ...[
          Material(
            color: HipColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
              side: const BorderSide(color: HipColors.line),
            ),
            child: InkWell(
              key: ValueKey('identity-${id.id}'),
              borderRadius: BorderRadius.circular(22),
              onTap: () => widget.store.setIdentity(id),
              child: SizedBox(
                height: 104,
                child: Row(
                  children: [
                    const SizedBox(width: 20),
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: HipColors.jade.withValues(alpha: .12),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Icon(icon, size: 36, color: HipColors.jade),
                    ),
                    const SizedBox(width: 18),
                    Text(
                      id.zh,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
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
  HipStore get store => widget.store;

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
      child: switch (_tab) {
        1 => HipAssessmentIntro(store: store, onStart: _startAssessment),
        2 => HipProgressPage(store: store),
        _ => _today(),
      },
    ),
    bottomNavigationBar: _nav(),
  );

  Widget _nav() => Container(
    decoration: const BoxDecoration(
      border: Border(top: BorderSide(color: HipColors.line)),
    ),
    child: SafeArea(
      top: false,
      child: SizedBox(
        height: 64,
        child: Row(
          children: [
            for (final (i, icon, label) in [
              (0, Icons.play_circle_outline_rounded, '今日'),
              (1, Icons.monitor_heart_outlined, '自测'),
              (2, Icons.bar_chart_rounded, '进度'),
            ])
              Expanded(
                child: InkWell(
                  key: ValueKey('tab-$i'),
                  onTap: () => setState(() => _tab = i),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        icon,
                        color: _tab == i ? HipColors.jade : HipColors.muted,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 11,
                          color: _tab == i ? HipColors.jade : HipColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );

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
                    style: const TextStyle(
                      fontSize: 13,
                      color: HipColors.muted,
                    ),
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
                  const Icon(
                    Icons.local_fire_department_outlined,
                    size: 18,
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
          height: 150,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _streakCard()),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: result == null
                      ? _startAssessment
                      : () => setState(() => _tab = 2),
                  child: HipPanel(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '我的髋部',
                          style: TextStyle(
                            fontSize: 13,
                            color: HipColors.muted,
                          ),
                        ),
                        Expanded(
                          child: result == null
                              ? const Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.radar_rounded,
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
    return Container(
      height: 350,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: HipColors.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: HipColors.line),
      ),
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
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [.45, .8],
                colors: [Color(0x0016171a), HipColors.surface],
              ),
            ),
          ),
          Positioned(
            left: 14,
            top: 14,
            child: _chip(Icons.repeat_rounded, '预览'),
          ),
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
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${plan.minutes} 分钟 · ${plan.steps.length} 个动作',
                  style: const TextStyle(fontSize: 14, color: HipColors.muted),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    for (final s in plan.steps.take(4))
                      Container(
                        width: 40,
                        height: 40,
                        margin: const EdgeInsets.only(right: 6),
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: HipColors.line),
                        ),
                        child: HipDrillArt(
                          drill: s.drill,
                          showPendingLabel: false,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            right: 18,
            bottom: 26,
            child: Semantics(
              button: true,
              label: '开始',
              child: GestureDetector(
                key: const ValueKey('start-today'),
                onTap: plan.steps.isEmpty ? null : () => _startPlan(plan),
                child: Container(
                  width: 104,
                  height: 104,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: HipColors.jade,
                    boxShadow: [
                      BoxShadow(
                        color: HipColors.jade.withValues(alpha: .45),
                        blurRadius: 30,
                        spreadRadius: 2,
                      ),
                    ],
                    border: Border.all(
                      color: HipColors.jade.withValues(alpha: .35),
                      width: 6,
                      strokeAlign: 1,
                    ),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.play_arrow_rounded,
                        size: 40,
                        color: Color(0xff07261d),
                      ),
                      Text(
                        '开始',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xff07261d),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
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
          const Icon(
            Icons.medical_information_outlined,
            size: 48,
            color: HipColors.tight,
          ),
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
        const Icon(Icons.info_outline_rounded, color: HipColors.tight),
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

  Widget _chip(IconData icon, String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: HipColors.background.withValues(alpha: .55),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: HipColors.line),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: HipColors.muted),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(fontSize: 12, color: HipColors.muted),
        ),
      ],
    ),
  );

  Widget _segment<T>({
    required List<T> values,
    required T selected,
    required Widget Function(T, bool) build,
    required ValueChanged<T> onTap,
    required String keyPrefix,
  }) => HipPanel(
    padding: const EdgeInsets.all(6),
    child: SizedBox(
      height: 62,
      child: Row(
        children: [
          for (final v in values)
            Expanded(
              child: GestureDetector(
                key: ValueKey('$keyPrefix-$v'),
                onTap: () => onTap(v),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  decoration: BoxDecoration(
                    color: v == selected
                        ? HipColors.jade.withValues(alpha: .14)
                        : null,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: v == selected
                          ? HipColors.jade
                          : const Color(0x00000000),
                    ),
                  ),
                  child: build(v, v == selected),
                ),
              ),
            ),
        ],
      ),
    ),
  );

  Widget _durationPicker() => _segment<int>(
    keyPrefix: 'minutes',
    values: TrainingPlanner.durations,
    selected: store.minutes,
    onTap: (v) => store.choose(minutes: v),
    build: (v, on) => Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '$v',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: on ? HipColors.jade : HipColors.text,
          ),
        ),
        Text(
          '分',
          style: TextStyle(
            fontSize: 11,
            color: on ? HipColors.jade : HipColors.muted,
          ),
        ),
      ],
    ),
  );

  Widget _scenePicker() => _segment<HipScene>(
    keyPrefix: 'scene',
    values: HipScene.values,
    selected: store.scene,
    onTap: (v) => store.choose(scene: v),
    build: (v, on) => Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          v == HipScene.chair ? Icons.chair_alt_outlined : Icons.home_outlined,
          color: on ? HipColors.jade : HipColors.muted,
        ),
        const SizedBox(height: 2),
        Text(
          v.zh,
          style: TextStyle(
            fontSize: 11,
            color: on ? HipColors.jade : HipColors.muted,
          ),
        ),
      ],
    ),
  );

  Widget _streakCard() => HipPanel(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(
              Icons.local_fire_department_outlined,
              size: 16,
              color: HipColors.tight,
            ),
            SizedBox(width: 4),
            Text('连续', style: TextStyle(fontSize: 13, color: HipColors.muted)),
          ],
        ),
        const SizedBox(height: 4),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: '${store.streak}',
                style: const TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const TextSpan(
                text: ' 天',
                style: TextStyle(fontSize: 15, color: HipColors.muted),
              ),
            ],
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
              const Icon(
                Icons.local_fire_department_outlined,
                color: HipColors.tight,
              ),
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
                style: const TextStyle(color: HipColors.muted),
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
                    const Text(
                      '最近一次自测',
                      style: TextStyle(color: HipColors.muted),
                    ),
                    const Spacer(),
                    Text(
                      '${result.level.name} · ${result.total}/12',
                      style: const TextStyle(color: HipColors.jade),
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
                  const Icon(Icons.event_seat_outlined, color: HipColors.jade),
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
                    style: const TextStyle(
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
                trailing: const Icon(Icons.chevron_right_rounded),
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
        HipPanel(
          padding: EdgeInsets.zero,
          child: ListTile(
            leading: const Icon(
              Icons.health_and_safety_outlined,
              color: HipColors.jade,
            ),
            title: const Text('重新看安全提示'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => HipOnboarding(store: store, review: true),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        HipPanel(
          padding: EdgeInsets.zero,
          child: ListTile(
            key: const ValueKey('privacy-policy'),
            leading: const Icon(
              Icons.privacy_tip_outlined,
              color: HipColors.jade,
            ),
            title: const Text('隐私政策'),
            subtitle: const Text('离线阅读 · 数据保存在设备上'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const HipPrivacyPage()),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
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
