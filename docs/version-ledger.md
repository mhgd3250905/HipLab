# 版本交付台账

仅登记实际产生的构建、安装或发布。文档提交不增加 App 版本；“安装成功”“PR 合并”“商店发布”分别记录。时间均为北京时间。

**最新实际交付：0.3.6+11 debug / arm64**，源码 `66f5da034c0cdac3341f3e80a57e3ddae5f95dce`；2026-10-18 19:29已保留数据安装。APK、SHA与安装证据见本页0.3.6两节。本次文档收束不新增构建或安装记录。下表为2026-10-17早期交付历史。

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


## iOS 0.3.6+11 本地候选（2026-10-18 20:17）

| 项目 | 实际状态 |
|---|---|
| 基线 / 源码 | Windows main `fce7ad8`；iOS 平台适配候选 `2f8aeb099fae965e764fc41fd38c2c3154064766` |
| 版本 / 签名 | com.ugk.hiplab / 0.3.6 /11 / arm64；已有开发签名，Team 不入库 |
| Release / Archive | 均成功，44.1 /34.1 秒；Archive 247,430,242 bytes；两次产物哈希分开见[iOS 0.3.6 对齐与验证](ios-main-ui-036-2026-10-18.md) |
| 检查 | analyze 无问题、160 pass /1 skip、隐私/流程10通过、92素材无漂移、611随包文件一致、6隐私清单解析与严格签名通过 |
| 安装 | 未成功：iPhone 16 Pro /iOS26.5 掉线；手机仍为0.3.3+8，当前435字节偏好已备份，未卸载清数据或回写旧备份 |
| 发布 | 无分发IPA、无上传或商店状态变更；由Windows审查iOS分支PR |


## 2026-10-18 20:49 / iOS 0.3.6+11 安装追加

同源`2f8aeb0` Release已覆盖安装到iPhone 16 Pro /iOS26.5；从0.3.3+8更新后回读0.3.6+11，安装前后753字节即时偏好逐字节保持，启动命令exit0。镜像待手机锁屏，新版UI/视频/听音尚未验收。未重构建、清数据、回写旧备份或上传商店。见[iOS 0.3.6 对齐与验证](ios-main-ui-036-2026-10-18.md)。


## 2026-10-18 21:05 / iOS 0.3.6+11 安装后UI与数据复核

复用同源`2f8aeb0`候选，未重复构建。iPhone16Pro/iOS26.5深浅首页/设置、隐私固定顶栏/复制/右滑、自测单屏与蝴蝶式视频暂停恢复、训练准备进入/暂停/退出已操作；恢复深色主题后753字节偏好与即时安装前逐字节相同，结构状态无差异。保留9张App截图/1张镜像结束截图；完整课、普通锁屏、ducking/中断/耳机及其他重点动作全循环仍待验。PR#12送审历史与#15计时说明补齐到#16，旧PR未关闭、main未合并，#17转场返工未安装。文档差异核对链接、事实和diff，不重复Flutter测试。详见[iOS本轮记录](ios-main-ui-036-2026-10-18.md)。
