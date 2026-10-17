import 'package:flutter/widgets.dart';

import 'session_script.dart';
import 'voice_library.dart';
import 'voice_queue.dart';

/// App-wide voice coaching service: the clip library, the audio output and
/// the user's settings. Pages get it with [HipVoice.of].
class HipVoice {
  HipVoice({required this.lib, required this.output, required this.settingsOf});

  final VoiceLibrary lib;
  final VoiceOutput output;
  final VoiceSettings Function() settingsOf;

  /// Off in widget tests / when no library loaded.
  static final silent = HipVoice(
    lib: VoiceLibrary.empty,
    output: const MutedVoiceOutput(),
    settingsOf: () => const VoiceSettings(voice: false, chimes: false),
  );

  VoiceSettings get settings => settingsOf();
  String get lang => settings.language.clipLanguage;

  VoiceQueue queue() {
    final s = settings;
    output.volume = s.volume;
    return VoiceQueue(output: output, lib: lib, settings: s);
  }

  SessionScript script({
    List<String> routineIds = const [],
    int restSeconds = 15,
  }) => SessionScript(
    lib: lib,
    lang: lang,
    routineIds: routineIds,
    restSeconds: restSeconds,
  );

  static HipVoice of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<HipVoiceScope>()?.voice ??
      silent;
}

class HipVoiceScope extends InheritedWidget {
  const HipVoiceScope({super.key, required this.voice, required super.child});
  final HipVoice voice;
  @override
  bool updateShouldNotify(HipVoiceScope old) => old.voice != voice;
}
