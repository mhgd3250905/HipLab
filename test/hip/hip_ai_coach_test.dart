// AI 定制 (docs/ai-coach.md): service scope, plan → custom group mapping,
// preset fallback and the page, all on the SDK's FakeLlmClient (no network).
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hiplab/hip/coach/coach_config.dart';
import 'package:hiplab/hip/coach/coach_service.dart';
import 'package:hiplab/hip/coach/plan_mapping.dart';
import 'package:hiplab/hip/coach/usage_store.dart';
import 'package:hiplab/hip/control/hip_store.dart';
import 'package:hiplab/hip/domain/hip_library.dart';
import 'package:hiplab/hip/domain/hip_models.dart';
import 'package:hiplab/hip/domain/hip_settings.dart';
import 'package:hiplab/hip/ui/coach/ai_coach_page.dart';
import 'package:hiplab/hip/ui/hip_app.dart';
import 'package:hiplab/hip/ui/hip_player_page.dart';
import 'package:ugk_coach/ugk_coach.dart' as uc;
import 'package:ugk_coach_ui/ugk_coach_ui.dart' as ui;

import 'hip_domain_test.dart' show MemoryStorage, loadContent;

/// Historical data fixtures are translated to the public Agent v2 protocol.
/// Doses, admission, plan identity and versions are produced by the real SDK.
/// This adapter is test-only; the App never converts model envelopes.
class CoachFakeClient extends uc.FakeLlmClient {
  CoachFakeClient(super.script);
  String? _draftId;
  String? _note;
  @override
  Future<uc.LlmResponse> complete(
    uc.LlmRequest request, {
    uc.CancelToken? cancel,
  }) async {
    if (_draftId case final draftId?) {
      _draftId = null;
      final receipt =
          jsonDecode(
                request.messages
                    .lastWhere((m) => m.toolCallId == draftId)
                    .content,
              )
              as Map;
      if (receipt['ok'] == true) {
        requests.add(request);
        return coachV2PlanShow(receipt['plan_id'] as String, _note ?? '');
      }
    }
    final response = await super.complete(request, cancel: cancel);
    Object? value;
    try {
      value = jsonDecode(response.content);
    } on FormatException {
      return response;
    }
    if (value is! Map || !value.containsKey('kind')) return response;
    final kind = value['kind'];
    final text = value['text'] as String? ?? '';
    if (kind == 'plan') {
      final prefix = 'fixture-${requests.length}';
      _draftId = '$prefix-draft';
      _note = text;
      return coachV2PlanStart(value, prefix: prefix);
    }
    return uc.LlmResponse(
      content: text,
      usage: response.usage,
      model: response.model,
      latency: response.latency,
      toolCalls: [
        if (kind == 'ask')
          uc.LlmToolCall(
            id: 'call-${requests.length}',
            name: 'ask_user',
            arguments: jsonEncode({
              'question': text,
              'mode': 'choice',
              'options': value['options'],
              'multiple': false,
            }),
          ),
      ],
    );
  }
}

