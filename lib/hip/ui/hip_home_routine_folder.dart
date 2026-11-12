import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ugk_trainer_runtime/ugk_trainer.dart' as trainer;

import '../data/hip_public_media.dart';
import '../domain/hip_models.dart';
import 'hip_glass.dart';
import 'hip_icons.dart';
import 'hip_theme.dart';
import 'hip_widgets.dart' show HipPressable;
import 'library/lib_text.dart';

abstract final class _FolderPreview {
  // Paired corners: outer radius = art radius + the surrounding inset.
  static const radius = 12.0;
  static const artRadius = 6.0;

  static Rect cell(int index) {
    return Rect.fromLTWH(6 + (index % 2) * 28, 6 + (index ~/ 2) * 28, 24, 24);
  }
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
      miniatures: _miniatures,
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
        child: SizedBox.square(
          dimension: 64,
          child: AnimatedBuilder(
            animation:
                _route?.animation ?? const AlwaysStoppedAnimation<double>(0),
            builder: (context, child) => Opacity(
              key: const ValueKey('home-routine-folder-source'),
              // Restore in the same frame that the reverse reaches its source,
              // before overlay disposal completes in a later microtask.
              opacity:
                  _route == null ||
                      (_route!.closingCovers != null &&
                          _route!.animation!.status ==
                              AnimationStatus.dismissed)
                  ? 1
                  : 0,
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
                        rect: _FolderPreview.cell(i),
                        child: _FolderArtwork(
                          key: ValueKey(
                            'home-routine-preview-${widget.choices[i].id}',
                          ),
                          drill: miniatures[i],
                          radius: _FolderPreview.artRadius,
                        ),
                      ),
                  ],
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
    required this.miniatures,
    required this.selectedId,
    required this.sceneLabel,
    required this.reduced,
    required this.barrierText,
    this.onChooseGroups,
  }) : coverKeys = [for (final c in choices) GlobalKey(debugLabel: c.id)];

  final Rect origin;
  final List<HipHomeRoutineChoice> choices;
  final List<HipDrill?> miniatures;
  final List<GlobalKey> coverKeys;
  final viewportKey = GlobalKey();
  final String selectedId;
  final String sceneLabel;
  final bool reduced;
  final String barrierText;
  final VoidCallback? onChooseGroups;

  /// The grid holds the scene's 套路 only; 「训练组选择」 lives in the header.
  int get itemCount => choices.length;
  List<Rect?>? closingCovers;

  @override
  Duration get transitionDuration =>
      reduced ? Duration.zero : const Duration(milliseconds: 360);
  @override
  Duration get reverseTransitionDuration =>
      reduced ? Duration.zero : const Duration(milliseconds: 300);
  @override
  Color get barrierColor => Colors.black.withValues(alpha: .28);
  @override
  bool get barrierDismissible => true;
  @override
  String get barrierLabel => barrierText;

  @override
  bool didPop(String? result) {
    final viewportBox = viewportKey.currentContext?.findRenderObject();
    final viewport = viewportBox is RenderBox && viewportBox.hasSize
        ? viewportBox.localToGlobal(Offset.zero) & viewportBox.size
        : null;
    closingCovers = [
      for (final key in coverKeys)
        if (key.currentContext?.findRenderObject() case final RenderBox box
            when box.attached && box.hasSize)
          if (viewport != null &&
              viewport.contains(box.localToGlobal(Offset.zero)) &&
              viewport.contains(
                box.localToGlobal(
                  box.size.bottomRight(Offset.zero) - const Offset(.01, .01),
                ),
              ))
            box.localToGlobal(Offset.zero) & box.size
          else
            null
        else
          null,
    ];
    return super.didPop(result);
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
                // Grow left/up from the original folder's bottom-right. Only
                // clamp when a window/keyboard change puts that anchor outside
                // the current safe bounds; never recenter a normal opening.
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
                // A single 套路 still fills the two-column grid instead of
                // leaving half a row empty.
                final columns = itemCount <= 1 ? 1 : 2;
                final tileWidth = (width - 40 - (columns - 1) * 14) / columns;
                final coverHeight = tileWidth / 1.2;
                final tileHeight = coverHeight + 59;
                final rows = (itemCount / columns).ceil();
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
                  coverKeys: coverKeys,
                  viewportKey: viewportKey,
                  animation: animation,
                  columns: columns,
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
                    final t = Curves.easeInOutCubic.transform(animation.value);
                    final current = Rect.lerp(origin, target, t)!;
                    final reveal = const Interval(
                      .28,
                      .82,
                      curve: Curves.easeOut,
                    ).transform(t);
                    final handover = const Interval(.65, .94).transform(t);
                    return Stack(
                      children: [
                        Positioned.fromRect(
                          rect: current,
                          child: _FolderSurface(
                            key: const ValueKey('home-routine-folder-surface'),
                            radius: lerpDouble(_FolderPreview.radius, 32, t)!,
                          ),
                        ),
                        ClipRRect(
                          clipper: _FolderRevealClip(
                            current,
                            lerpDouble(_FolderPreview.radius, 32, t)!,
                          ),
                          child: SizedBox.expand(
                            child: Stack(
                              children: [
                                Positioned.fromRect(
                                  rect: target,
                                  child: IgnorePointer(
                                    ignoring:
                                        animation.status !=
                                        AnimationStatus.completed,
                                    child: Opacity(
                                      opacity: reveal,
                                      child: child,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        for (var i = 0; i < miniatures.length; i++)
                          Positioned.fromRect(
                            rect: Rect.lerp(
                              _FolderPreview.cell(i).shift(origin.topLeft),
                              closingCovers != null && closingCovers![i] == null
                                  ? _FolderPreview.cell(i).shift(origin.topLeft)
                                  : closingCovers?.elementAtOrNull(i) ??
                                        Rect.fromLTWH(
                                          target.left +
                                              20 +
                                              (i % columns) * (tileWidth + 14),
                                          target.top +
                                              headerHeight +
                                              (i ~/ columns) *
                                                  (tileHeight + 14),
                                          tileWidth,
                                          coverHeight,
                                        ),
                              t,
                            )!,
                            child: IgnorePointer(
                              child: ExcludeSemantics(
                                child: Opacity(
                                  opacity:
                                      closingCovers != null &&
                                          closingCovers![i] == null
                                      ? 1 - const Interval(0, .4).transform(t)
                                      : 1 - handover,
                                  child: _FolderArtwork(
                                    key: ValueKey(
                                      'home-routine-flying-${choices[i].id}',
                                    ),
                                    drill: miniatures[i],
                                    radius: lerpDouble(
                                      _FolderPreview.artRadius,
                                      18,
                                      t,
                                    )!,
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

class _FolderRevealClip extends CustomClipper<RRect> {
  const _FolderRevealClip(this.rect, this.radius);
  final Rect rect;
  final double radius;
  @override
  RRect getClip(Size size) =>
      RRect.fromRectAndRadius(rect, Radius.circular(radius));
  @override
  bool shouldReclip(_FolderRevealClip oldClipper) =>
      oldClipper.rect != rect || oldClipper.radius != radius;
}

class _FolderSurface extends StatelessWidget {
  const _FolderSurface({super.key, required this.radius, this.child});
  final double radius;
  final Widget? child;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: HipColors.background.withValues(alpha: .80),
      borderRadius: BorderRadius.circular(radius),
    ),
    child: HipGlass(radius: radius, blur: true, sigma: 18, child: child),
  );
}

class _FolderArtwork extends StatelessWidget {
  const _FolderArtwork({super.key, required this.drill, required this.radius});
  final HipDrill? drill;
  final double radius;
  @override
  Widget build(BuildContext context) {
    final asset = drill == null
        ? null
        : HipPublicMedia.current?.posterAssetFor(drill!.id);
    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: ColoredBox(
          color: HipColors.mediaBackdrop,
          child: asset == null
              ? Center(
                  child: HipIcon(
                    HipGlyph.figure,
                    size: 14,
                    color: HipColors.muted,
                  ),
                )
              : trainer.TrainerPoster(
                  asset: asset,
                  stageColor: HipColors.mediaBackdrop,
                ),
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
    required this.coverKeys,
    required this.viewportKey,
    required this.animation,
    required this.columns,
    required this.tileHeight,
    required this.onSelect,
    this.onChooseGroups,
  });
  final List<HipHomeRoutineChoice> choices;
  final String selectedId;
  final String sceneLabel;
  final List<GlobalKey> coverKeys;
  final GlobalKey viewportKey;
  final Animation<double> animation;
  final int columns;
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
          child: SizedBox(
            key: viewportKey,
            child: GridView.builder(
              key: const ValueKey('home-routine-folder-grid'),
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
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
                        child: AnimatedBuilder(
                          animation: animation,
                          builder: (context, _) => Opacity(
                            opacity: i < 4
                                ? const Interval(.65, .94).transform(
                                    Curves.easeInOutCubic.transform(
                                      animation.value,
                                    ),
                                  )
                                : 1,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                SizedBox(
                                  key: coverKeys[i],
                                  child: _FolderArtwork(
                                    drill: choice.drills.firstOrNull,
                                    radius: 18,
                                  ),
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
