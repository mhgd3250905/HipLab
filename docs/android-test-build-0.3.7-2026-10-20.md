# Android 0.3.7+12 测试包（2026-10-20）

**已从已合并的 main 构建带 AI 配置的 Android 测试包，尚未安装、未发布。** 用户要求打新版 App 测试；本轮只递增共用版本号，业务代码与[PR25 已通过复审的来源](pr25-reaudit-2026-10-20.md)一致。

| 项目 | 身份 / 结果 |
|---|---|
| 版本 | **0.3.7+12**（由0.3.6+11递增） |
| 构建源码 | `55d99b3d097afc815fa16e165362cf4703c440d5`，基于main `8c61893`；仅pubspec版本变化 |
| 已验业务来源 | `8c985c4c6dcff4207db616e759910ea03820ad79` / ugk_coach 0.1.2 / `26e3255` |
| 构建时间 | 2026-10-20 13:17，北京时间；Gradle50.7秒 |
| 包 | `hiplab-0.3.7+12-ai-arm64-debug.apk`，**175043055 bytes** |
| SHA256 | `4846f335c4a8f100b17c6b9548a46d950011baa57e93c035e9735e3d24c8e052` |
| 包名 / SDK | `com.ugk.hiplab`，versionName0.3.7 / versionCode12，minSdk24 / targetSdk36 |
| 签名 | 既有debug证书，SHA256 `3761270a4764157f0e389014a9e5b800b05403bfddce0f4f7f8c039f6a53bdc7`，与手机已验包连续 |
| 架构 | Flutter engine仅arm64-v8a |
| AI配置 | 从用户指定的本地文件读取App令牌，使用私有dart-define文件构建，已核验配置进入包；不提交凭据 |

APK及证据目录：`E:/AII-3D/hiplab-releases/hiplab-0.3.7+12-test-20261020/`。包含`apk-identity.json`、`apk-badging.txt`、`apk-signature.txt`、`prior-apk-comparison.json`、`build.log`和`pub-get.log`。本地构建参数与APK不随Git推送，本地路径不代表远端备份。

## 本轮验证

- `flutter pub get --enforce-lockfile`成功，lock未改变。
- `flutter build apk --debug --target-platform android-arm64 --no-pub --dart-define-from-file=<本机私有参数文件>`成功。
- 回读包名、版本号、min/target SDK和签名正确；ZIP CRC通过，打包的876个源资源逐字节匹配。
- 新旧审核包的ZIP条目集合相同，Flutter引擎及其余原生库逐字节相同；3个架构的libdartjni.so仅ELF build-id节不同，其余节一致。AI配置绑定已确认。
- `lib/`、`android/`、`ios/`、assets、tools、tests和lock与已验8c985c4一致，仅共用版本递增。因此沿用本机414pass/1条件skip、原6独立复现通过、analyze0以及SDK真实调用13.695秒/7动作结果；**本轮未重复运行Flutter业务测试或真实模型调用**，没有把沿用结果写成本次重新执行。

## 安装与测试边界

此次没有执行ADB、安装、清数据或商店操作；手机最后已核验安装仍为9b22dcc / 0.3.6+11。此包具备同包名、同签名及更高versionCode的覆盖条件，但保留数据升级与新功能真机结果须在实际安装后核验。

AI入口为「练习→我的→AI定制训练」。后续验证生成→开始训练/保存为训练组、断网回落，并保留原有训练组与记录。已记录的字号/键盘和语音系统待验事项仍按[PR25复审边界](pr25-reaudit-2026-10-20.md)保留，不因打包而变为通过。Play前台服务声明及其他发布配置未调整，未上传Play/App Store/TestFlight。
