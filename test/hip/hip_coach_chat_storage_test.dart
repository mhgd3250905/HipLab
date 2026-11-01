import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hiplab/hip/coach/hip_coach_chat_storage.dart';
import 'package:hiplab/hip/coach/hip_coach_profile.dart';
import 'package:hiplab/hip/control/hip_store.dart';
import 'package:hiplab/hip/domain/hip_library.dart';
import 'package:hiplab/hip/domain/hip_settings.dart';
import 'package:hiplab/hip/voice/voice_queue.dart';
import 'package:ugk_coach/ugk_coach.dart' as coach;
import 'package:ugk_coach_chat/ugk_coach_chat.dart';
import 'package:ugk_trainer_runtime/engine.dart' as trainer;

import 'hip_domain_test.dart' show MemoryStorage, loadContent;

class RejectingStorage extends MemoryStorage {
  bool reject = false;
  @override
  Future<void> write(String key, String value) async {
    if (reject) throw StateError('Test disk failure');
    await super.write(key, value);
  }
}

void main() {
  final content = loadContent();
  final catalog = coach.Catalog.fromJson(
    jsonDecode(File('assets/coach/catalog.json').readAsStringSync())
        as Map<String, dynamic>,
  );
  final at = DateTime(2026, 11, 2, 10);
  final plan = coach.TrainingPlan(
    id: 'preserved-plan',
    source: 'ai',
    title: '原始 SDK 完整计划',
    goal: 'mobility',
    scene: 'home',
    level: 1,
    targetMinutes: 2,
    blocks: [
      coach.PlanBlock(
        id: 'circuit',
        name: '保留轮次',
        type: coach.BlockType.main,
        rounds: 2,
        items: [
          coach.PlanItem(
            exerciseId: 's-butterfly',
            mode: coach.DoseMode.time,
            sets: 2,
            workSeconds: 30,
            restSeconds: 7,
            perSide: false,
          ),
        ],
      ),
    ],
  );
  CustomRoutine routine({String name = '旧计划'}) => CustomRoutine(
    id: 'old-saved',
    name: name,
    steps: const [CustomStep('s-butterfly', seconds: 30, sets: 2)],
    restSeconds: 7,
    createdAt: at,
    updatedAt: at,
    coachPlan: plan.toJson(),
    coachSdkVersion: 3,
  );
  CoachChatSnapshot envelope(String namespace, String text) =>
      CoachChatSnapshot(
        appId: 'hiplab',
        storageNamespace: namespace,
        session: coach.CoachSessionSnapshot(
          sessionState: coach.CoachSessionState(),
          ledger: coach.ContextTurnLedger(const []),
        ),
        messages: [
          {
            'id': 'old-message',
            'role': 'assistant',
            'at': at.toIso8601String(),
            'text': text,
          },
        ],
      );

  test(
    'v2 saved full plan survives load and unrelated App state writes',
    () async {
      final disk = MemoryStorage();
      disk.values[HipStore.storageKey] = jsonEncode({
        'customRoutines': CustomRoutinesCodec.encode([routine()]),
        'doneDays': ['2026-11-01'],
      });
      final store = HipStore(content: content, storage: disk);
      addTearDown(store.dispose);
      await store.initialize();
      final plans = HiplabCoachPlanStore(store, catalog: catalog);
      final saved = (await plans.load()).single;
      expect(saved.externalId, 'old-saved');
      expect(saved.plan.toJson(), plan.toJson());
      expect(saved.sdkVersion, 3);
      expect(store.customRoutines.single.restSeconds, 7);
      await store.setTheme(HipThemeChoice.dark);
      final restarted = HipStore(content: content, storage: disk);
      addTearDown(restarted.dispose);
      await restarted.initialize();
      expect(restarted.customRoutines.single.coachPlan, plan.toJson());
      expect(restarted.doneDays, {'2026-11-01'});
    },
  );

  test(
    'CAS serializes concurrent saves and detects a later deletion',
    () async {
      final disk = MemoryStorage();
      final store = HipStore(content: content, storage: disk);
      addTearDown(store.dispose);
      await store.writeCoachCustomRoutine(routine(), update: false);
      final revision = HipStore.customRoutineRevision(
        store.customRoutines.single,
      );
      final results = await Future.wait([
        store.writeCoachCustomRoutine(
          routine(name: '第一次'),
          update: true,
          expectedStorageRevision: revision,
        ),
        store.writeCoachCustomRoutine(
          routine(name: '第二次'),
          update: true,
          expectedStorageRevision: revision,
        ),
      ]);
      expect(results.map((r) => r.status), [
        CoachRoutineWriteStatus.saved,
        CoachRoutineWriteStatus.conflict,
      ]);
      expect(store.customRoutines.single.name, '第一次');
      await store.deleteCustomRoutine('old-saved');
      final deleted = await store.writeCoachCustomRoutine(
        routine(),
        update: true,
        expectedStorageRevision: revision,
      );
      expect(deleted.status, CoachRoutineWriteStatus.deleted);
      expect(store.customRoutines, isEmpty);
    },
  );

  test(
    'a rejected durable save never publishes or poisons the queue',
    () async {
      final disk = RejectingStorage()..reject = true;
      final store = HipStore(content: content, storage: disk);
      addTearDown(store.dispose);
      await expectLater(
        store.writeCoachCustomRoutine(routine(), update: false),
        throwsStateError,
      );
      expect(store.customRoutines, isEmpty);
      disk.reject = false;
      expect(
        (await store.writeCoachCustomRoutine(routine(), update: false)).status,
        CoachRoutineWriteStatus.saved,
      );
    },
  );

  test(
    'ordinary edits cannot replace a complete coach plan with preview steps',
    () async {
      final disk = MemoryStorage();
      final store = HipStore(content: content, storage: disk);
      addTearDown(store.dispose);
      await store.writeCoachCustomRoutine(routine(), update: false);
      final original = store.customRoutines.single;
      final originalBytes = disk.values[HipStore.storageKey];
      final revision = HipStore.customRoutineRevision(original);
      await expectLater(
        store.saveCustomRoutine(
          original.copyWith(
            steps: [...original.steps, const CustomStep('s-pigeon')],
          ),
        ),
        throwsStateError,
      );
      await expectLater(
        store.saveCustomRoutine(
          CustomRoutine(
            id: original.id,
            name: original.name,
            steps: original.steps,
          ),
        ),
        throwsStateError,
      );
      expect(disk.values[HipStore.storageKey], originalBytes);
      expect(store.customRoutine(original.id)!.coachPlan, plan.toJson());

      final ordinary = await store.saveCustomRoutine(
        const CustomRoutine(
          id: 'ordinary',
          name: '普通训练组',
          steps: [CustomStep('s-pigeon')],
        ),
      );
      await store.saveCustomRoutine(
        ordinary.copyWith(
          steps: [...ordinary.steps, const CustomStep('s-butterfly')],
        ),
      );
      expect(store.customRoutine('ordinary')!.steps, hasLength(2));
      expect(
        (await store.writeCoachCustomRoutine(
          routine(name: 'SDK正常更新'),
          update: true,
          expectedStorageRevision: revision,
        )).status,
        CoachRoutineWriteStatus.saved,
      );
      expect(store.customRoutine(original.id)!.coachPlan, plan.toJson());
      final restarted = HipStore(content: content, storage: disk);
      addTearDown(restarted.dispose);
      await restarted.initialize();
      expect(restarted.customRoutine(original.id)!.coachPlan, plan.toJson());
    },
  );

  test(
    'v2 legacy field projection preserves old bytes and saved identity',
    () async {
      final disk = MemoryStorage();
      final store = HipStore(content: content, storage: disk);
      addTearDown(store.dispose);
      await store.writeCoachCustomRoutine(routine(), update: false);
      final legacy = jsonEncode({
        'snapshot': envelope('old', '').session.toJson(),
        'saved': {'plan-message': 'old-saved'},
        'messages': [
          {
            'id': 'user-message',
            'at': at.toIso8601String(),
            'isUser': true,
            'text': '原来的原话',
          },
          {
            'id': 'plan-message',
            'at': at.toIso8601String(),
            'isUser': false,
            'plan': plan.toJson(),
            'actions': [
              {'actionId': 's-butterfly'},
            ],
          },
        ],
      });
      disk.values[HiplabCoachChatHistoryStore.legacyKey] = legacy;
      final history = HiplabCoachChatHistoryStore(store, storage: disk);
      final imported = (await history.loadLegacy('hiplab'))!;
      expect(imported.chat.first['role'], 'user');
      expect(imported.chat.first['text'], '原来的原话');
      expect(imported.chat.last['savedExternalId'], 'old-saved');
      expect(imported.chat.last['actionIds'], ['s-butterfly']);
      expect(imported.session!.isValid, isTrue);
      await history.write('hiplab', envelope('hiplab', '新对话'));
      expect((await history.load('hiplab'))!.messages.single['text'], '新对话');
      expect(await history.load('other'), isNull);
      expect(disk.values[HiplabCoachChatHistoryStore.legacyKey], legacy);
    },
  );

  test(
    'archives append independent payloads and retain existing snapshots',
    () async {
      final disk = MemoryStorage();
      final store = HipStore(content: content, storage: disk);
      addTearDown(store.dispose);
      final history = HiplabCoachChatHistoryStore(store, storage: disk);
      await Future.wait([
        history.archive(envelope('hiplab', '第一段')),
        history.archive(envelope('hiplab', '第二段')),
      ]);
      final keys =
          jsonDecode(disk.values[HiplabCoachChatHistoryStore.archiveIndexKey]!)
              as List;
      expect(keys, hasLength(2));
      expect(keys.toSet(), hasLength(2));
      expect(
        (jsonDecode(disk.values[keys.first]!) as Map)['messages'][0]['text'],
        '第一段',
      );
    },
  );

  test(
    'SDK imports legacy text history and restores the new envelope again',
    () async {
      final disk = MemoryStorage();
      disk.values[HiplabCoachChatPreferenceStore.legacyDisclaimerKey] =
          '{"disclaimerAccepted":true}';
      final store = HipStore(content: content, storage: disk);
      addTearDown(store.dispose);
      final legacy = jsonEncode({
        'snapshot': envelope('old', '').session.toJson(),
        'messages': [
          {
            'id': 'old-user',
            'at': at.toIso8601String(),
            'isUser': true,
            'text': '以前聊过髋部',
          },
          {
            'id': 'old-assistant',
            'at': at.toIso8601String(),
            'isUser': false,
            'text': '原回复保持',
          },
        ],
        'saved': <String, String>{},
      });
      disk.values[HiplabCoachChatHistoryStore.legacyKey] = legacy;
      final history = HiplabCoachChatHistoryStore(store, storage: disk);
      final preferences = HiplabCoachChatPreferenceStore(store, storage: disk);
      addTearDown(preferences.dispose);
      final builder = trainer.SessionBuilder(
        rhythms: {
          for (final kit in content.kits.values)
            kit.id: trainer.Rhythm.fromActionKitJson(kit.raw),
        },
        prepSeconds: 15,
      );
      CoachChatController createChat() => CoachChatController(
        profile: hiplabCoachAppProfile(
          catalog: catalog,
          coachProfile: hiplabCoachProfile,
          executionTiming: builder.executionTiming,
          content: content,
        ),
        catalog: catalog,
        clock: () => at,
        bindings: CoachChatBindings(
          storageNamespace: 'hiplab-test',
          gateway: CoachGatewayBinding.shared(coach.FakeLlmClient([])),
          plans: HiplabCoachPlanStore(store, catalog: catalog),
          history: history,
          preferences: preferences,
          actions: CoachChatHostActions(
            onStartTraining: (_, _) async => null,
            onOpenAction: (_, _) async {},
            onOpenLibrary: (_, _) async {},
            onOpenSavedPlans: (_) async {},
            onOpenCustomPlan: (_) async {},
            onOpenSettings: (_) async {},
          ),
        ),
      );
      final first = createChat();
      final started = await first.start();
      expect(started.ok, isTrue, reason: '${started.error}');
      expect(
        first.messages.map((message) => message.text),
        containsAllInOrder(['以前聊过髋部', '原回复保持']),
      );
      await first.close();
      expect(disk.values[HiplabCoachChatHistoryStore.legacyKey], legacy);
      final restarted = createChat();
      final restored = await restarted.start();
      expect(restored.ok, isTrue, reason: '${restored.error}');
      expect(
        restarted.messages.map((message) => message.text),
        containsAllInOrder(['以前聊过髋部', '原回复保持']),
      );
      await restarted.close();
    },
  );

  test(
    'preferences retain old acceptance, host safety and audio details',
    () async {
      final disk = MemoryStorage();
      disk.values[HiplabCoachChatPreferenceStore.legacyDisclaimerKey] =
          '{"disclaimerAccepted":true}';
      final store = HipStore(content: content, storage: disk);
      addTearDown(store.dispose);
      await store.setVoice(const VoiceSettings(volume: .4));
      final preferences = HiplabCoachChatPreferenceStore(store, storage: disk);
      addTearDown(preferences.dispose);
      expect((await preferences.load()).trainingAllowed, isTrue);
      await preferences.update(
        const CoachChatPreferences(
          safetyAccepted: true,
          appearance: 'dark',
          voice: false,
          chimes: false,
        ),
      );
      expect(store.theme, HipThemeChoice.dark);
      expect(store.voice.voice, isFalse);
      expect(store.voice.volume, .4);
      await store.setSafety({'existing-block': true});
      expect((await preferences.load()).trainingAllowed, isFalse);
      expect(store.safety, {'existing-block': true});
      expect(
        disk.values[HiplabCoachChatPreferenceStore.legacyDisclaimerKey],
        '{"disclaimerAccepted":true}',
      );
    },
  );
}
