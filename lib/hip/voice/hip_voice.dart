import 'package:flutter/widgets.dart';

import '../domain/action_kit.dart';
import 'session_script.dart';
import 'voice_library.dart';
import 'voice_queue.dart';

/// App-wide voice coaching service: the clip library, the audio output and
/// the user's settings. Pages get it with [HipVoice.of].
class HipVoice {
  HipVoice({
    required this.lib,
    required this.output,
    required this.settingsOf,
    this.appLanguageTag = 'zh',
  });

  final VoiceLibrary lib;
  final VoiceOutput output;
  final VoiceSettings Function() settingsOf;
  final String appLanguageTag;

  /// A lightweight locale-bound view; the library, output and live preferences
  /// are shared. No playback resources are created or disposed here.
  HipVoice withAppLanguage(String languageTag) => HipVoice(
    lib: lib,
    output: output,
    settingsOf: settingsOf,
    appLanguageTag: languageTag,
  );

  /// Off in widget tests / when no library loaded.
  static final silent = HipVoice(
    lib: VoiceLibrary.empty,
    output: const MutedVoiceOutput(),
    settingsOf: () => const VoiceSettings(voice: false, chimes: false),
  );

  VoiceSettings get settings => settingsOf();
  String get lang => settings.language.resolveClipLanguage(appLanguageTag);

  VoiceQueue queue() {
    final s = settings;
    output.volume = s.volume;
    return VoiceQueue(
      output: output,
      lib: lib,
      settings: s,
      appLanguageTag: appLanguageTag,
    );
  }

  SessionScript script({
    List<String> routineIds = const [],
    int restSeconds = 15,
    Map<String, ActionKit> kits = const {},
  }) => SessionScript(
    lib: lib,
    lang: lang,
    routineIds: routineIds,
    restSeconds: restSeconds,
    kits: kits,
  );

  static HipVoice of(BuildContext context) {
    final service =
        context.dependOnInheritedWidgetOfExactType<HipVoiceScope>()?.voice ??
        silent;
    final language =
        Localizations.maybeLocaleOf(context)?.toLanguageTag() ?? 'zh';
    return service.withAppLanguage(language);
  }
}

class HipVoiceScope extends InheritedWidget {
  const HipVoiceScope({super.key, required this.voice, required super.child});
  final HipVoice voice;
  @override
  bool updateShouldNotify(HipVoiceScope old) => old.voice != voice;
}
