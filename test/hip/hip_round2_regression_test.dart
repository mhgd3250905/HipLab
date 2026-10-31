import 'dart:async';
import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiplab/core/media/media_controller.dart';
import 'package:hiplab/hip/control/hip_store.dart';
import 'package:hiplab/hip/domain/hip_models.dart';
import 'package:hiplab/hip/ui/hip_app.dart';
import 'package:hiplab/hip/ui/hip_assessment_page.dart';
import 'package:hiplab/hip/ui/hip_icons.dart';
import 'package:hiplab/hip/ui/hip_routes.dart';
import 'package:hiplab/hip/ui/hip_theme.dart';
import 'package:hiplab/hip/ui/hip_widgets.dart';
import 'package:hiplab/hip/voice/hip_voice.dart';
import 'package:hiplab/hip/voice/voice_library.dart';
import 'package:hiplab/hip/voice/voice_queue.dart';

import 'package:ugk_trainer/ugk_trainer.dart' as trainer;

import 'hip_domain_test.dart' show MemoryStorage, loadContent;
import 'checkup_entry.dart';

class _HandoffOutput implements VoiceOutput {
  final events = <String>[];
  final release = Completer<void>();
  int ends = 0;
  @override
  Future<void> begin() async => events.add('begin');
  @override
  Future<void> end() async {
    events.add('end');
    if (++ends == 1) await release.future;
    events.add('released');
  }

  @override
  Future<void> speak(List<String> assets) async {}
  @override
  Future<void> stopSpeech() async {}
  @override
  Future<void> chime(String asset) async {}
  @override
  set volume(double value) {}
}

Future<HipStore> _app(WidgetTester tester, {VoiceOutput? output}) async {
  final store = HipStore(content: loadContent(), storage: MemoryStorage());
  await store.initialize();
  store
    ..safety = {'pregnancy': false, 'surgery': false, 'acute': false}
    ..identity = HipIdentity.office
    ..voice = const VoiceSettings(chimes: false);
  await tester.pumpWidget(
    HipApp(
      store: store,
      videoEnabled: false,
      voice: output == null
          ? null
          : HipVoice(
              lib: VoiceLibrary.empty,
              output: output,
              settingsOf: () => store.voice,
            ),
    ),
  );
  await tester.pumpAndSettle();
  return store;
}

Future<void> _keyboardActivate(WidgetTester tester, Finder button) async {
  final detector = find
      .descendant(of: button, matching: find.byType(GestureDetector))
      .first;
  Focus.of(tester.element(detector)).requestFocus();
  await tester.pump();
  await tester.sendKeyEvent(LogicalKeyboardKey.enter);
  await tester.pumpAndSettle();
}

Future<void> _expectPausedClock(WidgetTester tester) async {
  // The shared paused control intentionally breathes indefinitely. Assert its
  // state and the frozen clock after a finite morph, without waiting for idle.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  expect(
    tester
        .widget<trainer.UgkPlayPauseButton>(
          find.byType(trainer.UgkPlayPauseButton),
        )
        .isPlaying,
    isFalse,
  );
  final digits = find.byType(trainer.TrainerCountdownDigits);
  final before = tester.widget<trainer.TrainerCountdownDigits>(digits).value;
  await tester.pump(const Duration(seconds: 2));
  expect(tester.widget<trainer.TrainerCountdownDigits>(digits).value, before);
}

