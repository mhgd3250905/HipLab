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

/// The former 练习 tab: 更多 → 动作库.
Future<void> openPractice(WidgetTester tester) =>
    _openRow(tester, 'more-practice');

/// The settings half of the former 进度 tab: 更多 → 设置.
Future<void> openSettings(WidgetTester tester) =>
    _openRow(tester, 'more-settings');

/// The records half of the former 进度 tab: 更多 → 训练记录.
Future<void> openRecords(WidgetTester tester) =>
    _openRow(tester, 'more-records');

/// Back to 首页 from any page opened from it.
Future<void> backHome(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    if (find
        .byKey(const ValueKey('home-more'))
        .hitTestable()
        .evaluate()
        .isNotEmpty) {
      return;
    }
    final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
    nav.pop();
    await tester.pumpAndSettle();
  }
}
