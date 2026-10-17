// Voice audit 2026-10-18: lines must play to their end. On the iPhone build
// lines faded out after a word or two because the duck release (which on
// iOS deactivates the audio session) ran while the next line was still
// playing. These tests drive VoiceLineController with a fake platform that
// plays clips in real (scaled-down) time and fails on any session
// deactivation while something is audible.
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:hiplab/hip/domain/hip_session.dart';
import 'package:hiplab/hip/voice/voice_line_controller.dart';

import 'hip_domain_test.dart' show loadContent;
import 'hip_voice_test.dart' show Sim;

class FakePlatform implements VoicePlatform {
  FakePlatform({
    this.ios = true,
    this.clipMs = 60,
    this.playReturnsAtOnce = false,
  });
  final bool ios;

  /// Old just_audio usage: `play()` on a player still in the "playing"
  /// state (after a completed clip) returns at once.
  final bool playReturnsAtOnce;
  bool _playerPlaying = false;
  final int clipMs;
  final sw = Stopwatch()..start();
  final events = <String>[];
  final violations = <String>[];
  bool active = false;
  bool duckOption = false;
  List<String> _loaded = const [];
  Completer<void>? _playing;
  Timer? _clip;
  String? onAir;
  final finished = <String>[];
  final stopped = <String>[];
  bool chimeOn = false;

  int get now => sw.elapsedMilliseconds;
  void log(String e) => events.add('$now $e');

  @override
  bool get isIOS => ios;

  @override
  Future<void> configureSession({required bool duck}) async {
    await Future<void>.delayed(const Duration(milliseconds: 2));
    duckOption = duck;
    log('configure duck=$duck');
  }

  @override
  Future<void> setSessionActive(bool on) async {
    await Future<void>.delayed(const Duration(milliseconds: 3));
    if (!on && (voiceAudible || chimeAudible)) {
      violations.add('deactivated at $now while ${onAir ?? 'chime'} audible');
    }
    active = on;
    log('active=$on');
  }

  @override
  Future<void> keepAlivePause() async => log('keepAlive pause');
  @override
  Future<void> keepAliveResume() async => log('keepAlive play');
  @override
  Future<void> setVoiceVolume(double v) async {}

  @override
  Future<void> loadVoice(List<String> assets) async {
    await Future<void>.delayed(const Duration(milliseconds: 5));
    _loaded = assets;
  }

  @override
  Future<void> playVoiceToEnd() {
    if (onAir != null) {
      violations.add('$onAir replaced by ${_loaded.join('+')} at $now');
      stopped.add(onAir!);
      _finish();
    }
    if (!active) violations.add('${_loaded.join('+')} played without session');
    final name = _loaded.join('+');
    onAir = name;
    log('play $name');
    final c = _playing = Completer<void>();
    final returnAtOnce = playReturnsAtOnce && _playerPlaying;
    _playerPlaying = true;
    _clip = Timer(Duration(milliseconds: clipMs * _loaded.length), () {
      finished.add(name);
      log('end $name');
      _finish();
    });
    return returnAtOnce ? Future.value() : c.future;
  }

  void _finish() {
    _clip?.cancel();
    onAir = null;
    final c = _playing;
    _playing = null;
    if (c != null && !c.isCompleted) c.complete();
  }

  @override
  Future<void> stopVoice() async {
    if (onAir != null) {
      stopped.add(onAir!);
      log('stop $onAir');
    }
    _finish();
  }

  @override
  bool get voiceAudible => onAir != null;
  @override
  bool get chimeAudible => chimeOn;
}

Future<void> wait(int ms) => Future<void>.delayed(Duration(milliseconds: ms));

