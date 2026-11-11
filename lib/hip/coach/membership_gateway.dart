import 'dart:convert';

import 'package:http/http.dart' as http;

enum GatewayRejection { premiumRequired, dailyQuota, rateLimit }

typedef GatewayNotice = ({GatewayRejection kind, int? limit});

/// Host transport for the SDK's normal OpenAI-compatible client.
class MembershipGateway extends http.BaseClient {
  MembershipGateway({
    required this.baseUri,
    required this.readUserId,
    required this.onNotice,
    http.Client? client,
  }) : _client = client ?? http.Client();

  static const configuredUrl = String.fromEnvironment('HIP_AI_GATEWAY_URL');
  final Uri baseUri;
  final String? Function() readUserId;
  final void Function(GatewayNotice) onNotice;
  final http.Client _client;

  static String? get baseUrl {
    final uri = Uri.tryParse(configuredUrl.trim());
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment ||
        !const ['', '/', '/v1', '/v1/'].contains(uri.path)) {
      return null;
    }
    return uri.replace(path: '/v1').toString();
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (request.method != 'POST' ||
        request.url.origin != baseUri.origin ||
        request.url.path != '/v1/chat/completions') {
      throw ArgumentError('Unexpected HipLab AI gateway endpoint');
    }
    final appUserId = readUserId();
    if (appUserId == null) {
      onNotice((kind: GatewayRejection.premiumRequired, limit: null));
      return http.StreamedResponse(
        Stream.value(utf8.encode('{"error":"not_premium"}')),
        402,
        headers: {'content-type': 'application/json'},
        request: request,
      );
    }
    request.headers
      ..['X-App'] = 'hip'
      ..['Authorization'] = 'Bearer rc:$appUserId';
    request.followRedirects = false;
    final response = await _client.send(request);
    if (response.statusCode == 402) {
      onNotice((kind: GatewayRejection.premiumRequired, limit: null));
      return response;
    }
    if (response.statusCode != 429) return response;
    final bytes = await response.stream.toBytes();
    try {
      final json = jsonDecode(utf8.decode(bytes));
      if (json case {
        'error': 'quota_exceeded',
        'limit': final int limit,
      } when limit > 0) {
        onNotice((kind: GatewayRejection.dailyQuota, limit: limit));
      } else if (json case {'error': 'rate_limited'}) {
        final limit = json['limit'];
        onNotice((
          kind: GatewayRejection.rateLimit,
          limit: limit is int && limit > 0 ? limit : null,
        ));
      }
    } on FormatException {
      // Let the SDK handle an unexpected proxy response as a standard 429.
    }
    return http.StreamedResponse(
      Stream.value(bytes),
      response.statusCode,
      headers: response.headers,
      contentLength: bytes.length,
      request: response.request,
      reasonPhrase: response.reasonPhrase,
    );
  }

  @override
  void close() {
    _client.close();
    super.close();
  }
}
