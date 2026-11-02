// Explicit real-model probe; outside the offline test suite. No device access.
// Run with flutter test tools/coach/chat_sdk_live_probe.dart and an external
// UGK_PROBE_DEFINE_FILE or UGK_COACH_* environment. Never pass secrets in source.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hiplab/core/storage/local_state_storage.dart';
import 'package:hiplab/hip/coach/coach_config.dart';
import 'package:hiplab/hip/coach/hip_coach_chat.dart';
import 'package:hiplab/hip/coach/hip_coach_chat_storage.dart';
import 'package:hiplab/hip/control/hip_store.dart';
import 'package:hiplab/hip/data/hip_content_loader.dart';
import 'package:hiplab/hip/trainer/hip_trainer_plan.dart';
import 'package:hiplab/hip/voice/session_script.dart';
import 'package:hiplab/hip/voice/voice_library.dart';
import 'package:ugk_coach/ugk_coach.dart' as coach;
import 'package:ugk_coach_chat/ugk_coach_chat.dart';
import 'package:ugk_trainer_runtime/engine.dart' as trainer;

const _sdk = '7d9be56a6c02b7a28e3d5d5cd9f6c3f1a23ac723';
const _inputs = ['在家拉伸髋部 10 分钟', '推荐几个拉大腿内侧的动作', '换一套，缩到 5 分钟', '练一下胸肌'];

class _Storage implements LocalStateStorage {
  final values = <String, String>{};
  @override
  Future<String?> read(String key) async => values[key];
  @override
  Future<void> write(String key, String value) async => values[key] = value;
}

class _LiveHttp extends HttpOverrides {}

class _Settings {
  _Settings(this.values);
  final Map<String, Object?> values;
  String read(String name, [String fallback = '']) =>
      Platform.environment[name] ?? values[name]?.toString() ?? fallback;

  static _Settings load() {
    const definedFile = String.fromEnvironment('UGK_PROBE_DEFINE_FILE');
    final path = Platform.environment['UGK_PROBE_DEFINE_FILE'] ?? definedFile;
    if (path.isEmpty) return _Settings(const {});
    final text = File(path).readAsStringSync().replaceFirst('\uFEFF', '');
    if (text.trimLeft().startsWith('{')) {
      return _Settings(Map<String, Object?>.from(jsonDecode(text) as Map));
    }
    // Reuse the existing labelled test-gateway file, without another plaintext
    // credential copy. Only its values enter the concrete client.
    String field(String label) {
      final match = RegExp(
        '^\\s*${RegExp.escape(label)}\\s*[:=：]\\s*(\\S+)',
        caseSensitive: false,
        multiLine: true,
      ).firstMatch(text);
      if (match == null) throw StateError('Incomplete external probe settings');
      return match.group(1)!;
    }

    return _Settings({
      'UGK_COACH_BASE_URL': field('Base URL'),
      'UGK_COACH_MODEL': field('Model'),
      'UGK_COACH_TOKEN': field('API Key'),
      'UGK_COACH_AUTH': 'bearer',
    });
  }

  CoachConfig get config => CoachConfig(
    appKey: read('UGK_COACH_APP_KEY'),
    token: read('UGK_COACH_TOKEN'),
    authMode: read('UGK_COACH_AUTH', 'worker'),
    baseUrl: read('UGK_COACH_BASE_URL', CoachConfig.defaultBaseUrl),
    model: read('UGK_COACH_MODEL', CoachConfig.defaultModel),
  );
}

class _Evidence {
  _Evidence(this.directory, CoachConfig config)
    : _secrets = [
        config.token,
        config.appKey,
      ].where((s) => s.isNotEmpty).toList();
  final Directory directory;
  final List<String> _secrets;
  String _redact(String value) {
    for (final secret in _secrets) {
      value = value.replaceAll(secret, '[REDACTED]');
    }
    return value;
  }

  void write(String name, Object? value) {
    final file = File('${directory.path}/$name');
    if (file.existsSync()) throw StateError('Preserve previous probe evidence');
    final text = '${const JsonEncoder.withIndent('  ').convert(value)}\n';
    file.writeAsStringSync(_redact(text), flush: true);
  }
}

/// Observes the same concrete client used by the SDK. Request/response bodies
/// are synthetic test data; authentication headers are never collected.
class _Observed implements coach.OpenAiCompatibleClient {
  _Observed(this.inner, this.evidence);
  final coach.OpenAiCompatibleClient inner;
  final _Evidence evidence;
  final calls = <Map<String, Object?>>[];
  final receipts = <String, Map<String, Object?>>{};
  final _tools = <String, String>{};
  int turn = 0;
  @override
  String get model => inner.model;
  @override
  coach.Pricing? get pricing => inner.pricing;
  @override
  coach.LlmConfig get config => inner.config;
  @override
  coach.AuthProvider get auth => inner.auth;
  @override
  Map<String, Object?> buildBody(coach.LlmRequest request) =>
      inner.buildBody(request);
  @override
  void close() => inner.close();

