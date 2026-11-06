import 'package:flutter/widgets.dart';

/// App-owned display strings follow the resolved Flutter locale. Authored
/// content has separate translated display helpers; user text is kept intact.
class HipText {
  const HipText(this.isEn);
  final bool isEn;
  static const zh = HipText(false);
  static const en = HipText(true);
  static HipText of(BuildContext context) =>
      Localizations.maybeLocaleOf(context)?.languageCode == 'en' ? en : zh;

  String get languageTag => isEn ? 'en' : 'zh';
  String pick(String chinese, String english) => isEn ? english : chinese;
  String plural(int count, String singular, [String? plural]) =>
      '$count ${count == 1 ? singular : plural ?? '${singular}s'}';
}
