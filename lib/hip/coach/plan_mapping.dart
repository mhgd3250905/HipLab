// Lossless SDK plans are persisted separately. This adapter only bridges
// the existing HipLab library/player DTO; it never chooses or repairs a plan.
import 'dart:math' as math;

import 'package:ugk_coach/ugk_coach.dart' as uc;

import '../domain/hip_library.dart';
import '../domain/hip_models.dart';

/// The legacy library DTO accompanies the complete SDK plan, without fitting.
class CoachPlanMapping {
  const CoachPlanMapping({required this.routine});
  final CustomRoutine routine;
}

class CoachPlanMapper {
  const CoachPlanMapper(this.content);
  final HipContent content;

  /// Keep every item in order, including repeated actions and circuit rounds.
  /// The SDK-admitted plan remains the authority for display and persistence.
  CoachPlanMapping map(
    uc.TrainingPlan plan, {
    required String id,
    required DateTime at,
  }) {
    final steps = <CustomStep>[];
    for (final block in plan.blocks) {
      for (var round = 0; round < block.rounds; round++) {
        for (final item in block.items) {
          final kit = content.kit(item.exerciseId);
          if (kit == null) {
            throw StateError(
              'SDK action has no HipLab kit: ${item.exerciseId}',
            );
          }
          final step = CustomStep(
            kit.id,
            reps: item.reps,
            seconds: item.workSeconds,
            sets: item.sets,
          );
          steps.add(step);
        }
      }
    }
    return CoachPlanMapping(
      routine: CustomRoutine(
        id: id,
        name: routineName(plan),
        steps: steps,
        restSeconds: plan.items.firstOrNull?.restSeconds ?? 15,
        createdAt: at,
        updatedAt: at,
        coachPlan: plan.toJson(),
      ),
    );
  }

  /// Structural import of a legacy saved group. The SDK validates all facts;
  /// no plan selection, dose fitting or focus inference happens in HipLab.
  uc.TrainingPlan toSdkPlan(
    CustomRoutine routine,
    uc.Catalog catalog, {
    required String scene,
  }) {
    final drills = [for (final step in routine.steps) catalog[step.kitId]!];
    return uc.TrainingPlan(
      id: 'ext:${routine.id}',
      source: 'ai',
      title: routine.name,
      goal: 'mobility',
      scene: scene,
      equipment: {for (final drill in drills) ...drill.equipment}.toList(),
      level: drills.fold(1, (level, drill) => math.max(level, drill.level)),
      targetMinutes: math.max(1, (routine.seconds(content) / 60).round()),
      blocks: [
        uc.PlanBlock(
          id: 'saved',
          name: routine.name,
          type: uc.BlockType.main,
          items: [
            for (final step in routine.steps)
              uc.PlanItem(
                exerciseId: step.kitId,
                mode: catalog[step.kitId]!.defaultDose.mode,
                sets: step.sets ?? 1,
                reps: catalog[step.kitId]!.defaultDose.mode == uc.DoseMode.reps
                    ? step.reps ?? content.kit(step.kitId)!.defaultReps
                    : null,
                workSeconds:
                    catalog[step.kitId]!.defaultDose.mode == uc.DoseMode.time
                    ? DoseRules.setSeconds(
                        content.kit(step.kitId)!,
                        step.dose(content.kit(step.kitId)!),
                        single: false,
                      )
                    : null,
                perSide: catalog[step.kitId]!.unilateral,
                restSeconds: routine.restSeconds,
              ),
          ],
        ),
      ],
    );
  }

  /// 训练组名（不超过 12 个字，同训练组编辑器）。
  static String routineName(uc.TrainingPlan plan) {
    final title = plan.title.trim().isEmpty ? 'AI 定制训练' : plan.title.trim();
    return CustomRoutine.cleanName(title);
  }
}
