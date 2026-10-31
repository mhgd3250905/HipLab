import 'package:flutter/material.dart';
import 'package:ugk_coach/ugk_coach.dart' as coach;
import 'package:ugk_trainer/ugk_trainer.dart' as trainer;

import '../control/hip_store.dart';
import '../domain/hip_pain.dart';
import '../domain/hip_session.dart';
import '../trainer/hip_trainer_plan.dart';
import '../voice/hip_voice.dart';
import '../voice/session_script.dart';
import 'hip_icons.dart';
import 'hip_theme.dart';
import 'hip_widgets.dart';

/// HipLab supplies its safety policy, content and storage. The shared trainer
/// owns the player, active clock, phase engine, audio queue and keep-alive.
class HipPlayerPage extends StatefulWidget {
  const HipPlayerPage({super.key, required this.store, required this.plan});
  final HipStore store;
  final TrainingPlan plan;

  @override
  State<HipPlayerPage> createState() => _HipPlayerPageState();
}

class _HipPlayerPageState extends State<HipPlayerPage> {
  late var _ladder = SessionPainLadder(widget.store.content);
  late final _steps = [...widget.plan.steps];
  final Map<int, String> _felt = {};
  final Set<int> _omitted = {};
  late coach.TrainingPlan? _activeSdkPlan = widget.plan.sdkPlan;
  final Map<int, double> _sdkWorkScale = {};
  String? _ladderCue;

  HipSessionScript _script() {
    final voice = HipVoice.of(context);
    return HipSessionScript(
      lib: voice.lib,
      lang: voice.lang,
      steps: _steps,
      kits: widget.store.content.kits,
      routineIds: [for (final r in widget.plan.routines) r.id],
      restSeconds: widget.plan.transitionSeconds,
      useSdkPhases: widget.plan.sdkPlan != null,
    );
  }

  trainer.SessionBuilder _builder(HipSessionScript script) =>
      widget.plan.sdkPlan != null
      ? trainer.SessionBuilder(
          rhythms: {
            for (final kit in widget.store.content.kits.values)
              kit.id: trainer.Rhythm.fromActionKitJson(kit.raw),
          },
          prepSeconds: 15,
          transitionSeconds: widget.plan.transitionSeconds,
          switchSecondsFor: script.switchSecondsFor,
        )
      : HipSessionBuilder(
          script: script,
          transitionSeconds: widget.plan.transitionSeconds,
        );

  List<trainer.SessionPhase> _replacementPhases() {
    if (_activeSdkPlan case final plan?) {
      return sdkSafetyPhases(
        _builder(_script()),
        plan,
        workScale: _sdkWorkScale,
        omitted: _omitted,
      );
    }
    final phases = _builder(_script()).phases(toTrainerPlan(widget.plan));
    return [
      for (final p in phases)
        if (p.kind == trainer.PhaseKind.done || !_omitted.contains(p.itemIndex))
          p,
    ];
  }

