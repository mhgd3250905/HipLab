# 当前状态

Git 基线核对于 **2026-11-17（北京时间）**。设备和渠道分别附核验日期。

| 对象 | 版本与状态 | 依据 |
| --- | --- | --- |
| 开发主线 | `main` · **1.1.4+71**。SDK 0.9.0 固定 `4eb87ce`，PR #39 已合并，集成点 `ba0d0c1` | [PR #39](https://github.com/mhgd3250905/HipLab/pull/39)、[版本规则](version-management.md#版本与来源身份) |
| Android 自用真机 | 2602BRT18C，**1.1.4+71 / 2071**，同签覆盖 +70，2026-11-16 用户验收通过 | [包身份](version-ledger.md#2026-11-16-android-sdk-基准-71)、[验收](verification.md#2026-11-16-android-sdk-基准-71) |
| Android Play 封闭测试 Alpha | **1.1.3+70 / 70** 为 PR #37 对应的 Alpha 目标版本。渠道送审结果以 Play Console 为准 | [PR #37](https://github.com/mhgd3250905/HipLab/pull/37)、[渠道记录](version-ledger.md#2026-11-15-至-17-商店渠道回执) |
| Android Play 内部测试 | 台账有回执的版本 **1.1.2+67 / 67**，2026-11-12 对 `wrist-test` 发布 | [内部测试记录](version-ledger.md#2026-11-12-会员阶段收束-67) |
| Android Play 正式版权限 | 2026-11-15 10:54 的回执为申请已收件、审核中 | [渠道记录](version-ledger.md#2026-11-15-至-17-商店渠道回执) |
| iOS TestFlight 内部测试 | 台账有回执的构建 **1.1.2 (68)**，2026-11-12 回读内部组可用 | [内部测试记录](version-ledger.md#2026-11-12-首次-ai-数据共享同意-68-候选) |
| iOS App Store 审核 | iOS PR #38 以 **1.1.0 (61)** 的送审源码为基线，审核结果以 App Store Connect 为准 | [PR #38](https://github.com/mhgd3250905/HipLab/pull/38) |
| iOS 开发候选 | 独立 Draft PR #38，**1.1.3 (71)**，SDK 固定 `63e2481` | [PR #38](https://github.com/mhgd3250905/HipLab/pull/38)、[渠道记录](version-ledger.md#2026-11-15-至-17-商店渠道回执) |

Android +71 的应用内随包目录是 `r2-v11`，稳定渠道冷启动验证取得 `r2-v16`。动作库和训练视频均已抽样回读默认 V4 素材。模拟器透明轮廓在 +70/+71 均可复现，Android 真机验收结论来自用户的 +71 实际使用。[验证台账](verification.md#2026-11-16-android-sdk-基准-71)

商店栏是最后可追溯的记录，日期与证据来源以各条回执为准。后续验收见[开发事项](development-roadmap.md)，早期状态见[历史快照](https://github.com/mhgd3250905/HipLab/blob/ba0d0c16ae56d7b679572be3a380969f0679b2dd/docs/current-state.md)。
