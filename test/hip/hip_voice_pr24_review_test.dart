// PR #24 review (docs/pr24-review-2026-10-19.md), four P2 findings:
//   F24-1 pause / pain after a tail-grace takeover kept playing the old
//         line and the queued countdown;
//   F24-2 a volume change during an in-flight setVoiceVolume was cached as
//         applied, so the lower volume never reached the player;
//   (F24-3 / F24-4 keep-alive: hip_training_keepalive_test.dart)
//   F24-3 the Android foreground service and its CPU wake lock outlived a
//         training that finished on its own (until the page closed / 3 h);
//   F24-4 a stale STOP could end a session that had already started again.
//
// Each group failed before the fix (see docs/android-voice-playback-2026-10-19.md).
import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiplab/hip/domain/hip_session.dart';
import 'package:hiplab/hip/voice/session_engine.dart';
import 'package:hiplab/hip/voice/session_script.dart';
import 'package:hiplab/hip/voice/voice_library.dart';
import 'package:hiplab/hip/voice/voice_line_controller.dart';
import 'package:hiplab/hip/voice/voice_queue.dart';

import 'hip_domain_test.dart' show loadContent;
import 'hip_voice_android_timeline_test.dart' show LaggyPlayer;
import 'hip_voice_playback_test.dart' show FakePlatform, wait;
import 'hip_voice_test.dart' show RecordingOutput, loadVoiceLibrary;

