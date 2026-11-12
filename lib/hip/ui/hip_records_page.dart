// The Hip v2 training history shows actual streaks and saved sessions.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:ugk_trainer_runtime/ugk_trainer.dart' as trainer;

import '../control/hip_store.dart';
import '../data/hip_public_media.dart';
import '../domain/hip_library.dart';
import '../domain/hip_progress.dart';
import 'hip_content_text.dart';
import 'hip_icons.dart';
import 'hip_page_kit.dart';
import 'hip_routes.dart';
import 'hip_text.dart';
import 'hip_theme.dart';
import 'hip_widgets.dart';

const _weekdays = ['一', '二', '三', '四', '五', '六', '日'];
const _englishWeekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _englishMonths = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

class HipRecordsView extends StatefulWidget {
  const HipRecordsView({
    super.key,
    required this.store,
    this.onStartPractice,
    this.embedded = false,
  });
  final HipStore store;

  /// Inside another list (the AI coach's 进度+设置 page): a plain column.
  final bool embedded;

  /// Empty state's one action (the 首页 training); null hides the button.
  final VoidCallback? onStartPractice;

  @override
  State<HipRecordsView> createState() => _HipRecordsViewState();
}

class _HipRecordsViewState extends State<HipRecordsView> {
  /// Milestone animating this time (newly reached since the last showing).
  int? _celebrate;

  HipStore get store => widget.store;

