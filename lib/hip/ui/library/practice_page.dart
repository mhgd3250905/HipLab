// 练习 tab (拍板 1, 2026-10-19 13:08): big title, the 「我的髋部 · 3 分半自测」
// card (the former 自测 tab), then 动作 | 套路 | 我的.
import 'package:flutter/material.dart';

import '../../domain/hip_library.dart';
import '../../domain/hip_models.dart';
import '../hip_assessment_page.dart';
import '../hip_icons.dart';
import '../hip_routes.dart';
import '../hip_segmented.dart';
import '../hip_theme.dart';
import '../hip_widgets.dart';
import 'drill_detail_page.dart';
import 'group_editor_page.dart';
import 'lib_text.dart';
import 'library_actions.dart';
import 'library_widgets.dart';
import 'routine_detail_page.dart';

class PracticePage extends StatefulWidget {
  const PracticePage({
    super.key,
    required this.actions,
    required this.memory,
    required this.onStartAssessment,
  });
  final LibraryActions actions;
  final PracticeMemory memory;

  /// Starts the check-up straight away, growing out of [from].
  final void Function({BuildContext? from, double radius, Color? color})
  onStartAssessment;
  @override
  State<PracticePage> createState() => _PracticePageState();
}

class _PracticePageState extends State<PracticePage> {
  late final _search = TextEditingController(text: widget.memory.filter.query);
  final _cardKey = GlobalKey();
  final _checkPillKey = GlobalKey();

