import 'package:flutter_test/flutter_test.dart';
import 'package:hiplab/hip/coach/hip_coach_chat.dart';
import 'package:hiplab/hip/coach/hip_coach_chat_storage.dart';
import 'package:hiplab/hip/control/hip_store.dart';
import 'package:hiplab/hip/data/hip_content_loader.dart';
import 'package:hiplab/hip/domain/hip_library.dart';
import 'package:hiplab/hip/domain/hip_models.dart';
import 'package:hiplab/hip/trainer/hip_sdk_session_builder.dart';
import 'package:ugk_coach/ugk_coach.dart' as coach;
import 'package:ugk_coach_chat/ugk_coach_chat.dart';

import 'hip_ai_coach_test.dart' show FileAssetBundle, noopCoachActions;
import 'hip_domain_test.dart' show MemoryStorage;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late HipContent content;
  setUpAll(() async {
    content = await loadHipContent(FileAssetBundle());
  });

  test(
    'fresh AI host imports the actual two-action public group without a model call',
    () async {
      final disk = MemoryStorage();
      final initial = HipStore(content: content, storage: disk);
      await initial.initialize();
      await initial.saveCustomRoutine(
        const CustomRoutine(
          id: 'public-two',
          name: 'Public two',
          restSeconds: 20,
          steps: [CustomStep('abs-A'), CustomStep('abs-B')],
        ),
      );
      initial.dispose();
      final persisted = disk.values[HipStore.storageKey];
      final store = HipStore(content: content, storage: disk);
      await store.initialize();
      addTearDown(store.dispose);
      expect(store.content.kit('abs-A'), isNull);
      expect(store.content.kit('abs-B'), isNull);
      final client = coach.FakeLlmClient([]);
      final host = HipCoachChat(
        store: store,
        storage: disk,
        bundle: FileAssetBundle(),
        gateway: CoachGatewayBinding.shared(client),
        replyDelay: Duration.zero,
      );
      addTearDown(host.close);
      final chat = await host.load(
        builder: hipSdkSessionBuilder(content),
        actions: noopCoachActions(),
      );
      expect(chat.error, isNull);
      expect(chat.inSafetyCheck, isTrue);
      expect(client.requests, isEmpty);
      final saved = chat.savedPlans.single;
      expect(saved.externalId, 'public-two');
      final items = saved.plan.blocks.single.items;
      expect(items.map((item) => item.exerciseId), ['abs-A', 'abs-B']);
      expect(items.map((item) => item.mode), [
        coach.DoseMode.time,
        coach.DoseMode.time,
      ]);
      expect(items.map((item) => item.sets), [3, 4]);
      expect(items.map((item) => item.workSeconds), [20, 10]);
      expect(items.map((item) => item.restSeconds), [20, 20]);
      expect(disk.values[HipStore.storageKey], persisted);
      expect(store.customRoutines.single.coachPlan, isNull);
    },
  );

  test(
    'public time and rep imports retain explicit dose overrides and group rest',
    () async {
      final store = HipStore(content: content, storage: MemoryStorage());
      addTearDown(store.dispose);
      await store.saveCustomRoutine(
        const CustomRoutine(
          id: 'public-overrides',
          name: 'Overrides',
          restSeconds: 30,
          steps: [
            CustomStep('abs-A', seconds: 35, sets: 2),
            CustomStep('abs-C', reps: 6, sets: 2),
          ],
        ),
      );
      final adapter = HiplabCoachPlanStore(
        store,
        catalog: content.publicCatalog!,
      );
      final items = (await adapter.load()).single.plan.blocks.single.items;
      expect(items.first.mode, coach.DoseMode.time);
      expect(items.first.workSeconds, 35);
      expect(items.first.reps, isNull);
      expect(items.last.mode, coach.DoseMode.reps);
      expect(items.last.reps, 6);
      expect(items.last.workSeconds, isNull);
      expect(items.map((item) => item.sets), [2, 2]);
      expect(items.map((item) => item.restSeconds), [30, 30]);
      expect(adapter.unreadableExternalIds, isEmpty);
    },
  );

  test(
    'mixed imports keep local kit doses and public defaults in authored order',
    () async {
      final store = HipStore(content: content, storage: MemoryStorage());
      addTearDown(store.dispose);
      await store.saveCustomRoutine(
        const CustomRoutine(
          id: 'mixed-import',
          name: 'Mixed',
          restSeconds: 15,
          steps: [
            CustomStep('s-butterfly', seconds: 45, sets: 2),
            CustomStep('n-chair-wiper', reps: 4, sets: 2),
            CustomStep('abs-C'),
          ],
        ),
      );
      final adapter = HiplabCoachPlanStore(
        store,
        catalog: content.publicCatalog!,
      );
      final items = (await adapter.load()).single.plan.blocks.single.items;
      expect(items.map((item) => item.exerciseId), [
        's-butterfly',
        'n-chair-wiper',
        'abs-C',
      ]);
      expect(items.map((item) => item.sets), [2, 2, 3]);
      expect(items.first.workSeconds, 45);
      expect(items[1].reps, 4);
      expect(items[1].perSide, isTrue);
      expect(items.last.reps, 8);
      expect(items.map((item) => item.restSeconds), [15, 15, 15]);
      expect(adapter.unreadableExternalIds, isEmpty);
    },
  );
}
