# 当前状态

**最新候选0.3.9+17已构建、尚未安装。** App79c172d固定SDKd193a70/trainer0.1.4，在唯一服务加入真实媒体会话/暂停状态和上限释放；原生编译26.8秒、App analyze0、保活专项8/8通过，SDK新增接口定向通过。手机仍为+16失败现场且安全锁屏，待用户回来解锁，先正常结束再保留数据安装/整节复测。两个main未合，不把构建记为修复验收。[候选身份与边界](android-lockscreen-fix-2026-10-21.md)。

**00:08最新：0.3.9+16锁屏仍失败。** 00:07:47.193 Greeze冻结（关屏5分25.7秒），服务和started/mutedState:none音轨仍在、训练锁DISABLED；系统媒体会话栈为0。不能把正常音量修正记为锁屏通过。当前安全锁屏，待用户回来解锁后正常结束本轮；SDK正在补真实媒体会话与释放，main未合。[完整现场](android-lockscreen-fix-2026-10-21.md)。

**00:02安装快照：0.3.9+16 / 38bce47，开始锁屏复测。** 固定SDK8fb0aac/trainer0.1.3，Android音轨已为started/mutedState:none，用户确认口令继续。App439过/1跳、analyze0，训练包119/119及analyze0；备份并保留数据安装，20记录/4组/UUID保持。+13/+15失败历史不改，两个main未合。[最新证据](android-lockscreen-fix-2026-10-21.md)。

**上一轮安装0.3.9+15 / f8f0ec8，AI通过、整节锁屏失败。** 固定SDK8ef37a9（coach0.1.3/trainer0.1.2），夹具ab963d7；App439过/1条件跳、analyze0，SDK168/118及两包analyze0。保留数据覆盖安装与UUID冷启动通过，手机AI36.595秒首轮生成8动作并保存第4组。23:50:21.914 Greeze再次冻结并禁用训练锁，亮屏后声音恢复。23:53用户正常结束失败课程，结果528秒、6/8、full=false、endedEarly=true，记录19→20，4组保持，TrainingSessionService已退出。main未合，待SDK修复与整节复验，不把提前结束释放算作锁屏通过。[新中转与失败证据](ai-relay-migration-2026-10-20.md)。

**上一轮修复候选：0.3.8+14 已保留数据覆盖安装。** App源f702164，固定SDK7348f0c/trainer0.1.2；SDK118/118、analyze0，Android编译及签名/CRC/876资产/单服务检查通过。升级前9882字节偏好备份，安装后逐字节一致，19条记录/3组/3个完成日保留。Android间隙静音保活与终态释放已有回归；新包App analyze0、全量429过/1条件跳（4分33秒）。用户明确改用扬声器复测，随后因需使用其他App要求稍等，课程未启动，待用户通知；尚未接受新原生结果，main未合。

**2026-10-20 分支真机验收未通过：** `codex/adopt-ugk-trainer` / `7dd40b0` / `0.3.8+13` 已保留数据覆盖安装，固定 SDK `7a84dc0` / ugk_trainer 0.1.1。App analyze0、429pass/1条件skip，SDK111pass；签名连续、876资产及单一包内服务通过。用户锁屏后出现无声、解锁恢复；系统日志确认小米 Greeze 在语音间隙冻结 UID 并禁用唤醒锁。首轮系统实际为扬声器路由，不能记耳机通过。正在 SDK 分支修复，未合 main；只有重新验收通过并获开哥本轮最终同意才合并。[接入与现场记录](ugk-trainer-adoption-2026-10-20.md)。

**2026-10-20 早间主线构建快照（历史）：0.3.7+12 Android测试包已生成，带AI配置，来源55d99b3，签名连续、资源/包校验通过；该阶段未安装、未发布。** main仅递增共用版本，业务内容保持已验PR25；晚间本轮实际已观察手机0.3.7+12并覆盖安装0.3.8+13，当前安装见下表。[早间测试包](android-test-build-0.3.7-2026-10-20.md)。