uc.LlmResponse coachV2PlanStart(Map envelope, {String prefix = 'fixture'}) {
  final plan = envelope['plan'] as Map;
  final catalog = uc.Catalog.fromJson(
    jsonDecode(File(CoachService.catalogAsset).readAsStringSync()),
  );
  final blocks = plan['blocks'] as List;
  final ids = <String>{
    for (final block in blocks)
      for (final item in (block as Map)['items'] as List)
        (item as Map)['exerciseId'] as String,
  };
  uc.LlmToolCall call(String suffix, String name, Object arguments) =>
      uc.LlmToolCall(
        id: '$prefix-$suffix',
        name: name,
        arguments: jsonEncode(arguments),
      );
  return uc.LlmResponse(
    content: '',
    finishReason: 'tool_calls',
    toolCalls: [
      call('start', 'start_task', {'type': 'plan'}),
      call('params', 'set_params', {
        'fields': {
          'scene': {'value': plan['scene'] ?? 'home', 'source': 'default'},
          'minutes': {
            'value': plan['targetMinutes'] ?? 12,
            'source': 'default',
          },
          'goal': {
            'value': [
              switch (plan['goal']) {
                'relax' => 'purpose.stretch',
                'strength' => 'purpose.strength',
                _ => 'purpose.mobility',
              },
            ],
            'source': 'default',
          },
          'equipment': {'value': <String>[], 'source': 'default'},
        },
      }),
      for (final id in ids)
        call('search-$id', 'search_actions', {
          'tags': <String>[],
          'keywords': catalog[id]?.name.of('en') ?? id,
        }),
      call('draft', 'draft_plan', {
        'title': plan['title'],
        'blocks': [
          for (final block in blocks)
            {
              'kind': (block as Map)['type'],
              'items': [
                for (final item in block['items'] as List)
                  {'id': (item as Map)['exerciseId']},
              ],
            },
        ],
      }),
    ],
  );
}

uc.LlmResponse coachV2PlanShow(String planId, String note) => uc.LlmResponse(
  content: '',
  finishReason: 'tool_calls',
  toolCalls: [
    uc.LlmToolCall(
      id: 'fixture-show-$planId',
      name: 'show_plan',
      arguments: jsonEncode({'plan_id': planId, 'note': note}),
    ),
  ],
);

List<Object> coachV2EditScript(uc.TrainingPlan plan, String externalId) {
  uc.LlmToolCall call(String id, String name, Object args) =>
      uc.LlmToolCall(id: id, name: name, arguments: jsonEncode(args));
  uc.LlmResponse calls(List<uc.LlmToolCall> tools) =>
      uc.LlmResponse(content: '', toolCalls: tools, finishReason: 'tool_calls');
  var sourceIndex = 0;
  final blocks = [
    for (final block in plan.blocks)
      {
        'kind': block.type.name,
        'items': [
          for (final item in block.items)
            {'id': item.exerciseId, 'sourceIndex': ++sourceIndex},
        ],
      },
  ];
  return [
    calls([
      call('edit-start', 'start_task', {'type': 'plan', 'reuse': true}),
      call('edit-params', 'set_params', {
        'fields': {
          'operation': {'value': 'edit', 'source': 'user', 'quote': '缩短到5分钟'},
          'minutes': {'value': 5, 'source': 'user', 'quote': '5分钟'},
        },
      }),
    ]),
    calls([
      call('edit-draft', 'draft_plan', {
        'plan_id': 'ext:$externalId',
        'title': '五分钟髋部放松',
        'blocks': blocks,
      }),
    ]),
    (uc.LlmRequest request) {
      final receipt =
          jsonDecode(
                request.messages
                    .lastWhere((m) => m.toolCallId == 'edit-draft')
                    .content,
              )
              as Map;
      expect(receipt['ok'], isTrue, reason: '$receipt');
      expect(receipt['version'], 2);
      return calls([
        call('edit-planning', 'check', {'node': 'planning'}),
        call('edit-check', 'check_plan', {'plan_id': 'ext:$externalId'}),
      ]);
    },
    (uc.LlmRequest request) {
      final receipt =
          jsonDecode(
                request.messages
                    .lastWhere((m) => m.toolCallId == 'edit-check')
                    .content,
              )
              as Map;
      expect(receipt['ok'], isTrue, reason: '$receipt');
      return calls([
        call('edit-review', 'check', {'node': 'review'}),
        call('edit-show', 'show_plan', {
          'plan_id': 'ext:$externalId',
          'note': '已缩短为五分钟。',
        }),
      ]);
    },
  ];
}

final _now = DateTime(2026, 10, 20, 9, 30);

/// Assets read synchronously (async IO never completes in the fake clock).
Future<String> readAsset(String path) async => File(path).readAsStringSync();

