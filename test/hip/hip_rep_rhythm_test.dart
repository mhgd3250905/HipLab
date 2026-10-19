// Rep rhythm (docs/rep-rhythm-audit-2026-10-19.md): every kind of action
// kit, driven by an injected active clock, produces a timeline where the
// count starts each rep, the phase words land on the phase starts, the last
// rep gets its full time before "很好 / 换边", nothing overlaps or is cut,
// and pause / skip / resume keep the beat.
import 'package:flutter_test/flutter_test.dart';
import 'package:hiplab/hip/domain/hip_assessment.dart';
import 'package:hiplab/hip/domain/hip_models.dart';
import 'package:hiplab/hip/domain/hip_session.dart';
import 'package:hiplab/hip/voice/session_engine.dart';
import 'package:hiplab/hip/voice/session_script.dart';
import 'package:hiplab/hip/voice/voice_library.dart';
import 'package:hiplab/hip/voice/voice_queue.dart';

import 'hip_domain_test.dart' show loadContent;
import 'hip_voice_test.dart' show RecordingOutput, loadVoiceLibrary;

/// Active-time clock for tests: wall time advances in 50 ms ticks; while
/// paused the active time stands still (what the player's clock does).
class FakeActiveClock {
  double wall = 0;
  double _paused = 0;
  double? _pausedAt;
  bool get paused => _pausedAt != null;
  double get t => (_pausedAt ?? wall) - _paused;
  void pause() => _pausedAt ??= wall;
  void resume() {
    if (_pausedAt == null) return;
    _paused += wall - _pausedAt!;
    _pausedAt = null;
  }
}

class KitSim {
  KitSim(List<PlanStep> steps, {String lang = 'zh', int rest = 15})
    : lib = loadVoiceLibrary() {
    script = SessionScript(
      lib: lib,
      lang: lang,
      routineIds: const [],
      restSeconds: rest,
      kits: content.kits,
    );
    engine = SessionEngine(script: script, steps: steps);
    queue = VoiceQueue(
      output: RecordingOutput(),
      lib: lib,
      settings: VoiceSettings(
        language: lang == 'en' ? VoiceLanguage.en : VoiceLanguage.zh,
      ),
    );
  }
  static final content = loadContent();
  final VoiceLibrary lib;
  late final SessionScript script;
  late final SessionEngine engine;
  late final VoiceQueue queue;
  final clock = FakeActiveClock();

  /// (active start, phase) of every phase entered.
  final phases = <(double, SessionPhase)>[];

  /// Run until [wallUntil]; [at] maps a wall time to an action.
  void run(double wallUntil, {Map<double, void Function()>? at}) {
    final pending = {...?at};
    SessionPhase? last;
    while (clock.wall <= wallUntil) {
      for (final k in pending.keys.where((k) => k <= clock.wall).toList()) {
        pending.remove(k)!();
      }
      if (!clock.paused) {
        final t = clock.t;
        for (final f in engine.update(t)) {
          queue.submit(f.cue, t);
        }
        queue.tick(t);
        if (!identical(engine.phase, last)) {
          last = engine.phase;
          phases.add((engine.phaseStart, last));
        }
        if (engine.done && t > engine.phaseStart + 8) break;
      }
      clock.wall = double.parse((clock.wall + .05).toStringAsFixed(2));
    }
  }

  List<SpokenLine> get lines => queue.log;
  List<SpokenLine> within(double a, double b) =>
      lines.where((l) => l.start >= a - 1e-6 && l.start < b - 1e-6).toList();
  List<(double, SessionPhase)> work(int step) => [
    for (final p in phases)
      if (p.$2.kind == PhaseKind.work && p.$2.step == step) p,
  ];
}

PlanStep stepOf(
  String drill,
  KitDose dose, {
  bool? sided,
  int budget = 0,
  HipSide? extra,
}) {
  final c = KitSim.content;
  final kit = c.kit(drill)!;
  final s = sided ?? kit.sided;
  final secs = c.stepSeconds(drill, dose, s, budget);
  final per = s ? secs ~/ 2 : secs;
  return PlanStep(
    drill: c.drill(drill),
    dose: '',
    seconds: secs + (extra != null ? per : 0),
    sided: s,
    extraSide: extra,
    extraSeconds: extra != null ? per : 0,
    kitDose: dose,
  );
}

