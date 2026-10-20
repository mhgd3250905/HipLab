# PR #22 / 2cc40e3 Android 真机复测（2026-10-19）

结论：F8 原错写场景已通过真机复测；新发现保存边界 F9，后台/锁屏连续运行也尚未通过，当前不合并。此记录区分真机操作、组件测试和实际听音，不把播放器状态或无错误日志等同于听感通过。

## 来源与安装

- PR [#22](https://github.com/mhgd3250905/HipLab/pull/22)，固定源 `2cc40e3e51730d14f87056afe76e2b0c51dfcb19`，目标 main `6299a382ae2114fb6914e3f56942d5116b8e2dbc`（之后本轮仅更新审核文档）。开始时 GitHub OPEN / CONFLICTING，无 checks/review 决定。副本继续复用 `E:/AII-3D/3D-Hip-worktrees/pr22-fix-review/3D-Hip`。
- Windows Flutter 3.44.7：锁定依赖获取成功、analyze 无问题、全量 **335pass / 1条件skip**。debug arm64 初次构建14.9秒；增量包有ZIP空洞，保留异常包后仅移出单个生成APK，重新打包15.0秒。没有改产品代码、依赖、版本或发布配置。
- APK：`E:/AII-3D/hiplab-releases/pr22-2cc40e3-retest-20261019/hiplab-0.3.6+11-pr22-2cc40e3-arm64-debug.apk`，174,481,110bytes；SHA256 `46dd0d0c4819ab4e29883fcdadcb3ccd2e6489d78d3f3f7395b6fc79f4f60342`。包名com.ugk.hiplab、0.3.6+11、既有debug证书连续；CRC/16KB对齐、575音频/94视频逐字节通过，最终ZIP项间隙为0。
- 用户确认连接后，识别手机2602BRT18C / Android16 / API36。先备份原APK和偏好，再 `adb install -r` 成功；回读安装APK SHA与本包相同。原安装包确认为9fa0cc0（SHA ce978c5f…），此次是 **9fa0cc0 → 2cc40e3**，不冒称重做main b12b0f5初始化测试。
- 升级前后 `flutter.hiplab.state.v1` JSON语义完全相同：安全答案、身份、自测、连续天数、提醒、主题、语音及现有库字段保持。原 doneDays 为10月17日/19日，首页连续1天。本机私有偏好和APK不入Git。

## F8：删除动画中编辑另一动作

通过。真机先通过动作选择器建立并保存 A=`h-9090-liftoff`、B=`h-adductor-rock`、C=`h-band-hip-ir`；再左删A，脚本在松手后配置100ms间隔点击B，打开的剂量面板确认为B，等待后改2组、完成并保存。回读准确为：

```json
[{"kitId":"h-adductor-rock","sets":2},{"kitId":"h-band-hip-ir"}]
```

C未丢，B不重复。原生输入命令自身启动开销没有精确计入此100ms，严格150ms的帧级窗口另由作者5项组件回归覆盖并在本机全量通过，不能将配置延时冒称设备测得的精确触摸间隔。

连续双删也未错删：真机删除前两项后保留C，稳定后编辑C为2组并保存准确为 `[C(2组)]`；两次动画窗口内按坐标立即点击未打开面板，不能将这部分声称为严格时序通过。作者的双pending删除/立即编辑等5项组件测试通过。截图、原生操作脚本、保存前后JSON和 `f8-native.mp4` 留本机证据目录。

## F9 / P2：左删后立即保存，被删项重新出现

真机与独立组件测试均确认，与F8的旧索引覆盖问题分开。位置：[group_editor_page.dart:98–101](https://github.com/mhgd3250905/HipLab/blob/2cc40e3e51730d14f87056afe76e2b0c51dfcb19/lib/hip/ui/library/group_editor_page.dart#L98-L101) 直接保存 `_current`；删除仍等 [391–392](https://github.com/mhgd3250905/HipLab/blob/2cc40e3e51730d14f87056afe76e2b0c51dfcb19/lib/hip/ui/library/group_editor_page.dart#L391-L392) 的 onDismissed 才从逻辑列表移除。

复现：保存一个至少两项的训练组；左滑提交删除第一项，在删除动画尚未结束时立即点底部保存；回到列表后重开。预期已删项消失，实际仍在。真机对 `[B(2组), C]` 执行后重新出现原两项；等动画结束再保存的控制组准确变为 `[C]`。

独立测试以真实Dismissible操作三项A/B/C，150ms后保存并重新初始化Store：得到 `[A,B,C]`，正确期望 `[B,C]`，失败；1000ms控制组通过。证据 `editor-pending-save.log`、`editor_pending_save_repro_test.dart`、`pending-save-native.mp4`、`pending-save-reopened-bc.png` 及两次状态回读。该保存边界在既有编辑器上仍存在，不把它冒称为stable-key修复新引入的回归。

建议保存前提交/等待已确认的删除，或在删除事务未结束时暂时禁用保存；不要保存旧 `_steps` 再丢弃后来的删除回调。

## 字号范围调整

起初按清单临时设密度569（1280px约360dp）及font_scale2.0，已看深色自测/训练组，并开始点按。用户随后明确当前阶段无需极大字号兼容，立即停止其余极端字号检查，恢复原font_scale1.0及物理密度520；不记为深浅全项通过，也不列当前合并门槛。规则写入实际协作入口AGENTS.md。正常字号下继续检查练习入口和日常系统播放行为。

## 原生播放与系统场景（第一阶段快照，后续见末节）

| 场景 | 已执行事实 / 当前判定 |
|---|---|
| 中文深蹲1次×1组，两轮自然结束 | 第二轮重新准备，完成记录恰增2条single/h-squat/seconds5/completed=true，doneDays不变；未以跳过代替自然完成 |
| 中文蝴蝶式30秒×1组，两轮 | 前台首轮正常到结束；第二轮中段按Home，后台30秒后返回可到结束，最终恰增2条single/s-butterfly，doneDays不变 |
| 上述后台连续运行 | **未通过**：开始后约45秒应结束；后台至约50秒仍只有首轮记录，回前台才补发第二轮（20:59:09.738）。说明完成事件延迟，不能仅凭回前台追上进度判后台通过 |
| 英文蝴蝶式首轮，锁屏30秒 | 确认English设置，20秒处休眠、30秒后唤醒。约50秒的锁屏状态尚无新记录，唤醒后才入账（21:01:32.709）；安全锁屏仍显示，后续UI需用户解锁。锁屏连续运行不记通过 |
| 英文保持第二轮、英文计次两轮 | 待安全锁屏解锁后继续 |
| 真实系统中断、外部音乐ducking、耳机/蓝牙 | 尚未完成，不用手动暂停或日志请求代替实际系统行为 |
| 实际口令完整性、第二轮提示音与听感 | Agent无法从ADB直接听到手机，仍需实际听音确认；原生轨道/焦点只作辅助 |
| iOS | 本轮未验收 |

本包没有PR #24的TrainingSessionService、PARTIAL_WAKE_LOCK、tailGrace/新队列修复或HipVoice慢加载日志。后台和锁屏观察属于当前共享播放的验收缺口，应与待修PR #24联动处理；不将问题归因于F8编辑修复。已有音频快照确认本App UID使用USAGE_MEDIA / CONTENT_TYPE_SPEECH及GAIN_TRANSIENT_MAY_DUCK；该请求本身不证明真实ducking和口令完整。

## 证据与合并边界

统一目录 `E:/AII-3D/hiplab-releases/pr22-2cc40e3-retest-20261019/`：原安装包/私有偏好、APK身份、构建/分析/335测试、独立失败专项、App截图/录屏、按App PID采集的logcat、音频与电源/锁屏快照、各轮状态回读及计时JSON。本机证据路径不代表远端备份；涉及用户数据及系统界面的文件不公开上传。

本轮测试产生的训练组/训练记录单列为测试产物，不清除旧数据；停止极大字号测试后恢复显示设置，后续已恢复原中文语音和深色主题，见末节。结果按用户授权回帖PR #22；不提交approve、不合并main、不上传商店。#19→#20→#21在本轮前已由GitHub确认历史合并，当前不重复合并；任何新的集成仍需开哥最终同意。

阶段结果已发布并回读一致：[PR #22 真机阶段复测评论](https://github.com/mhgd3250905/HipLab/pull/22#issuecomment-6268054160)。明确F8原场景关闭、F9及后台/锁屏未通过、极大字号退出门槛和安全解锁后待补范围；没有提交GitHub approve。

## 解锁后补齐与验收范围收束（2026-10-19）

用户解锁后，英文保持第二轮已自然完成；真实系统计时器闹铃确实把HipLab客户端焦点置为LOSS_TRANSIENT，播放器暂停在30秒。关闭闹铃后焦点恢复，等待5秒计时仍暂停，手动继续后于21:38:35.330689结束；再点「再来一组」，第三轮于21:40:24.341517正常结束。各新增single记录与剂量准确，doneDays仍为10月17日/19日。此处完成了真实闹铃中断，不冒称真实来电或实际听感全验。英文计次两轮未另做。

最终偏好为原中文语音/深色主题；font_scale1.0、物理密度520已恢复。只读校验22份状态快照、20份XML/JSON对应均通过，非测试设置与旧数据保持；当前共有两份测试训练组、8条本轮训练记录，保留以便审计，没有清用户数据。闹铃已关闭。证据 `resume-audio-audit.md`、`prefs-evidence-audit.json`、`settings-restored-final.*` 保存在上述E盘目录。

随后用户明确「先不用测试这么细，我们正常播放无误就行」。本轮后续收束为正常播放，不再继续耳机/蓝牙、外部音乐ducking或锁屏/中断矩阵；旧后台/锁屏失败保留历史，不改记通过，iOS未验。PR24返回0ccef6b后的源码复审、组合保活适配及新包正常播放另见[组合验证报告](pr24-reaudit-and-pr22-integration-2026-10-19.md)。F9仍待作者修复，main未合并。


后续更新：PR22 a586de3已修F9并在组合9b22dcc完成原生复核，旧F9待修结论为当时快照；详见[最新F9复审](pr22-f9-reaudit-2026-10-19.md)。
