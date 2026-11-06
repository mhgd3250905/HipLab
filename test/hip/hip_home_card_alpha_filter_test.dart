import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ugk_trainer_runtime/ugk_trainer_runtime.dart';
import 'package:hiplab/hip/ui/hip_home_action_deck.dart';
import 'package:hiplab/hip/ui/hip_theme.dart';
import 'package:hiplab/hip/ui/hip_widgets.dart';
import 'hip_domain_test.dart' show loadContent;
import 'public_media_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'card matrix transforms an already alpha-composited image without a displaced black silhouette',
    (tester) async {
      expect(ui.ImageFilter.isShaderFilterSupported, isTrue);
      tester.view
        ..physicalSize = const Size(600, 600)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final fixture = installPublicMediaFixture(sharedLibrary: true);
      final drill = loadContent().drills.values.firstWhere(
        (d) => fixture.policy.actionFor(d.id) != null,
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: hipTheme(HipPalette.light),
          home: HipMediaPolicy(
            videoEnabled: false,
            child: Center(
              child: SizedBox(
                width: 394,
                height: 600,
                child: HipHomeActionDeck(
                  identity: 'alpha-filter',
                  drills: [drill],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final actualQuality = tester
          .widget<Transform>(find.byKey(const ValueKey('home-deck-pose')))
          .filterQuality;
      const w = 160.0;
      void silhouette(Canvas canvas, Color color) {
        final paint = Paint()..color = color;
        canvas.drawCircle(const Offset(78, 29), 18, paint);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(52, 45, 57, 92),
            const Radius.circular(12),
          ),
          paint,
        );
        canvas.drawRect(const Rect.fromLTWH(25, 132, 112, 5), paint);
        canvas.drawRect(const Rect.fromLTWH(123, 37, 2, 75), paint);
      }

      Future<ui.Image> source(bool packed) async {
        final rec = ui.PictureRecorder();
        final c = Canvas(rec);
        if (packed) {
          c.drawColor(Colors.black, BlendMode.src);
        }
        silhouette(c, const Color(0xFFDC283C));
        if (packed) {
          c.translate(0, w);
          silhouette(c, Colors.white);
        }
        final picture = rec.endRecording();
        final image = await picture.toImage(160, packed ? 320 : 160);
        picture.dispose();
        return image;
      }

      final images = await tester.runAsync(
        () async => [await source(true), await source(false)],
      );
      final packed = images![0], reference = images[1];
      final program = await tester.runAsync(
        () => ui.FragmentProgram.fromAsset(TrainerRuntimeAssets.shader),
      );
      final shader = program!.fragmentShader();
      final filter = ui.ImageFilter.compose(
        outer: ui.ImageFilter.matrix(
          Matrix4.diagonal3Values(1, .5, 1).storage,
          filterQuality: FilterQuality.low,
        ),
        inner: ui.ImageFilter.shader(shader),
      );
      final root = GlobalKey();
      final pose = Matrix4.identity()
        ..setEntry(3, 2, .0012)
        ..rotateZ(-.025)
        ..rotateX(.018)
        ..rotateY(-.10);
      Future<Uint8List> capture({
        bool direct = false,
        FilterQuality? quality,
      }) async {
        final child = direct
            ? RawImage(image: reference, fit: BoxFit.fill)
            : ClipRect(
                child: OverflowBox(
                  alignment: Alignment.topLeft,
                  minWidth: w,
                  maxWidth: w,
                  minHeight: w * 2,
                  maxHeight: w * 2,
                  child: ImageFiltered(
                    imageFilter: filter,
                    child: SizedBox(
                      width: w,
                      height: w * 2,
                      child: RawImage(image: packed, fit: BoxFit.fill),
                    ),
                  ),
                ),
              );
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: RepaintBoundary(
              key: root,
              child: ColoredBox(
                color: Colors.white,
                child: Center(
                  child: SizedBox.square(
                    dimension: w,
                    child: Transform(
                      alignment: const Alignment(0, .8),
                      transform: pose,
                      filterQuality: quality,
                      child: child,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        return (await tester.runAsync(() async {
          final image =
              await (root.currentContext!.findRenderObject()
                      as RenderRepaintBoundary)
                  .toImage();
          final rgba = await image.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          );
          image.dispose();
          return rgba!.buffer.asUint8List();
        }))!;
      }

      final expected = await capture(direct: true);
      final after = await capture(quality: actualQuality);
      Map<String, Object> stats(Uint8List candidate) {
        var dark = 0, n = 0, error = 0;
        for (var i = 0; i < candidate.length; i += 4) {
          if (candidate[i] < 30 &&
              candidate[i + 1] < 30 &&
              candidate[i + 2] < 30) {
            dark++;
          }
          if (expected[i] < 240 ||
              expected[i + 1] < 240 ||
              expected[i + 2] < 240 ||
              candidate[i] < 240 ||
              candidate[i + 1] < 240 ||
              candidate[i + 2] < 240) {
            n++;
            for (var k = 0; k < 3; k++) {
              error += (candidate[i + k] - expected[i + k]).abs();
            }
          }
        }
        return {
          'blackPixels': dark,
          'inkPixels': n,
          'meanRgbError': error / (n * 3),
        };
      }

      final result = stats(after);
      expect(
        result['blackPixels'],
        lessThanOrEqualTo(2),
        reason:
            'RGB and alpha must sample the same silhouette after card rotation/perspective',
      );
      expect(
        result['meanRgbError'],
        lessThan(2.0),
        reason:
            'Compare the real production shader against an independent transparent-vector reference',
      );
      await tester.pumpWidget(const SizedBox.shrink());
      shader.dispose();
      packed.dispose();
      reference.dispose();
    },
    // Shader pixels require --enable-impeller; ordinary Skia runs skip this.
    skip: !ui.ImageFilter.isShaderFilterSupported,
  );
}
