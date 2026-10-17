# Android 首次实机运行（2026-10-17）

已按用户“先跑安卓”的要求，完成调试版构建、真机安装和启动。此授权覆盖此前接手阶段暂不打包的工作边界。

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
