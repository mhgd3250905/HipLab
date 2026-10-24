# App Review Notes 草稿

仅交付开哥复制，未写入 App Store Connect，未提交审核。

## 中文

本版本将原 Hip Interlude 更新为 HipLab 开髋训练，沿用原有 Bundle ID `com.ugk.hipinterlude`。应用无需登录，无广告、订阅或应用内购买；动作视频和语音内置，核心训练可离线完成。当前界面以中文为主，语音可选中文/英语。本版隐藏 AI 入口且未配置在线 AI。

后台音频用途：用户主动开始训练或语音自测后，播放动作预告、倒数、换边和要点口令，使用户戴耳机、锁屏或切换应用时仍可跟练。音频会话只属于进行中的引导练习；完成或退出后停止播放并释放。关闭人声与提示音后不启用后台音频。应用不录音、不使用后台定位、不收集健康传感器数据。设置页的无会话试听在本 iOS 基础版中隐藏。

复现：完成首次安全提示并选择练习身份 → 今日训练 → 开始训练 → 保持人声口令开启 → 锁屏观察语音与计时 → 解锁后结束训练。也可从“练习”查看动作、套路和自测，从“进度”查看本地记录及隐私政策。久坐提醒仅保存安排，尚不投递通知。

训练与自测供一般健身参考，不是医疗诊断或治疗，不是自动动作识别或测量。如有疼痛、麻木或其他不适，应停止练习并咨询专业人士。

## English

This version updates the former Hip Interlude app to HipLab, keeping the existing bundle identifier com.ugk.hipinterlude. No login is required. There are no ads, subscriptions or in-app purchases. Exercise videos and audio are bundled, and essential training works offline. The interface is primarily in Chinese, with Chinese and English spoken cues. Online AI is disabled and its entry points are hidden in this iOS release.

Background audio is used for user-started guided exercise and spoken self-check sessions: exercise previews, countdowns, side changes and technique cues remain audible through headphones when the screen is locked or the user switches apps. Playback and the audio session are released when the session completes or is exited. Background audio is not started when both voice and chimes are disabled. The app does not record audio or use background location or health sensors. The settings-only preview is hidden in this iOS base release.

To test: complete the initial safety prompts and select a practice profile, open the Today tab, start training with voice enabled, and lock the screen. After unlocking, finish or exit the session. The Practice tab contains exercises, routines and self-checks. The Progress tab shows local records and the bundled privacy policy. Sitting reminder settings currently store a schedule without delivering notifications.

The app provides general fitness guidance, not medical diagnosis or treatment, automated movement recognition or measurement.

## 提交前核对

本草稿描述预期行为；必须结合精确候选的真机耳机/锁屏验收记录复核，不能把待验行为写成已验证。后台能力的用途依据：[App Review Guidelines 2.5.4](https://developer.apple.com/app-store/review/guidelines/#software-requirements)。
