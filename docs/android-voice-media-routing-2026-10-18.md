# Android 静音模式下语音无声修复（2026-10-18）

用户反馈 0.3.4+9 的设置“试听”也无声。手机媒体音量 20/30、未静音、扬声器输出，App 人声/提示音开启、音量100%。实际点“试听”后，原生 AudioTrack 已 started，但属性为 `USAGE_ASSISTANCE_SONIFICATION`，状态 `mutedState:streamVolume portVolume`；铃声/系统提示音通道静音。

## 修复与回归

`JustAudioVoiceOutput._config` 将 Android usage 改为 `media`，让训练、自测和试听口令及提示音跟随媒体通道；不改手机的静音/勿扰或系统音量设置。speech content、transientMayDuck 焦点、iOS playback/mix/duck 策略和完成/取消生命周期保留。Android 官方对[用途属性的定义](https://developer.android.com/reference/android/media/AudioAttributes)区分了媒体和系统界面提示音；本次静音原因与恢复以手机原生轨道采样为准。

新增两项回归覆盖首次 begin，以及 duck/reactivate/end 全程使用媒体通道并保留其他平台策略：旧实现2项失败，修复后适配层8项全过。运行提交 `b3bd499a6eba1b2c4c72dc6625b6257d9288a5f7`，版本 **0.3.5+10**；全仓 analyze 0，单并发 **158 pass / 1 条件 skip**（未设置 VOICE_TIMELINE_OUT），debug arm64 构建通过。没有改依赖、pubspec.lock、素材或原生发布配置。

## 真机和用户确认

同一台 2602BRT18C 保留数据从 0.3.4+9 覆盖更新至 0.3.5+10，设备回读 versionCode10 / versionName0.3.5。安装前重新备份当前数据，1355字节偏好在安装、启动及试听后均逐字节一致，SHA `89ecef9bbd967029c933104f8dde625e4909ad2cb809c0da537d3bbf9092e512`，没有回写旧备份。

原生试听6次采样中3次捕获活跃轨道，均 `USAGE_MEDIA / CONTENT_TYPE_SPEECH / mutedState:none`。铃声通道前后仍 muted=true、音量0；媒体通道采样由20变为9且未静音，代理未执行系统音量写入，不将此记为音量数值完全不变。用户随后明确确认 **“已经能完整听到了”**，对应“准备、三、二、一、开始”。此结果只覆盖本次试听；完整课程、5–6秒自测长句、中英语音、背景音乐 ducking、锁屏/中断及iPhone仍按原清单待验。

## APK 与证据

- 路径：`E:\AII-3D\hiplab-releases\android-audio-fix-20261018\validation\hiplab-0.3.5+10-debug-arm64.apk`
- 字节数：150,885,612；SHA-256 `9aec5a354e2a521ea791822cb64b403c293d901c41849efe137645b562e51a33`。
- 既有 debug 证书、包名 com.ugk.hiplab、92新素材、22自有文件、488语音和共享播放器核验通过。
- 本机证据：`E:\AII-3D\hiplab-releases\android-audio-fix-20261018`；修复前原生证据另在 `E:/AII-3D/hiplab-releases/audio-diagnosis-20261018-172313/`。数据备份、日志和截图未入Git。
- 未上传商店或TestFlight。
