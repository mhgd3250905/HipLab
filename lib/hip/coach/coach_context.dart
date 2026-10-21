import 'package:ugk_coach/ugk_coach.dart' as uc;

import '../control/hip_store.dart';
import '../domain/hip_models.dart';

/// Conditions actually selected or recorded in HipLab for this request.
///
/// Pain is recorded by hip movement direction, not by the knee/waist cautions
/// of an exercise. Protect the hip when the catalog supports that body-part
/// key, and retain the precise App restrictions in notes. Do not infer other
/// injuries or equipment from an exercise's cautions or the user's identity.
uc.CoachContext buildCoachContext(
  HipStore store, {
  required uc.Catalog catalog,
}) {
  final profile = store.profile;
  // Reuse the App policy: any pain/skip/nerve report within seven days
  // (including the boundary, excluding future reports) is a recent hint.
  final recent = store.recentPainDirections;
  // These also include assessment pain until a pain-free retest and the
  // App's active two-skip, seven-day locks.
  final locked = profile.lockedDirections;
  final hasHipPain = recent.isNotEmpty || locked.isNotEmpty;
  final avoid = <String>{
    if (hasHipPain && catalog.taxonomy.cautions.contains('髋')) '髋',
  };
  final notes = <String>[
    if (store.latestResult == null) '尚未完成自测，使用 App 默认的入门水平。',
    if (recent.isNotEmpty) '最近7天有疼痛反馈的髋方向：${_directions(recent)}。',
    if (locked.isNotEmpty) 'App 已限制为放松练习的髋方向：${_directions(locked)}。',
    if (hasHipPain && avoid.isEmpty) '当前动作目录没有“髋”保护部位词；上述髋方向反馈仍需保留。',
    for (final card in store.content.safetyCards)
      if (store.safety?[card.id] == true) '安全检查“${card.title}”：有。',
    if (profile.blocked) 'App 安全检查尚未解除，当前仅供浏览。',
    if (store.askNumbness) 'App 的麻木复查标记尚未解除。',
  ];
  return uc.CoachContext(
    level: profile.level,
    minutes: store.minutes,
    scene: switch (store.scene) {
      HipScene.home => 'home',
      HipScene.chair => 'office',
    },
    avoid: Set.unmodifiable(avoid),
    notes: List.unmodifiable(notes),
  );
}

String _directions(Set<HipDirection> values) => [
  for (final direction in HipDirection.values)
    if (values.contains(direction)) direction.zh,
].join('、');
