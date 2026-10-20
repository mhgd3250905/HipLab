# ugk_trainer 接入（2026-10-20）

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

安装前实际手机为0.3.7+12，备份shared_prefs/files及原APK；覆盖安装和启动后7154字节prefs与安装前完全一致（18训练记录、2自定义组）。设备2602BRT18C / Android16 API36，字号1.0。22:41:40启动「办公室6个动作」，用户先报告锁屏口令继续，随后报告「没声音了……解锁之后又继续播放」。因此本轮原生未通过，不合并。

系统日志明确：22:42:08音频转为非活动，22:42:09.005 GreezeManager冻结uid10310（reason=screen off）；同刻PowerManager将包唤醒锁标记disabled=true、reason=greeze。22:42:31.326因Activity Resume解冻。服务始终mediaPlayback前台状态，标准Doze并未进入；不是据完成页推测。解锁后实际点击暂停，不能误记为系统音频中断。系统路由deviceId3对应扬声器，首轮亦不能记为耳机验证。主动关闭失败课程保存了一条endedEarly记录（70活动秒），现19条记录，不清理该真实记录。

原始证据在上述交付目录 `native/failure-system-logcat.txt`、`failure-power.txt`、`failure-services.txt`、`audio-locked.txt` 与 `audio-policy-after-failure.txt`。SDK原实现只有iOS静音保活；正在SDK补Android间隙保活及终态释放，单测只证明生命周期，仍须新包真机完整锁屏复测。

本轮不上传商店，不改商店配置，覆盖安装保留数据；iOS 构建/真机未验。主线合并和推送等待开哥本轮最终同意。

### 第二轮修复候选：已安装，原生待复测

SDK修复源 `7348f0cdcccf564fbddb73fef41c08e3bf30f0fa`，trainer0.1.2，已推开发分支并更新[草稿PR #2](https://github.com/mhgd3250905/ugk-3d-pose-sdk/pull/2)。Android复用包内静音音频保持语音间隙活动，不额外持续申请音频焦点；来电/断耳机暂停，end/dispose及固定两小时上限停止。播放页完成后等收尾至少4秒（长队列按实际末端延长）结束音频与服务；快速再练取消旧定时器，延迟再练等待异步end完成再启新时钟。新增7项回归，SDK全量118/118、analyze0、diff检查通过。日志 `E:/AII-3D/ugk-trainer-verification-20261020/android-keepalive-final-test.log`。

App `f702164559526c0073ad2f26734a91badb7e2b94` 固定该Git依赖，共用版本0.3.8+14。锁校验成功，Android构建35.4秒；175254439字节，SHA256 `c5f1b5e75dbf1b1da126fa35687b4138504e9c96c266b926a467d497b71f6bc6`，签名连续、CRC/876资产/单服务通过。新交付目录 `E:/AII-3D/hiplab-releases/hiplab-0.3.8+14-trainer-lockscreen-20261020/`。安装前再次备份shared_prefs/files，安装后9882字节prefs逐字节一致，保留19记录/2组/3完成日。覆盖安装回读code14，冷启动1192ms。

App新依赖analyze0（5.6秒），全量回归429过/1条件skip（4分33秒），唯一skip为未设VOICE_TIMELINE_OUT的时间线导出；日志build/ugk-app-android-fix-final-analyze.log和build/ugk-app-android-fix-final-test.log。启动首页看到测试闹钟浮层；之后用户明确「用扬声器即可」，本轮锁屏复测不再以耳机为门槛。再次观察闹钟已不在屏幕，当前为用户生成的「开髋灵活」7分钟/9动作课程；在点击开始前用户要求稍等、需使用其他App，因此未启动训练并停止手机操作，待其通知。SDK单测和本次安装不代表锁屏修复通过；未改系统电池/权限策略，不合main。
