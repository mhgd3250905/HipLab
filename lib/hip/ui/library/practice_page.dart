// 「训练组」 (UI r2 M2, 2026-11-03): HipNavBar 训练组, segments 我的 / 推荐套路
// (我的 default). 我的: 新建训练组 + AI 定制 as flat rows, then the groups.
// The 自测 card and the 动作 tab left (更多 has 髋部自测 and 动作库).
// [PracticePage.library] is the 动作库 entry: the moves view only (the SDK
// library under the HipLab bar until M3 replaces it).
import 'package:flutter/material.dart';
import '../../data/hip_shared_library.dart';

import '../../domain/hip_library.dart';
import '../../domain/hip_models.dart';
import '../coach/hip_coach_chat_page.dart';
import '../hip_assessment_page.dart';
import '../hip_icons.dart';
import '../hip_page_kit.dart';
import '../hip_routes.dart';
import '../hip_segmented.dart';
import '../hip_theme.dart';
import '../hip_widgets.dart';
import 'drill_detail_page.dart';
import 'group_editor_page.dart';
import 'lib_text.dart';
import 'action_filter.dart';
import 'library_actions.dart';
import 'library_widgets.dart';
import 'routine_detail_page.dart';

/// Flat card of the r2 kit: the [HipListGroup] panel colour, radius 12, no
/// border, no shadow.
Widget hipFlatCard({
  Key? key,
  required Widget child,
  EdgeInsets padding = const EdgeInsets.fromLTRB(16, 14, 14, 14),
}) => Container(
  key: key,
  padding: padding,
  decoration: BoxDecoration(
    color: HipListGroup.fill(),
    borderRadius: BorderRadius.circular(12),
  ),
  child: child,
);

class PracticePage extends StatefulWidget {
  const PracticePage({
    super.key,
    required this.actions,
    required this.memory,
    required this.onStartAssessment,
    this.library = false,
    this.trailing,
  });
  final LibraryActions actions;
  final PracticeMemory memory;

  /// The 动作库 entry instead of 训练组.
  final bool library;

  /// One action on the right of the bar (coach: 去排一套).
  final Widget? trailing;

  /// Starts the check-up (kept for the callers; the page no longer has the
  /// 自测 card).
  final void Function({BuildContext? from, double radius, Color? color})
  onStartAssessment;
  @override
  State<PracticePage> createState() => _PracticePageState();
}

class _PracticePageState extends State<PracticePage> {
  late final _search = TextEditingController(text: widget.memory.filter.query);

  PracticeMemory get mem => widget.memory;
  LibraryActions get actions => widget.actions;
  HipContent get content => actions.store.content;

  /// 训练组 segment: 2 我的 (default) or 1 推荐套路.
  int get _segment => mem.segment == 1 ? 1 : 2;

  @override
  void dispose() {
    _search.dispose();
    _actionSearch.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = LibText.of(context);
    return HipNavPage(
      title: widget.library ? t.libraryTitle : t.groupsTitle,
      leadingKey: const ValueKey('practice-back'),
      trailing: widget.trailing,
      body: ListenableBuilder(
        listenable: actions.store,
        builder: (context, _) => _build(context),
      ),
    );
  }

  Widget _build(BuildContext context) {
    final t = LibText.of(context);
    if (widget.library) {
      // UI r2 M3: HipLab's own 动作库 over the SDK-scoped actions.
      return _library(t);
    }
    final seg = _segment;
    return ListView(
      key: const ValueKey('practice-list'),
      padding: const EdgeInsets.fromLTRB(kHipPageEdge, 4, kHipPageEdge, 24),
      children: [
        HipSegmented<int>(
          keyPrefix: 'practice',
          standalone: true,
          height: 34,
          radius: 9,
          inset: 3,
          values: const [2, 1],
          selected: seg,
          onChanged: (v) => setState(() => mem.segment = v),
          label: (v) => v == 2 ? t.segMine : t.segRecommended,
        ),
        const SizedBox(height: 16),
        ...(seg == 1 ? _routines(t) : _mine(t)),
      ],
    );
  }

  // ── ① 动作库 (UI r2 M3) ──

  late final _actionSearch = TextEditingController(text: mem.actions.query);

