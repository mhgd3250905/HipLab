import 'package:ugk_coach/ugk_coach.dart' as coach;

import '../domain/hip_session.dart';

/// App plan identity and authored doses remain in HipLab. The trainer owns
/// execution; HipSessionBuilder supplies HipLab's per-side D-01 arrangement.
coach.TrainingPlan toTrainerPlan(TrainingPlan plan) => coach.TrainingPlan(
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
