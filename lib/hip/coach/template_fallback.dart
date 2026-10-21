// AI 定制的回落（docs/ai-coach.md §回落与安全）。结构沿用 3D-Body feat/ai-coach
// `app/lib/coach/template_fallback.dart`，换成 HipLab 的 7 套内置套路。
import 'package:ugk_coach/ugk_coach.dart' as uc;

import '../domain/hip_library.dart';
import '../domain/hip_models.dart';

/// 为什么用了预设方案（给用户看的一句话）。
enum PresetReason {
  notConfigured('AI 还没配置'),
  offline('网络不可用'),
  timeout('AI 响应超时'),
  invalid('AI 没有排出合格的计划'),
  unavailable('AI 暂时不可用');

  const PresetReason(this.zh);
  final String zh;

  static PresetReason of(uc.FallbackReason r) => switch (r) {
    uc.FallbackReason.offline => offline,
    uc.FallbackReason.timeout => timeout,
    uc.FallbackReason.invalidOutput => invalid,
    _ => unavailable,
  };
}

/// 回落：按关键词选择 App 内置套路，再由 SDK 门禁筛掉不符合本轮条件的动作。
/// 保留入选动作原有剂量，不把模型未通过的内容修成另一份计划。
class TemplateFallback {
  TemplateFallback(this.content);
  final HipContent content;

  /// 没命中任何关键词时用的套路：D 久坐解压 10 分钟（髋前侧 + 臀 + 内旋，最通用）。
  static const defaultRoutine = 'D';

  static final _keywords = <String, RegExp>{
    'A': RegExp(r'办公室|工位|上班|公司|椅子|坐着|不想躺|不能躺'),
    'B': RegExp(r'睡前|睡觉|入睡|失眠|晚上|放松|躺着|助眠'),
    'C': RegExp(r'早上|早晨|晨起|起床|唤醒|醒来'),
    'D': RegExp(r'久坐|下班|髋前侧|屈髋肌|臀|内旋|僵|紧'),
    'E': RegExp(r'跑步|健身|运动前|训练前|练前|激活|热身|球'),
    'F': RegExp(
      r'breaking|街舞|托马斯|风车|劈叉|一字马|横叉|竖叉|舞者|跳舞|L ?撑',
      caseSensitive: false,
    ),
    'M': RegExp(r'2 ?分钟|两分钟|一两分钟|很快|快速|椅边'),
  };

  /// 红旗情况（与 SDK 内核第 2 条同口径）：不出计划，建议先就医。
  static final _redFlags = RegExp(
    r'剧痛|刺痛|麻木|放射痛|肿胀|肿了|刚受伤|刚扭|拉伤|骨折|术后|手术后|做了手术|怀孕|孕期|产后|胸闷|胸痛|头晕|晕倒',
  );

  static const redFlagReply =
      '你提到的情况（如剧痛、刺痛、麻木、肿胀、刚受伤、术后、孕期产后、头晕胸闷）'
      '不适合现在练。建议先就医或咨询医生/康复师，确认可以恢复训练后再来找我排计划。';

  static bool isRedFlag(String text) => _redFlags.hasMatch(text);

  /// 场景约束：提过就一直有效（不能躺地 / 在办公室 → 只给椅上 / 站姿套路）。
  static final _chairOnly = RegExp(r'办公室|工位|上班|公司|不想躺|不能躺|不方便躺|不能趴');

  /// 关键词命中最多的套路；都没命中用 [defaultRoutine]。
  /// [history] = 同一对话里之前用户说过的话：本轮命中算 2 分、之前的算 1 分，
  /// 这样「办公室不能躺地」→「5分钟」不会忘了场景。
  static String pickRoutine(String text, {List<String> history = const []}) {
    var best = defaultRoutine;
    var bestScore = 0;
    for (final entry in _keywords.entries) {
      var score = entry.value.allMatches(text).length * 2;
      for (final h in history) {
        score += entry.value.allMatches(h).length;
      }
      if (score > bestScore) {
        best = entry.key;
        bestScore = score;
      }
    }
    return best;
  }

