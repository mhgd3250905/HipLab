# 验证台账

当前手机为 **0.3.6+11 debug / arm64**（源码 `66f5da034c0cdac3341f3e80a57e3ddae5f95dce`），2026-10-18 19:29保留数据安装，版本/冷启动首页/浅色新滑块及1356字节偏好保持已确认；见本页对应追加记录。0.3.5+10完整试听确认属于历史，不扩展为本版听音验收。以下V-01至V-13保留0.1.1+2 / `35f2a97`的原始检查，0.1.2+3 / `4cf5ca7`等各版本按日期独立登记，不能当作当前版本重新执行的结果。

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

## 第二轮 UI 打磨检查（2026-10-18，`feat/polish-round2`）

沙箱 Linux arm64，Flutter 3.44.7 / Dart 3.12.2，基于 `feat/ios` `313b484`（含 #7/#8/#9）。**无 macOS/Xcode、无 Android 设备：未构建、未安装、未在真机看动画。**

| 范围 / 命令 | 结果 | 边界 |
|---|---|---|
| `flutter analyze` | 无问题 | 全仓库 |
| `flutter test --concurrency=1` | **116 项全部通过**（基线 104 全过，无遗留失败；新增 `hip_ui_round2_test` 12 项） | 不含 `test_screens/` |
| `hip_ui_round2_test` | 分段控件（深浅色）：滑块圆角 = 外圆角 − 内边距、选中无描边、切换中途滑块在移动、两个首页控件同尺寸同风格、沿轨道拖动可选；32 个图标描边/填充两态都有笔迹且不出 24 栅格、继承 IconTheme；主要页面不再出现 Material `Icon`；倒计时环 0% 顶部无点、50% 有弧；体检行内无媒体框、缩略图圆角与卡片同心；开始→播放页为容器展开且首页反向变化；Tab 按方向滑；右推进详情、iOS 左缘右滑返回；Hero tag 首页↔播放页、体检缩略图/标题↔自测页往返无报错 | 动画只能断言几何与类型，**观感与帧率需真机** |
| `test_screens/hip_ios_shots_test.dart` | iPhone 15 Pro / SE × 深浅主题 72 张，已逐张查看（无截断/溢出，对比度正常） | 叠加的状态栏/灵动岛为示意；**截图时不画阴影**（见下） |
| `test_screens/hip_icons_sheet_test.dart` | 图标总览与组件总览（倒计时环 0/35/80/准备 50%、开始按钮、圆形按钮、分段控件） | [图标/组件总览](images/polish-round2/icons-sheet.jpg) |
| `test_screens/hip_transitions_frames_test.dart` | 7 段过渡各 6 帧（展开、缩回、Tab 右/左、右推、返回、自测展开 + Hero） | [帧序列](images/polish-round2/transitions-frames.jpg)；帧按测试时钟均分，不代表真机帧率 |

截图说明：`flutter_tester` 渲染 `BoxShadow` 时不做模糊（画成硬边偏移色块，已用单独探针确认），之前浅色截图里卡片下的灰条就是这个伪影。截图脚本现在设 `HipColors.flatShadows = true` 不画阴影；App 本身不受影响，真机仍有柔和阴影。[改前/改后对比](images/polish-round2/compare.jpg)里“改前”仍带伪影。

**需真机确认：**
- 页面过渡与 Hero 的流畅度（120Hz ProMotion / 60Hz Android 各看一次），尤其“开始”容器展开与缩略图 Hero 同时进行时是否掉帧；
- iOS 左缘右滑返回：跟手、松手回弹/完成、与系统手势无冲突（目前仅“重新看安全提示”页是右推页；播放器/自测页本就禁止手势返回）；
- 分段控件拖动与轻触觉（`HapticFeedback.selectionClick`）；
- 浅色主题真机阴影观感（截图里看不到阴影）；
- 倒计时环每 100ms 重绘一次是否足够顺滑（如有阶梯感可把播放器节拍提到 33ms）。

## 第二轮主干集成复核（2026-10-18）