  void _observeReceipts(List<coach.LlmMessage> messages) {
    for (final message in messages) {
      final id = message.toolCallId;
      if (message.role != coach.LlmRole.tool ||
          id == null ||
          receipts.containsKey(id)) {
        continue;
      }
      Object? content;
      try {
        content = jsonDecode(message.content);
      } on FormatException {
        content = message.content;
      }
      receipts[id] = {'id': id, 'tool': _tools[id], 'content': content};
    }
  }

  @override
  Future<coach.LlmResponse> complete(
    coach.LlmRequest request, {
    coach.CancelToken? cancel,
  }) async {
    _observeReceipts(request.messages);
    final watch = Stopwatch()..start();
    final number = calls.length + 1;
    final row = <String, Object?>{
      'call': number,
      'turn': turn,
      'startedAtUtc': DateTime.now().toUtc().toIso8601String(),
      'bodyBytes': utf8.encode(jsonEncode(inner.buildBody(request))).length,
      'bodyBytesMeasurement':
          'utf8(jsonEncode(OpenAiCompatibleClient.buildBody))',
      'request': inner.buildBody(request),
    };
    calls.add(row);
    try {
      final result = await inner.complete(request, cancel: cancel);
      for (final call in result.toolCalls) {
        _tools[call.id] = call.name;
      }
      row.addAll({
        'outcome': 'response',
        'httpAttempts': result.httpAttempts,
        'model': result.model,
        'finishReason': result.finishReason,
        'usage': result.usage.toJson(),
        'usageLimit':
            'SDK normalized usage; zero does not prove provider presence',
        'response': {
          'content': result.content,
          'reasoning': result.reasoning,
          'toolCalls': [
            for (final call in result.toolCalls)
              {'id': call.id, 'name': call.name, 'arguments': call.arguments},
          ],
        },
      });
      return result;
    } on coach.LlmException catch (error) {
      row.addAll({
        'outcome': 'llmException',
        'kind': error.kind.name,
        'statusCode': error.statusCode,
        'httpAttempts': error.httpAttempts,
        'usage': error.usage.toJson(),
        'diagnostic': error.responseDiagnostic?.toJson(),
      });
      rethrow;
    } on Object catch (error) {
      row.addAll({'outcome': 'exception', 'errorType': '${error.runtimeType}'});
      rethrow;
    } finally {
      watch.stop();
      row['elapsedMs'] = watch.elapsedMilliseconds;
      evidence.write('call-${number.toString().padLeft(2, '0')}.json', row);
    }
  }
}

Map<String, Object?> _packageProof() {
  final lock = File('pubspec.lock').readAsStringSync().replaceAll('\r\n', '\n');
  final packages = <String, Object?>{};
  for (final name in [
    'ugk_coach',
    'ugk_coach_ui',
    'ugk_trainer_runtime',
    'ugk_coach_chat',
  ]) {
    final section = RegExp(
      '^  $name:\\n(.*?)(?=^  \\S|\\Z)',
      multiLine: true,
      dotAll: true,
    ).firstMatch(lock)?.group(1);
    final ref = section == null
        ? null
        : RegExp(
            r'resolved-ref: ["\x27]?([0-9a-f]{40})',
          ).firstMatch(section)?.group(1);
    packages[name] = {'resolvedRef': ref, 'matchesExpected': ref == _sdk};
    if (ref != _sdk) throw StateError('SDK pin proof failed for $name');
  }
  final legacyPresent = RegExp(
    r'^  ugk_trainer:',
    multiLine: true,
  ).hasMatch(lock);
  if (legacyPresent) {
    throw StateError('Legacy Trainer asset dependency is present');
  }
  final head = Process.runSync('git', ['rev-parse', 'HEAD']);
  final dirty = Process.runSync('git', [
    '--no-optional-locks',
    'status',
    '--short',
  ]);
  return {
    'expectedSdkCommit': _sdk,
    'packages': packages,
    'legacyTrainerPresent': legacyPresent,
    'gitHead': head.exitCode == 0 ? head.stdout.toString().trim() : null,
    'workingTreeStatus': dirty.exitCode == 0 ? dirty.stdout.toString() : null,
  };
}

