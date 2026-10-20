# AI 定制训练（AI 训练助理第二个试验田）

2026-10-20 · 分支 `feat/ai-coach`（栈在 PR #22 `feat/training-library` a586de3 上）· 依赖 [ugk_coach](https://github.com/mhgd3250905/ugk-3d-pose-sdk) 0.1.1（`76829bd`，SDK main 最新）

HipLab 是三 App 共用 AI 训练助理 SDK 的第二个接入方（第一个是托马斯训练助手，3D-Body PR #122）。结构与交互沿用托马斯的集成，只换成 HipLab 的数据（内容包、动作包、内置套路、自定义训练组）和 UI 风格（HipPanel / HipPrimaryButton / LibChip …）。

## 用户路径

1. 「练习」页 →「我的」段，「新建训练组」下面的「AI 定制训练」卡片。底栏仍是 今日 / 练习 / 进度 3 个。只在中文界面显示（模型和目录文案都是中文；App 目前只有中文 locale）。未配置令牌时卡片带「未配置」标记。
2. 对话页：首次进入显示一行免责（含「你写的需求会发给 AI 服务」，「知道了」后不再显示）；空状态给三个示例。
3. 发送后显示分步提示（理解需求 → 挑动作配剂量 → 核对范围剂量安全）、已用秒数、「通常 30–40 秒」和进度条；可随时「停止」：HTTP 真正中止、不回落、不记进对话，原话回到输入框。
4. 结果：
   - `ask`：一句追问 + 选项按钮。最多追问一次：上一条已是追问时，App 在本轮条件里要求直接出计划；选项只在最新一条追问上可点。
   - `plan`：计划卡 = 缩略图、名称、剂量（按动作包口径）、预计时长、注意事项（avoid、AI 的 safetyNotes、剂量换算说明、固定一句「在不痛的范围内做，出现疼痛、麻木或头晕立即停止」）。AI 计划标「AI 定制」，回落标「预设方案」并写明「不是 AI 生成的」。
   - `reply`：纯文字（如红旗情况建议就医）。
5. 「开始训练」直接走现有训练流程（`startGroup` → 自定义训练组的 `customPlan` → 播放器，`PlanSource.custom`，锁定方向照常跳过并提示）；「保存为自定义训练组」后出现在「我的」，可编辑、可从组卡片开始。安全提示里有需先问医生的情况（`store.blocked`）时「开始训练」不可用。

截图（组件测试渲染，`test_screens/hip_ai_coach_shots_test.dart`）：

| | |
|---|---|
| `docs/ai-coach/1-practice-entry-light.png` | 练习页「我的」入口（浅色） |
| `docs/ai-coach/2-thinking-disclaimer-dark.png` | 首次免责 + 等待态（深色） |
| `docs/ai-coach/3-plan-card-light.png` | AI 计划卡（浅色） |
| `docs/ai-coach/4-preset-unconfigured-dark.png` | 未配置 → 预设方案（深色） |

## 计划怎么变成训练组

设计原则（开哥 2026-10-19）：**动画只负责演示，剂量以动作包训练参数为准。** 所以 AI 计划落地时一律换算成动作包口径，再按自定义训练组的同一套范围收进去（`lib/hip/coach/plan_mapping.dart`）：

| TrainingPlan v1 | HipLab 自定义训练组（custom_routines v1） |
|---|---|
| `blocks[].items[]` 按顺序 | 一串不重复的步骤，依次跟练（最多 20 步） |
| `rounds` | 折进组数：`sets × rounds`，最多 3 组（`DoseRules.maxSets`） |
| 同一动作出现多次 | 并进第一次的组数（仍最多 3 组） |
| `mode` 与动作包单位一致 | 计数类 → 次数，保持类 → 秒数，照用 |
| 计数类动作给了秒数 | 按动作包节奏换成这么多秒里能做完的次数（同单练「计时的计数动作」算法），卡片标 * |
| 保持类动作给了次数 | 没有节奏可换算，用动作包默认秒数，卡片标 * |
| 超出范围 | `DoseRules.clamp`：次数 1…2× 默认，秒 ½…2× 默认（5 秒一档，至少 10 秒），组数 1–3，卡片标 * |
| `restSeconds` | 取各动作中位数，就近落到训练组可选的 10 / 15 / 20 / 30 秒 |
| `title` | 训练组名（截到 12 个字，同编辑器） |
| `source=template`（预设方案） | 原样「复制成我的训练组」（`copyRoutine`，剂量与节奏照套路，记 `fromRoutine`） |