  PracticeMemory get mem => widget.memory;
  LibraryActions get actions => widget.actions;
  HipContent get content => actions.store.content;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: actions.store,
    builder: (context, _) => _build(context),
  );

  Widget _build(BuildContext context) {
    final t = LibText.of(context);
    final body = switch (mem.segment) {
      1 => _routines(t),
      2 => _mine(t),
      _ => _actions(t),
    };
    return ListView(
      key: const ValueKey('practice-list'),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      children: [
        Text(
          t.practice,
          style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        _checkCard(t),
        const SizedBox(height: 14),
        HipSegmented<int>(
          keyPrefix: 'practice',
          standalone: true,
          height: 46,
          radius: 16,
          inset: 4,
          values: const [0, 1, 2],
          selected: mem.segment,
          onChanged: (v) => setState(() => mem.segment = v),
          label: (v) => [t.segActions, t.segRoutines, t.segMine][v],
        ),
        const SizedBox(height: 14),
        ...body,
      ],
    );
  }

  // ── 我的髋部 · 3 分半自测 ──

  Widget _checkCard(LibText t) {
    final store = actions.store;
    final result = store.latestResult;
    final blocked = store.blocked;
    final last = store.assessments.isEmpty ? null : store.assessments.last.at;
    final pill = KeyedSubtree(
      key: _checkPillKey,
      child: RepaintBoundary(
        child: LibPill(
          key: const ValueKey('check-start'),
          label: blocked
              ? t.checkBlocked
              : result == null
              ? t.checkStart
              : t.checkRetest,
          icon: blocked ? null : HipGlyph.play,
          onTap: blocked
              ? null
              : () => widget.onStartAssessment(
                  from: _checkPillKey.currentContext,
                  radius: 17,
                  color: tintOf(HipColors.jade),
                ),
        ),
      ),
    );
    return HipPressable(
      key: const ValueKey('hip-check-card'),
      semanticLabel: '${t.myHip} · ${t.checkTitle}',
      scale: .98,
      onTap: _openIntro,
      child: RepaintBoundary(
        key: _cardKey,
        child: HipPanel(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Row(
            children: [
              SizedBox(
                width: 64,
                height: 64,
                child: result == null
                    ? Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: tintOf(HipColors.jade),
                        ),
                        alignment: Alignment.center,
                        child: HipIcon(
                          HipGlyph.radar,
                          size: 34,
                          color: HipColors.jade,
                        ),
                      )
                    : HipRadar(
                        key: const ValueKey('check-radar'),
                        values: result.radar,
                        highlight: result.tightest.toSet(),
                        warn: result.painDirections,
                        compact: true,
                        labels: false,
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.myHip,
                      maxLines: 1,
                      style: TextStyle(fontSize: 12.5, color: HipColors.muted),
                    ),
                    Text(
                      t.checkTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      result == null || last == null
                          ? t.checkUntested
                          : '${t.lastChecked(last)} · ${t.levelName(result.level.level)}',
                      key: const ValueKey('check-caption'),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, color: HipColors.muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              pill,
            ],
          ),
        ),
      ),
    );
  }

  /// The former 自测 tab body, now a page grown out of the card.
  void _openIntro() {
    Navigator.of(context).push(
      HipRoute.expandFrom<void>(
        _cardKey.currentContext,
        (_) => AssessmentIntroPage(actions: actions),
        radius: 22,
        color: HipColors.surface,
      ),
    );
  }

  // ── ① 动作大全 ──

  List<Widget> _actions(LibText t) {
    final all = libraryDrills(content);
    final shown = mem.filter.apply(content, all);
    return [
      LibSearchField(
        controller: _search,
        onChanged: (q) =>
            setState(() => mem.filter = mem.filter.copyWith(query: q)),
      ),
      const SizedBox(height: 12),
      LibFilterRow(
        filter: mem.filter,
        onDirection: (d) => setState(
          () => mem.filter = mem.filter.copyWith(
            direction: d,
            clearDirection: d == null,
          ),
        ),
        onSheet: () async {
          final f = await showFilterSheet(context, content, mem.filter);
          if (f != null && mounted) setState(() => mem.filter = f);
        },
      ),
      const SizedBox(height: 14),
      Text(
        mem.filter.isEmpty
            ? t.actionsCount(all.length)
            : t.actionsCount(shown.length),
        key: const ValueKey('actions-count'),
        style: TextStyle(fontSize: 13, color: HipColors.muted),
      ),
      const SizedBox(height: 10),
      if (shown.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Column(
            children: [
              Text(t.noMatch, style: TextStyle(color: HipColors.muted)),
              const SizedBox(height: 8),
              LibPill(
                label: t.clearFilters,
                onTap: () => setState(() {
                  _search.clear();
                  mem.filter = const LibraryFilter();
                }),
              ),
            ],
          ),
        )
      else
        LibDrillGrid(
          children: [
            for (final d in shown)
              LibDrillCard(
                key: ValueKey('drill-card-${d.id}'),
                content: content,
                drill: d,
                dose: doseText(
                  content.kit(d.id)!,
                  DoseRules.singleDefault(content.kit(d.id)!),
                  single: true,
                  lang: t.lang,
                ),
                onTap: (from) => _openDrill(d.id, from),
              ),
          ],
        ),
    ];
  }

  Future<void> _openDrill(String id, BuildContext from) async {
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
    if (jump is LibraryJump && mounted) {
      setState(() {
        _search.clear();
        mem
          ..segment = 0
          ..filter = jump.filter;
      });
    }
  }

  // ── ③ 套路 ──

  List<Widget> _routines(LibText t) {
    final rec = actions.store.profile.recommendedRoutine;
    final list = [...content.routines]
      ..sort((a, b) => (a.id == rec ? 0 : 1).compareTo(b.id == rec ? 0 : 1));
    final dancer = actions.store.identity == HipIdentity.dancer;
    return [
      Text(
        t.routinesCount(content.routines.length),
        style: TextStyle(fontSize: 13, color: HipColors.muted),
      ),
      const SizedBox(height: 10),
      for (final r in list) ...[
        _routineCard(t, r, r.id == rec, dancer),
        const SizedBox(height: 12),
      ],
    ];
  }

  Widget _routineCard(
    LibText t,
    HipRoutine r,
    bool rec,
    bool dancer,
  ) => HipPressable(
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
    child: HipPanel(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  routineShortName(r),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (rec) ...[tintTag(t.recommended), const SizedBox(width: 8)],
              Text(
                t.minutes(r.minutes),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              HipIcon(
                r.scene == HipScene.chair ? HipGlyph.chair : HipGlyph.home,
                size: 15,
                color: HipColors.muted,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${t.scene(r.scene)} · ${t.movesCount(r.steps.length)} · '
                  '${r.audience.split('；').first}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, color: HipColors.muted),
                ),
              ),
            ],
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
          const SizedBox(height: 10),
          LibThumbStrip(
            drills: [for (final s in r.steps) content.drill(s.drillId)],
          ),
        ],
      ),
    ),
  );

  // ── ⑤ 我的 ──

  List<Widget> _mine(LibText t) {
    final groups = actions.store.customRoutines;
    return [
      _newGroupCard(t),
      const SizedBox(height: 16),
      if (groups.isEmpty)
        _emptyMine(t)
      else ...[
        Text(
          t.myGroups(groups.length),
          style: TextStyle(
            fontSize: 13,
            color: HipColors.muted,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        for (final g in groups) ...[
          GroupCard(actions: actions, group: g),
          const SizedBox(height: 12),
        ],
      ],
    ];
  }

  Widget _newGroupCard(LibText t) => HipPressable(
    key: const ValueKey('new-group'),
    semanticLabel: t.newGroup,
    scale: .98,
    onTap: () => _newGroup(),
    child: HipPanel(
      padding: const EdgeInsets.all(14),
      borderColor: HipColors.jade.withValues(alpha: .55),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: tintOf(HipColors.jade),
            ),
            alignment: Alignment.center,
            child: HipIcon(
              HipGlyph.plus,
              size: 22,
              strokeWidth: 2.2,
              color: HipColors.jadeText,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.newGroup,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: HipColors.jadeText,
                  ),
                ),
                Text(
                  t.newGroupHint,
                  style: TextStyle(fontSize: 13, color: HipColors.muted),
                ),
              ],
            ),
          ),
          HipIcon(HipGlyph.chevronRight, size: 18, color: HipColors.jadeText),
        ],
      ),
    ),
  );

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

  Widget _emptyMine(LibText t) => HipPanel(
    key: const ValueKey('mine-empty'),
    padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
    child: Column(
      children: [
        HipIcon(HipGlyph.library, size: 44, color: HipColors.jade),
        const SizedBox(height: 10),
        Text(
          t.emptyTitle,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
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
        if (content.drills.containsKey(s.kitId)) content.drill(s.kitId),
    ];
    final from = g.fromRoutine == null
        ? null
        : content.routines.where((r) => r.id == g.fromRoutine).firstOrNull;
    return HipPressable(
      key: ValueKey('group-card-${g.id}'),
      semanticLabel: g.name,
      scale: .98,
      onTap: () => Navigator.of(context).push(
        HipRoute.push<void>(
          (_) => GroupEditorPage(actions: actions, initial: g),
        ),
      ),
      child: HipPanel(
        padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        g.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${t.movesCount(g.steps.length)} · ${t.duration(secs)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13, color: HipColors.muted),
                      ),
                      if (from != null)
                        Text(
                          t.fromRoutine(routineShortName(from)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: HipColors.faint,
                          ),
                        ),
                      if (g.removed > 0)
                        Text(
                          t.delisted(g.removed),
                          style: TextStyle(
                            fontSize: 12,
                            color: HipColors.tight,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                KeyedSubtree(
                  key: _startKey,
                  child: RepaintBoundary(
                    child: LibPill(
                      key: ValueKey('group-start-${g.id}'),
                      label: t.start,
                      icon: HipGlyph.play,
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
            const SizedBox(height: 10),
            LibThumbStrip(drills: drills),
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
  Widget build(BuildContext context) {
    final t = LibText.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: HipTopBar(
                icon: HipGlyph.back,
                tooltip: t.back,
                onClose: () => Navigator.of(context).maybePop(),
              ),
            ),
            Expanded(
              child: HipAssessmentIntro(
                store: widget.actions.store,
                startKey: _startKey,
                onStart: _start,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
