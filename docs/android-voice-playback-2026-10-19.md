# Android 语音播报三项真机问题（2026-10-19）

来源：开哥 2026-10-19 18:40 戴耳机使用一天后的反馈。分支 `fix/android-voice-playback`（基于 main `d9338ea`），沙盒完成代码、单测与时间线复现；**未构建 APK、未上真机**，原生部分待本机 Windows 安卓 agent 验收。

| # | 现象 | 结论 |
|---|---|---|
| 1 | App 放到后台时播放卡顿（已开自启动、后台运行、电池白名单） | 进程在后台没有前台服务：后台 CPU 组、语音间隙可休眠、Android 15+ 每句申请音频焦点被拒；每句都要重新 prepare，被节流时变慢 |
| 2 | 部分语音最后约半秒被突然掐断 | 计划内「倒数打断」：英文换边句 2.6 s，倒数「three」排在 2 s，被 stopSpeech 切掉 0.64 s；真机播放比队列时钟晚，实际切掉更多 |
| 3 | 连续播放时吞数字/短语，「3、2、1」整段听不到 | VoiceLineController 新句到来就作废还在等前一句尾巴/还在加载的旧句；播放器 prepare 一慢，每个数字被下一个数字顶掉 |

## 读过的链路

- 计时：`hip_player_page.dart` 用 `Timer.periodic(33 ms)` + 墙钟 `_ActiveClock`，**不依赖帧回调/Ticker**，后台无帧本身不会让调度失效（排除了“Ticker 后台停摆”假设）。`SessionEngine` 按绝对时间推进，计数提示晚于 0.6 s 即丢弃。
- 队列：`VoiceQueue` 用请求时刻作为句子开始，按 manifest 时长估算结束；计数（count）打断一切非计数句。
- 输出：`JustAudioVoiceOutput` 一个 voice 播放器，每句 `configure + setActive(=请求焦点) + setVolume + setAudioSources(prepare) + play`，播完 0.7 s 后释放焦点。Android 没有任何保活（注释原文“Android keeps Dart timers running while the process lives”）。
- Manifest：只有 `INTERNET`，无前台服务、无 WAKE_LOCK；`ScreenAwake`（wakelock_plus）只在页面可见时保持亮屏，`docs/development-roadmap.md` D-10 已记“手动锁屏不保证”。
- targetSdk：Flutter 3.44.7 默认 36。

## 素材排查（排除）

`/tmp` 脚本解码全部 570 条 m4a（ffmpeg→PCM）：manifest 时长与解码时长最大差 1 ms，容器时长不长于音频；每条尾部静音 ≥ 52 ms（en）/ ≥ 64 ms（zh），最后 10 ms 能量 ≤ −74.8 dB。**素材尾部没有被裁**，问题 2 不在文件。`tools/voice/audit_voice.py`：570 条中 1 条不合格（en `sec.66` 后半段弱 9.8 dB，本分支未改素材，与本问题无关，另记）。

## 根因与证据

### 问题 1：后台卡顿

