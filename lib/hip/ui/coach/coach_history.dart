// HipLab persists SDK facts and display DTOs; admission stays in ugk_coach.
import 'dart:convert';

import 'package:ugk_coach/ugk_coach.dart' as uc;

Map<String, Object?> coachMessageJson(uc.CoachConversationMessage message) => {
  'id': message.id,
  'at': message.at.toIso8601String(),
  'isUser': message.isUser,
  'text': message.text,
  'question': message.question?.toJson(),
  'questionAnswered': message.questionAnswered,
  'answeredChoices': message.answeredChoices,
  'answeredForm': message.answeredForm,
  'plan': message.plan?.plan.toJson(),
  'planState': message.planState?.toJson(),
  'actions': message.actions == null
      ? null
      : [
          for (final action in message.actions!.items)
            {
              'actionId': action.id,
              if (action.note != null) 'note': action.note,
            },
        ],
  'turnId': message.turnId,
  'isFailure': message.isFailure,
  'isPlanningFailure': message.isPlanningFailure,
};

uc.CoachConversationMessage coachMessageFromJson(
  Map<String, dynamic> json,
  uc.ToolGate gate,
) {
  final state = json['planState'] is Map
      ? uc.CoachPlanState.fromJson(
          Map<String, dynamic>.from(json['planState'] as Map),
        )
      : null;
  uc.ValidatedPlan? plan;
  if (json['plan'] is Map) {
    final decoded = const uc.PlanCodec().decodeStrict(json['plan']);
    if (decoded.ok) {
      final stored = decoded.plan!;
      plan = gate.admitTemplate(
        stored,
        uc.CoachContext(
          scene: stored.scene,
          equipment: stored.equipment.toSet(),
          minutes: stored.targetMinutes,
          level: stored.level,
          avoid: stored.avoid,
        ),
      );
      if (state?.sessionState case final sessionState?) {
        plan = plan?.withSessionVersion(sessionState);
      }
    }
  }
  final actions = json['actions'] is List
      ? gate.check('', [
          uc.LlmToolCall(
            id: 'restore-${json['id']}',
            name: 'show_actions',
            arguments: jsonEncode({'items': json['actions']}),
          ),
        ]).actions
      : null;
  return uc.CoachConversationMessage(
    id: json['id'] as String,
    at: DateTime.parse(json['at'] as String),
    isUser: json['isUser'] == true,
    text: json['text'] as String? ?? '',
    question: _question(json['question']),
    questionAnswered: json['questionAnswered'] == true,
    answeredChoices: _strings(json['answeredChoices']),
    answeredForm: _selections(json['answeredForm']),
    plan: plan,
    planState: state,
    actions: actions,
    turnId: json['turnId'] as String?,
    isFailure: json['isFailure'] == true,
    isPlanningFailure: json['isPlanningFailure'] == true,
  );
}

List<String> _strings(Object? value) =>
    value is List ? value.cast<String>() : const [];

Map<String, List<String>> _selections(Object? value) => value is Map
    ? {
        for (final entry in value.entries)
          entry.key as String: _strings(entry.value),
      }
    : const {};

uc.AskUserQuestion? _question(Object? value) {
  if (value is! Map) return null;
  final json = Map<String, dynamic>.from(value);
  if (json['isConfirmation'] != true) {
    return uc.AskUserGate.check(jsonEncode(json)).question;
  }
  return uc.AskUserQuestion.confirmation(
    question: json['question'] as String,
    focus: json['focus'] as String?,
    defaultSelections: _selections(json['defaultSelections']),
    fields: [
      for (final raw in json['fields'] as List)
        uc.AskUserField(
          key: (raw as Map)['key'] as String,
          label: raw['label'] as String,
          options: _strings(raw['options']),
          multiple: raw['multiple'] == true,
          preselected: _strings(raw['preselected']),
          previousSelections: _strings(raw['previousSelections']),
          optionsByScene: _selections(raw['optionsByScene']),
        ),
    ],
  );
}
