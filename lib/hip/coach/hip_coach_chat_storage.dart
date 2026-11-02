import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:ugk_coach/ugk_coach.dart' as coach;
import 'package:ugk_coach_chat/ugk_coach_chat.dart';

import '../../core/storage/local_state_storage.dart';
import '../control/hip_store.dart';
import '../domain/hip_library.dart';
import '../domain/hip_settings.dart';

/// The practice library remains the only writer of durable saved plans.
class HiplabCoachPlanStore extends CoachPlanStorageAdapter {
  HiplabCoachPlanStore(this.store, {required this.catalog});
  final HipStore store;
  final coach.Catalog catalog;
  final List<String> unreadableExternalIds = [];

  CoachSavedPlanSnapshot snapshot(CustomRoutine routine) =>
      CoachSavedPlanSnapshot(
        externalId: routine.id,
        title: routine.name,
        plan: planFor(routine),
        storageRevision: HipStore.customRoutineRevision(routine),
        sdkVersion: routine.coachSdkVersion,
        updatedAt: routine.updatedAt,
      );

  /// Existing SDK saves carry the complete original plan. Ordinary legacy
  /// groups need only a structural import of their authored dose and rest.
  coach.TrainingPlan planFor(CustomRoutine routine) {
    if (routine.coachPlan case final raw?) {
      final decoded = const coach.PlanCodec().decodeStrict(raw);
      if (decoded.plan case final plan?) return plan;
      throw const FormatException('Unreadable stored SDK plan');
    }
    if (routine.steps.any((step) => catalog[step.kitId] == null)) {
      throw const FormatException(
        'Stored group references an unavailable action',
      );
    }
    final drills = [for (final step in routine.steps) catalog[step.kitId]!];
    return coach.TrainingPlan(
      id: 'ext:${routine.id}',
      source: 'ai',
      title: routine.name,
      goal: 'mobility',
      scene: store.scene.name == 'chair' ? 'office' : store.scene.name,
      equipment: {for (final drill in drills) ...drill.equipment}.toList(),
      level: drills.fold(1, (level, drill) => math.max(level, drill.level)),
      targetMinutes: math.max(1, (routine.seconds(store.content) / 60).round()),
      blocks: [
        coach.PlanBlock(
          id: 'saved',
          name: routine.name,
          type: coach.BlockType.main,
          items: [
            for (final step in routine.steps)
              coach.PlanItem(
                exerciseId: step.kitId,
                mode: catalog[step.kitId]!.defaultDose.mode,
                sets: step.sets ?? 1,
                reps:
                    catalog[step.kitId]!.defaultDose.mode == coach.DoseMode.reps
                    ? step.reps ?? store.content.kit(step.kitId)!.defaultReps
                    : null,
                workSeconds:
                    catalog[step.kitId]!.defaultDose.mode == coach.DoseMode.time
                    ? DoseRules.setSeconds(
                        store.content.kit(step.kitId)!,
                        step.dose(store.content.kit(step.kitId)!),
                        single: false,
                      )
                    : null,
                perSide: catalog[step.kitId]!.unilateral,
                restSeconds: routine.restSeconds,
              ),
          ],
        ),
      ],
    );
  }

  @override
  Future<List<CoachSavedPlanSnapshot>> load() async {
    unreadableExternalIds.clear();
    final values = <CoachSavedPlanSnapshot>[];
    for (final routine in store.customRoutines) {
      try {
        values.add(snapshot(routine));
      } on FormatException {
        // Preserve the group in the App's library and on disk. One corrupt
        // optional SDK payload must not prevent all other saved plans loading.
        unreadableExternalIds.add(routine.id);
      }
    }
    return values;
  }

  @override
  Stream<void> get changes => _storeChanges(store);

