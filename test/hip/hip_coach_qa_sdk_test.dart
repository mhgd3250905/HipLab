import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiplab/hip/coach/hip_coach_chat.dart';
import 'package:hiplab/hip/coach/hip_coach_chat_storage.dart';
import 'package:hiplab/hip/coach/hip_coach_profile.dart';
import 'package:hiplab/hip/control/hip_store.dart';
import 'package:hiplab/hip/data/hip_public_catalog.dart';
import 'package:hiplab/hip/domain/hip_models.dart';
import 'package:hiplab/hip/trainer/hip_sdk_session_builder.dart';
import 'package:ugk_coach/ugk_coach.dart' as coach;
import 'package:ugk_coach_chat/ugk_coach_chat.dart';
import 'package:ugk_coach_ui/ugk_coach_ui.dart';

import 'hip_domain_test.dart' show MemoryStorage, loadContent;

class _FileAssets extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async =>
      ByteData.sublistView(File(key).readAsBytesSync());
}

coach.LlmResponse _tool(String name, Map<String, Object?> arguments) =>
    coach.LlmResponse(
      content: '',
      toolCalls: [
        coach.LlmToolCall(
          id: 'fake-$name',
          name: name,
          arguments: jsonEncode(arguments),
        ),
      ],
    );

Map<String, Object?> _form({
  String intent = 'actions',
  String place = 'home',
  bool equipmentKnown = true,
  String status = 'none',
  String next = 'answer',
  List<String> equipment = const ['mat', 'chair'],
  List<int> positions = const [],
}) => {
  'language': 'zh',
  'intent': intent,
  'place': place,
  'answer_status': status,
  'equipment_known': equipmentKnown,
  'equipment': equipment,
  'next': next,
  'positions': positions,
  'stretch_muscles': ['adductors', 'hamstrings'],
  'types': ['static-stretch'],
};

coach.LlmResponse _recommend() => _tool('respond', {
  'text': '按你的条件推荐这几个。',
  'items': [
    {'id': 's-butterfly', 'why': '适合当前条件'},
    {'id': 's-seated-fold', 'why': '适合当前条件'},
  ],
  'chips': [],
});

// Synthetic real-model tool outputs from the accepted 2026-11-04 QA probe.
// Fixed here as offline fixtures; no external evidence file is read by tests.
final _acceptedForm =
    jsonDecode(
          r'''{"language": "zh", "intent": "plan", "answer_status": "none", "place": "home", "place_word": "家", "equipment_known": true, "equipment": [], "stretch_muscles": ["hip-flexors", "hip-rotators", "glute-max", "hip-abductors", "adductors"], "types": ["static-stretch"], "goals": ["mobility"], "minutes": 10, "next": "answer", "note": "用户这轮明确说了在家、只有徒手和墙（无器械），要 10 分钟髋部拉伸；地点和器械已知，直接出方案，不再追问。"}''',
        )
        as Map<String, Object?>;
final _acceptedBuild =
    jsonDecode(
          r'''{"title": "居家徒手开髋舒展", "text": "按你在家徒手、没有其他器械的条件，这套10分钟以动态开髋和大腿内侧舒展为主：先用相扑深蹲肘推膝打开髋部，再用哥萨克蹲练侧向活动度。动作放慢，在能舒服停住的位置停留，不要弹振；膝盖或髋部不舒服就缩小幅度。", "minutes": 10, "main_ids": ["h-sumo-pry", "adductors-A"], "chips": ["再温和一点", "改成睡前髋部放松", "看看动作要点"], "block_names": {"warmup": "髋部热身", "main": "开髋拉伸", "cooldown": "收操放松"}}''',
        )
        as Map<String, Object?>;

class _Host {
  _Host(this.store, this.host, this.client, this.disk);
  final HipStore store;
  final HipCoachChat host;
  final coach.FakeLlmClient client;
  final MemoryStorage disk;
  CoachChatController get chat => host.controller;
  Future<void> close() async {
    await host.close();
    store.dispose();
  }
}

Future<_Host> _host(
  HipContent content,
  List<Object> script, {
  MemoryStorage? storage,
}) async {
  final disk = storage ?? MemoryStorage();
  disk.values.putIfAbsent(
    HiplabCoachChatPreferenceStore.storageKey,
    () => jsonEncode({
      'safetyAccepted': true,
      'safetyBlocked': false,
      'safetyChecking': false,
    }),
  );
  final store = HipStore(content: content, storage: disk);
  await store.initialize();
  final client = coach.FakeLlmClient(
    script,
    model: 'deepseek-v4.1-flash',
    latency: Duration.zero,
  );
  final host = HipCoachChat(
    store: store,
    storage: disk,
    bundle: _FileAssets(),
    gateway: CoachGatewayBinding.shared(client),
    replyDelay: Duration.zero,
  );
  await host.load(
    builder: hipSdkSessionBuilder(content),
    actions: CoachChatHostActions(
      onStartTraining: (_, _) async => null,
      onOpenAction: (_, _) async {},
      onOpenLibrary: (_, _) async {},
      onOpenSavedPlans: (_) async {},
      onOpenCustomPlan: (_) async {},
      onOpenSettings: (_) async {},
    ),
  );
  return _Host(store, host, client, disk);
}

