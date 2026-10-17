import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiplab/hip/control/hip_store.dart';
import 'package:hiplab/hip/domain/hip_models.dart';
import 'package:hiplab/hip/ui/hip_app.dart';
import 'package:hiplab/hip/ui/hip_privacy_page.dart';

import 'hip_domain_test.dart' show MemoryStorage, loadContent;

void main() {
  testWidgets('progress keeps the published privacy policy reachable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final store = HipStore(content: loadContent(), storage: MemoryStorage());
    await store.initialize();
    store.safety = {'pregnancy': false, 'surgery': false, 'acute': false};
    store.identity = HipIdentity.office;
    await tester.pumpWidget(HipApp(store: store, videoEnabled: false));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('tab-2')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('隐私政策'), 400);
    await tester.tap(find.text('隐私政策'));
    await tester.pumpAndSettle();
    expect(find.byType(HipPrivacyPage), findsOneWidget);
    await tester.scrollUntilVisible(
      find.textContaining('mhgd3250905@gmail.com'),
      400,
      scrollable: find
          .descendant(
            of: find.byType(HipPrivacyPage),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(find.textContaining('mhgd3250905@gmail.com'), findsOneWidget);
  });
}
