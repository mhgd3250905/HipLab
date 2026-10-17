// Round-2 UI polish (2026-10-18): segmented control, the custom icon set,
// clean thumbnails, directional page transitions and shared-element heroes.
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiplab/hip/control/hip_store.dart';
import 'package:hiplab/hip/domain/hip_models.dart';
import 'package:hiplab/hip/ui/hip_app.dart';
import 'package:hiplab/hip/ui/hip_icons.dart';
import 'package:hiplab/hip/ui/hip_segmented.dart';
import 'package:hiplab/hip/ui/hip_theme.dart';
import 'package:hiplab/hip/ui/hip_widgets.dart';

import 'hip_domain_test.dart' show MemoryStorage, loadContent;

void main() {
  final content = loadContent();

  Future<HipStore> pumpApp(
    WidgetTester tester, {
    Size size = const Size(390, 844),
    HipThemeChoice theme = HipThemeChoice.dark,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final store = HipStore(
      content: content,
      storage: MemoryStorage(),
      clock: () => DateTime(2026, 10, 16, 9, 41),
    );
    await store.initialize();
    store
      ..safety = {'pregnancy': false, 'surgery': false, 'acute': false}
      ..identity = HipIdentity.office
      ..minutes = 5
      ..scene = HipScene.chair
      ..theme = theme;
    await tester.pumpWidget(HipApp(store: store, videoEnabled: false));
    await tester.pumpAndSettle();
    return store;
  }

  group('segmented control', () {
    for (final theme in [HipThemeChoice.dark, HipThemeChoice.light]) {
      testWidgets('home pickers slide one concentric thumb (${theme.id})', (
        tester,
      ) async {
        final store = await pumpApp(tester, theme: theme);
        final picker = find.byWidgetPredicate(
          (w) => w is HipSegmented<int> && w.keyPrefix == 'minutes',
        );
        expect(picker, findsOneWidget);
        final seg = tester.widget<HipSegmented<int>>(picker);
        // Concentric corners: inner radius = outer radius − inset.
        expect(seg.thumbRadius, seg.radius - seg.inset);
        final thumb = find.byKey(const ValueKey('minutes-thumb'));
        expect(thumb, findsOneWidget);
        // No outline on the selection.
        final deco =
            tester
                    .widget<DecoratedBox>(
                      find.descendant(
                        of: thumb,
                        matching: find.byType(DecoratedBox),
                      ),
                    )
                    .decoration
                as BoxDecoration;
        expect(deco.border, isNull);
        expect((deco.borderRadius! as BorderRadius).topLeft.x, seg.thumbRadius);

        final x0 = tester.getRect(thumb).left;
        final target = tester.getRect(find.byKey(const ValueKey('minutes-15')));
        await tester.tap(find.byKey(const ValueKey('minutes-15')));
        await tester.pump();
        await tester.pump(HipMotion.segment ~/ 3);
        final mid = tester.getRect(thumb).left;
        // Mid-flight: the thumb is travelling, not jumping.
        expect(mid, greaterThan(x0 + 1));
        expect(mid, lessThan(target.left - 1));
        await tester.pumpAndSettle();
        expect(store.minutes, 15);
        expect(tester.getRect(thumb).center.dx, closeTo(target.center.dx, 1));

        // The scene picker is the same control.
        await tester.tap(find.byKey(ValueKey('scene-${HipScene.home}')));
        await tester.pumpAndSettle();
        expect(store.scene, HipScene.home);
        final scene = tester.widget<HipSegmented<HipScene>>(
          find.byWidgetPredicate((w) => w is HipSegmented<HipScene>),
        );
        expect(scene.radius, seg.radius);
        expect(scene.inset, seg.inset);
        expect(scene.height, seg.height);
      });
    }

    testWidgets('dragging along the track selects', (tester) async {
      final store = await pumpApp(tester);
      final from = tester.getCenter(find.byKey(const ValueKey('minutes-5')));
      final to = tester.getCenter(find.byKey(const ValueKey('minutes-15')));
      await tester.dragFrom(from, to - from);
      await tester.pumpAndSettle();
      expect(store.minutes, 15);
    });
  });

  testWidgets('every glyph paints in both states, inside the 24 grid', (
    tester,
  ) async {
    final key = GlobalKey();
    for (final g in HipGlyph.values) {
      for (final filled in [false, true]) {
        await tester.pumpWidget(
          Center(
            child: RepaintBoundary(
              key: key,
              child: HipIcon(
                g,
                size: 48,
                filled: filled,
                color: const Color(0xff000000),
              ),
            ),
          ),
        );
        final ink = await tester.runAsync(() async {
          final boundary =
              key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          final image = await boundary.toImage();
          final data = await image.toByteData();
          final bytes = data!.buffer.asUint8List();
          var painted = 0, edge = 0;
          for (var y = 0; y < 48; y++) {
            for (var x = 0; x < 48; x++) {
              if (bytes[(y * 48 + x) * 4 + 3] > 40) {
                painted++;
                // Outside the 1-unit (2 px) outer margin of the grid.
                if (x < 2 || y < 2 || x > 45 || y > 45) edge++;
              }
            }
          }
          image.dispose();
          return (painted, edge);
        });
        expect(ink!.$1, greaterThan(40), reason: '$g filled=$filled is blank');
        expect(ink.$2, 0, reason: '$g filled=$filled bleeds out of the grid');
      }
    }
    // Ambient IconTheme colour and size are honoured (drop-in for Icon).
    await tester.pumpWidget(
      const IconTheme(
        data: IconThemeData(size: 30, color: Color(0xff3ccfa4)),
        child: Center(child: HipIcon(HipGlyph.play)),
      ),
    );
    expect(tester.getSize(find.byType(HipIcon)), const Size(30, 30));
    final painter =
        tester
                .widget<CustomPaint>(
                  find.descendant(
                    of: find.byType(HipIcon),
                    matching: find.byType(CustomPaint),
                  ),
                )
                .painter!
            as HipIconPainter;
    expect(painter.color, const Color(0xff3ccfa4));
  });

  testWidgets('no Material icons remain on the main screens', (tester) async {
    await pumpApp(tester);
    expect(find.byType(Icon), findsNothing);
    expect(find.byType(HipIcon), findsWidgets);
    for (final tab in [1, 2]) {
      await tester.tap(find.byKey(ValueKey('tab-$tab')));
      await tester.pumpAndSettle();
      expect(find.byType(Icon), findsNothing, reason: 'tab $tab');
    }
    await tester.tap(find.byKey(const ValueKey('tab-0')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('start-today')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('player-ring')), findsOneWidget);
    expect(find.byType(Icon), findsNothing);
    await tester.tap(find.byKey(const ValueKey('player-pause')));
    await tester.pumpAndSettle();
  });

  testWidgets('countdown ring draws no dot at 0 % and an arc later', (
    tester,
  ) async {
    HipColors.palette = HipPalette.dark;
    final key = GlobalKey();
    Future<List<int>> topPixel(double progress) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: RepaintBoundary(
              key: key,
              child: HipCountdownRing(
                progress: progress,
                label: '30',
                size: 100,
                color: const Color(0xff00ff00),
              ),
            ),
          ),
        ),
      );
      return (await tester.runAsync(() async {
        final b =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await b.toImage();
        final bytes = (await image.toByteData())!.buffer.asUint8List();
        // Just right of 12 o'clock on the ring (radius 44.4, stroke 5.2).
        const x = 53, y = 6;
        final i = (y * 100 + x) * 4;
        image.dispose();
        return bytes.sublist(i, i + 4);
      }))!;
    }

    final empty = await topPixel(0);
    expect(empty[1], lessThan(80), reason: 'no green dot at the top at 0 %');
    final started = await topPixel(.5);
    expect(started[1], greaterThan(60), reason: 'arc tail at the top');
  });

  testWidgets('hip-check thumbnails: one card edge, concentric clean crop', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.tap(find.byKey(const ValueKey('tab-1')));
    await tester.pumpAndSettle();
    final row = find.byKey(const ValueKey('intro-item-butterfly'));
    // No framed media box inside the row any more.
    expect(
      find.descendant(of: row, matching: find.byType(HipMediaFrame)),
      findsNothing,
    );
    final panel = tester.widget<HipPanel>(row);
    final thumb = tester.widget<HipThumb>(
      find.descendant(of: row, matching: find.byType(HipThumb)),
    );
    expect(thumb.radius, panel.radius - panel.padding.left);
  });
}
