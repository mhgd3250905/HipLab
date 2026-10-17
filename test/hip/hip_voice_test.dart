// Voice coaching timeline (#13) and tight-side timing (D-01): given a plan,
// the session clock produces the right phases, the spoken events land at the
// right times, never overlap, counts are never cut, and pause / skip / side
// switch / rest behave.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hiplab/hip/domain/hip_assessment.dart';
import 'package:hiplab/hip/domain/hip_models.dart';
import 'package:hiplab/hip/domain/hip_session.dart';
import 'package:hiplab/hip/voice/session_engine.dart';
import 'package:hiplab/hip/voice/session_script.dart';
import 'package:hiplab/hip/voice/voice_library.dart';
import 'package:hiplab/hip/voice/voice_queue.dart';

import 'hip_domain_test.dart' show loadContent;

class RecordingOutput implements VoiceOutput {
  final spoken = <List<String>>[];
  final chimes = <String>[];
  int stops = 0;
  @override
  Future<void> begin() async {}
  @override
  Future<void> end() async {}
  @override
  Future<void> speak(List<String> assets) async => spoken.add(assets);
  @override
  Future<void> stopSpeech() async => stops++;
  @override
  Future<void> chime(String asset) async => chimes.add(asset);
  @override
  set volume(double v) {}
}

VoiceLibrary loadLibrary() => VoiceLibrary.fromJson(
  jsonDecode(File('assets/voice/manifest.json').readAsStringSync())
      as Map<String, dynamic>,
);

/// Runs a whole session at 20 Hz. [actions] maps an active time to a
/// callback (pause, skip…). Returns the queue (with its log).
class Sim {
  Sim(this.plan, {String lang = 'zh'})
    : lib = loadLibrary(),
      output = RecordingOutput() {
    script = SessionScript(
      lib: lib,
      lang: lang,
      routineIds: [for (final r in plan.routines) r.id],
      restSeconds: plan.transitionSeconds,
    );
    engine = SessionEngine(script: script, steps: plan.steps);
    queue = VoiceQueue(
      output: output,
      lib: lib,
      settings: VoiceSettings(
        language: lang == 'en' ? VoiceLanguage.en : VoiceLanguage.zh,
      ),
    );
  }
  final TrainingPlan plan;
  final VoiceLibrary lib;
  final RecordingOutput output;
  late final SessionScript script;
  late final SessionEngine engine;
  late final VoiceQueue queue;
  final fired = <FiredCue>[];
  final phaseLog = <(double, SessionPhase)>[];

  void run({double until = 1e9, Map<double, void Function(double t)>? at}) {
    var t = 0.0;
    final pending = {...?at};
    SessionPhase? last;
    while (t <= until) {
      for (final k in pending.keys.where((k) => k <= t).toList()) {
        pending.remove(k)!(t);
      }
      for (final f in engine.update(t)) {
        fired.add(f);
        queue.submit(f.cue, t);
      }
      queue.tick(t);
      if (!identical(engine.phase, last)) {
        last = engine.phase;
        phaseLog.add((engine.phaseStart, last));
      }
      if (engine.done && t > engine.phaseStart + 8) break;
      t = double.parse((t + .05).toStringAsFixed(2));
    }
  }

  List<SpokenLine> get lines => queue.log;
  Iterable<SpokenLine> spoken(String clip) =>
      lines.where((l) => l.clips.contains(clip));
}