  Widget _library(LibText t) {
    final all = hipActionItems(content, t);
    final f = mem.actions;
    final shown = f.apply(all);
    return ListView(
      key: const ValueKey('practice-list'),
      padding: const EdgeInsets.fromLTRB(kHipPageEdge, 4, kHipPageEdge, 24),
      children: [
        ActionFilterBar(
          all: all,
          filter: f,
          search: _actionSearch,
          onChanged: (v) => setState(() => mem.actions = v),
        ),
        const SizedBox(height: 14),
        Text(
          t.lang == 'en' ? '${shown.length} moves' : '${shown.length} 个动作',
          key: const ValueKey('actions-count'),
          style: TextStyle(fontSize: 13, color: HipColors.muted),
        ),
        const SizedBox(height: 10),
        if (shown.isEmpty)
          ActionEmpty(
            onReset: () => setState(() {
              _actionSearch.clear();
              mem.actions = const ActionFilter();
            }),
          )
        else
          LibDrillGrid(
            children: [
              for (final a in shown)
                ActionCard(
                  key: ValueKey('drill-card-${a.id}'),
                  item: a,
                  onTap: (from) => _openDrill(a.id, from),
                ),
            ],
          ),
      ],
    );
  }

  Future<void> _openDrill(String id, BuildContext from) async {
    if (HipSharedLibrary.current != null) {
      await HipSharedLibrary.openDetail(context, actions, id);
      return;
    }
    if (content.drills[id] == null) return;
    final jump = await Navigator.of(context).push<Object?>(
      HipRoute.expandFrom<Object?>(
        from,
        (_) => DrillDetailPage(actions: actions, drillId: id),
        radius: 20,
        color: HipColors.surface,
      ),
    );
    _applyJump(jump);
  }

  /// A detail page (or a routine's move) answered 看放松: 动作大全 filtered
  /// to that direction's relax moves.
  void _applyJump(Object? jump) {
    if (jump is! LibraryJump || !mounted) return;
    if (widget.library) {
      setState(() {
        _actionSearch.clear();
        mem.actions = jump.actionFilter;
      });
      return;
    }
    // 训练组 has no moves view: open 动作库 filtered.
    Navigator.of(context).push(
      HipRoute.push<void>(
        (_) => PracticePage(
          actions: actions,
          library: true,
          memory: PracticeMemory()
            ..filter = jump.filter
            ..actions = jump.actionFilter,
          onStartAssessment: widget.onStartAssessment,
        ),
      ),
    );
  }

  // ── ③ 套路 ──

  List<Widget> _routines(LibText t) {
    final rec = actions.store.profile.recommendedRoutine;
    final list = [...content.routines]
      ..sort((a, b) => (a.id == rec ? 0 : 1).compareTo(b.id == rec ? 0 : 1));
    final dancer = actions.store.identity == HipIdentity.dancer;
    return [
      HipSection(t.routinesCount(content.routines.length), first: true),
      for (final r in list) ...[
        _routineCard(t, r, r.id == rec, dancer),
        const SizedBox(height: 8),
      ],
    ];
  }

