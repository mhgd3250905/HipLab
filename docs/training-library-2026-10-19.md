# 练习库：动作大全 / 单动作练 / 套路随便练 / 自定义训练组（2026-10-19）

分支 `feat/training-library`（PR #22）。#19/#20/#21 已合入 main；2026-10-19 审核后本分支已 merge 对齐 main `243a812`（见 §7），复审后再 merge 同步 main `b12b0f5`（见 §8）。不改依赖、不改 `pubspec.lock`、不改版本号；`pubspec.yaml` 没有改动。

设计稿是 `training-library-design.md`（不在本仓库，位于工作区 `hiplab-library/deliver/`）。本文只记录**实际实现**和与设计稿不一样的地方。

## 0. 开哥拍板（2026-10-19 13:08，覆盖设计稿对应部分）

1. **底栏仍是 3 个 tab：今日 / 练习 / 进度**，不加第 4 个。原「自测」tab 收进练习页顶部的「我的髋部 · 3 分半自测」卡：
   - 未测：显示引导和「▶ 开始自测」。
   - 测过：显示小雷达、上次日期和等级，以及「重测」。
   - 点卡片：从卡片展开出原自测介绍页（`HipAssessmentIntro` 原样保留，加了返回键）。介绍页的「开始自测」从按钮展开进入原自测流程。
   - 点卡片上的胶囊（「开始自测」或「重测」）：从胶囊展开，直接进入自测。
   - 首页「我的髋部」tile 的入口保留不变。
2. **单练默认剂量要有训练量**：
   - 计时类每侧 60 秒，不分侧的就是 60 秒。
   - 计次类每侧 10 次。
   - 保持类、呼吸类按时长处理；带停留（`rep_hold`）也按保持类处理。
   - 组数默认 1，可选 1–3。用户可以微调。
   - 自定义训练组里的步骤沿用动作包 `training.defaults` 的剂量，可调范围：次数 1–2× 默认，秒数 ½–2× 默认（5 秒一档，最少 10 秒），组数 1–3。
   - 剂量的真源仍是动作包，语音按动作包的 cycle 报数，动画只做演示。
3. **单练不计连续天数**，但会记入历史（`source = single`）。套路和自定义训练组完成后照常计入连续天数。
4. **等级 1 选了进阶动作：只提示，照样练**，不自动替换。`t-*` 舞者解锁、`n-slider-lateral` 分数门槛这类进阶门槛也一样处理。

## 1. 基线：本地集成 #19 → #20 → #21

| 步骤 | 处理 |
|---|---|
| `origin/fix/tactile-curation`（#19，`0e4f21f`） | 作为起点 |
| 合入 `origin/feat/themed-action-media`（#20，`eacd8d9`） | 无冲突（提交 `9a1b36e`） |
| 合入 `origin/feat/rep-rhythm-voice`（#21，`318b9ff`） | 3 处冲突（提交 `1fe020e`），见下方说明 |
| `build_action_kits.py build` + `check` | 原 `build` 不会读 #20 的 `action-media.json`，浅色引用一直是 `null`。我在 builder 里补了读取，重新生成后 46/46 有浅色视频，`check` 0 问题 |
| #19 × #20 的语义冲突 | `hip_tactile_budget_test` 期望首页开始圆盘用深色 accent，但 #20 让圆盘跟随舞台主题。断言改为 `accent(stage)`（提交 `3dd3145`） |

#21 合入时的 3 处冲突：

- `hip_player_page.dart`：按 #21 正文处理，位置和行为取 #21，样式取 #19 的描边胶囊（`HipChipButton` 在 #19 中已删除）。
- `docs/development-log.md`、`docs/verification.md`：两边内容都保留。

集成后的基线：analyze 0，**246 pass / 1 条件 skip**。#19/#20/#21 的分支都没有改动，也没有推送。

> （已过时，见 §7：这些修复已随 main `243a812` 进入本分支。）远端还有一个 `codex/pr19-pr21-validation` 分支，是本机 agent 做的组合验证。它比三个 PR 多了几项修复（`e3fb1d3` 媒体封面和路线色、疼痛减时的短次数、`c7def28` 反馈字体、`572d9c0` 封面时间戳检查）。这些修复**不在** #19/#20/#21 分支上，所以本分支**没有包含**。如果它们后续并进 PR，本分支需要 rebase 一次，预计只会在 `hip_player_page.dart` 和 `hip_app.dart` 的开始按钮颜色处有少量文本冲突。

## 2. 实现范围

### 2.1 领域层（`lib/hip/domain/hip_library.dart` 等）

- **动作大全**：`libraryDrills()` 收录内容包中「有视频 + 有动作包」的动作，排除 `n-thomas-test`，共 **45 个**。`w-feet-on-chair-bridge` 保留。
- **`DoseRules`**（剂量规则）：
  - 提供单练默认值、组内默认值、可调范围、`clamp`、换算成 `KitDose`、单组秒数、单侧秒数、步骤秒数，以及紧侧多一组的秒数。
  - 时长类的呼吸、带停留动作，按「在时长内能放下的完整次数」生成 `reps`；多出的时间由动作包的 `stretch` 放慢分配。
  - `doseText()` 输出中英文剂量文案。
- **`custom_routines` v1**：写在 `HipStore.toJson()` 的 `customRoutines` 下，存储键仍是 `hiplab.state.v1`。
  - 只存和动作包默认值不同的字段。
  - 读取时校验：下架或未知的动作丢掉（卡片提示「N 个动作已下架」），剂量 clamp 到范围内，休息秒数不在 {10,15,20,30} 时改成 15，超过 20 步截断，名称截到 12 字，重复 id 和不认识的版本跳过。
  - `copyRoutine()` 按套路原样复制，不固化等级替换。
- **`PlanStep.sets`**；`TrainingPlan` 增加 `source`（recommended / routine / custom / single）、`refId`、`name`。
- **`TrainingPlanner`**：
  - 新增 `singlePlan` / `customPlan` / `routinePlan` / `customSkipped` / `needsEasier` / `lockedOut`。
  - 安全筛查 blocked 时一律返回 `null`。
  - 当周只做放松的方向：非放松动作，单练拒绝，自定义组跳过。