1. 无前台服务的后台进程被放进后台 cgroup/cpuset（小核、低配额）；电池白名单只豁免 Doze 的部分限制，不改变调度组。每句 4–5 次 platform channel 调用 + ExoPlayer prepare 全在被压低的主线程/播放线程上。
2. 锁屏后两句之间没有音频在放，CPU 可以休眠，Dart 定时器跟着停；`SessionEngine` 对迟到 >0.6 s 的计数直接丢弃。
3. Android 15 行为变更（targetSdk ≥ 35）：“must be the top app or running a foreground service in order to request audio focus … returns AUDIOFOCUS_REQUEST_FAILED”（[官方文档](https://developer.android.com/about/versions/15/behavior-changes-15#audio-focus-restrictions)）。本 App 每句都请求焦点。
4. 慢 prepare 会进一步触发问题 3 的吞句。

> 真机证据待补：`adb shell dumpsys activity processes | grep -A3 com.ugk.hiplab`（修复后应为 FGS 级别）、`dumpsys audio | grep -i focus`、logcat `HipVoice slow load`。

### 问题 2：句尾被掐

时间线复现（`test/hip/hip_voice_android_timeline_test.dart` 同一套假播放器，真实 manifest 时长、每句 prepare 延迟 L）。main `d9338ea`：

| prepare L | zh 被切句 | en 被切句（最多切掉） |
|---|---|---|
| 80 ms | 0 | 14（0.75 s） |
| 300 ms | 0 | 14（0.97 s） |
| 600 ms | 0 | 14（1.47 s） |
| 1100 ms | 63 | 70（2.36 s） |

被切的全是 `p.release + p.switch_left`（“Slowly come out of it. Switch to the left side”，2.64 s），换边阶段 5 s，倒数「three」在 2 s。纯队列层（无延迟）也是这 42 处（全套路×3 等级），只有英文。原有测试“no line is cut by the session timeline”用的 Sim 没传动作包（kits），所以一直没覆盖到换边说“慢慢还原”的真实情况。zh 同一句 1.82 s，只差 0.16 s，真机稍有延迟即压到倒数。

### 问题 3：吞数字

main `d9338ea` 同一复现，全部 15 套路、等级 3：

| prepare L | zh 计数没播 / 总数 | en | 整段 3-2-1 消失 |
|---|---|---|---|
| 80 / 300 ms | 0 / 956 | 0 / 956 | 0 |
| 600 ms | 588 / 956 | 679 / 956 | zh 52、en 64 |
| 1100 ms | 506 / 956 | 456 / 956 | 118 / 118 |

机制（`voice_line_controller.dart` 旧 `speak`）：每次 speak `++_generation`；旧句在“等上一句尾巴（≤1.2 s）”或 `loadVoice` 之后检查 `_current(gen)` 失败就直接 return。倒数每秒一个，prepare 一旦接近 1 s，「三」还没加载完「二」就来了，「三」作废；「二」同理被「一」作废——整段 3-2-1 听不到。

## 修法（保持聚焦，无新依赖，未改 pubspec/lock）

1. **Android 前台服务**（原生 Kotlin，无插件）：`TrainingSessionService`（`foregroundServiceType="mediaPlayback"`，`stopWithTask`，一条低优先级常驻通知“开胯训练进行中”，PARTIAL_WAKE_LOCK 上限 3 h）。`MainActivity` 加 `hiplab/training_session` 通道；Dart `lib/core/platform/training_service.dart` 由 `ScreenAwake` 引用计数驱动（训练播放器、自测页已有的持有点），不改页面代码。Manifest 加 `FOREGROUND_SERVICE`、`FOREGROUND_SERVICE_MEDIA_PLAYBACK`、`WAKE_LOCK`。未申请 `POST_NOTIFICATIONS`：Android 13+ 未授权时通知不显示在通知栏（任务管理器里可见），服务照常生效。
2. **队列不丢句**（`VoiceLineController`）：句子按请求顺序排队播放；只有 `stopSpeech`（有意打断）和 `abandon`（中断/结束）会作废之前的句子。积压保护：排队超过 3 s 且后面已有更新的句子时才跳过（logcat `HipVoice skipped late line`）。音量未变时不再每句调 `setVolume`（少一次通道往返）。
3. **不掐句尾**：`VoiceQueue.tailGrace = 0.8 s`——要打断的句子只剩 ≤0.8 s 时不切，新句紧跟其后播。换边阶段按“换边句 + 0.4 s 余量 + 3 s 倒数”取整秒自动加长（`SessionScript.switchSecondsFor`）：zh 慢慢还原类 5→6 s、en 5→7 s，计数类/无动作包仍 5 s；训练剂量不变。
4. 可观测：`JustAudioVoiceOutput.loadVoice` prepare 超过 250 ms 打 logcat `HipVoice slow load N ms: …`。

修复后同一复现：80/300/600 ms 下 zh/en 全部 0 被切、0 计数丢失、0 重叠；1100 ms（prepare 比两次计数间隔还长，物理上跟不上）仍 0 被切、0 重叠，只跳过落后 >3 s 的积压句——这一档靠前台服务避免进入。

## 测试

- 新增 `test/hip/hip_voice_android_timeline_test.dart`（15 项）：真实 SessionEngine→VoiceQueue→VoiceLineController，假播放器按 manifest 真实时长播放、每句 prepare 80/300/600/1100 ms，测试绑定的假时钟驱动 33 ms 定时器（无帧回调）；断言不掐句、计数全部播出、不重叠、换边句播完后紧接 3-2-1、换边间隔容得下换边句。
- 新增 `test/hip/hip_voice_android_fix_test.dart`（8 项）：慢加载下 3-2-1 全部按序播出；有意打断仍作废旧句；积压跳过规则；tailGrace 的两侧；ScreenAwake 引用计数启动/停止服务、iOS 不调用、无平台端不抛错。
- 改 1 项：`hip_voice_playback_test.dart` 原“a superseded volume operation cannot load over the new line”期望只播新句（正是吞句行为），改为两句按序播放、不重叠。
- 结果：`flutter analyze` 0；`flutter test` 277 pass / 1 条件 skip（main 基线 254 / 1）；`python3 -m unittest discover -s tools/tests` 19 OK；`build_action_kits.py check` 0 problem（无 jsonschema，仅结构检查）。

## 真机听音清单（给本机 Windows 安卓 agent）

前置：本分支 debug arm64 构建；覆盖安装保留数据（不清数据）；耳机（有线或蓝牙各一次更好）；开始前 `adb logcat -c`，全程 `adb logcat -v time | findstr /i "HipVoice HipTrainingService AudioFocus flutter"` 存到 `E:/AII-3D/hiplab-releases/` 下 Git 忽略目录。记录手机型号、Android 版本、ROM。

1. **服务**：进训练播放器后 `adb shell dumpsys activity services com.ugk.hiplab` 有 `TrainingSessionService` 且 `isForeground=true`；`adb shell dumpsys activity processes | findstr hiplab` 进程状态为前台服务级；退出播放器后服务消失；划掉任务后服务消失。Android 13+ 未授权通知时不弹权限、训练正常。
2. **前台基线（中文）**：选含左右侧保持动作的套路（如 D）完整练一组：每个「慢慢还原，换左边」完整说完再「三、二、一」；所有倒数完整；无句尾被切。
3. **后台**：训练开始约 30 s 后按 Home 切到其他 App（不放音乐）≥ 2 分钟：播报不卡顿、倒数完整、句尾完整；回到前台进度与语音一致。
4. **锁屏**：按电源键锁屏 ≥ 2 分钟（含一次换边和一次休息倒数）：同上。
5. **其他 App 放音乐 + 后台**：音乐在句子期间被压低、句后恢复；不中断训练。
6. **英文**：设置语音为 English，重复 2–4：「Slowly come out of it. Switch to the left side」完整，随后「three, two, one」完整。
7. **计数动作**：含计次（「一，起 / 落」）的动作在后台/锁屏下每个数字都在。
8. **自测页**：开始自测后切后台 1 分钟，语音提示与倒数不缺。
9. logcat：记录 `HipVoice slow load` 出现次数和最大值（前台/后台分开）、是否出现 `HipVoice skipped late line`、`HipTrainingService` 启停各一次、`AudioFocus` 请求是否有 FAILED。

判定：2–8 任一处吞数字或掐句尾即不通过，附 logcat 与时间点；`slow load` 若后台仍常见 >800 ms，回报给沙盒评估第二轮（预加载/多播放器池），不在本轮扩大。

## 风险与待定

- **Play Console**：新增 `FOREGROUND_SERVICE_MEDIA_PLAYBACK` 后，下次上传前需在 Play Console 填前台服务声明（媒体播放，附简短视频说明用途）。本分支未改任何商店/发布配置；是否接受前台服务方案由开哥决定（不接受可回退提交 `fd8d285`——`android/` 与 `lib/core/platform/`——并删去 `hip_voice_android_fix_test.dart` 第 1 组；队列/换边修复独立有效）。
- Kotlin 未在沙盒编译（无 Android SDK），需本机构建确认。
- 换边间隔变长（zh 慢慢还原类 +1 s、en +2 s），属 App 过渡时间，不是动作包训练剂量。
- 与 PR #22（feat/training-library）重叠：`lib/hip/voice/session_script.dart`（本分支改 `workPhases` 的换边长度和 `cues()` 的 switchSide 分支，#22 改 `_dose/_holdCues/setsOf/_repCues`，同文件不同段落，预计可自动合并；#22 新增的组间「慢慢还原」后 5 s 间隔无倒数，不受影响）。本分支未改 `hip_player_page.dart`。
