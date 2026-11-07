// The bundle carries public posters and assessment stills. SDK media policy
// resolves the catalog video files from the public release/cache.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hiplab/hip/data/hip_action_scope.dart';
import 'package:hiplab/hip/domain/hip_models.dart';

void main() {
  final content =
      jsonDecode(File('assets/hip/hip-content.json').readAsStringSync())
          as Map<String, dynamic>;
  final publicCatalog =
      jsonDecode(File('assets/public_media/catalog.json').readAsStringSync())
          as Map<String, dynamic>;
  final actions = {
    for (final action in publicCatalog['actions'] as List)
      (action as Map)['id'] as String: action,
  };

  Iterable<String> assetPaths(Object? node) sync* {
    if (node is String && node.startsWith('assets/')) yield node;
    if (node is Map) {
      for (final value in node.values) {
        yield* assetPaths(value);
      }
    }
    if (node is List) {
      for (final value in node) {
        yield* assetPaths(value);
      }
    }
  }

  test('content stills exist; retired clip paths are historical metadata', () {
    final retained = assetPaths(
      content,
    ).where((path) => !path.startsWith('assets/drill_media/'));
    expect(retained, isNotEmpty);
    for (final path in retained) {
      expect(File(path).existsSync(), isTrue, reason: path);
    }
    expect(
      Directory('assets/drill_media')
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.mp4')),
      isEmpty,
      reason: 'public clips must be resolved by the SDK media repository',
    );
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, isNot(contains('- assets/drill_media/')));
    expect(pubspec, contains('- assets/public_media/'));
    expect(pubspec, contains('- assets/public_posters/'));
  });

  test('public poster bundle exactly covers the full shared catalog', () {
    final expected = {
      for (final entry in actions.entries)
        if (entry.value['trainingDefinitionComplete'] == true) entry.key,
    };
    final bundled = Directory('assets/public_posters')
        .listSync()
        .whereType<File>()
        .map((file) => file.uri.pathSegments.last)
        .toSet();
    // r2-v1: 249 complete actions; posters cover HipLab's fixed 209 scope.
    expect(actions, hasLength(249));
    expect(expected, hasLength(249));
    expect(hiplabCoachAuthorizedActionIds, hasLength(209));
    expect(expected.containsAll(hiplabCoachAuthorizedActionIds), isTrue);
    expect(hiplabCoachAuthorizedActionIds, contains('n-thomas-test'));
    expect(bundled, {for (final id in hiplabCoachAuthorizedActionIds) '$id.webp'});
    for (final id in hiplabCoachAuthorizedActionIds) {
      final action = actions[id];
      expect(action, isNotNull, reason: id);
      final files = action!['files'] as Map;
      final video = files['video'] as Map;
      final cover = files['cover'] as Map;
      expect(video['bytes'], greaterThan(0), reason: id);
      expect(video['sha256'], matches(RegExp(r'^[0-9a-f]{64}$')), reason: id);
      expect(Uri.parse(video['downloadUrl'] as String).scheme, 'https');
      expect(cover['alpha'], isTrue, reason: id);
      expect(
        File('assets/public_posters/$id.webp').lengthSync(),
        greaterThan(0),
      );
    }
    expect(
      File('assets/public_media/catalog/catalog.json').existsSync(),
      isTrue,
    );
  });

  test('all six assessment IDs have public media and keep scored stills', () {
    final parsed = HipContent.fromJson(content);
    const demos = {
      'butterfly': 's-butterfly',
      'ninety_ninety': 's-9090',
      'thomas': 'n-thomas-test',
      'supine_cross': 'n-leg-circles',
      'seated_fold': 's-seated-fold',
      'deep_squat': 'h-squat',
    };
    const comparisonStills = {
      'butterfly': 'butterfly',
      'ninety_ninety': '9090',
      'thomas': 'thomas',
      'supine_cross': 'supine-cross',
      'seated_fold': 'seated-fold',
      'deep_squat': 'deep-squat',
    };
    expect(
      parsed.rules.items.map((item) => item.id).toSet(),
      demos.keys.toSet(),
    );
    for (final item in parsed.rules.items) {
      expect(item.demoDrill, demos[item.id]);
      expect(
        item.demoArt(parsed.drills)?.id,
        item.demoDrill,
        reason: 'self-test must use canonical SDK media IDs',
      );
      expect(actions, contains(item.demoDrill), reason: item.id);
      expect(
        File('assets/public_posters/${item.demoDrill}.webp').existsSync(),
        isTrue,
        reason: item.id,
      );
      expect(item.options.map((option) => option.score), [0, 1, 2]);
      expect(item.options.map((option) => option.image), [
        for (final grade in ['c', 'b', 'a'])
          'assets/hip/assessment/${comparisonStills[item.id]}-$grade.webp',
      ]);
    }
  });
}
