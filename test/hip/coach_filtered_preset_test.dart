import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiplab/hip/coach/coach_config.dart';
import 'package:hiplab/hip/coach/coach_service.dart';
import 'package:hiplab/hip/coach/plan_mapping.dart';
import 'package:hiplab/hip/coach/usage_store.dart';
import 'package:hiplab/hip/control/hip_store.dart';
import 'package:hiplab/hip/domain/hip_library.dart';
import 'package:hiplab/hip/domain/hip_session.dart';
import 'package:hiplab/hip/ui/library/library_actions.dart';
import 'package:hiplab/hip/ui/library/practice_page.dart' show startGroup;
import 'package:ugk_coach/ugk_coach.dart' as uc;

import 'hip_domain_test.dart' show MemoryStorage, loadContent;

void main() {
  final content = loadContent();
  final at = DateTime(2026, 10, 21, 15);

  CoachService service() => CoachService(
    config: const CoachConfig(),
    content: content,
    usage: CoachUsageStore(),
    storage: MemoryStorage(),
    readAsset: (path) async => File(path).readAsStringSync(),
  );

  testWidgets('knee-protected fallback stays filtered in preview, saved group '
      'and the actual startGroup handoff', (tester) async {
    final coach = service();
    final answer = await coach.send(
      '在办公室做一节训练',
      context: const uc.CoachContext(scene: 'office', avoid: {'膝'}),
    );
    expect(answer.status, uc.TurnStatus.fallback);
    expect(answer.plan, isA<uc.ValidatedPlan>());
    final plan = answer.plan!.plan;
    expect(plan.templateId, 'A');
    final admitted = [for (final item in plan.items) item.exerciseId];
    final full = copyRoutine(
      content.routine('A'),
      content,
      id: 'filtered',
      name: plan.title,
      at: at,
    );
    final excluded = full.steps
        .map((s) => s.kitId)
        .toSet()
        .difference(admitted.toSet());
    expect(excluded, containsAll(['n-chair-wiper', 'o-seated-fig4']));
    expect(admitted, isNotEmpty);

    final preview = CoachPlanMapper(content).map(plan, id: 'filtered', at: at);
    expect(preview.entries.map((e) => e.drill.id), admitted);
    expect(preview.routine.steps, [
      for (final step in full.steps)
        if (admitted.contains(step.kitId)) step,
    ]);
    expect(preview.adjusted, isFalse);

    void staysProtected(Iterable<String> ids) {
      expect(ids.toSet().intersection(excluded), isEmpty);
      for (final id in ids) {
        expect(coach.catalog[id]!.cautions, isNot(contains('膝')), reason: id);
      }
    }

    staysProtected(preview.routine.steps.map((s) => s.kitId));
    final storage = MemoryStorage();
    final store = HipStore(content: content, storage: storage, clock: () => at);
    await store.saveCustomRoutine(preview.routine);
    final reloaded = HipStore(
      content: content,
      storage: storage,
      clock: () => at,
    );
    await reloaded.initialize();
    final saved = reloaded.customRoutines.single;
    expect(saved.steps, preview.routine.steps);
    staysProtected(saved.steps.map((s) => s.kitId));
    expect(
      jsonDecode(storage.values[HipStore.storageKey]!)['customRoutines'],
      isNotEmpty,
    );

    TrainingPlan? launched;
    final actions = LibraryActions(
      store: reloaded,
      startPlan: (plan, {from, radius = 0, originColor}) async {
        launched = plan;
      },
    );
    late BuildContext origin;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            origin = context;
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    await startGroup(origin, actions, saved);
    expect(launched, isNotNull);
    expect(launched!.source, PlanSource.custom);
    expect(launched!.steps.map((s) => s.drill.id), admitted);
    staysProtected(launched!.steps.map((s) => s.drill.id));
    expect(coach.usage.totals.calls, 0);
    expect(tester.takeException(), isNull);
  });

  test(
    'unfiltered preset keeps the complete original authored doses',
    () async {
      final coach = service();
      final answer = await coach.send(
        '睡前放松',
        // B includes h-band-leg-out; declare the equipment needed to admit
        // the complete preset rather than expecting a missing band ignored.
        context: const uc.CoachContext(scene: 'home', equipment: {'band'}),
      );
      expect(answer.plan, isA<uc.ValidatedPlan>());
      final plan = answer.plan!.plan;
      expect(plan.templateId, 'B');
      final expected = copyRoutine(
        content.routine('B'),
        content,
        id: 'complete',
        name: plan.title,
        at: at,
      );
      expect(
        plan.items.map((i) => i.exerciseId),
        expected.steps.map((s) => s.kitId),
      );
      final actual = CoachPlanMapper(content).map(plan, id: 'complete', at: at);
      expect(actual.routine.toJson(), expected.toJson());
      expect(actual.adjusted, isFalse);
    },
  );

  test(
    'filtered template retains surviving rep-hold and pace overrides',
    () async {
      final coach = service();
      final answer = await coach.send(
        '想练横叉',
        context: const uc.CoachContext(scene: 'home', avoid: {'腰'}),
      );
      expect(answer.plan, isA<uc.ValidatedPlan>());
      final plan = answer.plan!.plan;
      expect(plan.templateId, 'F');
      final admitted = plan.items.map((i) => i.exerciseId).toSet();
      expect(admitted, contains('h-sumo-pry'));
      expect(admitted, isNot(contains('h-quad-cars')));
      final expected = copyRoutine(
        content.routine('F'),
        content,
        id: 'holds',
        name: plan.title,
        at: at,
      ).steps.where((s) => admitted.contains(s.kitId)).toList();
      final actual = CoachPlanMapper(content).map(plan, id: 'holds', at: at);
      expect(actual.routine.steps, expected);
      final sumo = actual.routine.steps.firstWhere(
        (s) => s.kitId == 'h-sumo-pry',
      );
      expect(sumo.holdSeconds, 15);
      expect(actual.adjusted, isFalse);
    },
  );
}
