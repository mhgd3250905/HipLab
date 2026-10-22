# HipLab · 开胯训练助手

开胯训练 App：围绕髋部的放松、柔韧和主动控制训练，基础训练离线可用，AI 定制可配置联网生成并提供预设回落。面向久坐人群和舞者，打开就能练，小白也能上手。和「托马斯训练助手 FlareLab」同一家族（石墨底 + 青玉 `#3ccfa4`），但是独立 App、独立仓库。

- Android applicationId / iOS bundle id：`com.ugk.hiplab`
- App 名：开胯训练助手（iOS 英文系统显示 HipLab，`CFBundleName` 为 HipLab）
- Dart ^3.12.2；两端统一 Flutter **3.44.7 stable**。只支持 Android / iOS，中文界面；浅色/深色/跟随系统主题，中英语音播报（`feat/polish-round1` 起）

后续在本目录进行 main 主线开发，文档统一从 **[文档与开发台账](docs/README.md)** 进入：[当前状态](docs/current-state.md)、[版本管理](docs/version-management.md)、[版本交付](docs/version-ledger.md)、[验证记录](docs/verification.md)、[开发事项](docs/development-roadmap.md)、[工作流](docs/development-workflow.md)。当前状态核对日期为 **2026-10-22**；按页内日期保留历史交付与验证。

