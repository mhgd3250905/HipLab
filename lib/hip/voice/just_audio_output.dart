import 'dart:async';
import 'dart:io';

import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';

import 'voice_queue.dart';

/// Real playback for voice coaching (#13).
///
/// * Voice and chimes are separate players so a tick can sit under a number.
/// * Other apps' music is lowered (ducked) only while a line is playing:
///   audio focus / an active ducking session is taken right before a line
///   and released ~0.7 s after it ends.
/// * During a session a looping silent clip keeps the audio session alive,
///   so with iOS `UIBackgroundModes: audio` the app – and its absolute-time
///   training clock – keeps running with the screen locked.
///
/// Needs real-device verification (ducking and lock-screen behaviour are
/// OS features that tests cannot exercise).
class JustAudioVoiceOutput implements VoiceOutput {
  final _voice = AudioPlayer(handleAudioSessionActivation: false);
  final _chime = AudioPlayer(handleAudioSessionActivation: false);
  final _keepAlive = AudioPlayer(handleAudioSessionActivation: false);
  AudioSession? _session;
  Timer? _release;
  bool _ducking = false;
  double _volume = 1;
  bool _began = false;
  int _generation = 0;

  static const _silence = 'assets/voice/chime/silence.m4a';

  static AudioSessionConfiguration _config({
    required bool duck,
  }) => AudioSessionConfiguration(
    avAudioSessionCategory: AVAudioSessionCategory.playback,
    avAudioSessionCategoryOptions: duck
        ? AVAudioSessionCategoryOptions.duckOthers |
              AVAudioSessionCategoryOptions.interruptSpokenAudioAndMixWithOthers
        : AVAudioSessionCategoryOptions.mixWithOthers,
    avAudioSessionMode: AVAudioSessionMode.defaultMode,
    androidAudioAttributes: const AndroidAudioAttributes(
      contentType: AndroidAudioContentType.speech,
      usage: AndroidAudioUsage.assistanceSonification,
    ),
    androidAudioFocusGainType: AndroidAudioFocusGainType.gainTransientMayDuck,
    androidWillPauseWhenDucked: false,
  );

  @override
  Future<void> begin() async {
    if (_began) return;
    _began = true;
    try {
      final s = _session = await AudioSession.instance;
      await s.configure(_config(duck: false));
      if (Platform.isIOS) {
        // Android keeps Dart timers running while the process lives; iOS
        // needs an active audio session to keep the app awake.
        await s.setActive(true);
        await _keepAlive.setAsset(_silence);
        await _keepAlive.setLoopMode(LoopMode.one);
        await _keepAlive.setVolume(0);
        unawaited(_keepAlive.play());
      }
      // A phone call or another app taking audio: just stop talking.
      s.interruptionEventStream.listen((e) {
        if (e.begin) _voice.stop();
      });
    } on Object {
      // Audio is best-effort; the visual timer works without it.
    }
  }

  @override
  Future<void> end() async {
    _release?.cancel();
    try {
      await _voice.stop();
      await _keepAlive.stop();
      await _duck(false);
      await _session?.setActive(false);
    } on Object {
      /* ignore */
    }
    _began = false;
  }

  Future<void> _duck(bool on) async {
    final s = _session;
    if (s == null || on == _ducking) return;
    _ducking = on;
    try {
      await s.configure(_config(duck: on));
      if (on) {
        await s.setActive(true);
      } else if (Platform.isIOS) {
        // Re-activating without duckOthers lets the music come back up while
        // the silent keep-alive keeps the session (and the app) running.
        await s.setActive(
          false,
          avAudioSessionSetActiveOptions:
              AVAudioSessionSetActiveOptions.notifyOthersOnDeactivation,
        );
        await s.setActive(true);
        unawaited(_keepAlive.play());
      } else {
        await s.setActive(false);
      }
    } on Object {
      /* ignore */
    }
  }

  @override
  Future<void> speak(List<String> assets) async {
    _release?.cancel();
    final gen = ++_generation;
    try {
      await _duck(true);
      await _voice.setVolume(_volume);
      await _voice.setAudioSources([
        for (final a in assets) AudioSource.asset(a),
      ]);
      await _voice.play();
      // play() completes when playback ends or is stopped.
      if (gen != _generation) return; // a newer line took over
      _release = Timer(const Duration(milliseconds: 700), () => _duck(false));
    } on Object {
      /* a missing clip must never stop the training */
    }
  }

  @override
  Future<void> stopSpeech() async {
    try {
      await _voice.stop();
    } on Object {
      /* ignore */
    }
  }

  @override
  Future<void> chime(String asset) async {
    try {
      await _chime.setVolume(_volume * .9);
      await _chime.setAsset(asset);
      await _chime.play();
    } on Object {
      /* ignore */
    }
  }

  @override
  set volume(double v) => _volume = v.clamp(0, 1);

  Future<void> dispose() async {
    await end();
    await _voice.dispose();
    await _chime.dispose();
    await _keepAlive.dispose();
  }
}