卡片上显示的剂量就是保存 / 训练时用的剂量（`doseText`，与训练组、播放器一致）；预计时长 = `CustomRoutine.seconds`（与训练组卡片同口径）。训练组数据格式没有改动，不需要迁移。

## 动作范围

- 目录：`assets/coach/catalog.json` = SDK 内 Pose-Hub 目录快照（catalog 0.1.0）里 `apps` 含 `hiplab` 的 46 个动作；profile：`assets/coach/hiplab.json`（SDK `profiles/hiplab.json` 原样）。升级 SDK 时用同一提交的 SDK 仓库重跑 `python3 tools/coach/sync_coach_assets.py <sdk 路径>`。
- 运行时范围 = profile 白名单 ∩ 动作大全（`inLibrary`：内容包里有视频、有动作包、不是自测演示）。不在交集里的 id 写进 `profile.select.exclude`，提示词目录表和校验器同时排除（用了会报 `E_SCOPE`，触发重写）。
- **当前：可用 45 个，profile 46 个。差异 1 个：`n-thomas-test`（托马斯测试）**——有视频、有动作包，但按 2026-10-19 拍板只用于自测演示、不进动作大全（训练形态是 `h-knee-hug`）。因此 HipLab 的系统提示词比 SDK 评测金样多排除这一项，前缀哈希与评测不同；没有改 Pose-Hub / SDK profile。
- 目录与动作包的剂量单位有 8 处不一致（目录 `defaultDose.mode` vs 动作包 `training.unit`）：`h-adductor-rock`、`h-knee-hug`、`h-sumo-pry`、`n-pelvis-circle`、`n-seated-knee-lift`、`n-seated-squeeze`、`n-squat-shift`（目录计时 / 动作包计数），`n-seated-ir-drop`（目录计次 / 动作包保持）。SDK 校验要求 AI 按目录单位出，App 落地时按上表换算回动作包口径，所以训练结果不受影响；单侧（perSide / sided）46 个全部一致。是否在 Pose-Hub 统一单位待定。
- 目录远端更新：配了 `UGK_COACH_CATALOG_URL`（manifest.json）时启动后后台检查一次，SDK 校验大小 / sha256 / 版本后才切换，失败保持随包目录；只存内存。远端发布位置待定。

## 配置与运行

令牌绝不进代码或仓库，只从 `--dart-define` 读。默认连自建 **UGK AI 中转站**（New API，`https://ai.uuugk.win/v1`）：上游 key 只在中转站，App 用中转站后台单独给 HipLab 发的令牌（可设额度、随时吊销；换上游只在后台改渠道，App 不用发版）。

```bash
flutter run \
  --dart-define=UGK_COACH_API_KEY=<中转站给 HipLab 的令牌>      # 必填；不填 = 未配置，只给预设方案
  --dart-define=UGK_COACH_BASE_URL=https://ai.uuugk.win/v1     # 可选，默认即此
  --dart-define=UGK_COACH_MODEL=deepseek-v4.1-flash-1017         # 可选，默认即此
  --dart-define=UGK_COACH_CATALOG_URL=https://…/manifest.json    # 可选，目录远端更新
```

模型参数用 SDK 预设 `LlmConfig.deepSeekOpenCsg`（max_tokens 6000、单次超时 90 秒、JSON 模式）。新增依赖：`ugk_coach`（git，固定 `76829bd`）；`path_provider` 原本就在 lock 里（经 shared_preferences），改为直接依赖、版本不变（2.1.6）。

## 回落与安全

