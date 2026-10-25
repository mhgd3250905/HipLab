// Integration probes for the published SDK player, not a copied scheduler.
// Natural phase changes keep the existing clock. Every manual previous/next
// now settles speech for 150ms, including an isolated tap: this is an explicit
// SDK compatibility difference, not an assertion that the old timing survived.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiplab/hip/voice/voice_library.dart';
import 'package:ugk_coach/ugk_coach.dart' as coach;
import 'package:ugk_trainer/ugk_trainer.dart' as trainer;

import 'hip_voice_test.dart' show RecordingOutput;

const _a = 'n-windshield';
const _b = 's-figure4';
const _c = 'h-knee-hug';
const _backlog = 'queued.old';

// Existing App source/recording fixtures, with short deterministic test clips.
// No decoder, device, real sound or asset/network request is involved.
final _source = VoiceLibrary(
  {
    'zh': {
      'drill.$_a': 2000,
      'drill.$_b': 20,
      'drill.$_c': 20,
      'preview.$_b': 20,
      _backlog: 20,
    },
  },
  const {},
  const {},
  const {},
);

class _Emission {
  const _Emission(this.asset, this.at);
  final String asset;
  final DateTime at;
}

class _ProbeOutput extends RecordingOutput {
  _ProbeOutput(this.now);
  final DateTime Function() now;
  final events = <_Emission>[];

  @override
  Future<void> speak(List<String> assets) async {
    for (final asset in assets) {
      events.add(_Emission(asset, now()));
    }
    await super.speak(assets);
  }

  List<_Emission> hits(String clip) => events
      .where((event) => event.asset == _source.asset(clip, lang: 'zh'))
      .toList();
}

class _NameOnEntry extends trainer.SessionScript {
  _NameOnEntry({this.queueBacklog = false}) : super(source: _source);
  final bool queueBacklog;

  @override
  List<trainer.VoiceCue> cues(
    trainer.SessionPhase phase, {
    double planSeconds = 0,
    bool bySkip = false,
  }) {
    final id = phase.exerciseId;
    if (phase.kind == trainer.PhaseKind.rest && id == _b) {
      return [
        const trainer.VoiceCue(0, ['preview.$_b'], trainer.CuePriority.info),
      ];
    }
    if (!phase.isWork || id == null) return const [];
    return [
      trainer.VoiceCue(0, ['drill.$id'], trainer.CuePriority.call),
      if (queueBacklog && id == _a)
        const trainer.VoiceCue(0, [_backlog], trainer.CuePriority.info),
    ];
  }
}

coach.TrainingPlan _plan({int firstSeconds = 30}) => coach.TrainingPlan(
  id: 'hip-sdk-navigation-voice',
  source: 'template',
  title: 'Navigation voice probe',
  goal: 'mobility',
  scene: 'home',
  level: 1,
  targetMinutes: 2,
  blocks: [
    coach.PlanBlock(
      id: 'main',
      name: 'Main',
      type: coach.BlockType.main,
      items: [
        for (final id in [_a, _b, _c])
          coach.PlanItem(
            exerciseId: id,
            mode: coach.DoseMode.time,
            sets: 1,
            workSeconds: id == _a ? firstSeconds : 30,
            perSide: false,
            restSeconds: 0,
          ),
      ],
    ),
  ],
);

// Public App extension point, only to make a zero/short transition cross inside
// the settle window. Work phases remain long enough to be genuine targets.
class _RestBoundaryBuilder extends trainer.SessionBuilder {
  _RestBoundaryBuilder(this.restSeconds)
    : super(prepSeconds: 0, transitionSeconds: 0);
  final double restSeconds;

  @override
  List<trainer.SessionPhase> phases(coach.TrainingPlan plan) {
    final items = plan.items.toList();
    trainer.SessionPhase at(
      trainer.PhaseKind kind,
      int index,
      double seconds,
    ) => trainer.SessionPhase(
      kind: kind,
      seconds: seconds,
      exerciseId: items[index].exerciseId,
      item: items[index],
      itemIndex: index,
      blockIndex: 0,
      itemInBlock: index,
      set: 1,
      sets: 1,
    );
    return [
      at(trainer.PhaseKind.prep, 0, 0),
      at(trainer.PhaseKind.work, 0, 30),
      at(trainer.PhaseKind.rest, 1, restSeconds),
      at(trainer.PhaseKind.work, 1, 30),
      at(trainer.PhaseKind.work, 2, 30),
      const trainer.SessionPhase(kind: trainer.PhaseKind.done, seconds: 0),
    ];
  }
}

