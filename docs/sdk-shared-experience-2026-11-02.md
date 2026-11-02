# HipLab 共享体验接入（2026-11-02）

## 启动定位更新（2026-11-02）

启动修复源为`1f76e745da30133b8b38986d27c2f1b9e5df7791`，继续原分支`codex/sdk-shared-experience@1b2399e`。**启动最小用例和断网回归通过；全量未通过，遇SDK布局问题按约停止，没有新APK。** 下方接入/两轮暂停/首次诊断包均为前轮历史。

先只跑`hip_flow_test.dart`的`a no-key build hides AI training and usage entries`，在`HipApp._load`每个await前后加临时日志及catch/rethrow。日志依次通过store、action media、public policy（已注入），到`coach catalog begin`后先发生`tab-1`缺失断言，再打印`coach catalog ready`、library ready、voice done；没有ERROR。卡点是App用`rootBundle.loadString`读取276253字节的内置`assets/coach/catalog.json`：非Web、至少51200字节时Flutter通过compute isolate解码，其完成不受widget fake async时钟驱动。不存在启动等待公共catalog下载、视频预取或Worker的证据。

App改为`AssetBundle.load`读取bytes、UTF-8解码，仍调用SDK`Catalog.fromJson`校验；不修改SDK、不加缓存、预热或遮罩。删除前轮24处测试setUpAll预热及辅助函数，临时日志已全部移除。原最小失败用例**1通过**。新增`hip_offline_startup_test.dart`，用真实SDK公共catalog/磁盘媒体仓库（只替换native目录查找为仓库build下隔离目录），HTTP连接全部失败、预取配置开启、coach已配置；内置公共poster可解码，冷coach catalog直接启动，`tab-1`和`start-today`均出现，初始化及进首页**0 HTTP client、0连接**；**1通过**。真实文件I/O和图片解码在tester.runAsync中，测试目录验证边界后删除。

严格`flutter analyze --no-pub --fatal-infos`为**0问题**。随后仅启动一轮全量，执行到**385通过/19失败**时停止，**未全量完成**。原普遍启动缺失已消除；18项涉及Launcher入场/海报解码等待及旧滚动辅助假设，仍需后续逐条验证，不能统称已修复或全部只是测试问题。另1项已用单条完整错误诊断确认：`hip_search_keyboard_test.dart`的`search ×2.0: tap shows the keyboard, keeps it when the inset arrives, typing filters`，390×844设备、text scale2.0、键盘inset320px，SDK的`packages/ugk_trainer_runtime/lib/src/library/training_library_browser.dart:221`之Column在**390×301约束**下**底部溢出20px**。固定搜索/筛选/汇总区域装不下；未证实是重复扣键盘inset，不将该猜测写成根因。最小复现命令：

```powershell
flutter test --no-pub --concurrency=1 --reporter expanded test/hip/hip_search_keyboard_test.dart --name 'search .2[.]0: tap shows the keyboard, keeps it'
```

2倍字号原不属当前日常显示门槛，但本任务另有全量通过要求；不删除测试、添加skip或在App改布局掩盖失败。按用户“若根因在SDK，停下报告，不在App侧绕过”边界，确认该问题后停止全量进程、后续测试适配和构建。未开启第二轮修复循环。此报告是SDK交接材料，**未创建外部issue或发送消息**。

Flutter差异：HipLab固定**3.44.7/Dart3.12.2**；SDK文档验证环境为**3.47.8/Dart3.13.7**。两套本机`asset_bundle.dart:91–100`源码一致，均以51200字节为compute阈值；SDK声明Flutter`>=3.44.0`、Dart`^3.12.0`，HipLab满足。版本差异不是本次启动失败的根因证据；没有用新版Flutter重跑App测试，也不据此保证两版行为全面等价。

证据目录`E:/AII-3D/hiplab-releases/sdk-shared-experience-20261102/startup-fix/`包含`minimal-trace.log`、`minimal-fixed.log`、`offline-startup.log`、`analyze.log`、未完成的`all-tests.log`及`sdk-layout-trace.log`。诊断注入已恢复原测试字节。Python沿用前轮25/25，本轮未重复。版本保持**1.1.0+28 / 2028**、SDK保持**d4502f35b1503d41cd782aa7fb3780c7f6591ad0**；没有新APK路径或包体，旧诊断包继续标为NOT-ACCEPTED。原日常WIP单独保存，不合main、不打tag、不动release/托管/Flare、不操作手机或商店。

## 前轮接入与暂停记录

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
