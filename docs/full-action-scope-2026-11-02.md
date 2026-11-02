# 全动作范围预检与主线合入回执（2026-11-02）

## 结论

用户确认 +28 真机测试通过并批准合入。远端 main 已从 `0f507a3124436d29e8e3fbb7e2769a1d7d3c9018` 以 `--ff-only` 快进到 `d0c28c59976e32d58e4999b524bb40c60ee3672a`，普通 push 后远端回读一致。没有重建 +28 APK；此处真机结论来自用户反馈。

已从新 main 建立 `codex/full-action-scope`。预检发现固定 SDK 的 8 个动作确实缺训练元数据，依用户原句“若 SDK 缺，停下报告，不在 App 自编”停止功能接入。本分支本轮仅提交报告和状态文档，动作范围、依赖、版本、自测题目和计分均未修改；+29/2029 APK 尚未生成。

## SDK / SF 的实际范围

- 固定 SDK：`d4502f35b1503d41cd782aa7fb3780c7f6591ad0`，继续使用完整 Git pin，没有更新或修改 SDK。
- 公共 delivery catalog 共 **219** 个动作，视频、cover、thumbnail 清单缺失均 **0**，媒体缺失排除清单为空。本轮未联网验证视频 URL。
- SDK standing 封面实体 **219/219**，大小、SHA256 与对应视频首帧绑定均通过；HipLab 已有的 46 张一致，若继续开放还需加入 173 张。本轮没有复制资源。
- SF 已提交 main `52d30aecc74c177c438f2b7e4d7c9970d5ea591a` 的口径是 **219 可浏览 / 211 可组计划**，不是 219 个都可规划。`lib/app/coach_chat_scope.dart:2` 明确该数量；`app_test_catalog.dart:127` 使用 `sdk.toAiCatalog()`，partial 保持 `training:null`；`app_test_content.dart:9` 声明不编造默认剂量，`:62` 起跳过没有 training 的动作。SF 没有补齐下列缺口。
- SDK `lib/src/catalog/pose_hub_app_test_pack.dart:308` 的 `toAiCatalog` 只投影完整训练定义。旧 semantic catalog 的 142 条不是公共动作总数；HipLab 自身旧 45 条授权及 46 条宿主内容限制也不是 SDK 缺口。

## 需要 SDK 补齐的 8 个动作

以下均为 SDK 自报 `trainingDefinitionComplete:false`，不是根据空数组或未知状态推测。证据在本仓已冻结的 [公共 catalog](../assets/public_media/catalog.json) 的 `actions[].trainingSemantics.missingRequiredFields`；与固定 SDK `packages/ugk_trainer/assets/pose_hub/app-test-pack-r1/catalog.json` 字节一致。

| 动作 ID | missingRequiredFields 原字段 | catalog 行 |
|---|---|---:|
| `h-bilateral-farmer-hold-native` | `muscleGroups` | 12847 |
| `h-db-shrug` | `muscleGroups` | 23900 |
| `h-floor-nordic-hand-reset` | `equipment` | 27222 |
| `h-kneeling-thread-needle` | `defaultDose.mode/reps/restSeconds/sets`、`doseRange` 及其 `reps/restSeconds/sets`、`level`、`purpose` | 31463 |
| `h-pike-scapular-elevation` | `muscleGroups` | 33001 |
| `h-towel-isometric-curl` | `defaultDose.restSeconds/seconds/sets`、`doseRange` 及其 `restSeconds/seconds/sets`、`equipment`、`level` | 44248 |
| `h-wall-palm-lift` | `defaultDose.reps/restSeconds/sets`、`doseRange` 及其 `reps/restSeconds/sets`、`level` | 46187 |
| `o-supported-ankle-eversion` | `muscleGroups` | 58430 |

公共 catalog SHA256：`75881cf91621c967f80732f0219f23e85b35e8bde5d1a51ee75dec5f7c5edd36`。SDK standing/index.json SHA256：`8a48386aaf353786850c8194c7c98e5fb4f05dd218acbbc6acb96e4fd12880e0`；219 张封面合计 5,813,392 bytes。

## 验证与工作区边界

本轮只做 Git 身份、SDK/SF 数据与封面清单的只读预检，以及文档检查；未修改功能，未运行新的 analyze、Flutter 全量测试或构建。既有 +28 的严格 analyze 0、428 通过 / 1 既有条件跳过属于上一轮证据，不能作为未实现 +29 的验收。

操作在既有干净 E 盘副本 `E:/AII-3D/3D-Hip-worktrees/coach-chat-sdk/3D-Hip` 完成。日常目录 `E:/AII-3D/3D-Hip` 始终保持 `codex/liquid-glass-design@71decd211969ca807142520111f7bdf999767651` 及原有 40 个 WIP 文件，未 stash、切换或恢复覆盖，无需恢复步骤。

本分支普通推送用于保存预检结果，不合 main；不打 tag、不动 `release/1.0`、托管、Flare 或商店，不执行 ADB。下一步需先处理上述 SDK 缺项，或由用户明确决定沿用 SF 的 219 浏览 / 211 可规划口径后继续。
