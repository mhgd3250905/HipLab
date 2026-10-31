# HipLab 第二阶段：SF +51 唯一参照与 SDK 抽取清单

> **2026-11-01 已取消并归档。** 用户已明确作废 App 自行换 SF 界面的第二阶段，以下仅保留取消前的调研与计划快照，不再作为待执行清单；其中 +27、页面接入及帧验收安排均不据此继续。
> 对话页将由 SDK 统一提供模块。HipLab 届时只写自己的配置档：拉伸/髋/臀动作白名单、holdSeconds 剂量、主题/文案/剪影及播放器时间线回调。
> 中止时的三份未提交文件仅保存在独立归档分支；品牌适配未接入现有页面，既有 UI 删除行数为 0。`codex/coach-v2` 保持 `58e2e8117dc89b57a4a2a3660439fd11f3fc3fe6`，+26 不安装；不合 main、不打 tag、不动发布分支。

参照严格固定为 SmartFit `codex/coach-ui-kit` / `3eb2a9e88ef4d28e02f4cf306c1716d61baa7f10`，工作树
`E:/AII-3D/3D-Sport-AI/Sport-Helper-coach-ui-kit`，本轮已核对HEAD精确且干净。后续SF main或其他分支不替代此参照。
HipLab在 `codex/coach-v2`，第二阶段删除行数的基线为 `58e2e8117dc89b57a4a2a3660439fd11f3fc3fe6`；
当前SDK pin仍为 `700d0100f1cb42ef122e774a6ee0076d1916b5e5`。

2026-11-01用户最新授权第二阶段与SDK配时修复并行，覆盖旧台账“第二阶段等+26验收后再开”的等待规则。
**+26不安装**。等SDK `fit-executed-duration` 合入main后再统一换pin、三次第三段复验，最终只出联合候选 **1.1.0+27**。
不合main、不打tag、不动发布分支、不在App补配时或UI旁路。

## 结论

SDK700已拥有高层卡片和动画组件，但SF整页、控件皮肤和部分展示状态编排仍在App。
**仅用当前SDK并只提供theme/文案/icon/cutout，尚不能得到SF3eb的完整页面。**
本清单对应用户要求“先列清单回报，由SDK抽出后再接”，以下UI不移植为HipLab自有类/Row/动画器。
SDK可选择具体公开API名称；验收要求是宿主只绑定事实/业务回调及品牌资源，SDK承接对应布局、动效和展示状态。

## 需要先由SDK抽出的内容

以下文件均位于上述固定SF工作树，行号对应3eb2a9e。

