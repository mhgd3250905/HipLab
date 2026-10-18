# 当前状态

核对日期：2026-10-19，北京时间。此页维护当前事实；过程见[开发日志](development-log.md)，检查范围见[验证台账](verification.md)。

**Mac / iOS 补记（20:49）：** `ios/main-ui-036` 已 rebase 到 `fce7ad8`，候选 `2f8aeb0` 的 analyze、160 pass /1 skip、签名Release/Archive和随包核验通过。重连后0.3.6+11已覆盖安装到iPhone 16 Pro /iOS26.5并回读确认；安装前后753字节偏好完全一致，启动命令成功，新UI镜像检查待手机锁屏。已推送[草稿 PR #16](https://github.com/mhgd3250905/HipLab/pull/16)，未合并。见[iOS 0.3.6 对齐与验证](ios-main-ui-036-2026-10-18.md)。

## App 与设备

| 项目 | 当前状态 |
|---|---|
| 产品 / 包名 | 开胯训练助手 HipLab / `com.ugk.hiplab` |
| Android 已安装版本 | **用户报告**已安装0.3.6+11 / debug arm64 engine审阅包（c7def28），简单测试通过；Agent本次未ADB回读，不推断数据保持或完整清单通过 |
| 合并前已验基线包（历史） | **0.3.6+11 debug**，源 `6dd16eda246657d1de8ddf9e92b8e91d992c3a80`；150,903,412bytes，已保留数据安装 |
| 本轮交付运行源码 | `c7def2869b789357b303d69d66eb8c18a0a748ae`；用户安装反馈绑定本会话交付包，设备实际版本未回读；运行内容已进入main；此前基线6dd16ed另存历史 |
| 正式 Android 图标 | 已选 B 站姿开髋，青玉绿/石墨底；普通、圆形、自适应及单色资源，已查看手机桌面确认彩色图标 |
| 历史用户验收（本轮见下） | 2026-10-17，0.1.2+3 更新测试通过；2026-10-18，用户已验收 0.3.1+6 单屏自测 UI。此验收不覆盖后来 CSS 修复的原生首帧 |
| 验证设备 | 此前Agent验证为2602BRT18C / Android16 / API36；本次用户自行安装，型号、WebView与系统设置未重新回读 |
| 产品范围 | 中文、离线；main 已含浅色/深色/跟随系统主题、中英语音、单屏自测布局及 iOS 配置。Android 已安装运行；iOS 仅静态和 widget 检查，尚未在 Mac 构建或真机验证 |
| 用户验收 | 2026-10-17，0.1.2+3 更新测试通过；2026-10-18，用户已验收 0.3.1+6 单屏自测 UI。此验收不覆盖后来 CSS 修复的原生首帧 |
| 验证设备 | 2602BRT18C，Android 16 / API 36，arm64 |
| 产品范围 | 中文、离线；main 已含浅色/深色/跟随系统主题、中英语音、单屏自测布局及 iOS 配置。Android 已安装运行；iOS 旧 0.3.3+8 已安装并获用户基本听音/锁屏复测通过；本轮0.3.6+11已构建/归档并保留偏好安装，镜像UI检查待手机锁屏 |
| 动作素材 | 当前冻结 Pose-Hub v0.2.0：46 条 1080 视频 / 46 张 540 封面，ID 和文件名保持；自有 supine-cross-demo 与20张 still 保留 |
| 自测素材 | 既有 20 张自测 still 保留（含 #8 修订），不在 v0.2.0 ZIP / lock；不重新渲染 |
| main基线运行验证（历史） | 组合analyze0、191pass/1条件skip，gallery2pass；两项P2首轮修复与当前Android复查通过。完整课程/ducking/低端帧时/强光/新结果页/iPhone仍待验；[证据](pr17-pr18-fixes-and-merge-2026-10-18.md) |

当前素材按仓库冻结 lock / manifest 取用 v0.2.0。同步：dry-run 92项计划；首次92 copied；check 92 matched /0 drift；重复同步0 copied；元数据：本机92文件大小/SHA全匹配；46视频H264/yuv420p/1080²/30fps/无音轨，11220帧；完整CPU解码通过；46封面均540²JPEG；保护文件：hip-supine-cross-demo.mp4/.jpg +20张自测still，共22文件SHA保持。该冻结ZIP仅深色；当前main/App包已含PR #20的47套light视频/封面及20张浅色自测图；旧批次QA和历史验收保留，不能作为本轮全量真机结论。

## Git 与主线集成

**`mhgd3250905/HipLab` 是 HipLab App 主仓库，`main` 是后续开发基线。** 接手成果通过 #2、#1 合入 main，本机 main 跟踪 origin/main。图标版本 0.1.2+3 的代码提交为 `4cf5ca7`，通过 [PR #5](https://github.com/mhgd3250905/HipLab/pull/5) 集成；业务逻辑和视频资源保持，安装状态独立记录。

| 对象 | 2026-10-18 核对结果（历史日期另列） |
|---|---|
| HipLab `main` | #19→#20→#21及五项修复已合入并推送，业务集成点`b9646d4`；GitHub均MERGED。运行内容与用户收到的c7def28包相同；下方未合并记录是此前快照 |
| [HipLab #7](https://github.com/mhgd3250905/HipLab/pull/7) | MERGED，merge `ba591bf`；并合入 Android 首轮验证修复 |
| [HipLab #8](https://github.com/mhgd3250905/HipLab/pull/8) | MERGED，merge `5bb43f0`；保留修订媒体与配套评分说明 |
| [HipLab #9](https://github.com/mhgd3250905/HipLab/pull/9) | MERGED，merge `61979d8`；保留 iOS 配置及共享音视频安全处理 |
| [HipLab #10](https://github.com/mhgd3250905/HipLab/pull/10) | MERGED，GitHub merge `60a683c`；本地 rebase 内容先由 `18a084b` 集成，再保留原 PR 祖先。隐私政策、复制链接测试及送审历史均保留 |
| [HipLab #1](https://github.com/mhgd3250905/HipLab/pull/1) | MERGED，`feat/initial-migration` → `main`，2026-10-17 13:59:40，merge `656ee28` |
| [HipLab #2](https://github.com/mhgd3250905/HipLab/pull/2) | MERGED，`codex/project-takeover` → `feat/initial-migration`，2026-10-17 13:59:14，merge `e52b3c2` |
| [HipLab #5](https://github.com/mhgd3250905/HipLab/pull/5) | 0.1.2+3 站姿开髋图标与安卓实机交付；已安装代码 `4cf5ca7`，具体合并 SHA 回读 GitHub |
| [3D-Body #119](https://github.com/mhgd3250905/3D-Body/pull/119) | 已合并，2026-10-17 10:29，merge `ae81d96f271a18129abbf6afc7064cfd9dd1d8c3` |
| [3D-Body #120](https://github.com/mhgd3250905/3D-Body/pull/120) | OPEN / draft，制作工具与修订规格 → `master`，源 `f8b5138` |

四个 PR 均已由 GitHub 回读确认 MERGED，合并时间为 2026-10-18 **01:01:06 北京时间**（UTC 2026-10-17T17:01:06Z）；推送与手机安装分别记录。

本地原先只抓取 `feat/initial-migration`，现已改为抓取所有远端分支。合并前后核验源 SHA、目标 SHA 和完整文件树，main 集成结果与已审核版本一致；原接手分支保留。细节见[主线集成审核](mainline-integration-2026-10-17.md)，日常更新见[工作流](development-workflow.md)。PR 状态是上述日期快照，操作前回读 GitHub。

## 本机环境和素材位置

| 位置 | 用途 |
|---|---|
| `E:\AII-3D\3D-Hip` | Flutter App、内容源、交付视频、开发台账 |
| `E:\AII-3D\3D-Body` | 既有源工程与输出，原工作区未提交文件未动 |
| `E:\AII-3D\3D-Body-worktrees\hiplab-hd-20261017` | 独立制作副本，`codex/hiplab-hd-20261017`，工具代码 `f8b5138fb377ec8cda464cfb08186fd696ca7921` |
| `E:\AII-3D\3D-Body\output\hiplab-delivery-20261017\selected-masters-46.json` | 最终 46 项母版选版清单 |
| `E:\AII-3D\3D-Body\output\hiplab-android-20261017-v2` | 历史 Android 派生片与 SHA，保留追溯；日常素材已改用 Pose-Hub |

两端按用户交接统一 Flutter **3.44.7 stable / Dart 3.12.2**。本轮显式对齐该 SDK 的 13 项传递依赖与 lock 的 Dart 下限（原 #7 lock 要求 Dart 3.13），已通过分析、测试和构建；不是使用 3.47.7 或继续保留不兼容的 lock。Android SDK 36、JBR 17。

路径：Flutter `E:\flutter`，Android SDK `E:\Android\SDK`，ADB `E:\Android\SDK\platform-tools\adb.exe`，FFmpeg `D:\ffmpeg-master-latest-win64-gpl\bin`。实际渲染为 **RTX 4080 Laptop GPU 12 GB / ANGLE D3D11**。绿幕、透明帧和大批次输出位于本机忽略目录，未由 Git 备份；制作副本和输出仍需保留。

## 第一轮修改历史（2026-10-17，原分支 `feat/polish-round1`）

用户 14 条问题中，本分支完成 1（全 App 媒体圆角框）、2（自测首页重排）、3（视频首帧占位不闪）、4（「托马斯测试」改「屈髋肌测试」+ 大字体不重叠）、5（分侧项明确「现在测右边」、防重复点击）、7（标题并入顶栏）、9（无分侧动作不留空行；脚部渲染另修）、11（引导页专属主视觉 A 套）、12（统一过渡动效与预加载）、13（中英语音播报，edge-tts Xiaoxiao / Jenny 预生成 244+244 条）、14（浅色/深色/跟随系统）及 D-01 紧侧加练。问题 6、8、10 与 9 的脚部朝向属于媒体重做，在 `fix/motion-media` 分支。此为 PR 原阶段记录；之后已在本轮逐次构建、覆盖安装并抽查，完整跟练与音乐 ducking 仍待补测，见下节集成记录。

## iOS 版本历史（2026-10-17，原分支 `feat/ios`）

`feat/ios` 从 `feat/polish-round1`（#7，tag `round1-app-v1` → `44db1fe`）切出，合入 `fix/motion-media`（#8，tag `round1-media-v1` → `0d07587`，无冲突，`hip-content.json` 重新生成无差异），因此包含第一轮全部成果。iOS 里程碑 tag：`ios-v0.1-config`（工程身份）、`ios-v0.2-icon-launch`（图标与启动页）、`ios-v0.3-audio`（音频会话与中断）、`ios-v0.4-video`（WKWebView 示范）、`ios-v0.5-safearea`（安全区截图自查）、`ios-v0.6-docs`（说明与台账）。

Bundle ID `com.ugk.hiplab`、iOS 15.0、仅 iPhone 竖屏、中英显示名、SwiftPM（无 Podfile），站姿开髋 AppIcon、跟随系统的启动页，playback + 按句 duckOthers、中断自动暂停，WKWebView 示范锁屏回来继续。只做了静态检查与 iOS 目标平台 widget 测试，**未在 Mac/Xcode 构建，未上真机**；Mac 步骤与真机确认清单见 [iOS 运行与上架说明](ios-setup-and-release.md)。

## 第一轮集成与送审历史（2026-10-18）

用户已明确授权 Windows 主干线审核集成贡献 PR，后续验证后直接提交和推送 main，无需另开 PR；禁止 force push。原目录 `E:\AII-3D\3D-Hip` 已回到 main，`963db04` 完成 Pose-Hub 接入，随后 `9ef59a1` 修复视频 CSS 双重淡入；两者与四个 PR 已推送 main，GitHub 已确认四 PR 合并。手机仍为 `963db04` 初步 APK，最终修复包只完成构建，手机拔出后没有再次 ADB 安装；手机安装与远端合并分别登记。原有 `.playwright-mcp/` 保持不动。

Play Alpha **0.2.0+4 / Submission ID 1** 于 2026-10-17 20:59 送审，当时为“审核中”；本轮未再次操作或回读 Console。当前 **0.3.2+7 debug** 是同证书真机验证包，不是新送审版本。隐私页、支持邮箱和复制链接测试均保留。送审历史见[送审记录](play-store-release-2026-10-17.md)，此前三阶段过程见[第一轮集成记录](android-round1-integration-2026-10-17.md)。

Pose-Hub 首版已发布并接入，版本冻结为 **v0.1.0**。新机器从已推送 main 按 [README 新机器拉素材](README.md#新机器拉素材mac--windows)恢复公开 ZIP 并执行 `sync --from-dir` / `--check`。Mac 从最终 main 开 `ios/…` 分支，只做 iOS 构建与真机验证；不升级素材、依赖、lock 或共用版本。

## 第一轮临时网页预览边界

独立预览在 320×568、360×740、390×844、768×1024 四个尺寸检查了正方形示范区、按钮 bounds、无滚动、六项自测切换及结果完成。该预览使用 poster stub，原生音频在网页会抛 `UnsupportedError`；系统行为与真实 H.264 媒体另由 Chrome 探针检查，不能将这些结果写为 HipLab 正式支持 Web。完整过程见[主干与 Pose-Hub 记录](mainline-pose-hub-2026-10-18.md)。

## 当前限制

紧侧加练、主题、iOS 配置和隐私入口已在 main 集成并推送，不再作为未合入功能。六个动作的逐帧证据均显示短暂淡入变暗；去除视频 CSS 双重淡入后，Chrome 原 H.264 新旧对照及循环/暂停/恢复通过，最终 Android 原生首帧仍待单独复验。完整训练、音乐 ducking 与全量媒体体验仍待验收；系统通知、Android 前台音频、iOS Mac 构建/真机和 CI 尚未完成。正式上传签名已在0.2.0+4验证；Play状态仅保留2026-10-17历史送审回执，本阶段未重新回读或上传。Android 彩色图标已实机验证，单色图层未做手机主题切换验证。事项统一维护在[开发事项台账](development-roadmap.md)。

## 第二轮集成快照（2026-10-18）

业务代码 `1b35657dec153741e25ca095ac2764b18d14ac29` 已于 2026-10-18 10:04 北京时间推送 main。运行源码 `1b35657dec153741e25ca095ac2764b18d14ac29`，版本 **0.3.3+8 debug**；行为检查源码 `162a4e6b78a8640d367cac13ef5e1ae6cfa9b33a`：analyze 0，Flutter 单并发 156 项通过、1 项按设计跳过。最终 APK 已构建，手机拔线未安装；Android 原生及 iOS 待验。PR #13：MERGED（a41e7e0）；PR #14：MERGED（4c563f9）。

临时独立网页预览在 320×568、360×740、390×844、768×1024 上检查正方形示范区、按钮 bounds、无滚动、六项自测及结果完成；点按暂停/继续、键盘、分段拖动、快速 Tab 和训练暂停/继续通过。预览使用 silent-voice fixture 与 poster stub；普通 DOM locator 仍因 Flutter semantics root 空白而超时，保留失败证据。坐标 page.mouse 操作通过且未使用 force；原生 widget hitTest 回归通过。这不构成原生媒体、H.264、系统音频或正式 Web 支持验收，也不据此诊断透明旧页遮挡。倒计时改为 33 ms tick；Chrome 18 屏的 17 个相邻环区域中，完全相同对数由旧 100 ms 的 5 对降至 0 对，采样约 47–79 ms，不代表真机帧时或帧率

[第二轮集成记录](round2-integration-2026-10-18.md)。本轮不上传商店，不改版本号以外的发布配置；没有新的手机安装或 native/iOS 通过结论。

## Pose-Hub v0.2.0 接入时快照（历史，2026-10-18）

Pose-Hub v0.2.0，视频 1080² / 封面 540²，46 个原 ID 与文件名保持。App 0.3.4+9，源码 `03c3b5bcd1ebc0157e3789af21a4bf0188f52468`，已构建但未安装；业务代码 `03c3b5bcd1ebc0157e3789af21a4bf0188f52468` 已于 2026-10-18 11:40 北京时间推送 main。手机仍为 `963db04` / 0.3.2+7，本轮无 ADB 或商店操作。

ZIP、云端冻结 manifest 已下载核验，安全解压 92 文件完成；App 同步：dry-run 92项计划；首次92 copied；check 92 matched /0 drift；重复同步0 copied。[Pose-Hub v0.2.0 接入](posehub-v020-integration-2026-10-18.md)。人工观感、原生首帧/音频与 Mac/iPhone 仍待验收。

## Android 安装历史（2026-10-18 17:15）

用户重新连接 2602BRT18C 后，核验旧包 0.3.2+7 与新包使用同一 debug 证书；备份 App 用户数据目录和 1356 字节偏好，执行 `adb install -r` 成功。设备回读 0.3.4 / versionCode 9；冷启动 Status ok（1677 ms），App 在前台、首页截图已查看，当前进程 crash 日志未见 FATAL EXCEPTION。安装后及启动后偏好均与备份逐字节一致。本次只安装和启动，未进入训练或自测，没有写回/清除数据；原生首帧、完整语音和系统音频仍待单独验证。

## Android 语音修复验收历史（0.3.5+10，2026-10-18）

0.3.4+9试听无声的原因是错误使用系统提示音通道；已改MEDIA并更新至0.3.5+10，铃声仍静音时原生轨道已 started / mutedState:none，用户确认完整口令可听。安装前当前偏好1355字节，与安装/启动/试听后逐字节一致；没有回写旧备份。详见[Android 静音模式语音修复](android-voice-media-routing-2026-10-18.md)。

## 样式修复构建阶段记录（安装前，2026-10-18）

0.3.6+11已完成浅色首页滑块、绿色小字和运动说明、隐私页共用顶栏；源码 `66f5da0`，analyze0、158pass/1条件skip、四尺寸网页自测及APK核验通过。该构建阶段尚未安装，手机当时仍为0.3.5+10；19:29安装事实见下一节。未发布商店。见[样式修复记录](theme-polish-2026-10-18.md)。

## 0.3.6+11 安装确认（2026-10-18 19:29）

已保留数据覆盖安装至2602BRT18C，设备回读versionName0.3.6/versionCode11，冷启动首页已查看浅色新滑块。安装前当前1356字节偏好在安装/启动/截图后逐字节保持，先备份再安装，未回写旧数据。仅验证本次安装和首页；未进入训练/自测或更改用户主题，未将旧版试听确认当成本版重新听音。证据见[样式修复记录](theme-polish-2026-10-18.md#安装追加2026-10-18)。

## PR #17/#18修复与集成（2026-10-18）

用户在初审后明确授权修复后直接推进合并。F1 Tab中途反向连续性、F2分段共享滑块下沉均首轮修复通过；#17独立169pass/1skip，组合191pass/1skip。23:35:52/23:36:26按顺序合入，源6dd16ed修复包已保留数据安装，本地main已对齐。原有自测和打卡保持，测试后1356字节偏好与测试前相同，浅色与系统动画值还原。本轮未新增假记录、未清数据/恢复备份或上传商店。剩余硬件/跨端边界见[本轮记录](pr17-pr18-fixes-and-merge-2026-10-18.md)。

## PR #19/#20/#21 隔离审核交付快照（历史；最新合并见末节）

main保持`6020d8e8bf26700e56785b029ef8d5ef4a379f2c`，原手机最后已记录源6dd16ed/0.3.6+11，本轮未操作手机及原记录。隔离分支`codex/pr19-pr21-validation`按#19→#20→#21组合：四项原PR问题在e3fb1d3首轮修复，另一本地组合反馈字体问题在c7def28首轮修复；最终analyze0、254pass/1条件skip、Python19通过，themed-media/action-kit检查通过。依赖、lock、版本未改。

按用户最新安排停止模拟器，Web复核已完成：实际Chrome共用播放器51/51、重点循环/暂停恢复7/7、核心脚本1/1；页面深浅、自测到结果/训练、88自测/追问+8结果尺寸组合、360×740字号1.5、设置与交互通过。最终字体增量深浅冷上下文复测通过。预览采用合成内存、静音输出及视频封面替身；不代替真机声音、原生合成、锁屏恢复或性能。47浅色视频技术审计及46动作包light引用检查通过。

早期e3fb1d3 x64包仅安装专用AVD，原AVD正式0.2.0未覆盖；9/14个合成场景后已停止，不能记为完整语音验收。最终c7def28 arm64候选身份见[版本台账](version-ledger.md)，未装手机。晚上继续真机、再按本轮同意顺序合入；当前未合main、未推送main、未上传商店。完整事实、截图与未验证边界见[审核报告](pr19-pr21-review-2026-10-19.md)。

## 本轮用户安装及简单测试反馈（2026-10-19）

用户收到本会话交付APK后反馈真机安装及简单测试通过。交付源`c7def2869b789357b303d69d66eb8c18a0a748ae`，版本0.3.6+11，174,329,762bytes，SHA256 `7fdbdf81f567d064d2dcab356494087a552913a32812f3a4c80c091a767ec678`；身份见[版本台账](version-ledger.md)。本次Agent未连接手机或执行ADB，未获取新设备版本、截图、WebView、逐项测试清单、备份或数据完整性证据。

当前状态为“已交付、用户报告安装及简单测试通过、审阅分支已推送、main未合入”。完整中英14项试听、原生切主题/退出专项、锁屏恢复、低端机/强光及iPhone等仍按实际未验范围保留；不把简单通过扩展为全部验收。本次只更新版本/验收记录，版本不递增、依赖/lock不改、不重构建、不上传商店。

## PR #19 → #20 → #21 主线合并确认（2026-10-19）

用户明确要求推进合并后，先回读原PR head与main，均与审核对象一致。将main从6020d8e快进至已审核合并链`b9646d4a15b4e3727d8e11ea5ee3106f0e396603`并普通push；GitHub于2026-10-19 14:00:39北京时间（06:00:39Z）确认三PR均MERGED。该时间为一次push后GitHub统一确认时间，Git第一父链实际顺序为#19→#20→#21：

| PR | GitHub确认的merge commit |
|---|---|
| [#19](https://github.com/mhgd3250905/HipLab/pull/19) | `2b552fd684a1a366433cf6544f1c721d4cd6209f` |
| [#20](https://github.com/mhgd3250905/HipLab/pull/20) | `18bf4ce2f211c6593cc9322a0776d9aa1e1aba43` |
| [#21](https://github.com/mhgd3250905/HipLab/pull/21) | `b6fd55ef1e00602a886d6bc62b2268b618639019` |

五项首轮运行修复、封面时刻工具guard、46动作包light引用和全部审核证据一并进入main。逐路径比较`lib/android/assets/tools/test/pubspec.yaml/pubspec.lock`，main与已验证源`c7def2869b789357b303d69d66eb8c18a0a748ae`无差异，因此本次不重跑全量或重构建APK；复用analyze0、254pass/1条件skip、Python19、媒体/动作包check及原arm64构建证据。用户报告安装及简单测试通过；完整原生14项试听、锁屏恢复、低端帧时/强光/iPhone等未验范围继续保留，不因合并自动通过。

版本仍0.3.6+11，依赖/lock无新改动，未操作手机或上传商店；原目录4个`.playwright-cli/`、`.playwright-mcp/`未跟踪文件保持。本次业务集成点为b9646d4，之后只追加实际合并文档记录。
