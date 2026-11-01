import 'package:ugk_coach/ugk_coach.dart' as uc;

/// HipLab relay settings. No credential has a bundled default. Builds without
/// an externally supplied app credential hide AI; provider keys stay server-side.
///
/// ```
/// flutter run --dart-define=UGK_COACH_APP_KEY=<HipLab app key> \
///   [--dart-define=UGK_COACH_BASE_URL=https://api.uuugk.win/v1] \
///   [--dart-define=UGK_COACH_MODEL=deepseek-v4-flash-0731] \
///   [--dart-define=UGK_COACH_CATALOG_URL=https://…/manifest.json]
/// ```
class CoachConfig {
  const CoachConfig({
    this.appKey = '',
    this.token = '',
    this.authMode = 'worker',
    String baseUrl = defaultBaseUrl,
    String model = defaultModel,
    this.catalogManifestUrl = '',
  }) : _baseUrl = baseUrl, // ignore: prefer_initializing_formals
       _model = model; // ignore: prefer_initializing_formals

  static const defaultBaseUrl = 'https://api.uuugk.win/v1';
  static const defaultModel = 'deepseek-v4-flash-0731';

  /// Relay app credential (X-App-Key). Blank means unconfigured.
  final String appKey;

  /// Internal test gateway credential, supplied only with --dart-define.
  final String token;
  final String authMode;
  final String _baseUrl;
  final String _model;
  String get baseUrl =>
      _baseUrl.trim().isEmpty ? defaultBaseUrl : _baseUrl.trim();
  String get model => _model.trim().isEmpty ? defaultModel : _model.trim();

  /// Optional catalog manifest; blank keeps the bundled catalog.
  final String catalogManifestUrl;

  static const fromEnvironment = CoachConfig(
    appKey: String.fromEnvironment('UGK_COACH_APP_KEY'),
    token: String.fromEnvironment('UGK_COACH_TOKEN'),
    authMode: String.fromEnvironment('UGK_COACH_AUTH', defaultValue: 'worker'),
    baseUrl: String.fromEnvironment(
      'UGK_COACH_BASE_URL',
      defaultValue: defaultBaseUrl,
    ),
    model: String.fromEnvironment(
      'UGK_COACH_MODEL',
      defaultValue: defaultModel,
    ),
    catalogManifestUrl: String.fromEnvironment('UGK_COACH_CATALOG_URL'),
  );

  bool get configured => switch (authMode) {
    'worker' => appKey.trim().isNotEmpty,
    'bearer' => token.trim().isNotEmpty,
    _ => false,
  };

  /// Release defaults retain Worker headers. Internal builds explicitly select
  /// bearer + https://ai.uuugk.win/v1 + deepseek-flash with dart defines.
  uc.LlmConfig get llmConfig => uc.LlmConfig.ugkWorker.copyWith(
    baseUrl: baseUrl,
    model: model,
    maxRetries: 0,
  );

  uc.OpenAiCompatibleClient createClient({
    required Future<String> Function() deviceId,
  }) => uc.OpenAiCompatibleClient(
    config: llmConfig,
    auth: switch (authMode) {
      'worker' => uc.UgkWorkerAuth(appKey: appKey.trim(), deviceId: deviceId),
      'bearer' => uc.ApiKeyAuth(token.trim()),
      _ => throw ArgumentError.value(authMode, 'UGK_COACH_AUTH'),
    },
  );
}
