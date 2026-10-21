# ugk_trainer 接入（2026-10-20）

**2026-10-21 10:47：本轮核心复核记录已获准合入并推送 main（354d0f1），远端回读一致。** 运行代码/依赖/版本保持，440 项与 Web 核心通过；真机暂缓、锁屏已知失败保留。下方复核中的“留分支、未合 main”是本次授权前快照；合并回执见[验证台账](verification.md)。

## 2026-10-21 接力复核（本机检查，真机暂缓）

用户再次交接同一接入任务后，从已推送的 HipLab `cb7ae4f2c50ce40243dbba0537ec0fa1aefdb637` 新开 `codex/verify-ugk-trainer-20261021` 核对现有实现。用户随后明确“先不做耳机测试，现在没有真机”，并要求先补 Web 操作验证；本轮不执行 ADB、原生构建、安装或手机操作，不把历史锁屏失败改为通过。

已 fetch 核对 SDK `origin/main = 09a392bc0b736e6a23eef71d55d86108660e0e59`。当前固定的 `d193a703e3a8bef6d41e7705a55ae250e23e6a69` 是其祖先，两者 `packages/ugk_trainer` 的 Git tree 同为 `f34eb764eb26fe54ffefbde64c6da8346d36dcf9`，训练包均为 0.1.4，源码、插件及测试逐字一致。因此保留现有固定 Git 引用；升级到 09a392b 只会额外引入 coach 0.2，不属于这次训练包复核。App 两项依赖的 ref/resolved-ref 一致，实际解析同一 E 盘 Git checkout；包内 `ugk_coach: path: ../..` 是该 checkout 内部关系，App 没有 path override。

| 交接要求 | 本轮核对结果 |
|---|---|
| 引擎、播放器、语音归包 | `HipPlayerPage` 返回 `TrainerPlayer`；App 的 `SessionEngine` 兼容视图调用包内 `SessionEngine` / `SessionRunner`，`VoiceQueue` 只转换 App 设置；逐句控制器和音频输出直接导出 SDK 实现 |
| 唯一原生服务 | App 原生服务类和旧 `hiplab/training_session` 通道已删除；MainActivity 与 App manifest 不注册第二份服务。历史 +17 构建的单服务证据保持，本轮没有重新构建 APK |
| 疼痛、感受、记录 | `onDiscomfort`、`restFeedbackBuilder`、`feedbackBuilder` 已接 App 业务；`onFinished` 接 `SessionResult`，按 sessionId 幂等保存、失败重试 |
| App 保留职责 | 课程名开场、剂量文字找台词、D-01 紧侧加组及自测仍留 App；工作节奏执行调用 SDK |
| 原语音时序 | 六份原有语音测试相对迁移前 `99fcc83` 无文件差异；生产适配另有中英文时序、D-01、疼痛与结果回归 |
| SDK 修改边界 | 本轮未发现须修改 SDK 的接入缺陷；未在 App 内复制或 patch SDK，也未手工修改 pub 缓存。SmartFit `0a40a45` 使用更早的 trainer 0.1.0，仅作接法参考 |

