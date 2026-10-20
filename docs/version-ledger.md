# 版本交付台账

**2026-10-20 PR25修复审核构建（未安装）：** 运行源8c985c4，0.3.6+11带令牌debug arm64，200749347bytes，SHA256 `33f54f20f47b3b25357b4ee83bb6a57620b1d3167b1a878e15a8a3f8a09b3636`，原debug证书连续。产物在E盘复审目录；主线未合入、版本未递增、未发布，手机仍按10月19日最后已验记录。见[复审](pr25-reaudit-2026-10-20.md)。

仅登记实际产生的构建、安装或发布。文档提交不增加 App 版本；“安装成功”“PR 合并”“商店发布”分别记录。时间均为北京时间。

**最新实际交付：0.3.6+11 debug / arm64**，构建源码 `9b22dccc2bf2ca269a67b408198b9e3e9dbb742b`；2026-10-19 23:15:53保留数据安装。APK为174,518,862bytes，SHA256 `f40f5956fa3bdae49872e525fced310257102c6b4f7638eb28911e18ec4b91bd`；身份及安装过程见本页末尾“PR22 F9 / PR24组合复审包”。该运行内容已随b33ed21合入main，本次文档收束不新增构建、安装、版本或商店发布记录。

此前0.3.6首轮交付摘要（历史）：源码 `66f5da034c0cdac3341f3e80a57e3ddae5f95dce`，2026-10-18 19:29保留数据安装。下表为2026-10-17早期交付历史。

