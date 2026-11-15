import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ugk_trainer_runtime/ugk_trainer.dart' as trainer;

import '../data/hip_library_poster_bounds.dart';
import '../data/hip_public_media.dart';
import '../domain/hip_models.dart';
import 'hip_glass.dart';
import 'hip_icons.dart';
import 'hip_poster_bounds_fit.dart';
import 'hip_theme.dart';
import 'hip_widgets.dart' show HipCard, HipPressable;
import 'library/lib_text.dart';

const _folderColumns = 2;
const _folderCoverFade = Interval(0, .36, curve: Curves.easeInOut);
const _folderContentFade = Interval(.12, .56, curve: Curves.easeInOut);

abstract final class _FolderPreview {
  static const radius = 14.0;
  static const artRadius = 6.0;

  static const _inset = 6.0;
  static const _cellSize = 21.0;
  static const _stride = 25.0;
  static const emptyHeight = 2 * _inset + _cellSize;
  static const width = emptyHeight + (_folderColumns - 1) * _stride;
  static const _singleArtSize = 44.0;

  static Rect artworkRect(int index, int count) => count == 1
      ? Rect.fromLTWH(
          (width - _singleArtSize) / 2,
          (width - _singleArtSize) / 2,
          _singleArtSize,
          _singleArtSize,
        )
      : Rect.fromLTWH(
          _inset + (index % _folderColumns) * _stride,
          _inset + (index ~/ _folderColumns) * _stride,
          _cellSize,
          _cellSize,
        );
}

@immutable
class HipHomeRoutineChoice {
  const HipHomeRoutineChoice({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.minutes,
    required this.drills,
    this.sceneLabel = '',
  });

  final String id;
  final String title;
  final String subtitle;
  final int minutes;
  final List<HipDrill> drills;

  /// 办公 / 居家 chip on the cover. Empty hides it: the folder lists the
  /// current scene's 套路 only, and the header already names that scene.
  final String sceneLabel;
}

/// A bounded folder, not a trainer or another copy of the home video deck.
/// Both miniatures and the open grid use the shared cached poster renderer.
class HipHomeRoutineFolder extends StatefulWidget {
  const HipHomeRoutineFolder({
    super.key,
    required this.choices,
    required this.selectedId,
    required this.sceneLabel,
    required this.onSelected,
    this.onChooseGroups,
  });

  final List<HipHomeRoutineChoice> choices;
  final String selectedId;
  final String sceneLabel;
  final ValueChanged<String> onSelected;

  /// 「训练组选择」 tile: opens 训练组 so entries can be added to 首页.
  /// null keeps the folder a pure selection panel (component fixtures).
  final VoidCallback? onChooseGroups;

  @override
  State<HipHomeRoutineFolder> createState() => _HipHomeRoutineFolderState();
}

class _HipHomeRoutineFolderState extends State<HipHomeRoutineFolder> {
  final _face = GlobalKey();
  _RoutineFolderRoute? _route;

