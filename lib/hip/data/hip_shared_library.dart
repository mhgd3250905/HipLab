// HipLab scope, theme and business callbacks; SDK owns browsing and details.
import 'package:flutter/material.dart';
import 'package:ugk_coach/ugk_coach.dart' as coach;
import 'package:ugk_trainer_runtime/ugk_trainer_runtime.dart' as trainer;
import '../domain/hip_library.dart';
import '../ui/hip_theme.dart';
import '../ui/library/library_actions.dart';
import 'hip_public_media.dart';

trainer.TrainingLibraryConfig hipSharedLibraryConfig(
  coach.CoachActionScopeManifest scope,
) => trainer.TrainingLibraryConfig(
  scopeManifest: scope,
  brand: 'HipLab',
  categoryOrder: const ['拉伸放松', '力量'],
  showStartAction: true,
);

abstract final class HipSharedLibrary {
  static trainer.TrainingLibraryConfig? current;

  static trainer.TrainerTheme theme(BuildContext context) {
    final p = Theme.of(context).brightness == Brightness.dark
        ? HipPalette.dark
        : HipPalette.light;
    return trainer.TrainerTheme(
      brightness: p.brightness,
      background: p.background,
      surface: p.surface,
      surfaceHigh: p.surfaceHigh,
      border: p.line,
      shadow: p.shadow,
      track: p.track,
      ringKnob: p.thumb,
      accent: p.jade,
      accentSubtle: p.jade.withValues(alpha: .12),
      accentText: p.jadeDeep,
      onAccent: p.onJade,
      text: p.text,
      muted: p.muted,
      faint: p.faint,
      caution: p.tight,
      danger: p.pain,
      mediaStage: p.mediaBackdrop,
      fontFamily: hipFontFamily,
    );
  }

  static bool canStart(LibraryActions actions, String id) {
    final store = actions.store;
    final drill = store.content.drills[id];
    final kit = store.content.kit(id);
    return current?.allowedActionIds.contains(id) == true &&
        drill != null &&
        kit != null &&
        store.planner.singlePlan(
              drill,
              DoseRules.singleDefault(kit),
              store.profile,
            ) !=
            null;
  }

  static Future<void> start(LibraryActions actions, String id) async {
    if (!canStart(actions, id)) return;
    final store = actions.store;
    final drill = store.content.drill(id);
    final plan = store.planner.singlePlan(
      drill,
      DoseRules.singleDefault(store.content.kit(id)!),
      store.profile,
    );
    if (plan != null) await actions.startPlan(plan);
  }

  static Future<void> openDetail(
    BuildContext context,
    LibraryActions actions,
    String id,
  ) async {
    final config = current;
    final policy = HipPublicMedia.current;
    if (config == null || policy == null) return;
    await trainer.TrainingLibraryDetails.open(
      context,
      actionId: id,
      config: config,
      mediaPolicy: policy,
      theme: theme(context),
      canStart: (id) => canStart(actions, id),
      onStart: (id) => start(actions, id),
    );
  }
}

class HipSharedLibraryPage extends StatelessWidget {
  const HipSharedLibraryPage({super.key, required this.actions, this.header});
  final LibraryActions actions;
  final Widget? header;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      if (header != null)
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
          child: header!,
        ),
      Expanded(
        child: trainer.TrainingLibraryPage(
          config: HipSharedLibrary.current!,
          mediaPolicy: HipPublicMedia.current!,
          theme: HipSharedLibrary.theme(context),
          embedded: true,
          canStart: (id) => HipSharedLibrary.canStart(actions, id),
          onStart: (id) => HipSharedLibrary.start(actions, id),
        ),
      ),
    ],
  );
}
