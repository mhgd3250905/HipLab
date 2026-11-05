// 「更多」 (UI r2, 2026-11-03): the hub of everything that left 首页 —
// 训练 (我的训练组 / 动作库), 身体 (髋部自测 / 训练记录), 偏好 (设置).
// No AI entry here (训练组 page holds the only one).
import 'package:flutter/material.dart';

import '../control/hip_store.dart';
import 'hip_app.dart' show HipProgressPage, HipProgressSection, HipSettingsPage;
import 'hip_calm.dart';
import 'hip_glass.dart';
import 'hip_icons.dart';
import 'hip_page_kit.dart';
import 'hip_routes.dart';
import 'hip_theme.dart';
import 'hip_widgets.dart';
import 'library/action_filter.dart';
import 'library/lib_text.dart';
import 'library/library_actions.dart';
import 'library/practice_page.dart';

class HipMorePage extends StatelessWidget {
  const HipMorePage({
    super.key,
    required this.store,
    required this.actions,
    required this.practice,
    required this.onStartAssessment,
    this.cover,
  });
  final HipStore store;

  /// Poster of the routine on 首页: blurred, darkened, it is the depth the
  /// glass panels refract (null: plain depth gradient).
  final String? cover;
  final LibraryActions actions;

  /// 练习库 segment and filter, shared with every opening of the library.
  final PracticeMemory practice;
  final void Function({BuildContext? from, double radius, Color? color})
  onStartAssessment;

  @override
  Widget build(BuildContext context) => HipNavPage(
    title: '更多',
    leadingKey: const ValueKey('more-back'),
    bodyScrollsUnderBar: true,
    backdrop: HipGlassBackdrop(
      image: cover == null ? null : HipMediaVariants.themed(cover!),
    ),
    body: ListenableBuilder(
      listenable: store,
      builder: (context, _) => _list(context),
    ),
  );

  Widget _list(BuildContext context) {
    final groups = store.customRoutines.length;
    // UI r2 M3: the same list 动作库 shows.
    final drills = hipActionItems(store.content, LibText.of(context)).length;
    final items = <Widget>[
      const HipSection('训练', first: true),
      HipListGroup(
        children: [
          HipListRow(
            key: const ValueKey('more-groups'),
            glyph: HipGlyph.grip,
            title: '我的训练组',
            meta: groups == 0 ? '还没有' : '$groups 组',
            onTap: () => _practice(context, 2),
          ),
          HipListRow(
            key: const ValueKey('more-practice'),
            glyph: HipGlyph.library,
            title: '动作库',
            meta: '$drills 个动作',
            onTap: () => _practice(context, 0),
          ),
        ],
      ),
      const HipSection('身体'),
      HipListGroup(
        children: [
          // UI r2 §1: 髋部自测 opens its 自测说明 page (开始 / 重测 there).
          HipListRow(
            key: const ValueKey('more-checkup'),
            glyph: HipGlyph.radar,
            title: '髋部自测',
            meta: '3 分半',
            onTap: () => _push(context, AssessmentIntroPage(actions: actions)),
          ),
          HipListRow(
            key: const ValueKey('more-records'),
            glyph: HipGlyph.progress,
            title: '训练记录',
            meta: store.streak > 0 ? '连续 ${store.streak} 天' : null,
            onTap: () => _sub(
              context,
              '训练记录',
              (_) => HipProgressPage(
                store: store,
                section: HipProgressSection.records,
                onStartPractice: () {
                  final plan = store.todayPlan;
                  if (plan != null) actions.startPlan(plan);
                },
              ),
            ),
          ),
        ],
      ),
      const HipSection('偏好'),
      HipListGroup(
        children: [
          HipListRow(
            key: const ValueKey('more-settings'),
            glyph: HipGlyph.contrast,
            title: '设置',
            meta: '提醒 · 语音 · 外观',
            onTap: () => _push(context, HipSettingsPage(store: store)),
          ),
        ],
      ),
      const SizedBox(height: 28),
      Text(
        '这是运动练习，不能替代医生的建议。',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 12, color: HipColors.faint),
      ),
    ];
    return ListView(
      key: const ValueKey('more-list'),
      padding: EdgeInsets.fromLTRB(
        kHipPageEdge,
        hipNavInset(context),
        kHipPageEdge,
        24,
      ),
      children: [
        for (final (i, w) in items.indexed) HipCalmStagger(index: i, child: w),
      ],
    );
  }

  void _practice(BuildContext context, int segment) {
    practice.segment = segment;
    // PracticePage carries its own HipNavBar (训练组 / 动作库).
    _push(
      context,
      PracticePage(
        actions: actions,
        memory: practice,
        library: segment == 0,
        onStartAssessment: onStartAssessment,
      ),
    );
  }

  void _sub(BuildContext context, String? title, WidgetBuilder body) => _push(
    context,
    HipNavPage(
      title: title,
      bodyScrollsUnderBar: true,
      // A pushed route is not rebuilt by the app root: follow the store
      // here so switches and choices show their new state.
      body: ListenableBuilder(listenable: store, builder: (c, _) => body(c)),
    ),
  );

  void _push(BuildContext context, Widget page) =>
      Navigator.of(context).push(HipRoute.push<void>((_) => page));
}
