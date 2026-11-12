import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:ugk_trainer_runtime/engine.dart' show SessionResult;

import '../../core/storage/local_state_storage.dart';
import '../data/hip_routine_scope.dart';
import '../domain/hip_assessment.dart';
import '../domain/hip_library.dart';
import '../domain/hip_models.dart';
import '../domain/hip_pain.dart';
import '../domain/hip_progress.dart';
import '../domain/hip_session.dart';
import '../domain/hip_settings.dart';
import '../voice/voice_queue.dart';

enum CoachRoutineWriteStatus { saved, conflict, deleted }

class CoachRoutineWriteResult {
  const CoachRoutineWriteResult(this.status, {this.routine});
  final CoachRoutineWriteStatus status;
  final CustomRoutine? routine;
}

/// All HipLab state lives on the device under one key (kept distinct from
/// FlareLab's `LearningStore` key from the time both shared one project).
class HipStore extends ChangeNotifier {
  HipStore({
    required this.content,
    LocalStateStorage? storage,
    ReminderScheduler? reminders,
    DateTime Function()? clock,
  }) : _storage = storage ?? SharedPreferencesLocalStateStorage(),
       reminders = reminders ?? PlannedReminderScheduler(),
       _clock = clock ?? DateTime.now;

  static const storageKey = 'hiplab.state.v1';

  final HipContent content;
  final LocalStateStorage _storage;
  final ReminderScheduler reminders;
  final DateTime Function() _clock;
  late final scorer = HipAssessmentScorer(content.rules);
  late final planner = TrainingPlanner(content);

  DateTime now() => _clock();

  /// Legacy field retained only so old saved state still decodes without
  /// migration. The first-launch safety cards were removed: nothing reads or
  /// writes this, and it never gates training again.
  Map<String, bool>? safety;
  HipIdentity identity = HipIdentity.other;
  final List<({DateTime at, Map<String, ItemAnswer> answers})> assessments = [];
  final Set<String> doneDays = {};
  final List<PainEvent> painEvents = [];
  ReminderSettings reminder = const ReminderSettings();
  bool askNumbness = false;
  int minutes = 10;
  HipScene scene = HipScene.home;

  /// When the user last switched 办公/居家 by hand on 首页. A hand choice
  /// holds for the rest of that day; otherwise the scene follows the time
  /// of day (home redesign r1, 2026-11-02).
  DateTime? sceneChosenAt;

  /// 首页 folder membership (开哥 2026-11-11): the ids of 编排套路 and
  /// 我的训练组 added to each scene's folder, in the order they were added.
  /// Nothing here is a whitelist — 训练组 can add any 编排套路 or custom group.
  /// A fresh install starts with the two default 编排套路 (one per scene).
  final Map<HipScene, List<String>> homeRoutineIds = {
    for (final s in HipScene.values) s: [...?hiplabDefaultHomeRoutineIds[s]],
  };

  /// The selected 套路 in each scene's folder, kept across launches.
  final Map<HipScene, String> sceneRoutinePicks = {};

  /// 外观: 跟随系统 / 浅色 / 深色 (#14).
  HipThemeChoice theme = HipThemeChoice.system;

  HipLanguage language = HipLanguage.zh;

  /// 语音播报 (#13).
  VoiceSettings voice = const VoiceSettings();

  /// 我的训练组 (custom_routines v1, stored under `customRoutines`).
  final List<CustomRoutine> customRoutines = [];

  /// Highest 训练记录 streak milestone whose celebration was already shown
  /// (UI r2 M4): a newly reached one animates once, then is marked here.
  int celebratedMilestone = 0;

  Map<String, String> get coachPlanJson => {
    for (final routine in customRoutines)
      if (routine.coachPlan != null) routine.id: jsonEncode(routine.coachPlan),
  };

  /// Practice history, newest last, at most [SessionRecord.keep].
  final List<SessionRecord> sessions = [];

  /// No first-launch gate any more: every launch lands on the home page.
  bool get onboarded => true;

  /// The old safety-card veto is gone; training is never blocked by it.
  bool get blocked => false;

  AssessmentResult? get latestResult => assessments.isEmpty
      ? null
      : scorer.score(assessments.last.answers, identity);