**2026-10-22 版本与阶段收束：** 当前开发分支 `codex/coach-tools-0.2` 已接入 coach 0.2.0 / trainer 0.1.4，Git 依赖固定 SDK `09a392bc0b736e6a23eef71d55d86108660e0e59`，运行来源 `5816c1b21dc5c4d398312922d70855633f2f7963`；沿用 10 月 21 日 analyze 0、469/469 和 Web 核心验证。main / origin/main 核对为 `e456d2a`，仍用旧 SDK d193a70 / coach 0.1.3；本轮 AI 尚未合 main。App 共用版本保持 **0.3.9+17**，最后已核验手机包为 79c172d，与开发候选分别记录。本次仅对齐文档并按用户授权推送当前分支，实际推送结果见[收束回执](docs/verification.md#2026-10-22-版本管理与阶段收束)；不生成新 APK，真机与真实 Worker 冷烟由后续补测，D-34 锁屏失败保留。[版本快照](docs/version-management.md#当前对齐快照2026-10-22) · [AI 工具会话](docs/ai-coach-tools-2026-10-21.md)。

2026-10-21 主线集成历史，**训练包接入及AI新中转已获同意合入并推送两仓库main**：HipLab集成点691ace2，SDK d193a70（PR #2已MERGED，coach0.1.3/trainer0.1.4）。手机已保留数据安装0.3.9+17，运行源79c172d；锁屏冻结仍是已知失败，用户后测，本轮不再排查/复测，不上传商店。[合并与验收边界](docs/android-lockscreen-fix-2026-10-21.md#主线合并确认2026-10-21)。

本仓库是 **HipLab App 主仓库，`main` 为开发基线**。[PR #2](https://github.com/mhgd3250905/HipLab/pull/2) 和 [PR #1](https://github.com/mhgd3250905/HipLab/pull/1) 已审核合并，App、高清素材和台账均已集成至 main；审核与提交身份见[主线集成记录](docs/mainline-integration-2026-10-17.md)。手机安装版本与 Git 提交分别登记。

此前2026-10-20阶段快照（历史）：**PR #25 已获同意合入并推送 main，GitHub 确认 MERGED**，业务来源 `8c985c4c6dcff4207db616e759910ea03820ad79`。新版 **0.3.7+12 AI 测试包已构建，未安装、未发布**，构建源码 `55d99b3d097afc815fa16e165362cf4703c440d5`；业务验证沿用上述来源的414项通过/1条件跳过、analyze无问题及本机真实API结果。[测试包身份](docs/android-test-build-0.3.7-2026-10-20.md)和[PR25复审/合并](docs/pr25-reaudit-2026-10-20.md)分别保存证据。

当时最后已核验安装为 **0.3.6+11 debug / arm64**，构建源码 `9b22dccc2bf2ca269a67b408198b9e3e9dbb742b`，2026-10-19 23:15:53保留数据覆盖安装。此前PR #22/#24及集成修复于23:32合入并推送main（`b33ed21088c4d334548fb45cfeb9b85959dd755d`）；当时387项通过/1条件跳过、F9编辑/键盘原生复测及正常播放听感已确认。这些旧包真机结果不覆盖PR25新功能。安装、合并和文档提交分别登记，详见[当前状态](docs/current-state.md)、[版本台账](docs/version-ledger.md)和[验证台账](docs/verification.md)。

以下为#19～#21阶段的历史交付反馈：

用户于2026-10-19反馈：已安装本轮 **0.3.6+11 debug / arm64 engine** 包并完成简单真机测试，运行源码 `c7def2869b789357b303d69d66eb8c18a0a748ae`。这是用户报告，Agent未再次ADB回读设备、版本或数据状态，不代表完整14项试听/锁屏/性能清单通过。#19→#20→#21及五项修复已顺序合入并推送main（业务集成点b9646d4）；GitHub确认三PR均MERGED。此前#17/#18的6dd16ed安装、偏好保持和专项验证保留历史，详见[当前状态](docs/current-state.md)、[版本台账](docs/version-ledger.md)及[本轮审核](docs/pr19-pr21-review-2026-10-19.md)。

制作前的视频缺口、清晰度和模型/动画源核对保留在 [媒体初始审计](docs/media-audit-2026-10-17.md)，其中缺片状态已由本轮高清交付解决。

PR #119 已审核合并，本机 4080 制作及三项动作修订已完成。绿幕、透明母帧与当前深色 App 播放版本的来源和检查见 [本地制作记录](docs/local-hd-render-2026-10-17.md)。

## 构建

本机已有依赖解析时使用 `--no-pub`，见[工作流](docs/development-workflow.md)。当前共用版本为 **0.3.9+17**；Android带AI新入口配置的debug arm64包已在源码 `79c172d9a83d248f23e136cffe825f3bd016e16b` 构建并保留数据安装，固定SDK `d193a703e3a8bef6d41e7705a55ae250e23e6a69`（coach0.1.3/trainer0.1.4），签名连续、包身份/CRC/876资产及唯一训练服务核验通过。该源analyze无问题、保活专项8/8；439过/1条件跳属于此前38bce47全量基线，未在最终依赖上重复全量测试。构建、安装和后续文档HEAD分别记录，详见[证据绑定](docs/verification.md#训练包与新中转阶段收束2026-10-21)；此次文档对齐不递增版本、不重新构建或安装。

**#19～#21阶段构建记录（历史）：** 本机现有依赖缓存的验证命令使用 `--no-pub`，见[工作流](docs/development-workflow.md)。本轮已合main的运行源c7def28：analyze0、254pass/1条件skip、Python19，arm64 debug APK已交付且用户报告安装/简单测试通过。文档收束未改变运行源码，不重复构建。真机结论限用户报告的简单测试，完整课程/音乐ducking、低端帧时、强光、新自测结果页及Mac/iPhone仍保持待验。0.2.0+4的Alpha送审回执属于2026-10-17历史，本次未回读Console或上传商店；见[送审记录](docs/play-store-release-2026-10-17.md)。下列为通用构建命令，不代表本次执行发布。

当前未验边界以[验证台账](docs/verification.md)及[开发事项](docs/development-roadmap.md)的最新日期记录为准：旧 +15 手机AI生成、保存和开练及 +17 保留数据升级已核验，不覆盖本轮 coach 0.2.0 原生/真实 Worker；本轮 Web 断网预设回落已通过。D-34 保留小米后台冻结失败，由用户后测；其他原生专项及 iOS 仍按原记录待验。下列为通用构建命令，不代表本次执行发布。

```bash
flutter pub get
flutter analyze
flutter test                                   # 单元 + 界面流程 + 资源边界测试
flutter test test_screens/hip_shots_test.dart  # 可选：界面截图 → test/_shots/hip/（不提交）
flutter test test_screens/hip_ios_shots_test.dart  # 可选：iPhone 15 Pro/SE 安全区截图 → test/_shots/ios/
python3 tools/ios/check_ios_project.py          # iOS 工程静态检查（plist / pbxproj / 图标）
python3 tools/voice/build_voice.py             # 重新生成语音（edge-tts，需联网）→ assets/voice/

flutter run
flutter build apk --release                    # → com.ugk.hiplab
flutter build appbundle --release
flutter build ipa --release                    # 需 Mac + Xcode，签名团队在 Xcode 里选，见 docs/ios-setup-and-release.md
```

Android release 签名：有 `android/key.properties` 就用它，没有时退回 debug 签名（和 3D-Body 的做法一样）。

## 目录

```
lib/main.dart                  入口
lib/hip/domain/                自测/今日训练/疼痛规则，以及练习剂量、自定义训练组和单练历史模型
lib/hip/control/hip_store.dart 本地持久化（SharedPreferences，单 key hiplab.state.v1）
lib/hip/ui/                    安全引导、今日/练习/进度三Tab、自测/跟练、动作详情与训练组编辑
lib/hip/voice/                 HipLab台词/剂量映射与设置适配；语音队列、时间线执行和音频输出复用ugk_trainer
lib/core/                      公共代码来源见下表；常亮导出及training_service.dart薄适配复用ugk_trainer保活/唯一原生服务
assets/hip/hip-content.json    内容包（脚本生成，不要手改）
assets/hip/posters/            历史原型静帧（当前 46 项动作均已接入视频）
assets/hip/assessment/         自测对比图（20 张）
assets/drill_media/            动作成片 hip-<id>.mp4 + .jpg，以及 WebView 播放器 player.html/js/css；light/ 放浅色版后自动用于浅色主题
assets/hip/onboarding/         引导页三问主视觉（深/浅各 3 张；换 B 套：tools/onboarding_art/import_onboarding_art.py <目录> B）
assets/voice/                  预生成语音 zh/ en/ chime/ + manifest.json（tools/voice/ 生成）
assets/fonts/NotoSansSC.ttf    字体（OFL）
tools/hip_content/             内容包生成脚本 + 第 0 阶段源文件（动作表 csv、成套训练 md、自测设计 md、hip-media.json）
tools/pose_hub_sync.py         当前冻结 Pose-Hub 版本同步（--from-dir / --check）
pose-hub.lock.json             Windows维护的冻结素材版本与目标
tools/sync_drill_media.py      3D-Body旧同步工具，仅保留历史兼容
test/hip/                      规则 / 界面流程 / 资源边界测试
test/core/                     公共代码的测试（随代码一起复制）
docs/                          当前状态、版本/验证/事项台账、工作流与历史设计证据
```

## 从 3D-Body 复制来的公共代码

拆仓时（来源 `mhgd3250905/3D-Body` 分支 `feat/hiplab-flavor` commit `a83a0f4`）HipLab 用到的公共部分全部复制进本仓库，每个文件顶部都注明了来源路径。以后两边各自演进，不做自动同步。

| 本仓库 | 3D-Body 原路径 | 改动 |
|---|---|---|
| `lib/core/storage/local_state_storage.dart` | `app/lib/data/local_state_storage.dart` | 无 |
| `lib/core/media/drill_media.dart` | `app/lib/data/drill_media.dart` | 只留数据类，删掉 FlareLab 媒体清单的解析/加载 |
| `lib/core/media/media_controller.dart` | `app/lib/platform/drill_media/media_controller.dart` | 无 |
| `lib/core/media/media_view.dart` | `app/lib/platform/drill_media/media_view.dart` | 去掉 Web 分支（不做 Web） |
| `lib/core/media/media_view_native.dart` | `app/lib/platform/drill_media/media_view_native.dart` | 只改 import 路径 |
| `lib/core/media/media_view_stub.dart` | `app/lib/platform/drill_media/media_view_stub.dart` | 只改 import 路径 |
| `lib/core/media/scene_asset_server.dart` | `app/lib/platform/scene/scene_asset_server.dart` | 删掉 3D 场景 URI 选项（scene_variant） |
| `lib/core/media/scene_asset_router.dart` | `app/lib/platform/scene/scene_asset_router.dart` | 无（本包没有 assets/scene/，只会命中 /drill_media/） |
| `assets/drill_media/player.html` / `player.css` | `app/assets/drill_media/` | 无 |
| `assets/drill_media/player.js` | `app/assets/drill_media/player.js` | id 规则只接受 `hip-<id>` |
| `assets/fonts/NotoSansSC.ttf` + `assets/licenses/NotoSansSC-OFL.txt` | `app/assets/fonts/FlareSans.ttf`（即 Noto Sans SC） | 改文件名，字体族改叫 `NotoSansSC` |
| `test/core/*_test.dart` | `app/test/platform/` 对应测试 | 只改 import |
| 初次迁移的 `hip-glute-max-a.*`、`hip-flexors-a.*` | `app/assets/drill_media/glute-max-A.*`、`hip-flexors-A.*` | 当时原样复制改名；0.1.1+2 已换为本机高清制作素材，废弃的 `hip-flexors-a.*` 别名已移出包 |

主题（`lib/hip/ui/hip_theme.dart`）本来就是 HipLab 自己的，没有依赖 FlareLab 主题。不带过来的：3D 场景、托马斯资源、FlareLab 的 51 个动作库/肌群图/多语言、`AppLocalizations`。

## 当前素材来源与历史拆仓关系

- **Pose-Hub**：日常动作素材按发布版本提供；当前冻结 **v0.2.0，46条1080视频和46张540封面**。恢复步骤以[文档入口](docs/README.md#新机器拉素材mac--windows)为准；本阶段不改素材版本。
- **HipLab（本仓库）**：App代码、内容包、构建和版本管理；保留自有supine-cross-demo与20张自测静图。
- **3D-Body**：保留拆仓来源、旧高清制作和母版追溯；下方同步段落属于历史，不是当前冻结素材的更新入口。

## 历史同步动作成片（tools/sync_drill_media.py）

以下仅保留2026-10-17旧高清导入过程，不用于日常覆盖Pose-Hub冻结素材。当前新机器按[文档入口](docs/README.md#新机器拉素材mac--windows)恢复素材并 `--check`。历史流程需要 `ffmpeg` / `ffprobe`，默认旧3D-Body和本仓库位于同一上级目录（`../3D-Body`）；当时使用的预览命令为：

```bash
python tools/sync_drill_media.py --copy-ready --force --size 1080 --crf 18 --poster-size 1080 --out E:/AII-3D/3D-Body/output/hiplab-android-20261017-v2 --dry-run
```

它做的事：

1. 从 `--out` 读取本 App 动作及 QA；`--copy-ready` 还校验完整交付清单、来源与文件 SHA。
2. 当时流程将 1080×1080 / 真实 30fps / H.264 CRF18 的主片原字节复制至 `assets/drill_media/hip-<id 小写>.mp4`，不二次压缩；按交付封面时间生成 1080 封面。
3. 自测示范片从长动作里剪（目前：`supine-cross-demo` 取自 `n-leg-circles` 7.2–12 秒）。
4. 更新 `tools/hip_content/source/hip-media.json`（时长、封面时间、来源），把动作表里对应行的「动画状态」标成已有成片。
5. 运行 `tools/hip_content/build_hip_content.py` 重生成 `assets/hip/hip-content.json`。

同步完跑一次 `flutter test`：`test/hip/hip_assets_test.dart` 会检查内容包引用的文件都在、`assets/drill_media/` 里只有 `hip-*` 成对文件。自测对比图（`assets/hip/assessment/`）不归这个脚本管，换图时直接替换同名 webp。

旧转码路径的默认参数仍是 720 / CRF27 / 540 封面，保留源帧时序；`--library` 属于早期迁移兼容功能，会从旧素材库复制，不用于当前高清批次。新批次替换 `--out`，完整步骤和验证见[开发工作流](docs/development-workflow.md)。

## 后续开发

待办统一维护在[开发事项台账](docs/development-roadmap.md)。第一、二轮贡献与当前样式修复已在main集成；D-24代码、网页与Android安装/首页检查完成，隐私页、自测、深色全流程原生复查及iPhone仍待验收。Android前台服务及练习库已随#24/#22合入，分别见D-30/D-29；旧“前台音频待开发”不再作为当前状态。完整训练、音乐ducking、原生首帧、系统通知和CI仍按各自事项与实际未验范围推进；Mac从最新main继续iOS分支验证，不升级素材或依赖，未经新授权不上传商店。
