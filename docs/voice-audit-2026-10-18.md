# 语音播报审计（2026-10-18，`fix/voice-audit`）

**起因**：用户在 iPhone 上实测 PR #9（`feat/ios`）构建：很多播报前面有声音、后面突然没了；有的长词只听到一两个字就消失；播报音量不稳定。

**结论**：截断的主因在**播放链路**，不在素材；素材问题是**响度不一致和削波**。两处都已修复，素材 488 条（zh 244 + en 244）全部重新生成并通过逐条检测。

## 1. 根因

### 1.1 播放链路：上一句"刚开始就被当成播完"，0.7 秒后 iOS 会话被停用（截断主因）

`JustAudioVoiceOutput.speak()` 用 `await _voice.play()` 判断一句话结束，播完 700 ms 后释放 duck；iOS 上释放 duck 要先停用音频会话（`setActive(false)`，通知其他 App 恢复音量）再重新激活。

但 just_audio 的 `play()`：**播放器已处于 playing 状态时立即返回**；而一条 clip 播完后播放器停在 `completed` 状态、`playing` 仍为 `true`（不会自动变 false）。所以：

1. 训练里第一句正常；
2. 从第二句起，`setAudioSources()` + `play()` 立刻返回 → 代码以为"这句播完了" → 700 ms 后释放 duck → **在这句还在播的时候停用了 iOS 音频会话** → 声音中途消失；
3. 越长的句子越明显（预告、动作要领、结束语）；短句往往在 700 ms 内说完，所以"有的能听全，有的只听到一两个字"。

另外三处小风险一并修掉：释放 duck 的一串异步会话调用可以和下一句的激活交错；释放时没检查提示音是否还在响；队列按 manifest 时长从"请求时刻"计时，而真正出声要晚一点（会话激活 + 加载），下一句可能剪掉上一句末尾几十到几百毫秒。

Android 不停用会话播放（`setActive(false)` 只是放弃焦点），所以这个问题基本只在 iPhone 上出现，和实测一致。

### 1.2 素材：响度忽高忽低、部分削波（音量不稳定）

v3 后处理（`build_voice.py` 旧 `_process`）：

* 长句用双遍 `loudnorm … linear=true`，但 **linear 模式在所需增益会超出真峰值限制时会自动退回动态模式**（edge-tts 的 Jenny 峰值因数很高，很多英文句子就是这样），一句之内音量起伏；
* 三个字以内的短句（数字、"开始"、"休息"）走 `dynaudnorm=f=75`——逐 75 ms 帧的自动增益；
* 结果：整体 **-21.1…-12.7 LUFS（跨 8 LU）**，**64 条真峰值超过 -1 dBTP，22 条超过 0 dBTP**（AAC 解码后削波），41 条尾巴只剩 15–39 ms，21 条容器标称时长比实际解码长 50–92 ms（manifest 也用了这个偏长值）。

**排除的嫌疑**：首尾静音裁剪（`silenceremove` start_periods=1 + areverse）**没有剪掉内容**——每条都与同文本、同音色、同语速的 edge-tts 原始输出比对了语音跨度，差值 -30…+40 ms（测量粒度 10 ms），没有句中长静音，没有后半段骤降（3 条英文后半段低 9–10 dB 是原始录音本身如此，如结尾 "s"）。

## 2. 改动

| 提交 | 内容 |
|---|---|
| `tools(voice)` 检测工具 | `tools/voice/audit_voice.py`：逐条解码检测（见 §3），`--raw` 对照 edge-tts 原始输出，`--shard/--merge` 分片，失败退出码 1 |
| `fix(voice)` 后处理 | 只裁首尾（numpy 找第一个/最后一个 >-50 dBFS 的 10 ms 窗，保留 40 ms 头、80 ms 尾，5 ms/20 ms 淡入淡出落在静音里），**从不剪句中**；每条一个固定增益到 -16 LUFS（把 clip 循环到 ≥3 s 再测，单字也有可靠读数）；12 kHz 低通 + `alimiter`（-2.5 dBFS、5 ms 前瞻、`latency=1` 不丢尾、`level=0` 不自动增益）；AAC 64k `-cutoff 12000`（原生编码器在 64k 下对 12 kHz 以上量化很粗，咝音峰值会再冒 3 dB）；编码后复测，偏差 >0.3 LU 或峰值 >-1.2 dBTP 就修正增益/限幅重做（取最好的一次）；manifest 时长改用实际解码长度；edge-tts 原始输出缓存到 `.raw-cache/`（重做后处理不需联网），相同文本只处理一次 |
| `assets(voice)` | v4.1 重新生成 zh/en 全部 488 条 + manifest（提示音未变） |
| `fix(voice)` 播放 | 新增 `lib/hip/voice/voice_line_controller.dart`（`VoiceLineController` + `VoicePlatform` 接口），`JustAudioVoiceOutput` 改为它的平台实现：一句话**播到 `completed` 才算结束**（监听 playerState，播完后 `pause()` 退出 playing 状态）；释放 duck/停用会话前确认**语音和提示音都不在响**且没有更新的句子，否则顺延；所有会话操作**串行**；新句若上一句还在出声且不是队列有意切断（`stopSpeech`），等它说完（最多 1.2 s），有意切断（倒数、口令）则立即接上；中断/拔耳机/结束会话时作废旧句，不会再触发释放 |
| `test(voice)` | `test/hip/hip_voice_playback_test.dart`（11 项，见 §4）；`test/hip/voice_timeline_export_test.dart` 导出真实课程时间线供 `build_voice.py demo` |

未改：`VoiceQueue` 的优先级规则、课程时间线、iOS `AVAudioSession` 类别（playback + 说话时 duckOthers/interruptSpokenAudioAndMixWithOthers，句间 mixWithOthers）、Android 音频属性、pubspec 版本号。

## 3. 逐条检测方法（`audit_voice.py`）

每条 clip 解码为 44.1 kHz float PCM：

| 检查 | 失败条件 |
|---|---|
| 格式 / 解码完整 | 非 AAC 单声道 44.1k；容器时长、流时长、实际解码样本三者差 >50 ms；manifest 时长与解码差 >50 ms |
| 对照源截断（`--raw`） | 语音跨度（首个到最后一个 >-50 dBFS 的 10 ms 窗）比 edge-tts 原始输出短 >90 ms |
| 时长 vs 文案 | 每音节秒数 < 同语种中位数 × 0.62（zh 按汉字+数字读法，en 按元音组粗估） |
| 首尾 | 最后/最初 10 ms 与语音电平差 <18 dB（句中被硬切）；尾巴 <40 ms 或 >200 ms；开头静音 >120 ms |
| 句中静音 | ≥0.45 s 的静音比源里最长停顿还长 0.25 s |
| 响度曲线 | 200 ms 窗，后半段中位数比前半段低的幅度比源多 >3 dB（无源时 >9 dB） |
| 整体响度 | 循环到 ≥3 s 测积分响度，偏离 -16 LUFS >1 LU；真峰值 > -1 dBTP |

完整逐条数据：[`voice-audit-2026-10-18/before.json`](voice-audit-2026-10-18/before.json)、[`after.json`](voice-audit-2026-10-18/after.json)（每条含时长、语音跨度、源跨度、头尾、LUFS、真峰值、前后半段差、句中静音）。

## 4. 前后对比

| 指标 | 修复前 zh | 修复前 en | 修复后 zh | 修复后 en |
|---|---|---|---|---|
| 不通过条数 | 62 / 244 | 202 / 244 | **0** | **0** |
| 响度范围（LUFS，循环测） | -20.1 … -12.7 | -21.1 … -15.5 | -16.2 … -15.9 | -16.5 … -15.9 |
| 响度标准差 | 0.8 LU | 1.2 LU | 0.08 LU | 0.08 LU |
| 真峰值最大 | +2.3 dBTP | +2.3 dBTP | -1.8 dBTP | -1.2 dBTP |
| 真峰值 > -1 / > 0 dBTP | 9 / 2 | 55 / 20 | 0 / 0 | 0 / 0 |
| 尾巴（最后声音后的静音） | 33–76 ms | 15–73 ms | 64–103 ms | 52–103 ms |
| manifest 与实际时长最大偏差 | 92 ms | 89 ms | 0 | 0 |
| 语音跨度 − 源跨度 | -10 … +20 ms | -30 … +40 ms | 0 … +30 ms | 0 … +60 ms |

修复前失败类型（共 264 条，一条可多项）：响度偏离 197、真峰值 64、尾巴过短 41、容器/解码长度不一致 21、manifest 时长偏差 21；**截断 0、句中静音 0、后半段骤降 0**。