  Map<HipDirection, DateTime> get lockedDirections =>
      PainHistory(painEvents).lockedUntil(now());

  /// Directions with a pain report in the last 7 days (练习库 hint).
  Set<HipDirection> get recentPainDirections =>
      PainHistory(painEvents).recentPain(now());

  int get streak => streakDays(doneDays, now());
  List<bool> get week => lastSevenDays(doneDays, now());

  TrainingProfile get profile => TrainingProfile.from(
    latestResult,
    identity: identity,
    extraLocks: lockedDirections.keys.toSet(),
  );

  TrainingPlan? get todayPlan =>
      planner.plan(minutes: minutes, scene: scene, profile: profile);

  /// 办公 on weekday daytime (07–18), 居家 otherwise.
  static HipScene sceneForTime(DateTime t) =>
      t.weekday <= DateTime.friday && t.hour >= 7 && t.hour < 18
      ? HipScene.chair
      : HipScene.home;

  bool get sceneChosenToday =>
      sceneChosenAt != null && dayKey(sceneChosenAt!) == dayKey(now());

  /// Points [scene] at the time of day unless it was chosen by hand today.
  /// Not saved: the next launch decides again.
  void applyTimeScene() {
    if (!sceneChosenToday) scene = sceneForTime(now());
  }

  /// 首页 办公/居家 switch: remembered for the rest of the day.
  Future<void> pickScene(HipScene value) {
    scene = value;
    sceneChosenAt = now();
    return _save();
  }

  /// Every 编排套路 in the content pack, including the 久坐提醒 micro set.
  /// 训练组 offers all of these (plus 我的训练组) for adding to 首页.
  List<HipRoutine> get libraryRoutines => [for (final r in content.routines) r];

  /// An entry that can live in a 首页 folder: an authored 套路 or a 我的训练组.
  /// Both resolve to the same playable [TrainingPlan], so 首页 needs no new
  /// trainer path to host custom groups.
  bool homeRoutineExists(String id) =>
      content.routines.any((r) => r.id == id) ||
      customRoutines.any((r) => r.id == id);

  /// The playable plan for any folder entry id, or null when the id is gone
  /// or the profile leaves it with no steps (a relax-only lock, for example).
  TrainingPlan? planForHomeRoutine(String id) {
    final routine = content.routines.where((r) => r.id == id).firstOrNull;
    if (routine != null) return planForRoutine(routine);
    final group = customRoutine(id);
    if (group == null) return null;
    return planner.customPlan(group, profile);
  }

  /// The ids actually available in [s]'s folder: stale ids (a deleted group
  /// or a 套路 no longer in the pack) and profiles that empty a plan are
  /// filtered out at read time, never written back into the saved membership.
  List<String> homeRoutines(HipScene s) => [
    for (final id in homeRoutineIds[s] ?? const <String>[])
      if (homeRoutineExists(id))
        if (planForHomeRoutine(id) case final plan? when plan.steps.isNotEmpty)
          id,
  ];

  /// The 套路 首页 resolves for [s]: the selected folder entry, else the first
  /// available one. A stale selected id falls back instead of crashing.
  String? homeRoutineId(HipScene s) {
    final list = homeRoutines(s);
    if (list.isEmpty) return null;
    final picked = sceneRoutinePicks[s];
    return picked != null && list.contains(picked) ? picked : list.first;
  }

  /// Legacy/home helper kept for callers that only need the resolved plan.
  TrainingPlan? sceneRoutinePlan(HipScene s) {
    final id = homeRoutineId(s);
    return id == null ? null : planForHomeRoutine(id);
  }

  /// Add/remove a 编排套路 or 我的训练组 from [s]'s 首页 folder. Adding selects
  /// it; removing selects the next remaining entry. Unknown ids are ignored.
  Future<void> setHomeRoutine(HipScene s, String id, {required bool added}) {
    if (!homeRoutineExists(id)) return Future<void>.value();
    final list = homeRoutineIds[s]!;
    if (added) {
      if (!list.contains(id)) list.add(id);
      sceneRoutinePicks[s] = id;
    } else {
      list.remove(id);
      if (sceneRoutinePicks[s] == id) {
        final remaining = homeRoutines(s);
        if (remaining.isEmpty) {
          sceneRoutinePicks.remove(s);
        } else {
          sceneRoutinePicks[s] = remaining.first;
        }
      }
    }
    return _save();
  }

