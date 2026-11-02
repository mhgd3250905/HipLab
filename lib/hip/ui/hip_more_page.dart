// 「更多」 (home redesign r1, 开哥 2026-11-02): everything that left 首页 —
// AI 排一套 first, then 我的训练组 / 全部动作与套路 / 髋部自测 / 训练记录,
// then 设置. Existing pages are reused as they are.
import 'package:flutter/material.dart';

import '../control/hip_store.dart';
import 'coach/hip_coach_chat_page.dart';
import 'hip_app.dart' show HipProgressPage, HipProgressSection;
import 'hip_calm.dart';
import 'hip_icons.dart';
import 'hip_routes.dart';
import 'hip_theme.dart';
import 'hip_widgets.dart';
import 'library/library_actions.dart';
import 'library/practice_page.dart';

class HipMorePage extends StatelessWidget {
  const HipMorePage({
    super.key,
    required this.store,
    required this.actions,
    required this.practice,
    required this.onStartAssessment,
  });
  final HipStore store;
  final LibraryActions actions;

  /// 练习库 segment and filter, shared with every opening of the library.
  final PracticeMemory practice;
  final void Function({BuildContext? from, double radius, Color? color})
  onStartAssessment;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: ListenableBuilder(
        listenable: store,
        builder: (context, _) => _list(context),
      ),
    ),
  );

  Widget _list(BuildContext context) {
    final coach = actions.coach;
    final showAi =
        coach != null &&
        aiCoachAvailable(context, configured: coach.configured);
    final groups = store.customRoutines.length;
    final items = <Widget>[
      Row(
        children: [
          HipCalmRoundButton(
            key: const ValueKey('more-back'),
            semanticLabel: '返回',
            onTap: () => Navigator.of(context).maybePop(),
            child: HipIcon(HipGlyph.back, size: 20, color: HipColors.text),
          ),
          const SizedBox(width: 14),
          const Text(
            '更多',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
        ],
      ),
      if (showAi) ...[const SizedBox(height: 22), _aiCard(context)],
      const SizedBox(height: 18),
      _group([
        _row(
          context,
          key: 'more-groups',
          glyph: HipGlyph.grip,
          title: '我的训练组',
          meta: groups == 0 ? '还没有' : '$groups 组',
          onTap: () => _practice(context, 2),
        ),
        _row(
          context,
          key: 'more-practice',
          glyph: HipGlyph.library,
          title: '全部动作与套路',
          meta: '${store.content.drills.length} 个动作',
          onTap: () => _practice(context, 0),
        ),
        Builder(
          builder: (rowContext) => _row(
            rowContext,
            key: 'more-checkup',
            glyph: HipGlyph.radar,
            title: '髋部自测',
            meta: '3 分半',
            onTap: () => onStartAssessment(
              from: rowContext,
              radius: 0,
              color: HipColors.surface,
            ),
          ),
        ),
        _row(
          context,
          key: 'more-records',
          glyph: HipGlyph.progress,
          title: '训练记录',
          meta: store.streak > 0 ? '连续 ${store.streak} 天' : '',
          onTap: () => _sub(
            context,
            '训练记录',
            HipProgressPage(store: store, section: HipProgressSection.records),
          ),
        ),
      ]),
      const SizedBox(height: 14),
      _group([
        _row(
          context,
          key: 'more-settings',
          glyph: HipGlyph.contrast,
          title: '设置',
          meta: '语音 · 外观 · 提醒',
          onTap: () => _sub(
            context,
            '设置',
            HipProgressPage(store: store, section: HipProgressSection.settings),
          ),
        ),
      ]),
      const SizedBox(height: 28),
      Text(
        '这是运动练习，不能替代医生的建议。',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 12, color: HipColors.faint),
      ),
    ];
    return ListView(
      key: const ValueKey('more-list'),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      children: [
        for (final (i, w) in items.indexed) HipCalmStagger(index: i, child: w),
      ],
    );
  }

  Widget _aiCard(BuildContext context) {
    final jade = HipColors.jade;
    return HipPressable(
      key: const ValueKey('more-ai-coach'),
      semanticLabel: '让 AI 帮你排一套',
      scale: .98,
      onTap: () => _push(context, HipCoachChatPage(actions: actions)),
      child: RepaintBoundary(
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                jade.withValues(alpha: HipColors.isDark ? .18 : .14),
                HipColors.glow.withValues(alpha: HipColors.isDark ? .06 : .05),
              ],
            ),
            border: Border.all(
              color: jade.withValues(alpha: HipColors.isDark ? .25 : .22),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '让 AI 帮你排一套',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  '说说哪里紧、有多少时间，直接给你一套能练的',
                  style: TextStyle(fontSize: 13, color: HipColors.muted),
                ),
                const SizedBox(height: 14),
                Container(
                  height: 46,
                  padding: const EdgeInsets.fromLTRB(18, 0, 6, 0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(23),
                    color: HipColors.isDark
                        ? Colors.black.withValues(alpha: .35)
                        : Colors.white.withValues(alpha: .8),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '比如：下午腰胯很僵，10 分钟',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            color: HipColors.faint,
                          ),
                        ),
                      ),
                      Container(
                        width: 34,
                        height: 34,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: jade,
                        ),
                        child: HipIcon(
                          HipGlyph.play,
                          size: 14,
                          filled: true,
                          color: HipColors.onJade,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final c in const ['久坐腰胯僵', '想练劈叉', '跑步后放松'])
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: HipColors.isDark
                              ? Colors.white.withValues(alpha: .06)
                              : Colors.white.withValues(alpha: .7),
                        ),
                        child: Text(
                          c,
                          style: TextStyle(
                            fontSize: 12,
                            color: HipColors.muted,
                          ),
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

  Widget _group(List<Widget> rows) => HipCalmSurface(
    radius: 22,
    child: Column(
      children: [
        for (final (i, r) in rows.indexed) ...[
          if (i > 0)
            Padding(
              padding: const EdgeInsets.only(left: 66),
              child: Divider(height: 1, thickness: 1, color: HipColors.line),
            ),
          r,
        ],
      ],
    ),
  );

  Widget _row(
    BuildContext context, {
    required String key,
    required HipGlyph glyph,
    required String title,
    required String meta,
    required VoidCallback onTap,
  }) => HipPressable(
    key: ValueKey(key),
    semanticLabel: title,
    scale: .99,
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 15, 14, 15),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(11),
              color: HipColors.surfaceHigh,
            ),
            child: HipIcon(glyph, size: 18, color: HipColors.jadeText),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          if (meta.isNotEmpty)
            Flexible(
              child: Padding(
                padding: const EdgeInsets.only(left: 8, right: 6),
                child: Text(
                  meta,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: TextStyle(fontSize: 13, color: HipColors.faint),
                ),
              ),
            ),
          HipIcon(HipGlyph.chevronRight, size: 18, color: HipColors.faint),
        ],
      ),
    ),
  );

  void _practice(BuildContext context, int segment) {
    practice.segment = segment;
    // PracticePage carries its own big 「练习」 title.
    _sub(
      context,
      null,
      PracticePage(
        actions: actions,
        memory: practice,
        onStartAssessment: onStartAssessment,
      ),
    );
  }

  void _sub(BuildContext context, String? title, Widget body) => _push(
    context,
    Scaffold(
      appBar: AppBar(
        // HipLab glyphs only (no Material Icon), same back as everywhere.
        leading: Builder(
          builder: (c) => IconButton(
            tooltip: '返回',
            onPressed: () => Navigator.of(c).maybePop(),
            icon: HipIcon(HipGlyph.back, size: 22, color: HipColors.text),
          ),
        ),
        title: title == null ? null : Text(title),
      ),
      body: SafeArea(top: false, child: body),
    ),
  );

  void _push(BuildContext context, Widget page) =>
      Navigator.of(context).push(HipRoute.push<void>((_) => page));
}