- **`HipStore`**：
  - 新增 `customRoutines` 和 `sessions` 历史，最多 365 条。
  - `completeSession(ladder, plan:)` 遇到单练不写 `doneDays`。
  - `recordLadder(ladder, plan:)` 写一条未完成记录。
  - `recordPain()` 每次点「疼 → 关节夹着疼」都记一条 `PainEvent('pain')`。
  - `recentPainDirections` 统计 7 天内的疼痛方向，`lockedUntil` 仍然只统计 `skip`。
- **`SessionScript`**：
  - `setsOf = sets + 紧侧 1`。
  - 计次类多组时，每组前报「再来一组」。
  - 保持类多组时，每组完整倒数，组间是「慢慢还原 → 5 秒 → 再来一组」。
  - 剂量预告：动作包里有对应文案就用；保持类改用「每侧 + N 秒」的现成音频；没有可用音频就不报，不播缺失的音频条目。
  - 计数超过 10 时只报相位词（数字音频只录到 10）。

### 2.2 界面（`lib/hip/ui/library/`）

| 屏 | 文件 | 要点 |
|---|---|---|
| 练习页 | `practice_page.dart` | 大标题 → 自测卡 → `HipSegmented` 动作 / 套路 / 我的（本页唯一的轻拟物元素就是滑块）。段位和筛选在切换 tab 后保留 |
| 动作大全 | 同上 | 搜索覆盖中文名和英文名；「练哪里」chip；筛选面板（同组「或」，跨组「与」，按钮实时显示数量）；两列海报卡；无结果时提供清除入口 |
| 动作详情 | `drill_detail_page.dart` | 循环视频、要点、标签、单练剂量面板；提示条按优先级：blocked → 锁定（附看放松链接）→ 疼过（附看放松链接），进阶提示另外叠加（附看入门版链接）。「开始练」从按钮展开播放器 |
| 加入训练组 | 同上 | 底部面板列出已有组；第一项「新建训练组」；已满 20 个的组置灰 |
| 套路列表 / 详情 | `practice_page.dart` / `routine_detail_page.dart` | 推荐套路置顶；非舞者在 F 上看到说明；详情用真实 `planFor` 结果和等级适配提示条，点步骤进入动作详情；「复制成我的训练组」会打开编辑器 |
| 我的 | `practice_page.dart` | 「新建训练组」先进挑选，再进编辑器；组卡片带「▶ 开始」色调胶囊，点卡片其他区域进入编辑器；有空状态；开始前若有被跳过的步骤，弹一行确认 |
| 编辑器 | `group_editor_page.dart` | 名称限 12 字；休息时长用分段控件；拖动柄排序（`ReorderableListView`）；左滑删除（`Dismissible`）；点行打开剂量面板（含恢复默认）；未保存关闭时确认「放弃修改？」；可删除组；总时长实时更新 |
| 挑选模式 | 同上 | 多选，允许重复加入同一动作，显示「已在组里」，超过 20 个时禁用并提示 |
| 播放器 | `hip_player_page.dart` | 单练结束页显示「练完了 · 单练记入练习记录，不计连续天数」，按钮为「再来一组」（同剂量从准备阶段重来）和「完成」。疼痛把方向跳过时，只显示「这里今天只做放松」 |
| 今日 | `hip_app.dart` | 有自定义组时，在页面最下方加一行「我的训练组」横滑小卡，点击直接开始；右上角箭头跳到 练习 · 我的 |

样式遵守 `tactile-design-rationale-2026-10-19.md`：

- 主按钮是 `HipPrimaryButton` 纯色平涂。
- 次按钮是 `HipSecondaryButton` 描边。
- 卡片内的操作用色调胶囊或文字链。
- 视频上的角标是黑色 50% 胶囊。
- 预算测试已覆盖练习页三个分段：页面上只有一个 HipTactile，就是分段滑块。

### 2.3 双语

- 新界面文案集中在 `LibText`，包含 zh / en 两张表，按 `Localizations` 选择。
- App 目前固定使用 zh locale，所以界面实际显示中文。英文表是完整的，并有测试确认英文表里没有中文。
- 动作名和要点取自动作包的 `display.{zh,en}`。详情页标题下方小字显示另一种语言的名称。语音本来就是双语。

## 3. 测试

| 命令 | 结果 |
|---|---|
| `flutter analyze --no-pub` | **0 issue** |
| `flutter test --no-pub test` | **286 pass / 1 条件 skip**（集成基线 246 + 新增 40） |
| `python3 tools/action_kits/build_action_kits.py check` | 0 问题（沙盒没有 jsonschema，只做了结构检查） |
| `python3 tools/media/build_themed_media.py check` | ok |
| `python3 -m unittest discover -s tools/tests` | OK |

新增测试：

- `test/hip/hip_library_test.dart`（24 个）：收录规则、单练默认值和范围、组内范围与 clamp、多组时长、v1 序列化往返与读取时校验、持久化、单练不计连续天数、历史上限 365、blocked、锁定、进阶只提示、7 天疼过、多组语音、紧侧加一组、计数超过 10、英文文案。
- `test/hip/hip_library_ui_test.dart`（16 个）：
  - tab 结构；自测卡未测和已测两种状态；介绍页进入自测流程；首页 tile 入口。
  - 搜索；单练剂量和播放器；记录写入历史且不计连续天数。
  - 四类提示条。
  - 新建组完整流程；编辑器剂量面板和放弃修改；复制套路；blocked 时禁用。
  - 320×568 和 360×740 ×1.5 两种尺寸的溢出检查。这项检查发现了一个问题：编辑器行在 ×1.5 字号下溢出 12 px，已修复。

原有测试的调整：入口从「tab-1 直接是自测页」改成 tab-1 → 卡片 → 介绍页（`test/hip/checkup_entry.dart`），涉及 8 个测试文件和 4 个截图脚本；无障碍标签「自测」改为「练习」；轻拟物预算测试加入练习页。其他断言都没有改。

截图：`test_screens/library_shots_test.dart` 生成 12 屏 × 深浅两套（iPhone 15 Pro 393×852，@3x）。

## 4. 偏离设计稿和判断的地方

