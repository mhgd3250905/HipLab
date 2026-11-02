import 'package:flutter/material.dart';
import 'package:ugk_coach_chat/ugk_coach_chat.dart';
import 'package:ugk_trainer_runtime/engine.dart' as trainer;

import '../../coach/coach_config.dart';
import '../../coach/hip_coach_chat_storage.dart';
import '../../domain/hip_library.dart';
import '../../domain/hip_session.dart';
import '../../trainer/hip_sdk_session_builder.dart';
import '../../voice/hip_voice.dart';
import '../../voice/session_script.dart';
import '../hip_app.dart' show HipProgressPage, HipProgressSection;
import '../hip_assessment_page.dart';
import '../hip_icons.dart';
import '../hip_player_page.dart';
import '../hip_routes.dart';
import '../hip_theme.dart';
import '../hip_widgets.dart';
import '../library/drill_detail_page.dart';
import '../library/group_editor_page.dart';
import '../library/library_actions.dart';
import '../library/practice_page.dart';

bool aiCoachAvailable(BuildContext context, {bool? configured}) =>
    (configured ?? CoachConfig.fromEnvironment.configured) &&
    Theme.of(context).platform != TargetPlatform.iOS &&
    (Localizations.maybeLocaleOf(context)?.languageCode ?? 'zh') == 'zh';

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
    _loading ??= loadHipChat(context, widget.actions);
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<CoachChatController>(
    future: _loading,
    builder: (context, snapshot) {
      if (snapshot.data case final chat?) {
        return CoachChatPage(controller: chat);
      }
      return Scaffold(
        appBar: AppBar(title: const Text('HipLab 训练助手')),
        body: Center(
          child: snapshot.hasError
              ? TextButton(
                  onPressed: () => setState(() {
                    _loading = loadHipChat(context, widget.actions);
                  }),
                  child: const Text('对话恢复失败，点击重试'),
                )
              : const CircularProgressIndicator(),
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
      lang: voice.lang,
      steps: const [],
      kits: store.content.kits,
      useSdkPhases: true,
    ).switchSecondsFor(item, rhythm, side),
  );
  return actions.coach!.load(
    builder: builder,
    actions: CoachChatHostActions(
      onStartTraining: (context, request) async {
        final release = request.holdTransition();
        Animation<double>? animation;
        void releaseEntry(AnimationStatus status) {
          if (status == AnimationStatus.completed) release();
        }

        try {
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
          if (!await request.onStarting() || !context.mounted) return null;
          final route = HipRoute.push<trainer.SessionResult>(
            (_) => HipPlayerPage(store: store, plan: plan, sdkBuilder: builder),
          );
          final receipt = Navigator.of(context).push(route);
          animation = route.animation;
          animation?.addStatusListener(releaseEntry);
          if (animation?.status == AnimationStatus.completed) release();
          return await receipt;
        } finally {
          animation?.removeStatusListener(releaseEntry);
          release();
        }
      },
      onOpenAction: (context, request) => _push(
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
      onOpenSettings: (context) => _push(
        context,
        Scaffold(
          appBar: AppBar(title: const Text('设置')),
          // A pushed route is not rebuilt by the app root: follow the store
          // so switches and choices show their new state (as from 更多).
          body: ListenableBuilder(
            listenable: store,
            builder: (_, _) => HipProgressPage(
              store: store,
              section: HipProgressSection.settings,
            ),
          ),
        ),
      ),
    ),
  );
}

Future<void> _push(BuildContext context, Widget page) async {
  await Navigator.of(context).push(HipRoute.push<void>((_) => page));
}

Future<void> _pushPractice(
  BuildContext context,
  LibraryActions actions,
  int segment,
) => _push(
  context,
  Builder(
    builder: (pageContext) => Scaffold(
      appBar: AppBar(
        title: Text(segment == 2 ? '我的训练组' : '练习库'),
        actions: [
          if (segment == 2)
            TextButton(
              onPressed: () {
                Navigator.of(pageContext).pop();
                actions.coach!.requestCompose();
              },
              child: const Text('去排一套'),
            ),
        ],
      ),
      body: PracticePage(
        actions: actions,
        memory: PracticeMemory()..segment = segment,
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('计划不符合当前动作范围或训练条件，原计划已保留。')));
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
  Widget build(BuildContext context) => HipPressable(
    key: const ValueKey('practice-ai-coach'),
    semanticLabel: 'AI 定制训练',
    scale: .98,
    onTap: () => _push(context, HipCoachChatPage(actions: actions)),
    child: HipPanel(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          HipIcon(HipGlyph.bolt, color: HipColors.jadeText, filled: true),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI 定制训练',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                Text('说说想拉伸哪里，用髋部动作排一套训练'),
              ],
            ),
          ),
          HipIcon(HipGlyph.chevronRight, size: 18, color: HipColors.muted),
        ],
      ),
    ),
  );
}
