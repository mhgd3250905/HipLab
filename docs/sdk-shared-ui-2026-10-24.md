# HipLab 共用 SDK 训练与聊天界面接入

**后续更新：** 用户确认修复tags后，本轮改锁coach0.4.2 / trainer0.2.2 / coach_ui0.1.1（均3302d62），检查通过即可直接合main推送。下方旧tags及待审描述保留当时事实；当前主线结果以[修复补丁回执](sdk-tag-patch-2026-10-24.md)为准。

本轮从远端 main `8880c71` 创建 `codex/sdk-shared-ui-20261024`，工作副本 `E:/AII-3D/3D-Hip-worktrees/sdk-shared-ui/3D-Hip`。当前为待审开发分支；未合 main。`release/1.0`、原日常目录的液态玻璃未提交改动均保持原状。

## 依赖与实现

| 包 | 固定正式 tag | lock resolved-ref |
|---|---|---|
| ugk_coach 0.4.1 | ugk_coach-v0.4.1 | 88da65ab4e7d6753ab548d779f4168f023dbf9f8 |
| ugk_trainer 0.2.1 | ugk_trainer-v0.2.1 | f0ea0647586913b205fc6dbb75fc9f97cedc55ce |
| ugk_coach_ui 0.1.0 | ugk_coach_ui-v0.1.0 | f0ea0647586913b205fc6dbb75fc9f97cedc55ce |

共用开发版本为 `1.1.0+21`。三个包均使用 Git tag；无 main、本地 path 或 dependency override。SDK 源码未修改，未从 SmartFit 复制界面或逻辑。冻结动作素材仍为 Pose-Hub v0.2.0。

训练通过 App 的 `HipPlayerPage` 调用 SDK `TrainerPlayer`，App 保留 D-01 左右侧剂量、疼痛策略、感受反馈和以 sessionId 幂等保存的业务插槽。媒体框遵循播放器请求的舞台边界。0.2 的组完成统计按实际唯一组身份计算；紧侧额外组未完成时不能记为完整完成。

聊天列表、普通气泡、澄清气泡和套路卡分别使用 SDK `CoachChatList`、`CoachMessageBubble`、`CoachQuestionBubble` 和 `CoachPlanCard`，通过 `CoachUiTheme` 注入 HipLab 颜色、NotoSansSC 字体及文案，保留 App 导航、保存和开始训练回调。

`CoachService` 持有同一个 `CoachAgent`；过程事件只显示进度，问题仅在 `await agent.send` 返回 SDK 门禁结果后启用。问题气泡代替相同正文，避免重复。文字答案走文字回调；单选/多选保持原选项字符串及原顺序。提交答案时同步关闭旧问题并追加用户气泡，再发给同一 agent。取消、新对话、销毁和恢复历史会使旧问题失效；历史不自动恢复 SDK 待答任务。

动作范围固定为随包 HipLab profile 与本地动作库交集，替换 profile 的并集选择器为明确 ID 白名单；资产路径由 App 解析。模型结果先由 SDK 门禁产生 ValidatedPlan / ValidatedActions，才能映射 UI 或开始训练。本地模板同样经过门禁。HipLab 当前一组一种剂量；新 PlanItem.segments 在 SDK extraRules 中明确拒绝并要求重交，映射器防御性拒绝，避免静默丢段。无需 SDK 新能力。

无 Key 时练习页 AI 入口及设置用量入口均隐藏，保持原有中文和 iOS 平台边界。构建不传 AI Key，不创建在线客户端或安装 UUID；没有新增入口、硬编码凭据或商店配置变更。

## 验证与交付

