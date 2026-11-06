// 训练记录 as an achievement page (UI r2 M4, feedback #12): a big streak
// number with the running totals, this week's dots, a 16-week check-in
// heatmap, streak milestones and the latest sessions. Only data the store
// keeps: doneDays (streak days) and the session history (title, time,
// seconds). The 髋部自测 radar lives on the 自测 page now (PLAN §1).
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../control/hip_store.dart';
import '../domain/hip_library.dart';
import '../domain/hip_progress.dart';
import 'hip_icons.dart';
import 'hip_page_kit.dart';
import 'hip_theme.dart';
import 'hip_widgets.dart';

const _weekdays = ['一', '二', '三', '四', '五', '六', '日'];

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
    final finished = [for (final s in store.sessions) if (s.completed) s];
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
    final children = <Widget>[
      _Hero(
        streak: streak,
        trainedToday: done.contains(dayKey(today)),
        totalDays: done.length,
        sessions: finished.length,
        minutes: (seconds / 60).round(),
        hasHistory: done.isNotEmpty,
      ),
      if (empty) ...[
        const SizedBox(height: 20),
        _Empty(onStart: widget.onStartPractice),
      ] else ...[
        HipSection(
          '本周',
          trailing: Text(
            '${_weekDone(done, today)}/7',
            key: const ValueKey('records-week-count'),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: HipColors.jadeText,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
        HipListGroup(
          children: [_Week(done: done, today: today)],
        ),
        const HipSection('近 16 周'),
        HipListGroup(
          children: [
            _Heatmap(done: done, minutes: minutesByDay, today: today),
          ],
        ),
      ],
      const HipSection('里程碑'),
      HipListGroup(
        children: [
          _Milestones(
            streak: streak,
            earned: history.earned,
            celebrate: _celebrate,
          ),
        ],
      ),
      if (store.sessions.isNotEmpty) ...[
        const HipSection('最近训练'),
        HipListGroup(
          key: const ValueKey('records-recent'),
          children: [
            for (final s in store.sessions.reversed.take(5)) _recent(s, today),
          ],
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

  Widget _recent(SessionRecord s, DateTime today) {
    final d = DateTime(s.at.year, s.at.month, s.at.day);
    final ago = today.difference(d).inDays;
    final day = ago == 0
        ? '今天'
        : ago == 1
        ? '昨天'
        : '${s.at.month}月${s.at.day}日 周${_weekdays[s.at.weekday - 1]}';
    final time =
        '${s.at.hour.toString().padLeft(2, '0')}:${s.at.minute.toString().padLeft(2, '0')}';
    final mins = math.max(1, (s.seconds / 60).round());
    return HipListRow(
      glyph: s.completed ? HipGlyph.checkCircle : HipGlyph.pause,
      title: s.title.isEmpty ? '训练' : s.title,
      subtitle: s.completed ? '$day $time' : '$day $time · 未完成',
      meta: '$mins 分钟',
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

  String get _line {
    if (streak == 0) {
      return hasHistory ? '歇了几天也没关系，今天练一次重新开始' : '练完第一次，连续天数就从 1 开始';
    }
    if (streakMilestones.contains(streak)) return '达成连续 $streak 天，真不容易！';
    final next = streakMilestones.firstWhere(
      (m) => m > streak,
      orElse: () => 0,
    );
    final keep = trainedToday ? '' : '今天练一次就能续上，';
    if (next == 0) return '$keep已经是长期习惯了';
    return '$keep再坚持 ${next - streak} 天，解锁「$next 天」';
  }

  @override
  Widget build(BuildContext context) {
    const tab = [FontFeature.tabularFigures()];
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$streak',
                key: const ValueKey('records-streak'),
                style: TextStyle(
                  fontSize: 56,
                  height: 1.05,
                  fontWeight: FontWeight.w700,
                  color: streak > 0 ? HipColors.jadeText : HipColors.faint,
                  fontFeatures: tab,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '天连续',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: HipColors.text,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _line,
            key: const ValueKey('records-cheer'),
            style: TextStyle(fontSize: 13, color: HipColors.muted, height: 1.4),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _stat('累计天数', '$totalDays', '天'),
              _stat('累计次数', '$sessions', '次'),
              _stat('累计时长', '$minutes', '分钟'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value, String unit) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: HipColors.text,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              TextSpan(
                text: ' $unit',
                style: TextStyle(fontSize: 12, color: HipColors.muted),
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 12, color: HipColors.faint)),
      ],
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
              '还没有训练记录',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: HipColors.text,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '每练完一次，这里会点亮一格，\n连续天数、打卡日历和里程碑都会慢慢长出来。',
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
                label: '开始今天的训练',
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
    return Padding(
      key: const ValueKey('records-week'),
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
      child: Row(
        children: [
          for (var i = 0; i < 7; i++)
            Expanded(
              child: Builder(
                builder: (_) {
                  final d = DateTime(mon.year, mon.month, mon.day + i);
                  final isToday = d == today;
                  final future = d.isAfter(today);
                  final on = done.contains(dayKey(d));
                  return Column(
                    children: [
                      Container(
                        key: ValueKey('week-dot-$i'),
                        width: 30,
                        height: 30,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: on
                              ? HipColors.jade
                              : HipColors.text.withValues(
                                  alpha: future ? .04 : .08,
                                ),
                        ),
                        child: on
                            ? HipIcon(
                                HipGlyph.check,
                                size: 16,
                                strokeWidth: 2.4,
                                color: HipColors.onJade,
                              )
                            : null,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isToday ? '今天' : _weekdays[i],
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isToday
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: isToday
                              ? HipColors.jadeText
                              : HipColors.faint,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

// ───────────────────────── heatmap ─────────────────────────

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
  static const gap = 3.0;

  @override
  Widget build(BuildContext context) {
    final first = weekStart(today).subtract(const Duration(days: 7 * (weeks - 1)));
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
    final labelStyle = TextStyle(fontSize: 11, color: HipColors.faint);
    return Padding(
      key: const ValueKey('records-heatmap'),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: LayoutBuilder(
        builder: (context, c) {
          const dayCol = 18.0;
          final cell = (c.maxWidth - dayCol - gap * (weeks - 1)) / weeks;
          // A month label over the column holding its 1st day.
          final months = <(int, String)>[];
          for (var w = 0; w < weeks; w++) {
            for (var d = 0; d < 7; d++) {
              final day = at(w, d);
              if (day.day == 1 && !day.isAfter(today)) {
                months.add((w, '${day.month}月'));
              }
            }
          }
          final gridW = c.maxWidth - dayCol;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 16,
                child: Stack(
                  children: [
                    for (final (w, t) in months)
                      Positioned(
                        left:
                            dayCol + math.min(w * (cell + gap), gridW - 30),
                        child: Text(t, style: labelStyle),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: dayCol,
                    height: cell * 7 + gap * 6,
                    child: Stack(
                      children: [
                        for (final d in [0, 2, 4, 6])
                          Positioned(
                            top: d * (cell + gap) + (cell - 13) / 2,
                            child: Text(
                              _weekdays[d],
                              style: labelStyle.copyWith(height: 1.2),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: CustomPaint(
                      size: Size(double.infinity, cell * 7 + gap * 6),
                      painter: _HeatPainter(
                        levels,
                        cell,
                        HipColors.palette,
                        today: (
                          today.difference(first).inDays ~/ 7,
                          today.weekday - 1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('少', style: labelStyle),
                  const SizedBox(width: 6),
                  for (var l = 0; l <= 4; l++) ...[
                    Container(
                      width: 11,
                      height: 11,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3),
                        color: _heatColor(l, HipColors.palette),
                      ),
                    ),
                    const SizedBox(width: 3),
                  ],
                  const SizedBox(width: 3),
                  Text('多', style: labelStyle),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

Color _heatColor(int level, HipPalette p) => switch (level) {
  0 => p.text.withValues(alpha: p.isDark ? .07 : .07),
  1 => p.jade.withValues(alpha: .3),
  2 => p.jade.withValues(alpha: .52),
  3 => p.jade.withValues(alpha: .76),
  _ => p.jade,
};

class _HeatPainter extends CustomPainter {
  _HeatPainter(this.levels, this.cell, this.p, {required this.today});
  final List<List<int>> levels;
  final double cell;
  final HipPalette p;
  final (int, int) today;

  @override
  void paint(Canvas canvas, Size size) {
    for (var w = 0; w < levels.length; w++) {
      for (var d = 0; d < 7; d++) {
        final l = levels[w][d];
        if (l < 0) continue;
        final r = Rect.fromLTWH(
          w * (cell + _Heatmap.gap),
          d * (cell + _Heatmap.gap),
          cell,
          cell,
        );
        final rr = RRect.fromRectAndRadius(r, const Radius.circular(3));
        canvas.drawRRect(rr, Paint()..color = _heatColor(l, p));
        if ((w, d) == today) {
          // Today: a small inner dot, not an outline.
          canvas.drawCircle(
            r.center,
            math.max(1.5, cell * .12),
            Paint()..color = l >= 2 ? p.onJade : p.jade,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(_HeatPainter old) =>
      old.levels != levels || old.cell != cell || old.p != p;
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 16, 6, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final m in streakMilestones)
            Expanded(
              child: _Badge(
                key: ValueKey('milestone-$m'),
                days: m,
                earnedAt: earned[m],
                progress: m == next ? (streak / m).clamp(0, 1).toDouble() : null,
                remaining: m == next ? m - streak : null,
                celebrate: m == celebrate,
              ),
            ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    super.key,
    required this.days,
    required this.earnedAt,
    required this.progress,
    required this.remaining,
    required this.celebrate,
  });
  final int days;
  final DateTime? earnedAt;
  final double? progress;
  final int? remaining;
  final bool celebrate;

  @override
  Widget build(BuildContext context) {
    final p = HipColors.palette;
    final earned = earnedAt != null;
    final medal = SizedBox(
      width: 46,
      height: 46,
      child: CustomPaint(
        painter: _BadgePainter(
          earned: earned,
          progress: progress,
          p: p,
        ),
        child: Center(
          child: Text(
            '$days',
            style: TextStyle(
              fontSize: days >= 100 ? 15 : 17,
              fontWeight: FontWeight.w700,
              height: 1,
              color: earned
                  ? p.onJade
                  : progress != null
                  ? p.text
                  : p.faint,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ),
    );
    final caption = earned
        ? '${earnedAt!.month}/${earnedAt!.day}'
        : remaining != null
        ? '还差 $remaining 天'
        : '未解锁';
    return Column(
      children: [
        celebrate ? _Celebrate(child: medal) : medal,
        const SizedBox(height: 8),
        Text(
          '$days 天',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: earned || progress != null ? p.text : p.faint,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          caption,
          maxLines: 1,
          overflow: TextOverflow.visible,
          softWrap: false,
          style: TextStyle(
            fontSize: 11,
            color: earned
                ? HipColors.jadeText
                : progress != null
                ? p.muted
                : p.faint.withValues(alpha: .7),
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

/// Six-notch medal: earned = solid jade with a soft halo; next = a track
/// ring filling with the current streak; locked = a dim disc.
class _BadgePainter extends CustomPainter {
  _BadgePainter({required this.earned, required this.progress, required this.p});
  final bool earned;
  final double? progress;
  final HipPalette p;

  Path _medal(Offset c, double r) {
    // A rounded 12-point rosette, the HipIcon radar's six axes doubled.
    final path = Path();
    const n = 12;
    for (var i = 0; i <= n * 2; i++) {
      final a = -math.pi / 2 + i * math.pi / n;
      final rr = i.isEven ? r : r * .9;
      final pt = c + Offset(math.cos(a), math.sin(a)) * rr;
      if (i == 0) {
        path.moveTo(pt.dx, pt.dy);
      } else {
        path.lineTo(pt.dx, pt.dy);
      }
    }
    return path..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    if (earned) {
      canvas.drawPath(
        _medal(c, r),
        Paint()..color = p.jade.withValues(alpha: .22),
      );
      canvas.drawCircle(c, r * .78, Paint()..color = p.jade);
      return;
    }
    canvas.drawCircle(
      c,
      r * .78,
      Paint()..color = p.text.withValues(alpha: progress != null ? .08 : .05),
    );
    if (progress != null) {
      final ring = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;
      final rect = Rect.fromCircle(center: c, radius: r * .9);
      canvas.drawArc(
        rect,
        0,
        math.pi * 2,
        false,
        ring..color = p.text.withValues(alpha: .08),
      );
      if (progress! > 0) {
        canvas.drawArc(
          rect,
          -math.pi / 2,
          math.pi * 2 * progress!,
          false,
          ring..color = p.jade,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_BadgePainter old) =>
      old.earned != earned || old.progress != progress || old.p != p;
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
