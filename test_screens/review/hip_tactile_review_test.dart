// PR #18 review regressions: exercise a held pointer and the actual painted
// route frame, rather than checking only the target scale or snapshot bytes.
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiplab/hip/control/hip_store.dart';
import 'package:hiplab/hip/domain/hip_models.dart';
import 'package:hiplab/hip/ui/hip_app.dart';
import 'package:hiplab/hip/ui/hip_assessment_page.dart';
import 'package:hiplab/hip/ui/hip_player_page.dart';
import 'package:hiplab/hip/ui/hip_routes.dart';
import 'package:hiplab/hip/ui/hip_segmented.dart';
import 'package:hiplab/hip/ui/hip_theme.dart';
import 'package:hiplab/hip/ui/hip_widgets.dart';

import '../../test/hip/hip_domain_test.dart' show MemoryStorage, loadContent;

HipTactilePainter _thumbPainter(WidgetTester tester) =>
    tester
            .widget<CustomPaint>(
              find.descendant(
                of: find.byKey(const ValueKey('review-thumb')),
                matching: find.byType(CustomPaint),
              ),
            )
            .painter!
        as HipTactilePainter;

Future<Uint8List> _screenPixels(
  WidgetTester tester,
  GlobalKey screenKey,
  String evidenceName,
) async {
  final boundary =
      screenKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  late Uint8List pixels;
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    pixels = Uint8List.fromList(bytes!.buffer.asUint8List());
    final evidenceDirectory = Platform.environment['HIP_REVIEW_EVIDENCE_DIR'];
    if (evidenceDirectory != null && evidenceDirectory.isNotEmpty) {
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('$evidenceDirectory/$evidenceName.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(png!.buffer.asUint8List());
    }
    image.dispose();
  });
  return pixels;
}

void _expectContinuousPixels(
  Uint8List before,
  Uint8List after,
  Rect region, {
  required String label,
}) {
  const width = 390;
  var samples = 0;
  var difference = 0;
  var visiblyChanged = 0;
  for (var y = region.top.ceil(); y < region.bottom.floor(); y++) {
    for (var x = region.left.ceil(); x < region.right.floor(); x++) {
      final offset = (y * width + x) * 4;
      var maxChannel = 0;
      for (var c = 0; c < 3; c++) {
        final delta = (before[offset + c] - after[offset + c]).abs();
        difference += delta;
        if (delta > maxChannel) maxChannel = delta;
      }
      if (maxChannel > 24) visiblyChanged++;
      samples++;
    }
  }
  final mean = difference / (samples * 3);
  final changedFraction = visiblyChanged / samples;
  // Allow subpixel anti-aliasing differences. A full-size green fill
  // appearing around a pressed 0.97-scale face is a visible discontinuity.
  expect(
    mean,
    lessThan(1),
    reason:
        '$label: frame 0 must retain the last held face; '
        'mean RGB delta=$mean, changed pixels=$changedFraction',
  );
  expect(
    changedFraction,
    lessThan(.015),
    reason:
        '$label: more than 1.5% of the origin changed by >24/255 '
        'on a channel before the route advanced',
  );
}