  @override
  void dispose() {
    final route = _route;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final navigator = route?.navigator;
      if (navigator != null && navigator.mounted && route!.isActive) {
        navigator.removeRoute(route);
      }
    });
    super.dispose();
  }

  List<HipDrill?> get _miniatures => [
    // One group, one preview. Never imply extra groups with later actions.
    for (final choice in widget.choices.take(4)) choice.drills.firstOrNull,
  ];

  @override
  void didUpdateWidget(HipHomeRoutineFolder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_route != null &&
        (oldWidget.sceneLabel != widget.sceneLabel ||
            !_sameChoices(oldWidget.choices, widget.choices))) {
      final route = _route!;
      // A safety/profile change may invalidate the open snapshot. Never let
      // an old grid select a plan that is no longer available.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && identical(_route, route) && route.isCurrent) {
          route.navigator?.pop();
        }
      });
    }
  }

  static bool _sameChoices(
    List<HipHomeRoutineChoice> a,
    List<HipHomeRoutineChoice> b,
  ) =>
      a.length == b.length &&
      Iterable.generate(a.length).every((i) {
        final x = a[i], y = b[i];
        return x.id == y.id &&
            x.title == y.title &&
            x.subtitle == y.subtitle &&
            x.sceneLabel == y.sceneLabel &&
            x.minutes == y.minutes &&
            x.drills.length == y.drills.length &&
            Iterable.generate(
              x.drills.length,
            ).every((j) => x.drills[j].id == y.drills[j].id);
      });

  Future<void> _open() async {
    if (_route != null ||
        (widget.choices.isEmpty && widget.onChooseGroups == null)) {
      return;
    }
    final box = _face.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return;
    final navigator = Navigator.of(context);
    late final _RoutineFolderRoute route;
    route = _RoutineFolderRoute(
      // The tap's press scale must not move the folder's resting anchor.
      origin: Rect.fromCenter(
        center: box.localToGlobal(box.size.center(Offset.zero)),
        width: box.size.width,
        height: box.size.height,
      ),
      choices: List.of(widget.choices),
      selectedId: widget.selectedId,
      sceneLabel: widget.sceneLabel,
      onChooseGroups: widget.onChooseGroups == null
          ? null
          : () async {
              // Close the folder first so 训练组 is pushed from 首页, and so
              // its return does not leave a stale grid above the new page.
              navigator.pop();
              await route.completed;
              if (mounted) widget.onChooseGroups!();
            },
      reduced: MediaQuery.disableAnimationsOf(context),
      barrierText: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    );
    setState(() => _route = route);
    final selected = await Navigator.of(context).push<String>(route);
    // Keep the old deck and the source face stable until the entire folder
    // has returned, rather than changing the home plan behind a shrinking grid.
    await route.completed;
    if (!mounted) return;
    setState(() => _route = null);
    if (selected != null && widget.choices.any((c) => c.id == selected)) {
      widget.onSelected(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final miniatures = _miniatures;
    final progress =
        _route?.animation ?? const AlwaysStoppedAnimation<double>(0);
    final height = miniatures.isEmpty
        ? _FolderPreview.emptyHeight
        : _FolderPreview.width;
    return PopScope(
      canPop: _route == null,
      child: HipPressable(
        semanticLabel: LibText.of(context).isEn ? 'Choose a workout' : '选择训练组',
        onTap:
            _route == null &&
                (widget.choices.isNotEmpty || widget.onChooseGroups != null)
            ? _open
            : null,
        scale: .95,
        // Keep a 44 pt tap target and the same bottom-right anchor.
        child: Padding(
          padding: EdgeInsets.only(top: math.max(0.0, 44 - height)),
          child: SizedBox(
            width: _FolderPreview.width,
            height: height,
            child: AnimatedBuilder(
              animation: progress,
              builder: (context, child) => Opacity(
                key: const ValueKey('home-routine-folder-source'),
                // Restore in the same frame that the reverse reaches its source,
                // before overlay disposal completes in a later microtask.
                opacity: 1 - _folderCoverFade.transform(progress.value),
                child: child,
              ),
              child: _FolderSurface(
                key: _face,
                radius: _FolderPreview.radius,
                child: SizedBox.expand(
                  child: Stack(
                    children: [
                      for (var i = 0; i < miniatures.length; i++)
                        Positioned.fromRect(
                          rect: _FolderPreview.artworkRect(
                            i,
                            miniatures.length,
                          ),
                          child: _FolderArtwork(
                            key: ValueKey(
                              'home-routine-preview-${widget.choices[i].id}',
                            ),
                            drill: miniatures[i],
                            radius: _FolderPreview.artRadius,
                            fitThumbnail: miniatures.length == 1,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoutineFolderRoute extends PopupRoute<String> {
  _RoutineFolderRoute({
    required this.origin,
    required this.choices,
    required this.selectedId,
    required this.sceneLabel,
    required this.reduced,
    required this.barrierText,
    this.onChooseGroups,
  });

  final Rect origin;
  final List<HipHomeRoutineChoice> choices;
  late final CurvedAnimation _motion;
  final String selectedId;
  final String sceneLabel;
  final bool reduced;
  final String barrierText;
  final VoidCallback? onChooseGroups;

  /// The grid holds the scene's 套路 only; 「训练组选择」 lives in the header.
  int get itemCount => choices.length;

  @override
  Duration get transitionDuration =>
      reduced ? Duration.zero : const Duration(milliseconds: 420);
  @override
  Duration get reverseTransitionDuration =>
      reduced ? Duration.zero : const Duration(milliseconds: 360);
  @override
  Color get barrierColor => Colors.transparent;
  @override
  bool get barrierDismissible => true;
  @override
  String get barrierLabel => barrierText;

  @override
  Animation<double> createAnimation() {
    final progress = super.createAnimation();
    _motion = CurvedAnimation(parent: progress, curve: Curves.easeInOut);
    return progress;
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) => DefaultTextStyle(
    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
      color: HipColors.text,
      decoration: TextDecoration.none,
    ),
    child: Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
      },
      child: Actions(
        actions: {
          DismissIntent: CallbackAction<DismissIntent>(
            onInvoke: (_) {
              if (isCurrent) navigator?.pop();
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: Semantics(
            scopesRoute: true,
            namesRoute: true,
            explicitChildNodes: true,
            label: LibText.of(context).isEn
                ? 'Recommended $sceneLabel workouts'
                : '$sceneLabel推荐训练组',
            child: LayoutBuilder(
              builder: (context, constraints) {
                final media = MediaQuery.of(context);
                final available = Rect.fromLTRB(
                  media.padding.left + 20,
                  media.padding.top + 20,
                  constraints.maxWidth - media.padding.right - 20,
                  constraints.maxHeight -
                      math.max(media.padding.bottom, media.viewInsets.bottom) -
                      20,
                );
                // Keep the open panel aligned with the folder's bottom-right
                // corner, subject to the current window and keyboard bounds.
                final anchor = Offset(
                  origin.right.clamp(
                    available.left + 64,
                    constraints.maxWidth - media.padding.right,
                  ),
                  origin.bottom.clamp(
                    available.top + 64,
                    constraints.maxHeight -
                        math.max(media.padding.bottom, media.viewInsets.bottom),
                  ),
                );
                final width = math.min(
                  420.0,
                  math.min(available.width, anchor.dx - available.left),
                );
                final tileWidth =
                    (width - 40 - (_folderColumns - 1) * 14) / _folderColumns;
                final coverHeight = tileWidth / 1.2;
                final tileHeight = coverHeight + 59;
                final rows = (itemCount / _folderColumns).ceil();
                const headerHeight = 76.0;
                final height = math.min(
                  headerHeight +
                      rows * tileHeight +
                      math.max(0, rows - 1) * 14 +
                      20,
                  anchor.dy - available.top,
                );
                final target = Rect.fromLTWH(
                  anchor.dx - width,
                  anchor.dy - height,
                  width,
                  height,
                );
                final panel = _FolderPanel(
                  choices: choices,
                  selectedId: selectedId,
                  sceneLabel: sceneLabel,
                  tileHeight: tileHeight,
                  onChooseGroups: onChooseGroups,
                  onSelect: (id) {
                    if (isCurrent) navigator?.pop(id);
                  },
                );
                return AnimatedBuilder(
                  animation: animation,
                  child: panel,
                  builder: (context, child) {
                    final t = _motion.value;
                    final startScale = origin.width / target.width;
                    final scale = lerpDouble(startScale, 1, t)!;
                    final offset =
                        Offset.lerp(origin.center, target.center, t)! -
                        target.center;
                    final interactive =
                        animation.status == AnimationStatus.completed;
                    // Interpolate in screen units, then let the panel transform
                    // bring the shadow back to that size.
                    final shadows = HipColors.cardShadow
                        ?.map((shadow) => shadow.scale((1 + .25 * t) / scale))
                        .toList();
                    return Stack(
                      children: [
                        Positioned.fill(
                          child: IgnorePointer(
                            child: ColoredBox(
                              color: Colors.black.withValues(alpha: .28 * t),
                            ),
                          ),
                        ),
                        Positioned.fromRect(
                          rect: target,
                          child: Transform(
                            key: const ValueKey(
                              'home-routine-folder-transform',
                            ),
                            alignment: Alignment.center,
                            transform: Matrix4.translationValues(
                              offset.dx,
                              offset.dy,
                              0,
                            )..scaleByDouble(scale, scale, 1, 1),
                            child: IgnorePointer(
                              ignoring: !interactive,
                              child: ExcludeSemantics(
                                excluding: !interactive,
                                child: Opacity(
                                  opacity: _folderCoverFade.transform(
                                    animation.value,
                                  ),
                                  child: _FolderSurface(
                                    key: const ValueKey(
                                      'home-routine-folder-surface',
                                    ),
                                    radius: lerpDouble(
                                      _FolderPreview.radius / startScale,
                                      28,
                                      t,
                                    )!,
                                    shadows: shadows,
                                    child: Opacity(
                                      key: const ValueKey(
                                        'home-routine-folder-content',
                                      ),
                                      opacity: _folderContentFade.transform(
                                        animation.value,
                                      ),
                                      child: child,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    ),
  );
}

class _FolderSurface extends StatelessWidget {
  const _FolderSurface({
    super.key,
    required this.radius,
    required this.child,
    this.shadows,
  });

  final double radius;
  final Widget child;
  final List<BoxShadow>? shadows;

  @override
  Widget build(BuildContext context) =>
      HipCard(radius: radius, shadows: shadows, child: child);
}

class _FolderArtwork extends StatelessWidget {
  const _FolderArtwork({
    super.key,
    required this.drill,
    required this.radius,
    this.fitThumbnail = false,
  });
  final HipDrill? drill;
  final double radius;
  final bool fitThumbnail;
  @override
  Widget build(BuildContext context) {
    final id = drill?.id;
    final asset = id == null
        ? null
        : HipPublicMedia.current?.posterAssetFor(id);
    final bounds = fitThumbnail ? libraryPosterBounds[id] : null;
    final thumbnail = bounds == null || id == null
        ? null
        : HipPublicMedia.thumbnailAssetFor(id);
    final Widget artwork;
    if (thumbnail != null && bounds != null) {
      artwork = HipPosterBoundsFit(
        sourceSize: const Size.square(libraryPosterPixels),
        bounds: bounds,
        child: trainer.TrainerPoster(asset: thumbnail),
      );
    } else if (asset != null) {
      artwork = trainer.TrainerPoster(asset: asset);
    } else {
      artwork = Center(
        child: HipIcon(HipGlyph.figure, size: 14, color: HipColors.muted),
      );
    }

    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: ColoredBox(
          color:
              (HipColors.isDark
                      ? HipColors.mediaBackdrop
                      : const Color(0xfff1f3f2))
                  .withValues(alpha: fitThumbnail ? 0 : 1),
          child: artwork,
        ),
      ),
    );
  }
}

class _FolderPanel extends StatelessWidget {
  const _FolderPanel({
    required this.choices,
    required this.selectedId,
    required this.sceneLabel,
    required this.tileHeight,
    required this.onSelect,
    this.onChooseGroups,
  });
  final List<HipHomeRoutineChoice> choices;
  final String selectedId;
  final String sceneLabel;
  final double tileHeight;
  final ValueChanged<String> onSelect;
  final VoidCallback? onChooseGroups;

  @override
  Widget build(BuildContext context) {
    final t = LibText.of(context);
    final subtitle = t.isEn
        ? '$sceneLabel · ${t.homeFolderScene}'
        : '$sceneLabel · ${t.homeFolderScene}';
    return Column(
      key: const ValueKey('home-routine-folder-panel'),
      children: [
        SizedBox(
          height: 76,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 14, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        t.isEn ? 'Home workouts' : '首页训练组',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 21,
                          height: 1.3,
                          fontWeight: FontWeight.w700,
                          color: HipColors.text,
                        ),
                      ),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          height: 1.5,
                          letterSpacing: 1,
                          color: HipColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onChooseGroups != null)
                  // The folder closes on a barrier tap or Back, so the corner
                  // button is the 训练组 entry rather than a close button.
                  HipGlassRoundButton(
                    key: const ValueKey('home-routine-choose-groups'),
                    semanticLabel: t.homeFolderEntry,
                    size: 32,
                    onTap: onChooseGroups!,
                    child: HipIcon(
                      HipGlyph.plus,
                      size: 17,
                      color: HipColors.jade,
                    ),
                  ),
              ],
            ),
          ),
        ),
        Expanded(
          child: GridView.builder(
            key: const ValueKey('home-routine-folder-grid'),
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _folderColumns,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              mainAxisExtent: tileHeight,
            ),
            itemCount: choices.length,
            itemBuilder: (context, i) {
              final choice = choices[i];
              final selected = choice.id == selectedId;
              final scene = choice.sceneLabel;
              return HipPressable(
                key: ValueKey('home-routine-choice-${choice.id}'),
                semanticLabel: t.isEn
                    ? '${scene.isEmpty ? '' : '$scene, '}${choice.title}, ${t.minutes(choice.minutes)}, ${t.movesCount(choice.drills.length)}'
                    : '${scene.isEmpty ? '' : '$scene，'}${choice.title}，${choice.minutes}分钟，${choice.drills.length}个动作',
                selected: selected,
                inMutuallyExclusiveGroup: true,
                onTap: () => onSelect(choice.id),
                scale: .97,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          _FolderArtwork(
                            drill: choice.drills.firstOrNull,
                            radius: 18,
                          ),
                          if (scene.isNotEmpty)
                            Positioned(
                              top: 8,
                              left: 8,
                              child: _SceneChip(label: scene),
                            ),
                          if (selected) ...[
                            DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: HipColors.jade,
                                  width: 1.5,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: HipColors.jade,
                                  shape: BoxShape.circle,
                                ),
                                child: HipIcon(
                                  HipGlyph.check,
                                  size: 13,
                                  color: HipColors.onJade,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 9),
                    Text(
                      choice.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                        color: HipColors.text,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${LibText.of(context).minutes(choice.minutes)} · ${LibText.of(context).movesCount(choice.drills.length)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10.5,
                        height: 1.4,
                        color: HipColors.muted,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// 办公 / 居家 on the cover: the folder lists only the current scene's 套路,
/// but the chip still makes the scene explicit.
class _SceneChip extends StatelessWidget {
  const _SceneChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: HipColors.background.withValues(alpha: .78),
      borderRadius: BorderRadius.circular(7),
      border: Border.all(color: HipColors.line.withValues(alpha: .55)),
    ),
    child: Text(
      label,
      style: TextStyle(
        fontSize: 10.5,
        height: 1.2,
        fontWeight: FontWeight.w600,
        letterSpacing: .2,
        color: HipColors.text,
      ),
    ),
  );
}
