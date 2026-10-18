# 第二轮语音与 UI 集成（2026-10-18）

从 main `12f143868959187047ff7f7aaeff9f469dca0039` 依次审核集成 #13 → #14。#7—#10 和 Pose-Hub v0.1.0 已在 main，本轮不重做迁移，不改写历史验收。用户授权本机验证后推 main，禁止新商店上传及修改版本号以外的发布配置；手机已拔线，本轮没有 ADB。

| 阶段 | 固定身份与结果 |
|---|---|
| [PR #13](https://github.com/mhgd3250905/HipLab/pull/13) | HEAD `d2e0286ffc0e402e0ddf0f80426536dc7192bca7`，本地 merge `a41e7e0084798b12ace3988123314d57650e3bab`；analyze 0，136 pass / 1 skip；23 targeted 通过 |
| [PR #14](https://github.com/mhgd3250905/HipLab/pull/14) | HEAD `217e058061325244de74f3155287b673e3247a57`，merge `4c563f90b2fe7814a07649df123d2769b0eb3240`；后续控制语义/倒计时修复 `162a4e6b78a8640d367cac13ef5e1ae6cfa9b33a`，analyze 0，156 pass / 1 skip |
| 运行与版本提交 | `1b35657dec153741e25ca095ac2764b18d14ac29`，版本 0.3.3+8；已推送 main，GitHub 回读 #13/#14 均 MERGED，提交祖先顺序为 #13 → #14 |

两 PR 的目标分支均已从旧 `feat/ios` 改为 main；原开发基线为 `313b4848ff0a436b9b2c400ea1d95f97c30c308b`。#7—#10 在前一轮北京时间 01:01 的合并记录保持不变。本轮全量测试唯一跳过项是未设置 `VOICE_TIMELINE_OUT` 的时间线导出，并非遗留失败。

## 语音整合

`VoiceLineController` 等真实 completed 状态，语音或提示音仍在响时不释放 duck，会话与准备操作串行。保留 main 的 forTesting、共享初始化 Future、session generation、end/dispose 和耳机停止双播放器释放焦点。审核新增取消/加载/旧 owner 清理等回归，防止取消后发声、旧 load 覆盖新句、旧句暂停新倒数、configure 取消后误记已获取焦点，以及快速失败 Future 未处理。

[488 条独立离线复核](voice-audit-2026-10-18.md)：中文 244 + 英文 244，0 失败，ID/文本绑定一致，manifest 与解码时长最大偏差 0 ms；本轮未联网 TTS、未重编码、未重跑 `--raw`。实际门槛为 **−16±1 LUFS / TP≤−1.0dBTP**。汇总 −1.2 是一位小数舍入，边界约 −1.160 / −1.180 / −1.170，不能表述为全部严格≤−1.2。工具八处显式 UTF-8 及 cp936 报告往返通过；算法未变。真机听感和系统音频仍待验收。

## UI、网页与边界

保留已验收 0.3.1+6 的单屏自测布局。合入自绘图标、统一分段、页面过渡/Hero，并修复动画重复 key、键盘操作、自测→训练音频 route 交接和隐藏页视频生命周期；控制语义和 33 ms 倒计时增加回归。

本轮临时网页采用 silent-voice fixture 与 poster stub。四尺寸为 320×568、360×740、390×844、768×1024；正方形示范、按钮边界、无滚动、六项自测及结果完成、点按暂停/继续、键盘/拖动/快速 Tab 和训练暂停继续有证据。普通 DOM locator 受空白 Flutter semantics root 限制仍超时，失败证据保留；page.mouse 坐标操作通过且未用 force，widget hitTest 亦通过，不能推断整个 DOM 指针链通过或存在透明旧页遮挡。

Chrome 倒计时 18 屏/17 相邻环区域，新 33 ms tick 为 0 对完全相同，旧 100 ms 为 5 对；采样间隔约 47–79 ms（`ring-33ms-analysis.json`），不等于真机帧时或帧率。网页检查不是 Android/WKWebView 真媒体、H.264、系统音频或正式 Web 支持验收。

## 构建与产物

PR #13 在 C 盘 worktree 构建因 Kotlin C/E 跨盘缓存失败一次，仅环境变量禁用 incremental 重试仍失败；E 盘同 SHA 副本离线 enforce-lockfile 后 lock 不变，构建成功，未为解决故障修改发布配置。保留各阶段产物，避免同版本号混淆：

| 源码 / 版本 | APK bytes / SHA-256 |
|---|---|
| PR #13 `a41e7e0` / 0.3.2+7 | 151,821,564 / `b0e5c543ef1acdb299c5f499f355089519ce6162bd247c28238aaf9367acd373` |
| PR #14 首阶段 `4c563f9` / 0.3.2+7（analyze 0，153 pass / 1 skip） | 176,826,741 / `8df8f96ee043d50de58b3e350c9be7f844522098a5bbb96b47eb6486bf877477` |
| 候选 `162a4e6` / 0.3.2+7 | 176,826,917 / `f48a11eb624ac9f08396e08140360aee9c8a6519d17ebdd7321dc3e7340a7b5a` |
| 最终 `1b35657` / **0.3.3+8 debug arm64** | **151,888,384** / `9ec9dbe4df19f625f38ffabb6448c479525b21dc138c60e8ca16e23afa688506` |

最终路径：`E:/AII-3D/hiplab-releases/round2-20261018/final/hiplab-0.3.3+8-debug-arm64.apk`，构建 26.96 秒。包名 com.ugk.hiplab、versionCode 8、预期 debug 证书及 488 条语音 / 92 个 Pose-Hub 资源 / 22 个保留文件检查通过；内容重生成无变化，Python 11 项及 iOS 静态检查通过。行为检查在 `162a4e6` 为 156 pass / 1 skip、analyze 0；版本提交与 APK 来源另按 `1b35657` 登记，不混写。

手机仍为 `963db04` / 0.3.2+7，最终包未安装。Android 原生首帧、语音/ducking、中断、后台、真实触觉/动画，以及 Mac/Xcode 与 iPhone 仍待后续；没有新 Play / App Store 上传或审核回读。前一轮 0.2.0+4 / Submission 1、既有用户验收与设备数据恢复记录继续保留。证据位于 `E:/AII-3D/hiplab-releases/round2-20261018/`，本机路径不代表远端备份。

## 最终交付快照（由实际 facts 生成）

业务代码 `1b35657dec153741e25ca095ac2764b18d14ac29` 已于 2026-10-18 10:04 北京时间推送 main。运行源码 `1b35657dec153741e25ca095ac2764b18d14ac29`，版本 **0.3.3+8 debug**；行为检查源码 `162a4e6b78a8640d367cac13ef5e1ae6cfa9b33a`：analyze 0，Flutter 单并发 156 项通过、1 项按设计跳过。最终 APK 已构建，手机拔线未安装；Android 原生及 iOS 待验。PR #13：MERGED（a41e7e0）；PR #14：MERGED（4c563f9）。

临时独立网页预览在 320×568、360×740、390×844、768×1024 上检查正方形示范区、按钮 bounds、无滚动、六项自测及结果完成；点按暂停/继续、键盘、分段拖动、快速 Tab 和训练暂停/继续通过。预览使用 silent-voice fixture 与 poster stub；普通 DOM locator 仍因 Flutter semantics root 空白而超时，保留失败证据。坐标 page.mouse 操作通过且未使用 force；原生 widget hitTest 回归通过。这不构成原生媒体、H.264、系统音频或正式 Web 支持验收，也不据此诊断透明旧页遮挡。倒计时改为 33 ms tick；Chrome 18 屏的 17 个相邻环区域中，完全相同对数由旧 100 ms 的 5 对降至 0 对，采样约 47–79 ms，不代表真机帧时或帧率

APK：`E:/AII-3D/hiplab-releases/round2-20261018/final/hiplab-0.3.3+8-debug-arm64.apk`；151,888,384 bytes；SHA-256 `9ec9dbe4df19f625f38ffabb6448c479525b21dc138c60e8ca16e23afa688506`。包名 com.ugk.hiplab、versionCode 8、预期 debug 证书及 488 条语音 / 92 个 Pose-Hub 资源 / 22 个保留文件核验通过；内容重生成无变化；Python 11 项及 iOS 工程静态检查通过。最终构建 26.96 秒，未安装手机