  /// 首页 folder tap: remember the selected entry without switching scenes —
  /// the folder only ever lists the current scene's entries.
  Future<void> pickSceneRoutine(HipScene s, String id) {
    if (!homeRoutines(s).contains(id)) return Future<void>.value();
    sceneRoutinePicks[s] = id;
    return _save();
  }

  /// One routine as a session.
  TrainingPlan? planForRoutine(HipRoutine r) => planner.planFor([r], profile);

  TrainingPlan? get microPlan {
    final m = content.routines.where((r) => r.micro).firstOrNull;
    return m == null ? null : planner.planFor([m], profile);
  }

  Future<void> initialize() async {
    final text = await _storage.read(storageKey);
    if (text == null) return;
    try {
      _apply(jsonDecode(text) as Map<String, dynamic>);
    } on Object catch (e) {
      // Corrupt local state: start fresh but never crash the app.
      debugPrint('HipStore: ignoring unreadable state ($e)');
    }
    await reminders.apply(reminder, now());
  }

  void _apply(Map<String, dynamic> j) {
    final s = j['safety'];
    safety = s == null ? null : Map<String, bool>.from(s as Map);
    // The identity picker was removed with the first-launch flow. Old saved
    // values are tolerated but no new state is written from a picker.
    identity = j['identity'] == null
        ? HipIdentity.other
        : HipIdentity.byId(j['identity'] as String);
    assessments
      ..clear()
      ..addAll([
        for (final a in (j['assessments'] as List? ?? const []))
          (
            at: DateTime.parse((a as Map)['at'] as String),
            answers: {
              for (final e in Map<String, dynamic>.from(
                a['answers'] as Map,
              ).entries)
                e.key: ItemAnswer.fromJson(
                  Map<String, dynamic>.from(e.value as Map),
                ),
            },
          ),
      ]);
    doneDays
      ..clear()
      ..addAll([
        for (final d in (j['doneDays'] as List? ?? const [])) d as String,
      ]);
    painEvents
      ..clear()
      ..addAll([
        for (final e in (j['painEvents'] as List? ?? const []))
          PainEvent.fromJson(Map<String, dynamic>.from(e as Map)),
      ]);
    if (j['reminder'] is Map) {
      reminder = ReminderSettings.fromJson(
        Map<String, dynamic>.from(j['reminder'] as Map),
      );
    }
    askNumbness = j['askNumbness'] == true;
    minutes = TrainingPlanner.durations.contains(j['minutes'])
        ? j['minutes'] as int
        : 10;
    scene = j['scene'] == 'chair' ? HipScene.chair : HipScene.home;
    sceneChosenAt = DateTime.tryParse(j['sceneChosenAt'] as String? ?? '');
    homeRoutineIds
      ..clear()
      ..addEntries([for (final s in HipScene.values) MapEntry(s, <String>[])]);
    if (j['homeRoutineIds'] is Map) {
      for (final e in (j['homeRoutineIds'] as Map).entries) {
        final s = HipScene.values
            .where((value) => value.id == e.key)
            .firstOrNull;
        if (s == null || e.value is! List) continue;
        homeRoutineIds[s] = [
          for (final id in e.value as List)
            if (id is String) id,
        ];
      }
    } else {
      // Pre-folder state (or the one-id-per-scene draft): start from the
      // shipped defaults plus any earlier explicit scene choices.
      for (final s in HipScene.values) {
        homeRoutineIds[s] = [
          for (final r in hiplabDefaultHomeRoutines(content, s)) r.id,
        ];
      }
      if (j['sceneRoutinePicks'] is Map) {
        for (final e in (j['sceneRoutinePicks'] as Map).entries) {
          final s = HipScene.values
              .where((value) => value.id == e.key)
              .firstOrNull;
          final id = e.value;
          if (s == null ||
              id is! String ||
              libraryRoutines.every((r) => r.id != id)) {
            continue;
          }
          if (!homeRoutineIds[s]!.contains(id)) homeRoutineIds[s]!.add(id);
        }
      }
    }
    sceneRoutinePicks.clear();
    if (j['sceneRoutinePicks'] is Map) {
      for (final e in (j['sceneRoutinePicks'] as Map).entries) {
        // An unknown scene key or a non-string id is dropped, not fatal.
        final s = HipScene.values
            .where((value) => value.id == e.key)
            .firstOrNull;
        if (s != null && e.value is String) sceneRoutinePicks[s] = e.value;
      }
    }
    theme = HipThemeChoice.byId(j['theme'] as String?);
    language = HipLanguage.byId(j['language'] as String?);
    if (j['voice'] is Map) {
      voice = VoiceSettings.fromJson(
        Map<String, dynamic>.from(j['voice'] as Map),
      );
    }
    customRoutines
      ..clear()
      ..addAll(CustomRoutinesCodec.decode(j['customRoutines'], content));
    celebratedMilestone = (j['celebratedMilestone'] as num?)?.toInt() ?? 0;
    sessions
      ..clear()
      ..addAll([
        for (final r in (j['sessions'] as List? ?? const []))
          ?SessionRecord.fromJson(r),
      ]);
  }

