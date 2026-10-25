# SDK 0.2.9 与 App 体验移植测试分支（2026-10-25）

基线 HipLab main `1083b499ec2bec145c6227e5e64c6944ab5716a1`；分支 `codex/sdk-029-app-feedback-20261025`。本轮只交付测试候选，不合 main，不动 release/1.0。按用户最后补充，先 Web 验证，**没有 ADB、真机安装或模拟器操作**；后续装机须保持签名并覆盖保留数据。

## SDK 来源与锁定

SDK 远端 main 核对为 `e6dd32d90d0533aecf595f17f002701c0bec7d7a`，以下三个 tag 的实际提交均通过 `git merge-base --is-ancestor <commit> <main>`。trainer/UI 为附注 tag，对象 SHA 与源码提交 SHA 分别记录，不能混用。

| 包 | 正式 tag | lock resolved-ref | 附注 tag 对象 |
|---|---|---|---|
| coach | ugk_coach-v0.5.0 | d7e0b8fa3afc514fe3a53427cfddb8f7b24c984f | 无，轻量 tag |
| trainer | ugk_trainer-v0.2.9 | 953be22414f23128af879dc62686db200db34265 | 184cc4828133c44b973041ae3b2be569a3260ccf |
| coach_ui | ugk_coach_ui-v0.1.3 | 159dadf058ef47f701e36a496668265f9fd3fc0d | 36a75cc7cccf152bde5ef9b1f3819aa6f58dbbdd |

固定 Flutter3.44.7 / Dart3.12.2，正式远端 `flutter pub get --enforce-lockfile` 成功。仅 trainer/UI 两个 lock 块变化，coach 与其余 hosted 依赖保持；无本地 path/override。SDK changelog 中“测试分支未合 main”等为发布过程历史，本轮以上述远端 ancestry 为准。

## 移植与取舍

