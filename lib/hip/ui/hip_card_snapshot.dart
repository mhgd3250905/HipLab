import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// A painted card in its original local coordinates, including its soft shadow.
/// [transform] maps the unpadded content, not the image's top-left, to the overlay.
class HipCardSnapshot {
  HipCardSnapshot({
    required this.image,
    required this.size,
    required this.padding,
    required Matrix4 transform,
  }) : transform = Matrix4.copy(transform);

  final ui.Image image;
  final Size size;
  final double padding;
  final Matrix4 transform;
  bool _disposed = false;

  Size get paddedSize =>
      Size(size.width + padding * 2, size.height + padding * 2);

  bool get isDisposed => _disposed;

  /// The dialog owns this image until its overlay has finished detaching.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    image.dispose();
  }
}

/// The ordinary repaint boundary, with a bounded capture API for a card flight.
/// It adds no layout, clipping, transform or visual decoration to its child.
class HipCardSnapshotBoundary extends SingleChildRenderObjectWidget {
  const HipCardSnapshotBoundary({super.key, super.child});

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderHipCardSnapshotBoundary();

  /// Captures only a painted boundary. Call before hiding the source card.
  /// An unavailable paint surface is a normal fallback, never a navigation error.
  static HipCardSnapshot? captureFrom(
    BuildContext sourceContext,
    BuildContext overlayContext, {
    required double pixelRatio,
  }) {
    try {
      final source = sourceContext.findRenderObject();
      final overlay = overlayContext.findRenderObject();
      if (source is! _RenderHipCardSnapshotBoundary || overlay == null) {
        return null;
      }
      return source.capture(overlay: overlay, pixelRatio: pixelRatio);
    } on Object {
      return null;
    }
  }
}

class _RenderHipCardSnapshotBoundary extends RenderRepaintBoundary {
  bool _painted = false;

  @override
  void markNeedsLayout() {
    _painted = false;
    super.markNeedsLayout();
  }

  @override
  void markNeedsPaint() {
    _painted = false;
    super.markNeedsPaint();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    super.paint(context, offset);
    _painted = true;
  }

  HipCardSnapshot? capture({
    required RenderObject overlay,
    required double pixelRatio,
    double padding = 48,
  }) {
    if (!_painted ||
        !attached ||
        !overlay.attached ||
        !hasSize ||
        size.isEmpty ||
        !size.width.isFinite ||
        !size.height.isFinite ||
        !pixelRatio.isFinite ||
        pixelRatio <= 0 ||
        !padding.isFinite ||
        padding < 0) {
      return null;
    }
    ui.Image? captured;
    try {
      // Access stays inside a render subclass; no protected or debug-only API
      // is read by a widget or used as a release-mode paint readiness check.
      final paintedLayer = layer;
      if (paintedLayer is! OffsetLayer) return null;
      final matrix = Matrix4.copy(getTransformTo(overlay));
      if (matrix.storage.any((entry) => !entry.isFinite)) return null;
      captured = paintedLayer.toImageSync(
        (Offset.zero & size).inflate(padding),
        pixelRatio: pixelRatio,
      );
      return HipCardSnapshot(
        image: captured,
        size: size,
        padding: padding,
        transform: matrix,
      );
    } on Object {
      captured?.dispose();
      return null;
    }
  }
}
