// 「更多」 (home redesign r1, 开哥 2026-11-02): everything that left 首页 —
// AI 排一套 first, then 我的训练组 / 全部动作与套路 / 髋部自测 / 训练记录,
// then 设置. Existing pages are reused as they are.
import 'package:flutter/material.dart';

import '../control/hip_store.dart';
import '../domain/hip_library.dart';
import 'coach/hip_coach_chat_page.dart';
import 'hip_app.dart' show HipProgressPage, HipProgressSection;
import 'hip_calm.dart';
import 'hip_glass.dart';
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
  Widget build(BuildContext context) => Scaffold(
    body: Stack(
      fit: StackFit.expand,
      children: [
        HipGlassBackdrop(
          image: cover == null ? null : HipMediaVariants.themed(cover!),
        ),
        SafeArea(
          child: ListenableBuilder(
            listenable: store,
            builder: (context, _) => _list(context),
          ),
        ),
      ],
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
            blur: true,
            onTap: () => Navigator.of(context).maybePop(),
            child: HipIcon(HipGlyph.back, size: 20, color: HipColors.text),
          ),
          const SizedBox(width: 14),
          const Text(
            '更多',
            style: TextStyle(
              fontSize: 24,
              height: 1.2,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w800,
            ),
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
          meta: '${libraryDrills(store.content).length} 个动作',
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
            (_) => HipProgressPage(
              store: store,
              section: HipProgressSection.records,
            ),
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
            (_) => HipProgressPage(
              store: store,
              section: HipProgressSection.settings,
            ),
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
      child: HipGlass(
        blur: true,
        radius: 26,
        tint: jade,
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
                      ? Colors.black.withValues(alpha: .28)
                      : Colors.white.withValues(alpha: .72),
                  border: Border.all(
                    color: Colors.white.withValues(
                      alpha: HipColors.isDark ? .08 : .9,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '比如：下午腰胯很僵，10 分钟',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 14, color: HipColors.faint),
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
                            ? Colors.white.withValues(alpha: .08)
                            : Colors.white.withValues(alpha: .66),
                        border: Border.all(
                          color: Colors.white.withValues(
                            alpha: HipColors.isDark ? .1 : .9,
                          ),
                        ),
                      ),
                      child: Text(
                        c,
                        style: TextStyle(fontSize: 12, color: HipColors.muted),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// One glass panel per group (never one per row).
  Widget _group(List<Widget> rows) => HipCalmSurface(
    radius: 24,
    blur: true,
    child: Column(
      children: [
        for (final (i, r) in rows.indexed) ...[
          if (i > 0)
            Padding(
              padding: const EdgeInsets.only(left: 66),
              child: Divider(
                height: 1,
                thickness: .5,
                color: HipColors.text.withValues(alpha: .1),
              ),
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
              color: Colors.white.withValues(
                alpha: HipColors.isDark ? .07 : .8,
              ),
            ),
            child: HipIcon(glyph, size: 18, color: HipColors.jadeText),
          ),
          const SizedBox(width: 16),
          Text(
            title,
            maxLines: 1,
            style: const TextStyle(
              fontSize: 16,
              letterSpacing: .3,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (meta.isEmpty)
            const Spacer()
          else
            Expanded(
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
      (_) => PracticePage(
        actions: actions,
        memory: practice,
        onStartAssessment: onStartAssessment,
      ),
    );
  }

  void _sub(BuildContext context, String? title, WidgetBuilder body) => _push(
    context,
    Stack(
      fit: StackFit.expand,
      children: [
        const HipGlassBackdrop(),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            // HipLab glyphs only (no Material Icon), same back as everywhere.
            leading: Builder(
              builder: (c) => Center(
                child: Tooltip(
                  message: '返回',
                  child: HipCalmRoundButton(
                    semanticLabel: '返回',
                    size: 38,
                    onTap: () => Navigator.of(c).maybePop(),
                    child: HipIcon(
                      HipGlyph.back,
                      size: 20,
                      color: HipColors.text,
                    ),
                  ),
                ),
              ),
            ),
            leadingWidth: 64,
            title: title == null ? null : Text(title),
          ),
          // A pushed route is not rebuilt by the app root: follow the store
          // here so switches and choices show their new state.
          body: SafeArea(
            top: false,
            child: ListenableBuilder(
              listenable: store,
              builder: (c, _) => body(c),
            ),
          ),
        ),
      ],
    ),
  );

  void _push(BuildContext context, Widget page) =>
      Navigator.of(context).push(HipRoute.push<void>((_) => page));
}
