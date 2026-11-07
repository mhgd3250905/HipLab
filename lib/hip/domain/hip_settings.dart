/// 跟随系统 / 浅色 / 深色 (settings → 外观).
enum HipThemeChoice {
  system('system', '跟随系统'),
  light('light', '浅色'),
  dark('dark', '深色');

  const HipThemeChoice(this.id, this.zh);
  final String id;
  final String zh;
  static HipThemeChoice byId(String? id) =>
      values.where((v) => v.id == id).firstOrNull ?? system;
}

/// Separate from the voice-clip language. Older installs remain Chinese until
/// the user explicitly changes their interface language.
enum HipLanguage {
  system('system'),
  zh('zh'),
  en('en');

  const HipLanguage(this.id);
  final String id;
  static HipLanguage byId(String? id) =>
      values.where((value) => value.id == id).firstOrNull ?? zh;
}
