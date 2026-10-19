# 动作包规格 action-kit v1

状态：v1（2026-10-19，分支 `feat/rep-rhythm-voice`）。审计与改前改后数据见 [rep-rhythm-audit-2026-10-19.md](rep-rhythm-audit-2026-10-19.md)。

**动作包**是一个动作在 HipLab 里的全部可复用信息：显示文案、媒体引用、训练节奏（相位与时长）、语音脚本、审核记录。一个动作一个 JSON 文件，以 **Pose-Hub 动作 ID** 为键，便于以后整体搬到 3D-Pose-Hub 作为上游数据。

> **原则（开哥，2026-10-19）：“动画没必要一定和真实训练时长一致，动画只负责演示。”**
> - **训练参数是唯一真源**：次数、时长、周期、相位、侧别都以动作包 `training`（+ 路线剂量覆盖）为准，语音按训练参数报数/报时。
> - Pose-Hub spec 实测的相位时长（`animation`）**只作缺省参考**：没写显式相位时拿来当默认节奏，`kit_rules.py` 里写了显式 `phases` 就以它为准。
> - 演示视频只循环播放作示范，**不要求与语音逐次对齐**，也**不因动画而改剂量**。“剂量与动画不一致”不再算待定问题，不写进 `review.flags`。

| 位置 | 作用 |
|---|---|
| `assets/action_kits/<id>.json` | 46 个动作包（Pose-Hub v0.2.0 全部 dark 视频动作） |
| `assets/action_kits/index.json` | `action-kit-index@1`：Pose-Hub 版本 + 动作包路径列表；App 只从这里加载 |
| `tools/action_kits/action-kit-v1.schema.json` | JSON Schema（draft 2020-12） |
| `tools/action_kits/kit_rules.py` | 人工规则：每个动作的类型、相位词、默认剂量、以及动画轨道描述不了单次动作时的显式相位（每条带 `why`） |
| `tools/action_kits/build_action_kits.py` | `build`（测相位、生成动作包）/ `check`（校验）/ `overview`（审核用 CSV + HTML） |
| `lib/hip/domain/action_kit.dart` | Dart 侧模型：`ActionKind`、`KitPhase`、`KitDose`、`ActionKit`（`sideSeconds` / `stretch` 与 Python 同公式） |
| `tools/hip_content/build_hip_content.py` | 生成 `assets/hip/hip-content.json` 时给每个路线步骤写 `kit` 引用 |

## 1. 字段说明

顶层必填：`schema`、`id`、`display`、`media`、`animation`、`training`、`voice`、`review`。

### 1.1 `schema` / `id`
- `schema`：固定 `"action-kit@1"`。不兼容的改动升到 `@2`，同时更新 Schema、`check` 和 Dart 解析。
- `id`：Pose-Hub 动作 ID，等于文件名（不含 `.json`），也等于 `drill-anim/specs/<id>.js` 的规格 ID。

### 1.2 `display`（显示）
| 字段 | 类型 | 说明 |
|---|---|---|
| `name` / `point` | `{zh, en}` | 动作名、一句要点；两种语言都必须非空 |
| `cautions` | string[] | 需要提醒的部位（如“腰”“膝”），供安全提示 |
| `targets` | enum[] ≥1 | `flexion` `extension` `abduction` `adduction` `internal_rotation` `external_rotation` |
| `methods` | enum[] | `relax` `flexibility` `control` `strength`，决定通用要点 `cue.<method>.N` |
| `level` | enum | `beginner` / `advanced` |
| `sided` | bool | 是否分左右侧 |
| `firstSide` | `right` / `left` / null | 双侧动作先做哪边（编排规则：右先左后） |
| `poster` | `{dark, light}` | 封面图资源路径；浅色暂无时为 `null` |

### 1.3 `media`（媒体引用）
- `poseHub`：`version`（冻结版本，例 `0.2.0`）、`spec`（规格文件路径）、`specSha256`（规格 SHA-256，`check` 用它发现上游改了规格而动作包没重建）。
- `video.dark`：`{asset, loopSeconds, posterTime}`，必填；`video.light`：同结构或 `null`（槽位必须存在）。

### 1.4 `animation`（实测记录，只作参考）
动画的测量结果，仅用作计数类节奏的缺省值；它不约束剂量，也不要求语音与它同步。
- `loopSeconds`：动画循环长度（8 / 10 / 12 s）。
- `track`：用来测量的主轨道名。
- `reps`：每一次动作的 `[起动, 到顶, 回落起点, 回到底]` 四个时刻（s），按主轨道 3 % / 97 % 穿越点测得。
- `source`：测量来源说明。离线 `build` 不带 `--pose-hub` 时原样保留本块。

