import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiplab/hip/control/hip_store.dart';
import 'package:hiplab/hip/domain/hip_models.dart';
import 'package:hiplab/hip/domain/hip_session.dart';
import 'package:hiplab/hip/ui/hip_app.dart';
import 'package:hiplab/hip/ui/hip_player_page.dart';

import 'package:ugk_trainer/ugk_trainer.dart' as trainer;

import 'hip_domain_test.dart' show MemoryStorage, loadContent;

int _secondsLeft(WidgetTester tester) => int.parse(
  tester
      .widget<trainer.TrainerCountdownDigits>(
        find.byType(trainer.TrainerCountdownDigits),
      )
      .value,
);

void main() {
  testWidgets(
    'pain skips a micro rep that cannot fit, then rests and continues',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final store = HipStore(
        content: loadContent(),
        storage: MemoryStorage(),
        clock: () => DateTime(2026, 10, 19, 10),
      );
      await store.initialize();
      store
        ..safety = {'pregnancy': false, 'surgery': false, 'acute': false}
        ..identity = HipIdentity.office
        ..scene = HipScene.chair
        ..minutes = 5;
      final micro = store.microPlan!;
      final target = micro.steps.singleWhere(
        (step) => step.drill.id == 'n-seated-knee-lift',
      );
      expect(target.seconds, 16);
      // Keep the real M doses, kits and rest duration. Move only this step
      // to the front so a next micro action remains after the pain skip.
      final plan = TrainingPlan(
        routines: micro.routines,
        steps: [target, ...micro.steps.where((step) => step != target)],
        transitionSeconds: micro.transitionSeconds,
      );
      final next = plan.steps[1];
      await tester.pumpWidget(HipApp(store: store, videoEnabled: false));
      await tester.pumpAndSettle();
      tester
          .state<NavigatorState>(find.byType(Navigator))
          .push<void>(
            MaterialPageRoute(
              builder: (_) => HipPlayerPage(store: store, plan: plan),
            ),
          );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('skip'))); // prep -> work
      await tester.pumpAndSettle();
      expect(find.text(target.drill.name), findsOneWidget);
      final player = tester.widget<trainer.TrainerPlayer>(
        find.byType(trainer.TrainerPlayer),
      );
      final work = player.sessionBuilder!
          .phases(player.plan)
          .where((p) => p.isWork && p.itemIndex == 0)
          .toList();
      expect(work, hasLength(2), reason: 'the real M dose runs both sides');
      for (final phase in work) {
        expect(phase.seconds, inInclusiveRange(6, 8));
        expect(phase.reps, 1, reason: 'one full cycle fits before halving');
      }
      expect(work.fold<double>(0, (sum, p) => sum + p.seconds), target.seconds);
      expect(
        tester
            .widget<trainer.TrainerCountdownDigits>(
              find.byType(trainer.TrainerCountdownDigits),
            )
            .value,
        '1',
        reason: 'counted work displays the rep, not its duration',
      );

      await tester.tap(find.byKey(const ValueKey('discomfort')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('pain-pinch')));
      await tester.pumpAndSettle();

      // Halving leaves 4s/side, shorter than one 7s lift-hold-lower cycle.
      // The current action must be skipped, rather than starting a partial rep.
      expect(find.text(next.drill.name), findsOneWidget);
      expect(
        tester
            .widget<Semantics>(find.byKey(const ValueKey('index')))
            .properties
            .label,
        '2 / ${plan.steps.length}',
      );
      expect(find.byKey(const ValueKey('discomfort')), findsNothing);
      expect(find.byKey(const ValueKey('feel-ok')), findsOneWidget);
      expect(
        find.textContaining(RegExp(r'(^| · )(右侧|左侧)( · |$)')),
        findsNothing,
      );
      final before = _secondsLeft(tester);
      expect(
        before,
        inInclusiveRange(plan.transitionSeconds - 2, plan.transitionSeconds),
      );
      await tester.pump(const Duration(seconds: 2));
      final after = _secondsLeft(tester);
      expect(after, inInclusiveRange(before - 3, before - 1));
      expect(find.byKey(const ValueKey('discomfort')), findsNothing);

      // Optional feedback still records without skipping the next rest.
      await tester.tap(find.byKey(const ValueKey('feel-ok')));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('已记录'), findsOneWidget);
      expect(find.byKey(const ValueKey('discomfort')), findsNothing);
      await tester.pump(Duration(seconds: _secondsLeft(tester) + 1));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byKey(const ValueKey('feel-ok')), findsNothing);
      expect(find.byKey(const ValueKey('discomfort')), findsOneWidget);
      expect(find.text(next.drill.name), findsOneWidget);
      expect(
        tester
            .widget<Semantics>(find.byKey(const ValueKey('index')))
            .properties
            .label,
        '2 / ${plan.steps.length}',
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );
}
