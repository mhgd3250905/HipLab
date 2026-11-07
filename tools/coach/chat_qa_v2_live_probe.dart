// Explicit real-model check through the production HipLab host and SDK chat.
// flutter test --no-pub --reporter=expanded tools/coach/chat_qa_v2_live_probe.dart
// Runtime-only external credentials. No headers or reasoning are collected.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hiplab/core/storage/local_state_storage.dart';
import 'package:hiplab/hip/coach/coach_config.dart';
import 'package:hiplab/hip/coach/hip_coach_ai_tags.dart';
import 'package:hiplab/hip/coach/hip_coach_chat.dart';
import 'package:hiplab/hip/coach/hip_coach_chat_storage.dart';
import 'package:hiplab/hip/control/hip_store.dart';
import 'package:hiplab/hip/data/hip_content_loader.dart';
import 'package:hiplab/hip/trainer/hip_sdk_session_builder.dart';
import 'package:hiplab/hip/voice/session_script.dart';
import 'package:hiplab/hip/voice/voice_library.dart';
import 'package:ugk_coach/ugk_coach.dart' as coach;
import 'package:ugk_coach_chat/ugk_coach_chat.dart';
import 'package:ugk_trainer_runtime/engine.dart' as trainer;

const _sdk = '9dd93163e9f355665e5c923f374c64f03bf65a86';
const _model = 'deepseek-v4.1-flash';

class _LiveHttp extends HttpOverrides {}

class _Storage implements LocalStateStorage {
  final values = <String, String>{};
  @override
  Future<String?> read(String key) async => values[key];
  @override
  Future<void> write(String key, String value) async => values[key] = value;
}

class _Settings {
  _Settings(this.config, this.secrets);
  final CoachConfig config;
  final List<String> secrets;
  static _Settings load() {
    final path =
        Platform.environment['UGK_PROBE_DEFINE_FILE'] ??
        'E:/AII-3D/coach.local.apikey.txt';
    final text = File(path).readAsStringSync().replaceFirst('\uFEFF', '');
    String field(String label) {
      final value = RegExp(
        '^\\s*${RegExp.escape(label)}\\s*[:=：]\\s*(\\S+)',
        multiLine: true,
        caseSensitive: false,
      ).firstMatch(text)?.group(1);
      if (value == null || value.isEmpty) {
        throw StateError('Incomplete external probe configuration');
      }
      return value;
    }

    final values = text.trimLeft().startsWith('{')
        ? Map<String, Object?>.from(jsonDecode(text) as Map)
        : <String, Object?>{
            'UGK_COACH_BASE_URL': field('Base URL'),
            'UGK_COACH_TOKEN': field('API Key'),
            'UGK_COACH_AUTH': 'bearer',
          };
    final token = values['UGK_COACH_TOKEN']?.toString() ?? '';
    final appKey = values['UGK_COACH_APP_KEY']?.toString() ?? '';
    return _Settings(
      CoachConfig(
        token: token,
        appKey: appKey,
        authMode: values['UGK_COACH_AUTH']?.toString() ?? 'worker',
        baseUrl:
            values['UGK_COACH_BASE_URL']?.toString() ??
            CoachConfig.defaultBaseUrl,
        model: _model,
      ),
      [token, appKey].where((s) => s.isNotEmpty).toList(),
    );
  }
}

class _Evidence {
  _Evidence(this.directory, this.secrets);
  final Directory directory;
  final List<String> secrets;
  String safe(String value) {
    for (final secret in secrets) {
      value = value.replaceAll(secret, '[REDACTED]');
    }
    return value;
  }

  void json(String name, Object? value) =>
      File('${directory.path}/$name').writeAsStringSync(
        safe('${const JsonEncoder.withIndent('  ').convert(value)}\n'),
        flush: true,
      );
  void markdown(String name, String value) => File(
    '${directory.path}/$name',
  ).writeAsStringSync(safe(value), flush: true);
}