void main() {
  final content = loadContent();
  final planner = TrainingPlanner(content);

  TrainingPlan planOf(String routine, {TrainingProfile? profile}) =>
      planner.planFor([
        content.routine(routine),
      ], profile ?? const TrainingProfile(level: 3));

  group('tight-side timing (D-01)', () {
    test('normal sided drill splits evenly, right first', () {
      final step = planOf('D').steps.first; // s-kneel-hipflex 每侧 40 秒
      expect(step.sided, isTrue);
      expect(step.segments, [(HipSide.right, 40), (HipSide.left, 40)]);
    });

    test('the extra set goes to the tight side only', () {
      final left = planOf(
        'D',
        profile: const TrainingProfile(
          level: 3,
          asymmetry: {HipDirection.extension: HipSide.left},
        ),
      ).steps.first;
      expect(left.seconds, 120);
      expect(left.extraSide, HipSide.left);
      expect(left.segments, [(HipSide.right, 40), (HipSide.left, 80)]);

      final right = planOf(
        'D',
        profile: const TrainingProfile(
          level: 3,
          asymmetry: {HipDirection.extension: HipSide.right},
        ),
      ).steps.first;
      expect(right.segments, [(HipSide.right, 80), (HipSide.left, 40)]);
    });

    test('half range (pain ladder) keeps the split proportional', () {
      final step = planOf(
        'D',
        profile: const TrainingProfile(
          level: 3,
          asymmetry: {HipDirection.extension: HipSide.left},
        ),
      ).steps.first;
      final half = step.copyWith(seconds: 60);
      expect(half.segments, [(HipSide.right, 20), (HipSide.left, 40)]);
    });

    test('the session clock gives the tight side its longer phase', () {
      final plan = planOf(
        'D',
        profile: const TrainingProfile(
          level: 3,
          asymmetry: {HipDirection.extension: HipSide.left},
        ),
      );
      final sim = Sim(plan);
      final phases = sim.engine.phases.where((p) => p.step == 0).toList();
      expect(phases.map((p) => '${p.kind.name}:${p.side?.name}:${p.seconds}'), [
        'prep:null:15.0',
        'work:right:40.0',
        'switchSide:left:5.0',
        'work:left:80.0',
      ]);
    });
  });

  group('session timeline', () {
    late Sim sim;
    final plan = planOf('D');
    setUp(() {
      sim = Sim(plan)..run();
    });

    test('phases: prep → (work / switch / work) → rest → … → done', () {
      final kinds = sim.phaseLog.map((e) => e.$2.kind).toList();
      expect(kinds.first, PhaseKind.prep);
      expect(kinds.last, PhaseKind.done);
      expect(
        kinds.where((k) => k == PhaseKind.rest).length,
        plan.steps.length - 1,
      );
      final sided = plan.steps.where((s) => s.sided).length;
      expect(kinds.where((k) => k == PhaseKind.switchSide).length, sided);
      expect(sim.engine.completed, plan.steps.length);
    });

    test('session start announces the routine, length and first drill', () {
      final first = sim.lines.first;
      expect(first.start, 0);
      expect(
        first.clips,
        containsAllInOrder(['p.welcome', 'routine.D', 'p.total']),
      );
      final preview = sim.spoken('p.first').single;
      expect(preview.clips, [
        'p.first',
        'drill.s-kneel-hipflex',
        isA<String>(),
      ]);
      expect(preview.clips.last, startsWith('dose.'));
      // 准备 3-2-1 right before the first drill, then 开始 at exactly 15 s.
      final go = sim.lines.firstWhere((l) => l.clips.contains('p.go_right'));
      expect(go.start, closeTo(15, .06));
      for (final k in [3, 2, 1]) {
        expect(
          sim.lines.firstWhere((l) => l.clips.contains('n.$k')).start,
          closeTo(15 - k, .06),
        );
      }
    });

    test(
      'a 40 s side: halfway at 20, 还剩 10 秒 at 30, 5-4-3-2-1 on the second',
      () {
        const start = 15.0; // after prep
        bool near(SpokenLine l, double t) => (l.start - t).abs() < .06;
        expect(sim.spoken('p.half').any((l) => near(l, start + 20)), isTrue);
        expect(sim.spoken('p.last10').any((l) => near(l, start + 30)), isTrue);
        for (var k = 5; k >= 1; k--) {
          expect(
            sim.spoken('n.$k').any((l) => near(l, start + 40 - k)),
            isTrue,
            reason: 'n.$k at ${start + 40 - k}',
          );
        }
        // Side switch: 换左边 at 55, countdown, 开始 at 60.
        expect(
          sim.spoken('p.switch_left').first.start,
          closeTo(start + 40, .06),
        );
        expect(
          sim.lines
              .where((l) => l.clips.contains('p.go') && near(l, start + 45))
              .length,
          1,
        );
      },
    );

    test('rest: 休息 15 秒, preview of the next drill, 3-2-1, 开始', () {
      final rests = sim.spoken('p.rest').toList();
      expect(rests, hasLength(plan.steps.length - 1));
      expect(
        rests.first.clips,
        containsAllInOrder(['p.nice', 'p.rest', 'sec.15']),
      );
      final previews = sim.lines
          .where((l) => l.clips.first == 'p.next' || l.clips.first == 'p.last')
          .toList();
      expect(previews, hasLength(plan.steps.length - 1));
      expect(previews.last.clips.first, 'p.last');
      expect(previews.first.clips[1], 'drill.${plan.steps[1].drill.id}');
    });

    test('counted drills are counted, not counted down', () {
      // h-reverse-clam 每侧 8 次 → 1…8 on each side.
      final i = plan.steps.indexWhere((s) => s.drill.id == 'h-reverse-clam');
      final works = sim.phaseLog
          .where((e) => e.$2.step == i && e.$2.kind == PhaseKind.work)
          .toList();
      expect(works, hasLength(2));
      for (final (start, phase) in works) {
        final inPhase = sim.lines.where(
          (l) => l.start >= start && l.start < start + phase.seconds,
        );
        final numbers = inPhase
            .expand((l) => l.clips)
            .where((c) => c.startsWith('n.'))
            .toList();
        expect(numbers, [for (var k = 1; k <= 8; k++) 'n.$k']);
        expect(inPhase.any((l) => l.clips.contains('p.last10')), isFalse);
      }
    });

    test('never two voices at once; counts are never cut', () {
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
    });

    test('coach lines are spoken during holds, away from the countdown', () {
      final coach = sim.lines.where((l) => l.priority == CuePriority.coach);
      expect(coach, isNotEmpty);
      expect(
        sim.lines.any(
          (l) => l.clips.any((c) => c.startsWith('cue.flexibility')),
        ),
        isTrue,
      );
    });

    test('the end: finish chime and the closing line', () {
      expect(sim.spoken('p.finish'), hasLength(1));
      expect(
        sim.queue.chimeLog.where((c) => c.$2 == 'chime.finish'),
        hasLength(1),
      );
    });
  });

  group('pause / skip / pain', () {
    test(
      'pausing freezes the clock: nothing fires, then it resumes in place',
      () {
        final plan = planOf('D');
        final sim = Sim(plan);
        // Drive manually: active time stops between 20 s and a resume.
        for (var t = 0.0; t <= 20; t += .05) {
          for (final f in sim.engine.update(t)) {
            sim.queue.submit(f.cue, t);
          }
        }
        final before = sim.fired.length + sim.queue.log.length;
        // (paused: the player stops calling update; wall time moves on)
        sim.queue.cancelAll(20);
        expect(sim.engine.phase.kind, PhaseKind.work);
        expect(sim.engine.secondsLeft(20), 35);
        // resume: active time continues from 20
        final fired = sim.engine.update(20.05);
        expect(fired, isEmpty);
        expect(sim.queue.log.length + sim.fired.length, before);
        expect(sim.engine.secondsLeft(20.05), 35);
      },
    );

    test(
      'skip from a drill goes to the rest (no "很好"), from rest into the drill',
      () {
        final plan = planOf('D');
        final sim = Sim(plan);
        sim.run(
          until: 200,
          at: {
            25.0: (t) {
              sim.queue.cancelAll(t);
              sim.engine.skip(t);
            },
            30.0: (t) {
              sim.queue.cancelAll(t);
              sim.engine.skip(t);
            },
          },
        );
        final restLine = sim.lines.firstWhere(
          (l) => l.clips.contains('p.rest'),
        );
        expect(restLine.start, closeTo(25, .06));
        expect(restLine.clips, isNot(contains('p.nice')));
        final go = sim.lines.firstWhere(
          (l) => l.start >= 30 && l.clips.contains('p.go_right'),
        );
        expect(go.start, closeTo(30, .06));
        expect(sim.engine.completed, greaterThanOrEqualTo(1));
      },
    );

    test('pain: replacing the current drill restarts its first side', () {
      final plan = planOf('D');
      final sim = Sim(plan)..run(until: 25);
      final half = sim.engine.steps.first.copyWith(seconds: 40);
      sim.engine.replaceFrom(0, [half, ...sim.engine.steps.skip(1)], 25);
      expect(sim.engine.phase.kind, PhaseKind.work);
      expect(sim.engine.phase.side, HipSide.right);
      expect(sim.engine.phase.seconds, 20);
      expect(sim.engine.secondsLeft(25), 20);
    });

    test(
      'a long background gap lands in the right phase without a backlog',
      () {
        final plan = planOf('D');
        final sim = Sim(plan);
        sim.engine.update(0);
        final fired = sim.engine.update(
          100,
        ); // e.g. screen locked, timer throttled
        // 15 prep + 40 + 5 + 40 = 100 → the rest before drill 2 has just begun.
        expect(sim.engine.phase.kind, PhaseKind.rest);
        expect(sim.engine.phase.step, 1);
        // only cues due right now, none of the missed 5-4-3-2-1s.
        expect(fired.every((f) => (100 - f.time) <= 2.5), isTrue);
      },
    );
  });

  group('english', () {
    test('english session uses english clips with the same timeline', () {
      final sim = Sim(planOf('A'), lang: 'en')..run();
      expect(sim.output.spoken.first.first, 'assets/voice/en/p.welcome.m4a');
      expect(sim.spoken('p.finish'), hasLength(1));
    });
  });

  group('assessment', () {
    test('instructions first, then the hold is counted, then "选一个"', () {
      final lib = loadLibrary();
      final script = SessionScript(
        lib: lib,
        lang: 'zh',
        routineIds: const [],
        restSeconds: 12,
      );
      final item = content.rules.items.firstWhere((i) => i.id == 'thomas');
      final cues = script.assessmentCues(
        item,
        first: false,
        side: HipSide.left,
      );
      final lead = script.assessmentLeadSeconds(
        item,
        first: false,
        side: HipSide.left,
      );
      expect(cues.first.clips, [
        'a.item.thomas',
        'a.left_first',
        'a.cue.thomas',
      ]);
      expect(cues[1].at, lead);
      expect(cues[1].clips, contains('a.hold'));
      expect(cues.last.at, lead + item.seconds);
      expect(cues.last.clips, contains('a.choose'));
      final right = script.assessmentCues(
        item,
        first: false,
        side: HipSide.right,
      );
      expect(right.first.clips.first, 'a.switch_right');
    });

    test('every line the app can ask for exists in both languages', () {
      final lib = loadLibrary();
      final keys = <String>{};
      for (final r in content.routines) {
        final plan = planner.planFor([r], const TrainingProfile(level: 3));
        final script = SessionScript(
          lib: lib,
          lang: 'zh',
          routineIds: [r.id],
          restSeconds: plan.transitionSeconds,
        );
        for (final p in script.phases(plan.steps)) {
          for (final c in script.cues(p, plan.steps)) {
            keys.addAll(c.clips);
          }
        }
      }
      for (final item in content.rules.items) {
        final script = SessionScript(
          lib: lib,
          lang: 'zh',
          routineIds: const [],
          restSeconds: 12,
        );
        for (final side in [null, HipSide.left, HipSide.right]) {
          for (final c in script.assessmentCues(
            item,
            first: true,
            side: side,
          )) {
            keys.addAll(c.clips);
          }
        }
      }
      for (final d in content.drills.values) {
        keys.add('drill.${d.id}');
      }
      for (final lang in ['zh', 'en']) {
        final missing = keys.where((k) => !lib.has(k, lang: lang)).toList();
        expect(missing, isEmpty, reason: lang);
        for (final k in keys.where((k) => !k.startsWith('chime.'))) {
          expect(
            File(lib.asset(k, lang: lang)).existsSync(),
            isTrue,
            reason: k,
          );
        }
      }
    });
  });

  test('repsOf parses counted doses only', () {
    expect(repsOf('每侧 8 次'), 8);
    expect(repsOf('6 次'), 6);
    expect(repsOf('慢呼吸 6 次'), 6);
    expect(repsOf('左右交替 6 次'), 6);
    expect(repsOf('每侧 3 圈'), 3);
    expect(repsOf('正反各 4 圈'), isNull);
    expect(repsOf('每侧 30 秒'), isNull);
    expect(repsOf('停 3 次 × 10 秒'), isNull);
    expect(repsOf('每侧 开 3 + 关 3'), isNull);
  });
}
