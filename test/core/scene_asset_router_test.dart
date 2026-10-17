import 'dart:typed_data';

import 'package:hiplab/core/media/scene_asset_router.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late List<String> loaded;
  late SceneAssetRouter router;
  setUp(() {
    loaded = [];
    router = SceneAssetRouter(
      assets: [
        'assets/scene/index.html',
        'assets/scene/src/runtime.js',
        'assets/scene/coach/flare-coach.glb',
        'assets/scene/coach/flare-coach.meshopt.glb.gz',
        'assets/scene/coach/coach-rig.json',
        'assets/data/catalog.json',
        'assets/scene/source.blend',
        'assets/scene/old-video.mp4',
        'assets/drill_media/player.html',
        'assets/drill_media/player.js',
        'assets/drill_media/demo.mp4',
        'assets/drill_media/cover.jpeg',
        'assets/drill_media/cover.jpg',
        'assets/drill_media/source.blend',
        'assets/fonts/NotoSansArabic.ttf',
        'assets/fonts/private.txt',
      ],
      load: (key) async {
        loaded.add(key);
        return Uint8List.fromList([0, 127, 128, 255]);
      },
    );
  });

  test(
    'scene fonts stay manifest-bound and retain offline font MIME',
    () async {
      final font = await router.route('/fonts/NotoSansArabic.ttf');
      expect(font.statusCode, 200);
      expect(font.contentType, 'font/ttf');
      expect(loaded, ['assets/fonts/NotoSansArabic.ttf']);
      expect((await router.route('/fonts/Unknown.ttf')).statusCode, 404);
      expect((await router.route('/fonts/private.txt')).statusCode, 404);
      expect(
        (await router.route('/fonts/%2e%2e/keys/debug.keystore')).statusCode,
        400,
      );
      expect(loaded.length, 1);
    },
  );

  test('raw and encoded traversal never reach the asset loader', () async {
    for (final target in [
      '/../data/catalog.json',
      '/src/../../index.html',
      '/%2e%2e/data/catalog.json',
      '/src/%2E%2E/index.html',
      '/%252e%252e/data/catalog.json',
      '/src%2f..%2findex.html',
      '/src\\..\\index.html',
      '/%5c..%5cindex.html',
      '//index.html',
      '/C:/index.html',
      '/%00index.html',
      '/bad%escape',
      'http://example.com/index.html',
      '/drill_media/../index.html',
      '/drill_media/%2e%2e/index.html',
      '/drill_media/%252e%252e/index.html',
      '/drill_media//demo.mp4',
    ]) {
      expect((await router.route(target)).statusCode, 400, reason: target);
    }
    expect(loaded, isEmpty);
  });

  test(
    'only scene manifest entries with supported MIME types can load',
    () async {
      for (final target in [
        '/data/catalog.json',
        '/coach/missing.glb',
        '/source.blend',
        '/old-video.mp4',
        '/drill_media/missing.mp4',
        '/drill_media/source.blend',
        '/assets/drill_media/demo.mp4',
      ]) {
        expect((await router.route(target)).statusCode, 404);
      }
      expect(
        (await router.route('/index.html', method: 'POST')).statusCode,
        405,
      );
      expect(loaded, isEmpty);
    },
  );

  test(
    'module/GLB/gzip/JSON responses retain binary bytes and their correct MIME',
    () async {
      final expected = {
        '/': 'text/html; charset=utf-8',
        '/src/runtime.js?v=1': 'text/javascript; charset=utf-8',
        '/coach/flare-coach.glb': 'model/gltf-binary',
        '/coach/flare-coach.meshopt.glb.gz': 'application/gzip',
        '/coach/coach-rig.json': 'application/json; charset=utf-8',
      };
      for (final entry in expected.entries) {
        final result = await router.route(entry.key);
        expect(result.statusCode, 200);
        expect(result.contentType, entry.value);
        expect(result.body, [0, 127, 128, 255]);
      }
      expect(loaded.length, 5);
    },
  );

  test(
    'media whitelist keeps player, video and poster MIME and asset keys',
    () async {
      final expected = {
        '/drill_media/player.html?drill=abs-A': 'text/html; charset=utf-8',
        '/drill_media/player.js': 'text/javascript; charset=utf-8',
        '/drill_media/demo.mp4': 'video/mp4',
        '/drill_media/cover.jpeg': 'image/jpeg',
        '/drill_media/cover.jpg': 'image/jpeg',
      };
      for (final entry in expected.entries) {
        final result = await router.route(entry.key);
        expect(result.statusCode, 200);
        expect(result.contentType, entry.value);
        expect(result.body, [0, 127, 128, 255]);
        expect(result.contentLength, 4);
        expect(result.headers['Accept-Ranges'], 'bytes');
      }
      expect(loaded.first, 'assets/drill_media/player.html');
      expect(loaded[2], 'assets/drill_media/demo.mp4');
    },
  );

  test(
    'bounded, open-ended and suffix ranges return exact media bytes',
    () async {
      final cases = <String, (List<int>, String)>{
        'bytes=1-2': ([127, 128], 'bytes 1-2/4'),
        'bytes=2-': ([128, 255], 'bytes 2-3/4'),
        'bytes=-2': ([128, 255], 'bytes 2-3/4'),
        'bytes=0-999': ([0, 127, 128, 255], 'bytes 0-3/4'),
        'bytes=-999': ([0, 127, 128, 255], 'bytes 0-3/4'),
        'bytes=0-0': ([0], 'bytes 0-0/4'),
      };
      for (final entry in cases.entries) {
        final result = await router.route(
          '/drill_media/demo.mp4',
          range: entry.key,
        );
        expect(result.statusCode, 206, reason: entry.key);
        expect(result.body, entry.value.$1, reason: entry.key);
        expect(result.contentLength, entry.value.$1.length);
        expect(result.headers['Content-Range'], entry.value.$2);
        expect(result.headers['Accept-Ranges'], 'bytes');
      }
    },
  );

  test('invalid, multiple and unsatisfiable ranges return 416', () async {
    for (final range in [
      'bytes=4-',
      'bytes=3-2',
      'bytes=-0',
      'bytes=-',
      'bytes=0-0,2-2',
      'items=0-1',
      'bytes=not-a-number',
      'bytes=999999999999999999999999999999-',
    ]) {
      final result = await router.route('/drill_media/demo.mp4', range: range);
      expect(result.statusCode, 416, reason: range);
      expect(result.contentLength, 0);
      expect(result.body, isEmpty);
      expect(result.headers['Content-Range'], 'bytes */4');
    }
    final empty = SceneAssetRouter(
      assets: ['assets/drill_media/empty.mp4'],
      load: (_) async => Uint8List(0),
    );
    expect(
      (await empty.route(
        '/drill_media/empty.mp4',
        range: 'bytes=0-',
      )).statusCode,
      416,
    );
  });

  test('HEAD returns full metadata and scene responses ignore Range', () async {
    final head = await router.route(
      '/drill_media/demo.mp4',
      method: 'HEAD',
      range: 'bytes=1-2',
    );
    expect(head.statusCode, 200);
    expect(head.contentLength, 4);
    expect(head.body, isEmpty);
    expect(head.headers['Content-Range'], isNull);
    expect(head.headers['Accept-Ranges'], 'bytes');
    final scene = await router.route(
      '/coach/flare-coach.glb',
      range: 'bytes=1-2',
    );
    expect(scene.statusCode, 200);
    expect(scene.body, [0, 127, 128, 255]);
    expect(scene.headers, isEmpty);
  });
}
