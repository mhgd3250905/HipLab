import 'dart:convert';
import 'dart:ui' as image_ui;

// Only checks already bundled SDK artifacts, using the SDK's pinned crypto.
// No runtime dependency or pubspec change is introduced by this asset audit.
// ignore: depend_on_referenced_packages
import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiplab/hip/domain/hip_library.dart' show libraryDrills;
import 'package:hiplab/hip/ui/coach/coach_ui_brand.dart';
import 'package:hiplab/hip/ui/hip_icons.dart';
import 'package:hiplab/hip/ui/hip_theme.dart';
import 'package:ugk_coach_ui/ugk_coach_ui.dart' as ui;

import 'hip_domain_test.dart' show loadContent;

const _standing =
    'packages/ugk_trainer/assets/pose_hub/app-test-pack-r1/standing/';

class _NoImageLoads extends CachingAssetBundle {
  final loads = <String>[];
  @override
  Future<ByteData> load(String key) async {
    loads.add(key);
    throw StateError('An unknown cutout must not request an image: $key');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final content = loadContent();

  for (final palette in [HipPalette.dark, HipPalette.light]) {
    test(
      'task colours follow HipLab ${palette.brightness.name} and SF alpha roles',
      () {
        final base = ui.CoachUiColors.fromTheme(ThemeData.light()).copyWith(
          background: Colors.purple,
          text: Colors.orange,
          primaryForeground: Colors.pink,
        );
        final roles = hipCoachTaskColors(base, palette: palette);
        final previousPalette = HipColors.palette;
        try {
          HipColors.palette = palette;
          expect(hipCoachTaskColors(base).taskAccent, palette.jade);
        } finally {
          HipColors.palette = previousPalette;
        }
        final contrast = palette.isDark ? Colors.white : Colors.black;
        expect(roles.brightness, palette.brightness);
        expect(roles.taskAccent, palette.jade);
        expect(roles.taskCardSurface, palette.surface);
        expect(roles.taskText, palette.text);
        expect(roles.taskMuted, palette.muted);
        expect(
          roles.taskCardBorder,
          contrast.withValues(alpha: palette.isDark ? .08 : .06),
        );
        expect(
          roles.taskGlow,
          palette.jade.withValues(alpha: palette.isDark ? .10 : .06),
        );
        expect(
          roles.taskChipSurface,
          palette.jade.withValues(alpha: palette.isDark ? .18 : .10),
        );
        expect(
          roles.taskOrbFill,
          palette.jade.withValues(alpha: palette.isDark ? .14 : .08),
        );
        expect(
          roles.taskProgressTrack,
          contrast.withValues(alpha: palette.isDark ? .10 : .08),
        );
        expect(
          roles.taskChipBorder,
          contrast.withValues(alpha: palette.isDark ? .12 : .10),
        );
        expect(roles.taskHalo, palette.jade.withValues(alpha: .15));
        expect(roles.taskShadowNear, Colors.black.withValues(alpha: .04));
        expect(roles.taskShadowFar, Colors.black.withValues(alpha: .06));
        // Brand adaptation cannot silently replace other controls' colour roles.
        expect(roles.background, base.background);
        expect(roles.text, base.text);
        expect(roles.surface, base.surface);
        expect(roles.accent, base.accent);
        expect(roles.primaryForeground, base.primaryForeground);
      },
    );
  }

  test(
    'all 45 existing SDK standing assets match index bytes SHA and real alpha',
    () async {
      final indexData = await rootBundle.load('${_standing}index.json');
      final index =
          jsonDecode(
                utf8.decode(
                  indexData.buffer.asUint8List(
                    indexData.offsetInBytes,
                    indexData.lengthInBytes,
                  ),
                ),
              )
              as Map;
      final entries = {
        for (final entry in index['actions'] as List)
          entry['id'] as String: entry as Map,
      };
      final ids = libraryDrills(content).map((drill) => drill.id).toSet();
      expect(ids, hasLength(45));
      expect(ids, contains('w-feet-on-chair-bridge'));
      expect(ids, isNot(contains('n-thomas-test')));
      for (final id in ids) {
        final entry = entries[id]!;
        expect(entry['file'], '$id.webp');
        expect(entry['alpha'], isTrue, reason: id);
        expect((entry['sourceVideo'] as Map)['frameIndex'], 0, reason: id);
        final data = await rootBundle.load('$_standing$id.webp');
        final bytes = data.buffer.asUint8List(
          data.offsetInBytes,
          data.lengthInBytes,
        );
        expect(bytes.length, entry['bytes'], reason: id);
        expect(
          crypto.sha256.convert(bytes).toString(),
          entry['sha256'],
          reason: id,
        );
        final codec = await image_ui.instantiateImageCodec(bytes);
        final frame = await codec.getNextFrame();
        try {
          expect(frame.image.width, entry['width'], reason: id);
          expect(frame.image.height, entry['height'], reason: id);
          final raw = (await frame.image.toByteData(
            format: image_ui.ImageByteFormat.rawRgba,
          ))!;
          final rgba = raw.buffer.asUint8List(
            raw.offsetInBytes,
            raw.lengthInBytes,
          );
          var transparent = false, visible = false;
          for (
            var i = 3;
            i < rgba.length && !(transparent && visible);
            i += 4
          ) {
            transparent |= rgba[i] == 0;
            visible |= rgba[i] > 0;
          }
          expect(
            transparent && visible,
            isTrue,
            reason: '$id is a real transparent figure, not a baked poster',
          );
        } finally {
          frame.image.dispose();
          codec.dispose();
        }
      }
    },
  );

  testWidgets(
    'cutout rendering caches stable widgets and preserves image semantics',
    (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        final cutouts = hipCoachTaskCutouts(content);
        late Widget light, same, dark, larger;
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                light = cutouts(
                  context,
                  'glute-max-A',
                  const Size.square(32),
                  Brightness.light,
                );
                same = cutouts(
                  context,
                  'glute-max-A',
                  const Size.square(32),
                  Brightness.light,
                );
                dark = cutouts(
                  context,
                  'glute-max-A',
                  const Size.square(32),
                  Brightness.dark,
                );
                larger = cutouts(
                  context,
                  'glute-max-A',
                  const Size.square(40),
                  Brightness.light,
                );
                expect(
                  cutouts(
                    context,
                    'w-feet-on-chair-bridge',
                    const Size.square(32),
                    Brightness.light,
                  ),
                  isA<ClipOval>(),
                  reason:
                      'The training library includes this non-MVP-labelled action.',
                );
                return Center(child: light);
              },
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(identical(light, same), isTrue);
        expect(identical(light, dark), isFalse);
        expect(identical(light, larger), isFalse);
        final picture = tester.widget<Image>(find.byType(Image));
        expect(
          (picture.image as AssetImage).assetName,
          '${_standing}glute-max-A.webp',
        );
        expect(picture.fit, BoxFit.contain);
        expect(picture.alignment, Alignment.center);
        expect(picture.semanticLabel, content.drill('glute-max-A').name);
        expect(
          find.bySemanticsLabel(content.drill('glute-max-A').name),
          findsOneWidget,
        );
        expect(tester.getSize(find.byType(ClipOval)), const Size.square(32));
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    },
  );

