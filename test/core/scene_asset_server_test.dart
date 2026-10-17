import 'dart:io';
import 'dart:typed_data';

import 'package:hiplab/core/media/scene_asset_router.dart';
import 'package:hiplab/core/media/scene_asset_server.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'offline media transport serves full, ranged and HEAD responses',
    () async {
      final bytes = Uint8List.fromList([0, 127, 128, 255, 2, 3]);
      final server = await SceneAssetServer.start(
        router: SceneAssetRouter(
          assets: [
            'assets/drill_media/player.html',
            'assets/drill_media/demo.mp4',
            'assets/drill_media/cover.jpg',
          ],
          load: (_) async => bytes,
        ),
      );
      final client = HttpClient();
      addTearDown(() async {
        client.close(force: true);
        await server.close();
      });
      final uri = server.origin.resolve('/drill_media/demo.mp4');
      final full = await (await client.getUrl(uri)).close();
      expect(full.statusCode, HttpStatus.ok);
      expect(full.headers.contentType?.mimeType, 'video/mp4');
      expect(full.headers.value(HttpHeaders.acceptRangesHeader), 'bytes');
      expect(full.contentLength, 6);
      expect(
        await full.fold<List<int>>([], (data, part) => data..addAll(part)),
        bytes,
      );

      final request = await client.getUrl(uri);
      request.headers.set(HttpHeaders.rangeHeader, 'bytes=2-4');
      final partial = await request.close();
      expect(partial.statusCode, HttpStatus.partialContent);
      expect(
        partial.headers.value(HttpHeaders.contentRangeHeader),
        'bytes 2-4/6',
      );
      expect(partial.contentLength, 3);
      expect(
        await partial.fold<List<int>>([], (data, part) => data..addAll(part)),
        [128, 255, 2],
      );

      final invalid = await client.getUrl(uri);
      invalid.headers.set(HttpHeaders.rangeHeader, 'bytes=99-');
      final unsatisfied = await invalid.close();
      expect(unsatisfied.statusCode, HttpStatus.requestedRangeNotSatisfiable);
      expect(
        unsatisfied.headers.value(HttpHeaders.contentRangeHeader),
        'bytes */6',
      );
      expect(unsatisfied.contentLength, 0);
      expect(
        await unsatisfied.fold<int>(0, (size, part) => size + part.length),
        0,
      );

      final repeated = await client.getUrl(uri);
      repeated.headers.add(HttpHeaders.rangeHeader, 'bytes=0-0');
      repeated.headers.add(HttpHeaders.rangeHeader, 'bytes=2-2');
      final multiple = await repeated.close();
      expect(multiple.statusCode, HttpStatus.requestedRangeNotSatisfiable);
      expect(
        multiple.headers.value(HttpHeaders.contentRangeHeader),
        'bytes */6',
      );
      await multiple.drain<void>();

      final headRequest = await client.openUrl('HEAD', uri);
      headRequest.headers.set(HttpHeaders.rangeHeader, 'bytes=2-4');
      final head = await headRequest.close();
      expect(head.statusCode, HttpStatus.ok);
      expect(head.headers.contentType?.mimeType, 'video/mp4');
      expect(head.contentLength, 6);
      expect(head.headers.value(HttpHeaders.contentRangeHeader), isNull);
      expect(await head.fold<int>(0, (size, part) => size + part.length), 0);

      final player = await (await client.getUrl(
        server.origin.resolve('/drill_media/player.html?drill=abs-A'),
      )).close();
      expect(player.statusCode, HttpStatus.ok);
      expect(player.headers.contentType?.mimeType, 'text/html');
      await player.drain<void>();
      final poster = await (await client.getUrl(
        server.origin.resolve('/drill_media/cover.jpg'),
      )).close();
      expect(poster.headers.contentType?.mimeType, 'image/jpeg');
      await poster.drain<void>();
      final missing = await (await client.getUrl(
        server.origin.resolve('/drill_media/missing.mp4'),
      )).close();
      expect(missing.statusCode, HttpStatus.notFound);
      await missing.drain<void>();
    },
  );

  test(
    'gzip models are served verbatim for the bundled JavaScript decoder',
    () async {
      final compressed = Uint8List.fromList(
        gzip.encode([103, 108, 84, 70, 128, 255]),
      );
      final server = await SceneAssetServer.start(
        router: SceneAssetRouter(
          assets: ['assets/scene/coach/model.meshopt.glb.gz'],
          load: (_) async => compressed,
        ),
      );
      final client = HttpClient();
      addTearDown(() async {
        client.close(force: true);
        await server.close();
      });

      final request = await client.getUrl(
        server.origin.resolve('/coach/model.meshopt.glb.gz'),
      );
      final response = await request.close();
      expect(response.statusCode, HttpStatus.ok);
      expect(response.headers.contentType?.mimeType, 'application/gzip');
      expect(response.headers.value(HttpHeaders.contentEncodingHeader), isNull);
      expect(response.contentLength, compressed.length);
      final actual = await response.fold<List<int>>(
        [],
        (data, part) => data..addAll(part),
      );
      expect(actual, compressed);
      expect(gzip.decode(actual), [103, 108, 84, 70, 128, 255]);
    },
  );

  test(
    'loopback transport serves bundled bytes and accepts only its own origin',
    () async {
      final bytes = Uint8List.fromList([103, 108, 84, 70, 128, 255]);
      final server = await SceneAssetServer.start(
        router: SceneAssetRouter(
          assets: ['assets/scene/index.html', 'assets/scene/coach/model.glb'],
          load: (_) async => bytes,
        ),
      );
      final client = HttpClient();
      addTearDown(() async {
        client.close(force: true);
        await server.close();
      });
      expect(server.origin.host, '127.0.0.1');
      expect(server.origin.port, greaterThan(0));
      expect(server.permitsNavigation(server.sceneUri), isTrue);
      expect(
        server.permitsNavigation(Uri.parse('https://example.com/')),
        isFalse,
      );
      expect(
        server.permitsNavigation(
          Uri.parse('http://localhost:${server.origin.port}/'),
        ),
        isFalse,
      );
      expect(
        server.permitsNavigation(
          Uri.parse('http://127.0.0.1:${server.origin.port + 1}/'),
        ),
        isFalse,
      );

      final request = await client.getUrl(
        server.origin.resolve('/coach/model.glb'),
      );
      final response = await request.close();
      expect(response.statusCode, HttpStatus.ok);
      expect(response.headers.contentType?.mimeType, 'model/gltf-binary');
      final actual = await response.fold<List<int>>(
        [],
        (data, part) => data..addAll(part),
      );
      expect(actual, bytes);
      final headRequest = await client.openUrl('HEAD', server.sceneUri);
      final head = await headRequest.close();
      expect(head.statusCode, HttpStatus.ok);
      expect(head.contentLength, bytes.length);
      expect(
        await head.fold<int>(0, (length, part) => length + part.length),
        0,
      );
    },
  );
}
