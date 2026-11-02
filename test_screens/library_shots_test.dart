// Current practice entry: home -> More -> actions/routines or saved groups.
// flutter test --no-pub test_screens/library_shots_test.dart
// SDK owns action browsing/details/player; no SDK phase timing is simulated.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiplab/hip/domain/hip_library.dart';
import 'package:hiplab/hip/domain/hip_models.dart';
import 'package:hiplab/hip/domain/hip_settings.dart';
import 'package:ugk_trainer_runtime/ugk_trainer_runtime.dart' as trainer;

import '../test/hip/home_nav.dart';
import 'support/app_shots.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late HipContent content;
  setUpAll(() async => content = await loadShotContent());

  for (final theme in [HipThemeChoice.light, HipThemeChoice.dark]) {
    testWidgets('${theme.id} library / routines / groups / editor', (
      tester,
    ) async {
      await mountShotApp(
        tester,
        content,
        theme,
        setup: (store) => store.customRoutines.add(
          const CustomRoutine(
            id: 'review-group',
            name: '下班放松',
            steps: [CustomStep('s-butterfly'), CustomStep('s-frog')],
          ),
        ),
      );
      Future<void> shot(String name) =>
          saveAppShot(tester, 'test/_shots/library-impl/${theme.id}/$name.png');

      await openPractice(tester);
      expect(find.byType(trainer.TrainingLibraryPage), findsOneWidget);
      await shot('01-actions');
      await tester.tap(find.byKey(const ValueKey('practice-1')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('routine-card-A')), findsOneWidget);
      await shot('02-routines');
      await openMore(tester);
      await tester.tap(find.byKey(const ValueKey('more-groups')));
      await tester.pumpAndSettle();
      await shot('03-groups');
      await tester.tap(find.byKey(const ValueKey('group-card-review-group')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('editor-name')), findsOneWidget);
      await shot('04-editor');
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
