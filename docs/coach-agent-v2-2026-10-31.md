# HipLab Coach Agent v2 第一阶段

分支 `codex/coach-v2`，从本地 main `1083b499ec2bec145c6227e5e64c6944ab5716a1` 创建。
开工刷新远端引用：origin/main 为 `1b94fc39a10cf8f44e90dea7cc1a675bfa8f31d6`，本地领先 0、落后 4 个 iOS 审核记录提交。
按本次指令保留本地 main 基线；没有快进 main、合并、推送、打 tag 或操作 release 分支。
工作副本 `E:/AII-3D/3D-Hip-worktrees/coach-v2/3D-Hip`；日常目录的液态玻璃分支 31 项未提交/未跟踪改动保留。

共用版本为 **1.1.0+23**，避开上一独立测试候选的 +22。三包及 trainer 的 coach 传递依赖统一固定
`66dd98a549c1ff5fedecb626a7c88583090a1440`，使用正常 GitHub Git 依赖与受版本控制的 override，未修改 SDK 源码或使用本机 path override。
解析版本 coach 0.8.0、coach_ui 0.4.0、trainer 0.6.0；工具链固定 Flutter 3.44.7 / Dart 3.12.2。

## 实现边界

- 移除 `lib/hip/coach/template_fallback.dart`（152 行）和重复认证实现 `coach_auth.dart`（20 行）。服务同时移除运行时白名单交集、自定义剂量门禁、自动预设生成和 App 指定的 Agent 默认策略；没有 App 关键词意图/槽位判断。
- profile 配置静态 45 个动作 ID，排除 `n-thomas-test`。产品重点仅髋部灵活性、拉伸、控制；规则、剂量、配时、目标与版本由 SDK 控制。只额外声明 SDK 要求的环境物能力和产品文案。
- 失败使用 SDK `CoachFailureBubble`，重试仅发送 `重试`；预设候选仅来自已保存的完整计划，显示与点击分别调用 `canOfferPreset` 和 `requestPreset`，无自动回落或 App 候选匹配规则。
- 计划渲染 SDK `CoachPlanExpanded`，推荐渲染 `CoachRecommendCard`；问答保留 confirmation、focus、defaultSelections、preselected、previousSelections、optionsByScene 等 SDK 字段。新任务生成气泡、讨论标签及训练页滑入留给第二阶段。
- AI 入口与用量入口统一限制 Android + 中文，且配置有效。无 Key 时仍隐藏入口。

## 会话、保存与讨论

`AiCoachSession` 单键顺序写入完整 `exportSession().toJson()`、显示消息、每张计划卡的
`planState.toJson()` 及保存关系，避免事实和卡片分属不同写入。发送完成、状态变化、后台、取消/销毁保存；存储失败保留 SDK 已交付结果并呈现保存状态。

完整快照调用 `restoreSession`；无快照的旧显示数据调用 SDK `restoreHistory`。恢复推荐和计划重新经过 SDK 门禁；恢复后旧问题调用 SDK `invalidateQuestion` 关闭，不重建 App 问题状态机。

