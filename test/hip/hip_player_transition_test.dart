// The SDK owns the V1 stage and transport. HipLab provides rest feedback
// that records an answer without skipping or shortening the countdown.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiplab/hip/control/hip_store.dart';
import 'package:hiplab/hip/data/hip_content_loader.dart';
import 'package:hiplab/hip/data/hip_shared_library.dart';
import 'package:hiplab/hip/domain/hip_models.dart';
import 'package:hiplab/hip/ui/hip_app.dart';
import 'package:hiplab/hip/ui/hip_player_page.dart';
import 'package:hiplab/hip/ui/hip_theme.dart';
import 'package:hiplab/hip/ui/hip_widgets.dart' show HipMediaPolicy;
import 'package:hiplab/hip/ui/library/library_actions.dart';
import 'package:hiplab/hip/voice/hip_voice.dart';
import 'package:hiplab/hip/voice/voice_library.dart';
import 'package:hiplab/hip/voice/voice_queue.dart' show VoiceSettings;

import 'package:ugk_trainer_runtime/ugk_trainer.dart' as trainer;

import 'hip_domain_test.dart' show MemoryStorage, loadContent;
import 'trainer_test_pump.dart';
import 'public_media_fixture.dart';

void main() {
  final content = loadContent();

  testWidgets(
    'a mounted player keeps its training cadence and media snapshot',
    (tester) async {
      const id = 'h-sumo-pry';
      final original = installPublicMediaFixture(sharedLibrary: true);
      final updated = original.withUpdatedThumbnail(id, 's-pigeon');
      addTearDown(updated.dispose);
      final trainingContent = applyHipPublicTraining(content, original.catalog);
      final updatedContent = trainingContent.withPublicTraining(
        trainingContent.publicCatalog!,
        {...trainingContent.publicRhythms, id: trainer.Rhythm.selfPacedReps},
      );
      final store = HipStore(
        content: trainingContent,
        storage: MemoryStorage(),
      );
      await store.initialize();
      final actions = LibraryActions(
        store: store,
        startPlan: (_, {from, radius = 52, originColor}) async {},
      );
      final plan = HipSharedLibrary.planFor(actions, id)!;
      expect(plan.sdkPlan, isNotNull);

      HipVoice voiceOf(String revision) => HipVoice(
        lib: VoiceLibrary.empty,
        output: const trainer.MutedVoiceOutput(),
        settingsOf: () => const VoiceSettings(voice: false, chimes: false),
        online: VoiceLibrary(const {}, const {}, const {}, {
          'catalogue-marker': {'zh': revision},
        }),
      );
      final newVoice = voiceOf('new');
      final active = ValueNotifier((original.policy, voiceOf('old'), 0));
      addTearDown(active.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: ValueListenableBuilder(
            valueListenable: active,
            builder: (context, state, _) => trainer.TrainingMediaPolicyScope(
              policy: state.$1,
              child: HipVoiceScope(
                voice: state.$2,
                child: HipMediaPolicy(
                  videoEnabled: false,
                  child: HipPlayerPage(
                    key: ValueKey(state.$3),
                    store: store,
                    plan: state.$3 == 0
                        ? plan
                        : HipSharedLibrary.planFor(actions, id)!,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      final player = find.byType(trainer.TrainerPlayer);
      trainer.TrainerPlayer current() => tester.widget(player);
      trainer.TrainingMediaPolicy? policy() =>
          trainer.TrainingMediaPolicyScope.read(tester.element(player));
      String? voiceLine() =>
          current().voice!.source.line('catalogue-marker', lang: 'zh');
      final rhythm = current().sessionBuilder!.rhythms[id];
      expect(rhythm, same(trainingContent.publicRhythms[id]));
      expect(voiceLine(), 'old');
      expect(policy(), same(original.policy));

      store.usePublicTrainingContent(updatedContent);
      active.value = (updated.policy, newVoice, 0);
      await tester.pump();
      expect(current().sessionBuilder!.rhythms[id], same(rhythm));
      expect(voiceLine(), 'old');
      expect(policy(), same(original.policy));

      active.value = (updated.policy, newVoice, 1);
      await tester.pump();
      expect(
        current().sessionBuilder!.rhythms[id],
        trainer.Rhythm.selfPacedReps,
      );
      expect(voiceLine(), 'new');
      expect(policy(), same(updated.policy));
    },
  );

  Future<HipStore> start(
    WidgetTester tester, {
    Size size = const Size(390, 844),
    double textScale = 1,
    HipThemeChoice theme = HipThemeChoice.system,
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
      ..theme = theme
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
    final completeSet = find.byKey(const ValueKey('complete-set-button'));
    final feedback = find.byKey(const ValueKey('player-v1-rest-comfortable'));
    // A skipped work phase no longer offers feedback. Finish the set.
    for (var second = 0; second < 40 && feedback.evaluate().isEmpty; second++) {
      if (completeSet.hitTestable().evaluate().isNotEmpty) {
        await tester.tap(completeSet);
      }
      await tester.pump(const Duration(seconds: 1));
    }
    // V1 expands the dock before showing and enabling the feedback choices.
    await pumpTrainerControl(tester, feedback);
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

  testWidgets(
    'dark home start keeps the trainer dark from prep to completion',
    (tester) async {
      final store = await start(tester, theme: HipThemeChoice.dark);
      final player = find.byType(trainer.TrainerPlayer);
      final dark = tester.widget<trainer.TrainerPlayer>(player).theme;
      expect(dark.brightness, Brightness.dark);
      expect(dark.usePlayerV1, isTrue);
      expect(dark.accent, HipPalette.dark.jadeDeep);

      final stage = find.ancestor(
        of: find.byKey(const ValueKey('player-v1-media-viewport')),
        matching: find.byWidgetPredicate((widget) {
          if (widget is! DecoratedBox || widget.decoration is! BoxDecoration) {
            return false;
          }
          final gradient = (widget.decoration as BoxDecoration).gradient;
          return gradient is LinearGradient &&
              gradient.colors.first == dark.stageTop &&
              gradient.colors.last == dark.stageBottom;
        }),
      );
      expect(find.textContaining('准备 · 第一个动作'), findsOneWidget);
      expect(stage, findsOneWidget);

      await enterRest(tester);
      final panel = tester.widget<trainer.TrainerRestFeedbackPanel>(
        find.byType(trainer.TrainerRestFeedbackPanel),
      );
      expect(panel.theme, same(dark));
      expect(stage, findsOneWidget);
      await tester.tap(
        find.byKey(const ValueKey('player-v1-rest-comfortable')),
      );
      await tester.pumpAndSettle();

      final finish = find.byKey(const ValueKey('finish'));
      final skip = find.byKey(const ValueKey('skip')).hitTestable();
      for (var phase = 0; phase < 40 && finish.evaluate().isEmpty; phase++) {
        expect(skip, findsOneWidget);
        await tester.tap(skip);
        await tester.pumpAndSettle();
      }
      expect(finish, findsOneWidget);
      final hero = tester.widget<DecoratedBox>(
        find.byKey(const ValueKey('completion-hero')),
      );
      final gradient = (hero.decoration as BoxDecoration).gradient!;
      expect(gradient.colors, [dark.heroTop, dark.heroBottom]);
      expect(store.streak, 1);
      expect(tester.widget<trainer.TrainerPlayer>(player).streakDays, 1);
      expect(
        find.byKey(const ValueKey('completion-item-rest-feedback-0')),
        findsOneWidget,
      );
      expect(find.text('本次感受'), findsNothing);
      expect(find.byKey(const ValueKey('player-done-note')), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

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
      findsNothing,
    );
    expect(completedNumber, findsOneWidget);
    expect(nextMove, findsOneWidget);
    final after = countdownSeconds(tester);
    expect(after, lessThan(before));
    expect(after, greaterThan(before - 4));
    await tester.tap(
      find.byKey(const ValueKey('player-v1-rest-feedback-edit')),
    );
    final tight = find.byKey(const ValueKey('player-v1-rest-tight'));
    await pumpTrainerControl(tester, tight);
    await tester.tap(tight);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('player-v1-rest-feedback-edit')),
      findsOneWidget,
    );
    expect(tight, findsNothing);
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
      find.byKey(const ValueKey('player-v1-rest-feedback-edit')),
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