1. 单练的可调范围按同一规则围绕单练默认值计算：次数 1–20，秒数 30–120。
2. 不分侧的计次动作（包括左右交替）单练默认是 10 次，不是每侧 10 次。
3. 单练不给紧侧多加一组，因为剂量是用户自己选的。自定义组和套路一样，紧侧多一组。
4. 保持类多组时，组间加 5 秒「慢慢还原 → 再来一组」，算进步骤时长。
5. 设计稿里的「新建训练组」是先进编辑器再添加动作；实现改成先进挑选模式，选完再进编辑器，因为空组不能保存。
6. `createdAt` / `updatedAt` 存 ISO 8601。设计稿示例里那种显示用字符串不适合解析。
7. 自测卡上的胶囊直接开始自测，卡片其他区域打开介绍页。在介绍页做完自测后，会自动回到练习页，卡片显示新结果。如果在结果页点「开始训练」，会先关掉介绍页再长出播放器。
8. 首页「我的训练组」放在今日页最下方。这样首屏 Hero、时长、场景和统计卡都不受影响，原有的首页布局测试也不用动。
9. `HipRadar` 新增 `labels` 参数，默认 true，现有用法不受影响。自测卡上 64 pt 的小雷达不显示方向文字。
10. 为了让 #20 合入后的 `build` 真正写入浅色引用，改了 `build_action_kits.py` 约 10 行。逻辑与远端验证分支一致。

## 5. 已知未做

- 进度页的「最近练习」列表：历史数据已经存储，还没有界面。
- 练习页顶部的「现在还麻吗？」卡：目前只有首页有。
- 单练第二次点「疼」后，结束页只提示「这里今天只做放松」，没有同方向放松动作的入口。
- 英文界面没有实际显示，要等 App 引入 locale 切换。
- 自定义剂量如果没有对应的文案音频，预告时不报剂量。计数超过 10 时只报相位词。
- 拖动排序和左滑删除没有写组件测试，交给真机检查。
- 没有构建 APK，也没有在真机或 iOS 上验证。

## 6. 真机检查清单（本机 Windows 安卓 agent）

与 PR 正文相同。

### A. 合入与构建

- [ ] 在 main 上依次合入 #19 → #20 → #21。#21 的冲突按其正文 §6 处理：播放器反馈行位置和行为取 #21，样式取 #19 的描边胶囊；两份 docs 都保留双方内容。
- [ ] 合入 #20 之后，以及合入本 PR 之后，各执行一次 `python3 tools/action_kits/build_action_kits.py build`，再执行 `check`，结果应为 0 问题。
  - 本 PR 修改了 builder，`build` 会把 `assets/hip/action-media.json` 里的浅色视频写进动作包，结果应为 46/46 带 `media.video.light`。
  - 在合入本 PR 之前，浅色引用一直是 `null`。这不影响播放。
- [ ] 把本分支 rebase 到合入三个 PR 之后的 main 上，然后运行 `flutter analyze` 和 `flutter test`。预期结果：analyze 0；测试 286 pass / 1 条件 skip。如果 `codex/pr19-pr21-validation` 的修复已先并入，测试数量会相应增加。
- [ ] 构建 debug APK，**保留数据覆盖安装**，然后核对：
  - 原有的安全提示、身份、自测结果、连续天数、提醒、主题、语音设置都还在。
  - `hiplab.state.v1` 只新增了 `customRoutines` 和 `sessions` 两个字段。

### B. 重点验证（中文语音；关键项再用英文语音过一遍）

1. **底栏**：只有「今日 / 练习 / 进度」三个 tab；左右切换方向正确；练习页「动作 | 套路 | 我的」的滑块按下有下沉感。除了这个滑块和首页「开始」圆盘，没有别的凸起元素。
2. **自测卡**
   - 未测时：点卡片，从卡片展开出原介绍页（6 项列表），再点「开始自测」进入原流程。做完后回到练习页，卡片显示雷达、上次日期和等级。
   - 点「重测」：直接从胶囊展开进入自测。
   - 在结果页点「开始训练」：播放器结束后应回到**练习页**，而不是介绍页。
   - 首页「我的髋部」tile：未测时点它仍然进入自测；已测时点它进入进度页。
3. **动作大全**
   - 共 45 个动作，没有 n-thomas-test。
   - 搜「pigeon」和「鸽」都能搜到。
   - 「练哪里」chip 和筛选面板的数量一致，「重置」有效。
   - 深色和浅色主题下，卡片封面都对应正确的舞台。
4. **动作详情**
   - 视频循环播放，退出详情后视频停止。
   - 默认剂量：保持类每侧 60 秒；计次类每侧 10 次；呼吸类和带停留类为 60 秒。
   - 步进器范围：秒数 30–120，5 秒一档；次数 1–20；组数 1–3。
   - 「开始练」时，播放器从按钮展开。
5. **单练播放**
   - 保持类每侧 60 秒，结尾报 5-4-3-2-1。
   - 2 组时，两组之间依次是「慢慢还原 → 5 秒 → 再来一组」。
   - 计次每侧 10 次，第 10 次报「最后一次」。调到 12 次时，第 11、12 次只报相位词，没有数字，也没有卡顿或错音。
   - 结束页文字为「单练记入练习记录，不计连续天数」：「再来一组」从准备阶段重新开始，「完成」回到详情页。
   - 首页的连续天数**不变**。
6. **疼**
   - 单练中点「疼 → 关节夹着疼」，听到「幅度小一点」。之后打开同方向的非放松动作详情，应出现「这个方向最近疼过」提示，开始按钮仍可用。
   - 7 天内同一方向两次「跳过方向」后：首页出现锁定卡；该方向非放松动作的详情页按钮变为「这周先只做放松」并禁用；点「看放松」后，列表筛选为该方向的放松动作。
   - 「麻、刺」类疼痛：立即停止，行为与之前一致。
7. **安全筛查选「有」**
   - 动作详情：开始按钮显示「先问问医生再来」并禁用。
   - 套路「开始」、我的训练组「▶ 开始」、首页小卡：都禁用。
   - 浏览、编辑训练组、复制套路仍然可用。