Map<String, Object?> item(
  String id,
  String mode,
  int sets,
  int amount, {
  bool perSide = false,
  int rest = 15,
}) => {
  'exerciseId': id,
  'mode': mode,
  'sets': sets,
  if (mode == 'reps') 'reps': amount else 'workSeconds': amount,
  'perSide': perSide,
  'restSeconds': rest,
};

/// A valid hiplab plan: units and sides as in the catalog, all at home.
Map<String, Object?> validPlanEnvelope({String text = '按你说的排了睡前 12 分钟。'}) => {
  'kind': 'plan',
  'text': text,
  'plan': {
    'schemaVersion': 1,
    'title': '睡前开胯 12 分钟',
    'summary': '先活动髋关节，再做外旋和内收拉伸，最后抱膝放松。',
    'goal': 'relax',
    'scene': 'home',
    'equipment': ['mat', 'chair', 'wall', 'block'],
    'level': 1,
    'targetMinutes': 12,
    'blocks': [
      {
        'id': 'b1',
        'name': '热身',
        'type': 'warmup',
        'rounds': 1,
        'restBetweenRoundsSeconds': 0,
        'items': [
          item('n-windshield', 'reps', 1, 8, rest: 10),
          item('h-quad-cars', 'reps', 1, 5, perSide: true, rest: 10),
        ],
      },
      {
        'id': 'b2',
        'name': '开胯拉伸',
        'type': 'main',
        'rounds': 2,
        'restBetweenRoundsSeconds': 20,
        'items': [
          item('s-figure4', 'time', 1, 40, perSide: true, rest: 20),
          item('s-butterfly', 'time', 1, 40, rest: 20),
          item('w-clamshell', 'reps', 1, 12, perSide: true, rest: 20),
        ],
      },
      {
        'id': 'b3',
        'name': '放松',
        'type': 'cooldown',
        'rounds': 1,
        'restBetweenRoundsSeconds': 0,
        'items': [item('h-knee-hug', 'reps', 1, 6, rest: 0)],
      },
    ],
    'notes': [],
    'safetyNotes': ['拉伸停在有感觉但不痛的位置。'],
  },
};

uc.TrainingPlan parsePlan(Map<String, Object?> envelope) =>
    const uc.EnvelopeParser()
        .parse(jsonEncode(envelope), planId: 'p')
        .reply!
        .plan!;