固定原 main `12f143868959187047ff7f7aaeff9f469dca0039`；#13 `d2e0286ffc0e402e0ddf0f80426536dc7192bca7`，#14 `217e058061325244de74f3155287b673e3247a57`，目标均 main。

| 检查 | 结果 | 限制 |
|---|---|---|
| PR #13 | analyze 0，136 pass / 1 skip；23 targeted 通过 | 导出测试未设置 VOICE_TIMELINE_OUT，未执行导出 |
| PR #14 初次合入 `4c563f9` | analyze 0，153 pass / 1 skip；APK 构建通过 | 后续控制语义及 33ms 更新另按 `162a4e6` 检查 |
| 独立素材 | 488 条，0 失败；UTF-8/cp936 报告往返通过 | 未重跑 --raw；一位小数 −1.2 不等于严格≤−1.2，实际 TP 门槛≤−1.0 |
| 行为检查源 `162a4e6b78a8640d367cac13ef5e1ae6cfa9b33a` | analyze 0；Flutter 156 项通过、1 项按设计跳过 | 不自动扩展到之后的代码变动 |
| 最终 APK | `1b35657dec153741e25ca095ac2764b18d14ac29` / 0.3.3+8；151,888,384 bytes / `9ec9dbe4df19f625f38ffabb6448c479525b21dc138c60e8ca16e23afa688506` | 未装手机；包名 com.ugk.hiplab、versionCode 8、预期 debug 证书及 488 条语音 / 92 个 Pose-Hub 资源 / 22 个保留文件核验通过；内容重生成无变化；Python 11 项及 iOS 工程静态检查通过。最终构建 26.96 秒，未安装手机 |

临时独立网页预览在 320×568、360×740、390×844、768×1024 上检查正方形示范区、按钮 bounds、无滚动、六项自测及结果完成；点按暂停/继续、键盘、分段拖动、快速 Tab 和训练暂停/继续通过。预览使用 silent-voice fixture 与 poster stub；普通 DOM locator 仍因 Flutter semantics root 空白而超时，保留失败证据。坐标 page.mouse 操作通过且未使用 force；原生 widget hitTest 回归通过。这不构成原生媒体、H.264、系统音频或正式 Web 支持验收，也不据此诊断透明旧页遮挡。倒计时改为 33 ms tick；Chrome 18 屏的 17 个相邻环区域中，完全相同对数由旧 100 ms 的 5 对降至 0 对，采样约 47–79 ms，不代表真机帧时或帧率

本轮没有 ADB、Android 原生复验或 iOS 系统行为新结论。详见[第二轮集成记录](round2-integration-2026-10-18.md)。

## Pose-Hub v0.2.0 接入验证（2026-10-18）

ZIP 39,151,634 bytes / `f422c051eab2b4e973fe637d5f2a3dec07207e21b960f10800efe77dd317c772`；下载云端冻结 manifest SHA `76be4160b48f1a8d658d558b30418fe11e686a241bdfd63d2b7ee8fa45012889`，均核验，安全解压92文件完成。

| 检查 | 本轮实际结果 |
|---|---|
| dry-run → sync → check | dry-run 92项计划；首次92 copied；check 92 matched /0 drift；重复同步0 copied |
| 46 视频 / 46 封面元数据 | 本机92文件大小/SHA全匹配；46视频H264/yuv420p/1080²/30fps/无音轨，11220帧；完整CPU解码通过；46封面均540²JPEG |
| 自有剪辑 /20张 still | hip-supine-cross-demo.mp4/.jpg +20张自测still，共22文件SHA保持 |
| 内容重生成 | 来源metadata更新后重生成hip-content.json逐字节不变；时长与poster_time均保持；旧来源完整快照及prior数组保留 |
| analyze | exit 0，无问题 |
| Flutter | 单并发156通过、1条件跳过（未设置VOICE_TIMELINE_OUT），exit 0 |
| Python | 本轮未重复；上一轮11项已通过，Python工具逻辑未改变 |
| iOS 静态 | 本轮未重复静态检查，ios/文件未改；Mac构建与iPhone仍待验 |
| APK 内容 / 身份 | 包名com.ugk.hiplab、versionCode9/versionName0.3.4、既有debug证书匹配；包内92新素材、22自有文件、488语音及共享播放器与源码匹配；未安装 |
| 临时网页 | Chrome实际共享player.html/player.js，青蛙式、90/90、抬脚、四足画圈、臀大肌、屈髋肌测试共6动作：首帧事件/opacity1/contain、至少一次循环、暂停无时间漂移和恢复通过，截图已查看；独立App预览换入新封面，320×568/360×740/390×844/768×1024正方形示范、按钮完整与无滚动、6项自测和结果完成通过。App预览仍为poster stub+静音fixture；键盘启用可访问性后坐标操作，非原生验收；未证明原生无黑闪或系统音频通过。 |

