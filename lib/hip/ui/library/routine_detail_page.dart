// ④ 套路详情: who it is for, minutes / moves / rest, the level adaptation
// note and the steps as the real planner will play them.
import 'package:flutter/material.dart';

import '../../domain/hip_library.dart';
import '../../domain/hip_models.dart';
import '../../domain/hip_session.dart';
import '../hip_icons.dart';
import '../hip_routes.dart';
import '../hip_theme.dart';
import '../hip_widgets.dart';
import 'drill_detail_page.dart';
import 'group_editor_page.dart';
import 'lib_text.dart';
import 'library_actions.dart';
import 'library_widgets.dart';

String routineShortName(HipRoutine r) =>
    r.name.replaceAll(RegExp(r'\s*\d+\s*分钟$'), '');

class RoutineDetailPage extends StatelessWidget {
  RoutineDetailPage({
    super.key,
    required this.actions,
    required this.routineId,
  });
  final LibraryActions actions;
  final String routineId;
  final _startKey = GlobalKey();

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: actions.store,
    builder: (context, _) => _build(context),
  );

  Widget _build(BuildContext context) {
    final t = LibText.of(context);
    final store = actions.store;
    final content = store.content;
    final r = content.routine(routineId);
    final profile = store.profile;
    // The real planner: level-1 / gate swaps and relax-only directions.
    final plan = store.planner.planFor([r], profile);
    final swapped = plan.steps.where((s) => s.replaced != null).length;
    final dropped = r.steps.length - plan.steps.length;
    final blocked = profile.blocked;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            HipTopBar(
              icon: HipGlyph.back,
              tooltip: t.back,
              onClose: () => Navigator.of(context).maybePop(),
              subtitle: '${t.routine} · ${t.scene(r.scene)}',
              title: routineShortName(r),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                children: [
                  Text(
                    r.audience,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.45,
                      color: HipColors.muted,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _stat('${plan.minutes}', t.statMinutes),
                      const SizedBox(width: 10),
                      _stat('${plan.steps.length}', t.statMoves),
                      const SizedBox(width: 10),
                      _stat('${plan.transitionSeconds}', t.statRest),
                    ],
                  ),
                  if (blocked) ...[
                    const SizedBox(height: 12),
                    LibNotice(
                      text: t.noticeBlocked,
                      color: HipColors.tight,
                      icon: HipGlyph.shield,
                    ),
                  ] else if (swapped + dropped > 0) ...[
                    const SizedBox(height: 12),
                    LibNotice(
                      key: const ValueKey('routine-adapted'),
                      text: t.levelAdapted(swapped, dropped),
                      color: HipColors.jadeText,
                    ),
                  ],
                  const SizedBox(height: 14),
                  for (final (i, s) in plan.steps.indexed) ...[
                    _row(context, t, content, i, s),
                    if (i < plan.steps.length - 1)
                      Divider(height: 1, indent: 72, color: HipColors.line),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: LibFooter(
        children: [
          Expanded(
            flex: 3,
            child: HipSecondaryButton(
              key: const ValueKey('routine-copy'),
              label: t.copyAsGroup,
              onPressed: () => _copy(context, t, r),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: KeyedSubtree(
              key: _startKey,
              child: RepaintBoundary(
                child: HipPrimaryButton(
                  key: const ValueKey('routine-start'),
                  label: blocked ? t.askDoctorFirst : t.start,
                  icon: blocked ? null : HipGlyph.play,
                  onPressed: blocked || plan.steps.isEmpty
                      ? null
                      : () {
                          final p = store.planner.routinePlan(r, profile);
                          if (p == null) return;
                          actions.startPlan(
                            p,
                            from: _startKey.currentContext,
                            radius: 28,
                            color: HipColors.jade,
                          );
                        },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _copy(BuildContext context, LibText t, HipRoutine r) {
    final store = actions.store;
    final group = copyRoutine(
      r,
      store.content,
      id: store.newCustomId(),
      name: t.copiedName(routineShortName(r)),
      at: store.now(),
    );
    Navigator.of(context).push(
      HipRoute.rise<void>(
        (_) => GroupEditorPage(actions: actions, initial: group, isNew: true),
      ),
    );
  }

  Widget _stat(String v, String unit) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: HipColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: HipColors.line),
      ),
      child: Column(
        children: [
          Text(
            v,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1.15,
            ),
          ),
          Text(unit, style: TextStyle(fontSize: 12, color: HipColors.muted)),
        ],
      ),
    ),
  );

  Widget _row(
    BuildContext context,
    LibText t,
    HipContent content,
    int i,
    PlanStep s,
  ) => HipPressable(
    semanticLabel: drillName(content, s.drill, t.lang),
    scale: .98,
    onTap: inLibrary(content, s.drill.id)
        ? () => Navigator.of(context).push(
            HipRoute.push<Object?>(
              (_) => DrillDetailPage(actions: actions, drillId: s.drill.id),
            ),
          )
        : null,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 18,
            child: Text(
              '${i + 1}',
              style: TextStyle(
                fontSize: 13,
                color: HipColors.faint,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 2),
          HipThumb(
            size: 52,
            radius: 12,
            child: HipDrillArt(drill: s.drill, showPendingLabel: false),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  drillName(content, s.drill, t.lang),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  s.replaced != null
                      ? t.easierFor(
                          drillName(
                            content,
                            content.drill(s.replaced!),
                            t.lang,
                          ),
                        )
                      : s.dose.replaceAll(RegExp(r'（.*?）'), ''),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: s.replaced != null
                        ? HipColors.jadeText
                        : HipColors.muted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            clockText(s.seconds),
            style: TextStyle(
              fontSize: 14,
              color: HipColors.muted,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    ),
  );
}