### 1.5 `training`（节奏，唯一真源）
剂量与语音节奏只看这里（路线可覆盖 `reps` / `holdSeconds` / `seconds`）。可以与动画不同。
| 字段 | 说明 |
|---|---|
| `kind` | 6 类之一，见 §2 |
| `unit` | `reps`（计数类）/ `seconds`（保持类） |
| `sided` | 与 `display.sided` 一致；路线步骤的 `sided` 必须与它一致 |
| `leadSeconds` | 训练段开头“开始”到第一次报数的引导时长，v1 固定 1.0 s（与语言无关） |
| `defaults` | `reps` `sets` `seconds` `holdSeconds` `restSeconds`；计数类必须有 `reps`，保持类必须有 `seconds` |
| `cycle`（计数类必填） | `seconds` 一次的时长；`offset` 动画里第一次动作的起点（仅记录，不要求画面对齐）；`phases` 相位列表；`source` 来源：`measured: …`（取动画实测作缺省）或 `training parameters (kit_rules phases)`（训练参数显式给出，覆盖实测） |
| `cycle.phases[]` | `id`：`go` 起 / `hold` 停 / `back` 落 / `rest` 间歇，第一个必须是 `go`；`seconds`；`cue` 该相位开头说的词（一个 key，或随报数轮换的 key 列表，用于左右交替/方向交替）；`cueAt` 相位开始后多久说（停留词等一拍再说） |
| `hold`（保持类必填） | `entrySeconds`：进入姿势所需时长（实测或规则值） |

### 1.6 `voice`（语音脚本）
所有值都是 `assets/voice/manifest.json` 里的语音 key（中英各一条预录音频）。

| 字段 | 说明 |
|---|---|
| `lines` | 本动作自带的文案：`drill.<id>`、`point.<id>`、用到的相位词 `w.*`。`build_voice.py` 从这里收集；同 key 不同文案直接报错 |
| `prepare` | 准备/休息期预告时依次说的 key（动作名、要点） |
| `go` | 训练段开头（`p.go` “开始”） |
| `count` | 报数模板，必须含 `{k}`（`n.{k}` → 一…十） |
| `lastRep` | 最后一次替代数字（`p.last_rep` “最后一次”） |
| `nextSet` | 第二组前（`p.again` “再来一组”） |
| `end` | 段结束后的第一句：计数类 `p.nice` “很好”，保持类 `p.release` “慢慢还原” |
| `switch` | `{left, right}`：换边口令 |
| `firstSide` | 双侧动作预告末尾“先做右边”（`p.right_first`）；单侧为 `null` |
| `coach` | 训练中可插的通用要点 |
| `midHold` | 保持类：`{half, last10, countdown}`；计数类为 `null` |

### 1.7 `review`
- `why`：节奏数字从哪来（规格注释、轨道、人工规则）。
- `flags`：需要人工决定的其他问题。非空的会在总览表里标出，不阻断 `check`。**剂量/节奏与动画不一致不算问题，不写进这里**（训练参数为准）。

### 1.8 路线如何引用
路线步骤只写引用 + 覆盖剂量，不复制节奏：

```json
{"drill": "n-seated-knee-lift", "dose": "每侧 3 次 × 停 5 秒", "seconds": 44, "sided": true,
 "kit": {"id": "n-seated-knee-lift", "reps": 3, "holdSeconds": 5}, "authored_seconds": 40}
```

`kit` 由 `build_hip_content.py` 用 `override_of(dose, kit)` 从剂量文案解析得到，只允许 `reps` / `holdSeconds` / `seconds` 三个覆盖。`seconds` 由 `side_seconds()` 算：计数类 = `max(路线原时长, ceil(lead + N × 周期))`；原时长被加长时保留 `authored_seconds`。

## 2. 六类节奏

单位是“一次”。第 k 次在 `lead + (k−1)·周期` 开始；报“k + 起词”，回落相位开始时报落词；N ≥ 3 时最后一次报“最后一次 + 起词”，之后整整一个周期段才结束，所以“很好 / 慢慢还原 / 换边”永远在最后一次做完之后。

