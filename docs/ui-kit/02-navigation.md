# 导航：状态栏、浮动顶栏与唯一返回胶囊

本章说明 HipLab 共享顶栏与页面转场的实现，尺寸以《UI 设计规范》为准。这里是 Flutter 自绘的仿 iOS 设计语言，跨 Android/iOS 使用，不是系统原生导航栏，也不声称完整复刻系统私有材质。

完整可编译样例：[navigation_example.dart](examples/navigation_example.dart)。公开入口 `NavigationRecipeHome` 可放入画廊的 `MaterialApp` 首页，或由画廊启动器推入。它展示“无返回键首页 → 更多单标题 → 添加动作双标题 → 动作说明单标题”，另含不穿透顶栏的固定正文页。

样例中的导航行没有前导图标，分组显式`inset:16`使分隔线对齐其文字列；有30pt图标的设置行仍用默认58。不要把无图标样例的缩进复制到有图标列表。

## 1. 实现依据和移植边界

| 依据 | 负责什么 |
|---|---|
| [hip_app.dart](../../lib/hip/ui/hip_app.dart) 的 `AnnotatedRegion<SystemUiOverlayStyle>` | 系统状态栏/导航栏图标及底色随主题变化 |
| [hip_page_kit.dart](../../lib/hip/ui/hip_page_kit.dart) 的 `HipNavBar`、`HipNavPage`、`HipNavBackChip` | 统一几何、渐隐遮罩、正文安全区、固定胶囊的分层 |
| [hip_routes.dart](../../lib/hip/ui/hip_routes.dart) 的 `HipRoute`、`HipRouteSurface`、`HipCoveredTransition` | 页面动画、下页响应、iOS 边缘返回、减少动画 |
| [hip_theme.dart](../../lib/hip/ui/hip_theme.dart) 的 `HipMotion`、`HipColors` | 全局色板、时长和曲线 |
| [hip_widgets.dart](../../lib/hip/ui/hip_widgets.dart) 的 `HipTopBar` | 自测等沉浸页独立的48点控制轨道 |

这些是项目内组件，不是已经发布的独立 UI 包。示例使用 `package:hiplab` 导入。移到其他 App 时，先把色板、文字、图标、按压组件和页面/路由一起建立对应接口；`hip_page_kit.dart` 还引用 `HipGlassBackdrop`、`HipPressable`、`HipText`、条目图标等，不能只拷一个 `HipNavPage` 类就认为依赖齐全。画廊宿主需要提供主题、正确的 `HipColors` 色板和本地化 delegates；本样例不重复创建第二个 `MaterialApp`。

生产文件顶部有部分旧阶段注释，例如早期条目图标32点、标题16点和卡片圆角12点。抽取时以当前 `build` 实现与本手册对应章节为准，不能把文件头当作当前数值表。

## 2. 状态栏与顶栏的坐标契约

所有尺寸均为 Flutter 逻辑像素。`safeTop = MediaQuery.paddingOf(context).top` 来自设备，不能写死刘海高度。

| 部位 | 当前参数 | 不能误解为 |
|---|---|---|
| 顶栏背景起点 | 屏幕 y=0 | 先放进顶部 `SafeArea` 后才开始绘制 |
| 普通标题行 | 44高 | 再加一个默认 Material AppBar 高度 |
| 双行标题区 | 52高 | 返回按钮也应居中到52高里 |
| 返回/关闭胶囊 | 44×44，左边16，顶为 `safeTop` | 视觉直径小、外面再补一个未对齐的热区 |
| 右侧操作轨道 | 右边16，顶为 `safeTop`，高44 | 随副标题或正文高度上下漂移 |
| 标题安全区 | 左右各60 | 右侧按钮越宽，标题仍可任意占满整行 |
| 标题 | 17/w600/行高1.2，单行省略 | 正文大标题 |
| 副标题 | 12/muted/行高1.25，单行省略 | 靠改变整行中心位置容纳 |
| 标题缩放 | 最多1.3；生产组件内限定 | 整个 App 的字号支持承诺 |
| 遮罩过渡段 | 标题行下24 | 正文静止时可以压在这24点里 |
| 页面水平外边距 | `kHipPageEdge = 20` | 返回按钮也跟着变成20 |

穿透页面的正文首个内容必须清除完整材料带：

```dart
double hipNavInset(BuildContext context, {bool hasSubtitle = false}) =>
    MediaQuery.paddingOf(context).top +
    (hasSubtitle ? HipNavBar.heightWithSubtitle : HipNavBar.height) +
    kHipNavFade;
```