void main() {
  testWidgets(
    'zero-time tab reversals leave start hittable and open training',
    (tester) async {
      final handle = tester.ensureSemantics();
      await _app(tester);
      for (final tab in [1, 0, 1, 0, 2, 0]) {
        await tester.tap(find.byKey(ValueKey('tab-$tab')));
        await tester.pump();
      }
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('tab-body-1')), findsNothing);
      expect(find.byKey(const ValueKey('tab-body-2')), findsNothing);
      final start = find.byKey(const ValueKey('start-today'));
      expect(start.hitTestable(), findsOneWidget);
      await tester.tap(start);
      // Wait for the finite App route transition. The training itself
      // keeps animating as its seconds/reps change, so it is not an idle UI.
      await tester.pump();
      await tester.pump(HipMotion.expand + const Duration(milliseconds: 100));
      expect(find.byType(trainer.TrainerPlayer), findsOneWidget);
      expect(find.byKey(const ValueKey('finish')), findsNothing);
      // The shared stage pins the counter and transport in the viewport.
      expect(find.byType(trainer.TrainerCountdownDigits), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('pause')));
      await _expectPausedClock(tester);
      handle.dispose();
    },
  );

  testWidgets('disabled circle exports one labelled disabled button', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: HipCircleButton(
            icon: HipGlyph.close,
            tooltip: '关闭',
            onPressed: null,
          ),
        ),
      ),
    );
    final buttons = find.semantics
        .byPredicate((node) => node.getSemanticsData().flagsCollection.isButton)
        .evaluate()
        .where((node) => !node.isMergedIntoParent)
        .toList();
    expect(buttons, hasLength(1));
    expect(buttons.single.getSemanticsData().label, '关闭');
    expect(
      buttons.single.getSemanticsData().flagsCollection.isEnabled !=
          Tristate.none,
      isTrue,
    );
    expect(
      buttons.single.getSemanticsData().flagsCollection.isEnabled ==
          Tristate.isTrue,
      isFalse,
    );
    expect(
      buttons.single.getSemanticsData().hasAction(SemanticsAction.tap),
      isFalse,
    );
    handle.dispose();
  });

  testWidgets('each picker and bottom tab exports one named semantic button', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await _app(tester);
    for (final label in [
      '5 分',
      '10 分',
      '15 分',
      '办公椅',
      '居家',
      '今日',
      '练习',
      '进度',
      '开始',
    ]) {
      final matches = find.semantics
          .byPredicate(
            (node) =>
                !node.isMergedIntoParent &&
                node.getSemanticsData().flagsCollection.isButton &&
                node
                        .getSemanticsData()
                        .label
                        .replaceAll(RegExp(r'\s+'), ' ')
                        .trim() ==
                    label,
          )
          .evaluate();
      expect(
        matches.length,
        1,
        reason: '$label must be a single accessible button',
      );
    }
    final selectedTab = find.semantics
        .byPredicate(
          (node) =>
              !node.isMergedIntoParent &&
              node.getSemanticsData().flagsCollection.isButton &&
              node.getSemanticsData().label == '今日',
        )
        .evaluate()
        .single;
    expect(
      selectedTab.getSemanticsData().flagsCollection.isSelected ==
          Tristate.isTrue,
      isTrue,
    );
    for (final button
        in find.semantics
            .byPredicate(
              (node) => node.getSemanticsData().flagsCollection.isButton,
            )
            .evaluate()) {
      if (button.isMergedIntoParent) continue;
      final nested = collectAllSemanticsNodesFrom(button).where(
        (node) =>
            !node.isMergedIntoParent &&
            node.getSemanticsData().flagsCollection.isButton,
      );
      expect(
        nested,
        isEmpty,
        reason: '${button.label} contains a second button',
      );
    }
    handle.dispose();
  });

  testWidgets(
    'rapid tab returns keep one source-key and Hero subtree per tab',
    (tester) async {
      await _app(tester);
      for (final index in [1, 0, 2, 1, 2, 0]) {
        await tester.tap(find.byKey(ValueKey('tab-$index')));
        await tester.pump(const Duration(milliseconds: 35));
        expect(tester.takeException(), isNull);
        expect(
          find.byKey(ValueKey('tab-body-$index'), skipOffstage: false),
          findsOneWidget,
        );
      }
      await tester.pumpAndSettle();
      for (var i = 0; i < 3; i++) {
        expect(
          find.byKey(ValueKey('tab-body-$i'), skipOffstage: false),
          findsOneWidget,
        );
        expect(
          find.byKey(ValueKey('tab-body-$i')),
          i == 0 ? findsOneWidget : findsNothing,
        );
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'pressable supports Enter and Space and disables keyboard activation',
    (tester) async {
      final focus = FocusNode();
      addTearDown(focus.dispose);
      var taps = 0;
      Future<void> show(bool enabled) => tester.pumpWidget(
        MaterialApp(
          home: HipPressable(
            focusNode: focus,
            onTap: enabled ? () => taps++ : null,
            child: const Text('activate'),
          ),
        ),
      );
      await show(true);
      focus.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      expect(taps, 2);
      await show(false);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      expect(taps, 2);
    },
  );

  testWidgets('bottom tabs and segmented choices remain keyboard operable', (
    tester,
  ) async {
    final store = await _app(tester);
    await _keyboardActivate(tester, find.byKey(const ValueKey('minutes-15')));
    expect(store.minutes, 15);
    await _keyboardActivate(tester, find.byKey(const ValueKey('tab-1')));
    // 练习 (拍板 2026-10-19): the check-up card replaces the 自测 tab.
    expect(find.byKey(const ValueKey('hip-check-card')), findsOneWidget);
    await _keyboardActivate(tester, find.byKey(const ValueKey('tab-0')));
    expect(find.byKey(const ValueKey('start-today')), findsOneWidget);
  });

  testWidgets(
    'assessment releases old audio before training begins, only once',
    (tester) async {
      final output = _HandoffOutput();
      await _app(tester, output: output);
      await openCheckupIntro(tester);
      await tester.tap(find.byKey(const ValueKey('assessment-start')));
      await tester.pumpAndSettle();
      for (var i = 0; i < 6; i++) {
        await tester.tap(find.byKey(const ValueKey('assessment-skip')));
        await tester.pumpAndSettle();
      }
      expect(output.events, ['begin']);
      await tester.tap(find.byKey(const ValueKey('result-start')));
      await tester.pump();
      expect(output.events, ['begin', 'end']);
      expect(find.byType(HipAssessmentPage), findsOneWidget);
      output.release.complete();
      await tester.pumpAndSettle();
      expect(output.events, ['begin', 'end', 'released', 'begin']);
      expect(find.byType(HipAssessmentPage), findsNothing);
      await tester.tap(find.byKey(const ValueKey('pause')));
      await _expectPausedClock(tester);
      expect(
        output.ends,
        1,
        reason: 'old route disposal must not end the new session',
      );
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('hidden and covered tabs pause media and preserve manual pause', (
    tester,
  ) async {
    final drill = loadContent().drill('s-kneel-hipflex');
    DrillMediaController? controller;
    Future<void> show(int tab, bool play) => tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HipTabSwitcher(
            index: tab,
            direction: tab == 0 ? -1 : 1,
            child: KeyedSubtree(
              key: ValueKey('tab-body-$tab'),
              child: tab == 0
                  ? HipDrillArt(
                      drill: drill,
                      play: play,
                      mediaViewBuilder: (_, c) {
                        controller = c;
                        return const SizedBox.expand();
                      },
                    )
                  : const Text('other'),
            ),
          ),
        ),
      ),
    );
    await show(0, true);
    final retained = controller!;
    expect(retained.wantsPlay, isTrue);
    await show(1, true);
    await tester.pumpAndSettle();
    expect(retained.active, isFalse);
    expect(retained.wantsPlay, isFalse);
    await show(0, true);
    await tester.pumpAndSettle();
    expect(controller, same(retained));
    expect(retained.wantsPlay, isTrue);
    final navigator = Navigator.of(tester.element(find.byType(HipTabSwitcher)));
    unawaited(
      navigator.push(MaterialPageRoute<void>(builder: (_) => const Scaffold())),
    );
    await tester.pumpAndSettle();
    expect(retained.active, isFalse);
    navigator.pop();
    await tester.pumpAndSettle();
    expect(retained.wantsPlay, isTrue);
    await show(0, false);
    await show(1, false);
    await tester.pumpAndSettle();
    await show(0, false);
    await tester.pumpAndSettle();
    expect(retained.active, isTrue);
    expect(retained.wantsPlay, isFalse);
    await tester.pumpWidget(const SizedBox());
  });
}