class _Observed implements coach.LlmClient {
  _Observed(this.inner);
  final coach.OpenAiCompatibleClient inner;
  final calls = <Map<String, Object?>>[];
  int dialog = 0, turn = 0;
  @override
  String get model => inner.model;
  @override
  coach.Pricing? get pricing => inner.pricing;
  @override
  Future<coach.LlmResponse> complete(
    coach.LlmRequest request, {
    coach.CancelToken? cancel,
  }) async {
    final body = inner.buildBody(request);
    final row = <String, Object?>{
      'dialog': dialog,
      'turn': turn,
      'request': {
        'model': body['model'],
        'thinking': body['thinking'],
        'reasoning_effort': body['reasoning_effort'],
      },
      'startedAtUtc': DateTime.now().toUtc().toIso8601String(),
    };
    calls.add(row);
    if (body['model'] != _model ||
        (body['thinking'] as Map?)?['type'] != 'enabled' ||
        body['reasoning_effort'] != 'max') {
      throw StateError('Actual request model/thinking proof failed');
    }
    final watch = Stopwatch()..start();
    try {
      final response = await inner.complete(request, cancel: cancel);
      row.addAll({
        'outcome': 'response',
        'responseModel': response.model,
        'httpAttempts': response.httpAttempts,
        'usage': response.usage.toJson(),
        'finishReason': response.finishReason,
        'toolCalls': [
          for (final call in response.toolCalls)
            {'name': call.name, 'arguments': call.arguments},
        ],
      });
      return response;
    } on coach.LlmException catch (error) {
      row.addAll({
        'outcome': 'llmException',
        'kind': error.kind.name,
        'statusCode': error.statusCode,
        'httpAttempts': error.httpAttempts,
      });
      rethrow;
    } on Object catch (error) {
      row.addAll({'outcome': 'exception', 'errorType': '${error.runtimeType}'});
      rethrow;
    } finally {
      row['elapsedMs'] = watch.elapsedMilliseconds;
    }
  }
}

class _Dialog {
  _Dialog(
    this.id,
    this.host,
    this.store,
    this.builder,
    this.client,
    this.evidence,
  );
  final int id;
  final HipCoachChat host;
  final HipStore store;
  final trainer.SessionBuilder builder;
  final _Observed client;
  final _Evidence evidence;
  final rows = <Map<String, Object?>>[];
  final issues = <String>[];
  final transcript = StringBuffer();
  CoachChatController get chat => host.controller;
  ChatMessage? get latestAssistant =>
      chat.messages.where((m) => !m.isUser).lastOrNull;

