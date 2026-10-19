// Android voice fix (2026-10-19): unit checks for the three device issues.
// The full-session reproduction is hip_voice_android_timeline_test.dart.

import 'package:flutter_test/flutter_test.dart';
import 'package:hiplab/core/platform/screen_awake.dart';
import 'package:hiplab/core/platform/training_service.dart';
import 'package:hiplab/hip/voice/session_script.dart';
import 'package:hiplab/hip/voice/voice_library.dart';
import 'package:hiplab/hip/voice/voice_line_controller.dart';
import 'package:hiplab/hip/voice/voice_queue.dart';

import 'hip_voice_playback_test.dart' show FakePlatform, wait;
import 'hip_voice_test.dart' show RecordingOutput;

/// Every prepare takes [loadMs] (a slow, backgrounded player).
class SlowLoadPlatform extends FakePlatform {
  SlowLoadPlatform({required this.loadMs, super.clipMs = 40})
    : super(ios: false);
  final int loadMs;
  @override
  Future<void> loadVoice(List<String> assets) async {
    await wait(loadMs);
    await super.loadVoice(assets);
  }
}

void main() {
  group('3: numbers are never swallowed', () {
    test('3-2-1 asked faster than the player prepares: all three play, in '
        'order (before: each number dropped the one before it)', () async {
      final p = SlowLoadPlatform(loadMs: 120);
      final c = VoiceLineController(
        p,
        releaseDelay: const Duration(milliseconds: 40),
      );
      final calls = <Future<void>>[];
      for (final n in ['n.3', 'n.2', 'n.1']) {
        calls.add(c.speak([n]));
        await wait(60); // next number before the previous one has loaded
      }
      await Future.wait(calls);
      expect(p.finished, ['n.3', 'n.2', 'n.1']);
      expect(p.stopped, isEmpty);
      expect(p.violations, isEmpty);
    });

    test('a deliberate cut still drops everything asked for before it',
        () async {
      final p = SlowLoadPlatform(loadMs: 80);
      final c = VoiceLineController(p);
      final a = c.speak(['coach']);
      final b = c.speak(['info']);
      await wait(20);
      await c.stopSpeech();
      final n = c.speak(['n.3']);
      await Future.wait([a, b, n]);
      expect(p.finished, ['n.3']);
    });

    test('a backlog line more than staleAfter late is skipped only when a '
        'newer one waits', () async {
      final p = SlowLoadPlatform(loadMs: 10, clipMs: 200);
      final skipped = <String>[];
      final c = VoiceLineController(
        p,
        releaseDelay: const Duration(milliseconds: 40),
        staleAfter: const Duration(milliseconds: 100),
        onSkip: (a) => skipped.addAll(a),
      );
      final calls = [
        c.speak(['long']),
        c.speak(['late']), // waits ~210 ms > staleAfter, 'last' behind it
        c.speak(['last']),
      ];
      await Future.wait(calls);
      expect(p.finished, ['long', 'last']);
      expect(skipped, ['late']);
    });
  });

  group('2: line endings are not chopped', () {
    VoiceQueue queueWith(RecordingOutput out) => VoiceQueue(
      output: out,
      lib: VoiceLibrary(
        {
          'zh': {'info': 3000, 'n.3': 464},
        },
        const {},
        const {},
        const {},
      ),
      settings: const VoiceSettings(chimes: false),
    );

    test('a count with only the last word left lets the line finish and '
        'follows it', () {
      final out = RecordingOutput();
      final q = queueWith(out);
      q.submit(const VoiceCue(0, ['info'], CuePriority.info), 0);
      q.submit(const VoiceCue(0, ['n.3'], CuePriority.count), 2.4);
      expect(out.stops, 0, reason: '0.6 s left ≤ tailGrace');
      expect(q.log.first.cutAt, isNull);
      expect(out.spoken.length, 2);
    });

    test('a count still cuts a line that has a lot left (by design)', () {
      final out = RecordingOutput();
      final q = queueWith(out);
      q.submit(const VoiceCue(0, ['info'], CuePriority.info), 0);
      q.submit(const VoiceCue(0, ['n.3'], CuePriority.count), 1.0);
      expect(out.stops, 1);
      expect(q.log.first.cutAt, 1.0);
    });
  });

  group('1: background keep-alive (Android foreground service)', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    final calls = <String>[];
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

    setUp(() {
      calls.clear();
      messenger.setMockMethodCallHandler(TrainingService.channel, (call) async {
        calls.add(call.method);
        return true;
      });
    });
    tearDown(() {
      messenger.setMockMethodCallHandler(TrainingService.channel, null);
      TrainingService.isAndroid = () => true;
    });

    test('a session hold starts the service once and stops it when the '
        'last hold is released', () async {
      TrainingService.isAndroid = () => true;
      ScreenAwake.acquire();
      ScreenAwake.acquire(); // nested session page
      ScreenAwake.release();
      await pumpEventQueue();
      expect(calls, ['start']);
      ScreenAwake.release();
      await pumpEventQueue();
      expect(calls, ['start', 'stop']);
    });

    test('not on iOS / web', () async {
      TrainingService.isAndroid = () => false;
      ScreenAwake.acquire();
      ScreenAwake.release();
      await pumpEventQueue();
      expect(calls, isEmpty);
    });

    test('a missing platform side never throws', () async {
      messenger.setMockMethodCallHandler(TrainingService.channel, null);
      TrainingService.isAndroid = () => true;
      ScreenAwake.acquire();
      ScreenAwake.release();
      await pumpEventQueue();
    });
  });
}
