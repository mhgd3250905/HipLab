// Exercise HipLab's real slots in the shared player, including the App's
// pain ladder and the result saved by SessionResult. No private player state.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiplab/hip/control/hip_store.dart';
import 'package:hiplab/hip/domain/hip_models.dart';
import 'package:hiplab/hip/domain/hip_session.dart';
import 'package:hiplab/hip/ui/hip_app.dart';
import 'package:hiplab/hip/ui/hip_player_page.dart';
import 'package:ugk_trainer/ugk_trainer.dart' as trainer;

import 'hip_domain_test.dart' show MemoryStorage, loadContent;

void main() {
  final content = loadContent();
  final now = DateTime(2026, 10, 20, 16);

  PlanStep step(String id, {int seconds = 40, bool counted = false}) =>
      PlanStep(
        drill: content.drill(id),
        dose: counted ? '2 次' : '$seconds 秒',
        seconds: seconds,
        sided: false,
        kitDose: counted ? const KitDose(reps: 2) : KitDose(seconds: seconds),
        alternative: content.drill(id).alternative,
      );

  TrainingPlan plan(List<PlanStep> steps) => TrainingPlan(
    routines: const [],
    steps: steps,
    transitionSeconds: 15,
    source: PlanSource.custom,
    refId: 'trainer-slot-test',
    name: '真实播放器插槽回归',
  );

  Future<HipStore> openPlayer(WidgetTester tester, TrainingPlan plan) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final store = HipStore(
      content: content,
      storage: MemoryStorage(),
      clock: () => now,
    );
    await store.initialize();
    store
      ..safety = {'pregnancy': false, 'surgery': false, 'acute': false}
      ..identity = HipIdentity.office;
    await tester.pumpWidget(HipApp(store: store, videoEnabled: false));
    await tester.pumpAndSettle();
    final navigator = tester.state<NavigatorState>(
      find.byType(Navigator).first,
    );
    unawaited(
      navigator.push<void>(
        MaterialPageRoute<void>(
          builder: (_) => HipPlayerPage(store: store, plan: plan),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(trainer.TrainerPlayer), findsOneWidget);
    // Enter the first work through the shared player's actual control.
    await tester.tap(find.byKey(const ValueKey('skip')));
    await tester.pump(const Duration(milliseconds: 400));
    return store;
  }

  trainer.TrainerPlayer player(WidgetTester tester) =>
      tester.widget<trainer.TrainerPlayer>(find.byType(trainer.TrainerPlayer));

  Future<void> pinch(WidgetTester tester, {bool fromFeedback = false}) async {
    await tester.tap(
      find.byKey(ValueKey(fromFeedback ? 'feel-pain' : 'discomfort')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const ValueKey('pain-pinch')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('pain-pinch')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(const ValueKey('pain-pinch')), findsNothing);
  }

  Future<void> finishNaturally(WidgetTester tester, HipStore store) async {
    for (var i = 0; i < 300 && store.sessions.isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    await tester.pump(const Duration(milliseconds: 400));
    expect(store.sessions, hasLength(1));
    expect(find.byKey(const ValueKey('finish')), findsOneWidget);
  }

  testWidgets('actual discomfort slot halves, substitutes, then omits the '
      'painful direction while another direction finishes', (tester) async {
    const firstId = 'glute-max-A';
    const otherId = 's-butterfly';
    final alternative = content.drill(firstId).alternative!;
    final direction = content.drill(firstId).directions.first;
    expect(content.drill(alternative).directions.first, direction);
    expect(content.drill(alternative).isRelax, isFalse);
    expect(content.drill(otherId).directions.first, isNot(direction));
    final training = plan([
      step(firstId, counted: true),
      step(firstId, counted: true),
      step(otherId, seconds: 8),
    ]);
    final store = await openPlayer(tester, training);

    await pinch(tester);
    final reduced = player(tester).sessionBuilder!
        .phases(player(tester).plan)
        .where((p) => p.itemIndex == 0 && p.isWork);
    expect(
      reduced.fold(0.0, (sum, p) => sum + p.seconds),
      20,
      reason: 'first pinch halves the current authored time, not another item',
    );
    expect(find.byKey(const ValueKey('name-glute-max-A')), findsOneWidget);

    await pinch(tester);
    expect(find.byKey(ValueKey('name-$alternative')), findsOneWidget);
    final substituted = player(tester).sessionBuilder!
        .phases(player(tester).plan)
        .where((p) => p.isWork && p.itemIndex < 2);
    expect(
      substituted.every((p) => p.exerciseId == alternative),
      isTrue,
      reason: 'both occurrences use the App-selected alternative',
    );

    await pinch(tester);
    expect(
      find.byKey(const ValueKey('name-s-butterfly')),
      findsOneWidget,
      reason: 'the same-direction second item was omitted from the live tail',
    );
    expect(find.byKey(ValueKey('name-$alternative')), findsNothing);
    await finishNaturally(tester, store);
    final record = store.sessions.single;
    final result = record.trainerResult!;
    expect(result['full'], isFalse);
    final events = (result['discomfort'] as List).cast<Map>();
    expect(events.map((e) => e['exerciseId']), [firstId, firstId, alternative]);
    expect(events.map((e) => e['action']), [
      'continueEasier',
      'substitute',
      'skip',
    ]);
    expect(events.map((e) => e['note']), [
      'pinch:reduceAmplitude',
      'pinch:substitute',
      'pinch:skipDirection',
    ]);
    final items = (result['items'] as List).cast<Map>();
    expect(
      items[1]['activeSeconds'],
      0,
      reason: 'future non-relax work in the painful direction never ran',
    );
    expect(items[1]['completedSets'], 0);
    expect(items[2]['exerciseId'], otherId);
    expect(items[2]['completedSets'], 1);
    expect(store.painEvents.where((e) => e.type == 'pain').length, 3);
    expect(
      store.painEvents.where((e) => e.type == 'skip').single.direction,
      direction,
    );
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('rest feel-pain targets the just-completed exercise, preserves '
      'the rest clock, and saves the final feedback', (tester) async {
    const firstId = 's-pigeon';
    const nextId = 's-butterfly';
    final training = plan([
      step(firstId, seconds: 10),
      step(nextId, seconds: 8),
    ]);
    final store = await openPlayer(tester, training);
    for (
      var i = 0;
      i < 30 && find.byKey(const ValueKey('feel-pain')).evaluate().isEmpty;
      i++
    ) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    expect(find.byKey(const ValueKey('feel-pain')), findsOneWidget);
    expect(find.byKey(const ValueKey('name-s-butterfly')), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    final before = int.parse(
      tester
          .widget<trainer.TrainerRollingNumber>(
            find.byKey(const ValueKey('counter')),
          )
          .value,
    );
    expect(before, lessThan(15));

    await pinch(tester, fromFeedback: true);
    final after = int.parse(
      tester
          .widget<trainer.TrainerRollingNumber>(
            find.byKey(const ValueKey('counter')),
          )
          .value,
    );
    expect(
      after,
      inInclusiveRange(before - 1, before),
      reason:
          'the pain sheet pauses and resumes the current rest, never restarts it',
    );
    expect(find.byKey(const ValueKey('name-s-butterfly')), findsOneWidget);
    expect(find.byKey(const ValueKey('name-s-pigeon')), findsNothing);
    expect(find.text('已记录'), findsOneWidget);

    await finishNaturally(tester, store);
    final record = store.sessions.single;
    expect(record.feedback, {0: 'pain'});
    expect(find.text('本次感受'), findsOneWidget);
    expect(find.text('${content.drill(firstId).name} · 疼'), findsOneWidget);
    final events = (record.trainerResult!['discomfort'] as List).cast<Map>();
    expect(events, hasLength(1));
    expect(events.single['exerciseId'], firstId);
    expect(events.single['itemIndex'], 0);
    expect(events.single['note'], 'pinch:reduceAmplitude');
    final items = (record.trainerResult!['items'] as List).cast<Map>();
    expect(
      items[0]['activeSeconds'],
      10,
      reason: 'completed work was neither halved retrospectively nor replayed',
    );
    expect(items[1]['activeSeconds'], 8);
    expect(record.trainerResult!['full'], isTrue);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