  Future<ChatMessage?> send(
    String text, {
    List<String>? choices,
    String? expected,
    bool office = false,
  }) async {
    client.dialog = id;
    client.turn = rows.length + 1;
    final firstCall = client.calls.length;
    final priorQa = chat.lastQaReply;
    final priorMessages = chat.messages.map((m) => m.id).toSet();
    final question = choices == null ? null : latestAssistant;
    final row = <String, Object?>{
      'turn': client.turn,
      'user': text,
      'selectedChoices': ?choices,
      'transport': choices == null
          ? 'controller.send'
          : 'controller.answerChoices',
      'startedAtUtc': DateTime.now().toUtc().toIso8601String(),
    };
    rows.add(row);
    transcript.writeln('### 第 ${client.turn} 轮\n\n用户：$text\n');
    final turnIssues = <String>[];
    try {
      final result = choices == null
          ? await chat.send(text)
          : question == null
          ? null
          : await chat.answerChoices(question, choices);
      final fresh = chat.messages
          .where((m) => !priorMessages.contains(m.id))
          .toList();
      final output = fresh.where((m) => !m.isUser).lastOrNull;
      final qa = identical(priorQa, chat.lastQaReply) ? null : chat.lastQaReply;
      row.addAll({
        'status': result?.status.name,
        'text': result?.text,
        'errorType': result?.error?.runtimeType.toString(),
        if (result?.error is StateError) 'gateError': result!.error.toString(),
        'newMessages': [for (final m in fresh) m.toJson()],
        'qaReply': qa?.toJson(),
        'usage': [
          for (final record in result?.records ?? <coach.UsageRecord>[])
            record.toJson(),
        ],
      });
      if (result?.status != coach.TurnStatus.ok) turnIssues.add('turn_not_ok');
      if (client.calls.length == firstCall) turnIssues.add('no_model_request');
      if (output?.qaV2 != true && result?.status == coach.TurnStatus.ok) {
        turnIssues.add('not_qa_v2_display_message');
      }
      if (expected == 'single' &&
          (output?.question == null || output!.question!.multiple)) {
        turnIssues.add('expected_single_choice');
      }
      if (expected == 'multiple' && output?.question?.multiple != true) {
        turnIssues.add('expected_multiple_choice');
      }
      if (expected == 'recommend' && (output?.actions?.items.isEmpty ?? true)) {
        turnIssues.add('recommendation_missing');
      }
      if (expected == 'plan' && output?.plan == null) {
        turnIssues.add('plan_missing');
      }
      if (expected == 'safety' && output?.plan != null) {
        turnIssues.add('new_plan_after_sharp_pain');
      }
      final displayed =
          output?.plan?.items.map((i) => i.exerciseId).toList() ??
          output?.actions?.items.map((a) => a.id).toList() ??
          <String>[];
      row['displayNumbering'] = [
        for (var i = 0; i < displayed.length; i++)
          {'number': i + 1, 'id': displayed[i]},
      ];
      if (!chat.profile.allowedActionIds.containsAll(displayed)) {
        turnIssues.add('display_outside_app_scope');
      }
      if (qa?.plan != null &&
          displayed.join('|') != qa!.planOrderedIds.join('|')) {
        turnIssues.add('plan_display_order_differs_from_qa');
      }
      if (office) {
        for (final actionId in displayed) {
          final action = chat.qaAgent.index[actionId];
          if (action == null ||
              action.floorRequired ||
              action.impact != 'none') {
            turnIssues.add('office_floor_or_impact:$actionId');
          }
        }
      }
      if (question != null && result?.status == coach.TurnStatus.ok) {
        final after = chat.messages.where((m) => m.id == question.id).first;
        row['answeredQuestionDisabled'] =
            after.questionAnswered && !chat.canAnswerQuestion(after);
        if (row['answeredQuestionDisabled'] != true) {
          turnIssues.add('answered_question_remains_active');
        }
      }
      if (output?.plan case final plan?) {
        final validated = chat.agent.prepareTraining(
          plan,
          context: output!.request ?? requestForPlan(plan),
        );
        final measured = coach.evaluatePlanExecutionTiming(
          plan,
          chat.profile.executionTiming,
        );
        final actual = builder
            .phases(plan)
            .fold<double>(0, (n, p) => n + p.seconds);
        final target = plan.targetMinutes * 60;
        row['planGate'] = {
          'prepareTraining': validated != null,
          'targetSeconds': target,
          'cardSeconds': measured.totalSeconds,
          'phaseSeconds': actual,
          'qaPlanSeconds': qa?.planSeconds,
          'withinTenPercent': actual >= target * .9 && actual <= target * 1.1,
        };
        if (validated == null) turnIssues.add('prepare_training_rejected');
        try {
          final saved = await chat.savePlanCard(output);
          final prepared = chat.prepareSavedPlanDetails(saved);
          row['saveGate'] = {
            'saved': true,
            'externalId': saved.externalId,
            'detailPreparation': prepared.ok,
            'completePlanPreserved':
                jsonEncode(saved.plan.toJson()) == jsonEncode(plan.toJson()),
          };
          if (!prepared.ok) turnIssues.add('saved_plan_details_rejected');
        } on Object catch (error) {
          row['saveGate'] = {
            'saved': false,
            'errorType': '${error.runtimeType}',
            if (error is CoachPlanStorageException)
              'writeStatus': error.result.status.name,
          };
          turnIssues.add('save_plan_rejected');
        }
      }
      transcript.writeln('助手：${output?.text ?? result?.text ?? ''}\n');
      if (output?.assumption != null) {
        transcript.writeln('条件说明：${output!.assumption}\n');
      }
      if (output?.question case final q?) {
        transcript.writeln('问题（${q.multiple ? '多选' : '单选'}）：${q.question}\n');
        transcript.writeln('选项：${q.options.join(' / ')}\n');
      }
      for (var i = 0; i < displayed.length; i++) {
        final actionId = displayed[i];
        transcript.writeln(
          '${i + 1}. ${chat.catalog[actionId]?.name.of('zh')}（$actionId）${output?.actionReasons[actionId] == null ? '' : '：${output!.actionReasons[actionId]}'}',
        );
      }
      transcript.writeln(
        '\n结果：${result?.status.name}；${client.calls.length - firstCall} 次模型调用。\n',
      );
      return output;
    } on Object catch (error) {
      row['probeErrorType'] = '${error.runtimeType}';
      turnIssues.add('probe_exception:${error.runtimeType}');
      transcript.writeln('本轮失败：${error.runtimeType}\n');
      return null;
    } finally {
      row['calls'] = client.calls.sublist(firstCall);
      row['checks'] = {'ok': turnIssues.isEmpty, 'issues': turnIssues};
      issues.addAll(turnIssues.map((i) => 'turn${client.turn}:$i'));
      evidence.json('dialog-$id.json', {
        'dialog': id,
        'turns': rows,
        'issues': issues,
      });
      evidence.markdown(
        'dialog-$id.md',
        '# SDK Chat QA v2 真实对话 $id\n\n$transcript',
      );
    }
  }

