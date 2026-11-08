import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:ugk_trainer_runtime/engine.dart' as trainer;

/// 跟随 App / 中文 / English.
enum VoiceLanguage {
  app('app', '跟随 App'),
  zh('zh', '中文'),
  en('en', 'English');

  const VoiceLanguage(this.id, this.label);
  final String id;
  final String label;
  static VoiceLanguage byId(String? id) =>
      values.where((v) => v.id == id).firstOrNull ?? app;

  /// Retained Chinese default for timeline callers without an App locale.
  String get clipLanguage => resolveClipLanguage('zh');

  /// Resolve the follow-App choice at the host boundary, without global state.
  String resolveClipLanguage(String appLanguageTag) =>
      this == en ||
          (this == app &&
              appLanguageTag.toLowerCase().split(RegExp('[-_]')).first == 'en')
      ? 'en'
      : 'zh';
}

/// Read-only view of `assets/voice/manifest.json` (written by
/// tools/voice/build_voice.py): which clips exist, how long each one is,
/// and which clip speaks a given content string (doses, tips).
class VoiceLibrary extends trainer.ManifestVoiceSource {
  VoiceLibrary(super.clips, super.chimes, super.texts, super.lines);

  factory VoiceLibrary.fromJson(Map<String, dynamic> j) {
    Map<String, int> ints(Object? m) => {
      for (final e in Map<String, dynamic>.from(m as Map? ?? const {}).entries)
        e.key: (e.value as num).toInt(),
    };
    return VoiceLibrary(
      {
        for (final e in Map<String, dynamic>.from(j['clips'] as Map).entries)
          e.key: ints(e.value),
      },
      ints(j['chimes']),
      {
        for (final e in Map<String, dynamic>.from(j['texts'] as Map).entries)
          e.key: Map<String, String>.from(e.value as Map),
      },
      {
        for (final e in Map<String, dynamic>.from(
          j['lines'] as Map? ?? const {},
        ).entries)
          e.key: Map<String, String>.from(e.value as Map),
      },
    );
  }

  /// A library with no clips: every lookup misses, durations fall back to
  /// estimates. Used when the manifest is unavailable.
  static final empty = VoiceLibrary(const {}, const {}, const {}, const {});

  static const manifestAsset = 'assets/voice/manifest.json';

  static Future<VoiceLibrary> load() async {
    try {
      return VoiceLibrary.fromJson(
        jsonDecode(await rootBundle.loadString(manifestAsset))
            as Map<String, dynamic>,
      );
    } on Object {
      return empty;
    }
  }

  @override
  bool has(String key, {String lang = 'zh'}) => super.has(key, lang: lang);
  @override
  double seconds(String key, {String lang = 'zh'}) =>
      super.seconds(key, lang: lang);
  @override
  double total(Iterable<String> keys, {String lang = 'zh'}) =>
      super.total(keys, lang: lang);
  @override
  String? line(String key, {String lang = 'zh'}) => super.line(key, lang: lang);
  @override
  String asset(String key, {String lang = 'zh'}) =>
      super.asset(key, lang: lang);

  @override
  List<String> setsPhrase(int n) => ['n.$n', 'u.sets'];

  @override
  List<String> ordinalSet(int n, {String lang = 'zh'}) =>
      lang == 'zh' ? ['p.di', 'n.$n', 'u.sets'] : ['p.set', 'n.$n'];

  @override
  List<String> ordinalRound(int n, {String lang = 'zh'}) =>
      lang == 'zh' ? ['p.di', 'n.$n', 'u.rounds'] : ['p.round', 'n.$n'];
}