未登记结果不能视为通过。网页不等于 Android / WKWebView 原生合成、音频或 iPhone 验收；没有本轮 ADB。详见[Pose-Hub v0.2.0 接入](posehub-v020-integration-2026-10-18.md)。

## 指定媒体分支复核与合入后构建（2026-10-18）

`media/pose-hub-v0.2.0` 起于 `bb828be`，接入已推送成果后按本次要求将 sync 单文件保持为原基线逐字节一致，再快进合入 main。`1a1657d` 与已验证的 `03c3b5b` 在 `lib/`、`assets/`、`android/`、`ios/`、`pubspec.lock`、共用版本、媒体 lock 和 manifest 上无差异；未升级依赖。同步工具正文与发布提交 59fb7b9 相同，保留原 ee9d7ea 来源注释。

合入/推送后重新 `--check` 为 92 up to date / 0 drift，并重新构建 debug arm64 APK，exit 0，17.42 秒。包名/证书/92 媒体/22 自有文件/488 语音再次核验，APK 字节与上一份相同；来源及路径见版本台账。沿用同一运行内容已通过的 analyze 0、Flutter 单并发 156 pass / 1 条件 skip，以及四尺寸单屏正方形示范、无滚动、六项自测和结果、实际共享播放器六动作循环/暂停恢复记录；没有重复声称新执行全套测试。原生合成/听感与本轮 v0.2.0 iPhone 验收仍待补。


## Android 最新版安装与启动（2026-10-18 17:15）

用户重连真机并要求先安装最新版。2602BRT18C 从 0.3.2+7 保留数据覆盖更新至 0.3.4+9，`adb install -r` 成功；新旧 APK 签名一致，设备版本及前台进程均回读确认。安装后和首次启动后，1356 字节偏好分别与安装前备份逐字节比较一致；备份 tar 可读取，未清数据或回写偏好。冷启动 Status ok / 1677 ms，首页截图已查看，当前进程 crash 缓冲未见 FATAL EXCEPTION。

本次未点击训练、自测或设置，不把安装成功扩展为原生首帧、循环、完整语音、ducking、锁屏或 iOS 验收。此前“手机拔线未安装”是该阶段历史，本次安装事实以本节及版本台账为准。证据 `E:/AII-3D/hiplab-releases/android-install-20261018-171428/` 留本机。

## Android 静音场景语音修复（2026-10-18）

修复前试听轨道为 SONIFICATION 且被 streamVolume/portVolume 静音；修复后 MEDIA / SPEECH 活跃轨道无静音标记，手机铃声仍静音，用户确认“已经能完整听到了”。新增2项旧红新绿回归；适配层8通过，全套analyze0 / 158 pass / 1条件skip，debug arm64构建通过。0.3.5+10覆盖安装、启动、试听后偏好1355字节均与安装前当前备份一致。完整课程、长句、背景音乐ducking和系统矩阵没有因此标通过。证据及版本身份见[Android 静音模式语音修复](android-voice-media-routing-2026-10-18.md)。

## 浅色 / 深色样式核对（2026-10-18，main a60b623）

