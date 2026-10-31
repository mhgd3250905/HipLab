// Explicit real-model acceptance probe. Not part of the offline test suite.
// Credentials come from dart defines; logs contain measurements, never headers.
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:hiplab/core/storage/local_state_storage.dart';
import 'package:hiplab/hip/coach/coach_config.dart';
import 'package:hiplab/hip/coach/coach_service.dart';
import 'package:hiplab/hip/coach/usage_store.dart';
import 'package:hiplab/hip/data/hip_content_loader.dart';
import 'package:ugk_coach/ugk_coach.dart' as uc;

import 'coach_v2_native_metrics.dart' show measureCoachPlanTiming;

class _Storage implements LocalStateStorage {
  final values = <String, String>{};
  @override
  Future<String?> read(String key) async => values[key];
  @override
  Future<void> write(String key, String value) async => values[key] = value;
}

class _LiveHttp extends HttpOverrides {}

class _Observed implements uc.LlmClient {
  _Observed(this.inner, this.log);
  final uc.OpenAiCompatibleClient inner;
  final File log;
  final calls = <Map<String, Object?>>[];
  final receipts = <String, Map<String, Object?>>{};
  final tools = <String, String>{};

  @override
  String get model => inner.model;
  @override
  uc.Pricing? get pricing => inner.pricing;

  // Only receipts actually exposed in a subsequent model request are captured.
  // SDK UsageRecord IDs are unrelated to model tool-call IDs; terminal receipt
  // bodies that the public API does not expose are never reconstructed here.
  void observeReceipts(Iterable<uc.LlmMessage> messages) {
    for (final message in messages) {
      final id = message.toolCallId;
      if (message.role != uc.LlmRole.tool ||
          id == null ||
          receipts.containsKey(id)) {
        continue;
      }
      try {
        final parsed = jsonDecode(message.content);
        if (parsed is Map) {
          final receipt = Map<String, Object?>.from(parsed);
          receipts[id] = receipt;
          File('${log.parent.path}/tool-receipts.jsonl').writeAsStringSync(
            '${jsonEncode({'id': id, 'tool': tools[id], 'receipt': receipt})}\n',
            mode: FileMode.append,
            flush: true,
          );
        }
      } on FormatException {
        // File disclosures can be plain text; only structured receipts count.
      }
    }
  }

