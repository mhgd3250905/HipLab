import 'package:flutter/material.dart';
import 'package:ugk_coach/ugk_coach.dart' as coach;
import 'package:ugk_trainer_runtime/ugk_trainer.dart' as trainer;

import '../control/hip_store.dart';
import '../domain/hip_pain.dart';
import '../domain/hip_session.dart';
import '../domain/hip_library.dart' show hipSdkDrill, LibraryDose, doseText;
import '../data/hip_public_media.dart';
import '../data/hip_public_text_en.dart';
import '../trainer/hip_trainer_plan.dart';
import '../voice/hip_voice.dart';
import '../voice/session_script.dart';
import 'hip_icons.dart';
import 'hip_content_text.dart';
import 'hip_text.dart';
import 'hip_theme.dart';
import 'hip_widgets.dart';

/// HipLab supplies its safety policy, content and storage. The shared trainer
/// owns the player, active clock, phase engine, audio queue and keep-alive.
class HipPlayerPage extends StatefulWidget {
  const HipPlayerPage({
    super.key,
    required this.store,
    required this.plan,
    this.sdkBuilder,
  });
  final HipStore store;
  final TrainingPlan plan;
  final trainer.SessionBuilder? sdkBuilder;

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

  String _cue(PainAction action) => HipText.of(context).pick(
    action.cue,
    switch (action.type) {
      PainActionType.reduceAmplitude => 'Use a smaller range. Do not force it.',
      PainActionType.substitute => 'Switch to an easier move. Do not force it.',
      PainActionType.skipDirection =>
        'Only gentle relaxation in this direction today. Do not force it.',
      PainActionType.endSession => 'Stop here for today.',
    },
  );

  String _drillName(String id) {
    final t = HipText.of(context);
    final definition = widget.store.content.publicCatalog?[id];
    if (definition != null) return definition.name.of(t.languageTag);
    final drill = widget.store.content.drills[id];
    return drill == null ? id : HipContentText.of(context).drillName(drill);
  }

  coach.TrainingPlan _displayPlan() {
    final original = toTrainerPlan(widget.plan);
    if (!HipText.of(context).isEn || widget.plan.source == PlanSource.custom) {
      return original;
    }
    final title = widget.plan.source == PlanSource.single
        ? _drillName(widget.plan.refId ?? widget.plan.steps.first.drill.id)
        : widget.plan.routines
              .map(HipContentText.of(context).routineName)
              .join(' + ');
    if (title.isEmpty) return original;
    return coach.TrainingPlan(
      schemaVersion: original.schemaVersion,
      id: original.id,
      source: original.source,
      templateId: original.templateId,
      title: title,
      summary: original.summary,
      goal: original.goal,
      scene: original.scene,
      equipment: original.equipment,
      level: original.level,
      targetMinutes: original.targetMinutes,
      blocks: [
        for (final block in original.blocks)
          coach.PlanBlock(
            id: block.id,
            name: block.name == original.title
                ? title
                : switch (block.name) {
                    '热身' => 'Warm-up',
                    '主体' => 'Main',
                    '主训练' => 'Main',
                    '放松' => 'Cool-down',
                    '循环' => 'Circuit',
                    _ => block.name,
                  },
            type: block.type,
            rounds: block.rounds,
            restBetweenRoundsSeconds: block.restBetweenRoundsSeconds,
            items: block.items,
          ),
      ],
      avoid: original.avoid,
      notes: original.notes,
      safetyNotes: original.safetyNotes,
    );
  }

