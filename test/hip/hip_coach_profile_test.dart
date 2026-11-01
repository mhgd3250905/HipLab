import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiplab/hip/coach/hip_coach_profile.dart';
import 'package:hiplab/hip/domain/hip_models.dart';
import 'package:hiplab/hip/ui/coach/hip_coach_visuals.dart';
import 'package:hiplab/hip/ui/hip_theme.dart';
import 'package:ugk_coach/ugk_coach.dart' as coach;

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

void main() {
  final content = _content();
  final catalog = coach.Catalog.fromJson(
    jsonDecode(File(hipCoachCatalogAsset).readAsStringSync()),
  );
  final profile = hiplabCoachAppProfile(
    catalog: catalog,
    coachProfile: hiplabCoachProfile,
    executionTiming: (_) => throw StateError('Not invoked by profile tests'),
    content: content,
  );

  test(
    'one explicit list admits all 45 HipLab candidates and no test demo',
    () {
      expect(hiplabCoachAuthorizedActionIds, hasLength(45));
      expect(hiplabCoachProfile.select.ids, hiplabCoachAuthorizedActionIds);
      expect(hiplabCoachProfile.select.apps, isEmpty);
      expect(hiplabCoachProfile.select.idPrefixes, isEmpty);
      final scope = profile.scopeManifest.restrict(
        catalog: profile.planningCatalog(catalog),
        profile: profile.coachProfile,
      );
      expect(scope.plannableIds, hiplabCoachAuthorizedActionIds);
      expect(scope.catalog.ids.toSet(), hiplabCoachAuthorizedActionIds);
      expect(scope.contains('n-thomas-test'), isFalse);
      expect(scope.contains('chest-A'), isFalse);
      expect(profile.conversationPolicy.guidanceEnabled, isFalse);
    },
  );

  test('unknown configured action fails rather than shrinking the list', () {
    final missing = coach.Catalog.fromJson({
      ...catalog.toJson(),
      'drills': [
        for (final drill in catalog.drills)
          if (drill.id != 's-frog') drill.toJson(),
      ],
    });
    expect(
      () => hiplabCoachAppProfile(
        catalog: missing,
        coachProfile: hiplabCoachProfile,
        executionTiming: profile.executionTiming,
        content: content,
      ),
      throwsA(isA<coach.CoachActionScopeConfigurationException>()),
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
      expect(profile.visual.exerciseFor!('chest-A', brightness), isNull);
      expect(profile.visual.cutoutFor!('chest-A', brightness), isNull);
    }
  });
}
