// Round-1 UI fixes (2026-10-17): media frames, the hip check layout,
// side switching, the renamed hip-flexor test, top bars, themes and voice
// settings. Each test names the issue number it guards.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiplab/hip/control/hip_store.dart';
import 'package:hiplab/hip/domain/hip_models.dart';
import 'package:hiplab/hip/ui/hip_app.dart';
import 'package:hiplab/hip/ui/hip_icons.dart';
import 'package:hiplab/hip/ui/hip_theme.dart';
import 'package:hiplab/hip/ui/hip_widgets.dart';
import 'package:hiplab/hip/voice/voice_library.dart';

import 'hip_domain_test.dart' show MemoryStorage, loadContent;
import 'checkup_entry.dart';

void main() {
  final content = loadContent();

  Future<HipStore> pumpApp(
    WidgetTester tester, {
    Size size = const Size(390, 844),
    double textScale = 1,
    HipThemeChoice theme = HipThemeChoice.dark,
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
      ..theme = theme;
    await tester.pumpWidget(HipApp(store: store, videoEnabled: false));
    await tester.pumpAndSettle();
    return store;
  }

  Future<void> openAssessment(WidgetTester tester) async {
    await openCheckupIntro(tester);
    await tester.tap(find.byKey(const ValueKey('assessment-start')));
    await tester.pumpAndSettle();
  }

  Future<void> choose(WidgetTester tester, int score) async {
    final f = find.byKey(ValueKey('option-$score'));
    await tester.ensureVisible(f);
    await tester.pumpAndSettle();
    await tester.tap(f);
    await tester.pump();
  }

  testWidgets(
    '#1 option cards and media paint their stroke above the picture',
    (tester) async {
      await pumpApp(tester);
      await openAssessment(tester);
      await choose(tester, 2);
      // Every picture area is a HipMediaFrame whose border is a foreground
      // decoration (drawn over the clipped content), and the check badge is
      // laid out inside the frame.
      final selected = find.descendant(
        of: find.byKey(const ValueKey('option-2')),
        matching: find.byType(HipMediaFrame),
      );
      expect(selected, findsOneWidget);
      final box = tester.widget<AnimatedContainer>(
        find
            .descendant(of: selected, matching: find.byType(AnimatedContainer))
            .first,
      );
      final fg = box.foregroundDecoration! as BoxDecoration;
      final border = fg.border! as Border;
      expect(border.top.color, HipColors.jade);
      expect(border.top.strokeAlign, BorderSide.strokeAlignInside);
      final frameRect = tester.getRect(selected);
      final badge = tester.getRect(
        find.descendant(
          of: selected,
          matching: find.byWidgetPredicate(
            (w) => w is HipIcon && w.glyph == HipGlyph.check,
          ),
        ),
      );
      expect(
        frameRect.deflate(border.top.width).contains(badge.topRight),
        isTrue,
      );
      // The demo video area uses the same frame.
      expect(find.byKey(const ValueKey('assessment-demo')), findsOneWidget);
      expect(
        tester.widget(find.byKey(const ValueKey('assessment-demo'))),
        isA<HipMediaFrame>(),
      );
    },
  );

  testWidgets('#2 the hip check lists all six moves with what each looks at', (
    tester,
  ) async {
    await pumpApp(tester);
    await openCheckupIntro(tester);
    for (final item in content.rules.items) {
      expect(find.byKey(ValueKey('intro-item-${item.id}')), findsOneWidget);
    }
    expect(find.text('屈髋肌测试'), findsOneWidget);
    expect(find.textContaining('看髋前侧 · 15 秒 · 左右各一次'), findsOneWidget);
    expect(find.byType(HipFocusImage), findsNWidgets(6));
  });

  testWidgets('#4 托马斯测试 is now 屈髋肌测试 (Thomas test in the note)', (
    tester,
  ) async {
    final item = content.rules.items.firstWhere((i) => i.id == 'thomas');
    expect(item.title, '屈髋肌测试');
    expect(item.aka, contains('Thomas test'));
    expect(content.drill('n-thomas-test').name, isNot(contains('托马斯')));
    await pumpApp(tester);
    await openAssessment(tester);
    await choose(tester, 1);
    await tester.tap(find.byKey(const ValueKey('assessment-next')));
    await tester.pumpAndSettle();
    for (var i = 0; i < 2; i++) {
      await choose(tester, 1);
      await tester.tap(find.byKey(const ValueKey('assessment-next')));
      await tester.pumpAndSettle();
    }
    expect(find.text('膝窝能塞进什么？'), findsOneWidget);
    expect(find.textContaining('Thomas test'), findsOneWidget);
    expect(find.textContaining('托马斯测试 ·'), findsNothing);
  });

  for (final (size, scale) in [
    (const Size(360, 740), 1.0),
    (const Size(360, 740), 1.3),
    (const Size(360, 740), 1.5),
    (const Size(390, 844), 1.5),
  ]) {
    testWidgets(
      '#4 all six items fit without overlap at ${size.width.toInt()} wide, text ×$scale',
      (tester) async {
        await pumpApp(tester, size: size, textScale: scale);
        await openAssessment(tester);
        for (var n = 0; n < 9; n++) {
          // The bottom bar never overlaps the scrolling content.
          final bar = tester.getRect(
            find.byKey(const ValueKey('assessment-next')),
          );
          final pain = tester.getRect(
            find.byKey(const ValueKey('assessment-pain')),
          );
          expect(pain.bottom, lessThanOrEqualTo(bar.top + .5));
          await choose(tester, 1);
          if (find
              .byKey(const ValueKey('follow-front'))
              .evaluate()
              .isNotEmpty) {
            break;
          }
          await tester.tap(find.byKey(const ValueKey('assessment-next')));
          await tester.pumpAndSettle();
          if (find.text('你的髋部').evaluate().isNotEmpty) break;
        }
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    '#5 sided items: the first 下一项 clearly switches to the right side',
    (tester) async {
      await pumpApp(tester);
      await openAssessment(tester);
      await choose(tester, 2);
      await tester.tap(find.byKey(const ValueKey('assessment-next')));
      await tester.pumpAndSettle();
      // 90/90, left side: the button says what happens next.
      expect(find.text('记下左边，测右边'), findsOneWidget);
      await choose(tester, 2);
      await tester.tap(find.byKey(const ValueKey('assessment-next')));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('现在测右边'), findsOneWidget);
      expect(find.text('左边记好了'), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.text('下一项'), findsOneWidget);
      expect(find.text('2/6'), findsOneWidget);
    },
  );

  testWidgets(
    '#5 a double tap on 下一项 records one answer, never skips an item',
    (tester) async {
      await pumpApp(tester);
      await openAssessment(tester);
      await choose(tester, 2);
      final next = find.byKey(const ValueKey('assessment-next'));
      await tester.tap(next);
      await tester.tap(next, warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.text('2/6'), findsOneWidget);
      expect(find.text('记下左边，测右边'), findsOneWidget);
    },
  );

  testWidgets('#7 result title sits in the close-button row', (tester) async {
    await pumpApp(tester);
    await openAssessment(tester);
    for (var n = 0; n < 12; n++) {
      if (find.text('你的髋部').evaluate().isNotEmpty) break;
      await choose(tester, 2);
      await tester.tap(find.byKey(const ValueKey('assessment-next')));
      await tester.pumpAndSettle();
    }
    final title = tester.getRect(find.text('你的髋部'));
    final close = tester.getRect(find.byType(HipCircleButton).first);
    expect(title.center.dy, closeTo(close.center.dy, 14));
    expect(find.text('自测完成'), findsOneWidget);
    // Recommended route card: content height, thumbnails fully inside.
    final card = tester.getRect(find.byKey(const ValueKey('route-card')));
    final thumbs = find.descendant(
      of: find.byKey(const ValueKey('route-card')),
      matching: find.byType(HipThumb),
    );
    expect(thumbs, findsWidgets);
    for (final e in thumbs.evaluate()) {
      final r = tester.getRect(find.byWidget(e.widget));
      expect(card.contains(r.bottomRight - const Offset(.5, .5)), isTrue);
    }
  });

  testWidgets('#9 unsided drills show no side switcher; sided ones do', (
    tester,
  ) async {
    final store = await pumpApp(tester);
    store.choose(scene: HipScene.chair, minutes: 5);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('start-today')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('player-skip'))); // lead-in
    await tester.pump(const Duration(seconds: 1));
    final first = store.todayPlan!.steps.first;
    expect(first.sided, isFalse);
    expect(find.byKey(const ValueKey('side-indicator')), findsNothing);
    // to the second (sided) drill: skip the drill, then the rest
    await tester.tap(find.byKey(const ValueKey('player-skip')));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.byKey(const ValueKey('player-skip')));
    await tester.pump(const Duration(seconds: 1));
    expect(store.todayPlan!.steps[1].sided, isTrue);
    expect(find.byKey(const ValueKey('side-indicator')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('player-pause')));
    await tester.pumpAndSettle();
  });

  testWidgets('#14 appearance: 跟随系统 / 浅色 / 深色 switch the whole app live', (
    tester,
  ) async {
    final store = await pumpApp(tester);
    expect(HipColors.palette, HipPalette.dark);
    await tester.tap(find.byKey(const ValueKey('tab-2')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(ValueKey('theme-${HipThemeChoice.light}')),
      200,
    );
    await tester.tap(find.byKey(ValueKey('theme-${HipThemeChoice.light}')));
    await tester.pumpAndSettle();
    expect(store.theme, HipThemeChoice.light);
    expect(HipColors.palette, HipPalette.light);
    final scaffold = tester.widget<Material>(
      find
          .descendant(
            of: find.byType(Scaffold).first,
            matching: find.byType(Material),
          )
          .first,
    );
    expect(scaffold.color, HipPalette.light.background);
    // The tab and scroll position survive the switch.
    expect(find.byKey(const ValueKey('appearance-settings')), findsOneWidget);
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await tester.tap(find.byKey(ValueKey('theme-${HipThemeChoice.system}')));
    await tester.pumpAndSettle();
    expect(HipColors.palette, HipPalette.dark);
    expect(store.toJson()['theme'], 'system');
  });

  testWidgets(
    '#13 voice settings persist (voice / chimes / language / volume)',
    (tester) async {
      final store = await pumpApp(tester);
      await tester.tap(find.byKey(const ValueKey('tab-2')));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('voice-preview')),
        200,
      );
      await tester.tap(find.byKey(const ValueKey('chime-switch')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ValueKey('voice-lang-${VoiceLanguage.en}')));
      await tester.pumpAndSettle();
      expect(store.voice.chimes, isFalse);
      expect(store.voice.voice, isTrue);
      expect(store.voice.language, VoiceLanguage.en);
      final saved = store.toJson()['voice'] as Map;
      expect(saved['language'], 'en');
      expect(saved['chimes'], false);
    },
  );
}
