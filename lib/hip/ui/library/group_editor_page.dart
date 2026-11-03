// ⑥ 训练组编辑器 + ⑦ 挑选模式. Name (12 字), rest between drills
// (segmented, 10/15/20/30 s), steps: drag to reorder, swipe left to delete,
// tap for the dose sheet. 添加动作 opens the picker over 动作大全.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/hip_library.dart';
import '../../domain/hip_models.dart';
import '../../domain/hip_session.dart';
import '../hip_icons.dart';
import '../hip_page_kit.dart';
import '../hip_routes.dart';
import '../hip_segmented.dart';
import '../hip_theme.dart';
import '../hip_widgets.dart';
import 'action_filter.dart';
import 'lib_text.dart';
import 'library_actions.dart';
import 'library_widgets.dart';

class GroupEditorPage extends StatefulWidget {
  const GroupEditorPage({
    super.key,
    required this.actions,
    required this.initial,
    this.isNew = false,
  });
  final LibraryActions actions;
  final CustomRoutine initial;
  final bool isNew;
  @override
  State<GroupEditorPage> createState() => _GroupEditorPageState();
}

class _GroupEditorPageState extends State<GroupEditorPage> {
  late final TextEditingController _name = TextEditingController(
    text: widget.initial.name,
  );
  late int _rest = widget.initial.restSeconds;
  late final FocusNode _nameFocus = FocusNode()
    ..addListener(() => setState(() {}));
  bool get _nameFocused => _nameFocus.hasFocus;

  /// Steps with a stable key each (reorder / dismiss).
  late final List<(int, CustomStep)> _steps = [
    for (final s in widget.initial.steps) (_nextKey++, s),
  ];
  static int _nextKey = 0;

  /// Keys whose swipe-left delete is committed (confirmDismiss) while the
  /// row still runs its resize animation; onDismissed drops them from
  /// [_steps] ~300 ms later. Until then they are already gone for saving,
  /// leaving, the step count and every check (PR #22 F9).
  final Set<int> _deleting = {};

  /// Rows being swiped right now (finger down, or sliding out / snapping
  /// back after it lifted), key → progress. A released swipe past the
  /// threshold commits only once its slide ends, so save / close wait for
  /// these to resolve first.
  final Map<int, double> _swiping = {};
  Completer<void>? _swipesSettled;

  /// One save / close at a time (a second tap while waiting is ignored).
  bool _busy = false;

  HipContent get content => widget.actions.store.content;

  /// The steps as they stand for the user: committed deletes left out.
  List<(int, CustomStep)> get _live => [
    for (final e in _steps)
      if (!_deleting.contains(e.$1)) e,
  ];

  CustomRoutine get _current => widget.initial.copyWith(
    name: _name.text,
    restSeconds: _rest,
    steps: [for (final (_, s) in _live) s],
  );

  void _onSwipe(int key, double progress) {
    if (_deleting.contains(key)) return;
    if (progress > 0) {
      _swiping[key] = progress;
    } else {
      _swiping.remove(key);
    }
    _checkSwipesSettled();
  }

  /// The swipe on [key] has committed: it counts as deleted from now on.
  Future<bool> _commitDelete(int key) async {
    setState(() {
      _deleting.add(key);
      _swiping.remove(key);
    });
    _checkSwipesSettled();
    return true;
  }

  void _finishDelete(int key) {
    setState(() {
      _steps.removeWhere((e) => e.$1 == key);
      _deleting.remove(key);
      _swiping.remove(key);
    });
    _checkSwipesSettled();
  }

  void _checkSwipesSettled() {
    if (_swiping.isNotEmpty) return;
    final c = _swipesSettled;
    _swipesSettled = null;
    if (c != null && !c.isCompleted) c.complete();
  }

  /// Waits until no row is mid-swipe: each one has either committed its
  /// delete or snapped back (a slide is ≤ 200 ms). A finger still holding
  /// a row past the cap leaves that row in.
  Future<void> _settleSwipes() async {
    if (_swiping.isEmpty) return;
    final c = _swipesSettled ??= Completer<void>();
    await c.future.timeout(const Duration(milliseconds: 800), onTimeout: () {});
  }