  testWidgets(
    'unknown IDs and assessment-only Thomas do not load artwork or use posters',
    (tester) async {
      final bundle = _NoImageLoads();
      final cutouts = hipCoachTaskCutouts(content);
      await tester.pumpWidget(
        DefaultAssetBundle(
          bundle: bundle,
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Builder(
              builder: (context) => Column(
                children: [
                  cutouts(
                    context,
                    'unknown',
                    const Size.square(32),
                    Brightness.dark,
                  ),
                  cutouts(
                    context,
                    'n-thomas-test',
                    const Size.square(32),
                    Brightness.light,
                  ),
                  cutouts(
                    context,
                    '../../poster',
                    const Size.square(32),
                    Brightness.dark,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(Image), findsNothing);
      expect(bundle.loads, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'focus and all four SDK glyph roles reuse HipIcon and SDK sizing',
    (tester) async {
      final colors = ui.CoachUiColors.fromTheme(
        ThemeData.light(),
      ).copyWith(text: Colors.purple);
      await tester.pumpWidget(
        MaterialApp(
          home: ui.CoachUiTheme(
            style: ui.CoachUiStyle(
              colors: colors,
              typography: ui.CoachUiTypography.fromTheme(ThemeData.light()),
            ),
            child: Builder(
              builder: (context) => Row(
                children: [
                  hipCoachPlanFocusIcon(context, 14, Colors.red),
                  hipCoachPlanFocusClearIcon(context, 14, Colors.blue),
                  for (final glyph in ui.CoachGlyph.values)
                    hipCoachIconBuilder(
                      context,
                      ui.CoachIcon(
                        glyph,
                        size: 20,
                        filled: true,
                        strokeWidth: 1.5,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
      final icons = tester.widgetList<HipIcon>(find.byType(HipIcon)).toList();
      expect(icons.map((icon) => icon.glyph), [
        HipGlyph.clipboard,
        HipGlyph.close,
        HipGlyph.clipboard,
        HipGlyph.chevronRight,
        HipGlyph.play,
        HipGlyph.stop,
      ]);
      expect(icons.take(2).map((icon) => icon.size), [14, 14]);
      expect(icons.take(2).map((icon) => icon.color), [
        Colors.red,
        Colors.blue,
      ]);
      for (final icon in icons.skip(2)) {
        expect(icon.size, 20);
        expect(icon.color, Colors.purple);
        expect(icon.filled, isTrue);
        expect(icon.strokeWidth, 1.5);
      }
      expect(find.byType(Icon), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