Future<_ProbeOutput> _pump(
  WidgetTester tester, {
  int firstSeconds = 30,
  bool queueBacklog = false,
  trainer.SessionBuilder? builder,
}) async {
  final output = _ProbeOutput(tester.binding.clock.now);
  await tester.pumpWidget(
    MaterialApp(
      home: trainer.TrainerPlayer(
        plan: _plan(firstSeconds: firstSeconds),
        drillOf: (id) => trainer.TrainerDrill(id: id, name: id),
        strings: trainer.TrainerStrings.en(),
        prepSeconds: 0,
        transitionSeconds: 0,
        keepAlive: false,
        sessionBuilder: builder,
        voice: trainer.TrainerVoice(
          source: _source,
          output: output,
          settings: const trainer.VoiceSettings(chimes: false),
          scriptBuilder: (_, _) => _NameOnEntry(queueBacklog: queueBacklog),
        ),
        mediaBuilder: (_, _) => const SizedBox.expand(),
        onFinished: (_) async {},
      ),
    ),
  );
  await tester.pump();
  expect(output.hits('drill.$_a'), hasLength(1));
  return output;
}

Future<void> _unmount(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
}

void main() {
  testWidgets(
    'natural phase entry speaks at its original boundary exactly once',
    (tester) async {
      final output = await _pump(tester, firstSeconds: 3);
      final startedAt = output.hits('drill.$_a').single.at;
      await tester.pump(const Duration(milliseconds: 2999));
      expect(output.hits('drill.$_b'), isEmpty);
      await tester.pump(const Duration(milliseconds: 1));
      expect(output.hits('drill.$_b'), hasLength(1));
      expect(
        output.hits('drill.$_b').single.at.difference(startedAt),
        const Duration(seconds: 3),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(output.hits('drill.$_b'), hasLength(1));
      await _unmount(tester);
    },
  );

  testWidgets('single manual skip has the SDK 150ms delay and speaks once', (
    tester,
  ) async {
    final output = await _pump(tester, queueBacklog: true);
    await tester.pump(const Duration(milliseconds: 100));
    final beforeStops = output.stops;
    final tappedAt = tester.binding.clock.now();
    await tester.tap(find.byKey(const ValueKey('skip')));
    expect(output.stops, greaterThan(beforeStops));
    await tester.pump(const Duration(milliseconds: 149));
    expect(output.hits('drill.$_b'), isEmpty);
    await tester.pump(const Duration(milliseconds: 1));
    expect(output.hits('drill.$_b'), hasLength(1));
    expect(
      output.hits('drill.$_b').single.at.difference(tappedAt),
      const Duration(milliseconds: 150),
    );
    await tester.pump(const Duration(seconds: 3));
    expect(output.hits('drill.$_b'), hasLength(1));
    expect(output.hits(_backlog), isEmpty);
    await _unmount(tester);
  });

  testWidgets(
    'rapid skips cancel the old queue and speak only the final target once',
    (tester) async {
      final output = await _pump(tester, queueBacklog: true);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.byKey(const ValueKey('skip')));
      await tester.pump(const Duration(milliseconds: 100));
      expect(output.hits('drill.$_b'), isEmpty);
      final finalTapAt = tester.binding.clock.now();
      await tester.tap(find.byKey(const ValueKey('skip')));
      await tester.pump(const Duration(milliseconds: 149));
      expect(output.hits('drill.$_b'), isEmpty);
      expect(output.hits('drill.$_c'), isEmpty);
      await tester.pump(const Duration(milliseconds: 1));
      expect(output.hits('drill.$_c'), hasLength(1));
      expect(
        output.hits('drill.$_c').single.at.difference(finalTapAt),
        const Duration(milliseconds: 150),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(output.hits('drill.$_c'), hasLength(1));
      await tester.pump(const Duration(seconds: 2));
      expect(output.hits('drill.$_c'), hasLength(1));
      expect(output.hits('drill.$_b'), isEmpty);
      expect(output.hits(_backlog), isEmpty);
      await _unmount(tester);
    },
  );

  testWidgets(
    'zero and short rests crossed while settling do not swallow the final cue',
    (tester) async {
      for (final rest in [0.0, 0.05]) {
        final output = await _pump(
          tester,
          builder: _RestBoundaryBuilder(rest),
          queueBacklog: true,
        );
        await tester.pump(const Duration(milliseconds: 100));
        await tester.tap(find.byKey(const ValueKey('skip')));
        await tester.pump(const Duration(milliseconds: 149));
        expect(output.hits('drill.$_b'), isEmpty, reason: 'rest=$rest');
        await tester.pump(const Duration(milliseconds: 1));
        expect(output.hits('drill.$_b'), hasLength(1), reason: 'rest=$rest');
        expect(output.hits('preview.$_b'), isEmpty, reason: 'rest=$rest');
        await tester.pump(const Duration(seconds: 1));
        expect(output.hits('drill.$_b'), hasLength(1), reason: 'rest=$rest');
        expect(output.hits(_backlog), isEmpty, reason: 'rest=$rest');
        await _unmount(tester);
      }
    },
  );
}
