# PR #24 修复复审与 PR #22 组合验证（2026-10-19）

当前结论：**PR24 原 4 项 P2 在源码层面闭环；PR22 的 F8 已关闭，F9「删除动画未结束立即保存」仍待作者修复。组合版本373项测试及本轮Android正常播放验证通过；尚未合并 main。**

## 固定身份与主线边界

| 对象 | 身份 |
|---|---|
| PR24 修复来源 | `0ccef6b8dbb419ff67e176d1a51f35b2b0d25c7a` |
| PR22 修复来源 | `2cc40e3e51730d14f87056afe76e2b0c51dfcb19` |
| 本轮目标 main | `2d91688b499f6e3f3199fd1199e4504336b1e448`；结束前回读未变，后续本轮主线仅提交文档 |
| 组合验证分支 | `codex/pr22-pr24-validation`，已普通推送 `5725c3668baddbe844a9943ed81c9374bc7aa3f1`（两来源为父提交） |
| 复用工作副本 | `E:/AII-3D/3D-Hip-worktrees/pr22-fix-review/3D-Hip` |
| PR24 本轮证据 | `E:/AII-3D/hiplab-releases/pr24-0ccef6b-reaudit-20261019/` |

组合分支含本机集成修复，不能只用任一来源 SHA 标识最终构建；本轮组合提交为 `5725c36`，APK 哈希和实际安装身份另列。所有临时副本及交付产物继续位于非 C 盘。原 [PR24 首轮审核](pr24-review-2026-10-19.md)保留为 `e3655e5` 的历史结论，不改写成新版本通过。

## PR24 四项修复复审

- **F24-1：取消遗留语音。** `VoiceQueue.cancelAll` 无条件通知输出停止；尾音保护后的跟随句按前句预计结束时间记账。Controller 在第一个 await 前推进取消代次，并在准备、加载和播放边界检查代次，避免疼痛弹窗或暂停后继续播旧句及积压倒数。
- **F24-2：异步音量缓存。** 调用前捕获本次目标音量，平台参数和完成后的缓存使用同一值；后续准备能发现最新音量仍未应用。这里不声称已开始播放的旧句会立即改变音量。
- **F24-3：终态保活释放。** `ScreenAwake` 只负责页面常亮引用计数；`TrainingHold` 单独管理训练服务。自然完成保留 6 秒收尾后释放，关闭及 dispose 可立即释放；新会话 token 防止旧定时释放误停新任务。超时改为按计划时长加余量，并设上下界。
- **F24-4：旧 STOP 与新 START。** Kotlin 用最新期望 session/token 裁决旧请求，忽略过期 STOP，真正结束使用 `stopSelfResult(startId)`。Dart 使用 MethodChannel 的 FIFO 顺序及 token 检查；没有新增显式 Dart 异步请求队列。

以上为固定 `0ccef6b` 的只读源码结论，未发现新的已证实阻断项。详细依据留在证据目录的 `voice/voice-reaudit.md`、`android/keepalive-reaudit.md`。原 3 个独立暂停、疼痛及音量专项由本机串行重跑，全部通过，日志 `original-repros.log`；其中疼痛取消后实际无在播、无旧倒数启动。

## PR22 组合时补充的生命周期修复

`_complete` 冲突同时保留 PR24 的 6 秒收尾释放与 PR22 的 `completeSession(_ladder, plan: widget.plan)`，确保历史来源和单练不计连续天数的规则保留。

PR22 的「再来一组」复用同一播放器 State，不重新执行初始化。只保留 PR24 的首次 `TrainingHold.begin` 不够：旧轮次的 hold 可能已在 6 秒后释放，也可能仍有定时释放等待执行。本机集成在 `_restart` 中释放旧 hold，创建新 engine 后再申请新 hold，使每轮使用新 token 和新计划时长；不重复 `ScreenAwake.acquire`，页面常亮仍只 acquire/dispose 一次。

为此补充 2 个组件回归：结束后立即（0 秒）重播，以及等 7 秒后重播。两项在补充修复前失败，修复后通过；它们只证明模拟通道下的新旧 token 交接，不是 Android 实际后台服务验收。保留 PR22 同 State、共享音频输出、重置 ladder/clock/queue、带 plan 的历史记录和 F7 疼痛保护。

## 当前验证与未决项

| 项目 | 本轮状态 |
|---|---|
| PR24 原 4 项源码复审 | 静态闭环 |
| 原 3 个独立语音专项 | 本机3项全部通过 |
| 组合重播保活回归 | 0 秒 / 7 秒两项先失败、修复后通过 |
| 组合全量测试、静态分析 | enforce-lockfile成功；analyze无问题；373pass / 1条件skip（timeline导出），4分40秒 |
| 组合 APK 构建、资源/签名核对 | Kotlin/Gradle成功；debug证书连续、CRC/16KB对齐、575音频/94视频逐字节通过 |
| 手机组合覆盖安装与正常播放 | 21:56:37 install-r成功，APK SHA回读一致；14键状态JSON完全保持；中文h-squat 1次×1组两轮自然结束、再来一组通过，用户现场确认正常听到/播放无异常 |
| PR22 F8 | 已关闭；stable key 防止异步删除后剂量写错动作 |
| PR22 F9 | 仍存在，删除动画未结束立即保存可能保留已滑删动作；作者待修 |
| main 合并 | 未执行 |
| iOS | 未验收 |

