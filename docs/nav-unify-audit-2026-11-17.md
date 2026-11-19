# HipLab 顶栏与转场逐页核对

这是 2026-11-17 的候选审计。相关改动随后随 2077 合入主线，以下逐页结论按当时的源码和测试保留。[当前状态](current-state.md)

基线为 `origin/main@60b16181e9d0002b9a8f44404db728df74fb5bef`，候选分支为 `feat/nav-unify`。页面来源、返回去向和边界按该版本实际入口核对。[UI 设计规范](ui-design-standard.md#1-顶部导航栏hipnavbar) · [导航实现手册](ui-kit/02-navigation.md)

本轮的无模糊要求用于顶栏背景遮罩。共用返回胶囊延用规范 §1.3 的独立材质，标题、遮罩、右操作及底栏均属于滑动表面。以下的「穿透」表示视口从 y=0 开始，首屏正文跳过安全区、标题区和 24pt 过渡段，滚动内容随后可以经过遮罩。固定正文模式由 `HipNavPage` 一次性预留全段；标题保持静止时正文的第一行在遮罩下方。共用布局会处理横向安全区和无固定底栏时的底部安全区。

## HipLab 宿主页

| 页面 | 来源 → 返回 | 首屏、滚动及安全区 | 改前问题 → 当前处理 |
|---|---|---|---|
| 启动中、读取失败 | App 启动；失败时原地重试 → 首页 | 根 `Scaffold`；空屏或居中重试，无正文滚动 | 根页面没有导航顶栏 |
| 首页 | 启动 → 根页面，无返回胶囊 | `Scaffold`、页面背景和 `SafeArea` 包住页面滚动；动作卡展开由页内状态控制 | 根页面保留现有头部；其目的页以来源无胶囊处理 |
| 更多 | 首页 dock → 首页 | `HipNavPage` 单标题，列表穿透，首屏 `hipNavInset + 12` | 原有 `content(pinLeading: false)` 正确；改用共用遮罩 |
| 训练记录 | 首页打卡徽章或更多 → 对应来源页 | 单标题穿透；共享 `HipRecordsView`，有/无记录皆由同一滚动容器承载 | 首页胶囊跟随目的页，从更多进入固定；改用共用遮罩 |
| 全部训练 | 训练记录「最近训练 → 全部」，有记录才显示 → 训练记录 | 单标题穿透，列表首屏 `hipNavInset + 4` | 已为 `content`，保留固定胶囊 |
| 设置 | 更多或 SDK Coach 设置 → 对应来源页 | 单标题穿透，提醒、口令、显示设置和其它同列表滚动 | SDK 来源不参与共用胶囊的接力，目的页返回键随页滑动；从更多固定 |
| 隐私政策 | 设置、会员法律链接或 AI 同意弹层 → 对应页面或原弹层 | 单标题穿透，正文随列表滚动 | 设置及会员来源使用固定胶囊；同意弹层来源显式随页，弹层及同意状态继续保留 |
| 动作库 | 更多、SDK Coach、按方向查看放松动作 → 对应来源页 | 单标题穿透；搜索、计数、卡片随同一列表滚动，首屏 `hipNavInset + 4` | SDK 来源的胶囊随页，其余宿主来源固定。基线通常由 SDK 弹层显示动作详细内容 |
| 训练组 | 更多、首页文件夹「训练组选择」、SDK Coach「计划」→ 对应来源页 | 单标题且正文不穿透；「我的／推荐套路」分段及内容独立于顶栏，SDK 来源可有右侧操作 | 首页文件夹先关闭再打开训练组，补 `pinLeading: false`；SDK 来源也随页，计划入口的右侧长文案改为 44×44 图标，保留提示和语义标签；从更多固定 |
| 推荐套路详情 | 训练组「推荐套路」 → 同一分段 | 双标题穿透，首屏 `hipNavInset(hasSubtitle: true) + 4`；底部开练区处理底部安全区 | 继续用 `content`；返回、标题、右操作与整页滑动分层 |
| 已保存组只读详情 | 非会员在「我的」打开已保存组 → 「我的」 | 双标题穿透，首屏 `hipNavInset(hasSubtitle: true) + 12`；删除操作在右侧，开始操作在底部。记录已移除时为空壳单标题 | 原来列表截止在固定标题下 → 列表滚动到共用遮罩下方 |
| 组编辑／新组 | 已保存组、推荐套路复制、动作详情加到新组、添加动作选择器返回后、SDK Coach 新建入口 → 实际调用页 | 单标题固定正文模式；名称及休息设置在固定区，动作区独立滚动，底栏负责下方安全区 | 使用同一固定胶囊；从 SDK 来源随页。点击关闭及 Android 系统返回走原 `_close` 及未保存确认；编辑器的 `PopScope(canPop: false)` 不启动 iOS 交互式侧滑，避免跳过退出确认 |
| 添加动作选择器 | 训练组新建、会员权益新建、编辑组加动作 → 调用页，确认返回所选项 | 双标题穿透，首屏按 52pt 标题区留白，搜索和卡片滚动，底栏单独处理安全区 | 源和目的共享 44pt 锚点；取消返回空结果，不改已选项处理 |
| 本地动作详情（SDK 配置缺失时的回退） | 动作库、推荐套路、SDK Coach 或另一个动作「看入门版」→ 原列表或详情；「看放松」返回原列表并应用方向 | 双标题穿透，`hipNavInset(hasSubtitle: true) + 4`；媒体及动作内容在列表内，底栏保留 | 动作库回退详情原来扩张入场 → 改用水平 `content`；SDK 来源使用随页胶囊，其余固定 |
| 自测说明 | 更多「髋部自测」→ 更多 | `HipAssessmentIntro` 单标题穿透，首屏 `hipNavInset + 12`；开始／重测在固定 `LibFooter` | 共用顶栏延用；开始按钮容器展开属于自测流程 |
| 沉浸式自测题目 | 自测说明「开始／重测」，或首页复测入口 → 自测说明或首页 | 原 `SafeArea`、独立 `HipTopBar` 48pt 控制轨及 8pt 外留白，复用 `HipNavBackChip`。每题单屏，无跨题纵向滚动 | 按 §1.4 保留关闭／进度和原题目状态；使用按钮容器扩张／无布局来源时上升 |
| 自测结果 | 题目完成后原路由内切换 → 原入口；开始推荐训练后由现有回调确定返回页 | `HipNavPage` 双标题穿透，固定底部操作自带安全区 | 非额外 push；保留结果、路线选择和开练状态机 |
| 会员／购买页 | 更多、Coach 会员提示、组与动作的会员门禁 → 实际调用页 | 单标题穿透，购买和已订阅各自滚动；商店操作与法律链接仍在固定底栏，底栏负责安全区 | 原来 `content` 无滑动表面，右上另画关闭 → 接入 `HipNavPage`，左侧共用关闭；交易成功仍由原 `_transact` 和当前路由检查触发退出。系统购买、恢复与订阅管理行为保留 |
| Coach 加载、失败、权益或同意阻断 | 训练组或会员权益进入 Coach → 对应来源页 | HipLab 固定正文模式；失败或加载正文在居中的可滚动容器内 | 共用遮罩和返回胶囊。切到 SDK 已就绪页面时，同一路由继续驱动页面表面 |

基线的当前生产入口没有独立的首启引导或安全提示复审页；安全业务提示实际出现在首页提示卡、自测问题、动作提示与训练反馈中。

## 弹层、页内状态及 SDK 边界

| 页面或弹层 | 来源 → 返回 | 组件与安全区 |
|---|---|---|
| 首页推荐训练组文件夹 | 首页文件夹 → 首页；「训练组选择」会先关闭弹层 | 自绘 `PopupRoute`，锚定来源按钮，按可用屏幕范围布局；小视口需要时滚动内容 |
| 首页动作卡展开及里程碑庆祝 | 首页动作卡、训练记录徽章 → 原页面 | 原页面内状态；动作卡的本地历史先收起卡片。没有额外顶栏或 push |
| 动作筛选 | 动作库或加动作 → 原列表 | Material 底部弹层，`showLibSheet` 处理底部安全区和键盘 |
| 添加到训练组、训练剂量、编辑组容量提示 | 本地动作详情或组编辑 → 调用页 | `showLibSheet`；长列表在弹层内滚动 |
| 自测结果「换一条路线」 | 自测结果 → 自测结果或所选训练 | `showLibSheet`，候选路线在弹层内滚动 |
| 放弃编辑、删组、跳过不适方向 | 组编辑、组详情或开练入口 → 原入口或确认后的目标 | `showHipConfirmDialog` 居中弹窗；取消不会切换页面 |
| AI 同意 | 首次进入 Coach 或 Coach 再授权 → 原入口／Coach | Material 底部弹层，安全区内独立滚动；正文链接打开隐私页时保留弹层 |
| 训练不适选项 | SDK 训练中的 HipLab 反馈回调 → 训练或现有安全中止分支 | Material 底部弹层带 `SafeArea`；不替换训练的返回与终止控制 |
| 系统键盘、商店购买页、订阅管理、外部条款 | 搜索、编辑、购买或法律链接 → 原页面 | 系统或外部应用处理。App 保留已有的键盘避让与购买回执检查 |
| SDK 动作详情 | 动作库、套路动作、自测示范或 Coach → 实际入口／单动作训练 | `TrainingLibraryDetails` 管理媒体和原生底部弹层，内部 `SafeArea` 和滚动。正常有 SDK 配置时优先用此入口 |
| SDK Coach 会话及计划面板 | Coach 壳就绪 → 训练组或会员；面板开闭留在会话 | `CoachChatPage` 自有返回与安全区；HipLab 仅为整个 SDK 页面接上当前 `content` 路由的滑动。面板不算额外路由 |
| SDK Coach 计划详情 | 会话中的计划卡，或训练组已保存的 AI 计划 → 实际入口 | SDK 自绘标题、正文及安全区。会话入口由 SDK 自己 push，宿主入口补整页 `HipRoute.push` |
| SDK 训练播放器、退出确认和训练总结 | 首页／历史空态、自测、动作、组、Coach 的开练 → 实际入口，或自测现有回调指定的返回页 | `TrainerLauncher` 和 SDK 训练壳管理进退、固定头部、安全区、媒体及结束状态，HipLab 保持业务回调边界 |

## 规范差异与验收口径

- 本轮要求纯渐变常驻，因此 §1.2 和复用手册 §3 取消全顶栏背景模糊。固定正文同样按完整遮罩留白（旧 §1.4 为 `fade = 0`）。采样只保留在返回胶囊内部。
- 恢复共享胶囊的 44pt 圆面、32pt 字形、2pt 描边和标题 17pt/w600。单双标题的左右控制轨均为 44pt，双标题区为 52pt。Coach「计划」的新建操作也收进 44pt 控制轨。
- 标准页进入 400ms、返回 340ms，使用原 `HipMotion` 曲线。下一层最多偏移 .28 屏宽，浅色／深色遮暗分别为 .14／.32。返回键或关闭键仍触发页面原回调。iOS 手势跟手，抬手可完成返回或回弹，系统取消即使拖过阈值也回弹。减少动态效果时直接到终态，保留返回手势。
- 浅色截图来自 Flutter Widget Test。可滚动页面检查首屏及滚动后，内容不足一屏的详情另用紧凑视口。素材、权益和 SDK 网络状态由测试夹具提供。测试结果及文件路径见[验证台账](verification.md#2026-11-17-顶栏与页面转场)。

## iOS 对齐要点

共享 Dart 实现从本分支接收，版本名 `1.1.4`，共用构建号 `73`。Android 自用 arm64 split 目标版本码为 `2073`。iOS 归档时以自身的 `CFBundleShortVersionString` 和 `CFBundleVersion` 回读为准。

| 页面或入口 | iOS 对齐／复查项 | 涉及文件 | 规范 |
|---|---|---|---|
| 首页 → 更多、训练记录、训练组 | 无源胶囊，目标胶囊随整页滑动；推荐文件夹先收起 | [hip_app.dart](../lib/hip/ui/hip_app.dart) | §1.5；手册 §4.1 |
| 首页动作叠卡 | 深色后两层用前卡深色纸面叠白 4% 和 8%，描边白 8%／0.6pt；保留浅色纸面、阴影和切牌动效 | [hip_home_action_deck.dart](../lib/hip/ui/hip_home_action_deck.dart)、[hip_home_action_inspect.dart](../lib/hip/ui/hip_home_action_inspect.dart) | §6；本轮深色真机反馈 |
| 更多 → 设置 → 隐私、训练记录 → 全部训练 | 单标题首屏避开状态栏 + 44 + 24；滚动时正文穿过透明渐变；返回时固定一枚胶囊 | [hip_page_kit.dart](../lib/hip/ui/hip_page_kit.dart)、[hip_routes.dart](../lib/hip/ui/hip_routes.dart)、[hip_records_page.dart](../lib/hip/ui/hip_records_page.dart) | §1.1–1.5；手册 §2–5 |
| 动作库、训练组、动作／套路详情、组编辑、添加动作 | 动作库和详情穿透；训练组分段与编辑表单保持固定区。双标题区 52，控制轨 44。只读详情首屏为安全区 + 52 + 24 + 12。编辑器按原退出确认拦截侧滑 | [practice_page.dart](../lib/hip/ui/library/practice_page.dart)、[group_editor_page.dart](../lib/hip/ui/library/group_editor_page.dart)、[hip_page_kit.dart](../lib/hip/ui/hip_page_kit.dart) | §1.3–1.5；手册 §2、§4 |
| 自测说明、题目、结果 | 说明和结果使用共享顶栏；题目保留从按钮展开、48pt 控制轨和既有关闭回调 | [hip_assessment_page.dart](../lib/hip/ui/hip_assessment_page.dart)、[hip_page_kit.dart](../lib/hip/ui/hip_page_kit.dart) | §1.4–1.5；手册 §5 |
| 会员两态、系统购买、隐私 | 关闭键在左侧 44pt 控制轨，购买与已订阅正文滚动，固定底栏避开 Home Indicator。在 iOS 核对系统购买返回及原回执处理 | [hip_membership_page.dart](../lib/hip/ui/hip_membership_page.dart)、[hip_membership_scope.dart](../lib/hip/ui/hip_membership_scope.dart) | §1.3–1.5、§7；手册 §4 |
| 会员报价暂不可用 | Android 使用同一套餐布局，优先显示上次成功取得的本地价格，无缓存时显示标明币种的美区参考价。App Store 对齐时换用该店已核实的价格和提示，离线只展示有条件的试用说明；重试成功后使用实时套餐发起购买 | [hip_membership.dart](../lib/hip/control/hip_membership.dart)、[hip_membership_page.dart](../lib/hip/ui/hip_membership_page.dart)、[hip_revenuecat.dart](../lib/hip/platform/hip_revenuecat.dart) | §7；[Android 订阅配置](android-membership-2026-11-11.md#play-和-revenuecat) |
| Coach、同意弹层与 SDK 页面 | 宿主加载/错误壳共享顶栏；SDK 会话和计划详情保留 SDK 顶栏。SDK 到宿主页时胶囊随页。播放器、动作详情弹层及 SDK 退出流程按原行为核对 | [hip_coach_chat_page.dart](../lib/hip/ui/coach/hip_coach_chat_page.dart)、[hip_ai_consent_sheet.dart](../lib/hip/ui/coach/hip_ai_consent_sheet.dart)、[hip_routes.dart](../lib/hip/ui/hip_routes.dart) | §1.4–1.5；手册 §4–5 |
| 训练准备、训练中、休息、完成 | 播放器按宿主 Material 亮度选 SDK V1 主题，宿主休息反馈和 SDK 共用该主题。深色保留 HipLab 绿，SDK 固定版本不变 | [hip_player_page.dart](../lib/hip/ui/hip_player_page.dart) | §7 训练播放器休息反馈；本轮深色真机反馈 |
| 宿主通知条、训练组徽标 | 深色通知用主题面板色及对应的文字／关闭按钮颜色，训练组「已加入首页」用深色主题文字色；核对宿主弹层、底部表单和空状态 | [hip_theme.dart](../lib/hip/ui/hip_theme.dart)、[practice_page.dart](../lib/hip/ui/library/practice_page.dart) | §2–3；本轮深色真机反馈 |

iPhone 验收时重点看刘海或灵动岛下的首行、Home Indicator 上的固定底栏、键盘避让，以及浅色和深色下的返回按钮。用 首页 → 更多 → 设置 验证 400/340ms 进退、慢拖完成和取消回弹，再开启「减少动态效果」重复。Widget Test 中的 iOS 平台模拟提供软件回归证据，iOS 原生安装、系统购买和播放需要单独验收。