8. **等级 1（入门）**
   - 进阶动作的详情页有提示，可点进入门版，「开始练」仍可用。
   - 套路 F 自动换成入门版，并显示提示条。
9. **训练组**
   - 「新建」流程：挑选 2 个以上动作 → 编辑器 → 保存。
   - 拖动柄排序，看与外层滚动是否冲突。
   - 左滑删除。
   - 点行改剂量：范围是 ½–2× 默认，「恢复默认」有效，改过的显示「已调整」。
   - 休息秒数用分段控件切换。
   - 名称最多 12 字，用中文输入法测试。
   - 未保存就关闭时，确认框显示「放弃修改？」。
   - 删除整个组。
   - **杀进程重启**后，数据都还在。
   - 首页最下方出现「我的训练组」横滑小卡，点击后直接开始。
10. **自定义组播放**
    - 组间休息时长与设置一致；紧侧多做一组。
    - 播完后连续天数 +1。
    - 组里含有锁定方向的动作时，开始前提示「髋前侧这周只做放松，跳过 N 个」。
11. **小屏和大字号**：360 宽、系统字号最大，检查练习页三个分段、详情、编辑器、挑选、首页小卡，都不溢出。
12. **主题**：深浅主题来回切换，练习页各屏和详情视频舞台都正确。
13. **后台、锁屏、音乐 ducking、来电打断**：单练和自定义组的表现与以往一致（它们用的是同一个播放器）。
14. **PR #22 审核修复（§7）**
    - 单练结束点「再来一组」：第二轮语音、提示音都在；再结束点「完成」后语音停止。用英文语音再过一遍。
    - 复制套路 F（等级 3、舞者解锁）：编辑器里 h-sumo-pry 显示「3 次 × 停 15 秒」，播放时每次停 15 秒，步骤约 60 秒。
    - 动作详情「加入训练组」：建 12 个组后面板可滚动到最后一个，大字号下不溢出。
    - 有紧侧的自定义组里放一个 1 组的保持动作（如鸽子式）：紧侧听到「慢慢还原 → 5 秒 → 再来一组」；内置套路的紧侧仍是一次连续加长保持。
    - 蝴蝶式 20 秒 × 3 组中点「疼 → 关节夹着疼」：不出现「左边多做一组」。

## 7. PR #22 审核修复（2026-10-19，开哥 15:09「合并审核：需要修改」）

审核固定 head `a7992a6`，目标 main `243a812`。1 项 P1、5 项 P2 全部首轮修复，没有用到第二轮。

### 7.1 对齐 main

`git merge origin/main`（merge commit `144e260`，没有 force、没有改写已推送历史）。7 个冲突文件逐块手工解决：

| 文件 | 处理 |
|---|---|
| `tools/action_kits/build_action_kits.py` | 浅色视频引用 builder 修复两边重复，保留 main 版本；合并后与 main 无差异 |
| `test/hip/hip_tactile_budget_test.dart` | 开始圆盘 accent 断言取 main；练习页三分段的预算用例（自动合并部分）保留 |
| `lib/hip/ui/hip_player_page.dart` | 反馈按钮取 main（c7def28 主题字体、`labelLarge` 14px、语义）；单练结束页（自动合并部分）保留。疼痛短剂量 skip、媒体按钮语义等 main 修复都在非冲突区，原样保留 |
| `lib/hip/ui/hip_app.dart` | `_startPlan` 同时保留本分支的 `radius`（练习库各入口展开半径）和 main 的 `originColor`，缺省色取 main 的 `HipColors.jade`；首页开始圆盘仍传 `stage.jade`（main 开始展开颜色修复）。`StartPlan` typedef 与三个练习库调用改名为 `originColor` |
| `docs/README.md` | main 的 PR #19–#21 审核行与轻拟物行原样保留，本分支练习库行更新后放在前面 |
| `docs/development-log.md`、`docs/verification.md` | main 内容逐字保留（包括原有空行），练习库条目追加在末尾；verification.md 与 main 相同。PR 版 development-log 第 129 行尾部多余空行随之消失 |

封面主题交接、媒体工具 guard（`build_themed_media.py`、`tools/tests`）等其余 main 修复没有冲突，按 main 进入。合并后基线：analyze 0，**294 pass / 1 条件 skip**。

### 7.2 F1–F6

| 项 | 处理 | 提交 | 回归测试 |
|---|---|---|---|
| F1 P1 再来一组第二轮无声 | 不再 `pushReplacement` 新页面；`_restart()` 在同一播放器里重建会话（新 ladder、时钟、engine、queue），音频会话保持打开，只在播放器关闭时 `end()` 一次 | `2f27355` | `hip_library_review_ui_test`「F1 再来一组 restarts in the same player…」：真实路由（详情 → expandFrom 播放器），`NativeLikeOutput` 与 JustAudioVoiceOutput 同语义（begin 已开时 no-op，end 立即关闭，关闭后 speak/chime 丢弃）。断言无 end、第二轮有新语音、丢弃 0、同一 State；完成后 end 恰 1 次 |
| F2 P2 复制 F 丢停留 | `LibraryDose`/`CustomStep` 增 `holdSeconds`（rep_hold）和 `paceSeconds`（套路每侧秒数，即节奏预算）。v1 可选键，缺省 null = 动作包默认，越界 clamp；进编辑器文案、`kitDose`、步骤秒数、语音 repPlan。剂量面板改次数保留停留、丢掉 pace；「恢复默认」两者都清 | `53f7082` | 「F2 copied F: h-sumo-pry hold stays 15 s and the step 60 s」「F2 holdSeconds survives custom_routines v1 round trip…」「F2 changing reps keeps the hold…」「F2 copy F → editor row says 停 15 秒」 |
| F3 P2 加入训练组溢出 | 组列表改为 `Flexible` + shrinkWrap `ListView`（key `add-group-list`），面板最高 80% 屏高。测试还发现剂量面板标题行在 390 ×1.5 的分侧动作上溢出 5.3 px（详情页本身），时长改为可换行 | `2111d6f` | 「F3 12 groups at 390×844 ×1.0 / ×1.5、320×568 ×1.3」：无溢出、滚到第 12 个并加入成功。修复前复现 211 px |
| F4 P2 看放松结果丢失 | 套路详情步骤 await 动作详情并把 `LibraryJump` 继续 pop 给动作大全；入门版改为 push 并转发结果（替换路由会提前用 null 结束等待）；`practice_page` 用 `_applyJump` 统一处理动作卡和套路卡 | `ac449ac` | 「F4 recent extension pain → 套路 A → 站姿弓步 → 看放松…」「F4 recent internalRotation pain → h-9090-liftoff → 侧卧反向蚌式 → 看放松…」 |
| F5 P2 1 组保持紧侧无组间休息 | `PlanStep.extraSet`（自定义组 true）；`extraSetSeconds` 保持类一律 + 5 秒；`SessionScript.holdSetsOf` 按本侧实际组数分组。内置套路 `extraSet=false`，紧侧仍是连续加长保持（原 D-01 行为） | `8783f7e` | 「F5 custom 鸽子式 35 s × 1 + tight set: 40 s extra, 2 sets…」「F5 extra-set budget…」「F5 built-in routine keeps the continuous longer hold…」 |
| F6 P2 不分侧误报左侧加练 | `SessionScript.tightSide` 检查真实 `extraSide` 与当前侧；「多做一组」只在紧侧、只在第一组说 | `8783f7e` | 「F6 蝴蝶式 20 s × 3, pain halved to 35 s…」「F6 normal multi-set sided hold…」 |