  Map<String, Object?> toJson() => {
    'v': 1,
    'safety': safety,
    'identity': identity.id,
    'assessments': [
      for (final a in assessments)
        {
          'at': a.at.toIso8601String(),
          'answers': {
            for (final e in a.answers.entries) e.key: e.value.toJson(),
          },
        },
    ],
    'doneDays': doneDays.toList()..sort(),
    'painEvents': [for (final e in painEvents) e.toJson()],
    'reminder': reminder.toJson(),
    'askNumbness': askNumbness,
    'minutes': minutes,
    'scene': scene.id,
    'sceneChosenAt': sceneChosenAt?.toIso8601String(),
    'homeRoutineIds': {
      for (final e in homeRoutineIds.entries) e.key.id: e.value,
    },
    'sceneRoutinePicks': {
      for (final e in sceneRoutinePicks.entries) e.key.id: e.value,
    },
    'theme': theme.id,
    'language': language.id,
    'voice': voice.toJson(),
    'customRoutines': CustomRoutinesCodec.encode(customRoutines),
    'sessions': [for (final r in sessions) r.toJson()],
    if (celebratedMilestone > 0) 'celebratedMilestone': celebratedMilestone,
  };

  Future<void> _stateWriteTail = Future<void>.value();

  Future<T> _queueStateWrite<T>(Future<T> Function() operation) {
    final result = _stateWriteTail.then((_) => operation());
    _stateWriteTail = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }

  Future<void> _save() {
    notifyListeners();
    return _queueStateWrite(
      () => _storage.write(storageKey, jsonEncode(toJson())),
    );
  }

  /// Kept as a no-op so legacy callers cannot re-enable the removed gate.
  Future<void> setSafety(Map<String, bool> answers) => Future<void>.value();

  Future<void> setIdentity(HipIdentity value) {
    identity = value;
    return _save();
  }

  Future<AssessmentResult> saveAssessment(
    Map<String, ItemAnswer> answers,
  ) async {
    assessments.add((at: now(), answers: Map.unmodifiable(answers)));
    await _save();
    return latestResult!;
  }

  Future<void> choose({int? minutes, HipScene? scene}) {
    if (minutes != null) this.minutes = minutes;
    if (scene != null) this.scene = scene;
    return _save();
  }

  /// A finished (or partly finished, ≥ 1 drill) session counts for the
  /// streak – except 单练, which is only written to the history (拍板 3).
  Future<void> completeSession(SessionPainLadder ladder, {TrainingPlan? plan}) {
    if (plan == null || plan.source.countsForStreak) {
      doneDays.add(dayKey(now()));
    }
    _record(plan, completed: true);
    return _recordLadder(ladder);
  }

