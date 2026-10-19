// Prep / rest in the player (rep-rhythm PR): the next drill's demo is shown
// whole – no dark layer, no text on the media – and the feedback on the
// drill just done sits under it; answering it never skips or shortens the
// rest countdown.
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiplab/hip/control/hip_store.dart';
import 'package:hiplab/hip/domain/hip_models.dart';
import 'package:hiplab/hip/ui/hip_app.dart';
import 'package:hiplab/hip/ui/hip_theme.dart';
import 'package:hiplab/hip/ui/hip_widgets.dart';

import 'hip_domain_test.dart' show MemoryStorage, loadContent;

void main() {
  final content = loadContent();

  Future<HipStore> start(
    WidgetTester tester, {
    Size size = const Size(390, 844),
    double textScale = 1,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final store = HipStore(
      content: content,
      storage: MemoryStorage(),
      clock: () => DateTime(2026, 10, 16, 9, 41),
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
    return store;
  }

  Finder onMedia(Finder f) =>
      find.descendant(of: find.byType(HipMediaFrame), matching: f);

  int ringSeconds(WidgetTester tester) {
    final ring = tester.widget<HipCountdownRing>(
      find.byKey(const ValueKey('player-ring')),
    );
    return int.parse(ring.label);
  }

  testWidgets('prep: the demo is not covered – only a small tag on it', (
    tester,
  ) async {
    final store = await start(tester);
    final first = store.todayPlan!.steps.first;
    expect(onMedia(find.byKey(const ValueKey('phase-tag'))), findsOneWidget);
    expect(onMedia(find.text(first.drill.name)), findsNothing);
    expect(onMedia(find.text(first.dose)), findsNothing);
    expect(onMedia(find.textContaining('准备开始')), findsNothing);
    // no dimming layer over the picture
    expect(
      onMedia(
        find.byWidgetPredicate(
          (w) =>
              w is ColoredBox &&
              w.color.a > .3 &&
              w.color.a < 1 &&
              w.color.r < .1,
        ),
      ),
      findsNothing,
    );
    // name + dose live under the media
    expect(find.text(first.drill.name), findsOneWidget);
    expect(find.textContaining(first.dose), findsWidgets);
  });

  testWidgets('rest: all feedback labels render in the bundled font at 14', (
    tester,
  ) async {
    await start(tester);
    await tester.tap(find.byKey(const ValueKey('player-skip'))); // prep → work
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('player-skip'))); // work → rest
    await tester.pump(const Duration(seconds: 2));

    final renderedStyles = <String, TextStyle>{};
    final inheritedStyles = <String, TextStyle>{};
    for (final key in ['ok', 'tight', 'pain']) {
      final button = find.byKey(ValueKey('feel-$key'));
      expect(button, findsOneWidget);
      final label = find.descendant(of: button, matching: find.byType(Text));
      expect(label, findsOneWidget);
      final richText = find.descendant(
        of: button,
        matching: find.byType(RichText),
      );
      expect(richText, findsOneWidget);
      // Check the final paragraph, after Text/Button/Material inheritance,
      // rather than the ButtonStyle that happened to produce it.
      final paragraph = tester.renderObject<RenderParagraph>(richText);
      renderedStyles[key] = paragraph.text.style!;
      inheritedStyles[key] = DefaultTextStyle.of(tester.element(label)).style;
    }
    debugPrint(
      'feedback rendered family/size: '
      '${renderedStyles.map((key, style) => MapEntry(key, '${style.fontFamily}/${style.fontSize}'))}; '
      'inherited family: '
      '${inheritedStyles.map((key, style) => MapEntry(key, style.fontFamily))}',
    );
    expect(
      renderedStyles.values.map((style) => style.fontSize),
      everyElement(14),
      reason: 'All three actual rest feedback labels retain their 14px size.',
    );
    expect(
      renderedStyles.values.map((style) => style.fontFamily),
      everyElement(hipFontFamily),
      reason:
          'The first feedback frame must use bundled NotoSansSC rather than '
          'request a fallback font when the rest row first appears.',
    );
  });

  testWidgets('rest: feedback under the media; a tap records, never skips', (
    tester,
  ) async {
    final store = await start(tester);
    final plan = store.todayPlan!;
    await tester.tap(find.byKey(const ValueKey('player-skip'))); // prep → work
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('player-skip'))); // work → rest
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('2/${plan.steps.length}'), findsOneWidget);
    final ok = find.byKey(const ValueKey('feel-ok'));
    expect(ok, findsOneWidget);
    expect(onMedia(ok), findsNothing);
    expect(onMedia(find.byKey(const ValueKey('phase-tag'))), findsOneWidget);
    final before = ringSeconds(tester);
    await tester.tap(ok);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('已记录'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    // still the rest before drill 2: same step, countdown kept going
    expect(find.byKey(const ValueKey('feel-ok')), findsOneWidget);
    expect(find.text('2/${plan.steps.length}'), findsOneWidget);
    final after = ringSeconds(tester);
    expect(after, lessThan(before));
    expect(after, greaterThan(before - 4));
    await tester.tap(find.byKey(const ValueKey('feel-tight')));
    await tester.pump(const Duration(seconds: 1));
    expect(find.byKey(const ValueKey('feel-ok')), findsOneWidget);
    // the countdown ends on its own → the drill starts, the row goes away
    await tester.pump(Duration(seconds: after + 1));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const ValueKey('feel-ok')), findsNothing);
    expect(find.byKey(const ValueKey('player-pain')), findsOneWidget);
  });

  testWidgets('rest: 疼 opens the pain ladder; closing it keeps the rest', (
    tester,
  ) async {
    await start(tester);
    await tester.tap(find.byKey(const ValueKey('player-skip')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('player-skip')));
    await tester.pump(const Duration(seconds: 2));
    final before = ringSeconds(tester);
    await tester.tap(find.byKey(const ValueKey('feel-pain')));
    await tester.pumpAndSettle();
    expect(find.text('哪种疼？'), findsOneWidget);
    // dismiss without choosing
    await tester.tapAt(const Offset(195, 80));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('feel-ok')), findsOneWidget);
    expect(ringSeconds(tester), closeTo(before, 1));
  });

  for (final (size, scale) in [
    (const Size(320, 568), 1.0),
    (const Size(360, 740), 1.5),
    (const Size(390, 844), 1.0),
    (const Size(430, 932), 1.0),
  ]) {
    testWidgets('prep + rest fit one screen at $size ×$scale', (tester) async {
      await start(tester, size: size, textScale: scale);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byKey(const ValueKey('player-skip')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('player-skip')));
      await tester.pump(const Duration(seconds: 2));
      expect(tester.takeException(), isNull);
      for (final k in ['ok', 'tight', 'pain']) {
        final r = tester.getRect(find.byKey(ValueKey('feel-$k')));
        expect(r.bottom, lessThanOrEqualTo(size.height), reason: k);
        expect(r.right, lessThanOrEqualTo(size.width), reason: k);
      }
      await tester.tap(find.byKey(const ValueKey('feel-ok')));
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
    });
  }
}