- 断网 / 超时 / 限流 / 鉴权 / 服务端错误 / 输出截断：不重写，直接回落；两次校验都不合格（首次 + 带错误重写 1 次）：回落。未配置令牌：不调模型，直接回落。
- 回落 = 从 7 套内置套路里按关键词挑最接近的一套：A 办公室（办公室 / 工位 / 椅子…）、B 睡前（睡前 / 放松 / 晚上…）、C 晨起（早上 / 起床…）、D 久坐解压（久坐 / 下班 / 髋前侧 / 臀…，也是没命中时的默认）、E 训练前激活（跑步 / 健身 / 热身…）、F Breaking（街舞 / 托马斯 / 劈叉 / 一字马…）、M 椅边 2 分钟（两分钟 / 快速…）。回复第一句写明原因并说明「这是 App 内置的预设方案，不是 AI 生成的」，卡片带「预设方案」标记。
- 安全：AI 路径沿用 SDK 内核的红旗规则（剧痛、刺痛、麻木 / 放射痛、明显肿胀、刚受伤、术后、孕期产后、头晕胸闷 → 不出计划、建议就医）。离线 / 未配置时 App 用同口径关键词判断，命中只回就医建议、不给预设计划。开始训练仍走 App 自己的安全规则（安全提示拦截、疼痛锁定方向跳过）。

## 用量记录

每次模型调用一条 SDK `UsageRecord`，追加到 `<应用支持目录>/coach/usage.jsonl`（Web 只记内存）。进度页设置区「AI 定制用量」显示本机累计调用次数和输入 / 输出 token。SDK 不内置单价，花费待定。

## 代码位置

- `lib/hip/coach/coach_config.dart`：dart-define 配置
- `lib/hip/coach/coach_service.dart`：SDK 装配、范围交集、追问一次、回落、免责标记
- `lib/hip/coach/template_fallback.dart`：预设回落与离线红旗判断
- `lib/hip/coach/plan_mapping.dart`：TrainingPlan → 自定义训练组 / 计划卡行
- `lib/hip/coach/usage_store.dart`（+ `usage_file_io.dart` / `usage_file_stub.dart`）：JSONL 记账
- `lib/hip/ui/coach/ai_coach_page.dart`：入口卡、对话页、计划卡、等待态
- 接线：`library_actions.dart`（`LibraryActions.coach`）、`practice_page.dart`（入口）、`hip_app.dart`（`HipApp.coach` 注入、会话持有、用量面板）
- `test/hip/hip_ai_coach_test.dart`：19 个测试（SDK `FakeLlmClient`，不打真实网络）
- `test_screens/hip_ai_coach_shots_test.dart`：4 张截图（不在 `flutter test` 默认集合里）

## 真实冒烟（2026-10-20 09:26 CST，经 UGK AI 中转站，1 次）

App 随包 profile + 目录快照、App 同样的范围交集（排除 `n-thomas-test`，范围 45）、SDK 原样编排，请求不带 Authorization（沙盒为 ai.uuugk.win 注入中转站令牌）。

| 输入 | 久坐一天髋前侧很紧，在家 12 分钟左右，想顺便练练臀，膝盖有点不舒服 |
|---|---|
| 结果 | **超时**：90.0 s 内中转站没返回（SDK 单次超时 90 s），走 `fallback(timeout)`；App 里此时会给预设方案（关键词命中 D 久坐解压 10 分钟） |
| token | 客户端未收到响应，记 0（上游若在断开后仍完成，可能已计费，需在中转站后台日志核对） |
| 提示词版本 | `kernel-v2-694a82ed.cd651.r1413@hiplab-1` |
| 连通性 | 同一时刻 `GET /v1/models` 200（0.16 s），三个模型都在，令牌注入正常 |

按约定只跑 1 次，没有重试。托马斯 PR #122 此前经 OpenCSG 直连两次分别 38.7 s / 42.6 s；这次是经中转站的第一次 completion 调用，超时原因（上游排队 / 限流后 New API 内部重试 / 渠道配置）需要看中转站日志。