本轮 App 运行代码、依赖和测试保持不变，共用版本仍为 0.3.9+17。检查结果见[验证台账](verification.md#2026-10-21-训练包接力复核)。本轮复核记录留在上述审阅分支；此前已批准合入 main 的事实不变，不据此自动合并或推送新的 main。D-34 仍为已知失败，耳机锁屏整节待后续真机安排。

本轮新执行的 analyze 0、全量 440/440 及 Web 核心路径均通过。Web 真实操作覆盖自测、单练自然完成、暂停恢复、再练新 sessionId、疼痛减量/停止、休息感受与刷新保存；按用户“核心功能验证通过就行”结束本轮检查。Web 临时构建保留真实存储/音频与既有媒体封面替身，不能替代人工听音或原生锁屏；没有新 App 或 SDK 代码改动。

以下保留上一轮实施、候选及合并历史；当时的“当前”“未合 main”等不代表本轮复核状态。

**已获同意，两个main均已合入并推送。** 2026-10-21用户明确“合并并推送，保留锁屏已知问题”；SDK main为d193a70（PR #2已MERGED，00:39:10），HipLab主线集成点691ace2（00:39:31）。已安装包保持0.3.9+17/79c172d、21原记录/4组/UUID保持；锁屏冻结仍是已知失败，由用户后测，不重建/重测、不改手机省电设置、不上传商店。[合并与边界](android-lockscreen-fix-2026-10-21.md#主线合并确认2026-10-21)。

**00:08失败阶段快照：0.3.9+16锁屏仍失败。** 00:07:47.193 Greeze冻结（关屏5分25.7秒），服务和started/mutedState:none音轨仍在、训练锁DISABLED；系统媒体会话栈为0。不能把正常音量修正记为锁屏通过。当前安全锁屏，待用户回来解锁后正常结束本轮；SDK正在补真实媒体会话与释放，main未合。[完整现场](android-lockscreen-fix-2026-10-21.md)。

**10月21日00:02候选快照0.3.9+16：** SDK8fb0aac/trainer0.1.3以正常播放器音量播放全零采样，119训练包及App439过/1跳、analyze通过。保留数据安装后正在完成8动作整节锁屏复测，未预记通过或合main。[最新证据](android-lockscreen-fix-2026-10-21.md)。

**最新0.3.9+15锁屏复测失败：** 新中转/UUID/AI生成保存通过，固定SDK8ef37a9（trainer0.1.2），App439测试过/1跳及analyze0。23:50:21.914小米Greeze再次冻结并禁用训练锁；静音音轨虽started但被clientVolume标静音。用户亮屏恢复后于23:53正常退出失败课程，结果528秒、6/8、full=false、endedEarly=true，记录现20条、训练组4个，退出后训练服务已释放。main未合，仍需SDK修复、整节复验与开哥最终同意；+13失败和+14未开练历史保留。详情见[新中转与本轮失败证据](ai-relay-migration-2026-10-20.md)。

本轮在 `codex/adopt-ugk-trainer` 接入通用训练包。基线 HipLab `99fcc83`，SDK 起点 `9407bf3`，参考 SmartFit `0a40a45`。依赖固定 Git 提交，不使用浮动 main。用户要求完成验证后经开哥同意才合入 main；此前直接推进 main 的通用授权不替代本轮最终同意。

## 实现边界

训练播放界面、活动时钟、相位执行、语音队列/音频输出、Android 前台服务由 `ugk_trainer` 提供。App 删除自身 `TrainingSessionService` 与 `hiplab/training_session` 通道；自测保活适配和屏幕常亮也复用包的 owner/引用计数。

HipLab 保留课程名开场、按剂量文字找台词、D-01 紧侧剂量与整侧多组顺序、自测。`HipSessionBuilder` 将 App 编排转换为包的真实逐组相位，`HipSessionScript` 在包通用脚本上补专有台词。旧语音测试接口保留为适配视图，时钟和播放队列调用包实现。

疼痛阶梯仍在 App，通过 `onDiscomfort` 返回减量后的相位、替代或方向过滤；麻刺放射痛结束训练。动作间感受由包反馈插槽展示，完成页由 `feedbackBuilder` 展示 App 说明。单练再练复用包播放页状态，但使用新的会话 ID 和服务 owner。

训练保存接 `SessionResult`，按 `sessionId` 幂等写入，存储失败保留重试。旧记录格式可读，新记录保留完整 SDK 结果和感受，训练时长使用实际活动时间；全跳过及单练不累计连续天数。

## SDK 修复与扩展

问题在 SDK 仓库分支 `codex/hiplab-trainer-slots` 修复：通用相位构建/脚本/剂量/反馈插槽、疼痛后替换剩余相位、同页再练、实际完成计数及不对称侧组记录。不在 App 复制另一份通用执行器。

## 验证和交付

首轮 App 源 `7dd40b0`，SDK `7a84dc0` / trainer 0.1.1；SDK 全量111项通过、analyze0。App原语音129项专项通过，生产适配的中英文计数/保持/rep-hold与D-01共6例时序比较通过，疼痛插槽2例通过；最终全量429过/1条件skip（时间线导出需环境变量），analyze0，固定Git依赖enforce-lockfile成功。首轮界面适配中间失败已修复，最终日志为 `build/ugk-all-tests-final.log`。

### 第一轮 Android：失败，保留证据

0.3.8+13 debug arm64 已构建并保留数据覆盖安装；包名与签名连续，876资产逐字节匹配、CRC通过，manifest仅一份包内训练服务。APK SHA256 `64ac542cd754bd1e33445fe9451f4a4b5b4b5ae84eb758d42b5e026ea186dc98`，175247923字节。交付目录 `E:/AII-3D/hiplab-releases/hiplab-0.3.8+13-trainer-20261020/`，仅本机留存，不代表远端备份。

安装前实际手机为0.3.7+12，备份shared_prefs/files及原APK；覆盖安装和启动后7154字节prefs与安装前完全一致（18训练记录、3自定义组）。设备2602BRT18C / Android16 API36，字号1.0。22:41:40启动「办公室6个动作」，用户先报告锁屏口令继续，随后报告「没声音了……解锁之后又继续播放」。因此本轮原生未通过，不合并。

系统日志明确：22:42:08音频转为非活动，22:42:09.005 GreezeManager冻结uid10310（reason=screen off）；同刻PowerManager将包唤醒锁标记disabled=true、reason=greeze。22:42:31.326因Activity Resume解冻。服务始终mediaPlayback前台状态，标准Doze并未进入；不是据完成页推测。解锁后实际点击暂停，不能误记为系统音频中断。系统路由deviceId3对应扬声器，首轮亦不能记为耳机验证。主动关闭失败课程保存了一条endedEarly记录（70活动秒），现19条记录，不清理该真实记录。

原始证据在上述交付目录 `native/failure-system-logcat.txt`、`failure-power.txt`、`failure-services.txt`、`audio-locked.txt` 与 `audio-policy-after-failure.txt`。SDK原实现只有iOS静音保活；正在SDK补Android间隙保活及终态释放，单测只证明生命周期，仍须新包真机完整锁屏复测。

本轮不上传商店，不改商店配置，覆盖安装保留数据；iOS 构建/真机未验。主线合并和推送等待开哥本轮最终同意。

### 第二轮修复候选：已安装，原生待复测

SDK修复源 `7348f0cdcccf564fbddb73fef41c08e3bf30f0fa`，trainer0.1.2，已推开发分支并更新[草稿PR #2](https://github.com/mhgd3250905/ugk-3d-pose-sdk/pull/2)。Android复用包内静音音频保持语音间隙活动，不额外持续申请音频焦点；来电/断耳机暂停，end/dispose及固定两小时上限停止。播放页完成后等收尾至少4秒（长队列按实际末端延长）结束音频与服务；快速再练取消旧定时器，延迟再练等待异步end完成再启新时钟。新增7项回归，SDK全量118/118、analyze0、diff检查通过。日志 `E:/AII-3D/ugk-trainer-verification-20261020/android-keepalive-final-test.log`。

App `f702164559526c0073ad2f26734a91badb7e2b94` 固定该Git依赖，共用版本0.3.8+14。锁校验成功，Android构建35.4秒；175254439字节，SHA256 `c5f1b5e75dbf1b1da126fa35687b4138504e9c96c266b926a467d497b71f6bc6`，签名连续、CRC/876资产/单服务通过。新交付目录 `E:/AII-3D/hiplab-releases/hiplab-0.3.8+14-trainer-lockscreen-20261020/`。安装前再次备份shared_prefs/files，安装后9882字节prefs逐字节一致，保留19记录/3组/3完成日。覆盖安装回读code14，冷启动1192ms。

App新依赖analyze0（5.6秒），全量回归429过/1条件skip（4分33秒），唯一skip为未设VOICE_TIMELINE_OUT的时间线导出；日志build/ugk-app-android-fix-final-analyze.log和build/ugk-app-android-fix-final-test.log。启动首页看到测试闹钟浮层；之后用户明确「用扬声器即可」，本轮锁屏复测不再以耳机为门槛。再次观察闹钟已不在屏幕，当前为用户生成的「开髋灵活」7分钟/9动作课程；在点击开始前用户要求稍等、需使用其他App，因此未启动训练并停止手机操作，待其通知。SDK单测和本次安装不代表锁屏修复通过；未改系统电池/权限策略，不合main。

App运行提交f702164及本轮记录已推送 `origin/codex/adopt-ugk-trainer`；SDK7348f0c已在草稿PR #2。2026-10-20本次只读核对远端main：HipLab99fcc83、SDK9407bf3，均未合本轮。原有Playwright未跟踪目录保持，不纳入提交。


### 第三轮0.3.9+15：AI通过，整节锁屏再次失败

运行源 `f8f0ec8`、夹具 `ab963d7`、SDK `8ef37a9`，APK175257947字节、SHA256 `34e337b8760cb1bd709824282ab6d8b88efe2f19d2959b5f9d98714c14d52829`；已保留数据安装。新中转、持久UUID冷启动与手机AI首轮生成8动作/保存第4组通过，原3组保持。

23:44:39启动保存组 `c_20261020_9eb3`，23:45:06关屏。23:50:15音频活动分类被移除，23:50:21.914 Greeze冻结，23:50:21.915训练唤醒锁disabled=true、reason=greeze；训练FGS仍在，零音量静音音轨仍started且mutedState=clientVolume。用户亮屏后声音恢复，因此本轮锁屏失败，不能以几分钟存活或单测通过关闭问题。仅扬声器路由，未验耳机。

23:53用户正常结束失败课程，保存SessionResult活动时间字段528秒、完成6/8、full=false、endedEarly=true，记录19→20且4个训练组保持。结束后TrainingSessionService不在，仅剩WebView服务；这是主动提前结束后的释放，不是整节锁屏自然终态通过。证据：`E:/AII-3D/hiplab-releases/hiplab-0.3.9+15-relay-20261020/native/lockscreen-logcat.txt`、`monitor/`、`failed-course-result.json`及退出后的服务快照。锁屏中未run-as，不通过额外App UID进程干扰冻结。

候选方向为SDK Android保活音轨volume=1、素材自身静音，避免clientVolume标记；89088个PCM16采样全0的检查见 `E:/AII-3D/ugk-trainer-verification-20261020/silence-pcm-check.json`。此候选尚未验证，不登记未发生的构建或安装，也不改系统白名单。main仍未合，必须实际通过并经开哥最终同意。