  @override
  void initState() {
    super.initState();
    final earned = streakHistory(store.doneDays).earned.keys;
    final top = earned.isEmpty ? 0 : earned.reduce(math.max);
    if (top > store.celebratedMilestone) {
      _celebrate = top;
      // Mark after the first frame: the badge keeps its own animation.
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => store.markCelebrated(top),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = store.now();
    final today = DateTime(now.year, now.month, now.day);
    final done = store.doneDays;
    final finished = [
      for (final s in store.sessions)
        if (s.completed) s,
    ];
    final secondsByDay = <String, int>{};
    var seconds = 0;
    for (final s in finished) {
      seconds += s.seconds;
      final k = dayKey(s.at);
      secondsByDay[k] = (secondsByDay[k] ?? 0) + s.seconds;
    }
    final minutesByDay = {
      for (final entry in secondsByDay.entries)
        entry.key: (entry.value / 60).round(),
    };
    final history = streakHistory(done);
    final streak = store.streak;
    final empty = done.isEmpty && store.sessions.isEmpty;
    final t = HipText.of(context);
    final children = <Widget>[
      _Hero(
        streak: streak,
        trainedToday: done.contains(dayKey(today)),
        totalDays: done.length,
        sessions: finished.length,
        minutes: (seconds / 60).round(),
        hasHistory: done.isNotEmpty,
      ),
      const SizedBox(height: 20),
      if (empty)
        _Empty(onStart: widget.onStartPractice)
      else
        HipCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              HipCardHeading(
                t.pick('本周', 'This week'),
                key: const ValueKey('records-week-count'),
                trailing: '${_weekDone(done, today)} / 7',
              ),
              const SizedBox(height: 10),
              _Week(done: done, today: today),
              const SizedBox(height: 12),
              Divider(height: .5, thickness: .5, color: HipColors.cardDivider),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: HipCardHeading(t.pick('近 16 周', 'Last 16 weeks')),
                  ),
                  const SizedBox(width: 8),
                  const _HeatLegend(),
                ],
              ),
              const SizedBox(height: 8),
              _Heatmap(done: done, minutes: minutesByDay, today: today),
            ],
          ),
        ),
      const SizedBox(height: 16),
      HipCard(
        padding: const EdgeInsets.fromLTRB(8, 16, 8, 16),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: HipCardHeading(
                t.pick('里程碑', 'Milestones'),
                trailing:
                    '${history.earned.length} / ${streakMilestones.length}',
              ),
            ),
            const SizedBox(height: 18),
            _Milestones(
              streak: streak,
              earned: history.earned,
              celebrate: _celebrate,
            ),
          ],
        ),
      ),
      if (store.sessions.isNotEmpty) ...[
        const SizedBox(height: 16),
        HipCard(
          key: const ValueKey('records-recent'),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: HipCardHeading(t.pick('最近训练', 'Recent training')),
                  ),
                  HipPressable(
                    key: const ValueKey('records-all'),
                    semanticLabel: t.pick('全部训练', 'All training'),
                    onTap: _openHistory,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 36),
                      child: Row(
                        children: [
                          Text(
                            t.pick('全部', 'All'),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: HipColors.jadeText,
                            ),
                          ),
                          HipIcon(
                            HipGlyph.chevronRight,
                            size: 13,
                            color: HipColors.jadeText,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              for (final (i, s) in store.sessions.reversed.take(3).indexed) ...[
                if (i > 0)
                  Divider(
                    height: .5,
                    thickness: .5,
                    indent: 50,
                    color: HipColors.cardDivider,
                  ),
                _recent(context, s, today),
              ],
            ],
          ),
        ),
      ],
    ];
    if (widget.embedded) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      );
    }
    return ListView(
      key: const ValueKey('records-list'),
      padding: EdgeInsets.fromLTRB(
        kHipPageEdge,
        hipNavInset(context) + 4,
        kHipPageEdge,
        32,
      ),
      children: children,
    );
  }

  static int _weekDone(Set<String> done, DateTime today) {
    final mon = weekStart(today);
    var n = 0;
    for (var i = 0; i < 7; i++) {
      if (done.contains(dayKey(DateTime(mon.year, mon.month, mon.day + i)))) {
        n++;
      }
    }
    return n;
  }

  void _openHistory() {
    Navigator.of(context).push<void>(
      HipRoute.content<void>(
        (context) => HipNavPage(
          title: HipText.of(context).pick('全部训练', 'All training'),
          bodyScrollsUnderBar: true,
          body: ListenableBuilder(
            listenable: store,
            builder: (context, _) {
              final now = store.now();
              final today = DateTime(now.year, now.month, now.day);
              return ListView.separated(
                key: const ValueKey('records-all-list'),
                padding: EdgeInsets.fromLTRB(
                  kHipPageEdge,
                  hipNavInset(context) + 4,
                  kHipPageEdge,
                  24,
                ),
                itemCount: store.sessions.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) => HipCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _recent(
                    context,
                    store.sessions[store.sessions.length - 1 - index],
                    today,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _recent(BuildContext context, SessionRecord s, DateTime today) {
    final t = HipText.of(context);
    final d = DateTime(s.at.year, s.at.month, s.at.day);
    final ago = DateTime.utc(
      today.year,
      today.month,
      today.day,
    ).difference(DateTime.utc(d.year, d.month, d.day)).inDays;
    final day = ago == 0
        ? t.pick('今天', 'Today')
        : ago == 1
        ? t.pick('昨天', 'Yesterday')
        : t.pick(
            '${s.at.month}月${s.at.day}日 周${_weekdays[s.at.weekday - 1]}',
            '${_englishWeekdays[s.at.weekday - 1]}, ${_englishMonths[s.at.month - 1]} ${s.at.day}',
          );
    final time =
        '${s.at.hour.toString().padLeft(2, '0')}:${s.at.minute.toString().padLeft(2, '0')}';
    final mins = math.max(1, (s.seconds / 60).round());
    final builtIn =
        s.source == PlanSource.routine || s.source == PlanSource.recommended
        ? store.content.routines.where((r) => r.id == s.refId).firstOrNull
        : null;
    final items = s.trainerResult?['items'];
    final leadingItem = items is List ? items.firstOrNull : null;
    final savedId = leadingItem is Map ? leadingItem['exerciseId'] : null;
    final ref = s.refId;
    final actionId = savedId is String && savedId.isNotEmpty
        ? savedId
        : switch (s.source) {
            PlanSource.single => ref,
            PlanSource.custom =>
              ref == null
                  ? null
                  : store.customRoutine(ref)?.steps.firstOrNull?.kitId,
            _ => builtIn?.steps.firstOrNull?.drillId,
          };
    final asset = actionId == null
        ? null
        : HipPublicMedia.current?.posterAssetFor(actionId) ??
              HipPublicMedia.coverAssetFor(actionId);
    // Only known authored routine IDs can supply translated titles. Keep
    // custom/AI titles and ambiguous historical text exactly as stored.
    final title = t.isEn && s.source == PlanSource.routine && builtIn != null
        ? HipContentText.of(context).routineName(builtIn)
        : s.title.isEmpty
        ? t.pick('训练', 'Training')
        : s.title;
    return _RecordRow(
      title: title,
      timestamp: '$day $time',
      unfinished: !s.completed,
      duration: t.pick('$mins 分钟', '$mins min'),
      asset: asset,
    );
  }
}

class _RecordRow extends StatelessWidget {
  const _RecordRow({
    required this.title,
    required this.timestamp,
    required this.unfinished,
    required this.duration,
    required this.asset,
  });

  final String title;
  final String timestamp;
  final bool unfinished;
  final String duration;
  final String? asset;

  @override
  Widget build(BuildContext context) {
    final fallback = Center(
      child: HipIcon(
        unfinished ? HipGlyph.pause : HipGlyph.checkCircle,
        size: 18,
        color: HipColors.muted,
      ),
    );
    return SizedBox(
      height: 60,
      child: Row(
        children: [
          SizedBox(
            width: 38,
            height: 40,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: HipColors.isDark
                      ? [HipColors.surfaceHigh, HipColors.surface]
                      : const [Color(0xfff1f3f2), Color(0xffeaedeb)],
                ),
              ),
              child: ExcludeSemantics(
                child: asset == null
                    ? fallback
                    : trainer.TrainerPoster(
                        asset: asset!,
                        radius: 10,
                        decodeWidth:
                            (38 * MediaQuery.devicePixelRatioOf(context))
                                .ceil(),
                        fallback: fallback,
                      ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: HipColors.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text.rich(
                  TextSpan(
                    text: timestamp,
                    children: [
                      if (unfinished)
                        TextSpan(
                          text: HipText.of(
                            context,
                          ).pick(' · 未完成', ' · Unfinished'),
                          style: TextStyle(color: HipColors.tight),
                        ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: HipColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            duration,
            style: TextStyle(fontSize: 12, color: HipColors.muted),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── hero ─────────────────────────

class _Hero extends StatelessWidget {
  const _Hero({
    required this.streak,
    required this.trainedToday,
    required this.totalDays,
    required this.sessions,
    required this.minutes,
    required this.hasHistory,
  });
  final int streak;
  final bool trainedToday;
  final int totalDays;
  final int sessions;
  final int minutes;
  final bool hasHistory;

  String _line(BuildContext context) {
    final t = HipText.of(context);
    if (streak == 0) {
      return hasHistory
          ? t.pick(
              '歇了几天也没关系，今天练一次重新开始',
              'A few days off is fine. Train today to start again.',
            )
          : t.pick(
              '练完第一次，连续天数就从 1 开始',
              'Finish your first session to start a 1-day streak.',
            );
    }
    if (streakMilestones.contains(streak)) {
      return t.pick('达成连续 $streak 天，真不容易！', 'A $streak-day streak. Well done!');
    }
    final next = streakMilestones.firstWhere(
      (m) => m > streak,
      orElse: () => 0,
    );
    final keep = trainedToday
        ? ''
        : t.pick('今天练一次就能续上，', 'Train today to keep it going. ');
    if (next == 0) {
      return t.pick('$keep已经是长期习惯了', '${keep}You have built a lasting habit.');
    }
    return t.pick(
      '$keep再坚持 ${next - streak} 天，解锁「$next 天」',
      '$keep${t.plural(next - streak, 'more day')} to unlock $next days.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = HipText.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(2, 4, 2, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.pick('连续天数', 'STREAK'),
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w700,
                  color: HipColors.jade,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '$streak',
                    key: const ValueKey('records-streak'),
                    style: TextStyle(
                      fontSize: 72,
                      height: 1.05,
                      fontWeight: FontWeight.w700,
                      color: HipColors.text,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    t.pick('天', streak == 1 ? 'day' : 'days'),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: HipColors.text,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                _line(context),
                key: const ValueKey('records-cheer'),
                style: TextStyle(fontSize: 12.5, color: HipColors.muted),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        HipCard(
          key: const ValueKey('records-totals'),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 74),
            child: Row(
              children: [
                _stat(
                  t.pick('累计天数', 'Total days'),
                  totalDays,
                  t.pick('天', totalDays == 1 ? 'day' : 'days'),
                ),
                _statDivider(),
                _stat(t.pick('累计次数', 'Sessions'), sessions, t.pick('次', '')),
                _statDivider(),
                _stat(
                  t.pick('累计时长', 'Total time'),
                  minutes,
                  t.pick('分钟', 'min'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _statDivider() => SizedBox(
    width: .5,
    height: 36,
    child: ColoredBox(color: HipColors.cardDivider),
  );

  Widget _stat(String label, int value, String unit) => Expanded(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$value',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: HipColors.text,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  if (unit.isNotEmpty)
                    TextSpan(
                      text: ' $unit',
                      style: TextStyle(fontSize: 11, color: HipColors.muted),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, color: HipColors.faint),
          ),
        ],
      ),
    ),
  );
}

class _Empty extends StatelessWidget {
  const _Empty({this.onStart});
  final VoidCallback? onStart;
  @override
  Widget build(BuildContext context) => HipListGroup(
    key: const ValueKey('records-empty'),
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        child: Column(
          children: [
            HipIcon(HipGlyph.today, size: 32, color: HipColors.jadeText),
            const SizedBox(height: 12),
            Text(
              HipText.of(context).pick('还没有训练记录', 'No training records yet'),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: HipColors.text,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              HipText.of(context).pick(
                '每练完一次，这里会点亮一格，\n连续天数、打卡日历和里程碑都会慢慢长出来。',
                'Each completed session lights up a day.\nBuild your streak, check-in calendar and milestones over time.',
              ),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: HipColors.muted,
                height: 1.5,
              ),
            ),
            if (onStart != null) ...[
              const SizedBox(height: 18),
              HipPrimaryButton(
                key: const ValueKey('records-start'),
                label: HipText.of(
                  context,
                ).pick('开始今天的训练', 'Start today’s training'),
                icon: HipGlyph.play,
                onPressed: onStart,
              ),
            ],
          ],
        ),
      ),
    ],
  );
}

// ───────────────────────── 本周 ─────────────────────────

class _Week extends StatelessWidget {
  const _Week({required this.done, required this.today});
  final Set<String> done;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final mon = weekStart(today);
    final t = HipText.of(context);
    return Row(
      key: const ValueKey('records-week'),
      children: [
        for (var i = 0; i < 7; i++)
          Expanded(
            child: _day(i, DateTime(mon.year, mon.month, mon.day + i), t),
          ),
      ],
    );
  }

  Widget _day(int index, DateTime date, HipText t) {
    final isToday = date == today;
    final future = date.isAfter(today);
    final on = done.contains(dayKey(date));
    final weekday = t.pick(
      isToday ? '今天' : _weekdays[index],
      isToday ? 'Today' : _englishWeekdays[index],
    );
    return MergeSemantics(
      child: Semantics(
        label: on ? t.pick('已训练', 'Trained') : null,
        child: Column(
          children: [
            Container(
              key: ValueKey('week-dot-$index'),
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: !isToday && !future
                    ? _heatColor(0, HipColors.palette)
                    : null,
                border: isToday
                    ? Border.all(color: HipColors.jade, width: 1.5)
                    : future
                    ? Border.all(
                        color: (HipColors.isDark ? Colors.white : Colors.black)
                            .withValues(alpha: .09),
                        width: .8,
                      )
                    : null,
              ),
              child: isToday
                  ? Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: HipColors.jade,
                      ),
                    )
                  : on
                  ? HipIcon(HipGlyph.check, size: 14, color: HipColors.jadeText)
                  : null,
            ),
            const SizedBox(height: 8),
            Text(
              weekday,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                color: isToday
                    ? HipColors.jade
                    : future
                    ? HipColors.faint
                    : HipColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeatLegend extends StatelessWidget {
  const _HeatLegend();

  @override
  Widget build(BuildContext context) {
    final t = HipText.of(context);
    final label = TextStyle(fontSize: 10, color: HipColors.faint);
    return Row(
      children: [
        Text(t.pick('少', 'Less'), style: label),
        const SizedBox(width: 6),
        for (var level = 0; level < 5; level++) ...[
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              color: _heatColor(level, HipColors.palette),
            ),
          ),
          const SizedBox(width: 4),
        ],
        Text(t.pick('多', 'More'), style: label),
      ],
    );
  }
}

class _Heatmap extends StatelessWidget {
  const _Heatmap({
    required this.done,
    required this.minutes,
    required this.today,
  });
  final Set<String> done;
  final Map<String, int> minutes;
  final DateTime today;

  static const weeks = 16;
  static const gap = 2.3;

  @override
  Widget build(BuildContext context) {
    final monday = weekStart(today);
    final first = DateTime(
      monday.year,
      monday.month,
      monday.day - 7 * (weeks - 1),
    );
    DateTime at(int w, int d) =>
        DateTime(first.year, first.month, first.day + w * 7 + d);
    final levels = [
      for (var w = 0; w < weeks; w++)
        [
          for (var d = 0; d < 7; d++)
            at(w, d).isAfter(today)
                ? -1
                : heatLevel(
                    trained: done.contains(dayKey(at(w, d))),
                    minutes: minutes[dayKey(at(w, d))] ?? 0,
                  ),
        ],
    ];
    final t = HipText.of(context);
    String monthLabel(DateTime date) =>
        t.pick('${date.month}月', _englishMonths[date.month - 1]);
    final months = <(int, String)>[(0, monthLabel(first))];
    for (var w = 1; w < weeks; w++) {
      for (var d = 0; d < 7; d++) {
        final day = at(w, d);
        if (day.day == 1 && !day.isAfter(today)) {
          months.add((w, monthLabel(day)));
        }
      }
    }
    final label = TextStyle(fontSize: 10, color: HipColors.faint);
    return LayoutBuilder(
      key: const ValueKey('records-heatmap'),
      builder: (context, c) {
        const dayCol = 13.0;
        final cell = math.min(
          15.0,
          math.max(0.0, (c.maxWidth - dayCol - gap * (weeks - 1)) / weeks),
        );
        final gridWidth = weeks * cell + gap * (weeks - 1);
        final gridHeight = 7 * cell + gap * 6;
        return Center(
          child: SizedBox(
            width: dayCol + gridWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 16,
                  child: Stack(
                    children: [
                      for (final (w, month) in months)
                        Positioned(
                          left:
                              dayCol +
                              math.min(w * (cell + gap), gridWidth - 26),
                          child: Text(month, style: label),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    SizedBox(
                      width: dayCol,
                      height: gridHeight,
                      child: Stack(
                        children: [
                          for (final d in [0, 2, 4, 6])
                            Positioned(
                              top: d * (cell + gap) + (cell - 12) / 2,
                              child: Text(
                                t.pick(
                                  _weekdays[d],
                                  ['M', 'T', 'W', 'T', 'F', 'S', 'S'][d],
                                ),
                                style: label,
                              ),
                            ),
                        ],
                      ),
                    ),
                    CustomPaint(
                      size: Size(gridWidth, gridHeight),
                      painter: _HeatPainter(
                        levels,
                        cell,
                        HipColors.palette,
                        today: (weeks - 1, today.weekday - 1),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

const _lightHeatColors = [
  Color(0xffecefed),
  Color(0xffc8e9dc),
  Color(0xff82cdaf),
  Color(0xff3caa82),
  Color(0xff148c68),
];

Color _heatColor(int level, HipPalette palette) {
  if (!palette.isDark) return _lightHeatColors[level];
  if (level == 0) return palette.text.withValues(alpha: .07);
  return palette.jade.withValues(alpha: const [.0, .3, .52, .76, 1.0][level]);
}

class _HeatPainter extends CustomPainter {
  _HeatPainter(this.levels, this.cell, this.palette, {required this.today});
  final List<List<int>> levels;
  final double cell;
  final HipPalette palette;
  final (int, int) today;

  @override
  void paint(Canvas canvas, Size size) {
    for (var w = 0; w < levels.length; w++) {
      for (var d = 0; d < 7; d++) {
        final level = levels[w][d];
        if (level < 0) continue;
        final rect = Rect.fromLTWH(
          w * (cell + _Heatmap.gap),
          d * (cell + _Heatmap.gap),
          cell,
          cell,
        );
        final rounded = RRect.fromRectAndRadius(rect, const Radius.circular(4));
        canvas.drawRRect(rounded, Paint()..color = _heatColor(level, palette));
        if ((w, d) == today) {
          canvas.drawRRect(
            rounded.deflate(.6),
            Paint()
              ..color = palette.jade
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.2,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(_HeatPainter old) =>
      old.levels != levels ||
      old.cell != cell ||
      old.palette != palette ||
      old.today != today;
}

// ───────────────────────── 里程碑 ─────────────────────────

class _Milestones extends StatelessWidget {
  const _Milestones({
    required this.streak,
    required this.earned,
    required this.celebrate,
  });
  final int streak;
  final Map<int, DateTime> earned;
  final int? celebrate;

  @override
  Widget build(BuildContext context) {
    final next = streakMilestones
        .where((m) => !earned.containsKey(m))
        .firstOrNull;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final days in streakMilestones)
          Expanded(
            child: _Badge(
              key: ValueKey('milestone-$days'),
              days: days,
              earnedAt: earned[days],
              remaining: days == next ? days - streak : null,
              celebrate: days == celebrate,
            ),
          ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    super.key,
    required this.days,
    required this.earnedAt,
    required this.remaining,
    required this.celebrate,
  });
  final int days;
  final DateTime? earnedAt;
  final int? remaining;
  final bool celebrate;

  @override
  Widget build(BuildContext context) {
    final t = HipText.of(context);
    final earned = earnedAt != null;
    final next = remaining != null;
    final medal = Container(
      width: 38,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: earned
            ? HipColors.primaryAction
            : next
            ? null
            : HipColors.isDark
            ? HipColors.surfaceHigh
            : const Color(0xfff0f2f1),
        border: next
            ? Border.all(
                width: 2.5,
                color: HipColors.isDark
                    ? HipColors.line
                    : const Color(0xffe6eae8),
              )
            : null,
        boxShadow: earned
            ? HipColors.shadows([
                BoxShadow(
                  color: HipColors.jadeDeep.withValues(alpha: .16),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ])
            : null,
      ),
      child: Text(
        '$days',
        style: TextStyle(
          fontSize: days >= 100 ? 13 : 15,
          fontWeight: FontWeight.w700,
          height: 1,
          color: earned
              ? HipColors.onJade
              : next
              ? HipColors.text
              : HipColors.faint,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
    final caption = earned
        ? '${earnedAt!.month}/${earnedAt!.day}'
        : next
        ? t.pick('还差 $remaining 天', '$remaining left')
        : t.pick('未解锁', 'Locked');
    return Column(
      children: [
        celebrate ? _Celebrate(child: medal) : medal,
        const SizedBox(height: 8),
        Text(
          t.pick('$days 天', '$days d'),
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: earned || next ? FontWeight.w700 : FontWeight.w400,
            color: earned || next ? HipColors.text : HipColors.faint,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          caption,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 9.5,
            color: earned
                ? HipColors.jadeText
                : next
                ? HipColors.muted
                : HipColors.faint,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

/// One-time pop for a newly reached milestone: a small overshoot scale and
/// a jade glow that fades out.
class _Celebrate extends StatefulWidget {
  const _Celebrate({required this.child});
  final Widget child;
  @override
  State<_Celebrate> createState() => _CelebrateState();
}

class _CelebrateState extends State<_Celebrate>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    child: widget.child,
    builder: (context, child) {
      final t = _c.value;
      final pop = Curves.elasticOut.transform((t / .7).clamp(0, 1));
      final glow = math.sin(math.pi * t);
      return Transform.scale(
        scale: .7 + .3 * pop,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: HipColors.jade.withValues(alpha: .45 * glow),
                blurRadius: 18 * glow,
                spreadRadius: 2 * glow,
              ),
            ],
          ),
          child: child,
        ),
      );
    },
  );
}