播放链路测试（`hip_voice_playback_test.dart`，假平台按真实时间播放 clip，任何"有声时停用会话"或"新句顶掉旧句"都记为违规）：单句播完后才释放；释放窗口内来的下一句不停用会话；释放进行中来的下一句等释放做完再激活；即使平台 `play()` 立即返回（旧 just_audio 情形）释放也会等到无声；上一句还在出声时下一句等它说完；`stopSpeech` 有意切断时立即接上；提示音在响时不释放；中断后旧句不再释放；iOS/Android 各 60 条随机口令压力测试无违规；7 套课程 × 3 个等级 × 中英文完整时间线无一句被切、无丢句。

**限额说明**：限幅器对少数英文峰值因数高的句子压了 3–5 dB 峰值（`sec.5`、`a.item.deep_squat`、`drill.h-reverse-clam`、`p.go_right`、`min.15`、`point.w-clamshell`），前后半段差比原始录音小，听感可能略"扁"，需真机复听确认。

## 5. 需要真机复听的条目

自动检测不能代替人耳和系统音频行为。请在 iPhone（主要）和 Android 上用本分支构建复听：

1. **iPhone 截断回归（最重要）**：开一套 5–6 分钟课程（如套 A）完整跟一遍，重点听第二句以后的长句——课程开头"开始训练…全程大约 N 分钟"、`p.first`/`p.next` 预告 + 动作名 + 剂量、`point.*` 动作要领、休息时的 `tip.*`、结束语 `p.finish`；自测里 `a.intro`、`a.cue.*`（最长 5–6 s）。预期每句都完整、句尾不被吞。
2. **后台放着音乐**（Apple Music/Spotify）跟练：每句说话时音乐被压低、句间 0.7 s 后恢复；句子不再因为恢复音乐而被切。
3. **倒数**：`准备`→`三、二、一`（带滴答）→`开始`，节拍对、不吞字；每侧 8 次计数 1…8。
4. **音量一致性**：数字（`n.*`）、短口令（开始/休息/换左边/很好）与长句之间音量接近，无忽大忽小；英文语音同样检查。
5. **重点单条**：响度变化最大的 en `drill.h-butterfly-active`、`drill.h-quad-cars`、`point.o-stand-crossreach`、`min.17`（各提高 4–5 LU）、zh `drill.n-wide-fold`（+4 LU）、zh `p.resume`（-3.3 LU）；限幅较重的 en `sec.5`、`a.item.deep_squat`、`drill.h-reverse-clam`、`p.go_right` 是否发扁/失真。
6. **中断**：来电/Siri/拔耳机时暂停，恢复后第一句完整。
7. **Android**：同样跑一遍 1、3、4（Android 原本不受会话停用影响，主要确认新素材和"等上一句说完"的逻辑没有让口令明显迟到）。

## 6. 复现

```bash
pip install edge-tts numpy                      # 需能直连 speech.platform.bing.com
python3 tools/voice/build_voice.py build         # 原始输出缓存在 tools/voice/.raw-cache/
python3 tools/voice/audit_voice.py --raw --json /tmp/a.json --md /tmp/a.md   # 慢机可 --shard 1/4 … 再 --merge
VOICE_TIMELINE_OUT=/tmp/tl.json VOICE_LANG=zh VOICE_ROUTINE=A flutter test --no-pub test/hip/voice_timeline_export_test.dart
python3 tools/voice/build_voice.py demo --lang zh --timeline /tmp/tl.json --seconds 60 --out /tmp/demo-zh.mp3
```

## 附录：修复前不通过条目（264 条）

488 clips, **264 failing**