| 版本 | 交付日期 | 状态 | 内容与证据 |
|---|---|---|---|
| 0.1.0+1 | 2026-10-17 | Android debug 首次安装、启动通过 | 原迁移基线 `2865ed7`，首次安全引导截图；[首次运行记录](android-first-run-2026-10-17.md)下半部分 |
| 0.1.1+2 | 2026-10-17 13:15 | Android debug 保留数据覆盖安装、冷启动、视频播放通过 | 应用提交 `35f2a977530bdcc6ab7e7caa9aa1d76dfe0bc53d`；46 动作 + 1 自测剪辑、47 张封面升级至 1080；[更新记录](android-first-run-2026-10-17.md)上半部分 |
| **0.1.2+3** | **2026-10-17 14:37** | **Android debug 保留数据安装、冷启动与桌面图标确认通过** | 应用提交 `4cf5ca7990949d025e02f13fc83e468f8bab9d07`；用户选 B 站姿开髋，普通/圆形/Adaptive/Monochrome 资源；[图标交付](app-icon-sports-2026-10-17.md)、[PR #5](https://github.com/mhgd3250905/HipLab/pull/5) |
| **0.2.0+4** | **2026-10-17 20:59** | **正式签名 release 已上传；Alpha Submission ID 1 状态“审核中”；尚未审核通过或正式上架，用户真机仍为旧版** | `codex/play-store-release` / `19aa388`，已推送并创建 [PR #10](https://github.com/mhgd3250905/HipLab/pull/10)，main 未合并；analyze 无问题、50 项测试及 API 35 模拟器实播/断网政策通过；[送审回执](play-store-release-2026-10-17.md) |

以上版本均非商店发布。0.1.1+2 通过 [HipLab #2](https://github.com/mhgd3250905/HipLab/pull/2)、[HipLab #1](https://github.com/mhgd3250905/HipLab/pull/1) 集成至 main（首次业务集成 `656ee28`），该次安装基线为 `35f2a97`。后续图标版本 0.1.2+3 由 PR #5 记录；不能将文档提交或合并当成重新构建、安装。

## 本轮追加：送审与本地集成

| 版本 | 日期 | 状态 | 身份与边界 |
|---|---|---|---|
| 0.2.0+4 | 2026-10-17 20:59 | Alpha 已送审 | 正式上传证书，Submission 1 当时为审核中；源码 `19aa388`，#10 未合并；[送审回执](play-store-release-2026-10-17.md) |
| **0.3.0+5** | **2026-10-17** | **三阶段 debug APK 构建、保留数据安装通过** | #7 + 修复 `3eb175d` → 加 #8 `025f675` → 加 #9 `c8057ad`；本地验证分支未推送/未合并/未送审；[本轮记录与三个 SHA](android-round1-integration-2026-10-17.md) |

最终 APK：`E:\AII-3D\hiplab-releases\round1-validation-20261017\stage3-pr7-pr8-pr9\hiplab-0.3.0+5-debug-arm64.apk`，176,624,651 bytes，SHA256 `28143d19339b9d28c3ec65c5e200423a8b76a05e0acd2427dd596f5bf80a66d7`。原 0.1.2+3 debug 证书一致；安装前后 1359 bytes 设置文件一致。音乐实测用户选择稍后；该 APK 不是新的 Play 产物。

## 0.1.1+2 产物身份

| 项目 | 值 |
|---|---|
| 包名 / versionCode | `com.ugk.hiplab` / `2` |
| APK 归档路径 | `build/apk-history/hiplab-0.1.1+2.apk`，相对于仓库根目录 |
| 类型 / 大小 | debug 通用多 ABI / 203,896,543 字节 |
| SHA256 | `a9dcd836a91452a309154ae6b1a4da7db5c72e086c8bb44e123cfaecad69a2ce` |
| 原始动作源 | `175ff31c29895f5730fc344519da6cbe1108ab30`，已由 3D-Body #119 合并；三项派生修订及工具见 #120 `f8b5138` |
| 最终母版选择 | `E:\AII-3D\3D-Body\output\hiplab-delivery-20261017\selected-masters-46.json` |
| Android 派生批次 | `E:\AII-3D\3D-Body\output\hiplab-android-20261017-v2`；逐条元数据见 [hip-media.json](../tools/hip_content/source/hip-media.json) |
| 设备 / 数据 | 2602BRT18C / Android 16；覆盖安装前后 609 字节设置文件逐字节一致 |
| 验证 | 静态分析无问题、Flutter 49 项、同步工具 11 项、原生 WebView 一条实播；详见[验证台账](verification.md) |
| 本地证据 | `build/android-update-20261017/`；`build/media-audit/assessment-hd-sync-audit.json` |

APK 会被下次构建覆盖，以上 SHA 用于识别本次产物。旧版 APK 已归档到 `build/apk-history/hiplab-0.1.0+1.apk`，95,489,848 字节，SHA256 `efa0efd7e65e51a7c9f40d51937c83804411b4545cdf5248190425a9c48864f8`。本地 APK、截图和设置备份不在 Git 中；用户数据备份不得提交仓库。

## 0.1.2+3 产物身份

| 项目 | 值 |
|---|---|
| 包名 / versionCode | `com.ugk.hiplab` / `3`，旧版与新版 debug 证书 SHA 一致，均通过签名验证 |
| 代码提交 | `4cf5ca7990949d025e02f13fc83e468f8bab9d07`，其后的文档/设计状态更新不改变已安装应用 |
| APK / 归档 | `build/app/outputs/flutter-apk/app-debug.apk` / `build/apk-history/hiplab-0.1.2+3.apk` |
| 大小 / SHA256 | 204,100,257 字节 / `1790469a46ac1b0195599a92c419baa3bb1c4b143dd8027bfd79d93d7a840c64` |
| 图标 | 用户认可 B 站姿开髋；五档普通/圆形，v26 Adaptive，v33 Monochrome；[原图、前景与导出](../design/app-icon/launcher-20261017/README.md) |
| 构建与检查 | analyze 无问题，49 项 Flutter 测试通过，Gradle 18.8 秒；29 文件 SHA、20 PNG 尺寸、4 XML 和编译入包层核验通过 |
| 安装与显示 | 2026-10-17 14:37，`adb install -r` 成功，Android 16 冷启动正常；`com.miui.home` 桌面已查看新图标，App 首页正常 |
| 用户验收 | 2026-10-17，用户在本次更新后反馈“测试通过了” |
| 数据保持 | 本次安装前设置为 1195 字节，安装后、冷启动后、桌面检查后逐字节一致；SHA `21bee487722bef25928b8541a26dc1959773ee6be5db42b487f6adc77c292255` |
| 本地证据 | `build/android-icon-20261017/`：APK/安装/桌面核验 JSON、编译图标 XML、日志与截图；用户数据与截图不入 Git |
| 未验证 | iOS 图标/构建、正式矢量、商店发布、设备端主题图标切换；单色资源已做导出/离线预览 |

## 0.2.0+4 Play 准备阶段（2026-10-17）

正式上传 key 的 release 构建已产生，包名 `com.ugk.hiplab` / versionCode `4`。源码已提交为 `codex/play-store-release` / `19aa388`，开工 HEAD `9aeb268`；该代码提交对应本次最终构建源码，包含正常网络权限用于 loopback 媒体读取及离线隐私政策入口。analyze 无问题、50 项 Flutter 测试通过；API 35 模拟器 host GPU 的 release 实际播放及断网隐私页验证通过，用户真机仍安装 `0.1.2+3` debug。

| 项目 | 最终产物身份 |
|---|---|
| 本地归档目录 | `E:\AII-3D\hiplab-releases\0.2.0+4`，仓库外部本机目录 |
| AAB | `hiplab-0.2.0+4-release.aab`，102,859,951 字节；SHA256 `36468F42FAED30F98C56E4F229BE41B92C744745C81BA2F66E5C0C9ABC3AE747` |
| APK | `hiplab-0.2.0+4-release.apk`，103,992,845 字节；SHA256 `75ED33E237D0CF5B74ED14F5BC7DC6BBE45BC208A64A5C6FE2BE472928C07902` |
| 签名核验 | AAB `jarsigner`、APK `apksigner` 通过；上传证书 SHA256 `8f8c114e8e1f8650d3e461abaf2a1c719e11ab390bb0ba285c87bb072433b7ad` |
| 验证设备 | `emulator-5554` / API 35 / host RTX 4080 GPU；用户真机未覆盖 |
| 非敏感运行证据 | 上述目录下 `release-verification-20261017`，详情见[验证台账](verification.md) |
| 16 KB 页对齐静态检查 | SDK 36 `zipalign -c -P 16 -v 4` 通过；三种 ABI 共 9 个 `.so` 的 ELF 对齐及 AAB/APK 库身份检查通过；未做 16 KB 内核设备运行验收 |

产物和签名材料保存在本机，不代表已备份到远端。Play 商店资料、素材和内容声明已保存，Alpha AAB 平台处理完成；20:59 确认将 15 项更改送审，提交活动回读 **Submission ID 1 / 状态“审核中”**。尚未审核通过或正式上架。详见 [Play 送审记录](play-store-release-2026-10-17.md)，本节不把构建、安装、送审和正式发布互相替代。

## 后续登记模板

新交付在版本表追加一行，并按下列字段记录；未执行项写“未执行”，不能用预计结果填充。

```text
版本 / versionCode：
时间 / 构建类型 / 签名类型：
代码提交 / PR / main 是否已集成：
改动与关联事项 ID：
APK 或 AAB 路径 / 字节数 / SHA256：
媒体批次（如有变化）：
检查命令、结果与证据路径：
安装设备、数据保留结果（如执行）：
已知问题、未验证范围：
商店发布状态（如执行）：
```

## 0.3.1+6 / 0.3.2+7 主干交付（2026-10-18）

| 版本 / 源码 | 产物与状态 | 验证 |
|---|---|---|
| 0.3.1+6 / `6177cc1` | 单屏自测 debug arm64 已安装，用户确认看过、验证通过；后由 `05ac3d7` 合入 main | 固定正方形 contain、标题置顶、去圆点/进度条、点击暂停继续；115 项测试及 analyze / APK 通过 |
| 0.3.2+7 / `963db04` | Pose-Hub 初步 APK，同证书保留数据安装，当前手机仍为此源码 | 116 项测试、analyze、APK；六动作完整循环通过，录屏发现首帧交接变暗 |
| **0.3.2+7 / `9ef59a1`** | **首帧修复最终 APK 已构建并推送 main；用户拔手机，尚未覆盖安装此修复** | **116 项单并发通过、analyze 0、Chrome/H264 回归通过；四尺寸网页单屏检查通过，原生首帧复验待补** |

单屏 0.3.1+6 APK：`E:\AII-3D\hiplab-releases\assessment-demo-20261018\single-screen\hiplab-0.3.1+6-debug-arm64.apk`，150,802,408 bytes；SHA256 `618da12ec15a304c28920fb5c669c3ddfc7b00a90c794d409c763e24d685568d`。

| 0.3.2+7 产物 | 字节数 / SHA256 |
|---|---|
| 已安装初步版：`E:\AII-3D\hiplab-releases\mainline-20261018\posehub\hiplab-0.3.2+7-debug-arm64.apk` | 150,739,180 / `d1fcb0843b0078034db8ef0143708ec54d912b1d14b015cef7262b7c8f42ed18` |
| 最终修复版：`E:\AII-3D\hiplab-releases\mainline-20261018\final\hiplab-0.3.2+7-debug-arm64.apk` | **150,742,085 / `6509ecca36162afc92737e3d3628c075b13c22d2814717763e6142df501fdfe1`** |

包名 `com.ugk.hiplab`，versionCode 7，最终 APK apksigner 核验成功，debug 证书 SHA256 `3761270a4764157f0e389014a9e5b800b05403bfddce0f4f7f8c039f6a53bdc7` 与手机既有版本一致。安装阶段原 1356 bytes 设置逐字节保持；六动作测试产生的当天打卡已单独撤回，重启后原设置 SHA `74f83f14c7ef77da8cdf08e6886a5401ee86aa325a7f653f68a3fea5b6b07c21`。

main 按 #7/#8/#9/rebased #10 集成，四 PR 均回读 MERGED；素材固定 Pose-Hub v0.1.0、`--check` 92 / 0 drift；详见[主干交付记录](mainline-pose-hub-2026-10-18.md)。本节是本机 debug 交付，未生成或上传新的 Play release；0.2.0+4 / Submission 1 保留其原始送审状态。

## 第二轮 APK 交付（2026-10-18）

| 项目 | 实际结果 |
|---|---|
| 版本 / 类型 | 0.3.3+8 / debug arm64 |
| APK 运行源码 | `1b35657dec153741e25ca095ac2764b18d14ac29` |
| 行为检查源码 | `162a4e6b78a8640d367cac13ef5e1ae6cfa9b33a`：analyze 0，Flutter 156 项通过、1 项按设计跳过 |
| APK 路径 | `E:/AII-3D/hiplab-releases/round2-20261018/final/hiplab-0.3.3+8-debug-arm64.apk` |
| 字节数 / SHA-256 | 151,888,384 / `9ec9dbe4df19f625f38ffabb6448c479525b21dc138c60e8ca16e23afa688506` |
| 包与签名 / 资源核验 | 包名 com.ugk.hiplab、versionCode 8、预期 debug 证书及 488 条语音 / 92 个 Pose-Hub 资源 / 22 个保留文件核验通过；内容重生成无变化；Python 11 项及 iOS 工程静态检查通过。最终构建 26.96 秒，未安装手机 |
| 安装 | 未安装；手机仍为 `963db04` / 0.3.2+7，本轮无 ADB |
| 远端 | 业务代码 `1b35657dec153741e25ca095ac2764b18d14ac29` 已于 2026-10-18 10:04 北京时间推送 main；PR #13：MERGED（a41e7e0）；PR #14：MERGED（4c563f9） |

PR #13 阶段源码 `a41e7e0`、C 盘两次缓存失败及 E 盘同 SHA 构建成功保留在[第二轮集成记录](round2-integration-2026-10-18.md)，不覆盖其 151,821,564 bytes 阶段 APK，也不混用早期候选 APK。没有新商店上传或审核回执。

阶段产物均未安装：#13 `a41e7e0` / 0.3.2+7（151,821,564 bytes），#14 `4c563f9` / 0.3.2+7（176,826,741 bytes），后续候选 `162a4e6` / 0.3.2+7（176,826,917 bytes）；各 SHA-256 与检查结果见[第二轮集成记录](round2-integration-2026-10-18.md)。

## Pose-Hub v0.2.0 App 产物（2026-10-18）

| 项目 | 结果 |
|---|---|
| App版本 / 源码 | 0.3.4+9 / `03c3b5bcd1ebc0157e3789af21a4bf0188f52468` |
| APK | `E:\AII-3D\hiplab-releases\posehub-v020-20261018\validation\hiplab-0.3.4+9-debug-arm64.apk` |
| 字节数 / SHA | 150,880,644 / `ded02ba1f26c263c6e0d8c88d62a4b0fe43f6e6a5dba9a29baf6ba21773d4e75` |
| 媒体 | v0.2.0，46视频1080 /46封面540 |
| 核验 | 包名com.ugk.hiplab、versionCode9/versionName0.3.4、既有debug证书匹配；包内92新素材、22自有文件、488语音及共享播放器与源码匹配；未安装 |
| 安装 / 远端 | 未安装，无ADB；业务代码 `03c3b5bcd1ebc0157e3789af21a4bf0188f52468` 已于 2026-10-18 11:40 北京时间推送 main |

上一轮0.3.3+8及手机0.3.2+7记录保留；不是商店包，不新上传商店。详见[Pose-Hub v0.2.0 接入](posehub-v020-integration-2026-10-18.md)。

## 指定媒体分支合入后的复打包（2026-10-18 11:55）

| 项目 | 实际结果 |
|---|---|
| 分支 / 起点 | `media/pose-hub-v0.2.0` / `bb828be`；已快进集成原有 v0.2.0 成果并合回、推送 main |
| 构建源码 / 版本 | `1a1657da91ea4b2d2a189e1439f370ed6d083e24` / **0.3.4+9 debug arm64** |
| APK 路径 | `E:\AII-3D\hiplab-releases\posehub-v020-request-20261018\final\hiplab-0.3.4+9-debug-arm64.apk` |
| 字节数 / SHA-256 | 150,880,644 / `ded02ba1f26c263c6e0d8c88d62a4b0fe43f6e6a5dba9a29baf6ba21773d4e75` |
| 实际构建 | 合入并推送 main 后执行 `flutter build apk --debug --target-platform android-arm64 --no-pub`，exit 0，17.42 秒 |
| 包与资源核验 | 包名 `com.ugk.hiplab`、versionCode 9、既有 debug 证书匹配；92 新素材、22 自有文件、488 语音及共享播放器匹配源码 |
| 与前包关系 | 与 `03c3b5b` 的 0.3.4+9 APK 逐字节一致；本次只恢复未变工具的原来源头并补分支/文档，按版本规则不再次递增 |
| 安装 / 发布 | 未安装、无 ADB；未上传商店或 TestFlight |


## Android 0.3.4+9 保留数据覆盖安装（2026-10-18 17:15）

| 项目 | 实际结果 |
|---|---|
| 设备 / 包名 | 2602BRT18C / Android 16 / arm64；`com.ugk.hiplab` |
| 更新 | 0.3.2+7 → **0.3.4+9 debug**，`adb install -r` 返回 Success，设备回读 versionName 0.3.4 / versionCode 9 |
| APK 源 / 主线 | `1a1657da91ea4b2d2a189e1439f370ed6d083e24` / `5c7dc8e`（后者仅文档收尾） |
| APK | `E:\AII-3D\hiplab-releases\posehub-v020-request-20261018\final\hiplab-0.3.4+9-debug-arm64.apk`，150,880,644 bytes；SHA-256 `ded02ba1f26c263c6e0d8c88d62a4b0fe43f6e6a5dba9a29baf6ba21773d4e75` |
| 签名连续 | 新旧 APK 均为既有 debug 证书，SHA-256 `3761270a4764157f0e389014a9e5b800b05403bfddce0f4f7f8c039f6a53bdc7` |
| 数据备份与保持 | 安装前备份 shared_prefs/files/databases/no_backup 中实际存在目录，tar 4,204,032 bytes、可读取；偏好 1356 bytes，安装后及启动后逐字节一致，SHA-256 `74f83f14c7ef77da8cdf08e6886a5401ee86aa325a7f653f68a3fea5b6b07c21` |
| 启动 | COLD / Status ok，TotalTime 1677 ms；App 前台，首页已查看，当前进程 crash 日志未见 FATAL EXCEPTION |
| 检查范围 | 仅安装与启动；未进入训练/自测，未测试原生首帧或系统音频，未上传商店 |
| 本机证据 | `E:\AII-3D\hiplab-releases\android-install-20261018-171428`；含原包、签名、数据备份、安装与启动日志、版本回读、截图，均留本机，不代表 Git 备份 |

## Android 0.3.5+10：静音场景语音修复与安装（2026-10-18 17:36）

源码 `b3bd499a6eba1b2c4c72dc6625b6257d9288a5f7`；修复 Android 音频 usage，版本0.3.4+9 → **0.3.5+10**。APK `E:\AII-3D\hiplab-releases\android-audio-fix-20261018\validation\hiplab-0.3.5+10-debug-arm64.apk`，150,885,612 bytes，SHA-256 `9aec5a354e2a521ea791822cb64b403c293d901c41849efe137645b562e51a33`。同包名/同debug证书覆盖安装成功，设备回读versionCode10；安装、启动、试听后1355字节偏好保持（以安装前当前数据为基线）。用户确认完整试听恢复；未上传商店。构建和检查、原生证据及未验范围见[Android 静音模式语音修复](android-voice-media-routing-2026-10-18.md)。

## 0.3.6+11：浅色控件与文字、隐私顶栏（2026-10-18）

业务源码 `66f5da034c0cdac3341f3e80a57e3ddae5f95dce`。`flutter build apk --debug --target-platform android-arm64 --no-pub` 成功（Gradle 23.1秒）；同包名、既有debug证书，versionName0.3.6/versionCode11。APK `E:/AII-3D/hiplab-releases/theme-polish-20261018/hiplab-0.3.6+11-debug-arm64.apk`，150,886,340 bytes，SHA-256 `78e766d76a083a519d703a88001a26cbfe8d8193d55125b2393f5a1d80ceb4f8`。包名/签名/ABI与114媒体/488语音+5提示音核验通过。analyze0；158pass/1条件skip；网页复查通过。**构建完成时尚未安装**，手机当时为0.3.5+10；19:29安装见下一节。未上传/发布商店。见[样式修复记录](theme-polish-2026-10-18.md)。

## 0.3.6+11 安装追加（2026-10-18 19:29）

同上已归档APK（源码`66f5da0`，SHA-256 `78e766d76a083a519d703a88001a26cbfe8d8193d55125b2393f5a1d80ceb4f8`）经`adb install -r`返回Success，从0.3.5+10更新至0.3.6+11，设备2602BRT18C / Android16，冷启动首页及浅色滑块已查看。当前偏好1356字节在安装/启动/截图后保持，SHA-256 `b4ac5a3817155431b4a0b445fd12d8941852ea99fafd86956f0da153a505a5a4`；完整数据tar已备份且可读。本次未重构建、未修改版本、未上传商店。

## 0.3.6+11初审组合验证包（2026-10-18，历史）

源5711b42，150,894,768bytes，SHA256 `e79052fd4015935ed6f1e72b230213d2f9814846919d3ff0bbad5c26be225847`，曾保留数据安装用于#17/#18初审。发现两项P2，当时未合main；该包已被下述修复包替代。[原审核与数据边界](https://github.com/mhgd3250905/HipLab/blob/be782b74b3eefe782803aebf26b5224c33c0c3d7/docs/pr17-pr18-device-review-2026-10-18.md)。

## 0.3.6+11转场与按钮修复包（2026-10-18）

源码 `6dd16eda246657d1de8ddf9e92b8e91d992c3a80`；包名与debug签名连续，Gradle49s构建。APK `E:/AII-3D/hiplab-releases/pr17-pr18-fixes-20261018/hiplab-0.3.6+11-pr17-pr18-fixed-debug-arm64.apk`，150,903,412bytes，SHA256 `34bae5ac3a17a1906f390336e17292a5ba7078d0f822413c9a2a25e822286c0a`。`install -r`成功，设备0.3.6/code11，冷启动1316ms；测试前/安装后/复查后1356字节偏好相同。#17/#18随后23:35:52/23:36:26顺序合入main，运行内容保持。本轮版本未递增、不上传商店；[完整证据](pr17-pr18-fixes-and-merge-2026-10-18.md)。

## 0.3.6+11 PR #19/#20/#21 隔离构建与模拟器安装（2026-10-19，未合main）

两份APK均源于 `e3fb1d31d3d490dbe46afe5f0461f6d273dba404`，包名 `com.ugk.hiplab`，版本仍0.3.6+11。使用 `flutter build apk --debug --no-pub --target-platform android-arm64` / `android-x64` 构建，Gradle分别125.9秒、46.3秒。仅命令环境 `GRADLE_OPTS` 关闭Kotlin增量编译，未为构建修改项目配置、依赖或lock。

| 产物 | 字节数 / SHA-256 | 当前安装边界 |
|---|---|---|
| `hiplab-0.3.6+11-pr19-pr21-arm64-debug.apk` | 174,333,226 / `fb959b061a09f907e826a846dae2badca397f735d02603621b3841b834e2e785` | 已构建，未安装手机；较上一轮150,903,412bytes增加23,429,814bytes |
| `hiplab-0.3.6+11-pr19-pr21-x64-debug.apk` | 213,174,642 / `292c7b4fb7aa0a5e85546d8d642e46ae0e9eb9b6eaf57ec52dd524eed4f33051` | 已安装专用AVD `codex_hiplab_pr19_21_api35`；不代表手机更新 |

两份签名证据均为既有debug证书SHA-256 `3761270a4764157f0e389014a9e5b800b05403bfddce0f4f7f8c039f6a53bdc7`。本机目录 `E:/AII-3D/hiplab-releases/pr19-pr21-review-20261019/` 保存上述APK、`apk-identity.json`、`apk-build-arm64.log`、`apk-build-x64.log`、`apk-arm64-signature.txt`、`apk-x64-signature.txt`；不代表远端备份。

构建之后仅补主题媒体工具的封面时刻防漂移check及mutation回归，最终Python19通过，themed-media/action-kit检查均通过；没有改变App或资产，APK来源仍为e3fb1d3，不因工具/文档改动重新构建。两段录屏698帧未发现全卡黑屏/中部单色空白候选，逐秒图与原图未见内容脱离圆角；录屏和模拟器GPU色差限制见[审核报告](pr19-pr21-review-2026-10-19.md)，不作为物理真机或iOS结论。

用户本轮改用模拟器。专用AVD为Android15/API35、1080×2400/density420，WebView124.0.6367.219；原有 `codex_api35` 正式0.2.0包未覆盖。手机安装状态沿用上次源6dd16ed的记录，原记录本轮未操作。原生训练、主题切换与休息反馈已进行，模拟器9个合成场景后已停止，按用户最新安排转Web复核、晚上再真机；最终模拟器验收由[审核报告](pr19-pr21-review-2026-10-19.md)补记。尚未合main或推送，需本轮最后同意；未上传商店。

### 最终晚间arm64候选（c7def28）

`hiplab-0.3.6+11-pr19-pr21-c7def28-arm64-debug-repacked.apk`：**174,329,762 bytes**，SHA-256 `7fdbdf81f567d064d2dcab356494087a552913a32812f3a4c80c091a767ec678`，包名com.ugk.hiplab、0.3.6+11，沿用上述debug证书。构建含字体运行修复，未安装手机/AVD。命令仍debug/no-pub/android-arm64；首次构建69.1秒，发现增量APK含37,584,896 bytes ZIP空洞（总211,931,209 bytes）后，仅删除隔离副本的单个生成APK并重建33.2秒。重新打包的1478条ZIP项大小/CRC与原c7包完全一致，Flutter引擎仅arm64，未改源码、依赖或配置；APK v2签名校验、16KB页对齐检查通过。异常包保留为本地调查历史，不作为晚间安装候选。

本轮晚间候选比上一轮6dd16ed包增加23,426,350 bytes；与早期本轮e3arm64差−3,464 bytes，不能把含空洞的增长归因素材/字体。候选保存在本机`E:/AII-3D/hiplab-releases/pr19-pr21-review-20261019/`，不入Git；身份与打包日志也在该目录。晚上仅在确认连接、备份及身份后覆盖安装，保留现有记录，不清数据。

## 用户真机安装及简单测试反馈（2026-10-19）

本会话向用户交付`hiplab-0.3.6+11-pr19-pr21-c7def28-arm64-debug-repacked.apk`，用户随后报告“真机安装、简单测试通过”。运行源`c7def2869b789357b303d69d66eb8c18a0a748ae`，包名com.ugk.hiplab、0.3.6+11 / debug arm64 engine，174,329,762bytes，SHA256 `7fdbdf81f567d064d2dcab356494087a552913a32812f3a4c80c091a767ec678`，沿用既有debug证书。本次未重新构建、重命名版本或发布商店；APK本身继续留本机忽略目录，Git仅保存身份和记录。

证据来源是用户在当前会话的安装及简单测试反馈，非Agent再次ADB安装或仪器核验；设备型号/WebView、本机安装后版本、测试明细、备份及用户数据保持未重新核对，不推断这些项目已通过。原“未安装”段落保留为构建时历史；本轮交付现更新为用户报告已安装/简单测试通过。main仍`6020d8e8bf26700e56785b029ef8d5ef4a379f2c`，审阅分支`codex/pr19-pr21-validation`保存组合修复；尚未合入main或上传商店。

## 0.3.6+11 对应代码合入main（2026-10-19）

用户随后明确要求推进合并，#19→#20→#21及五项修复随已审核合并链普通push至main；业务集成点`b9646d4a15b4e3727d8e11ea5ee3106f0e396603`。GitHub于2026-10-19 14:00:39北京时间（06:00:39Z）确认三PR均MERGED，merge依次2b552fd/18bf4ce/b6fd55e；[完整合并身份](pr19-pr21-review-2026-10-19.md#pr-19--20--21-主线合并确认2026-10-19)。运行内容与上述用户收到的c7def28 APK一致，本次没有新构建/安装/版本递增/商店上传；用户简单真机通过和完整专项未验范围保持独立。

## 0.3.6+11 PR #22 原生验收包准备（2026-10-19）

准确源b12b0f5基线及9fa0cc0候选均已构建debug arm64，包名/版本/debug证书连续，CRC/16KB对齐和575音频/94视频校验通过。基线174,333,322bytes，SHA256 `5502ec69e77d81ee42309f1265904e963c1c8a45e405ebb50f60153510653a3c`；最终候选174,483,026bytes，SHA256 `ce978c5f7ae92fe4ab19587040faf638183bef868dd54e06c572bff01beeca1b`。两包位于`E:/AII-3D/hiplab-releases/pr22-android-acceptance-20261019/`，完整文件名及打包过程见[验收准备](pr22-android-acceptance-2026-10-19.md)。用户安排先准备包、稍后接手机；两包均未安装，无ADB操作，未递增版本或上传商店。

### PR #22 Web验收构建追加（2026-10-19）

同样准确两源在E盘临时Web壳构建真实lib/main.dart，未替换产品lib/依赖/入口；字号专项另包裹2.0 TextScaler，产品哈希不变。版本仍0.3.6+11，没有新APK、手机安装或商店动作。Web补测发现F8/P2待修，前述9fa APK不记验收通过；修复后需新候选来源与包身份。[来源/结果/证据](pr22-web-acceptance-2026-10-19.md)。

## 0.3.6+11 PR #24 Android编译验证包（2026-10-19，未安装）

源e3655e50e2ff7868d9d381489df90efe9cf208f1，debug arm64；E:/AII-3D/hiplab-releases/pr24-review-20261019/hiplab-0.3.6+11-pr24-e3655e5-arm64-debug.apk，174,483,026bytes，SHA256 `d8a2e01329d3f140dd5ca1ae861fc4d29ddd10da43528ff73bbab7a456edfe2a`。包名com.ugk.hiplab、versionCode11，debug证书SHA256 `3761270a4764157f0e389014a9e5b800b05403bfddce0f4f7f8c039f6a53bdc7`连续；Gradle20.6秒，新Kotlin服务/Manifest已入包，CRC/16KB对齐和575音频/94视频一致；最大ZIP间隙138,313bytes。版本、依赖、发布配置保持。4项P2待作者修，当前不是验收通过包；未ADB、未安装、未商店上传，手机安装记录不变。[完整身份和问题](pr24-review-2026-10-19.md)。

## 0.3.6+11 PR #22 / 2cc40e3 真机复测包（2026-10-19）

源2cc40e3e51730d14f87056afe76e2b0c51dfcb19，debug arm64；E:/AII-3D/hiplab-releases/pr22-2cc40e3-retest-20261019/hiplab-0.3.6+11-pr22-2cc40e3-arm64-debug.apk，174,481,110bytes，SHA256 `46dd0d0c4819ab4e29883fcdadcb3ccd2e6489d78d3f3f7395b6fc79f4f60342`。初编14.9秒，单个生成APK移出后重打15.0秒消除ZIP空洞；签名连续、CRC/16KB对齐、575音频/94视频一致。20:44:23向2602BRT18C / Android16 install-r成功，安装包hash相同；原安装包为9fa0cc0（ce978c5f…），原偏好备份且升级JSON相同。F8真机原场景通过，新F9及后台/锁屏待修，候选尚未验收或合main；版本未增、未上传商店。[完整记录](pr22-native-retest-2026-10-19.md)。


## 0.3.6+11 PR #22/#24组合正常播放包（2026-10-19）

组合源5725c3668baddbe844a9943ed81c9374bc7aa3f1（22的2cc40e3 + 24的0ccef6b + 本机重播hold适配），验证分支已推送，main未合入。APK `E:/AII-3D/hiplab-releases/pr24-0ccef6b-reaudit-20261019/hiplab-0.3.6+11-pr22-pr24-combined-arm64-debug.apk`，174512710bytes，SHA256 `922ca6a7e1fa6da07ad96479dde2e9fa32a218515d8d0a0a3235a6ce664f643e`；com.ugk.hiplab/versionCode11，既有debug证书连续、资源/CRC/16KB对齐通过。初编19.9秒、ZIP空洞单APK重打16.9秒；21:56:37向2602BRT18C / Android16覆盖安装成功，安装SHA相同、14键状态JSON保持。两轮正常播放及服务释放通过，用户现场听感正常；F9仍待修。没有增加版本、修改发布配置或上传商店。[本轮记录](pr24-reaudit-and-pr22-integration-2026-10-19.md)。


## 0.3.6+11 PR22 F9 / PR24组合复审包（2026-10-19）

准确组合9b22dccc2bf2ca269a67b408198b9e3e9dbb742b（a586de3+既有PR24/重播hold修复），已推验证分支；APK位于E:/AII-3D/hiplab-releases/pr22-a586de3-f9-reaudit-20261019/hiplab-0.3.6+11-pr22-pr24-f9-arm64-debug.apk，174518862bytes，SHA256 `f40f5956fa3bdae49872e525fced310257102c6b4f7638eb28911e18ec4b91bd`。Gradle41.8秒，证书连续、资源/CRC/16KB对齐通过，间隙0；23:15:53对2602BRT18C / Android16覆盖安装成功，安装SHA匹配、14键state相同。F9编辑与键盘原生通过，尚未合main，未改版本或上传商店。[报告](pr22-f9-reaudit-2026-10-19.md)。


### PR22/24合并状态追加（2026-10-19 23:32）

开哥同意后，已安装9b22dcc的运行代码随b33ed21合入并推送main；GitHub22/24均MERGED。版本保持0.3.6+11，APK仍为上述174518862bytes / SHA f40f5956…，23:15:53安装事实保持。本次无新构建、无重新安装、无商店上传；主线SHA变化不冒称新APK。[合并确认](pr22-f9-reaudit-2026-10-19.md)。
