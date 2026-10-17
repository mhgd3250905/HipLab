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
