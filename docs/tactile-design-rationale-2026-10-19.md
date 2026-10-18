# 轻拟物“有选择地引入”：审美考据与判定规则（2026-10-19）

分支 `fix/tactile-curation`，基于 `origin/main`（`6020d8e`，已含 #17 转场 + #18 轻拟物按钮）。不改依赖、`pubspec.lock`、版本号和商店配置。

## 0. 起因

#18（[按钮质感统一](button-style-audit-2026-10-18.md)）把设置页语言分段控件选中块的“实体小片”质感提炼成 `HipTactile`，并铺到了几乎所有按钮：主按钮、次按钮、圆形图标按钮、卡片内小按钮、播放器反馈、视频上的药丸，以及底部 Tab 选中图标下的小药丸。

开哥真机看过后的反馈：

1. 做得太彻底，反而落入俗套——所有东西都鼓起来，就没有东西是重要的。
2. 他喜欢的原型是**分段控件的选中块**；**少数特别重要的按钮**可以轻拟物；其余不要。
3. 底部 Tab 现在只有选中 icon 下一个拟物小药丸，不如改前好看，恢复改前样式（参考截图：浅色主题「开始自测」大绿按钮 + 底栏药丸）。
4. 引入拟物要有审美上的依据，不能凭感觉；前提是审美和界面观感确实正向增加。

本文先给出处与原文，再推导规则，最后逐控件判定。代码按本文实施。

## 1. 成熟设计体系怎么说（原文摘录）

> 以下引文均为 2026-10-19 直接打开原页面核对过的英文原文，括号内为中文意译。

### 1.1 Apple Human Interface Guidelines

**Materials**（<https://developer.apple.com/design/human-interface-guidelines/materials>）

- “A material is a visual effect that creates a sense of depth, layering, and hierarchy between foreground and background elements.”（材质的作用是表达前后景之间的**深度与层级**，不是装饰。）
- “Liquid Glass forms a distinct functional layer for controls and navigation elements — like tab bars and sidebars — that floats above the content layer …”（导航与控件属于“功能层”，作为**一整层**浮在内容之上——是整条 Tab bar 浮起，而不是 Tab 里的某个图标单独鼓起。）
- “**Don’t use Liquid Glass in the content layer.** … including it in the content layer can result in unnecessary complexity and a confusing visual hierarchy. … An exception to this is for controls in the content layer with a transient interactive element like sliders and toggles; in these cases, the element takes on a Liquid Glass appearance to emphasize its interactivity when a person activates it.”（内容层不要上特殊材质，否则层级混乱；**例外是滑块、开关这类带“可被拨动的部件”的控件**——那个部件可以有材质，用来强调它能动。）
- “**Use Liquid Glass effects sparingly.** … overusing this material in multiple custom controls can provide a subpar user experience by distracting from that content. Limit these effects to the most important functional elements in your app.”（**克制使用**；在多个自定义控件上滥用会分散注意力；只给**最重要**的功能元素。）

**Buttons**（<https://developer.apple.com/design/human-interface-guidelines/buttons>）

- “In general, use a button that has a prominent visual style for the most likely action in a view. … Buttons that use color tend to be the most visually distinctive … **Keep the number of prominent buttons to one or two per view.** Presenting too many prominent buttons increases cognitive load …”（突出样式只给本视图最可能的动作；**靠颜色**就最醒目；每个视图 1–2 个，多了增加认知负担。）
- “Use style — not size — to visually distinguish the preferred choice …”（用样式层级区分主次。）
- “Always include a press state for a custom button.”（自定义按钮必须有按下态。）

**Segmented controls**（<https://developer.apple.com/design/human-interface-guidelines/segmented-controls>）

- “Consider a segmented control when it’s important to group functions together, or to clearly show their selection state.”（分段控件的职责就是**把选中状态清楚地显示出来**。）iOS 的 `UISegmentedControl` 选中块是一块会滑动的实体，它的“浮起”正是在说明“这块东西在轨道上、能被推到别的格子”。

### 1.2 Material Design 3

**Elevation – Overview**（<https://m3.material.io/styles/elevation/overview>）

- “Elevation can be shown as tonal surface colors or shadows.” / “Stick to using a small amount of elevation levels.”（层级可以用**色调**或阴影表达；**层级数量要少**。）
- 与 M2 的区别：“Shadows: Instead of applying shadows by default to all levels, **use shadows only when required** to create additional protection against a background or to encourage interaction.”（不再默认给所有层加阴影，**只在需要与背景分离或鼓励交互时**用。）
- “Focus attention on the highest elevation …”（最高的那层吸引注意——所以“最高”只能是少数。）

