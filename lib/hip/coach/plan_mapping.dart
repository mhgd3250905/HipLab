// TrainingPlan v1 → HipLab 自定义训练组（docs/ai-coach.md §计划怎么变成训练组）。
//
// 设计原则（开哥 2026-10-19）：动画只负责演示，剂量以动作包训练参数为准。所以 AI 给的
// 剂量一律换算成动作包的口径（计数类 = 次数，保持类 = 秒），再按自定义训练组的同一套
// 范围（DoseRules：次数 1…2× 默认，秒 ½…2× 默认、5 秒一档，组数 1–3）收进去。
import 'dart:math' as math;

import 'package:ugk_coach/ugk_coach.dart' as uc;

import '../domain/hip_library.dart';
import '../domain/hip_models.dart';

/// 计划卡上的一行，也是训练组里的一步。
class CoachPlanEntry {
  const CoachPlanEntry({
    required this.drill,
    required this.kit,
    required this.step,
    required this.blockName,
    required this.doseText,
    this.adjusted = false,
  });

  final HipDrill drill;
  final ActionKit kit;
  final CustomStep step;
  final String blockName;

  /// 按动作包口径的剂量文字（与训练组、播放器一致）。
  final String doseText;

  /// AI 给的剂量被换算或收进了范围（单位不同、超出范围、轮数折算超过 3 组）。
  final bool adjusted;
}

/// 一份计划映射后的结果：训练组（未保存）+ 卡片行。
class CoachPlanMapping {
  const CoachPlanMapping({required this.routine, required this.entries});
  final CustomRoutine routine;
  final List<CoachPlanEntry> entries;

  int seconds(HipContent c) => routine.seconds(c);
  bool get adjusted => entries.any((e) => e.adjusted);
}

class CoachPlanMapper {
  const CoachPlanMapper(this.content);
  final HipContent content;

  /// - 块按顺序拍平成一串动作（训练组是依次跟练）；`rounds` 折进组数（sets × rounds，最多 3 组）；
  ///   同一动作再次出现时并进第一次的组数。最多 20 步。
  /// - `mode` 与动作包单位一致时直接用；计数类给了秒数 → 按动作包节奏换成能做完的次数
  ///   （同单练「计时的计数动作」的算法）；保持类给了次数 → 用动作包默认秒数。
  /// - 动作间休息：取计划里各动作 restSeconds 的中位数，就近落到训练组可选的 10/15/20/30 秒。
  /// - 预设方案（source=template）：只复制门禁准入动作，剂量、节奏照原套路。
  /// - 不在动作大全里的动作跳过（校验阶段已按「profile ∩ 动作大全」排除，正常不会出现）。
  CoachPlanMapping map(
    uc.TrainingPlan plan, {
    required String id,
    required DateTime at,
  }) {
    final name = routineName(plan);
    if (plan.source == 'template' && plan.templateId != null) {
      final r = content.routines
          .where((r) => r.id == plan.templateId)
          .firstOrNull;
      if (r != null) {
        final admittedIds = {for (final item in plan.items) item.exerciseId};
        // Presets retain their authored hold/pace overrides, but a gated
        // subset must never regain an excluded exercise from its template.
        final original = copyRoutine(r, content, id: id, name: name, at: at);
        final routine = original.copyWith(
          steps: [
            for (final step in original.steps)
              if (admittedIds.contains(step.kitId)) step,
          ],
        );
        return CoachPlanMapping(
          routine: routine,
          entries: [for (final s in routine.steps) _entry(s, r.name, false)],
        );
      }
    }
    final order = <String>[];
    final doses = <String, LibraryDose>{};
    final adjusted = <String, bool>{};
    final blocks = <String, String>{};
    final rests = <int>[];
    for (final block in plan.blocks) {
      final rounds = math.max(1, block.rounds);
      for (final item in block.items) {
        final id = item.exerciseId;
        final kit = content.kit(id);
        if (kit == null || !inLibrary(content, id)) continue;
        final sets = item.sets * rounds;
        final existing = doses[id];
        if (existing != null) {
          final merged = existing.sets + sets;
          doses[id] = existing.copyWith(
            sets: math.min(merged, DoseRules.maxSets),
          );
          if (merged > DoseRules.maxSets) adjusted[id] = true;
          continue;
        }
        if (order.length >= CustomRoutine.maxSteps) continue;
        order.add(id);
        rests.add(item.restSeconds);
        blocks[id] = block.name.isEmpty ? block.type.zh : block.name;
        final (raw, converted) = _kitDose(kit, item, sets);
        final clamped = DoseRules.clamp(kit, raw, single: false);
        doses[id] = clamped;
        adjusted[id] =
            converted ||
            clamped.reps != raw.reps ||
            clamped.seconds != raw.seconds ||
            clamped.sets != raw.sets;
      }
    }
    final steps = [
      for (final id in order) CustomStep.fromDose(content.kit(id)!, doses[id]!),
    ];
    final routine = CustomRoutine(
      id: id,
      name: name,
      steps: steps,
      restSeconds: restFor(rests),
      createdAt: at,
      updatedAt: at,
    );
    return CoachPlanMapping(
      routine: routine,
      entries: [
        for (final s in steps)
          _entry(s, blocks[s.kitId]!, adjusted[s.kitId] ?? false),
      ],
    );
  }