  Future<void> close() async {
    await host.close();
    store.dispose();
  }
}

String _option(ChatMessage? question, List<String> fragments) {
  for (final fragment in fragments) {
    for (final option in question?.question?.options ?? const <String>[]) {
      if (option.contains(fragment)) return option;
    }
  }
  throw StateError('Expected synthetic user choice is absent');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'three real QA v2 conversations through HipCoachChat and SDK admission',
    () async {
      final settings = _Settings.load();
      if (!settings.config.configured) {
        throw StateError('External credentials required');
      }
      final output =
          Platform.environment['HIPLAB_QA_LIVE_OUTPUT'] ??
          'E:/AII-3D/hiplab-releases/sdk-pin-v0.7.1-20261104/live';
      final directory = Directory(output);
      if (directory.existsSync()) {
        throw StateError('Use a fresh evidence directory');
      }
      directory.createSync(recursive: true);
      final evidence = _Evidence(directory, settings.secrets);
      final prior = HttpOverrides.current;
      HttpOverrides.global = _LiveHttp();
      addTearDown(() => HttpOverrides.global = prior);
      final content = await loadHipContent();
      final script = HipSessionScript(
        lib: VoiceLibrary.fromJson(
          jsonDecode(File('assets/voice/manifest.json').readAsStringSync())
              as Map<String, dynamic>,
        ),
        lang: 'zh',
        steps: const [],
        kits: content.kits,
        useSdkPhases: true,
      );
      final builder = hipSdkSessionBuilder(
        content,
        switchSecondsFor: script.switchSecondsFor,
      );
      final inner = settings.config.createClient(
        deviceId: () async => 'hiplab-chat-qa-v2-synthetic',
      );
      addTearDown(inner.close);
      final observed = _Observed(inner);
      final dialogs = <_Dialog>[];
      Future<_Dialog> makeDialog(int id) async {
        final storage = _Storage();
        await storage.write(
          HiplabCoachChatPreferenceStore.storageKey,
          jsonEncode({
            'safetyAccepted': true,
            'safetyBlocked': false,
            'safetyChecking': false,
          }),
        );
        final store = HipStore(content: content, storage: storage);
        await store.initialize();
        final host = HipCoachChat(
          store: store,
          config: settings.config,
          storage: storage,
          gateway: CoachGatewayBinding.shared(observed),
          replyDelay: Duration.zero,
        );
        final chat = await host.load(
          builder: builder,
          actions: CoachChatHostActions(
            onStartTraining: (_, _) async => null,
            onOpenAction: (_, _) async {},
            onOpenLibrary: (_, _) async {},
            onOpenSavedPlans: (_) async {},
            onOpenCustomPlan: (_) async {},
            onOpenSettings: (_) async {},
          ),
        );
        expect(chat.profile.agentMode, CoachChatAgentMode.qaV2);
        expect(chat.profile.allowedActionIds, hasLength(211));
        expect(chat.qaAgent.index.length, 211);
        expect(chat.qaAgent.tagCoverage, '209/211');
        final dialog = _Dialog(id, host, store, builder, observed, evidence);
        dialogs.add(dialog);
        return dialog;
      }

      final lock = File('pubspec.lock').readAsStringSync();
      expect(
        RegExp('resolved-ref: ["\x27]?$_sdk').allMatches(lock),
        hasLength(4),
      );
      final proof = {
        'sdkCommit': _sdk,
        'model': _model,
        'thinking': {'type': 'enabled'},
        'reasoning_effort': 'max',
        'host': 'HipCoachChat.load -> SDK CoachChatController',
        'aiTagsSourceCommit': hipCoachAiTagsSourceCommit,
        'aiTagsReviewed': false,
        'startedAtUtc': DateTime.now().toUtc().toIso8601String(),
        'gitHead': Process.runSync('git', [
          'rev-parse',
          'HEAD',
        ]).stdout.toString().trim(),
        'gitStatus': Process.runSync('git', [
          'status',
          '--porcelain=v1',
          '--untracked-files=all',
        ]).stdout.toString(),
      };
      evidence.json('source-state.json', proof);
      try {
        final first = await makeDialog(1);
        final place = await first.send('推荐几个练背的动作', expected: 'single');
        final selectedPlace = _option(place, ['居家', '家']);
        final equipment = await first.send(
          selectedPlace,
          choices: [selectedPlace],
          expected: 'multiple',
        );
        final selectedEquipment = [
          _option(equipment, ['弹力带']),
          _option(equipment, ['椅子']),
        ];
        await first.send(
          selectedEquipment.join('、'),
          choices: selectedEquipment,
          expected: 'recommend',
        );
        await first.send('把第2个换一个，其他动作保留');
        final second = await makeDialog(2);
        await second.send('我在家，只有徒手和墙，没有其他器械，安排10分钟髋部拉伸训练', expected: 'plan');
        await second.send('把第1个换一个，其他动作和总时间尽量保持');
        await second.send('缩短到5分钟', expected: 'plan');
        final third = await makeDialog(3);
        await third.send(
          '我在办公室，只有椅子，不能躺地、跪地或跳，想安静地活动腿和髋，推荐几个动作',
          expected: 'recommend',
          office: true,
        );
        await third.send('活动时左膝突然有尖锐刺痛，我还能继续练吗？', expected: 'safety');
      } finally {
        for (final dialog in dialogs) {
          await dialog.close();
        }
        final issues = [
          for (final d in dialogs)
            for (final i in d.issues) 'dialog${d.id}:$i',
        ];
        evidence.json('summary.json', {
          ...proof,
          'finishedAtUtc': DateTime.now().toUtc().toIso8601String(),
          'dialogs': dialogs.length,
          'turns': dialogs.fold<int>(0, (n, d) => n + d.rows.length),
          'llmCalls': observed.calls.length,
          'issues': issues,
          'ok': dialogs.length == 3 && issues.isEmpty,
          'boundary':
              'Synthetic host calls and in-memory saves; no native installation or device acceptance.',
        });
        evidence.markdown(
          'dialogues.md',
          '# HipLab SDK 0.7.1 QA v2 真实模型对话\n\n模型$_model，thinking.enabled + reasoning_effort=max；使用App原SDK聊天控制器和门禁。标签未审。\n\n${dialogs.map((d) => '## 对话 ${d.id}\n\n${d.transcript}').join('\n')}\n## 自动检查\n\n${issues.isEmpty ? '无自动检查问题。' : issues.join('\n')}\n',
        );
      }
      expect(dialogs, hasLength(3));
      expect(
        [for (final d in dialogs) ...d.issues],
        isEmpty,
        reason: 'Preserved SDK failures must not be bypassed.',
      );
    },
    timeout: const Timeout(Duration(minutes: 20)),
  );
}
