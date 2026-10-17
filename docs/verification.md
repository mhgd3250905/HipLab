# 验证台账

当前用户真机安装基线为 **0.1.2+3 / `4cf5ca7`**，检查日期 2026-10-17。待送审 **0.2.0+4 release** 的独立检查见本页末节；下表 V-01 至 V-13 保留 0.1.1+2 / `35f2a97` 的原始验证，新图标版本见对应节。测试通过只覆盖所述范围，后续文档修改不会使旧检查变成新版本验证。

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

## 0.2.0+4 Play 准备阶段检查（2026-10-17）

`codex/play-store-release` 工作区重新执行 `flutter analyze --no-pub` 无问题，`flutter test --no-pub` **50 项通过**；对应源码随后提交为 `19aa388`。新增用例从进度页打开离线隐私页、复制公开政策链接并返回；全部 7 项界面流程测试通过。支持邮箱按用户确认补入 `mhgd3250905@gmail.com`，最终 release 的离线页面验证已覆盖该邮箱。

准备阶段正式上传 key 签名 release 构建已产生，当时 release 实际播放器核验尚在进行。商店四张 `verified-real-20261017` 截图来自用户真机的 `0.1.2+3`，不能作为新版 release 安装或运行证明。后续最终核验如下。

Play Console 的商店介绍、图标、1024 × 500 展示图与四张手机截图已保存，全部 10 项内容声明当前无待注意项；IARC 显示 ESRB Everyone / PEGI 3，目标受众 18+。公开隐私页已发布且回读 HTTP 200，含系统备份、本机媒体权限与支持邮箱。准备阶段 Alpha 地区、单人测试名单和反馈邮箱已保存，当时尚未上传版本或送审；上传后续变化见下节与 [Play 送审记录](play-store-release-2026-10-17.md)。

### 最终 release 模拟器核验回执

正式签名 AAB 的 `jarsigner`、APK 的 `apksigner` 验证通过，最终字节数和 SHA 见[版本台账](version-ledger.md)。API 35 `emulator-5554` 使用 host RTX 4080 GPU 运行正式 APK，视频实播 8 秒，纯媒体区域 15 次采样获得 14 个不同 hash。App 进程未出现 `SocketException`、`EACCES` 或 cleartext 异常；禁用 Wi-Fi/移动数据后，离线隐私页与 `mhgd3250905@gmail.com` 仍可见。

证据在本地外部目录 `E:\AII-3D\hiplab-releases\0.2.0+4\release-verification-20261017`：`host-playback.mp4`、`host-player*.png`、`final-progress.png`、`final-privacy-offline.png`、`final-privacy-bottom.png`。日志保留本地，不链接敏感运行日志。模拟器软件 SwiftShader 曾出现宿主 GL 崩溃，host GPU 验证通过；旧包未声明 `INTERNET` 的真实问题已修复，不能将软件 GPU 的黑屏本身当成唯一 App 失败证据。

**以上为最终 release 的模拟器验证；用户真机保持旧 debug 版本，未覆盖、未清数据。** Alpha AAB 上传已开始，仍待 Console 平台校验与送审回执。

四张真机商店图已排序为今日训练 → 播放暂停 → 自测 → 进度；Console 已声明 ImageGen 制作的站姿图标，真机截图未用 AI 改造。独立只读 review 无阻塞项；基线 Gradle 在异机缺 release key 配置时可能回退 debug 签名，本轮正式签名核验通过，后续重建仍须核对证书。

追加同环境对照：稳定 NVIDIA host GPU 下旧无 `INTERNET` release 仍黑屏，权限清单确认缺失网络权限；`original-host-black.png` 留证。最终 release 已覆盖恢复，`INTERNET` granted，未卸载或清除模拟器应用数据，产物 SHA 未变。结构化验证结果为上述证据目录的 `verification-report.json`。

上传后续回执：Alpha AAB 文件传输完成，Console 已进入 Google 优化，尚待平台处理就绪与提交审核。

### 16 KB 页对齐静态检查

Android SDK 36 `zipalign -c -P 16 -v 4` 对最终 APK 返回 `Verification successful`。三种 ABI 共 9 个 `.so` 的所有 `PT_LOAD` 对齐值为 16,384 或 65,536，文件 offset 与虚拟地址模 16,384 一致；AAB 的 `base/lib` 与 APK `lib` 九项库 SHA256 逐项相同。证据为上述验证目录内 `zipalign-16kb.txt`、`elf-16kb-and-aab-library-identity.json`。未改源码、未重新构建、最终产物 SHA 不变；**未在 16 KB 内核设备运行，不作该类真机验收声明**。

平台处理回执：最终 AAB 优化完成，Console 显示 `4 (0.2.0)`、target SDK 36、min SDK 24、三 ABI、估算下载大小 60.5 MB。预览“可以发布了”、无阻塞错误，Alpha 版本已保存，尚待最终送审回执。代码 `19aa388` 已推送并创建 draft [PR #10](https://github.com/mhgd3250905/HipLab/pull/10)，main 未合并。

### Play 送审请求回执（2026-10-17 20:59）

发布概览确认“将 15 项更改送审”后，变为“正在审核中的更改”，含 Alpha `0.2.0 (4)`、177 国家/地区及其他、名单、商店与内容声明。快速自动检查仍在进行，界面提示最多约 14 分钟、成功后自动进入审核；**没有取得审核通过或正式上架结果**。

本机证据为 `E:\AII-3D\hiplab-releases\0.2.0+4\play-console-20261017` 下 `submitted-overview.txt`、`submitted-overview.png`、`before-submit-15-changes.*`、`alpha-preview.*`。Console 提供的测试加入链接提交时仍 disabled；名单 1 人、实际加入 0 人，12 人连续 14 天的正式发布门槛未满足。详见[送审记录](play-store-release-2026-10-17.md)。

最终在提交活动及详情回读确认 **Submission ID 1 / 2026-10-17 20:59 / 状态“审核中” / 15 项变更**，覆盖封闭式测试 Alpha、商品详情、应用内容、商店设置；准确时间取 Console 的 8:59 下午。证据追加 `submission-activity.txt/.png`、`submission-1-details.txt/.png`，同在上述本机目录。[需登录的提交详情](https://play.google.com/console/u/0/developers/4872134440776463225/app/4976120800604322549/publishing/submission-activity/1/details)可回读最新状态，本文没有记录审核通过。