测试提交 `a38190f`：`test/hip/hip_library_review_test.dart`（9）+ `test/hip/hip_library_review_ui_test.dart`（7）。在合并后、修复前的代码上运行：领域测试因缺少新字段编译失败，UI 7 项全部失败（F1 同一 State 断言失败、F2 找不到「3 次 × 停 15 秒」、F3 211/485/651 px 溢出、F4 两条筛选数量对不上），与审核复现一致。

### 7.3 最终验证（冲突解决后的最终代码，Flutter 3.44.7 / Dart 3.12.2，沙盒 Linux）

| 命令 | 结果 |
|---|---|
| `flutter pub get --enforce-lockfile` | 通过，依赖与 lock 未变 |
| `flutter analyze --no-pub` | 0 issue |
| `flutter test --no-pub --concurrency=1 test` | **310 pass / 1 条件 skip**（合并基线 294 + 新增 16） |
| `python3 tools/action_kits/build_action_kits.py check` | 0 problem（沙盒无 jsonschema，只做结构检查） |
| `python3 tools/media/build_themed_media.py check` | check ok |
| `python3 -m unittest discover -s tools/tests` | 19 pass |
| `git diff --check origin/main HEAD` | 无输出 |

`pubspec.yaml`、`pubspec.lock`、版本号与 main 相同。

### 7.4 仍需本机

- 没有构建 APK，没有上真机，没有原生听音，没有 iOS。
- Android 原生复查：§6 清单第 14 条，重点是「再来一组」第二轮的真实 just_audio 输出（中英），以及来电/锁屏后再来一组。
- 保留数据升级：用 main 当前已装版本覆盖安装本分支，`hiplab.state.v1` 原有键逐字节不变，只新增 `customRoutines`、`sessions`；建一个复制 F 的组后杀进程重启，`holdSeconds`/`paceSeconds` 仍在。

## 8. PR #22 复审 F7 修复与同步 main（2026-10-19，复审固定 head `f7271f6`）

复审确认 F1–F6 已关闭，新增 F7 / P2；本轮首轮修复，没有用到第二轮。

### 8.1 F7：多组计次动作疼痛减半时保护与脚本组数不一致

- 问题：`hip_player_page.dart` 疼痛减半的短次数保护把组数写死为正常侧 1 / 紧侧 2，没算 `PlanStep.sets`；`SessionScript` 实际按 `sets + 紧侧额外 1 组` 排次数。单练 `h-squat` 1 次 × 3 组 → 疼 → 关节夹着疼：减半 8 秒，保护按 1 组得 1 次不跳过，脚本按 3 组每组 0 次，cues 为空却仍显示 8 秒倒计时。
- 修法：组数规则抽到 `PlanStep`，三处共用。
  - `PlanStep.tightOn(side)`：只有真实 `extraSide` 且是当前侧才算紧侧（F6 规则）。
  - `PlanStep.countedSetsOn(side)` = `sets + 紧侧 1`（计次；内置套路 sets=1，紧侧仍 2，旧行为不变）。
  - `PlanStep.holdSetsOn(side)` = `sets + (extraSet 且紧侧 ? 1 : 0)`（保持；内置套路仍连续加长，F5 规则）。
  - `SessionScript.setsOf / holdSetsOf / tightSide` 改为委托上面三个函数；新增 `SessionScript.noFullRep(step, kit)`：任一侧按 `countedSetsOn` 放不下完整一次即为真。播放器疼痛减半只调用它，命中就 `skip` 当前动作并报「跳过」。
- 提交：`ba0919d`（实现 + 回归测试）。

### 8.2 回归测试（12 个）

`test/hip/hip_player_multiset_pain_test.dart`（播放器 widget，真实 `HipPlayerPage`，跳过准备 → 疼 → 关节夹着疼）：

| 测试 | 断言 |
|---|---|
| F7 单练 h-squat 1 次 × 2 组 (unsided) … reaches the end page | 无倒计时环，进入「练完了」结束页，有「再来一组」 |
| F7 单练 h-squat 1 次 × 3 组 (unsided) … reaches the end page | 复审原复现，同上 |
| F7 group h-squat 1 次 × 3 组 → skip, rest + feedback, then the next step runs | 进入 2/2 休息，倒计时在走，「舒服」反馈记录，休息结束后下一步正常开始 |
| F7 sided glute-max-A 1 次 × 2 组 (no tight side) → … | 分侧，同上 |
| F7 sided glute-max-A 1 次 × 3 组, left tight (+1 组) → … | 紧侧额外组，同上 |
| F7 control: h-squat 4 次 × 2 组 … not skipped | 减半后每组仍放得下一次：不跳过，继续减半倒计时 |

