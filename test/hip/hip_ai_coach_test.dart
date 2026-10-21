// AI 定制 (docs/ai-coach.md): service scope, plan → custom group mapping,
// preset fallback and the page, all on the SDK's FakeLlmClient (no network).
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:hiplab/hip/coach/coach_config.dart';
import 'package:hiplab/hip/coach/coach_service.dart';
import 'package:hiplab/hip/coach/plan_mapping.dart';
import 'package:hiplab/hip/coach/template_fallback.dart';
import 'package:hiplab/hip/coach/usage_store.dart';
import 'package:hiplab/hip/control/hip_store.dart';
import 'package:hiplab/hip/domain/hip_library.dart';
import 'package:hiplab/hip/domain/hip_models.dart';
import 'package:hiplab/hip/domain/hip_settings.dart';
import 'package:hiplab/hip/ui/coach/ai_coach_page.dart';
import 'package:hiplab/hip/ui/hip_app.dart';
import 'package:hiplab/hip/ui/hip_player_page.dart';
import 'package:hiplab/hip/ui/hip_widgets.dart';
import 'package:ugk_coach/ugk_coach.dart' as uc;

import 'hip_domain_test.dart' show MemoryStorage, loadContent;

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
Map<String, Object?> validPlanArguments() => {
  'schemaVersion': 1,
  'title': '睡前开胯 12 分钟',
  'summary': '先活动髋关节，再做外旋和内收拉伸，最后抱膝放松。',
  'goal': 'mobility',
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
      'items': [item('h-knee-hug', 'time', 1, 30, rest: 0)],
    },
  ],
  'notes': [],
  'safetyNotes': ['拉伸停在有感觉但不痛的位置。'],
};

uc.TrainingPlan parsePlan(Map<String, Object?> arguments) =>
    const uc.PlanCodec().decodeStrict(arguments, id: 'p').plan!;

uc.LlmToolCall toolCall(
  String name,
  Object arguments, {
  String id = 'call-1',
}) => uc.LlmToolCall(
  id: id,
  name: name,
  arguments: arguments is String ? arguments : jsonEncode(arguments),
);

uc.LlmResponse toolResponse({
  String text = '按你说的排了睡前 12 分钟。',
  String name = 'show_plan',
  Object? arguments,
}) => uc.LlmResponse(
  content: text,
  toolCalls: [toolCall(name, arguments ?? validPlanArguments())],
  usage: const uc.TokenUsage(promptTokens: 1000, completionTokens: 200),
  model: 'fake-model',
  finishReason: 'tool_calls',
);

uc.LlmResponse textResponse(String text) => uc.LlmResponse(
  content: text,
  usage: const uc.TokenUsage(promptTokens: 1000, completionTokens: 200),
  model: 'fake-model',
  finishReason: 'stop',
);

