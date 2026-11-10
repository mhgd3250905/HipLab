import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiplab/hip/coach/hip_coach_profile.dart';
import 'package:hiplab/hip/data/hip_action_scope.dart';
import 'package:hiplab/hip/data/hip_public_catalog.dart';
import 'package:hiplab/hip/data/hip_public_media.dart';
import 'package:hiplab/hip/domain/hip_models.dart';
import 'package:hiplab/hip/ui/coach/hip_coach_visuals.dart';
import 'package:hiplab/hip/ui/hip_theme.dart';
import 'package:ugk_coach/ugk_coach.dart' as coach;
import 'package:ugk_trainer_runtime/ugk_trainer_runtime.dart' as trainer;

HipContent _content() {
  final content = HipContent.fromJson(
    jsonDecode(File('assets/hip/hip-content.json').readAsStringSync())
        as Map<String, dynamic>,
  );
  final index =
      jsonDecode(File('assets/action_kits/index.json').readAsStringSync())
          as Map<String, dynamic>;
  return content.withKits({
    for (final path in index['kits'] as List)
      (path as String)
          .split('/')
          .last
          .replaceAll('.json', ''): ActionKit.fromJson(
        jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>,
      ),
  });
}

class _BytesOnlyAssets extends CachingAssetBundle {
  final loaded = <String>[];

  @override
  Future<ByteData> load(String key) async {
    loaded.add(key);
    final bytes = File(key).readAsBytesSync();
    // Exercise offset/length handling as well as the large-asset byte path.
    final padded = Uint8List(bytes.length + 8)
      ..setRange(4, bytes.length + 4, bytes);
    return ByteData.sublistView(padded, 4, bytes.length + 4);
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) =>
      throw StateError('Catalog loading must retain the byte path');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final pack = coach.PoseHubAppTestCatalog.fromBytes(
    File(hipPublicCatalogAsset).readAsBytesSync(),
    semanticCatalogBytes: File(hipPublicSemanticsAsset).readAsBytesSync(),
  );
  final rhythms = hipPublicRhythms(pack);
  final catalog = hipCoachCatalogFromPublic(pack, rhythms: rhythms);
  final content = _content().withPublicTraining(catalog, rhythms);
  final profile = hiplabCoachAppProfile(
    catalog: catalog,
    coachProfile: hiplabCoachProfile,
    executionTiming: (_) => throw StateError('Not invoked by profile tests'),
    content: content,
  );

  setUpAll(() async {
    HipPublicMedia.current = await HipPublicMedia.load(
      rootDirectory: 'build/test-public-media/profile-cache',
      prefetchBeforeTraining: false,
    );
  });
  tearDownAll(() => HipPublicMedia.current?.repository.dispose());

  test('one fixed list admits the 248 training actions to Coach', () {
    expect(pack.allActions, hasLength(249));
    expect(pack.pendingActions, isEmpty);
    expect(hiplabCoachAuthorizedActionIds, hasLength(248));
    expect(
      coach.computeAllowlistSha256(hiplabCoachAuthorizedActionIds),
      '7a74b025e73765bf878a67ed6e6dd8c24cb20cc79719d6561da4378331e8fbf3',
    );
    final complete = pack.semanticCompleteActions
        .map((action) => action.id)
        .toSet();
    expect(complete.containsAll(hiplabCoachAuthorizedActionIds), isTrue);
    final outside = complete.difference(hiplabCoachAuthorizedActionIds);
    expect(outside, {'n-thomas-test'});
    expect(catalog.ids.toSet(), complete);
    expect(catalog.problems, isEmpty);
    expect(hiplabCoachProfile.select.ids, hiplabCoachAuthorizedActionIds);
    expect(hiplabCoachProfile.select.apps, isEmpty);
    expect(hiplabCoachProfile.select.idPrefixes, isEmpty);
    final scope = profile.scopeManifest.restrict(
      catalog: profile.planningCatalog(catalog),
      profile: profile.coachProfile,
    );
    expect(scope.allowedActionIds, hiplabCoachAuthorizedActionIds);
    expect(scope.plannableIds, hiplabCoachAuthorizedActionIds);
    expect(scope.catalog.ids.toSet(), hiplabCoachAuthorizedActionIds);
    expect(scope.contains('n-thomas-test'), isFalse);
    expect(scope.contains('chest-A'), isTrue);
    for (final action in pack.pendingActions) {
      expect(scope.contains(action.id), isFalse, reason: action.id);
      expect(catalog[action.id], isNull, reason: action.id);
    }
    for (final id in outside) {
      expect(scope.contains(id), isFalse, reason: id);
    }
    expect(profile.library!.allowedActionIds, scope.allowedActionIds);
    expect(
      profile.library!.actions(pack).map((action) => action.id).toSet(),
      scope.plannableIds,
    );
    expect(profile.conversationPolicy.guidanceEnabled, isFalse);
  });

  test('small fixtures intersect the list without admitting unknown IDs', () {
    final fixture = coach.Catalog.fromJson({
      ...catalog.raw,
      'drills': [
        catalog['s-frog']!.raw,
        {...catalog['chest-A']!.raw, 'id': 'not-in-public-catalog'},
      ],
    });
    final scope = hipActionScope(
      fixture,
    ).restrict(catalog: fixture, profile: hiplabCoachProfile);
    expect(scope.allowedActionIds, {'s-frog'});
    expect(scope.plannableIds, {'s-frog'});
    expect(scope.contains('not-in-public-catalog'), isFalse);
  });

