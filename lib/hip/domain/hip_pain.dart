import 'hip_models.dart';

/// What the user tapped after a drill: 疼 → which kind.
enum PainKind {
  /// 关节夹着疼 — walk down the ladder.
  pinch,

  /// 麻、刺、往下窜 — stop the session immediately.
  nerve,
}

enum PainActionType { reduceAmplitude, substitute, skipDirection, endSession }

class PainAction {
  const PainAction(this.type, {this.direction, this.substituteId});
  final PainActionType type;
  final HipDirection? direction;
  final String? substituteId;

  /// One short spoken / subtitle line. Never "忍一忍"; always "别勉强".
  String get cue => switch (type) {
    PainActionType.reduceAmplitude => '幅度小一点，别勉强',
    PainActionType.substitute => '换一个更轻松的动作，别勉强',
    PainActionType.skipDirection => '这里今天只做放松，别勉强',
    PainActionType.endSession => '先停下来，今天就到这里',
  };
}

/// In-session ladder (自测设计.md §4.4):
/// 1st pain on a drill → smaller range; still painful / 2nd pain in the same
/// direction → swap to the L1 alternative; alternative painful → skip the
/// direction (relax only for the rest of today). Nerve-type pain ends it.
class SessionPainLadder {
  SessionPainLadder(this.content);
  final HipContent content;

  final Map<String, int> _drillPain = {};
  final Map<HipDirection, int> _directionPain = {};
  final Set<String> _substitutes = {};
  final Set<HipDirection> skippedDirections = {};
  final Set<String> reducedDrills = {};
  bool ended = false;

  static HipDirection primaryDirection(HipDrill d) => d.directions.first;

  PainAction report(String drillId, PainKind kind, {String? alternative}) {
    final drill = content.drill(drillId);
    final dir = primaryDirection(drill);
    if (kind == PainKind.nerve) {
      ended = true;
      return PainAction(PainActionType.endSession, direction: dir);
    }
    final drillCount = (_drillPain[drillId] ?? 0) + 1;
    final dirCount = (_directionPain[dir] ?? 0) + 1;
    _drillPain[drillId] = drillCount;
    _directionPain[dir] = dirCount;

    if (_substitutes.contains(drillId) || skippedDirections.contains(dir)) {
      skippedDirections.add(dir);
      return PainAction(PainActionType.skipDirection, direction: dir);
    }
    if (drillCount == 1 && dirCount == 1) {
      reducedDrills.add(drillId);
      return PainAction(PainActionType.reduceAmplitude, direction: dir);
    }
    final alt = alternative ?? drill.alternative;
    if (alt != null && content.drills.containsKey(alt)) {
      _substitutes.add(alt);
      return PainAction(
        PainActionType.substitute,
        direction: dir,
        substituteId: alt,
      );
    }
    skippedDirections.add(dir);
    return PainAction(PainActionType.skipDirection, direction: dir);
  }
}

class PainEvent {
  const PainEvent(this.at, this.direction, this.type);
  final DateTime at;
  final HipDirection direction;

  /// `skip` (ladder reached "skip direction"), `nerve`, or `pain` (every
  /// tap on 疼 → 关节夹着疼, 练习库 2026-10-19; feeds 「最近疼过」 only).
  final String type;

  Map<String, Object?> toJson() => {
    'at': at.toIso8601String(),
    'direction': direction.id,
    'type': type,
  };
  factory PainEvent.fromJson(Map<String, dynamic> j) => PainEvent(
    DateTime.parse(j['at'] as String),
    HipDirection.byId(j['direction'] as String),
    j['type'] as String,
  );
}

/// Across sessions: two "skip" events for one direction within 7 days lock it
/// to relax-only for 7 days and show the "问问医生或专业人士" card.
class PainHistory {
  const PainHistory(this.events);
  final List<PainEvent> events;

  static const window = Duration(days: 7);

  Map<HipDirection, DateTime> lockedUntil(DateTime now) {
    final out = <HipDirection, DateTime>{};
    for (final d in HipDirection.values) {
      final skips =
          events.where((e) => e.direction == d && e.type == 'skip').toList()
            ..sort((a, b) => a.at.compareTo(b.at));
      for (var i = 1; i < skips.length; i++) {
        if (skips[i].at.difference(skips[i - 1].at) <= window) {
          final until = skips[i].at.add(window);
          if (until.isAfter(now) &&
              (out[d] == null || until.isAfter(out[d]!))) {
            out[d] = until;
          }
        }
      }
    }
    return out;
  }

  /// Directions with any pain report (疼 / skip / nerve) in the last 7 days:
  /// the library's 「这个方向最近疼过」 hint. Never a lock by itself.
  Set<HipDirection> recentPain(DateTime now) => {
    for (final e in events)
      if (!e.at.isAfter(now) && now.difference(e.at) <= window) e.direction,
  };

  bool get lastWasNerve => events.isNotEmpty && events.last.type == 'nerve';
}
