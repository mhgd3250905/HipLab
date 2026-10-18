# 按钮质感统一：轻拟物（2026-10-18）

> 2026-10-19 更新：用户反馈“做得太彻底”，本文的全量铺开已按[审美考据与判定规则](tactile-design-rationale-2026-10-19.md)收敛，只保留分段滑块与首页「开始」两处轻拟物（分支 `fix/tactile-curation`）。下文为 #18 当时的记录。

分支 `feat/tactile-buttons`，叠在 `fix/transition-quality`（`e7cb11e`，PR #17，未合并）之上，PR 目标 base 为 `fix/transition-quality`，**须在 #17 之后合并**。不改依赖、`pubspec.lock`、版本号和商店配置；未合入 main，未构建 APK，未安装手机。

起因：用户不喜欢首页「开始」等按钮“浅色柔和泛光阴影”的平、廉价感，点名喜欢设置页语言分段控件（跟随 App / 中文 / English）选中项的质感——微妙的上亮下暗、顶边一道细高光、细描边、紧贴的深色投影，像一块实体小片而不是发光。本轮把这个选中块提炼成全 App 唯一的按钮材质。

## 1. 来源与提炼出的样式令牌

来源：`lib/hip/ui/hip_segmented.dart` 原 `_thumbDecoration` + `HipColors.thumbShadow`：

| 参数 | 原选中块（深色） | 原选中块（浅色） |
|---|---|---|
| 填充 | `thumb #26292d`，上半部叠 `thumbHighlight 0x14ffffff`（≈ 提亮 8%）渐变到 50% 处 | `#ffffff`，无渐变 |
| 描边 | 无 | 无 |
| 投影 | `0x66000000 blur2 y1` + `0x40000000 blur10 y4` | `0x1a0d2a20 blur2 y1` + `0x140d2a20 blur12 y4` |

新文件 `lib/hip/ui/hip_tactile.dart`：

- `HipTactileStyle`：`base` 中段色、`lighten` 顶边向白提亮、`darken` 底边向黑压暗（三段渐变 0 / .5 / 1）、`highlight` 顶边 1px 内高光（沿两侧淡出）、`stroke`/`strokeBottom` 细描边（上浅下深）、`shadows`（贴身接触影 + 小范围环境影）。
- `HipTactile`：在圆角矩形 / 圆形里画一种材质，按下态 100 ms 插值；默认读外层 `HipPressable` 的按下状态（`HipPressedScope`）。
- `HipTactilePainter`：一个 CustomPainter 画完阴影、填充、描边、高光。阴影不用模糊滤镜，用 2–8 层逐层外扩的圆角矩形叠出线性衰减——真机与 widget 测试截图一致（测试渲染器不画 BoxShadow 模糊），也省掉离屏模糊。

| 令牌 | 主题 | 填充（顶 / 中 / 底） | 顶部内高光 | 描边（上 → 下） | 投影（接触 + 环境） |
|---|---|---|---|---|---|
| `neutral` | 深 | `#26292d` 提亮 .08 / 原色 / 压暗 .10 | 白 14% (`0x24ffffff`) | 白 6% → 白 2% | `#000 45% b2 y1` + `#000 25% b6 y3` |
| `neutral` | 浅 | 白 / 白 / 压暗 .035 | 白（白底上不可见） | `#0d2a20` 7% → 14% | `#0d2a20 14% b2 y1` + `8% b7 y3` |
| `accent`（品牌绿） | 深 | `#3ccfa4` 提亮 .16 / 原色 / 压暗 .10 | 白 45% | 深 30% 绿 55% → 深 45% 绿 75% | `#000 50% b2 y1.5` + `#000 28% b7 y3.5` |
| `accent` | 浅 | `#14a37b` 提亮 .14 / 原色 / 压暗 .08 | 白 40% | 深 25% 绿 45% → 深 40% 绿 55% | `#0d2a20 28% b2 y1` + `12% b7 y3` |
| `glass`（视频上的药丸） | 两套同 | 黑 45% 提亮 .06 | 白 18% | 白 12% → 白 4% | 无 |
| `flat`（禁用） | 跟随主题 | `surfaceHigh` 纯色 | 无 | `line` | 无 |

按下态 `pressed()`：顶部提亮 ×0.3、内高光 ×0.35、填充压暗 5%、接触影 blur ×0.6 / y ×0.4（收紧到身下）、环境影归零；`HipPressable` 同时缩放到 `HipMotion.pressScale = 0.97`，按下 `HipMotion.press = 100 ms easeOut`，松开 `HipMotion.release = 180 ms easeOutCubic`（原为 420 ms 弹簧回弹，去掉回弹以免“弹”而不是“按进去”）。系统“减少动态效果”时不缩放，只保留材质变化。