例如 `safeTop=47`：普通标题材料带高115，双标题高123。加上正文自己的12点间距，首行起点分别127/135。顶栏从y=0开始取样，返回按钮仍在y=47，中心为y=69；有无副标题都一样。

```text
y=0       ┌──────── 系统状态栏 + 顶栏材料从这里开始 ────────┐
          │ 状态栏图标由系统绘制，背景由页面延伸到其下       │
y=safeTop │ [44×44胶囊]       标题       [44点操作轨道]       │
          │                  副标题（可选）                 │
          ├── 标题行结束：safeTop + 44 或 52 ────────────────┤
          │       24点材料逐渐消失的过渡带                 │
          └── hipNavInset：正文静止时至少越过这里 ──────────┘
                     +正文自有间距，如12
```

系统栏样式由主题宿主的 `AnnotatedRegion<SystemUiOverlayStyle>` 管理：深色背景采用浅色图标，浅色背景采用深色图标，`statusBarColor`透明，系统导航栏使用当前页面背景色。不要一边在宿主切深浅色，一边在各子页重复设置固定图标亮度。Android edge-to-edge 和系统栏行为还受目标 App 的原生配置影响，移植后需要实际设备核对，不能仅靠上述 Flutter 参数证明一致。

### 两种正文模式只能选一种

| 模式 | 组件行为 | 页面正文需要做的事 |
|---|---|---|
| `bodyScrollsUnderBar:true` | 视口到达屏幕顶部，顶栏覆盖在上面 | 给自己的滚动内容添加 `hipNavInset`，双标题传 `hasSubtitle:true` |
| `bodyScrollsUnderBar:false` | 组件先保留 `safeTop + 44/52 + 24` | 只加正文间距；不要再加顶部 `SafeArea` 或 `hipNavInset` |

`HipNavPage.bottomBar` 接收页面底部操作条。操作条负责自身底部 `SafeArea`；有操作条时，正文不会再叠底部安全区。键盘出现时页面组件利用 `viewInsets.bottom` 抬起操作条，调用方不能再加一份相同的键盘位移。

## 3. 渐隐遮罩和返回按钮

### 3.1 顶栏遮罩

背景色渐变覆盖状态栏、标题区和 24 点过渡段。渐变以 13 个采样近似，在带高 60% 处降到 α=.86，随后按抛物线降到完全透明。浅色和深色取当前背景色，内容滑到遮罩下方时仍可辨认轮廓。遮罩常驻，无背景模糊、实色底板或分割线。

### 3.2 返回/关闭胶囊

胶囊与顶栏处于同一平面：均匀透明填色、真实局部σ12模糊和一条细边，不加立体高光渐变、斜面或漂浮投影。

| 项 | 浅色 | 深色 |
|---|---|---|
| 填色 | 白色α=.38 | 白色α=.12 |
| 细边 | 黑色α=.10 | 白色α=.16 |
| 细边宽 | .75 | .75 |
| 高对比度 | 实色填充、边宽1、边黑α=.35 | 实色填充、边宽1、边白α=.45 |

`ClipOval` 必须在胶囊的 `BackdropFilter` 外面，限定实际采样范围。图形尺寸32、线宽2，热区44×44。按压使用 `.9` 缩放，这是导航胶囊的特定反馈值，不要误套成所有按钮统一缩放。返回/关闭都有Tooltip与语义标签，默认动作是 `Navigator.maybePop()`；有未保存内容的页面应继续走它自己的退出拦截，不应另造一个绕过业务检查的pop入口。

## 4. 页面与胶囊的分层和所有权

`HipRoute.content` 和 `HipNavPage` 必须配对。content路由本身不平移整个child，由 `HipRouteSurface` 按路由动画时钟移动页面表面。

```text
Navigator
└─ HipRoute.content：掌握正向/反向/手势进度
   └─ HipNavPage 外层 Stack
      ├─ 滑动表面 HipRouteSurface
      │  ├─ 页面背景 backdrop
      │  ├─ 透明 Scaffold
      │  │  ├─ body
      │  │  └─ bottomBar（如有）
      │  └─ 顶栏遮罩 + 标题 + 右侧操作
      └─ 固定胶囊（仅 pinLeading=true；不在滑动表面内）
```

只有胶囊固定，遮罩、标题和右侧操作随页面滑动。pop时整张表面退向右侧，仍存活的下层页直接露出，避免先淡成空背景。

### 4.1 两类来源调用点

| 来源 → 目的地 | `pinLeading` | 原因 |
|---|---|---|
| 无返回键首页 → 更多/记录 | 显式false | 来源没有可对齐胶囊，目的胶囊应跟随顶栏滑入 |
| 更多 → 设置 → 隐私 | 默认true | 前后都有胶囊，只固定这个视觉锚点 |
| 单标题 → 双标题 → 单标题 | 默认true | 标题区可以改变，44点左右控件轨道不变 |

