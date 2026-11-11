import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import '../../data/hip_shared_library.dart';
import 'package:ugk_coach_chat/ugk_coach_chat.dart';
import 'package:ugk_trainer_runtime/ugk_trainer_runtime.dart' as trainer;

import '../../coach/coach_config.dart';
import '../../coach/hip_coach_chat_storage.dart';
import '../../domain/hip_library.dart';
import '../../domain/hip_session.dart';
import '../../trainer/hip_sdk_session_builder.dart';
import '../../voice/hip_voice.dart';
import '../../voice/session_script.dart';
import '../hip_app.dart' show HipSettingsPage;
import '../hip_assessment_page.dart';
import '../hip_icons.dart';
import '../hip_page_kit.dart';
import '../hip_player_page.dart';
import '../hip_routes.dart';
import '../hip_theme.dart';
import '../hip_text.dart';
import '../hip_widgets.dart';
import '../library/drill_detail_page.dart';
import '../library/group_editor_page.dart';
import '../library/library_actions.dart';
import '../library/practice_page.dart';

bool aiCoachAvailable(BuildContext context, {bool? configured}) =>
    configured ?? CoachConfig.fromEnvironment.configured;

/// Only the route, lifecycle and dependency lookup belong to HipLab.
class HipCoachChatPage extends StatefulWidget {
  const HipCoachChatPage({super.key, required this.actions});
  final LibraryActions actions;
  @override
  State<HipCoachChatPage> createState() => _HipCoachChatPageState();
}