| lang | key | text | ms | speech | src | tail | LUFS | TP | problems |
|---|---|---|---|---|---|---|---|---|---|
| en | `a.choose` | Okay. Which picture looks li | 4203 | 4140 | 4130 | 53 | -16.1 | -0.4 | true peak -0.4 dBTP > -1.0 |
| en | `a.cue.butterfly` | Soles together, sit tall and | 3111 | 3060 | 3050 | 41 | -16.0 | -0.7 | container/stream/decoded length mismatch; manifest 3200 ms vs decoded 3111 ms; true peak -0.7 dBTP > -1.0 |
| en | `a.cue.ninety_ninety` | Both legs at right angles, h | 3297 | 3220 | 3220 | 67 | -16.3 | -0.3 | true peak -0.3 dBTP > -1.0 |
| en | `a.cue.supine_cross` | Lift one straight leg and cr | 5341 | 5300 | 5290 | 31 | -16.2 | -1.1 | container/stream/decoded length mismatch; manifest 5400 ms vs decoded 5341 ms; tail 31 ms < 40 |
| en | `a.done` | Check complete. Here are you | 2856 | 2790 | 2780 | 56 | -17.8 | -1.5 | LUFS -17.8 outside -16.0±1.0 |
| en | `a.hold` | Hold it and notice how it fe | 1625 | 1570 | 1570 | 55 | -17.3 | -1.3 | LUFS -17.3 outside -16.0±1.0 |
| en | `a.intro` | Hip check, six moves. Follow | 5526 | 5480 | 5470 | 46 | -16.4 | -0.7 | container/stream/decoded length mismatch; manifest 5600 ms vs decoded 5526 ms; true peak -0.7 dBTP > -1.0 |
| en | `a.item.butterfly` | Move one: Butterfly | 1440 | 1380 | 1380 | 50 | -17.8 | -1.1 | LUFS -17.8 outside -16.0±1.0 |
| en | `a.item.deep_squat` | Move six: Deep squat | 1649 | 1580 | 1570 | 59 | -18.7 | -1.3 | LUFS -18.7 outside -16.0±1.0 |
| en | `a.item.ninety_ninety` | Move two: Ninety ninety | 1672 | 1600 | 1590 | 62 | -16.9 | -0.1 | true peak -0.1 dBTP > -1.0 |
| en | `a.item.seated_fold` | Move five: Seated forward fo | 2067 | 2010 | 2000 | 47 | -18.6 | -0.6 | true peak -0.6 dBTP > -1.0; LUFS -18.6 outside -16.0±1.0 |
| en | `a.item.supine_cross` | Move four: Lying leg cross | 2020 | 1960 | 1960 | 50 | -17.3 | -1.6 | LUFS -17.3 outside -16.0±1.0 |
| en | `a.item.thomas` | Move three: Hip flexor test | 1997 | 1940 | 1930 | 47 | -18.7 | -1.6 | LUFS -18.7 outside -16.0±1.0 |
| en | `a.left_first` | Left side first | 1115 | 1050 | 1050 | 55 | -17.5 | -1.6 | LUFS -17.5 outside -16.0±1.0 |
| en | `a.switch_right` | Left side saved. Now the rig | 2972 | 2910 | 2890 | 52 | -16.3 | -0.9 | true peak -0.9 dBTP > -1.0 |
| en | `cue.control.2` | Keep the pelvis still, move  | 2043 | 1970 | 1960 | 63 | -19.0 | -1.5 | LUFS -19.0 outside -16.0±1.0 |
| en | `cue.extra_left` | One extra set on the left | 1463 | 1400 | 1390 | 53 | -17.7 | -0.6 | true peak -0.6 dBTP > -1.0; LUFS -17.7 outside -16.0±1.0 |
| en | `cue.extra_right` | One extra set on the right | 1416 | 1360 | 1350 | 46 | -17.9 | -1.6 | LUFS -17.9 outside -16.0±1.0 |
| en | `cue.flexibility.1` | Breathe out and sink a littl | 1602 | 1540 | 1530 | 52 | -17.8 | -1.4 | LUFS -17.8 outside -16.0±1.0 |
| en | `cue.half_range` | Half the range, only go wher | 2345 | 2300 | 2290 | 45 | -18.8 | 0.1 | true peak 0.1 dBTP > -1.0; LUFS -18.8 outside -16.0±1.0 |
| en | `cue.relax.2` | Shoulders loose, keep breath | 1741 | 1690 | 1680 | 41 | -17.6 | -1.0 | LUFS -17.6 outside -16.0±1.0 |
| en | `cue.strength.1` | Stay steady, keep breathing | 1695 | 1620 | 1620 | 65 | -18.8 | -1.5 | LUFS -18.8 outside -16.0±1.0 |
| en | `cue.strength.2` | Breathe out as you push | 1161 | 1090 | 1070 | 61 | -18.0 | -3.0 | LUFS -18.0 outside -16.0±1.0 |
| en | `dose.02` | 30 seconds each side | 1347 | 1290 | 1270 | 47 | -17.8 | -0.8 | true peak -0.8 dBTP > -1.0; LUFS -17.8 outside -16.0±1.0 |
| en | `dose.03` | 3 open and 3 close, each sid | 2090 | 2030 | 2020 | 50 | -17.5 | -1.4 | LUFS -17.5 outside -16.0±1.0 |
| en | `dose.04` | 25 seconds each side | 1602 | 1530 | 1530 | 62 | -18.7 | -0.9 | true peak -0.9 dBTP > -1.0; LUFS -18.7 outside -16.0±1.0 |
| en | `dose.05` | 6 reps, alternating sides | 2020 | 1960 | 1950 | 50 | -19.3 | -1.4 | LUFS -19.3 outside -16.0±1.0 |
| en | `dose.06` | 3 reps with a 5 second hold, | 2531 | 2490 | 2460 | 31 | -17.8 | 0.6 | tail 31 ms < 40; true peak 0.6 dBTP > -1.0; LUFS -17.8 outside -16.0±1.0 |
| en | `dose.07` | 6 slow breaths | 1091 | 1040 | 1040 | 41 | -19.4 | -1.6 | LUFS -19.4 outside -16.0±1.0 |
| en | `dose.08` | 8 slow drops side to side | 1556 | 1510 | 1480 | 36 | -16.6 | 0.5 | tail 36 ms < 40; true peak 0.5 dBTP > -1.0 |
| en | `dose.09` | 40 seconds each side | 1347 | 1300 | 1290 | 47 | -17.1 | -1.7 | LUFS -17.1 outside -16.0±1.0 |
| en | `dose.10` | 40 seconds each side | 1347 | 1300 | 1290 | 47 | -17.1 | -1.7 | LUFS -17.1 outside -16.0±1.0 |
| en | `dose.11` | 6 slow open and close | 1602 | 1540 | 1530 | 52 | -19.1 | -1.7 | LUFS -19.1 outside -16.0±1.0 |
| en | `dose.12` | hold for 60 seconds | 1393 | 1340 | 1320 | 53 | -18.3 | -1.6 | LUFS -18.3 outside -16.0±1.0 |
| en | `dose.14` | 3 circles each side | 1277 | 1240 | 1230 | 27 | -16.4 | -1.7 | tail 27 ms < 40 |
| en | `dose.15` | 5 reps each side | 1161 | 1090 | 1110 | 71 | -18.2 | -1.5 | LUFS -18.2 outside -16.0±1.0 |
| en | `dose.16` | 6 reps each side | 1254 | 1210 | 1190 | 34 | -18.2 | -1.2 | tail 34 ms < 40; LUFS -18.2 outside -16.0±1.0 |
| en | `dose.17` | 6 reps | 859 | 800 | 790 | 49 | -18.2 | -1.0 | LUFS -18.2 outside -16.0±1.0 |
| en | `dose.18` | 35 seconds each side | 1602 | 1520 | 1510 | 72 | -18.7 | -1.0 | LUFS -18.7 outside -16.0±1.0 |
| en | `dose.19` | 8 reps each side | 1138 | 1080 | 1070 | 48 | -15.8 | 1.9 | true peak 1.9 dBTP > -1.0 |
| en | `dose.20` | hold for 40 seconds | 1347 | 1310 | 1290 | 37 | -17.7 | -1.4 | tail 37 ms < 40; LUFS -17.7 outside -16.0±1.0 |
| en | `dose.22` | 3 open and 3 close, each sid | 2090 | 2030 | 2020 | 50 | -17.5 | -1.4 | LUFS -17.5 outside -16.0±1.0 |
| en | `dose.23` | 10 reps each side | 1138 | 1080 | 1060 | 48 | -17.0 | -0.3 | true peak -0.3 dBTP > -1.0 |
| en | `dose.24` | 3 holds of 10 seconds | 1440 | 1380 | 1360 | 50 | -16.9 | 0.4 | true peak 0.4 dBTP > -1.0 |
| en | `dose.25` | 8 reps | 697 | 640 | 630 | 47 | -16.1 | 1.3 | true peak 1.3 dBTP > -1.0 |
| en | `dose.26` | hold for 60 seconds | 1393 | 1340 | 1320 | 53 | -18.3 | -1.6 | LUFS -18.3 outside -16.0±1.0 |
| en | `dose.27` | hold for 75 seconds | 1649 | 1610 | 1600 | 39 | -17.9 | -1.3 | tail 39 ms < 40; LUFS -17.9 outside -16.0±1.0 |
| en | `dose.28` | 8 reps side to side | 1277 | 1220 | 1210 | 47 | -16.2 | -0.6 | true peak -0.6 dBTP > -1.0 |
| en | `dose.29` | 3 holds of 15 seconds | 1625 | 1570 | 1560 | 45 | -18.3 | -1.3 | LUFS -18.3 outside -16.0±1.0 |
| en | `dose.30` | 20 seconds each side | 1370 | 1310 | 1300 | 50 | -18.9 | -1.3 | LUFS -18.9 outside -16.0±1.0 |
| en | `dose.31` | 15 seconds each side | 1463 | 1400 | 1400 | 63 | -19.1 | -1.8 | LUFS -19.1 outside -16.0±1.0 |
| en | `dose.32` | 1 reps with a 5 second hold, | 2577 | 2520 | 2500 | 47 | -19.2 | -1.8 | LUFS -19.2 outside -16.0±1.0 |
| en | `drill.glute-max-A` | Single-leg glute bridge | 1370 | 1320 | 1310 | 40 | -17.8 | -1.5 | LUFS -17.8 outside -16.0±1.0 |
| en | `drill.h-9090-liftoff` | Ninety-ninety rear-leg lift- | 1695 | 1670 | 1650 | 15 | -18.1 | -1.5 | tail 15 ms < 40; LUFS -18.1 outside -16.0±1.0 |
| en | `drill.h-adductor-rock` | Quadruped adductor rock-back | 1533 | 1500 | 1490 | 33 | -20.3 | -1.7 | tail 33 ms < 40; LUFS -20.3 outside -16.0±1.0 |
| en | `drill.h-band-hip-ir` | Seated band hip internal rot | 1881 | 1820 | 1820 | 51 | -17.2 | -1.4 | LUFS -17.2 outside -16.0±1.0 |
| en | `drill.h-band-leg-out` | Supine band leg lower-out | 1602 | 1550 | 1550 | 42 | -18.7 | -1.8 | LUFS -18.7 outside -16.0±1.0 |
| en | `drill.h-butterfly-active` | Active supine butterfly | 1416 | 1340 | 1330 | 66 | -21.1 | -1.6 | LUFS -21.1 outside -16.0±1.0 |
| en | `drill.h-couch-stretch` | Couch stretch | 882 | 820 | 820 | 52 | -19.0 | -2.2 | LUFS -19.0 outside -16.0±1.0 |
| en | `drill.h-hip-gate` | Standing hip gate | 1115 | 1050 | 1030 | 55 | -17.8 | -1.1 | LUFS -17.8 outside -16.0±1.0 |
| en | `drill.h-knee-hug` | Supine knee hug | 998 | 940 | 930 | 48 | -18.4 | -1.6 | LUFS -18.4 outside -16.0±1.0 |
| en | `drill.h-quad-cars` | Quadruped hip circles | 1300 | 1260 | 1250 | 40 | -20.7 | -1.6 | LUFS -20.7 outside -16.0±1.0 |
| en | `drill.h-reverse-clam` | Side-lying reverse clam | 1393 | 1310 | 1310 | 73 | -18.4 | -1.4 | LUFS -18.4 outside -16.0±1.0 |
| en | `drill.h-squat` | Bodyweight squat | 975 | 930 | 920 | 45 | -18.1 | -1.5 | LUFS -18.1 outside -16.0±1.0 |
| en | `drill.h-supine-twist` | Supine bent-knee twist | 1370 | 1310 | 1300 | 50 | -17.8 | -1.0 | LUFS -17.8 outside -16.0±1.0 |
| en | `drill.h-wall-straddle` | Wall straddle | 789 | 730 | 720 | 49 | -15.9 | 0.6 | true peak 0.6 dBTP > -1.0 |
| en | `drill.n-half-split` | Half split | 720 | 670 | 660 | 50 | -19.2 | -1.2 | LUFS -19.2 outside -16.0±1.0 |
| en | `drill.n-leg-circles` | Supine leg circles | 1370 | 1310 | 1300 | 50 | -17.6 | -1.5 | LUFS -17.6 outside -16.0±1.0 |
| en | `drill.n-pelvis-circle` | Standing pelvic circles | 1463 | 1400 | 1390 | 53 | -17.9 | -1.4 | LUFS -17.9 outside -16.0±1.0 |
| en | `drill.n-prone-hip-ext` | Prone bent-knee hip lift | 1231 | 1170 | 1160 | 51 | -18.4 | -1.4 | LUFS -18.4 outside -16.0±1.0 |
| en | `drill.n-prone-ir` | Prone hip internal rotation | 1533 | 1460 | 1460 | 63 | -19.3 | -1.6 | LUFS -19.3 outside -16.0±1.0 |
| en | `drill.n-seated-squeeze` | Seated block squeeze | 1231 | 1180 | 1170 | 41 | -17.1 | -0.4 | true peak -0.4 dBTP > -1.0; LUFS -17.1 outside -16.0±1.0 |
| en | `drill.n-thomas-test` | Supine single knee hug | 1347 | 1290 | 1280 | 47 | -18.7 | -1.5 | LUFS -18.7 outside -16.0±1.0 |
| en | `drill.n-wide-fold` | Wide-stance forward fold | 1393 | 1340 | 1330 | 43 | -18.6 | 0.8 | true peak 0.8 dBTP > -1.0; LUFS -18.6 outside -16.0±1.0 |
| en | `drill.o-seated-fig4` | Seated figure four | 1161 | 1100 | 1100 | 51 | -18.7 | -1.7 | LUFS -18.7 outside -16.0±1.0 |
| en | `drill.o-seated-ham` | Seated hamstring reach | 1254 | 1200 | 1190 | 44 | -17.5 | -1.6 | LUFS -17.5 outside -16.0±1.0 |
| en | `drill.o-stand-crossreach` | Standing cross-reach | 1161 | 1110 | 1110 | 41 | -18.0 | -1.5 | LUFS -18.0 outside -16.0±1.0 |
| en | `drill.o-stand-lunge` | Standing lunge hip flexor st | 1881 | 1820 | 1820 | 51 | -19.4 | -1.5 | LUFS -19.4 outside -16.0±1.0 |
| en | `drill.s-9090` | Ninety-ninety hip switch | 1324 | 1250 | 1250 | 64 | -17.2 | -1.3 | LUFS -17.2 outside -16.0±1.0 |
| en | `drill.s-butterfly` | Butterfly | 720 | 650 | 640 | 60 | -17.3 | -1.4 | LUFS -17.3 outside -16.0±1.0 |
| en | `drill.s-figure4` | Supine figure four | 1254 | 1190 | 1180 | 54 | -18.4 | -1.5 | LUFS -18.4 outside -16.0±1.0 |
| en | `drill.s-frog` | Frog stretch | 859 | 800 | 820 | 59 | -19.6 | -0.6 | true peak -0.6 dBTP > -1.0; LUFS -19.6 outside -16.0±1.0 |
| en | `drill.s-kneel-hipflex` | Kneeling hip flexor stretch | 1533 | 1480 | 1470 | 43 | -18.1 | -1.8 | LUFS -18.1 outside -16.0±1.0 |
| en | `drill.s-lizard` | Lizard lunge | 929 | 870 | 850 | 49 | -17.5 | -1.6 | LUFS -17.5 outside -16.0±1.0 |
| en | `drill.s-pigeon` | Upright pigeon | 882 | 820 | 820 | 52 | -18.5 | -0.6 | true peak -0.6 dBTP > -1.0; LUFS -18.5 outside -16.0±1.0 |
| en | `drill.s-seated-fold` | Seated forward fold | 1207 | 1160 | 1130 | 37 | -16.3 | -1.9 | tail 37 ms < 40 |
| en | `drill.t-seated-straddle-lift-1leg` | Seated straddle single-leg l | 1765 | 1720 | 1710 | 35 | -17.0 | -1.0 | tail 35 ms < 40 |
| en | `drill.w-clamshell` | Side-lying clamshell | 1277 | 1200 | 1200 | 67 | -17.5 | -1.2 | LUFS -17.5 outside -16.0±1.0 |
| en | `drill.w-feet-on-chair-bridge` | Feet-on-chair bridge | 1091 | 1030 | 1020 | 61 | -17.1 | -1.3 | LUFS -17.1 outside -16.0±1.0 |
| en | `min.10` | 10 minutes | 789 | 730 | 720 | 49 | -17.2 | -1.6 | LUFS -17.2 outside -16.0±1.0 |
| en | `min.12` | 12 minutes | 836 | 770 | 760 | 56 | -18.5 | -1.4 | LUFS -18.5 outside -16.0±1.0 |
| en | `min.13` | 13 minutes | 952 | 900 | 880 | 52 | -16.7 | -0.2 | true peak -0.2 dBTP > -1.0 |
| en | `min.15` | 15 minutes | 929 | 880 | 880 | 49 | -19.7 | -1.6 | LUFS -19.7 outside -16.0±1.0 |
| en | `min.16` | 16 minutes | 1068 | 1010 | 1000 | 48 | -19.1 | -1.3 | LUFS -19.1 outside -16.0±1.0 |
| en | `min.17` | 17 minutes | 1091 | 1020 | 1020 | 61 | -20.3 | -1.6 | LUFS -20.3 outside -16.0±1.0 |
| en | `min.18` | 18 minutes | 929 | 870 | 870 | 49 | -17.3 | -1.1 | LUFS -17.3 outside -16.0±1.0 |
| en | `min.19` | 19 minutes | 975 | 910 | 900 | 55 | -17.2 | -0.5 | true peak -0.5 dBTP > -1.0; LUFS -17.2 outside -16.0±1.0 |
| en | `min.20` | 20 minutes | 859 | 810 | 800 | 39 | -19.3 | -0.8 | tail 39 ms < 40; true peak -0.8 dBTP > -1.0; LUFS -19.3 outside -16.0±1.0 |
| en | `min.21` | 21 minutes | 1091 | 1030 | 1020 | 51 | -18.1 | -0.9 | true peak -0.9 dBTP > -1.0; LUFS -18.1 outside -16.0±1.0 |
| en | `min.22` | 22 minutes | 1045 | 1000 | 990 | 35 | -18.4 | 1.8 | tail 35 ms < 40; true peak 1.8 dBTP > -1.0; LUFS -18.4 outside -16.0±1.0 |
| en | `min.23` | 23 minutes | 1091 | 1030 | 1020 | 51 | -18.8 | 1.3 | true peak 1.3 dBTP > -1.0; LUFS -18.8 outside -16.0±1.0 |
| en | `min.24` | 24 minutes | 1068 | 1020 | 1010 | 38 | -18.9 | -0.9 | tail 38 ms < 40; true peak -0.9 dBTP > -1.0; LUFS -18.9 outside -16.0±1.0 |
| en | `min.25` | 25 minutes | 1138 | 1080 | 1070 | 48 | -17.8 | 0.4 | true peak 0.4 dBTP > -1.0; LUFS -17.8 outside -16.0±1.0 |
| en | `min.26` | 26 minutes | 1184 | 1120 | 1110 | 54 | -19.5 | -0.2 | true peak -0.2 dBTP > -1.0; LUFS -19.5 outside -16.0±1.0 |
| en | `min.27` | 27 minutes | 1161 | 1110 | 1110 | 41 | -18.3 | -1.4 | LUFS -18.3 outside -16.0±1.0 |
| en | `min.28` | 28 minutes | 1045 | 990 | 980 | 45 | -18.5 | -1.5 | LUFS -18.5 outside -16.0±1.0 |
| en | `min.29` | 29 minutes | 1091 | 1030 | 1020 | 51 | -18.2 | -1.0 | LUFS -18.2 outside -16.0±1.0 |
| en | `min.30` | 30 minutes | 813 | 770 | 750 | 43 | -16.8 | -0.7 | true peak -0.7 dBTP > -1.0 |
| en | `min.5` | 5 minutes | 813 | 770 | 780 | 43 | -19.1 | -2.2 | LUFS -19.1 outside -16.0±1.0 |
| en | `min.6` | 6 minutes | 929 | 870 | 860 | 49 | -19.1 | -1.7 | LUFS -19.1 outside -16.0±1.0 |
| en | `min.7` | 7 minutes | 929 | 860 | 860 | 59 | -19.8 | -1.4 | LUFS -19.8 outside -16.0±1.0 |
| en | `min.8` | 8 minutes | 743 | 690 | 680 | 43 | -17.5 | -1.7 | LUFS -17.5 outside -16.0±1.0 |
| en | `min.9` | 9 minutes | 836 | 770 | 760 | 56 | -15.7 | 0.7 | true peak 0.7 dBTP > -1.0 |
| en | `n.0` | zero | 557 | 510 | 500 | 37 | -15.5 | -2.5 | tail 37 ms < 40 |
| en | `n.1` | one | 441 | 370 | 350 | 61 | -17.5 | -4.1 | LUFS -17.5 outside -16.0±1.0 |
| en | `n.10` | ten | 441 | 380 | 370 | 51 | -19.2 | -4.4 | LUFS -19.2 outside -16.0±1.0 |
| en | `n.2` | two | 441 | 370 | 360 | 61 | -16.3 | -0.6 | true peak -0.6 dBTP > -1.0 |
| en | `n.5` | five | 488 | 470 | 460 | 18 | -18.7 | -3.3 | tail 18 ms < 40; LUFS -18.7 outside -16.0±1.0 |
| en | `n.6` | six | 557 | 510 | 490 | 37 | -17.2 | -2.7 | tail 37 ms < 40; LUFS -17.2 outside -16.0±1.0 |
| en | `n.7` | seven | 557 | 500 | 490 | 47 | -19.2 | -2.8 | LUFS -19.2 outside -16.0±1.0 |
| en | `n.8` | eight | 418 | 370 | 350 | 38 | -17.7 | -2.5 | tail 38 ms < 40; LUFS -17.7 outside -16.0±1.0 |
| en | `n.9` | nine | 488 | 440 | 430 | 38 | -16.3 | -4.0 | tail 38 ms < 40 |
| en | `p.each_side` | each side | 720 | 680 | 670 | 30 | -16.7 | -3.1 | tail 30 ms < 40 |
| en | `p.finish` | Great job, today's session i | 4644 | 4580 | 4580 | 54 | -15.8 | -0.6 | container/stream/decoded length mismatch; manifest 4700 ms vs decoded 4644 ms; true peak -0.6 dBTP > -1.0 |
| en | `p.go_right` | Right side first. Go | 2392 | 2320 | 2320 | 62 | -17.5 | -1.4 | LUFS -17.5 outside -16.0±1.0 |
| en | `p.half` | Halfway there. Hold it | 2206 | 2160 | 2150 | 46 | -18.2 | -1.9 | LUFS -18.2 outside -16.0±1.0 |
| en | `p.last10` | 10 seconds left | 1091 | 1040 | 1030 | 41 | -18.7 | -1.4 | LUFS -18.7 outside -16.0±1.0 |
| en | `p.next` | Next up | 673 | 620 | 600 | 43 | -16.7 | -0.1 | true peak -0.1 dBTP > -1.0 |
| en | `p.nice` | Nice work | 743 | 710 | 680 | 23 | -16.2 | 1.4 | tail 23 ms < 40; true peak 1.4 dBTP > -1.0 |
| en | `p.paused` | Paused | 534 | 470 | 450 | 54 | -16.4 | 0.7 | true peak 0.7 dBTP > -1.0 |
| en | `p.ready` | Get ready | 604 | 530 | 520 | 64 | -15.9 | -0.2 | true peak -0.2 dBTP > -1.0 |
| en | `p.resume` | Let's continue | 929 | 870 | 860 | 49 | -17.8 | -1.7 | LUFS -17.8 outside -16.0±1.0 |
| en | `p.skip` | Skipped | 488 | 440 | 430 | 38 | -17.5 | -1.7 | tail 38 ms < 40; LUFS -17.5 outside -16.0±1.0 |
| en | `p.stop` | Stop here. Numbness or a sho | 4412 | 4350 | 4350 | 52 | -16.1 | -1.3 | container/stream/decoded length mismatch; manifest 4500 ms vs decoded 4412 ms |
| en | `p.switch_left` | Switch to the left side | 1277 | 1230 | 1230 | 37 | -18.8 | -1.7 | tail 37 ms < 40; LUFS -18.8 outside -16.0±1.0 |
| en | `p.switch_right` | Switch to the right side | 1254 | 1200 | 1200 | 44 | -18.6 | -1.6 | LUFS -18.6 outside -16.0±1.0 |
| en | `p.welcome` | Let's begin | 836 | 770 | 770 | 56 | -18.2 | -1.0 | LUFS -18.2 outside -16.0±1.0 |
| en | `point.glute-max-A` | One leg up, drive your hips  | 2392 | 2330 | 2330 | 52 | -18.9 | -1.6 | LUFS -18.9 outside -16.0±1.0 |
| en | `point.h-9090-liftoff` | Sit tall, lift the back knee | 3437 | 3370 | 3370 | 57 | -16.2 | -1.2 | container/stream/decoded length mismatch; manifest 3500 ms vs decoded 3437 ms |
| en | `point.h-adductor-rock` | One leg out to the side, sit | 2694 | 2620 | 2620 | 64 | -18.5 | -0.9 | true peak -0.9 dBTP > -1.0; LUFS -18.5 outside -16.0±1.0 |
| en | `point.h-band-leg-out` | Keep the leg straight and lo | 2229 | 2200 | 2160 | 29 | -16.2 | -1.6 | tail 29 ms < 40 |
| en | `point.h-butterfly-active` | Soles together, open the kne | 2972 | 2940 | 2930 | 22 | -18.8 | -1.3 | tail 22 ms < 40; LUFS -18.8 outside -16.0±1.0 |
| en | `point.h-couch-stretch` | Back foot up, squeeze your g | 2670 | 2610 | 2600 | 50 | -19.4 | 1.0 | true peak 1.0 dBTP > -1.0; LUFS -19.4 outside -16.0±1.0 |
| en | `point.h-hip-gate` | Hold the chair, lift the kne | 2438 | 2390 | 2390 | 48 | -18.5 | -1.3 | LUFS -18.5 outside -16.0±1.0 |
| en | `point.h-knee-hug` | Hug your knees and breathe s | 1625 | 1560 | 1560 | 55 | -19.1 | -1.0 | LUFS -19.1 outside -16.0±1.0 |
| en | `point.h-quad-cars` | On all fours, draw a big cir | 3715 | 3640 | 3630 | 65 | -16.3 | -0.7 | true peak -0.7 dBTP > -1.0 |
| en | `point.h-reverse-clam` | Knees together, lift the shi | 2159 | 2100 | 2100 | 49 | -18.6 | -1.9 | LUFS -18.6 outside -16.0±1.0 |
| en | `point.h-squat` | Heels down, knees track over | 2159 | 2120 | 2110 | 39 | -19.0 | -1.0 | tail 39 ms < 40; LUFS -19.0 outside -16.0±1.0 |
| en | `point.h-supine-twist` | Drop both knees to one side, | 2717 | 2660 | 2650 | 47 | -20.1 | -1.5 | LUFS -20.1 outside -16.0±1.0 |
| en | `point.h-wall-straddle` | Legs up the wall, let them f | 2740 | 2690 | 2680 | 40 | -18.8 | -1.6 | LUFS -18.8 outside -16.0±1.0 |
| en | `point.n-half-split` | Front leg straight, fold fro | 3111 | 3060 | 3050 | 51 | -16.2 | 1.9 | true peak 1.9 dBTP > -1.0 |
| en | `point.n-leg-circles` | Leg straight, draw slow circ | 2856 | 2780 | 2770 | 66 | -19.0 | -0.1 | true peak -0.1 dBTP > -1.0; LUFS -19.0 outside -16.0±1.0 |
| en | `point.n-pelvis-circle` | Feet still, draw slow circle | 2601 | 2550 | 2560 | 51 | -18.8 | -1.5 | LUFS -18.8 outside -16.0±1.0 |
| en | `point.n-prone-hip-ext` | Lying face down, knee bent,  | 2926 | 2860 | 2860 | 56 | -17.3 | -1.4 | LUFS -17.3 outside -16.0±1.0 |
| en | `point.n-prone-ir` | Lying face down, knees bent, | 3228 | 3160 | 3140 | 58 | -16.2 | -1.2 | container/stream/decoded length mismatch; manifest 3300 ms vs decoded 3228 ms |
| en | `point.n-seated-ir-drop` | Hands behind you, drop one k | 2090 | 2020 | 2010 | 70 | -18.8 | -1.9 | LUFS -18.8 outside -16.0±1.0 |
| en | `point.n-seated-knee-lift` | Sit tall, lift the knee and  | 2183 | 2130 | 2120 | 43 | -18.8 | -1.6 | LUFS -18.8 outside -16.0±1.0 |
| en | `point.n-seated-squeeze` | Squeeze the block between yo | 1765 | 1700 | 1690 | 55 | -17.1 | -1.4 | LUFS -17.1 outside -16.0±1.0 |
| en | `point.n-slider-lateral` | Slide one foot out to the si | 2392 | 2350 | 2350 | 32 | -18.2 | -1.7 | tail 32 ms < 40; LUFS -18.2 outside -16.0±1.0 |
| en | `point.n-squat-shift` | Stay low and shift your weig | 2159 | 2120 | 2090 | 29 | -17.7 | -1.3 | tail 29 ms < 40; LUFS -17.7 outside -16.0±1.0 |
| en | `point.n-straddle-fold` | Sit tall in a straddle and l | 2670 | 2600 | 2600 | 60 | -19.7 | -0.9 | true peak -0.9 dBTP > -1.0; LUFS -19.7 outside -16.0±1.0 |
| en | `point.n-thomas-test` | Hug one knee, let the other  | 2531 | 2470 | 2460 | 61 | -18.6 | -1.3 | LUFS -18.6 outside -16.0±1.0 |
| en | `point.n-wide-fold` | Feet wide, hold the chair, f | 2601 | 2540 | 2550 | 61 | -17.8 | -1.5 | LUFS -17.8 outside -16.0±1.0 |
| en | `point.n-windshield` | Let both knees fall side to  | 2694 | 2640 | 2640 | 44 | -17.9 | 2.3 | true peak 2.3 dBTP > -1.0; LUFS -17.9 outside -16.0±1.0 |
| en | `point.o-seated-fig4` | Ankle on the knee, keep the  | 2810 | 2740 | 2730 | 60 | -18.1 | -1.7 | LUFS -18.1 outside -16.0±1.0 |
| en | `point.o-seated-ham` | Leg straight, toes up, lean  | 3135 | 3080 | 3050 | 45 | -16.1 | -1.4 | container/stream/decoded length mismatch; manifest 3200 ms vs decoded 3135 ms |
| en | `point.o-stand-crossreach` | Cross one leg behind and rea | 2113 | 2060 | 2050 | 43 | -20.5 | -1.6 | LUFS -20.5 outside -16.0±1.0 |
| en | `point.o-stand-lunge` | Hold the chair, squeeze the  | 2926 | 2870 | 2860 | 56 | -19.0 | -0.6 | true peak -0.6 dBTP > -1.0; LUFS -19.0 outside -16.0±1.0 |
| en | `point.s-9090` | Both legs at right angles, s | 3483 | 3420 | 3410 | 53 | -16.2 | 1.9 | true peak 1.9 dBTP > -1.0 |
| en | `point.s-butterfly` | Soles together, sit tall, le | 2717 | 2650 | 2650 | 57 | -19.1 | -1.5 | LUFS -19.1 outside -16.0±1.0 |
| en | `point.s-figure4` | Ankle over the other knee, p | 3019 | 2960 | 2940 | 49 | -16.1 | -0.7 | container/stream/decoded length mismatch; manifest 3100 ms vs decoded 3019 ms; true peak -0.7 dBTP > -1.0 |
| en | `point.s-frog` | Knees wide, toes out, sit yo | 2833 | 2770 | 2770 | 53 | -18.8 | -1.7 | LUFS -18.8 outside -16.0±1.0 |
| en | `point.s-kneel-hipflex` | Squeeze the back glute and e | 2252 | 2170 | 2180 | 72 | -19.6 | -0.2 | true peak -0.2 dBTP > -1.0; LUFS -19.6 outside -16.0±1.0 |
| en | `point.s-lizard` | Front foot outside your hand | 2206 | 2150 | 2150 | 56 | -19.9 | -1.5 | LUFS -19.9 outside -16.0±1.0 |
| en | `point.s-pigeon` | Stay upright, hands on the b | 2879 | 2810 | 2810 | 59 | -18.5 | -1.6 | LUFS -18.5 outside -16.0±1.0 |
| en | `point.t-seated-straddle-lift-1leg` | Sit tall in a straddle and l | 2763 | 2710 | 2700 | 43 | -20.1 | -1.4 | LUFS -20.1 outside -16.0±1.0 |
| en | `point.w-clamshell` | Heels together, open the kne | 2322 | 2260 | 2250 | 62 | -18.5 | -1.6 | LUFS -18.5 outside -16.0±1.0 |
| en | `point.w-feet-on-chair-bridge` | Feet on the chair, drive you | 1904 | 1850 | 1850 | 54 | -18.5 | -1.7 | LUFS -18.5 outside -16.0±1.0 |
| en | `routine.A` | Office | 557 | 510 | 490 | 37 | -17.7 | -1.7 | tail 37 ms < 40; LUFS -17.7 outside -16.0±1.0 |
| en | `routine.B` | Bedtime | 627 | 560 | 550 | 57 | -17.7 | -1.5 | LUFS -17.7 outside -16.0±1.0 |
| en | `routine.C` | Morning wake-up | 859 | 790 | 790 | 59 | -16.8 | -0.9 | true peak -0.9 dBTP > -1.0 |
| en | `routine.D` | Desk-sitting relief | 1068 | 1010 | 1000 | 48 | -18.7 | -1.5 | LUFS -18.7 outside -16.0±1.0 |
| en | `routine.E` | Pre-workout activation | 1347 | 1280 | 1280 | 57 | -17.5 | -1.5 | LUFS -17.5 outside -16.0±1.0 |
| en | `routine.F` | Breaking hip opener | 975 | 920 | 910 | 45 | -18.2 | 0.1 | true peak 0.1 dBTP > -1.0; LUFS -18.2 outside -16.0±1.0 |
| en | `routine.M` | Chair break | 697 | 650 | 640 | 37 | -16.7 | -2.3 | tail 37 ms < 40 |
| en | `sec.10` | 10 seconds | 882 | 820 | 810 | 52 | -18.0 | -1.8 | LUFS -18.0 outside -16.0±1.0 |
| en | `sec.15` | 15 seconds | 1045 | 1010 | 1000 | 35 | -19.8 | -1.4 | tail 35 ms < 40; LUFS -19.8 outside -16.0±1.0 |
| en | `sec.20` | 20 seconds | 975 | 920 | 910 | 45 | -19.1 | -1.3 | LUFS -19.1 outside -16.0±1.0 |
| en | `sec.25` | 25 seconds | 1207 | 1150 | 1130 | 47 | -18.7 | -1.6 | LUFS -18.7 outside -16.0±1.0 |
| en | `sec.27` | 27 seconds | 1277 | 1220 | 1200 | 47 | -18.6 | -1.1 | LUFS -18.6 outside -16.0±1.0 |
| en | `sec.30` | 30 seconds | 929 | 880 | 870 | 39 | -17.3 | -1.2 | tail 39 ms < 40; LUFS -17.3 outside -16.0±1.0 |
| en | `sec.35` | 35 seconds | 1161 | 1100 | 1090 | 61 | -18.8 | -1.7 | LUFS -18.8 outside -16.0±1.0 |
| en | `sec.40` | 40 seconds | 952 | 920 | 930 | 32 | -17.2 | -1.3 | tail 32 ms < 40; LUFS -17.2 outside -16.0±1.0 |
| en | `sec.45` | 45 seconds | 1161 | 1120 | 1130 | 41 | -18.4 | -1.3 | LUFS -18.4 outside -16.0±1.0 |
| en | `sec.5` | 5 seconds | 882 | 830 | 830 | 52 | -19.0 | -0.8 | true peak -0.8 dBTP > -1.0; LUFS -19.0 outside -16.0±1.0 |
| en | `sec.50` | 50 seconds | 952 | 920 | 910 | 32 | -19.5 | -1.4 | tail 32 ms < 40; LUFS -19.5 outside -16.0±1.0 |
| en | `sec.54` | 54 seconds | 1184 | 1130 | 1130 | 54 | -19.9 | -1.6 | LUFS -19.9 outside -16.0±1.0 |
| en | `sec.55` | 55 seconds | 1161 | 1120 | 1120 | 41 | -19.1 | -1.7 | LUFS -19.1 outside -16.0±1.0 |
| en | `sec.7` | 7 seconds | 1022 | 960 | 960 | 52 | -20.0 | -1.5 | LUFS -20.0 outside -16.0±1.0 |
| en | `sec.70` | 1 minute 10 | 952 | 890 | 890 | 52 | -16.5 | 1.4 | true peak 1.4 dBTP > -1.0 |
| en | `sec.75` | 1 minute 15 | 1161 | 1090 | 1090 | 61 | -17.1 | -1.7 | LUFS -17.1 outside -16.0±1.0 |
| en | `tip.02` | No towel? Hold the inner thi | 2949 | 2890 | 2890 | 49 | -18.4 | -2.0 | LUFS -18.4 outside -16.0±1.0 |
| zh | `a.choose` | 好，看看你像哪一张，选一个 | 2508 | 2450 | 2450 | 58 | -20.0 | -1.4 | LUFS -20.0 outside -16.0±1.0 |
| zh | `a.cue.butterfly` | 脚心对脚心，坐直，让膝盖自己往下落。 | 3437 | 3370 | 3360 | 57 | -16.1 | -1.6 | container/stream/decoded length mismatch; manifest 3500 ms vs decoded 3437 ms |
| zh | `a.cue.thomas` | 抱住一边膝盖，另一条腿放松伸直，把手塞到膝盖下面试试。 | 5039 | 4970 | 4960 | 59 | -16.0 | -0.7 | container/stream/decoded length mismatch; manifest 5100 ms vs decoded 5039 ms; true peak -0.7 dBTP > -1.0 |
| zh | `a.item.deep_squat` | 第六项，深蹲到底 | 1718 | 1650 | 1660 | 58 | -18.4 | -1.4 | LUFS -18.4 outside -16.0±1.0 |
| zh | `a.item.ninety_ninety` | 第二项，90 90 | 1695 | 1620 | 1620 | 65 | -17.1 | -1.7 | LUFS -17.1 outside -16.0±1.0 |
| zh | `a.item.seated_fold` | 第五项，坐姿体前屈 | 1881 | 1820 | 1810 | 51 | -18.2 | -1.5 | LUFS -18.2 outside -16.0±1.0 |
| zh | `a.item.supine_cross` | 第四项，仰卧横跨 | 1672 | 1600 | 1590 | 62 | -18.2 | -2.0 | LUFS -18.2 outside -16.0±1.0 |
| zh | `cue.flexibility.1` | 呼气，再沉一点 | 1486 | 1420 | 1410 | 66 | -17.4 | -1.6 | LUFS -17.4 outside -16.0±1.0 |
| zh | `cue.strength.2` | 用力的时候呼气 | 1277 | 1240 | 1220 | 37 | -16.2 | -2.6 | tail 37 ms < 40 |
| zh | `dose.01` | 正反各 4 圈 | 1115 | 1060 | 1050 | 45 | -16.6 | -0.0 | true peak -0.0 dBTP > -1.0 |
| zh | `dose.18` | 每侧 35 秒 | 1277 | 1230 | 1230 | 37 | -16.1 | -2.4 | tail 37 ms < 40 |
| zh | `drill.h-9090-liftoff` | 90 90 后腿主动抬起 | 2067 | 1990 | 1990 | 67 | -17.6 | -1.5 | LUFS -17.6 outside -16.0±1.0 |
| zh | `drill.h-band-leg-out` | 仰卧弹力带单腿侧落 | 1788 | 1730 | 1730 | 48 | -16.7 | -0.9 | true peak -0.9 dBTP > -1.0 |
| zh | `drill.h-butterfly-active` | 仰卧蝴蝶主动开合 | 1602 | 1530 | 1530 | 62 | -16.7 | 0.0 | true peak 0.0 dBTP > -1.0 |
| zh | `drill.hip-flexors-A` | 坐姿直腿抬腿，压缩 | 2020 | 1950 | 1960 | 60 | -17.4 | -1.5 | LUFS -17.4 outside -16.0±1.0 |
| zh | `drill.n-pelvis-circle` | 站姿骨盆画圈 | 1300 | 1220 | 1210 | 70 | -17.1 | -1.5 | LUFS -17.1 outside -16.0±1.0 |
| zh | `drill.n-straddle-fold` | 坐姿分腿体前屈 | 1556 | 1490 | 1490 | 56 | -18.1 | -1.8 | LUFS -18.1 outside -16.0±1.0 |
| zh | `drill.n-thomas-test` | 仰卧单膝抱胸，屈髋肌测试演示 | 2879 | 2800 | 2800 | 69 | -17.4 | -1.3 | LUFS -17.4 outside -16.0±1.0 |
| zh | `drill.n-wide-fold` | 站姿宽距体前屈，扶椅、扶砖 | 2810 | 2750 | 2740 | 50 | -20.1 | -1.4 | LUFS -20.1 outside -16.0±1.0 |
| zh | `drill.s-9090` | 90 90 坐姿换髋 | 1858 | 1780 | 1780 | 68 | -17.4 | -1.5 | LUFS -17.4 outside -16.0±1.0 |
| zh | `drill.s-butterfly` | 蝴蝶式 | 743 | 670 | 670 | 63 | -14.6 | -2.3 | LUFS -14.6 outside -16.0±1.0 |
| zh | `drill.s-figure4` | 仰卧 4 字拉伸 | 1254 | 1180 | 1190 | 64 | -16.4 | -0.4 | true peak -0.4 dBTP > -1.0 |
| zh | `drill.s-frog` | 青蛙式 | 743 | 690 | 690 | 43 | -14.2 | -2.3 | LUFS -14.2 outside -16.0±1.0 |
| zh | `drill.w-feet-on-chair-bridge` | 脚踩椅面臀桥 | 1347 | 1270 | 1270 | 67 | -17.8 | -1.2 | LUFS -17.8 outside -16.0±1.0 |
| zh | `min.10` | 10 分钟 | 766 | 710 | 710 | 56 | -15.4 | 1.1 | true peak 1.1 dBTP > -1.0 |
| zh | `min.2` | 2 分钟 | 720 | 660 | 640 | 50 | -15.7 | -0.6 | true peak -0.6 dBTP > -1.0 |
| zh | `min.29` | 29 分钟 | 1022 | 960 | 950 | 52 | -17.2 | -1.8 | LUFS -17.2 outside -16.0±1.0 |
| zh | `min.9` | 9 分钟 | 697 | 640 | 650 | 47 | -15.0 | 2.3 | true peak 2.3 dBTP > -1.0 |
| zh | `n.0` | 零 | 372 | 290 | 280 | 72 | -14.4 | -1.6 | LUFS -14.4 outside -16.0±1.0 |
| zh | `n.5` | 五 | 348 | 290 | 280 | 48 | -14.9 | -4.5 | LUFS -14.9 outside -16.0±1.0 |
| zh | `n.7` | 七 | 395 | 340 | 330 | 45 | -14.2 | -3.0 | LUFS -14.2 outside -16.0±1.0 |
| zh | `n.9` | 九 | 348 | 290 | 290 | 48 | -18.1 | -2.5 | LUFS -18.1 outside -16.0±1.0 |
| zh | `p.finish` | 太棒了，今天的训练完成了。记得多喝水，慢慢起身。 | 4737 | 4670 | 4660 | 67 | -16.0 | -1.0 | container/stream/decoded length mismatch; manifest 4800 ms vs decoded 4737 ms |
| zh | `p.half` | 过半了，保持住 | 1463 | 1400 | 1390 | 53 | -19.0 | -1.7 | LUFS -19.0 outside -16.0±1.0 |
| zh | `p.paused` | 已暂停 | 789 | 720 | 720 | 59 | -14.7 | -2.0 | LUFS -14.7 outside -16.0±1.0 |
| zh | `p.resume` | 继续 | 557 | 510 | 490 | 37 | -12.7 | -2.0 | tail 37 ms < 40; LUFS -12.7 outside -16.0±1.0 |
| zh | `p.stop` | 先停下来。麻、刺或往下窜的感觉不该出现在练习里。 | 5224 | 5170 | 5160 | 54 | -16.0 | -1.5 | container/stream/decoded length mismatch; manifest 5300 ms vs decoded 5224 ms |
| zh | `point.h-9090-liftoff` | 坐直，后腿膝盖慢慢抬离地面，再慢慢放下 | 3947 | 3880 | 3880 | 57 | -16.0 | -1.5 | container/stream/decoded length mismatch; manifest 4000 ms vs decoded 3947 ms |
| zh | `point.h-couch-stretch` | 后脚搭高，收紧臀部，髋往前送 | 2926 | 2870 | 2870 | 56 | -17.1 | -1.5 | LUFS -17.1 outside -16.0±1.0 |
| zh | `point.h-knee-hug` | 双手抱膝，慢慢呼吸 | 1950 | 1870 | 1880 | 70 | -16.8 | -0.1 | true peak -0.1 dBTP > -1.0 |
| zh | `point.h-quad-cars` | 四点跪姿，膝盖画一个尽量大的圈，腰不要动 | 3808 | 3760 | 3740 | 48 | -16.0 | -1.3 | container/stream/decoded length mismatch; manifest 3900 ms vs decoded 3808 ms |
| zh | `point.h-squat` | 脚跟踩稳，膝盖对准脚尖 | 2322 | 2250 | 2250 | 62 | -17.5 | -1.7 | LUFS -17.5 outside -16.0±1.0 |
| zh | `point.h-sumo-pry` | 蹲低，手肘把膝盖轻轻向外推 | 2810 | 2740 | 2730 | 60 | -17.6 | -2.1 | LUFS -17.6 outside -16.0±1.0 |
| zh | `point.h-supine-twist` | 双膝倒向一侧，肩膀贴地 | 2299 | 2220 | 2220 | 69 | -17.9 | -1.5 | LUFS -17.9 outside -16.0±1.0 |
| zh | `point.n-chair-wiper` | 坐在椅子上，小腿向外摆，膝盖向内倒 | 3297 | 3260 | 3240 | 37 | -16.1 | -1.6 | tail 37 ms < 40 |
| zh | `point.n-half-split` | 前腿伸直，从髋部往前折，手扶砖 | 3228 | 3170 | 3170 | 48 | -16.0 | -1.6 | container/stream/decoded length mismatch; manifest 3300 ms vs decoded 3228 ms |
| zh | `point.n-prone-hip-ext` | 趴着，屈膝，大腿慢慢抬离地面 | 3042 | 2970 | 2960 | 62 | -16.1 | -1.4 | container/stream/decoded length mismatch; manifest 3100 ms vs decoded 3042 ms |
| zh | `point.n-prone-ir` | 趴着，屈膝，小腿向外侧摆 | 2647 | 2590 | 2580 | 47 | -18.1 | -1.5 | LUFS -18.1 outside -16.0±1.0 |
| zh | `point.n-seated-knee-lift` | 坐直，膝盖抬起，悬停住 | 2461 | 2400 | 2400 | 51 | -17.4 | -1.3 | LUFS -17.4 outside -16.0±1.0 |
| zh | `point.n-wide-fold` | 双脚分开，扶住椅子，从髋部往前折 | 3320 | 3270 | 3260 | 40 | -16.0 | -1.7 | container/stream/decoded length mismatch; manifest 3400 ms vs decoded 3320 ms |
| zh | `point.n-windshield` | 双膝一起慢慢左右倒，肩膀贴地 | 2995 | 2920 | 2920 | 65 | -17.5 | -1.8 | LUFS -17.5 outside -16.0±1.0 |
| zh | `point.o-seated-ham` | 腿伸直，脚尖勾起，背挺直往前 | 3042 | 2980 | 2970 | 52 | -16.1 | -1.6 | container/stream/decoded length mismatch; manifest 3100 ms vs decoded 3042 ms |
| zh | `point.o-stand-lunge` | 扶住椅子，后侧臀部收紧，髋往前推 | 3413 | 3370 | 3360 | 43 | -16.0 | -1.6 | container/stream/decoded length mismatch; manifest 3500 ms vs decoded 3413 ms |
| zh | `point.s-9090` | 两条腿都成直角，坐直，再左右换 | 3111 | 3050 | 3050 | 51 | -16.1 | -1.2 | container/stream/decoded length mismatch; manifest 3200 ms vs decoded 3111 ms |
| zh | `point.s-lizard` | 前脚放在手外侧，髋往下沉 | 2531 | 2470 | 2480 | 51 | -17.3 | -2.0 | LUFS -17.3 outside -16.0±1.0 |
| zh | `point.w-feet-on-chair-bridge` | 脚踩椅面，用臀部把身体推高 | 2554 | 2490 | 2490 | 54 | -18.3 | -1.4 | LUFS -18.3 outside -16.0±1.0 |
| zh | `routine.A` | 办公室 | 720 | 650 | 650 | 60 | -14.5 | -2.2 | LUFS -14.5 outside -16.0±1.0 |
| zh | `routine.D` | 久坐解压 | 859 | 810 | 810 | 39 | -16.4 | -1.8 | tail 39 ms < 40 |
| zh | `routine.F` | Breaking 开胯 | 952 | 890 | 880 | 52 | -17.2 | -1.3 | LUFS -17.2 outside -16.0±1.0 |
| zh | `routine.M` | 久坐提醒 · 椅边 | 1509 | 1440 | 1440 | 59 | -18.8 | -1.4 | LUFS -18.8 outside -16.0±1.0 |
| zh | `sec.35` | 35 秒 | 859 | 820 | 800 | 39 | -16.4 | -3.4 | tail 39 ms < 40 |
| zh | `sec.55` | 55 秒 | 813 | 770 | 760 | 33 | -15.8 | -2.0 | tail 33 ms < 40 |