  @override
  Future<CoachPlanWriteResult> save(CoachPlanWriteRequest request) async {
    final update = request.mode == CoachPlanWriteMode.update;
    if (update && request.externalId == null) {
      return const CoachPlanWriteResult.failure(CoachPlanWriteStatus.deleted);
    }
    final id = update ? request.externalId! : store.newCustomId();
    final existing = store.customRoutine(id);
    final at = store.now();
    final plan = request.plan;
    // This DTO is a library preview only. Do not expand rounds, merge repeated
    // actions or fit doses: playback and cards use the stored complete plan.
    final routine = CustomRoutine(
      id: id,
      name: CustomRoutine.cleanName(request.name).isEmpty
          ? store.nextCustomName()
          : CustomRoutine.cleanName(request.name),
      steps: [
        for (final item in plan.items)
          CustomStep(
            item.exerciseId,
            reps: item.reps,
            seconds: item.workSeconds,
            sets: item.sets,
          ),
      ],
      restSeconds: plan.items.firstOrNull?.restSeconds ?? 15,
      createdAt: existing?.createdAt ?? at,
      updatedAt: at,
      coachPlan: plan.toJson(),
      coachSdkVersion: request.sdkVersion,
    );
    try {
      final result = await store.writeCoachCustomRoutine(
        routine,
        update: update,
        expectedStorageRevision: request.expectedStorageRevision,
      );
      return switch (result.status) {
        CoachRoutineWriteStatus.saved => CoachPlanWriteResult.saved(
          snapshot(result.routine!),
        ),
        CoachRoutineWriteStatus.conflict => const CoachPlanWriteResult.failure(
          CoachPlanWriteStatus.conflict,
        ),
        CoachRoutineWriteStatus.deleted => const CoachPlanWriteResult.failure(
          CoachPlanWriteStatus.deleted,
        ),
      };
    } on Object catch (error) {
      return CoachPlanWriteResult.failure(
        CoachPlanWriteStatus.failed,
        error: error,
      );
    }
  }
}

/// New SDK envelopes and archives never overwrite the Coach v2 source key.
class HiplabCoachChatHistoryStore extends CoachChatHistoryStore {
  HiplabCoachChatHistoryStore(this.store, {LocalStateStorage? storage})
    : _storage = storage ?? SharedPreferencesLocalStateStorage();
  static const legacyKey = 'hip.coach.session.v2';
  static const archiveIndexKey = 'hip.coach.chat.archives.v1';
  static String envelopeKey(String namespace) => 'hip.coach.chat.v1:$namespace';
  static const lastPlanKey = 'hip.coach.last-plan.v1';
  final HipStore store;
  final LocalStateStorage _storage;
  Future<void> _archiveTail = Future.value();

  @override
  Future<CoachChatSnapshot?> load(String namespace) async {
    final raw = await _storage.read(envelopeKey(namespace));
    return raw == null
        ? null
        : CoachChatSnapshot.fromJson(
            Map<String, Object?>.from(jsonDecode(raw) as Map),
          );
  }

  @override
  Future<void> write(String namespace, CoachChatSnapshot snapshot) =>
      _storage.write(envelopeKey(namespace), jsonEncode(snapshot.toJson()));

  @override
  Future<CoachChatLegacyData?> loadLegacy(String namespace) async {
    final raw = await _storage.read(legacyKey);
    if (raw == null) return null;
    final data = Map<String, Object?>.from(jsonDecode(raw) as Map);
    final saved = data['saved'] is Map ? data['saved']! as Map : const {};
    final display = <Map<String, Object?>>[
      for (final value in data['messages'] as List? ?? const [])
        if (value is Map) _legacyRow(Map<String, Object?>.from(value), saved),
    ];
    return CoachChatLegacyData(
      chat: display,
      coachDisplay: display,
      coachSessionJson: data['snapshot'] == null
          ? null
          : jsonEncode(data['snapshot']),
    );
  }

  Map<String, Object?> _legacyRow(Map<String, Object?> row, Map saved) {
    final id = saved[row['id']];
    final routine = id is String ? store.customRoutine(id) : null;
    return {
      ...row,
      'role': row['isUser'] == true ? 'user' : 'assistant',
      'aiVisible': true,
      'conversationMessageId': row['id'],
      if (row['actions'] is List)
        'actionIds': [
          for (final action in row['actions']! as List)
            if (action is Map && action['actionId'] is String)
              action['actionId'],
        ],
      if (id is String) 'savedExternalId': id,
      if (routine != null)
        'storageRevision': HipStore.customRoutineRevision(routine),
    };
  }

