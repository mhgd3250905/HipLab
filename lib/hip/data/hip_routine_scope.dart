// HipLab 首页 folder scope (开哥 2026-11-11): which 编排套路 start on 首页 in
// each scene. Every 编排套路 and every 我的训练组 can be added later from
// 训练组; this is only the out-of-the-box default, never a whitelist.
import '../domain/hip_models.dart';

/// The 编排套路 added to 首页 by default: 办公 and 居家 each get one.
/// Values are content-pack routine ids. Micro sets (久坐提醒) are not default
/// home 套路, but can still be added from 训练组.
const hiplabDefaultHomeRoutineIds = <HipScene, List<String>>{
  HipScene.chair: ['A'], // 办公室 5 分钟 · 工位放松
  HipScene.home: ['D'], // 久坐解压 10 分钟
};

/// Resolved default home 套路 for [s], in folder order. Ids the content pack
/// no longer ships are skipped, never synthesized.
List<HipRoutine> hiplabDefaultHomeRoutines(HipContent content, HipScene s) {
  final byId = {for (final routine in content.routines) routine.id: routine};
  return [
    for (final id in hiplabDefaultHomeRoutineIds[s] ?? const <String>[])
      ?byId[id],
  ];
}