void main() {
  final content = loadContent();

  CoachService service({
    CoachFakeClient? fake,
    CoachUsageStore? usage,
    MemoryStorage? storage,
  }) => CoachService(
    config: fake == null
        ? const CoachConfig()
        : const CoachConfig(appKey: 'test'),
    content: content,
    maxRequestRetries: 0,
    client: fake,
    usage: usage ?? CoachUsageStore(),
    storage: storage ?? MemoryStorage(),
    readAsset: readAsset,
  );

  group('SDK-owned coaching service', () {
    test('profile has exactly the 45 playable HipLab actions', () async {
      final coach = service(fake: CoachFakeClient([]));
      await coach.load();
      addTearDown(coach.dispose);
      final scope = coach.profile.scope(coach.catalog);
      expect(scope, hasLength(45));
      expect(coach.profile.select.apps, isEmpty);
      expect(
        coach.profile.select.ids,
        libraryDrills(content).map((d) => d.id).toSet(),
      );
      expect(scope.map((d) => d.id), isNot(contains('n-thomas-test')));
      expect(coach.conversation!.agent.extraRules, isEmpty);
      expect(coach.conversation!.agent.fallback, isNull);
      expect(coach.profile.planRules.toJson(), const uc.PlanRules().toJson());
    });

    test('SDK scope rejects an assessment demonstration', () async {
      final coach = service(fake: CoachFakeClient([]));
      await coach.load();
      addTearDown(coach.dispose);
      final original = parsePlan(validPlanEnvelope());
      final context = uc.CoachContext(
        scene: original.scene,
        equipment: original.equipment.toSet(),
      );
      expect(
        coach.gate.admitTemplate(original, context),
        isNotNull,
        reason: coach.validator.validate(original).issues.toString(),
      );
      final bad = validPlanEnvelope();
      (((bad['plan'] as Map)['blocks'] as List).last as Map)['items'] = [
        item('n-thomas-test', 'time', 1, 30, perSide: true),
      ];
      expect(coach.gate.admitTemplate(parsePlan(bad), context), isNull);
    });

    test(
      'model planning uses SDK tasks and the timer, with no App fallback',
      () async {
        final fake = CoachFakeClient([validPlanEnvelope()]);
        final coach = service(fake: fake);
        await coach.load();
        addTearDown(coach.dispose);
        final result = (await coach.conversation!.send(
          'hip mobility at home',
        ))!;
        expect(
          result.status,
          uc.TurnStatus.ok,
          reason:
              '${result.error}\n${fake.requests.last.messages.map((m) => m.toolCallId == null ? '' : '${m.toolCallId}: ${m.content}').join('\n')}',
        );
        expect(result.plan, isNotNull);
        expect(result.plan!.version, 1);
        expect(fake.requests, hasLength(2));
        expect(coach.conversation!.exportSession().toJson(), isNotEmpty);
      },
    );

    test(
      'offline model returns an error without an automatic preset',
      () async {
        final fake = CoachFakeClient([
          const uc.LlmException(uc.LlmErrorKind.network, 'offline'),
        ]);
        final coach = service(fake: fake);
        await coach.load();
        addTearDown(coach.dispose);
        final result = (await coach.conversation!.send(
          'hip mobility at home',
        ))!;
        expect(result.status, uc.TurnStatus.error);
        expect(result.plan, isNull);
        expect(coach.conversation!.state.admittedPlans, isEmpty);
        expect(fake.requests, hasLength(1));
      },
    );

    test('disposing during asset load creates no late controller', () async {
      final asset = Completer<String>();
      final fake = CoachFakeClient([]);
      final coach = CoachService(
        config: const CoachConfig(appKey: 'test'),
        content: content,
        client: fake,
        usage: CoachUsageStore(),
        storage: MemoryStorage(),
        readAsset: (path) =>
            path == CoachService.catalogAsset ? asset.future : readAsset(path),
      );
      final loading = coach.load();
      await coach.dispose();
      asset.complete(File(CoachService.catalogAsset).readAsStringSync());
      await loading;
      expect(coach.conversation, isNull);
      expect(fake.requests, isEmpty);
    });
  });

  group('AI 定制页', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    Future<HipStore> pumpApp(
      WidgetTester tester,
      CoachService coach, {
      bool dark = false,
    }) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final store = HipStore(content: content, storage: MemoryStorage());
      store
        ..safety = {'pregnancy': false, 'surgery': false, 'acute': false}
        ..identity = HipIdentity.office
        ..theme = dark ? HipThemeChoice.dark : HipThemeChoice.light;
      await tester.pumpWidget(
        HipApp(store: store, videoEnabled: false, coach: coach),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('tab-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('practice-2')));
      await tester.pumpAndSettle();
      return store;
    }

    Future<void> tapIn(WidgetTester tester, Finder finder, String list) async {
      await tester.scrollUntilVisible(
        finder,
        150,
        scrollable: find
            .descendant(
              of: find.byKey(ValueKey(list)),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.pumpAndSettle();
      await tester.tap(finder);
      await tester.pumpAndSettle();
    }

    Future<void> openCoach(WidgetTester tester) async {
      await tapIn(
        tester,
        find.byKey(const ValueKey('practice-ai-coach')),
        'practice-list',
      );
      final accept = find.byKey(const ValueKey('coach-disclaimer-ok'));
      if (accept.evaluate().isNotEmpty) {
        await tester.tap(accept);
        await tester.pumpAndSettle();
      }
    }

    Future<void> say(WidgetTester tester, String text) async {
      await tester.enterText(find.byKey(const ValueKey('coach-input')), text);
      await tester.tap(find.byKey(const ValueKey('coach-send')));
      await tester.pumpAndSettle();
    }

    Future<void> expand(WidgetTester tester) async {
      await tapIn(
        tester,
        find.byKey(const ValueKey('plan-expanded-header')).last,
        'coach-list',
      );
    }

    testWidgets(
      'SDK plan card saves the full plan and enters the existing player',
      (tester) async {
        final fake = CoachFakeClient([validPlanEnvelope()]);
        final coach = service(fake: fake);
        final store = await pumpApp(tester, coach);
        await openCoach(tester);
        await say(tester, '睡前12分钟开胯');
        expect(fake.requests, hasLength(2));
        final admitted = coach.conversation!.state.admittedPlans.single;
        final card = tester.widget<ui.CoachPlanExpanded>(
          find.byType(ui.CoachPlanExpanded),
        );
        expect(card.plan.id, admitted.plan.id);
        expect(
          card.plan.items.map((i) => i.exerciseId),
          admitted.plan.items.map((i) => i.exerciseId),
        );
        expect(card.expanded, isFalse);
        await expand(tester);
        await tapIn(
          tester,
          find.byKey(const ValueKey('coach-save')),
          'coach-list',
        );
        expect(store.customRoutines, hasLength(1));
        final group = store.customRoutines.single;
        expect(
          jsonDecode(store.coachPlanJson[group.id]!),
          admitted.plan.toJson(),
        );
        await tapIn(
          tester,
          find.byKey(const ValueKey('coach-start')),
          'coach-list',
        );
        final player = tester.widget<HipPlayerPage>(find.byType(HipPlayerPage));
        expect(player.plan.source, PlanSource.custom);
        expect(
          player.plan.steps.first.drill.id,
          admitted.plan.items.first.exerciseId,
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'recommendations use SDK card and send the SDK follow-up text',
      (tester) async {
        final fake = CoachFakeClient([
          {'kind': 'reply', 'text': '收到'},
        ]);
        final coach = service(fake: fake);
        await pumpApp(tester, coach);
        await openCoach(tester);
        final actions = coach.gate.check('', [
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
        coach.conversation!.restoreHistory([
          uc.CoachConversationMessage(
            id: 'recommend-card',
            at: _now,
            text: '内侧拉伸动作',
            actions: actions,
          ),
        ]);
        await tester.pumpAndSettle();
        final card = tester.widget<ui.CoachRecommendCard>(
          find.byType(ui.CoachRecommendCard),
        );
        expect(card.actionIds, ['s-butterfly', 's-figure4']);
        expect(find.text('内侧拉伸动作'), findsOneWidget);
        await tapIn(
          tester,
          find.byKey(const ValueKey('recommend-plan-button')),
          'coach-list',
        );
        expect(
          coach.conversation!.state.messages.where((m) => m.isUser).last.text,
          '请把刚才推荐的动作排成计划。',
        );
      },
    );

    testWidgets(
      'failure shows explicit retry and offers no unverified preset',
      (tester) async {
        final fake = CoachFakeClient([
          const uc.LlmException(uc.LlmErrorKind.network, 'offline'),
          {'kind': 'reply', 'text': '可以继续了'},
        ]);
        final coach = service(fake: fake);
        await pumpApp(tester, coach);
        await openCoach(tester);
        await say(tester, '在家开胯');
        expect(find.byType(ui.CoachFailureBubble), findsOneWidget);
        expect(
          find.byKey(const ValueKey('coach-failure-secondary')),
          findsNothing,
        );
        expect(find.byType(ui.CoachPlanExpanded), findsNothing);
        await tapIn(
          tester,
          find.byKey(const ValueKey('coach-failure-retry')),
          'coach-list',
        );
        expect(
          coach.conversation!.state.messages.where((m) => m.isUser).last.text,
          '重试',
        );
        expect(fake.requests, hasLength(2));
      },
    );

    testWidgets(
      'SDK confirmation fields map without App defaults or revived history',
      (tester) async {
        final coach = service(fake: CoachFakeClient([]));
        await pumpApp(tester, coach);
        await openCoach(tester);
        final question = uc.AskUserQuestion.confirmation(
          question: '确认练习条件',
          focus: '髋部',
          fields: [
            uc.AskUserField(
              key: 'scene',
              label: '场地',
              options: ['在家', '办公室'],
              preselected: ['在家'],
              previousSelections: ['在家'],
            ),
            uc.AskUserField(
              key: 'equipment',
              label: '器械',
              options: ['徒手', '椅子'],
              multiple: true,
              preselected: ['椅子'],
              optionsByScene: {
                '在家': ['徒手', '椅子'],
                '办公室': ['椅子'],
              },
            ),
            uc.AskUserField(
              key: 'minutes',
              label: '时长',
              options: ['5分钟', '10分钟'],
              preselected: ['10分钟'],
            ),
          ],
          defaultSelections: {
            'scene': ['在家'],
            'equipment': ['椅子'],
            'minutes': ['10分钟'],
          },
        );
        coach.conversation!.restoreHistory([
          uc.CoachConversationMessage(id: 'q', at: _now, question: question),
        ]);
        await tester.pumpAndSettle();
        final bubble = tester.widget<ui.CoachQuestionBubble>(
          find.byType(ui.CoachQuestionBubble),
        );
        expect(bubble.question.isConfirmation, isTrue);
        expect(bubble.question.focus, '髋部');
        expect(bubble.question.defaultSelections, question.defaultSelections);
        expect(bubble.question.fields.first.initialSelections, ['在家']);
        expect(bubble.question.fields.first.previousSelections, ['在家']);
        expect(
          bubble.question.fields[1].optionsByScene,
          question.fields[1].optionsByScene,
        );
        expect(bubble.enabled, isFalse);
        expect(bubble.question.answered, isTrue);
        expect(bubble.onFormAnswer, isNotNull);
        expect(bubble.onSkip, isNotNull);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('saved plan sends to discussion without requesting the model', (
      tester,
    ) async {
      final fake = CoachFakeClient([validPlanEnvelope()]);
      final coach = service(fake: fake);
      final store = await pumpApp(tester, coach);
      await openCoach(tester);
      await say(tester, '在家开胯12分钟');
      await expand(tester);
      await tapIn(
        tester,
        find.byKey(const ValueKey('coach-save')),
        'coach-list',
      );
      final group = store.customRoutines.single;
      final requests = fake.requests.length;
      await tester.tap(find.bySemanticsLabel('返回').first);
      await tester.pumpAndSettle();
      await tapIn(
        tester,
        find.byKey(ValueKey('group-to-coach-${group.id}')),
        'practice-list',
      );
      expect(coach.conversation!.focus!.planId, 'ext:${group.id}');
      expect(coach.conversation!.focus!.savedRef.externalId, group.id);
      expect(fake.requests, hasLength(requests));
      expect(find.byType(AiCoachPage), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'focused version supports updating its save and saving a new copy',
      (tester) async {
        final raw = parsePlan(validPlanEnvelope());
        final coach = service(
          fake: CoachFakeClient(coachV2EditScript(raw, 'saved-1')),
        );
        final store = await pumpApp(tester, coach);
        await openCoach(tester);
        final group = await store.saveCustomRoutine(
          CoachPlanMapper(content).map(raw, id: 'saved-1', at: _now).routine,
          coachPlan: raw.toJson(),
        );
        final controller = coach.conversation!;
        expect(
          controller.focusExternalPlan(externalId: group.id, plan: raw).ok,
          isTrue,
        );
        await say(tester, '缩短到5分钟');
        final edited = controller.state.messages.lastWhere(
          (m) => m.plan != null,
        );
        final focused = edited.plan!.plan;
        expect(edited.plan!.version, 2);
        expect(edited.plan!.savedRef!.externalId, group.id);
        expect(edited.plan!.savedRef!.baseVersion, 1);
        expect(edited.planState!.sessionState!.savedRef!.baseVersion, 1);
        await tester.pumpAndSettle();
        expect(find.text('另存一份'), findsOneWidget);
        await expand(tester);
        await tapIn(tester, find.text('更新到我的计划'), 'coach-list');
        expect(store.customRoutines, hasLength(1));
        expect(jsonDecode(store.coachPlanJson[group.id]!), focused.toJson());
        await tapIn(tester, find.text('另存一份'), 'coach-list');
        expect(store.customRoutines, hasLength(2));
        expect(store.coachPlanJson, hasLength(2));
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'SDK-approved preset is offered only after the planning failure and selected explicitly',
      (tester) async {
        final fake = CoachFakeClient([
          uc.LlmResponse(
            content: '',
            toolCalls: [
              uc.LlmToolCall(
                id: 'preset-start',
                name: 'start_task',
                arguments: jsonEncode({'type': 'plan'}),
              ),
            ],
          ),
          const uc.LlmException(uc.LlmErrorKind.network, 'offline'),
        ]);
        final coach = service(fake: fake);
        final store = await pumpApp(tester, coach);
        await openCoach(tester);
        final raw = parsePlan(validPlanEnvelope());
        await store.saveCustomRoutine(
          CoachPlanMapper(
            content,
          ).map(raw, id: 'preset-source', at: _now).routine,
          coachPlan: raw.toJson(),
        );
        expect(
          coach.conversation!
              .focusExternalPlan(externalId: 'preset-source', plan: raw)
              .ok,
          isTrue,
        );
        await say(tester, '修改这个计划');
        expect(coach.conversation!.canOfferPreset(raw), isTrue);
        expect(
          find.byKey(const ValueKey('coach-failure-secondary')),
          findsOneWidget,
        );
        expect(coach.conversation!.state.admittedPlans, isEmpty);
        final requests = fake.requests.length;
        await tapIn(
          tester,
          find.byKey(const ValueKey('coach-failure-secondary')),
          'coach-list',
        );
        expect(fake.requests, hasLength(requests));
        expect(
          coach.conversation!.state.admittedPlans.single.savedRef!.baseVersion,
          1,
        );
        expect(coach.conversation!.state.admittedPlans.single.version, 2);
        expect(find.byType(ui.CoachPlanExpanded), findsOneWidget);
      },
    );

    testWidgets('starting an unsaved SDK plan does not add a saved group', (
      tester,
    ) async {
      final coach = service(fake: CoachFakeClient([validPlanEnvelope()]));
      final store = await pumpApp(tester, coach);
      await openCoach(tester);
      await say(tester, '在家开胯12分钟');
      await expand(tester);
      await tapIn(
        tester,
        find.byKey(const ValueKey('coach-start')),
        'coach-list',
      );
      expect(find.byType(HipPlayerPage), findsOneWidget);
      expect(store.customRoutines, isEmpty);
      expect(store.coachPlanJson, isEmpty);
    });

    testWidgets(
      'editing a saved group cannot change the immutable older SDK card playback',
      (tester) async {
        final coach = service(fake: CoachFakeClient([validPlanEnvelope()]));
        final store = await pumpApp(tester, coach);
        await openCoach(tester);
        await say(tester, '在家开胯12分钟');
        final original = coach.conversation!.state.admittedPlans.single.plan;
        await expand(tester);
        await tapIn(
          tester,
          find.byKey(const ValueKey('coach-save')),
          'coach-list',
        );
        final group = store.customRoutines.single;
        await store.saveCustomRoutine(
          group.copyWith(steps: const [CustomStep('s-seated-fold')]),
        );
        await tapIn(
          tester,
          find.byKey(const ValueKey('coach-start')),
          'coach-list',
        );
        final player = tester.widget<HipPlayerPage>(find.byType(HipPlayerPage));
        expect(
          player.plan.steps.first.drill.id,
          original.items.first.exerciseId,
        );
        expect(player.plan.steps.first.drill.id, isNot('s-seated-fold'));
      },
    );

    testWidgets(
      'a deleted save can be saved again from its unchanged SDK card',
      (tester) async {
        final coach = service(fake: CoachFakeClient([validPlanEnvelope()]));
        final store = await pumpApp(tester, coach);
        await openCoach(tester);
        await say(tester, '在家开胯12分钟');
        final original = coach.conversation!.state.admittedPlans.single.plan;
        await expand(tester);
        await tapIn(
          tester,
          find.byKey(const ValueKey('coach-save')),
          'coach-list',
        );
        await store.deleteCustomRoutine(store.customRoutines.single.id);
        await tester.tap(find.bySemanticsLabel('返回').first);
        await tester.pumpAndSettle();
        await openCoach(tester);
        await expand(tester);
        await tapIn(
          tester,
          find.byKey(const ValueKey('coach-save')),
          'coach-list',
        );
        expect(store.customRoutines, hasLength(1));
        expect(store.customRoutines.single.coachPlan, original.toJson());
      },
    );

    for (final reset in [false, true]) {
      testWidgets(
        '${reset ? 'reset' : 'stop'} ignores a late model result and never revives a question',
        (tester) async {
          final pending = Completer<uc.LlmResponse>();
          final coach = service(
            fake: CoachFakeClient([(uc.LlmRequest _) => pending.future]),
          );
          await pumpApp(tester, coach);
          await openCoach(tester);
          await tester.enterText(
            find.byKey(const ValueKey('coach-input')),
            '等待中的训练请求',
          );
          await tester.tap(find.byKey(const ValueKey('coach-send')));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 100));
          expect(find.byKey(const ValueKey('coach-thinking')), findsOneWidget);
          if (reset) {
            await tester.tap(find.byKey(const ValueKey('coach-reset')));
          } else {
            await tester.tap(find.byKey(const ValueKey('chat-cancel')));
          }
          await tester.pump();
          pending.complete(
            uc.LlmResponse(content: jsonEncode(validPlanEnvelope())),
          );
          await tester.pumpAndSettle();
          expect(find.byType(ui.CoachPlanExpanded), findsNothing);
          expect(find.byType(ui.CoachQuestionBubble), findsNothing);
          expect(find.byKey(const ValueKey('coach-thinking')), findsNothing);
          final input = tester.widget<TextField>(
            find.byKey(const ValueKey('coach-input')),
          );
          expect(input.controller!.text, reset ? isEmpty : '等待中的训练请求');
        },
      );
    }

    testWidgets('missing configuration leaves AI entry hidden', (tester) async {
      await pumpApp(tester, service());
      expect(find.byKey(const ValueKey('practice-ai-coach')), findsNothing);
    });

    for (final dark in [false, true]) {
      testWidgets(
        'normal-sized ${dark ? 'dark' : 'light'} SDK plan stays in bounds',
        (tester) async {
          await pumpApp(
            tester,
            service(fake: CoachFakeClient([validPlanEnvelope()])),
            dark: dark,
          );
          await openCoach(tester);
          await say(tester, '在家开胯12分钟');
          await expand(tester);
          expect(find.byType(ui.CoachPlanExpanded), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }

    for (final platform in [
      TargetPlatform.android,
      TargetPlatform.iOS,
      TargetPlatform.windows,
      TargetPlatform.macOS,
    ]) {
      for (final language in ['zh', 'en']) {
        testWidgets('AI scope: $platform/$language', (tester) async {
          late bool available;
          await tester.pumpWidget(
            MaterialApp(
              theme: ThemeData(platform: platform),
              home: Localizations(
                locale: Locale(language),
                delegates: const [DefaultWidgetsLocalizations.delegate],
                child: Builder(
                  builder: (context) {
                    available = aiCoachAvailable(context, configured: true);
                    return const SizedBox();
                  },
                ),
              ),
            ),
          );
          expect(
            available,
            platform == TargetPlatform.android && language == 'zh',
          );
        });
      }
    }
  });
}
