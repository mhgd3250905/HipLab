# HipLab AI 新中转迁移（2026-10-20）

**已获准合入main：** 2026-10-21两仓库main已推送，SDK PR #2已MERGED；App精确依赖d193a70，手机仍0.3.9+17。新AI入口/持久UUID验收事实保持；锁屏冻结另保留给用户后测。[主线确认](android-lockscreen-fix-2026-10-21.md#主线合并确认2026-10-21)。

**00:08失败阶段快照：0.3.9+16锁屏仍失败。** 00:07:47.193 Greeze冻结（关屏5分25.7秒），服务和started/mutedState:none音轨仍在、训练锁DISABLED；系统媒体会话栈为0。不能把正常音量修正记为锁屏通过。当前安全锁屏，待用户回来解锁后正常结束本轮；SDK正在补真实媒体会话与释放，main未合。[完整现场](android-lockscreen-fix-2026-10-21.md)。

**后续安装：** 10月21日0.3.9+16继续保留本页AI实现和同一UUID；仅升级训练包锁屏候选，记录/训练组完整。[后续整节复测](android-lockscreen-fix-2026-10-21.md)。

在既有 `codex/adopt-ugk-trainer` 分支补充本轮需求。用户最初需用手机，前半轮仅电脑验证；23:37用户确认手机可用后恢复安装与验收，新AI入口、UUID和保存通过，但播放器整节锁屏复测失败，main未合。

## 实现与凭据

- 默认入口 `https://api.uuugk.win/v1`，默认模型 `deepseek-v4-flash-0731`；未填和空白模型均回退此值。
- `UGK_COACH_APP_KEY` 只从编译期 dart-define 读取，发到 `X-App-Key`。不再读取旧 `UGK_COACH_API_KEY`，不做兼容别名，AI 请求不带 Authorization。实际值来自用户提供的本机私有文件，没有写入源码、测试或文档；构建私有参数留在 E 盘交付目录，旧构建参数中的旧令牌已移除。
- `CoachDeviceId` 在 `main` 首次启动即生成 UUID v4，独立持久键 `hip.coach.device-id.v1`。后续启动、多个服务和并发请求复用同一标识，作为 `X-Device-Id`；写入成功前不发布新 ID，失败不发请求且下次可重试。App Key 不写入用户偏好。
- 同步修正 App 内隐私说明，说明主动使用 AI 时发送对话与随机安装标识，不再保留“完全不向外部发请求”的旧措辞。没有发布公开政策或商店改动。