  bool get _dirty {
    final c = _current;
    final i = widget.initial;
    if (widget.isNew) return true;
    if (c.name.trim() != i.name || c.restSeconds != i.restSeconds) return true;
    if (c.steps.length != i.steps.length) return true;
    for (var k = 0; k < c.steps.length; k++) {
      if (c.steps[k] != i.steps[k]) return true;
    }
    return false;
  }

  @override
  void dispose() {
    _name.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  Future<void> _close() async {
    if (_busy) return;
    _busy = true;
    try {
      await _settleSwipes();
      if (mounted) await _closeNow();
    } finally {
      _busy = false;
    }
  }

  Future<void> _closeNow() async {
    if (!_dirty) {
      Navigator.of(context).pop();
      return;
    }
    final t = LibText.of(context);
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.discardTitle),
        actions: [
          TextButton(
            key: const ValueKey('editor-keep'),
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(t.keepEditing),
          ),
          TextButton(
            key: const ValueKey('editor-discard'),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(t.discard),
          ),
        ],
      ),
    );
    if (leave == true && mounted) Navigator.of(context).pop();
  }

  Future<void> _save() async {
    if (_busy) return;
    _busy = true;
    try {
      // A delete the user just swiped must be in what is saved, even while
      // its animation runs (PR #22 F9): never save the old list.
      await _settleSwipes();
      if (!mounted || _live.isEmpty) return;
      await widget.actions.store.saveCustomRoutine(_current);
      if (mounted) Navigator.of(context).pop();
    } finally {
      _busy = false;
    }
  }

  Future<void> _delete() async {
    final t = LibText.of(context);
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.deleteGroup),
        content: Text(t.deleteGroupBody(widget.initial.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(t.cancel),
          ),
          TextButton(
            key: const ValueKey('editor-delete-confirm'),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(t.delete, style: TextStyle(color: HipColors.pain)),
          ),
        ],
      ),
    );
    if (yes != true) return;
    await widget.actions.store.deleteCustomRoutine(widget.initial.id);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _addMoves() async {
    final ids = await Navigator.of(context).push<List<String>>(
      HipRoute.push(
        (_) => DrillPickerPage(
          actions: widget.actions,
          groupName: _name.text.trim().isEmpty
              ? widget.initial.name
              : _name.text.trim(),
          existing: [for (final (_, s) in _live) s.kitId],
        ),
      ),
    );
    if (ids == null || ids.isEmpty || !mounted) return;
    setState(() {
      var n = _live.length;
      for (final id in ids) {
        if (n >= CustomRoutine.maxSteps) break;
        _steps.add((_nextKey++, CustomStep(id)));
        n++;
      }
    });
  }

  /// Index of the step with stable [key] now, or -1 once it is gone.
  /// Indexes shift while the sheet is up (a swipe-left delete finishing
  /// under it, PR #22 F8), so never hold one across an await.
  int _indexOf(int key) => _steps.indexWhere((e) => e.$1 == key);

  Future<void> _editDose(int key) async {
    final t = LibText.of(context);
    final at = _indexOf(key);
    if (at < 0 || _deleting.contains(key)) return;
    final step = _steps[at].$2;
    if (isSdkGroupStep(content, step.kitId)) return _showSdkDose(step);
    final kit = content.kit(step.kitId)!;
    var dose = step.dose(kit);
    final result = await showLibSheet<LibraryDose>(
      context,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheet) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            sheetTitle(
              drillName(content, content.drill(step.kitId), t.lang),
              trailing: HipPressable(
                key: const ValueKey('dose-reset'),
                semanticLabel: t.resetDose,
                onTap: () => setSheet(() => dose = DoseRules.kitDefault(kit)),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Text(
                    t.resetDose,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: HipColors.jadeText,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            LibDosePanel(
              kit: kit,
              dose: dose,
              single: false,
              onChanged: (v) => setSheet(() => dose = v),
            ),
            const SizedBox(height: 14),
            HipPrimaryButton(
              key: const ValueKey('dose-done'),
              label: t.done,
              onPressed: () => Navigator.of(context).pop(dose),
            ),
          ],
        ),
      ),
    );
    if (result == null || !mounted) return;
    // Re-find the step by key: it may have moved or been deleted meanwhile.
    final now = _indexOf(key);
    if (now < 0 || _deleting.contains(key)) return;
    setState(() => _steps[now] = (key, CustomStep.fromDose(kit, result)));
  }

  /// SDK actions (M6) train at the SDK library's default dose; shown
  /// read-only.
  Future<void> _showSdkDose(CustomStep step) async {
    final t = LibText.of(context);
    final d = hipSdkDrill(content, step.kitId);
    if (d == null) return;
    await showLibSheet<void>(
      context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          sheetTitle(drillName(content, d, t.lang)),
          const SizedBox(height: 12),
          Text(
            sdkStepDoseText(content, step, lang: t.lang),
            key: const ValueKey('sdk-dose'),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            t.lang == 'en'
                ? 'Library moves use their default dose in a group.'
                : '动作库动作在训练组里按默认剂量练，暂不支持调整',
            style: TextStyle(fontSize: 13, color: HipColors.muted),
          ),
          const SizedBox(height: 14),
          HipPrimaryButton(
            key: const ValueKey('dose-done'),
            label: t.done,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = LibText.of(context);
    final store = widget.actions.store;
    final secs = _current.seconds(content);
    final profile = store.profile;
    final count = _live.length;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close();
      },
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              HipNavBar(
                leading: HipNavLeading.close,
                leadingKey: const ValueKey('editor-close'),
                onLeading: _close,
                title: t.editGroup,
                trailing: widget.isNew
                    ? null
                    : Tooltip(
                        message: t.deleteGroup,
                        child: HipNavButton(
                          key: const ValueKey('editor-delete'),
                          glyph: HipGlyph.trash,
                          semanticLabel: t.deleteGroup,
                          onTap: _delete,
                        ),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // UI r2 §2: flat filled field, no outline; focus only
                    // lifts the fill a touch (the caret is jade).
                    AnimatedContainer(
                      duration: HipMotion.fast,
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: _nameFocused
                            ? HipColors.text.withValues(alpha: .10)
                            : HipColors.text.withValues(alpha: .06),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Text(
                            t.name,
                            style: TextStyle(
                              fontSize: 13,
                              color: HipColors.muted,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              key: const ValueKey('editor-name'),
                              controller: _name,
                              focusNode: _nameFocus,
                              cursorColor: HipColors.jade,
                              onChanged: (_) => setState(() {}),
                              inputFormatters: [
                                LengthLimitingTextInputFormatter(
                                  CustomRoutine.maxName,
                                ),
                              ],
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: HipColors.text,
                              ),
                              decoration: const InputDecoration(
                                isCollapsed: true,
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                          Text(
                            '${_name.text.runes.length}/${CustomRoutine.maxName}',
                            style: TextStyle(
                              fontSize: 12,
                              color: HipColors.meta,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Text(
                          t.restBetween,
                          style: TextStyle(
                            fontSize: 14,
                            color: HipColors.muted,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: HipSegmented<int>(
                            keyPrefix: 'rest',
                            standalone: true,
                            height: 34,
                            radius: 9,
                            inset: 3,
                            values: CustomRoutine.rests,
                            selected: _rest,
                            onChanged: (v) => setState(() => _rest = v),
                            label: t.restValue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Text(
                          t.stepsCount(count),
                          style: TextStyle(
                            fontSize: 13,
                            color: HipColors.muted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            t.reorderHint,
                            textAlign: TextAlign.end,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: HipColors.meta,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
              Expanded(
                child: _steps.isEmpty
                    ? Center(
                        child: Text(
                          t.emptySteps,
                          style: TextStyle(color: HipColors.muted),
                        ),
                      )
                    : ReorderableListView.builder(
                        key: const ValueKey('editor-steps'),
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                        buildDefaultDragHandles: false,
                        itemCount: _steps.length,
                        footer: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            t.rowHint,
                            style: TextStyle(
                              fontSize: 12,
                              color: HipColors.meta,
                            ),
                          ),
                        ),
                        onReorderItem: (from, to) => setState(
                          () => _steps.insert(to, _steps.removeAt(from)),
                        ),
                        itemBuilder: (context, i) {
                          final (key, s) = _steps[i];
                          // One grouped panel (audit r3 07-1): rounded ends,
                          // inset hairlines between rows, no per-row border.
                          final last = i == _steps.length - 1;
                          final r = _segmentRadius(i, _steps.length);
                          return Column(
                            key: ValueKey('step-$key'),
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Dismissible(
                                key: ValueKey('dismiss-$key'),
                                direction: DismissDirection.endToStart,
                                background: _deleteBackground(t, r),
                                onUpdate: (d) => _onSwipe(key, d.progress),
                                confirmDismiss: (_) => _commitDelete(key),
                                onDismissed: (_) => _finishDelete(key),
                                child: ClipRRect(
                                  borderRadius: r,
                                  child: ColoredBox(
                                    color: HipListGroup.fill(),
                                    child: _row(i, key, s, profile),
                                  ),
                                ),
                              ),
                              if (!last)
                                ColoredBox(
                                  color: HipListGroup.fill(),
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                      left: 4 + 30 + 48 + 12,
                                    ),
                                    child: Divider(
                                      height: .5,
                                      thickness: .5,
                                      color: HipColors.text.withValues(
                                        alpha: .1,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: LibFooter(
          above: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Text(
                  t.total,
                  style: TextStyle(fontSize: 14, color: HipColors.muted),
                ),
                const SizedBox(width: 8),
                Text(
                  t.duration(secs),
                  key: const ValueKey('editor-total'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    t.summary(count, _rest),
                    textAlign: TextAlign.end,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: HipColors.muted),
                  ),
                ),
              ],
            ),
          ),
          children: [
            Expanded(
              flex: 2,
              child: HipSecondaryButton(
                key: const ValueKey('editor-add'),
                label: t.addMoves,
                onPressed: count >= CustomRoutine.maxSteps ? null : _addMoves,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: HipPrimaryButton(
                key: const ValueKey('editor-save'),
                label: t.save,
                onPressed: count == 0 ? null : _save,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static BorderRadius _segmentRadius(int i, int n) {
    const c = Radius.circular(HipRadius.panel);
    return BorderRadius.vertical(
      top: i == 0 ? c : Radius.zero,
      bottom: i == n - 1 ? c : Radius.zero,
    );
  }

  Widget _deleteBackground(LibText t, BorderRadius r) => Container(
    decoration: BoxDecoration(
      color: HipColors.pain,
      borderRadius: r,
    ),
    alignment: Alignment.centerRight,
    padding: const EdgeInsets.only(right: 18),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const HipIcon(HipGlyph.trash, size: 20, color: Colors.white),
        const SizedBox(height: 2),
        Text(
          t.delete,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );

  Widget _row(int i, int key, CustomStep s, TrainingProfile profile) {
    final t = LibText.of(context);
    final sdk = isSdkGroupStep(content, s.kitId);
    final k = sdk ? null : content.kit(s.kitId)!;
    final d = sdk ? hipSdkDrill(content, s.kitId)! : content.drill(s.kitId);
    final dose = k == null ? null : s.dose(k);
    final relaxOnly = TrainingPlanner.lockedOut(d, profile);
    final doseLine = k == null
        ? sdkStepDoseText(content, s, lang: t.lang)
        : doseText(k, dose!, single: false, lang: t.lang);
    return HipDrillRow(
      key: ValueKey('editor-row-$i'),
      semanticLabel: drillName(content, d, t.lang),
      onTap: () => _editDose(key),
      leading: ReorderableDragStartListener(
        index: i,
        child: SizedBox(
          width: 30,
          height: 52,
          child: Center(
            child: HipIcon(HipGlyph.grip, size: 18, color: HipColors.faint),
          ),
        ),
      ),
      titlePrefix: relaxOnly
          ? Tooltip(
              message: t.relaxDot,
              child: CircleAvatar(
                radius: 3.5,
                backgroundColor: HipColors.tight,
              ),
            )
          : null,
      thumb: HipDrillArt(drill: d, showPendingLabel: false),
      title: drillName(content, d, t.lang),
      subtitle: s.adjusted ? '$doseLine · ${t.adjusted}' : doseLine,
      subtitleColor: s.adjusted ? HipColors.jadeText : null,
      meta: clockText(
        k == null
            ? sdkStepSeconds(content, s)
            : DoseRules.stepSeconds(k, dose!, single: false),
      ),
    );
  }
}

// ───────────────────────── ⑦ 挑选模式 ─────────────────────────

class DrillPickerPage extends StatefulWidget {
  const DrillPickerPage({
    super.key,
    required this.actions,
    required this.groupName,
    required this.existing,
    this.initialPicked = const [],
    this.initialFilter = const LibraryFilter(),
    this.initialActions = const ActionFilter(),
  });
  final LibraryActions actions;
  final String groupName;

  /// Drill ids already in the group (the 已在组里 note; repeats allowed).
  final List<String> existing;
  final List<String> initialPicked;
  final LibraryFilter initialFilter;

  /// UI r2 M3: the shared 动作库 filter the picker opens with.
  final ActionFilter initialActions;
  @override
  State<DrillPickerPage> createState() => _DrillPickerPageState();
}

class _DrillPickerPageState extends State<DrillPickerPage> {
  late final List<String> _picked = [...widget.initialPicked];
  late ActionFilter _actions = widget.initialActions;
  late final _search = TextEditingController(text: _actions.query);

  HipContent get content => widget.actions.store.content;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = LibText.of(context);
    final all = hipActionItems(content, t);
    // Addable actions first (M6: every public SDK action is addable).
    final match = _actions.apply(all);
    final shown = [
      for (final a in match)
        if (a.canAddToGroup) a,
      for (final a in match)
        if (!a.canAddToGroup) a,
    ];
    final inGroup = widget.existing.toSet();
    final after = widget.existing.length + _picked.length;
    final over = after > CustomRoutine.maxSteps;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            HipNavBar(
              leading: HipNavLeading.close,
              leadingKey: const ValueKey('picker-close'),
              onLeading: () => Navigator.of(context).pop(),
              title: t.addMovesTitle,
              subtitle: t.addTo(widget.groupName),
            ),
            Expanded(
              child: Builder(
                builder: (context) {
                  final header = <Widget>[
                    ActionFilterBar(
                      all: all,
                      filter: _actions,
                      search: _search,
                      onChanged: (f) => setState(() => _actions = f),
                    ),
                    const SizedBox(height: 14),
                    if (shown.isEmpty)
                      ActionEmpty(
                        onReset: () => setState(() {
                          _search.clear();
                          _actions = const ActionFilter();
                        }),
                      ),
                  ];
                  final rows = ActionRows(context, [
                    for (final a in shown)
                      ActionCard(
                        key: ValueKey('pick-${a.id}'),
                        item: a,
                        // Local kit drills show their group dose; SDK
                        // actions their catalog default (M6).
                        disabled: !a.canAddToGroup,
                        dose:
                            content.kit(a.id) != null &&
                                inLibrary(content, a.id)
                            ? doseText(
                                content.kit(a.id)!,
                                DoseRules.kitDefault(content.kit(a.id)!),
                                single: false,
                                lang: t.lang,
                              )
                            : null,
                        check: _picked.contains(a.id),
                        inGroup: inGroup.contains(a.id),
                        onTap: (_) {
                          if (!a.canAddToGroup) {
                            ScaffoldMessenger.of(context)
                              ..hideCurrentSnackBar()
                              ..showSnackBar(
                                SnackBar(
                                  content: Text(
                                    t.lang == 'en'
                                        ? 'This move can be practised on its own, not in a group yet.'
                                        : '这个动作暂时只能在动作库单独练，还不能加入训练组',
                                  ),
                                ),
                              );
                            return;
                          }
                          setState(() {
                            if (!_picked.remove(a.id)) _picked.add(a.id);
                          });
                        },
                      ),
                  ]);
                  return ListView.builder(
                    key: const ValueKey('picker-list'),
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                    itemCount: header.length + rows.length,
                    itemBuilder: (context, i) => i < header.length
                        ? header[i]
                        : rows.row(i - header.length),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: LibFooter(
        above: Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Text(
                t.picked(_picked.length),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  over ? t.max20 : t.willHave(after),
                  key: const ValueKey('picker-count'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: over ? HipColors.pain : HipColors.muted,
                  ),
                ),
              ),
              HipPressable(
                key: const ValueKey('picker-clear'),
                semanticLabel: t.clear,
                onTap: _picked.isEmpty
                    ? null
                    : () => setState(() => _picked.clear()),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Text(
                    t.clear,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _picked.isEmpty
                          ? HipColors.faint
                          : HipColors.jadeText,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        children: [
          Expanded(
            child: HipPrimaryButton(
              key: const ValueKey('picker-add'),
              label: t.addN(_picked.length),
              icon: HipGlyph.plus,
              onPressed: _picked.isEmpty || over
                  ? null
                  : () => Navigator.of(context).pop([..._picked]),
            ),
          ),
        ],
      ),
    );
  }
}

/// ①b 筛选面板: 在哪做 / 怎么练 / 难度; OR within a group, AND across;
/// the button shows the live result count.
Future<LibraryFilter?> showFilterSheet(
  BuildContext context,
  HipContent content,
  LibraryFilter initial,
) {
  final t = LibText.of(context);
  final all = libraryDrills(content);
  var f = initial;
  Set<T> toggle<T>(Set<T> s, T v) =>
      s.contains(v) ? ({...s}..remove(v)) : {...s, v};
  return showLibSheet<LibraryFilter>(
    context,
    builder: (context) => StatefulBuilder(
      builder: (context, setSheet) {
        final n = f.apply(content, all).length;
        Widget section(String title, List<Widget> chips) => Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  color: HipColors.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: chips),
            ],
          ),
        );
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            sheetTitle(
              t.filter,
              trailing: HipPressable(
                key: const ValueKey('filter-reset'),
                semanticLabel: t.reset,
                onTap: f.sheetCount == 0
                    ? null
                    : () => setSheet(() => f = f.withoutSheet),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Text(
                    t.reset,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: f.sheetCount == 0
                          ? HipColors.faint
                          : HipColors.jadeText,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            section(t.sceneTitle, [
              for (final s in [HipScene.chair, HipScene.home])
                LibChip(
                  t.scene(s),
                  key: ValueKey('filter-scene-${s.id}'),
                  on: f.scenes.contains(s),
                  onTap: () => setSheet(
                    () => f = f.copyWith(scenes: toggle(f.scenes, s)),
                  ),
                ),
            ]),
            section(t.methodTitle, [
              for (final m in HipMethod.values)
                LibChip(
                  t.method(m),
                  key: ValueKey('filter-method-${m.id}'),
                  on: f.methods.contains(m),
                  onTap: () => setSheet(
                    () => f = f.copyWith(methods: toggle(f.methods, m)),
                  ),
                ),
            ]),
            section(t.levelTitle, [
              for (final (adv, label) in [
                (false, t.starter),
                (true, t.advancedLevel),
              ])
                LibChip(
                  label,
                  key: ValueKey('filter-level-$adv'),
                  on: f.levels.contains(adv),
                  onTap: () => setSheet(
                    () => f = f.copyWith(levels: toggle(f.levels, adv)),
                  ),
                ),
            ]),
            HipPrimaryButton(
              key: const ValueKey('filter-apply'),
              label: t.showN(n),
              onPressed: () => Navigator.of(context).pop(f),
            ),
          ],
        );
      },
    ),
  );
}
