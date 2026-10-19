// Tactile budget (docs/tactile-design-rationale-2026-10-19.md): the light
// skeuomorphic material is used selectively. These checks turn the
// rationale's rules into assertions over the real screens, both themes:
//
// T1 (R1) every neutral tactile tile is a segmented-control thumb;
// T2 (R2, R6) at most one accent (raised brand) object on screen, and it is
//    the home 开始 disc;
// T3 (R3) the primary CTA 开始自测 is flat: one solid fill, no tactile;
// T4 (R4) the bottom tab bar has no tactile surface; selection is a filled
//    glyph vs outline glyphs (the pre-#18 style).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiplab/hip/control/hip_store.dart';
import 'package:hiplab/hip/domain/hip_models.dart';
import 'package:hiplab/hip/domain/hip_progress.dart';
import 'package:hiplab/hip/ui/hip_app.dart';
import 'package:hiplab/hip/ui/hip_icons.dart';
import 'package:hiplab/hip/ui/hip_segmented.dart';
import 'package:hiplab/hip/ui/hip_theme.dart';
import 'package:hiplab/hip/ui/hip_widgets.dart';

import 'hip_domain_test.dart' show MemoryStorage, loadContent;
import 'checkup_entry.dart';

bool _inside<T>(Element e) {
  var found = false;
  e.visitAncestorElements((a) {
    if (a.widget is T) {
      found = true;
      return false;
    }
    return true;
  });
  return found;
}

/// Checks the on-screen tactile surfaces of whatever is visible now.
void _expectBudget(WidgetTester tester, HipPalette p, String where) {
  final faces = find.byType(HipTactile).evaluate().toList();
  var accents = 0;
  for (final e in faces) {
    final face = e.widget as HipTactile;
    final inSegment = _inside<HipSegmented>(e);
    final inStart = _inside<HipStartButton>(e);
    if (inStart) {
      accents++;
      continue;
    }
    expect(
      inSegment,
      isTrue,
      reason: '$where: tactile surface outside a segmented control (R1)',
    );
    expect(face.style, HipTactileStyle.neutral(p), reason: '$where (R1)');
  }
  expect(accents, lessThanOrEqualTo(1), reason: '$where: ≤ 1 accent (R6)');
  // Nothing in the bottom bar is raised (R4).
  for (var i = 0; i < 3; i++) {
    expect(
      find.descendant(
        of: find.byKey(ValueKey('tab-$i')),
        matching: find.byType(HipTactile),
      ),
      findsNothing,
      reason: '$where: tab $i must stay flat (R4)',
    );
  }
}

void main() {
  for (final theme in [HipThemeChoice.dark, HipThemeChoice.light]) {
    testWidgets('${theme.id}: tactile budget on home, check-up, progress', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final old = HipColors.palette;
      addTearDown(() => HipColors.palette = old);
      final store = HipStore(
        content: loadContent(),
        storage: MemoryStorage(),
        clock: () => DateTime(2026, 10, 19, 9),
      );
      await store.initialize();
      store
        ..theme = theme
        ..safety = {'pregnancy': false, 'surgery': false, 'acute': false}
        ..identity = HipIdentity.dancer
        ..minutes = 10
        ..scene = HipScene.home
        ..reminder = const ReminderSettings(enabled: true);
      await tester.pumpWidget(HipApp(store: store, videoEnabled: false));
      await tester.pumpAndSettle();
      final p = HipColors.palette;

      // Home: exactly one accent, the 开始 disc (T2).
      _expectBudget(tester, p, 'home');
      final start = find.byKey(const ValueKey('start-today'));
      expect(
        find.descendant(of: start, matching: find.byType(HipTactile)),
        findsOneWidget,
      );
      expect(
        tester
            .widget<HipTactile>(
              find.descendant(of: start, matching: find.byType(HipTactile)),
            )
            .style,
        // #20 themes the stage under the disc; the accent follows it.
        HipTactileStyle.accent(
          tester.widget<HipStartButton>(find.byType(HipStartButton)).stage,
        ),
      );

      // Tab glyphs: filled when selected, outline otherwise (T4).
      bool filled(int i) => tester
          .widget<HipIcon>(
            find.descendant(
              of: find.byKey(ValueKey('tab-$i')),
              matching: find.byType(HipIcon),
            ),
          )
          .filled;
      expect([filled(0), filled(1), filled(2)], [true, false, false]);

      // 练习: only the 动作 | 套路 | 我的 thumb is tactile (T1); the check-up
      // card's 开始自测 is a flat tinted pill.
      await tester.tap(find.byKey(const ValueKey('tab-1')));
      await tester.pumpAndSettle();
      _expectBudget(tester, p, 'practice');
      expect(find.byType(HipTactile), findsOneWidget, reason: 'one thumb');
      expect([filled(0), filled(1), filled(2)], [false, true, false]);
      for (final seg in [1, 2]) {
        await tester.tap(find.byKey(ValueKey('practice-$seg')));
        await tester.pumpAndSettle();
        _expectBudget(tester, p, 'practice segment $seg');
      }

      // Check-up intro (from the card): the primary CTA is flat (T3).
      await openCheckupIntro(tester);
      _expectBudget(tester, p, 'check-up');
      final cta = find.byKey(const ValueKey('assessment-start'));
      expect(tester.widget(cta), isA<HipPrimaryButton>());
      expect(
        find.descendant(of: cta, matching: find.byType(HipTactile)),
        findsNothing,
      );
      expect(find.byType(HipTactile), findsNothing, reason: 'no accent here');
      tester.state<NavigatorState>(find.byType(Navigator).first).pop();
      await tester.pumpAndSettle();

      // Progress + settings (scrolled): only segmented thumbs (T1).
      await tester.tap(find.byKey(const ValueKey('tab-2')));
      await tester.pumpAndSettle();
      _expectBudget(tester, p, 'progress');
      expect(
        find.byKey(const ValueKey('reminder-interval-thumb')),
        findsOneWidget,
        reason: '45 / 60 is a segmented control',
      );
      for (var i = 0; i < 4; i++) {
        await tester.drag(find.byType(ListView).first, const Offset(0, -300));
        await tester.pumpAndSettle();
        _expectBudget(tester, p, 'settings scroll $i');
      }
      expect(
        _inside<HipSegmented>(find.byType(HipTactile).evaluate().first),
        isTrue,
      );
    });
  }
}
