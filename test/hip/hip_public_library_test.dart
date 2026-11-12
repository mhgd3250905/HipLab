import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiplab/hip/control/hip_store.dart';
import 'package:hiplab/hip/data/hip_action_scope.dart';
import 'package:hiplab/hip/data/hip_content_loader.dart';
import 'package:hiplab/hip/data/hip_shared_library.dart';
import 'package:hiplab/hip/domain/hip_library.dart';
import 'package:hiplab/hip/ui/hip_player_page.dart';
import 'package:hiplab/hip/ui/hip_widgets.dart';
import 'package:hiplab/hip/ui/library/library_actions.dart';
import 'package:hiplab/hip/ui/library/practice_page.dart' show GroupCard;
import 'package:hiplab/hip/voice/hip_voice.dart';
import 'package:ugk_trainer_runtime/ugk_trainer_runtime.dart' as trainer;

import 'hip_ai_coach_test.dart' show FileAssetBundle;
import 'hip_domain_test.dart' show MemoryStorage;
import 'public_media_fixture.dart';
import 'trainer_test_pump.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('saved public plans keep their new-action thumbnails', (
    tester,
  ) async {
    final content = await loadHipContent(FileAssetBundle());
    installPublicMediaFixture(sharedLibrary: true);
    final store = HipStore(content: content, storage: MemoryStorage());
    addTearDown(store.dispose);
    final actions = LibraryActions(
      store: store,
      startPlan: (plan, {from, radius = 28, originColor}) async {},
    );
    final plan = HipSharedLibrary.planFor(actions, 'chest-A')!;
    final group = CustomRoutine(
      id: 'saved-public',
      name: '胸部训练',
      steps: [const CustomStep('chest-A')],
      coachPlan: plan.sdkPlan!.toJson(),
    );
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh'),
        supportedLocales: const [Locale('zh'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
          body: GroupCard(actions: actions, group: group),
        ),
      ),
    );
    await tester.pump();
    expect(
      tester.widget<HipDrillArt>(find.byType(HipDrillArt)).drill.id,
      'chest-A',
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  test(
    'public single practice preserves all 248 SDK doses without the legacy safety gate',
    () async {
      final content = await loadHipContent(FileAssetBundle());
      final store = HipStore(content: content, storage: MemoryStorage());
      addTearDown(store.dispose);
      final previous = HipSharedLibrary.current;
      addTearDown(() => HipSharedLibrary.current = previous);
      HipSharedLibrary.current = hipSharedLibraryConfig(
        hipActionScope(content.publicCatalog!),
      );
      final actions = LibraryActions(
        store: store,
        startPlan: (plan, {from, radius = 28, originColor}) async {},
      );
      var admitted = 0;
      for (final drill in content.publicCatalog!.drills) {
        final plan = HipSharedLibrary.planFor(actions, drill.id);
        if (!hiplabCoachAuthorizedActionIds.contains(drill.id)) {
          expect(plan, isNull, reason: drill.id);
          continue;
        }
        admitted++;
        expect(plan, isNotNull, reason: drill.id);
        expect(plan!.source, PlanSource.single);
        final item = plan.sdkPlan!.items.single;
        expect(item.exerciseId, drill.id);
        expect(item.mode, drill.defaultDose.mode);
        expect(item.sets, drill.defaultDose.sets);
        expect(item.reps, drill.defaultDose.reps);
        expect(item.workSeconds, drill.defaultDose.seconds);
        expect(item.restSeconds, drill.defaultDose.restSeconds);
        expect(item.perSide, drill.unilateral);
        expect(plan.sdkPlan!.equipment, drill.equipment.toList());
      }
      expect(admitted, 248);
      expect(HipSharedLibrary.planFor(actions, 'h-db-shrug'), isNotNull);
      for (final id in assessmentOnlyDrills) {
        expect(HipSharedLibrary.planFor(actions, id), isNull, reason: id);
      }
      // Legacy safety answers no longer veto public single practice.
      store.safety = {'pregnancy': true};
      expect(HipSharedLibrary.canStart(actions, 'chest-A'), isTrue);
    },
  );

  testWidgets(
    'new public action opens the SDK player with SDK discomfort flow',
    (tester) async {
      final content = await loadHipContent(FileAssetBundle());
      final fixture = installPublicMediaFixture(sharedLibrary: true);
      final store = HipStore(content: content, storage: MemoryStorage());
      addTearDown(store.dispose);
      final actions = LibraryActions(
        store: store,
        startPlan: (plan, {from, radius = 28, originColor}) async {},
      );
      final plan = HipSharedLibrary.planFor(actions, 'chest-A')!;
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('zh'),
          supportedLocales: const [Locale('zh'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: HipVoiceScope(
            voice: HipVoice.silent,
            child: HipMediaPolicy(
              videoEnabled: false,
              child: trainer.TrainingMediaPolicyScope(
                policy: fixture.policy,
                child: HipPlayerPage(store: store, plan: plan),
              ),
            ),
          ),
        ),
      );
      await pumpTrainerReady(tester);
      final player = tester.widget<trainer.TrainerPlayer>(
        find.byType(trainer.TrainerPlayer),
      );
      final definition = content.publicCatalog!['chest-A']!;
      expect(player.drillOf('chest-A')!.name, definition.name.of('zh'));
      expect(player.drillOf('chest-A')!.cues, definition.cues['zh']);
      expect(player.onDiscomfort, isNull);
      expect(fixture.requested, isEmpty);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
