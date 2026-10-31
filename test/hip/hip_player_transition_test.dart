// Trainer 0.2 stage: the App supplies media and a rest feedback pendant;
// the SDK owns the top information card and transport. Answering the
// feedback never skips or shortens the rest countdown.
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiplab/hip/control/hip_store.dart';
import 'package:hiplab/hip/domain/hip_models.dart';
import 'package:hiplab/hip/ui/hip_app.dart';
import 'package:hiplab/hip/ui/hip_theme.dart';
import 'package:hiplab/hip/ui/hip_widgets.dart';

import 'package:ugk_trainer/ugk_trainer.dart' as trainer;

import 'hip_domain_test.dart' show MemoryStorage, loadContent;
import 'trainer_test_pump.dart';

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

  // The SDK owns overlay placement outside App's media builder. Check the
  // actual media bounds so an external overlay is covered by this guard too.
  Finder onMedia(Finder f) => find.byElementPredicate((element) {
    if (!f.evaluate().contains(element)) return false;
    final art = find.byType(HipDrillArt).first.evaluate().single.renderObject;
    final target = element.renderObject;
    if (art is! RenderBox ||
        target is! RenderBox ||
        !art.hasSize ||
        !target.hasSize) {
      return false;
    }
    final bounds = art.localToGlobal(Offset.zero) & art.size;
    final rect = target.localToGlobal(Offset.zero) & target.size;
    return rect.overlaps(bounds.deflate(.5));
  });

  int ringSeconds(WidgetTester tester) {
    final ring = tester.widget<trainer.TrainerCountdownDigits>(
      find.byType(trainer.TrainerCountdownDigits),
    );
    return int.parse(ring.value);
  }

  testWidgets('prep: the top card and App demo follow the shared stage', (
    tester,
  ) async {
    final store = await start(tester);
    final first = store.todayPlan!.steps.first;
    final prep = find.textContaining('准备 · 第一个动作');
    expect(prep, findsOneWidget);
    expect(onMedia(prep), findsNothing);
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
    // Name + authored dose live in the shared top card, outside the demo.
    expect(find.text(first.drill.name), findsOneWidget);
    expect(find.textContaining(first.dose), findsWidgets);
  });

  testWidgets('rest: all feedback labels render in the bundled font at 14', (
    tester,
  ) async {
    await start(tester);
    await tester.tap(find.byKey(const ValueKey('skip'))); // prep → work
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('skip'))); // work → rest
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

  testWidgets('rest: App feedback pendant records without skipping', (
    tester,
  ) async {
    final store = await start(tester);
    final plan = store.todayPlan!;
    await tester.tap(find.byKey(const ValueKey('skip'))); // prep → work
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('skip'))); // work → rest
    await tester.pump(const Duration(seconds: 2));
    expect(
      tester
          .widget<Semantics>(find.byKey(const ValueKey('index')))
          .properties
          .label,
      '2 / ${plan.steps.length}',
    );
    final ok = find.byKey(const ValueKey('feel-ok'));
    expect(ok, findsOneWidget);
    expect(
      find.descendant(of: find.byType(HipDrillArt), matching: ok),
      findsNothing,
    );
    // The SDK places this HUD tag on the stage edge; the App does not own
    // whether that edge overlaps the video rectangle at a given viewport.
    expect(find.byKey(const ValueKey('tag-next')), findsOneWidget);
    final before = ringSeconds(tester);
    await tester.tap(ok);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('已记录'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    // still the rest before drill 2: same step, countdown kept going
    expect(find.byKey(const ValueKey('feel-ok')), findsOneWidget);
    expect(
      tester
          .widget<Semantics>(find.byKey(const ValueKey('index')))
          .properties
          .label,
      '2 / ${plan.steps.length}',
    );
    final after = ringSeconds(tester);
    expect(after, lessThan(before));
    expect(after, greaterThan(before - 4));
    await tester.tap(find.byKey(const ValueKey('feel-tight')));
    await tester.pump(const Duration(seconds: 1));
    expect(find.byKey(const ValueKey('feel-ok')), findsOneWidget);
    // the countdown ends on its own → the drill starts, the row goes away
    await tester.pump(Duration(seconds: after + 1));
    await tester.pump(
      trainer.TrainerMotion.calm + const Duration(milliseconds: 20),
    );
    expect(find.byKey(const ValueKey('feel-ok')), findsNothing);
    expect(find.byKey(const ValueKey('discomfort')), findsOneWidget);
  });

  testWidgets('rest: 疼 opens the pain ladder; closing it keeps the rest', (
    tester,
  ) async {
    await start(tester);
    await tester.tap(find.byKey(const ValueKey('skip')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('skip')));
    await tester.pump(const Duration(seconds: 2));
    final before = ringSeconds(tester);
    await tester.tap(find.byKey(const ValueKey('feel-pain')));
    await pumpPainSheet(tester);
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
    testWidgets('prep + rest controls stay reachable at $size ×$scale', (
      tester,
    ) async {
      await start(tester, size: size, textScale: scale);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byKey(const ValueKey('skip')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('skip')));
      await tester.pump(const Duration(seconds: 2));
      expect(tester.takeException(), isNull);
      // The shared stage keeps feedback and transport in fixed visible slots.
      await tester.ensureVisible(find.byKey(const ValueKey('feel-ok')));
      await tester.pump(trainer.TrainerMotion.fast);
      for (final k in ['ok', 'tight', 'pain']) {
        final r = tester.getRect(find.byKey(ValueKey('feel-$k')));
        expect(r.bottom, lessThanOrEqualTo(size.height), reason: k);
        expect(r.right, lessThanOrEqualTo(size.width), reason: k);
      }
      await tester.tap(find.byKey(const ValueKey('feel-ok')));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('已记录'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