不能把“所有目的页都固定胶囊”当作规则。`pinLeading` 表达的是来源与目的地的关系，需要在push调用处判断。

### 4.2 push、pop与取消的控制权

`_HipUncoveredLeading` 同时包住inline和pinned两种布局的胶囊。被覆盖页的 `secondaryAnimation.value > 0` 时隐藏胶囊；反向进度完全回到0才恢复。

| 时刻 | 来源胶囊 | 目的胶囊 | 页面表面 |
|---|---|---|---|
| push之前 | 显示（如来源本来有） | 未出现 | 来源静止 |
| push中间帧 | 隐藏 | 由目的页拥有；按pin设置固定或随页移动 | 目的从右侧进入，来源轻视差 |
| push完成 | 隐藏在下层 | 显示 | 目的静止 |
| pop或完成侧滑中间帧 | 继续隐藏 | 继续拥有控制权 | 目的向右退，来源露出 |
| pop完全结束 | 恢复 | 随路由移除 | 来源恢复 |
| 侧滑一小段再取消 | 始终隐藏 | 仍由目的页拥有 | 目的回到展开终态，来源仍在下层 |

精确零帧的测试允许两个同位控件元素短暂存在，但必须使用相同几何，中间可见帧不能有两只胶囊横穿屏幕。规范要保证视觉控制权单一，不要把“每个时刻Widget树永远只有一个节点”当作实际实现事实。

### 4.3 侧滑跟手与减少动画

iOS 左侧热区宽度取 20pt 和左侧安全区宽度中的较大值。当前页只接收一个边缘触点，拖动距离除以屏幕宽度后直接更新路由进度。正常松手时，归一化速度绝对值达到 1 就按方向决定完成或回弹，其余按路由进度 0.5 判断。收尾使用 `fastEaseInToSlowEaseOut`，时长按剩余距离计算，至少 120ms。系统发送 `PointerCancelEvent` 时，只要该页仍在顶部就恢复当前页。

减少动画时路由正反时长为0并直接到达最终布局，iOS返回手势仍保留。不要把关闭动画误实现为禁掉导航交互。Android系统返回按正常路由栈处理，不需要伪装成iOS边缘手势。

## 5. 时序与曲线

| 语义 | 正向 / 反向 | 主动作 | 下页响应 |
|---|---|---|---|
| `content` | 400 / 340ms | 目的页面表面水平进入/退出 | -.28倍宽视差 + 轻微压暗 |
| `push` | 400 / 340ms | 整个目的页水平进入/退出 | 同上；不提供固定胶囊拆层 |
| `rise` | 400 / 340ms | 无在屏来源的任务页自下升起 | 仅压暗 |
| `expandFrom` | 500 / 420ms | 来源控件容器向页面扩张 | 仅压暗，不额外缩放 |

页面enter为 `Cubic(.2,0,0,1)`，pop使用 `HipMotion.exit.flipped`，其中exit为 `Curves.fastOutSlowIn`。不能仅凭“都是400ms”就换成任意同名弹簧曲线：前1/3时间就走完90%的曲线会使页面像突然切入，最后再缓慢爬行。

下层页面只做一个轻响应：push/content最多向左偏移28%宽，压暗上限为浅色.14、深色.32。rise/expand不增加第二个滑动或缩放。一次过渡一个主动作，容器扩张时不再让另一个Hero同时飞行。

`expandFrom` 在来源找不到已布局RenderBox时回落到rise；来源有同尺寸 `RepaintBoundary` 时可以取小控件快照。该快照是开始按钮等控件的过渡辅助，不是视频卡片换播放器的许可；连续媒体的单实例约定见媒体与动效章节。

## 6. 最小完整页面样例

下面的页面在已有主题/组件宿主内可直接编译；完整的来源→目的多页版本见[画廊样例文件](examples/navigation_example.dart)。

```dart
import 'package:flutter/material.dart';
import 'package:hiplab/hip/ui/hip_page_kit.dart';

class PreferencesExample extends StatelessWidget {
  const PreferencesExample({super.key});

  @override
  Widget build(BuildContext context) => HipNavPage(
    title: '设置',
    bodyScrollsUnderBar: true,
    body: ListView(
      padding: EdgeInsets.fromLTRB(
        kHipPageEdge,
        hipNavInset(context) + 12,
        kHipPageEdge,
        24,
      ),
      children: const [
        HipListGroup(
          inset: 16,
          children: [
            HipListRow(title: '训练提醒', meta: '每天'),
            HipListRow(title: '界面语言', meta: '中文'),
          ],
        ),
      ],
    ),
  );
}
```

