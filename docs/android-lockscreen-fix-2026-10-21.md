# Android 锁屏复测（2026-10-21）

本页继续[训练包接入](ugk-trainer-adoption-2026-10-20.md)及[AI新中转](ai-relay-migration-2026-10-20.md)。+13、+15的锁屏冻结失败保留；+14未开练。本次只完成当前整节课程与必要终态核对，不扩展系统中断矩阵或重复已通过检查。

## 修复与代码验证

SDK `8fb0aacff2072b31c4abaea10e101075fb9a2e9a` / trainer0.1.3，Android将保活音轨播放器音量从0改为1，iOS仍为0。现有 `silence.m4a` 解码后的89088个PCM16采样全部为零；没有增加可闻声音、服务或持续音频焦点。自定义保活音源也必须提供真正静音采样。

上轮+15虽有started音轨，但系统标记为clientVolume静音。Android的[AudioPlaybackConfiguration实现](https://android.googlesource.com/platform/frameworks/base/+/refs/heads/main/media/java/android/media/AudioPlaybackConfiguration.java)会将客户端音量静音的播放器排除出有效播放。该事实与上轮系统判音频不活动后Greeze冻结的日志相符；是否解决设备冻结由下述整节验证决定。

SDK训练包119/119、analyze0；根包168及analyze0沿用8ef37a9，根代码未变，不重复跑。App `38bce474723d45d4b025e7def52dfe935ed40fda` 固定上述Git来源，锁校验成功；App全量439pass/1条件skip（3分39秒）、analyze0（6.0秒），包括保留的原语音时序。唯一skip是需设置VOICE_TIMELINE_OUT的导出。没有注入真实密钥跑测试或再次调用AI。

证据：`E:/AII-3D/ugk-trainer-verification-20261020/android-unmuted-loop-{test,analyze}.log`、`silence-pcm-check.json`；App `build/android-unmuted-loop-app-{test,analyze}.log`。

## 包与安装

App共用版本0.3.9+16，构建开始于10月20日晚、安装于10月21日零点后。保留原任务交付目录名 `E:/AII-3D/hiplab-releases/hiplab-0.3.9+16-lockscreen-20261020/`。

| 身份 | 核对结果 |
|---|---|
| APK | `hiplab-0.3.9+16-lockscreen-arm64-debug.apk`，175258187bytes |
| SHA256 | `a5a5bc30cd69cf74fed1fe0a4166bf2844dc5d439fa06d3ef80f8022b13941c2` |
| 包 / 签名 | com.ugk.hiplab / code16 / versionName0.3.9 / debug arm64；原证书连续 |
| 内容 | CRC、876源资产逐字节及唯一包内训练服务通过；新AI编译配置绑定、旧令牌define符号缺失 |
| 备份 | 14250字节偏好及23552字节shared_prefs/files备份，均留本机 |
| 覆盖安装 | install -r成功；冷启动1338ms；安装启动后偏好逐字节一致，20记录/4组/3完成日及同一设备UUID保持 |

APK中继续携带新入口、模型及只通过dart-define注入的App Key，未将凭据放入仓库。UUID原值和用户备份不写文档。安装、源码分支推送、main合并分别登记。

## 当前整节观察

00:02:05.839启动已保存的8动作「办公室久坐开胯」（列表剂量9分38秒），00:02:21.511关屏。用户确认扬声器口令正常继续，随后授权独立完成当前测试、避免冗余测试。

初始保活音轨piid24487/session7953在UID10310/PID11056，device3扬声器，started/mutedState:none；之前的clientVolume静音标记消失。00:03:00仍Dozing、训练锁无DISABLED、服务isForeground=true。整节尚在进行，不能把这些阶段快照写为完整通过。

锁屏期间仅用系统dumpsys和系统logcat观察，不用run-as或启动App UID进程唤醒它，不点亮屏幕。原始证据在交付目录 `native/course-start.json`、`audio-first-lock.txt`、`monitor/`、`lockscreen-logcat.txt`。待自然结束后核对SessionResult、原记录和训练服务/音轨释放。

两个main均未合本轮；完成后仍按用户本轮要求等待最终合并同意。未上传商店或调整商店配置。


## 本轮结果：失败，继续SDK修复

00:07:22训练锁仍正常；00:07:42.015系统真实移除音频活动UID，00:07:47.193 Greeze冻结。00:08:17系统快照中训练锁DISABLED，FGS仍true，音轨仍started/mutedState:none，屏幕Dozing。单次media_session核对的会话栈为0，没有HipLab媒体会话。因此全零采样正常音量仅修正了AOSP静音标记，不足以避免本设备冻结。

失败证据为native/failure-summary.json、media-session-failure.txt、monitor/20261021-000817-{audio,power,services}.txt及lockscreen-logcat.txt。已停止系统采集；手机安全锁屏，尚未正常结束课程/读取新结果，不能宣称记录21或完整8/8。用户回来解锁后继续正常结束及保留记录。

下一候选在包内现有唯一前台服务建立framework MediaSession、真实PLAYING/PAUSED状态与MediaStyle token，并受session owner和安全上限管理。官方API证明系统可发现性，不证明小米必然免冻；仍需一次完整锁屏复测。已通过的439/119及原语音时序不重复跑，只验证新增接口、原生编译与必要现场。


## 第三轮修复候选0.3.9+17：已构建，未安装

SDK提交d6268aa加入媒体会话与真实状态；d193a703e3a8bef6d41e7705a55ae250e23e6a69再限定仅语音或提示音启用时创建媒体身份，trainer0.1.4。默认自测及纯静默视觉训练保持普通hold。owner保护覆盖状态/STOP，暂停不续cap，finish、taskRemoved、destroy、启动/锁失败、原生cap到期均STOPPED→inactive→release，并释放锁与通知。仅既有唯一服务，无新依赖/权限/系统电池白名单或持续音频焦点。未宣告外部播放控制。

必要增量验证：SDK hold9/9、受影响UI24/24在d6268aa通过；追加静默边界后新UI文件4/4在d193a70通过，scoped analyze/format/diff检查通过。这些是已有工具输出，未为产生日志重新运行，汇总media-session-targeted-validation.json留本机。App79c172d9a83d248f23e136cffe825f3bd016e16b固定精确Git来源，锁校验通过；App analyze0（6.5秒）、自测/package共享owner与释放专项8/8（1秒）。原439/119及AI/语音时序沿用前一已验源码，相关执行器未改，不伪称在新提交重新跑过全量。

原生APK已成功编译（Gradle26.8秒），debug arm64，175258975bytes，SHA256 `09e11efd96f284aeb642e0b46b05843916b061d0e06e40160089cbeeca08ce51`。产物：`E:/AII-3D/hiplab-releases/hiplab-0.3.9+17-media-session-20261021/hiplab-0.3.9+17-media-session-arm64-debug.apk`。com.ugk.hiplab/code17/0.3.9，原签名连续、CRC/876资产/单服务通过；继续携带新AI编译配置，无旧令牌define，未输出实际key。

手机仍安全锁屏，未安装+17，也未正常结束+16失败课程。已请求用户回来后本人解锁，随后正常结束并核对结果、重新备份、install-r保留数据，再只做必要的PLAYING/PAUSED/恢复身份与整节锁屏/自然释放验证。不能把API、单测或编译当作小米免冻保证。SDK草稿PR #2及App开发分支已保存候选，两个main未合；没有上传商店。