| kind | 中文名 | 一次的相位 | 报数方式 | 放慢规则（路线时间多于所需） | 代表动作 |
|---|---|---|---|---|---|
| `rep_updown` | 计数·双相起落 | go → hold → back → rest | “k，起词”…“落词” | 动作速度不变；多出时间 60 % 放顶端停留、40 % 放底端间歇 | 单腿臀桥、深蹲、蚌式 |
| `rep_cycle` | 计数·正反循环 | go（正向一圈）→ rest → back（反向）→ rest | “k，向前画圈”…“反着画回来” | 一整圈是连续动作，整体等比放慢 | 四足画圈、骨盆画圈、直腿画圈 |
| `rep_alternate` | 计数·左右交替 | go → hold → back → rest；go 的词随 k 轮换左右 | “k，右膝向内”…“回正”，下一次换左 | 同 `rep_updown` | 坐椅雨刷、仰卧雨刷、开髋门 |
| `rep_hold` | 计数·带停留 | go → hold（= 剂量“停 N 秒”）→ back → rest | “k，蹲下” → 停留词（`cueAt` 1.2 s）→ 停留 ≥6 s 时末尾 3-2-1 → 落词 | 停留不加长（停 N 秒就是 N 秒），多出时间全放间歇 | 相扑深蹲停留、坐姿抬膝悬停 |
| `rep_breath` | 计数·呼吸配合 | 呼气相 → 停 → 吸气相 → 间歇 | “k，呼气，抱紧”…“吸气，放松” | 同 `rep_updown` | 仰卧抱膝 |
| `hold` | 保持计时 | 进入（`entrySeconds`）+ 保持 | 开始 → 要点 → 过半（≥30 s）→ 还剩 10 秒（≥20 s）→ 5-4-3-2-1 → 下一阶段开头“慢慢还原” | — | 各类静态拉伸 |

时间不够（N 次完整做完超过路线原时长）时不压缩动作，而是把步骤加长到 `ceil(lead + N × 周期)`。双侧：右先左后；紧侧多一组 = 两组，第二组前“再来一组”，每组都给满。疼痛降级减时长时减少次数，不压缩周期。暂停/跳过/恢复：所有节拍都是“有效时间”上的固定点，暂停不移位，跳过从新阶段 0 开始。

## 3. 语音模板

| 类别 | 中文 | English |
|---|---|---|
| 双相起落 | 开始 → 一，臀部抬起 …… 放下；二，…；最后一次，臀部抬起 …… 放下 → 换左边 | Go → one, hips up … lower; … last one, hips up … lower → switch to the left side |
| 正反循环 | 一，向前画圈 …… 反着画回来 | one, circle forward … now reverse |
| 左右交替 | 一，右膝向内 …… 回正；二，左膝向内 …… 回正 | one, right knee in … back to center; two, left knee in … |
| 带停留 | 一，蹲下 → 停住 → ……三、二、一 → 起 | one, squat down → hold → three, two, one → up |
| 呼吸 | 一，呼气，抱紧 …… 吸气，放松 | one, breathe out, hug in … breathe in, let go |
| 保持 | 开始 → 要点 → 还剩 10 秒 → 五…一 → 慢慢还原，换左边 | Go → coaching → 10 seconds left → five…one → slowly come out of it, switch to the left side |

准备/休息期（15 s）顺序：叮 + “很好（或慢慢还原），休息 15 秒” → “下一个 / 最后一个动作 + 名称 + 剂量 +（双侧）先做右边” → 要点 → 条件提示 → 留白 → 三、二、一 → 开始。按实测音频时长排队，放不下的要点自动省略。

相位词表（`w.*`，33 个）在 `kit_rules.py` 的 `WORDS`；会话短语 `p.last_rep` `p.release` `p.again` `p.right_first` 在 `tools/voice/voice_lines.py`。每个词必须短：要放得进它所在相位到下一个词之间的窗口。

## 4. 校验规则（`build_action_kits.py check` + `test/hip/action_kit_test.dart`）

1. JSON Schema（装了 `jsonschema` 时；没装则跳过这一步并提示，结构检查照做）。
2. 结构：顶层字段齐全；`schema == action-kit@1`；`id` 等于文件名；`display.name/point` 中英非空；`targets` 非空；有 dark 视频且有 `video.light` 槽位；`kind` 合法。
3. 上游一致：`id` 是冻结 Pose-Hub 版本（`pose-hub.lock.json` + `tools/pose-hub-manifest.json`）里的动作；`specSha256` 与冻结清单一致，否则报“stale，用 --pose-hub 重建”。
4. 语音：`prepare` 和所有相位词在 `assets/voice/manifest.json` 里中英都有音频。
5. 节奏：相位时长之和 = `cycle.seconds`（±0.05 s）；第一个相位是 `go`；相位 ID 只能是 go/hold/back/rest；计数类有默认 `reps`、保持类有默认 `seconds`。
6. **窗口**：中英两种语言下，每句话（含最长的“十 / 最后一次 + 起词”）的音频时长 + 0.1 s 必须小于它到下一句的窗口；停留 ≥6 s 时停留词不能压到末尾 3-2-1。
7. 路线：每个步骤都有 `kit` 引用且 ID 等于 `drill`；步骤每侧秒数 = `side_seconds()`；`sided` 一致；所有可播动作（路线动作 + L1 替代 + 疼痛替代）都有动作包。
8. Dart 测试另外检查：路线分钟数与路线名称一致；路线秒数与动作包节奏一致。

