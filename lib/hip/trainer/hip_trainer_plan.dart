import 'package:ugk_coach/ugk_coach.dart' as coach;
import 'package:ugk_trainer/engine.dart' as trainer;

import '../domain/hip_session.dart';

/// App plan identity and authored doses remain in HipLab. The trainer owns
/// execution; HipSessionBuilder supplies HipLab's per-side D-01 arrangement.
coach.TrainingPlan toTrainerPlan(TrainingPlan plan) =>
    plan.sdkPlan ??
    coach.TrainingPlan(
      id: 'hiplab-${plan.source.id}-${plan.refId ?? plan.title}',
      source: 'template',
      title: plan.title,
      goal: 'hip-mobility',
      scene: 'home',
      level: 1,
      targetMinutes: plan.minutes,
      blocks: [
        coach.PlanBlock(
          id: 'hiplab',
          name: plan.title,
          type: coach.BlockType.main,
          items: [
            for (final step in plan.steps)
              coach.PlanItem(
                exerciseId: step.drill.id,
                mode: coach.DoseMode.time,
                sets: step.sets,
                workSeconds: step.sided
                    ? (step.seconds - step.extraSeconds) ~/ 2
                    : step.seconds,
                perSide: step.sided,
                restSeconds: plan.transitionSeconds,
                note: step.dose,
                replacedFrom: step.replaced,
              ),
          ],
        ),
      ],
    );

/// App safety substitution changes only the named action. All plan structure,
/// occurrence identities, doses and rests continue through the SDK builder.
coach.TrainingPlan substituteSdkExercise(
  coach.TrainingPlan plan,
  String from,
  String to,
) {
  final json = plan.toJson();
  for (final block in json['blocks'] as List) {
    for (final item in block['items'] as List) {
      if (item['exerciseId'] == from) {
        item['exerciseId'] = to;
        item['replacedFrom'] = from;
      }
      for (final segment in item['segments'] as List? ?? const []) {
        if (segment['exerciseId'] == from) {
          segment['exerciseId'] = to;
          // A catalog replacement owns its rhythm, as in SDK TrainerPlayer.
          segment.remove('rhythm');
        }
      }
    }
  }
  return const coach.PlanCodec().decodeStrict(json).plan!;
}

/// The existing pain policy may shorten an occurrence or omit it. The SDK
/// phases retain their sets, rounds, segments and actual rest durations.
List<trainer.SessionPhase> sdkSafetyPhases(
  trainer.SessionBuilder builder,
  coach.TrainingPlan plan, {
  Map<int, double> workScale = const {},
  Set<int> omitted = const {},
}) => [
  for (final phase in builder.phases(plan))
    if (phase.kind == trainer.PhaseKind.done ||
        !omitted.contains(phase.itemIndex))
      if (phase.isWork && workScale.containsKey(phase.itemIndex))
        phase.withSeconds(
          (phase.seconds * workScale[phase.itemIndex]!).ceilToDouble(),
        )
      else
        phase,
];

bool sdkCanFitFullRep(trainer.SessionPhase phase, double scale) {
  if (!phase.isWork || phase.rhythm?.counted != true) return true;
  return phase.rhythm!
          .repPlan(
            reps: phase.reps,
            hold: phase.holdSeconds,
            seconds: (phase.seconds * scale).ceilToDouble(),
          )
          .reps >
      0;
}
