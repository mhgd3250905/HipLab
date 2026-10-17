import 'dart:async';
import 'dart:io';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
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
  JustAudioVoiceOutput()
    : this._(
        AudioPlayer(handleAudioSessionActivation: false),
        AudioPlayer(handleAudioSessionActivation: false),
        AudioPlayer(handleAudioSessionActivation: false),
        () => AudioSession.instance,
      );

  @visibleForTesting
  JustAudioVoiceOutput.forTesting({
    required AudioPlayer voice,
    required AudioPlayer chime,
    required AudioPlayer keepAlive,
    required Future<AudioSession> Function() session,
  }) : this._(voice, chime, keepAlive, session);

  JustAudioVoiceOutput._(
    this._voice,
    this._chime,
    this._keepAlive,
    this._getSession,
  );

  final AudioPlayer _voice;
  final AudioPlayer _chime;
  final AudioPlayer _keepAlive;
  final Future<AudioSession> Function() _getSession;
  AudioSession? _session;
  Timer? _release;
  bool _ducking = false;
  double _volume = 1;
  bool _began = false;
  int _generation = 0;
  int _sessionGeneration = 0;
  Future<void>? _beginning;
  Future<void>? _ending;
  Future<void>? _disposal;
  bool _disposed = false;
  StreamSubscription<AudioInterruptionEvent>? _interruption;

  bool _current(int generation) =>
      _began && !_disposed && generation == _sessionGeneration;

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
  Future<void> begin() {
    if (_disposed) return Future<void>.value();
    if (_began) return _beginning ?? Future<void>.value();
    _began = true;
    final generation = ++_sessionGeneration;
    // A new page can open while the previous page is releasing its audio.
    // Finish that release before configuring or starting this session.
    return _beginning = _initialize(generation, _ending);
  }

  Future<void> _initialize(int generation, Future<void>? ending) async {
    await ending;
    if (!_current(generation)) return;
    try {
      final s = await _getSession();
      if (!_current(generation)) return;
      _session = s;
      await s.configure(_config(duck: false));
      if (!_current(generation)) return;
      if (Platform.isIOS) {
        await s.setActive(true);
        if (!_current(generation)) return;
        await _keepAlive.setAsset(_silence);
        if (!_current(generation)) return;
        await _keepAlive.setLoopMode(LoopMode.one);
        if (!_current(generation)) return;
        await _keepAlive.setVolume(0);
        if (!_current(generation)) return;
        unawaited(_keepAlive.play());
      }
      _interruption ??= s.interruptionEventStream.listen((e) {
        if (_began && e.begin) unawaited(_voice.stop());
      });
    } on Object {
      // Audio is best-effort; the visual timer works without it.
    }
  }

  @override
  Future<void> end() {
    _began = false;
    ++_sessionGeneration;
    ++_generation;
    _release?.cancel();
    final starting = _beginning;
    _beginning = null;
    return _ending = _finish(_ending, starting);
  }

  Future<void> _finish(Future<void>? ending, Future<void>? starting) async {
    await ending;
    // Invalidate immediately, but let pending native initialization settle
    // before stopping players, so it cannot turn audio back on after end.
    await starting;
    try {
      await _voice.stop();
      await _chime.stop();
      await _keepAlive.stop();
      _ducking = false;
      await _session?.configure(_config(duck: false));
      await _session?.setActive(false);
    } on Object {
      /* ignore */
    }
  }

  Future<void> _duck(bool on) async {
    final generation = _sessionGeneration;
    if (!_current(generation)) return;
    final s = _session;
    if (s == null || on == _ducking) return;
    _ducking = on;
    try {
      await s.configure(_config(duck: on));
      if (!_current(generation)) return;
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
        if (!_current(generation)) return;
        await s.setActive(true);
        if (!_current(generation)) return;
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
    final sessionGeneration = _sessionGeneration;
    bool current() => _current(sessionGeneration) && gen == _generation;
    try {
      await _beginning;
      if (!current() || _session == null) return;
      await _duck(true);
      if (!current()) return;
      await _voice.setVolume(_volume);
      if (!current()) return;
      await _voice.setAudioSources([
        for (final a in assets) AudioSource.asset(a),
      ]);
      if (!current()) return;
      await _voice.play();
      // play() completes when playback ends or is stopped.
      if (!current()) return; // a newer line or session took over
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
    final generation = _sessionGeneration;
    try {
      await _beginning;
      if (!_current(generation)) return;
      await _chime.setVolume(_volume * .9);
      if (!_current(generation)) return;
      await _chime.setAsset(asset);
      if (!_current(generation)) return;
      await _chime.play();
    } on Object {
      /* ignore */
    }
  }

  @override
  set volume(double v) => _volume = v.clamp(0, 1);

  Future<void> dispose() {
    if (_disposal != null) return _disposal!;
    _disposed = true;
    return _disposal = _dispose();
  }

  Future<void> _dispose() async {
    await end();
    await _interruption?.cancel();
    await _voice.dispose();
    await _chime.dispose();
    await _keepAlive.dispose();
  }
}