**Buttons – Guidelines**（<https://m3.material.io/components/buttons/guidelines>）

- Elevated：“To avoid overusing shadows, use the elevated style only when absolutely necessary … Buttons at higher elevations typically have more emphasis in a design, and **should be used sparingly**. For high emphasis, consider the filled style instead.”（带阴影的按钮要少用；要高强调**用实心填充**而不是阴影。）
- Filled：“should be used for important, final actions that complete a flow … the filled style should be used sparingly, **ideally for only one action on a page**.”（实心按钮给完成流程的关键动作，**每页最好一个**。）
- Outlined：“medium-emphasis … pair well with filled buttons to indicate alternative, secondary actions.”（次要动作用描边。）
- Text：“should be used for the lowest priority actions … In cards, text buttons help maintain an emphasis on card content.”（最低优先级、卡片内动作用文字按钮，保持卡片内容为主。）
- “Too many buttons on a screen can disrupt the visual hierarchy.”

**Navigation bar – Overview**（<https://m3.material.io/components/navigation-bar/overview>）

- 与 M2 的区别：“**Elevation: No shadow**” / “M3: Taller and no drop shadow. Filled icons and an active indicator indicate active state.”（导航栏**没有投影**；选中态靠**实心图标 + 色调指示**，不是靠凸起。）

### 1.3 Refactoring UI（Adam Wathan & Steve Schoger）

“7 Practical Tips for Cheating at Design”（<https://medium.com/refactoring-ui/7-practical-tips-for-cheating-at-design-40c736799886>）

- #7 “Not every button needs a background color”：“Every action on a page sits somewhere in a pyramid of importance. Most pages only have one true primary action, a couple of less important secondary actions, and a few seldom used tertiary actions. … **Primary actions should be obvious.** Solid, high contrast background colors work great here. **Secondary actions should be clear but not prominent.** Outline styles or lower contrast background colors … **Tertiary actions should be discoverable but unobtrusive.** Styling these actions like links is usually the best approach.”（动作是一座金字塔：主动作实心高对比，次动作描边/低对比，三级动作像链接。）
- #3 “Offset your shadows”：阴影要有竖向偏移、模拟顶光，而不是大模糊大扩散（我们保留的拟物元素遵守这一点：紧贴接触影 + 小环境影，无彩色外发光）。

### 1.4 Nielsen Norman Group（防止走向另一个极端）

“Flat-Design Best Practices”（<https://www.nngroup.com/articles/flat-design-best-practices/>）

- “we recommend using a semiflat or flat 2.0 aesthetic instead — … looks much like flat design, but incorporates **subtle** shadows, highlights, and layers to create some depth in the UI.”
- “Add back in some depth. Flat doesn’t have to be totally flat. … often shadows and layers are used just to improve aesthetics instead of supporting user mental models and building signifiers.”（深度应服务于心智模型与可点击信号，而不是为了好看而加。）
- “Never use the same visual treatment for static text and linked text.”（扁平不等于没有信号：可点的东西要有可辨的容器或颜色。）

### 1.5 Dieter Rams《好设计十原则》

Vitsœ 官方页（<https://www.vitsoe.com/us/about/good-design>）

- 5 “Good design is unobtrusive … Their design should therefore be both neutral and restrained.”（中性、克制。）
- 7 “Good design is long-lasting. It avoids being fashionable …”（不追流行——“处处拟物”恰好是一种流行腔。）
- 10 “Good design is as little design as possible. Less, but better …”

## 2. 推导：HipLab 的轻拟物判定规则

把上面的共同点归纳成 6 条**可执行、可检验**的规则。第 4 节的回归测试把其中可量化的部分写成了断言。

