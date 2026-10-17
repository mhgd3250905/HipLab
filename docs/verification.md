# 验证台账

当前 Android 基线为 **0.1.2+3 / `4cf5ca7`**，检查日期 2026-10-17。下表 V-01 至 V-13 保留 0.1.1+2 / `35f2a97` 的原始验证，新图标版本见本页末节。测试通过只覆盖所述范围，后续文档修改不会使旧检查变成新版本验证。

| 编号 | 范围 / 命令 | 已执行结果 | 证据与边界 |
|---|---|---|---|
| V-01 | `flutter analyze --no-pub` | 无问题 | 当前 App 代码基线 |
| V-02 | `flutter test --no-pub --reporter expanded` | 49 项通过 | 规则、界面、内容资源边界；不代表原生视频全量验收 |
| V-03 | `python -m unittest discover -s tools/tests` | 11 项通过 | 媒体同步、copy-ready 来源/SHA、帧率与参数保护 |
| V-04 | `flutter build apk --debug --no-pub` | 成功，Gradle 约 27.5 秒 | APK 大小/哈希见[版本台账](version-ledger.md)；未验证正式签名 |
| V-05 | 真机 `adb install -r`、包信息、冷启动 | 0.1.1 / code 2 正常启动 | `build/android-update-20261017/install-verification.json` |
| V-06 | 安装前后及播放后数据对比 | 设置文件 609 字节逐字节一致 | `smoke-preservation.json`；备份含用户数据，留本机忽略目录 |
| V-07 | 真机原生 WebView 播放 | `hip-n-pelvis-circle.mp4`：1080×1080、8 秒、readyState 4、error null；1.5 秒内呈现帧 155→200，掉帧数 2 不增 | `player-probe.json`，查看首页与训练页截图；仅一条实际播放样本 |
| V-08 | 全部交付片与 App 引用 | 46 主片逐条来源 SHA 相同；另有 1 自测剪辑，共 47 对 1080 视频/封面；6 项自测为视频，20 张评分图未变 | `build/media-audit/assessment-hd-sync-audit.json`、制作批次 `app-sync-verification.json` |
| V-09 | Android 派生片 | 46 条完整解码、138 次首中末像素检查通过 | `hiplab-android-20261017-v2/verification/`；不替代人工观感检查 |
| V-10 | 动作原 QA 与母版 | 最终选版 46/46 PASS | 原批次 43 PASS / 3 REVIEW，后续三项修订通过；选版清单排除旧失败候选 |
| V-11 | 3D-Body 冻结源验证 `node tools/drill-anim/verify.mjs` | 159 规格 / 51 原 App 动作 / 13 人体固定源通过 | 原规格、人体和 QA 保持；见[制作记录](local-hd-render-2026-10-17.md) |
| V-12 | 制作工具回归 | 前期 22 项通过；后续来源/不可变性/覆盖规格相关 6 项通过 | 属于分阶段记录，不能相加宣称一次最终全套 28 项通过 |
| V-13 | 初次接手截图测试 | 4 项通过，已查看四图 | 仅 0.1.0+1 接手阶段；高清更新后未重跑，不是当前版本的全量截图回归 |

具体实机过程见 [Android 记录](android-first-run-2026-10-17.md)。当前没有完成 iOS 构建/实机、商店上架、长期运行或 46 条手机端逐条人工观感验收。

## 媒体已知观察

最终坐姿体前屈使用 `hiplab-fix-fold-20261017-r3`：完整 240 帧原 QA 通过，穿透/触边为 0，左右手接触间隙在原门槛内。**63 条历史腕部可达范围警告仍保留**；原 QA 不把该警告计数作为失败门槛。不能写成“所有动作零警告”。抱膝 r1 与屈膝扭转 r1 各 240 帧通过且警告为 0。旧批次与 r1/r2 失败候选保留，未装进 App。

## 后续按改动验证

| 改动 | 必要验证 |
|---|---|
| 仅文档 | 相对链接、Git 差异和事实一致性；不重复构建 App |
| Dart 规则 / UI | 静态分析、相关回归和 Flutter 测试；涉及原生行为补真机 |
| 内容 / 媒体同步 | 来源和 QA、完整解码/参数、内容生成、资源边界测试；替换片真机播放 |
| Android 版本交付 | 构建、SHA、覆盖安装、版本回读、冷启动；核对数据和核心功能 |
| 计时修复 | 左紧/右紧/正常分配及暂停、跳过、疼痛降级回归；详见 D-01 |