class _Out implements VoiceOutput {
  _Out(this.c);
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

/// Platform whose setVoiceVolume completes only when the test says so.
class _GatedVolumePlatform extends FakePlatform {
  _GatedVolumePlatform() : super(ios: false, clipMs: 20);
  final applied = <double>[];
  Completer<void>? gate;
  @override
  Future<void> setVoiceVolume(double v) async {
    final g = gate;
    if (g != null) await g.future;
    applied.add(v);
  }
}

void main() {
  group(
    'F24-1: pause / pain / skip silence the line on air and the backlog',
    () {
      final lib = VoiceLibrary(
        {
          'zh': {
            'info': 3000,
            'n.3': 464,
            'n.2': 464,
            'p.paused': 900,
            'p.resume': 900,
          },
        },
        const {},
        const {},
        const {},
      );

      VoiceQueue queueOn(LaggyPlayer p) => VoiceQueue(
        output: _Out(VoiceLineController(p)),
        lib: lib,
        settings: const VoiceSettings(chimes: false),
      );

      testWidgets('pain after a tail-grace takeover: the old line stops and the '
          'queued count is never heard', (tester) async {
        final p = LaggyPlayer(lib, 'zh', loadMs: 80);
        final q = queueOn(p);
        final t0 = clock.now();
        double t() => clock.now().difference(t0).inMicroseconds / 1e6;
        q.submit(const VoiceCue(0, ['info'], CuePriority.info), t());
        await tester.binding.delayed(const Duration(milliseconds: 2400));
        // 0.6 s left: the count follows the line instead of cutting it.
        q.submit(const VoiceCue(0, ['n.3'], CuePriority.count), t());
        await tester.binding.delayed(const Duration(milliseconds: 500));
        // 2.9 s: the queue's predicted end of n.3 (2.4 + 0.464) has passed, the
        // real info line is still sounding and n.3 waits behind it.
        final painAt = t();
        q.cancelAll(painAt);
        await tester.binding.delayed(const Duration(milliseconds: 30));
        expect(p.onAir, isNull, reason: 'still sounding after the pain sheet');
        await tester.binding.delayed(const Duration(seconds: 3));
        expect([for (final l in p.played) l.$3], isNot(contains('n.3')));
        expect(
          p.played.where((l) => l.$2 > painAt + .05),
          isEmpty,
          reason: 'heard after cancelAll: ${p.played}',
        );
      });

      testWidgets('manual pause during a slow load: the old line does not play '
          'on, 「已暂停」 follows at once', (tester) async {
        final p = LaggyPlayer(lib, 'zh', loadMs: 600);
        final q = queueOn(p);
        final t0 = clock.now();
        double t() => clock.now().difference(t0).inMicroseconds / 1e6;
        q.submit(const VoiceCue(0, ['info'], CuePriority.info), t());
        // Queue thinks info ends at 3.0 s; it really sounds 0.6–3.6 s.
        await tester.binding.delayed(const Duration(milliseconds: 3200));
        final pauseAt = t();
        q.cancelAll(pauseAt);
        q.submit(const VoiceCue(0, ['p.paused'], CuePriority.call), pauseAt);
        await tester.binding.delayed(const Duration(seconds: 3));
        final info = p.played.where((l) => l.$3 == 'info');
        expect(info, isEmpty, reason: 'info played to its end: ${p.played}');
        expect(p.played.map((l) => l.$3), ['p.paused']);
      });

      // The reviewer's whole-session reproduction: real D set, real manifest,
      // the page's order (pause: cancelAll → 「已暂停」 → clock stops; resume:
      // 「继续」; pain: cancelAll → clock stops). The resume line's tail meets
      // a countdown number, then the pain sheet opens just after the queue's
      // predicted end of that number. Swept over many pause instants so some
      // land exactly there.
      for (final lang in ['zh', 'en']) {
        for (final loadMs in [0, 300]) {
          testWidgets('$lang D, load $loadMs ms: after pause → 继续 → pain, '
              'nothing from before the pain sheet is heard', (tester) async {
            final content = loadContent();
            final real = loadVoiceLibrary();
            final plan = TrainingPlanner(
              content,
            ).planFor([content.routine('D')], const TrainingProfile(level: 3));
            final resumeLen = real.total(['p.resume'], lang: lang);
            final failures = <String>[];
            var trials = 0;
            for (var i = 0; i < 400; i++) {
              for (final painDelay in [.2, .35, .5]) {
                trials++;
                final engine = SessionEngine(
                  script: SessionScript(
                    lib: real,
                    lang: lang,
                    routineIds: const ['D'],
                    restSeconds: plan.transitionSeconds,
                    kits: content.kits,
                  ),
                  steps: plan.steps,
                );
                final p = LaggyPlayer(real, lang, loadMs: loadMs);
                final q = VoiceQueue(
                  output: _Out(VoiceLineController(p)),
                  lib: real,
                  settings: VoiceSettings(
                    chimes: false,
                    language: lang == 'en'
                        ? VoiceLanguage.en
                        : VoiceLanguage.zh,
                  ),
                );
                double wall() => p.now;
                var pausedTotal = 0.0;
                double? pausedAt;
                double active() => (pausedAt ?? wall()) - pausedTotal;
                final pauseAt = 30.0 + i * .1;
                final resumeAt = pauseAt + 3;
                final painAt = resumeAt + resumeLen + painDelay;
                var stage = 0;
                while (wall() < painAt + 4) {
                  final w = wall();
                  if (stage == 0 && w >= pauseAt) {
                    q.cancelAll(active());
                    q.submit(
                      const VoiceCue(0, ['p.paused'], CuePriority.call),
                      active(),
                    );
                    pausedAt = w;
                    stage = 1;
                  } else if (stage == 1 && w >= resumeAt) {
                    pausedTotal += w - pausedAt!;
                    pausedAt = null;
                    q.submit(
                      const VoiceCue(0, ['p.resume'], CuePriority.call),
                      active(),
                    );
                    stage = 2;
                  } else if (stage == 2 && w >= painAt) {
                    q.cancelAll(active());
                    pausedAt = w;
                    stage = 3;
                  }
                  if (pausedAt == null) {
                    final now = active();
                    for (final f in engine.update(now)) {
                      q.submit(f.cue, now);
                    }
                  }
                  q.tick(active());
                  await tester.binding.delayed(
                    const Duration(milliseconds: 33),
                  );
                }
                final from = painAt;
                final late = [
                  for (final l in p.played)
                    if (l.$2 > from + .1) '${l.$3}@${l.$1.toStringAsFixed(2)}',
                ];
                if (late.isNotEmpty) {
                  failures.add(
                    'pause ${pauseAt.toStringAsFixed(2)} pain '
                    '${painAt.toStringAsFixed(2)}: $late',
                  );
                }
                expect(p.violations, isEmpty);
              }
            }
            expect(
              failures,
              isEmpty,
              reason:
                  '${failures.length}/$trials trials heard old voice after '
                  'the pain sheet, e.g. ${failures.take(4)}',
            );
          });
        }
      }

      test('skip / stop: cancelAll always tells the output to stop, even when '
          'the queue predicts silence', () {
        final out = RecordingOutput();
        final q = VoiceQueue(
          output: out,
          lib: lib,
          settings: const VoiceSettings(chimes: false),
        );
        q.submit(const VoiceCue(0, ['info'], CuePriority.info), 0);
        q.submit(const VoiceCue(0, ['n.3'], CuePriority.count), 2.4);
        expect(out.stops, 0, reason: 'tail grace for a normal takeover stays');
        q.cancelAll(2.9);
        expect(out.stops, 1);
        q.cancelAll(20); // nothing at all on the air: harmless extra stop
        expect(out.stops, 2);
      });

      test(
        'a count that follows a tail is predicted after it, not on top of it',
        () {
          final out = RecordingOutput();
          final q = VoiceQueue(
            output: out,
            lib: lib,
            settings: const VoiceSettings(chimes: false),
          );
          q.submit(const VoiceCue(0, ['info'], CuePriority.info), 0);
          q.submit(const VoiceCue(0, ['n.3'], CuePriority.count), 2.4);
          expect(q.log.last.start, closeTo(3.0, 1e-9));
          expect(q.log.last.end, closeTo(3.464, 1e-9));
        },
      );
    },
  );

  group('F24-2: the last volume asked for wins', () {
    test('lowered while the previous setVoiceVolume is in flight', () async {
      final p = _GatedVolumePlatform();
      final c = VoiceLineController(
        p,
        releaseDelay: const Duration(milliseconds: 20),
      );
      c.volume = 1.0;
      p.gate = Completer<void>();
      final first = c.speak(['a']);
      await wait(30); // first line is inside setVoiceVolume(1.0)
      c.volume = 0.25; // slider moved, 试听 again
      p.gate!.complete();
      p.gate = null;
      await first;
      await c.speak(['b']);
      expect(p.applied, [1.0, 0.25]);
      expect(p.finished, ['a', 'b']);
    });

    test('unchanged volume is not re-sent for every line', () async {
      final p = _GatedVolumePlatform();
      final c = VoiceLineController(
        p,
        releaseDelay: const Duration(milliseconds: 20),
      );
      c.volume = .5;
      await c.speak(['a']);
      await c.speak(['b']);
      expect(p.applied, [.5]);
      c.volume = .8;
      await c.speak(['c']);
      expect(p.applied, [.5, .8]);
    });
  });
}
