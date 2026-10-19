// PR #20 review: inspect the rendered opacity, not AnimatedOpacity's target.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiplab/core/media/media_controller.dart';
import 'package:hiplab/hip/domain/hip_action_media.dart';
import 'package:hiplab/hip/domain/hip_models.dart';
import 'package:hiplab/hip/ui/hip_theme.dart';
import 'package:hiplab/hip/ui/hip_widgets.dart';

import 'hip_domain_test.dart' show loadContent;

class _Fixture {
  _Fixture(this.drill);
  final HipDrill drill;
  final captureKey = GlobalKey();
  final views = <DrillMediaController>[];

  Future<void> show(WidgetTester tester, HipPalette palette, {bool play = true}) {
    HipColors.palette = palette;
    return tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(brightness: palette.brightness),
        home: Center(
          child: SizedBox.square(
            dimension: 240,
            child: RepaintBoundary(
              key: captureKey,
              child: HipDrillArt(
                key: const ValueKey('review-themed-art'),
                drill: drill,
                play: play,
                mediaViewBuilder: (_, controller) {
                  views.add(controller);
                  // A deliberately invalid pre-first-frame platform surface.
                  // This sentinel must never be visible through the poster.
                  return const ColoredBox(color: Color(0xffff00ff));
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Finder get cover => find.descendant(
        of: find.byKey(const ValueKey('review-themed-art')),
        matching: find.byType(AnimatedOpacity),
      ).first;

  double renderedCover(WidgetTester tester) =>
      tester.renderObject<RenderAnimatedOpacity>(cover).opacity.value;

  Future<void> preparePlayingDark(WidgetTester tester) async {
    // Warm the light poster using its real asset, before returning to dark.
    // A missing/undecoded poster must not masquerade as the opacity defect.
    await show(tester, HipPalette.light, play: false);
    await tester.pumpAndSettle();
    await show(tester, HipPalette.dark);
    await tester.pumpAndSettle();
    final dark = views.last;
    dark.receive({'source': 'drill-media', 'type': 'ready'});
    dark.receive({'source': 'drill-media', 'type': 'first-frame'});
    await tester.pump(); // Start the old poster's fade-out clock.
    await tester.pump(const Duration(milliseconds: 500));
    expect(renderedCover(tester), 0,
        reason: 'the fixture must start after the old clip is fully revealed');
  }

  Future<Uint8List> pixels(WidgetTester tester, String name) async {
    final boundary = captureKey.currentContext!.findRenderObject()!
        as RenderRepaintBoundary;
    late Uint8List pixels;
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 1);
      try {
        final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
        pixels = Uint8List.fromList(bytes!.buffer.asUint8List());
        final directory = Platform.environment['HIP_REVIEW_EVIDENCE_DIR'];
        if (directory != null && directory.isNotEmpty) {
          final png = await image.toByteData(format: ui.ImageByteFormat.png);
          final file = File('$directory/$name.png');
          await file.parent.create(recursive: true);
          await file.writeAsBytes(png!.buffer.asUint8List());
        }
      } finally {
        image.dispose();
      }
    });
    return pixels;
  }
}

void main() {
  setUp(() {
    HipMediaVariants.media = HipActionMedia.fromJson(
      jsonDecode(File(HipActionMedia.assetPath).readAsStringSync())
          as Map<String, dynamic>,
    );
  });
  tearDown(() {
    HipMediaVariants.media = HipActionMedia.empty;
    HipColors.palette = HipPalette.dark;
  });

  testWidgets('theme replacement immediately restores the rendered opaque cover', (
    tester,
  ) async {
    final fixture = _Fixture(loadContent().drill('s-kneel-hipflex'));
    await fixture.preparePlayingDark(tester);
    final old = fixture.views.last;
    await fixture.show(tester, HipPalette.light);
    final next = fixture.views.last;
    expect(next, isNot(same(old)));
    expect(next.hasFrame, isFalse);
    final target = tester.widget<AnimatedOpacity>(fixture.cover).opacity;
    final rendered = fixture.renderedCover(tester);
    await fixture.pixels(tester, 'pr20-theme-cover-first-replacement-frame');
    await tester.pumpWidget(const SizedBox());
    expect(target, 1);
    expect(rendered, 1,
        reason: 'a new WebView without a first-frame event needs an opaque '
            'poster on the same frame, not a 0-to-1 fade');
  });

  testWidgets('theme replacement pixels never expose an unready platform view', (
    tester,
  ) async {
    final fixture = _Fixture(loadContent().drill('s-kneel-hipflex'));
    await fixture.preparePlayingDark(tester);
    await fixture.show(tester, HipPalette.light);
    expect(fixture.views.last.hasFrame, isFalse);
    final bytes = await fixture.pixels(tester, 'pr20-theme-cover-sentinel');
    var exposed = 0;
    for (var i = 0; i < bytes.length; i += 4) {
      if (bytes[i] > 250 && bytes[i + 1] < 5 && bytes[i + 2] > 250) exposed++;
    }
    await tester.pumpWidget(const SizedBox());
    expect(exposed, 0,
        reason: '$exposed pixels of the pre-first-frame platform surface '
            'were exposed during a theme switch');
  });
}
