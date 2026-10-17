# 当前状态

核对日期：2026-10-17，北京时间。此页维护当前事实；过程见[开发日志](development-log.md)，检查范围见[验证台账](verification.md)。

## App 与设备

| 项目 | 当前状态 |
|---|---|
| 产品 / 包名 | 开胯训练助手 HipLab / `com.ugk.hiplab` |
| Android 已安装版本 | **0.3.0+5 debug / arm64**，本轮三阶段均保留数据覆盖安装；不是 Play 已发布版本 |
| 已安装代码提交 | `c8057ad74c5a4cf60daad9419f6825dc53bad93c`，本地 `fix/android-round1-validation`；后续台账提交不改变 APK |
| 正式 Android 图标 | 已选 B 站姿开髋，青玉绿/石墨底；普通、圆形、自适应及单色资源，已查看手机桌面确认彩色图标 |
| 用户验收 | 2026-10-17，用户确认本次 Android 0.1.2+3 更新测试通过 |
| 验证设备 | 2602BRT18C，Android 16 / API 36，arm64 |
| 产品范围 | 中文、离线；main 为深色。`feat/polish-round1`（待合并）加入浅色/深色/跟随系统主题和中英语音播报；Android 已运行；iOS 配置在 `feat/ios`（静态验证完成），尚未在 Mac 构建与实机验证 |
| 动作素材 | 46 项动作全视频（45 MVP + 1 备选），另有 1 条专用自测剪辑，共 47 对视频/封面，均为 1080 |
| 自测素材 | 6 项自测均解析为视频；PR #8 更新其中 11 张自测静图；尺寸与来源见本轮集成记录 |
| 运行验证 | 构建、覆盖安装、冷启动和一条原生 WebView 视频播放通过；数据文件逐字节保持 |

当前 App 使用从透明母帧直接合成的 `#101013` 深色视频，1080×1080 / 真实 30 fps / H.264 yuv420p / CRF18。绿幕与透明母帧已保留，浅色主题已在本地集成版实现，媒体仍用深色舞台；运行时透明视频尚未实现。46 条通过原 QA，不等于逐条完成手机端人工体验验收；坐姿体前屈 r3 保留 63 条历史腕部可达范围警告，详见[验证台账](verification.md)。

## Git 与主线集成

**`mhgd3250905/HipLab` 是 HipLab App 主仓库，`main` 是后续开发基线。** 接手成果通过 #2、#1 合入 main，本机 main 跟踪 origin/main。图标版本 0.1.2+3 的代码提交为 `4cf5ca7`，通过 [PR #5](https://github.com/mhgd3250905/HipLab/pull/5) 集成；业务逻辑和视频资源保持，安装状态独立记录。

