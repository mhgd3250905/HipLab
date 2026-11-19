# 当前状态

Git 与 PR 于 **2026-11-19（北京时间）** 核验。真机验收和商店渠道按各自证据日期登记。

| 对象 | 版本与状态 | 依据 |
| --- | --- | --- |
| 开发主线 | **1.2.0+77**。PR #40 已于 2026-11-18 合入 main，集成点和标签 v1.2.0+77 均指向 7ef08d3。四个 SDK 依赖使用 ugk_trainer-v1.0.1，解析为 85b57fd | [PR #40](https://github.com/mhgd3250905/HipLab/pull/40) · [版本台账](version-ledger.md#2026-11-18-android-2077-展示素材候选) |
| Android 自用真机 | **1.2.0+77 / 2077**。用户于 2026-11-18 17:11 确认验收通过，沿用该轮签名 APK | [包身份](version-ledger.md#2026-11-18-android-2077-展示素材候选) · [验收](verification.md#2026-11-18-android-2077-展示素材候选) |
| Android Play 封闭测试 Alpha | PR #37 的目标为 **1.1.3+70 / 70**。渠道状态以 Play Console 为准 | [渠道记录](version-ledger.md#2026-11-15-至-17-商店渠道回执) |
| Android Play 内部测试 | 2026-11-12 台账记载 **1.1.2+67 / 67** 对 wrist-test 发布 | [内部测试记录](version-ledger.md#2026-11-12-会员阶段收束-67) |
| Android Play 正式版权限 | 2026-11-15 10:54 回执为申请已收件、审核中 | [渠道记录](version-ledger.md#2026-11-15-至-17-商店渠道回执) |
| iOS TestFlight 内部测试 | 2026-11-12 回读 **1.1.2 (68)** 在内部组可用 | [内部测试记录](version-ledger.md#2026-11-12-首次-ai-数据共享同意-68-候选) |
| iOS App Store 审核 | iOS PR #38 以 **1.1.0 (61)** 的送审源码为基线，审核结果以 App Store Connect 为准 | [PR #38](https://github.com/mhgd3250905/HipLab/pull/38) |
| iOS 开发候选 | 截至 2026-11-19，独立 PR #38 仍为 Draft，源码 d281695，版本 **1.1.3 (71)**，SDK 固定 63e2481 | [PR #38](https://github.com/mhgd3250905/HipLab/pull/38) |

主线随包展示素材为 r2-v18。SDK 检测到新目录后会先持久化并校验展示文件，再切换当前目录。主动打开动作后才准备训练视频和语音。冷启动、失败重试及旧版本证据见[验证台账](verification.md#2026-11-18-android-2077-展示素材候选)。

商店条目记录最后有据可查的状态。后续事项见[开发事项](development-roadmap.md)，旧阶段状态见[历史快照](https://github.com/mhgd3250905/HipLab/blob/ba0d0c16ae56d7b679572be3a380969f0679b2dd/docs/current-state.md)。
