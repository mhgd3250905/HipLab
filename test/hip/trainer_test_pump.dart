import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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