| # | 规则 | 依据 | 怎么检验 |
|---|---|---|---|
| R1 | **拟物只给“会动的实体”**：轻拟物（`HipTactileStyle.neutral`）只用于分段控件的**滑块**——它真的在轨道上滑动、能被拖过去，凸起是在解释“它是一块能被推走的东西”。 | HIG Materials 例外条款（sliders / toggles 的可拨动部件）；HIG 分段控件“清楚显示选中状态”；NN/g“深度要服务心智模型” | `neutral` 只出现在 `HipSegmented` 子树内（测试 T1） |
| R2 | **每条主流程只有一个“英雄动作”可用强调拟物**：品牌绿实体圆盘（`HipTactileStyle.accent`）只给首页「开始」——App 的核心循环就是“打开 → 点开始 → 练”。 | HIG Buttons“prominent 每视图 1–2 个”、Materials“只给最重要的功能元素”；M3 Elevation“最高层吸引注意”、Elevated“sparingly” | 全 App 只有 `HipStartButton` 用 `accent`；同屏 `accent` ≤ 1（T2） |
| R3 | **其余主 CTA 用颜色而不是高度表达强调**：开始自测、下一项、开始这条路线、引导「没有」、回首页——实心品牌绿平涂，无渐变、无内高光、无投影、无外发光。 | HIG“Buttons that use color tend to be the most visually distinctive”；M3 Filled（高强调、无阴影）与“For high emphasis, consider the filled style instead”；M3 M2→M3“shadows only when required”；Refactoring UI #7 | 主按钮子树无 `HipTactile`，只有一层无渐变、无阴影的纯色 `ShapeDecoration`（T3） |
| R4 | **导航与工具层保持扁平**：底部 Tab、顶栏关闭/返回、播放器暂停/跳过、视频上的「疼」——用颜色、实心/描边图标、色调底色表达状态，不加凸起。 | M3 Navigation bar“Elevation: No shadow … Filled icons … indicate active state”；HIG Materials：功能层是**整层**浮起，不是层内单个元素鼓起 | 底栏子树无 `HipTactile`（T4）；圆形按钮无阴影 |
| R5 | **按金字塔递减**：次按钮 = 描边（中强调）；卡片内动作 / 重试 / 复制链接 = 品牌色文字按钮（低强调）；播放器休息反馈 = 彩色描边胶囊。 | M3 Outlined / Text 按钮用法；Refactoring UI #7 主/次/三级 | 次按钮 = surface 底 + `line` 描边、无阴影；卡片内动作回到 Material `TextButton`（`hip_tactile_test`；`HipChipButton` 已删除） |
| R6 | **克制的数量与强度上限**：①同屏强调拟物 ≤ 1，中性拟物只在分段控件里；②保留的拟物元素一律“紧贴接触影 + 小环境影”，**不用彩色外发光、不用大模糊光晕**（开哥原先就不喜欢「开始」的浅色泛光）；③浅色主题阴影只用墨绿灰（`#0d2a20`），不透明度不高于深色主题对应层；④不退回“纯扁平”：每个可点元素仍有可见容器或品牌色文字作为信号。 | M3“Stick to a small amount of elevation levels”；Refactoring UI #3；Rams 5/7/10；NN/g flat 2.0 与“signifiers” | 令牌值在 `hip_tactile.dart` 中固定，`hip_tactile_test` 断言无彩色阴影；T1–T4 |

一句话：**能被推动的东西才有厚度；全 App 只有一个按钮值得浮起来；其余靠颜色和层级说话。**

### 为什么不是“每屏唯一主 CTA 都拟物”

这是本轮最需要权衡的一点。规则上“每屏 1 个强调拟物”也能允许每屏主 CTA 都做成凸起的绿胶囊，但这样会让**几乎每一屏底部都有一块鼓起的大绿胶囊**——观感上仍是“全都拟物”，开哥说的俗套感主要就来自这里（参考截图里浅色「开始自测」的渐变 + 投影，在白底上显得厚重）。HIG 与 M3 都把“颜色”列为最强的强调手段，再叠一层高度属于重复编码；M3 明确说高强调用 filled、阴影只在需要与背景分离时用。主 CTA 本来就在页面底部纯色背景上，不需要额外分离，所以回到平涂。

首页「开始」不同：它坐在深色媒体舞台（视频封面）之上，是“视觉丰富背景上的控件”，M3 Elevated 恰好允许这种情况用高度做分离（“when the button requires visual separation from a visually prominent background”），同时它是 App 唯一的英雄动作。所以只保留它。

### 浅色主题的「开始自测」大绿胶囊是否过重

#18 版本：`#14a37b` 顶部提亮 14% → 底部压暗 8% 的渐变 + 深绿描边 + 白 40% 内高光 + 两层投影，在 `#f4f5f3` 页面上显得像一块厚橡皮。改前版本：纯色 + `jade 22% blur24 y6` 绿色外发光（开哥已否定的“浅色泛光”）。本次：**纯色平涂，无任何阴影/发光/渐变**；按下态 = 共享 `HipPressable` 的 0.97 缩放 + 填充压暗 10%（100 ms 按下 / 180 ms 松开），与「开始」和分段滑块是同一套时序，只是没有“下沉的光影”。颜色本身足够强，视觉重量明显下降（见对比图）。

