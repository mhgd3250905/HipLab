import 'package:flutter_test/flutter_test.dart';
import 'package:hiplab/hip/data/hip_action_scope.dart';
import 'package:hiplab/hip/data/hip_content_loader.dart';
import 'package:hiplab/hip/data/hip_public_media.dart';
import 'package:hiplab/hip/data/hip_shared_library.dart';
import 'package:hiplab/hip/domain/hip_library.dart';
import 'package:hiplab/hip/domain/hip_models.dart';
import 'package:hiplab/hip/ui/library/action_filter.dart';
import 'package:hiplab/hip/ui/library/lib_text.dart';

import 'hip_ai_coach_test.dart' show FileAssetBundle;
import 'public_media_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late HipContent content;

  setUpAll(() async {
    content = await loadHipContent(FileAssetBundle());
  });
  setUp(() {
    installPublicMediaFixture(sharedLibrary: true);
  });

  test('muscle terms find glute and iliopsoas actions beyond their names', () {
    final all = hipActionItems(content, LibText.zh);
    for (final (query, id) in const [
      ('臀', 'h-bulgarian'),
      ('髂腰', 'h-band-straight-leg-raise'),
    ]) {
      final action = all.firstWhere((a) => a.id == id);
      expect(action.name, isNot(contains(query)));
      expect(ActionFilter(query: query).apply(all), contains(action));
    }
  });

  test(
    'muscle search intersects HipLab part, equipment, type, place and level',
    () {
      final all = hipActionItems(content, LibText.zh);
      final action = all.firstWhere((a) => a.id == 'h-band-straight-leg-raise');
      const filter = ActionFilter(
        query: '髂腰',
        parts: {'髋前侧'},
        equipment: {'弹力带'},
        types: {hipTypeStrength},
        places: {'居家'},
        levels: {1},
      );
      expect(filter.apply(all), contains(action));
      expect(
        filter.copyWith(parts: {'臀部'}).apply(all),
        isNot(contains(action)),
      );
      expect(
        filter.copyWith(equipment: {'哑铃'}).apply(all),
        isNot(contains(action)),
      );
      expect(
        filter.copyWith(types: {hipTypeRelax}).apply(all),
        isNot(contains(action)),
      );
      expect(
        filter.copyWith(places: {'办公室'}).apply(all),
        isNot(contains(action)),
      );
      expect(filter.copyWith(levels: {3}).apply(all), isNot(contains(action)));
    },
  );

  test('English names remain searchable alongside Chinese muscle terms', () {
    final all = hipActionItems(content, LibText.en);
    final action = all.firstWhere((a) => a.id == 'h-bulgarian');
    expect(action.name, 'Bulgarian Split Squat');
    expect(const ActionFilter(query: 'bulgarian').apply(all), contains(action));
    expect(const ActionFilter(query: '臀').apply(all), contains(action));
  });

  test(
    'new search terms keep browsing and group selection within existing scope',
    () {
      final all = hipActionItems(content, LibText.zh);
      final expected = hiplabCoachAuthorizedActionIds.difference(
        assessmentOnlyDrills,
      );
      expect(all.map((a) => a.id).toSet(), expected);
      expect(all.map((a) => a.id), isNot(contains('n-thomas-test')));
      expect(all.map((a) => a.id), isNot(contains('h-db-shrug')));
      for (final query in ['臀', '髂腰', 'dumbbell', '']) {
        final results = ActionFilter(query: query).apply(all);
        expect(results.every((a) => expected.contains(a.id)), isTrue);
        expect(
          results
              .where((a) => a.canAddToGroup)
              .every((a) => expected.contains(a.id)),
          isTrue,
        );
      }
    },
  );

  test(
    'content-only loading reuses the SDK muscle vocabulary before media is installed',
    () {
      HipPublicMedia.current = null;
      HipSharedLibrary.current = null;
      final all = hipActionItems(content, LibText.zh);
      final action = all.firstWhere((a) => a.id == 'h-band-straight-leg-raise');
      expect(const ActionFilter(query: '髂腰').apply(all), contains(action));
    },
  );
}