| 范围 | 固定源码 | 需要SDK承接的行为 |
|---|---|---|
| 页面壳/系统栏/天空背景 | `lib/ui/chat/chat_home_page.dart:314–391`；`lib/ui/chat/cosmos.dart:17–217` | Scaffold、透明系统栏、安全区、背景、面板遮罩及主视口与dock定位；Hip不另写页面壳 |
| 空态组合/建议语条 | `lib/chat/chat_controller.dart:264–330`；`lib/ui/chat/chat_widgets.dart:23–102`；`lib/ui/chat/chat_timeline.dart:36–135` | 欢迎内容插入与建议条时机、横向排布、stagger、空态占位。欢迎气泡本身已是SDK，不重复抽一个气泡 |
| 输入栏 | `lib/ui/chat/chat_widgets.dart:106–280` | 胶囊、TextField、发送/菜单状态、交互与尺寸；不得在Hip复制ChatInputBar |
| Dock/IME/面板交接 | `lib/ui/chat/chat_composer_dock.dart:16–511` | 键盘与面板切换、底部渐变、动态高度、focus标签占高和输入区冻结；不得在Hip复制ChatComposerDock |
| 功能面板 | `lib/ui/chat/chat_widgets.dart:282–411` | 四项功能布局、按钮与展开/收起；宿主仅给文案、图标和业务回调 |
| 时间线/完成行 | `lib/ui/chat/chat_timeline.dart:10–206` | `TrainingFinishedEntry`的高度增长、12px上浮/淡入，240ms（减弱动效150ms）；SDK CoachChatList当前无对应finishedEntries能力 |
| 活跃任务与交付编排 | `lib/chat/chat_controller.dart:48–69,174–204`；`lib/ui/chat/chat_home_page.dart:439–519` | 活跃turn任务快照、取消/完成后不重放、等待行与交付行的稳定entryId/GlobalKey配对；不能只抽动画本体却让Hip重写整套状态映射 |
| 通用控件皮肤/反馈 | `lib/ui/theme/widgets.dart:37–172,375–436`；`lib/ui/theme/polish_card.dart:8–89`；`lib/ui/chat/coach_ui_adapter.dart:348–419` | SFPressable/展开按钮/controlFace/textAction/surface/startButton的实际绘制与按压反馈，见下表；Hip不新增这些低阶绘制builder |
| 计划卡裁剪与保存次动作 | `lib/ui/chat/plan_card.dart:34–72`；`lib/ui/chat/coach_ui_adapter.dart:78–165` | 外层ClipRRect20、正式inset策略，以及“更新/另存一份”footer布局（现SF自画Row，gap12）；宿主仅供标签/状态/回调 |
| 训练源页冻结/预解码/首帧 | `lib/ui/training_transition_freeze.dart:8–88`；`lib/ui/training_visible_poster_preload.dart:11–67`；`lib/ui/chat/training_card_media.dart:10–49`；`lib/ui/open_training.dart:64–85`；`lib/ui/player_page.dart:174–181` | 训练滑动期间源页与dock不变、屏宽×DPR的同一ResizeImage解码键、push前最多150ms预热、startGate前海报；不能以普通AssetImage预热替代完整链路 |

### 不能误记为已共享的控件

| 控件 | SF3eb | SDK700默认 |
|---|---|---|
| pressable | .97缩放、down100ms/up180ms、pressed/focus状态 | TextButton；scale没有用于相同缩放动画 |
| 展开按钮 | 高32/r16/hpad12、纯文字 | min44×44、旋转箭头及不同间距 |
| controlFace | 浅色直接child；暗色solid capsule | 两主题均有min44/hpad14/边框/阴影 |
| textAction | min44/hpad4/icon gap6、14px/1.2 | Material TextButton/callout，不同图标间距 |
| surface | ClipRRect20、前景1px边框、无阴影 | 不clip child、4px阴影 |
| startButton | 48px平面圆盘、无边框阴影、glyph左偏2 | 同48px但有边框阴影、不同按压 |

高层SDK卡片已经共享，并不能把以上绘制差异归为“只换颜色”。SDK应给通用样式/控件实现或公开的完整展示配置，
而不是要求Hip把SFPressable/SFPolishCard等再实现为Hip类。

`SfAlphaCardScope`在此提交没有`.of`读取者，不具有当前绘制作用；旧`SfAlphaCardSurface`也未用，不要误加历史14px下沉效果。
`cutoutTopInset`和`surfaceTopInset`已有SDK API，SF明确传`surfaceTopInset:0`，透明hero传`cutoutTopInset:0`；应保留此正式策略。
页面壳接入后还需保留Hip现有安全禁练、保存/另存、免责声明与本地持久化错误等业务事实；用SDK标准UI和回调呈现，不另画Hip卡片。

## SDK700已经可直接使用

| 功能 | 公开组件/接口 |
|---|---|
| 状态摘要、等待卡、剪影轮播 | `CoachTaskSummary.fromState`、`CoachTaskBubble`、`cutoutBuilder` |
| 出卡动画 | `CoachDeliveryTransition`；稳定ID/Key编排仍需上表中的SDK层 |
| 计划卡/展开 | `CoachPlanCard` / `CoachPlanExpanded`；控件皮肤/裁剪/次动作仍需上表的SDK层 |
| 推荐/提问/失败 | `CoachRecommendCard`、`CoachQuestionBubble`完整字段映射、`CoachFailureBubble` |
| 欢迎/普通消息/选项/时间 | `CoachGreetingBlock`、`CoachMessageBubble`、`CoachOptionPill`、`CoachTimeMark` |
| 正在讨论标签 | `PlanFocusLabel`及iconBuilder/clearIconBuilder；dock归SDK后按SF位置接入 |
| 训练路由本体 | `TrainerSlideRoute`、control.startGate/beginExit/beforeExitPop/exitSaveFailed；冻结/预热链仍待上表SDK层 |