## 3. 逐控件判定

“改前”= `e98d0f1`（#17 合入后、#18 合入前）；“#18”= `6020d8e`。

| # | 控件（位置） | 改前 | #18 | 本次判定 | 理由（规则） |
|---|---|---|---|---|---|
| 1 | 分段控件选中块 `HipSegmented`（首页时长 / 场景、设置语言、外观主题） | `BoxDecoration` 选中块 + 双层阴影 | 共享 `HipTactile(neutral)`，加顶边高光与细描边，按压滑块与文字同步下沉 | **保留轻拟物** | R1：唯一“会动的实体”；开哥点名喜欢的原型 |
| 2 | 久坐提醒 45 / 60 分钟（进度页） | Material `ChoiceChip` | 小号 `HipSegmented` | **保留 #18（小号分段）** | R1：本质是二选一分段，用同一滑块与其他二选一一致；不是新增的按钮拟物 |
| 3 | 首页「开始」`HipStartButton`（深色媒体舞台，两主题同） | 渐变 + 径向光晕 + jade 大泛光 + 高光径向渐变 | `accent` 圆形轻拟物，无光晕 | **保留轻拟物（全 App 唯一）**；不恢复光晕 | R2、R6②：唯一英雄动作，处在视觉丰富背景上；#17 容器展开首帧仍取自同一 `RepaintBoundary` |
| 4 | 主 CTA `HipPrimaryButton`（开始自测、下一项 / 看结果、开始这条路线、引导「没有」、回首页） | `FilledButton` 纯 jade + jade 柔光阴影 | `accent` 胶囊（渐变 + 描边 + 内高光 + 投影） | **回退并弱化**：改前的纯 jade 胶囊外观，**去掉 jade 外发光**；按压改为共享缩放 + 压暗（不用墨水波纹，见下） | R3、R6②：颜色已是最强信号；浅色下 #18 胶囊过重，改前的发光是开哥已否定的样式 |
| 5 | 次按钮 `HipSecondaryButton`（引导安全问答「有」） | `OutlinedButton`（surface 底 + line 描边） | `neutral` 胶囊 | **回退改前外观**（surface 底 + `line` 描边，w500 字重），按压与主按钮一致 | R5：中强调 = 描边 |
| 6 | 圆形图标按钮 `HipCircleButton`（顶栏关闭/返回 44、播放器暂停/继续与跳过 64） | 深色 `surfaceHigh` 平涂；浅色灰平涂 + 选中块柔阴影；按下缩 0.9 | `neutral` 圆形轻拟物 | **回退为色调平涂**（两主题都是 `surfaceHigh`；**浅色去掉旧柔阴影，换成 1 px `line` 细描边**），按下缩 0.9 | R4、R6②④：工具/媒体控件属于功能层；浅色旧阴影属于“柔光阴影”一类，改为干净的色调层级；浅色下灰盘与页面底色只差约 2%，加一道细描边保住可点信号（NN/g signifier），不加阴影 |
| 7 | 底部 Tab（今日 / 自测 / 进度） | 颜色 + 实心图标 + 轻微缩放 | 选中图标下 56×30 `neutral` 小药丸 | **完全恢复改前**（去药丸、图标与文字间距 3、按下缩放 0.94） | R4；开哥明确要求；M3 导航栏无投影、实心图标即选中信号 |
| 8 | 卡片内小按钮（设置「试听」、首页麻木追问「是 / 否」、阻断卡「重新选择安全提示」、隐私页「复制链接」、读取失败「点一下重试」） | `TextButton` / `TextButton.icon` | `HipChipButton` 中性小药丸 | **回退改前**；删除 `HipChipButton` | R5：三级动作 = 文字按钮，保持卡片内容为主 |
| 9 | 播放器休息「舒服 / 有点紧 / 疼」（深色媒体上） | 彩色描边胶囊 `OutlinedButton`（88×48） | `HipChipButton(palette: dark)` | **回退改前** | R4、R5：媒体上的反馈选项，彩色描边已足够 |
| 10 | 播放器视频上的「疼」 | 黑 45% + 白 12% 描边 + `InkWell` | `glass` 药丸 | **回退改前**；删除 `glass` 令牌 | R4：浮在视频上的工具控件，HIG 建议半透明而非实体 |
| 11 | 自测底栏「做的时候疼 · 做不了 · 跳过」、结果页「换一条路线」 | 文字链接 | 未改 | 保持 | R5 |
| 12 | Switch、选项卡片、ListTile、左右侧指示 | — | 未改 | 保持 | 非按钮 / 系统惯例控件 |