  /// 已保存（可能被用户编辑过）的训练组 → 卡片行：卡片展示与开练用同一份训练组。
  /// 分块名沿用原 AI 计划里同一动作的分块，新加的动作归到训练组名下。
  CoachPlanMapping fromRoutine(CustomRoutine routine, CoachPlanMapping original) {
    final blocks = {for (final e in original.entries) e.drill.id: e.blockName};
    return CoachPlanMapping(
      routine: routine,
      entries: [
        for (final s in routine.steps)
          if (content.kit(s.kitId) != null)
            _entry(s, blocks[s.kitId] ?? routine.name, false),
      ],
    );
  }

  CoachPlanEntry _entry(CustomStep s, String block, bool adjusted) {
    final kit = content.kit(s.kitId)!;
    return CoachPlanEntry(
      drill: content.drill(s.kitId),
      kit: kit,
      step: s,
      blockName: block,
      doseText: doseText(kit, s.dose(kit), single: false),
      adjusted: adjusted,
    );
  }

  /// AI 剂量 → 动作包口径；第二个值 = 是否做了单位换算。
  static (LibraryDose, bool) _kitDose(ActionKit k, uc.PlanItem item, int sets) {
    final time = item.mode == uc.DoseMode.time;
    if (k.kind.counted) {
      if (!time) {
        return (
          LibraryDose(reps: item.reps ?? k.defaultReps, sets: sets),
          false,
        );
      }
      // 计数类给了秒数：按动作包节奏，在这么多秒里能做完几次（同单练计时的计数动作）。
      final secs = item.workSeconds ?? 0;
      final cycle = k.cycleFor(const KitDose());
      final reps = cycle <= 0 || secs <= 0
          ? (k.defaultReps ?? 1)
          : math.max(1, ((secs - k.lead) / cycle).floor());
      return (LibraryDose(reps: reps, sets: sets), true);
    }
    if (time) {
      return (
        LibraryDose(seconds: item.workSeconds ?? k.defaultSeconds, sets: sets),
        false,
      );
    }
    // 保持类给了次数：没有可换算的节奏，用动作包默认秒数。
    return (LibraryDose(seconds: k.defaultSeconds, sets: sets), true);
  }

  /// 各动作 restSeconds 的中位数，就近落到 10/15/20/30 秒（空 = 15 秒）。
  static int restFor(List<int> rests) {
    if (rests.isEmpty) return CustomRoutine.defaultRest;
    final sorted = [...rests]..sort();
    final mid = sorted[sorted.length ~/ 2];
    var best = CustomRoutine.defaultRest;
    for (final r in CustomRoutine.rests) {
      if ((r - mid).abs() < (best - mid).abs()) best = r;
    }
    return best;
  }

  /// 训练组名（不超过 12 个字，同训练组编辑器）。
  static String routineName(uc.TrainingPlan plan) {
    final title = plan.title.trim().isEmpty ? 'AI 定制训练' : plan.title.trim();
    return CustomRoutine.cleanName(title);
  }
}