  String _dose(PlanStep step) {
    if (!HipText.of(context).isEn) return step.dose;
    final kit = widget.store.content.kit(step.drill.id);
    if (kit != null) {
      return doseText(
        kit,
        LibraryDose(
          reps: step.kitDose.reps ?? kit.defaultReps,
          seconds: step.kitDose.seconds ?? kit.defaultSeconds,
          holdSeconds: step.kitDose.holdSeconds,
          sets: step.sets,
        ),
        single: widget.plan.source == PlanSource.single,
        lang: 'en',
      );
    }
    final amount = step.kitDose.reps != null
        ? '${step.kitDose.reps} reps${step.kitDose.holdSeconds == null ? '' : ' × ${step.kitDose.holdSeconds}s hold'}'
        : '${step.kitDose.seconds ?? step.seconds}s';
    return '${step.sided ? 'Each side: ' : ''}$amount${step.sets > 1 ? ' × ${step.sets} sets' : ''}';
  }

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
      ? widget.sdkBuilder ??
            hipSdkSessionBuilder(
              widget.store.content,
              switchSecondsFor: script.switchSecondsFor,
              transitionSeconds: widget.plan.transitionSeconds,
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
              Text(
                HipText.of(context).pick('哪种疼？', 'What kind of pain?'),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              for (final (kind, icon, label) in [
                (
                  PainKind.pinch,
                  HipGlyph.pinch,
                  HipText.of(context).pick('关节夹着疼', 'Pinching in the joint'),
                ),
                (
                  PainKind.nerve,
                  HipGlyph.bolt,
                  HipText.of(
                    context,
                  ).pick('麻、刺、往下窜', 'Numbness, tingling or radiating pain'),
                ),
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
      _ladderCue = _cue(action);
      return trainer.DiscomfortDecision(
        trainer.DiscomfortAction.end,
        note: 'nerve',
        subtitle: _cue(action),
        voiceClips: const ['p.stop'],
      );
    }
    try {
      await widget.store.recordPain(direction);
    } on Object {
      debugPrint('HipLab pain report awaits session save');
    }
    _ladderCue = _cue(action);
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
            subtitle: _cue(action),
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
      subtitle: _cue(action),
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
                  _felt.containsKey(index)
                      ? HipText.of(context).pick('已记录', 'Recorded')
                      : HipText.of(
                          context,
                        ).pick('刚才感觉怎么样？', 'How did that feel?'),
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
                      ('ok', HipText.of(context).pick('舒服', 'Good')),
                      ('tight', HipText.of(context).pick('有点紧', 'Tight')),
                      ('pain', HipText.of(context).pick('疼', 'Pain')),
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
      plan: _displayPlan(),
      sessionBuilder: _builder(script),
      prepSeconds: 15,
      transitionSeconds: widget.plan.transitionSeconds,
      strings: HipText.of(context).isEn
          ? trainer.TrainerStrings.en()
          : trainer.TrainerStrings.zh(),
      theme: _theme,
      notificationIcon: 'mipmap/ic_launcher_monochrome',
      voice: trainer.TrainerVoice(
        source: script.source,
        output: voice.output,
        settings: voice.settings.toTrainer(
          appLanguageTag: voice.appLanguageTag,
        ),
        scriptBuilder: (_, _) => script,
      ),
      drillOf: (id) {
        final drill =
            hipSdkDrill(widget.store.content, id) ??
            widget.store.content.drills[id];
        if (drill == null) return null;
        final definition = widget.store.content.publicCatalog?[id];
        final translated = HipText.of(context).isEn
            ? hipPublicTextEn[id]
            : null;
        final step = _steps.where((s) => s.drill.id == id).firstOrNull;
        return trainer.TrainerDrill(
          id: id,
          name: _drillName(id),
          cue:
              _ladderCue ??
              (translated != null
                  ? translated.cues.elementAtOrNull(definition?.primaryCue ?? 0)
                  : step == null
                  ? null
                  : HipContentText.of(context).text(step.tip)),
          cues:
              translated?.cues ??
              definition?.cues[HipText.of(context).languageTag] ??
              const [],
          precautions: [
            if (translated != null) ...[
              ...translated.cautions,
              ...translated.contraindications,
            ] else
              for (final precaution in [
                ...?definition?.cautions,
                ...?definition?.contraindications,
              ])
                HipContentText.of(context).text(precaution),
          ],
          media: trainer.DrillMedia(
            id: id,
            actionId: id,
            videoAsset: '',
            posterAsset: HipPublicMedia.current?.posterAssetFor(id) ?? '',
            duration: 0,
            videoAvailable: HipMediaPolicy.of(context),
          ),
        );
      },
      doseLabel: widget.plan.sdkPlan != null
          ? null
          : (phase) => phase.itemIndex >= 0 && phase.itemIndex < _steps.length
                ? _dose(_steps[phase.itemIndex])
                : null,
      // Public actions without HipLab direction metadata use the SDK's own
      // discomfort flow. Never invent hip directions for a full-body plan.
      onDiscomfort: _steps.any((step) => step.drill.directions.isEmpty)
          ? null
          : _pain,
      announceDiscomfortPause: false,
      restFeedbackBuilder: _restFeedback,
      replayBuilder: (context, result, replay) =>
          widget.plan.source != PlanSource.single ||
              _ladder.skippedDirections.isNotEmpty ||
              _ladder.ended
          ? const SizedBox.shrink()
          : HipSecondaryButton(
              key: const ValueKey('player-again'),
              label: HipText.of(context).pick('再来一组', 'Another set'),
              sdkScale: true,
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
            Text(
              HipText.of(context).pick('先停下来', 'Stop and rest'),
              style: const TextStyle(fontSize: 24),
            ),
            Text(
              HipText.of(context).pick(
                '麻、刺或往下窜的感觉不该出现在练习里。\n建议问问医生或专业人士。',
                'Stop exercising if you feel numbness, tingling or radiating pain.\nConsult a qualified healthcare professional.',
              ),
              textAlign: TextAlign.center,
            ),
          ] else
            Text(
              widget.plan.source == PlanSource.single
                  ? HipText.of(context).pick(
                      '单练记入练习记录，不计连续天数',
                      'Individual moves are logged without extending your streak',
                    )
                  : HipText.of(context).pick(
                      '连续 ${widget.store.streak} 天',
                      '${widget.store.streak}-day streak',
                    ),
              key: const ValueKey('player-done-note'),
            ),
          if (_ladderCue != null) Text(_ladderCue!),
          if (_felt.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(HipText.of(context).pick('本次感受', 'How you felt')),
            for (final entry in _felt.entries)
              Text(
                '${_drillName(_steps[entry.key].drill.id)} · ${switch (entry.value) {
                  'ok' => HipText.of(context).pick('舒服', 'Good'),
                  'tight' => HipText.of(context).pick('有点紧', 'Tight'),
                  _ => HipText.of(context).pick('疼', 'Pain'),
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
