# HipLab 共享体验接入（2026-11-02）

分支 `codex/sdk-shared-experience` 从 HipLab main `0f507a3124436d29e8e3fbb7e2769a1d7d3c9018` 建立。已现场核对 SDK 远端 main 为 `d4502f35b1503d41cd782aa7fb3780c7f6591ad0`；四个实际运行包 `ugk_coach`、`ugk_coach_ui`、`ugk_trainer_runtime`、`ugk_coach_chat` 和 coach override 的 ref/resolved-ref 全部固定该提交，未重新引入 legacy `ugk_trainer`。

## 接入范围

参考 SDK 工作副本 `F:/codex-worktrees/trainer-no-flash/3D-Pose-SDK/build/` 下 `trainer-no-flash`、`media-on-demand`、`library-shared` 三批临时接线，正式接入普通课程、微训练和 AI 计划的 SDK `TrainerLauncher`，统一 HipLab 主题、public `mediaPolicy` 与 SDK 动作库/详情/示范。App 保留剂量、安全、疼痛、存储和训练回调；媒体预取、解码、封面切换与缓存由 SDK 执行，没有 App 自建媒体缓存或过渡遮罩。

单一可编辑范围配置为 `lib/hip/data/hip_action_scope.dart`，Coach 与动作库均限定 45 个公共动作，不含 `supine-cross-demo` 或 Thomas 测试。自测保留原题目、计分和对比图；仰卧横跨使用公共 `n-leg-circles` 完整示范，Thomas 仅作为自测公共示范。SDK 详情启用单练按钮并沿用 App 默认剂量和安全回调；自测详情按钮置于播放点击层上方。

删除 94 个已跟踪 MP4（47 动作各浅/深两份），移除旧视频目录和旧 Coach 剪影的打包声明；旧来源记录、母版及兼容剂量元数据保留。新包仅带 46 张公共帧零透明海报、公共 catalog 和已有业务所需资源。

## 本机构建与验证

版本 `1.1.0+28`，arm64 split APK 的 versionCode 为 **2028**。固定 Flutter **3.44.7 / Dart 3.12.2**，在带原有 `android/key.properties` 的日常目录 `E:/AII-3D/3D-Hip` 构建；未复制密钥。`kotlin.incremental=false` 避免 Windows 跨盘相对路径缓存异常，严格锁文件 pub get 重生成忽略的 plugin registrant，去掉过期 `IntegrationTestPlugin` 注册。

严格 `flutter analyze --no-pub --fatal-infos` 为 **0 问题**，Python 全量 **25/25**。Flutter 全量首轮 **310 通过 / 128 失败 / 1 条件跳过**（4分29秒）；修正旧视频断言、测试主题插值，并在 setUpAll 真实异步区加载 catalog 字符串后，第二轮仍出现同类 App 启动未进入主界面的失败。第二轮在 **234 通过 / 116 失败** 时按用户“两次仍卡住就停下报告”停止进程，后续测试未执行；**全量门禁未通过**，没有第三次修复或重试。

主要表象为 `tab-1` / `start-today` 等主界面 finder 为空；尚未定位 `HipApp._load` 的未完成步骤或错误，不将其断言为仅测试问题，也不据此宣布真实 App 启动通过。媒体、kit、域模型、Coach 等若干测试已通过，但不替代全量结果。全部日志留在非 C 盘证据目录。

## APK 与交付

首次 release 构建成功，**46,604,271 bytes（44.45 MiB）**，ZIP 内 **0 个 MP4**。诊断包保存在 `E:/AII-3D/hiplab-releases/sdk-shared-experience-20261102/hiplab-1.1.0+28-pass1-upload-signed-NOT-ACCEPTED.apk`；该包早于单练按钮和自测详情点击层修复，也早于移除旧 Coach 剪影打包声明，**不是最终候选或安装交付包**。因第二轮门禁失败，停止后没有重构建、设备证书重签或发布最终 APK。

证据目录：`E:/AII-3D/hiplab-releases/sdk-shared-experience-20261102/`，包含 `analyze-final.log`、`all-tests-pass1.log`、未完成的 `all-tests-final.log`、`python-tests-final.log` 和 `build-release-pass1.log`。

日常目录原有液态玻璃 WIP 已在切换前完整保存，收束时按原分支和字节哈希恢复。分支仅作为未过门禁的工作保存，不能视为已验收；HipLab main、release、本机托管副本和 Flare 不操作，不打 tag、不提交商店。未执行 ADB 或安装，真实操作和视觉细节未验。
