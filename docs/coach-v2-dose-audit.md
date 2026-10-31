# Coach v2 剂量对齐审计（2026-10-31）

HipLab 的剂量真源仍为 `assets/action_kits/<id>.json` 的 `training.defaults`，尤其是计数停留动作的 `holdSeconds`；不从演示视频周期反推剂量。本次不升级动作素材、media lock、taxonomy、器械或安全元数据。目录保留 46 个动作包对应的可信动作数据；AI profile 单独声明 45 个白名单，排除 `n-thomas-test`。

## 八项改前改后

这里把旧上游缺陷与本次实际差异分开记录。八条单位不一致来自 SDK 的旧 `test/fixtures/pose-hub-catalog.json`（catalog 0.1.0）；HipLab 本地 main `1083b49` 已按动作包修过这八条 mode，缺少的是两条停留参数。本轮补齐它们，并验证八条完整默认剂量与 SDK 固定提交 `66dd98a549c1ff5fedecb626a7c88583090a1440` 正式内置目录 0.3.0 一致。不能把这八条 mode 都算作本轮新增修复。

| ID | 旧上游 catalog 0.1.0 | 本地 main 1083b49 | 本轮完整结果（action-kit） |
| --- | --- | --- | --- |
| `h-adductor-rock` | time，1 × 30 秒 | reps，1 × 5 次 | reps，1 × 5 次 |
| `h-knee-hug` | time，1 × 30 秒 | reps，1 × 6 次 | reps，1 × 6 次 |
| `h-sumo-pry` | time，1 × 30 秒 | reps，1 × 3 次，缺 holdSeconds | reps，1 × 3 次，每次停 **10 秒** |
| `n-pelvis-circle` | time，1 × 30 秒 | reps，1 × 4 次 | reps，1 × 4 次 |
| `n-seated-ir-drop` | reps，1 × 8 次 | time，1 × 30 秒 | time，1 × 30 秒 |
| `n-seated-knee-lift` | time，2 × 30 秒 | reps，1 × 3 次，缺 holdSeconds | reps，1 × 3 次，每次停 **5 秒** |
| `n-seated-squeeze` | time，2 × 30 秒 | reps，1 × 8 次 | reps，1 × 8 次 |
| `n-squat-shift` | time，1 × 30 秒 | reps，1 × 8 次 | reps，1 × 8 次 |

完整结果的 `restSeconds` 均为 15；侧别以对应动作包 `training.sided` 为准。旧上游前三、第四、第五和第八条休息为 10 秒，第六/第七为 30 秒；这些历史默认值不覆盖 HipLab 的 15 秒。

## 可复现来源

- SDK 正式目录：`packages/ugk_trainer/assets/pose_hub/app-test-pack-r1/catalog/catalog.json`，version `0.3.0`，来源 Pose-Hub `93d8f52`。固定 SDK commit 为 `66dd98a549c1ff5fedecb626a7c88583090a1440`；目录原始字节 SHA-256 为 `40610dbb71b58886ebe001409ae15161761747b4f776e74a252e7b1f8df6e983`。
- 动作包聚合 SHA-256：`be4c05c66e86e32152a30b523553d654e2c1820b722b7fffce1a32174e060396`。聚合算法沿用原工具：按 index 路径排序，将路径、NUL、文件原字节依次送入 SHA-256。
- 本地 `assets/coach/catalog.json` 保留其原 `version: 0.1.0` 和原媒体快照来源；`source.hiplabDoseSource.alignedCatalog` 单独记录本次 **剂量投影** 对齐的 0.3.0 来源，不冒充全目录已升级。
- `tools/coach/sync_coach_assets.py` 使用 `git show <ref>:<path>` 读取已提交 SDK 目录，避免借用 SDK 目录里的未提交改动。它不再覆盖独立维护的 `assets/coach/hiplab.json`。

```powershell
python tools/coach/sync_coach_assets.py E:/AII-3D/3D-Pose-SDK --sdk-ref 66dd98a549c1ff5fedecb626a7c88583090a1440
python tools/coach/sync_coach_assets.py --align-local --check
python -m unittest tools.tests.test_coach_dose_projection -v
```

## 完整周期数据投影与 SDK 估时接口事实

固定 SDK 的 `lib/src/catalog/catalog.dart` 中，`Dose` 的类型字段为 mode、sets、reps、seconds、restSeconds；额外 `defaultDose.holdSeconds` 在 `Drill.raw` 中保留，但不是类型化 `Dose` 字段。`TrainingPlan.PlanSegment` 支持 `holdSeconds` 和 `rhythm`。

`PlanDuration` 对普通（无 segments）reps 项，优先取 `assets.videos` 的首个有效 `repSeconds`，缺省为 3 秒/次；它不会仅因 `defaultDose.holdSeconds` 出现就换算完整周期。因此本轮额外把动作包完整训练周期投影到该目录第一条视频来源的 `repSeconds`，让 SDK 直接按同一可信周期配时。它是本 App 范围内的训练剂量数据投影，不是视频测量值，也不改演示视频本身。

全部 46 个动作中有 **25 个计数动作**。逐条核对后 **14 处实际变化**（7 处缺失、7 处旧 3 秒值不符），其余 11 处本来正确。计时动作保持不动；全部视频路径、SHA、大小、loopSeconds、顺序与素材文件保持。

| ID | 原 repSeconds（缺失时 SDK 缺省 3 秒） | 本轮完整周期/秒 |
| --- | --- | ---: |
| `h-adductor-rock` | 缺失 | 4 |
| `h-hip-gate` | 3 | 4 |
| `h-knee-hug` | 缺失 | 4 |
| `h-quad-cars` | 3 | 8 |
| `h-sumo-pry` | 缺失 | 12.35（含停 10 秒） |
| `hip-flexors-A` | 3 | 4 |
| `n-chair-wiper` | 3 | 4 |
| `n-leg-circles` | 3 | 8 |
| `n-pelvis-circle` | 缺失 | 8 |
| `n-seated-knee-lift` | 缺失 | 7（含停 5 秒） |
| `n-seated-squeeze` | 缺失 | 4 |
| `n-squat-shift` | 缺失 | 4 |
| `n-windshield` | 3 | 4 |
| `t-seated-straddle-lift-1leg` | 3 | 2.5 |

动作包执行通过 `ActionKit.phasesFor` 把 hold 相位替换为动作包的 10/5 秒，再经 `sideSeconds` 给足完整次数。投影只解决单次周期口径：SDK `PlanDuration` 的普通 reps 项仍未包含动作包每组 1 秒 lead；双方准备/过渡策略也需按实际计划核对。故不能把 JSON 剂量字段与周期补全称为逐秒完全一致；真模型计划的 SDK 估时和 App 开练时长由本轮集成记录分别实报。App 没有增加教练判断或 SDK 估时旁路。

## 验证

`python -m unittest tools.tests.test_coach_dose_projection -v`：5 项通过，覆盖全部 46 条真实剂量、八项固定纠正值（含两条停留）、25 条完整计数周期、投影保留媒体/安全/动作顺序、只读检查不覆盖 profile。精确 SDK 来源核对和 `--align-local --check` 均退出 0；`git diff --check` 通过。App 全量测试和真模型对话由本轮集成记录统一给出。