修复前（`f7271f6` 的实现 + 本测试文件）运行：**5 fail / 1 pass**（对照用例通过）。两个单练用例失败于「Expected: no matching candidates / Found 1 widget with key player-ring」——即仍显示减半倒计时、没进结束页；三个训练组用例失败于找不到「2/2」——没跳到下一步休息。修复后 6 项全部通过。

`test/hip/hip_pain_multiset_sets_test.dart`（领域 / 脚本，依赖新函数，修复前无法编译）：不分侧 2 / 3 组、分侧 2 组、紧侧 3 组（右 3 / 左 4，与每个 work 相位的 `setsOf` 一致）、内置套路紧侧仍 1 → 2 组，以及「保护 ≡ 脚本」：h-squat、glute-max-A × 次数 1–6 × 组数 1–3 × 紧侧（无 / 左 / 右）减半后，`noFullRep` 为真当且仅当脚本有某个 work 相位 cues 为空，且两种结果都出现过。

### 8.3 同步 main `b12b0f5`

`git merge origin/main`（merge commit `b4db041`，不 force），只有 `docs/README.md`、`docs/development-log.md` 两处冲突，均为文档：main 原文一字不改放前面（PR #22 修复复审入口行；首轮审核、评论发布、修复复审三段历史），本分支的练习库入口行与两段实现/修复记录追加在后，入口行更新为含 F7、已同步 `b12b0f5`。`AGENTS.md`、`docs/current-state.md`、`development-roadmap.md`、`development-workflow.md`、`verification.md`、两份 PR #22 审核报告（含本机非 C 盘工作副本规则）按 main 进入，与 main 无差异；`git diff --numstat origin/main -- docs AGENTS.md` 无删除行。

### 8.4 最终验证（最终代码，Flutter 3.44.7 / Dart 3.12.2，沙盒 Linux）

| 命令 | 结果 |
|---|---|
| `flutter pub get --enforce-lockfile` | 通过，依赖与 lock 未变 |
| `flutter analyze --no-pub` | 0 issue |
| `flutter test --no-pub --concurrency=1` 全部 38 个测试文件 | **322 pass / 1 条件 skip**（310 + 新增 12）。沙盒单条命令 120 秒上限，按文件名排序分两批跑（158 + 164/1 skip） |
| `python3 tools/action_kits/build_action_kits.py check` | 0 problem（沙盒无 jsonschema，只做结构检查） |
| `python3 tools/media/build_themed_media.py check` | check ok |
| `python3 -m unittest discover -s tools/tests` | 19 pass |
| `git diff --check origin/main HEAD` | 无输出 |

`pubspec.yaml`、`pubspec.lock`、版本号与 main 相同；未合并 main。

### 8.5 仍需本机

仍未构建 APK、未上真机、未做 iOS。§7.4 的 Android 原生听音、重复单练（再来一组）、中断/锁屏、保留数据升级仍由本机补；另建议真机过一遍 F7 复现（单练深蹲 1 次 × 3 组 → 疼 → 关节夹着疼 → 应直接到结束页、报「跳过」）。

## 9. PR #22 Web 补充验收 F8 / P3 修复与同步 main（2026-10-19，验收固定 head `9fa0cc0`）

