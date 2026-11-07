# HipLab · 开胯训练助手

## 2026-11-07：已验收UI接收为main主线 / +61

用户已明确确认截至+61的本轮UI改动全部验收通过，并授权推进main作为后续开发主线。已将main从`6bdf1e9`快进到完整候选`6e49ac7`（67提交），再追加本次文档回执；不重写历史、不拆分已验收内容。共用版本保持`1.1.0+61`，arm64`2061`，四SDK实际依赖及coach override固定`fa957ff405cc57cd10d53987430313822ff20607`，hosted锁版本保持。最终候选全量624通过/70条件跳过/0失败、analyze0、严格离线锁解析及diff检查通过。手机已装+61，运行源`7ca9617`；它与集成候选的非docs文件完全相同。本轮只做集成与文档，不重建、不增版、不再操作手机。用户验收属于本轮日常Android界面体验，不扩大为新iOS、语音听感、锁屏/中断、实模对话或商店发布的Agent实测。

[主线接收回执](docs/ui-main-integration-2026-11-07.md) · [当前状态](docs/current-state.md)。

## 2026-11-06：二级页面转场优化 / +41

修复顶栏三层模糊未限定绘制范围造成的额外渲染负载，保留固定返回键与已确认转场。+41/2041已覆盖安装，真机对照和浅深色验收完成，手机按用户要求锁屏。

[本轮定位与验证](docs/navigation-jank-2026-11-06.md) · [当前状态](docs/current-state.md) · [包身份](docs/version-ledger.md)。

## 2026-11-06：首页自由拖牌与视频悬浮卡 / +40

前牌任意方向随指尖浮动，左右区域切牌，上下释放回位；点牌放大显示介绍和自动播放视频，支持原位暂停/继续与收回。+40/2040已安装到连接的小米设备，独立候选已保存。

[本轮交互与验证](docs/home-action-floating-2026-11-06.md) · [当前状态](docs/current-state.md) · [包身份](docs/version-ledger.md)。

## 2026-11-05：UI r4 全界面补全 / +36 真机包

保留已确认的仿iOS主体设计，完成页面与交互状态补全、冗余旧界面整理，修复公共训练组导致助手打不开的问题。源码`6e247aa`，独立分支`codex/ui-r4-completion-20261105`，+36/2036内部release已安装连接的小米机。

[本轮审核与验证](docs/ui-r4-completion-2026-11-05.md) · [当前状态](docs/current-state.md) · [包与签名](docs/version-ledger.md)。main/PR31集成另行处理，下方为历史阶段。

## 2026-11-04：SDK 问答 v3 / +34 已入 main