  Widget _routineCard(LibText t, HipRoutine r, bool rec, bool dancer) {
    final nameStyle = TextStyle(
      fontSize: 16,
      height: 1.25,
      fontWeight: FontWeight.w600,
      color: HipColors.text,
    );
    final minutes = Text(
      t.minutes(r.minutes),
      style: TextStyle(fontSize: 14, color: HipColors.faint),
    );
    return HipPressable(
      key: ValueKey('routine-card-${r.id}'),
      semanticLabel: routineShortName(r),
      scale: .98,
      onTap: () async => _applyJump(
        await Navigator.of(context).push<Object?>(
          HipRoute.push<Object?>(
            (_) => RoutineDetailPage(actions: actions, routineId: r.id),
          ),
        ),
      ),
      child: hipFlatCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Very large text: name on its own line, tag + minutes under it
            // (side by side the name was squeezed to one character a line).
            if (libLargeText(context)) ...[
              Text(routineShortName(r), style: nameStyle),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [if (rec) tintTag(t.recommended), minutes],
              ),
            ] else
              Row(
                children: [
                  Expanded(child: Text(routineShortName(r), style: nameStyle)),
                  if (rec) ...[
                    tintTag(t.recommended),
                    const SizedBox(width: 8),
                  ],
                  minutes,
                ],
              ),
            const SizedBox(height: 4),
            Text(
              '${t.scene(r.scene)} · ${t.movesCount(r.steps.length)} · '
              '${r.audience.split('；').first}',
              style: TextStyle(
                fontSize: 13,
                height: 1.3,
                color: HipColors.muted,
              ),
            ),
            if (r.id == 'F' && !dancer) ...[
              const SizedBox(height: 6),
              Text(
                t.dancerNote,
                style: TextStyle(
                  fontSize: 12.5,
                  color: HipColors.tight,
                  height: 1.35,
                ),
              ),
            ],
            const SizedBox(height: 12),
            LibThumbStrip(
              size: 32,
              gap: 8,
              drills: [for (final s in r.steps) content.drill(s.drillId)],
            ),
          ],
        ),
      ),
    );
  }

  // ── ⑤ 我的 ──

  List<Widget> _mine(LibText t) {
    final groups = actions.store.customRoutines;
    return [
      HipListGroup(
        children: [
          HipListRow(
            key: const ValueKey('new-group'),
            glyph: HipGlyph.plus,
            title: t.newGroup,
            subtitle: t.newGroupHint,
            onTap: _newGroup,
          ),
          // AI 定制 (docs/ai-coach.md): the app's only AI entry, zh UI only.
          if (actions.coach != null &&
              aiCoachAvailable(context, configured: actions.coach!.configured))
            HipCoachChatEntryCard(actions: actions),
        ],
      ),
      if (groups.isEmpty) ...[
        const SizedBox(height: 24),
        _emptyMine(t),
      ] else ...[
        HipSection(t.myGroups(groups.length)),
        for (final g in groups) ...[
          GroupCard(actions: actions, group: g),
          const SizedBox(height: 8),
        ],
      ],
    ];
  }

  Future<void> _newGroup() async {
    final store = actions.store;
    final draft = CustomRoutine(
      id: store.newCustomId(),
      name: store.nextCustomName(),
      steps: const [],
    );
    // 新建 goes straight to picking moves, then the editor.
    final ids = await Navigator.of(context).push<List<String>>(
      HipRoute.push(
        (_) => DrillPickerPage(
          actions: actions,
          groupName: draft.name,
          existing: const [],
        ),
      ),
    );
    if (ids == null || ids.isEmpty || !mounted) return;
    await Navigator.of(context).push(
      HipRoute.push<void>(
        (_) => GroupEditorPage(
          actions: actions,
          initial: draft.copyWith(
            steps: [
              for (final id in ids.take(CustomRoutine.maxSteps)) CustomStep(id),
            ],
          ),
          isNew: true,
        ),
      ),
    );
  }

  Widget _emptyMine(LibText t) => hipFlatCard(
    key: const ValueKey('mine-empty'),
    padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
    child: Column(
      children: [
        HipIcon(HipGlyph.library, size: 32, color: HipColors.jade),
        const SizedBox(height: 10),
        Text(
          t.emptyTitle,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          t.emptyBody,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, height: 1.4, color: HipColors.muted),
        ),
        const SizedBox(height: 14),
        LibPill(
          key: const ValueKey('mine-copy-routine'),
          label: t.copyFromRoutine,
          onTap: () => setState(() => mem.segment = 1),
        ),
      ],
    ),
  );
}

