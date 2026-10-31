// Offline replay of already captured live plans. Makes no model requests.
import 'dart:convert';
import 'dart:io';

import 'package:hiplab/hip/coach/plan_mapping.dart';
import 'package:hiplab/hip/domain/hip_models.dart';
import 'package:hiplab/hip/domain/hip_session.dart';
import 'package:hiplab/hip/trainer/hip_trainer_plan.dart';
import 'package:ugk_coach/ugk_coach.dart' as uc;

void main(List<String> args) {
  if (args.length != 2) {
    throw ArgumentError(
      'Expected captured results.json and output JSON paths.',
    );
  }
  final capture = jsonDecode(File(args[0]).readAsStringSync()) as Map;
  final index =
      jsonDecode(File('assets/action_kits/index.json').readAsStringSync())
          as Map;
  final kits = <String, ActionKit>{};
  for (final path in index['kits'] as List) {
    final kit = ActionKit.fromJson(
      jsonDecode(File(path as String).readAsStringSync())
          as Map<String, dynamic>,
    );
    kits[kit.id] = kit;
  }
  final content = HipContent.fromJson(
    jsonDecode(File('assets/hip/hip-content.json').readAsStringSync())
        as Map<String, dynamic>,
  ).withKits(kits);
  final rows = <Map<String, Object?>>[];
  for (final record in capture['cases'] as List) {
    if (record['plan'] == null) continue;
    final decoded = const uc.PlanCodec().decodeStrict(record['plan']);
    if (!decoded.ok) throw StateError('Captured SDK plan cannot be decoded.');
    final plan = decoded.plan!;
    final saved = CoachPlanMapper(content)
        .map(plan, id: 'offline-${plan.id}', at: DateTime.utc(2026, 10, 31))
        .routine;
    final native = TrainingPlanner(
      content,
    ).customPlan(saved, const TrainingProfile());
    if (native == null ||
        jsonEncode(toTrainerPlan(native).toJson()) !=
            jsonEncode(plan.toJson())) {
      throw StateError('Native adapter changed a captured SDK plan.');
    }
    final target = plan.targetMinutes * 60;
    rows.add({
      'input': record['input'],
      'planId': plan.id,
      'targetSeconds': target,
      'sdkEstimateSeconds': record['estimatedSeconds'],
      'nativePlanSeconds': native.seconds,
      'nativePrepSeconds': 15,
      'nativeTotalSeconds': native.seconds + 15,
      'nativeDurationErrorRatio': (native.seconds + 15 - target) / target,
      'nativeOccurrences': native.steps.length,
      'completePlanPreserved': true,
    });
  }
  File(args[1]).writeAsStringSync(
    const JsonEncoder.withIndent(
      '  ',
    ).convert({'modelRequests': 0, 'deviceOperated': false, 'cases': rows}),
  );
  for (final row in rows) {
    stdout.writeln(jsonEncode(row));
  }
}
