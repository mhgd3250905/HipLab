import 'package:flutter/material.dart';
import 'package:ugk_coach_chat/ugk_coach_chat.dart';
import 'package:ugk_coach_ui/ugk_coach_ui.dart';
import 'package:ugk_coach/ugk_coach.dart' as coach;
import 'package:ugk_trainer_runtime/ugk_trainer_runtime.dart' as trainer;

import '../../coach/hip_coach_profile.dart' show hiplabCoachAuthorizedActionIds;
import '../../domain/hip_models.dart';
import '../../domain/hip_library.dart';
import '../../data/hip_public_media.dart';
import '../../data/hip_public_text_en.dart';
import '../hip_icons.dart';
import '../hip_theme.dart';
import '../hip_widgets.dart';
import '../hip_content_text.dart';

/// Only brand roles, local artwork and the existing native preview are bound
/// here. The SDK owns chat layout, states, controls and animation.
CoachChatVisuals hipCoachChatVisuals(
  HipContent content, {
  coach.Catalog? catalog,
  String Function()? languageTagOf,
}) {
  final previews = Expando<Map<String, HipDrillArtHandle>>();
  HipDrillArtHandle surface(BuildContext context, String id) {
    final handles = previews[context] ??= {};
    return handles.putIfAbsent(id, HipDrillArtHandle.new);
  }

  return CoachChatVisuals(
    light: hipCoachChatPalette(HipPalette.light),
    dark: hipCoachChatPalette(HipPalette.dark),
    fontFamily: hipFontFamily,
    iconBuilder: _hipChatIcon,
    exerciseFor: (id, brightness) {
      final lang = languageTagOf?.call() ?? 'zh';
      final english = lang == 'en';
      final copy = english ? HipContentText.en : HipContentText.zh;
      final translated = english ? hipPublicTextEn[id] : null;
      final drill = content.drills[id];
      final public = (content.publicCatalog ?? catalog)?[id];
      final action = HipPublicMedia.current?.actionFor(id);
      final poster = HipPublicMedia.current?.posterAssetFor(id);
      if (!hiplabCoachAuthorizedActionIds.contains(id) ||
          (drill == null && public == null) ||
          poster == null) {
        return null;
      }
      final dark = brightness == Brightness.dark;
      final p = dark ? HipPalette.dark : HipPalette.light;
      return CoachExercise(
        id: id,
        name: public?.name.of(lang) ?? copy.drillName(drill!),
        poster: poster,
        cutout: hipCoachStandingAsset(id),
        stillCutout: hipCoachStandingAsset(id),
        categoryLabel: english
            ? switch (public?.category) {
                'strength' => 'Strength',
                'core' => 'Core',
                'cardio' => 'Cardio',
                'mobility' => 'Mobility',
                'stretch' => 'Stretch',
                _ =>
                  drill?.methods
                          .map((value) => copy.text(value.zh))
                          .join(' · ') ??
                      '',
              }
            : action != null
            ? trainer.PoseHubActionFacets.type(action)
            : drill?.methods.map((value) => value.zh).join(' · ') ?? '',
        levelLabel: public == null
            ? (drill!.advanced
                  ? (english ? 'Advanced' : '进阶')
                  : (english ? 'Basic' : '基础'))
            : switch (public.level) {
                1 => english ? 'Starter' : '入门',
                2 => english ? 'Basic' : '基础',
                _ => english ? 'Advanced' : '进阶',
              },
        cues:
            translated?.cues ??
            public?.cues[lang] ??
            [if (drill?.note.isNotEmpty ?? false) copy.text(drill!.note)],
        stage: CoachMediaPalette(
          mediaStage: p.mediaBackdrop,
          onStage: p.text,
          onStageMuted: p.muted,
        ),
      );
    },
    cutoutFor: (id, _) => hiplabCoachAuthorizedActionIds.contains(id)
        ? AssetImage(hipCoachStandingAsset(id))
        : null,
    preloadPoster: (context, id) async {
      final poster = HipPublicMedia.current?.posterAssetFor(id);
      if (poster != null) {
        await trainer.TrainingPosterImages.prepareAsset(context, poster);
      }
    },
    previewBuilder: (context, id, playing) {
      final drill = hipSdkDrill(content, id);
      if (drill == null) return const SizedBox.expand();
      final handle = surface(context, id);
      return HipDrillArt(
        key: handle.key,
        retirementHandle: handle,
        drill: drill,
        play: playing,
        fit: BoxFit.contain,
      );
    },
    retirePreview: (context, id) async {
      await previews[context]?[id]?.retire();
    },
  );
}

String hipCoachStandingAsset(String id) => 'assets/public_posters/$id.webp';

CoachChatPalette hipCoachChatPalette(HipPalette p) => CoachChatPalette(
  brightness: p.brightness,
  skyTop: p.background,
  skyBottom: p.background,
  dust: p.jade.withValues(alpha: p.isDark ? .2 : .12),
  background: p.background,
  surfaceLow: p.track,
  surface: p.surface,
  surfaceHigh: p.surfaceHigh,
  line: p.line,
  accent: p.jade,
  accentText: p.isDark ? p.jade : p.jadeDeep,
  onAccent: p.onJade,
  emphasis: p.jade,
  emphasisText: p.isDark ? p.jade : p.jadeDeep,
  onEmphasis: p.onJade,
  text: p.text,
  muted: p.muted,
  faint: p.faint,
  caution: p.tight,
  danger: p.pain,
  mediaStage: p.mediaBackdrop,
  onStage: p.text,
  onStageMuted: p.muted,
  thumb: p.thumb,
  scrim: p.scrim,
  track: p.track,
  userBubble: p.jade.withValues(alpha: p.isDark ? .16 : .1),
  assistantBubble: p.surface,
  shadow: p.shadow,
);

Widget _hipChatIcon(BuildContext context, CoachChatIconData icon) {
  if (icon.glyph == ChatGlyph.more) {
    return Icon(Icons.more_horiz_rounded, size: icon.size, color: icon.color);
  }
  final glyph = switch (icon.glyph) {
    ChatGlyph.skipPrevious => HipGlyph.skipNext,
    ChatGlyph.bookmark => HipGlyph.clipboard,
    ChatGlyph.arrowUp => HipGlyph.back,
    ChatGlyph.grid => HipGlyph.library,
    ChatGlyph.sliders => HipGlyph.filter,
    ChatGlyph.swap => HipGlyph.loop,
    ChatGlyph.clock => HipGlyph.today,
    ChatGlyph.sparkle => HipGlyph.bolt,
    _ => HipGlyph.values.byName(icon.glyph.name),
  };
  final child = HipIcon(
    glyph,
    size: icon.size,
    color: icon.color,
    filled: icon.filled,
    strokeWidth: icon.strokeWidth,
  );
  return switch (icon.glyph) {
    ChatGlyph.skipPrevious => Transform.flip(flipX: true, child: child),
    ChatGlyph.arrowUp => RotatedBox(quarterTurns: 1, child: child),
    _ => child,
  };
}
