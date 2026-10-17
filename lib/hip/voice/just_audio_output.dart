import 'dart:async';
import 'dart:io';

import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';

import 'voice_queue.dart';

/// Real playback for voice coaching (#13).
///
/// * Voice and chimes are separate players so a tick can sit under a number.
/// * iOS category is `playback`: the coach is heard with the ring/silent
///   switch on (a workout follow-along, like a fitness app), and keeps
///   talking with the screen locked (`UIBackgroundModes: audio`).
/// * Other apps' music is lowered (ducked) only while a line is playing:
///   `duckOthers` is taken right before a line and released ~0.7 s after it
///   ends; between lines the session mixes with others at full volume.
/// * During a session a looping silent clip keeps the audio session alive,
///   so with iOS `UIBackgroundModes: audio` the app – and its absolute-time
///   training clock – keeps running with the screen locked.
/// * Interruptions are handled here, not by just_audio (its default would
///   resume a stale line after a call and pause the keep-alive when
///   headphones are unplugged): a call / Siri / alarm or unplugging the
///   headphones cuts the line and is reported on [interruptions] so the
///   player pauses the session; when the interruption ends the session and
///   keep-alive are re-activated, and the player waits for 继续.
///
/// Needs real-device verification (ducking, silent switch, lock screen and
/// interruptions are OS features that tests cannot exercise) – see
/// docs/ios-setup-and-release.md.
class JustAudioVoiceOutput implements VoiceOutput, InterruptibleVoiceOutput {
  final _voice = AudioPlayer(
    handleAudioSessionActivation: false,
    handleInterruptions: false,
  );
  final _chime = AudioPlayer(
    handleAudioSessionActivation: false,
    handleInterruptions: false,
  );
  final _keepAlive = AudioPlayer(
    handleAudioSessionActivation: false,
    handleInterruptions: false,
  );
  final _events = StreamController<AudioInterruption>.broadcast();
  final _subscriptions = <StreamSubscription<Object?>>[];
  AudioSession? _session;
  Timer? _release;
  bool _ducking = false;
  double _volume = 1;
  bool _began = false;
  int _generation = 0;

  @override
  Stream<AudioInterruption> get interruptions => _events.stream;

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
      await _keepAliveOn();
      if (_subscriptions.isEmpty) {
        _subscriptions
          ..add(s.interruptionEventStream.listen(_onInterruption))
          ..add(s.becomingNoisyEventStream.listen((_) => _onUnplugged()));
      }
    } on Object {
      // Audio is best-effort; the visual timer works without it.
    }
  }

  /// iOS: activate the session and loop the silent clip. Android keeps Dart
  /// timers running while the process lives, so nothing to keep alive there.
  Future<void> _keepAliveOn() async {
    if (!Platform.isIOS) return;
    final s = _session;
    if (s == null) return;
    await _step(() => s.setActive(true));
    await _step(() async {
      if (_keepAlive.audioSource == null) {
        await _keepAlive.setAsset(_silence);
        await _keepAlive.setLoopMode(LoopMode.one);
        await _keepAlive.setVolume(0);
      }
    });
    unawaited(_keepAlive.play().catchError((Object _) {}));
  }

  /// Runs one platform call; a failure must not skip the calls after it.
  static Future<void> _step(Future<void> Function() call) async {
    try {
      await call();
    } on Object {
      /* best effort */
    }
  }

  void _onInterruption(AudioInterruptionEvent e) {
    if (!_began) return;
    if (e.begin) {
      // `duck`: another app's short prompt (Android transient focus); the
      // coach can keep going. Anything else (call, Siri, alarm): stop.
      if (e.type == AudioInterruptionType.duck) return;
      _release?.cancel();
      _generation++;
      unawaited(_step(_voice.stop));
      unawaited(_step(_chime.stop));
      _ducking = false;
      _events.add(AudioInterruption.began);
    } else {
      if (e.type == AudioInterruptionType.duck) return;
      unawaited(reactivate().then((_) => _events.add(AudioInterruption.ended)));
    }
  }

  void _onUnplugged() {
    if (!_began) return;
    _release?.cancel();
    _generation++;
    unawaited(_step(_voice.stop));
    // The silent keep-alive keeps running so the app stays awake.
    _events.add(AudioInterruption.unplugged);
  }

  @override
  Future<void> reactivate() async {
    if (!_began) return;
    final s = _session;
    if (s == null) return;
    await _step(() => s.configure(_config(duck: false)));
    _ducking = false;
    if (Platform.isIOS) {
      await _keepAliveOn();
    }
  }

  @override
  Future<void> end() async {
    _release?.cancel();
    _generation++;
    await _step(_voice.stop);
    await _step(_chime.stop);
    await _step(_keepAlive.stop);
    _ducking = false;
    final s = _session;
    if (s != null) {
      await _step(() => s.configure(_config(duck: false)));
      await _step(
        () => s.setActive(
          false,
          avAudioSessionSetActiveOptions:
              AVAudioSessionSetActiveOptions.notifyOthersOnDeactivation,
        ),
      );
    }
    _began = false;
  }

  Future<void> _duck(bool on) async {
    final s = _session;
    if (s == null || on == _ducking) return;
    _ducking = on;
    if (on) {
      // Adding duckOthers and (re-)activating lowers other apps' audio.
      await _step(() => s.configure(_config(duck: true)));
      await _step(() => s.setActive(true));
      return;
    }
    await _step(() => s.configure(_config(duck: false)));
    if (Platform.isIOS) {
      // iOS only lifts the duck when the session deactivates. Pause the
      // keep-alive first (deactivating with running I/O fails with
      // "IsBusy"), notify others so the music comes back up, then take the
      // mixable session and the keep-alive straight back. Each step runs on
      // its own so one failure can't leave the app without a session.
      await _step(_keepAlive.pause);
      await _step(
        () => s.setActive(
          false,
          avAudioSessionSetActiveOptions:
              AVAudioSessionSetActiveOptions.notifyOthersOnDeactivation,
        ),
      );
      if (_began) await _keepAliveOn();
    } else {
      await _step(() => s.setActive(false));
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
    for (final sub in _subscriptions) {
      await sub.cancel();
    }
    _subscriptions.clear();
    await _events.close();
    await _voice.dispose();
    await _chime.dispose();
    await _keepAlive.dispose();
  }
}
