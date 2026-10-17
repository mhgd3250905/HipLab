import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiplab/hip/voice/just_audio_output.dart';
import 'package:just_audio/just_audio.dart';

class _Player extends Fake implements AudioPlayer {
  _Player(this.events);
  final List<String> events;
  @override
  Future<void> setVolume(double volume) async {}
  @override
  Future<Duration?> setAudioSources(
    List<AudioSource> audioSources, {
    bool preload = true,
    int? initialIndex,
    Duration? initialPosition,
    ShuffleOrder? shuffleOrder,
  }) async => Duration.zero;
  @override
  Future<void> play() async => events.add('play');
  @override
  Future<void> stop() async {}
  @override
  Future<void> dispose() async {}
}

class _Session extends Fake implements AudioSession {
  _Session(this.events);
  final List<String> events;
  @override
  Stream<AudioInterruptionEvent> get interruptionEventStream =>
      const Stream.empty();
  @override
  Future<void> configure(AudioSessionConfiguration configuration) async {}
  @override
  Future<bool> setActive(
    bool active, {
    AVAudioSessionSetActiveOptions? avAudioSessionSetActiveOptions,
    AndroidAudioFocusGainType? androidAudioFocusGainType,
    AndroidAudioAttributes? androidAudioAttributes,
    bool? androidWillPauseWhenDucked,
    AudioSessionConfiguration fallbackConfiguration =
        const AudioSessionConfiguration.music(),
  }) async {
    events.add('active:$active');
    return true;
  }
}

void main() {
  test(
    'first speech waits for initialization and acquires focus before play',
    () async {
      final events = <String>[];
      final session = Completer<AudioSession>();
      final player = _Player(events);
      final output = JustAudioVoiceOutput.forTesting(
        voice: player,
        chime: player,
        keepAlive: player,
        session: () => session.future,
      );
      final beginning = output.begin();
      final speech = output.speak(['assets/voice/zh/p.welcome.m4a']);
      await Future<void>.delayed(Duration.zero);
      expect(events, isEmpty);
      session.complete(_Session(events));
      await beginning;
      await speech;
      expect(events, ['active:true', 'play']);
      await output.dispose();
    },
  );

  test(
    'ending while initialization is pending prevents stale speech',
    () async {
      final events = <String>[];
      final session = Completer<AudioSession>();
      final player = _Player(events);
      final output = JustAudioVoiceOutput.forTesting(
        voice: player,
        chime: player,
        keepAlive: player,
        session: () => session.future,
      );
      final beginning = output.begin();
      final speech = output.speak(['assets/voice/zh/p.welcome.m4a']);
      await Future<void>.delayed(Duration.zero);
      final ending = output.end();
      session.complete(_Session(events));
      await Future.wait([beginning, speech, ending]);
      expect(events, isNot(contains('play')));
      expect(events, isNot(contains('active:true')));
      await output.dispose();
    },
  );
}
