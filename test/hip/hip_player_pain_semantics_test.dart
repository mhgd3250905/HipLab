import 'dart:ui' show SemanticsAction;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiplab/hip/control/hip_store.dart';
import 'package:hiplab/hip/domain/hip_models.dart';
import 'package:hiplab/hip/ui/hip_app.dart';

import 'hip_domain_test.dart' show MemoryStorage, loadContent;

void main() {
  testWidgets('video pain action retains a named semantic button and tap', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final store = HipStore(
        content: loadContent(),
        storage: MemoryStorage(),
        clock: () => DateTime(2026, 10, 19, 9),
      );
      await store.initialize();
      store
        ..safety = {'pregnancy': false, 'surgery': false, 'acute': false}
        ..identity = HipIdentity.office
        ..scene = HipScene.chair
        ..minutes = 5;
      await tester.pumpWidget(HipApp(store: store, videoEnabled: false));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('start-today')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('player-skip')));
      await tester.pumpAndSettle();

      final pain = find.byKey(const ValueKey('player-pain'));
      expect(pain, findsOneWidget);
      final data = tester.getSemantics(pain).getSemanticsData();
      expect(data.label, '疼');
      expect(data.hasAction(SemanticsAction.tap), isTrue);
      expect(
        data.flagsCollection.isButton,
        isTrue,
        reason:
            'A flat video action must retain its screen-reader button role.',
      );

      await tester.tap(pain);
      await tester.pumpAndSettle();
      expect(find.text('哪种疼？'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    } finally {
      semantics.dispose();
    }
  });
}
