// Offline replay of already captured live plans. Makes no model requests.
import 'dart:convert';
import 'dart:io';

import 'package:hiplab/hip/coach/plan_mapping.dart';
import 'package:hiplab/hip/domain/hip_models.dart';
import 'package:hiplab/hip/domain/hip_session.dart';
import 'package:hiplab/hip/trainer/hip_trainer_plan.dart';
import 'package:ugk_coach/ugk_coach.dart' as uc;
import 'package:ugk_trainer/engine.dart' as trainer;

/// The AI player's inherited SDK script, without Flutter asset loading.
/// HipSessionScript's source delegates these calls and timings to this same
/// manifest source and the bundled action-kit voices. A regression test compares
/// every kit's side-switch timing with the actual HipSessionScript.
trainer.SessionScript loadCoachMetricVoiceScript(
  HipContent content, {
  String lang = 'zh',
}) => trainer.SessionScript(
  lang: lang,
  source: trainer.ManifestVoiceSource.fromJson(
    jsonDecode(File('assets/voice/manifest.json').readAsStringSync())
        as Map<String, dynamic>,
    kitVoices: {
      for (final kit in content.kits.values)
        kit.id: trainer.KitVoice.fromActionKitJson(kit.raw),
    },
  ),
);

/// Offline acceptance measurements. No doses, rounds or plan fields are changed.
/// Defaults to the AI player's bundled Chinese voice-aware side-switch timing.
/// A caller can pass the actual player's builder to verify another voice locale.
Map<String, Object?> measureCoachPlanTiming({
  required uc.TrainingPlan plan,
  required HipContent content,
  required uc.Catalog catalog,
  trainer.SessionBuilder? executionBuilder,
}) {
  final saved = CoachPlanMapper(
    content,
  ).map(plan, id: 'offline-${plan.id}', at: DateTime.utc(2026, 10, 31)).routine;
  final native = TrainingPlanner(
    content,
  ).customPlan(saved, const TrainingProfile());
  if (native == null ||
      jsonEncode(toTrainerPlan(native).toJson()) != jsonEncode(plan.toJson())) {
    throw StateError('Native adapter changed a captured SDK plan.');
  }
  final rhythms = {
    for (final kit in content.kits.values)
      kit.id: trainer.Rhythm.fromActionKitJson(kit.raw),
  };
  final plannerBuilder = trainer.SessionBuilder(
    prepSeconds: 15,
    transitionSeconds: native.transitionSeconds,
    rhythms: rhythms,
  );
  final plannerPhases = plannerBuilder.phases(toTrainerPlan(native));
  final plannerTotal = plannerPhases.fold<double>(
    0,
    (sum, phase) => sum + phase.seconds,
  );
  final plannerPrep = plannerPhases
      .where((phase) => phase.kind == trainer.PhaseKind.prep)
      .fold<double>(0, (sum, phase) => sum + phase.seconds);
  final script = executionBuilder == null
      ? loadCoachMetricVoiceScript(content)
      : null;
  final builder =
      executionBuilder ??
      trainer.SessionBuilder(
        prepSeconds: 15,
        transitionSeconds: native.transitionSeconds,
        rhythms: rhythms,
        switchSecondsFor: script!.switchSecondsFor,
      );
  final phases = builder.phases(toTrainerPlan(native));
  if (phases.any((phase) => phase.selfPaced)) {
    throw StateError('Self-paced phases cannot certify a fixed duration.');
  }
  final total = phases.fold<double>(0, (sum, phase) => sum + phase.seconds);
  final prep = phases
      .where((phase) => phase.kind == trainer.PhaseKind.prep)
      .fold<double>(0, (sum, phase) => sum + phase.seconds);
  final engine = trainer.SessionEngine(phases)..update(total + .001);
  final visited = engine.visits.fold<double>(
    0,
    (sum, visit) => sum + visit.seconds,
  );
  if (!engine.done || (visited - total).abs() > .000001) {
    throw StateError(
      'SDK engine did not naturally visit the complete timeline.',
    );
  }
  final target = plan.targetMinutes * 60;
  if (target <= 0) throw StateError('Plan duration target must be positive.');
  final card = const uc.PlanDuration().estimateSeconds(plan, catalog);
  final cardError = (card - target) / target;
  final nativeError = (total - target) / target;
  const tolerance = .10;
  return {
    'planId': plan.id,
    'targetSeconds': target,
    'sdkEstimateSeconds': card,
    'cardDurationErrorRatio': cardError,
    'cardWithinTolerance': cardError.abs() <= tolerance + 1e-9,
    'nativePlanSeconds': total - prep,
    'nativePrepSeconds': prep,
    'nativeTotalSeconds': total,
    'nativeDurationErrorRatio': nativeError,
    'nativeWithinTolerance': nativeError.abs() <= tolerance + 1e-9,
    'withinTolerance':
        cardError.abs() <= tolerance + 1e-9 &&
        nativeError.abs() <= tolerance + 1e-9,
    'nativeOccurrences': native.steps.length,
    'nativeWorkPhases': phases.where((phase) => phase.isWork).length,
    'nativeEngineVisitSeconds': visited,
    'fullyCompletedOccurrences': engine.fullyCompletedExercises,
    'completePlanPreserved': true,
    'voiceAwareSwitchTiming': executionBuilder == null,
    'executionBuilder': executionBuilder == null
        ? 'AI player bundled zh voice timing'
        : 'caller supplied',
    'plannerPlanSeconds': plannerTotal - plannerPrep,
    'plannerPrepSeconds': plannerPrep,
    'plannerTotalSeconds': plannerTotal,
    'voiceSwitchExtensionSeconds': total - plannerTotal,
  };
}

HipContent loadCoachMetricContent() {
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
  return HipContent.fromJson(
    jsonDecode(File('assets/hip/hip-content.json').readAsStringSync())
        as Map<String, dynamic>,
  ).withKits(kits);
}

void main(List<String> args) {
  if (args.length != 2) {
    throw ArgumentError(
      'Expected captured results.json and output JSON paths.',
    );
  }
  final capture = jsonDecode(File(args[0]).readAsStringSync()) as Map;
  final content = loadCoachMetricContent();
  final catalog = uc.Catalog.fromJson(
    jsonDecode(File('assets/coach/catalog.json').readAsStringSync())
        as Map<String, dynamic>,
  );
  final rows = <Map<String, Object?>>[];
  for (final record in capture['cases'] as List) {
    if (record['plan'] == null) continue;
    final decoded = const uc.PlanCodec().decodeStrict(record['plan']);
    if (!decoded.ok) throw StateError('Captured SDK plan cannot be decoded.');
    final plan = decoded.plan!;
    rows.add({
      'input': record['input'],
      'capturedEstimateSeconds': record['estimatedSeconds'],
      ...measureCoachPlanTiming(plan: plan, content: content, catalog: catalog),
    });
  }
  final passed =
      rows.isNotEmpty && rows.every((row) => row['withinTolerance'] == true);
  File(args[1]).writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert({
      'modelRequests': 0,
      'deviceOperated': false,
      'measurement':
          'AI player bundled zh voice-aware SDK phase sum and natural engine '
          'visits, including preparation; no audio or device execution',
      'toleranceRatio': .10,
      'allWithinTolerance': passed,
      'cases': rows,
    }),
  );
  for (final row in rows) {
    stdout.writeln(jsonEncode(row));
  }
  if (!passed) exitCode = 1;
}
