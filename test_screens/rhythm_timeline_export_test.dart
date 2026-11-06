// Exports the voice timeline of one representative action per rhythm
// category, before (main: counts at the end of equal slices) and after
// (action kits), for the audit charts and the listening demos:
//
//   flutter test --no-pub test_screens/rhythm_timeline_export_test.dart \
//     --dart-define=OUT=/tmp/rhythm
//
// Writes <OUT>/<case>.<before|after>.<lang>.json: phases, spoken lines (with
// per-clip start times, as the queue plays them back to back) and chimes.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hiplab/hip/domain/hip_models.dart';
import 'package:hiplab/hip/domain/hip_session.dart';
import 'package:hiplab/hip/voice/session_engine.dart';
import 'package:hiplab/hip/voice/session_script.dart';
import 'package:hiplab/hip/voice/voice_library.dart';
import 'package:hiplab/hip/voice/voice_queue.dart';

import '../test/hip/hip_domain_test.dart' show loadContent;
import '../test/hip/hip_voice_test.dart' show RecordingOutput, loadVoiceLibrary;

const _out = String.fromEnvironment('OUT', defaultValue: 'build/rhythm');

/// (case, routine, drill): one representative step per category.
const cases = [
  ('rep_updown', 'C', 'glute-max-A'),
  ('rep_updown_unsided', 'E', 'h-squat'),
  ('rep_cycle', 'C', 'h-quad-cars'),
  ('rep_alternate', 'A', 'n-chair-wiper'),
  ('rep_hold', 'E', 'h-sumo-pry'),
  ('rep_breath', 'B', 'h-knee-hug'),
  ('hold_sided', 'A', 'o-stand-lunge'),
  ('hold', 'F', 's-frog'),
];

void main() {
  final content = loadContent();
  final raw =
      jsonDecode(File('assets/hip/hip-content.json').readAsStringSync())
          as Map<String, dynamic>;
  final lib = loadVoiceLibrary();

  PlanStep step(HipRoutineStep s, {required bool before}) {
    final authored =
        ((raw['routines'] as List).expand(
              (r) => (r as Map)['steps'] as List,
            )).cast<Map>().firstWhere(
              (j) => j['drill'] == s.drillId && j['dose'] == s.dose,
            )['authored_seconds']
            as int?;
    return PlanStep(
      drill: content.drill(s.drillId),
      dose: s.dose,
      seconds: before ? (authored ?? s.seconds) : s.seconds,
      sided: s.sided,
      kitDose: s.kit,
    );
  }

  Map<String, Object?> export(
    List<PlanStep> steps,
    String lang, {
    required bool kits,
  }) {
    final script = SessionScript(
      lib: lib,
      lang: lang,
      routineIds: const [],
      restSeconds: 15,
      kits: kits ? content.kits : const {},
    );
    final engine = SessionEngine(script: script, steps: steps);
    final queue = VoiceQueue(
      output: RecordingOutput(),
      lib: lib,
      settings: VoiceSettings(
        language: lang == 'en' ? VoiceLanguage.en : VoiceLanguage.zh,
      ),
    );
    final phases = <Map<String, Object?>>[];
    SessionPhase? last;
    var t = 0.0;
    while (true) {
      for (final f in engine.update(t)) {
        queue.submit(f.cue, t);
      }
      queue.tick(t);
      if (!identical(engine.phase, last)) {
        last = engine.phase;
        final p = last;
        final kit = kits
            ? content.kit(steps[p.step.clamp(0, steps.length - 1)].drill.id)
            : null;
        final s = steps[p.step.clamp(0, steps.length - 1)];
        final plan = p.isWork && kit != null && kit.kind.counted
            ? kit.repPlan(
                s.kitDose,
                p.seconds,
                sets: SessionScript.setsOf(p, s),
              )
            : null;
        phases.add({
          'start': engine.phaseStart,
          'kind': p.kind.name,
          'step': p.step,
          'side': p.side?.name,
          'seconds': p.seconds,
          if (plan != null)
            'reps': [
              for (var set = 0; set < plan.sets; set++)
                for (var k = 1; k <= plan.reps; k++)
                  {
                    'start': engine.phaseStart + plan.repStart(set, k),
                    'phases': [
                      for (final ph in plan.phases)
                        {'id': ph.id, 'seconds': ph.seconds},
                    ],
                  },
            ],
        });
      }
      if (engine.done && t > engine.phaseStart + 6) break;
      t = double.parse((t + .05).toStringAsFixed(2));
    }
    List<double> clipStarts(SpokenLine l) {
      final out = <double>[];
      var at = l.start;
      for (final c in l.clips) {
        out.add(at);
        at += lib.seconds(c, lang: lang) + .06;
      }
      return out;
    }

    return {
      'lang': lang,
      'steps': [
        for (final s in steps)
          {
            'drill': s.drill.id,
            'name': s.drill.name,
            'dose': s.dose,
            'seconds': s.seconds,
          },
      ],
      'phases': phases,
      'lines': [
        for (final l in queue.log)
          {
            'start': l.start,
            'end': l.end,
            'cut': l.cutAt != null,
            'priority': l.priority.name,
            'clips': l.clips,
            'text': [for (final c in l.clips) lib.line(c, lang: lang) ?? c],
            'at': clipStarts(l),
          },
      ],
      'chimes': [
        for (final (at, c) in queue.chimeLog) {'t': at, 'clip': c},
      ],
    };
  }

  test('export rhythm timelines', () {
    Directory(_out).createSync(recursive: true);
    for (final (name, routine, drill) in cases) {
      final r = content.routine(routine);
      final i = r.steps.indexWhere((s) => s.drillId == drill);
      final picked = [r.steps[i], if (i + 1 < r.steps.length) r.steps[i + 1]];
      for (final before in [true, false]) {
        for (final lang in ['zh', 'en']) {
          final steps = [for (final s in picked) step(s, before: before)];
          final j = export(steps, lang, kits: !before);
          File(
            '$_out/$name.${before ? 'before' : 'after'}.$lang.json',
          ).writeAsStringSync(const JsonEncoder.withIndent(' ').convert(j));
        }
      }
    }
  });
}