class _HipCoachChatPageState extends State<HipCoachChatPage> {
  Future<CoachChatController>? _loading;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loading = _load();
  }

  Future<CoachChatController> _load() async {
    try {
      return await loadHipChat(context, widget.actions);
    } on Object catch (error, stack) {
      // Diagnosable in a development build without logging user content,
      // credentials or the exception's potentially sensitive message.
      if (kDebugMode) {
        debugPrint('HipLab coach initialization: ${error.runtimeType}');
        debugPrint(stack.toString().split('\n').take(8).join('\n'));
      }
      Error.throwWithStackTrace(error, stack);
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<CoachChatController>(
    future: _loading,
    builder: (context, snapshot) {
      if (snapshot.data case final chat?) {
        return CoachChatPage(controller: chat);
      }
      final failed =
          snapshot.connectionState == ConnectionState.done && snapshot.hasError;
      // UI r2: HipLab's own loading/error shell uses HipNavBar; the chat
      // itself is the SDK's CoachChatPage.
      return HipNavPage(
        title: HipText.of(context).pick('HipLab 训练助手', 'HipLab Coach'),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: HipPanel(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (failed)
                      HipIcon(HipGlyph.info, size: 32, color: HipColors.muted)
                    else
                      SizedBox.square(
                        dimension: 28,
                        child: CircularProgressIndicator(
                          color: HipColors.jade,
                          strokeWidth: 2,
                          semanticsLabel: HipText.of(
                            context,
                          ).pick('正在准备训练助手', 'Preparing your coach'),
                        ),
                      ),
                    const SizedBox(height: 20),
                    Text(
                      failed
                          ? HipText.of(
                              context,
                            ).pick('训练助手暂时无法打开', 'Coach is unavailable')
                          : HipText.of(
                              context,
                            ).pick('正在准备训练助手', 'Preparing your coach'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: HipColors.text,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      failed
                          ? HipText.of(context).pick(
                              '请重试。你也可以返回动作库或训练组，继续安排训练。',
                              'Try again, or return to your move library or saved groups.',
                            )
                          : HipText.of(context).pick(
                              '正在读取动作目录和对话记录',
                              'Loading moves and conversation history',
                            ),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: HipColors.muted,
                      ),
                    ),
                    if (failed) ...[
                      const SizedBox(height: 24),
                      HipPrimaryButton(
                        label: HipText.of(context).pick('重试', 'Retry'),
                        onPressed: () => setState(() {
                          _loading = _load();
                        }),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

Future<CoachChatController> loadHipChat(
  BuildContext context,
  LibraryActions actions,
) {
  final voice = HipVoice.of(context);
  final store = actions.store;
  final builder = hipSdkSessionBuilder(
    store.content,
    // The controller outlives settings routes. Read the current voice language
    // for both SDK admission timing and the player's phase construction.
    switchSecondsFor: (item, rhythm, side) => HipSessionScript(
      lib: voice.lib,
      lang: voice.settings.language.resolveClipLanguage(
        actions.coach!.languageTag,
      ),
      steps: const [],
      kits: store.content.kits,
      useSdkPhases: true,
    ).switchSecondsFor(item, rhythm, side),
  );
  return actions.coach!.load(
    builder: builder,
    languageTag: HipText.of(context).languageTag,
    actions: CoachChatHostActions(
      onStartTraining: (context, request) async {
        final plan = TrainingPlanner(store.content, sdkBuilder: builder)
            .customPlan(
              CustomRoutine(
                id: 'coach-playback',
                name: request.plan.plan.title,
                steps: const [],
                coachPlan: request.plan.plan.toJson(),
              ),
              store.profile,
            );
        if (plan == null || plan.sdkPlan == null) {
          throw StateError('The complete SDK plan cannot be played safely');
        }
        final profile = actions.coach!.controller.profile;
        final policy = profile.mediaPolicy;
        final first = plan.steps.firstOrNull?.drill.id;
        return trainer.TrainerLauncher.open<trainer.SessionResult>(
          context,
          builder: (_) =>
              HipPlayerPage(store: store, plan: plan, sdkBuilder: builder),
          firstPosterAsset: first == null
              ? null
              : policy?.posterAssetFor(first),
          mediaPolicy: policy,
          theme: HipSharedLibrary.theme(context),
          planActionIds: plan.steps.map((step) => step.drill.id),
          experience: profile.trainingExperience,
          onStarting: request.onStarting,
          holdTransition: request.holdTransition,
        );
      },
      onOpenAction: (context, request) => HipSharedLibrary.current != null
          ? HipSharedLibrary.openDetail(context, actions, request.actionId)
          : _push(
              context,
              DrillDetailPage(actions: actions, drillId: request.actionId),
            ),
      onOpenLibrary: (context, request) => _pushPractice(context, actions, 0),
      onOpenSavedPlans: (context) => _pushPractice(context, actions, 2),
      onOpenCustomPlan: (context) => _push(
        context,
        GroupEditorPage(
          actions: actions,
          initial: CustomRoutine(
            id: store.newCustomId(),
            name: store.nextCustomName(),
            steps: const [],
          ),
          isNew: true,
        ),
      ),
      onOpenSettings: (context) =>
          _push(context, HipSettingsPage(store: store)),
    ),
  );
}

Future<void> _push(BuildContext context, Widget page) async {
  await Navigator.of(context).push(HipRoute.content<void>((_) => page));
}

Future<void> _pushPractice(
  BuildContext context,
  LibraryActions actions,
  int segment,
) => _push(
  context,
  Builder(
    builder: (pageContext) => PracticePage(
      actions: actions,
      library: segment == 0,
      memory: PracticeMemory()..segment = segment,
      // UI r2: 去排一套 is the bar's trailing action.
      trailing: segment == 2
          ? HipPressable(
              key: const ValueKey('practice-compose'),
              semanticLabel: HipText.of(context).pick('去排一套', 'Create a plan'),
              scale: .95,
              onTap: () {
                Navigator.of(pageContext).pop();
                actions.coach!.requestCompose();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                child: Text(
                  HipText.of(context).pick('去排一套', 'Create plan'),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: HipColors.jadeText,
                  ),
                ),
              ),
            )
          : null,
      onStartAssessment:
          ({BuildContext? from, double radius = 28, Color? color}) {
            _push(
              pageContext,
              HipAssessmentPage(
                store: actions.store,
                onStartPlan: actions.startPlan,
              ),
            );
          },
    ),
  ),
);

Future<void> openHipSavedCoachPlan(
  BuildContext context,
  LibraryActions actions,
  CustomRoutine routine,
) async {
  final chat = await loadHipChat(context, actions);
  final selection = HiplabCoachPlanStore(
    actions.store,
    catalog: chat.catalog,
  ).snapshot(routine);
  final prepared = chat.prepareSavedPlanDetails(selection);
  if (!context.mounted) return;
  if (!prepared.ok) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          HipText.of(context).pick(
            '计划不符合当前动作范围或训练条件，原计划已保留。',
            'This plan does not meet the current move scope or training requirements. Your original plan is unchanged.',
          ),
        ),
      ),
    );
    return;
  }
  await _push(
    context,
    CoachChatPlanDetailsPage(controller: chat, plan: prepared.reference!),
  );
}

/// Existing saved SDK plans pass the SDK's current admission boundary again.
Future<void> startHipSavedCoachPlan(
  BuildContext context,
  LibraryActions actions,
  CustomRoutine routine,
) async {
  final chat = await loadHipChat(context, actions);
  final saved = HiplabCoachPlanStore(
    actions.store,
    catalog: chat.catalog,
  ).snapshot(routine);
  if (!context.mounted) return;
  await chat.startTraining(
    context,
    ChatMessage(
      id: 'saved-${saved.externalId}',
      role: ChatRole.assistant,
      at: saved.updatedAt ?? DateTime.now(),
      plan: saved.plan,
      savedExternalId: saved.externalId,
      storageRevision: saved.storageRevision,
    ),
    sourceEntry: 'saved_plan',
  );
}

class HipCoachChatEntryCard extends StatelessWidget {
  const HipCoachChatEntryCard({super.key, required this.actions});
  final LibraryActions actions;
  @override
  Widget build(BuildContext context) => HipListRow(
    // UI r2: a normal row in 训练组's first group, not a big card.
    key: const ValueKey('practice-ai-coach'),
    glyph: HipGlyph.bolt,
    title: HipText.of(context).pick('AI 定制训练', 'AI training coach'),
    subtitle: HipText.of(context).pick(
      '说说想拉伸哪里，用髋部动作排一套训练',
      'Tell us your goals and build a guided workout',
    ),
    onTap: () => _push(context, HipCoachChatPage(actions: actions)),
  );
}
