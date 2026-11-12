import 'package:http/http.dart' as http;

import '../control/hip_ai_consent.dart';

/// Rechecks the local grant immediately before every AI network request.
class HipAiConsentClient extends http.BaseClient {
  HipAiConsentClient(this.consent, {http.Client? client})
    : _client = client ?? http.Client();

  final HipAiConsent consent;
  final http.Client _client;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (!await consent.read() || !consent.granted) {
      throw http.ClientException('AI data sharing consent is required.');
    }
    return _client.send(request);
  }

  @override
  void close() {
    _client.close();
    super.close();
  }
}
