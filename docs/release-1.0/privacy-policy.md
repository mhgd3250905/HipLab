# 开胯训练助手 HipLab 隐私政策草稿

更新日期：2026 年 10 月 24 日。适用版本：Android 基础版 `1.0.0+20`，包名 `com.ugk.hiplab`，打包不配置 AI Key。开发者：Bboy Ug1yk。

本文件是待审阅正文；保存到 Git 不等于公开网站已更新。拟继续使用的公开地址为 <https://mhgd3250905.github.io/HipLab/>。该地址本轮 HTTP 核对为 200，但当前网页仍标注 2026 年 10 月 17 日，尚未补充以下训练前台服务说明。

## 我们如何处理信息

HipLab 面向成年人的日常髋部活动度与柔韧练习。此基础版无需账号，不含广告、行为分析、崩溃上报、支付或云同步功能。应用保留「AI 定制」入口，但未配置在线 AI 服务；输入需求后由本地预设方案回落，不调用在线模型。开发者不通过此基础版收集、上传、出售或分享你的训练、自测或偏好数据。

## 保存在设备上的信息

安全提示的回答、训练身份选择、自测结果、疼痛与麻木反馈、训练日期和完成情况、自己的训练组、提醒时间和主题及音量等偏好，通过本机应用私有存储保存。这些信息用于设备上的练习安排、进度显示和设置恢复。开发者无法通过应用远程读取这些记录。

基础版不会为了 AI 请求生成或发送安装标识，不会向 AI 服务发送需求、对话、自测或训练记录，也不拉取远端动作目录。入口中的需求和预设回落在本机处理。若由带 AI 功能的旧测试版覆盖升级而保留了安装标识或 AI 使用记录，它们可继续留在应用私有存储中，但此基础版不会自动上传它们。

## 保留、删除和系统备份

本地记录会保留到你通过系统设置清除应用存储或卸载应用。Android 系统或设备厂商可能按照你的设备、账号和备份设置备份应用数据，并在重装或迁移设备时恢复。应用未禁用系统备份。此类备份由系统或相应服务提供方控制，开发者不接收或存储这些系统备份。

清除本地存储或卸载并不保证删除已有的系统或云端备份。请在设备或备份服务设置中管理、关闭或删除备份。开发者无法访问或代你删除设备和系统备份中的记录。

## 视频、语音和权限

动作视频、示意图和语音随应用提供。Android 的 `INTERNET` 权限用于绑定 `127.0.0.1` 的本机媒体服务，供应用内播放器读取素材；此地址不离开本机，不用于向外部服务器上传记录。应用限制普通明文网络访问，仅允许本机回环媒体地址。

你主动开始跟练或自测后，应用可能使用 `FOREGROUND_SERVICE`、`FOREGROUND_SERVICE_MEDIA_PLAYBACK` 和 `WAKE_LOCK`，支持本机训练语音、会话计时和训练中的唤醒状态，并显示训练通知。结束训练、离开会话或移除任务时，程序按生命周期停止服务并释放资源；具体设备运行情况按实际验证结果说明。这些权限不用于持续追踪、采集健康传感器数据、定位、广告或上传。

应用不请求相机、麦克风、位置、联系人、身体传感器、Health Connect、健康记录、短信、通话记录或共享存储访问权限。耳机由 Android 系统负责路由，应用不会为了播放而读取联系人、扫描蓝牙设备或录音。久坐提醒设置目前仅保存安排，不投递系统提醒通知。

## 外部链接和主动联系

隐私页提供公开政策地址及支持方式。你主动在浏览器访问公开网站，或通过邮件、GitHub Issues 联系我们时，相关服务提供方会按各自政策处理你主动提交的内容和访问请求。请勿在公开 Issues 中填写敏感健康或身份信息。此类主动联系不等于应用自动上传训练记录。

## 成年人健身和安全

本应用面向成年人提供一般健身信息，不面向儿童，不是医疗器械，不能诊断、治疗、治愈或预防疾病，也不能替代医疗建议。如有疼痛、麻木、受伤或其他不适，请停止练习并咨询合格的医疗专业人员。

## 政策变更和联系

如数据处理方式变化，我们会更新应用内说明及公开政策。与本基础版不同的在线 AI 功能构建，不适用此处的无在线 AI 数据流说明；公开政策和商店数据安全声明必须覆盖实际分发给用户的版本。

开发者：Bboy Ug1yk。支持与隐私邮箱：mhgd3250905@gmail.com。项目 Issues：<https://github.com/mhgd3250905/HipLab/issues>。

## English privacy policy draft

Updated October 24, 2026. Applies to the Android basic release `1.0.0+20`, package `com.ugk.hiplab`, built without an AI key. Developer: Bboy Ug1yk.

HipLab provides general hip mobility and flexibility practice for adults. This basic release has no accounts, ads, analytics, crash reporting, payments or cloud sync. The AI customization entry remains visible, but no online AI service is configured. Requests entered there use on-device preset fallbacks without calling an online model or fetching a remote catalog. The developer does not use this release to automatically collect, upload, sell or share your training records, self-check answers or preferences.

Safety answers, selected training profile, self-checks, pain or numbness feedback, practice dates, session results, personal training groups, reminder schedules and preferences are stored in the app's private local storage. They support on-device planning, progress and settings. The developer cannot remotely read these records. This basic release does not create or send an AI installation identifier. Data retained when upgrading from a previous AI-enabled test build may remain locally but is not automatically transmitted by this release.

Local records remain until you clear app storage or uninstall. Android or your device manufacturer may back up and restore app data according to your system and backup settings. System backup is not disabled by the app. These backups are controlled by the system or backup provider, not received by the developer. Removing local data does not necessarily remove existing backups; manage those through the relevant system or provider settings.

Videos and spoken cues are bundled. The Android internet permission supports a media server bound to the device's `127.0.0.1` loopback address. It does not send your records to an external server. Ordinary cleartext network access is restricted to local media addresses.

When you start guided practice or a self-check, foreground-service, media-playback and wake-lock permissions support local audio, timing and an active training notification. Session termination releases the service and related resources through the app lifecycle; device behavior requires actual runtime verification. These permissions are not used for tracking, health sensors, location, advertising or uploading data. The app does not request camera, microphone, location, contacts, body sensors, Health Connect, SMS, call-log or shared-storage access. Android manages headphone audio routing. Reminder settings currently save a schedule without delivering reminders.

If you choose to open a website or contact us by email or GitHub Issues, those services process the visit and the information you submit under their own policies. Avoid posting sensitive personal or health information in public Issues.

HipLab is intended for adults and general fitness. It has no medical-device function, provides no diagnosis or treatment, and makes no disease-curing or prevention claims. Seek qualified medical advice and stop exercising if you experience pain, numbness, injury or other discomfort.

We will update the in-app and public policy when data practices change. Any separately distributed AI-enabled version needs disclosures reflecting its own data flows. Contact Bboy Ug1yk at mhgd3250905@gmail.com or <https://github.com/mhgd3250905/HipLab/issues>.