验收报告：[pr22-web-acceptance-2026-10-19.md](pr22-web-acceptance-2026-10-19.md)（main `fcffded`）与 [PR 评论](https://github.com/mhgd3250905/HipLab/pull/22#issuecomment-6266421023)。

### 9.1 F8 / P2：左删未结束时编辑下一动作，覆盖其他动作

根因：`GroupEditorPage._editDose(int index)` 在 `await showLibSheet` 前取了行号，面板返回后仍按原行号写回 `_steps[index]`。左滑删除的 `onDismissed` 在滑出 + 收起动画结束才触发；若前项删除在面板打开期间完成，后面各项行号前移一位，写回就落到下一个动作上，还复用了被编辑动作的 key（A、B、C → 删 A、编辑 B → `[B 默认, B 2 组]`，C 丢失；重复 key 也解释了保存前有时只渲染一行）。行号越界时（多个待完成删除）直接 RangeError，编辑丢失。

修法（`d352552`，只改 `lib/hip/ui/library/group_editor_page.dart`）：每步已有的稳定 key 贯穿到底——行的 onTap 传 key，`_editDose(int key)` 打开前、面板返回后都用 `_indexOf(key)` 重新定位，已删除（-1）则不写回；`onDismissed` 改为按 key `removeWhere`，不再依赖构建时的行号。拖动排序的 `ReorderableDragStartListener` 仍用当前行号（它本来就是每帧重建的位置）。

回归：`test/hip/hip_editor_race_test.dart`（5 个，真实界面手势：`tester.drag` 左滑、点行、剂量面板「组数 +」、完成、保存；按 100 ms 逐帧推进让删除动画真正走完，并断言面板标题与面板打开期间的行数）：

| 用例 | 修复前（`6306214`） | 修复后 |
|---|---|---|
| F8 delete A, tap B 150 ms later, A finishes, B → 2 组: saves [B(2), C] | **fail**：Actual `[(h-adductor-rock,1),(h-adductor-rock,2)]`（与验收复现一致） | pass |
| F8 two pending deletes (A and B), edit C: saves [C(2)] | **fail**：`RangeError … Only valid value is 0: 2`，C 编辑丢失 | pass |
| F8 two pending deletes (A and C) around the edited B in four steps: saves [B(2), D] | **fail**：Actual `[(B,1),(B,2)]`，D 被覆盖 | pass |
| F8 the sheet target is deleted while the sheet is open: nothing is written back, saves [A, C] | **fail**：Actual `[A, (B,2)]`，C 被已删的 B 覆盖 | pass |
| F8 reorder (A to the end) then edit A: saves [B, C, A(2)] | pass（护栏：排序后编辑原本就对） | pass |

修复前合计 **4 fail / 1 pass**。

### 9.2 P3：360 宽、TextScaler 2.0 深浅主题下练习页关键文字截断

修法（`f366276`）：新增 `libLargeText(context)`（系统字号 ≥1.6×）。大字号下：自测卡「开始自测 / 重测」移到文字下方，「我的髋部 / 3 分半自测 / 说明」占满卡宽；动作大全改一行一张卡，名称与剂量完整换行；套路卡名称独占一行，「为你推荐」和分钟数放下一行；训练组卡「开始」移到文字下方；搜索框用短提示「搜动作」并允许增高。所有字号下自测卡标题/说明、套路卡名称/副标题、训练组名称/副标题/来源都改为换行而不是省略号。1× 和 1.5× 的原布局不变（原有 ×1.3/×1.5 测试全部通过）。

回归：`test/hip/hip_practice_large_text_test.dart`（8 个：浅/深 × 未自测/已自测 × 〔自测卡；动作/套路/我的三段从上滚到底〕，360×780、textScaleFactor 2.0、HipThemeChoice 显式设为浅/深）：检查无溢出异常、练习列表里所有文字 `RenderParagraph.didExceedMaxLines == false`、自测卡含「3 分半自测」且按钮整个在卡内。修复前 **0 pass / 8 fail**（例：自测卡「我的髋部」「3 分半自测」被截、搜索提示、动作名、套路副标题等）。另用 Noto Sans SC 渲染 12 张截图人工看过（沙盒工作区，未入库）。筛选行的方向 chip 是横向滚动列表，末尾半个 chip 是滚动提示，不属于截断。

### 9.3 不在本 PR 范围：Web 语音内容异常

验收发现 Web 播放循环初始口令；独立 main 基线也复现，属既有 Web 兼容问题，本 PR 不修，不据 Web `playing` 事件宣称语音通过。

### 9.4 同步 main `fcffded`

`git merge origin/main`（merge commit `c0af7f0`，不 force）。冲突仅 `docs/README.md`、`docs/development-log.md`：README 表头部取 main 的两行（Web 补充验收、更新后的修复复审）原文，本分支的练习库入口行接在后面（本轮更新为含 F8/P3）；development-log 本分支三段（实现、F1–F6、F7）在前、main 两段（Android 验收准备、Web 代验与新增 F8）在后，均原文保留。按行比对 main 版本这两个文件，main 的每一行都在合并结果中（无删改）。

### 9.5 最终验证（最终代码，Flutter 3.44.7 / Dart 3.12.2，沙盒 Linux）

| 命令 | 结果 |
|---|---|
| `flutter pub get --enforce-lockfile` | 通过，依赖与 lock 未变 |
| `flutter analyze --no-pub` | 0 issue |
| `flutter test --no-pub` 全部 40 个测试文件，分 4 批 | **335 pass / 1 条件 skip**（322 + 新增 13）：68 + 88 + 74 + 105/1 skip |
| `python3 tools/action_kits/build_action_kits.py check` | 0 problem（沙盒无 jsonschema，只做结构检查） |
| `python3 tools/media/build_themed_media.py check` | check ok |
| `python3 -m unittest discover -s tools/tests` | 19 pass |
| `git diff --check origin/main HEAD` | 无输出 |

`pubspec.yaml`、`pubspec.lock`、版本号与 main 相同；未合并 main。仍未构建 APK、未上真机、未做 iOS；建议真机补一遍 F8 复现手势和系统最大字号下的练习页。

## 10. PR #22 F9 与搜索框键盘（2026-10-19，复测固定 head `2cc40e3`）

来源：[PR #22 真机复测评论](https://github.com/mhgd3250905/HipLab/pull/22#issuecomment-6268054160)、main 上 [pr22-native-retest-2026-10-19.md](pr22-native-retest-2026-10-19.md) 的 F9 段；用户新报 Android 真机「练习页搜索框点了有光标、不弹键盘」。

### 10.1 F9 / P2：左删后动画内立即保存，被删项重开后仍在

根因：`GroupEditorPage._save` 直接保存 `_current`（由 `_steps` 生成），而左滑删除要等 `Dismissible.onDismissed` 才从 `_steps` 移除。onDismissed 在「滑出 200 ms + 收起 300 ms」都结束后才触发；在这之前点保存，写入的是旧列表。离开页的放弃判断 `_dirty` 读的也是旧列表，所以删除后立即返回不会提示、删除丢失；只剩 1 项时左删再立即保存，会把这 1 项照样存回去。

修法（`7018fcb`，只改 `lib/hip/ui/library/group_editor_page.dart`）：
- `confirmDismiss` 触发（滑出结束、确认删除）时把该稳定 key 记入 `_deleting`；`_live` = `_steps` 去掉 `_deleting`。保存内容、`_dirty`、步骤数文案、底部摘要、保存按钮是否可用（0 项禁用）、「添加动作」上限、挑选页「已在组里」、剂量面板打开前和写回前，都只读 `_live`。`onDismissed` 再从 `_steps` 真正移除并清掉 `_deleting`；列表行数与 Dismissible 生命周期不变，不会重复删除，也不会 RangeError。
- 松手已过阈值、但还在滑出的 ≤200 ms 内，确认尚未发生。为此用 `onUpdate` 记录正在滑动的行（progress>0），保存 / 关闭（含系统返回）先等这些行要么确认删除、要么弹回，再读列表；最多等 800 ms（手指一直按住不放时按未删处理）。同一时间只处理一次保存或关闭，等待期间重复点按会被忽略。
- 与 F8 的稳定 key 修法兼容：`_indexOf(key)` 不变，待删 key 的剂量面板不再打开、也不写回。

回归：`test/hip/hip_editor_pending_save_test.dart`（8 个，真实 `tester.drag` 左滑，在动画结束前操作；“重开”用同一存储新建 `HipStore` 读回，主用例另在界面重开编辑器数行）。

| 用例 | 修复前（`2cc40e3` 的 lib + 本测试） | 修复后 |
|---|---|---|
| F9 delete the first step, save 150 ms later: reopened group has [B, C] | **fail**：Actual `[A, B, C]` | pass |
| F9 delete the first step, save in the very next frame: saves [B, C] | **fail**：Actual `[A, B, C]` | pass |
| F9 delete two steps back to back, save at once: saves [C] | **fail**：Actual `[A, B, C]` | pass |
| F9 delete then close at once: asks to discard; discard keeps the stored [A, B, C] | **fail**：没有放弃提示，直接离开 | pass |
| F9 delete then system back at once: asks; keep editing, then save: saves [B, C] | **fail**：没有放弃提示 | pass |
| F9 delete the only step, save at once: same as after the animation (nothing saved, editor stays, save disabled) | **fail**：保存并离开了编辑器 | pass |
| F9 control: delete, wait for the animation, save: [B, C] | pass（对照） | pass |
| F9 a swipe that snaps back (under the threshold) is not a delete: save right after keeps [A, B, C] | pass（护栏） | pass |

修复前 **6 fail / 2 pass**（测试先提交为 `6b4b101`）。F8 的 5 个回归在修复后照常通过。

### 10.2 练习页搜索框：有光标、不弹软键盘（Android 真机）

结论：**在 Flutter 这一侧没有找到原因，组件测试复现不了；只能真机确认。** 本轮没有改产品代码，只加了键盘契约回归测试。

排查过的点：
- 上一轮 P3（`f366276`）对 `LibSearchField` 只改了容器：`height: 44` → `minHeight: 44`、上下各 6 的内边距、大字号用短提示「搜动作」。`TextField` 本身没动：`maxLines` 仍为默认 1，没有设 `minLines` / `keyboardType`（仍是 text）/ `readOnly` / `showCursor`。
- 没有外层 `GestureDetector` / `InkWell` / `Listener` 抢点按；全仓库 `lib/` 没有 `unfocus`、`FocusManager`、`TextInput.hide`、`SystemChannels.textInput`；练习页 `ListView` 没设 `keyboardDismissBehavior`；`TextField` 没传 `focusNode`，用的是自己 State 里的节点，不会每次 build 重建。底栏 tab 切换器给每个 tab 包了 `FocusScope(canRequestFocus: 当前 tab)`，当前 tab 可获取焦点。
- main 上没有任何 `TextField`（练习库是本 PR 新增），没有可对比的 main 搜索框；这也是本 App 第一次有文字输入。
- 组件测试（Flutter 3.44.7，Android 目标平台）：点按后 `TextInput.setClient` → `TextInput.show` 按序发出，`hasAnyClients` / `isVisible` 为真；键盘 inset 逐步升到 320 后连接仍在；收起键盘后再点会再次 show；切到别的 tab 再回来、从动作详情页返回后点按都会 show；能输入并过滤。1× 与 2.0 字号都一样；把 lib 换回 P3 之前（`f366276^`）结果相同，排除 P3。

由此推断：Flutter 已经发出 `TextInput.show`，键盘没出来发生在 Android 侧（引擎 `TextInputPlugin` → `InputMethodManager.showSoftInput`）。按可能性排序，需要真机区分：
1. **系统认为接了实体键盘**：Android 默认在有实体键盘时不弹软键盘，表现正好是「有光标、无键盘」。本轮复测通过 ADB/投屏控制手机，scrcpy 的 UHID 键盘或蓝牙键盘都会被当作实体键盘。查 `adb shell dumpsys input_method | grep -iE "mInputShown|mShowRequested|hardKeyboard"`、`adb shell settings get secure show_ime_with_hard_keyboard`，以及 `dumpsys input` 里的键盘设备；断开投屏/键盘或打开「显示虚拟键盘」再试。
2. **WebView 平台视图拿走了 Android 焦点**：动作详情页的示范视频是 webview_flutter 平台视图，上游有未关闭的同类问题（[flutter#156659](https://github.com/flutter/flutter/issues/156659)：点过 WebView 后，Flutter 输入框仍有光标但键盘不工作）。分别在冷启动后直接点搜索框、和打开过动作详情（视频播放）返回后点搜索框，各试一次；只有后者复现就是这一条。
3. 以上都排除时，抓 `adb logcat -s InputMethodManager:* ImeTracker:* TextInputPlugin:*`，看 show 请求是否到达、被谁拒绝。

回归：`test/hip/hip_search_keyboard_test.dart`（6 个）：`search ×1.0` / `search ×2.0` 各两例（点按弹键盘 + inset 后保持 + 输入过滤；收起后再点再弹），`search: leave for another tab and come back…`，`添加动作 picker search ×2.0…`。这些在修复前后都通过，锁的是 Flutter 侧契约，不等于真机键盘已验证。

### 10.3 同步 main `76ff846`

`git merge origin/main`（merge commit `0d2c625`，不 force）。冲突只有 `docs/development-log.md`：本分支的 F8/P3 段与 main 的 PR #24 审核、PR #22 真机复测、组合验证三段都保留，main 原文未改。其余 main 文档（AGENTS.md、README、current-state、roadmap、verification、version-ledger 及三份新审核文档）自动合入。

### 10.4 最终验证（最终代码，Flutter 3.44.7 / Dart 3.12.2，沙盒 Linux）

| 命令 | 结果 |
|---|---|
| `flutter pub get --enforce-lockfile` | 通过，依赖与 lock 未变 |
| `flutter analyze --no-pub` | 0 issue |
| `flutter test --no-pub` 全部 42 个测试文件，分批 | **349 pass / 1 条件 skip**（335 + 新增 14）：61 + 59 + 51 + 8 + 50 + 49 + 71/1 skip |
| `python3 tools/action_kits/build_action_kits.py check` | 0 problem（沙盒无 jsonschema，只做结构检查） |
| `python3 tools/media/build_themed_media.py check` | check ok |
| `python3 -m unittest discover -s tools/tests` | 19 pass |
| `git diff --check origin/main HEAD` | 无输出 |

`pubspec.yaml`、`pubspec.lock`、版本号与 main 相同；未合并 main。**未构建 APK，未上真机，未做 iOS。**

### 10.5 本机 Android 复测点

- F9：至少两项的训练组，左滑删首项，150 ms 内点保存，回列表重开，应不含被删项；连删两项后立即保存；删除后立即点关闭 / 系统返回，应出现「放弃修改？」；只剩 1 项时删掉立即点保存，应停在编辑器、保存按钮置灰、存储不变。
- 搜索框：冷启动进练习页点搜索框，键盘应弹出并能输入过滤；再从动作详情页（视频播放过）返回后点一次；系统最大字号下各一次。不弹时按 10.2 的三步取证（先确认没有实体/投屏键盘）。