运行代码提交 `429eaf5c0e952d60199ca95362bd3dd2880f8606`。Flutter3.44.7 / Dart3.12.2；分析0问题，最终完整测试集合 **451通过 / 1条件跳过**。为避免重复执行未变化的长语音队列测试，保留本轮首次全量中该文件10项通过的证据，其余全部文件在修正后重新运行，441通过/1跳过、2分24秒。初轮10项旧SDK断言失败及随后修正保留在[验证台账](verification.md#2026-10-24sdk-共用界面候选验证)，没有未解决失败。AI及聊天专项41项通过；包括20动作长详情可滚动、全部7模板经同一门禁。

App自己的目录生成工具 `python tools/coach/sync_coach_assets.py --align-local` 将剂量来源固定到本仓库action-kit：默认单位、范围、侧别与训练一致，profile允许真实内置2分钟套路，模板明确所需器材。重复生成字节一致，46个既有快照ID未增加或删除；运行时profile与动作库交集仍45个可信动作。未改变Pose-Hub冻结素材。

Android arm64 release最终编译98.1秒通过，不传AI Key。真机包与原手机测试证书一致，以 `install -r` 覆盖安装1.1.0+21。最终APK为 `E:/AII-3D/hiplab-releases/sdk-shared-ui-20261024/hiplab-1.1.0+21-device-test.apk`，104240666bytes，SHA256 `5d2923880587bf9c57e3493bb5de136c575384f2b1beaa67f6e4491d3827ee0a`。原上传证书签名编译结果也保存在同目录，二者用途分开，没有上传商店。

### 真机验收

设备QSG6Q8IFDMDELVGQ / 2602BRT18C；仅目标包com.ugk.hiplab。安装前0.3.10+19的测试证书保持，firstInstallTime仍为2026-10-17；未卸载、清数据或改系统音量/省电设置。原训练组1组“办公室（我的）”、累计4天与最近自测进阶10/12均在升级后实际核对。旧包非debuggable，无法用run-as备份私有目录；UI截图是可见数据保持证据，不能称完整数据备份。

第一轮从“练习→套路→M详情→开始”进入SDK舞台播放器，自然完成4/4（完成页3分钟），未跳过或暂停。完成按钮保存并返回套路，再到进度显示累计5天/连续1天，自测10/12保持。训练时唯一SDK TrainingSessionService为mediaPlayback/type0x2、通知4107；自然完成后服务不存在，通知记录为0。本包PID27089全程保持，crash buffer为空，logcat未发现fatal/Flutter未处理异常。

实际语音焦点CONTENT_TYPE_SPEECH活动已记录。用户随后要求“你再播放一次”，第二轮从同一M套路正常开始，并明确反馈 **“OK 我听到了没问题”**，本轮真机语音听感据此记为用户确认正常，非Agent实听。未扩展耳机、蓝牙、锁屏或来电矩阵；历史D-34仍保留。第二轮已推进到4/4，其后回到套路页且服务释放；Agent未捕获该轮完成页或保存操作，不将第二轮另记为完整训练通过。重播证据另存本地，未开第三轮。

首轮证据为 `native/final-native-result.json`，截图包括 `existing-group-and-no-ai.png`、`no-ai-usage-settings.png`、`training-work-2.png`、`natural-completion.png`、`saved-progress-after-training.png`；安装包在手机base.apk上的SHA也与本地一致。用户听感回执为 `native/user-audio-confirmation.json`。这些本地证据不进入Git，不代表已远端备份。

### 构建准备问题与修复

最初启动的API35模拟器已按用户要求停止，实际训练验收使用上述真机。本机Windows系统编码936曾误解码Git中UTF-8的中文pubspec，把version吞入description并错误识别0.0.0；初次依赖解析通过 `build/utf8-dart-sdk` 中同版Dart临时工具副本的进程级UTF-8 manifest完成。未修改系统编码、原Flutter/Dart工具、UGK SDK或Pub缓存源码；临时工具和日志不进入提交。

仅运行Dart pub get不会执行Flutter插件注册生成，首个试装包因此启动失败。已保留失败APK/日志，随后正常执行 `flutter pub get --offline --enforce-lockfile` 成功（lock无变化），生成忽略的 `.flutter-plugins-dependencies` 和 GeneratedPluginRegistrant.java，再完整重编译。最终APK已验证注册类存在且真机正常启动；不能把最初失败包算通过或继续交付。

iOS原生编译/安装和真实模型端到端未执行；SDK多轮与门禁使用实际SDK加Fake/本地HTTP回归验证，不把它写成真实云端评测。无SDK新能力需求。当前main和release/1.0远端均保持8880c71；本轮候选未合main、未推送或发布，等待开哥审阅同意。
