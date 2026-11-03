// M6: training groups take every SDK-exposed action. Mixed groups play as
// one host-built SDK plan; groups of local kit drills keep the old path and
// their stored bytes.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiplab/hip/control/hip_store.dart';
import 'package:hiplab/hip/data/hip_action_scope.dart';
import 'package:hiplab/hip/data/hip_content_loader.dart';
import 'package:hiplab/hip/data/hip_shared_library.dart';
import 'package:hiplab/hip/domain/hip_library.dart';
import 'package:hiplab/hip/domain/hip_models.dart';
import 'package:hiplab/hip/domain/hip_pain.dart';
import 'package:hiplab/hip/domain/hip_session.dart';
import 'package:hiplab/hip/trainer/hip_sdk_session_builder.dart';
import 'package:hiplab/hip/ui/hip_app.dart';
import 'package:hiplab/hip/ui/library/group_editor_page.dart';
import 'package:ugk_trainer_runtime/ugk_trainer.dart' as trainer;

import 'hip_ai_coach_test.dart' show FileAssetBundle;
import 'hip_domain_test.dart' show MemoryStorage;
import 'home_nav.dart';
import 'public_media_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late HipContent content;
  setUpAll(() async {
    content = await loadHipContent(FileAssetBundle());
  });

  TrainingProfile profile(HipContent c) =>
      HipStore(content: c, storage: MemoryStorage()).profile;

  test(
    'every scoped SDK action joins a group and sequences in a mixed plan',
    () {
      final scope = hipActionScope(content.publicCatalog!).allowedActionIds;
      final planner = TrainingPlanner(content);
      final p = profile(content);
      final failed = <String>[];
      var addable = 0;
      for (final id in scope) {
        if (assessmentOnlyDrills.contains(id)) continue;
        if (!canJoinGroup(content, id)) {
          failed.add('$id: not joinable');
          continue;
        }
        addable++;
        final g = CustomRoutine(
          id: 'g',
          name: '混合',
          restSeconds: 20,
          steps: [const CustomStep('h-9090-liftoff'), CustomStep(id)],
        );
        final plan = planner.customPlan(g, p);
        final skipped = planner.customSkipped(g, p);
        if (plan == null) {
          failed.add('$id: no plan');
          continue;
        }
        if (plan.steps.length + skipped.length != 2) {
          failed.add('$id: ${plan.steps.length} steps');
          continue;
        }
        if (g.mixed(content)) {
          expect(plan.sdkPlan, isNotNull, reason: id);
          expect(plan.transitionSeconds, 20, reason: id);
          expect(g.seconds(content), greaterThan(0), reason: id);
        }
      }
      // ignore: avoid_print
      print('M6 addable=$addable failed=$failed');
      expect(failed, isEmpty);
      expect(addable, greaterThanOrEqualTo(200));
    },
  );

  test('mixed plan keeps order, SDK default dose and the group rest', () {
    final g = CustomRoutine(
      id: 'm',
      name: '混合',
      restSeconds: 30,
      steps: [
        const CustomStep('chest-A'),
        const CustomStep('h-9090-liftoff', sets: 2),
      ],
    );
    expect(isSdkGroupStep(content, 'chest-A'), isTrue);
    expect(g.mixed(content), isTrue);
    final plan = g.mixedPlan(content)!;
    final items = plan.blocks.single.items;
    expect(items.map((i) => i.exerciseId), ['chest-A', 'h-9090-liftoff']);
    final dd = content.publicCatalog!['chest-A']!.defaultDose;
    expect(items.first.sets, dd.sets);
    expect(items.first.reps, dd.reps);
    expect(items.last.sets, 2);
    final played = TrainingPlanner(content).customPlan(g, profile(content))!;
    expect(played.source, PlanSource.custom);
    expect(played.refId, 'm');
    expect(played.steps.map((s) => s.drill.id), ['chest-A', 'h-9090-liftoff']);
    expect(played.transitionSeconds, 30);
    expect(sdkStepDoseText(content, g.steps.first), isNotEmpty);
    expect(sdkStepSeconds(content, g.steps.first), greaterThan(0));
  });

  test('mixed SDK phases keep action order and the actual group rest', () {
    final group = CustomRoutine(
      id: 'phase-mix',
      name: '混合',
      restSeconds: 30,
      steps: [
        const CustomStep('chest-A'),
        const CustomStep('h-9090-liftoff', sets: 2),
      ],
    );
    final played = TrainingPlanner(
      content,
    ).customPlan(group, profile(content))!;
    final phases = hipSdkSessionBuilder(
      content,
      transitionSeconds: played.transitionSeconds,
    ).phases(played.sdkPlan!);
    final workOrder = <String>[];
    for (final phase in phases.where((p) => p.isWork)) {
      if (workOrder.lastOrNull != phase.exerciseId) {
        workOrder.add(phase.exerciseId!);
      }
    }
    expect(workOrder, ['chest-A', 'h-9090-liftoff']);
    final transition = phases.singleWhere(
      (p) => p.nextExerciseId == 'h-9090-liftoff',
    );
    expect(transition.kind, trainer.PhaseKind.rest);
    expect(transition.doneExerciseId, 'chest-A');
    expect(transition.seconds, 30);
  });

  test('completed mixed SDK session persists its result and streak', () async {
    final group = CustomRoutine(
      id: 'completed-mix',
      name: '混合完成组',
      restSeconds: 20,
      steps: [
        const CustomStep('chest-A'),
        const CustomStep('h-9090-liftoff', sets: 2),
      ],
    );
    final played = TrainingPlanner(
      content,
    ).customPlan(group, profile(content))!;
    final builder = hipSdkSessionBuilder(
      content,
      transitionSeconds: played.transitionSeconds,
    );
    final sdkPlan = played.sdkPlan!;
    final engine = trainer.SessionEngine(builder.phases(sdkPlan));
    var activeSeconds = 0.0;
    for (var guard = 0; !engine.done && guard < 1000; guard++) {
      if (engine.awaitingCompletion) {
        activeSeconds = engine.phaseStart + 10;
        expect(engine.completeSet(activeSeconds), isTrue);
      } else {
        activeSeconds = engine.phaseStart + engine.phase.seconds;
        expect(engine.update(activeSeconds), isTrue);
      }
    }
    expect(engine.done, isTrue);
    final at = DateTime(2026, 11, 3, 10);
    final result = trainer.SessionRecorder(
      plan: sdkPlan,
      totalExercises: builder.occurrenceCount(sdkPlan),
      sessionId: 'mixed-session',
      startedAt: at,
    ).finish(engine, activeSeconds: activeSeconds);
    expect(result.full, isTrue);
    expect(result.items.map((item) => item.exerciseId), [
      'chest-A',
      'h-9090-liftoff',
    ]);
    expect(
      result.items.every((item) => item.completedSets == item.plannedSets),
      isTrue,
    );
    final storage = MemoryStorage();
    final store = HipStore(content: content, storage: storage, clock: () => at);
    await store.initialize();
    await store.saveTrainerSession(
      result,
      plan: played,
      ladder: SessionPainLadder(content),
    );
    final reloaded = HipStore(
      content: content,
      storage: storage,
      clock: () => at,
    );
    await reloaded.initialize();
    final record = reloaded.sessions.single;
    expect(record.completed, isTrue);
    expect(record.source, PlanSource.custom);
    expect(record.refId, group.id);
    expect(record.title, played.title);
    expect(record.sessionId, result.sessionId);
    expect(record.seconds, activeSeconds.round());
    expect(record.trainerResult?['full'], isTrue);
    expect(record.trainerResult?['items'], result.toJson()['items']);
    expect(reloaded.streak, 1);
    store.dispose();
    reloaded.dispose();
  });

  test('old local-only groups stay byte-compatible and on the old path', () {
    final stored = {
      'v': 1,
      'items': [
        {
          'id': 'c_old',
          'name': '老组',
          'restSeconds': 15,
          'fromRoutine': null,
          'createdAt': '2026-10-20T08:00:00.000',
          'steps': [
            {'kitId': 'h-9090-liftoff'},
            {'kitId': 'o-seated-ham', 'seconds': 45},
          ],
        },
      ],
    };
    final raw = jsonEncode(stored);
    final items = CustomRoutinesCodec.decode(jsonDecode(raw), content);
    expect(items.single.mixed(content), isFalse);
    expect(jsonEncode(CustomRoutinesCodec.encode(items)), raw);
    final plan = TrainingPlanner(
      content,
    ).customPlan(items.single, profile(content))!;
    expect(plan.sdkPlan, isNull);
    expect(plan.steps, hasLength(2));
  });

  test('mixed groups round-trip; SDK overrides clamp; unknown ids drop', () {
    final g = CustomRoutine(
      id: 'c_mix',
      name: '混合组',
      restSeconds: 10,
      steps: [
        const CustomStep('chest-A'),
        CustomStep.sdk(
          content,
          'chest-A',
          const LibraryDose(reps: 12, sets: 3),
        )!,
        const CustomStep('h-9090-liftoff'),
      ],
    );
    final json = jsonEncode(CustomRoutinesCodec.encode([g]));
    final back = CustomRoutinesCodec.decode(jsonDecode(json), content).single;
    expect(back.steps, g.steps);
    expect(back.restSeconds, 10);
    expect(jsonEncode(CustomRoutinesCodec.encode([back])), json);

    final odd = CustomRoutinesCodec.decode({
      'v': 1,
      'items': [
        {
          'id': 'c_odd',
          'name': 'x',
          'restSeconds': 15,
          'steps': [
            {'kitId': 'chest-A', 'reps': 9999, 'sets': 99},
            {'kitId': 'no-such-move'},
          ],
        },
      ],
    }, content).single;
    expect(odd.removed, 1);
    final d = odd.steps.single.sdkDose(content)!;
    expect(d.reps, 100);
    expect(d.sets, 10);
  });

  testWidgets('picker adds an SDK action and the editor shows it', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final fixture = installPublicMediaFixture(sharedLibrary: true);
    final previous = HipSharedLibrary.current;
    addTearDown(() => HipSharedLibrary.current = previous);
    final store = HipStore(content: content, storage: MemoryStorage());
    await store.initialize();
    store
      ..safety = {'pregnancy': false, 'surgery': false, 'acute': false}
      ..identity = HipIdentity.office;
    await tester.pumpWidget(
      HipApp(store: store, videoEnabled: false, mediaPolicy: fixture.policy),
    );
    await tester.pumpAndSettle();
    await openGroups(tester);
    await tester.tap(find.byKey(const ValueKey('new-group')));
    await tester.pumpAndSettle();
    expect(find.byType(DrillPickerPage), findsOneWidget);
    expect(find.text('仅单练 · 暂不能加入训练组'), findsNothing);
    await tapCard(tester, const ValueKey('pick-chest-A'));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('picker-add')));
    await tester.pumpAndSettle();
    expect(find.byType(GroupEditorPage), findsOneWidget);
    final name = hipSdkDrill(content, 'chest-A')!.name;
    expect(find.text(name), findsWidgets);
    await tester.tap(find.byKey(const ValueKey('editor-row-0')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('sdk-dose')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('dose-done')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('editor-save')));
    await tester.pumpAndSettle();
    expect(store.customRoutines.single.steps.single.kitId, 'chest-A');
    expect(tester.takeException(), isNull);
    store.dispose();
  });
}