## 5. 迁移到 Pose-Hub 作为上游数据

v1 的设计就是为了能原样搬走：键是 Pose-Hub ID，`media.poseHub` 已记录版本与规格 SHA，相位测量只依赖规格轨道。建议步骤：

1. 在 3D-Pose-Hub 增加 `drill-anim/kits/<id>.json`（内容与本仓库 `assets/action_kits/<id>.json` 相同，Schema 一起搬到 `drill-anim/kits/action-kit-v1.schema.json`），把 `build_action_kits.py build` 的测量部分（`measure` / `reps_of` / `cycle_of`）和 `kit_rules.py` 移到 Pose-Hub 的工具里，在 Pose-Hub 发版时生成并做 §4 第 2/5/6 条检查。
2. 发版清单（`manifest`）为每个动作增加 `role: "kit"` 条目（路径 + SHA-256），与 video/poster 一起冻结。
3. 媒体路径：上游包里 `media.video.*.asset` 写 Pose-Hub 发布内的相对路径；HipLab 同步时（现有媒体同步工具）改写为 `assets/drill_media/...`，或在 HipLab 加载时做映射。
4. 语音：上游只放文案（`voice.lines`），**不放音频**；HipLab 继续用 `build_voice.py --keep-existing` 生成本地预录，`check` 第 4 条保证不缺条。
5. HipLab 侧：`pose-hub.lock.json` 升级到含动作包的版本后，同步脚本把 kit 复制到 `assets/action_kits/` 并重建 `index.json`，然后跑 `build_hip_content.py` 和 `check`。本仓库的 `build` 改为只做“同步 + 校验”。
6. 兼容：迁移期间两边 Schema 都是 `action-kit@1`；`index.json` 的 `poseHub` 字段与 lock 不一致时 `check` 报错。产品相关的字段（`voice.coach`、`review`）如 Pose-Hub 不想持有，可拆成 HipLab 覆盖层 `assets/action_kits/overrides/<id>.json`，按字段深合并（v2 再定）。

## 6. 如何新增一个动作

1. 确认动作已在冻结的 Pose-Hub 版本里（有 spec 和 dark 视频）；没有就先在 Pose-Hub 制作发版并升级 lock。
2. 在 `tools/action_kits/kit_rules.py` 为它加一条规则：`kind`、各相位的词（复用 `WORDS`，确需新词就加到 `WORDS`，中英都写、尽量短）、默认剂量、`why`；主轨道描述不了单次动作时写显式 `phases`。
3. 在 `tools/hip_content/` 的源数据里补显示文案（名称、要点、目标、方法、注意部位）。
4. 生成：
   ```bash
   python3 tools/action_kits/build_action_kits.py build --pose-hub ../3D-Pose-Hub
   python3 tools/voice/build_voice.py build --keep-existing \
       --zh-voice zh-CN-XiaoxiaoNeural --en-voice en-US-JennyNeural   # 只生成新增/改词的语音
   python3 tools/hip_content/build_hip_content.py               # 若加入路线
   python3 tools/action_kits/build_action_kits.py check
   python3 tools/action_kits/build_action_kits.py overview --out /tmp/kits   # 人工审核
   ```
5. 跑 `flutter analyze` 和 `flutter test`（`action_kit_test`、`hip_rep_rhythm_test` 会覆盖新动作），把审核发现写进 `review.flags`。
6. 新语音跑 `tools/voice/audit_voice.py`（响度 −16 LUFS、真峰值 ≤ −1.2 dBTP、无截断），并真机试听。

## 7. 画面与语音（按原则，不是限制）

- 演示视频在 WebView 里按原速循环，语音按训练参数走；两者不要求起点、周期或次数对齐，放慢的步骤画面比语音快也属正常。`cycle.offset` 只作记录。
- 2026-10-19 按原则回正的 3 个动作（原先 `review.flags` 里的“剂量与动画不一致”已清除）：
  - `n-leg-circles` 仰卧直腿画圈：剂量“每侧 正反各 4 圈”，语音每侧报 4 次“k，向前画圈 …… 反着画回来”（每圈 3.6 s，一次 8 s），不再按动画的“画两圈 + 跨过去 + 回来”。
  - `t-seated-straddle-lift-1leg` 坐姿分腿单腿抬起：保持 2.5 s 一次（抬 0.8 / 停 1.0 / 放 0.6 / 歇 0.1），按单侧计数，每侧 6 次。
  - `n-seated-ir-drop` 坐姿后撑单膝内倒：一侧持续保持 30 秒（开始 → 过半 → 还剩 10 秒 → 5-4-3-2-1 → 慢慢还原 → 换边），动画的左右交替只作演示。
