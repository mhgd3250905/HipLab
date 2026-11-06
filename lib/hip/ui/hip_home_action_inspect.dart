import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../domain/hip_models.dart';
import 'hip_icons.dart';
import 'hip_theme.dart';
import 'hip_widgets.dart';

/// One physical face, including one video subtree, at every expansion value.
/// Only geometry and playback intent change; no route, snapshot or media swap.
class HipHomeActionFace extends StatelessWidget {
  const HipHomeActionFace({
    super.key,
    required this.drill,
    required this.number,
    required this.expansion,
    required this.expanded,
    required this.paused,
    required this.onClose,
    required this.onToggle,
    required this.previous,
    required this.informationScroll,
    this.multiple = true,
    required this.next,
    this.compact = false,
    this.dose = '',
    this.cue = '',
    this.description = '',
  });

  final HipDrill drill;
  final int number;
  final double expansion;
  final bool expanded, paused, compact;
  final bool multiple;
  final ScrollController informationScroll;
  final VoidCallback onClose, onToggle;
  final Widget previous, next;
  final String dose, cue, description;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final t = expansion;
      final w = box.maxWidth;
      final h = box.maxHeight;
      final inset = lerpDouble(compact ? 10 : 22, 24, t)!;
      final header = lerpDouble(compact ? 28 : 60, 56, t)!;
      final footer = compact ? 64.0 : 122.0 + (cue.isEmpty ? 0 : 20);
      final compactMedia = Rect.fromLTWH(
        0,
        header,
        w,
        math.max(0, h - header - footer),
      );
      final largeMedia = Rect.fromLTWH(
        0,
        56,
        w,
        math.min(w * 1.05, math.max(0, h - 56) * .56),
      );
      final media = Rect.lerp(compactMedia, largeMedia, t)!;
      final radius = lerpDouble(22, 28, t)!;
      final active = expanded || t > 0;
      return DecoratedBox(
        decoration: BoxDecoration(
          color: HipColors.mediaBackdrop,
          borderRadius: BorderRadius.circular(radius),
          boxShadow: HipColors.shadows([
            BoxShadow(
              color: Colors.black.withValues(
                alpha: HipColors.isDark ? .32 : .085,
              ),
              blurRadius: lerpDouble(20, 34, t)!,
              offset: Offset(0, lerpDouble(7, 14, t)!),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: .035),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ]),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned(
                key: const ValueKey('face-header'),
                left: inset,
                right: lerpDouble(inset, 8, t)!,
                top: lerpDouble(compact ? 8 : 20, 6, t)!,
                height: 44,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'HIPLAB',
                            style: TextStyle(
                              fontSize: lerpDouble(compact ? 8 : 10, 11, t),
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2.4,
                              color: HipColors.jadeText,
                            ),
                          ),
                          if (!compact)
                            Opacity(
                              opacity: 1 - t,
                              child: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  drill.methods.firstOrNull?.zh ?? '动作练习',
                                  maxLines: 1,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: HipColors.muted,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Text(
                      number.toString().padLeft(2, '0'),
                      key: const ValueKey('home-deck-position'),
                      style: TextStyle(
                        fontSize: compact ? 10 : 17,
                        fontWeight: FontWeight.w500,
                        letterSpacing: .5,
                        color: HipColors.muted,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    SizedBox(
                      width: 52 * t,
                      child: OverflowBox(
                        alignment: Alignment.centerRight,
                        minWidth: 44,
                        maxWidth: 44,
                        child: IgnorePointer(
                          ignoring: !expanded,
                          child: ExcludeSemantics(
                            excluding: !expanded,
                            child: Opacity(
                              opacity: t,
                              child: HipCircleButton(
                                key: const ValueKey('home-deck-expanded-close'),
                                icon: HipGlyph.close,
                                tooltip: '收起动作卡片',
                                onPressed: onClose,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned.fromRect(
                key: const ValueKey('face-media'),
                rect: media,
                child: Semantics(
                  button: expanded,
                  label: expanded ? (paused ? '播放动作示范' : '暂停动作示范') : drill.name,
                  value: paused || !expanded ? '已暂停' : '自动循环播放',
                  onTap: expanded ? onToggle : null,
                  child: GestureDetector(
                    key: const ValueKey('home-deck-expanded-media'),
                    behavior: HitTestBehavior.opaque,
                    excludeFromSemantics: true,
                    onTap: expanded ? onToggle : null,
                    child: Center(
                      child: SizedBox.square(
                        dimension: math.min(media.width, media.height),
                        child: HipDrillArt(
                          key: const ValueKey('home-hero'),
                          drill: drill,
                          play: expanded && !paused,
                          holdVideo: true,
                          showPendingLabel: false,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                key: const ValueKey('face-information'),
                left: inset,
                right: inset,
                top: media.bottom + lerpDouble(4, 14, t)!,
                bottom: 44 * (1 - t) + 14 * t,
                child: SingleChildScrollView(
                  key: const ValueKey('home-deck-expanded-description'),
                  controller: informationScroll,
                  physics: expanded
                      ? null
                      : const NeverScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        drill.name,
                        key: const ValueKey('home-deck-caption'),
                        maxLines: expanded ? null : (compact ? 1 : 2),
                        overflow: expanded ? null : TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: lerpDouble(compact ? 12 : 23, 28, t),
                          height: 1.22,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -.3,
                          color: HipColors.text,
                        ),
                      ),
                      if (dose.isNotEmpty && (!compact || t > 0)) ...[
                        const SizedBox(height: 7),
                        Text(
                          dose,
                          key: const ValueKey('home-deck-dose'),
                          style: TextStyle(
                            fontSize: lerpDouble(13, 15, t),
                            fontWeight: FontWeight.w500,
                            color: HipColors.jadeText,
                          ),
                        ),
                      ],
                      if (cue.isNotEmpty && (!compact || t > 0)) ...[
                        const SizedBox(height: 5),
                        Text(
                          cue,
                          maxLines: expanded ? null : 1,
                          overflow: expanded ? null : TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: lerpDouble(11, 13, t),
                            height: 1.4,
                            color: HipColors.muted,
                          ),
                        ),
                      ],
                      ExcludeSemantics(
                        excluding: !expanded,
                        child: Opacity(
                          opacity: t,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 16),
                              Text(
                                [
                                  drill.methods.map((m) => m.zh).join(' · '),
                                  drill.directions.map((d) => d.zh).join(' / '),
                                ].where((s) => s.isNotEmpty).join('  ·  '),
                                style: TextStyle(
                                  fontSize: 11,
                                  height: 1.5,
                                  color: HipColors.muted,
                                ),
                              ),
                              if ((description.isNotEmpty
                                      ? description
                                      : drill.note)
                                  .trim()
                                  .isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Text(
                                  description.isNotEmpty
                                      ? description
                                      : drill.note,
                                  style: TextStyle(
                                    fontSize: 14,
                                    height: 1.65,
                                    color: HipColors.text,
                                  ),
                                ),
                              ],
                              if (drill.cautions.isNotEmpty) ...[
                                const SizedBox(height: 14),
                                Text(
                                  '留意 · ${drill.cautions.join('、')}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    height: 1.6,
                                    color: HipColors.muted,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                key: const ValueKey('face-navigation'),
                left: compact ? 4 : 10,
                right: compact ? 4 : 10,
                bottom: 0,
                height: 44,
                child: IgnorePointer(
                  ignoring: active,
                  child: ExcludeSemantics(
                    excluding: active,
                    child: Opacity(
                      opacity: 1 - t,
                      child: Row(
                        children: [
                          previous,
                          Expanded(
                            child: Text(
                              multiple ? '左右翻阅' : '',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: compact ? 8 : 9,
                                letterSpacing: 1.2,
                                color: HipColors.muted,
                              ),
                            ),
                          ),
                          next,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                key: const ValueKey('face-border'),
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(radius),
                      border: Border.all(
                        color: MediaQuery.highContrastOf(context)
                            ? HipColors.text
                            : Colors.white.withValues(
                                alpha: HipColors.isDark ? .13 : .8,
                              ),
                        width: MediaQuery.highContrastOf(context) ? 1.5 : 1,
                      ),
                    ),
                  ),
                ),
              ),
              if (active)
                const Positioned.fill(
                  key: ValueKey('face-expanded-marker'),
                  child: IgnorePointer(
                    child: SizedBox(key: ValueKey('home-deck-expanded')),
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
}
