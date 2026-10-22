# HipLab AI 工具会话升级（2026-10-21）

本轮在 `codex/coach-tools-0.2` 升级 ugk_coach 0.2.0。前置训练包接入已合入并推送 main（本轮基线 `e456d2a`）；AI 升级尚未合 main。用户明确当前功能开发阶段只验核心功能，真实体验由其后续真机测试；无手机，不执行 ADB。

## 接入与配置

两个 SDK Git 依赖均固定 SDK main 上的完整 commit `09a392bc0b736e6a23eef71d55d86108660e0e59`：ugk_coach 0.2.0、ugk_trainer 0.1.4。trainer 包 tree 与旧固定 d193a70 相同，本轮没有 SDK 源码改动、path 依赖、缓存修改或 App 内 SDK 副本。

使用 SDK README 的 `CoachSession.send()` / `reset()`。bundled hiplab profile 沿用 SDK 版本，运行时再与 App 可训练动作取交集；提示词与门禁均排除 `n-thomas-test`、未随包动作及未来目录新增但 App 不可播放的动作。

默认 Base URL 为 `https://api.uuugk.win/v1`，模型 `deepseek-v4-flash-0731`。`UGK_COACH_APP_KEY` 只从 `--dart-define` 读取，发送 `X-App-Key`；`X-Device-Id` 首次生成 UUID 后持久化，后续请求和新 Service 复用。不发送 Authorization。采用 SDK ugkWorker 配置的 120 秒超时；未配置密钥时直接走本地预设，不计为真实模型调用。

## 核心行为

- 纯文字显示气泡；`show_actions` 只接 `ValidatedActions`；`show_plan` 只接 `ValidatedPlan`。UI 不接收或解析原始工具参数，未通过门禁的内容不进入卡片。
- 关闭 AI 页面保留本次进程中的会话；「新对话」取消当前轮并调用 `reset()`。请求中禁用发送，有 75–120 秒说明、累计等待时长和取消入口；cancelled 不显示、不触发回落，旧轮晚到结果不覆盖新对话。
- 计划卡开练继续 `startGroup` → App `customPlan` → SDK `TrainerPlayer`；保存继续现有自定义训练组与剂量换算。模板映射保留入选动作的原有剂量、节奏和停留参数，只保留门禁已准入动作，不能从原套路补回被排除项。
- 断网、超时和门禁最终失败继续使用 App 内置关键词模板，明确标「预设方案」「不是 AI 生成的」。模板逐项及最终整份都经 SDK 门禁；无符合条件的模板时只给说明，不安排开练。原有红旗情况提示保留。
- `CoachContext` 来自实际 HipStore：用户水平、选择时长、场地、锁定方向及近期疼痛反馈。髋部保护映射到目录支持的 avoid，方向、麻刺和安全事实附入 notes；不虚构膝或腰的既往情况。

旧目录与动作包计量单位存在 8 处差异（见 [PR25 历史说明](ai-coach.md)）。预设送门禁时按 catalog 单位表达原剂量，落地仍保留 App 原套路参数；缺少器材、疼痛保护等实际约束继续筛选。对应回归覆盖过滤后的预览、保存重载及真实 `startGroup` 交接，防止被删除动作重新出现。

## 验证与交付边界

本机检查与最终 Web 来源、数量和证据以 [验证台账](verification.md#2026-10-21-ai-工具会话升级) 为准。测试覆盖工具类型边界、三次门禁失败、取消/重置竞态、重复发送、上下文、HTTP 请求头与超时、离线模板、旧剂量换算及保存开练。

Web 使用 E 盘忽略目录的临时壳编译真实生产 `lib/main.dart`，保留实际 HTTP 客户端、门禁、HipStore、SharedPreferences 和训练播放器。只在浏览器网络层拦截响应，使用显然为测试值的 App Key，不访问真实 Worker；不注入 App 业务状态。该结果证明客户端核心功能，不能记为真实 Worker 冷烟或原生体验通过。

未构建或安装新 APK，App 版本保持 0.3.9+17；手机安装仍为此前来源 79c172d。show_actions/show_plan 的真实 Worker 冷烟、原生播放体验与 iOS 尚未测试。D-34 锁屏冻结继续保留已知失败，不以本轮 Web 结果关闭。未调整商店或发布配置。

代码和证据完成后交开哥审阅；本任务要求经同意后才合入 main 并普通推送。

## 2026-10-22 文档收束与分支保存

用户显式调用 cockpit-closeout，要求版本管理和台账对齐后保存、提交、push。本次只修正文档，开发候选仍5816c1b/SDK09a392b，App仍0.3.9+17；main保持e456d2a，AI尚未合入。沿用10月21日469/469、AI62/62、analyze0与Web核心结果，未再次构建、操作手机或调用真实Worker。最新版本身份见[版本管理](version-management.md#当前对齐快照2026-10-22)，完整Preflight及实际分支推送结果见[收束回执](verification.md#2026-10-22-版本管理与阶段收束)；上文“经同意合main”的边界保持。
