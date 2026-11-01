// The production config uses SDK auth; this local server never reads real keys.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hiplab/hip/coach/coach_config.dart';
import 'package:hiplab/hip/coach/coach_device_id.dart';
import 'package:ugk_coach/ugk_coach.dart' as coach;

import 'hip_domain_test.dart' show MemoryStorage;

class RelayRequest {
  const RelayRequest(this.uri, this.headers, this.body);
  final Uri uri;
  final Map<String, String> headers;
  final Map<String, Object?> body;
}

Future<({HttpServer server, List<RelayRequest> requests})> startRelay() async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  final captured = <RelayRequest>[];
  server.listen((request) async {
    final headers = <String, String>{};
    request.headers.forEach((name, values) {
      headers[name.toLowerCase()] = values.join(',');
    });
    final body = Map<String, Object?>.from(
      jsonDecode(await utf8.decoder.bind(request).join()) as Map,
    );
    captured.add(RelayRequest(request.uri, headers, body));
    request.response.headers.contentType = ContentType.json;
    request.response.write(
      jsonEncode({
        'model': body['model'],
        'choices': [
          {
            'message': {'role': 'assistant', 'content': 'local adapter check'},
            'finish_reason': 'stop',
          },
        ],
        'usage': {'prompt_tokens': 1, 'completion_tokens': 1},
      }),
    );
    await request.response.close();
  });
  return (server: server, requests: captured);
}

const request = coach.LlmRequest(
  messages: [coach.LlmMessage.user('adapter check')],
);

void main() {
  test('release defaults retain Worker configuration with no bundled key', () {
    const config = CoachConfig();
    expect(config.authMode, 'worker');
    expect(config.token, isEmpty);
    expect(config.appKey, isEmpty);
    expect(config.configured, isFalse);
    expect(config.baseUrl, 'https://api.uuugk.win/v1');
    expect(config.model, 'deepseek-v4-flash-0731');
    expect(config.llmConfig.maxRetries, 0);
    const blank = CoachConfig(baseUrl: ' \t ', model: ' \n ');
    expect(blank.baseUrl, config.baseUrl);
    expect(blank.model, config.model);
    expect(
      const CoachConfig(authMode: 'worker', token: 'unused').configured,
      isFalse,
    );
    expect(
      const CoachConfig(authMode: 'bearer', appKey: 'unused').configured,
      isFalse,
    );
    expect(
      const CoachConfig(authMode: 'unknown', appKey: 'unused').configured,
      isFalse,
    );
    expect(
      CoachConfig.fromEnvironment.appKey,
      const String.fromEnvironment('UGK_COACH_APP_KEY'),
    );
  });

  test(
    'Worker client sends only app/device auth and reuses persisted identity',
    () async {
      final relay = await startRelay();
      addTearDown(() => relay.server.close(force: true));
      final disk = MemoryStorage();
      for (var run = 0; run < 2; run++) {
        final identity = CoachDeviceId(storage: disk);
        final client = CoachConfig(
          appKey: ' local-app-fixture ',
          baseUrl:
              'http://${relay.server.address.address}:${relay.server.port}/v1/',
        ).createClient(deviceId: identity.load);
        addTearDown(client.close);
        expect((await client.complete(request)).content, 'local adapter check');
      }
      expect(relay.requests, hasLength(2));
      for (final captured in relay.requests) {
        expect(captured.uri.path, '/v1/chat/completions');
        expect(captured.headers['x-app-key'], 'local-app-fixture');
        expect(captured.headers['x-device-id'], isNotEmpty);
        expect(captured.headers, isNot(contains('authorization')));
        expect(captured.headers, isNot(contains('x-app-token')));
        expect(captured.body['model'], CoachConfig.defaultModel);
        expect(captured.body['stream'], isFalse);
      }
      expect(
        relay.requests.first.headers['x-device-id'],
        relay.requests.last.headers['x-device-id'],
      );
      expect(
        disk.values[CoachDeviceId.storageKey],
        relay.requests.last.headers['x-device-id'],
      );
    },
  );

  test(
    'internal bearer mode is explicit and does not read the installation ID',
    () async {
      final relay = await startRelay();
      addTearDown(() => relay.server.close(force: true));
      var identityReads = 0;
      final client =
          CoachConfig(
            authMode: 'bearer',
            token: ' local-token-fixture ',
            baseUrl:
                'http://${relay.server.address.address}:${relay.server.port}/v1',
            model: 'deepseek-flash',
          ).createClient(
            deviceId: () async {
              identityReads++;
              return 'unused';
            },
          );
      addTearDown(client.close);
      await client.complete(request);
      final captured = relay.requests.single;
      expect(captured.headers['authorization'], 'Bearer local-token-fixture');
      expect(captured.headers, isNot(contains('x-app-key')));
      expect(captured.headers, isNot(contains('x-device-id')));
      expect(captured.body['model'], 'deepseek-flash');
      expect(identityReads, 0);
    },
  );

  test(
    'identity storage failure sends no request and can retry without a new client',
    () async {
      final relay = await startRelay();
      addTearDown(() => relay.server.close(force: true));
      var loads = 0;
      final client =
          CoachConfig(
            appKey: 'local-app-fixture',
            baseUrl:
                'http://${relay.server.address.address}:${relay.server.port}/v1',
          ).createClient(
            deviceId: () async {
              loads++;
              if (loads == 1) throw StateError('test identity unavailable');
              return 'local-persisted-id';
            },
          );
      addTearDown(client.close);
      await expectLater(client.complete(request), throwsA(anything));
      expect(relay.requests, isEmpty);
      await client.complete(request);
      expect(loads, 2);
      expect(
        relay.requests.single.headers['x-device-id'],
        'local-persisted-id',
      );
    },
  );
}
