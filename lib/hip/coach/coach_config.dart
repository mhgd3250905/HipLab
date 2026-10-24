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
    String baseUrl = defaultBaseUrl,
    String model = defaultModel,
    this.catalogManifestUrl = '',
  }) : _baseUrl = baseUrl, // ignore: prefer_initializing_formals
       _model = model; // ignore: prefer_initializing_formals

  static const defaultBaseUrl = 'https://api.uuugk.win/v1';
  static const defaultModel = 'deepseek-v4-flash-0731';

  /// Relay app credential (X-App-Key). Blank means unconfigured.
  final String appKey;
  final String _baseUrl;
  final String _model;
  String get baseUrl =>
      _baseUrl.trim().isEmpty ? defaultBaseUrl : _baseUrl.trim();
  String get model => _model.trim().isEmpty ? defaultModel : _model.trim();

  /// Optional catalog manifest; blank keeps the bundled catalog.
  final String catalogManifestUrl;

  static const fromEnvironment = CoachConfig(
    appKey: String.fromEnvironment('UGK_COACH_APP_KEY'),
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

  bool get configured => appKey.trim().isNotEmpty;
}
