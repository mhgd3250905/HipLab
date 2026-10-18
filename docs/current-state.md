# 当前状态

核对日期：2026-10-18，北京时间。此页维护当前事实；过程见[开发日志](development-log.md)，检查范围见[验证台账](verification.md)。

**Mac / iOS 补记（10:33）：** `ios/device-validation` 从 `origin/main@bb828be` 验证 **0.3.3+8**：analyze 无问题、156 pass / 1 skip，签名 Flutter Release 与 Xcode Archive 均通过。iPhone 16 Pro / iOS 26.5 的 CoreDevice 准备错误阻止安装，当前版本未上真机，11 项均待验收。此前 0.3.2+7 的 TestFlight 用户反馈与 09:43 正式送审是独立历史，本轮未操作 Apple；已推送文档提交 `668616f` 并创建 [草稿 PR #15](https://github.com/mhgd3250905/HipLab/pull/15)，未合并；详情见[iOS 本地验证记录](ios-device-validation-2026-10-18.md)。

## App 与设备

| 项目 | 当前状态 |
|---|---|
| 产品 / 包名 | 开胯训练助手 HipLab / `com.ugk.hiplab` |
| Android 已安装版本 | **0.3.2+7 debug / arm64**，Pose-Hub v0.1.0 接入后已保留数据覆盖安装；不是 Play 已发布版本 |
| 已构建版本 | **0.3.3+8 debug / arm64**，源码 `1b35657`，已构建并核验，尚未安装 |
| 已安装代码提交 | 手机仍为 `963db04` / 0.3.2+7；本轮运行源码 `1b35657dec153741e25ca095ac2764b18d14ac29` 仅构建，手机拔线未安装 |
| 正式 Android 图标 | 已选 B 站姿开髋，青玉绿/石墨底；普通、圆形、自适应及单色资源，已查看手机桌面确认彩色图标 |
| 用户验收 | 2026-10-17，0.1.2+3 更新测试通过；2026-10-18，用户已验收 0.3.1+6 单屏自测 UI。此验收不覆盖后来 CSS 修复的原生首帧 |
| 验证设备 | 2602BRT18C，Android 16 / API 36，arm64 |
| 产品范围 | 中文、离线；main 已含浅色/深色/跟随系统主题、中英语音、单屏自测布局及 iOS 配置。Android 已安装运行；iOS 0.3.3+8 本地 Release / Archive 已通过，当前版本安装与真机验收待设备连接恢复 |
| 动作素材 | 46 项动作已取用 Pose-Hub v0.1.0 的 1080 dark 视频/封面，共 92 文件；另保留 HipLab 自有 `supine-cross-demo` 视频/封面 |
| 自测素材 | 6 项自测均解析为视频；现有 20 张自测静图保留（含 #8 的 11 张修订），不在 Pose-Hub v0.1.0 ZIP / lock 内 |
| 运行验证 | 行为检查源 `162a4e6b78a8640d367cac13ef5e1ae6cfa9b33a`：analyze 0，Flutter 156 项通过、1 项按设计跳过；本轮 APK 构建成功，网页证据边界见下文；未执行 ADB / iPhone 验收 |

当前素材按仓库冻结的 `pose-hub.lock.json` / `tools/pose-hub-manifest.json` 取用。92 文件 `--check`、46 条视频 ffprobe、22 个保留文件及 APK 内资源检查通过；具体版本和检查证据见[版本台账](version-ledger.md)与[验证台账](verification.md)。浅色主题仍使用深色舞台，light 未发布；绿幕和透明母帧留在上游，App 不直接播放。历史 3D-Body 批次 QA 与体前屈 r3 警告保留在原验证记录，不能当成本轮全量真机验收。

## Git 与主线集成

**`mhgd3250905/HipLab` 是 HipLab App 主仓库，`main` 是后续开发基线。** 接手成果通过 #2、#1 合入 main，本机 main 跟踪 origin/main。图标版本 0.1.2+3 的代码提交为 `4cf5ca7`，通过 [PR #5](https://github.com/mhgd3250905/HipLab/pull/5) 集成；业务逻辑和视频资源保持，安装状态独立记录。

| 对象 | 2026-10-18 核对结果（历史日期另列） |
|---|---|
| HipLab `main` | 业务代码 `1b35657dec153741e25ca095ac2764b18d14ac29` 已于 2026-10-18 10:04 北京时间推送 main；PR #13：MERGED（a41e7e0）；PR #14：MERGED（4c563f9）；保留原 #7—#10 及 Pose-Hub v0.1.0 |
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

紧侧加练、主题、iOS 配置和隐私入口已在 main 集成并推送，不再作为未合入功能。六个动作的逐帧证据均显示短暂淡入变暗；去除视频 CSS 双重淡入后，Chrome 原 H.264 新旧对照及循环/暂停/恢复通过，最终 Android 原生首帧仍待手机重连后补测。完整训练、音乐 ducking 与全量媒体体验仍待验收；系统通知、Android 前台音频、iOS 0.3.3+8 真机验收和 CI 尚未完成（Mac 构建已通过）。正式上传签名已在 0.2.0+4 验证，审核通过与正式发布仍待后续。Android 彩色图标已实机验证，单色图层未做手机主题切换验证。事项统一维护在[开发事项台账](development-roadmap.md)。

## 第二轮集成快照（2026-10-18）

业务代码 `1b35657dec153741e25ca095ac2764b18d14ac29` 已于 2026-10-18 10:04 北京时间推送 main。运行源码 `1b35657dec153741e25ca095ac2764b18d14ac29`，版本 **0.3.3+8 debug**；行为检查源码 `162a4e6b78a8640d367cac13ef5e1ae6cfa9b33a`：analyze 0，Flutter 单并发 156 项通过、1 项按设计跳过。最终 APK 已构建，手机拔线未安装；Android 原生及 iOS 待验。PR #13：MERGED（a41e7e0）；PR #14：MERGED（4c563f9）。

临时独立网页预览在 320×568、360×740、390×844、768×1024 上检查正方形示范区、按钮 bounds、无滚动、六项自测及结果完成；点按暂停/继续、键盘、分段拖动、快速 Tab 和训练暂停/继续通过。预览使用 silent-voice fixture 与 poster stub；普通 DOM locator 仍因 Flutter semantics root 空白而超时，保留失败证据。坐标 page.mouse 操作通过且未使用 force；原生 widget hitTest 回归通过。这不构成原生媒体、H.264、系统音频或正式 Web 支持验收，也不据此诊断透明旧页遮挡。倒计时改为 33 ms tick；Chrome 18 屏的 17 个相邻环区域中，完全相同对数由旧 100 ms 的 5 对降至 0 对，采样约 47–79 ms，不代表真机帧时或帧率

[第二轮集成记录](round2-integration-2026-10-18.md)。本轮不上传商店，不改版本号以外的发布配置；没有新的手机安装或 native/iOS 通过结论。