  @override
  Future<uc.LlmResponse> complete(
    uc.LlmRequest request, {
    uc.CancelToken? cancel,
  }) async {
    observeReceipts(request.messages);
    final watch = Stopwatch()..start();
    final row = <String, Object?>{
      'requestBytes': utf8.encode(jsonEncode(inner.buildBody(request))).length,
      'roles': request.messages.map((m) => m.role.name).toList(),
    };
    calls.add(row);
    try {
      final response = await inner.complete(request, cancel: cancel);
      for (final call in response.toolCalls) {
        tools[call.id] = call.name;
      }
      row.addAll({
        'model': response.model,
        'httpAttempts': response.httpAttempts,
        'tools': response.toolCalls.map((c) => c.name).toList(),
        'toolCalls': [
          for (final call in response.toolCalls)
            {'id': call.id, 'name': call.name, 'arguments': call.arguments},
        ],
        'usage': response.usage.toJson(),
      });
      return response;
    } on uc.LlmException catch (error) {
      row.addAll({
        'errorKind': error.kind.name,
        'statusCode': error.statusCode,
        'httpAttempts': error.httpAttempts,
      });
      rethrow;
    } finally {
      row['elapsedMs'] = watch.elapsedMilliseconds;
      log.writeAsStringSync('${jsonEncode(row)}\n', mode: FileMode.append);
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'HipLab Coach v2: the three requested real-model turns',
    () async {
      const config = CoachConfig.fromEnvironment;
      const output = String.fromEnvironment('HIPLAB_SMOKE_OUTPUT');
      const sdkCommit = String.fromEnvironment('HIPLAB_SMOKE_SDK_COMMIT');
      const trialId = String.fromEnvironment(
        'HIPLAB_SMOKE_TRIAL',
        defaultValue: '1',
      );
      const latencyLimitMs = 20000;
      const callLimit = 8;
      expect(config.baseUrl, 'https://ai.uuugk.win/v1');
      expect(config.model, 'deepseek-flash');
      expect(config.authMode, 'bearer');
      expect(config.token, isNotEmpty);
      expect(config.llmConfig.maxRetries, 0);
      expect(output, isNotEmpty);
      expect(sdkCommit, matches(RegExp(r'^[0-9a-f]{40}$')));
      final lock = File(
        'pubspec.lock',
      ).readAsStringSync().replaceAll('\r\n', '\n');
      for (final name in ['ugk_coach', 'ugk_coach_ui', 'ugk_trainer']) {
        final declaration = RegExp(
          '^  $name:\\n(.*?)(?=^  \\S|\\Z)',
          multiLine: true,
          dotAll: true,
        ).firstMatch(lock)?.group(1);
        expect(declaration, isNotNull);
        expect(
          declaration!
              .split('\n')
              .any(
                (line) =>
                    line.trim().replaceAll('"', '') ==
                    'resolved-ref: $sdkCommit',
              ),
          isTrue,
        );
      }
      final root = Directory(output).absolute..createSync(recursive: true);
      final resultFile = File('${root.path}/results.json');
      expect(
        resultFile.existsSync(),
        isFalse,
        reason: 'Preserve prior live runs.',
      );
      HttpOverrides.global = _LiveHttp();
      final observed = _Observed(
        config.createClient(deviceId: () async => 'hiplab-coach-v2-live-probe'),
        File('${root.path}/requests.jsonl'),
      );
      final service = CoachService(
        config: config,
        content: await loadHipContent(),
        client: observed,
        usage: CoachUsageStore(),
        storage: _Storage(),
      );
      await service.load();
      final controller = service.conversation!;
      final cases = <Map<String, Object?>>[];
      const inputs = ['在家开胯10分钟入门', '推荐几个拉大腿内侧的动作', '换一套，缩短到5分钟'];
      try {
        for (final input in inputs) {
          final start = observed.calls.length;
          final diagnosticsStart =
              controller.agent.contextRequestDiagnostics.length;
          final beforeReceipts = observed.receipts.keys.toSet();
          final watch = Stopwatch()..start();
          final result = await controller.send(input);
          final elapsedMs = watch.elapsedMilliseconds;
          final calls = observed.calls.skip(start).toList();
          final state = controller.agent.sessionState;
          final plan = result?.plan?.plan;
          final versions = plan == null ? null : state.plans[plan.id];
          final latest = versions?.last;
          final check = latest?.check;
          final goal = state.params['goal']?.value;
          final target = state.params['minutes']?.value;
          final targetSec = target is num ? target * 60 : null;
          final estimateSec = plan == null
              ? null
              : const uc.PlanDuration().estimateSeconds(plan, service.catalog);
          final nativeTiming = plan == null
              ? null
              : measureCoachPlanTiming(
                  plan: plan,
                  content: service.content,
                  catalog: service.catalog,
                );
          final actions = result?.actions?.items;
          final bodyTags = goal is Iterable
              ? goal
                    .whereType<String>()
                    .where((s) => s.startsWith('body.'))
                    .toList()
              : <String>[];
          final ids = plan != null
              ? [
                  for (final b in plan.blocks.where(
                    (b) => b.type == uc.BlockType.main,
                  ))
                    for (final i in b.items) i.exerciseId,
                ]
              : [for (final a in actions ?? <uc.ValidatedAction>[]) a.id];
          final bodyHits = ids.where((id) {
            final drill = service.catalog[id]!;
            // Measurement only: SDK ActionTags encodes muscleGroups as body.*,
            // including the catalogue's adductors -> inner_thigh alias.
            final catalogBody = {
              for (final group in drill.muscleGroups)
                'body.${group == 'adductors' ? 'inner_thigh' : group.replaceAll('-', '_')}',
            };
            return bodyTags.any(catalogBody.contains);
          }).length;
          final diagnostic = controller.agent.contextRequestDiagnostics
              .skip(diagnosticsStart)
              .map((d) => d.toJson())
              .toList();
          final toolReceipts = [
            for (final entry in observed.receipts.entries)
              if (!beforeReceipts.contains(entry.key))
                {
                  'id': entry.key,
                  'tool': observed.tools[entry.key],
                  'receipt': entry.value,
                },
          ];
          bool skipped(Map<String, Object?> row) =>
              ((row['receipt'] as Map)['code'] as String? ?? '').startsWith(
                'skipped_after_',
              );
          final rejected = [
            for (final receipt in toolReceipts)
              if ((receipt['receipt'] as Map)['ok'] == false &&
                  !skipped(receipt))
                receipt,
          ];
          final drafts = [
            for (final receipt in toolReceipts)
              if (receipt['tool'] == 'draft_plan' && !skipped(receipt)) receipt,
          ];
          final toolCalls = [
            for (final call in calls) ...call['toolCalls'] as List? ?? [],
          ];
          final anomalies = [
            if (elapsedMs > latencyLimitMs) 'elapsed_over_20s',
            if (calls.length > callLimit) 'calls_over_8',
          ];
          File(
            '${root.path}/session-${cases.length + 1}.json',
          ).writeAsStringSync(
            const JsonEncoder.withIndent(
              '  ',
            ).convert(controller.exportSession().toJson()),
            flush: true,
          );
          final usage = result?.usage ?? uc.TokenUsage.zero;
          final row = <String, Object?>{
            'input': input,
            'elapsedMs': elapsedMs,
            'calls': calls.length,
            'httpAttempts': calls.fold<int>(
              0,
              (n, c) => n + (c['httpAttempts'] as int? ?? 0),
            ),
            'searches': [
              for (final c in calls) ...c['tools'] as List? ?? [],
            ].where((t) => t == 'search_actions').length,
            'maxRequestBytes': calls.fold<int>(
              0,
              (n, c) => math.max(n, c['requestBytes'] as int),
            ),
            'usage': usage.toJson(),
            'totalTokens': usage.totalTokens,
            'cacheHitRatio': usage.promptTokens == 0
                ? 0
                : usage.cachedTokens / usage.promptTokens,
            'rejections': rejected.length,
            'rejectedReceipts': rejected,
            'durationFitRejections': rejected
                .where(
                  (r) => (r['receipt'] as Map)['code'] == 'duration_fit_failed',
                )
                .length,
            'skippedToolCalls': toolReceipts.where(skipped).length,
            'draftCallsRequested': toolCalls
                .where((c) => (c as Map)['name'] == 'draft_plan')
                .length,
            'observedDraftCallsExecuted': drafts.length,
            'observedDraftRegenerations': math.max(0, drafts.length - 1),
            'toolReceipts': toolReceipts,
            'toolReceiptCoverage':
                'Only structured receipts exposed in subsequent model requests; final terminal bodies may be unavailable.',
            'unobservedToolCalls': [
              for (final call in toolCalls)
                if (!observed.receipts.containsKey((call as Map)['id']))
                  {'id': call['id'], 'name': call['name']},
            ],
            'rejectedModelSteps': result?.records
                .where((r) => r.outcome == uc.CallOutcome.rejected)
                .length,
            'durationFitIssueRecords': result?.records
                .where((r) => r.issueCodes.contains('duration_fit_failed'))
                .length,
            'usageRecords': [
              for (final record in result?.records ?? <uc.UsageRecord>[])
                record.toJson(),
            ],
            'performanceAnomaly': anomalies.isNotEmpty,
            'anomalyReasons': anomalies,
            'taskType': state.task?.type,
            'status': result?.status.name,
            'planCard': plan != null,
            'recommendCard': actions != null,
            'question': result?.question?.toJson(),
            'errorType': result?.error?.runtimeType.toString(),
            'targetSeconds': targetSec,
            'estimatedSeconds': estimateSec,
            'nativeTiming': nativeTiming,
            'nativeTotalSeconds': nativeTiming?['nativeTotalSeconds'],
            'nativeDurationErrorRatio':
                nativeTiming?['nativeDurationErrorRatio'],
            'nativeIsEstimate': nativeTiming?['isEstimate'],
            'nativeMeasurementLabel': nativeTiming == null
                ? null
                : nativeTiming['isEstimate'] == true
                ? '估算'
                : '定时回放',
            'nativeEstimateDurationErrorRatio':
                nativeTiming?['nativeEstimateDurationErrorRatio'],
            'nativeWithinTolerance': nativeTiming?['nativeWithinTolerance'],
            'nativeDurationGatePassed':
                nativeTiming?['nativeDurationGatePassed'],
            'manualCountingPhases': nativeTiming?['manualCountingPhases'],
            'durationErrorRatio': estimateSec == null || targetSec == null
                ? null
                : (estimateSec - targetSec) / targetSec,
            'bodyGoals': bodyTags,
            'bodyHits': bodyTags.isEmpty ? null : bodyHits,
            'bodyItems': ids.length,
            'planCheck': check,
            'planVersion': latest?.version,
            'folded': diagnostic.any((d) => d['folded'] == true),
            'contextDiagnostics': diagnostic,
            'requests': calls,
            'state': state.toJson(),
            if (plan != null) 'plan': plan.toJson(),
            if (actions != null) 'actionIds': [for (final a in actions) a.id],
          };
          cases.add(row);
          resultFile.writeAsStringSync(
            const JsonEncoder.withIndent('  ').convert({
              'sdkCommit': sdkCommit,
              'baseUrl': config.baseUrl,
              'model': config.model,
              'auth': config.authMode,
              'maxRetries': config.llmConfig.maxRetries,
              'trialId': trialId,
              'latencyLimitMs': latencyLimitMs,
              'callLimit': callLimit,
              'sameConversation': true,
              'cases': cases,
            }),
            flush: true,
          );
          stdout.writeln(
            'LIVE_CASE ${jsonEncode({
              for (final k in ['input', 'elapsedMs', 'calls', 'searches', 'totalTokens', 'status', 'planCard', 'recommendCard', 'taskType', 'rejections', 'durationFitRejections', 'observedDraftRegenerations', 'estimatedSeconds', 'nativeTotalSeconds', 'nativeMeasurementLabel', 'nativeDurationGatePassed', 'performanceAnomaly']) k: row[k],
            })}',
          );
        }
        expect(cases[0]['planCard'], true);
        expect(cases[1]['recommendCard'], true);
        expect(cases[2]['planCard'], true);
        expect(cases[0]['targetSeconds'], 600);
        expect(cases[2]['targetSeconds'], 300);
        expect((cases[2]['plan'] as Map)['targetMinutes'], 5);
        expect(
          jsonEncode(cases[2]['plan']),
          isNot(jsonEncode(cases[0]['plan'])),
        );
        for (final row in cases) {
          expect(row['status'], 'ok');
          expect(
            row['performanceAnomaly'],
            false,
            reason: 'Over 20s or 8 calls is abnormal.',
          );
          if (row['planCard'] == true) {
            expect(
              (row['durationErrorRatio'] as num).abs(),
              lessThanOrEqualTo(.1),
            );
            expect(
              row['nativeDurationGatePassed'],
              isTrue,
              reason:
                  'Timed execution including prep must fit ±10%; manual counting is reported as an estimate under the user exemption.',
            );
          }
        }
      } finally {
        await service.dispose();
        observed.inner.close();
        HttpOverrides.global = null;
      }
    },
    timeout: const Timeout(Duration(minutes: 20)),
  );
}