Future<void> _frames(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final pack = coach.PoseHubAppTestCatalog.fromBytes(
    File(hipPublicCatalogAsset).readAsBytesSync(),
    semanticCatalogBytes: File(hipPublicSemanticsAsset).readAsBytesSync(),
  );
  final rhythms = hipPublicRhythms(pack);
  final catalog = hipCoachCatalogFromPublic(pack, rhythms: rhythms);
  final content = loadContent().withPublicTraining(catalog, rhythms);

  test(
    'real App host opts into QA v2 with draft tags and unchanged admission',
    () async {
      final h = await _host(content, []);
      addTearDown(h.close);
      expect(h.chat.profile.agentMode, CoachChatAgentMode.qaV2);
      expect(h.chat.profile.aiTags, hasLength(209));
      expect(h.chat.profile.aiTags['h-squat']!['status'], 'ai-draft');
      expect(
        h.chat.profile.allowedActionIds,
        unorderedEquals(hiplabCoachAuthorizedActionIds),
      );
      expect(h.chat.profile.allowedActionIds, hasLength(211));
      expect(h.chat.qaAgent.index['h-squat']!.source, 'ai-tags');
      expect(h.chat.qaAgent.index['h-sleeper-stretch']!.source, 'catalog');
      expect(h.chat.qaAgent.index['not-in-hiplab'], isNull);
      expect(h.chat.bindings.plans, isA<HiplabCoachPlanStore>());
      expect(h.chat.bindings.history, isA<HiplabCoachChatHistoryStore>());
      expect(h.client.requests, isEmpty);
      expect(identical(h.host.controller, h.chat), isTrue);
      final snapshot = jsonEncode(h.chat.exportSnapshot().toJson());
      expect(snapshot, isNot(contains('textSha256Lf')));
    },
  );

  testWidgets(
    'App-hosted SDK page sends single choice immediately and multi only on confirm',
    (tester) async {
      final h = await _host(content, [
        _tool(
          'fill_form',
          _form(place: 'unknown', equipmentKnown: false, next: 'ask_place'),
        ),
        _tool('ask_user', {
          'question': '在哪练？',
          'options': ['居家', '健身房', '办公室', '直接推荐'],
        }),
        _tool(
          'fill_form',
          _form(
            intent: 'answer_pending',
            status: 'answered',
            equipmentKnown: false,
            next: 'ask_equipment',
          ),
        ),
        _tool('ask_user', {
          'question': '哪些器械？',
          'options': ['瑜伽垫', '椅子', '哑铃', '弹力带', '徒手', '直接推荐'],
        }),
        _tool('fill_form', _form(intent: 'answer_pending', status: 'answered')),
        _recommend(),
      ]);
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox());
        final closing = h.close();
        await _frames(tester);
        await closing;
      });
      await tester.binding.setSurfaceSize(const Size(430, 932));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final scroll = ScrollController();
      addTearDown(scroll.dispose);
      expect((await h.chat.send('想练几个拉伸动作'))!.status, coach.TurnStatus.ok);
      final place = h.chat.messages.last;
      expect(place.question!.multiple, isFalse);
      await tester.pumpWidget(
        MaterialApp(
          home: CoachChatPage(
            controller: h.chat,
            showBackButton: true,
            scrollController: scroll,
          ),
        ),
      );
      await _frames(tester);
      expect(find.byKey(const ValueKey('chat-back-button')), findsOneWidget);
      final placeChoice = find.byKey(ValueKey('question-option-${place.id}-0'));
      await tester.ensureVisible(placeChoice);
      await tester.tap(placeChoice);
      await _frames(tester);
      expect(h.client.requests, hasLength(4));
      expect(h.chat.messages.where((m) => m.isUser).last.text, '居家');
      expect(h.chat.canAnswerQuestion(place), isFalse);
      final equipment = h.chat.messages.last;
      expect(equipment.question!.multiple, isTrue);
      final mat = find.byKey(ValueKey('question-option-${equipment.id}-0'));
      await tester.ensureVisible(mat);
      await tester.tap(mat);
      await tester.pump();
      final chair = find.byKey(ValueKey('question-option-${equipment.id}-1'));
      await tester.tap(chair);
      await tester.pump();
      expect(
        h.client.requests,
        hasLength(4),
        reason: 'Selection is not submission',
      );
      final submit = find.byKey(ValueKey('question-submit-${equipment.id}'));
      await tester.ensureVisible(submit);
      await _frames(tester);
      if (scroll.hasClients) {
        scroll.jumpTo(scroll.position.maxScrollExtent);
      }
      await _frames(tester);
      await tester.tap(submit);
      await _frames(tester);
      expect(
        h.chat.error,
        isNull,
        reason: h.client.requests
            .map((r) => '${r.tools.first.name}: ${r.messages.last.content}')
            .join('\n'),
      );
      expect(h.client.requests, hasLength(6));
      expect(h.chat.messages.where((m) => m.isUser).last.text, '瑜伽垫、椅子');
      expect(h.client.requests[4].messages.last.content, contains('瑜伽垫、椅子'));
      expect(h.chat.lastQaReply!.cards.map((c) => c.id), [
        's-butterfly',
        's-seated-fold',
      ]);
      expect(h.chat.messages.last.qaV2, isTrue);
      final recommend = tester.widget<CoachRecommendCard>(
        find.byType(CoachRecommendCard).last,
      );
      expect(recommend.showNumbers, isTrue);
      expect(recommend.actionIds, ['s-butterfly', 's-seated-fold']);
      expect(find.byKey(const ValueKey('recommend-number-1')), findsOneWidget);
      expect(find.byKey(const ValueKey('recommend-number-2')), findsOneWidget);
      final before = h.client.requests.length;
      expect(await h.chat.answerChoices(equipment, ['徒手']), isNull);
      expect(h.client.requests, hasLength(before));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  test(
    'QA plan uses the App plan writer, persists and restores without a model call',
    () async {
      final h = await _host(content, [
        _tool('fill_form', _acceptedForm),
        _tool('build_plan', _acceptedBuild),
      ]);
      addTearDown(h.close);
      final result = await h.chat.send('在家徒手做10分钟髋部拉伸');
      expect(result?.status, coach.TurnStatus.ok, reason: '${result?.error}');
      final row = h.chat.messages.lastWhere((m) => m.plan != null);
      expect(row.qaV2, isTrue);
      expect(row.validatedPlan, isNotNull);
      expect(row.plan!.source, 'ai');
      expect(
        h.chat.lastQaReply!.planOrderedIds,
        row.plan!.items.map((i) => i.exerciseId),
      );
      final saved = await h.chat.savePlanCard(row);
      expect(h.store.customRoutines, hasLength(1));
      expect(h.store.customRoutines.single.coachPlan, saved.plan.toJson());
      expect(saved.plan.toJson(), row.plan!.toJson());
      final exactJson = saved.plan.toJson();
      await h.host.close();
      final restored = await _host(content, [
        _tool('fill_form', {
          ..._acceptedForm,
          'intent': 'swap',
          'positions': [3],
        }),
        _tool('swap', {'text': '保留这几个动作。', 'changes': [], 'chips': []}),
      ], storage: h.disk);
      addTearDown(restored.close);
      expect(restored.store.customRoutines.single.coachPlan, exactJson);
      expect(restored.chat.savedPlans.single.plan.toJson(), exactJson);
      expect(restored.chat.qaAgent.state.lastPlan!.plan.toJson(), exactJson);
      expect(
        restored.chat.messages.lastWhere((m) => m.plan != null).plan!.toJson(),
        exactJson,
      );
      expect(restored.client.requests, isEmpty);
      final ids = saved.plan.items.map((i) => i.exerciseId).toList();
      expect(saved.plan.blocks.map((b) => b.type), [
        coach.BlockType.warmup,
        coach.BlockType.main,
      ]);
      expect(
        (await restored.chat.sendPlanToConversation(
          restored.chat.savedPlans.single,
        )).ok,
        isTrue,
      );
      final swap = await restored.chat.send('换第3个');
      expect(swap?.status, coach.TurnStatus.ok, reason: '${swap?.error}');
      expect(
        restored.client.requests.last.messages.last.content,
        contains('第 3 个（main）'),
      );
      expect(restored.chat.lastQaReply!.planOrderedIds, ids);
      expect(restored.store.customRoutines, hasLength(1));

      final bad = const coach.PlanCodec().decodeStrict({
        ...saved.plan.toJson(),
        'blocks': [
          coach.PlanBlock(
            id: 'bad',
            name: 'bad',
            type: coach.BlockType.main,
            items: [
              const coach.PlanItem(
                exerciseId: 'not-in-hiplab',
                mode: coach.DoseMode.time,
                workSeconds: 30,
                sets: 1,
                restSeconds: 0,
                perSide: false,
              ),
            ],
          ).toJson(),
        ],
      }).plan!;
      await expectLater(
        restored.chat.save(bad),
        throwsA(isA<CoachPlanStorageException>()),
      );
      expect(restored.store.customRoutines, hasLength(1));
      expect(restored.store.customRoutines.single.coachPlan, exactJson);
    },
  );
}