| 对象 | 2026-10-17 核对结果 |
|---|---|
| HipLab `main` | 已包含 App、高清素材与台账；首次业务集成提交 `656ee28daf1a0335f28c28fd2ac802e8dd20b6b7`，后续文档提交继续在其上集成 |
| [HipLab #1](https://github.com/mhgd3250905/HipLab/pull/1) | MERGED，`feat/initial-migration` → `main`，2026-10-17 13:59:40，merge `656ee28` |
| [HipLab #2](https://github.com/mhgd3250905/HipLab/pull/2) | MERGED，`codex/project-takeover` → `feat/initial-migration`，2026-10-17 13:59:14，merge `e52b3c2` |
| [HipLab #5](https://github.com/mhgd3250905/HipLab/pull/5) | 0.1.2+3 站姿开髋图标与安卓实机交付；已安装代码 `4cf5ca7`，具体合并 SHA 回读 GitHub |
| [3D-Body #119](https://github.com/mhgd3250905/3D-Body/pull/119) | 已合并，2026-10-17 10:29，merge `ae81d96f271a18129abbf6afc7064cfd9dd1d8c3` |
| [3D-Body #120](https://github.com/mhgd3250905/3D-Body/pull/120) | OPEN / draft，制作工具与修订规格 → `master`，源 `f8b5138` |

本地原先只抓取 `feat/initial-migration`，现已改为抓取所有远端分支。合并前后核验源 SHA、目标 SHA 和完整文件树，main 集成结果与已审核版本一致；原接手分支保留。细节见[主线集成审核](mainline-integration-2026-10-17.md)，日常更新见[工作流](development-workflow.md)。PR 状态是上述日期快照，操作前回读 GitHub。

## 本机环境和素材位置

| 位置 | 用途 |
|---|---|
| `E:\AII-3D\3D-Hip` | Flutter App、内容源、交付视频、开发台账 |
| `E:\AII-3D\3D-Body` | 既有源工程与输出，原工作区未提交文件未动 |
| `E:\AII-3D\3D-Body-worktrees\hiplab-hd-20261017` | 独立制作副本，`codex/hiplab-hd-20261017`，工具代码 `f8b5138fb377ec8cda464cfb08186fd696ca7921` |
| `E:\AII-3D\3D-Body\output\hiplab-delivery-20261017\selected-masters-46.json` | 最终 46 项母版选版清单 |
| `E:\AII-3D\3D-Body\output\hiplab-android-20261017-v2` | 当前 Android 派生片、来源与 SHA 核验 |

两端按用户交接统一 Flutter **3.44.7 stable / Dart 3.12.2**。本轮显式对齐该 SDK 的 13 项传递依赖与 lock 的 Dart 下限（原 #7 lock 要求 Dart 3.13），已通过分析、测试和构建；不是使用 3.47.7 或继续保留不兼容的 lock。Android SDK 36、JBR 17。

路径：Flutter `E:\flutter`，Android SDK `E:\Android\SDK`，ADB `E:\Android\SDK\platform-tools\adb.exe`，FFmpeg `D:\ffmpeg-master-latest-win64-gpl\bin`。实际渲染为 **RTX 4080 Laptop GPU 12 GB / ANGLE D3D11**。绿幕、透明帧和大批次输出位于本机忽略目录，未由 Git 备份；制作副本和输出仍需保留。

## 第一轮修改（2026-10-17，分支 `feat/polish-round1`，PR 待合并）

用户 14 条问题中，本分支完成 1（全 App 媒体圆角框）、2（自测首页重排）、3（视频首帧占位不闪）、4（「托马斯测试」改「屈髋肌测试」+ 大字体不重叠）、5（分侧项明确「现在测右边」、防重复点击）、7（标题并入顶栏）、9（无分侧动作不留空行；脚部渲染另修）、11（引导页专属主视觉 A 套）、12（统一过渡动效与预加载）、13（中英语音播报，edge-tts Xiaoxiao / Jenny 预生成 244+244 条）、14（浅色/深色/跟随系统）及 D-01 紧侧加练。问题 6、8、10 与 9 的脚部朝向属于媒体重做，在 `fix/motion-media` 分支。此为 PR 原阶段记录；之后已在本轮逐次构建、覆盖安装并抽查，完整跟练与音乐 ducking 仍待补测，见下节集成记录。

## iOS 版本（2026-10-17，分支 `feat/ios`，PR #9 待合并）

`feat/ios` 从 `feat/polish-round1`（#7，tag `round1-app-v1` → `44db1fe`）切出，合入 `fix/motion-media`（#8，tag `round1-media-v1` → `0d07587`，无冲突，`hip-content.json` 重新生成无差异），因此包含第一轮全部成果。iOS 里程碑 tag：`ios-v0.1-config`（工程身份）、`ios-v0.2-icon-launch`（图标与启动页）、`ios-v0.3-audio`（音频会话与中断）、`ios-v0.4-video`（WKWebView 示范）、`ios-v0.5-safearea`（安全区截图自查）、`ios-v0.6-docs`（说明与台账）。

Bundle ID `com.ugk.hiplab`、iOS 15.0、仅 iPhone 竖屏、中英显示名、SwiftPM（无 Podfile），站姿开髋 AppIcon、跟随系统的启动页，playback + 按句 duckOthers、中断自动暂停，WKWebView 示范锁屏回来继续。只做了静态检查与 iOS 目标平台 widget 测试，**未在 Mac/Xcode 构建，未上真机**；Mac 步骤与真机确认清单见 [iOS 运行与上架说明](ios-setup-and-release.md)。

## 本轮集成与送审边界（2026-10-17 更新）

原目录 `E:\AII-3D\3D-Hip` 保持 `codex/play-store-release` / `c20fae5`，原有 `.playwright-mcp/` 未动。隔离 worktree `C:\Users\29485\.codex\worktrees\hiplab-round1-android\3D-Hip` 在 `fix/android-round1-validation` 完成本轮修复与验证，**尚未推送，#7/#8/#9 尚未远端合并**；main 核对基线为 `9aeb268`，不能因手机安装成功写成 main 已更新。Mac 等实际合并后从 main 新建 `ios/…` 分支。

Play Alpha **0.2.0+4 / Submission ID 1** 已于 20:59 送审，当时为“审核中”，本轮未再次操作或回读 Console；#10 为待审 PR。新版本号 0.3.0+5 避免回退 code 4，本轮 APK 为原 debug 证书，仅用于真机覆盖验证，不是新的商店送审包。隐私政策页已保留并适配动态主题。详见[送审记录](play-store-release-2026-10-17.md)和[本轮集成验证](android-round1-integration-2026-10-17.md)。

后续素材按 [Pose-Hub 接入约定](pose-hub-adoption.md) 执行；目前无已发布素材版本，本轮未创建 lock 或切换同步来源。

## 当前限制

main 上紧侧加练计时缺陷仍在，修复在 `feat/polish-round1` 待合并；iOS 图标与工程配置在 `feat/ios` 待合并；系统通知、iOS 构建与真机验证和 CI 尚未完成；正式上传签名已在 0.2.0+4 验证，审核通过与正式发布仍待后续。Android 彩色图标已实机验证，单色图层未做手机主题切换验证。完整事项和验收要求统一维护在[开发事项台账](development-roadmap.md)，不继续把已完成的缺片或 Android 占位图标作为当前待办。