保留的共享组件：`lib/hip/ui/hip_tactile.dart` 只剩 `neutral`（分段滑块）与 `accent`（「开始」）两种令牌；删去不再使用的 `glass` 与 `flat`，文件头注释写明使用范围与本文链接。`HipPressable` 的按压逻辑（`HipPressedScope`、`onPressChanged`、减少动态效果时不缩放、100 ms 按下 / 180 ms 松开）保持 #18 的修复版不变——这是交互时序，不是材质，且分段滑块与「开始」都依赖它；Tab 和圆形按钮显式传回改前的缩放值（0.94 / 0.9）。

**主 / 次按钮为什么不直接用回 Material `FilledButton` / `OutlinedButton`**：第一轮实施时确实直接退回了改前的 Material 按钮，但回归测试发现「开始自测」的容器展开转场失去了首帧快照（`HipRoute.expandFrom` 在点击瞬间对按钮做 `toImageSync`，Material 墨水波纹在松手那一帧把按钮标记为待重绘，快照被拒，首帧退化为无文字的纯色块）。这是 #17 转场质量的倒退，所以第二轮改为：外观完全按改前（纯色 / 描边胶囊），按压用不触发重绘竞争的共享 `HipPressable`（缩放 + 填充压暗）。这也让主、次按钮在引导页「有 / 没有」并排时按压手感一致。

## 4. 落地与检验

- 新增回归 `test/hip/hip_tactile_budget_test.dart`：
  - T1 首页、自测入口、设置、进度页：所有 `HipTactile(neutral)` 都在 `HipSegmented` 子树内。
  - T2 首页恰好 1 个 `accent`（「开始」），其余页面 0 个；全页面 `accent` ≤ 1。
  - T3「开始自测」是 `HipPrimaryButton`，子树无 `HipTactile`。
  - T4 底部 Tab 子树无 `HipTactile`，选中项为实心图标、未选中为描边图标。
- `test/hip/hip_tactile_test.dart`（同步改写）：主按钮深 / 浅两主题都只有一层纯 jade `ShapeDecoration`、无渐变 / 阴影 / 墨水波纹；次按钮 surface + `line` 描边无阴影；圆形按钮 `surfaceHigh` 无阴影（浅色有 `line` 细描边）；「开始」仍是唯一 `accent`、无光晕；按压 0.97 / 100 ms 与减少动态效果改由「开始」验证。
- `test/hip/hip_tactile_regression_test.dart`：「开始自测」按住→松手首帧连续性测试保留；“确实画出了按下态”的证据由“材质高光下降”改为“按住前后屏幕像素有变化”，并断言其中没有 `HipTactile`。
- #17：「开始」→ 训练页容器展开首帧与按钮逐像素一致的原有测试保留不动（`hip_tactile_regression_test`）。
- 验证：`flutter analyze` 0 问题；全量 194 pass / 1 条件 skip（main 191 + 净增 3：预算测试 2、`hip_tactile_test` 改写后 +1）；四尺寸单屏自测回归在全量内通过。仅沙盒无头 widget 测试；未构建 APK、未上真机。
- 三栏对比（① #18 之前 `e98d0f1` / ② #18 当前 `6020d8e` / ③ 本次）：[按钮总览·深色](images/tactile-curation-2026-10-19/overview-3col-dark.jpg) · [按钮总览·浅色](images/tactile-curation-2026-10-19/overview-3col-light.jpg) · [底部 Tab 特写](images/tactile-curation-2026-10-19/tabbar-closeup.jpg)。“① #18 之前”的总览由同一 gallery 改写为当时 App 实际控件（久坐提醒 45/60 为 `ChoiceChip`、试听为文字按钮）后在 `e98d0f1` 上生成；②③ 用仓库内 `test_screens/hip_button_gallery_test.dart`。

## 5. 风险

- 主 / 次按钮按下反馈 = 缩放 0.97 + 压暗，没有改前的墨水波纹，也没有 #18 的“光影下沉”；真机需确认按压感够明确（HIG：自定义按钮必须有按下态）。卡片内文字按钮仍是 Material 墨水波纹。
- 浅色圆形按钮去掉旧柔阴影，改为 `#eef0ee` 色调 + 1 px `#e1e4e1` 细描边，阳光下是否够清楚需真机确认；若仍不足，下一步加深描边色，不加阴影。
- 测试渲染器不画 `BoxShadow` 模糊，改前列中的发光在截图里呈硬边色带，真机是柔光；对比图里看“改前”的阴影要按此理解。
