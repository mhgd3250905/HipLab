# HipLab · 开胯训练助手

离线的开胯训练 App：围绕髋部的放松、柔韧和主动控制训练。面向久坐人群和舞者，打开就能练，小白也能上手。和「托马斯训练助手 FlareLab」同一家族（石墨底 + 青玉 `#3ccfa4`），但是独立 App、独立仓库。

- Android applicationId / iOS bundle id：`com.ugk.hiplab`
- App 名：开胯训练助手（iOS 英文系统显示 HipLab，`CFBundleName` 为 HipLab）
- Dart ^3.12.2；两端统一 Flutter **3.44.7 stable**。只支持 Android / iOS，中文界面；浅色/深色/跟随系统主题，中英语音播报（`feat/polish-round1` 起）

后续在本目录进行 main 主线开发，文档统一从 **[文档与开发台账](docs/README.md)** 进入：[当前状态](docs/current-state.md)、[版本交付](docs/version-ledger.md)、[验证记录](docs/verification.md)、[开发事项](docs/development-roadmap.md)、[工作流](docs/development-workflow.md)。当前状态核对日期为 **2026-10-18**；按页内日期保留历史交付与验证。

本仓库是 **HipLab App 主仓库，`main` 为开发基线**。[PR #2](https://github.com/mhgd3250905/HipLab/pull/2) 和 [PR #1](https://github.com/mhgd3250905/HipLab/pull/1) 已审核合并，App、高清素材和台账均已集成至 main；审核与提交身份见[主线集成记录](docs/mainline-integration-2026-10-17.md)。手机安装版本与 Git 提交分别登记。

Android 16 真机当前已保留数据更新至 **0.3.6+11 debug / arm64**，业务源码 `66f5da034c0cdac3341f3e80a57e3ddae5f95dce`。本次补齐浅色首页浮起滑块、绿色小字、运动说明和隐私页共用顶栏；19:29冷启动首页及浅色滑块已查看，安装/启动后1356字节偏好保持。检查、APK身份和安装边界见[样式修复与安装记录](docs/theme-polish-2026-10-18.md)、[版本台账](docs/version-ledger.md)。0.3.5+10静音模式试听的用户确认保留为历史，本版未重新做完整听音。

制作前的视频缺口、清晰度和模型/动画源核对保留在 [媒体初始审计](docs/media-audit-2026-10-17.md)，其中缺片状态已由本轮高清交付解决。

PR #119 已审核合并，本机 4080 制作及三项动作修订已完成。绿幕、透明母帧与当前深色 App 播放版本的来源和检查见 [本地制作记录](docs/local-hd-render-2026-10-17.md)。

## 构建

本机现有依赖缓存的验证命令使用 `--no-pub`，见[工作流](docs/development-workflow.md)。本轮 Android analyze 0问题、158项测试通过/1条件跳过，debug arm64 APK已构建并安装；网页四尺寸复查仅证明布局，完整训练、原生视频/系统音频仍需单独验收。iOS 0.3.6+11 候选已完成签名 Release/Archive、保留数据安装及基础真机检查，完整系统矩阵仍待验，见[iOS 本轮记录](docs/ios-main-ui-036-2026-10-18.md)。0.2.0+4的Alpha送审回执属于2026-10-17历史，本次未回读Console、未上传任何商店；见[送审记录](docs/play-store-release-2026-10-17.md)。下列为通用构建命令，不代表本次执行发布。

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
lib/hip/domain/                纯规则（自测计分、今日训练、疼痛阶梯、连续天数、提醒时间表），全部单测
lib/hip/control/hip_store.dart 本地持久化（SharedPreferences，单 key hiplab.state.v1）
lib/hip/ui/                    安全图卡/身份 → 首页 → 自测 → 结果 → 跟练播放器 → 进度/设置
lib/hip/voice/                 语音播报：会话阶段/台词时间线、播放队列、just_audio 输出（ducking、iOS 后台保活）
lib/core/                      从 3D-Body 复制来的公共代码（见下表）；lib/core/platform/screen_awake.dart 会话期间屏幕常亮
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

待办统一维护在[开发事项台账](docs/development-roadmap.md)。第一、二轮贡献与当前样式修复已在main集成；D-24代码、网页与Android安装/首页检查完成，Android隐私页、自测、深色全流程原生复查仍待验收。iPhone基础检查已补，iOS平台适配在PR #16待主线审核；完整系统矩阵及后续共用UI集成复验列D-26。完整训练、音乐ducking、原生首帧、Android前台音频、系统通知和CI仍按各自事项推进；Mac从最新main继续iOS分支验证，不升级素材或依赖，未经新授权不上传商店。