所有品牌绿按钮已**去掉彩色外发光**（原主按钮 `jade 22–28% blur24 y6`、「开始」`jade 38% blur31 y10` + 径向光晕 + 高光径向渐变）。

## 2. 按钮盘点（位置 / 当前样式 / 计划与实际样式）

| # | 控件 | 位置 | 改前 | 改后 |
|---|---|---|---|---|
| 1 | 首页「开始」`HipStartButton` | 今日页英雄卡右下（深色舞台，两主题同） | 104 圆，上亮渐变 + 外圈径向光晕 + jade 大泛光阴影 + 高光径向渐变，按下缩 0.93 | `accent(HipPalette.dark)` 圆形轻拟物，无光晕/泛光；按下 0.97 + 下沉。仍在自身 `RepaintBoundary` 内，容器展开转场首帧截图不变 |
| 2 | 主 CTA `HipPrimaryButton` | 开始自测、下一项 / 看结果、开始这条路线、引导「没有」、回首页（完成 / 停止） | Material FilledButton 纯 jade + jade 柔光阴影 | `accent` 胶囊（r28，高 56）；禁用为 `flat`；自绘，按下态统一 |
| 3 | 次按钮 `HipSecondaryButton` | 引导安全问答「有」 | OutlinedButton，surface 填充 + line 描边，无投影 | `neutral` 胶囊，文字 w600 |
| 4 | 圆形图标按钮 `HipCircleButton` | 所有 `HipTopBar` 关闭/返回（44）、播放器暂停/继续与跳过（64） | 深色：`surfaceHigh` 平涂；浅色：灰平涂 + 选中块阴影；按下缩 0.9 | `neutral` 圆形；禁用 `flat` |
| 5 | 分段控件选中块 `HipSegmented` | 首页时长 / 场景（独立卡片）、设置语言、外观主题 | 即本次参考样式 | 改为共享 `HipTactile(neutral)`（新增顶边内高光与细描边，阴影收紧）；轨道仍为凹陷色 |
| 6 | 底部 Tab 选中态 | 今日 / 自测 / 进度 | 仅颜色 + 实心图标 + 轻微缩放 | 选中图标下加 56×30 `neutral` 小药丸，淡入；其余不变 |
| 7 | 久坐提醒间隔 45 / 60 分钟 | 进度页「久坐提醒」开启后 | Material ChoiceChip（勾 + 浅绿底） | 小号 `HipSegmented`（高 40）——与其他二选一一致 |
| 8 | 卡片内小按钮 `HipChipButton`（新） | 设置「试听」、首页麻木追问「是 / 否」、阻断卡「重新选择安全提示」、隐私页「复制链接」、读取失败「点一下重试」 | TextButton（纯文字 / 图标 + 文字） | `neutral` 小药丸（视觉高 40，可点区域 ≥ 48），文字 jadeText |
| 9 | 播放器休息时「舒服 / 有点紧 / 疼」 | 训练页休息阶段（深色媒体上） | OutlinedButton 彩色描边胶囊 | `HipChipButton(palette: dark)`，高 48、最小宽 88，彩色文字 |
| 10 | 播放器视频上的「疼」 | 训练页媒体右上 | 黑 45% + 白 12% 描边 + Material InkWell | `glass` 药丸 + 统一按下态（不加投影、不遮视频） |
| 11 | 自测底栏「做的时候疼 · 做不了 · 跳过」、结果页「换一条路线」 | 自测 / 结果页主按钮上方 | TextButton | **保持文字链接**：属于三级动作，且自测单屏布局高度紧（四尺寸单屏回归），做成实体块会和主 CTA 抢层级 |
| 12 | Switch（人声 / 提示音 / 久坐提醒） | 设置 | Material Switch | **保持**：开关是系统惯例控件，非按钮 |
| 13 | 选项卡片（自测选项、身份选择、疼痛类型、我的髋部磁贴） | 自测 / 引导 / 播放器弹层 / 首页 | 卡片 + 选中描边 | **保持卡片**：是内容卡片而非按钮，样式另行评估 |
| 14 | ListTile 行（2 分钟椅边放松、重新看安全提示、隐私政策） | 进度 / 设置 | 列表行 | **保持** |
| 15 | 对话框按钮 | — | App 内没有 `showDialog`/AlertDialog | 无需改；弹层为 bottom sheet 列表 |
| 16 | 左右侧指示（自测「左边/右边」、播放器「右/左」）、媒体角标 | 媒体上 | 状态指示，非按钮 | **保持** |

