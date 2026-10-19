// PR #20: the expand fill must start with the actual themed button colour.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiplab/hip/control/hip_store.dart';
import 'package:hiplab/hip/domain/hip_models.dart';
import 'package:hiplab/hip/ui/hip_app.dart';
import 'package:hiplab/hip/ui/hip_player_page.dart';
import 'package:hiplab/hip/ui/hip_routes.dart';
import 'package:hiplab/hip/ui/hip_theme.dart';
import 'package:hiplab/hip/ui/hip_widgets.dart';

import 'hip_domain_test.dart' show MemoryStorage, loadContent;

void main() {
  testWidgets('light home start expand fill matches its actual button stage', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final oldPalette = HipColors.palette;
    final oldMedia = HipMediaVariants.media;
    addTearDown(() {
      HipColors.palette = oldPalette;
      HipMediaVariants.media = oldMedia;
    });
    final store = HipStore(
      content: loadContent(),
      storage: MemoryStorage(),
      clock: () => DateTime(2026, 10, 19, 9),
    );
    await store.initialize();
    store
      ..safety = {'pregnancy': false, 'surgery': false, 'acute': false}
      ..identity = HipIdentity.dancer
      ..minutes = 10
      ..scene = HipScene.home
      ..theme = HipThemeChoice.light;
    await tester.pumpWidget(HipApp(store: store, videoEnabled: false));
    await tester.pumpAndSettle();
    final start = find.byType(HipStartButton);
    final button = tester.widget<HipStartButton>(start);
    expect(button.stage.isDark, isFalse,
        reason: 'the fixture must load the actual bundled light media stage');
    final sourceColor = button.stage.jade;
    await tester.tap(find.byKey(const ValueKey('start-today')));
    await tester.pump();
    final route = ModalRoute.of(
      tester.element(find.byType(HipPlayerPage, skipOffstage: false)),
    )! as HipRoute;
    expect(route.transition, HipTransition.expand);
    final transitionColor = route.originColor;
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox());
    expect(transitionColor, sourceColor,
        reason: 'after the origin snapshot fades away, the expand fill must '
            'continue from the light button jade rather than dark-theme jade');
  });
}
