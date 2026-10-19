// PR #22 P3 (Web acceptance 2026-10-19): at 360 wide with the system text
// size at 2.0, light and dark, the 练习 page must not overflow and must not
// cut its key text with an ellipsis — the 自测 card title / caption, the
// segment labels, the drill cards' names, routine and group cards. Long
// copy wraps instead.
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiplab/hip/control/hip_store.dart';
import 'package:hiplab/hip/domain/hip_assessment.dart';
import 'package:hiplab/hip/domain/hip_library.dart';
import 'package:hiplab/hip/domain/hip_models.dart';
import 'package:hiplab/hip/ui/hip_app.dart';
import 'package:hiplab/hip/ui/hip_theme.dart';
import 'package:hiplab/hip/voice/voice_queue.dart';

import 'hip_domain_test.dart' show MemoryStorage, loadContent;

final _now = DateTime(2026, 10, 19, 9, 41);

void main() {
  final content = loadContent();

  void addAssessment(HipStore s) {
    ItemAnswer one(int v) => ItemAnswer.single(SideAnswer.choice(v));
    ItemAnswer two(int l, int r) => ItemAnswer.sided(
      left: SideAnswer.choice(l),
      right: SideAnswer.choice(r),
    );
    s.assessments.add((
      at: DateTime(2026, 10, 18, 20),
      answers: {
        'butterfly': one(1),
        'ninety_ninety': two(1, 1),
        'thomas': two(0, 1),
        'supine_cross': two(1, 1),
        'seated_fold': one(2),
        'deep_squat': one(2),
      },
    ));
  }

  Future<void> pumpPractice(
    WidgetTester tester, {
    required Brightness brightness,
    required bool tested,
  }) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    tester.platformDispatcher.platformBrightnessTestValue = brightness;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    final store = HipStore(
      content: content,
      storage: MemoryStorage(),
      clock: () => _now,
    );
    await store.initialize();
    store
      ..safety = {'pregnancy': false, 'surgery': false, 'acute': false}
      ..identity = HipIdentity.office
      ..voice = const VoiceSettings(chimes: false)
      ..theme = brightness == Brightness.dark
          ? HipThemeChoice.dark
          : HipThemeChoice.light;
    if (tested) addAssessment(store);
    store.customRoutines.add(
      copyRoutine(
        content.routine('F'),
        content,
        id: 'f-copy',
        name: '晚上睡前放松髋部训练',
        at: _now,
      ),
    );
    await tester.pumpWidget(HipApp(store: store, videoEnabled: false));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('tab-1')));
    await tester.pumpAndSettle();
  }

  /// Texts on screen inside the 练习 list that were cut (ellipsis or
  /// maxLines exceeded), with their full string.
  List<String> cutTexts(WidgetTester tester) {
    final out = <String>[];
    final list = find.byKey(const ValueKey('practice-list'));
    for (final e
        in find
            .descendant(of: list, matching: find.byType(RichText))
            .evaluate()) {
      final p = e.renderObject;
      if (p is! RenderParagraph || !p.attached || !p.hasSize) continue;
      if (p.didExceedMaxLines) out.add(p.text.toPlainText());
    }
    return out;
  }

  Finder practiceScrollable() => find
      .descendant(
        of: find.byKey(const ValueKey('practice-list')),
        matching: find.byType(Scrollable),
      )
      .first;

  /// Walks the list top to bottom, collecting cut texts at every stop.
  Future<Set<String>> scanList(WidgetTester tester) async {
    final cut = <String>{...cutTexts(tester)};
    final pos = tester.state<ScrollableState>(practiceScrollable()).position;
    var guard = 0;
    while (pos.pixels < pos.maxScrollExtent && guard++ < 40) {
      pos.jumpTo((pos.pixels + 300).clamp(0, pos.maxScrollExtent));
      await tester.pump();
      cut.addAll(cutTexts(tester));
    }
    pos.jumpTo(0);
    await tester.pump();
    return cut;
  }

  for (final brightness in [Brightness.light, Brightness.dark]) {
    for (final tested in [false, true]) {
      final label = '${brightness.name} ${tested ? '已自测' : '未自测'}';
      testWidgets('P3 360×780 ×2.0 $label: 自测卡 title and caption are not '
          'cut, no overflow', (tester) async {
        await pumpPractice(tester, brightness: brightness, tested: tested);
        expect(tester.takeException(), isNull);
        final card = find.byKey(const ValueKey('hip-check-card'));
        expect(card, findsOneWidget);
        for (final e
            in find
                .descendant(of: card, matching: find.byType(RichText))
                .evaluate()) {
          final p = e.renderObject as RenderParagraph;
          expect(
            p.didExceedMaxLines,
            isFalse,
            reason: '自测卡 cut: "${p.text.toPlainText()}"',
          );
        }
        expect(
          find.descendant(of: card, matching: find.text('3 分半自测')),
          findsOneWidget,
        );
        // The start / retest pill stays fully on the card.
        final pill = tester.getRect(find.byKey(const ValueKey('check-start')));
        final box = tester.getRect(card);
        expect(
          box.contains(pill.topLeft) &&
              box.contains(pill.bottomRight - const Offset(1, 1)),
          isTrue,
        );
      });

      testWidgets('P3 360×780 ×2.0 $label: 动作 / 套路 / 我的 texts are not '
          'cut, no overflow', (tester) async {
        await pumpPractice(tester, brightness: brightness, tested: tested);
        final cut = <String, Set<String>>{};
        for (final seg in [0, 1, 2]) {
          await tester.tap(find.byKey(ValueKey('practice-$seg')));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: 'segment $seg');
          final c = await scanList(tester);
          expect(tester.takeException(), isNull, reason: 'segment $seg scroll');
          if (c.isNotEmpty) cut['$seg'] = c;
        }
        expect(cut, isEmpty, reason: 'cut texts by segment: $cut');
      });
    }
  }
}
