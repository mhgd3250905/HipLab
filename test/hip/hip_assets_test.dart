// Guards the package boundary after the split from 3D-Body: the bundle carries
// only HipLab's own media, and every path the content pack names exists.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hiplab/hip/domain/hip_models.dart';

void main() {
  final content =
      jsonDecode(File('assets/hip/hip-content.json').readAsStringSync())
          as Map<String, dynamic>;

  Iterable<String> assetPaths(Object? node) sync* {
    if (node is String && node.startsWith('assets/')) yield node;
    if (node is Map) {
      for (final v in node.values) {
        yield* assetPaths(v);
      }
    }
    if (node is List) {
      for (final v in node) {
        yield* assetPaths(v);
      }
    }
  }

  test('every asset named by the content pack is in the repository', () {
    final missing = assetPaths(content).toSet()
      ..removeWhere((p) => File(p).existsSync());
    expect(missing, isEmpty);
  });

  test('drill media holds only the player and hip-<id> clip pairs', () {
    final referenced = assetPaths(content).toSet();
    // Files only: the light/ folder holds the light-stage twins of these
    // clips and is checked against action-media.json in
    // hip_action_media_test.dart.
    final names = Directory(
      'assets/drill_media',
    ).listSync().whereType<File>().map((e) => e.uri.pathSegments.last).toSet();
    final clip = RegExp(r'^(hip-[a-z0-9]+(?:-[a-z0-9]+)*)\.(mp4|jpg)$');
    for (final name in names) {
      if (name.startsWith('player.')) continue;
      expect(
        referenced,
        contains('assets/drill_media/$name'),
        reason: '$name is bundled but not used by the content pack',
      );
      final m = clip.firstMatch(name);
      expect(m, isNotNull, reason: '$name is not a HipLab clip');
      final pair = '${m![1]}.${m[2] == 'mp4' ? 'jpg' : 'mp4'}';
      expect(names, contains(pair), reason: '$name has no $pair');
    }
  });

  test('every video in the content pack has a loop length', () {
    for (final drill in content['drills'] as List) {
      final media = (drill as Map)['media'] as Map;
      if (media['video'] == null) continue;
      expect(media['duration_seconds'], isA<num>(), reason: '${drill['id']}');
    }
  });

  test('all six assessment demos resolve to video and keep scored stills', () {
    final parsed = HipContent.fromJson(content);
    const clips = {
      'butterfly': 'hip-s-butterfly',
      'ninety_ninety': 'hip-s-9090',
      'thomas': 'hip-n-thomas-test',
      'supine_cross': 'hip-supine-cross-demo',
      'seated_fold': 'hip-s-seated-fold',
      'deep_squat': 'hip-h-squat',
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
      clips.keys.toSet(),
    );
    for (final item in parsed.rules.items) {
      // Exercise the resolver used by the screen, including the dedicated
      // cross-over cut; a missing video must not silently become a score still.
      final demo = item.demoArt(parsed.drills);
      expect(demo, isNotNull, reason: item.id);
      expect(demo!.mediaStatus, HipMediaStatus.video, reason: item.id);
      expect(demo.video, 'assets/drill_media/${clips[item.id]}.mp4');
      expect(demo.poster, 'assets/drill_media/${clips[item.id]}.jpg');
      expect(demo.duration, greaterThan(0), reason: item.id);
      expect(item.options.map((option) => option.score), [0, 1, 2]);
      expect(item.options.map((option) => option.image), [
        for (final grade in ['c', 'b', 'a'])
          'assets/hip/assessment/${comparisonStills[item.id]}-$grade.webp',
      ]);
    }
  });
}
