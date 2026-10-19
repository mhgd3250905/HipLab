// Android voice fix (2026-10-19, device feedback with headphones):
//   1. in the background playback stuttered,
//   2. some lines lost their last ~0.5 s,
//   3. numbers in a run were swallowed – a whole 「3、2、1」 went missing.
//
// These tests drive the real pipeline – SessionEngine → VoiceQueue →
// VoiceLineController – against a fake player that behaves like the real
// one on a slow phone: every line needs a load (prepare) before it sounds,
// and a clip lasts exactly as long as its asset (manifest ms). Time is the
// test binding's fake clock, so whole sessions run in a few seconds and the
// timer never sees a frame callback (like a backgrounded app).
import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiplab/hip/domain/hip_assessment.dart' show HipSide;
import 'package:hiplab/hip/domain/hip_session.dart';
import 'package:hiplab/hip/voice/session_engine.dart';
import 'package:hiplab/hip/voice/session_script.dart';
import 'package:hiplab/hip/voice/voice_library.dart';
import 'package:hiplab/hip/voice/voice_line_controller.dart';
import 'package:hiplab/hip/voice/voice_queue.dart';

import 'hip_domain_test.dart' show loadContent;
import 'hip_voice_test.dart' show loadVoiceLibrary;

/// A just_audio stand-in with real clip lengths and a slow prepare.
class LaggyPlayer implements VoicePlatform {
  LaggyPlayer(this.lib, this.lang, {required this.loadMs, this.callMs = 15});
  final VoiceLibrary lib;
  final String lang;

  /// setAudioSources → ready (an ExoPlayer prepare through the platform
  /// channel; slow when the process is throttled in the background).
  final int loadMs;

  /// Any other platform-channel call (focus, volume).
  final int callMs;

  final DateTime _t0 = clock.now();
  double get now => clock.now().difference(_t0).inMicroseconds / 1e6;

  List<String> _loaded = const [];
  String? onAir;
  double _endsAt = 0;
  Timer? _clip;
  Completer<void>? _playing;

  /// (start, end, clips) of every line that played to its end.
  final played = <(double, double, String)>[];

  /// Lines stopped while sounding, with the seconds that were left.
  final stopped = <(String, double)>[];
  final violations = <String>[];

  static String keyOf(String asset) =>
      asset.split('/').last.replaceAll('.m4a', '');

  double lengthOf(List<String> assets) =>
      lib.total([for (final a in assets) keyOf(a)], lang: lang);

  Future<void> _call() =>
      Future<void>.delayed(Duration(milliseconds: callMs));

  @override
  bool get isIOS => false;
  @override
  Future<void> configureSession({required bool duck}) => _call();
  @override
  Future<void> setSessionActive(bool active) => _call();
  @override
  Future<void> keepAlivePause() async {}
  @override
  Future<void> keepAliveResume() async {}
  @override
  Future<void> setVoiceVolume(double v) => _call();

  @override
  Future<void> loadVoice(List<String> assets) async {
    // Like JustAudioVoiceOutput.loadVoice: reusing the player stops what
    // it was playing.
    _stopNow();
    await Future<void>.delayed(Duration(milliseconds: loadMs));
    _loaded = assets;
  }

  @override
  Future<void> playVoiceToEnd() {
    if (onAir != null) violations.add('two lines at ${now.toStringAsFixed(2)}');
    final name = [for (final a in _loaded) keyOf(a)].join('+');
    final start = now;
    final len = lengthOf(_loaded);
    onAir = name;
    _endsAt = start + len;
    final c = _playing = Completer<void>();
    _clip = Timer(Duration(microseconds: (len * 1e6).round()), () {
      played.add((start, now, name));
      onAir = null;
      _playing = null;
      c.complete();
    });
    return c.future;
  }

  void _stopNow() {
    final name = onAir;
    if (name != null) stopped.add((name, _endsAt - now));
    _clip?.cancel();
    onAir = null;
    final c = _playing;
    _playing = null;
    if (c != null && !c.isCompleted) c.complete();
  }

  @override
  Future<void> stopVoice() async => _stopNow();

  @override
  bool get voiceAudible => onAir != null;
  @override
  bool get chimeAudible => false;
}

class _ControllerOutput implements VoiceOutput {
  _ControllerOutput(this.c);
  final VoiceLineController c;
  @override
  Future<void> begin() async {}
  @override
  Future<void> end() async {}
  @override
  Future<void> speak(List<String> assets) => c.speak(assets);
  @override
  Future<void> stopSpeech() => c.stopSpeech();
  @override
  Future<void> chime(String asset) async {}
  @override
  set volume(double v) {}
}

class TimelineRun {
  TimelineRun({required this.fired, required this.player});
  final List<FiredCue> fired;
  final LaggyPlayer player;

  List<FiredCue> get countCues => [
    for (final f in fired)
      if (f.cue.priority == CuePriority.count && f.cue.voiceClips.isNotEmpty)
        f,
  ];

  /// Count cues that never reached the speaker.
  List<FiredCue> get missingCounts {
    final heard = [for (final p in player.played) p.$3];
    final out = <FiredCue>[];
    var from = 0;
    for (final f in countCues) {
      final name = f.cue.voiceClips.join('+');
      final i = heard.indexOf(name, from);
      if (i < 0) {
        out.add(f);
      } else {
        from = i + 1;
      }
    }
    return out;
  }
}