参考 SmartFit `mhgd3250905/Sport-Helper` main `5efb3e0ba8dfe418f4b5ea0ce87e9e04f9b3e594` 的 [follow-up](https://github.com/mhgd3250905/Sport-Helper/blob/5efb3e0ba8dfe418f4b5ea0ce87e9e04f9b3e594/docs/phone-feedback-followup-2026-10-24.md)、[第1批](https://github.com/mhgd3250905/Sport-Helper/blob/5efb3e0ba8dfe418f4b5ea0ce87e9e04f9b3e594/docs/phone-feedback-batch1-2026-10-24.md) 和 `lib/ui/plan_page.dart`。SmartFit 全程只读、HEAD 与干净状态保持；没有复制其训练协议或 SDK 实现。按 HipLab 现有模型重写 App 呈现和协调逻辑。

| 项目 | 本轮处理 |
|---|---|
| 文章式训练图文 | 共用 `HipTrainingArticle` 接入内置套路和 AI 套路详情：标题、实际剂量/时长/休息、安排说明、分节、编号动作、普通视频、现有动作包要点；移除原缩略行/纯 ListTile 详情。 |
| 预览交互 | 默认静帧，手动播放/暂停；共用 `HipPreviewCoordinator` 只允许一个活动视频。以视频本身与滚动视口相交判定离屏，离屏卸载；手动暂停保帧，返回页面不自动播。 |
| 动作详情 | 单动作示范从自动循环改为手动预览。原单练剂量、疼痛/等级提示、替代动作、加入训练组和开练保留。 |
| 媒体交接 | 开练、打开动作详情、复制组编辑前先 suspend 预览并等 endOfFrame，再沿用现有导航。返回后只恢复可操作状态，不续播。 |
| 浮动训练入口 | 文章右下“前往训练”，文末留足按钮和系统安全区；保留套路复制入口，点击时重新经过现有 planner/profile 安全门禁。 |
| SDK HUD/暂停按钮 | 通过正式 SDK 更新获得，不在 HipLab 重写。仍用 HipLab 已有 theme、声音、疼痛及完成回调。 |
| 已有浅深素材、首帧、无Key门禁 | 保留当前随包浅深映射、可信白名单/profile、Controller、保存和开练逻辑，不重复引入 SmartFit 实现。 |

不移植透明/packed-alpha 素材、新动作目录、Pose-Hub v0.3.0、SmartFit93动作/下载清单、诊断/动作问题上报、全身肌群文案或其替代规则。文章只映射现有冻结动作包普通 MP4/封面，`bundledOnly:true`，没有 alpha 字段、目录扩张或 SDK 补丁。

聊天沉浸状态栏不移植：HipLab有固定返回/新对话栏，本轮保留既有 SafeArea。训练舞台继续使用原 `HipDrillArt → lib/core/media`，没有顺带迁移原生媒体桥；因此不能宣称 SDK 新的训练视频首帧/快切能力已全部接入。Web 的文章预览使用 SDK Web 播放器，原训练舞台 Web stub 的限制保留。

AI 详情继续使用当前 CoachPlanMapper 的结果，包括已保存并被编辑的训练组剂量；分节取映射保留的 blockName，不另写训练计划/剂量规则。正文只使用现有 display.point、tip/note/cautions，不编造 SmartFit 独有的肌群资料。

## 语音与前台服务：已验范围及 SDK 差异

SDK0.2.3→0.2.9 的 voice、engine、platform、result、TrainingSessionService.kt、Android Manifest/Gradle 和 ios tree 相同；plugin仅追加透明视频宿主注册/释放，原 training_session 通道未改。HipLab 自身 voice、trainer、core/media、Android/iOS 和动作包也未改。此为源码/测试证据，**不是本轮真机前台服务验收**。

用户接受 SDK 快切合并，追加要求普通切换时机保持、最终目标不吞不重。新增4个公开 SDK 集成用例实测：

| 检查 | 结果 |
|---|---|
| 自然自动跨相位 | 3秒边界准确播一次；后续tick不重复。 |
| 快速两次 skip | 末次操作后150ms仅播最终目标一次；再过1秒/3秒仍仅一次，中间目标和旧积压不播放。 |
| 0/50ms休息在合并窗内跨过 | 最终work播报一次，无吞掉/重复或陈旧休息提示。 |
| 单次手动 skip | **也会等待150ms**：149ms未播，150ms播一次。与旧版即时调用不同。 |

因此不能把“普通切换与旧版完全一致”写成已通过：自然自动切换已验；普通单次手动上一/下一也受 SDK 的合并窗影响，仍是待裁决的 SDK 兼容差异。HipLab只记录回报，没有添加开关、复制队列或修改 SDK；如需恢复单次手动原时序，应由上游处理。

## 验证与产物

用户后续明确不需要极大字体等异常状态测试：本轮以正常字号验收，不再扩展字号边界。下述既有测试运行记录保留，不新增兼容门槛，也不为此重复执行。

- 分析：`flutter analyze --no-pub`，0 issues（17.5秒）。
- 只跑9个受影响测试文件，**92/92通过**（36秒），覆盖新预览/文章、练习库与安全路径、AI卡与保存开练、HipLab语音适配、keep-alive replay、训练转场及4个导航语音用例。没有跑全量测试。
- 首轮为87过/1失败；失败为旧测试对暂停状态调用 pumpAndSettle，而新版暂停按钮持续呼吸。改成按弹层完成时间的有界检查，原休息计时断言保留；最终92单轮全部通过。
- 独立E盘 Web host 的严格锁解析与 release Web 构建通过；不向仓库增加 Web工程文件，也不构建 APK/AAB。构建有原有 CupertinoIcons 字族未包含提示，未改图标依赖，本轮页面实际显示正常。
- 390×844浏览器检查：原7套路/45动作入口、文章静帧、真实1080视频 readyState4且时间推进、旧视频paused而新视频播放、离屏iframe归零、进训练前全部卸载、退出后不续播。预览图与 DOM 播放证据落在下述目录。未把 Web 操作记为听音、完整训练或原生FGS验证。
- Playwright/Chrome调试MCP传输断开，改用Codex应用内浏览器完成验证。仅使用新建localhost测试资料，未动手机数据、SmartFit或SDK工作树。

日志、Web host/输出、截图 `web-article-review.png`、`web-proof.json` 和最终 SHA 回执保存在 `E:/AII-3D/hiplab-releases/sdk-029-app-feedback-20261025/`。App共用版本仍1.1.0+21；无Key入口继续隐藏，未调用真实云AI。

main保持1083b49，远端release/1.0保持8880c71；原目录31项液态玻璃WIP保留。当前为已测试分支候选、未合main、未装机。后续真机需用户恢复安排，并继续按同签名覆盖保留数据；SDK普通手动切换时序差异未被本轮测试掩盖。
