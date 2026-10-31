import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiplab/hip/coach/coach_config.dart';
import 'package:hiplab/hip/coach/coach_service.dart';
import 'package:hiplab/hip/coach/plan_mapping.dart';
import 'package:hiplab/hip/coach/usage_store.dart';
import 'package:hiplab/hip/control/hip_store.dart';
import 'package:hiplab/hip/domain/hip_library.dart';
import 'package:hiplab/hip/domain/hip_models.dart';
import 'package:hiplab/hip/ui/coach/ai_coach_page.dart';
import 'package:hiplab/hip/ui/coach/coach_history.dart';
import 'package:ugk_coach/ugk_coach.dart' as uc;

import 'hip_ai_coach_test.dart'
    show
        CoachFakeClient,
        readAsset,
        validPlanEnvelope,
        parsePlan,
        coachV2EditScript;
import 'hip_domain_test.dart' show MemoryStorage, loadContent;

class FaultyStorage extends MemoryStorage {
  bool failRead = false;
  bool failWrite = false;

  @override
  Future<String?> read(String key) async {
    if (failRead) throw StateError('read failed');
    return super.read(key);
  }

  @override
  Future<void> write(String key, String value) async {
    if (failWrite) throw StateError('write failed');
    await super.write(key, value);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final content = loadContent();
  final sessions = <AiCoachSession>[];

  AiCoachSession session(MemoryStorage storage, CoachFakeClient fake) {
    final value = AiCoachSession(
      CoachService(
        content: content,
        config: const CoachConfig(appKey: 'test'),
        client: fake,
        usage: CoachUsageStore(),
        storage: MemoryStorage(),
        readAsset: readAsset,
        maxRequestRetries: 0,
      ),
      storage: storage,
    );
    sessions.add(value);
    return value;
  }

  tearDown(() {
    for (final value in sessions) {
      value.dispose();
    }
    sessions.clear();
  });

  test(
    'one save pairs complete SDK snapshot, per-card state and saved identity',
    () async {
      final storage = MemoryStorage();
      final first = session(storage, CoachFakeClient([validPlanEnvelope()]));
      await first.load();
      await first.send('在家开胯12分钟');
      final card = first.messages.lastWhere((m) => m.plan != null);
      first.markSaved(card.id, 'my-save');
      await first.flush();
      final persisted =
          jsonDecode(storage.values[AiCoachSession.storageKey]!) as Map;
      expect(
        persisted['snapshot'],
        first.conversation!.exportSession().toJson(),
      );
      expect(
        (persisted['messages'] as List).last['planState'],
        card.planState!.toJson(),
      );
      expect(persisted['saved'], {card.id: 'my-save'});

      final freshClient = CoachFakeClient([]);
      final restored = session(storage, freshClient);
      await restored.load();
      final recovered = restored.messages.lastWhere((m) => m.plan != null);
      expect(recovered.plan!.plan.toJson(), card.plan!.plan.toJson());
      expect(recovered.planState!.toJson(), card.planState!.toJson());
      expect(recovered.plan!.version, card.plan!.version);
      expect(restored.saved, {card.id: 'my-save'});
      expect(
        restored.conversation!.exportSession().sessionState.toJson(),
        first.conversation!.exportSession().sessionState.toJson(),
      );
      expect(freshClient.requests, isEmpty);
    },
  );

  test(
    'full snapshot restores recommendations without replaying old tools',
    () async {
      final storage = MemoryStorage();
      final first = session(storage, CoachFakeClient([]));
      await first.load();
      final actions = first.service.gate.check('', [
        uc.LlmToolCall(
          id: 'recommend',
          name: 'show_actions',
          arguments: jsonEncode({
            'items': [
              {'actionId': 's-butterfly'},
              {'actionId': 's-figure4'},
            ],
          }),
        ),
      ]).actions!;
      first.restoreHistory([
        uc.CoachConversationMessage(
          id: 'recommend',
          at: DateTime(2026, 10, 31),
          text: '拉伸内侧',
          actions: actions,
        ),
      ]);
      await first.flush();
      final fake = CoachFakeClient([]);
      final restored = session(storage, fake);
      await restored.load();
      expect(restored.messages.single.actions!.items.map((a) => a.id), [
        's-butterfly',
        's-figure4',
      ]);
      expect(restored.messages.single.text, '拉伸内侧');
      expect(fake.requests, isEmpty);
    },
  );

  test(
    'reopening a complete snapshot leaves the old unanswered question closed',
    () async {
      final storage = MemoryStorage();
      final first = session(
        storage,
        CoachFakeClient([
          {
            'kind': 'ask',
            'text': '在哪里练？',
            'options': ['在家', '办公室'],
          },
        ]),
      );
      await first.load();
      await first.send('想活动一下');
      final question = first.conversation!.state.pendingQuestion!;
      expect(first.conversation!.canAnswer(question.id), isTrue);
      await first.flush();
      final fake = CoachFakeClient([]);
      final restored = session(storage, fake);
      await restored.load();
      expect(restored.conversation!.state.pendingQuestion, isNull);
      expect(restored.conversation!.canAnswer(question.id), isFalse);
      expect(
        restored.messages
            .singleWhere((m) => m.id == question.id)
            .questionAnswered,
        isTrue,
      );
      expect(fake.requests, isEmpty);
    },
  );

  test(
    'legacy restoreHistory restores plan conditions and never revives a question',
    () async {
      final storage = MemoryStorage();
      final source = session(
        MemoryStorage(),
        CoachFakeClient([validPlanEnvelope()]),
      );
      await source.load();
      await source.send('在家开胯12分钟');
      final question = uc.AskUserGate.check(
        jsonEncode({
          'question': '在哪里练？',
          'mode': 'choice',
          'options': ['在家', '办公室'],
        }),
      ).question!;
      storage.values[AiCoachSession.storageKey] = jsonEncode({
        'messages': [
          for (final message in source.messages) coachMessageJson(message),
          coachMessageJson(
            uc.CoachConversationMessage(
              id: 'old-question',
              at: DateTime(2026, 10, 30),
              question: question,
            ),
          ),
        ],
      });
      final restored = session(storage, CoachFakeClient([]));
      await restored.load();
      expect(restored.conversation!.state.pendingQuestion, isNull);
      expect(restored.messages.last.questionAnswered, isTrue);
      expect(
        restored.conversation!.exportSession().sessionState.activePlanId,
        source.messages.last.plan!.plan.id,
      );
    },
  );

  test(
    'invalid snapshot delegates fallback to SDK with its matching per-card planState',
    () async {
      final storage = MemoryStorage();
      final first = session(storage, CoachFakeClient([validPlanEnvelope()]));
      await first.load();
      await first.send('在家开胯12分钟');
      await first.flush();
      final raw = jsonDecode(storage.values[AiCoachSession.storageKey]!) as Map;
      raw['snapshot'] = {'schemaVersion': 999};
      storage.values[AiCoachSession.storageKey] = jsonEncode(raw);
      final restored = session(storage, CoachFakeClient([]));
      await restored.load();
      expect(
        restored.messages.last.plan!.plan.toJson(),
        first.messages.last.plan!.plan.toJson(),
      );
      expect(
        restored.conversation!.exportSession().sessionState.activePlanId,
        first.messages.last.plan!.plan.id,
      );
    },
  );

  test(
    'external saved plan focus and savedRef survive a new App session',
    () async {
      final storage = MemoryStorage();
      final first = session(storage, CoachFakeClient([]));
      final store = HipStore(content: content, storage: MemoryStorage());
      final plan = parsePlan(validPlanEnvelope());
      final group = await store.saveCustomRoutine(
        CoachPlanMapper(
          content,
        ).map(plan, id: 'my-plan', at: DateTime(2026, 10, 31)).routine,
        coachPlan: plan.toJson(),
      );
      expect((await first.focusRoutine(group, store))!.ok, isTrue);
      final restored = session(storage, CoachFakeClient([]));
      await restored.load();
      expect(restored.conversation!.focus!.planId, 'ext:my-plan');
      expect(restored.conversation!.focus!.savedRef.externalId, 'my-plan');
      expect(restored.conversation!.focus!.savedRef.baseVersion, 1);
    },
  );

  test(
    'SDK plan data and occurrence order survive storage without library clamping',
    () async {
      final storage = MemoryStorage();
      final store = HipStore(content: content, storage: storage);
      final plan = parsePlan(validPlanEnvelope());
      final routine = CoachPlanMapper(content)
          .map(
            plan.copyWith(
              blocks: [
                uc.PlanBlock(
                  id: plan.blocks[1].id,
                  name: plan.blocks[1].name,
                  type: plan.blocks[1].type,
                  rounds: 8,
                  items: plan.blocks[1].items,
                ),
              ],
            ),
            id: 'long-sdk-plan',
            at: DateTime(2026, 10, 31),
          )
          .routine;
      final saved = await store.saveCustomRoutine(
        routine,
        coachPlan: routine.coachPlan,
      );
      expect(saved.steps, hasLength(24));
      final restored = HipStore(content: content, storage: storage);
      await restored.initialize();
      final group = restored.customRoutines.single;
      expect(
        group.steps.map((s) => s.toJson()),
        saved.steps.map((s) => s.toJson()),
      );
      expect(group.coachPlan, routine.coachPlan);
      expect(restored.coachPlanJson[group.id], jsonEncode(routine.coachPlan));
      await restored.saveCustomRoutine(group.copyWith(name: '手动改名'));
      expect(restored.coachPlanJson, isEmpty);
    },
  );

  test(
    'legacy chair scene is mapped to the SDK office scene at the boundary',
    () async {
      final first = session(MemoryStorage(), CoachFakeClient([]));
      final store = HipStore(content: content, storage: MemoryStorage())
        ..scene = HipScene.chair;
      final routine = CustomRoutine(
        id: 'chair-plan',
        name: '办公练习',
        steps: const [
          CustomStep('o-seated-fig4'),
          CustomStep('n-seated-knee-lift'),
        ],
      );
      await first.load();
      final plan = CoachPlanMapper(
        content,
      ).toSdkPlan(routine, first.service.catalog, scene: 'office');
      expect(plan.scene, 'office');
      final result = await first.focusRoutine(routine, store);
      expect(
        result!.errors.map((e) => e.code),
        isNot(contains('sceneUnsupported')),
      );
    },
  );

  test(
    'a real SDK edit restores version 2 with its original save base and version 1 intact',
    () async {
      final storage = MemoryStorage();
      final original = parsePlan(validPlanEnvelope());
      final first = session(
        storage,
        CoachFakeClient(coachV2EditScript(original, 'saved-1')),
      );
      final store = HipStore(content: content, storage: MemoryStorage());
      final group = await store.saveCustomRoutine(
        CoachPlanMapper(
          content,
        ).map(original, id: 'saved-1', at: DateTime(2026, 10, 31)).routine,
        coachPlan: original.toJson(),
      );
      expect((await first.focusRoutine(group, store))!.ok, isTrue);
      await first.send('缩短到5分钟');
      final edited = first.messages.lastWhere((m) => m.plan != null);
      expect(edited.plan!.version, 2);
      expect(edited.plan!.savedRef!.baseVersion, 1);
      await first.flush();
      final restored = session(storage, CoachFakeClient([]));
      await restored.load();
      final card = restored.messages.lastWhere((m) => m.plan != null);
      expect(card.plan!.version, 2);
      expect(card.plan!.savedRef!.externalId, group.id);
      expect(card.plan!.savedRef!.baseVersion, 1);
      expect(card.planState!.toJson(), edited.planState!.toJson());
      expect(
        restored.conversation!
            .exportSession()
            .sessionState
            .plans['ext:${group.id}'],
        hasLength(2),
      );
    },
  );

  test(
    'a new conversation chosen during loading cannot revive stored history or queue input',
    () async {
      final asset = Completer<String>();
      final fake = CoachFakeClient([]);
      final storage = MemoryStorage();
      storage.values[AiCoachSession.storageKey] = jsonEncode({
        'messages': [
          coachMessageJson(
            uc.CoachConversationMessage(
              id: 'old-user',
              at: DateTime(2026, 10, 30),
              isUser: true,
              text: '旧对话',
            ),
          ),
        ],
      });
      final value = AiCoachSession(
        CoachService(
          content: content,
          config: const CoachConfig(appKey: 'test'),
          client: fake,
          usage: CoachUsageStore(),
          storage: MemoryStorage(),
          readAsset: (path) => path == CoachService.catalogAsset
              ? asset.future
              : readAsset(path),
        ),
        storage: storage,
      );
      sessions.add(value);
      final loading = value.load();
      await value.send('不应排队的请求');
      value.reset();
      asset.complete(await readAsset(CoachService.catalogAsset));
      await loading;
      await value.flush();
      expect(value.loaded, isTrue);
      expect(value.messages, isEmpty);
      expect(fake.requests, isEmpty);
      expect(
        (jsonDecode(storage.values[AiCoachSession.storageKey]!)
            as Map)['messages'],
        isEmpty,
      );
    },
  );

  test('background checkpoint saves the latest SDK state atomically', () async {
    final storage = MemoryStorage();
    final first = session(
      storage,
      CoachFakeClient([
        {'kind': 'reply', 'text': '随时可以开始。'},
      ]),
    );
    await first.load();
    await first.send('你好');
    first.didChangeAppLifecycleState(AppLifecycleState.paused);
    await first.flush();
    final raw = jsonDecode(storage.values[AiCoachSession.storageKey]!) as Map;
    expect(raw['snapshot'], first.conversation!.exportSession().toJson());
    expect((raw['messages'] as List).last['text'], first.messages.last.text);
  });

  test(
    'a failed history read does not strand the conversation in loading',
    () async {
      final storage = FaultyStorage()..failRead = true;
      final first = session(
        storage,
        CoachFakeClient([
          {'kind': 'reply', 'text': '可以继续'},
        ]),
      );
      await first.load();
      expect(first.loaded, isTrue);
      expect(first.persistenceFailed, isTrue);
      storage.failRead = false;
      await first.send('你好');
      expect(first.messages.last.text, '可以继续');
      expect(first.persistenceFailed, isFalse);
    },
  );

  test(
    'a failed write preserves admitted output and a later checkpoint can retry',
    () async {
      final storage = FaultyStorage()..failWrite = true;
      final first = session(storage, CoachFakeClient([validPlanEnvelope()]));
      await first.load();
      await first.send('在家开胯12分钟');
      expect(first.messages.last.plan, isNotNull);
      expect(first.persistenceFailed, isTrue);
      storage.failWrite = false;
      first.didChangeAppLifecycleState(AppLifecycleState.paused);
      await first.flush();
      expect(first.persistenceFailed, isFalse);
      final persisted =
          jsonDecode(storage.values[AiCoachSession.storageKey]!) as Map;
      expect(
        (persisted['messages'] as List).last['plan'],
        first.messages.last.plan!.plan.toJson(),
      );
    },
  );
}
