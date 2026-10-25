// Based on SmartFit's explicit article-preview interaction design. Reimplemented
// for HipLab's frozen action packs; media playback remains the SDK's code.
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:ugk_trainer/ugk_trainer.dart' as trainer;

import '../../domain/hip_models.dart';
import '../hip_icons.dart';
import '../hip_theme.dart';
import '../hip_widgets.dart';
import 'lib_text.dart';

/// Owns only which article preview may play, never training or voice state.
class HipPreviewCoordinator extends ChangeNotifier {
  String? _activeId;
  bool _enabled = true;
  int _stopRevision = 0;
  bool _disposed = false;

  String? get activeId => _activeId;
  bool get enabled => _enabled;

  void toggle(String id) {
    if (_disposed || !_enabled) return;
    _activeId = _activeId == id ? null : id;
    notifyListeners();
  }

  /// Releases retained paused previews as well as the currently playing one.
  void stop() {
    if (_disposed) return;
    _activeId = null;
    _stopRevision++;
    notifyListeners();
  }

  /// Call before leaving the article or handing control to the trainer.
  void suspend() {
    if (_disposed) return;
    _enabled = false;
    stop();
  }

  /// Returning to the article makes controls available without auto-playing.
  void resume() {
    if (_disposed || _enabled) return;
    _enabled = true;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _activeId = null;
    super.dispose();
  }
}

/// Ordinary bundled media only: no alpha assets, downloads or new catalog.
/// A manually paused SDK surface retains its frame; leaving the viewport or
/// suspending the coordinator unmounts it and releases playback.
class HipManualPreview extends StatefulWidget {
  const HipManualPreview({
    super.key,
    required this.drill,
    required this.coordinator,
    required this.slot,
    this.radius = 16,
  });

  final HipDrill drill;
  final HipPreviewCoordinator coordinator;
  final String slot;
  final double radius;

  @override
  State<HipManualPreview> createState() => _HipManualPreviewState();
}

class _HipManualPreviewState extends State<HipManualPreview>
    with WidgetsBindingObserver {
  final _video = GlobalKey();
  ScrollPosition? _position;
  bool _started = false;
  bool _measurementQueued = false;
  late int _stopRevision;

  @override
  void initState() {
    super.initState();
    _stopRevision = widget.coordinator._stopRevision;
    widget.coordinator.addListener(_changed);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final position = Scrollable.maybeOf(context)?.position;
    if (!identical(position, _position)) {
      _position?.removeListener(_measureAfterLayout);
      _position = position;
      _position?.addListener(_measureAfterLayout);
    }
    _measureAfterLayout();
  }

  @override
  void didChangeMetrics() => _measureAfterLayout();

  @override
  void didUpdateWidget(HipManualPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.coordinator != widget.coordinator) {
      oldWidget.coordinator.removeListener(_changed);
      widget.coordinator.addListener(_changed);
      _stopRevision = widget.coordinator._stopRevision;
      _started = false;
    }
    if (oldWidget.drill.id != widget.drill.id ||
        oldWidget.slot != widget.slot) {
      _started = false;
    }
    _measureAfterLayout();
  }

  void _changed() {
    if (!mounted) return;
    setState(() {
      final coordinator = widget.coordinator;
      if (!coordinator.enabled || coordinator._stopRevision != _stopRevision) {
        _started = false;
      } else if (coordinator.activeId == widget.slot) {
        _started = true;
      }
      _stopRevision = coordinator._stopRevision;
    });
    _measureAfterLayout();
  }

  void _measureAfterLayout() {
    if (!mounted || !_started || _measurementQueued) return;
    _measurementQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measurementQueued = false;
      if (!mounted || !_started) return;
      final box = _video.currentContext?.findRenderObject();
      if (box is! RenderBox || !box.attached || !box.hasSize) return;
      final viewport = RenderAbstractViewport.maybeOf(box);
      if (viewport == null || viewport is! RenderBox) return;
      final viewportBox = viewport as RenderBox;
      if (!viewportBox.hasSize) return;
      final videoRect = box.localToGlobal(Offset.zero) & box.size;
      final viewRect =
          viewportBox.localToGlobal(Offset.zero) & viewportBox.size;
      if (videoRect.overlaps(viewRect)) return;
      if (widget.coordinator.activeId == widget.slot) {
        widget.coordinator.stop();
      } else {
        // An old paused preview leaving the screen must not stop another
        // preview that the user has since started in the visible viewport.
        setState(() => _started = false);
      }
    });
  }

  @override
  void dispose() {
    widget.coordinator.removeListener(_changed);
    _position?.removeListener(_measureAfterLayout);
    WidgetsBinding.instance.removeObserver(this);
    final coordinator = widget.coordinator;
    final slot = widget.slot;
    if (coordinator.activeId == slot) {
      // A lazy list may dispose this row during its layout. Do not notify
      // siblings while that tree is locked; stop only if it is still ours.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (coordinator.activeId == slot) coordinator.stop();
      });
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final drill = widget.drill;
    final t = LibText.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final palette = dark ? HipPalette.dark : HipPalette.light;
    final video = drill.video ?? '';
    final poster = drill.poster;
    final duration = drill.duration ?? 0.0;
    final hasVideo =
        drill.mediaStatus == HipMediaStatus.video &&
        video.isNotEmpty &&
        duration > 0;
    final active =
        widget.coordinator.enabled &&
        widget.coordinator.activeId == widget.slot;
    final mediaOn =
        widget.coordinator.enabled &&
        _started &&
        hasVideo &&
        HipMediaPolicy.of(context);
    final still = poster == null
        ? const HipPendingArt(label: null)
        : Image.asset(
            HipMediaVariants.themed(poster, dark: dark),
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const HipPendingArt(label: null),
          );
    return AspectRatio(
      key: ValueKey('article-video-${widget.slot}'),
      aspectRatio: 1,
      child: SizedBox(
        key: _video,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(widget.radius),
          child: ColoredBox(
            color: palette.mediaBackdrop,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (mediaOn)
                  trainer.DrillMediaView(
                    media: trainer.DrillMedia(
                      id: drill.id,
                      videoAsset: video,
                      posterAsset: poster ?? '',
                      duration: duration,
                      posterTime: drill.posterTime,
                      lightVideoAsset: HipMediaVariants.media.lightOf(video),
                      lightPosterAsset: HipMediaVariants.lightPoster(poster),
                      theme: dark ? 'dark' : 'light',
                      videoAvailable: true,
                      bundledOnly: true,
                    ),
                    playing: true,
                    paused: !active,
                    radius: widget.radius,
                    stage: palette.mediaBackdrop,
                    errorColor: palette.muted,
                    errorLabel: t.isEn
                        ? 'The demonstration could not load.'
                        : '示范暂时加载不了',
                  )
                else
                  still,
                if (hasVideo)
                  Center(
                    child: HipCircleButton(
                      key: ValueKey('article-video-toggle-${widget.slot}'),
                      icon: active ? HipGlyph.pause : HipGlyph.play,
                      size: 60,
                      tooltip: t.isEn
                          ? '${active ? 'Pause' : 'Play'} ${drill.name} demonstration'
                          : '${active ? '暂停' : '播放'}${drill.name}示范',
                      onPressed: widget.coordinator.enabled
                          ? () => widget.coordinator.toggle(widget.slot)
                          : null,
                    ),
                  )
                else
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        t.isEn
                            ? 'No video demonstration for this move.'
                            : '此动作暂无视频示范',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: palette.muted, fontSize: 13),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
