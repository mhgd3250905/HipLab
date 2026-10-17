# 验证台账

当前手机为 **0.3.0+5 debug / `c8057ad`** 本地集成验证版，未推送或合并；新检查见本页末节。以下保留 **0.1.2+3 / `4cf5ca7`** 的历史基线，检查日期 2026-10-17。下表 V-01 至 V-13 保留 0.1.1+2 / `35f2a97` 的原始验证，新图标版本见本页末节。测试通过只覆盖所述范围，后续文档修改不会使旧检查变成新版本验证。

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

## 第一轮 Android 集成验证（2026-10-17，本地未合并）

按 #7 → #8 → #9 固定源预演集成，三阶段分别无静态问题、85 / 85 / 109 项测试通过，debug arm64 APK 均构建并覆盖安装成功。最终代码 `c8057ad`，版本 `0.3.0+5`；安装前后同证书、数据逐字节一致。iOS 工程静态检查通过，没有 Mac 构建或 iPhone 实机结论。源 SHA、APK SHA 与设备证据见[本轮集成验证](android-round1-integration-2026-10-17.md)。

真机四足画圈训练：暂停时 1.5 秒帧数增加 0，继续后增加 46，确认恢复未再次暂停；蝴蝶式自测示范增加 46 帧，切换到青蛙式后增加 44 帧，均 1080² / readyState 4 / error null。首页到训练与动作切换保存录屏及接触表抽查，不代表全量逐帧或完整跟练验收。政策页和公开邮箱可见；中英语音试听观察到本 App AudioTrack / 焦点请求，未据此断言人工听感通过。

用户明确选择音乐实测稍后：ducking、恢复和实际听感仍待补测。安卓只屏幕常亮，手动锁屏后的后台语音不保证；前台服务另开 `android/foreground-audio`。四足画圈高亮、全量动作人工观感、完整紧侧跟练与 iPhone 系统行为仍保留待验收。授权后每步实际合并仍重新 analyze、test、build APK 与覆盖安装，不能把本轮预演当作远端已合并。

## 主干、单屏自测与 Pose-Hub 验证（2026-10-18）

已按用户新授权实际集成并推送 main。GitHub 于北京时间 **01:01:06** 回读 #7/#8/#9/#10 均为 MERGED，源码 `9ef59a1`；四个原 PR 源头均是 main 祖先。每步合并后的 analyze 无问题、Flutter 单并发测试 **85 / 85 / 115 / 116** 项通过，debug arm64 APK 各构建成功并同证书保留数据覆盖安装。源头、合并及 rebase 细节见[整合记录](mainline-pose-hub-2026-10-18.md)。

单屏自测 `6177cc1` / 0.3.1+6 已获用户“我看过了，验证通过”。演示固定 1:1、视频和海报 contain，点按暂停/继续；标题置顶、去顶部圆点和视频进度条，选项及底部控件随可用高度布局。Flutter 回归包含 320×568、360×740、390×844、768×1024，以及大字号和六项自测；不滚动、不裁掉底栏，下一项恢复播放。

| 检查 | 结果 | 范围与证据 |
|---|---|---|
| ZIP 与 92 个资源 | 40,153,961 bytes、指定 SHA 一致；dry-run → 同步 → `--check` 退出 0，92 matched / 0 drift | v0.1.0 冻结清单，上游 `ee9d7ea`；缓存/ZIP 在忽略目录 |
| 媒体元数据 | 46 视频与 46 封面尺寸、SHA 均一致；视频 1080² / H.264 / 30fps / 8s / 240帧 | 8 个媒体文件实际更新，其他 84 个已匹配；无文件名/时长变动 |
| 保留文件与生成器 | 自有剪辑一对 + 20 张 still 共 22 文件逐字节不变；`hip-content.json` 重生成无差异 | light 不在包内，未删除或重渲媒体 |
| 真机六动作循环 | 四足画圈、青蛙式、滑垫侧向滑、分腿体前屈、90/90 抬脚及 90/90 自测均跨完整循环，error null | 初步 APK `963db04`；帧数增加分别 343/318/308/311/310/312；**首帧另见下文** |
| 最终源码检查与 APK | `9ef59a1`：analyze 0；`flutter test --no-pub --concurrency=1` 116 项通过；APK 成功 | 0.3.2+7 debug arm64，最终修复未在拔线后覆盖安装 |
| 原 H.264 浏览器回归 | 旧 CSS 红、修复绿；首帧 opacity 1 / transition 0s / readyState 4，跨循环、暂停稳定、继续推进 | `test/core/drill_media_first_frame_browser_test.cjs`，真实 Chrome；不代替 Android / WKWebView 合成验收 |
| 网页尺寸与交互 | 320×568、360×740、390×844、768×1024：正方形示范，选项/下一项均在屏内、无重叠，滚轮不改变答题页位置；六项切换、暂停/播放状态及结果页通过 | 仓库外临时 Flutter web 预览；网页视频是既有 poster stub；原生音频出现 `Platform._operatingSystem` UnsupportedError，未据此验收音频/系统行为 |
| 最终 APK 内容 | 92 个发布资源 + 22 个保留文件及修复后的 CSS/JS 均与源码一致 | 150,742,085 bytes，SHA 见[版本台账](version-ledger.md) |
| 工具与 iOS 静态 | Python 同步工具 11 项通过；`tools/ios/check_ios_project.py` OK | 未做 Mac/Xcode 构建或 iPhone 实机 |

原六段手机录屏逐帧复查发现 0.08–0.25 秒的交接变暗。`9ef59a1` 取消视频自身透明淡入，仅由 Flutter 海报淡出，Chrome 回归已通过。用户明确拔手机并改用网页测试，故 **Android 原生首帧最终复验待补**；不把解码正常或网页探针当作无闪验收。此前约 0.8 秒的口头估计已由逐帧时间校正。

测试结束恢复 5 分钟选择；只撤回测试生成的当天打卡，重启后原 1356 bytes 偏好逐字节一致、SHA `74f83f14c7ef77da8cdf08e6886a5401ee86aa325a7f653f68a3fea5b6b07c21`。证据位于仓库外 `E:\AII-3D\hiplab-releases\mainline-20261018`。音乐 ducking 按用户选择稍后；完整紧侧跟练、Android 手动锁屏后台、iPhone 系统行为继续保留待办。本轮没有新 Play 上传或 Console 状态回读。
