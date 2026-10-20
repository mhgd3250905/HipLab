# Android 锁屏复测（2026-10-21）

**当前交付结论：** 用户10月21日最新明确“先不要纠结这个问题了，继续推进，我后面自己来测试”。因此本轮停止后台冻结排查和手机复测，未改省电策略，保留+13/+15/+16/+17失败事实，不记为通过。训练包接入和AI迁移代码/必要检查及+17保留数据安装已完成，两个main仍待用户本轮最终集成同意。

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


### 00:24已安装，开始原生整节复测

用户00:22回来解锁，+16才补算为完成页：8/8、activeSeconds1210、full=true/endedEarly=false。该结果包含冻结后的挂钟追赶，仍明确归为+16失败，不能当20分钟锁屏通过；保留真实记录不删除，记录20→21、4组和原20条逐项保持。训练服务已释放，正常点击完成退出。

+17安装前备份17637字节偏好与files；install-r成功，冷启动1271ms，启动后偏好逐字节相同，21记录/4组/同一UUID保持。实际系统会话com.ugk.hiplab/ugk_trainer:guided/29，UID10310/PID11197，active=true、PLAYING(3)。页面暂停后PAUSED(2)、恢复后PLAYING(3)，通知包含MediaStyle与android.mediaSession token，均为真实设备dump。暂停核对阶段主机读取中文dump遇默认GBK解码失败，改UTF-8后核对、恢复，不作为App异常或锁屏测试时间。

00:23:52.606启动同一AI保存组，00:24:34.883关屏。当前整节观察中；锁屏期间仅系统采集，结束前不读取App UID或唤醒屏幕。记录native/course-start.json、media-{playing,paused,resumed}.txt、notification-media-style.txt、monitor/及lockscreen-logcat.txt。尚未先记通过或合main。


### +17整节结果：仍失败（00:30）

00:29:36训练锁仍正常；00:29:41.070系统移除音频活动UID，00:29:50.582 Greeze冻结（关屏5分15.7秒），00:30:39系统快照确认训练锁DISABLED。FGS仍在、MediaSession /29仍active=true/PLAYING、纯静音音轨仍started/mutedState:none。故正式媒体会话可发现性已验，但它并没有解决此设备冻结；本轮仍FAILED，不能改写为通过。

系统采集已停止，现场在native/failure-summary.json、monitor/20261021-003039-*及lockscreen-logcat.txt。此后一次只读AOSP检查显示RUN_ANY_IN_BACKGROUND/RUN_IN_BACKGROUND均默认allow，standby bucket40，设备idle白名单无HipLab；这些不能代表小米独立后台策略已放行。下一步先核对HipLab的系统后台省电限制，使用同一个+17包做设置前后对照，不继续猜测改音频或重新构建。小米[官方支持说明](https://www.mi.com/uk/support/faq/details/KA-700534/)将单App后台No restrictions列为后台运行保护步骤；是否适用于此台手机需实际查看并验证，不能先认定根因。安全锁屏已请求用户再次解锁，以正常结束失败课程及查看设置。


## 用户决定后续自行测试（00:34）

用户已解锁但要求停止纠结后台问题、继续推进，后续自己测试。停止进一步ADB排查、系统省电设置查看/修改、重建与训练复测。收尾只核对旧数据和当前服务：原21条记录/4组/UUID仍保持，+17失败课程尚未保存新记录，读取到的1210秒8/8是前一+16补算记录，不能归给+17。

为结束本轮仍挂起的测试，在保存偏好后只force-stop com.ugk.hiplab，未清数据、未回写备份。训练服务已消失，未继续操作手机。+17当前失败尝试未新增训练记录，不造结果。证据native/prefs-after-failed-course.xml、failed-course-result.json、services-after-user-deferred-stop.txt。用户后续可自行正常启动现有+17包测试。

代码范围已完成：训练引擎/播放页/语音及唯一前台服务由Git依赖ugk_trainer提供；App保留课程开场/剂量台词/D-01/自测，疼痛和感受通过插槽，保存SessionResult。AI新入口、模型、App Key dart-define、持久设备UUID与无Authorization均已实现并经过真实手机生成保存。锁屏问题不再作为本轮继续排查任务，但不能由此改记原生通过；耳机/蓝牙/iOS等未验范围仍不扩展。

最终代码来源App79c172d、SDKd193a70（coach0.1.3/trainer0.1.4），同一已安装0.3.9+17，无额外代码改动或重新构建。代码检查沿用上文精确来源与增量验证，不为交接重复跑测试。App开发分支与SDK草稿PR #2可供最终审阅；依用户原始“经开哥同意”要求，合并/推送main仍需最后同意，不上传商店。