/// Runs [plan] like the player page does: a 33 ms timer on the wall clock
/// (no frame callbacks), the engine's cues into the queue.
Future<TimelineRun> runTimeline(
  WidgetTester tester,
  TrainingPlan plan, {
  required String lang,
  required int loadMs,
  double? until,
}) async {
  final content = loadContent();
  final lib = loadVoiceLibrary();
  final script = SessionScript(
    lib: lib,
    lang: lang,
    routineIds: [for (final r in plan.routines) r.id],
    restSeconds: plan.transitionSeconds,
    kits: content.kits,
  );
  final engine = SessionEngine(script: script, steps: plan.steps);
  final player = LaggyPlayer(lib, lang, loadMs: loadMs);
  final controller = VoiceLineController(player);
  final queue = VoiceQueue(
    output: _ControllerOutput(controller),
    lib: lib,
    settings: VoiceSettings(
      language: lang == 'en' ? VoiceLanguage.en : VoiceLanguage.zh,
    ),
  );
  final fired = <FiredCue>[];
  final start = clock.now();
  double t() => clock.now().difference(start).inMicroseconds / 1e6;
  while (true) {
    final now = t();
    for (final f in engine.update(now)) {
      fired.add(f);
      queue.submit(f.cue, now);
    }
    queue.tick(now);
    if (engine.done && now > engine.phaseStart + 6) break;
    if (until != null && now > until) break;
    await tester.binding.delayed(const Duration(milliseconds: 33));
  }
  await tester.binding.delayed(const Duration(seconds: 5));
  return TimelineRun(fired: fired, player: player);
}

void main() {
  final content = loadContent();
  final planner = TrainingPlanner(content);
  TrainingPlan planOf(String routine) =>
      planner.planFor([content.routine(routine)], const TrainingProfile(level: 3));

  // 80 ms ≈ a foreground prepare; 300 ms a busy phone; 600 ms ≈ a
  // throttled background process. Before the fix, at 600 ms 588 of 956
  // count cues (zh, all routines) never sounded and 52 whole 3-2-1 runs
  // were silent; in English the switch line lost 0.7–1.5 s at any load.
  for (final loadMs in [80, 300, 600]) {
    for (final lang in ['zh', 'en']) {
      for (final routine in ['A', 'D']) {
        testWidgets('$lang $routine, load $loadMs ms: no line cut, every '
            'count heard, never two at once', (tester) async {
          final run = await runTimeline(
            tester,
            planOf(routine),
            lang: lang,
            loadMs: loadMs,
          );
          final p = run.player;
          expect(p.violations, isEmpty);
          expect(
            p.stopped,
            isEmpty,
            reason: 'lines cut by the timeline: ${p.stopped}',
          );
          expect(
            run.missingCounts,
            isEmpty,
            reason:
                '${run.missingCounts.length}/${run.countCues.length} counts '
                'never heard: ${run.missingCounts.take(8)}',
          );
          expect(run.countCues, isNotEmpty);
        });
      }
    }
  }

  // A prepare longer than the gap between two counts cannot keep up with a
  // count every second; then the controller skips lines that fell more than
  // 3 s behind – but it still never cuts a line or plays two at once. (The
  // foreground service exists so a real phone does not get here.)
  testWidgets('load 1100 ms: degrades by skipping late lines, never cuts or '
      'overlaps', (tester) async {
    for (final lang in ['zh', 'en']) {
      final run = await runTimeline(
        tester,
        planOf('D'),
        lang: lang,
        loadMs: 1100,
      );
      expect(run.player.violations, isEmpty);
      expect(run.player.stopped, isEmpty, reason: '${run.player.stopped}');
    }
  });

  testWidgets('switch side: the whole switch line is heard, then 3-2-1 '
      '(en, the line that lost ~0.6 s)', (tester) async {
    final plan = planOf('D');
    final run = await runTimeline(tester, plan, lang: 'en', loadMs: 300);
    final p = run.player;
    final switches = p.played.where(
      (l) => l.$3.contains('p.switch_left') || l.$3.contains('p.switch_right'),
    );
    expect(switches, isNotEmpty);
    for (final sw in switches) {
      final after = p.played.where((l) => l.$1 >= sw.$2).take(3).toList();
      expect(
        [for (final l in after) l.$3],
        ['n.3', 'n.2', 'n.1'],
        reason: 'after "${sw.$3}" ended at ${sw.$2.toStringAsFixed(2)}',
      );
    }
    expect(p.stopped, isEmpty);
  });

  test('the switch gap fits its line before the 3-2-1, in both languages', () {
    final lib = loadVoiceLibrary();
    for (final lang in ['zh', 'en']) {
      final script = SessionScript(
        lib: lib,
        lang: lang,
        routineIds: const [],
        restSeconds: 15,
        kits: content.kits,
      );
      for (final r in content.routines) {
        for (final s in planner.planFor([r], const TrainingProfile(level: 3)).steps) {
          for (final side in [HipSide.left, HipSide.right]) {
            final len = lib.total(script.switchClips(s, side), lang: lang);
            final gap = script.switchSecondsFor(s, side);
            expect(gap, greaterThanOrEqualTo(5));
            expect(
              len + SessionScript.switchMargin,
              lessThanOrEqualTo(gap - 3),
              reason: '$lang ${s.drill.id} $side',
            );
            expect(gap, gap.roundToDouble());
          }
        }
      }
    }
  });
}
