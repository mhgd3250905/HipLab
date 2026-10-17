# HipLab · 开胯训练助手

离线的开胯训练 App：围绕髋部的放松、柔韧和主动控制训练。面向久坐人群和舞者，打开就能练，小白也能上手。和「托马斯训练助手 FlareLab」同一家族（石墨底 + 青玉 `#3ccfa4`），但是独立 App、独立仓库。

- Android applicationId / iOS bundle id：`com.ugk.hiplab`
- App 名：开胯训练助手（iOS `CFBundleName` 为 HipLab）
- Flutter 3.47.x（Dart ^3.12.2），只支持 Android / iOS，只做中文、深色

本地接手与验证记录见 [2026-10-17 接手基线](docs/project-takeover-2026-10-17.md)，包含实际测试结果、SDK 差异、已确认问题与后续顺序。

已完成 Android 16 真机调试版安装与启动，产物和复现方式见 [Android 首次运行记录](docs/android-first-run-2026-10-17.md)。

视频缺口、清晰度和模型/动画源的逐项核对见 [媒体交付核对](docs/media-audit-2026-10-17.md)。

## 构建

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
assets/hip/posters/            原型静帧（还没成片的动作用）
assets/hip/assessment/         自测对比图（20 张）
assets/drill_media/            动作成片 hip-<id>.mp4 + .jpg，以及 WebView 播放器 player.html/js/css
assets/fonts/NotoSansSC.ttf    字体（OFL）
tools/hip_content/             内容包生成脚本 + 第 0 阶段源文件（动作表 csv、成套训练 md、自测设计 md、hip-media.json）
tools/sync_drill_media.py      从 3D-Body drill-anim 同步成片并重生成内容包
test/hip/                      规则 / 界面流程 / 资源边界测试
test/core/                     公共代码的测试（随代码一起复制）
docs/                          设计与 MVP 说明
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
| `assets/drill_media/hip-glute-max-a.*`、`hip-flexors-a.*` | `app/assets/drill_media/glute-max-A.*`、`hip-flexors-A.*` | 原样复制、改名 |

主题（`lib/hip/ui/hip_theme.dart`）本来就是 HipLab 自己的，没有依赖 FlareLab 主题。不带过来的：3D 场景、托马斯资源、FlareLab 的 51 个动作库/肌群图/多语言、`AppLocalizations`。

## 和 3D-Body 的分工

- **3D-Body**：动作动画的制作和渲染（`tools/drill-anim`，方案 B `themes/glow-b.json`），动作源文件和 SHA 登记也在那里提 PR。FlareLab App 继续在 3D-Body。
- **HipLab（本仓库）**：App 代码、内容包、打包发布。成片通过下面的同步脚本拿过来，不在这里渲染。

## 同步动作成片（tools/sync_drill_media.py）

需要 `ffmpeg` / `ffprobe`。默认 3D-Body 和本仓库放在同一个上级目录（`../3D-Body`）。

```bash
python3 tools/sync_drill_media.py --dry-run                      # 先看会改什么
python3 tools/sync_drill_media.py                                # 用 ../3D-Body/tools/drill-anim/out
python3 tools/sync_drill_media.py --threed-body D:/src/3D-Body   # 别的位置
python3 tools/sync_drill_media.py --out D:/renders/out --ids n-prone-ir s-pigeon
python3 tools/sync_drill_media.py --library                      # 顺带刷新两条 FlareLab 库成片
```

它做的事：

1. 在 drill-anim 的 `out/` 里找本 App 动作表（`tools/hip_content/source/髋部动作表.csv`）里有的动作 `<id>.mp4`，并且 `out/metrics/<id>.json` 是 qa PASS 的；其他（包括 FlareLab 的渲染）一律跳过。
2. 转码成 `assets/drill_media/hip-<id 小写>.mp4`（720×720、30fps、H.264 CRF 27、faststart、无音轨），按动作 spec 的 `stillAt` 截 540×540 封面 `.jpg`。App 里的文件比渲染新时不重转，`--force` 强制。
3. 自测示范片从长动作里剪（目前：`supine-cross-demo` 取自 `n-leg-circles` 7.2–12 秒）。
4. 更新 `tools/hip_content/source/hip-media.json`（时长、封面时间、来源），把动作表里对应行的「动画状态」标成已有成片。
5. 运行 `tools/hip_content/build_hip_content.py` 重生成 `assets/hip/hip-content.json`。

同步完跑一次 `flutter test`：`test/hip/hip_assets_test.dart` 会检查内容包引用的文件都在、`assets/drill_media/` 里只有 `hip-*` 成对文件。自测对比图（`assets/hip/assessment/`）不归这个脚本管，换图时直接替换同名 webp。

## 待办

- 久坐提醒的系统通知插件（`ReminderScheduler` 接口已留好，目前只记录时间表）
- 正式 App 图标（现在 Android/iOS 用的是占位图标，iOS 由 192px 图放大）
- iOS 签名团队、App Store 信息（以后可用 Hip Interlude 的名额）
- CI
- 18 个动作还没有成片（显示「动画待渲染」），9 个用原型静帧
- 字体 Noto Sans SC 17 MB，可以按用到的字做子集瘦身