## PR #13 语音素材独立复核（Windows，2026-10-18）

固定审核版本 `d2e0286ffc0e402e0ddf0f80426536dc7192bca7`，原基线 `313b4848ff0a436b9b2c400ea1d95f97c30c308b`，集成目标 `12f143868959187047ff7f7aaeff9f469dca0039`。将脚本与资源导出到仓库外审计目录，未运行合成、未联网 TTS、未改音频。

中文 244 条、英文 244 条，共 **488 条**，文件 ID、manifest 的 lines/clips、生成器文本绑定完全一致；与集成目标现有内容生成的 ID/文案也无差异。逐条默认离线审核 **0/488 失败**，退出码 0，耗时 **11.672 秒**（本机 Python 3.14、32 个逻辑 CPU、脚本默认 32 工作线程）。AAC 单声道 44.1 kHz、解码/容器时长、首尾、语速和默认响度检查通过，manifest 与实际解码时长最大偏差 0 ms。此轮未使用 `--raw`，因此不把原始 TTS 语音跨度、源停顿或源响度曲线比对写成此次重新实测。

**实际通过门槛是 −17…−15 LUFS（−16±1 LU）和 true peak ≤−1.0 dBTP**，不是严格的 −16.5…−15.9 / ≤−1.2。EBU R128 summary 以一位小数显示：zh −16.2…−15.9 LUFS、最大 TP −1.8；en −16.5…−15.9 LUFS、最大 TP −1.2；488 条一位小数及常规时长数据与 PR 内 after.json 完全吻合。

