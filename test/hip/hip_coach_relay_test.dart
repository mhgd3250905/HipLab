// Exercise the production Service -> SDK -> HTTP request path locally.
// No real gateway or credential file is read by this suite.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hiplab/hip/coach/coach_config.dart';
import 'package:hiplab/hip/coach/coach_device_id.dart';
import 'package:hiplab/hip/coach/coach_service.dart';
import 'package:hiplab/hip/coach/usage_store.dart';
import 'package:ugk_coach/ugk_coach.dart' as uc;

import 'hip_domain_test.dart' show MemoryStorage, loadContent;

Future<String> readAsset(String path) async => File(path).readAsStringSync();

class _RelayRequest {
  const _RelayRequest(this.method, this.uri, this.headers, this.body);
  final String method;
  final Uri uri;
  final Map<String, String> headers;
  final Map<String, Object?> body;
}

Future<({HttpServer server, List<_RelayRequest> requests})>
_startRelay() async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  final captured = <_RelayRequest>[];
  server.listen((request) async {
    final headers = <String, String>{};
    request.headers.forEach((name, values) {
      headers[name.toLowerCase()] = values.join(',');
    });
    final body = Map<String, Object?>.from(
      jsonDecode(await utf8.decoder.bind(request).join()) as Map,
    );
    captured.add(_RelayRequest(request.method, request.uri, headers, body));
    request.response.headers.contentType = ContentType.json;
    request.response.write(
      jsonEncode({
        'model': CoachConfig.defaultModel,
        'choices': [
          {
            'message': {
              'role': 'assistant',
              'content': 'Gateway response received.',
            },
            'finish_reason': 'stop',
          },
        ],
        'usage': {'prompt_tokens': 12, 'completion_tokens': 8},
      }),
    );
    await request.response.close();
  });
  return (server: server, requests: captured);
}