HipLab 已有“我的训练组”，本轮没有跳过计划讨论。保存组增加“发到对话”，调用
`focusExternalPlan(externalId: routine.id, plan: completePlan)`，SDK 生成 `ext:<保存 ID>`。
编辑后按 `ValidatedPlan.savedRef` 显示“更新到我的计划”和“另存一份”；更新原 ID、另存新 ID，原版和 SDK 版本历史保留。
遵循 [SDK plan-focus 接口](https://github.com/mhgd3250905/ugk-3d-pose-sdk/blob/66dd98a549c1ff5fedecb626a7c88583090a1440/packages/ugk_coach/docs/plan-focus.md)。

完整 `TrainingPlan` 随 `CustomRoutine.coachPlan` 原子保存。原有训练组步骤仅为列表/编辑格式投影，不裁剪或重配 AI 剂量。
AI 开练通过 `TrainingPlan.sdkPlan` 直接交给 SDK `SessionBuilder`，保留块、rounds、sets、逐项/轮间休息、perSide、segments 和 holdSeconds；语音使用 SDK phase 与 HipLab 词库。
点击旧卡按旧卡原稿启动，不因对应保存组后来被编辑而改练另一份计划。

App 仍保留必需的业务边界：认证与持久设备 ID、资产加载、用量/免责与本地写入、主题/文案、保存计划 ID 和导航、旧手工组到 SDK 的结构适配，以及原生疼痛/禁练保护与结果存储。
这些不判断模型意图、不挑动作、不配时、不补计划；只有显式疼痛与既有安全锁会干预执行，且不回写 SDK 原稿。

### 指定 SDK 提交的轮次执行缺陷

离线回放两份真实模型结果，确认固定 SDK 内部存在不一致：`PlanDuration` 无条件累计所有 block.rounds，
Agent 的 `draft_plan` 也能交付 `type=main, rounds=2`；Trainer `SessionBuilder._occurrences` 只在
`type=circuit` 时重复轮数，并将 circuit 的 sets 设为 1。没有找到公开开关或现成规范化器。
因此“完整 SDK JSON 没丢”不能证明 SDK 自己执行了全部轮次。本轮没有在 App 写配时/轮次旁路，也没有擅自改 pin。

| 真模型计划 | Coach 估时 | Trainer 时间线（不含准备） | 加 15 秒准备 | 相对目标偏差（含准备） |
|---|---:|---:|---:|---:|
| 在家开胯 10 分钟 | 629s | 446s | 461s | -23.17% |
| 换一套缩到 5 分钟 | 315s | 197s | 212s | -29.33% |

这是未上设备的离线 SDK 执行数据；实际语音可能扩大换边间隔，不会补回缺失的整个 main 轮次。
复现 `tools/coach/coach_v2_native_metrics.dart` 读取已保存的 `live/results.json`，零模型请求，
完整计划往返相等，证据保存在 `live/native-metrics.json`。用户已明确选择由 SDK Agent 修复；本任务先完成其余项，
等修复提交出来后，三个包统一改钉到该提交，再重跑两张计划的开练时长和三段真实对话。App 不自行展开轮数或改写计划绕过。
不能把下文 Coach 估时通过表述为原生开练时长验收通过。

## 网关

生产默认仍为 `https://api.uuugk.win/v1` / `deepseek-v4-flash-0731`，使用 SDK `UgkWorkerAuth` 的
`X-App-Key + X-Device-Id`，没有 Authorization。凭据仍从外部配置提供，无内置默认 Key。

本次真模型与 APK 明确通过四项 dart define 选择 `UGK_COACH_BASE_URL=https://ai.uuugk.win/v1`、
`UGK_COACH_MODEL=deepseek-flash`、`UGK_COACH_AUTH=bearer` 和 `UGK_COACH_TOKEN`。
Key 只在本机运行/构建时注入，不入仓库、报告或日志。`LlmConfig.maxRetries=0`；Agent 自身重试/门禁仍用 SDK 默认。

## 真实模型三轮

三条原文在同一会话依次发送，每条只跑一次，没有补充输入、强塞场景或预设回落，全部 status=ok。
第三轮交付第一张计划同 ID 的 v2。总计 13 次请求/HTTP 尝试，没有传输重试；门禁拒绝与重交均为 0。

| 输入 | 调用/搜索 | 耗时 | 最大请求 bytes | prompt / completion tokens | 缓存 tokens / prompt命中率 | 拒绝 | 任务 | 估时/目标及偏差 | 部位/重点命中 | 上下文折叠 |
|---|---:|---:|---:|---:|---:|---:|---|---|---|---|
| 在家开胯10分钟入门 | 5/1 | 10.109s | 40,352 | 38,552 / 879 | 25,088 / 65.08% | 0 | plan | 629/600s，+4.83% | 未设 body 目标；灵活/拉伸 3/3，臀部/内收肌均来自目录 | 否 |
| 推荐几个拉大腿内侧的动作 | 4/1 | 6.853s | 38,333 | 30,418 / 447 | 25,472 / 83.74% | 0 | recommend | 不适用（推荐卡无计划时长） | 大腿内侧 4/4 | 是 |
| 换一套，缩短到5分钟 | 4/0 | 10.906s | 43,091 | 39,286 / 1,019 | 27,264 / 69.40% | 0 | plan | 315/300s，+5.00% | 大腿内侧 2/2；拉伸 2/2 | 是 |

completion 已包含 reasoning，三轮总 tokens 分别 39,431 / 30,865 / 40,305；reasoning 分别 333 / 130 / 637。
缓存为服务商报告的 cachedTokens / promptTokens；“折叠”是 SDK 模型上下文折叠，不是 UI 卡片折叠。
卡片均默认收起，由 SDK 组件展开。

原始测量保存在 `E:/AII-3D/hiplab-releases/coach-v2-20261031/live/results.json` 与 `requests.jsonl`；
`summary.json` 保留原始结果 SHA，并用 SDK 相同的 muscleGroups→body 编码核对部位命中。
初版探针误读 raw drill.tags 的报告字段已在探针修正，原始网络结果未覆盖、未重复模型请求。

## 八项剂量与实际改动

以下“改前”是历史上游 0.1.0；本地 main 开工时已完成这些 mode 修正，不虚报成本轮新改八种单位。
本轮新增两处 holdSeconds 和 14 处 repSeconds 数据对齐，详细来源与契约见[剂量审计](coach-v2-dose-audit.md)。

| ID | 旧上游 | 与 HipLab kit / Pose-Hub 0.2.0+ 对齐 |
|---|---|---|
| h-adductor-rock | 1×30 秒 | 1×5 次 |
| h-knee-hug | 1×30 秒 | 1×6 次 |
| h-sumo-pry | 1×30 秒 | 1×3 次，每次停 10 秒 |
| n-pelvis-circle | 1×30 秒 | 1×4 次 |
| n-seated-ir-drop | 1×8 次 | 1×30 秒 |
| n-seated-knee-lift | 2×30 秒 | 1×3 次，每次停 5 秒 |
| n-seated-squeeze | 2×30 秒 | 1×8 次 |
| n-squat-shift | 1×30 秒 | 1×8 次 |

全部 46 kit 的 25 个计数动作已核对，14 处缺失/旧 3 秒 repSeconds 按完整 authored 周期补正。
SDK 类型化 Dose 不含 holdSeconds，但 raw 与分段保留该值；普通 reps 估时通过完整周期包含停留。
SDK PlanDuration 的普通 reps 估时与 native rhythm 的每组 lead 存在原接口口径差异，不能声称 native 与估时逐秒相等。
catalog 媒体版本与资源保持，provenance 单独声明 SDK 66dd98a 正式 catalog 0.3.0 的剂量对齐，未升级媒体或整份目录语义。

## 最终验证与交付

- `flutter test --no-pub --concurrency=1 --reporter expanded`：**468 通过 / 0 失败 / 0 跳过**，6 分 9 秒。通过 `VOICE_TIMELINE_OUT` 执行原本条件跳过的语音导出。
- `dart analyze --fatal-infos`：**0 问题**。
- `python -m unittest discover -s tools/tests`：**24 通过**；固定 SDK 目录剂量校验及本地只读校验均通过。
- UI/持久化定向 41、原生完整计划/语音适配 14、疼痛流程 26、中断 24、界面/转场 25 项通过；这些是全量集合或定向复查，不累加为额外测试总数。
- SDK 依赖缓存的 HEAD 和实际 lib 内容核对为精确 66dd98a，未使用 `pubspec_overrides.yaml`；候选版本化文件未检出本机 API Key。
- 初次全量暴露旧测试的暂停文案、持续呼吸动画及完成页差异；已在保留计时冻结、疼痛、保存和中断断言的前提下迁测，最终完整一轮 468 全过。初轮证据保留为 `all-tests-initial.log`，最终 `all-tests-final.log`。
- `lib/hip/coach/` 相对本地 main 删除 **441 行**、新增 140 行，净减 **301 行**；完全删除的两个文件合计 172 行。剩余代码职责见上方边界。
- APK 已从实现提交 `d0a0181d22d8eb1c4f6c774ebe02b2d8c3ffbfa9` 构建并核验。最终为 `hiplab-1.1.0+23-coach-v2-d0a0181-test-gateway-arm64-split-release.apk`，**111,504,576 bytes（106.34 MiB）**，SHA256 `128517258d2fc77c855c5b36f2d2849b8bd8dbcc84334508af764c18d93b8af1`。
- 签名、zipalign 16KB、全部 arm64 ELF LOAD 16KB、JNI 固定类/方法与原生符号均通过。来源及完整核验记录为 `E:/AII-3D/hiplab-releases/coach-v2-20261031/release-apk.json`。使用实际锁定的 JNI/path-provider 契约；shared_preferences_android 2.4.28 使用平台通道，未误套 SmartFit 新版 JNI registrar 契约。
- 为排除 JNI 附带其他架构，最终使用 `--split-per-abi --target-platform android-arm64`；Flutter 将 pubspec build23 派生为 manifest **versionName1.1.0 / versionCode2023**（arm64 偏移2000），发布配置未改。首次多 ABI JNI 产物保留为 `hiplab-1.1.0+23-initial-extra-jni-abis-unverified.apk`，不作为交付包。
- 轮次缺陷保持明确未关闭：其余项已完成，等待 SDK Agent 的修复提交；届时三包一起更新并重跑两张开练时长及三段真实对话。当前包仍为原66dd98a候选，不将其标为第一阶段产品验收通过。

未安装或操作手机，未完成原生听音/视觉验收；上述真模型为 Flutter 测试进程中的真实服务/SDK 调用，不冒充设备证据。
没有上传 Play、App Store 或 TestFlight。第二阶段需用户确认后再开始。
