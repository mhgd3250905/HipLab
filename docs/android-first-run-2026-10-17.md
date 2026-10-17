# Android 首次实机运行（2026-10-17）

当前版本统一登记在[版本交付台账](version-ledger.md)；本页保留两次实机运行的详细证据，下方首次运行阶段的限制不代表高清更新后的当前状态。

已按用户“先跑安卓”的要求，完成调试版构建、真机安装和启动。此授权覆盖此前接手阶段暂不打包的工作边界。

## 高清素材更新：0.1.1+2

2026-10-17 13:15，按用户“更新到安卓 APP”的明确授权，通过 `adb install -r` 保留数据覆盖安装 `com.ugk.hiplab` 0.1.1 / versionCode 2，已回读包信息并冷启动成功。版本 0.1.0+1 的旧 APK 与未使用旧库别名素材已备份在忽略目录 `build/apk-history/`、`build/previous-media/`。

- 46 项动作（45 MVP + 1 备选）全部为真实 30 fps、1080×1080、H.264/yuv420p；另有 4.8 秒专用仰卧横跨自测剪辑，合计 47 对视频与 1080 封面，包内没有孤立媒体。
- 从通过原 QA 的透明 PNG 直接合成现有播放器背景 `#101013`，CRF18；46 条安装资源 SHA 与派生成品逐个相同，未二次转码，也未从绿幕抠图。绿幕及透明母帧继续保留。
- 6 项自测经真实 `AssessmentItem.demoArt` 解析均为视频；20 张评分静图、计分、教学、计时与侧别语义保持。
- `flutter analyze --no-pub` 无问题，`flutter test --no-pub` 49 项全通过；同步工具 11 项 Python 回归通过。`flutter build apk --debug --no-pub` 成功，Gradle 约 27.5 秒；Flutter/Dart 依赖锁未改。
- 覆盖安装前后 `FlutterSharedPreferences.xml` 609 字节逐字节一致，SHA256 `f4d1e8574c4dd8735f134c3186cf30fa4753f3e5a76065ce078c638618532596`。
- 真机训练页实际播放 `hip-n-pelvis-circle.mp4`，WebView 读回 1080×1080 / 8 秒 / readyState 4 / error null；1.5 秒间呈现帧从 155 增至 200，启动时掉帧数保持 2。已查看首页和训练页截图，退出测试训练返回首页。

本版 APK：`build/app/outputs/flutter-apk/app-debug.apk`，203,896,543 字节（通用调试版含多 ABI），SHA256 `a9dcd836a91452a309154ae6b1a4da7db5c72e086c8bb44e123cfaecad69a2ce`。本轮不是商店发布。安装、设置校验、真机播放 JSON 与截图位于 `build/android-update-20261017/`；自测独立核验在 `build/media-audit/assessment-hd-sync-audit.json`。

下方保留首次运行记录。

## 本次结果

- 设备：2602BRT18C，Android 16 / API 36，arm64。
- 环境：Windows，Flutter 3.44.7 / Dart 3.12.2，Android SDK 36，Android Studio JBR 17。
- 命令：`flutter run -d <设备序列号>`。
- Gradle `assembleDebug` 成功，约 83 秒；安装成功，约 6 秒。
- App：开胯训练助手，包名 `com.ugk.hiplab`，版本 `0.1.0+1`，debug 签名。
- 已确认 App 进程及可见 Activity 存在，查看手机截图确认安全引导页正常显示。
- 检查启动日志未发现 Flutter 未处理异常、Android 致命异常或资源加载错误。没有替用户填写安全问题或身份。
- 保留手机 App 运行，供用户体验。

## 产物

- APK：`build/app/outputs/flutter-apk/app-debug.apk`，95,489,848 字节。
- SHA-256：`EFA0EFD7E65E51A7C9F40D51937C83804411B4545CDF5248190425A9C48864F8`。
- 实机截图：`build/runtime-validation/android-first-launch.png`。

以上构建产物在 Git 忽略目录中，后续构建会覆盖。此次没有发布商店或合并远端 PR。

## 后续开发

连接手机后用 `flutter devices` 确认设备，再执行 `flutter run -d <设备序列号>`，可继续热重载调试。首次构建生成的 `android/.kotlin/` 是编译缓存，已添加到 `android/.gitignore`。

本次验收范围为构建、安装与启动；完整自测、训练交互、原生 WebView 视频播放及长期运行由后续体验验证。此前 48 项自动测试及 4 项 Widget 截图测试的记录见 [接手基线](project-takeover-2026-10-17.md)。