调用差异：

```dart
// 此代码位于已有页面的回调内，context来自该页面。
// 无返回键首页来源：目的胶囊随页进入。
Navigator.of(context).push(
  HipRoute.content<void>(
    (_) => const PreferencesExample(),
    pinLeading: false,
  ),
);

// 来源已经有返回胶囊：目的胶囊留在共同锚点。
Navigator.of(context).push(
  HipRoute.content<void>((_) => const PreferencesExample()),
);
```

两段调用分别对应不同来源，不应连续执行。实际导入和回调位置已完整写在样例文件中。列表样式由共享组件负责，页面不额外嵌套Material AppBar或重复绘制返回键。

## 7. 遮罩与胶囊的绘制范围

顶栏遮罩直接绘制在自己的带高内。返回胶囊是独立控件，`ClipOval` 限定其 σ12 的采样范围，高对比度使用实色和边线。路由进入和退出的曲线在路由生命周期绑定与释放，拖动时直接使用原始路由进度。

## 8. 常见做歪方式

| 错误做法 | 看到的问题 | 正确检查点 |
|---|---|---|
| 所有页面一律 `pinLeading:true` | 从首页进入时按钮先冒出来，再看到页面 | 来源是否本来有返回胶囊 |
| 只固定整个Topbar | 标题和右操作像贴在屏幕上，页面从下面穿过去 | 固定层只含胶囊 |
| 只给pinned胶囊做隐藏 | 更多inline胶囊和设置pinned胶囊同时出现 | 两种布局都经过 `_HipUncoveredLeading` |
| 一调用pop就显示来源胶囊 | 退出中出现两只按钮 | 等secondary进度回到0 |
| 44点按钮居中放在52点标题区 | 进双标题页时下移4点 | 左右控件固定topInset/44点轨道 |
| 顶部包SafeArea，正文又加hipNavInset | 额外空白，材料不到状态栏下面 | 区分材料坐标与正文首行坐标 |
| 首行只避开44点标题，不避24点尾带 | 静止第一条内容发灰 | `hipNavInset`包含24 |
| `HipRoute.push`再包自行固定Topbar | 路由和页面各滑一次或拆层错误 | HipNavPage目的页使用content配对 |
| content路由用于普通Scaffold，却没有HipNavPage | 因content本身不变换child而没有预期滑入 | 宿主页使用 HipNavPage；从宿主包裹 SDK 页时可用 HipRouteSurface 或 push |
| Pop先淡掉整张页面 | 短暂空背景/穿帮 | 同一surface反向滑出露出存活下页 |
| ShaderMask直接淡掉正文/背景快照 | 字体意外透出 | 使用独立背景色渐变遮罩 |
| 给顶栏遮罩加滤镜 | 滚动内容被模糊 | 采样只发生在胶囊 ClipOval 内 |
| 手势过程仍走enter曲线 | 页面滞后或超前于指尖 | 拖动直接使用线性route进度 |
| 深浅色切换只改正文 | 状态栏图标、胶囊边缘仍沿用旧亮度 | 同步主题宿主、色板、系统栏样式 |

## 9. 原有验证入口与复现顺序

| 文件 | 原断言覆盖 |
|---|---|
| [hip_nav_anchor_test.dart](../../test/hip/hip_nav_anchor_test.dart) | safeTop=0/47；back/close/none；单双标题连续push/pop；pin true/false；键盘/减少动画；真实新建训练组；沉浸48点轨道 |
| [hip_nav_blur_bounds_test.dart](../../test/hip/hip_nav_blur_bounds_test.dart) | 渐变区起止和正文间距；深浅主题、单双标题和胶囊局部采样 |
| [hip_ui_round2_test.dart](../../test/hip/hip_ui_round2_test.dart) | 首页胶囊随页进入；固定胶囊；push/pop及取消侧滑的双胶囊回归；容器扩张不同时飞Hero |
| [hip_transition_test.dart](../../test/hip/hip_transition_test.dart) | 渐进push/pop；下页仅压暗；容器变换；减少动画最终态可交互；tab fade-through |

在样例中依次打开更多、双标题选择器、单标题详情，分别观察正向、返回、iOS左缘拖一半完成、拖一小段取消。再滚动更多页，让正文经过状态栏和材料带；切换深浅主题和减少动画后重复。完整回归会在精确零帧和每16ms中间帧检查几何，不能只用两张静止截图判断导航正确。

本章提供原验证入口和可复用复现路径，不表示本次文档抽取又做了一轮手机或iOS原生验收。
