# 版本交付台账

仅登记实际产生的构建、安装或发布。文档提交不增加 App 版本；“安装成功”“PR 合并”“商店发布”分别记录。时间均为北京时间。

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

## iOS 0.3.2+7 / TestFlight（2026-10-18）

源 `9c2802f1701b3d13d608db6a098548c0cca24d0b`，基线 main `12f1438`；Flutter 3.44.7 stable、Xcode 26.6、SwiftPM。Release Archive 和 App Store 分发验签通过，最终实际上传 IPA 为 `build/ios/ipa/HipLab-XcodeUpload.ipa`，**81,120,270 bytes / SHA256 `d751608eb74508d4115908c3e64da420a28cd56c2a7c7b034828a0ac661caade`**。

北京时间约 01:32 Xcode 显示上传完成；Apple 列表显示上传于 01:36，Build 7 已处理。独立 App `6824011384` / `com.ugk.hiplab`，HipLab Internal 1 个构建、1 名当前账号测试员已邀请，自动分发关闭；**尚未安装验收或正式送审、未发布**。analyze 无问题、117 项测试和 92 文件素材 SHA 通过；同源模拟器 Debug 用于四张原生截图，不能替代 Release 真机结论。详情见[iOS 首轮交付](ios-store-release-2026-10-18.md)。

历史 Mac 0.1.2+3 / `313b484` Release 曾在 iPhone 16 Pro / iOS 26.5 安装运行，用户确认“我打开使用还行”；这只证明当时工程可运行，不覆盖本次 Build 7。原证据在主 worktree 的 `build/mac-preflight/`、`build/mac-device/`，不入 Git。

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