用户最新验收范围已收窄为**正常播放无误**，后续按这一范围收束；不再扩展极大字号、耳机/蓝牙、ducking、锁屏及中断的系统矩阵。旧轮次已发现的行为和未验边界仍保留，不因本次范围收窄而改记为通过。

PR24未发布GitHub评论或review；PR22既有授权评论更新本轮实际证据。未操作商店发布。

## APK、真机与证据

组合源码 [`5725c36`](https://github.com/mhgd3250905/HipLab/commit/5725c3668baddbe844a9943ed81c9374bc7aa3f1) 已普通推送验证分支；main运行实现仍是原已合入版本。APK为 `E:/AII-3D/hiplab-releases/pr24-0ccef6b-reaudit-20261019/hiplab-0.3.6+11-pr22-pr24-combined-arm64-debug.apk`，174,512,710bytes，SHA256 `922ca6a7e1fa6da07ad96479dde2e9fa32a218515d8d0a0a3235a6ce664f643e`。版本0.3.6+11、包名com.ugk.hiplab、既有debug证书SHA256 `3761270a4764157f0e389014a9e5b800b05403bfddce0f4f7f8c039f6a53bdc7`。新增TrainingSessionService及3项前台服务/唤醒权限确实入包。初次Gradle19.9秒，增量APK出现ZIP空洞，保留异常包并只移出单个生成APK后重打16.9秒，最终最大间隙0；未改依赖、版本或发布配置。

手机2602BRT18C / Android16（API36）已由PR22单独包2cc40e3覆盖升级为本组合包，安装哈希匹配；不是把main基线的PR24独立包直接覆盖含练习库字段的用户数据。升级前后14个状态键及值完全相同。之后两轮中文徒手深蹲均自然完成，新增记录恰2条single/h-squat/5秒/completed=true（21:58:05.623404、21:58:45.385723）；现共有10条本轮测试记录，原8条逐项保持、两份训练组及全部非记录字段保持，doneDays未变，首页连续1天。用户在本会话现场答复「正常听到，播放无异常」，记为正常播放听感确认，不扩张为两语言逐句或全系统验收。

两轮播放中的dumpsys均见TrainingSessionService isForeground=true及活动PARTIAL_WAKE_LOCK hiplab:training；两轮自然结束、收尾时间过后，服务消失且活动唤醒锁消失。Power历史记录第一轮21:57:45.737取得、21:58:11.645释放，与21:58:05.623完成后6秒收尾一致。页面仍在结束页，未靠关页释放。本次第二轮是在首轮释放后重播；立即重播由前述0秒回归覆盖。没有对快速退出重进的原生Intent竞态作真机复现，F24-4为源码+模拟通道证据。

`native-normal-logcat.txt` 为本次安装后App PID17378的383,017bytes日志；未检出FATAL EXCEPTION、Unhandled Exception、ExoPlaybackException、Playback error、onPlayerError、ANR或前台服务启动失败。仍有OEM/资源回收等E级日志，不统称「无错误」。该采集中未出现HipTrainingService自定义tag，服务释放结论取自dumpsys及Power事件，不伪造token顺序日志。正常播放后手机已回今日页，中文/深色与显示设置保持。

身份见 `apk-identity.json`；数据/服务断言见 `normal-playback-audit.json`；听音原答复见 `user-listening-confirmation.md`；另有两轮准备/结束截图、服务/电源/音频快照及状态回读。上述证据和APK保存在本机E盘，不随Git推送，也未公开上传私有偏好。

结束前再次inspect：两PR均OPEN、无checks或现有review决定；PR24 head0ccef6b、MERGEABLE/CLEAN，PR22 head2cc40e3、CONFLICTING/DIRTY；actual targetHeadOid均2d91688未变。PR24 baseRefOid为2d91688；PR22报告的baseRefOid为fcffded5288b2ad62253dc1c7661918d5eac5e4c，未把它误用为最新main。组合仅解决本机合并冲突并保留双方历史，不代表远端PR22冲突已消除。以后main若仅推进本轮文档，运行验证不因此重复构建。


后续更新：PR22 a586de3已修F9并在组合9b22dcc完成原生复核，旧F9待修结论为当时快照；详见[最新F9复审](pr22-f9-reaudit-2026-10-19.md)。


合并更新：开哥同意后，#22/#24已于2026-10-19 23:32合入并推送main，GitHub均MERGED；本页旧未合入结论为阶段快照。详见[最终合并身份](pr22-f9-reaudit-2026-10-19.md)。