本轮为样式审查，未修改 App 代码、版本、依赖或安装手机。独立网页预览重新构建成功，33 个 lib/ Dart 文件与当前主线一致（入口仅注入静音语音）。390×844 实际查看安全引导、今日首页、进度/语音/外观、自测列表与选中态、浅色六项自测/补充选项/结果/路线弹层、播放准备/暂停以及隐私政策；主题 dark→light→dark 后缓存页配色更新。

确认待完善：① 首页时长/场景共用 HipSegmented 的 standalone 浅色特例没有浮起滑块阴影；② 隐私政策仍用默认 AppBar，返回图标、标题与共用 HipTopBar 不一致；③ 浅色部分绿色小字对比偏弱（jade 对白底3.204、选项浅绿底2.814，建议小字用 jadeDeep）；④ 引导/设置底部12px运动说明使用 faint，对浅色背景2.390，建议用 muted。自测选中边框/勾选/补充选项、方形示范及单屏布局存在；深色媒体舞台为既定素材约定，不计为遗漏。

本机完整报告与17张接受截图：`E:/AII-3D/3D-Hip/build/theme-audit-20261018/report.md`；颜色计算/源码比对：同目录 `audit-data.json`。均在忽略目录，未备份到远端。11/19截图未达稳定状态，不作缺陷证据；浅色播放页用12。网页使用海报stub/静音语音，未覆盖原生视频/声音、全部系统字号与屏幕尺寸、深色整页结果和完整无障碍检查，不替代此前待补的真机验收。本轮不新增版本、不重打APK。

## 0.3.6+11 样式修复复查（构建阶段，2026-10-18）

此前样式审查中的4项已完成代码修复：浅色首页浮起滑块、隐私共用顶栏、浅色绿色小字、底部说明。源码 `66f5da034c0cdac3341f3e80a57e3ddae5f95dce`。analyze 0；158 pass /1条件skip；隐私专项8通过；四尺寸网页自测选中态完整单屏；新debug arm64 APK构建及包名/签名/资源SHA核验通过。当时尚未安装，19:29安装结果见下一节；不将旧0.3.5+10试听确认当作本版真机验收。详细范围、产物和未验边界见[样式修复记录](theme-polish-2026-10-18.md)。

## 0.3.6+11 Android 安装复查（2026-10-18 19:29）

设备回读0.3.6+11，HipLab处于resumed，冷启动首页和浅色浮起滑块原生截图已查看。当前1356字节偏好与安装前一致；数据tar备份可读。没有执行训练/自测/试听或主题切换，完整功能及iPhone验收仍保持此前待验范围。报告及截图：`E:/AII-3D/hiplab-releases/theme-polish-20261018/install-20261018/`，用户数据和截图不入Git。

## 转场质量返工（2026-10-18，分支 fix/transition-quality）

基于 main `ee83628`。新增逐帧捕获工具（widget test 60 fps 截帧 + 拼图/MP4），14 个转场修改前后同场景录制并逐帧审阅，缺陷与修改见[转场审计](transition-audit-2026-10-18.md)。`flutter analyze` 0；全量 165 pass / 1 条件 skip（main 158 + 新增 7）；四尺寸单屏自测回归包含在全量内通过。仅在沙盒无头环境验证；未构建 APK、未安装手机，GPU 掉帧、原生视频视图参与容器变换、iOS 右滑手感待真机按审计文末清单验收。未合入 main。

## 按钮轻拟物统一（2026-10-18，分支 feat/tactile-buttons）

叠在 `fix/transition-quality`（PR #17）之上。从设置页分段控件选中块提炼共享材质 `HipTactile`，统一主 CTA、「开始」、次按钮、圆形图标按钮、分段选中块、底部 Tab 选中态、卡片内小按钮、播放器反馈按钮，去掉全部彩色外发光，详见[按钮样式审计](button-style-audit-2026-10-18.md)。`flutter analyze` 0；全量 178 pass / 1 条件 skip（165 + 新增 13）；四尺寸单屏自测回归在全量内通过；「开始」容器展开首帧截图与新按钮逐像素一致（新增测试）。仅沙盒无头 widget 测试截图验证；未构建 APK、未安装手机，真机渲染与掉帧待查。未合入 main。

