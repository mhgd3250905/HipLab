import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ugk_trainer_runtime/ugk_trainer_runtime.dart' as trainer;

/// SDK play/pause controls deliberately breathe while the player is paused.
/// A pain sheet pauses the player, so global pumpAndSettle cannot complete.
/// Wait only until the real pain choice is mounted and receives pointer hits.
Future<void> pumpPainSheet(WidgetTester tester) async {
  final choice = find.byKey(const ValueKey('pain-pinch')).hitTestable();
  final nerve = find.byKey(const ValueKey('pain-nerve')).hitTestable();
  await tester.pump();
  for (var frame = 0; frame < 100; frame++) {
    if (choice.evaluate().isNotEmpty && nerve.evaluate().isNotEmpty) return;
    await tester.pump(const Duration(milliseconds: 20));
  }
  expect(
    choice,
    findsOneWidget,
    reason: 'The pain sheet must be tappable within two seconds.',
  );
  expect(nerve, findsOneWidget);
}

/// Shared launcher first decodes its real poster, then completes its entry
/// transition. Native image work does not progress just by advancing fake time.
/// Yield to that work between bounded frames, then require usable live controls.
Future<void> pumpTrainerReady(WidgetTester tester) async {
  final pause = find.byKey(const ValueKey('pause')).hitTestable();
  await tester.pump();
  for (var frame = 0; frame < 150; frame++) {
    if (pause.evaluate().isNotEmpty &&
        tester.widget<trainer.UgkPlayPauseButton>(pause).isPlaying) {
      return;
    }
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 25)),
    );
    await tester.pump(const Duration(milliseconds: 10));
  }
  expect(
    pause,
    findsOneWidget,
    reason: 'Shared launcher must finish poster preparation and entry.',
  );
  expect(tester.widget<trainer.UgkPlayPauseButton>(pause).isPlaying, isTrue);
}
