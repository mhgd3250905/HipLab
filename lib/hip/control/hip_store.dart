import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../../core/storage/local_state_storage.dart';
import '../domain/hip_assessment.dart';
import '../domain/hip_library.dart';
import '../domain/hip_models.dart';
import '../domain/hip_pain.dart';
import '../domain/hip_progress.dart';
import '../domain/hip_session.dart';
import '../domain/hip_settings.dart';
import '../voice/voice_queue.dart';

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

  /// card id → answered "有". Null until the first-launch cards are done.
  Map<String, bool>? safety;
  HipIdentity? identity;
  final List<({DateTime at, Map<String, ItemAnswer> answers})> assessments = [];
  final Set<String> doneDays = {};
  final List<PainEvent> painEvents = [];
  ReminderSettings reminder = const ReminderSettings();
  bool askNumbness = false;
  int minutes = 10;
  HipScene scene = HipScene.home;

  /// 外观: 跟随系统 / 浅色 / 深色 (#14).
  HipThemeChoice theme = HipThemeChoice.system;

  /// 语音播报 (#13).
  VoiceSettings voice = const VoiceSettings();

  /// 我的训练组 (custom_routines v1, stored under `customRoutines`).
  final List<CustomRoutine> customRoutines = [];

  /// Practice history, newest last, at most [SessionRecord.keep].
  final List<SessionRecord> sessions = [];

  bool get onboarded => safety != null && identity != null;
  bool get blocked => safety?.values.any((v) => v) ?? false;

  AssessmentResult? get latestResult => assessments.isEmpty
      ? null
      : scorer.score(assessments.last.answers, identity ?? HipIdentity.other);

  Map<HipDirection, DateTime> get lockedDirections =>
      PainHistory(painEvents).lockedUntil(now());

  /// Directions with a pain report in the last 7 days (练习库 hint).
  Set<HipDirection> get recentPainDirections =>
      PainHistory(painEvents).recentPain(now());

  int get streak => streakDays(doneDays, now());
  List<bool> get week => lastSevenDays(doneDays, now());

  TrainingProfile get profile => TrainingProfile.from(
    latestResult,
    identity: identity ?? HipIdentity.other,
    extraLocks: lockedDirections.keys.toSet(),
    blocked: blocked,
  );

  TrainingPlan? get todayPlan =>
      planner.plan(minutes: minutes, scene: scene, profile: profile);

  TrainingPlan? get microPlan {
    if (blocked) return null;
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
    identity = j['identity'] == null
        ? null
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
    theme = HipThemeChoice.byId(j['theme'] as String?);
    if (j['voice'] is Map) {
      voice = VoiceSettings.fromJson(
        Map<String, dynamic>.from(j['voice'] as Map),
      );
    }
    customRoutines
      ..clear()
      ..addAll(CustomRoutinesCodec.decode(j['customRoutines'], content));
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
    'identity': identity?.id,
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
    'theme': theme.id,
    'voice': voice.toJson(),
    'customRoutines': CustomRoutinesCodec.encode(customRoutines),
    'sessions': [for (final r in sessions) r.toJson()],
  };

  Future<void> _save() async {
    notifyListeners();
    await _storage.write(storageKey, jsonEncode(toJson()));
  }

  Future<void> setSafety(Map<String, bool> answers) {
    safety = Map.unmodifiable(answers);
    return _save();
  }

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

  Future<void> setTheme(HipThemeChoice value) {
    theme = value;
    return _save();
  }

  Future<void> setVoice(VoiceSettings value) {
    voice = value;
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
  String nextCustomName() {
    for (var n = customRoutines.length + 1; ; n++) {
      final name = '我的训练组 $n';
      if (customRoutines.every((r) => r.name != name)) return name;
    }
  }

  /// Inserts or replaces (by id); stamps updatedAt.
  Future<CustomRoutine> saveCustomRoutine(CustomRoutine r) {
    final at = now();
    final saved = CustomRoutine(
      id: r.id,
      name: CustomRoutine.cleanName(r.name).isEmpty
          ? nextCustomName()
          : CustomRoutine.cleanName(r.name),
      steps: r.steps.length > CustomRoutine.maxSteps
          ? r.steps.sublist(0, CustomRoutine.maxSteps)
          : r.steps,
      restSeconds: CustomRoutine.rests.contains(r.restSeconds)
          ? r.restSeconds
          : CustomRoutine.defaultRest,
      fromRoutine: r.fromRoutine,
      createdAt: r.createdAt ?? at,
      updatedAt: at,
    );
    final i = customRoutines.indexWhere((x) => x.id == r.id);
    if (i < 0) {
      customRoutines.add(saved);
    } else {
      customRoutines[i] = saved;
    }
    return _save().then((_) => saved);
  }

  Future<void> deleteCustomRoutine(String id) {
    customRoutines.removeWhere((r) => r.id == id);
    return _save();
  }

  Future<void> setReminder(ReminderSettings value) async {
    reminder = value;
    await reminders.apply(value, now());
    await _save();
  }
}
