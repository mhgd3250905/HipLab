# HipLab CoachConversationController 接入（2026-10-24）

基线为 HipLab main `64daf6ad23312438184ac7b79c5233cf19bb27ad`；候选分支 `codex/coach-conversation-050-20261024`，复用 E 盘现有干净副本。原目录 `E:/AII-3D/3D-Hip` 的液态玻璃未提交改动保留。当前仅交付 HipLab 候选，未操作 Flare，合入和推送 main 等待开哥本轮同意。`release/1.0` 保持 `8880c71645163809b18c1829247c83e79bb99842`。

## 固定来源

| 包 | 正式 tag | resolved-ref |
|---|---|---|
| ugk_coach | ugk_coach-v0.5.0 | d7e0b8fa3afc514fe3a53427cfddb8f7b24c984f |
| ugk_trainer | ugk_trainer-v0.2.3 | d7e0b8fa3afc514fe3a53427cfddb8f7b24c984f |
| ugk_coach_ui | ugk_coach_ui-v0.1.1 | 3302d6235a39e2c2b4b51fa196cc32b37c31b54c |

已用 `git ls-remote` 核实正式远端 tag。按[SDK 接入说明](https://github.com/mhgd3250905/ugk-3d-pose-sdk/blob/ugk_coach-v0.5.0/docs/coach-conversation-controller.md)实现；说明内的“待审”是 SDK 发布前文字，正式 tag 是否存在以上述远端核验和用户发布确认为准。App 与 lock 中仅更新 coach/trainer 两个条目，其余 hosted 依赖和 UI tag/源码不变，无本地路径或 dependency_overrides。

执行固定 `E:/DevCaches/flutter-3.44.7-hiplab/bin/flutter.bat pub get --enforce-lockfile` 成功，使用 Flutter 3.44.7 / Dart 3.12.2。trainer 此次 lib/android/ios 运行代码与 3302d62 相同，仅版本/coach 依赖适配；未修改 SDK。

## 替换范围与删除项

- `coach_service.dart` 删除 `CoachAnswer`、`ask()`、直接 agent send/reset/dispose、App `CoachConversation` 镜像与 `_preset()` 无 Key 会话旁路、事件中转流。App 只构造可信 agent 和一个 controller；生命周期交给 controller，自有 HTTP client 由 App 关闭。
- `ai_coach_page.dart` 删除 `CoachMessage`、自有 messages 列表、`awaitingQuestionId`、`answeredQuestions` / `answeredChoices`、`_nextResult`、`_generation`、取消令牌、选项校验/排序和手工恢复问题逻辑。直接绑定 SDK state/messages、canAnswer、answerText/answerChoices、cancel/newConversation/restoreHistory/invalidateQuestion。
- `template_fallback.dart` 删除旧 `CoachConversation` 的 `userTexts()` 镜像提取函数；已有预设方案的场景/红旗上下文从 controller.state.messages 派生。未增加兼容状态机或重复 SDK 实现。
- 删除旧无 Key 会话直调的失效测试、旧自有问题集合/编号/世代状态机测试；接口、认证、usage、范围门禁、预设安全和真实 App 保存开练用例迁移到 controller，保留其业务断言。

App 继续负责 Key/接口/UUID、可信本地白名单/profile、额外剂量门禁、TrainingPlan→CoachRoutine/自定义套路、素材、保存与训练启动。无 Key 全部 AI 入口和用量隐藏，controller/client 不创建，不触发远端请求或设备 UUID。

## 界面绑定

共用 CoachChatList、问题气泡、普通气泡、套路卡、HipLab Theme/字体/文案保持。AiCoachSession 只作 Flutter 呈现适配：监听 SDK、进度文案、计时、临时输入草稿、turnId 对应的预设/状态和用户气泡呈现标识，以及 message.id 对应的保存关联。其不持有待答问题、答案或展示历史副本。

草稿用于保持发送后立即显示用户气泡与停止后恢复输入；SDK 结果到达后使用 SDK 消息，用户行沿用草稿呈现标识以保持同一行、避免重复入场；问题与保存仍使用 SDK message.id。初始化未完成时禁用输入/例句，避免新对话前排队发送。首轮等待隐藏欢迎内容；对话上限直接从 state.lastResult 显示“开始新对话”，不依赖 SDK 是否生成空助理消息。

问题正文去重由 SDK 处理，App 独立渲染 SDK message.text 和 question。当前 SDK Agent 的实时 ask_user 结果仍以问题正文为 text；历史消息含独立说明时两者均显示，没有截取原始 LLM 响应。恢复历史先对计划与动作重新过当前 HipLab gate，失效输出不进入训练卡，历史问题保持只读。

## 验证与交付边界

- `flutter pub get --enforce-lockfile`：成功；lock 仅 coach/trainer 两个包变化，UI 与其余 hosted 依赖逐块比对相同。
- `flutter analyze --no-pub`：**0 issues**（最终 8.5 秒）。
- AI/接口专项：**44 通过 / 0 失败**（最终 12 秒），含同 controller 多轮回调、可信输出恢复门禁、问题+独立历史文字、初始化/新对话、等待行身份、停止还原输入、预设标注、保存/编辑/开练、无 Key 与中转认证/UUID。
- `flutter test --no-pub --concurrency=2 --reporter expanded`：**454 通过 / 1 条件跳过 / 0 失败**，runner 3分53秒（进程237.69秒）。唯一跳过为未设置 `VOICE_TIMELINE_OUT` 的导出用例。此为最终代码完整单轮，不是分批拼接。
- 收束前全量另有453通过/1跳过的历史日志；用户行呈现身份回归补齐后，最终44专项和完整454均重跑通过。
- `git diff --check`、新增文档链接、改动范围与锁文件核对通过。独立只读复核无阻断问题；其发现的首轮Intro、对话上限按钮、初始化期间发送竞态均已修正并有回归覆盖。


日志保存在 `E:/AII-3D/hiplab-releases/coach-conversation-050-20261024/`；最终待审 SHA 与日志摘要见该目录的 `review-receipt.json` 和本轮交付回复。按用户要求不构建、不安装、不操作真机或模拟器；本轮结果不表示新 SDK 已装手机。共用版本保留 1.1.0+21，没有商店操作或发布配置改动。SDK 无新增能力需求。

## 主线集成回执

用户已明确同意将固定候选 `448f1096a96746a235913a58a172826431b3ec13` 合入 main 并推送。核对候选及远端未变、E盘工作副本干净后，main从64daf6a快进到448f109，普通push成功；`git ls-remote`回读main为448f109，release/1.0仍为`8880c71645163809b18c1829247c83e79bb99842`。未force push、未修改release分支。

随后仅补批准和集成回执，最终main HEAD与远端核对保存在同一日志目录的 `approval-merge-receipt.json`。此文档提交不会改变已验运行代码、依赖或1.1.0+21版本；分析0、完整454通过/1条件跳过、专项44通过保持，不重复测试或构建。原目录31项WIP保持，无手机、模拟器或商店操作。上文待审/待同意描述为批准前快照。