void main() {
  VoiceLineController controller(FakePlatform p) => VoiceLineController(
    p,
    releaseDelay: const Duration(milliseconds: 40),
    maxTailWait: const Duration(milliseconds: 400),
  );

  test('a line plays to its end; the duck is released only after it', () async {
    final p = FakePlatform();
    final c = controller(p);
    await c.speak(['a']);
    expect(p.finished, ['a']);
    expect(c.ducking, isTrue, reason: 'release waits releaseDelay');
    await wait(120);
    expect(c.ducking, isFalse);
    expect(p.violations, isEmpty);
    // iOS: deactivate (lift the duck) and take the session straight back.
    expect(p.active, isTrue);
  });

  test('the next line inside the release window keeps the session '
      '(the iPhone bug: the release cut it after ~0.7 s)', () async {
    final p = FakePlatform();
    final c = controller(p);
    await c.speak(['a']);
    await wait(15); // < releaseDelay
    final b = c.speak(['b']);
    await wait(30); // the old release moment falls inside b
    await b;
    expect(p.finished, ['a', 'b']);
    expect(p.stopped, isEmpty);
    expect(p.violations, isEmpty);
    expect(
      p.events.where((e) => e.endsWith('active=false')),
      isEmpty,
      reason: 'no deactivation between back-to-back lines',
    );
  });

  test('second guard: even if play() returned at once (the old just_audio '
      'case), the release waits until nothing is audible', () async {
    final p = FakePlatform(clipMs: 120, playReturnsAtOnce: true);
    final c = controller(p);
    await c.speak(['first']);
    await c.speak(['second']); // returns at once, release due 40 ms later
    await wait(400);
    expect(p.finished, ['first', 'second']);
    expect(p.violations, isEmpty);
    expect(c.ducking, isFalse);
  });

  test('a release that is already running finishes before the next line '
      'activates the session again', () async {
    final p = FakePlatform();
    final c = controller(p);
    await c.speak(['a']);
    await wait(42); // release has just started its platform calls
    await c.speak(['b']);
    expect(p.finished, ['a', 'b']);
    expect(p.violations, isEmpty);
  });

  test('a line asked for while the previous one is still audible waits for '
      'its end instead of clipping its tail', () async {
    final p = FakePlatform(clipMs: 80);
    final c = controller(p);
    unawaited(c.speak(['long', 'line']));
    await wait(100); // the queue's clock says "free", the clip still plays
    await c.speak(['next']);
    expect(p.finished, ['long+line', 'next']);
    expect(p.stopped, isEmpty);
    expect(p.violations, isEmpty);
  });

  test(
    'a deliberate cut (stopSpeech, e.g. a count) takes over at once',
    () async {
      final p = FakePlatform(clipMs: 200);
      final c = controller(p);
      unawaited(c.speak(['coach']));
      await wait(60);
      await c.stopSpeech();
      final t0 = p.now;
      unawaited(c.speak(['n.3']));
      await wait(40);
      expect(p.onAir, 'n.3');
      expect(p.now - t0, lessThan(150));
      expect(p.stopped, ['coach']);
      await wait(300);
      expect(p.violations, isEmpty);
    },
  );

  test('the duck is not released while a chime is still sounding', () async {
    final p = FakePlatform();
    final c = controller(p);
    p.chimeOn = true;
    await c.speak(['a']);
    await wait(120);
    expect(c.ducking, isTrue);
    p.chimeOn = false;
    await wait(120);
    expect(c.ducking, isFalse);
    expect(p.violations, isEmpty);
  });

  test('after an interruption the old line never releases anything', () async {
    final p = FakePlatform(clipMs: 100);
    final c = controller(p);
    unawaited(c.speak(['a']));
    await wait(30);
    c
      ..abandon()
      ..forgetDuck();
    await p.stopVoice();
    final before = p.events.length;
    await wait(200);
    expect(
      p.events.skip(before).where((e) => e.contains('active=false')),
      isEmpty,
    );
  });

  for (final ios in [true, false]) {
    test('random cue storm (${ios ? 'iOS' : 'Android'}): never deactivated '
        'while audible, never two lines at once', () async {
      final rnd = math.Random(7);
      final p = FakePlatform(ios: ios, clipMs: 30);
      final c = controller(p);
      final calls = <Future<void>>[];
      for (var i = 0; i < 60; i++) {
        await wait(rnd.nextInt(90));
        if (rnd.nextInt(4) == 0) await c.stopSpeech();
        calls.add(c.speak(['l$i', if (rnd.nextBool()) 'm$i']));
      }
      await Future.wait(calls);
      await wait(150);
      expect(p.violations, isEmpty, reason: p.events.join('\n'));
      expect(c.ducking, isFalse);
    });
  }

  test('no line is cut by the session timeline (all routines, levels, both '
      'languages)', () {
    final content = loadContent();
    final planner = TrainingPlanner(content);
    for (final lang in ['zh', 'en']) {
      for (final r in content.routines) {
        for (final lvl in [1, 3, 5]) {
          final plan = planner.planFor([r], TrainingProfile(level: lvl));
          final sim = Sim(plan, lang: lang)..run();
          final cut = sim.lines.where((l) => l.cutAt != null);
          expect(cut, isEmpty, reason: '$lang ${r.id} L$lvl: $cut');
          expect(
            sim.lines.length,
            sim.fired.length,
            reason: '$lang ${r.id} L$lvl: a cue was dropped',
          );
        }
      }
    }
  });
}
