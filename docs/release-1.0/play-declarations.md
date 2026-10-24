# HipLab 1.0 Play 声明填写草稿

2026-10-24；`com.ugk.hiplab`，`1.0.0+20`，SDK 固定 `d193a703e3a8bef6d41e7705a55ae250e23e6a69`。仅准备文案，开哥在 Play 后台填写。本轮未读取、修改或提交 Console。

## 前台服务声明：必须提交的内容

选择类型：`mediaPlayback` / Media playback，权限 `FOREGROUND_SERVICE_MEDIA_PLAYBACK`，用途选用户主动开始的音频播放。不要因为产品属于健身类就选 `health`；本包没有通过健康或身体传感器权限持续采样。

实际服务：`com.ugk.trainer.TrainingSessionService`，`android:exported="false"`，`android:foregroundServiceType="mediaPlayback"`，`android:stopWithTask="true"`。固定 SDK 的 Manifest 提供上述声明及 `FOREGROUND_SERVICE`、`FOREGROUND_SERVICE_MEDIA_PLAYBACK`、`WAKE_LOCK`；最终合并 Manifest 由主交付报告核验，不能仅凭源文件判定构建产物。

**功能说明（中文可复制）：**

HipLab 在用户明确点击开始跟练或带语音自测后，播放随包提供的指导语音，包括动作预告、倒数、换边及要点提示。用户练习时可能锁屏或切到其他应用，前台媒体播放服务用于支持这段由用户发起的语音练习及相应计时，并展示持续的训练通知。它不在打开应用时自动开始，也不用于广告、上传、位置追踪或传感器采集。练习正常结束、用户结束或离开会话时释放服务和唤醒锁并移除训练通知；从最近任务移除应用也会停止服务。后台与锁屏设备实测结果另附，不以声明文案代替验收。

**Functionality (English, ready to paste):**

HipLab plays bundled spoken exercise guidance after the user explicitly starts guided training or an audio-guided self-check. Cues include exercise previews, countdowns, side changes and technique prompts. The media-playback foreground service supports this user-started guided audio while the user practices with the screen locked or another app open. An ongoing training notification makes the active session visible. It does not start merely because the app opens and is not used for advertising, uploads, location tracking or sensor collection. Completing or ending the session releases the service and wake lock and removes the training notification. Removing the app task also stops the service. Device-specific background behavior is verified separately.

**若系统延迟启动，对用户的影响 / If deferred:**

用户已经开始跟练并按动作口令执行；延迟启动会使动作预告和第一段语音缺失，语音与显示的训练步骤、换边和计时失去一致性。该任务需要随用户点击立即开始，不能交给延后的批处理。

The user has already started exercising. Delaying playback would omit the initial instruction and misalign spoken guidance with the displayed exercise, side changes and session timing. Playback must begin with the user's start action rather than a deferred batch job.

**若系统中断，对用户的影响 / If interrupted:**

练习中的用户可能看不到屏幕。语音被中断或重启会使动作结束、休息和换边提示中断，用户必须停下练习、解锁并返回应用检查状态。前台媒体播放用于维持用户主动开启的引导任务；不是常驻后台服务。

The user may be exercising away from the screen. Interrupting or restarting playback would interrupt exercise-end, rest and side-change cues, forcing the user to stop, unlock the device and inspect the session. This is a bounded, user-started guided-audio task.

## 演示视频脚本和验收表

视频链接：**待真实录制并由开哥上传到审核员可访问的地址**。没有视频 URL 时，这份声明材料尚不具备可提交的完整证据。不得用文字脚本、旧版本录像、静音剪辑或模拟器通过替代本次真机演示。

1. 展示手机中最终 `1.0.0+20` 构建身份、未在训练时的通知栏；不得出现个人通知或敏感内容。
2. 从 HipLab「今日」选择真实训练并点击开始，录到明确用户动作、动作示范及实际语音；展示训练通知出现。
3. 切到系统桌面或其他无敏感信息应用，持续记录至少一次动作/换边/休息语音及训练仍在继续。
4. 锁屏，外部摄像机记录手机状态和时间；耳机试听由佩戴者确认。耳机模式下屏幕录制可能录不到实际输出，不能仅看音轨/计时就宣称人耳听到；另记录真实用户确认。
5. 覆盖完整训练直至自然结束。若视频摘要有剪辑，明确标注删减并保留未剪原始证据；锁屏时长和重要过程不得伪造。
6. 回到应用展示自然完成结果，拉下通知栏证明训练通知已消失；用运行日志和服务状态辅助检查无崩溃、服务/唤醒锁/媒体会话已释放。可补一段用户主动结束路径，不代替自然结束。
7. 补录用户主动开始一次带语音自测并结束，展示该入口同样由用户触发音频指导和通知，结束后释放。它与跟练共用上述服务，不额外申请 `health` 或传感器权限。

| 项目 | 目前可作出的结论 |
|---|---|
| 用户现有 App 体验 | 用户 2026-10-24 表示「app我已经都测试通过了」；未明确该报告所指构建号和逐项耳机/锁屏证据 |
| 新 `1.0.0+20` 完整训练 | 真机新包未重测；API35原生模拟器同AAB短训练4/4自然完成，锁屏/后台服务保持、结束通知及会话清理通过，不替代耳机人耳试听 |
| 历史 D-34 小米锁屏冻结 | 失败历史保留，不能据一般体验反馈追溯改为通过 |
| 声明理由、影响和演示步骤 | 本文件已提供，待匹配最终产物及真实视频 |
| Play 表单实际填写/送审 | 本轮未操作，由开哥完成 |