void main() {
  final content = loadContent();

  CoachService service({
    uc.FakeLlmClient? fake,
    CoachUsageStore? usage,
    MemoryStorage? storage,
  }) => CoachService(
    config: fake == null
        ? const CoachConfig()
        : const CoachConfig(appKey: 'test'),
    content: content,
    client: fake,
    usage: usage ?? CoachUsageStore(),
    storage: storage ?? MemoryStorage(),
    readAsset: readAsset,
  );

  group('服务、映射与回落', () {
    test('范围 = hiplab profile ∩ 动作大全：45 个，自测演示 n-thomas-test 排除', () async {
      final s = service(fake: uc.FakeLlmClient(const []));
      await s.load();
      expect(s.excludedIds, {'n-thomas-test'});
      final scope = s.profile.scope(s.catalog);
      expect(scope, hasLength(45));
      expect(scope.length, libraryDrills(content).length);
      for (final d in scope) {
        expect(inLibrary(content, d.id), isTrue, reason: d.id);
        expect(File(content.drill(d.id).video!).existsSync(), isTrue);
      }
    });

    test('合格样例通过工具门禁；用到被排除的动作报 out_of_profile', () async {
      final s = service(fake: uc.FakeLlmClient(const []));
      await s.load();
      final gate = uc.ToolGate(catalog: s.catalog, profile: s.profile);
      final good = gate.check('', [
        toolCall('show_plan', validPlanArguments()),
      ]);
      expect(good.ok, isTrue);
      expect(good.plan, isA<uc.ValidatedPlan>());
      final bad = validPlanArguments();
      ((bad['blocks'] as List)[2] as Map)['items'] = [
        item('n-thomas-test', 'time', 1, 30, perSide: true),
      ];
      expect(
        gate.check('', [toolCall('show_plan', bad)]).errors.map((e) => e.code),
        contains(uc.IssueCodes.outOfProfile),
      );
    });

    test('映射：块拍平、轮数折进组数、按动作包口径换算与收范围、休息取中位数', () {
      final m = CoachPlanMapper(
        content,
      ).map(parsePlan(validPlanArguments()), id: 'c1', at: _now);
      expect(m.routine.steps.map((s) => s.kitId), [
        'n-windshield',
        'h-quad-cars',
        's-figure4',
        's-butterfly',
        'w-clamshell',
        'h-knee-hug',
      ]);
      final byId = {for (final e in m.entries) e.drill.id: e};
      expect(byId['n-windshield']!.doseText, '左右交替 8 次');
      expect(byId['h-quad-cars']!.doseText, '每侧 5 圈');
      // 2 轮 → 2 组。
      expect(byId['s-figure4']!.doseText, '每侧 40 秒 × 2 组');
      expect(byId['s-butterfly']!.doseText, '停 40 秒 × 2 组');
      expect(byId['w-clamshell']!.doseText, '每侧 12 次 × 2 组');
      expect(byId['w-clamshell']!.adjusted, isFalse);
      // 抱膝呼吸：目录是计时，动作包是计数（慢呼吸）→ 换成 30 秒里能做完的次数。
      final hug = byId['h-knee-hug']!;
      final kit = content.kit('h-knee-hug')!;
      final reps = ((30 - kit.lead) / kit.cycleFor(const KitDose())).floor();
      expect(hug.adjusted, isTrue);
      expect(hug.step.dose(kit).reps, reps);
      expect(hug.doseText, '慢呼吸 $reps 次');
      expect(m.routine.restSeconds, 20);
      expect(m.routine.name, '睡前开胯 12 分钟');
      expect(m.adjusted, isTrue);
      expect(m.seconds(content), m.routine.seconds(content));
    });

    test('映射：超范围收进训练组范围、3 组封顶、重复并入、名字 12 字', () {
      final env = validPlanArguments();
      final plan = env;
      plan['title'] = '一个非常非常非常长的开胯训练名字';
      plan['blocks'] = [
        {
          'id': 'b1',
          'name': '',
          'type': 'main',
          'rounds': 3,
          'restBetweenRoundsSeconds': 0,
          'items': [
            item('w-clamshell', 'reps', 2, 30, perSide: true),
            item('s-frog', 'time', 1, 120),
            item('w-clamshell', 'reps', 1, 10, perSide: true),
            item('n-seated-ir-drop', 'reps', 1, 8, perSide: true),
          ],
        },
      ];
      final m = CoachPlanMapper(
        content,
      ).map(parsePlan(env), id: 'c2', at: _now);
      expect(m.routine.steps.map((s) => s.kitId), [
        'w-clamshell',
        's-frog',
        'n-seated-ir-drop',
      ]);
      final clam = m.entries[0];
      final clamKit = content.kit('w-clamshell')!;
      expect(clam.step.dose(clamKit).reps, 2 * clamKit.defaultReps!);
      expect(clam.step.dose(clamKit).sets, 3);
      expect(clam.adjusted, isTrue);
      expect(m.entries[1].step.dose(content.kit('s-frog')!).seconds, 120);
      // 保持类给了次数 → 动作包默认秒数。
      final drop = content.kit('n-seated-ir-drop')!;
      expect(m.entries[2].step.dose(drop).seconds, drop.defaultSeconds);
      expect(m.entries[2].adjusted, isTrue);
      expect(m.entries.first.blockName, '主训练');
      expect(m.routine.name.runes.length, CustomRoutine.maxName);
      expect(m.routine.restSeconds, 15);
    });

    test('回落按关键词挑内置套路；原剂量保留且遵守器械限制；红旗只给就医建议', () async {
      expect(TemplateFallback.pickRoutine('睡前想放松一下'), 'B');
      expect(TemplateFallback.pickRoutine('在办公室工位上做'), 'A');
      expect(TemplateFallback.pickRoutine('早上起床唤醒'), 'C');
      expect(TemplateFallback.pickRoutine('跑步前热身激活'), 'E');
      expect(TemplateFallback.pickRoutine('想练横叉和托马斯'), 'F');
      expect(TemplateFallback.pickRoutine('随便练练'), 'D');
      final s = service(fake: uc.FakeLlmClient(const []));
      await s.load();
      final t = TemplateFallback(content);
      final r = t.reply(
        '睡前练练',
        reason: PresetReason.offline,
        catalog: s.catalog,
        profile: s.profile,
      );
      expect(r.plan!.source, 'template');
      expect(r.plan!.templateId, 'B');
      expect(r.text, contains('网络不可用'));
      expect(r.text, contains('预设方案'));
      expect(r.text, contains('不是 AI 生成的'));
      final m = CoachPlanMapper(content).map(r.plan!, id: 'c3', at: _now);
      final copy = copyRoutine(
        content.routine('B'),
        content,
        id: 'c3',
        name: '睡前 8 分钟',
        at: _now,
      );
      // Home assumes no band. The gate excludes h-band-leg-out, while all
      // admitted steps retain the App's original kit doses and pace.
      expect(
        r.plan!.items.map((i) => i.exerciseId),
        copy.steps
            .where((s) => s.kitId != 'h-band-leg-out')
            .map((s) => s.kitId),
      );
      expect(
        m.routine.toJson(),
        copy
            .copyWith(
              steps: [
                for (final step in copy.steps)
                  if (step.kitId != 'h-band-leg-out') step,
              ],
            )
            .toJson(),
      );
      final red = t.reply(
        '大腿刚拉伤，肿了',
        reason: PresetReason.offline,
        catalog: s.catalog,
        profile: s.profile,
      );
      expect(red.plan, isNull);
      expect(red.text, contains('就医'));
    });
  });

  group('PR #25 审核：多轮回落记得先前约束（F25-1）', () {
    Future<uc.TrainingPlan?> twoRounds(
      CoachService s,
      String first,
      String second,
    ) async {
      await s.send(first);
      return (await s.send(second)).plan?.plan;
    }

    test('未配置：先说做了手术，第二轮仍不给可开始的计划', () async {
      final s = service();
      expect((await s.send('我做了手术，想恢复训练')).plan, isNull);
      final a2 = await s.send('给我一个简单方案');
      expect(a2.plan, isNull);
      expect(a2.text, contains('就医'));
    });

    test('首轮模型建议就医、第二轮断网：回落仍不给计划', () async {
      final s = service(
        fake: uc.FakeLlmClient([
          textResponse('术后请先咨询医生，确认可以练再来。'),
          const uc.LlmException(uc.LlmErrorKind.network, 'offline'),
        ]),
      );
      expect(await twoRounds(s, '我做了手术，想恢复训练', '给我一个简单方案'), isNull);
    });

    test('办公室不能躺地 → 追问时长 → 答「5分钟」时断网：回落不出地面动作', () async {
      final s = service(
        fake: uc.FakeLlmClient([
          textResponse('想练几分钟？'),
          const uc.LlmException(uc.LlmErrorKind.network, 'offline'),
        ]),
      );
      final plan = await twoRounds(s, '在办公室，不能躺地', '5分钟');
      expect(plan, isNotNull);
      expect(plan!.scene, 'office');
      expect(content.routine(plan.templateId!).scene, HipScene.chair);
    });
  });

  group('AI 定制页', () {
    Future<HipStore> pumpApp(
      WidgetTester tester,
      CoachService coach, {
      Size size = const Size(390, 844),
      double textScale = 1,
      bool dark = false,
      void Function(HipStore)? setup,
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = textScale;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final store = HipStore(
        content: content,
        storage: MemoryStorage(),
        clock: () => _now,
      );
      await store.initialize();
      store
        ..safety = {'pregnancy': false, 'surgery': false, 'acute': false}
        ..identity = HipIdentity.office
        ..minutes = 12
        ..theme = dark ? HipThemeChoice.dark : HipThemeChoice.light;
      setup?.call(store);
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

    Finder inList(String key) => find.byKey(ValueKey(key));

    Future<void> tapIn(WidgetTester tester, Finder f, String list) async {
      await tester.scrollUntilVisible(
        f,
        200,
        scrollable: find
            .descendant(
              of: find.byKey(ValueKey(list)),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.pumpAndSettle();
      await tester.tap(f);
      await tester.pumpAndSettle();
    }

    Future<void> openCoach(WidgetTester tester, {bool accept = true}) async {
      await tapIn(tester, inList('practice-ai-coach'), 'practice-list');
      if (accept && inList('coach-disclaimer-ok').evaluate().isNotEmpty) {
        await tester.tap(inList('coach-disclaimer-ok'));
        await tester.pumpAndSettle();
      }
    }

    Future<void> say(WidgetTester tester, String text) async {
      await tester.enterText(inList('coach-input'), text);
      await tester.tap(inList('coach-send'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpAndSettle();
    }

    Future<void> tapCard(WidgetTester tester, String key) =>
        tapIn(tester, inList(key), 'coach-list');

    testWidgets('show_actions 只展示门禁动作卡，不出现计划、保存或开练', (tester) async {
      final fake = uc.FakeLlmClient([
        toolResponse(
          text: '先看看这两个动作。',
          name: 'show_actions',
          arguments: {
            'items': [
              {'actionId': 's-figure4', 'note': '先了解姿势。'},
              {'actionId': 'n-windshield'},
            ],
          },
        ),
      ]);
      await pumpApp(tester, service(fake: fake));
      await openCoach(tester);
      await say(tester, '先看看动作');
      expect(inList('coach-actions-0'), findsOneWidget);
      expect(find.text('先看看这两个动作。'), findsOneWidget);
      expect(find.text(content.drill('s-figure4').name), findsOneWidget);
      expect(find.text(content.drill('n-windshield').name), findsOneWidget);
      expect(find.text('先了解姿势。'), findsOneWidget);
      expect(inList('coach-plan-card'), findsNothing);
      expect(inList('coach-save'), findsNothing);
      expect(inList('coach-start'), findsNothing);
      expect(
        find.descendant(
          of: inList('coach-actions-0'),
          matching: find.byType(HipDrillArt),
        ),
        findsNWidgets(2),
      );
    });

    testWidgets('无效工具的原始文字、字段与动作卡不进入渲染层', (tester) async {
      final fake = uc.FakeLlmClient([
        for (var i = 0; i < 3; i++)
          toolResponse(
            text: '原始无效输出不可显示',
            name: 'show_actions',
            arguments: {
              'items': [
                {'actionId': 'n-thomas-test', 'note': '原始未验台词'},
              ],
            },
          ),
      ]);
      await pumpApp(tester, service(fake: fake));
      await openCoach(tester);
      await say(tester, '睡前放松');
      expect(fake.requests, hasLength(3));
      expect(find.text('原始无效输出不可显示'), findsNothing);
      expect(find.text('原始未验台词'), findsNothing);
      expect(inList('coach-actions-0'), findsNothing);
      expect(inList('coach-badge-preset'), findsOneWidget);
      expect(inList('coach-plan-card'), findsOneWidget);
    });

    testWidgets('关闭重开保留消息；新对话清空并重置 SDK 历史', (tester) async {
      final fake = uc.FakeLlmClient([
        textResponse('第一轮的文字回复'),
        textResponse('新对话的文字回复'),
      ]);
      final coach = service(fake: fake);
      await pumpApp(tester, coach);
      await openCoach(tester);
      await say(tester, '保留这轮');
      await tester.tap(find.bySemanticsLabel('返回').first);
      await tester.pumpAndSettle();
      await openCoach(tester);
      expect(find.text('第一轮的文字回复'), findsOneWidget);
      expect(find.text('保留这轮'), findsOneWidget);
      expect(coach.session!.turnCount, 1);
      await tester.tap(inList('coach-new-conversation'));
      await tester.pumpAndSettle();
      expect(find.text('第一轮的文字回复'), findsNothing);
      expect(find.text('保留这轮'), findsNothing);
      expect(coach.session!.history, isEmpty);
      expect(coach.session!.turnCount, 0);
      await say(tester, '重新开始');
      expect(find.text('新对话的文字回复'), findsOneWidget);
      expect(fake.requests.last.messages, hasLength(2));
    });

    testWidgets('生成 → 计划卡 → 保存为自定义训练组 → 出现在「我的」→ 开始训练', (tester) async {
      final usage = CoachUsageStore();
      final fake = uc.FakeLlmClient([toolResponse()]);
      final store = await pumpApp(tester, service(fake: fake, usage: usage));
      expect(inList('practice-ai-unconfigured'), findsNothing);
      // 底栏仍是 3 个。
      expect(find.byKey(const ValueKey('tab-3')), findsNothing);
      await openCoach(tester);
      expect(find.text('说说你想怎么练'), findsOneWidget);
      await say(tester, '睡前 12 分钟，开开胯');

      expect(fake.requests, hasLength(1));
      expect(inList('coach-plan-card'), findsOneWidget);
      expect(inList('coach-badge-ai'), findsOneWidget);
      expect(find.text('睡前开胯 12 分钟'), findsOneWidget);
      expect(find.text('每侧 40 秒 × 2 组'), findsOneWidget);
      expect(find.text(content.drill('s-butterfly').name), findsOneWidget);
      expect(
        find.descendant(
          of: inList('coach-plan-card'),
          matching: find.byType(HipDrillArt),
        ),
        findsNWidgets(6),
      );
      expect(find.textContaining('拉伸停在有感觉但不痛的位置'), findsOneWidget);
      expect(find.textContaining('出现疼痛、麻木或头晕立即停止'), findsOneWidget);
      expect(find.textContaining('6 个动作 · 约'), findsOneWidget);
      expect(usage.totals.calls, 1);

      await tapCard(tester, 'coach-save');
      expect(store.customRoutines, hasLength(1));
      final g = store.customRoutines.single;
      expect(g.name, '睡前开胯 12 分钟');
      expect(g.steps, hasLength(6));
      expect(g.restSeconds, 20);
      expect(g.steps[2].sets, 2);
      expect(find.text('已保存到「我的」'), findsOneWidget);

      // 直接开始：进入现有训练流程（自定义训练组），第一步是热身动作。
      await tapCard(tester, 'coach-start');
      expect(find.byType(HipPlayerPage), findsOneWidget);
      final player = tester.widget<HipPlayerPage>(find.byType(HipPlayerPage));
      expect(player.plan.source, PlanSource.custom);
      expect(player.plan.refId, g.id);
      expect(player.plan.steps.first.drill.id, 'n-windshield');
      expect(player.plan.steps[2].sets, 2);
      await tester.tap(find.byKey(const ValueKey('close')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('close-confirm')));
      await tester.pumpAndSettle();
      expect(find.byType(HipPlayerPage), findsNothing);
      expect(inList('coach-plan-card'), findsOneWidget);

      // 回到练习页「我的」：训练组在，从组卡片开始同样进训练。
      await tester.tap(find.bySemanticsLabel('返回').first);
      await tester.pumpAndSettle();
      expect(inList('group-card-${g.id}'), findsOneWidget);
      await tapIn(tester, inList('group-start-${g.id}'), 'practice-list');
      final again = tester.widget<HipPlayerPage>(find.byType(HipPlayerPage));
      expect(again.plan.steps.map((s) => s.drill.id), [
        for (final s in g.steps) s.kitId,
      ]);
      expect(tester.takeException(), isNull);
    });

    testWidgets('不保存直接开始：同样进训练流程，不新增训练组', (tester) async {
      final store = await pumpApp(
        tester,
        service(fake: uc.FakeLlmClient([toolResponse()])),
      );
      await openCoach(tester);
      await say(tester, '睡前 12 分钟');
      await tapCard(tester, 'coach-start');
      final player = tester.widget<HipPlayerPage>(find.byType(HipPlayerPage));
      expect(player.plan.source, PlanSource.custom);
      expect(player.plan.steps, hasLength(6));
      expect(store.customRoutines, isEmpty);
    });

    testWidgets('纯文字按气泡呈现；继续发送保留上一轮历史，再出计划', (tester) async {
      final fake = uc.FakeLlmClient([
        textResponse('在家还是在办公室？'),
        toolResponse(),
      ]);
      await pumpApp(tester, service(fake: fake));
      await openCoach(tester);
      await say(tester, '想开开胯');
      expect(find.text('在家还是在办公室？'), findsOneWidget);
      expect(inList('coach-plan-card'), findsNothing);
      await say(tester, '在家');
      expect(fake.requests, hasLength(2));
      expect(fake.requests.last.messages.last.content, contains('在家'));
      expect(
        fake.requests.last.messages.any(
          (m) => m.role == uc.LlmRole.assistant && m.content == '在家还是在办公室？',
        ),
        isTrue,
      );
      expect(inList('coach-plan-card'), findsOneWidget);
    });

    testWidgets('第一次输出校验失败 → 带错误重写 → 通过', (tester) async {
      final bad = validPlanArguments();
      (((bad['blocks'] as List)[0] as Map)['items'] as List)[0] = item(
        'made-up-drill',
        'reps',
        1,
        8,
      );
      final usage = CoachUsageStore();
      final fake = uc.FakeLlmClient([
        toolResponse(arguments: bad),
        toolResponse(),
      ]);
      await pumpApp(tester, service(fake: fake, usage: usage));
      await openCoach(tester);
      await say(tester, '睡前 12 分钟');
      expect(fake.requests, hasLength(2));
      expect(fake.requests.last.messages.last.role, uc.LlmRole.tool);
      expect(
        fake.requests.last.messages.last.content,
        contains(uc.IssueCodes.unknownExercise),
      );
      expect(inList('coach-badge-ai'), findsOneWidget);
      expect(inList('coach-badge-preset'), findsNothing);
      expect(usage.records.map((r) => r.outcome), [
        uc.CallOutcome.rejected,
        uc.CallOutcome.rewritten,
      ]);
    });

    testWidgets('三次门禁失败 → 回落预设方案并说明不是 AI 生成', (tester) async {
      final bad = validPlanArguments();
      ((bad['blocks'] as List)[1] as Map)['items'] = [
        item('s-figure4', 'time', 1, 40), // 单侧动作没标每侧
      ];
      await pumpApp(
        tester,
        service(
          fake: uc.FakeLlmClient([
            for (var i = 0; i < 3; i++)
              toolResponse(text: "不应展示的无效计划", arguments: bad),
          ]),
        ),
      );
      await openCoach(tester);
      await say(tester, '睡前放松');
      expect(inList('coach-badge-preset'), findsOneWidget);
      expect(inList('coach-preset-note'), findsOneWidget);
      expect(find.textContaining(PresetReason.invalid.zh), findsOneWidget);
      expect(find.text('不应展示的无效计划'), findsNothing);
      expect(find.textContaining('「睡前 8 分钟」'), findsOneWidget);
    });

    testWidgets('断网 → 预设方案（按关键词），可保存成训练组', (tester) async {
      final usage = CoachUsageStore();
      final fake = uc.FakeLlmClient([
        const uc.LlmException(uc.LlmErrorKind.network, 'offline'),
      ]);
      final store = await pumpApp(tester, service(fake: fake, usage: usage));
      await openCoach(tester);
      await say(tester, '在办公室工位上做一组');
      expect(fake.requests, hasLength(1)); // 网络错误不重写
      expect(find.textContaining('网络不可用'), findsOneWidget);
      expect(inList('coach-badge-preset'), findsOneWidget);
      await tapCard(tester, 'coach-save');
      final g = store.customRoutines.single;
      expect(g.fromRoutine, 'A');
      expect(g.steps.map((s) => s.kitId), [
        for (final s in content.routine('A').steps) s.drillId,
      ]);
      expect(usage.records.single.turnOutcome, uc.TurnOutcome.fallback);
    });

    testWidgets('超时 → 标记预设方案，可保存并交给共享训练播放器开练', (tester) async {
      final fake = uc.FakeLlmClient([
        const uc.LlmException(uc.LlmErrorKind.timeout, 'timed out'),
      ]);
      final store = await pumpApp(tester, service(fake: fake));
      await openCoach(tester);
      await say(tester, '睡前放松');
      expect(find.textContaining('AI 响应超时'), findsOneWidget);
      expect(inList('coach-badge-preset'), findsOneWidget);
      await tapCard(tester, 'coach-save');
      expect(store.customRoutines, hasLength(1));
      final saved = store.customRoutines.single;
      expect(saved.fromRoutine, 'B');
      await tapCard(tester, 'coach-start');
      final player = tester.widget<HipPlayerPage>(find.byType(HipPlayerPage));
      expect(player.plan.source, PlanSource.custom);
      expect(player.plan.refId, saved.id);
      expect(
        player.plan.steps.map((s) => s.drill.id),
        saved.steps.map((s) => s.kitId),
      );
    });

    testWidgets('未配置令牌：入口标未配置，不调模型，直接给预设方案', (tester) async {
      final coach = service();
      expect(coach.configured, isFalse);
      await pumpApp(tester, coach);
      expect(inList('practice-ai-unconfigured'), findsOneWidget);
      await openCoach(tester);
      expect(find.text('未配置 AI · 使用预设方案'), findsOneWidget);
      expect(inList('coach-unconfigured-note'), findsOneWidget);
      await say(tester, '早上起床唤醒一下');
      expect(find.textContaining('AI 还没配置'), findsOneWidget);
      expect(inList('coach-badge-preset'), findsOneWidget);
      expect(find.textContaining('「晨起唤醒 6 分钟」'), findsOneWidget);
      expect(coach.usage.totals.calls, 0);
    });

    testWidgets('离线 / 未配置时提到红旗情况：只给就医建议，不给计划', (tester) async {
      await pumpApp(tester, service());
      await openCoach(tester);
      await say(tester, '昨天大腿后侧刚拉伤，还有点肿');
      expect(find.textContaining('建议先就医'), findsOneWidget);
      expect(inList('coach-plan-card'), findsNothing);
    });

    testWidgets('首次使用显示一行免责，确认后不再显示', (tester) async {
      final storage = MemoryStorage();
      await pumpApp(tester, service(storage: storage));
      await openCoach(tester, accept: false);
      expect(inList('coach-disclaimer'), findsOneWidget);
      await tester.tap(inList('coach-disclaimer-ok'));
      await tester.pumpAndSettle();
      expect(inList('coach-disclaimer'), findsNothing);
      expect(storage.values[CoachService.storageKey], contains('true'));
      final again = service(storage: storage);
      await again.load();
      expect(again.disclaimerAccepted, isTrue);
    });

    testWidgets('等待：显示首轮 75–120 秒与取消；发送禁用，取消后不显示结果', (tester) async {
      final usage = CoachUsageStore();
      final coach = service(
        usage: usage,
        fake: uc.FakeLlmClient([
          (uc.LlmRequest r) async {
            await Future<void>.delayed(const Duration(seconds: 30));
            return toolResponse();
          },
        ]),
      );
      await pumpApp(tester, coach);
      await openCoach(tester);
      await tester.enterText(inList('coach-input'), '睡前开胯');
      await tester.tap(inList('coach-send'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(inList('coach-thinking'), findsOneWidget);
      expect(inList('coach-progress'), findsOneWidget);
      expect(
        tester.widget<HipCircleButton>(inList('coach-send')).onPressed,
        isNull,
      );
      expect(tester.widget<TextField>(inList('coach-input')).enabled, isFalse);
      expect(find.text('正在等待 AI 回复…'), findsOneWidget);
      await tester.pump(const Duration(seconds: 8));
      expect(find.textContaining('已用 8 秒'), findsOneWidget);
      expect(find.textContaining('75–120 秒'), findsOneWidget);
      await tester.tap(inList('coach-stop'));
      await tester.pump(const Duration(seconds: 30));
      await tester.pumpAndSettle();
      expect(inList('coach-thinking'), findsNothing);
      expect(inList('coach-plan-card'), findsNothing);
      expect(inList('coach-badge-preset'), findsNothing); // 停止不回落
      final field = tester.widget<TextField>(inList('coach-input'));
      expect(field.controller!.text, '睡前开胯');
      expect(usage.records.single.outcome, uc.CallOutcome.cancelled);
    });

    Finder inMsg(int i, String key) =>
        find.descendant(of: inList('coach-msg-$i'), matching: inList(key));
    Finder textInMsg(int i, String text) =>
        find.descendant(of: inList('coach-msg-$i'), matching: find.text(text));

    Map<String, Object?> planWithId(String id, int figure4Seconds) {
      final env = validPlanArguments();
      final plan = env;
      plan['id'] = id;
      ((((plan['blocks'] as List)[1] as Map)['items'] as List)[0]
              as Map)['workSeconds'] =
          figure4Seconds;
      return env;
    }

    Future<void> dismissSnack(WidgetTester tester) async {
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    }

    Future<void> backAndReopen(
      WidgetTester tester,
      void Function() edit,
    ) async {
      await tester.tap(find.bySemanticsLabel('返回').first);
      await tester.pumpAndSettle();
      edit();
      await tester.pumpAndSettle();
      await openCoach(tester);
    }

    testWidgets('F25-2 模型两轮给同一 plan id：第二张卡未保存，保存/开练都是新剂量', (tester) async {
      final store = await pumpApp(
        tester,
        service(
          fake: uc.FakeLlmClient([
            toolResponse(arguments: planWithId('plan-1', 40)),
            toolResponse(arguments: planWithId('plan-1', 25)),
          ]),
        ),
      );
      await openCoach(tester);
      await say(tester, '睡前 12 分钟');
      await tapIn(tester, inMsg(1, 'coach-save'), 'coach-list');
      await dismissSnack(tester);
      await say(tester, '拉伸短一点');
      expect(textInMsg(3, '保存为自定义训练组'), findsOneWidget);
      expect(textInMsg(3, '每侧 25 秒 × 2 组'), findsOneWidget);
      await tapIn(tester, inMsg(3, 'coach-start'), 'coach-list');
      final player = tester.widget<HipPlayerPage>(find.byType(HipPlayerPage));
      expect(player.plan.steps[2].kitDose.seconds, 25);
      await tester.tap(find.byKey(const ValueKey('close')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('close-confirm')));
      await tester.pumpAndSettle();
      await tapIn(tester, inMsg(3, 'coach-save'), 'coach-list');
      expect(store.customRoutines, hasLength(2));
      expect(store.customRoutines.last.steps[2].seconds, 25);
      expect(textInMsg(1, '已保存到「我的」'), findsOneWidget);
      expect(textInMsg(3, '已保存到「我的」'), findsOneWidget);
    });

    testWidgets('F25-2 预设 template-* 多轮：每张卡各自保存', (tester) async {
      final store = await pumpApp(tester, service());
      await openCoach(tester);
      await say(tester, '睡前放松');
      await tapIn(tester, inMsg(1, 'coach-save'), 'coach-list');
      await dismissSnack(tester);
      await say(tester, '睡前再来一组');
      expect(textInMsg(3, '保存为自定义训练组'), findsOneWidget);
      await tapIn(tester, inMsg(3, 'coach-save'), 'coach-list');
      expect(store.customRoutines, hasLength(2));
      expect(store.customRoutines.map((r) => r.fromRoutine), ['B', 'B']);
    });

    testWidgets('F25-3 已保存组被编辑（动作与剂量）：卡片展示与开练一致', (tester) async {
      final store = await pumpApp(
        tester,
        service(fake: uc.FakeLlmClient([toolResponse()])),
      );
      await openCoach(tester);
      await say(tester, '睡前 12 分钟');
      await tapCard(tester, 'coach-save');
      final g = store.customRoutines.single;
      await backAndReopen(tester, () {
        store.saveCustomRoutine(
          g.copyWith(
            steps: [const CustomStep('n-windshield', reps: 12), g.steps[2]],
          ),
        );
      });
      expect(inList('coach-row-1'), findsOneWidget);
      expect(inList('coach-row-2'), findsNothing);
      expect(find.text('左右交替 12 次'), findsOneWidget);
      expect(find.textContaining('2 个动作 · 约'), findsOneWidget);
      await tapCard(tester, 'coach-start');
      final player = tester.widget<HipPlayerPage>(find.byType(HipPlayerPage));
      expect(player.plan.steps.map((s) => s.drill.id), [
        'n-windshield',
        's-figure4',
      ]);
      expect(player.plan.steps.first.kitDose.reps, 12);
    });

    testWidgets('F25-4 删除已保存组后：原计划可重新保存且内容正确', (tester) async {
      final store = await pumpApp(
        tester,
        service(fake: uc.FakeLlmClient([toolResponse()])),
      );
      await openCoach(tester);
      await say(tester, '睡前 12 分钟');
      await tapCard(tester, 'coach-save');
      final g = store.customRoutines.single;
      await backAndReopen(tester, () => store.deleteCustomRoutine(g.id));
      expect(store.customRoutines, isEmpty);
      expect(find.text('保存为自定义训练组'), findsOneWidget);
      await tapCard(tester, 'coach-save');
      expect(store.customRoutines, hasLength(1));
      final again = store.customRoutines.single;
      expect(again.name, '睡前开胯 12 分钟');
      expect(
        again.steps.map((s) => s.toJson()),
        g.steps.map((s) => s.toJson()),
      );
      expect(find.text('已保存到「我的」'), findsOneWidget);
    });

    testWidgets('F25-5 重试退避中停止：立即结束、无第二次请求、不回落、恢复输入', (tester) async {
      var calls = 0;
      var sleeping = false;
      final gate = Completer<void>();
      final client = uc.OpenAiCompatibleClient(
        config: const uc.LlmConfig(
          baseUrl: 'https://gw.example.com/v1/',
          model: 'm',
          maxRetries: 2,
        ),
        sleep: (_) {
          sleeping = true;
          return gate.future;
        },
        httpClient: MockClient((_) async {
          calls++;
          return http.Response('limited', 429, headers: {'retry-after': '30'});
        }),
      );
      final usage = CoachUsageStore();
      final coach = CoachService(
        config: const CoachConfig(appKey: 'test'),
        content: content,
        client: client,
        usage: usage,
        storage: MemoryStorage(),
        readAsset: readAsset,
      );
      await pumpApp(tester, coach);
      await openCoach(tester);
      await tester.enterText(inList('coach-input'), '睡前开胯');
      await tester.tap(inList('coach-send'));
      for (var i = 0; i < 20 && !sleeping; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(sleeping, isTrue);
      expect(inList('coach-thinking'), findsOneWidget);
      await tester.tap(inList('coach-stop'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(inList('coach-thinking'), findsNothing);
      expect(calls, 1);
      expect(inList('coach-msg-1'), findsNothing); // 不追加回答
      expect(inList('coach-badge-preset'), findsNothing); // 不回落
      final field = tester.widget<TextField>(inList('coach-input'));
      expect(field.controller!.text, '睡前开胯');
      expect(field.enabled ?? true, isTrue);
      expect(usage.records.single.outcome, uc.CallOutcome.cancelled);
    });

    testWidgets('设置里显示累计调用次数和 token', (tester) async {
      final usage = CoachUsageStore();
      await pumpApp(
        tester,
        service(fake: uc.FakeLlmClient([toolResponse()]), usage: usage),
      );
      await openCoach(tester);
      await say(tester, '睡前 12 分钟');
      await tester.tap(find.bySemanticsLabel('返回').first);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('tab-2')));
      await tester.pumpAndSettle();
      final panel = inList('coach-usage');
      await tester.scrollUntilVisible(
        panel,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        find.descendant(of: panel, matching: find.textContaining('累计调用 1 次')),
        findsOneWidget,
      );
    });

    testWidgets('非中文界面不显示入口', (tester) async {
      late bool zh;
      late bool en;
      await tester.pumpWidget(
        Localizations(
          locale: const Locale('en'),
          delegates: const [DefaultWidgetsLocalizations.delegate],
          child: Builder(
            builder: (context) {
              en = aiCoachAvailable(context);
              return const SizedBox();
            },
          ),
        ),
      );
      await tester.pumpWidget(
        Localizations(
          locale: const Locale('zh'),
          delegates: const [DefaultWidgetsLocalizations.delegate],
          child: Builder(
            builder: (context) {
              zh = aiCoachAvailable(context);
              return const SizedBox();
            },
          ),
        ),
      );
      expect(en, isFalse);
      expect(zh, isTrue);
    });

    for (final dark in [false, true]) {
      testWidgets('360 宽 + 1.3 倍字号${dark ? '（深色）' : '（浅色）'}不溢出', (
        tester,
      ) async {
        await pumpApp(
          tester,
          service(fake: uc.FakeLlmClient([toolResponse()])),
          size: const Size(360, 740),
          textScale: 1.3,
          dark: dark,
        );
        expect(tester.takeException(), isNull);
        await openCoach(tester);
        await say(tester, '睡前 12 分钟，开开胯');
        expect(inList('coach-plan-card'), findsOneWidget);
        await tapCard(tester, 'coach-save');
        expect(tester.takeException(), isNull);
      });
    }
  });
}
