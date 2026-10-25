# SDK 0.2.9：红米 release 安装回执

2026-10-26，用户接受单次手动切换 150ms 延迟，已记为 SDK 待办，HipLab 不处理。按指定测试分支 `codex/sdk-029-app-feedback-20261025` 的候选 `5351f42782be876a33aaaa59fad9ed19645192bc` 打包并保留数据安装。

## 包与来源

- **1.1.0+22**，包名 `com.ugk.hiplab`。构建源 `06c559cbd535744b35928c8fab5494348203770c` 相对 5351f42 仅将共用版本 +21 递增为 +22，运行代码、SDK lock、语音队列和前台服务未改。
- Flutter 3.44.7 / Dart 3.12.2；正常执行 `flutter pub get --enforce-lockfile`，再运行 `flutter build apk --release --target-platform android-arm64 --no-pub --no-android-gradle-daemon --android-project-arg=kotlin.compiler.execution.strategy=in-process`，157.6 秒成功。未传 AI Key。
- coach0.5.0 / trainer0.2.9 / coach_ui0.1.3 正式 tag 沿用[候选锁定结果](sdk-029-app-feedback-2026-10-25.md)，无 SDK 修改。

制品目录：`E:/AII-3D/hiplab-releases/sdk-029-redmi-20261026/`（本机产物，不进 Git，不代表远端备份）。

| 文件 | 用途 |
|---|---|
| `hiplab-1.1.0+22-arm64-upload-release.apk` | 既有上传证书签名的 release 编译结果；未上传商店。 |
| `hiplab-1.1.0+22-redmi-release.apk` | 同一 release 运行负载，沿用红米现有测试证书签名以保留数据覆盖安装；不是商店上传包。 |

安装包 104,437,388 字节，SHA256 `1ec9c7d5d7bc975cdab89bb5b39b95d20972c8b8d83ddbdedfbca34362806773`。v2/v3 验签和 16KB zipalign 通过；证书 SHA256 `3761270a4764157f0e389014a9e5b800b05403bfddce0f4f7f8c039f6a53bdc7`，与旧安装一致。密钥和 key.properties 未改、未入仓库。

## 安装与旧数据

只操作红米 `QSG6Q8IFDMDELVGQ`（2602BRT18C），所有 ADB 调用均显式带 `-s QSG6Q8IFDMDELVGQ`。`install -r --no-incremental` 返回 Success，包管理器回读 1.1.0 / 22；未卸载、清数据或操作另一台手机。UI 操作前核对 HipLab 前台，期间前台切换的尝试由保护拒绝，未在其他 App 点击。

| 本轮新鲜检查 | 安装前 | 安装后 |
|---|---|---|
| 累计练习 | 共 5 天 | 共 5 天 |
| 最近一次自测 | 进阶 · 10/12 | 进阶 · 10/12 |
| 语音音量 | 84% | 84% |
| 首次安装时间 | 2026-10-17 10:20:00 | 相同 |
| User 0 数据目录 inode（CE / DE） | 162220 / 58466 | 相同 |

正常启动，无重新引导。截图/XML、安装 Success、前后 dumpsys、`install-proof.json` 和旧 APK 在制品目录 `native/`。这是 UI 与安装元数据比对，不是完整私有用户数据备份，不声称逐条核对全部历史记录。本轮未新建训练、自测或训练组。

## 验证与收尾

沿用 5351f42 的分析 0、受影响 92/92 和 Web 证据；仅版本递增，不重复 App 测试。此次补充 release 构建、包身份、保留数据安装、启动及旧数据核对；没有重新完成整节训练、听音、锁屏或前台服务矩阵，不把历史未验项目改为通过，也不扩展极大字体验收。

本任务使用 E 盘独立 Gradle daemon 注册目录，禁用常驻 daemon，Kotlin 编译在进程内执行。收尾时在独立 `GRADLE_USER_HOME` 执行 `gradlew --stop`，返回 No Gradle daemons are running；本任务 wrapper/daemon PID 37020 / 33460 均已退出，无本任务 Java/JDK 残留。其他任务原有 Java 进程保留。证据见制品目录 `task-java-cleanup.json`。

只提交/推送测试分支的版本和回执；不合 main，main 保持 `1083b499ec2bec145c6227e5e64c6944ab5716a1`，远端 release/1.0 保持 `8880c71645163809b18c1829247c83e79bb99842`。原日常目录 31 项 WIP 保留，未操作 Play / App Store。
