# iOS 运行与上架说明

更新日期：2026-10-18，北京时间。当前共用版本 **0.3.6+11**，Windows main `fce7ad8`；Mac 分支 `ios/main-ui-036` 已 rebase 对齐，补 iOS 隐私页平台适配，候选 `2f8aeb0` 的签名 Release / Archive 已通过，已保留偏好安装到iPhone 16 Pro，完成深浅主题、隐私页、单屏自测与视频/训练入口抽查；系统听音/完整11项仍待验。详情见[iOS 0.3.6 对齐与验证](ios-main-ui-036-2026-10-18.md)。固定 Flutter 3.44.7，冻结素材 v0.2.0，不升级 lock / 依赖；旧 0.3.3 的用户验收独立保留。

> 历史边界：原 #9 在 Linux 沙箱完成，彼时未执行 Mac/iPhone 检查。后续 Mac 已完成 0.3.3 首轮真机验证及本轮 0.3.6 本地构建；各候选结果分别记账，不将旧通过套用新版本。下文「已做」是静态检查与 iOS 目标平台的 widget 测试；凡是系统行为（后台、ducking、静音键、中断、WKWebView 首帧）都必须真机确认。

## 工程身份（已配置）

| 项目 | 值 | 位置 |
|---|---|---|
| Bundle ID | `com.ugk.hiplab`（与 Android 一致） | `ios/Runner.xcodeproj/project.pbxproj`（Debug/Release/Profile）；RunnerTests 为 `com.ugk.hiplab.RunnerTests` |
| 入口 | `lib/main.dart`（就是开胯 App，无需单独 scheme/xcconfig；仓库没有 `main_hip.dart`） | `flutter run` 默认 |
| 显示名 | 中文「开胯训练助手」、英文「HipLab」；`CFBundleName` = HipLab | `ios/Runner/{zh-Hans,en}.lproj/InfoPlist.strings`、`Info.plist` |
| 开发区域 / 本地化 | `developmentRegion = zh-Hans`；`CFBundleLocalizations` = zh-Hans、en | pbxproj、Info.plist |
| 版本 | `CFBundleShortVersionString = $(FLUTTER_BUILD_NAME)`、`CFBundleVersion = $(FLUTTER_BUILD_NUMBER)`，取自 `pubspec.yaml`（0.3.6+11 → 0.3.6 / 11）；Windows 统一递增，Mac 不自行升版本 | Info.plist；`flutter build` 生成 `ios/Flutter/Generated.xcconfig`（不入库） |
| 最低系统 | iOS 15.0（插件最高要求 13.0：wakelock_plus / shared_preferences / webview / package_info_plus；与 FlareLab 一致取 15.0） | pbxproj 三处 `IPHONEOS_DEPLOYMENT_TARGET` |
| 设备 | 仅 iPhone（`TARGETED_DEVICE_FAMILY = 1`），仅竖屏，`UIRequiresFullScreen` | pbxproj、Info.plist |
| 加密出口 | `ITSAppUsesNonExemptEncryption = false`（只有本机 127.0.0.1 回环 HTTP，无加密通信） | Info.plist |
| 权限 | 不申请任何权限，无 `NS*UsageDescription`；通知尚未接入（D-04） | Info.plist |
| 后台 | `UIBackgroundModes = [audio]`（训练语音锁屏继续） | Info.plist |
| 隐私清单 | 不追踪、不收集；`UserDefaults` 理由 `CA92.1`（shared_preferences 读写本 App 自己的设置）。各插件自带清单（shared_preferences、webview、wakelock_plus、package_info_plus） | `ios/Runner/PrivacyInfo.xcprivacy`（在 Copy Bundle Resources 中） |

**依赖管理：Swift Package Manager，不需要 CocoaPods。** Flutter 3.44 stable 默认启用 SwiftPM，6 个含 iOS 原生代码的插件（audio_session、just_audio、wakelock_plus、shared_preferences_foundation、webview_flutter_wkwebview、package_info_plus）都提供 `Package.swift`，所以仓库没有 `ios/Podfile`、也不用 `pod install`。`flutter run/build` 会生成 `ios/Flutter/ephemeral/Packages/FlutterGeneratedPluginSwiftPackage`（已忽略）。如果你的 Flutter 关了 SwiftPM（`flutter config --no-enable-swift-package-manager`），Flutter 会自动生成 Podfile 并要求 `pod install`，生成的文件按 `platform :ios, '15.0'` 检查后再决定是否提交。

