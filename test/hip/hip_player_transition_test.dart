// The SDK owns the V1 stage and transport. HipLab provides rest feedback
// that records an answer without skipping or shortening the countdown.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiplab/hip/control/hip_store.dart';
import 'package:hiplab/hip/domain/hip_models.dart';
import 'package:hiplab/hip/ui/hip_app.dart';

import 'package:ugk_trainer_runtime/ugk_trainer.dart' as trainer;

import 'hip_domain_test.dart' show MemoryStorage, loadContent;
import 'trainer_test_pump.dart';
import 'public_media_fixture.dart';

void main() {
  final content = loadContent();

  Future<HipStore> start(
    WidgetTester tester, {
    Size size = const Size(390, 844),
    double textScale = 1,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final store = HipStore(
      content: content,
      storage: MemoryStorage(),
      clock: () => DateTime(2026, 10, 16, 9, 41),
    );
    await store.initialize();
    store
      ..safety = {'pregnancy': false, 'surgery': false, 'acute': false}
      ..identity = HipIdentity.office
      ..scene = HipScene.chair
      ..minutes = 5;
    await tester.pumpWidget(
      HipApp(
        mediaPolicy: installPublicMediaFixture().policy,
        store: store,
        videoEnabled: false,
      ),
    );
    await tester.pumpAndSettle();
    final start = find.byKey(const ValueKey('start-today'));
    await tester.ensureVisible(start);
    await tester.pumpAndSettle();
    await tester.tap(start);
    await pumpTrainerReady(tester);
    return store;
  }

  // The SDK owns overlay placement outside App's media builder. Check the
  // actual media bounds so an external overlay is covered by this guard too.
  Finder onMedia(Finder f) => find.byElementPredicate((element) {
    if (!f.evaluate().contains(element)) return false;
    final video = find.byType(trainer.TrainingActionMedia);
    // The current SDK renders TrainerPoster directly when videos are disabled.
    // Both backends occupy the actual demonstration bounds checked below.
    final media = video.evaluate().isEmpty
        ? find.byType(trainer.TrainerPoster).first
        : video.first;
    final art = media.evaluate().single.renderObject;
    final target = element.renderObject;
    if (art is! RenderBox ||
        target is! RenderBox ||
        !art.hasSize ||
        !target.hasSize) {
      return false;
    }
    final bounds = art.localToGlobal(Offset.zero) & art.size;
    final rect = target.localToGlobal(Offset.zero) & target.size;
    return rect.overlaps(bounds.deflate(.5));
  });

  int countdownSeconds(WidgetTester tester) {
    final clock = tester.widget<trainer.TrainerV1PhaseCountdown>(
      find.byType(trainer.TrainerV1PhaseCountdown),
    );
    return int.parse(clock.value);
  }

  Future<void> enterRest(WidgetTester tester) async {
    final skip = find.byKey(const ValueKey('skip'));
    await tester.tap(skip); // prep → work
    await tester.pumpAndSettle();
    await tester.tap(skip); // work → rest
    // V1 expands the dock before showing and enabling the feedback choices.
    await pumpTrainerControl(
      tester,
      find.byKey(const ValueKey('player-v1-rest-comfortable')),
    );
  }

  testWidgets('prep: the top card and App demo follow the shared stage', (
    tester,
  ) async {
    final store = await start(tester);
    final first = store.todayPlan!.steps.first;
    final prep = find.textContaining('准备 · 第一个动作');
    expect(prep, findsOneWidget);
    expect(onMedia(prep), findsNothing);
    expect(onMedia(find.text(first.drill.name)), findsNothing);
    expect(onMedia(find.text(first.dose)), findsNothing);
    expect(onMedia(find.textContaining('准备开始')), findsNothing);
    // no dimming layer over the picture
    expect(
      onMedia(
        find.byWidgetPredicate(
          (w) =>
              w is ColoredBox &&
              w.color.a > .3 &&
              w.color.a < 1 &&
              w.color.r < .1,
        ),
      ),
      findsNothing,
    );
    // Name + authored dose live in the shared top card, outside the demo.
    expect(find.text(first.drill.name), findsOneWidget);
    expect(find.textContaining(first.dose), findsWidgets);
  });

  testWidgets('rest: SDK cards render HipLab labels with semantic colors', (
    tester,
  ) async {
    await start(tester);
    await enterRest(tester);

    final panel = tester.widget<trainer.TrainerRestFeedbackPanel>(
      find.byType(trainer.TrainerRestFeedbackPanel),
    );
    expect(panel.selected, isNull);
    final theme = trainer.TrainerTheme.playerV1;
    expect(
      panel.options!.map(
        (option) => (option.choice, option.label, option.tone),
      ),
      [
        (
          trainer.TrainerRestFeedbackChoice.comfortable,
          '舒服',
          trainer.TrainerRestFeedbackTone.positive,
        ),
        (
          trainer.TrainerRestFeedbackChoice.tight,
          '有点紧',
          trainer.TrainerRestFeedbackTone.neutral,
        ),
        (
          trainer.TrainerRestFeedbackChoice.pain,
          '疼',
          trainer.TrainerRestFeedbackTone.negative,
        ),
      ],
    );
    for (final (choice, label, color) in [
      (
        trainer.TrainerRestFeedbackChoice.comfortable,
        '舒服',
        theme.feedbackPositive,
      ),
      (trainer.TrainerRestFeedbackChoice.tight, '有点紧', theme.feedbackNeutral),
      (trainer.TrainerRestFeedbackChoice.pain, '疼', theme.feedbackNegative),
    ]) {
      final card = find.byKey(ValueKey('player-v1-rest-${choice.name}'));
      expect(
        find.descendant(of: card, matching: find.text(label)),
        findsOneWidget,
      );
      final icon = find.descendant(of: card, matching: find.byType(Icon));
      expect(tester.widget<Icon>(icon).color, color);
    }
  });

  testWidgets('rest: HipLab feedback in the V1 dock records without skipping', (
    tester,
  ) async {
    final store = await start(tester);
    final plan = store.todayPlan!;
    await enterRest(tester);
    final completedNumber = find.text(
      '1/${plan.steps.length}',
      findRichText: true,
    );
    final nextMove = find.text(
      '${trainer.TrainerStrings.zh().upcomingLabel} · ${plan.steps[1].drill.name}',
    );
    expect(completedNumber, findsOneWidget);
    expect(nextMove, findsOneWidget);
    final ok = find.byKey(const ValueKey('player-v1-rest-comfortable'));
    expect(ok, findsOneWidget);
    final dock = find.byKey(const ValueKey('player-v1-dock'));
    expect(find.descendant(of: dock, matching: ok), findsOneWidget);
    expect(onMedia(ok), findsNothing);
    expect(onMedia(nextMove), findsNothing);
    final before = countdownSeconds(tester);
    await tester.tap(ok);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('已记录'), findsOneWidget);
    expect(
      tester
          .widget<trainer.TrainerRestFeedbackPanel>(
            find.byType(trainer.TrainerRestFeedbackPanel),
          )
          .selected,
      trainer.TrainerRestFeedbackChoice.comfortable,
    );
    await tester.pump(const Duration(seconds: 2));
    // The V1 header stays on the completed move while the rest clock runs.
    expect(
      find.byKey(const ValueKey('player-v1-rest-comfortable')),
      findsOneWidget,
    );
    expect(completedNumber, findsOneWidget);
    expect(nextMove, findsOneWidget);
    final after = countdownSeconds(tester);
    expect(after, lessThan(before));
    expect(after, greaterThan(before - 4));
    await tester.tap(find.byKey(const ValueKey('player-v1-rest-tight')));
    await tester.pump(const Duration(seconds: 1));
    expect(
      find.byKey(const ValueKey('player-v1-rest-comfortable')),
      findsOneWidget,
    );
    // the countdown ends on its own → the drill starts, the row goes away
    await tester.pump(Duration(seconds: after + 1));
    await tester.pump(
      trainer.TrainerMotion.calm + const Duration(milliseconds: 20),
    );
    expect(
      find.byKey(const ValueKey('player-v1-rest-comfortable')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('discomfort')), findsOneWidget);
  });

  testWidgets('rest: 疼 opens the pain ladder; closing it keeps the rest', (
    tester,
  ) async {
    await start(tester);
    await enterRest(tester);
    final before = countdownSeconds(tester);
    await tester.tap(find.byKey(const ValueKey('player-v1-rest-pain')));
    await pumpPainSheet(tester);
    expect(find.text('哪种疼？'), findsOneWidget);
    // dismiss without choosing
    await tester.tapAt(const Offset(195, 80));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('player-v1-rest-comfortable')),
      findsOneWidget,
    );
    expect(countdownSeconds(tester), closeTo(before, 1));
  });

  for (final (size, scale) in [
    (const Size(320, 568), 1.0),
    (const Size(360, 740), 1.5),
    (const Size(390, 844), 1.0),
    (const Size(430, 932), 1.0),
  ]) {
    testWidgets('prep + rest controls stay reachable at $size ×$scale', (
      tester,
    ) async {
      await start(tester, size: size, textScale: scale);
      expect(tester.takeException(), isNull);
      await enterRest(tester);
      expect(tester.takeException(), isNull);
      for (final choice in trainer.TrainerRestFeedbackChoice.values) {
        final control = find.byKey(ValueKey('player-v1-rest-${choice.name}'));
        expect(control.hitTestable(), findsOneWidget, reason: choice.name);
        final r = tester.getRect(control);
        expect(r.bottom, lessThanOrEqualTo(size.height), reason: choice.name);
        expect(r.right, lessThanOrEqualTo(size.width), reason: choice.name);
      }
      await tester.tap(
        find.byKey(const ValueKey('player-v1-rest-comfortable')),
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('已记录'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
