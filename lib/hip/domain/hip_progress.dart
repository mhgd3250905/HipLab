/// Streak and sitting-reminder rules. Pure, clock injected by the caller.
library;

String dayKey(DateTime t) =>
    '${t.year.toString().padLeft(4, '0')}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';

DateTime _day(DateTime t) => DateTime(t.year, t.month, t.day);

/// Consecutive training days ending today, or ending yesterday when today is
/// not trained yet (an unfinished today never breaks the streak).
int streakDays(Set<String> doneDays, DateTime now) {
  var cursor = _day(now);
  if (!doneDays.contains(dayKey(cursor))) {
    cursor = cursor.subtract(const Duration(days: 1));
  }
  var n = 0;
  while (doneDays.contains(dayKey(cursor))) {
    n++;
    cursor = DateTime(cursor.year, cursor.month, cursor.day - 1);
  }
  return n;
}

/// The last 7 days, oldest first, for the home dots.
List<bool> lastSevenDays(Set<String> doneDays, DateTime now) => [
  for (var i = 6; i >= 0; i--)
    doneDays.contains(dayKey(DateTime(now.year, now.month, now.day - i))),
];

class ReminderSettings {
  const ReminderSettings({
    this.enabled = false,
    this.intervalMinutes = 60,
    this.startHour = 9,
    this.endHour = 18,
    this.weekdaysOnly = true,
  });
  final bool enabled;

  /// 45 or 60 (规划 v1 §三.5).
  final int intervalMinutes;
  final int startHour;
  final int endHour;
  final bool weekdaysOnly;

  ReminderSettings copyWith({bool? enabled, int? intervalMinutes}) =>
      ReminderSettings(
        enabled: enabled ?? this.enabled,
        intervalMinutes: intervalMinutes ?? this.intervalMinutes,
        startHour: startHour,
        endHour: endHour,
        weekdaysOnly: weekdaysOnly,
      );

  Map<String, Object?> toJson() => {
    'enabled': enabled,
    'interval': intervalMinutes,
    'start': startHour,
    'end': endHour,
    'weekdaysOnly': weekdaysOnly,
  };

  factory ReminderSettings.fromJson(Map<String, dynamic> j) => ReminderSettings(
    enabled: j['enabled'] == true,
    intervalMinutes: (j['interval'] as int?) == 45 ? 45 : 60,
    startHour: (j['start'] as int?) ?? 9,
    endHour: (j['end'] as int?) ?? 18,
    weekdaysOnly: j['weekdaysOnly'] != false,
  );

  bool _workday(DateTime t) => !weekdaysOnly || t.weekday <= DateTime.friday;

  /// Next reminder strictly after [now]: start + k·interval inside the work
  /// window, skipping weekends when [weekdaysOnly]. Null when disabled.
  DateTime? nextAfter(DateTime now) {
    if (!enabled) return null;
    for (var d = 0; d < 8; d++) {
      final day = DateTime(now.year, now.month, now.day + d);
      if (!_workday(day)) continue;
      final end = DateTime(day.year, day.month, day.day, endHour);
      var t = DateTime(
        day.year,
        day.month,
        day.day,
        startHour,
      ).add(Duration(minutes: intervalMinutes));
      while (!t.isAfter(now) && t.isBefore(end)) {
        t = t.add(Duration(minutes: intervalMinutes));
      }
      if (t.isAfter(now) && !t.isAfter(end)) return t;
    }
    return null;
  }

  /// The day's fire times (used to schedule a batch of local notifications).
  List<DateTime> firesOn(DateTime day) {
    if (!enabled || !_workday(day)) return const [];
    final out = <DateTime>[];
    final end = DateTime(day.year, day.month, day.day, endHour);
    var t = DateTime(
      day.year,
      day.month,
      day.day,
      startHour,
    ).add(Duration(minutes: intervalMinutes));
    while (!t.isAfter(end)) {
      out.add(t);
      t = t.add(Duration(minutes: intervalMinutes));
    }
    return out;
  }
}

/// Platform boundary for the sitting reminder. The MVP ships without a
/// notification plugin yet (still to be chosen for this repository), so
/// the default implementation only records the schedule. A
/// `flutter_local_notifications` implementation plugs in here later.
abstract interface class ReminderScheduler {
  bool get deliversNotifications;
  Future<void> apply(ReminderSettings settings, DateTime now);
}

class PlannedReminderScheduler implements ReminderScheduler {
  DateTime? next;
  @override
  bool get deliversNotifications => false;
  @override
  Future<void> apply(ReminderSettings settings, DateTime now) async {
    next = settings.nextAfter(now);
  }
}

// ───────────────────────── 训练记录 achievements (UI r2 M4) ─────────────────

/// Consecutive-day milestones on 训练记录.
const streakMilestones = [3, 7, 14, 30, 60, 100];

DateTime? _parseDay(String k) {
  final p = k.split('-');
  if (p.length != 3) return null;
  final y = int.tryParse(p[0]), m = int.tryParse(p[1]), d = int.tryParse(p[2]);
  if (y == null || m == null || d == null) return null;
  return DateTime(y, m, d);
}

/// Longest run of consecutive training days ever, and for each milestone the
/// day a run first reached it (absent = not earned yet).
({int best, Map<int, DateTime> earned}) streakHistory(Set<String> doneDays) {
  final days = [for (final k in doneDays) ?_parseDay(k)]..sort();
  var best = 0, run = 0;
  DateTime? prev;
  final earned = <int, DateTime>{};
  for (final d in days) {
    final consecutive =
        prev != null &&
        DateTime(prev.year, prev.month, prev.day + 1) == d;
    if (prev != null && d == prev) continue;
    run = consecutive ? run + 1 : 1;
    prev = d;
    if (run > best) best = run;
    for (final m in streakMilestones) {
      if (run == m) earned.putIfAbsent(m, () => d);
    }
  }
  return (best: best, earned: earned);
}

/// Monday of the week [t] falls in.
DateTime weekStart(DateTime t) => DateTime(t.year, t.month, t.day - (t.weekday - 1));

/// Heat level 0–4 for one day: 0 not trained, then by trained minutes (a
/// trained day without a timed record still shows the lightest level).
int heatLevel({required bool trained, required int minutes}) {
  if (!trained && minutes <= 0) return 0;
  if (minutes < 5) return 1;
  if (minutes < 10) return 2;
  if (minutes < 20) return 3;
  return 4;
}