检查失败先记录事实并修复；未完成检查留在事项台账，不能标“已验收”。本机 SDK 差异及 `--no-pub` 使用条件见[当前状态](current-state.md)。

## 文档管理建立检查（2026-10-17）

README、AGENTS 和 docs 共 14 份 Markdown 的 66 个相对文件链接均存在；版本 0.1.1+2、47 对视频/封面、47 条媒体元数据、当前 APK 字节数/SHA 和最终母版/Android 派生清单路径均已与本机文件核对。`git diff --check` 通过。本轮仅修改文档，没有重跑 Flutter、重建或重新安装 App；V-01 至 V-13 保持各自原始验证范围。

## 主线集成检查（2026-10-17）

#2、#1 合并前回读固定源和最新目标 SHA，合并后文件树均与已审 `14d754d` 完全一致。47 条视频 SHA 与元数据逐条一致，资源引用完整。状态跟进文档共 15 份 Markdown、76 个相对链接通过，`git diff --check` 通过；App、素材、工具、依赖锁与测试文件相对已验收 `35f2a97` 均无差异，沿用既有验证，无重复构建或安装。审核对象与回执记录在 `docs/mainline-integration-2026-10-17.md`。

## 0.1.2+3 图标与实机检查（2026-10-17）

代码基线 `4cf5ca7`：重新执行 `flutter analyze --no-pub` 无问题，`flutter test --no-pub --reporter expanded` 49 项通过，`flutter build apk --debug --no-pub` 成功（Gradle 18.8 秒）。29 个导出文件 SHA、20 张 density PNG 尺寸、4 份 Adaptive XML 及 APK 编译资源核验通过；旧/新 APK 签名验证及证书一致。

alpha≥8 阈值下，各 density 主体半径约 32.02–32.14dp，中央 66dp 安全圆越界数为 0；少量 alpha 1–7 的透明残留在圆外，如实保留。单色前景与彩色前景 alpha 各档一致。已查看圆形、圆角方形、主题色和 32/48/64px 预览。

Android 16 上 `adb install -r` 更新至 versionCode 3 / 0.1.2，冷启动正常、未观察到运行致命错误。安装前后、冷启动后和桌面检查后，1195 字节设置文件逐字节一致。查看 App 首页和 `com.miui.home` 桌面截图，确认新图标完整显示。证据位于 `build/android-icon-20261017/`；未切换手机系统主题，未做 iOS、商店或矢量验收。媒体及业务代码未改，本轮没有重复媒体解码与同步工具测试。

用户验收反馈（2026-10-17）：本次 Android 0.1.2+3 更新后，用户确认“测试通过了”。该反馈已登记至版本台账；其他独立待办的状态保持各自记录。本次台账更新没有新增自动测试结果或重新构建、安装。

## 第一轮修改检查（2026-10-17，`feat/polish-round1`）

沙箱 Linux，Flutter 3.44.7（`/workspace/work/hiplab-env.sh`），未做 Android 构建或真机安装。

| 范围 / 命令 | 结果 | 边界 |
|---|---|---|
| `flutter analyze` | 无问题 | 全仓库 |
| `flutter test --concurrency=1` | **82 项全部通过**（含 hip_flow 6、hip_ui_round1 13、hip_voice 23；main 基线 49 项全过，无基线遗留失败） | 不含 `test_screens/` 截图生成 |
| `hip_ui_round1` #4 | 360×740 文本 ×1.0/1.3/1.5、390×844 ×1.5，6 项自测底栏不重叠、无溢出 | 360×1.5 首页「我的髋部」卡 4px 溢出已真修：卡高随系统字号伸缩，空态内容 scaleDown |
| `hip_domain` 套 A 时长 | 断言更新为 350 秒 / 6 分钟 | 15 秒语音休息带来的预期变化，产品待定（D-12） |
| iOS `Info.plist` | `UIBackgroundModes = [audio]`，plistlib 解析通过 | 未在 iOS 上构建 |
| Android 常亮 | `wakelock_plus 1.8.1`，Gradle 配置 JVM 17 / compileSdk 跟随 Flutter，与 App 一致 | **未在本环境构建 APK**；下次 `flutter build apk` 时确认 |