  /// SDK completion saves are keyed by the id fixed at session start.
  /// Stage the update until storage accepts it: ResultSaver may then retry
  /// a failed save without duplicate history, streak or pain-ladder events.
  Future<void> saveTrainerSession(
    SessionResult result, {
    required TrainingPlan plan,
    required SessionPainLadder ladder,
    Map<int, String> feedback = const {},
  }) {
    return _queueStateWrite(() async {
      final existing = sessions.indexWhere(
        (s) => s.sessionId == result.sessionId,
      );
      final record = SessionRecord(
        // Practice history/streak use the App's completion-day clock;
        // the SDK's original start/end timestamps remain in trainerResult.
        at: existing < 0 ? now() : sessions[existing].at,
        source: plan.source,
        refId: plan.refId,
        title: plan.title,
        seconds: result.activeSeconds.round(),
        completed:
            result.completedExercises > 0 &&
            result.items.any((item) => item.completedSets > 0),
        sessionId: result.sessionId,
        trainerResult: Map.unmodifiable({
          ...result.toJson(),
          'full': result.full,
        }),
        feedback: Map.unmodifiable(feedback),
      );
      final nextSessions = [...sessions];
      if (existing < 0) {
        nextSessions.add(record);
      } else {
        nextSessions[existing] = record;
      }
      if (nextSessions.length > SessionRecord.keep) {
        nextSessions.removeRange(0, nextSessions.length - SessionRecord.keep);
      }
      final nextDays = {...doneDays};
      if (record.completed && plan.source.countsForStreak) {
        nextDays.add(dayKey(record.at));
      }
      final addedPain = existing >= 0
          ? const <PainEvent>[]
          : [
              for (final d in ladder.skippedDirections)
                PainEvent(result.endedAt.toLocal(), d, 'skip'),
            ];
      final nextPain = [...painEvents, ...addedPain];
      final nextNumbness = askNumbness || ladder.ended;
      final state = toJson()
        ..['sessions'] = [for (final s in nextSessions) s.toJson()]
        ..['doneDays'] = (nextDays.toList()..sort())
        ..['painEvents'] = [for (final e in nextPain) e.toJson()]
        ..['askNumbness'] = nextNumbness;
      await _storage.write(storageKey, jsonEncode(state));
      sessions
        ..clear()
        ..addAll(nextSessions);
      doneDays.addAll(nextDays);
      painEvents.addAll(addedPain);
      askNumbness = nextNumbness;
      notifyListeners();
    });
  }

  /// Left before finishing a drill: pain ladder kept, history marks it
  /// unfinished, the streak is untouched.
  Future<void> recordLadder(SessionPainLadder ladder, {TrainingPlan? plan}) {
    _record(plan, completed: false);
    return _recordLadder(ladder);
  }

  void _record(TrainingPlan? plan, {required bool completed}) {
    if (plan == null) return;
    sessions.add(
      SessionRecord(
        at: now(),
        source: plan.source,
        refId: plan.refId,
        title: plan.title,
        seconds: plan.seconds,
        completed: completed,
      ),
    );
    if (sessions.length > SessionRecord.keep) {
      sessions.removeRange(0, sessions.length - SessionRecord.keep);
    }
  }

  /// Every tap on 疼 (关节夹着疼) in the player: feeds 「最近疼过」.
  Future<void> recordPain(HipDirection direction) {
    painEvents.add(PainEvent(now(), direction, 'pain'));
    return _save();
  }

  Future<void> _recordLadder(SessionPainLadder ladder) {
    final at = now();
    for (final d in ladder.skippedDirections) {
      painEvents.add(PainEvent(at, d, 'skip'));
    }
    if (ladder.ended) askNumbness = true;
    return _save();
  }

  Future<void> recordNerve(HipDirection direction) {
    painEvents.add(PainEvent(now(), direction, 'nerve'));
    askNumbness = true;
    return _save();
  }

  Future<void> answerNumbness({required bool stillNumb}) {
    askNumbness = stillNumb;
    return _save();
  }

  /// 训练记录 showed the celebration for milestone [days].
  Future<void> markCelebrated(int days) {
    if (days <= celebratedMilestone) return Future<void>.value();
    celebratedMilestone = days;
    return _save();
  }

  Future<void> setTheme(HipThemeChoice value) {
    theme = value;
    return _save();
  }

  Future<void> setVoice(VoiceSettings value) {
    voice = value;
    return _save();
  }

  Future<void> setLanguage(HipLanguage value) {
    language = value;
    return _save();
  }

  // ── 我的训练组 ──

