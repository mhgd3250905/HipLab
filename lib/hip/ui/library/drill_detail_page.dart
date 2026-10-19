// ② 动作详情: the looping clip, key point, tags, the 单练 dose and the
// safety / level notices; 「开始练」 runs a one-step plan in the player,
// 「加入训练组」 appends the drill to a custom group.
import 'package:flutter/material.dart';

import '../../domain/hip_library.dart';
import '../../domain/hip_models.dart';
import '../../domain/hip_session.dart';
import '../hip_icons.dart';
import '../hip_routes.dart';
import '../hip_theme.dart';
import '../hip_widgets.dart';
import 'group_editor_page.dart';
import 'lib_text.dart';
import 'library_actions.dart';
import 'library_widgets.dart';

/// Why 开始练 is (not) allowed and which hints show, from the same rules as
/// the routines (docs/training-library-2026-10-19.md §安全规则).
class DrillAdvice {
  const DrillAdvice({
    required this.blocked,
    required this.locked,
    required this.recentPain,
    required this.easier,
  });

  /// A safety card answered 「有」: browse only.
  final bool blocked;

  /// Direction relax-only this week (assessment pain or 7-day lock) and the
  /// drill is not a relax drill: 开始练 disabled.
  final bool locked;

  /// Pain reported in this direction in the last 7 days (not relax): hint.
  final bool recentPain;

  /// The routines would swap it for the easier version: hint only (拍板 4).
  final bool easier;

  bool get canStart => !blocked && !locked;

  static DrillAdvice of(
    HipDrill d,
    TrainingProfile p,
    TrainingPlanner planner,
    Set<HipDirection> recentPain,
  ) {
    final locked = TrainingPlanner.lockedOut(d, p);
    return DrillAdvice(
      blocked: p.blocked,
      locked: locked,
      recentPain:
          !d.isRelax && !locked && recentPain.contains(d.directions.first),
      easier: planner.needsEasier(d, p),
    );
  }
}

class DrillDetailPage extends StatefulWidget {
  const DrillDetailPage({
    super.key,
    required this.actions,
    required this.drillId,
  });
  final LibraryActions actions;
  final String drillId;
  @override
  State<DrillDetailPage> createState() => _DrillDetailPageState();
}

class _DrillDetailPageState extends State<DrillDetailPage> {
  late LibraryDose _dose;
  final _startKey = GlobalKey();

  HipContent get content => widget.actions.store.content;
  HipDrill get drill => content.drill(widget.drillId);
  ActionKit get kit => content.kit(widget.drillId)!;

  @override
  void initState() {
    super.initState();
    _dose = DoseRules.singleDefault(kit);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.actions.store,
    builder: (context, _) => _build(context),
  );