SDK 现有 `AuthProvider` 足够承载新请求头，无需修改其他 App 的默认模型或鉴权。发现异步请求头准备在 SDK 计时器清理范围之外，在 SDK 修复：取消/超时也覆盖鉴权准备，失败不遗留计时器或迟发 HTTP。提交 `8ef37a92bcc9e701fbe454ba98aa2100406287fb`，ugk_coach0.1.3/trainer0.1.2，已推 SDK 开发分支和[草稿 PR #2](https://github.com/mhgd3250905/ugk-3d-pose-sdk/pull/2)。

## 验证

App运行源 `f8f0ec8af94d67149612574070c11094eeb80900`，Git固定上述SDK，锁校验通过；uuid4.6.0从间接改直接依赖，版本不变。受影响38项通过：旧AI27、新relay6、设备ID4、原隐私组件1。本机真实HTTP回归检查生产Service→SDK请求路径、地址/模型/请求体、两个头及无Authorization、跨服务复用UUID、身份失败不请求且后续重试；另以旧令牌define编译验证不能启用AI。

SDK根包168项与训练包118项全通过，两包analyze0。日志在 `E:/AII-3D/ugk-trainer-verification-20261020/relay-sdk-root-*.log` 和 `relay-trainer-*.log`。App全量首轮438过/1条件跳/1旧隐私断言失败；已按真实数据流更新断言并改截图夹具旧参数名，最终全量439过/1条件skip（5分19秒）、analyze0（3.2秒），日志 `build/coach-relay-final-rerun-{test,analyze}.log`。唯一skip为未设VOICE_TIMELINE_OUT的导出。夹具对齐提交ab963d7，仅测试改动，不影响已构建运行源。

### 真实入口观察（不能以最小请求代替完整计划）

主机通过生产Service调用完整计划，首轮82.409秒、回落 `unavailable`；通过电脑已有代理复核83.611秒、仍为HTTP错误后回落，2次HTTP尝试，无返回token。原始日志分别为交付目录 `live-relay-smoke.log` / `live-relay-proxied-smoke.log`。不把回落的内置6动作当成AI成功。

独立最小诊断：系统代理下 `GET /v1/models` 200（16模型），指定模型的最小POST 200（3.270秒，未带Authorization）；Dart SDK最小请求亦收到响应，但16-token上限全部用于推理而截断（12.023秒）。这些最小诊断本身未作为完整计划通过。主机测试的代理设置仅在Git忽略的测试脚本内，不进入App或APK，手机网络设置未改。

最后完整复测通过：同一App Service/目录/profile/请求体与鉴权配置，主机诊断仅记录HTTP状态、关闭自动重试以限定为单次请求；31.279秒返回200，首轮生成通过校验的5动作计划，5856 token，未重写、未回落、单次HTTP。日志 `live-relay-diagnostic.log`，结果 `live-relay-summary.json`。不推定前两次失败的具体服务端原因；保留失败记录，也不把主机成功扩大为手机AI或锁屏验收。

## 构建与设备边界

0.3.9+15 debug arm64已构建（Gradle27.6秒），产物：`E:/AII-3D/hiplab-releases/hiplab-0.3.9+15-relay-20261020/hiplab-0.3.9+15-relay-arm64-debug.apk`，175257947字节，SHA256 `34e337b8760cb1bd709824282ab6d8b88efe2f19d2959b5f9d98714c14d52829`。包名com.ugk.hiplab/code15/0.3.9，既有debug签名连续，CRC及876源资产逐字节通过；仅一份包内训练服务。编译参数检查确认新入口/模型/App Key绑定，旧令牌define符号不在运行kernel中；不输出实际key。

23:37对同一2602BRT18C/Android16保留数据覆盖安装，先备份9882字节偏好与files；启动只新增UUID独立偏好键，全部旧键值保持。再次冷启动（1019ms）后偏好与UUID保持。首次冷启动1242ms。APK现已安装，原签名/包名连续，不清数据。

手机点击办公室示例，36.595秒、1次HTTP、首轮通过，4554输入/2151输出token；SDK用量记录的服务器模型别名为`deepseek-flash`，请求模型仍是编译配置指定的`deepseek-v4-flash-0731`。UI标AI定制，8动作「办公室久坐开胯」、折算约10分钟，无预设回落。保存为第4个自定义组，原3组逐项相同，19条训练记录和完成日保持。原始证据在交付目录 `native/ai-native-summary.json`、`ai-plan-top.png`、`ai-save-check.json`及偏好备份。

23:44:39从已保存AI组 `c_20261020_9eb3` 开练，23:45:06关屏，用户确认扬声器口令继续。随后23:50:15系统将音频判为非活动，23:50:21.914 Greeze冻结进程并禁用训练唤醒锁，用户亮屏后声音恢复；本轮整节锁屏验收失败。锁屏监测只读系统dumpsys及持续logcat，没有用run-as读取App私有文件或点屏干扰。23:53用户通过正常结束流程退出失败课程后再读取结果：记录19→20，SessionResult活动时间字段528秒、完成6/8、full=false、endedEarly=true；4个训练组保持。随后确认TrainingSessionService已消失，仅剩WebView服务，不把提前结束后的释放算作锁屏自然完成。没有合main、上传商店或改商店配置；前两次主机HTTP失败仍保留。

### 计数修正

此前将`customRoutines`编码容器`{v,items}`的字段数2误记为训练组数。重新核对+13和+15原始备份，`items`中实际有3组；本轮相关台账已纠正为3，偏好逐字节/逐项保持的结论不变。保存本次AI组后为4组。原始备份及计数修正记录均留本机。


## 本次锁屏失败与后续候选边界

持续监测在23:46:14、23:49:45等快照中看到训练FGS、唤醒锁和零音量静音音轨存活；23:50:30快照则已出现唤醒锁DISABLED，但同一音轨仍为started、mutedState=clientVolume。系统日志在23:50:15.737移除音频活动UID，23:50:15.742记audio off，23:50:21.912还明确识别HasForegroundService，随后冻结。因此“有FGS”或“静音音轨started”均不足以证明整节锁屏通过。系统路由deviceId3为扬声器，本轮不记耳机通过。

证据位于 `E:/AII-3D/hiplab-releases/hiplab-0.3.9+15-relay-20261020/native/`：`lockscreen-logcat.txt`、`monitor/`、`failed-course-result.json`及退出后的服务快照；APK身份见上节。原始偏好、UUID与凭据不写入文档，也不因失败删除真实记录。

下一候选方向是在SDK中将Android保活音轨播放音量设为1，依赖音频素材本身的全零采样保持静音，避免clientVolume静音分类；尚未验证，不记为修复通过。现有素材解码的89088个PCM16采样全部为0（nonzeroSamples=0、maxAbsoluteSample=0），证据 `E:/AII-3D/ugk-trainer-verification-20261020/silence-pcm-check.json`。后续需重新构建并完成整节锁屏与终态释放；此处不预登记未发生的版本。