  test('catalog loading verifies both assets through exact bytes', () async {
    final assets = _BytesOnlyAssets();
    final loaded = await loadHipCoachCatalog(bundle: assets);
    expect(assets.loaded, [hipPublicCatalogAsset, hipPublicSemanticsAsset]);
    expect(
      loaded.ids.toSet(),
      pack.semanticCompleteActions.map((action) => action.id).toSet(),
    );
    expect(loaded.problems, isEmpty);
    final damaged = File(hipPublicSemanticsAsset).readAsBytesSync();
    damaged[damaged.length - 1] ^= 1;
    expect(
      () => coach.PoseHubAppTestCatalog.fromBytes(
        File(hipPublicCatalogAsset).readAsBytesSync(),
        semanticCatalogBytes: damaged,
      ),
      throwsFormatException,
    );
  });

  test('metadata and authored execution cadence are preserved', () {
    final source = pack.toAiCatalog();
    expect(rhythms.keys.toSet(), pack.allActions.map((a) => a.id).toSet());
    var authored = 0;
    for (final drill in source.drills) {
      final projected = catalog[drill.id]!;
      for (final field in [
        'defaultDose',
        'doseRange',
        'equipment',
        'cautions',
        'contraindications',
        'rhythm',
      ]) {
        expect(
          projected.raw[field],
          drill.raw[field],
          reason: '${drill.id}:$field',
        );
      }
      final rhythm = rhythms[drill.id]!;
      final metadata = pack.tryGet(drill.id)!.raw['rhythm'] as Map;
      if (metadata['execution'] case final Map execution) {
        authored++;
        var expected = trainer.Rhythm.fromJson(
          Map<String, dynamic>.from(execution),
        );
        final hold = (drill.raw['defaultDose'] as Map)['holdSeconds'];
        if (hold is int && expected.counted) expected = expected.withHold(hold);
        expect(rhythm.toJson(), expected.toJson(), reason: drill.id);
      } else {
        expect(
          rhythm.toJson(),
          drill.defaultDose.mode == coach.DoseMode.reps
              ? trainer.Rhythm.selfPacedReps.toJson()
              : trainer.Rhythm.timedHold.toJson(),
          reason: drill.id,
        );
      }
      if (drill.defaultDose.mode == coach.DoseMode.reps && rhythm.counted) {
        expect(
          projected.assets.videos.first.repSeconds,
          rhythm.cycleFor(),
          reason: drill.id,
        );
      }
    }
    // r2-v1 authors an execution rhythm for every action.
    expect(authored, 249);
    // r2-v1 dropped defaultDose.holdSeconds; the hold is the authored phase.
    double holdPhase(String id) =>
        rhythms[id]!.phases.firstWhere((p) => p.id == 'hold').seconds;
    expect(rhythms['h-sumo-pry']!.holdSeconds, isNull);
    expect(holdPhase('h-sumo-pry'), 1.9);
    expect(rhythms['n-seated-knee-lift']!.holdSeconds, isNull);
    expect(holdPhase('n-seated-knee-lift'), 2.1);
  });

  test('ambient equipment codes match public catalog IDs through SDK tags', () {
    final schema = jsonEncode([
      for (final tool in coach.AgentTools.build(
        hiplabCoachProfile,
        catalog,
        memory: false,
      ))
        tool.toJson(),
    ]);
    for (final id in ['mat', 'chair', 'wall']) {
      expect(catalog.taxonomy.equipment, contains(id));
      expect(schema, contains('"equip.$id"'));
    }
    expect(
      hiplabCoachProfile.ambientEquipmentFor('home'),
      containsAll(['equip.mat', 'equip.chair', 'equip.wall']),
    );
    expect(hiplabCoachProfile.ambientEquipmentFor('office'), {
      'equip.chair',
      'equip.wall',
    });
    expect(
      hiplabCoachProfile.ambientEquipmentFor('gym'),
      isNot(contains('equip.dumbbell')),
    );
  });

  test('brand colors and resolved media remain HipLab local to each theme', () {
    expect(profile.visual.light.accent, HipPalette.light.jade);
    expect(profile.visual.dark.accent, HipPalette.dark.jade);
    expect(profile.visual.fontFamily, hipFontFamily);
    for (final brightness in Brightness.values) {
      for (final id in hiplabCoachAuthorizedActionIds) {
        final exercise = profile.visual.exerciseFor!(id, brightness);
        expect(exercise?.id, id);
        expect(exercise?.cutout, hipCoachStandingAsset(id));
        expect(profile.visual.cutoutFor!(id, brightness), isA<AssetImage>());
      }
      expect(
        profile.visual.exerciseFor!('not-in-public-catalog', brightness),
        isNull,
      );
      expect(
        profile.visual.cutoutFor!('not-in-public-catalog', brightness),
        isNull,
      );
      for (final action in pack.pendingActions) {
        expect(profile.visual.exerciseFor!(action.id, brightness), isNull);
        expect(profile.visual.cutoutFor!(action.id, brightness), isNull);
      }
    }
  });
}
