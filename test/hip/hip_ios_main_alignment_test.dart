// Integration of the mainline action kits with the iOS player: an OS
// interruption must freeze the rep clock and never replay missed counts.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiplab/hip/domain/hip_models.dart';
import 'package:hiplab/hip/domain/hip_session.dart';
import 'package:hiplab/hip/domain/hip_settings.dart';
import 'package:hiplab/hip/ui/hip_player_page.dart';
import 'package:hiplab/hip/ui/hip_widgets.dart';
import 'package:hiplab/hip/voice/hip_voice.dart';
import 'package:hiplab/hip/voice/voice_library.dart';
import 'package:hiplab/hip/voice/voice_queue.dart';

import 'hip_ios_test.dart'
    show FakeInterruptibleOutput, bootIos, iPhones, safeAreaOffenders;

void main() {
  final ios = TargetPlatformVariant.only(TargetPlatform.iOS);

  for (final language in [VoiceLanguage.zh, VoiceLanguage.en]) {
    testWidgets('iOS ${language.name} reps resume after an OS interruption', (
      tester,
    ) async {
      final output = FakeInterruptibleOutput();
      addTearDown(output.events.close);
      final voice = HipVoice(
        lib: VoiceLibrary.fromJson(
          jsonDecode(File('assets/voice/manifest.json').readAsStringSync())
              as Map<String, dynamic>,
        ),
        output: output,
        settingsOf: () => VoiceSettings(language: language),
      );
      final store = await bootIos(tester, voice: voice);
      final drill = store.content.drill('h-butterfly-active');
      final step = PlanStep(
        drill: drill,
        dose: '慢开慢合 6 次',
        seconds: 60,
        sided: false,
        kitDose: const KitDose(reps: 6),
      );
      tester
          .state<NavigatorState>(find.byType(Navigator))
          .push<void>(
            MaterialPageRoute(
              builder: (_) => HipPlayerPage(
                store: store,
                plan: TrainingPlan(
                  routines: const [],
                  steps: [step],
                  transitionSeconds: 15,
                ),
              ),
            ),
          );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('player-skip')));
      await tester.pump();
      output.spoken.clear();
      await tester.pump(const Duration(milliseconds: 1300));
      final lang = language.clipLanguage;
      String clip(String key) => 'assets/voice/$lang/$key.m4a';
      List<String> spoken() => output.spoken.expand((line) => line).toList();
      expect(spoken(), contains(clip('n.1')));
      expect(spoken(), contains(clip('w.open')));
      expect(spoken(), isNot(contains(clip('n.2'))));

      output.events.add(AudioInterruption.began);
      await tester.pump();
      expect(find.text('已暂停'), findsOneWidget);
      final ring = find.byKey(const ValueKey('player-ring'));
      final remaining = tester.widget<HipCountdownRing>(ring).label;
      final before = spoken();
      await tester.pump(const Duration(seconds: 30));
      expect(tester.widget<HipCountdownRing>(ring).label, remaining);
      expect(spoken(), before);
      output.events.add(AudioInterruption.ended);
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('已暂停'), findsOneWidget);
      expect(output.reactivations, 0);

      await tester.tap(find.byKey(const ValueKey('player-pause')));
      await tester.pump();
      await tester.pump(const Duration(seconds: 11));
      expect(output.reactivations, 1);
      expect(find.text('已暂停'), findsNothing);
      expect(spoken().where((asset) => asset == clip('n.1')), hasLength(1));
      expect(spoken().where((asset) => asset == clip('n.2')), hasLength(1));
      expect(spoken(), isNot(contains(clip('n.3'))));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      expect(output.ends, 1);
    }, variant: ios);
  }

  for (final phone in iPhones) {
    testWidgets('${phone.name}: light-theme rep player keeps safe areas', (
      tester,
    ) async {
      await bootIos(tester, phone: phone, theme: HipThemeChoice.light);
      await tester.tap(find.byKey(const ValueKey('start-today')));
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.tap(find.byKey(const ValueKey('player-skip')));
      await tester.pump(const Duration(milliseconds: 600));
      expect(safeAreaOffenders(tester, phone), isEmpty);
      expect(find.byKey(const ValueKey('player-pain')), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    }, variant: ios);
  }
}
