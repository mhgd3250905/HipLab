/// AI 定制（AI 训练助理）的运行配置。令牌只从 `--dart-define` 读取，绝不写进代码或仓库：
///
/// ```
/// flutter run --dart-define=UGK_COACH_API_KEY=<UGK AI 中转站为 HipLab 发的令牌> \
///   [--dart-define=UGK_COACH_BASE_URL=https://ai.uuugk.win/v1] \
///   [--dart-define=UGK_COACH_MODEL=deepseek-v4.1-flash-1017] \
///   [--dart-define=UGK_COACH_CATALOG_URL=https://…/manifest.json]
/// ```
///
/// 默认走自建 UGK AI 中转站（New API，https://ai.uuugk.win/v1）：上游模型 key 只放在中转站，
/// App 只带中转站单独发给它、可设额度和随时吊销的令牌（见 docs/ai-coach.md）。
class CoachConfig {
  const CoachConfig({
    this.apiKey = '',
    this.baseUrl = defaultBaseUrl,
    this.model = defaultModel,
    this.catalogManifestUrl = '',
  });

  static const defaultBaseUrl = 'https://ai.uuugk.win/v1';
  static const defaultModel = 'deepseek-v4.1-flash-1017';

  /// 中转站令牌（Authorization: Bearer）。空 = 未配置。
  final String apiKey;
  final String baseUrl;
  final String model;

  /// 目录远端更新清单（manifest.json）地址；空 = 只用随包目录。
  final String catalogManifestUrl;

  static const fromEnvironment = CoachConfig(
    apiKey: String.fromEnvironment('UGK_COACH_API_KEY'),
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

  /// 有令牌才调模型；否则入口显示「未配置」，一律给预设方案。
  bool get configured => apiKey.isNotEmpty;
}
