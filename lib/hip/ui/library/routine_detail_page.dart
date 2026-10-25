// Article presentation follows the SmartFit feedback design; all HipLab
// safety adaptation, copying and training plans still use the existing planner.
import 'package:flutter/material.dart';

import '../../domain/hip_library.dart';
import '../../domain/hip_models.dart';
import '../hip_icons.dart';
import '../hip_routes.dart';
import '../hip_theme.dart';
import '../hip_widgets.dart';
import 'drill_detail_page.dart';
import 'group_editor_page.dart';
import 'hip_training_article.dart';
import 'lib_text.dart';
import 'library_actions.dart';
import 'library_widgets.dart';

String routineShortName(HipRoutine r) =>
    r.name.replaceAll(RegExp(r'\s*\d+\s*分钟$'), '');

class RoutineDetailPage extends StatelessWidget {
  const RoutineDetailPage({
    super.key,
    required this.actions,
    required this.routineId,
  });
  final LibraryActions actions;
  final String routineId;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: actions.store,
    builder: (context, _) {
      final t = LibText.of(context);
      final store = actions.store;
      final content = store.content;
      final routine = content.routine(routineId);
      final plan = store.planner.planFor([routine], store.profile);
      final swapped = plan.steps.where((s) => s.replaced != null).length;
      final dropped = routine.steps.length - plan.steps.length;
      final blocked = store.profile.blocked;
      return Scaffold(
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              HipTopBar(
                icon: HipGlyph.back,
                tooltip: t.back,
                onClose: () => Navigator.of(context).maybePop(),
                subtitle: '${t.routine} · ${t.scene(routine.scene)}',
                title: routineShortName(routine),
              ),
              Expanded(
                child: HipTrainingArticle(
                  content: content,
                  title: routineShortName(routine),
                  introduction: routine.audience,
                  seconds: plan.seconds,
                  restSeconds: plan.transitionSeconds,
                  startKey: const ValueKey('routine-start'),
                  startLabel: blocked ? t.askDoctorFirst : null,
                  notices: [
                    if (blocked)
                      LibNotice(
                        text: t.noticeBlocked,
                        color: HipColors.tight,
                        icon: HipGlyph.shield,
                      )
                    else if (swapped + dropped > 0)
                      LibNotice(
                        key: const ValueKey('routine-adapted'),
                        text: t.levelAdapted(swapped, dropped),
                        color: HipColors.jadeText,
                      ),
                  ],
                  secondaryKey: const ValueKey('routine-copy'),
                  secondaryLabel: t.copyAsGroup,
                  onSecondary: () => _copy(context, t, routine),
                  steps: [
                    for (final step in plan.steps)
                      HipArticleStep(
                        drill: step.drill,
                        dose: step.dose,
                        section: t.isEn ? 'Training sequence' : '训练安排',
                        note: step.replaced == null
                            ? step.tip
                            : '${t.easierFor(drillName(content, content.drill(step.replaced!), t.lang))}\n${step.tip}',
                        detailKey: ValueKey('routine-step-${step.drill.id}'),
                      ),
                  ],
                  onOpenDrill: (drill) async {
                    if (!inLibrary(content, drill.id)) return;
                    final jump = await Navigator.of(context).push<Object?>(
                      HipRoute.push<Object?>(
                        (_) => DrillDetailPage(
                          actions: actions,
                          drillId: drill.id,
                        ),
                      ),
                    );
                    if (jump is LibraryJump && context.mounted) {
                      Navigator.of(context).pop(jump);
                    }
                  },
                  onStart: blocked || plan.steps.isEmpty
                      ? null
                      : (from) async {
                          // Recheck live safety state when the user actually starts.
                          final actual = store.planner.routinePlan(
                            routine,
                            store.profile,
                          );
                          if (actual == null) return;
                          await actions.startPlan(
                            actual,
                            from: from,
                            radius: 28,
                            originColor: HipColors.jade,
                          );
                        },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );

  Future<void> _copy(BuildContext context, LibText t, HipRoutine r) async {
    final store = actions.store;
    final group = copyRoutine(
      r,
      store.content,
      id: store.newCustomId(),
      name: t.copiedName(routineShortName(r)),
      at: store.now(),
    );
    await Navigator.of(context).push(
      HipRoute.rise<void>(
        (_) => GroupEditorPage(actions: actions, initial: group, isNew: true),
      ),
    );
  }
}