void main() {
  test('relay defaults and whitespace use the App gateway/model', () {
    const defaults = CoachConfig();
    expect(defaults.baseUrl, 'https://api.uuugk.win/v1');
    expect(defaults.model, 'deepseek-v4-flash-0731');
    expect(defaults.configured, isFalse);
    const blank = CoachConfig(appKey: '  ', baseUrl: ' \t ', model: ' \n ');
    expect(blank.baseUrl, defaults.baseUrl);
    expect(blank.model, defaults.model);
    expect(blank.configured, isFalse);
    const custom = CoachConfig(
      appKey: 'test-app',
      baseUrl: ' https://relay.example/v1/ ',
      model: ' my-model ',
    );
    expect(custom.baseUrl, 'https://relay.example/v1/');
    expect(custom.model, 'my-model');
    expect(custom.configured, isTrue);
    expect(defaults.authMode, 'worker');
    expect(defaults.llmConfig.maxRetries, 0);
    expect(defaults.llmConfig.timeout, const Duration(seconds: 120));
    // The SDK is shared by other Apps; HipLab overrides its selection locally.
    expect(uc.LlmConfig.deepSeekOpenCsg.model, 'deepseek-v4.1-flash-1017');
  });

  test('environment credential comes only from the app-key define', () {
    expect(
      CoachConfig.fromEnvironment.appKey,
      const String.fromEnvironment('UGK_COACH_APP_KEY'),
    );
    expect(
      CoachConfig.fromEnvironment.configured,
      const String.fromEnvironment('UGK_COACH_APP_KEY').trim().isNotEmpty,
    );
  });

  test('no app key: retired define cannot enable the relay', () {
    expect(CoachConfig.fromEnvironment.appKey, isEmpty);
    expect(CoachConfig.fromEnvironment.configured, isFalse);
  });

  test(
    'no key sends no model or catalog request and creates no device ID',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      var requests = 0;
      server.listen((request) async {
        requests++;
        request.response.statusCode = HttpStatus.notFound;
        await request.response.close();
      });
      addTearDown(() => server.close(force: true));
      var identityLoads = 0;
      final fake = uc.FakeLlmClient(['unexpected']);
      final base = 'http://${server.address.address}:${server.port}';
      final service = CoachService(
        config: CoachConfig(
          appKey: '  ',
          baseUrl: '$base/v1',
          catalogManifestUrl: '$base/manifest.json',
        ),
        content: loadContent(),
        client: fake,
        usage: CoachUsageStore(),
        storage: MemoryStorage(),
        readAsset: readAsset,
        deviceId: () async {
          identityLoads++;
          return 'unused';
        },
      );
      await service.load();
      addTearDown(service.dispose);
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(service.configured, isFalse);
      expect(service.conversation, isNull);
      expect(fake.requests, isEmpty);
      expect(requests, 0);
      expect(identityLoads, 0);
    },
  );

  test(
    'relay auth has exactly two headers and retries failed identity loads',
    () async {
      var loads = 0;
      final auth = uc.UgkWorkerAuth(
        appKey: 'test-app',
        deviceId: () async {
          loads++;
          if (loads == 1) throw StateError('storage unavailable');
          return 'e3992abc-aa29-4a48-a2f5-d806171828cf';
        },
      );
      await expectLater(auth.headers(), throwsStateError);
      expect(await auth.headers(), {
        'X-App-Key': 'test-app',
        'X-Device-Id': 'e3992abc-aa29-4a48-a2f5-d806171828cf',
      });
      expect(loads, 2);
    },
  );

  test('production Service sends relay headers, endpoint and default model; '
      'a new Service reuses the persisted device UUID', () async {
    final relay = await _startRelay();
    final server = relay.server;
    final captured = relay.requests;
    addTearDown(() => server.close(force: true));
    final content = loadContent();
    final storage = MemoryStorage();
    final base = 'http://${server.address.address}:${server.port}/v1/';
    for (final model in [CoachConfig.defaultModel, ' \t ']) {
      // Simulate a new App service using the same installation's persisted ID.
      final identity = CoachDeviceId(storage: storage);
      final service = CoachService(
        maxRequestRetries: 0,
        config: CoachConfig(
          appKey: 'local-relay-test-app',
          baseUrl: base,
          model: model,
        ),
        content: content,
        usage: CoachUsageStore(),
        storage: storage,
        readAsset: readAsset,
        deviceId: identity.load,
      );
      await service.load();
      addTearDown(service.dispose);
      final answer = (await service.conversation!.send('睡前在家开胯 12 分钟'))!;
      expect(
        answer.status,
        uc.TurnStatus.ok,
        reason: 'the real SDK must parse and validate the local response',
      );
      expect(answer.plan, isNull);
    }
    expect(captured, hasLength(2));
    for (final request in captured) {
      expect(request.method, 'POST');
      expect(request.uri.path, '/v1/chat/completions');
      expect(request.uri.hasQuery, isFalse);
      expect(request.body['model'], 'deepseek-v4-flash-0731');
      expect(request.body['stream'], isFalse);
      expect(request.body.containsKey('response_format'), isFalse);
      expect(request.body['tools'], isNotEmpty);
      expect(request.body['messages'], isNotEmpty);
      expect(request.headers['x-app-key'], 'local-relay-test-app');
      expect(request.headers, isNot(contains('authorization')));
      expect(request.headers, isNot(contains('x-app-token')));
      expect(
        request.headers['x-device-id'],
        matches(
          RegExp(
            r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
            caseSensitive: false,
          ),
        ),
      );
    }
    expect(
      captured.last.headers['x-device-id'],
      captured.first.headers['x-device-id'],
    );
  });
  test(
    'failed device identity sends no HTTP and the next ask can retry',
    () async {
      final relay = await _startRelay();
      addTearDown(() => relay.server.close(force: true));
      var loads = 0;
      final service = CoachService(
        maxRequestRetries: 0,
        config: CoachConfig(
          appKey: 'local-relay-test-app',
          baseUrl:
              'http://${relay.server.address.address}:${relay.server.port}/v1',
        ),
        content: loadContent(),
        usage: CoachUsageStore(),
        storage: MemoryStorage(),
        readAsset: readAsset,
        deviceId: () async {
          loads++;
          if (loads == 1) throw StateError('identity persistence unavailable');
          return 'e3992abc-aa29-4a48-a2f5-d806171828cf';
        },
      );
      await service.load();
      addTearDown(service.dispose);
      final failed = (await service.conversation!.send('睡前在家开胯 12 分钟'))!;
      expect(failed.status, uc.TurnStatus.error);
      expect(
        relay.requests,
        isEmpty,
        reason: 'no request without a persistent device identity',
      );
      expect(loads, 1);
      final retried = (await service.conversation!.send('睡前在家开胯 12 分钟'))!;
      expect(retried.status, uc.TurnStatus.ok);
      expect(loads, 2);
      expect(relay.requests, hasLength(1));
      expect(
        relay.requests.single.headers['x-device-id'],
        'e3992abc-aa29-4a48-a2f5-d806171828cf',
      );
      expect(relay.requests.single.headers, isNot(contains('authorization')));
    },
  );

  test('internal bearer transport has no Worker or device headers', () async {
    final relay = await _startRelay();
    addTearDown(() => relay.server.close(force: true));
    const token = 'local-bearer-fixture';
    final config = CoachConfig(
      authMode: 'bearer',
      token: token,
      baseUrl: 'http://${relay.server.address.address}:${relay.server.port}/v1',
      model: 'deepseek-flash',
    );
    expect(config.configured, isTrue);
    expect(config.llmConfig.maxRetries, 0);
    var identities = 0;
    final service = CoachService(
      config: config,
      content: loadContent(),
      maxRequestRetries: 0,
      usage: CoachUsageStore(),
      storage: MemoryStorage(),
      readAsset: readAsset,
      deviceId: () async {
        identities++;
        return 'unused';
      },
    );
    await service.load();
    addTearDown(service.dispose);
    final result = await service.conversation!.send('hip mobility');
    expect(result?.status, uc.TurnStatus.ok);
    expect(identities, 0);
    expect(relay.requests, hasLength(1));
    final request = relay.requests.single;
    expect(request.body['model'], 'deepseek-flash');
    expect(request.headers['authorization'], 'Bearer $token');
    expect(request.headers, isNot(contains('x-app-key')));
    expect(request.headers, isNot(contains('x-device-id')));
  });

  test('transport does not retry a failed HTTP attempt', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    var requests = 0;
    server.listen((request) async {
      requests++;
      await utf8.decoder.bind(request).join();
      request.response.statusCode = HttpStatus.serviceUnavailable;
      request.response.headers.contentType = ContentType.json;
      request.response.write(
        jsonEncode({
          'error': {'message': 'unavailable'},
        }),
      );
      await request.response.close();
    });
    final service = CoachService(
      config: CoachConfig(
        authMode: 'bearer',
        token: 'local-failure-fixture',
        baseUrl: 'http://${server.address.address}:${server.port}/v1',
        model: 'deepseek-flash',
      ),
      content: loadContent(),
      maxRequestRetries: 0,
      usage: CoachUsageStore(),
      storage: MemoryStorage(),
      readAsset: readAsset,
    );
    await service.load();
    addTearDown(service.dispose);
    final result = await service.conversation!.send('hip mobility');
    expect(result?.status, uc.TurnStatus.error);
    expect(result?.plan, isNull);
    expect(requests, 1);
  });
}