Map<String, Object?> _metrics(List<Map<String, Object?>> calls) => {
  'llmCalls': calls.length,
  'httpAttempts': calls.every((c) => c['httpAttempts'] is int)
      ? calls.fold<int>(0, (sum, c) => sum + (c['httpAttempts'] as int))
      : null,
  'usage': {
    for (final key in [
      'promptTokens',
      'completionTokens',
      'cachedTokens',
      'reasoningTokens',
    ])
      key: {
        'sdkNormalizedTotal': calls.fold<int>(
          0,
          (sum, c) =>
              sum + (((c['usage'] as Map?)?[key] as num?)?.toInt() ?? 0),
        ),
        'callsWithPositiveValue': calls
            .where((c) => (((c['usage'] as Map?)?[key] as num?) ?? 0) > 0)
            .length,
      },
  },
};

Map<String, Object?> _timing(
  coach.ValidatedPlan validated,
  CoachChatController controller,
  trainer.SessionBuilder builder,
) {
  final plan = validated.plan;
  final measured = coach.evaluatePlanExecutionTiming(
    plan,
    controller.profile.executionTiming,
  );
  final phases = builder.phases(plan);
  final actual = phases.fold<double>(0, (sum, p) => sum + p.seconds);
  final target = plan.targetMinutes * 60;
  final card = measured.totalSeconds;
  final catalog = const coach.PlanDuration().estimateSeconds(
    plan,
    controller.catalog,
  );
  bool within(double seconds) =>
      seconds >= target * .9 - 1e-9 && seconds <= target * 1.1 + 1e-9;
  final manual = phases.where((p) => p.isWork && p.selfPaced).toList();
  final engine = manual.isEmpty
      ? (trainer.SessionEngine(phases)..update(actual + .001))
      : null;
  final visited = engine?.visits.fold<double>(
    0,
    (sum, visit) => sum + visit.seconds,
  );
  return {
    'targetSeconds': target,
    'cardSeconds': card,
    'validatedExecutionSeconds': validated.executionTiming?.totalSeconds,
    'executionIncludingPrepSeconds': actual,
    'catalogEstimateSeconds': catalog,
    'catalogEstimateWithinTolerance': within(catalog.toDouble()),
    'cardWithinTolerance': within(card),
    'executionWithinTolerance': within(actual),
    'sameCallbackAndPlayer': (card - actual).abs() < 1e-9,
    'deliveredTimingMatches':
        validated.executionTiming != null &&
        (validated.executionTiming!.totalSeconds - actual).abs() < 1e-9,
    'isEstimate': measured.containsManualCounting,
    'manualLabel': manual.isEmpty ? null : '估算',
    'manualEstimatedSeconds': manual.fold<double>(
      0,
      (sum, p) => sum + p.seconds,
    ),
    'timedPhaseSeconds': phases
        .where((p) => !p.selfPaced)
        .fold<double>(0, (sum, p) => sum + p.seconds),
    'manualWorkPhases': [
      for (final p in manual)
        {
          'actionId': p.exerciseId,
          'seconds': p.seconds,
          'reps': p.reps,
          'label': '估算',
        },
    ],
    'naturalEngineReplay': engine?.done,
    'engineVisitSeconds': visited,
    'completeTimelineVisited': engine == null
        ? null
        : engine.done && (visited! - actual).abs() < 1e-6,
    'manualEstimateDoesNotExemptNumericGate': true,
    'phases': [
      for (final p in phases)
        {
          'kind': p.kind.name,
          'seconds': p.seconds,
          'actionId': p.exerciseId,
          'itemIndex': p.itemIndex,
          'blockIndex': p.blockIndex,
          'itemInBlock': p.itemInBlock,
          'segmentId': p.segmentId,
          'round': p.round,
          'set': p.set,
          'sets': p.sets,
          'side': p.side?.name,
          'selfPaced': p.selfPaced,
          'reps': p.reps,
          'holdSeconds': p.holdSeconds,
        },
    ],
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'four exact user turns through the HipLab SDK chat host',
    () async {
      final settings = _Settings.load();
      final config = settings.config;
      final output = settings.read(
        'UGK_PROBE_OUTPUT',
        settings.read('HIPLAB_LIVE_OUTPUT'),
      );
      if (!config.configured ||
          output.isEmpty ||
          config.llmConfig.maxRetries != 0) {
        throw StateError(
          'Explicit external credentials and a fresh output directory are required',
        );
      }
      final directory = Directory(output).absolute;
      if (directory.existsSync()) {
        throw StateError('Use a fresh evidence directory');
      }
      directory.createSync(recursive: true);
      final evidence = _Evidence(directory, config);
      evidence.write('package-proof.json', _packageProof());
      final previousHttp = HttpOverrides.current;
      HttpOverrides.global = _LiveHttp();
      addTearDown(() => HttpOverrides.global = previousHttp);
      final storage = _Storage();
      await storage.write(
        HiplabCoachChatPreferenceStore.storageKey,
        jsonEncode({
          'safetyAccepted': true,
          'safetyBlocked': false,
          'safetyChecking': false,
        }),
      );
      final content = await loadHipContent();
      final store = HipStore(content: content, storage: storage);
      await store.initialize();
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
      final observed = _Observed(
        config.createClient(deviceId: () async => 'hiplab-chat-sdk-live-probe'),
        evidence,
      );
      final rawInputs = <Map<String, Object?>>[];
      final runtimeEvents = <Map<String, Object?>>[];
      final host = HipCoachChat(
        store: store,
        config: config,
        storage: storage,
        gateway: CoachGatewayBinding.shared(observed),
        replyDelay: Duration.zero,
        onRawInput: (input) => rawInputs.add({
          'messageId': input.messageId,
          'rawText': input.rawText,
          'sentText': input.sentText,
          'displayLabel': input.displayLabel,
          'questionId': input.questionId,
        }),
        observer: (event, detail) => runtimeEvents.add({
          'event': event,
          'detail': detail is Map
              ? Map<String, Object?>.from(detail)
              : {'type': '${detail.runtimeType}'},
        }),
      );
      final controller = await host.load(
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
      final originalAgent = controller.agent;
      final progress = <Map<String, Object?>>[];
      final subscription = controller.events.listen(
        (event) => progress.add({
          'kind': event.kind.name,
          'step': event.step,
          'path': event.path,
          'status': event.status?.name,
          'reason': event.reason?.name,
          'turnId': event.turnId,
        }),
      );
      final turns = <Map<String, Object?>>[];
      final failures = <String>[];
      coach.ValidatedPlan? firstPlan;
      final watchAll = Stopwatch()..start();
      try {
        expect(observed.calls, isEmpty);
        expect(controller.profile.allowedActionIds, hasLength(45));
        evidence.write(
          'initial-snapshot.json',
          controller.exportSnapshot().toJson(),
        );
        for (final (index, input) in _inputs.indexed) {
          observed.turn = index + 1;
          final firstCall = observed.calls.length;
          final firstEvent = runtimeEvents.length;
          final firstProgress = progress.length;
          final firstDiagnostic =
              controller.agent.contextRequestDiagnostics.length;
          final previousMessages = controller.messages.map((m) => m.id).toSet();
          final priorReceiptIds = observed.receipts.keys.toSet();
          final timer = Stopwatch()..start();
          final result = await controller.send(input);
          timer.stop();
          final messages = controller.messages
              .where((m) => !previousMessages.contains(m.id))
              .toList();
          final problems = <String>[];
          if (!identical(originalAgent, controller.agent)) {
            problems.add('agent_replaced');
          }
          if (result?.status != coach.TurnStatus.ok) {
            problems.add('turn_not_ok');
          }
          if (observed.calls.length == firstCall) {
            problems.add('no_model_request');
          }
          final plan = result?.plan?.plan;
          final ids = plan?.exerciseIds.toSet() ?? <String>{};
          final actions =
              result?.actions?.items.map((a) => a.id).toList() ?? <String>[];
          if (!controller.profile.allowedActionIds.containsAll({
            ...ids,
            ...actions,
          })) {
            problems.add('action_outside_allowlist');
          }
          Map<String, Object?>? timing;
          if (plan != null) {
            timing = _timing(result!.plan!, controller, builder);
            for (final key in [
              'cardWithinTolerance',
              'executionWithinTolerance',
              'sameCallbackAndPlayer',
              'deliveredTimingMatches',
            ]) {
              if (timing[key] != true) problems.add(key);
            }
            if (timing['isEstimate'] == false &&
                timing['completeTimelineVisited'] != true) {
              problems.add('timed_engine_replay_failed');
            }
          }
          if (index == 0 || index == 2) {
            if (plan == null || plan.items.isEmpty) {
              problems.add('plan_missing');
            }
            if (plan?.targetMinutes != (index == 0 ? 10 : 5)) {
              problems.add('wrong_target');
            }
            if (index == 0) firstPlan = result?.plan;
            if (index == 2 &&
                plan != null &&
                firstPlan != null &&
                plan.id == firstPlan.plan.id &&
                result?.plan?.version == firstPlan.version) {
              problems.add('new_plan_version_missing');
            }
          } else if (index == 1) {
            if (plan != null || actions.isEmpty) {
              problems.add('recommendation_card_missing');
            }
          } else {
            // A wholly chest-focused request is outside HipLab's documented
            // specialty. Inspect the SDK's disclosure; do not synthesize a fix.
            final text = messages
                .where((m) => !m.isUser)
                .map((m) => m.text)
                .join('\n');
            if (plan != null) {
              problems.add('whole_out_of_scope_request_delivered_plan');
            }
            if (text.trim().isEmpty || !RegExp('髋|开胯|HipLab').hasMatch(text)) {
              problems.add('scope_explanation_missing');
            }
            if (controller.suggestions.isEmpty &&
                messages.every((m) => m.options.isEmpty)) {
              problems.add('scope_suggestion_missing');
            }
          }
          final events = runtimeEvents.skip(firstEvent).toList();
          final observedTurn = events
              .where((e) => e['event'] == 'chat.turn.result')
              .toList();
          if (observedTurn.length != 1) problems.add('turn_result_event_count');
          final state = controller.agent.sessionState;
          final row = <String, Object?>{
            'turn': index + 1,
            'input': input,
            'elapsedMs': timer.elapsedMilliseconds,
            'status': result?.status.name,
            'turnId': result?.turnId,
            'text': result?.text,
            'errorType': result?.error?.runtimeType.toString(),
            'plan': plan?.toJson(),
            'planVersion': result?.plan?.version,
            'planVersions': plan == null
                ? null
                : [
                    for (final v
                        in state.plans[plan.id] ?? <coach.CoachPlanVersion>[])
                      v.toJson(),
                  ],
            'recommendationIds': actions,
            'executionIds': ids.toList()..sort(),
            'allowlistPassed': controller.profile.allowedActionIds.containsAll({
              ...ids,
              ...actions,
            }),
            'warnings': [
              for (final issue in result?.warnings ?? <coach.PlanIssue>[])
                issue.toJson(),
            ],
            'issues': [
              for (final issue in result?.issues ?? <coach.PlanIssue>[])
                issue.toJson(),
            ],
            'usageRecords': [
              for (final record in result?.records ?? <coach.UsageRecord>[])
                record.toJson(),
            ],
            'metrics': _metrics(observed.calls.skip(firstCall).toList()),
            'calls': observed.calls.skip(firstCall).toList(),
            'observedToolReceipts': [
              for (final entry in observed.receipts.entries)
                if (!priorReceiptIds.contains(entry.key)) entry.value,
            ],
            'receiptVisibility':
                'Only tool bodies actually exposed in subsequent model requests; terminal private receipts are not reconstructed',
            'contextRequests': [
              for (final d in controller.agent.contextRequestDiagnostics.skip(
                firstDiagnostic,
              ))
                d.toJson(),
            ],
            'runtimeEvents': events,
            'progressEvents': progress.skip(firstProgress).toList(),
            'newMessages': [for (final message in messages) message.toJson()],
            'suggestions': controller.suggestions,
            'timing': timing,
            'snapshot': controller.exportSnapshot().toJson(),
            'problems': problems,
            'passed': problems.isEmpty,
          };
          turns.add(row);
          failures.addAll(problems.map((p) => 'turn${index + 1}:$p'));
          evidence.write('turn-${index + 1}.json', row);
        }
        if (rawInputs.map((e) => e['rawText']).join('\n') !=
                _inputs.join('\n') ||
            rawInputs.any((e) => e['rawText'] != e['sentText'])) {
          failures.add('raw_user_input_changed');
        }
      } on Object catch (error) {
        failures.add('probe_exception:${error.runtimeType}');
        rethrow;
      } finally {
        watchAll.stop();
        await subscription.cancel();
        await host.close();
        observed.close();
        store.dispose();
        evidence.write('results.json', {
          'sdkCommit': _sdk,
          'inputs': _inputs,
          'syntheticInput': true,
          'deviceOperated': false,
          'conversationResets': 0,
          'outerRetries': 0,
          'maxHttpRetries': config.llmConfig.maxRetries,
          'gatewayModel': config.model,
          'gatewayAuthMode': config.authMode,
          'elapsedMs': watchAll.elapsedMilliseconds,
          'metrics': _metrics(observed.calls),
          'rawInputEvents': rawInputs,
          'turns': [
            for (final turn in turns)
              {...turn}
                ..remove('snapshot')
                ..remove('calls'),
          ],
          'failures': failures,
          'passed': turns.length == 4 && failures.isEmpty,
        });
      }
      expect(turns, hasLength(4));
      expect(failures, isEmpty);
    },
    timeout: const Timeout(Duration(minutes: 35)),
  );
}
