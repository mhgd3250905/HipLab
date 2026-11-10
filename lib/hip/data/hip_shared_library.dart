// HipLab scope, theme and business callbacks; SDK owns browsing and details.
import 'package:flutter/material.dart';
import 'package:ugk_coach/ugk_coach.dart' as coach;
import 'package:ugk_trainer_runtime/ugk_trainer_runtime.dart' as trainer;
import '../domain/hip_library.dart';
import '../domain/hip_session.dart';
import '../trainer/hip_sdk_session_builder.dart';
import '../ui/hip_theme.dart';
import '../ui/library/library_actions.dart';
import 'hip_public_media.dart';
import 'hip_public_display.dart';
import 'hip_public_text_en.dart';

/// Compatibility fallback for SDK configs with no explicit language. The
/// interface itself follows the saved language and Flutter's resolved locale.
const hipAppLocale = Locale('zh');

trainer.TrainingLibraryConfig hipSharedLibraryConfig(
  coach.CoachActionScopeManifest scope, {
  String? languageTag,
  coach.Catalog? catalog,
}) => trainer.TrainingLibraryConfig(
  scopeManifest: scope,
  strings: trainer.TrainingLibraryStrings.forLanguage(
    languageTag ?? hipAppLocale.toLanguageTag(),
  ),
  brand: 'HipLab',
  categoryOrder: const ['拉伸放松', '力量'],
  showStartAction: true,
  displayText: (languageTag ?? 'zh').split(RegExp('[-_]')).first == 'en'
      ? hipEnglishPublicDisplay(catalog)
      : null,
);

/// Shared by App routes and the Coach profile, which has no BuildContext.
/// Translation is display-only and uses the same checked canonical catalogue.
trainer.TrainingLibraryActionText? Function(String actionId)?
hipEnglishPublicDisplay(coach.Catalog? catalog) {
  if (catalog == null) return null;
  final definitions = {for (final drill in catalog.drills) drill.id: drill};
  return (id) {
    final definition = definitions[id];
    if (definition == null) return null;
    final copy = hipPublicTextEn[id];
    return trainer.TrainingLibraryActionText(
      name: definition.name.of('en'),
      metadata: HipPublicDisplay.metadata(definition.raw),
      muscles: HipPublicDisplay.muscleText(definition.raw),
      // The SDK retains the authored catalogue text when a display override
      // is null. The expanded library does not have new English instructions.
      cues: copy?.cues,
      cautions: copy == null
          ? null
          : [
              ...copy.cautions,
              if (copy.contraindications.isNotEmpty)
                'Caution areas: ${copy.contraindications.join(', ')}.',
            ],
    );
  };
}

abstract final class HipSharedLibrary {
  static trainer.TrainingLibraryConfig? current;

  /// The scope stays shared; each presentation follows the active App locale.
  static trainer.TrainingLibraryConfig localized(BuildContext context) {
    final source = current!;
    final english = Localizations.localeOf(context).languageCode == 'en';
    return trainer.TrainingLibraryConfig(
      scopeManifest: source.scopeManifest,
      categoryOrder: source.categoryOrder,
      brand: source.brand,
      showStartAction: source.showStartAction,
      searchNames: source.searchNames,
      displayText: english
          ? hipEnglishPublicDisplay(
              HipPublicMedia.current?.catalog.toAiCatalog(),
            )
          : source.displayText,
      strings: trainer.TrainingLibraryStrings.forLanguage(
        Localizations.localeOf(context).languageCode,
      ),
    );
  }

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
    return planFor(actions, id) != null;
  }

  /// A single action uses the public definition's authored dose, as in the
  /// SDK single-practice adapter. No local kit or prescription is synthesized.
  static TrainingPlan? planFor(LibraryActions actions, String id) {
    final store = actions.store;
    if (current?.allowedActionIds.contains(id) != true || store.blocked) {
      return null;
    }
    if (store.content.publicCatalog case final catalog?) {
      final source = catalog[id];
      if (source == null) return null;
      final dose = source.defaultDose;
      final original = coach.TrainingPlan(
        id: 'practice-$id',
        source: 'template',
        title: source.name.of('zh'),
        goal: source.purpose,
        scene: source.scenes.first,
        equipment: source.equipment.toList(),
        level: source.level,
        targetMinutes: 1,
        blocks: [
          coach.PlanBlock(
            id: 'single',
            name: source.name.of('zh'),
            type: coach.BlockType.main,
            items: [
              coach.PlanItem(
                exerciseId: id,
                mode: dose.mode,
                sets: dose.sets,
                reps: dose.reps,
                workSeconds: dose.seconds,
                perSide: source.unilateral,
                restSeconds: dose.restSeconds,
              ),
            ],
          ),
        ],
      );
      final builder = hipSdkSessionBuilder(store.content);
      final plan = original.copyWith(
        targetMinutes: (builder.executionTiming(original).totalSeconds / 60)
            .ceil()
            .clamp(1, 10000),
      );
      final result = store.planner.customPlan(
        CustomRoutine(
          id: 'practice-$id',
          name: source.name.of('zh'),
          steps: const [],
          coachPlan: plan.toJson(),
        ),
        store.profile,
      );
      if (result == null) return null;
      return TrainingPlan(
        routines: result.routines,
        steps: result.steps,
        transitionSeconds: result.transitionSeconds,
        source: PlanSource.single,
        refId: id,
        name: result.name,
        sdkPlan: result.sdkPlan,
        sdkSeconds: result.sdkSeconds,
      );
    }
    final drill = store.content.drills[id];
    final kit = store.content.kit(id);
    return drill == null || kit == null
        ? null
        : store.planner.singlePlan(
            drill,
            DoseRules.singleDefault(kit),
            store.profile,
          );
  }

  static Future<void> start(LibraryActions actions, String id) async {
    final plan = planFor(actions, id);
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
      config: localized(context),
      mediaPolicy: HipPublicMedia.forLibrary(policy),
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
          config: HipSharedLibrary.localized(context),
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
