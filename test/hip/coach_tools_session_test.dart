// App boundary regressions around the SDK 0.2 real CoachSession / ToolGate.
// Every model response enters through the fake LLM, never a fabricated card.
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:hiplab/hip/coach/coach_config.dart';
import 'package:hiplab/hip/coach/coach_service.dart';
import 'package:hiplab/hip/coach/template_fallback.dart';
import 'package:hiplab/hip/coach/usage_store.dart';
import 'package:hiplab/hip/ui/coach/ai_coach_page.dart';
import 'package:ugk_coach/ugk_coach.dart' as uc;

import 'hip_ai_coach_test.dart' show readAsset, textResponse, toolResponse;
import 'hip_domain_test.dart' show MemoryStorage, loadContent;

CoachService _service(uc.LlmClient client) => CoachService(
  config: const CoachConfig(appKey: 'test'),
  content: loadContent(),
  client: client,
  usage: CoachUsageStore(),
  storage: MemoryStorage(),
  readAsset: readAsset,
);

void main() {
  test(
    'only gate admitted values leave the service: text / actions / plan',
    () async {
      final fake = uc.FakeLlmClient([
        textResponse('先说说今天想怎么练。'),
        toolResponse(
          text: '先看看这两个动作。',
          name: 'show_actions',
          arguments: {
            'items': [
              {'actionId': 's-figure4', 'note': '感受臀部外侧的拉伸。'},
              {'actionId': 'n-windshield'},
            ],
          },
        ),
        toolResponse(),
      ], latency: Duration.zero);
      final service = _service(fake);
      final text = await service.send('你好');
      expect(text.status, uc.TurnStatus.ok);
      expect(text.text, '先说说今天想怎么练。');
      expect(text.plan, isNull);
      expect(text.actions, isNull);
      final actions = await service.send('看两个动作');
      expect(actions.status, uc.TurnStatus.ok);
      expect(actions.actions, isA<uc.ValidatedActions>());
      expect(actions.actions!.items.map((a) => a.id), [
        's-figure4',
        'n-windshield',
      ]);
      expect(actions.plan, isNull);
      final plan = await service.send('给我睡前 12 分钟的训练');
      expect(plan.plan, isA<uc.ValidatedPlan>());
      expect(plan.actions, isNull);
      expect(service.session, isA<uc.CoachSession>());
      expect(service.session!.turnCount, 3);
      expect(service.usage.totals.calls, 3);
      expect(service.usage.totals.totalTokens, 3600);
    },
  );

  test(
    'raw invalid actions never leave the service; gate feedback retries three times',
    () async {
      final fake = uc.FakeLlmClient([
        for (var i = 0; i < 3; i++)
          toolResponse(
            text: '非法原始内容不应显示',
            name: 'show_actions',
            arguments: {
              'items': [
                {'actionId': 'n-thomas-test', 'note': '自测演示不可选'},
              ],
            },
          ),
      ], latency: Duration.zero);
      final service = _service(fake);
      final answer = await service.send('睡前放松');
      expect(answer.status, uc.TurnStatus.fallback);
      expect(answer.presetReason, PresetReason.invalid);
      expect(answer.actions, isNull);
      expect(answer.plan, isA<uc.ValidatedPlan>());
      expect(answer.text, isNot(contains('非法原始内容')));
      expect(answer.text, contains('预设方案'));
      expect(fake.requests, hasLength(3));
      for (final request in fake.requests.skip(1)) {
        expect(request.messages.last.role, uc.LlmRole.tool);
        expect(
          request.messages.last.content,
          contains(uc.IssueCodes.outOfProfile),
        );
      }
      expect(service.usage.records, hasLength(3));
      expect(
        service.usage.records.every(
          (r) => r.turnOutcome == uc.TurnOutcome.fallback,
        ),
        isTrue,
      );
    },
  );

  test(
    'send passes the explicit level, minutes and protected body parts to SDK',
    () async {
      final fake = uc.FakeLlmClient([
        textResponse('按已知条件继续。'),
      ], latency: Duration.zero);
      final service = _service(fake);
      const context = uc.CoachContext(
        level: 2,
        minutes: 15,
        avoid: {'膝', '腰'},
        notes: ['上次练习报告疼痛，本次保护对应部位。'],
      );
      await service.send('安排一节训练', context: context);
      expect(
        fake.requests.single.messages.last.content,
        uc.ToolPromptBuilder().userMessage(
          service.profile,
          service.catalog,
          context,
          '安排一节训练',
        ),
      );
      expect(fake.requests.single.tools.map((t) => t.name), [
        'show_actions',
        'show_plan',
      ]);
    },
  );

  test(
    'concurrent send returns busy without another request or duplicate history',
    () async {
      final started = Completer<void>();
      final response = Completer<uc.LlmResponse>();
      final fake = uc.FakeLlmClient([
        (uc.LlmRequest _) {
          started.complete();
          return response.future;
        },
      ], latency: Duration.zero);
      final service = _service(fake);
      final first = service.send('第一轮');
      await started.future;
      final duplicate = await service.send('重复发送');
      expect(duplicate.status, uc.TurnStatus.busy);
      expect(duplicate.plan, isNull);
      expect(fake.requests, hasLength(1));
      response.complete(textResponse('完成第一轮'));
      expect((await first).status, uc.TurnStatus.ok);
      expect(service.session!.turnCount, 1);
      expect(
        service.session!.history.map((m) => m.content).join(),
        isNot(contains('重复发送')),
      );
    },
  );

  test(
    'newConversation resets SDK, UI and saved identities; late old response is discarded',
    () async {
      final started = Completer<void>();
      final oldResponse = Completer<uc.LlmResponse>();
      final fake = uc.FakeLlmClient([
        (uc.LlmRequest _) {
          started.complete();
          return oldResponse.future;
        },
        textResponse('新对话的回复'),
      ], latency: Duration.zero);
      final service = _service(fake);
      final state = AiCoachSession(service);
      addTearDown(state.dispose);
      final old = state.send('应作废的旧请求');
      await started.future;
      state.saved[99] = 'old-group';
      state.newConversation();
      expect(state.messages, isEmpty);
      expect(state.saved, isEmpty);
      expect(state.busy, isFalse);
      expect(service.session!.history, isEmpty);
      await state.send('新对话的问题');
      oldResponse.complete(toolResponse(text: '不应显示的晚到旧计划'));
      await old;
      expect(state.messages, hasLength(2));
      expect(state.messages.first.text, '新对话的问题');
      expect(state.messages.last.answer!.text, '新对话的回复');
      expect(state.messages.last.answer!.plan, isNull);
      expect(service.session!.turnCount, 1);
      expect(
        fake.requests.last.messages.any((m) => m.content.contains('应作废的旧请求')),
        isFalse,
      );
      expect(state.busy, isFalse);
      expect(state.cancelledText, isNull);
    },
  );

  test(
    'cancelled result carries no renderable values or committed conversation',
    () async {
      final started = Completer<void>();
      final pending = Completer<uc.LlmResponse>();
      final fake = uc.FakeLlmClient([
        (uc.LlmRequest _) {
          started.complete();
          return pending.future;
        },
      ], latency: Duration.zero);
      final service = _service(fake);
      final cancel = uc.CancelToken();
      final sent = service.send('取消这一轮', cancel: cancel);
      await started.future;
      cancel.cancel();
      pending.complete(toolResponse());
      final answer = await sent;
      expect(answer.status, uc.TurnStatus.cancelled);
      expect(answer.cancelled, isTrue);
      expect(answer.text, isEmpty);
      expect(answer.plan, isNull);
      expect(answer.actions, isNull);
      expect(answer.preset, isFalse);
      expect(service.session!.turnCount, 0);
      expect(service.session!.history, isEmpty);
    },
  );

  test(
    'session contextBuilder is evaluated each turn; explicit context overrides it',
    () async {
      final fake = uc.FakeLlmClient([
        textResponse('收到第一轮条件'),
        textResponse('收到第二轮条件'),
        textResponse('收到覆盖条件'),
      ], latency: Duration.zero);
      final service = _service(fake);
      var minutes = 5;
      final state = AiCoachSession(
        service,
        contextBuilder: () =>
            uc.CoachContext(level: 1, minutes: minutes, avoid: const {'膝'}),
      );
      addTearDown(state.dispose);
      await state.send('第一轮');
      minutes = 15;
      await state.send('第二轮');
      const explicit = uc.CoachContext(level: 2, minutes: 20, avoid: {'腰'});
      await state.send('第三轮', context: explicit);
      final contexts = [
        const uc.CoachContext(level: 1, minutes: 5, avoid: {'膝'}),
        const uc.CoachContext(level: 1, minutes: 15, avoid: {'膝'}),
        explicit,
      ];
      for (var i = 0; i < fake.requests.length; i++) {
        expect(
          fake.requests[i].messages.last.content,
          uc.ToolPromptBuilder().userMessage(
            service.profile,
            service.catalog,
            contexts[i],
            ['第一轮', '第二轮', '第三轮'][i],
          ),
        );
      }
    },
  );

  test(
    'context protected parts also gate tool actions; retry uses valid action',
    () async {
      final fake = uc.FakeLlmClient([
        toolResponse(
          name: 'show_actions',
          arguments: {
            'items': [
              {'actionId': 's-frog'},
            ],
          },
        ),
        textResponse('先保护膝部，本次不展示该动作。'),
      ], latency: Duration.zero);
      final service = _service(fake);
      final answer = await service.send(
        '看个开胯动作',
        context: const uc.CoachContext(avoid: {'膝'}),
      );
      expect(answer.status, uc.TurnStatus.ok);
      expect(answer.actions, isNull);
      expect(fake.requests, hasLength(2));
      expect(
        fake.requests.last.messages.last.content,
        contains(uc.IssueCodes.avoid),
      );
    },
  );
}
