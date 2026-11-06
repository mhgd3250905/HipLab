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

List<String> _candidates(coach.LlmRequest request) => RegExp(
  r'^([A-Za-z0-9_-]+) \| ',
  multiLine: true,
).allMatches(request.messages.last.content).map((m) => m[1]!).toList();

coach.LlmResponse _search() => _tool('search_actions', {
  'muscles': ['adductors', 'hamstrings'],
  'types': ['static-stretch'],
});

final _picked = <String>[];

coach.LlmResponse _recommend(coach.LlmRequest request) {
  _picked
    ..clear()
    ..addAll(_candidates(request).take(3));
  return _tool('show_actions', {
    'text': '按你的条件推荐这几个。',
    'items': [
      for (final id in _picked) {'id': id, 'why': '适合当前条件'},
    ],
    'chips': [],
  });
}

// Plan fixture: home, bodyweight, 10-minute hip stretch (from the accepted
// 2026-11-04 QA probe), replayed through the v3 tools offline.
final _acceptedConditions = <String, Object?>{
  'language': 'zh',
  'place': 'home',
  'place_word': '家',
  'equipment_known': true,
  'equipment': <String>[],
  'minutes': 10,
};
final _planSearch = <String, Object?>{
  'muscles': [
    'hip-flexors',
    'hip-rotators',
    'glute-max',
    'hip-abductors',
    'adductors',
  ],
  'types': ['static-stretch'],
};
final _planMain = <String>[];

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
      // r2-v1: all 209 authorized actions carry a draft tag.
      expect(h.chat.profile.aiTags, hasLength(209));
      expect(h.chat.profile.aiTags['h-squat']!['status'], 'ai-draft');
      expect(
        h.chat.profile.allowedActionIds,
        unorderedEquals(hiplabCoachAuthorizedActionIds),
      );
      expect(h.chat.profile.allowedActionIds, hasLength(209));
      expect(h.chat.qaAgent.index['h-squat']!.source, 'ai-tags');
      // h-sleeper-stretch (the former untagged catalog-source example) was
      // deleted before r2-v1; every remaining authorized action is tagged.
      expect(h.chat.qaAgent.index['n-leg-circles']!.source, 'ai-tags');
      expect(h.chat.qaAgent.index['h-sleeper-stretch'], isNull);
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
        _tool('ask_user', {
          'step': 'place',
          'question': '在哪练？',
          'options': ['居家', '健身房', '办公室', '直接推荐'],
        }),
        _tool('set_conditions', {'place': 'home', 'place_word': '居家'}),
        _tool('ask_user', {
          'step': 'equipment',
          'question': '哪些器械？',
          'options': ['瑜伽垫', '椅子', '哑铃', '弹力带', '徒手', '直接推荐'],
          'multi': true,
        }),
        _tool('set_conditions', {
          'equipment_known': true,
          'equipment': ['mat', 'chair'],
        }),
        _search(),
        _recommend,
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
      expect(h.client.requests, hasLength(3));
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
        hasLength(3),
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
      expect(h.client.requests[3].messages.last.content, contains('瑜伽垫、椅子'));
      expect(_picked, hasLength(3));
      expect(h.chat.lastQaReply!.cards.map((c) => c.id), _picked);
      expect(h.chat.messages.last.qaV2, isTrue);
      final recommend = tester.widget<CoachRecommendCard>(
        find.byType(CoachRecommendCard).last,
      );
      expect(recommend.showNumbers, isTrue);
      expect(recommend.actionIds, _picked);
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
        _tool('set_conditions', _acceptedConditions),
        _tool('search_actions', _planSearch),
        (coach.LlmRequest request) {
          _planMain
            ..clear()
            ..addAll(_candidates(request).take(4));
          return _tool('search_actions', {
            'roles': ['warmup'],
            'limit': 3,
          });
        },
        (coach.LlmRequest request) => _tool('build_plan', {
          'mode': 'new',
          'title': '居家徒手开髋舒展',
          'text': '按你在家徒手的条件，这套10分钟以开髋和大腿内侧舒展为主。动作放慢，在能舒服停住的位置停留，不要弹振。',
          'minutes': 10,
          'warmup_ids': _candidates(
            request,
          ).where((id) => !_planMain.contains(id)).take(1).toList(),
          'main_ids': _planMain,
          'chips': ['再温和一点', '看看动作要点'],
          'block_names': {'warmup': '髋部热身', 'main': '开髋拉伸', 'cooldown': '收操放松'},
        }),
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
        _tool('reply', {'text': '保留这几个动作。', 'items': [], 'chips': []}),
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
      expect(restored.client.requests, hasLength(1));
      expect(restored.chat.qaAgent.state.lastPlan!.orderedIds, ids);
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