## 0.3.6+11阶段收束检查（2026-10-18）

基线`9c0401505ed6d9e56715f3cce307406e38f68ed1`→入场`ee83628aaa1b9a53d545bbb061a0e203a6db8c40`。只读Preflight核对canonical、完整状态与证据源码后修正文档；`66f5da0`之后运行代码/测试/配置未变，复用前序analyze0、158pass/1条件skip、APK与19:29安装证据，不把本次文档HEAD说成新构建。本次必要检查为链接、事实、Git差异及完整状态；未重跑Flutter或操作手机。范围与依据见[阶段收束说明](theme-polish-2026-10-18.md#阶段收束2026-10-18)。

收束文档独立复核通过：9份Markdown未发现剩余确定finding，147处相对链接目标为Git已跟踪路径，选中文档内锚点匹配；代码相对已验证源`66f5da0`保持，完整工作区仅本轮9份文档和两项原有未跟踪文件，后者不纳入提交。

## 动作素材浅/深主题（2026-10-19，分支 feat/themed-action-media，沙盒，未合并、未安装）

| 范围 / 命令 | 结果 | 边界 |
|---|---|---|
| `flutter analyze --no-pub` | 0 问题 | |
| `flutter test --no-pub` | 198 通过 / 1 条件跳过（新增 `hip_action_media_test.dart` 7 项） | 含清单 SHA-256 逐文件校验、两主题素材齐全、主题切换重建视频 |
| `python3 -m unittest discover -s tools/tests` | 15 通过（新增 4 项） | `build_themed_media.py check` 通过：47 视频 + 47 封面 + 20 自测图 |
| `test_screens/hip_shots_test.dart` 深/浅截图 | 深色 18 张与改前逐像素一致；浅色无深色块 | `large text 1.5 on 360` 改前即溢出，未改 |
| 原生 WebView 播放浅色视频 | **未执行** | 沙盒 Chromium 无 H.264；待 Android/iOS 真机 |

## Windows复核修订：中途反向Tab连续性（2026-10-18）

按用户直接修复并推进合并授权处理F1，第1轮将Tab改为共享时钟，每次重定向从实际当前透明度和位移采样；保留持久slot、fade-through及媒体/焦点/语义策略。新增4项：零时间透明度与位移连续、三Tab快速重定向、减少动画无漂移。此固定分支analyze0，独立全量169pass/1条件skip；相关22项targeted通过。原失败证据在PR #17评论6251531461，修复后的组合Android原生验证与#18一起完成，不将本段写成已安装结论。未改依赖、lock、版本或商店配置。

## Windows复核修订：共享滑块按压（2026-10-18）

用户已授权修复后直接合并。F2第1轮让分段控件显式持有共享滑块按压/拖动/取消状态，滑块和文字同步缩放；减少动画仅保留材质下沉。材质释放与缩放统一180ms。新增9项回归覆盖正常/减少动画、移出/取消、拖动取消、纵向滚动、键盘选中语义、180ms释放及两个开始入口实际首帧。相关34项通过；组合analyze0、全量191pass/1条件skip（F1新增4、F2新增9），原审核6项现由日常回归覆盖。gallery 45/60模拟区改为小号分段与实际试听按钮，先前深浅2项生成通过。未改依赖、lock、版本或商店配置；后续组合APK与真机检查另记，不将本段当作已安装。

## PR #17/#18修复后验收与合并（2026-10-18）

初审两项P2及2pass/4fail保留为[历史审核](https://github.com/mhgd3250905/HipLab/blob/be782b74b3eefe782803aebf26b5224c33c0c3d7/docs/pr17-pr18-device-review-2026-10-18.md)。F1/F2均首轮运行修复；#17独立analyze0、169pass/1条件skip，组合6dd16ed analyze0、191pass/1条件skip，合并main另生成深浅gallery2pass。新回归共13项，两个原失败类别已转通过；零时间Tab前后图相同，深浅/移除动画的原生分段持按有变化、松开回原像素。连续单指流采样、快速Tab录屏及播放中关闭抽帧完成，当前进程无FATAL/E/flutter标记。保留数据覆盖安装，用户偏好1356字节与原始相同；未新增自测/打卡，系统设置还原。main顺序merge e98d0f1/aac4b1d与已安装6dd16ed运行内容相同，仅文档不重构建。低端帧时、强光、新结果页/iPhone仍保持待验，不扩大旧结论。[逐项与证据](pr17-pr18-fixes-and-merge-2026-10-18.md)。

## 轻拟物有选择引入（2026-10-19，分支 fix/tactile-curation）

基于 main `6020d8e`。按[审美考据](tactile-design-rationale-2026-10-19.md)收敛 #18：只保留分段控件滑块（neutral）与首页「开始」（accent）两处轻拟物；底部 Tab 完全恢复 #18 前样式；主 / 次 / 圆形 / 卡片内 / 播放器按钮回到改前扁平外观（主按钮去掉 jade 外发光，浅色圆形按钮以细描边替代旧柔阴影）；删除 `HipChipButton` 与 `glass` / `flat` 令牌。新增 `hip_tactile_budget_test`（深浅两主题、首页 / 自测 / 进度 / 设置滚动，断言拟物只在分段控件内、accent ≤ 1、Tab 无拟物且实心 / 描边图标正确），该测试在 #18 版本上运行会失败（已验证）。`flutter analyze` 0；全量 194 pass / 1 条件 skip；四尺寸单屏回归在全量内通过；「开始」与「开始自测」按住→松手容器展开首帧连续性测试通过（第一轮直接退回 Material 按钮导致「开始自测」首帧快照丢失，第二轮改为共享 HipPressable 平涂面后通过）。仅沙盒无头验证；未构建 APK、未安装手机。未改依赖、lock、版本或商店配置；未合入 main。


## 动作节奏与语音 + 动作包 v1（2026-10-19，分支 feat/rep-rhythm-voice）

基于 main `6020d8e`，沙盒 Linux、Flutter 3.44.7（本地 `.dart_tool/package_config.json` 的 `shared_preferences_android` 路径改为 lock 对应的 2.4.28，不入库；未改 pubspec.lock/依赖/版本号）。详见[节奏审计](rep-rhythm-audit-2026-10-19.md)与[动作包规格](action-kit-spec-v1.md)。

| 范围 / 命令 | 结果 | 边界 |
|---|---|---|
| `flutter analyze --no-pub` | 无问题 | 首轮 3 error + 1 warning：测试共享函数名 `loadLibrary` 与 Dart 延迟加载保留名冲突，改名 `loadVoiceLibrary` 后为 0 |
| `flutter test --no-pub test` | **236 pass / 1 条件 skip**（main 191 + 新增 45：`hip_rep_rhythm_test` 33、`action_kit_test` 5、`hip_player_transition_test` 7） | skip 为 `voice_timeline_export_test`（需环境变量）；不含 `test_screens/` |
| `python3 tools/action_kits/build_action_kits.py check` | 0 问题（含 JSON Schema 校验，jsonschema 4.26） | 46 个动作包结构、Pose-Hub 冻结 SHA、语音齐全、每句话放得进相位窗口、路线引用与秒数 |
| `python3 -m unittest discover -s tools/tests` | 13 项通过 | 含 `test_action_kits.py` |
| 四尺寸单屏（320×568、360×740×1.5、390×844、430×932） | 准备 + 休息期无溢出，在全量内通过 | 修复 360×740×1.5 “下一个”卡片训练期溢出 8 px（main 已存在） |
| 语音新条目 `audit_voice.py` | 92 条中 1 条提示（`en/sec.66` 尾音偏轻，兜底条目） | 原有条目未重生成 |

未执行：APK 构建、真机安装与试听、iOS。画面与语音只对齐周期未对齐起点（播放器无重播/倍速指令），需真机按 PR 内试听清单确认。