void expectClean(KitSim sim) {
  final lines = sim.lines;
  for (var i = 1; i < lines.length; i++) {
    expect(
      lines[i].start,
      greaterThanOrEqualTo(lines[i - 1].end - 1e-6),
      reason: '${lines[i - 1]} overlaps ${lines[i]}',
    );
  }
  for (final l in lines.where((l) => l.priority == CuePriority.count)) {
    expect(l.cutAt, isNull, reason: '$l was cut');
  }
}

/// Checks one counted work phase: counts on the beat, words on the phase
/// starts, last rep full, nothing after the last rep's words.
void expectRepPhase(
  KitSim sim,
  PlanStep step,
  (double, SessionPhase) work, {
  int sets = 1,
}) {
  final (start, phase) = work;
  final kit = sim.script.kits[step.drill.id]!;
  final plan = kit.repPlan(step.kitDose, phase.seconds, sets: sets);
  final end = start + phase.seconds;
  // The last rep ends exactly at the end of the phase: full cycle.
  expect(
    start + plan.repStart(plan.sets - 1, plan.reps) + plan.cycle,
    closeTo(end, 1e-6),
  );
  final inPhase = sim.within(start, end);
  for (var set = 0; set < plan.sets; set++) {
    for (var k = 1; k <= plan.reps; k++) {
      final at = start + plan.repStart(set, k);
      final last = set == plan.sets - 1 && k == plan.reps && plan.reps >= 3;
      final head = last ? kit.voice.lastRep : kit.voice.countClip(k);
      final line = inPhase.where((l) => (l.start - at).abs() < .06).toList();
      expect(line, hasLength(1), reason: '$head at $at');
      expect(line.single.clips.first, head);
      final word = plan.phases.first.cueFor(k);
      if (word != null) expect(line.single.clips, contains(word));
      // later phase words of this rep
      var t = at;
      for (final ph in plan.phases) {
        if (ph != plan.phases.first && ph.cueFor(k) != null) {
          final w = ph.cueFor(k)!;
          expect(
            inPhase.any(
              (l) =>
                  l.clips.contains(w) && (l.start - (t + ph.cueAt)).abs() < .06,
            ),
            isTrue,
            reason: '$w at ${t + ph.cueAt} (rep $k)',
          );
        }
        t += ph.seconds;
      }
    }
  }
  // Every word of the phase is over before the phase ends.
  for (final l in inPhase) {
    expect(l.end, lessThanOrEqualTo(end + 1e-6), reason: '$l runs past $end');
  }
  // The time from the last count to the end is a whole rep (20 Hz ticks:
  // a cue fires up to one tick late).
  final lastAt = start + plan.repStart(plan.sets - 1, plan.reps);
  final lastCount = inPhase.firstWhere((l) => (l.start - lastAt).abs() < .06);
  expect(end - lastCount.start, greaterThanOrEqualTo(plan.cycle - .06));
}