## 3. 转场（PR #17）

「开始」→ 训练页的容器展开从 `HipStartButton` 内的 `RepaintBoundary` 截图起步；新按钮保留同一结构（`HipPressable > RepaintBoundary > 104×104`），阴影画在边界之外、会被展开裁剪掉，不进截图。新增测试：点「开始」后路由 `originImage` 与点之前该层的像素逐字节比较（平均差 < 1/255），并确认是实心不透明的按钮面。逐帧对比见交付目录 `transition-*`。

## 4. 验证

- `flutter analyze` 0 问题。
- 全量 `flutter test`：178 pass / 1 条件 skip（原 165 + 新增 `test/hip/hip_tactile_test.dart` 13）；四尺寸单屏自测回归（320×568、360×740、390×844、768×1024）包含在全量内通过。
- 更新 1 条旧断言：`hip_ui_round2_test` 原断言选中块是“无描边的 DecoratedBox”，改为断言它是共享 `HipTactile(neutral)` 且圆角同心。
- 截图工具：`test_screens/hip_button_gallery_test.dart`（按钮总览 + 按下态逐帧），沿用 PR #17 的 `FrameCapture` 与 `tools/transitions/render.py`。

```bash
BUTTONS_OUT=test/_shots/buttons/after flutter test --no-pub test_screens/hip_button_gallery_test.dart
python3 tools/transitions/render.py test/_shots/buttons/after/dark   # press-sheet.jpg / press.mp4 / press-slow.mp4
```

## 5. 风险与真机待验

- 渲染开销：每个按钮一次 CustomPaint，阴影 2–8 次 RRect 填充 + 1 次渐变填充 + 2 次描边，无模糊滤镜、无离屏层；按下时 100 ms 内逐帧重绘该按钮。预期低于原来的 BoxShadow 模糊；低端机仍需看列表滚动和播放器倒计时时有无掉帧。
- 测试渲染器与真机抗锯齿不同：1px 内高光与细描边在 1× / 低 DPI 屏可能偏粗或发虚，需在真机 2.75–3× 屏确认。
- 浅色白色 neutral 按钮靠描边 + 投影与背景区分，阳光下对比度需真机确认。
- 未在 Android / iOS 真机、未构建 APK；减少动态效果只做了 widget 测试。

## 6. 前后对比图

- 按钮总览：[深色](images/button-style-audit-2026-10-18/buttons-gallery-dark.jpg) · [浅色](images/button-style-audit-2026-10-18/buttons-gallery-light.jpg)
- 按下态（常态 / 约 110 ms 处）：[深色](images/button-style-audit-2026-10-18/press-states-dark.jpg) · [浅色](images/button-style-audit-2026-10-18/press-states-light.jpg)

整页对比、按下慢放 MP4 和转场逐帧对比体积较大，未入库（由 `test_screens/hip_button_gallery_test.dart`、`hip_shots_test.dart`、`hip_transition_capture_test.dart` 复现）。

## Windows复核修订：共享滑块按压（2026-10-18）

用户已授权修复后直接合并。F2第1轮让分段控件显式持有共享滑块按压/拖动/取消状态，滑块和文字同步缩放；减少动画仅保留材质下沉。材质释放与缩放统一180ms。新增9项回归覆盖正常/减少动画、移出/取消、拖动取消、纵向滚动、键盘选中语义、180ms释放及两个开始入口实际首帧。相关34项通过；组合analyze0、全量191pass/1条件skip（F1新增4、F2新增9），原审核6项现由日常回归覆盖。gallery 45/60模拟区改为小号分段与实际试听按钮，先前深浅2项生成通过。未改依赖、lock、版本或商店配置；后续组合APK与真机检查另记，不将本段当作已安装。

## 主线集成与原生补验（2026-10-18）

原沙盒未安装/待合入结论保留历史。共享分段滑块按压缺陷已首轮修复，正常/减少动画、拖动取消、滚动和键盘回归通过；组合191pass/1skip、analyze0，当前Android原生持按与释放已复查。#17/#18顺序合入main，当前已保留数据安装修复包6dd16ed。原对比图为当时素材，修正gallery后的新图及本轮证据见[修复与合并记录](pr17-pr18-fixes-and-merge-2026-10-18.md)。