## 在 Mac 上跑起来

前提：macOS + Xcode（含 iOS SDK 与命令行工具，App Store 上传对 Xcode/SDK 的最低版本以 Apple 当期公告为准）、两端统一 Flutter **3.44.7 stable**、Apple 开发者账号。版本和依赖由 Windows 统一管理，Mac 不单独升级。

```bash
git fetch origin
git switch main                # 使用已推送且包含 9ef59a1 的 main
git pull --ff-only
git switch -c ios/main-ui-036  # 只改 ios/ 与少量 iOS 专属平台代码
flutter --version              # 必须为 3.44.7 stable
# 先按 docs/README.md 校验 ZIP、恢复 v0.2.0 冻结素材并 --check
flutter pub get --enforce-lockfile  # 不修改 lock 或升级依赖
flutter analyze && flutter test --concurrency=1
open ios/Runner.xcworkspace    # 用 workspace 打开
```

新机器先完成 [README 新机器拉素材](README.md#新机器拉素材mac--windows) 的恢复步骤，再继续检查和构建。ZIP 根是动作 ID 文件夹，`--from-dir` 指向 `build/pose-hub/v0.2.0/extracted`；资源缓存不入库。Mac 仅恢复既定版本，不改 lock / manifest / pubspec 或生成新的素材版本。

Xcode 里：

1. 选 `Runner` target → **Signing & Capabilities**：勾 *Automatically manage signing*，Team 选你的开发者团队。Bundle Identifier 保持 `com.ugk.hiplab`（首次需要在开发者后台/自动签名时注册该 ID）。后台音频由 Info.plist 的 `UIBackgroundModes = audio` 生效（Xcode 中对应 *Background Modes → Audio, AirPlay, and Picture in Picture*），不需要也不要再加其他能力。
2. 不要改 `DEVELOPMENT_TEAM` 以外的签名设置后提交；团队 ID 是否入库由你决定（建议不入库，各自本机选）。

运行：

```bash
flutter devices
flutter run -d <你的 iPhone>                 # debug，入口 lib/main.dart
flutter run -d <你的 iPhone> --release       # 测锁屏/后台/性能用 release（debug 下息屏后调试器行为不同）
```

模拟器可看界面、安全区与启动页，但**后台音频、ducking、静音键、来电在模拟器上不可信**，必须真机。

归档上传：

```bash
flutter build ipa --release                  # 产物 build/ios/ipa/*.ipa 与 build/ios/archive/Runner.xcarchive
# 或 Xcode：Product ▸ Archive ▸ Distribute App ▸ App Store Connect
```

上传前在 App Store Connect 建 App（Bundle ID `com.ugk.hiplab`，主要语言建议简体中文），填隐私「不收集数据」、年龄分级、出口合规（已声明无非豁免加密，上传后不会再问）。建议在定价与销售里**关闭 iPad / Apple 芯片 Mac 上架**：本 App 只为 iPhone 设计（iPad 上会以 iPhone 兼容模式运行，审核仍可能在 iPad 上测，需保证可用）。

每次构建/安装/上传按[版本台账](version-ledger.md)模板追加记录；build 号随 `pubspec.yaml` 的 `+N` 递增，TestFlight 同一版本号下 build 号不能重复。

## 已集成的 iOS 配置（及原验证方式）

| 范围 | 内容 | 验证 |
|---|---|---|
| 工程身份 | 见上表；去掉 iPad 方向与 iPad 图标 | `python3 tools/ios/check_ios_project.py`：plist/strings/xcprivacy 解析、pbxproj 结构（括号、对象 ID 唯一且被引用的都已定义、文件引用存在、资源阶段、Bundle ID、最低版本、设备族） |
| 图标 | `tools/ios/export_ios_icons.py` 从 Android 同源透明前景（B 站姿开髋）确定性导出：#101316 满版方形、无透明、无预切圆角，iPhone 40/58/60/80/87/120/180 + 1024 | 同上脚本检查尺寸与 1024 无 alpha；导出清单 `design/app-icon/launcher-20261017/ios-export-manifest.json`（SHA）；人工查看预览 |
| 启动页 | `LaunchBackground` colorset：浅色 #F4F5F3 / 深色 #0C0D0F，跟随系统外观，与 App 默认「跟随系统」及加载帧同色；中央 120pt 透明人物；`Main.storyboard` 底色同色 | storyboard XML 解析、引用的 image/color 存在 |
| 音频 | `playback` 类别（静音键下也播放）；只在说话时 `duckOthers`，句间恢复其他 App 音量；静音片段循环保活后台；来电/Siri/闹钟/拔耳机：切断语音、训练静默暂停，中断结束重新激活会话，用户点「继续」恢复（再次激活，iOS 不保证发结束事件）；关闭 just_audio 内置中断处理（默认会在来电后重播旧句、拔耳机时暂停保活） | `test/hip/hip_ios_test.dart`（iOS 目标平台）：中断/拔耳机→暂停且不播「已暂停」，20 秒内计时不动，中断结束仍暂停，点继续后恢复并调用 reactivate；已暂停时中断不改变状态 |
| 屏幕常亮 / 锁屏计时 | `wakelock_plus`（iOS 为 `idleTimerDisabled`）在训练与自测页持有；训练计时按绝对时钟（`clock.now()` 减暂停时长），后台/锁屏回来直接落到正确阶段，过时的口令丢弃 | 既有 `hip_voice_test` 覆盖时钟/阶段；常亮与锁屏需真机 |
| 视频示范 | 保留 WKWebView + `player.js`：`allowsInlineMediaPlayback`、`mediaTypesRequiringUserAction` 为空（原已有）；`playsinline`、muted 属性与 property 同设、禁 PiP/AirPlay/开始播放按钮浮层，当前 `9ef59a1` 让 video 始终 `opacity: 1`，在 Flutter 海报下播放；首帧事件后只由 Flutter 海报淡出，去除双重淡入；锁屏/后台回来若宿主仍要播放则自动继续（原先会停住，Android 同受益）；关闭 WKWebView 前进后退手势，debug 可用 Safari Web Inspector。本地回环服务器已支持 Range/206（AVFoundation 必需）。未改 `video_player`：现方案已在 Android 真机验证、支持透明舞台，换原生播放器风险更大 | 原 #9 阶段：Playwright Chromium 驱动 `player.html`（当时使用 VP9 转码副本，该 Chromium 环境无 H.264）：需手势策略下静音自动播放、首帧事件、隐藏→暂停、可见→继续、宿主暂停后隐藏再显示不播放；`test/core` 路由/服务器 Range 测试。2026-10-18 又以 Chrome 原 H.264 完成新旧首帧对照、循环和暂停恢复；独立网页 UI 预览使用 poster stub，不是正式 Web 支持。**最终 Android 原生首帧与 WebKit 仍待补测** |
| 状态栏 | `UIViewControllerBasedStatusBarAppearance = true`，Flutter `AnnotatedRegion`：深色主题白字、浅色黑字 | hip_ios_test 断言 `statusBarBrightness` |
| 安全区 | 各页面原本就用 SafeArea/viewPadding | hip_ios_test：iPhone 15 Pro（59/34）、15 Pro Max、13 mini（50/34）、SE（20/0）下引导 3 卡、三个 Tab、自测题与结果、播放器准备/动作/暂停：固定控件和文字不进状态栏/灵动岛与 Home 条；列表滚到底最后一个控件在 Home 条之上；探测器做过反向验证（放大不安全区会报出） |
| iOS 返回手势 | 训练播放器 `PopScope(canPop: false)`，Cupertino 侧滑不能中途退出；自测/播放器为 fullscreenDialog | hip_ios_test 侧滑测试 |
| 截图自查 | `flutter test --no-pub test_screens/hip_ios_shots_test.dart`：iPhone 15 Pro 与 SE、深浅主题各 18 屏，叠加状态栏时间、灵动岛、Home 条和安全区线，输出 `test/_shots/ios/`（不入库） | 已人工查看两机型深浅主题 |

## 真机确认清单

在 Mac + iPhone 上用 release 构建，逐项记录机型、iOS 版本、结果，回填[验证台账](verification.md)：

1. **安装与外观**：桌面图标、名称（系统语言中文显示「开胯训练助手」，英文显示「HipLab」）；冷启动启动页在深/浅系统外观下颜色与 App 首屏一致、无闪白；在 App 里选了与系统相反的主题时，启动页后会切一次颜色（预期，记录观感）。
2. **安全区**：灵动岛/刘海机型和 SE 上首页、自测、结果、播放器、设置不被遮挡，底部按钮不压 Home 条。
3. **视频首帧**：首页卡、自测示范、播放器切换动作时，不出现原生播放按钮/灰底/白框，海报 → 视频无跳动；浅色主题同样检查；左右侧当前仍共用未镜像视频，水平镜像另列 D-18；不要将其当成已经实现的功能。
4. **后台语音**：开始训练后按电源键锁屏，语音按时继续，换边/倒数不丢；锁屏 3 分钟后解锁，计时与阶段对得上，动作示范继续播放。
5. **Ducking**：先在音乐 App 放歌再训练：说话时音乐压低、说完约 0.7 秒恢复；结束训练后音乐恢复原音量；不出现音乐被暂停（若被暂停记录系统版本）。
6. **静音键**：打开静音（铃声开关）后语音和提示音仍能听到（预期，健身跟练选 playback）；音量键调的是媒体音量。
7. **来电 / FaceTime / Siri / 闹钟**：训练中来电，训练自动暂停且不再播报；挂断后仍停在暂停，点「继续」语音恢复。Siri 唤起同理。
8. **耳机**：AirPods/有线耳机拔下或断开时训练暂停，语音不会从外放突然出来；重新连接点继续。
9. **常亮**：训练与自测页 2 分钟以上不自动锁屏；离开后恢复系统自动锁屏。
10. **自测**：自测页锁屏/切后台再回来的语音调度与视频恢复。当前实现已无可见倒计时环，指导口令按 `clock.now()` + `Timer` 调度并丢弃过时口令；旧 AnimationController 描述已失效，系统行为仍需听音验证，见 D-13。
11. **审核风险**：后台音频保活使用静音循环片段，训练期间确有语音播报；若审核以 2.5.4 质疑，说明为跟练语音提示，或考虑仅在语音开启时启用后台（当前：语音和提示音都关时不建立音频会话）。

## 已知待办

- **系统通知**（久坐提醒，D-04）未接入：iOS 需 `flutter_local_notifications` 或同类插件、首启后再申请权限、隐私清单与 Info.plist 无需额外 usage 描述（通知不需要），本分支不硬加。
- **团队 SDK / CI**（D-08）：两端固定 3.44.7，Mac 使用 `pub get --enforce-lockfile`，不单独改 lock；CI 仍待开发。
- **iPad**：仅 iPhone；若以后支持 iPad 需补方向、图标与布局。
- **正式矢量图标**（D-05）：iOS 图标由透明 PNG 前景导出，非矢量源。

## 第二轮共享代码需复验

#13 的 complete/duck/取消与 #14 的页面/音频 route 交接已做假平台和 widget 回归，仍需 iPhone 验证完整句尾、背景音乐恢复、来电/耳机、返回路由不结束新音频会话、WKWebView 隐藏停播及恢复。重点复听第二句后的长句、5–6 秒自测指导、准备→三二一→开始；英文 sec.5、a.item.deep_squat、drill.h-reverse-clam 等重限幅片段需检查音量、句尾与失真。整套课程完整复听，不能只听开头。

页面过渡/Hero 流畅度、iOS 右滑返回的跟手与回弹、浅色真机阴影/触觉以及 33 ms 倒计时 tick 的实际观感均待原生设备；Chrome 环区域比较不等于 native 帧率。原第 9 PR 的静态配置与历史 VP9/Chrome 探针记录保留，不能作为本轮系统行为验收。见[第二轮集成记录](round2-integration-2026-10-18.md)。


## 共用版本更新历史（2026-10-18，Android音频通道修复）

当时 Windows 已统一递增至 **0.3.5+10**，Android usage由系统提示音改为MEDIA；iOS playback/mix/duck与焦点生命周期未改，回归测试保留其原策略。该历史阶段没有新iOS构建或验收，没有商店上传。当前0.3.6+11的Mac构建与检查见本文开头及版本台账，不沿用历史阶段的“未构建”结论。
