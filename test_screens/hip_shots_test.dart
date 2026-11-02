// App-owned home / More / settings review; SDK player UI is unchanged.
// flutter test --no-pub test_screens/hip_shots_test.dart
// Output is git-ignored; these widget frames are not native-device evidence.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiplab/hip/domain/hip_models.dart';
import 'package:hiplab/hip/domain/hip_settings.dart';

import '../test/hip/home_nav.dart';
import 'support/app_shots.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late HipContent content;
  setUpAll(() async => content = await loadShotContent());

  for (final theme in [HipThemeChoice.light, HipThemeChoice.dark]) {
    testWidgets('${theme.id} home / More / settings', (tester) async {
      await mountShotApp(tester, content, theme);
      await saveAppShot(tester, 'test/_shots/hip/${theme.id}/01-home.png');
      await openMore(tester);
      await saveAppShot(tester, 'test/_shots/hip/${theme.id}/02-more.png');
      await openSettings(tester);
      expect(find.byKey(const ValueKey('voice-switch')), findsOneWidget);
      await saveAppShot(tester, 'test/_shots/hip/${theme.id}/03-settings.png');
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
