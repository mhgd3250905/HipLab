import 'package:hiplab/hip/coach/membership_gateway.dart';
import 'package:hiplab/hip/control/hip_ai_consent.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final baseUri = Uri.https('gateway.invalid', '/v1');
  final uri = Uri.https('gateway.invalid', '/v1/chat/completions');
  late HipAiConsent consent;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    consent = HipAiConsent();
  });

  test('gates every request and persists only a timestamped grant', () async {
    var calls = 0;
    final client = MembershipGateway(
      baseUri: baseUri,
      consent: consent,
      readUserId: () => r'$RCAnonymousID:00000000000000000000000000000001',
      onNotice: (_) {},
      client: MockClient((_) async {
        calls++;
        return http.Response('{}', 200);
      }),
    );
    addTearDown(client.close);

    await expectLater(client.post(uri), throwsA(isA<http.ClientException>()));
    expect(calls, 0);

    await consent.grant();
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getBool(HipAiConsent.key), isTrue);
    expect(
      DateTime.tryParse(preferences.getString(HipAiConsent.timestampKey)!),
      isNotNull,
    );
    expect(await HipAiConsent().read(), isTrue);
    expect((await client.post(uri)).statusCode, 200);
    expect(calls, 1);

    final withdrawal = consent.withdraw();
    expect(consent.granted, isFalse);
    await expectLater(client.post(uri), throwsA(isA<http.ClientException>()));
    await withdrawal;
    expect(calls, 1);
    expect(preferences.containsKey(HipAiConsent.key), isFalse);
    expect(preferences.containsKey(HipAiConsent.timestampKey), isFalse);
    expect(await HipAiConsent().read(), isFalse);
  });

  test('never sends a RevenueCat identifier to another origin', () async {
    final client = MembershipGateway(
      baseUri: baseUri,
      consent: consent,
      readUserId: () => throw StateError('identity should not be read'),
      onNotice: (_) {},
      client: MockClient((_) async => throw StateError('request escaped')),
    );
    addTearDown(client.close);
    await expectLater(
      client.post(Uri.https('other.invalid', '/v1/chat/completions')),
      throwsArgumentError,
    );
  });

  test('without an active RC identity no request leaves the app', () async {
    final notices = <GatewayNotice>[];
    final client = MembershipGateway(
      baseUri: baseUri,
      consent: consent,
      readUserId: () => null,
      onNotice: notices.add,
      client: MockClient((_) async => throw StateError('request escaped')),
    );
    addTearDown(client.close);
    expect((await client.post(uri)).statusCode, 402);
    expect(notices, [(kind: GatewayRejection.premiumRequired, limit: null)]);
  });

  test(
    'uses current RC identity and keeps quota and IP throttling distinct',
    () async {
      await consent.grant();
      final notices = <GatewayNotice>[];
      var call = 0;
      final client = MembershipGateway(
        baseUri: baseUri,
        consent: consent,
        readUserId: () => r'$RCAnonymousID:00000000000000000000000000000001',
        onNotice: notices.add,
        client: MockClient((request) async {
          expect(request.headers['X-App'], 'hip');
          expect(
            request.headers['Authorization'],
            r'Bearer rc:$RCAnonymousID:00000000000000000000000000000001',
          );
          return switch (++call) {
            1 => http.Response('{"error":"not_premium"}', 402),
            2 => http.Response('{"error":"quota_exceeded","limit":30}', 429),
            3 => http.Response('{"error":"quota_exceeded","limit":50}', 429),
            _ => http.Response('{"error":"rate_limited","limit":20}', 429),
          };
        }),
      );
      addTearDown(client.close);
      expect((await client.post(uri)).statusCode, 402);
      expect(
        (await client.post(uri)).body,
        '{"error":"quota_exceeded","limit":30}',
      );
      expect(
        (await client.post(uri)).body,
        '{"error":"quota_exceeded","limit":50}',
      );
      expect((await client.post(uri)).statusCode, 429);
      expect(notices, [
        (kind: GatewayRejection.premiumRequired, limit: null),
        (kind: GatewayRejection.dailyQuota, limit: 30),
        (kind: GatewayRejection.dailyQuota, limit: 50),
        (kind: GatewayRejection.rateLimit, limit: 20),
      ]);
    },
  );
}