  /// Each captured snapshot has a separate key. The small index is published
  /// only after its archive payload was written, retaining every earlier key.
  Future<void> archive(CoachChatSnapshot snapshot) {
    final result = _archiveTail.then((_) async {
      final raw = await _storage.read(archiveIndexKey);
      final keys = raw == null
          ? <String>[]
          : (jsonDecode(raw) as List).cast<String>();
      var sequence = keys.length + 1;
      var key = '$archiveIndexKey:$sequence';
      while (await _storage.read(key) != null) {
        sequence++;
        key = '$archiveIndexKey:$sequence';
      }
      await _storage.write(key, jsonEncode(snapshot.toJson()));
      await _storage.write(archiveIndexKey, jsonEncode([...keys, key]));
    });
    _archiveTail = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }

  @override
  Future<CoachChatHistoryContext> readTrainingContext() async {
    final raw = await _storage.read(lastPlanKey);
    return CoachChatHistoryContext(
      lastPlan: raw == null
          ? null
          : const coach.PlanCodec().decodeStrict(jsonDecode(raw)).plan,
      history: [
        for (final record in store.sessions)
          WorkoutLog(
            title: record.title,
            at: record.at,
            minutes: (record.seconds / 60).round(),
            completed: record.completed ? 1 : 0,
            total: 1,
          ),
      ],
    );
  }

  @override
  Future<void> rememberStartedPlan(
    coach.TrainingPlan plan, {
    String? savedExternalId,
  }) => _storage.write(lastPlanKey, jsonEncode(plan.toJson()));
}

/// SDK safety acceptance is separate from HipLab's existing onboarding facts;
/// the App's blocked state always continues to veto training.
class HiplabCoachChatPreferenceStore extends CoachChatPreferenceStore {
  HiplabCoachChatPreferenceStore(this.store, {LocalStateStorage? storage})
    : _storage = storage ?? SharedPreferencesLocalStateStorage();
  static const storageKey = 'hip.coach.preferences.v1';
  static const legacyDisclaimerKey = 'hip.coach.v1';
  final HipStore store;
  final LocalStateStorage _storage;
  final _changes = StreamController<void>.broadcast();
  Future<void>? _loading;
  bool _accepted = false, _blocked = false, _checking = false;

  Future<void> _read() async {
    final raw = await _storage.read(storageKey);
    if (raw != null) {
      final value = jsonDecode(raw) as Map;
      _accepted = value['safetyAccepted'] == true;
      _blocked = value['safetyBlocked'] == true;
      _checking = value['safetyChecking'] == true;
    } else {
      final legacy = await _storage.read(legacyDisclaimerKey);
      if (legacy != null) {
        _accepted = (jsonDecode(legacy) as Map)['disclaimerAccepted'] == true;
      }
    }
  }

  CoachChatPreferences get _value => CoachChatPreferences(
    safetyAccepted: _accepted,
    safetyBlocked: _blocked || store.blocked,
    safetyChecking: _checking,
    appearance: store.theme.id,
    voice: store.voice.voice,
    chimes: store.voice.chimes,
    enableUserMemory: false,
    starfield: false,
  );

  @override
  Future<CoachChatPreferences> load() async {
    await (_loading ??= _read());
    return _value;
  }

  @override
  Stream<CoachChatPreferences> get changes => Stream.multi((listener) {
    void changed() => listener.add(_value);
    store.addListener(changed);
    final subscription = _changes.stream.listen((_) => changed());
    listener.onCancel = () async {
      store.removeListener(changed);
      await subscription.cancel();
    };
  }, isBroadcast: true);

  @override
  Future<void> update(CoachChatPreferences preferences) async {
    await (_loading ??= _read());
    await _storage.write(
      storageKey,
      jsonEncode({
        'safetyAccepted': preferences.safetyAccepted,
        'safetyBlocked': preferences.safetyBlocked,
        'safetyChecking': preferences.safetyChecking,
      }),
    );
    _accepted = preferences.safetyAccepted;
    _blocked = preferences.safetyBlocked;
    _checking = preferences.safetyChecking;
    await store.setTheme(HipThemeChoice.byId(preferences.appearance));
    await store.setVoice(
      store.voice.copyWith(
        voice: preferences.voice,
        chimes: preferences.chimes,
      ),
    );
    _changes.add(null);
  }

  Future<void> dispose() => _changes.close();
}

Stream<void> _storeChanges(HipStore store) => Stream.multi((listener) {
  void changed() => listener.add(null);
  store.addListener(changed);
  listener.onCancel = () => store.removeListener(changed);
}, isBroadcast: true);
