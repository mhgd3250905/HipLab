import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hiplab/hip/control/hip_store.dart';
import 'package:hiplab/hip/domain/hip_library.dart';
import 'package:hiplab/hip/domain/hip_models.dart';
import 'package:hiplab/hip/domain/hip_pain.dart';
import 'package:hiplab/hip/domain/hip_session.dart';
import 'package:ugk_trainer/ugk_trainer.dart' as trainer;

import 'hip_domain_test.dart' show MemoryStorage, loadContent;

class FailingStorage extends MemoryStorage {
  bool fail = true;

  @override
  Future<void> write(String key, String value) async {
    if (fail) throw StateError('disk full');
    await super.write(key, value);
  }
}

void main() {
  final content = loadContent();
  final at = DateTime(2026, 10, 20, 10);
  final base = TrainingPlanner(
    content,
  ).planFor([content.routines.first], const TrainingProfile());
  TrainingPlan plan([PlanSource source = PlanSource.routine]) => TrainingPlan(
    routines: base.routines,
    steps: base.steps,
    transitionSeconds: base.transitionSeconds,
    source: source,
    refId: 'A',
  );
  trainer.SessionResult result({
    String id = 'session-1',
    bool full = false,
    bool skipped = false,
  }) => trainer.SessionResult(
    sessionId: id,
    planId: 'routine-A',
    planTitle: base.title,
    startedAt: at,
    endedAt: at.add(const Duration(minutes: 5)),
    activeSeconds: 42.4,
    endedEarly: !full,
    completedExercises: 1,
    totalExercises: 2,
    items: [
      trainer.ItemResult(
        exerciseId: base.steps.first.drill.id,
        blockIndex: 0,
        itemInBlock: 0,
        plannedSets: 1,
        completedSets: skipped ? 0 : 1,
        activeSeconds: skipped ? 0 : 25,
        status: skipped
            ? trainer.ItemStatus.skipped
            : trainer.ItemStatus.completed,
      ),
    ],
  );

  test(
    'actual duration, partial completion and full SDK result survive reload',
    () async {
      final storage = MemoryStorage();
      final store = HipStore(
        content: content,
        storage: storage,
        clock: () => at,
      );
      await store.initialize();
      final r = result();
      await store.saveTrainerSession(
        r,
        plan: plan(),
        ladder: SessionPainLadder(content),
        feedback: {0: '刚刚好'},
      );
      final reloaded = HipStore(
        content: content,
        storage: storage,
        clock: () => at,
      );
      await reloaded.initialize();
      final record = reloaded.sessions.single;
      expect(record.sessionId, r.sessionId);
      expect(record.seconds, 42);
      expect(record.seconds, isNot(base.seconds));
      expect(record.completed, isTrue);
      expect(record.trainerResult?['endedEarly'], isTrue);
      expect(record.trainerResult?['full'], isFalse);
      expect(record.trainerResult?['items'], r.toJson()['items']);
      expect(record.feedback, {0: '刚刚好'});
      expect(reloaded.streak, 1);
    },
  );

  test('retry and reload upsert once without doubling pain events', () async {
    final storage = MemoryStorage();
    var store = HipStore(content: content, storage: storage, clock: () => at);
    final ladder = SessionPainLadder(content)
      ..skippedDirections.add(HipDirection.flexion);
    await store.saveTrainerSession(result(), plan: plan(), ladder: ladder);
    store = HipStore(content: content, storage: storage, clock: () => at);
    await store.initialize();
    await Future.wait([
      store.saveTrainerSession(result(), plan: plan(), ladder: ladder),
      store.saveTrainerSession(
        result(),
        plan: plan(),
        ladder: ladder,
        feedback: {0: '轻松'},
      ),
    ]);
    expect(store.sessions, hasLength(1));
    expect(store.sessions.single.feedback, {0: '轻松'});
    expect(store.painEvents.where((p) => p.type == 'skip'), hasLength(1));
  });

  test('storage failure propagates and retry commits exactly once', () async {
    final storage = FailingStorage();
    final store = HipStore(content: content, storage: storage, clock: () => at);
    final ladder = SessionPainLadder(content)
      ..skippedDirections.add(HipDirection.flexion)
      ..ended = true;
    await expectLater(
      store.saveTrainerSession(result(), plan: plan(), ladder: ladder),
      throwsStateError,
    );
    expect(store.sessions, isEmpty);
    expect(store.doneDays, isEmpty);
    expect(store.painEvents, isEmpty);
    expect(store.askNumbness, isFalse);
    storage.fail = false;
    await store.saveTrainerSession(result(), plan: plan(), ladder: ladder);
    expect(store.sessions, hasLength(1));
    expect(store.painEvents, hasLength(1));
    expect(store.askNumbness, isTrue);
    expect(
      jsonDecode(storage.values[HipStore.storageKey]!)['sessions'],
      hasLength(1),
    );
  });

  test('all skipped and single practice never add a streak day', () async {
    for (final skipped in [true, false]) {
      final store = HipStore(
        content: content,
        storage: MemoryStorage(),
        clock: () => at,
      );
      await store.saveTrainerSession(
        result(skipped: skipped),
        plan: plan(skipped ? PlanSource.routine : PlanSource.single),
        ladder: SessionPainLadder(content),
      );
      expect(store.doneDays, isEmpty);
      expect(store.sessions.single.completed, !skipped);
    }
  });

  test('legacy history has no trainer payload and retains its values', () {
    final legacy = {
      'at': at.toIso8601String(),
      'source': 'custom',
      'title': '旧训练组',
      'seconds': 600,
      'completed': true,
    };
    final record = SessionRecord.fromJson(legacy)!;
    expect(record.seconds, 600);
    expect(record.completed, isTrue);
    expect(record.sessionId, isNull);
    expect(record.trainerResult, isNull);
    expect(record.feedback, isEmpty);
    expect(SessionRecord.fromJson(record.toJson())!.title, '旧训练组');
  });
}
