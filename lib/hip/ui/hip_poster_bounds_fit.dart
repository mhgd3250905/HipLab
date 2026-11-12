import 'package:flutter/material.dart';

/// Fits an artwork rectangle while reusing the existing poster image.
class HipPosterBoundsFit extends StatelessWidget {
  const HipPosterBoundsFit({
    super.key,
    required this.sourceSize,
    required this.bounds,
    required this.child,
  });

  final Size sourceSize;
  final Rect bounds;
  final Widget child;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final fitted = applyBoxFit(
        BoxFit.contain,
        bounds.size,
        constraints.biggest,
      ).destination;
      final scale = fitted.width / bounds.width;
      final imageSize = sourceSize * scale;
      return Center(
        child: SizedBox.fromSize(
          size: fitted,
          child: ClipRect(
            child: OverflowBox(
              alignment: Alignment.topLeft,
              minWidth: imageSize.width,
              maxWidth: imageSize.width,
              minHeight: imageSize.height,
              maxHeight: imageSize.height,
              child: Transform.translate(
                offset: -bounds.topLeft * scale,
                child: child,
              ),
            ),
          ),
        ),
      );
    },
  );
}