void main() {
  for (final reduceMotion in [false, true]) {
    testWidgets(
      'selected segment sinks while held (reduce motion: $reduceMotion)',
      (tester) async {
        final oldPalette = HipColors.palette;
        HipColors.palette = HipPalette.dark;
        addTearDown(() => HipColors.palette = oldPalette);
        var selected = 45;
        var changes = 0;
        final screenKey = GlobalKey();
        await tester.pumpWidget(
          RepaintBoundary(
            key: screenKey,
            child: MaterialApp(
              home: MediaQuery(
                data: MediaQueryData(disableAnimations: reduceMotion),
                child: Scaffold(
                  body: Center(
                    child: SizedBox(
                      width: 240,
                      child: StatefulBuilder(
                        builder: (context, setState) => HipSegmented<int>(
                          keyPrefix: 'review',
                          values: const [45, 60],
                          selected: selected,
                          label: (value) => '$value 分钟',
                          onChanged: (value) => setState(() {
                            selected = value;
                            changes++;
                          }),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final idle = _thumbPainter(tester).style;
        final evidence = reduceMotion ? 'segment-reduced' : 'segment-normal';
        await _screenPixels(tester, screenKey, 'review-$evidence-idle');
        final segment = find.byKey(const ValueKey('review-45'));
        final pointer = await tester.startGesture(tester.getCenter(segment));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 120));
        await tester.pump(const Duration(milliseconds: 120));
        if (reduceMotion) {
          for (final scale in tester.widgetList<ScaleTransition>(
            find.descendant(
              of: segment,
              matching: find.byType(ScaleTransition),
            ),
          )) {
            expect(scale.scale.value, 1);
          }
        }
        final held = _thumbPainter(tester).style;
        await _screenPixels(tester, screenKey, 'review-$evidence-held');
        // Release before asserting, so a failing regression does not leave
        // an active pointer behind for test cleanup.
        await pointer.up();
        await tester.pumpAndSettle();
        expect(
          changes,
          0,
          reason: 'holding the selected segment must not select',
        );
        expect(_thumbPainter(tester).style, idle);
        expect(
          held.highlight.a,
          lessThan(idle.highlight.a),
          reason:
              'the selected thumb must lose its top light while held, '
              'including when movement is disabled',
        );
        expect(
          held.shadows.last.color.a,
          0,
          reason: 'the ambient lift must disappear while held',
        );
      },
    );
  }

  for (final assessment in [false, true]) {
    final label = assessment ? '开始自测' : '开始';
    testWidgets('$label held release preserves the painted route frame 0', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final oldPalette = HipColors.palette;
      addTearDown(() => HipColors.palette = oldPalette);
      final store = HipStore(
        content: loadContent(),
        storage: MemoryStorage(),
        clock: () => DateTime(2026, 10, 18, 20),
      );
      await store.initialize();
      store
        ..safety = {'pregnancy': false, 'surgery': false, 'acute': false}
        ..identity = HipIdentity.dancer
        ..minutes = 10
        ..scene = HipScene.home;
      final screenKey = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: screenKey,
          child: HipApp(store: store, videoEnabled: false),
        ),
      );
      await tester.pumpAndSettle();
      if (assessment) {
        await tester.tap(find.byKey(const ValueKey('tab-1')));
        await tester.pumpAndSettle();
      }
      final button = find.byKey(
        ValueKey(assessment ? 'assessment-start' : 'start-today'),
      );
      final origin = tester.getRect(button);
      final face = find.descendant(
        of: button,
        matching: find.byType(HipTactile),
      );
      HipTactileStyle paintedStyle() =>
          (tester
                      .widget<CustomPaint>(
                        find.descendant(
                          of: face,
                          matching: find.byWidgetPredicate(
                            (widget) =>
                                widget is CustomPaint &&
                                widget.painter is HipTactilePainter,
                          ),
                        ),
                      )
                      .painter!
                  as HipTactilePainter)
              .style;
      final idle = paintedStyle();
      final pointer = await tester.startGesture(tester.getCenter(button));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));
      await tester.pump(const Duration(milliseconds: 120));
      expect(
        paintedStyle().highlight.a,
        lessThan(idle.highlight.a),
        reason: 'the fixture must really paint a held press before capture',
      );
      final evidence = assessment ? 'assessment' : 'start';
      final heldScreen = await _screenPixels(
        tester,
        screenKey,
        'review-$evidence-held',
      );
      await pointer.up();
      // No elapsed time: this is the first route paint, before expansion.
      await tester.pump();
      final page = assessment
          ? find.byType(HipAssessmentPage, skipOffstage: false)
          : find.byType(HipPlayerPage, skipOffstage: false);
      final route = ModalRoute.of(tester.element(page))! as HipRoute;
      expect(route.transition, HipTransition.expand);
      expect(route.animation!.value, 0);
      expect(
        route.originImage,
        isNotNull,
        reason: 'the comparison must exercise the snapshot path',
      );
      final firstScreen = await _screenPixels(
        tester,
        screenKey,
        'review-$evidence-frame0',
      );
      // Settle before the pixel assertions so a failure still cleans up
      // route animations normally.
      await tester.pumpAndSettle();
      _expectContinuousPixels(
        heldScreen,
        firstScreen,
        origin.deflate(1),
        label: label,
      );
    });
  }
}