  /// 本轮或之前提过的红旗情况（手术、受伤……）整段对话都有效。
  static bool anyRedFlag(String text, List<String> history) =>
      isRedFlag(text) || history.any(isRedFlag);

  uc.SessionFallbackReply reply(
    String text, {
    required PresetReason reason,
    required uc.Catalog catalog,
    required uc.CoachProfile profile,
    uc.CoachContext context = const uc.CoachContext(),
    List<String> history = const [],
  }) {
    if (anyRedFlag(text, history)) {
      return const uc.SessionFallbackReply(redFlagReply);
    }
    var routine = content.routine(pickRoutine(text, history: history));
    final chairOnly =
        context.scene == 'office' ||
        [text, ...history].any(_chairOnly.hasMatch);
    if (chairOnly && routine.scene != HipScene.chair) {
      routine = content.routine('A');
    }
    final original = build(routine);
    final plan = original.copyWith(
      scene: context.scene ?? original.scene,
      level: context.level ?? original.level,
      targetMinutes: context.minutes ?? original.targetMinutes,
      avoid: {...original.avoid, ...context.avoid},
    );
    final gate = uc.ToolGate(catalog: catalog, profile: profile);
    final blocks = <uc.PlanBlock>[];
    // Use SDK admission for the filtering decision too: App does not duplicate
    // its caution, scene, equipment, scope or dose validation rules.
    for (final block in plan.blocks) {
      final items = <uc.PlanItem>[];
      for (final item in block.items) {
        final candidate = plan.copyWith(
          blocks: [
            _withItems(block, [item]),
          ],
        );
        if (gate.admitTemplate(candidate, context) != null) items.add(item);
      }
      if (items.isNotEmpty) blocks.add(_withItems(block, items));
    }
    final admitted = gate.admitTemplate(plan.copyWith(blocks: blocks), context);
    if (admitted == null) {
      return uc.SessionFallbackReply(
        '${reason.zh}。现有预设方案没有符合本次条件的可用训练，暂不安排开练。',
      );
    }
    final filtered = admitted.plan.items.length != original.items.length;
    return uc.SessionFallbackReply(
      '${reason.zh}，先给你 App 内置的预设方案「${routine.name}」'
      '${filtered ? '（已按本轮条件筛选）' : ''}，不是 AI 生成的。',
      plan: admitted.plan,
    );
  }

  static uc.PlanBlock _withItems(uc.PlanBlock block, List<uc.PlanItem> items) =>
      uc.PlanBlock(
        id: block.id,
        name: block.name,
        type: block.type,
        rounds: block.rounds,
        restBetweenRoundsSeconds: block.restBetweenRoundsSeconds,
        items: items,
      );

  /// 内置套路转成 TrainingPlan v1（source=template，templateId=套路 id），剂量照套路原样。
  uc.TrainingPlan build(HipRoutine r) {
    final items = <uc.PlanItem>[];
    for (final s in r.steps) {
      final kit = content.kit(s.drillId);
      if (kit == null || !inLibrary(content, s.drillId)) continue;
      items.add(
        uc.PlanItem(
          exerciseId: s.drillId,
          mode: kit.kind.counted ? uc.DoseMode.reps : uc.DoseMode.time,
          sets: 1,
          reps: kit.kind.counted ? (s.kit.reps ?? kit.defaultReps ?? 1) : null,
          workSeconds: kit.kind.counted
              ? null
              : (s.kit.seconds ?? kit.defaultSeconds ?? 30),
          perSide: kit.sided,
          restSeconds: CustomRoutine.defaultRest,
        ),
      );
    }
    return uc.TrainingPlan(
      id: 'template-${r.id}',
      source: 'template',
      templateId: r.id,
      title: r.name,
      summary: r.audience,
      goal: r.micro ? 'relax' : 'mobility',
      scene: r.scene == HipScene.chair ? 'office' : 'home',
      level: 1,
      targetMinutes: r.minutes < 1 ? 1 : r.minutes,
      blocks: [
        uc.PlanBlock(
          id: 'b1',
          name: r.name,
          type: uc.BlockType.main,
          items: items,
        ),
      ],
      safetyNotes: const ['在不痛的范围内做，出现疼痛、麻木或头晕立即停止。'],
    );
  }
}
