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
      Directory('assets')
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.toLowerCase().endsWith('.mp4')),
      isEmpty,
      reason: 'public clips must be resolved by the SDK media repository',
    );
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, isNot(contains('- assets/drill_media/')));
    expect(pubspec, contains('- assets/public_media/'));
    expect(pubspec, contains('- assets/public_posters/'));
    expect(pubspec, contains('- assets/public_posters/r2-v11/cover/'));
    expect(pubspec, contains('- assets/public_posters/r2-v11/thumbnail/'));
  });

  test('r2-v11 artwork covers the explicit 248-action library scope', () {
    final expected = {
      for (final entry in actions.entries)
        if (entry.value['trainingDefinitionComplete'] == true &&
            entry.key != 'n-thomas-test')
          entry.key,
    };
    expect(publicCatalog['pack'], 'r2-v11');
    expect(actions, hasLength(249));
    expect(expected, hasLength(248));
    expect(hiplabCoachAuthorizedActionIds, expected);
    expect(actions, contains('n-thomas-test'));
    expect(hiplabCoachAuthorizedActionIds, isNot(contains('n-thomas-test')));
    for (final kind in ['cover', 'thumbnail']) {
      final bundled = Directory('assets/public_posters/r2-v11/$kind')
          .listSync()
          .whereType<File>()
          .map((file) => file.uri.pathSegments.last)
          .toSet();
      expect(bundled, {for (final id in expected) '$id.webp'}, reason: kind);
    }
    for (final id in hiplabCoachAuthorizedActionIds) {
      final files = actions[id]!['files'] as Map;
      final video = files['video'] as Map;
      expect(video['bytes'], greaterThan(0), reason: id);
      expect(video['sha256'], matches(RegExp(r'^[0-9a-f]{64}$')), reason: id);
      expect(Uri.parse(video['downloadUrl'] as String).scheme, 'https');
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
