// Round-2 UI polish (2026-10-18): segmented control, the custom icon set,
// clean thumbnails, directional page transitions and shared-element heroes.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiplab/hip/control/hip_store.dart';
import 'package:hiplab/hip/domain/hip_models.dart';
import 'package:hiplab/hip/ui/hip_app.dart';
import 'package:hiplab/hip/ui/hip_segmented.dart';
import 'package:hiplab/hip/ui/hip_theme.dart';

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
}