## HipLab品牌准备与素材事实

只新增 `lib/hip/ui/coach/coach_ui_brand.dart`，提供task颜色角色、4种SDK glyph映射、focus/clear图标和cutoutBuilder，
没有新按钮/卡片/页面壳/动画。该文件暂为接入准备，不用它掩盖尚缺的SDK整页组件。

Hip自有浅深JPG/视频是烘焙背景，不当透明剪影。现有已钉SDK自带45/45匹配Hip profile的透明WebP，640×640、RGBA alpha0–255，
路径为 `packages/ugk_trainer/assets/pose_hub/app-test-pack-r1/standing/<精确actionId>.webp`；全部已在+26包中，不复制、不重渲。
它们是同一份中性透明人物供浅深两主题使用，没有独立light/dark透明文件；SF3eb也按此方式使用brightness缓存而未重新着色。
保持动作ID大小写。动作集合复用`libraryDrills`：`mvpDrills`包含Thomas且遗漏脚踩椅面臀桥，不能拿它误当AI45白名单。
Hip图标复用HipIcon；bookmark角色以现有clipboard语义映射，不声称与SF书签同形。

品牌适配定向6/6、两文件fatal-infos分析0；已逐项核对45资源index/SHA/alpha、缓存、语义和浅深角色。
日志在 `E:/AII-3D/hiplab-releases/coach-ui-kit-20261101/brand-adapter-tests.log`。
**本检查点删除的既有App UI行数为0**；尚未抽SDK的旧实现不能先删成缺功能页，也不能从SF移植来虚报删除。
后续删除行数统一以阶段二基线58e2e81计算，第一阶段已删除的template_fallback等不重复计入。

## 固定视觉验收协议

SF正式参照帧为 `docs/ui-kit-frames/sdk-main700d010/new/{light,dark}`，同源工具在
`tools/ui_kit_frames/{capture_slots_test.dart,capture_adapter.dart,inputs-slots.json}`。
收据源码de0bd432至指定3eb2a9e在lib/捕获工具/pubspec/lock无差异；历史base比较的13帧/299像素差不冒称零差通过。

固定Flutter3.44.7、逻辑412×915、DPR2.625、输出1082×2402、边距20/64/20/20，中文、textScaler1.0、正常动画，
主题切换动画0，图片预解码；只禁素材自身循环，SDK动画正常。保留未遮罩原图，几何/动画数值为门禁，
不能通过大面积颜色/文字mask掩盖布局错误。

| 场景 | 相对触发毫秒 |
|---|---|
| 等待 | 0/400/800/1200/1600，并补六个原始node阶段 |
| 参数变更/完成 | 变更后260/完成后260 |
| 首图揭示 | 179/180/181/305/429/430/431 |
| 剪影交叉淡入 | 899/900/901/1025/1149/1150/1151 |
| 出卡 | 0/222.5/445/667.5/890 |
| 标签进入/退出 | 0/1/90/179/180/181；0/1/60/119/120/121 |
| 训练滑入/滑出 | 0/75/150/225/300；0/70/140/210/280 |

计划非legacy组件帧102张、补六阶段浅深12张，共114张；整页空态/输入栏、计划/推荐/问题/失败以及真实对话截帧另补。
SF与Hip字体SHA不同（4,110,060B与17,772,300B），抽样共有汉字advance、unitsPerEm、hhea及wght轴相同；
这只排除已查样本的部分风险，不能把SHA不同直接当相同或用文字mask跳过换行/外部尺寸验证。
已有compare_frames.py仅支持精确RGBA，跨品牌不能原样运行后宣称等价。

SDK抽取合入后再接完整页面，三次真实对话截图与全量测试/analyze/签名/16KB/JNI、SDK配时修复后的三次270–330秒复验均仍待执行。
当前未做整页帧对比、未发模型请求、未产出+27、未安装+26，不将准备工作记作第二阶段完成。
