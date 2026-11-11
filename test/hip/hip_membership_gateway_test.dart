import 'package:hiplab/hip/coach/membership_gateway.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  final baseUri = Uri.https('gateway.invalid', '/v1');
  final uri = Uri.https('gateway.invalid', '/v1/chat/completions');

  test('never sends a RevenueCat identifier to another origin', () async {
    final client = MembershipGateway(
      baseUri: baseUri,
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
      final notices = <GatewayNotice>[];
      var call = 0;
      final client = MembershipGateway(
        baseUri: baseUri,
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