/// A custom group: name, moves · time, 「改自套路」, thumbnails; the tinted
/// 「▶ 开始」 pill plays it, the rest of the card opens the editor.
class GroupCard extends StatelessWidget {
  GroupCard({super.key, required this.actions, required this.group});
  final LibraryActions actions;
  final CustomRoutine group;
  final _startKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final t = LibText.of(context);
    final store = actions.store;
    final content = store.content;
    final g = group;
    final secs = g.seconds(content);
    final drills = [
      for (final s in g.steps)
        ?(g.coachPlan != null
            ? hipSdkDrill(content, s.kitId)
            : content.drills[s.kitId]),
    ];
    final large = libLargeText(context);
    final from = g.fromRoutine == null
        ? null
        : content.routines.where((r) => r.id == g.fromRoutine).firstOrNull;
    return HipPressable(
      key: ValueKey('group-card-${g.id}'),
      semanticLabel: g.name,
      scale: .98,
      onTap: () => g.coachPlan != null && actions.coach != null
          ? openHipSavedCoachPlan(context, actions, g)
          : Navigator.of(context).push(
              HipRoute.push<void>(
                (_) => GroupEditorPage(actions: actions, initial: g),
              ),
            ),
      child: hipFlatCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Very large text: 开始 goes under the texts instead of
            // squeezing them (PR #22 P3).
            Flex(
              direction: large ? Axis.vertical : Axis.horizontal,
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(
                  flex: large ? 0 : 1,
                  fit: FlexFit.tight,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        g.name,
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.25,
                          fontWeight: FontWeight.w600,
                          color: HipColors.text,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${t.movesCount(g.steps.length)} · ${t.duration(secs)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.3,
                          color: HipColors.muted,
                        ),
                      ),
                      if (from != null)
                        Text(
                          t.fromRoutine(routineShortName(from)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.3,
                            color: HipColors.faint,
                          ),
                        ),
                      if (g.removed > 0)
                        Text(
                          t.delisted(g.removed),
                          style: TextStyle(
                            fontSize: 13,
                            color: HipColors.tight,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8, height: 10),
                KeyedSubtree(
                  key: _startKey,
                  child: RepaintBoundary(
                    child: LibPill(
                      key: ValueKey('group-start-${g.id}'),
                      label: t.start,
                      icon: HipGlyph.play,
                      height: 32,
                      radius: 8,
                      onTap: store.blocked || g.steps.isEmpty
                          ? null
                          : () => startGroup(
                              context,
                              actions,
                              g,
                              from: _startKey.currentContext,
                            ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LibThumbStrip(drills: drills, size: 32, gap: 8),
          ],
        ),
      ),
    );
  }
}

/// Starts a custom group: relax-only directions are skipped (a one-line
/// confirmation says which and how many); nothing left → explain instead.
Future<void> startGroup(
  BuildContext context,
  LibraryActions actions,
  CustomRoutine g, {
  BuildContext? from,
}) async {
  if (g.coachPlan != null && actions.coach != null) {
    await startHipSavedCoachPlan(context, actions, g);
    return;
  }
  final t = LibText.of(context);
  final store = actions.store;
  final profile = store.profile;
  final plan = store.planner.customPlan(g, profile);
  if (plan == null) return;
  final skipped = store.planner.customSkipped(g, profile);
  if (plan.steps.isEmpty || skipped.isNotEmpty) {
    final areas = {
      for (final s in skipped)
        if (store.content.drills.containsKey(s.kitId))
          t.area(store.content.drill(s.kitId).directions.first),
    }.join('、');
    final go = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(
          plan.steps.isEmpty
              ? t.allRelaxOnly
              : t.lockedSkipped(areas, skipped.length),
          key: const ValueKey('group-skip-note'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(t.cancel),
          ),
          if (plan.steps.isNotEmpty)
            TextButton(
              key: const ValueKey('group-start-anyway'),
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(t.startAnyway),
            ),
        ],
      ),
    );
    if (go != true) return;
  }
  if (!context.mounted) return;
  final origin = from != null && from.mounted ? from : null;
  await actions.startPlan(
    plan,
    from: origin,
    radius: 17,
    originColor: tintOf(HipColors.jade),
  );
}

// ───────────────────────── 自测介绍页 ─────────────────────────

/// HipAssessmentIntro (the former 自测 tab) as a page: back button on top,
/// 开始自测 grows the check-up out of itself as before.
class AssessmentIntroPage extends StatefulWidget {
  const AssessmentIntroPage({super.key, required this.actions});
  final LibraryActions actions;
  @override
  State<AssessmentIntroPage> createState() => _AssessmentIntroPageState();
}

class _AssessmentIntroPageState extends State<AssessmentIntroPage> {
  final _startKey = GlobalKey();
  bool _left = false;

  Future<void> _start() async {
    final store = widget.actions.store;
    final before = store.assessments.length;
    final nav = Navigator.of(context);
    _left = false;
    await nav.push(
      HipRoute.expandFrom<void>(
        _startKey.currentContext,
        (_) => HipAssessmentPage(
          store: store,
          // 开始训练 from the result: leave the intro first so the player
          // closes back onto 练习.
          onStartPlan: (plan) async {
            _left = true;
            if (mounted) nav.pop();
            await widget.actions.startPlan(plan);
          },
        ),
        color: HipColors.jade,
      ),
    );
    // A finished check-up returns to 练习, where the card shows the result.
    if (mounted && !_left && store.assessments.length > before) {
      nav.maybePop();
    }
  }

  @override
  Widget build(BuildContext context) => HipNavPage(
    title: '髋部自测',
    leadingKey: const ValueKey('intro-back'),
    body: HipAssessmentIntro(
      store: widget.actions.store,
      startKey: _startKey,
      onStart: _start,
    ),
  );
}