[PR #30](https://github.com/mhgd3250905/HipLab/pull/30) 已合并，功能集成点 `2400b34`；共用版本 **1.1.0+34 / arm64 2034**，SDK 固定 `f7b8a8e`（v0.7.2 内容）。App 沿用 SDK 聊天页，只传入 209 条未审 AI 标签，模型 deepseek-v4.1-flash / max；不增加问答适配层，Coach 211、动作库/组选项 210 与原安全/保存门禁保持。

验证/构建源 `0f0882e` 与集成点完整文件树相同：analyze 0，全部 66 文件 **461 通过 / 0 失败 / 68 既有条件跳过**。+34 arm64 release APK 已交付、与实际 +32 签名一致；用户确认 +33 从未出包、手机是 +32。尚无 +34 真机或新 SDK 实模对话结论，旧 +31 对话不作替代。[版本与包身份](docs/version-ledger.md)、[验证适用性](docs/verification.md)。

本轮只收束版本文档并提交推送，不增版、重建或安装。UI r3 [PR #29](https://github.com/mhgd3250905/HipLab/pull/29) 仍为 Draft，与 SDK 问答 v3 是不同事项。下方 +31、+30 及旧日期记录均为各自阶段历史；最新事实从[当前状态](docs/current-state.md)进入。

## 2026-11-04：SDK QA v2 / +31 待验候选（历史）

分支codex/sdk-pin-v0.7.0固定SDK0.7.1/9dd93163，原聊天页直接启用qaV2、传入209条未审AI标签，模型deepseek-v4.1-flash/max；App没有问答适配层。analyze0，全部66测试文件461通过/0失败/68既有条件跳过；真实3段9轮及计划保存通过。1.1.0+31/2031同测试签名内部APK已备好、未安装，等待用户远程验收，不合main。[交付、原文与边界](docs/sdk-qa-v0.7.1-validation-2026-11-04.md)。下方主线/旧候选按日期保留。

## 2026-11-04：SDK 0.6 阶段成果整理（历史）

主线已完成共享训练/媒体接入、211 完整动作准入、简约玻璃首页、UI r2 页面统一及 SDK v0.6.0 接入。PR [#26](https://github.com/mhgd3250905/HipLab/pull/26)、[#27](https://github.com/mhgd3250905/HipLab/pull/27)、[#28](https://github.com/mhgd3250905/HipLab/pull/28) 均已合并；收束前 main 为 `0737e4e`，共用版本 **1.1.0+30 / arm64 2030**，SDK 固定 `693cbc02`。

- 训练组可使用动作库的 210 个动作，混合组按一个 SDK 计划执行，使用所选休息并保存训练记录；训练记录新增热力图与成就，自测说明展示雷达。
- 动作库与添加动作共用搜索/筛选和懒加载列表；更多、设置、导航及按钮统一。每日训练秒数先合计再取整。
- 公共封面 211 张，视频按需获取，包内 0 MP4；Coach 范围 211，8 条不完整动作排除。界面固定中文，设置语言只改变语音。

主线运行源码沿用 `3a449c3` 的严格 analyze 0、454 通过 / 68 条件跳过；到收束前 HEAD 仅文档变化。UI r3 [Draft PR #29](https://github.com/mhgd3250905/HipLab/pull/29) 另有候选包与 434 通过 / 68 条件跳过，**待用户远程真机反馈，尚未合入**。最后有安装证据的是 PR #26 的 `a7e371e` 包，不能以同为 +30 推断手机已有最新候选。

成果、包身份及未验边界从 [文档入口](docs/README.md)、[当前状态](docs/current-state.md)、[版本交付](docs/version-ledger.md) 和 [验证台账](docs/verification.md) 查看。本次仅文档收束；以下日期条目保留为历史快照。

## 2026-11-03：PR #27 r2候选验证完成，待用户远程安装

保留已确认的r2结构，仅修每日训练分钟重复取整，补混合组实际SDK阶段/组间休息/完成保存回归。验证构建源`f4714c6`；analyze0，64文件按4文件/批全部通过，含新增回归去重454通过/0失败/68条件跳过（opt-in截图/导出）。47.64MiB release候选保持+30/2030、同测试签名/0MP4，交用户远程安装验混合组和旧数据，本轮未安装。只正常字体，不合main、不升版、不动release/商店。[交付与APK身份](docs/ui-r2-pages-integration-2026-11-03.md)。以下为历史阶段。

## 2026-11-02：PR #26 首页主题合入，+30 已保留数据安装

用户确认设计并授权合并，PR26在同步最新main后验证通过，合并点`a201fd5`；1.1.0+30/2030构建源`a7e371e`，47.70MiB release APK已同签名覆盖安装。analyze0、全量444通过/0失败/13条件跳过，额外截图4通过。正常字号浅深快速走查无新增显示问题，6天训练汇总、自测10/12、2组及主要设置保持；详细使用交用户。SDK仍d4502f3/211动作，日常40个WIP未变，release/tag/商店不动。[交付、脚本删除清单与验收边界](docs/home-calm-r1-2026-11-02.md)。下方为历史阶段。

**2026-11-02 全动作 +29 已交付：** 按17:14最终口径，SDK完整211动作统一用于浏览和Coach计划，8个不完整动作排除；严格analyze0、全量437通过/1既有条件跳过、Python25/25。47.64MiB release APK（2029）、211封面、0 MP4已备好，日常WIP逐字节恢复。只推codex/full-action-scope，不合main、不打tag。[交付与APK身份](docs/full-action-scope-completion-2026-11-02.md)。下方为历史阶段。

**2026-11-02 共享体验 +28 候选完成：** 用户16:19确认2倍字号不在支持范围，已删除11条相关用例并修复SDK入场/图片/滚动测试适配。严格analyze0、全量428通过/1既有条件跳过；release APK 43.40MiB、0 MP4已备好。SDK固定d4502f3，不合main、不动release；用户自行安装和真机验收。[交付与删除清单](docs/sdk-shared-experience-completion-2026-11-02.md)。以下暂停记录保留历史。

**2026-11-02 启动定位更新：** App 大型内置 catalog 的 isolate 解码与测试假时钟竞争已修复，冷启动最小用例和断网启动均通过，严格 analyze 0。全量在385通过/19失败时因确认 SDK 动作库键盘布局溢出而停止；未绕过 SDK、未重建 APK。[根因与 SDK 交接](docs/sdk-shared-experience-2026-11-02.md#启动定位更新2026-11-02)。以下暂缓记录保留历史。

**2026-11-02 共享体验接入暂缓：** `codex/sdk-shared-experience` 从 main `0f507a3` 接入 SDK `d4502f3` 三批共享能力，版本 +28。严格 analyze 0、Python25/25、首次构建包内0 MP4；Flutter 两轮仍卡在主界面加载相关测试，按用户要求停止，不交付最终 APK。[当前结果与日志](docs/sdk-shared-experience-2026-11-02.md)。

**2026-10-24 Controller 已合入 main：** 开哥明确同意后，固定候选448f109已快进合入并普通推送，远端回读一致。分析0、全量454通过/1条件跳过、专项44通过保持；release/1.0不动。以下候选待审描述为批准前历史。[集成回执](docs/sdk-conversation-controller-2026-10-24.md#主线集成回执)。

**2026-10-24 对话 controller 候选：** 从 main64daf6a 建 `codex/coach-conversation-050-20261024`，锁 coach0.5.0 / trainer0.2.3@d7e0b8f，UI0.1.1保持。自有会话/问题状态已交给 SDK，界面与业务边界保持；严格锁解析完成，分析0、全量454通过/1条件跳过、AI专项44通过，候选已完成待审，等待本轮同意后合 main。release/1.0不动。[接入与删除范围](docs/sdk-conversation-controller-2026-10-24.md)。

**2026-10-24 SDK 修复 tag：** 已按用户确认从候选5c4d32e改锁 coach0.4.2 / trainer0.2.2 / coach_ui0.1.1（均3302d62）；使用固定Flutter3.44.7从远端重新pub get，App源码和其余hosted依赖保持。分析0、窄屏大字体专项13通过，全量451通过/1条件跳过；已按授权合入并普通推送main（功能集成点88d8802），release/1.0不动。[补丁与集成回执](docs/sdk-tag-patch-2026-10-24.md)。以下保留此前候选记录。

**2026-10-24 SDK 共用界面候选：** 从 main 8880c71 建立 `codex/sdk-shared-ui-20261024`，开发版 1.1.0+21；锁定 coach 0.4.1 / trainer 0.2.1 / coach_ui 0.1.0 正式 tags，SDK TrainerPlayer 与共用聊天界面接入。无 Key 全部 AI 入口隐藏；分析0、完整测试集合451通过/1跳过、release编译和真机M自然4/4通过；语音用户确认正常，等待开哥同意再合 main。release/1.0 不动。[接入与验证](docs/sdk-shared-ui-2026-10-24.md)。

**2026-10-24 13:09：** 1.0.0(20)已提交Alpha审核，Submission ID2状态审核中；前台服务演示和公开隐私已补齐。正式版仍需12名真实测试者连续14天，用户选择稍后组织。[执行回执](docs/play-store-release-2026-10-24.md)。以下上架准备段落保留历史。

**2026-10-24 基础版上架准备：** `release/1.0` 从 main e456d2a 建立，1.0.0+20 / SDK固定d193a70，无Key本地预设、保留AI入口。上传签名AAB和商店/FGS材料已准备；Play由开哥操作，Mac从release分支接iOS。[本轮交付](docs/release-1.0/README.md)。以下日期条目为历史记录。

开胯训练 App：围绕髋部的放松、柔韧和主动控制训练，基础训练离线可用，AI 定制可配置联网生成并提供预设回落。面向久坐人群和舞者，打开就能练，小白也能上手。和「托马斯训练助手 FlareLab」同一家族（石墨底 + 青玉 `#3ccfa4`），但是独立 App、独立仓库。

- Android applicationId / iOS bundle id：`com.ugk.hiplab`
- App 名：开胯训练助手（iOS 英文系统显示 HipLab，`CFBundleName` 为 HipLab）
- Dart ^3.12.2；两端统一 Flutter **3.44.7 stable**。只支持 Android / iOS，中文界面；浅色/深色/跟随系统主题，中英语音播报（`feat/polish-round1` 起）

后续在本目录进行 main 主线开发，文档统一从 **[文档与开发台账](docs/README.md)** 进入：[当前状态](docs/current-state.md)、[版本管理](docs/version-management.md)、[版本交付](docs/version-ledger.md)、[验证记录](docs/verification.md)、[开发事项](docs/development-roadmap.md)、[工作流](docs/development-workflow.md)。当前状态核对日期为 **2026-11-04**；按页内日期保留历史交付与验证。

2026-10-21，**训练包接入及AI新中转已获同意合入并推送两仓库main**：HipLab集成点691ace2，SDK d193a70（PR #2已MERGED，coach0.1.3/trainer0.1.4）。手机已保留数据安装0.3.9+17，运行源79c172d；锁屏冻结仍是已知失败，用户后测，本轮不再排查/复测，不上传商店。[合并与验收边界](docs/android-lockscreen-fix-2026-10-21.md#主线合并确认2026-10-21)。

本仓库是 **HipLab App 主仓库，`main` 为开发基线**。[PR #2](https://github.com/mhgd3250905/HipLab/pull/2) 和 [PR #1](https://github.com/mhgd3250905/HipLab/pull/1) 已审核合并，App、高清素材和台账均已集成至 main；审核与提交身份见[主线集成记录](docs/mainline-integration-2026-10-17.md)。手机安装版本与 Git 提交分别登记。

此前2026-10-20阶段快照（历史）：**PR #25 已获同意合入并推送 main，GitHub 确认 MERGED**，业务来源 `8c985c4c6dcff4207db616e759910ea03820ad79`。新版 **0.3.7+12 AI 测试包已构建，未安装、未发布**，构建源码 `55d99b3d097afc815fa16e165362cf4703c440d5`；业务验证沿用上述来源的414项通过/1条件跳过、analyze无问题及本机真实API结果。[测试包身份](docs/android-test-build-0.3.7-2026-10-20.md)和[PR25复审/合并](docs/pr25-reaudit-2026-10-20.md)分别保存证据。

当时最后已核验安装为 **0.3.6+11 debug / arm64**，构建源码 `9b22dccc2bf2ca269a67b408198b9e3e9dbb742b`，2026-10-19 23:15:53保留数据覆盖安装。此前PR #22/#24及集成修复于23:32合入并推送main（`b33ed21088c4d334548fb45cfeb9b85959dd755d`）；当时387项通过/1条件跳过、F9编辑/键盘原生复测及正常播放听感已确认。这些旧包真机结果不覆盖PR25新功能。安装、合并和文档提交分别登记，详见[当前状态](docs/current-state.md)、[版本台账](docs/version-ledger.md)和[验证台账](docs/verification.md)。

以下为#19～#21阶段的历史交付反馈：

用户于2026-10-19反馈：已安装本轮 **0.3.6+11 debug / arm64 engine** 包并完成简单真机测试，运行源码 `c7def2869b789357b303d69d66eb8c18a0a748ae`。这是用户报告，Agent未再次ADB回读设备、版本或数据状态，不代表完整14项试听/锁屏/性能清单通过。#19→#20→#21及五项修复已顺序合入并推送main（业务集成点b9646d4）；GitHub确认三PR均MERGED。此前#17/#18的6dd16ed安装、偏好保持和专项验证保留历史，详见[当前状态](docs/current-state.md)、[版本台账](docs/version-ledger.md)及[本轮审核](docs/pr19-pr21-review-2026-10-19.md)。

制作前的视频缺口、清晰度和模型/动画源核对保留在 [媒体初始审计](docs/media-audit-2026-10-17.md)，其中缺片状态已由本轮高清交付解决。

PR #119 已审核合并，本机 4080 制作及三项动作修订已完成。绿幕、透明母帧与当前深色 App 播放版本的来源和检查见 [本地制作记录](docs/local-hd-render-2026-10-17.md)。

## 构建

当前源码为 **1.1.0+34**，SDK 四包/override pin `f7b8a8e`；使用 Flutter 3.44.7，按锁文件中的 `pub.dev` 严格解析。当前依赖与素材准备见[文档入口](docs/README.md#新机器拉素材mac--windows)，构建/安装身份见[版本台账](docs/version-ledger.md)。下段 0.3.9+17 是 10 月 21 日历史，不代表当前版本或最新安装。

本机已有依赖解析时使用 `--no-pub`，见[工作流](docs/development-workflow.md)。2026-10-21 历史共用版本为 **0.3.9+17**；Android带AI新入口配置的debug arm64包已在源码 `79c172d9a83d248f23e136cffe825f3bd016e16b` 构建并保留数据安装，固定SDK `d193a703e3a8bef6d41e7705a55ae250e23e6a69`（coach0.1.3/trainer0.1.4），签名连续、包身份/CRC/876资产及唯一训练服务核验通过。该源analyze无问题、保活专项8/8；439过/1条件跳属于此前38bce47全量基线，未在最终依赖上重复全量测试。构建、安装和后续文档HEAD分别记录，详见[证据绑定](docs/verification.md#训练包与新中转阶段收束2026-10-21)；此次文档对齐不递增版本、不重新构建或安装。

**#19～#21阶段构建记录（历史）：** 本机现有依赖缓存的验证命令使用 `--no-pub`，见[工作流](docs/development-workflow.md)。本轮已合main的运行源c7def28：analyze0、254pass/1条件skip、Python19，arm64 debug APK已交付且用户报告安装/简单测试通过。文档收束未改变运行源码，不重复构建。真机结论限用户报告的简单测试，完整课程/音乐ducking、低端帧时、强光、新自测结果页及Mac/iPhone仍保持待验。0.2.0+4的Alpha送审回执属于2026-10-17历史，本次未回读Console或上传商店；见[送审记录](docs/play-store-release-2026-10-17.md)。下列为通用构建命令，不代表本次执行发布。

当前未验边界以[验证台账](docs/verification.md)及[开发事项](docs/development-roadmap.md)的最新日期记录为准：+15已实际完成手机AI生成、保存和开练，+17保留数据升级已核验；这些结果不代表完整锁屏课程通过。D-34保留小米后台冻结失败，由用户后测；断网回落、其他未执行专项及iOS仍按原记录待验。下列为通用构建命令，不代表本次执行发布。

```bash
flutter pub get
flutter analyze
flutter test                                   # 单元 + 界面流程 + 资源边界测试
flutter test test_screens/hip_shots_test.dart  # 可选：界面截图 → test/_shots/hip/（不提交）
flutter test test_screens/hip_ios_shots_test.dart  # 可选：iPhone 15 Pro/SE 安全区截图 → test/_shots/ios/
python3 tools/ios/check_ios_project.py          # iOS 工程静态检查（plist / pbxproj / 图标）
python3 tools/voice/build_voice.py             # 重新生成语音（edge-tts，需联网）→ assets/voice/

flutter run
flutter build apk --release                    # → com.ugk.hiplab
flutter build appbundle --release
flutter build ipa --release                    # 需 Mac + Xcode，签名团队在 Xcode 里选，见 docs/ios-setup-and-release.md
```

Android release 构建要求既有 `android/key.properties` 和对应签名材料；缺失时构建失败，不自动退回 debug 签名。内部测试包的签名须与实际旧安装包单独比对，不能把内部测试签名包当作商店上传包。

## 目录

```
lib/main.dart                  入口
lib/hip/domain/                自测/今日训练/疼痛规则，以及练习剂量、自定义训练组和单练历史模型
lib/hip/control/hip_store.dart 本地持久化（SharedPreferences，单 key hiplab.state.v1）
lib/hip/ui/                    安全引导、今日/练习/进度三Tab、自测/跟练、动作详情与训练组编辑
lib/hip/voice/                 HipLab台词/剂量映射与设置适配；语音队列、时间线执行和音频输出复用ugk_trainer
lib/core/                      公共代码来源见下表；常亮导出及training_service.dart薄适配复用ugk_trainer保活/唯一原生服务
assets/hip/hip-content.json    内容包（脚本生成，不要手改）
assets/hip/posters/            历史原型静帧（当前 46 项动作均已接入视频）
assets/hip/assessment/         自测对比图（20 张）
assets/public_media/           当前 SDK 公共目录与训练语义元数据
assets/public_posters/         211 张内置公共封面；视频由 SDK 按需获取
assets/drill_media/            历史封面和 WebView 播放器源；当前包不内置 MP4
assets/hip/onboarding/         引导页三问主视觉（深/浅各 3 张；换 B 套：tools/onboarding_art/import_onboarding_art.py <目录> B）
assets/voice/                  预生成语音 zh/ en/ chime/ + manifest.json（tools/voice/ 生成）
assets/fonts/NotoSansSC.ttf    字体（OFL）
tools/hip_content/             内容包生成脚本 + 第 0 阶段源文件（动作表 csv、成套训练 md、自测设计 md、hip-media.json）
tools/pose_hub_sync.py         当前冻结 Pose-Hub 版本同步（--from-dir / --check）
pose-hub.lock.json             Windows维护的冻结素材版本与目标
tools/sync_drill_media.py      3D-Body旧同步工具，仅保留历史兼容
test/hip/                      规则 / 界面流程 / 资源边界测试
test/core/                     公共代码的测试（随代码一起复制）
docs/                          当前状态、版本/验证/事项台账、工作流与历史设计证据
```

## 从 3D-Body 复制来的公共代码

拆仓时（来源 `mhgd3250905/3D-Body` 分支 `feat/hiplab-flavor` commit `a83a0f4`）HipLab 用到的公共部分全部复制进本仓库，每个文件顶部都注明了来源路径。以后两边各自演进，不做自动同步。

| 本仓库 | 3D-Body 原路径 | 改动 |
|---|---|---|
| `lib/core/storage/local_state_storage.dart` | `app/lib/data/local_state_storage.dart` | 无 |
| `lib/core/media/drill_media.dart` | `app/lib/data/drill_media.dart` | 只留数据类，删掉 FlareLab 媒体清单的解析/加载 |
| `lib/core/media/media_controller.dart` | `app/lib/platform/drill_media/media_controller.dart` | 无 |
| `lib/core/media/media_view.dart` | `app/lib/platform/drill_media/media_view.dart` | 去掉 Web 分支（不做 Web） |
| `lib/core/media/media_view_native.dart` | `app/lib/platform/drill_media/media_view_native.dart` | 只改 import 路径 |
| `lib/core/media/media_view_stub.dart` | `app/lib/platform/drill_media/media_view_stub.dart` | 只改 import 路径 |
| `lib/core/media/scene_asset_server.dart` | `app/lib/platform/scene/scene_asset_server.dart` | 删掉 3D 场景 URI 选项（scene_variant） |
| `lib/core/media/scene_asset_router.dart` | `app/lib/platform/scene/scene_asset_router.dart` | 无（本包没有 assets/scene/，只会命中 /drill_media/） |
| `assets/drill_media/player.html` / `player.css` | `app/assets/drill_media/` | 无 |
| `assets/drill_media/player.js` | `app/assets/drill_media/player.js` | id 规则只接受 `hip-<id>` |
| `assets/fonts/NotoSansSC.ttf` + `assets/licenses/NotoSansSC-OFL.txt` | `app/assets/fonts/FlareSans.ttf`（即 Noto Sans SC） | 改文件名，字体族改叫 `NotoSansSC` |
| `test/core/*_test.dart` | `app/test/platform/` 对应测试 | 只改 import |
| 初次迁移的 `hip-glute-max-a.*`、`hip-flexors-a.*` | `app/assets/drill_media/glute-max-A.*`、`hip-flexors-A.*` | 当时原样复制改名；0.1.1+2 已换为本机高清制作素材，废弃的 `hip-flexors-a.*` 别名已移出包 |

主题（`lib/hip/ui/hip_theme.dart`）本来就是 HipLab 自己的，没有依赖 FlareLab 主题。不带过来的：3D 场景、托马斯资源、FlareLab 的 51 个动作库/肌群图/多语言、`AppLocalizations`。

## 当前素材来源与历史拆仓关系

- **Pose-Hub / SDK 公共媒体**：当前 main 使用仓库内公共元数据与 211 张封面，视频由 SDK 媒体策略按需缓存。旧 **v0.2.0，46 条 1080 视频 / 46 张 540 封面** 仅用于旧分支追溯，不向当前 main 恢复内置 MP4。准备步骤见[文档入口](docs/README.md#新机器拉素材mac--windows)。
- **HipLab（本仓库）**：App代码、内容包、构建和版本管理；保留自有supine-cross-demo与20张自测静图。
- **3D-Body**：保留拆仓来源、旧高清制作和母版追溯；下方同步段落属于历史，不是当前冻结素材的更新入口。

## 历史同步动作成片（tools/sync_drill_media.py）

以下仅保留2026-10-17旧高清导入过程，不用于日常覆盖Pose-Hub冻结素材。当前新机器按[文档入口](docs/README.md#新机器拉素材mac--windows)恢复素材并 `--check`。历史流程需要 `ffmpeg` / `ffprobe`，默认旧3D-Body和本仓库位于同一上级目录（`../3D-Body`）；当时使用的预览命令为：

```bash
python tools/sync_drill_media.py --copy-ready --force --size 1080 --crf 18 --poster-size 1080 --out E:/AII-3D/3D-Body/output/hiplab-android-20261017-v2 --dry-run
```

它做的事：

1. 从 `--out` 读取本 App 动作及 QA；`--copy-ready` 还校验完整交付清单、来源与文件 SHA。
2. 当时流程将 1080×1080 / 真实 30fps / H.264 CRF18 的主片原字节复制至 `assets/drill_media/hip-<id 小写>.mp4`，不二次压缩；按交付封面时间生成 1080 封面。
3. 自测示范片从长动作里剪（目前：`supine-cross-demo` 取自 `n-leg-circles` 7.2–12 秒）。
4. 更新 `tools/hip_content/source/hip-media.json`（时长、封面时间、来源），把动作表里对应行的「动画状态」标成已有成片。
5. 运行 `tools/hip_content/build_hip_content.py` 重生成 `assets/hip/hip-content.json`。

同步完跑一次 `flutter test`：`test/hip/hip_assets_test.dart` 会检查内容包引用的文件都在、`assets/drill_media/` 里只有 `hip-*` 成对文件。自测对比图（`assets/hip/assessment/`）不归这个脚本管，换图时直接替换同名 webp。

旧转码路径的默认参数仍是 720 / CRF27 / 540 封面，保留源帧时序；`--library` 属于早期迁移兼容功能，会从旧素材库复制，不用于当前高清批次。新批次替换 `--out`，完整步骤和验证见[开发工作流](docs/development-workflow.md)。

## 后续开发

待办统一维护在[开发事项台账](docs/development-roadmap.md)。第一、二轮贡献与当前样式修复已在main集成；D-24代码、网页与Android安装/首页检查完成，隐私页、自测、深色全流程原生复查及iPhone仍待验收。Android前台服务及练习库已随#24/#22合入，分别见D-30/D-29；旧“前台音频待开发”不再作为当前状态。完整训练、音乐ducking、原生首帧、系统通知和CI仍按各自事项与实际未验范围推进；Mac从最新main继续iOS分支验证，不升级素材或依赖，未经新授权不上传商店。