void main() {
  final content = KitSim.content;

  group('every category', () {
    for (final (drill, dose) in [
      ('glute-max-A', const KitDose(reps: 6)), // 计数·双相起落, 每侧
      ('h-squat', const KitDose(reps: 8)), // 双相, 双侧
      ('h-quad-cars', const KitDose(reps: 3)), // 正反循环, 每侧
      ('n-chair-wiper', const KitDose(reps: 6)), // 左右交替
      ('h-hip-gate', const KitDose(reps: 6)), // 开门 / 关门 交替, 每侧
      ('h-sumo-pry', const KitDose(reps: 3, holdSeconds: 10)), // 带停留
      ('n-seated-knee-lift', const KitDose(reps: 3, holdSeconds: 5)),
      ('h-knee-hug', const KitDose(reps: 6)), // 呼吸
      ('h-butterfly-active', const KitDose(reps: 6)),
    ]) {
      for (final lang in ['zh', 'en']) {
        test('$drill ($lang): beat, phase words, last rep in full', () {
          final kit = content.kit(drill)!;
          final step = stepOf(drill, dose, budget: 0);
          final sim = KitSim([step, step], lang: lang)..run(400);
          final works = sim.work(0);
          expect(works, hasLength(kit.sided ? 2 : 1));
          for (final w in works) {
            expectRepPhase(sim, step, w);
          }
          expectClean(sim);
          // After the last rep: 很好 + rest (never cut into the rep).
          final rest = sim.phases.firstWhere(
            (p) => p.$2.kind == PhaseKind.rest,
          );
          final head = sim.lines.firstWhere((l) => l.clips.contains('p.rest'));
          expect(head.start, closeTo(rest.$1, .06));
          expect(head.clips, contains('p.nice'));
        });
      }
    }

    test('the routine budget slows reps down instead of leaving silence', () {
      // 慢开慢合 6 次 in 60 s: 6 × 9.83 s reps, the movements at demo speed.
      final step = stepOf(
        'h-butterfly-active',
        const KitDose(reps: 6),
        budget: 60,
      );
      expect(step.seconds, 60);
      final sim = KitSim([step])..run(120);
      final (start, phase) = sim.work(0).single;
      final kit = content.kit('h-butterfly-active')!;
      final plan = kit.repPlan(step.kitDose, phase.seconds);
      expect(plan.cycle, closeTo((60 - 1) / 6, 1e-9));
      final base = kit.phasesFor(step.kitDose);
      expect(plan.phases.first.seconds, base.first.seconds); // go unchanged
      expect(
        plan.phases.firstWhere((p) => p.id == 'back').seconds,
        base.firstWhere((p) => p.id == 'back').seconds,
      );
      expectRepPhase(sim, step, (start, phase));
      expectClean(sim);
    });

    test('停 N 秒 stays N seconds when the reps are slowed down', () {
      final kit = content.kit('h-sumo-pry')!;
      const dose = KitDose(reps: 3, holdSeconds: 10);
      final plan = kit.repPlan(dose, 50);
      expect(plan.cycle, closeTo(49 / 3, 1e-9));
      expect(plan.phases.firstWhere((p) => p.id == 'hold').seconds, 10);
      expect(
        plan.phases.firstWhere((p) => p.id == 'rest').seconds,
        greaterThan(kit.phases.firstWhere((p) => p.id == 'rest').seconds),
      );
    });

    test('hold, sided: start, halfway, 还剩 10 秒, 5-4-3-2-1, 慢慢还原 + 换边', () {
      final step = stepOf('s-figure4', const KitDose(seconds: 40), budget: 80);
      final sim = KitSim([step, step])..run(300);
      final works = sim.work(0);
      expect(works, hasLength(2));
      final (s0, p0) = works.first;
      bool near(SpokenLine l, double t) => (l.start - t).abs() < .06;
      expect(
        sim.lines.any((l) => l.clips.contains('p.go') && near(l, s0)),
        isTrue,
      );
      expect(
        sim.lines.any((l) => l.clips.contains('p.half') && near(l, s0 + 20)),
        isTrue,
      );
      expect(
        sim.lines.any((l) => l.clips.contains('p.last10') && near(l, s0 + 30)),
        isTrue,
      );
      for (var k = 5; k >= 1; k--) {
        expect(
          sim.lines.any(
            (l) => l.clips.contains('n.$k') && near(l, s0 + 40 - k),
          ),
          isTrue,
        );
      }
      final sw = sim.lines.firstWhere((l) => l.clips.contains('p.switch_left'));
      expect(sw.start, closeTo(s0 + p0.seconds, .06));
      expect(sw.clips, containsAllInOrder(['p.release', 'p.switch_left']));
      final rest = sim.lines.firstWhere((l) => l.clips.contains('p.rest'));
      expect(rest.clips, contains('p.release'));
      expectClean(sim);
    });

    test('tight side: two sets, 再来一组 between them, each set in full', () {
      final step = stepOf(
        'glute-max-A',
        const KitDose(reps: 6),
        budget: 54,
        extra: HipSide.left,
      );
      final sim = KitSim([step])..run(200);
      final works = sim.work(0);
      expect(works[0].$2.side, HipSide.right);
      expect(works[1].$2.side, HipSide.left);
      expectRepPhase(sim, step, works[0]);
      expectRepPhase(sim, step, works[1], sets: 2);
      final again = sim.lines.where((l) => l.clips.contains('p.again'));
      expect(again, hasLength(1));
      expect(
        again.single.start,
        closeTo(works[1].$1 + works[1].$2.seconds / 2, .06),
      );
      expectClean(sim);
    });
  });

  group('transitions', () {
    test('rest: 很好 → 预告（先做右边）→ 要点 → 3-2-1 → 开始, no overlap', () {
      final a = stepOf('h-squat', const KitDose(reps: 6), budget: 40);
      final b = stepOf('glute-max-A', const KitDose(reps: 6), budget: 54);
      final sim = KitSim([a, b])..run(200);
      final rest = sim.phases.firstWhere((p) => p.$2.kind == PhaseKind.rest);
      final inRest = sim.within(rest.$1, rest.$1 + 15);
      expect(
        inRest.first.clips,
        containsAllInOrder(['p.nice', 'p.rest', 'sec.15']),
      );
      final preview = inRest.firstWhere((l) => l.clips.first == 'p.last');
      expect(
        preview.clips,
        containsAllInOrder(['drill.glute-max-A', 'p.right_first']),
      );
      for (final k in [3, 2, 1]) {
        expect(
          inRest.any(
            (l) =>
                l.clips.contains('n.$k') &&
                (l.start - (rest.$1 + 15 - k)).abs() < .06,
          ),
          isTrue,
        );
      }
      // everything else in the rest is over before the 3-2-1
      for (final l in inRest.where((l) => l.priority != CuePriority.count)) {
        expect(l.end, lessThanOrEqualTo(rest.$1 + 12 + 1e-6), reason: '$l');
      }
      expectClean(sim);
    });
  });

  group('pause / skip / resume', () {
    test('a pause mid-rep keeps every later beat on the active clock', () {
      final step = stepOf('h-squat', const KitDose(reps: 8), budget: 50);
      final plain = KitSim([step])..run(120);
      final paused = KitSim([step]);
      paused.run(
        140,
        at: {
          26.0: () {
            paused.queue.cancelAll(paused.clock.t);
            paused.clock.pause();
          },
          36.0: paused.clock.resume,
        },
      );
      List<(double, String)> beats(KitSim s) => [
        for (final l in s.lines)
          if (l.start > 26.2 && l.priority == CuePriority.count)
            (double.parse(l.start.toStringAsFixed(2)), l.clips.join('+')),
      ];
      expect(beats(paused), beats(plain));
      expect(paused.clock.t, lessThan(paused.clock.wall));
      expectClean(paused);
    });

    test(
      'skip mid-set → rest at once; skip the rest → 开始 then 一 on the beat',
      () {
        final a = stepOf('h-squat', const KitDose(reps: 8), budget: 50);
        final b = stepOf('h-squat', const KitDose(reps: 6), budget: 40);
        final sim = KitSim([a, b]);
        sim.run(
          120,
          at: {
            25.0: () {
              sim.queue.cancelAll(sim.clock.t);
              sim.engine.skip(sim.clock.t);
            },
            30.0: () {
              sim.queue.cancelAll(sim.clock.t);
              sim.engine.skip(sim.clock.t);
            },
          },
        );
        // nothing of the first drill after the skip
        expect(
          sim
              .within(25.01, 30)
              .where(
                (l) =>
                    l.priority == CuePriority.count &&
                    !l.clips.first.startsWith('n.'),
              ),
          isEmpty,
        );
        final work = sim.work(1).single;
        expect(work.$1, closeTo(30, .06));
        expectRepPhase(sim, b, work);
        expectClean(sim);
      },
    );

    test('pain: half the time keeps whole reps and the last one in full', () {
      final step = stepOf('h-squat', const KitDose(reps: 8), budget: 50);
      final sim = KitSim([step])..run(20);
      final half = step.copyWith(seconds: (step.seconds / 2).ceil());
      sim.engine.replaceFrom(0, [half], sim.clock.t);
      sim.run(80);
      final work = sim.work(0).last;
      final kit = content.kit('h-squat')!;
      final plan = kit.repPlan(half.kitDose, work.$2.seconds);
      expect(plan.reps, lessThan(8));
      expectRepPhase(sim, half, work);
    });
  });

  group('routines with kits', () {
    for (final r in content.routines) {
      test('routine ${r.id}: clean timeline, every counted side in full', () {
        final plan = TrainingPlanner(
          content,
        ).planFor([r], const TrainingProfile(level: 3));
        for (final lang in ['zh', 'en']) {
          final sim = KitSim(
            plan.steps,
            lang: lang,
            rest: plan.transitionSeconds,
          )..run(2000);
          expect(sim.engine.done, isTrue);
          for (final (i, s) in plan.steps.indexed) {
            final kit = content.kit(s.drill.id)!;
            if (!kit.kind.counted) continue;
            for (final w in sim.work(i)) {
              expectRepPhase(sim, s, w);
            }
          }
          expectClean(sim);
        }
      });
    }
  });
}