对边界 19 项使用同一 EBU meter 的 metadata 输出复核，积分响度全局极值为 **−16.533 LUFS**（en `a.cue.ninety_ninety`）和 **−15.864 LUFS**（zh `n.4`）。三个英文 true peak 的线性 metadata 换算约值如下，均会四舍五入显示为 −1.2：

| clip | true peak 约值（dBTP） | 线性 metadata 三位小数舍入对应区间 |
|---|---:|---:|
| `point.hip-flexors-A` | −1.160 | −1.165…−1.155 |
| `point.n-seated-ir-drop` | −1.180 | −1.185…−1.175 |
| `point.o-stand-crossreach` | −1.170 | −1.175…−1.165 |

这些数值符合现存审核门槛，但不能作为“所有素材严格 ≤−1.2 dBTP”的证据。保留现有 488 条音频，不因显示舍入边界重新编码。生成器虽然尝试向 −16±0.3 LU / ≤−1.2 dBTP 收敛，但最多六次后选择 best，并未强制最终符合更窄门槛。

Windows 兼容性：原工具的 Path 文本读写未显式指定编码；本次首次 488 条复核通过 `-X utf8` 和 `PYTHONUTF8=1` 绕过了该缺陷，不能据此声称原工具在 GBK 环境直接可用。随后仅给 `audit_voice.py` 和 `build_voice.py` 的八处 Path 文本读写补 `encoding='utf-8'`，未改处理算法。两个文件 compile/AST、diff 检查通过；禁用 UTF-8 mode、系统编码 cp936 时，488 条报告离线 merge 和包含中文/非 GBK 字符的 JSON/Markdown 往返检查通过，未执行 build 命令。

证据目录：`E:/AII-3D/hiplab-releases/round2-20261018/audio-audit/`。主要文件：`run-record.json`、`audit-no-raw.json`、`audit-no-raw.log`、`boundary-ebu-precision.json`、`boundary-meter-logs/`、`utf8-fixed-merged.json`、`utf8-fixture.log`。真机听感、iOS 截断和系统 ducking 仍需按对应设备实测，自动素材检查不替代这些结果。