  Future<trainer.DiscomfortDecision?> _pain(
    BuildContext context,
    trainer.DiscomfortContext at,
  ) async {
    final index = at.phase.itemIndex;
    if (index < 0 || index >= _steps.length) return null;
    final kind = await showModalBottomSheet<PainKind>(
      context: context,
      sheetAnimationStyle: HipMotion.sheet,
      builder: (c) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '哪种疼？',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              for (final (kind, icon, label) in [
                (PainKind.pinch, HipGlyph.pinch, '关节夹着疼'),
                (PainKind.nerve, HipGlyph.bolt, '麻、刺、往下窜'),
              ])
                ListTile(
                  key: ValueKey('pain-${kind.name}'),
                  leading: HipIcon(icon, color: HipColors.pain),
                  title: Text(label),
                  onTap: () => Navigator.pop(c, kind),
                ),
            ],
          ),
        ),
      ),
    );
    if (!mounted || kind == null) return null;
    final actualDrill = _activeSdkPlan == null
        ? null
        : widget.store.content.drills[at.phase.exerciseId];
    final target = actualDrill == null
        ? _steps[index]
        : _steps[index].copyWith(drill: actualDrill);
    final action = _ladder.report(
      target.drill.id,
      kind,
      alternative: actualDrill?.alternative ?? target.alternative,
    );
    final direction = SessionPainLadder.primaryDirection(target.drill);
    if (kind == PainKind.nerve) {
      try {
        await widget.store.recordNerve(direction);
      } on Object {
        // The in-memory event is retained and the terminal result save retries
        // persistence. A storage failure must never prevent the safety stop.
        debugPrint('HipLab nerve report awaits session save');
      }
      _ladderCue = action.cue;
      return trainer.DiscomfortDecision(
        trainer.DiscomfortAction.end,
        note: 'nerve',
        subtitle: action.cue,
        voiceClips: const ['p.stop'],
      );
    }
    try {
      await widget.store.recordPain(direction);
    } on Object {
      debugPrint('HipLab pain report awaits session save');
    }
    _ladderCue = action.cue;
    var restart = at.resumePhase.itemIndex;
    var decision = trainer.DiscomfortAction.continueEasier;
    switch (action.type) {
      case PainActionType.reduceAmplitude:
        // Apply the authored half-time policy only to the current work;
        // after-exercise feedback cannot restart an already completed item.
        if (at.afterExercise) {
          return trainer.DiscomfortDecision(
            trainer.DiscomfortAction.continueEasier,
            note: '${kind.name}:${action.type.name}',
            subtitle: action.cue,
            voiceClips: const ['cue.half_range'],
          );
        } else {
          final reduced = target.copyWith(seconds: (target.seconds / 2).ceil());
          if (_activeSdkPlan case final sdk?) {
            final scale = (_sdkWorkScale[index] ?? 1) / 2;
            final fits = _builder(_script())
                .phases(sdk)
                .where((phase) => phase.isWork && phase.itemIndex == index)
                .every((phase) => sdkCanFitFullRep(phase, scale));
            if (fits) {
              _sdkWorkScale[index] = scale;
              _steps[index] = reduced;
            } else {
              _omitted.add(index);
              restart = index + 1;
              decision = trainer.DiscomfortAction.skip;
            }
            break;
          }
          final kit = widget.store.content.kit(reduced.drill.id);
          if (kit != null && SessionScript.noFullRep(reduced, kit)) {
            _omitted.add(index);
            restart = index + 1;
            decision = trainer.DiscomfortAction.skip;
          } else {
            _steps[index] = reduced;
          }
        }
      case PainActionType.substitute:
        final alt = widget.store.content.drill(action.substituteId!);
        if (_activeSdkPlan case final sdk?) {
          _activeSdkPlan = substituteSdkExercise(sdk, target.drill.id, alt.id);
        }
        for (
          var i = at.afterExercise ? restart : index;
          i < _steps.length;
          i++
        ) {
          if (_steps[i].drill.id == target.drill.id) {
            _steps[i] = _steps[i].copyWith(
              drill: alt,
              replaced: target.drill.id,
            );
          }
        }
        decision = trainer.DiscomfortAction.substitute;
      case PainActionType.skipDirection:
        if (_activeSdkPlan case final sdk?) {
          for (final phase in _builder(_script()).phases(sdk)) {
            if (!phase.isWork || phase.itemIndex < restart) continue;
            final drill = widget.store.content.drills[phase.exerciseId];
            if (drill != null &&
                drill.directions.first == direction &&
                !drill.isRelax) {
              _omitted.add(phase.itemIndex);
            }
          }
        }
        for (
          var i = at.afterExercise ? restart : index;
          i < _steps.length;
          i++
        ) {
          final drill = _steps[i].drill;
          if (drill.directions.first == direction && !drill.isRelax) {
            _omitted.add(i);
          }
        }
        decision = trainer.DiscomfortAction.skip;
      case PainActionType.endSession:
        return trainer.DiscomfortDecision(
          trainer.DiscomfortAction.end,
          note: kind.name,
        );
    }
    return trainer.DiscomfortDecision(
      decision,
      substituteId: action.substituteId,
      note: '${kind.name}:${action.type.name}',
      subtitle: action.cue,
      replacementPhases: _replacementPhases(),
      restartItemIndex: restart,
      withRest: at.afterExercise || _omitted.contains(index),
      voiceClips: [
        action.type == PainActionType.reduceAmplitude
            ? 'cue.half_range'
            : 'p.skip',
      ],
    );
  }

  Widget _restFeedback(BuildContext context, trainer.TrainerRestFeedback at) {
    final index = at.completedPhase.itemIndex;
    return StatefulBuilder(
      builder: (context, update) => LayoutBuilder(
        builder: (context, box) => FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: box.maxWidth,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _felt.containsKey(index) ? '已记录' : '刚才感觉怎么样？',
                  key: const ValueKey('feel-prompt'),
                  style: const TextStyle(
                    fontFamily: hipFontFamily,
                    fontSize: 13,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (final (value, label) in [
                      ('ok', '舒服'),
                      ('tight', '有点紧'),
                      ('pain', '疼'),
                    ])
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: OutlinedButton(
                          key: ValueKey('feel-$value'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(70, 36),
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            foregroundColor: _felt[index] == value
                                ? HipColors.jade
                                : HipColors.text,
                            textStyle: const TextStyle(
                              fontFamily: hipFontFamily,
                              fontSize: 14,
                            ),
                          ),
                          child: Text(
                            label,
                            style: const TextStyle(
                              fontFamily: hipFontFamily,
                              fontSize: 14,
                            ),
                          ),
                          onPressed: () async {
                            update(() => _felt[index] = value);
                            if (value == 'pain') await at.reportDiscomfort();
                          },
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  trainer.TrainerTheme get _theme {
    final p = HipColors.palette;
    return trainer.TrainerTheme(
      brightness: p.brightness,
      background: p.background,
      surface: p.surface,
      surfaceHigh: p.surfaceHigh,
      border: p.line,
      shadow: p.shadow,
      track: p.track,
      ringKnob: p.thumb,
      accent: p.jade,
      accentSubtle: p.jade.withValues(alpha: .12),
      accentText: HipColors.jadeText,
      onAccent: p.onJade,
      text: p.text,
      muted: p.muted,
      faint: p.faint,
      caution: p.tight,
      danger: p.pain,
      mediaStage: p.mediaBackdrop,
      fontFamily: hipFontFamily,
    );
  }

  @override
  Widget build(BuildContext context) {
    final voice = HipVoice.of(context);
    final script = _script();
    return trainer.TrainerPlayer(
      plan: toTrainerPlan(widget.plan),
      sessionBuilder: _builder(script),
      prepSeconds: 15,
      transitionSeconds: widget.plan.transitionSeconds,
      strings: trainer.TrainerStrings.zh(),
      theme: _theme,
      notificationIcon: 'mipmap/ic_launcher_monochrome',
      voice: trainer.TrainerVoice(
        source: script.source,
        output: voice.output,
        settings: voice.settings.toTrainer(),
        scriptBuilder: (_, _) => script,
      ),
      drillOf: (id) {
        final drill = widget.store.content.drills[id];
        if (drill == null) return null;
        final step = _steps.where((s) => s.drill.id == id).firstOrNull;
        return trainer.TrainerDrill(
          id: id,
          name: drill.name,
          cue: _ladderCue ?? step?.tip,
        );
      },
      mediaBuilder: (context, request) => AspectRatio(
        aspectRatio: 1,
        child: HipMediaFrame(
          // The shared stage supplies its own edge treatment. Follow the
          // player request so App thumbnails do not round the stage again.
          radius: request.theme.radius,
          child: HipDrillArt(
            drill: widget.store.content.drill(request.drill.id),
            play: !request.paused,
            mirror: request.mirrored,
          ),
        ),
      ),
      doseLabel: widget.plan.sdkPlan != null
          ? null
          : (phase) => phase.itemIndex >= 0 && phase.itemIndex < _steps.length
                ? _steps[phase.itemIndex].dose
                : null,
      onDiscomfort: _pain,
      announceDiscomfortPause: false,
      restFeedbackBuilder: _restFeedback,
      replayBuilder: (context, result, replay) =>
          widget.plan.source != PlanSource.single ||
              _ladder.skippedDirections.isNotEmpty ||
              _ladder.ended
          ? const SizedBox.shrink()
          : HipSecondaryButton(
              key: const ValueKey('player-again'),
              label: '再来一组',
              onPressed:
                  !widget.store.sessions.any(
                    (s) => s.sessionId == result.sessionId,
                  )
                  ? null
                  : () {
                      _ladder = SessionPainLadder(widget.store.content);
                      _steps
                        ..clear()
                        ..addAll(widget.plan.steps);
                      _felt.clear();
                      _omitted.clear();
                      _ladderCue = null;
                      replay();
                    },
            ),
      feedbackBuilder: (context, result) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_ladder.ended) ...[
            const Text('先停下来', style: TextStyle(fontSize: 24)),
            const Text(
              '麻、刺或往下窜的感觉不该出现在练习里。\n建议问问医生或专业人士。',
              textAlign: TextAlign.center,
            ),
          ] else
            Text(
              widget.plan.source == PlanSource.single
                  ? '单练记入练习记录，不计连续天数'
                  : '连续 ${widget.store.streak} 天',
              key: const ValueKey('player-done-note'),
            ),
          if (_ladderCue != null) Text(_ladderCue!),
          if (_felt.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text('本次感受'),
            for (final entry in _felt.entries)
              Text(
                '${_steps[entry.key].drill.name} · ${switch (entry.value) {
                  'ok' => '舒服',
                  'tight' => '有点紧',
                  _ => '疼',
                }}',
              ),
          ],
        ],
      ),
      onFinished: (result) => widget.store.saveTrainerSession(
        result,
        plan: widget.plan,
        ladder: _ladder,
        feedback: _felt,
      ),
    );
  }
}
