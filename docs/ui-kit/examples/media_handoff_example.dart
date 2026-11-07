// Teaching recipe: fake media, real shared-element lifecycle and completion gate.
// It does not demonstrate a native Texture, decoder, alpha shader or frame rate.
import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:hiplab/hip/ui/hip_page_kit.dart';
import 'package:hiplab/hip/ui/hip_text.dart';
import 'package:hiplab/hip/ui/hip_theme.dart';

class MediaHandoffRecipePage extends StatefulWidget {
  const MediaHandoffRecipePage({super.key});

  @override
  State<MediaHandoffRecipePage> createState() => _MediaHandoffRecipePageState();
}

class _MediaHandoffRecipePageState extends State<MediaHandoffRecipePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _morph;
  bool _expanded = false;
  bool _paused = true;
  bool _ready = false;
  int _generation = 0;
  int _frame = 0;

  @override
  void initState() {
    super.initState();
    _morph =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 380),
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed ||
              status == AnimationStatus.dismissed) {
            setState(() {
              if (status == AnimationStatus.completed && _expanded && _ready) {
                _startFakePlayback();
              }
            });
          }
        });
  }

  void _startFakePlayback() {
    _paused = false;
    _frame++;
  }

  Future<void> _open() async {
    if (_expanded || _morph.isAnimating) return;
    final generation = ++_generation;
    setState(() {
      _expanded = true;
      _paused = true;
    });
    if (MediaQuery.disableAnimationsOf(context)) {
      _morph.value = 1;
    } else {
      _morph.forward();
    }
    if (_ready) return;
    // Simulates only an asynchronous readiness callback. A production adapter
    // must report a genuinely presented native frame, never a timer as ready.
    await Future<void>.delayed(const Duration(milliseconds: 120));
    if (!mounted || generation != _generation || !_expanded) return;
    setState(() {
      _ready = true;
      if (_morph.isCompleted) _startFakePlayback();
    });
  }

  void _close() {
    if (!_expanded) return;
    ++_generation; // A late callback from the opening cannot alter the closed face.
    setState(() {
      _expanded = false;
      _paused =
          true; // Pause immediately; keep _frame and the same media child.
    });
    if (MediaQuery.disableAnimationsOf(context)) {
      _morph.value = 0;
    } else {
      _morph.reverse();
    }
  }

  void _back() {
    if (_expanded || _morph.isAnimating) {
      _close();
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    ++_generation;
    _morph.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = HipText.of(context);
    return PopScope<void>(
      canPop: !_expanded && !_morph.isAnimating,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close();
      },
      child: HipNavPage(
        title: t.pick('媒体交接样例', 'Media handoff recipe'),
        onLeading: _back,
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                t.pick(
                  '点卡片放大，点关闭缩回。观察元素编号和保留帧编号。',
                  'Tap to expand, then close. Watch the element and retained frame IDs.',
                ),
                style: TextStyle(fontSize: 14, color: HipColors.muted),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, box) {
                    final compactWidth = math.min(240.0, box.maxWidth - 24);
                    final compactHeight = math.min(260.0, box.maxHeight * .68);
                    final small = Rect.fromLTWH(
                      (box.maxWidth - compactWidth) / 2,
                      24,
                      compactWidth,
                      compactHeight,
                    );
                    final large = Rect.fromLTWH(
                      0,
                      0,
                      box.maxWidth,
                      math.max(0, box.maxHeight - 8),
                    );
                    return AnimatedBuilder(
                      animation: _morph,
                      builder: (context, child) {
                        final progress = Curves.easeOutCubic.transform(
                          _morph.value,
                        );
                        final rect = Rect.lerp(small, large, progress)!;
                        return Stack(
                          children: [
                            Positioned.fromRect(
                              rect: rect,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(
                                  lerpDouble(22, 28, progress)!,
                                ),
                                child: ColoredBox(
                                  color: HipColors.surfaceHigh,
                                  child: child,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                      // One fixed child slot, not compact ? Poster : Video.
                      child: _FakeMediaSurface(
                        key: const ValueKey('recipe-media-surface'),
                        paused: _paused,
                        ready: _ready,
                        frame: _frame,
                        expanded: _expanded,
                        onOpen: _open,
                        onClose: _close,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FakeMediaSurface extends StatefulWidget {
  const _FakeMediaSurface({
    super.key,
    required this.paused,
    required this.ready,
    required this.frame,
    required this.expanded,
    required this.onOpen,
    required this.onClose,
  });

  final bool paused, ready, expanded;
  final int frame;
  final VoidCallback onOpen, onClose;

  @override
  State<_FakeMediaSurface> createState() => _FakeMediaSurfaceState();
}

class _FakeMediaSurfaceState extends State<_FakeMediaSurface> {
  static int _nextId = 0;
  late final int _elementId = ++_nextId;

  @override
  Widget build(BuildContext context) {
    final t = HipText.of(context);
    return GestureDetector(
      key: const ValueKey('recipe-media-open'),
      behavior: HitTestBehavior.opaque,
      onTap: widget.expanded ? null : widget.onOpen,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  'ELEMENT $_elementId',
                  style: const TextStyle(fontSize: 12),
                ),
                const Spacer(),
                if (widget.expanded)
                  IconButton(
                    key: const ValueKey('recipe-media-close'),
                    tooltip: t.pick('收起', 'Collapse'),
                    onPressed: widget.onClose,
                    icon: const Icon(Icons.close),
                  ),
              ],
            ),
            Expanded(
              child: Center(
                child: Icon(
                  Icons.smart_display_outlined,
                  size: 72,
                  color: HipColors.jadeText,
                ),
              ),
            ),
            Text(
              t.pick('教学画板 · 非真实视频', 'Teaching canvas · no real video'),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: HipColors.muted),
            ),
            const SizedBox(height: 8),
            Text(
              '${widget.paused ? t.pick('暂停', 'Paused') : t.pick('播放', 'Playing')}'
              ' · ${t.pick('保留帧', 'Retained frame')} ${widget.frame}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              widget.ready
                  ? t.pick('模拟就绪', 'Simulated ready')
                  : t.pick('模拟封面', 'Simulated poster'),
              style: TextStyle(fontSize: 12, color: HipColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

/// PopupRoute.push returns at pop; completed waits until reverse/disposal finishes.
/// Build a real folder route in the host, then use this gate to commit its choice.
Future<void> commitSelectionAfterReverse<T extends Object>(
  BuildContext context,
  PopupRoute<T> route,
  ValueChanged<T> onCommit,
) async {
  final selected = await Navigator.of(context).push<T>(route);
  await route.completed;
  if (!context.mounted || selected == null) return;
  onCommit(selected);
}
