// Embeddable recipe, not a standalone app or an independent UI package.
// The gallery host supplies HipLab's theme, palette and localization delegates.
import 'package:flutter/material.dart';
import 'package:hiplab/hip/ui/hip_page_kit.dart';
import 'package:hiplab/hip/ui/hip_routes.dart';
import 'package:hiplab/hip/ui/hip_theme.dart';

/// A home surface with no back chip, followed by single/double-title pages.
class NavigationRecipeHome extends StatelessWidget {
  const NavigationRecipeHome({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: HipColors.background,
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(kHipPageEdge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            Text(
              '导航样例首页',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: HipColors.text,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '本页没有返回胶囊。打开下一页时，胶囊必须随顶栏一起滑入。'
              '后续单双标题页面之间，只有胶囊保持原位。',
              style: TextStyle(fontSize: 16, color: HipColors.muted),
            ),
            const SizedBox(height: 28),
            HipListGroup(
              inset: 16, // Icon-free rows start their text at the inner edge.
              children: [
                HipListRow(
                  key: const ValueKey('recipe-nav-open-more'),
                  title: '打开更多样页',
                  subtitle: '首页入口显式使用 pinLeading: false',
                  onTap: () => Navigator.of(context).push(
                    HipRoute.content<void>(
                      (_) => const _NavigationRecipeMenu(),
                      pinLeading: false,
                    ),
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

class _NavigationRecipeMenu extends StatelessWidget {
  const _NavigationRecipeMenu();

  @override
  Widget build(BuildContext context) => HipNavPage(
    title: '更多样页',
    bodyScrollsUnderBar: true,
    body: ListView(
      padding: EdgeInsets.fromLTRB(
        kHipPageEdge,
        hipNavInset(context) + 12,
        kHipPageEdge,
        24,
      ),
      children: [
        HipListGroup(
          inset: 16,
          children: [
            HipListRow(
              key: const ValueKey('recipe-nav-open-caption'),
              title: '添加动作（双标题）',
              subtitle: '标题区增高，左右控件仍在原来的44点轨道上',
              onTap: () => Navigator.of(context).push(
                HipRoute.content<void>((_) => const _NavigationCaptionPage()),
              ),
            ),
            HipListRow(
              title: '固定正文页',
              subtitle: 'bodyScrollsUnderBar: false，不再重复添加顶栏间距',
              onTap: () => Navigator.of(context).push(
                HipRoute.content<void>((_) => const _NavigationFixedPage()),
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        for (var index = 1; index <= 14; index++)
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Text(
              '滚动内容 $index：向上滚动，看文字经过真实磨砂带后逐渐消失。',
              style: TextStyle(fontSize: 17, color: HipColors.text),
            ),
          ),
      ],
    ),
  );
}

class _NavigationCaptionPage extends StatelessWidget {
  const _NavigationCaptionPage();

  @override
  Widget build(BuildContext context) => HipNavPage(
    title: '添加动作',
    subtitle: '加到「导航样例训练组」',
    leading: HipNavLeading.close,
    bodyScrollsUnderBar: true,
    body: ListView(
      padding: EdgeInsets.fromLTRB(
        kHipPageEdge,
        hipNavInset(context, hasSubtitle: true) + 12,
        kHipPageEdge,
        24,
      ),
      children: [
        HipListGroup(
          inset: 16,
          children: [
            HipListRow(
              key: const ValueKey('recipe-nav-open-detail'),
              title: '打开动作说明（单标题）',
              subtitle: '进入、返回和取消侧滑都保持同一胶囊锚点',
              onTap: () => Navigator.of(context).push(
                HipRoute.content<void>((_) => const _NavigationDetailPage()),
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        Text(
          '观察关闭按钮：副标题增加了8点标题空间，按钮仍位于状态栏下缘，'
          '没有向下移动4点。iOS平台可从左边缘拖动返回，也可拖一小段后取消。',
          style: TextStyle(fontSize: 17, color: HipColors.text),
        ),
      ],
    ),
  );
}

class _NavigationDetailPage extends StatelessWidget {
  const _NavigationDetailPage();

  @override
  Widget build(BuildContext context) => HipNavPage(
    title: '动作说明',
    bodyScrollsUnderBar: true,
    body: ListView(
      padding: EdgeInsets.fromLTRB(
        kHipPageEdge,
        hipNavInset(context) + 12,
        kHipPageEdge,
        24,
      ),
      children: [
        Text(
          '本页从双标题页进入，恢复44点单标题高度。返回按钮的位置不变。',
          style: TextStyle(fontSize: 17, color: HipColors.text),
        ),
        const SizedBox(height: 28),
        Text(
          '点击返回或使用系统返回后，下方页面仍在原处，整张页面表面向右退场，'
          '而不是先淡成空背景。',
          style: TextStyle(fontSize: 17, color: HipColors.muted),
        ),
      ],
    ),
  );
}

class _NavigationFixedPage extends StatelessWidget {
  const _NavigationFixedPage();

  @override
  Widget build(BuildContext context) => HipNavPage(
    title: '固定正文页',
    body: Padding(
      padding: const EdgeInsets.fromLTRB(kHipPageEdge, 12, kHipPageEdge, 24),
      child: Text(
        'HipNavPage已经为固定正文保留状态栏和44点标题行。'
        '这里仅添加正文自己的12点间距，不再使用hipNavInset，也不包顶部SafeArea。',
        style: TextStyle(fontSize: 17, color: HipColors.text),
      ),
    ),
  );
}