  Widget _build(BuildContext context) {
    final t = LibText.of(context);
    final store = widget.actions.store;
    final d = drill;
    final advice = DrillAdvice.of(
      d,
      store.profile,
      store.planner,
      store.recentPainDirections,
    );
    final alt = d.alternative == null ? null : content.drills[d.alternative!];
    final dir = d.directions.first;
    final notices = <Widget>[
      if (advice.blocked)
        LibNotice(
          key: const ValueKey('notice-blocked'),
          text: t.noticeBlocked,
          color: HipColors.tight,
          icon: HipGlyph.shield,
        )
      else if (advice.locked)
        LibNotice(
          key: const ValueKey('notice-locked'),
          text: t.noticeLocked(t.area(dir)),
          color: HipColors.tight,
          action: t.seeRelax,
          onAction: () => Navigator.of(context).pop(LibraryJump(dir)),
        )
      else if (advice.recentPain)
        LibNotice(
          key: const ValueKey('notice-pain'),
          text: t.noticePain,
          color: HipColors.tight,
          action: t.seeRelax,
          onAction: () => Navigator.of(context).pop(LibraryJump(dir)),
        ),
      if (advice.easier && !advice.blocked)
        LibNotice(
          key: const ValueKey('notice-advanced'),
          text: alt != null && inLibrary(content, alt.id)
              ? t.noticeAdvanced
              : t.noticeAdvancedNoAlt,
          color: HipColors.jadeText,
          action: alt != null && inLibrary(content, alt.id)
              ? t.seeDrill(drillName(content, alt, t.lang))
              : null,
          onAction: alt == null
              ? null
              : () => Navigator.of(context).pushReplacement(
                  HipRoute.push<Object?>(
                    (_) => DrillDetailPage(
                      actions: widget.actions,
                      drillId: alt.id,
                    ),
                  ),
                ),
        ),
    ];
    final point = drillPoint(content, d, t.lang);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            HipTopBar(
              icon: HipGlyph.back,
              tooltip: t.back,
              onClose: () => Navigator.of(context).maybePop(),
              subtitle:
                  '${t.area(dir)} · ${d.methods.map(t.method).join(' / ')}',
              title: drillName(content, d, t.lang),
            ),
            Expanded(
              child: ListView(
                key: const ValueKey('detail-list'),
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                children: [
                  SizedBox(
                    height: 232,
                    child: HipMediaFrame(
                      radius: 24,
                      color: HipColors.mediaBackdrop,
                      overlays: [
                        Positioned(
                          left: 12,
                          top: 12,
                          child: mediaPill(t.loopPlaying, icon: HipGlyph.loop),
                        ),
                        if (d.advanced)
                          Positioned(
                            right: 12,
                            top: 12,
                            child: mediaPill(
                              t.advanced,
                              color: HipPalette.dark.tight,
                            ),
                          ),
                      ],
                      child: HipDrillArt(
                        drill: d,
                        play: true,
                        alignment: const Alignment(0, -.1),
                      ),
                    ),
                  ),
                  for (final n in notices) ...[const SizedBox(height: 12), n],
                  const SizedBox(height: 16),
                  Text(
                    drillAltName(content, d, t.lang),
                    style: TextStyle(fontSize: 12.5, color: HipColors.faint),
                  ),
                  const SizedBox(height: 4),
                  if (point.isNotEmpty)
                    Text(
                      point,
                      style: const TextStyle(
                        fontSize: 17,
                        height: 1.45,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final x in d.directions.take(3))
                        _tag(t.area(x), HipColors.glow),
                      for (final s in d.scenes) _tag(t.scene(s), null),
                      _tag(d.advanced ? t.advancedLevel : t.starter, null),
                      if (d.cautions.isNotEmpty)
                        _tag(
                          '${t.cautions}：${d.cautions.join('、')}',
                          HipColors.pain,
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  LibDosePanel(
                    kit: kit,
                    dose: _dose,
                    single: true,
                    onChanged: (v) => setState(() => _dose = v),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    t.singleNoStreak,
                    style: TextStyle(fontSize: 12, color: HipColors.faint),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: LibFooter(
        children: [
          Expanded(
            flex: 2,
            child: HipSecondaryButton(
              key: const ValueKey('detail-add'),
              label: t.addToGroup,
              onPressed: () => _addToGroup(context),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: KeyedSubtree(
              key: _startKey,
              child: RepaintBoundary(
                child: HipPrimaryButton(
                  key: const ValueKey('detail-start'),
                  label: advice.blocked
                      ? t.askDoctorFirst
                      : advice.locked
                      ? t.relaxOnlyThisWeek
                      : t.startPractice,
                  icon: advice.canStart ? HipGlyph.play : null,
                  onPressed: advice.canStart ? _start : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tag(String text, Color? dot) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: HipColors.surfaceHigh,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (dot != null) ...[
          CircleAvatar(radius: 3.5, backgroundColor: dot),
          const SizedBox(width: 6),
        ],
        Text(text, style: TextStyle(fontSize: 13, color: HipColors.text)),
      ],
    ),
  );

  void _start() {
    final store = widget.actions.store;
    final plan = store.planner.singlePlan(drill, _dose, store.profile);
    if (plan == null) return;
    widget.actions.startPlan(
      plan,
      from: _startKey.currentContext,
      radius: 28,
      originColor: HipColors.jade,
    );
  }

  Future<void> _addToGroup(BuildContext context) async {
    final t = LibText.of(context);
    final store = widget.actions.store;
    final step = CustomStep(widget.drillId);
    final picked = await showLibSheet<String>(
      context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          sheetTitle(t.addToWhich),
          const SizedBox(height: 12),
          _groupRow(
            context,
            key: const ValueKey('add-new-group'),
            icon: HipGlyph.plus,
            title: t.newGroup,
            subtitle: t.newGroupHint,
            onTap: () => Navigator.of(context).pop(''),
          ),
          for (final g in store.customRoutines) ...[
            const SizedBox(height: 8),
            _groupRow(
              context,
              key: ValueKey('add-to-${g.id}'),
              icon: HipGlyph.library,
              title: g.name,
              subtitle: g.steps.length >= CustomRoutine.maxSteps
                  ? t.groupFull
                  : '${t.movesCount(g.steps.length)} · '
                        '${t.duration(g.seconds(content))}',
              onTap: g.steps.length >= CustomRoutine.maxSteps
                  ? null
                  : () => Navigator.of(context).pop(g.id),
            ),
          ],
        ],
      ),
    );
    if (picked == null || !mounted) return;
    if (picked.isEmpty) {
      await Navigator.of(this.context).push(
        HipRoute.rise<void>(
          (_) => GroupEditorPage(
            actions: widget.actions,
            initial: CustomRoutine(
              id: store.newCustomId(),
              name: store.nextCustomName(),
              steps: [step],
            ),
            isNew: true,
          ),
        ),
      );
      return;
    }
    final g = store.customRoutine(picked);
    if (g == null) return;
    await store.saveCustomRoutine(g.copyWith(steps: [...g.steps, step]));
    if (!mounted) return;
    ScaffoldMessenger.of(this.context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(t.addedTo(g.name))));
  }

  Widget _groupRow(
    BuildContext context, {
    required Key key,
    required HipGlyph icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
  }) => HipPressable(
    key: key,
    semanticLabel: title,
    onTap: onTap,
    scale: .98,
    child: Opacity(
      opacity: onTap == null ? .5 : 1,
      child: HipPanel(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        radius: 18,
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: tintOf(HipColors.jade),
              ),
              child: HipIcon(icon, size: 20, color: HipColors.jadeText),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: HipColors.muted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
