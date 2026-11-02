// UI r2 (2026-11-03): 更多 → 髋部自测 opens the intro page (开始自测); the
// 练习 card that used to lead there is gone.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'home_nav.dart';

Future<void> openCheckupIntro(WidgetTester tester) async {
  await openMore(tester);
  await tester.tap(find.byKey(const ValueKey('more-checkup')));
  await tester.pumpAndSettle();
}
