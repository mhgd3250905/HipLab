import 'dart:typed_data';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
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

  testWidgets(
    'native RGBA production consumer preserves all edge poses while legacy control exposes clipping',
    (tester) async {
      expect(ui.ImageFilter.isShaderFilterSupported, isTrue);
      tester.view
        ..physicalSize = const Size(394, 853)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final previousPalette = HipColors.palette;
      HipColors.palette = HipPalette.light;
      addTearDown(() => HipColors.palette = previousPalette);
      final fixture = installPublicMediaFixture(sharedLibrary: true);
      final drills = loadContent().drills.values
          .where((d) => fixture.policy.actionFor(d.id) != null)
          .take(3)
          .toList();
      final poses =
          <
            ({
              String label,
              Matrix4 pose,
              Size paper,
              Rect media,
              FilterQuality? quality,
            })
          >[];
      Future<void> showDeck(String identity) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: hipTheme(HipPalette.light),
            home: HipMediaPolicy(
              videoEnabled: false,
              child: Center(
                child: SizedBox(
                  width: 394,
                  height: 600,
                  child: HipHomeActionDeck(identity: identity, drills: drills),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
      }

      void record(String label) {
        final transform = tester.widget<Transform>(
          find.byKey(const ValueKey('home-deck-pose')),
        );
        final paper = tester
            .renderObject<RenderBox>(
              find.byKey(const ValueKey('home-deck-front')),
            )
            .size;
        final area = tester.widget<Positioned>(
          find.descendant(
            of: find.byKey(const ValueKey('home-deck-live-face')),
            matching: find.byKey(const ValueKey('face-media')),
          ),
        );
        final rect = Rect.fromLTWH(
          area.left!,
          area.top!,
          area.width!,
          area.height!,
        );
        final square = rect.shortestSide;
        poses.add((
          label: label,
          pose: Matrix4.copy(transform.transform),
          paper: paper,
          media: Rect.fromCenter(
            center: rect.center,
            width: square,
            height: square,
          ),
          quality: transform.filterQuality,
        ));
      }

      for (final (direction, delta) in [
        ('up', const Offset(0, -150)),
        ('down', const Offset(0, 150)),
        ('left', const Offset(-150, 0)),
        ('right', const Offset(150, 0)),
      ]) {
        await showDeck('edge-$direction');
        record('$direction/rest');
        final gesture = tester.widget<GestureDetector>(
          find.byKey(const ValueKey('home-deck-gesture')),
        );
        gesture.onPanStart!(DragStartDetails());
        gesture.onPanUpdate!(
          DragUpdateDetails(globalPosition: Offset.zero, delta: delta),
        );
        await tester.pump();
        record('$direction/drag');
        gesture.onPanEnd!(DragEndDetails());
        await tester.pump();
        var previous = 0;
        for (final ms in [16, 80, 120, 200, 280, 360, 440, 520, 600, 680]) {
          await tester.pump(Duration(milliseconds: ms - previous));
          previous = ms;
          final number = tester
              .widget<Text>(find.byKey(const ValueKey('home-deck-position')))
              .data;
          if (number != '01') break;
          record('$direction/exit-$ms');
        }
      }
      // Do not substitute a guessed tilt for the card's production transform.
      expect(poses.length, greaterThan(8));
      await tester.pumpWidget(const SizedBox.shrink());

      Future<ui.Image> pattern(bool packed) async {
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);
        if (packed) canvas.drawColor(Colors.black, BlendMode.src);
        void ink(Color color) {
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

        ink(const Color(0xffdc283c));
        if (packed) {
          canvas.translate(0, 160);
          ink(Colors.white);
        }
        final picture = recorder.endRecording();
        final image = await picture.toImage(160, packed ? 320 : 160);
        picture.dispose();
        return image;
      }

      final images = await tester.runAsync(
        () async => [await pattern(true), await pattern(false)],
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
      final artifact =
          Platform.environment['HIPLAB_MEDIA_BOUNDARY_ARTIFACT_DIR'];
      final nativeControllers = <DrillMediaController>[];
      Future<Uint8List> capture(
        int index, {
        required bool direct,
        ui.Image? referenceImage,
        String? nativeCase,
      }) async {
        final sample = poses[index];
        final width = sample.media.width;
        final nativeController = nativeCase != null && !direct
            ? DrillMediaController()
            : null;
        if (nativeController != null) nativeControllers.add(nativeController);
        final media = direct
            ? RawImage(image: referenceImage ?? reference, fit: BoxFit.fill)
            : nativeCase != null
            ? UgkPackedAlphaVideo.source(
                sourceUri: Uri.parse('file:///synthetic-native-rgba.mp4'),
                controller: nativeController!,
                nativeAlpha: true,
              )
            : ClipRect(
                child: OverflowBox(
                  alignment: Alignment.topLeft,
                  minWidth: width,
                  maxWidth: width,
                  minHeight: width * 2,
                  maxHeight: width * 2,
                  child: ImageFiltered(
                    imageFilter: filter,
                    child: SizedBox(
                      width: width,
                      height: width * 2,
                      child: RawImage(image: packed, fit: BoxFit.fill),
                    ),
                  ),
                ),
              );
        final paper = ColoredBox(
          color: Colors.white,
          child: Stack(
            clipBehavior: Clip.none,
            children: [Positioned.fromRect(rect: sample.media, child: media)],
          ),
        );
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: RepaintBoundary(
              key: root,
              child: ColoredBox(
                color: Colors.white,
                child: Stack(
                  fit: StackFit.expand,
                  clipBehavior: Clip.hardEdge,
                  children: [
                    Positioned(
                      left: 0,
                      top: 0,
                      width: sample.paper.width,
                      height: sample.paper.height,
                      child: Transform(
                        alignment: Alignment.topLeft,
                        transform: sample.pose,
                        filterQuality: sample.quality,
                        child: paper,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        if (nativeCase != null && !direct) {
          await tester.pump();
          await tester.pump();
          expect(
            find.byKey(const ValueKey('packed-alpha-full-input')),
            findsNothing,
          );
          expect(
            find.byKey(const ValueKey('packed-alpha-gpu-filter')),
            findsNothing,
          );
          expect(find.byType(UgkPackedAlphaVideo), findsOneWidget);
        }
        return (await tester.runAsync(() async {
          final image =
              await (root.currentContext!.findRenderObject()
                      as RenderRepaintBoundary)
                  .toImage();
          final rgba = await image.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          );
          if (artifact != null) {
            final png = await image.toByteData(format: ui.ImageByteFormat.png);
            File(
              '$artifact/edge-${nativeCase ?? 'legacy'}-$index-${direct ? 'reference' : 'output'}.png',
            ).writeAsBytesSync(png!.buffer.asUint8List());
          }
          image.dispose();
          return rgba!.buffer.asUint8List();
        }))!;
      }

      Map<String, Object> compare(
        String label,
        Uint8List expected,
        Uint8List actual,
      ) {
        var dark = 0, ink = 0, error = 0;
        for (var i = 0; i < actual.length; i += 4) {
          if (actual[i] < 30 && actual[i + 1] < 30 && actual[i + 2] < 30) {
            dark++;
          }
          if (expected[i] < 240 ||
              expected[i + 1] < 240 ||
              expected[i + 2] < 240 ||
              actual[i] < 240 ||
              actual[i + 1] < 240 ||
              actual[i + 2] < 240) {
            ink++;
            for (var channel = 0; channel < 3; channel++) {
              error += (actual[i + channel] - expected[i + channel]).abs();
            }
          }
        }
        final result = <String, Object>{
          'label': label,
          'blackPixels': dark,
          'inkPixels': ink,
          'meanRgbError': ink == 0 ? 0.0 : error / (ink * 3),
        };
        return result;
      }

      final results = <Map<String, Object>>[];
      for (var index = 0; index < poses.length; index++) {
        final expected = await capture(index, direct: true);
        final actual = await capture(index, direct: false);
        final result = compare(poses[index].label, expected, actual);
        results.add(result);
        debugPrint('boundary-stats ${jsonEncode(result)}');
      }

      const fixturePath = 'test/hip/fixtures/native-alpha-unpack';
      final receipt =
          jsonDecode(File('$fixturePath/receipt.json').readAsStringSync())
              as Map<String, dynamic>;
      expect(receipt['androidDevice'], isFalse);
      for (final item in receipt['cases'] as List<dynamic>) {
        expect((item as Map<String, dynamic>)['maxChannelError'], 0);
      }
      final frames = (await tester.runAsync(() async {
        final decoded = <ui.Image>[];
        for (final name in [
          'reference-rgba.png',
          'rgba-identity.png',
          'rgba-vertical-flip.png',
        ]) {
          final codec = await ui.instantiateImageCodec(
            File('$fixturePath/$name').readAsBytesSync(),
          );
          decoded.add((await codec.getNextFrame()).image);
          codec.dispose();
        }
        return decoded;
      }))!;
      final oldPlatform = UgkPackedAlphaVideo.debugPlatform;
      final oldBuilder = UgkPackedAlphaVideo.debugRgbaTextureBuilder;
      final rgbaPlatform = _RgbaFixturePlatform();
      var gpuFrame = frames[1];
      UgkPackedAlphaVideo.debugPlatform = rgbaPlatform;
      UgkPackedAlphaVideo.debugRgbaTextureBuilder = (id) {
        expect(id, 101);
        return RawImage(image: gpuFrame, fit: BoxFit.fill);
      };
      addTearDown(() {
        UgkPackedAlphaVideo.debugPlatform = oldPlatform;
        UgkPackedAlphaVideo.debugRgbaTextureBuilder = oldBuilder;
      });
      final nativeResults = <Map<String, Object>>[];
      for (var frame = 1; frame <= 2; frame++) {
        gpuFrame = frames[frame];
        final nativeCase = frame == 1 ? 'identity' : 'st-flip';
        for (var index = 0; index < poses.length; index++) {
          final expected = await capture(
            index,
            direct: true,
            referenceImage: frames[0],
            nativeCase: nativeCase,
          );
          final actual = await capture(
            index,
            direct: false,
            nativeCase: nativeCase,
          );
          final result = compare(
            '$nativeCase/${poses[index].label}',
            expected,
            actual,
          );
          nativeResults.add(result);
          debugPrint('native-rgba-boundary-stats ${jsonEncode(result)}');
        }
      }
      expect(rgbaPlatform.rgbaCreates, greaterThan(0));
      expect(rgbaPlatform.legacyCreates, 0);
      if (artifact != null) {
        File(
          '$artifact/native-rgba-boundary-stats.json',
        ).writeAsStringSync(jsonEncode(nativeResults));
      }
      await tester.pumpWidget(const SizedBox.shrink());
      for (final controller in nativeControllers) {
        controller.dispose();
      }
      for (final image in frames) {
        image.dispose();
      }
      for (final result in nativeResults) {
        expect(
          result['blackPixels'],
          lessThanOrEqualTo(2),
          reason: result['label'].toString(),
        );
        expect(
          result['meanRgbError'],
          lessThan(4.0),
          reason: result['label'].toString(),
        );
      }
      if (artifact != null) {
        File(
          '$artifact/boundary-stats.json',
        ).writeAsStringSync(jsonEncode(results));
      }
      await tester.pumpWidget(const SizedBox.shrink());
      shader.dispose();
      packed.dispose();
      reference.dispose();
      // Diagnostic control for the pinned engine: the center is healthy, while
      // a nonlocal packed-alpha sample loses its full source at an edge. The
      // independent ANGLE-generated frames above pass through the production
      // native-RGBA consumer, not the legacy packed shader. The fixture receipt
      // separately establishes the real native shader math before this test.
      for (final result in results.where(
        (r) => r['label'].toString().endsWith('/rest'),
      )) {
        expect(
          result['blackPixels'],
          lessThanOrEqualTo(2),
          reason: result['label'].toString(),
        );
        expect(
          result['meanRgbError'],
          // This larger independent-vector canvas has about 3/255 mean edge
          // sampling error at rest; clipping errors exceed 100/255.
          lessThan(4.0),
          reason: result['label'].toString(),
        );
      }
      expect(
        results.any(
          (r) =>
              (r['meanRgbError'] as num) > 40 ||
              (r['blackPixels'] as int) > 100,
        ),
        isTrue,
        reason:
            'This control must actually reach the legacy viewport-culling bug, not only center the media.',
      );
    },
    skip: !ui.ImageFilter.isShaderFilterSupported,
  );
}

// The native capability is available even with the old ImageFilter backend
// unsupported. A decoder is not emulated here: the injected RGBA frame was
// separately produced by the real native GLSL on ANGLE and compared to a CPU
// oracle, as documented in fixtures/native-alpha-unpack/receipt.json.
class _RgbaFixturePlatform extends PackedAlphaPlatform
    implements PackedAlphaRgbaPlatform {
  int rgbaCreates = 0;
  int legacyCreates = 0;
  @override
  bool get isSupported => false;
  @override
  bool get isRgbaSupported => true;
  @override
  Stream<Map<Object?, Object?>> get events => const Stream.empty();
  @override
  Future<({int playerId, int textureId})> create(String asset) async {
    legacyCreates++;
    throw StateError(
      'Native RGBA consumer must not use the packed shader path',
    );
  }

  @override
  Future<({int playerId, int textureId})> createRgba({
    String? asset,
    Uri? sourceUri,
  }) async {
    rgbaCreates++;
    return (playerId: 1, textureId: 101);
  }

  @override
  Future<Object?> command(int playerId, String type, [Object? value]) async =>
      null;
}