Google 要求功能描述、延迟/中断影响、用户触发演示及视频链接，详见[前台服务声明说明](https://support.google.com/googleplay/android-developer/answer/13392821?hl=en)。Manifest 类型与权限对应关系见 [Android 服务类型](https://developer.android.com/develop/background-work/services/fgs/service-types#media)。

## 数据安全表草稿

**适用前提：最终包未传任何 AI Key、远端目录地址或其他远程配置，保留的 AI 入口只用本机预设回落，无在线模型和远端目录请求，且发布构建未集成广告、分析、崩溃上传和其他发送用户数据的 SDK。** 本表根据 App 源代码与固定 SDK 的数据流给出；最终 AAB 和运行核验由主报告补齐。

数据安全是整个包名下实际分发版本的合并口径。开哥应确认所有在测/分发渠道：如仍向用户分发带 Key 且会联网的 AI 构建，不可仅按此离线基础包回答“不收集”，应覆盖其安装标识、用户输入和相关数据流。历史 0.2.0+4 的已送审记录不证明当前平台状态。

| 表单问题/类别 | 本基础版的建议回答与理由 |
|---|---|
| 应用收集或共享必须披露的用户数据吗 | 否，前提满足上段范围。训练、自测及反馈只在本机处理，未由 App 发往外部服务 |
| 收集的数据类型 | 不勾选个人信息、财务、位置、健康与健身、消息、媒体、文件、日历、联系人、应用活动、应用信息/性能、设备或其他标识符；本机记录不等于离机收集 |
| 共享的数据类型 | 无；基础版无自动对第三方传输用户记录的功能 |
| 账号创建 | 无账号创建、登录、OAuth 或账号绑定 |
| 应用内账号删除 | 不适用；无账号。隐私政策明确本地清除/卸载和系统备份管理方法 |
| 数据传输加密问题 | 如“不收集”后表单跳过，保持跳过；本包无待声明的离机数据传输，不为回环 HTTP 虚构全程 TLS 或认证 |
| 删除请求网页/机制 | 如表单因不收集而不要求则不虚构。没有远程账号/记录可由开发者代删；本地删除见隐私政策，支持邮箱可受理问题 |
| 独立安全审查/认证 | 未完成，不宣称通过 |
| Android/厂商系统备份 | 未禁用，用户系统设置可能备份私有数据；隐私正文披露。开发者不读取这些备份，不把系统备份写成 App 自有云同步 |

参考[数据安全填写说明](https://support.google.com/googleplay/android-developer/answer/10787469?hl=en)：表单包含第三方 SDK 数据流；仅本机处理且不传出设备的数据不算离机收集。最终所有渠道的事实由开哥确认。

## 权限及其他内容声明

| 项目 | 建议填写 |
|---|---|
| `INTERNET` | 普通权限，内置视频通过 `127.0.0.1` 本机服务播放，无 Key 基础版不调用 AI 服务；不勾选位置、录音等无关用途 |
| `ACCESS_NETWORK_STATE` | 最终合并清单中由播放依赖带入的普通权限，用于网络状态检查，不授权读取或上传训练记录，无运行时弹窗 |
| `com.ugk.hiplab.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION` | 最终合并清单的应用自有 signature 权限，保护 AndroidX 内部动态广播接收器；非用户数据权限，无运行时弹窗 |
| `FOREGROUND_SERVICE` / `FOREGROUND_SERVICE_MEDIA_PLAYBACK` | 按本页 mediaPlayback 声明；用户主动开始的训练指导音频，显示训练通知 |
| `WAKE_LOCK` | 训练/自测会话内的计时和语音连续性；会话结束按生命周期释放，非持续追踪 |
| 通知权限 | 固定 SDK 和 App 源 Manifest 未声明 `POST_NOTIFICATIONS`；不要声称请求了提醒通知权限。训练媒体通知与尚未实现的久坐提醒是两回事，以最终合并 Manifest 为准 |
| 特殊权限 | 无相机/麦克风/定位/后台定位/身体传感器/Health Connect/短信/通话/全文件访问/精确闹钟/无障碍/全屏意图；不提交对应受限权限理由 |
| 广告 | 无广告 |
| 应用访问权限 | 基础功能无需账号、邀请码、Key或审核员凭据；按用户最新决定保留AI入口，未配置Key时使用本地预设回落，不提供在线AI |
| 应用类别/健康声明 | 健康与健身，活动与健身相关内容；无医疗器械、疾病管理、研究、传染病或传感器采集；仍应完成健康应用声明 |
| 目标受众 | 成人 18+，沿用真实产品定位，不选择面向儿童 |
| 内容分级 | 依据最终问卷逐项填写；无暴力、色情、赌博、用户社区、公开UGC或付费抽奖。不把旧 IARC 分级直接作为本次回执 |
| AI生成内容 | 运行时不提供AI文本/图像生成；正式图标有ImageGen辅助制作来源。若Console询问上传美术素材是否AI制作，如实披露该图标来源，不把真实截图标为AI生成 |
| 财务/支付 | 无金融功能、订阅或应用内购买 |

健康类隐私政策需公开可访问，并与实际行为一致；商店描述需有一般健身和非医疗说明。参考[健康内容政策](https://support.google.com/googleplay/android-developer/answer/16679511?hl=en)。