**2026-10-20 最新主线：** 开哥明确授权后，PR25来源8c985c4及审核文档ce7ab74已合入并推送main，GitHub于11:24:56确认MERGED；SDK0.1.2，原5P2闭环，414过/1条件skip、analyze/Android构建/API通过。此次以已完成的代码和本机验证推进合并，真机未验不改记通过。没有安装/发布，手机仍为10月19日最后已验包；[合并记录](pr25-reaudit-2026-10-20.md#主线合并确认2026-10-20)。

核对日期：2026-10-21，北京时间。此页维护当前事实；过程见[开发日志](development-log.md)，检查范围见[验证台账](verification.md)。

## App 与设备

| 项目 | 当前状态 |
|---|---|
| 产品 / 包名 | 开胯训练助手 HipLab / `com.ugk.hiplab` |
| 共用 App 版本 | 当前接入分支 `pubspec.yaml`：**0.3.9+17**；main仍0.3.7+12，未合并；维护规则见[版本管理说明](version-management.md) |
| Android 已安装版本 | **0.3.9+16 / debug arm64 / 38bce47**，SDK8fb0aac；备份14250字节偏好后覆盖安装，启动后逐字节保持，20记录/4组/UUID不变。8动作整节锁屏失败，安全锁屏待用户回来正常结束 |
| 合并前已验基线包（历史） | **0.3.6+11 debug**，源 `6dd16eda246657d1de8ddf9e92b8e91d992c3a80`；150,903,412bytes，已保留数据安装 |
| 本轮交付运行源码 | 最新候选0.3.9+17/79c172d，SDKd193a70，已构建未装；手机仍+16/38bce47失败现场。+13/+15/+16失败保留、+14未开练；main未合、未发布 |
| 正式 Android 图标 | 已选 B 站姿开髋，青玉绿/石墨底；普通、圆形、自适应及单色资源，已查看手机桌面确认彩色图标 |
| 历史用户验收（本轮见下） | 2026-10-17，0.1.2+3 更新测试通过；2026-10-18，用户已验收 0.3.1+6 单屏自测 UI。此验收不覆盖后来 CSS 修复的原生首帧 |
| 验证设备 | 2026-10-20已核验2602BRT18C / Android16 / API36，物理密度520/font_scale1.0；本轮未改设备设置，WebView版本未重新取证 |
| 产品范围 | 中文；基础训练离线，AI定制可配置联网生成并提供预设回落。main已含今日/练习/进度三Tab、动作大全/单练/自定义训练组与AI定制、Android训练保活、三档主题、中英语音和单屏自测。AI本机代码/构建/API验证通过，真机与iOS尚未验收 |
| 动作素材 | 当前冻结 Pose-Hub v0.2.0：46 条 1080 视频 / 46 张 540 封面，ID 和文件名保持；自有 supine-cross-demo 与20张 still 保留 |
| 自测素材 | 既有 20 张自测 still 保留（含 #8 修订），不在 v0.2.0 ZIP / lock；不重新渲染 |
| 当前运行验证 | 接入分支439pass/1条件skip、analyze0、SDK根168/训练118通过；构建/安装/原数据与UUID冷启动通过，手机新AI生成/保存通过。整节扬声器锁屏再次失败，23:50:21.914 Greeze冻结；23:53提前结束后记录/服务释放已核对，不能验收或合main；+13失败及旧main证据保留 |
| main基线运行验证（历史） | 组合analyze0、191pass/1条件skip，gallery2pass；两项P2首轮修复与当前Android复查通过。完整课程/ducking/低端帧时/强光/新结果页/iPhone仍待验；[证据](pr17-pr18-fixes-and-merge-2026-10-18.md) |

当前素材按仓库冻结 lock / manifest 取用 v0.2.0。同步：dry-run 92项计划；首次92 copied；check 92 matched /0 drift；重复同步0 copied；元数据：本机92文件大小/SHA全匹配；46视频H264/yuv420p/1080²/30fps/无音轨，11220帧；完整CPU解码通过；46封面均540²JPEG；保护文件：hip-supine-cross-demo.mp4/.jpg +20张自测still，共22文件SHA保持。该冻结ZIP仅深色；当前main/App包已含PR #20的47套light视频/封面及20张浅色自测图；旧批次QA和历史验收保留，不能作为本轮全量真机结论。

## Git 与主线集成

本轮App最新运行提交 `79c172d` 及交付记录已推送 `origin/codex/adopt-ugk-trainer`，SDK修复 `d193a70` 已推送 `codex/hiplab-trainer-slots`（草稿PR #2）。两仓库main分别仍为 `99fcc83` / `9407bf3`，均未合本轮；手机已安装0.3.9+16，整节锁屏失败，不代表已合main或原生已通过。

**`mhgd3250905/HipLab` 是 HipLab App 主仓库，`main` 是后续开发基线。** 接手成果通过 #2、#1 合入 main，本机 main 跟踪 origin/main。图标版本 0.1.2+3 的代码提交为 `4cf5ca7`，通过 [PR #5](https://github.com/mhgd3250905/HipLab/pull/5) 集成；业务逻辑和视频资源保持，安装状态独立记录。

| 对象 | 核对结果（逐项日期另列，旧轮保留历史） |
|---|---|
| HipLab `main` | PR25来源8c985c4、SDK0.1.2及审核记录已获开哥同意并普通推送，集成ce7ab74，GitHub11:24:56确认MERGED；#22/#24及#19/#20/#21此前集成保持 |
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

紧侧加练、主题、iOS 配置和隐私入口已在 main 集成并推送，不再作为未合入功能。六个动作的逐帧证据均显示短暂淡入变暗；去除视频 CSS 双重淡入后，Chrome 原 H.264 新旧对照及循环/暂停/恢复通过，最终 Android 原生首帧仍待单独复验。完整训练、音乐 ducking 与全量媒体体验仍待验收；系统通知、iOS Mac 构建/真机和 CI 尚未完成。Android前台服务/TrainingHold已随PR24合入，正常播放及终态释放有原生证据；锁屏/耳机/蓝牙/ducking等扩展矩阵按用户最新要求不列本阶段门槛，未验项不改记通过。正式上传签名已在0.2.0+4验证；Play状态仅保留2026-10-17历史送审回执，本阶段未重新回读或上传。Android 彩色图标已实机验证，单色图层未做手机主题切换验证。事项统一维护在[开发事项台账](development-roadmap.md)。

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

## PR #22 审核（2026-10-19）

练习库 PR #22（head `a7992a6`）已按最新 main `243a812` 隔离审核，结论需要修改：7个合并冲突文件，查实1项P1与5项P2。原PR analyze0、286pass/1条件skip、Python18及两工具check通过；专项复现证实缺陷，未修复、未合并、未提交GitHub review，未构建安装或扩大真机验收。详见[审核报告](pr22-review-2026-10-19.md)。原main运行版本与设备记录保持。

### PR #22 修复复审（2026-10-19）

作者反馈新head `f7271f6`已合入目标main243a812，GitHub可合并。Windows复审原F1–F6闭环，analyze0、310pass/1skip、Python19、两工具check及49步骤独立剂量比对通过；另复现F7/P2：多组计次动作疼痛减半保护仍按1/2组判断，深蹲1次×3组减至8秒空转而不skip。结论仍需修改，未合并、无APK/真机新验收。[复审报告](pr22-reaudit-2026-10-19.md)。审核副本和新产物均在E盘。

### PR #22 F7复核（2026-10-19）

9fa0cc0对齐b12b0f5，F1–F7代码问题均关闭；Windows analyze0、322pass/1skip、Python19、两工具check通过，原F7独立复现由失败变通过。代码审核通过，D-29转待Android原生验收；尚未合并、无新APK/手机结果。[最新复核](pr22-reaudit-2026-10-19.md#最新f7复核通过2026-10-19)。

### PR #22 Android包已准备（2026-10-19）

准确基线b12b0f5及候选9fa0cc0的0.3.6+11 debug arm64 APK已在E盘构建并通过身份/签名/CRC/16KB对齐与音视频资源核对。用户安排先准备包、稍后接手机；本轮无ADB/安装/原生通过项，设备已安装事实保持原记录。D-29继续待原生验收，全部通过后仍需开哥同意才合并。[包身份与清单](pr22-android-acceptance-2026-10-19.md)。

### PR #22 Web补测发现F8（2026-10-19，待修复）

真实Web入口补齐非空状态升级、练习库/编辑、F3/F4/安全/F7、重复单练计时/记录与360宽2.0字号检查；新增P2：删除前项动画中打开后项剂量，返回按旧索引写回，覆盖第三动作，独立三步实测已确认并[评论PR](https://github.com/mhgd3250905/HipLab/pull/22#issuecomment-6266421023)。D-29转待修F8，尚未合并。Web口令循环初始片段在main基线也复现，声音内容不记通过；字号有P3截断。真实手机数据/语音/视频及系统矩阵仍待验，旧APK暂不作验收通过包。[完整结果与精简手测](pr22-web-acceptance-2026-10-19.md)。

## PR #24 Android后台语音审核（2026-10-19，待修复）

head e3655e5 / target main fcffded，Windows独立analyze0、277pass/1条件skip及debug arm64构建通过。专项复现两项P2：疼痛/暂停漏取消尾音与排队倒数、异步调音量缓存错误；main队列/控制器对照通过。另查实终态仍持有服务/CPU锁及旧STOP关闭新START的两项P2。GitHub OPEN/CONFLICTING，当前仅verification文档冲突。APK已在E盘校验，未安装/未ADB，无原生/iOS新增通过项，未合并；用户安排PR22 F8交作者处理。[完整审核与包身份](pr24-review-2026-10-19.md)。

## PR #22 / 2cc40e3 Android阶段复测（2026-10-19）

用户确认手机连接后已保留数据安装准确新head，原安装包9fa0cc0及偏好已留E盘；安装前后state JSON完全一致。Windows335pass/1skip、analyze0；F8主场景真机保存[B(2组),C]正确，连续双删稳定后编辑也正确，严格动画窗口点击边界单列未证实。另查实F9/P2：删除动画内立即保存使已删项重新出现，真机和150ms组件专项均失败、等待动画控制组通过。中文计次/保持各两轮记录准确；后台和英文锁屏的完成事件延迟到恢复后，不能记持续运行通过。当前手机安全锁屏需用户解锁，剩余英文/中断/ducking及实际听音待补。用户取消极大字号验收，显示已恢复，原中文/深色设置仍待解锁后恢复；不合并PR。[复测证据](pr22-native-retest-2026-10-19.md)。

## PR #24修复与#22组合进展（2026-10-19 22:00）

PR24固定0ccef6b原4项P2在源码/原失败专项闭环；与PR22 2cc40e3组合，并补同State重播的新TrainingHold交接。验证分支codex/pr22-pr24-validation的5725c36已推送；373pass/1条件skip、analyze0、Kotlin/APK身份检查通过。21:56:37组合包已保留数据安装，14键升级状态相同；正常单练两轮及再来一组完成，恰增2条记录，原8条/两组/设置/连续天数保持；两轮服务和CPU锁在收尾后释放，用户听音确认正常。当前手机中文、深色、正常字号，已回今日页。

PR22 F8关闭，F9删除后立即保存仍待作者修；PR22/24均未合并main、未approve，main本轮只推进文档。用户将当前原生门槛收窄为正常播放，不再扩展耳机/蓝牙/ducking/锁屏中断矩阵；旧失败不改记通过，iOS未验。已解锁、英文保持第二轮/闹铃中断/第三轮重播及原设置恢复均补齐，旧等待解锁描述为历史快照。[本轮精确身份与证据](pr24-reaudit-and-pr22-integration-2026-10-19.md)。


## PR22 F9复审完成（2026-10-19）

a586de3的F9原失败专项、8项新增与F8/键盘回归通过，组合9b22dcc的387pass/1skip、analyze0、APK及保留数据安装通过；真机唯一项/立即保存/连删/放弃关闭正确，正常字号搜索首次及视频详情返回均实际弹IME。全部非训练组字段、10条记录与另一测试组保持，仅既有测试组1按操作变化。F1–F9代码问题均关闭，当前验收范围内无已知阻断；仍未合main，等待开哥最终合并同意。旧“F9待修”均为历史快照，iOS与扩展矩阵不冒称通过。[复审报告](pr22-f9-reaudit-2026-10-19.md)。


## PR #22 / #24 主线集成完成（2026-10-19 23:32）

开哥明确同意后，main从ab1425b快进至已验候选b33ed21并普通推送；GitHub23:32:51确认22/24均MERGED（各mergeCommit为9b22dcc/5725c36）。来源a586de3/0ccef6b保持，主线运行内容与已安装9b22dcc相同。当前开发基线已包含练习库、自定义训练组/单练历史、PR24语音与按会话保活、重播hold适配和F1–F9修复。无新构建/安装/版本或商店动作；387pass/1skip及原生结果沿用，iOS未验。旧“待最终同意”均为历史快照。[合并确认](pr22-f9-reaudit-2026-10-19.md)。
