import 'package:ugk_coach/ugk_coach.dart' as uc;

/// HipLab relay protocol. Device identity is supplied by the App's persistent
/// loader; a failed load is retried on the next request rather than cached here.
class CoachRelayAuth implements uc.AuthProvider {
  CoachRelayAuth({
    required String appKey,
    required Future<String> Function() deviceId,
  }) : _appKey = appKey.trim(),
       _deviceId = deviceId; // ignore: prefer_initializing_formals

  final String _appKey;
  final Future<String> Function() _deviceId;

  @override
  Future<Map<String, String>> headers() async => {
    'X-App-Key': _appKey,
    'X-Device-Id': await _deviceId(),
  };
}
