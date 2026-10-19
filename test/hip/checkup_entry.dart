// The check-up moved from its own tab into 练习's 「我的髋部 · 3 分半自测」
// card (拍板 2026-10-19): tab-1 → card → the intro page (开始自测).
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> openCheckupIntro(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('tab-1')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('hip-check-card')));
  await tester.pumpAndSettle();
}
