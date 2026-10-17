// Guards the package boundary after the split from 3D-Body: the bundle carries
// only HipLab's own media, and every path the content pack names exists.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

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
    final names = Directory('assets/drill_media')
        .listSync()
        .map((e) => e.uri.pathSegments.last)
        .toSet();
    final clip = RegExp(r'^(hip-[a-z0-9]+(?:-[a-z0-9]+)*)\.(mp4|jpg)$');
    for (final name in names) {
      if (name.startsWith('player.')) continue;
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
}
