# HipLab · 开胯训练助手

离线的开胯训练 App：围绕髋部的放松、柔韧和主动控制训练。面向久坐人群和舞者，打开就能练，小白也能上手。和「托马斯训练助手 FlareLab」同一家族（石墨底 + 青玉 `#3ccfa4`），但是独立 App、独立仓库。

- Android applicationId / iOS bundle id：`com.ugk.hiplab`
- App 名：开胯训练助手（iOS `CFBundleName` 为 HipLab）
- Dart ^3.12.2；本机已验证 Flutter 3.44.7，原迁移 PR 声明 3.47.7，团队 SDK 尚待统一。只支持 Android / iOS，目前中文、深色

后续在本目录进行 main 主线开发，文档统一从 **[文档与开发台账](docs/README.md)** 进入：[当前状态](docs/current-state.md)、[版本交付](docs/version-ledger.md)、[验证记录](docs/verification.md)、[开发事项](docs/development-roadmap.md)、[工作流](docs/development-workflow.md)。台账快照日期为 2026-10-17。

本仓库是 **HipLab App 主仓库，`main` 为开发基线**。[PR #2](https://github.com/mhgd3250905/HipLab/pull/2) 和 [PR #1](https://github.com/mhgd3250905/HipLab/pull/1) 已审核合并，App、高清素材和台账均已集成至 main；审核与提交身份见[主线集成记录](docs/mainline-integration-2026-10-17.md)。手机安装版本与 Git 提交分别登记。

Android 16 真机现已保留数据更新至 **0.1.2+3**，采用用户选定的青玉绿「站姿开髋」图标，已查看桌面确认。原有 46 项动作视频、专用自测剪辑及 47 张 1080 封面保持；6 项自测均为视频。当前构建/安装见[版本台账](docs/version-ledger.md)，高清媒体实机证据保留在 [Android 运行记录](docs/android-first-run-2026-10-17.md)。

制作前的视频缺口、清晰度和模型/动画源核对保留在 [媒体初始审计](docs/media-audit-2026-10-17.md)，其中缺片状态已由本轮高清交付解决。

PR #119 已审核合并，本机 4080 制作及三项动作修订已完成。绿幕、透明母帧与当前深色 App 播放版本的来源和检查见 [本地制作记录](docs/local-hd-render-2026-10-17.md)。

## 构建

本机现有依赖缓存的验证命令使用 `--no-pub`，见[工作流](docs/development-workflow.md)。新环境先明确 Flutter SDK，再获取依赖并审阅锁文件差异；下方为通用构建命令。Android 已验证 debug，iOS、正式签名和商店发布尚未验收。

```bash
flutter pub get
flutter analyze
flutter test                                   # 单元 + 界面流程 + 资源边界测试
flutter test test_screens/hip_shots_test.dart  # 可选：4 张 390×844 截图 → test/_shots/hip/（不提交）

flutter run
flutter build apk --release                    # → com.ugk.hiplab
flutter build appbundle --release
flutter build ios --release --no-codesign      # 签名团队需在 Xcode 里自己选
```

Android release 签名：有 `android/key.properties` 就用它，没有时退回 debug 签名（和 3D-Body 的做法一样）。

## 目录

```
lib/main.dart                  入口
lib/hip/domain/                纯规则（自测计分、今日训练、疼痛阶梯、连续天数、提醒时间表），全部单测
lib/hip/control/hip_store.dart 本地持久化（SharedPreferences，单 key hiplab.state.v1）
lib/hip/ui/                    安全图卡/身份 → 首页 → 自测 → 结果 → 跟练播放器 → 进度/设置
lib/core/                      从 3D-Body 复制来的公共代码（见下表）
assets/hip/hip-content.json    内容包（脚本生成，不要手改）
assets/hip/posters/            历史原型静帧（当前 46 项动作均已接入视频）
assets/hip/assessment/         自测对比图（20 张）
assets/drill_media/            动作成片 hip-<id>.mp4 + .jpg，以及 WebView 播放器 player.html/js/css
assets/fonts/NotoSansSC.ttf    字体（OFL）
tools/hip_content/             内容包生成脚本 + 第 0 阶段源文件（动作表 csv、成套训练 md、自测设计 md、hip-media.json）
tools/sync_drill_media.py      从 3D-Body drill-anim 同步成片并重生成内容包
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

## 和 3D-Body 的分工

- **3D-Body**：动作动画的制作和渲染（`tools/drill-anim`，方案 B `themes/glow-b.json`），动作源文件和 SHA 登记也在那里提 PR。FlareLab App 继续在 3D-Body。
- **HipLab（本仓库）**：App 代码、内容包、打包发布。成片通过下面的同步脚本拿过来，不在这里渲染。

## 同步动作成片（tools/sync_drill_media.py）

需要 `ffmpeg` / `ffprobe`。默认 3D-Body 和本仓库放在同一个上级目录（`../3D-Body`）。当前高清流程从已验收 Android 派生批次导入，先预览，再移除 `--dry-run` 执行：

```bash
python tools/sync_drill_media.py --copy-ready --force --size 1080 --crf 18 --poster-size 1080 --out E:/AII-3D/3D-Body/output/hiplab-android-20261017-v2 --dry-run
```

它做的事：

1. 从 `--out` 读取本 App 动作及 QA；`--copy-ready` 还校验完整交付清单、来源与文件 SHA。
2. 当前流程将 1080×1080 / 真实 30fps / H.264 CRF18 的主片原字节复制至 `assets/drill_media/hip-<id 小写>.mp4`，不二次压缩；按交付封面时间生成 1080 封面。
3. 自测示范片从长动作里剪（目前：`supine-cross-demo` 取自 `n-leg-circles` 7.2–12 秒）。
4. 更新 `tools/hip_content/source/hip-media.json`（时长、封面时间、来源），把动作表里对应行的「动画状态」标成已有成片。
5. 运行 `tools/hip_content/build_hip_content.py` 重生成 `assets/hip/hip-content.json`。

同步完跑一次 `flutter test`：`test/hip/hip_assets_test.dart` 会检查内容包引用的文件都在、`assets/drill_media/` 里只有 `hip-*` 成对文件。自测对比图（`assets/hip/assessment/`）不归这个脚本管，换图时直接替换同名 webp。

旧转码路径的默认参数仍是 720 / CRF27 / 540 封面，保留源帧时序；`--library` 属于早期迁移兼容功能，会从旧素材库复制，不用于当前高清批次。新批次替换 `--out`，完整步骤和验证见[开发工作流](docs/development-workflow.md)。

## 后续开发

待办统一维护在[开发事项台账](docs/development-roadmap.md)。当前优先处理紧侧加练计时分配缺陷和全量真机体验验收；系统通知、正式发布签名、iOS、CI 与主题适配仍待推进。主线集成、46 项动作高清交付、Android 正式图标与 0.1.2+3 安装已完成。
