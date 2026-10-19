import 'package:flutter_test/flutter_test.dart';
import 'package:hiplab/hip/domain/hip_session.dart';
import 'package:hiplab/hip/voice/session_script.dart';

import 'hip_domain_test.dart' show loadContent;
import 'hip_rep_rhythm_test.dart' show KitSim;

PlanStep _halvedMicroStep() {
  final content = loadContent();
  final micro = content.routines.singleWhere((routine) => routine.micro);
  final plan = TrainingPlanner(
    content,
  ).planFor([micro], const TrainingProfile());
  final step = plan.steps.singleWhere(
    (step) => step.drill.id == 'n-seated-knee-lift',
  );
  return step.copyWith(seconds: (step.seconds / 2).ceil());
}

void main() {
  test(
    'pain reduction cannot schedule a full rep beyond the shortened side',
    () {
      final half = _halvedMicroStep();
      expect(half.seconds, 8);
      expect(half.segments.map((segment) => segment.$2), [4, 4]);
      final sim = KitSim([half]);
      final phase = sim.script.workPhases(0, half).first;
      final kit = sim.script.kits[half.drill.id]!;
      final plan = kit.repPlan(half.kitDose, phase.seconds);

      // One full rep needs seven seconds (lift .65 + hold 5 + lower .7 +
      // rest .65). If no whole rep fits, it must not start a partial one.
      expect(
        plan.reps == 0 || plan.seconds <= phase.seconds,
        isTrue,
        reason:
            '${plan.reps} rep(s) need ${plan.seconds}s but the pain-reduced '
            'side lasts only ${phase.seconds}s.',
      );
    },
  );

  test(
    'pain-shortened micro action never starts a rep without its return cue',
    () {
      final half = _halvedMicroStep();
      final sim = KitSim([half]);
      sim.engine.skip(0); // prep -> the shortened first side
      sim.run(25);
      final work = sim.work(0);
      expect(work, hasLength(2));
      for (final (start, phase) in work) {
        expect(phase.kind, PhaseKind.work);
        expect(phase.seconds, 4);
        final lines = sim.within(start, start + phase.seconds);
        final lifts = lines.where((line) => line.clips.contains('w.lift'));
        final lowers = lines.where((line) => line.clips.contains('w.lower'));
        expect(
          lowers.length,
          lifts.length,
          reason:
              '${phase.side}: a shortened side must either skip its rep or '
              'finish lowering before changing sides; it must not cut a hold.',
        );
      }
    },
  );
}
