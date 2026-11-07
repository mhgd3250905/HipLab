# HipLab SDK 0.7.1 QA v2 候选验证与内部包

2026-11-04，分支 `codex/sdk-pin-v0.7.0`，基于 main `4d610f50ee47f2d4de7c19517eb7e99220bb2204`。测试/构建运行源码 `2c13e8a119409c857508c6c3e79dc27241e8e702`；后续新增 SDK 回归和交付文档不改变运行源码。候选交用户远程安装验收，不合 main、不打 tag、不提交商店。

## 接入范围

- 四个实际 SDK 包及 coach override 全部固定 `9dd93163e9f355665e5c923f374c64f03bf65a86`，已核对官方 annotated tag `ugk_trainer-v0.7.1` 的解引用；非SDK lock逐字未变，Flutter 3.44.7/Dart 3.12.2。
- 原 `CoachAppProfile` 设置 `agentMode: CoachChatAgentMode.qaV2` 与 `aiTags: appAiTags`。继续使用 SDK `CoachChatController` / `CoachChatPage`、原存储/白名单/安全/保存/开练边界；App没有问答session、页面适配或语言规则。
- 模型 `deepseek-v4.1-flash`，请求启用 thinking、reasoning_effort=max。无凭据的构建继续隐藏AI入口；内部验收包通过外部配置启用现有测试网关，不在Git保存凭据。
- `assets/coach/ai-tags/actions.json` 从 Pose-Hub `codex/ai-action-tags` / PR26 的固定提交 `5d17c24af859d905dbbdee4b1d623b99881ac618` 提取原始草稿，209条；逐项Git blob SHA1与固定提交一致，汇总文件SHA256 `747d5710f2ed2b68e12c07b08a718a4b80bf108ebab0b8ac29b2e581eb7e0133`，原始来源记录在旁边的provenance.json。仍为ai-draft、reviewed=false；未修改Pose-Hub。
- 原211授权上限保持；`h-sleeper-stretch`、`scapular-C`缺标签，按SDK目录回退，不补造、不映射替代。动作库/组选项210、Coach211、211封面、0内置MP4；未验收v3动作及UIr3候选不纳入。
- 单选/多选和卡片编号由SDK提供，App仅传标签与开关。旧0.7.0的App适配已另存仓库外且未提交，旧直接Agent试跑不作为本候选验收。

## 本机检查及源码绑定

| 检查 | 命令 / 结果 |
|---|---|
| 锁解析 | `flutter pub get --offline --enforce-lockfile`通过，四包ref/resolved-ref固定9dd93163；其余hosted依赖未升级 |
| 静态检查 | `flutter analyze --no-pub --fatal-infos`：0问题 |
| 全量test/ | 65个文件按4文件/批、批内concurrency=2、expanded执行，共458通过/0失败/68既有条件跳过；新增 `test/hip/hip_coach_qa_sdk_test.dart` 独立concurrency=1执行3通过/0失败/0跳过。精确覆盖全部66文件，合计461通过/0失败/68既有条件跳过 |
| 跳过范围 | 12首页截图+55 r2截图+1可选语音导出；本轮未新增跳过 |
| 新增回归 | 生产Host开启qaV2、209草稿/211范围/缺项回退；SDK页面单选即发、多选确认前零调用/顿号原文/推荐编号/唯一返回键/旧问题禁用；完整计划保存和重启恢复、含热身的编号跟进、越界保存拒绝且原计划保持 |
| 真实模型 | `flutter test --no-pub --reporter=expanded tools/coach/chat_qa_v2_live_probe.dart`，显式外部配置；经生产 `HipCoachChat.load -> SDK CoachChatController`，3段9轮18次实际请求，全部新模型+最大思考，自动检查0问题 |
| 构建及验包 | release arm64 split成功；包身份/2031/ABI/非debuggable、CRC、211封面/0MP4、标签asset逐字一致、签名连续、重签前后运行负载一致性均通过 |

65文件全量及真实对话于2026-11-04对运行工作树执行，同一运行代码随后固定到 `2c13e8a119409c857508c6c3e79dc27241e8e702`；新增3项回归、最终analyze、构建和验包在固定运行源上执行。新增3项回归/后续文档与运行源之间无lib/android/assets/pubspec差异，所以运行检查仍适用，不写成新HEAD重跑。测试分批清单、命令和结果在本机产物目录的test-summary.json / additional-regression.json。新增回归初轮曾出现2通过/2失败，原因是无效手写计划/模拟表单与widget等待；修正测试数据后最终3项通过，没有放宽SDK或App门禁。

## 真实对话结果与实际边界

1. 推荐练背→地点单选→居家→器械多选→编号推荐→换第2个：单多选经SDK answerChoices，已答问题禁用；第2项没有合格替代时如实保留原动作，没有扩大范围。
2. 在家徒手/墙安排10分钟髋部训练→换第1个→改5分钟：三个计划均通过原prepareTraining、savePlanCard、保存后详情准备，完整JSON保持。实际阶段610/626/296秒，卡片时长等于播放器阶段求和，均在目标±10%内；SDK QA估时596/612/288秒属于预计值，未机械当成执行时长。
3. 办公室不躺地、安静限制推荐通过；膝刺痛跟进只验证到安全追问且无新计划，未验证追问后的后续处理，不宣称完整安全场景或真机通过。

本轮限定场景未发现阻塞问题；AI标签仍未审、两条目录回退、没有合格替换时保留动作及更复杂场景均按实际边界保留。没有手机连接或安装操作，旧数据覆盖安装、正常字号实机观感和完整训练由用户远程安装验收。D-34历史锁屏失败不改写。

完整原文（用户/助手正文、选择题、卡片顺序）和逐轮结构化回执在 `E:/AII-3D/hiplab-releases/sdk-pin-v0.7.1-20261104/live/dialogues.md`、dialog-1/2/3.json、summary.json；没有收集headers或模型reasoning。本机证据未上传GitHub，所列路径不代表已有远端备份。

## 内部APK身份

| 字段 | 结果 |
|---|---|
| 文件 | `E:\AII-3D\hiplab-releases\sdk-pin-v0.7.1-20261104\hiplab-1.1.0+31-2c13e8a-internal-arm64-release.apk` |
| 构建源码 | `2c13e8a119409c857508c6c3e79dc27241e8e702` |
| 版本 / Android code | 1.1.0+31 / 2031 |
| 包名 / 架构 | com.ugk.hiplab / arm64-v8a，release、非debuggable |
| 大小 | 49,393,884 bytes (47.11 MiB) |
| SHA256 | `676a1df79cb40f244ef459d27a3e196d423728d09b84b3e8bccaacb0698a7d15` |
| 连续测试签名SHA256 | `3761270a4764157f0e389014a9e5b800b05403bfddce0f4f7f8c039f6a53bdc7` |
| 资源 / 安装 | 211公共封面、0MP4、209条未审标签；本轮未安装 |

原上传签名包另存；复用既有受忽略签名配置的本地hardlink，未复制签名密钥。release-apk.json保存完整回执；版本比现有+30/2030递增，不卸载、不清数据。main保持4d610f5，release/1.0与其他候选分支保持。