需真机确认：视频首帧不闪、页面过渡流畅度、语音 ducking 与锁屏/后台（iOS 锁屏继续；Android 常亮期间继续、手动锁屏行为）、浅色主题观感。

## iOS 配置检查（2026-10-17，`feat/ios`）

沙箱 Linux arm64，Flutter 3.44.7 / Dart 3.12.2，**无 macOS/Xcode：未执行 `flutter build ios`、未上模拟器或真机**。分支含 #7、#8 全部内容。

| 范围 / 命令 | 结果 | 边界 |
|---|---|---|
| `flutter analyze --no-pub` | 无问题 | 全仓库 |
| `flutter test --no-pub --concurrency=1` | **104 项全部通过**（第一轮 82 + 新增 `hip_ios_test` 22） | 不含 `test_screens/` |
| `python3 tools/ios/check_ios_project.py` | OK | plist/xcprivacy/strings 解析，pbxproj OpenStep 结构、对象引用、文件存在、资源阶段、Bundle ID、iOS 15.0、仅 iPhone、AppIcon 尺寸与 1024 无 alpha、LaunchScreen 引用；不等于 Xcode 能编译 |
| `hip_ios_test`（iOS 目标平台） | 22 项通过 | 来电/拔耳机静默暂停、中断结束不自动继续、继续时 reactivate；4 种 iPhone 安全区（含反向验证探测器）；状态栏随主题；侧滑不能退出训练。系统音频行为用假输出模拟 |
| `test_screens/hip_ios_shots_test.dart` | iPhone 15 Pro / SE × 深浅主题共 72 张截图，已人工查看 | 叠加画的状态栏、灵动岛、Home 条为示意，不是系统渲染 |
| `player.js` 行为探针（Playwright Chromium，VP9 转码副本） | 静音自动播放、首帧事件、隐藏暂停、可见继续、宿主暂停后不自动播放均符合预期 | Chromium 而非 WebKit；未验证 H.264 / WKWebView |
| 合并 #8 后 `build_hip_content.py` | 生成结果与提交一致，无差异 | — |

需在 Mac/真机确认的项目见 [iOS 运行与上架说明](ios-setup-and-release.md#真机确认清单)。

## 语音播报审计检查（2026-10-18，`fix/voice-audit`，叠在 `feat/ios` 之上）

沙箱 Linux arm64，Flutter 3.44.7 / Dart 3.12.2，ffmpeg 7.1.5，edge-tts 7.3.1；**无 macOS/Xcode、无真机：iPhone 截断修复只经假平台单元测试验证，需真机复听**。详见[语音审计](voice-audit-2026-10-18.md)。

| 范围 / 命令 | 结果 | 边界 |
|---|---|---|
| `python3 tools/voice/audit_voice.py --raw`（分 10 片后 `--merge`） | 修复前 264/488 不通过（响度 197、真峰值 64、尾巴过短 41、长度不一致 21、manifest 偏差 21；截断/句中静音/骤降 0）；**修复后 0/488** | 对照同文本 edge-tts 原始输出；数据在 `docs/voice-audit-2026-10-18/` |
| 修复后响度 / 峰值 | zh -16.2…-15.9、en -16.5…-15.9 LUFS；真峰值 ≤ -1.2 dBTP | 循环到 ≥3 s 测量 |
| `flutter analyze --no-pub` | 无问题 | 全仓库 |
| `flutter test --no-pub --concurrency=1` | **115 项通过、1 项按设计跳过**（iOS 基线 104 + `hip_voice_playback_test` 11；`voice_timeline_export_test` 未设环境变量时跳过） | 沙箱单条命令限时 120 s，按文件逐个运行（12 个文件全部通过），不含 `test_screens/` |
| `hip_voice_playback_test` | 11 项通过 | 假平台模拟会话/播放器时序；不等于 AVAudioSession 真机行为 |
| `build_voice.py demo --lang zh --seconds 60` | 生成套 A 开头 60 秒混音（-17.1 LUFS 整段） | 仅混音示意，不经过 App 播放链路 |

真机复听清单见[语音审计 §5](voice-audit-2026-10-18.md#5-需要真机复听的条目)。