  CustomRoutine? customRoutine(String id) =>
      customRoutines.where((r) => r.id == id).firstOrNull;

  final _rand = math.Random();

  /// A fresh id: `c_<yyyymmdd>_<4 hex>`.
  String newCustomId() {
    final d = dayKey(now()).replaceAll('-', '');
    while (true) {
      final id =
          'c_${d}_${_rand.nextInt(0x10000).toRadixString(16).padLeft(4, '0')}';
      if (customRoutine(id) == null) return id;
    }
  }

  /// 我的训练组 N: the first number not taken.
  String nextCustomName({String language = 'zh'}) {
    for (var n = customRoutines.length + 1; ; n++) {
      final name = language == 'en' ? 'My group $n' : '我的训练组 $n';
      if (customRoutines.every((r) => r.name != name)) return name;
    }
  }

  /// Inserts or replaces (by id); stamps updatedAt.
  Future<CustomRoutine> saveCustomRoutine(CustomRoutine r) => _queueStateWrite(
    () async {
      final at = now();
      final existing = customRoutine(r.id);
      if (existing?.coachPlan != null) {
        throw StateError(
          'A complete coach plan must use the admitted SDK save path.',
        );
      }
      final hasFullPlan = r.coachPlan != null;
      final saved = CustomRoutine(
        id: r.id,
        name: CustomRoutine.cleanName(r.name).isEmpty
            ? nextCustomName()
            : CustomRoutine.cleanName(r.name),
        steps: !hasFullPlan && r.steps.length > CustomRoutine.maxSteps
            ? r.steps.sublist(0, CustomRoutine.maxSteps)
            : r.steps,
        restSeconds: hasFullPlan || CustomRoutine.rests.contains(r.restSeconds)
            ? r.restSeconds
            : CustomRoutine.defaultRest,
        fromRoutine: r.fromRoutine,
        createdAt: existing?.createdAt ?? r.createdAt ?? at,
        updatedAt: at,
        coachPlan: r.coachPlan,
        coachSdkVersion: hasFullPlan ? r.coachSdkVersion : null,
      );
      await _persistCustomRoutines(saved);
      return saved;
    },
  );

  /// The chat card uses a host revision independent of the SDK plan version.
  static String customRoutineRevision(CustomRoutine routine) =>
      jsonEncode(routine.toJson());

  Future<CoachRoutineWriteResult> writeCoachCustomRoutine(
    CustomRoutine routine, {
    required bool update,
    Object? expectedStorageRevision,
  }) => _queueStateWrite(() async {
    final current = customRoutine(routine.id);
    if (update && current == null) {
      return const CoachRoutineWriteResult(CoachRoutineWriteStatus.deleted);
    }
    if ((update &&
            customRoutineRevision(current!) != expectedStorageRevision) ||
        (!update && current != null)) {
      return const CoachRoutineWriteResult(CoachRoutineWriteStatus.conflict);
    }
    await _persistCustomRoutines(routine);
    return CoachRoutineWriteResult(
      CoachRoutineWriteStatus.saved,
      routine: routine,
    );
  });

  /// Publish only after the same durable write used by the library succeeds.
  Future<void> _persistCustomRoutines(CustomRoutine saved) async {
    final next = [...customRoutines];
    final i = next.indexWhere((x) => x.id == saved.id);
    if (i < 0) {
      next.add(saved);
    } else {
      next[i] = saved;
    }
    final state = toJson()
      ..['customRoutines'] = CustomRoutinesCodec.encode(next);
    await _storage.write(storageKey, jsonEncode(state));
    customRoutines
      ..clear()
      ..addAll(next);
    notifyListeners();
  }

  Future<void> deleteCustomRoutine(String id) => _queueStateWrite(() async {
    final next = customRoutines.where((r) => r.id != id).toList();
    final state = toJson()
      ..['customRoutines'] = CustomRoutinesCodec.encode(next);
    await _storage.write(storageKey, jsonEncode(state));
    customRoutines
      ..clear()
      ..addAll(next);
    notifyListeners();
  });

  Future<void> setReminder(ReminderSettings value) async {
    reminder = value;
    await reminders.apply(value, now());
    await _save();
  }
}
