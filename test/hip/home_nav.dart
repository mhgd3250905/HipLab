// Home redesign r1 (2026-11-02): the 今日/练习/进度 tab bar is gone. 练习,
// 训练记录 and 设置 open from 首页 ⋯ → 「更多」; these helpers are the new
// entry points the tab taps used to be.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> openMore(WidgetTester tester) async {
  await backHome(tester);
  await tester.tap(find.byKey(const ValueKey('home-more')));
  await tester.pumpAndSettle();
}

Future<void> _openRow(WidgetTester tester, String key) async {
  await openMore(tester);
  await tester.tap(find.byKey(ValueKey(key)));
  await tester.pumpAndSettle();
}

/// The former 练习 tab's moves view: 更多 → 动作库.
Future<void> openPractice(WidgetTester tester) =>
    _openRow(tester, 'more-practice');

/// 更多 → 我的训练组 (UI r2: the 训练组 page, 我的 / 推荐套路).
Future<void> openGroups(WidgetTester tester) => _openRow(tester, 'more-groups');

/// The settings half of the former 进度 tab: 更多 → 设置.
Future<void> openSettings(WidgetTester tester) =>
    _openRow(tester, 'more-settings');

/// The records half of the former 进度 tab: 更多 → 训练记录.
Future<void> openRecords(WidgetTester tester) =>
    _openRow(tester, 'more-records');

/// Back to 首页 from any page opened from it.
Future<void> backHome(WidgetTester tester) async {
  final more = find.byKey(const ValueKey('home-more'));
  for (var i = 0; i < 6; i++) {
    if (more.hitTestable().evaluate().isNotEmpty) return;
    final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
    if (!nav.canPop()) {
      await tester.ensureVisible(more);
      await tester.pumpAndSettle();
      expect(more.hitTestable(), findsOneWidget);
      return;
    }
    nav.pop();
    await tester.pumpAndSettle();
  }
}

/// UI r2 M3: action cards are built lazily; scroll [key] in, then tap it.
Future<void> tapCard(WidgetTester tester, Key key) async {
  final card = find.byKey(key);
  for (final list in ['picker-list', 'practice-list']) {
    final scroll = find.descendant(
      of: find.byKey(ValueKey(list)),
      matching: find.byType(Scrollable),
    );
    if (card.evaluate().isEmpty && scroll.evaluate().isNotEmpty) {
      await tester.scrollUntilVisible(card, 300, scrollable: scroll.first);
    }
  }
  await tester.ensureVisible(card);
  await tester.pumpAndSettle();
  await tester.tap(card);
}
