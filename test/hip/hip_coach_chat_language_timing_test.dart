import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiplab/hip/coach/hip_coach_chat.dart';
import 'package:hiplab/hip/control/hip_store.dart';
import 'package:hiplab/hip/trainer/hip_sdk_session_builder.dart';
import 'package:hiplab/hip/ui/coach/hip_coach_chat_page.dart';
import 'package:hiplab/hip/ui/library/library_actions.dart';
import 'package:hiplab/hip/voice/hip_voice.dart';
import 'package:hiplab/hip/voice/session_script.dart';
import 'package:hiplab/hip/voice/voice_library.dart';
import 'package:hiplab/hip/voice/voice_queue.dart';
import 'package:ugk_coach/ugk_coach.dart' as coach;
import 'package:ugk_coach_chat/ugk_coach_chat.dart';
import 'package:ugk_trainer_runtime/engine.dart' as trainer;

import 'hip_domain_test.dart' show MemoryStorage, loadContent;
import 'hip_voice_test.dart' show loadVoiceLibrary;

void main() {
  testWidgets('loaded chat timing follows a later voice language change', (
    tester,
  ) async {
    final content = loadContent();
    final disk = MemoryStorage();
    final store = HipStore(content: content, storage: disk);
    var settings = const VoiceSettings(language: VoiceLanguage.zh);
    final voice = HipVoice(
      lib: loadVoiceLibrary(),
      output: const MutedVoiceOutput(),
      settingsOf: () => settings,
    );
    final host = HipCoachChat(
      store: store,
      storage: disk,
      gateway: CoachGatewayBinding.shared(coach.FakeLlmClient(const [])),
    );
    addTearDown(() async {
      await host.close();
      store.dispose();
    });
    final actions = LibraryActions(
      store: store,
      coach: host,
      startPlan: (_, {from, radius = 28, originColor}) async {},
    );
    late BuildContext hostContext;
    await tester.pumpWidget(
      MaterialApp(
        home: HipVoiceScope(
          voice: voice,
          child: Builder(
            builder: (context) {
              hostContext = context;
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    final chat = (await tester.runAsync(
      () => loadHipChat(hostContext, actions),
    ))!;
    const plan = coach.TrainingPlan(
      id: 'language-switch',
      source: 'ai',
      title: '换边语音计时',
      goal: 'mobility',
      scene: 'home',
      level: 1,
      targetMinutes: 2,
      blocks: [
        coach.PlanBlock(
          id: 'main',
          name: 'Main',
          type: coach.BlockType.main,
          items: [
            coach.PlanItem(
              exerciseId: 's-figure4',
              mode: coach.DoseMode.time,
              sets: 1,
              workSeconds: 30,
              restSeconds: 0,
              perSide: true,
            ),
          ],
        ),
      ],
    );

    double verifyTiming(int expectedSwitchSeconds) {
      final script = HipSessionScript(
        lib: voice.lib,
        lang: voice.lang,
        steps: const [],
        kits: content.kits,
        useSdkPhases: true,
      );
      final player = hipSdkSessionBuilder(
        content,
        switchSecondsFor: script.switchSecondsFor,
      );
      final phases = player.phases(plan);
      expect(
        phases
            .singleWhere((p) => p.kind == trainer.PhaseKind.switchSide)
            .seconds,
        expectedSwitchSeconds,
      );
      final actual = chat.profile.executionTiming(plan);
      final expected = player.executionTiming(plan);
      expect(actual.totalSeconds, expected.totalSeconds);
      expect(
        actual.blocks.map((b) => b.seconds),
        expected.blocks.map((b) => b.seconds),
      );
      return actual.totalSeconds;
    }

    final chineseSeconds = verifyTiming(6);
    settings = settings.copyWith(language: VoiceLanguage.en);
    expect(host.controller, same(chat));
    expect(verifyTiming(7), chineseSeconds + 1);
    await tester.pumpWidget(const SizedBox());
  });
}
