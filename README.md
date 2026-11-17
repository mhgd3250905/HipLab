# HipLab · 开胯训练助手

面向久坐人群和舞者的髋部放松、柔韧和主动控制训练。基础训练可离线使用，AI 定制支持联网配置及本地预设回落。

- Android 包名 `com.ugk.hiplab`，iOS Bundle ID `com.ugk.hipinterlude`。
- 支持中英文界面与浅色、深色、跟随系统。界面语言和语音口令语言可各自设置。

## 版本与文档

`main` 是开发基线。当前源码、设备安装和商店渠道分别见[当前状态](docs/current-state.md)，版本号与证据维护规则见[版本管理](docs/version-management.md)。从[文档入口](docs/README.md)进入验证、开发和 UI 资料。

## 构建

使用 Flutter **3.44.7 stable / Dart 3.12.2**，按 `pubspec.lock` 从 `pub.dev` 严格解析。当前 SDK 和素材身份见[版本管理](docs/version-management.md#版本与来源身份)，安装与商店记录见[版本台账](docs/version-ledger.md)。已有依赖解析时可使用 `--no-pub`。

```bash
flutter pub get --enforce-lockfile
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

Android release 构建要求既有 `android/key.properties` 和对应签名材料；缺失时构建失败，不自动退回 debug 签名。内部测试包的签名须与实际旧安装包单独比对，不能把内部测试签名包当作商店上传包。

## 目录

```
lib/main.dart                  入口
lib/hip/domain/                自测/今日训练/疼痛规则，以及练习剂量、自定义训练组和单练历史模型
lib/hip/control/hip_store.dart 本地持久化（SharedPreferences，单 key hiplab.state.v1）
lib/hip/ui/                    首页叠牌/场景文件夹、更多/设置、自测/跟练、记录、动作库与训练组编辑
lib/hip/voice/                 HipLab台词/剂量映射与设置适配；语音队列、时间线执行和音频输出复用ugk_trainer
lib/core/                      公共代码来源见下表；常亮导出及training_service.dart薄适配复用ugk_trainer保活/唯一原生服务
assets/hip/hip-content.json    内容包（脚本生成，不要手改）
assets/hip/posters/            历史原型静帧
assets/hip/assessment/         自测对比图（20 张）
assets/public_media/           当前 SDK 公共目录与训练语义元数据
assets/public_posters/         209 张授权动作封面；r2-v1目录249项，视频由SDK按需获取
assets/drill_media/            历史封面和 WebView 播放器源；当前包不内置 MP4
assets/hip/onboarding/         三张friendly透明卡通安全图；旧六张留源追溯但不入包
assets/voice/                  预生成语音 zh/ en/ chime/ + manifest.json（tools/voice/ 生成）
assets/fonts/NotoSansSC.ttf    字体（OFL）
tools/hip_content/             内容包生成脚本 + 第 0 阶段源文件（动作表 csv、成套训练 md、自测设计 md、hip-media.json）
tools/pose_hub_sync.py         历史冻结 Pose-Hub ZIP 同步（--from-dir / --check）
pose-hub.lock.json             历史冻结 ZIP 的素材版本与目标
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

## 素材

主线从 Git 获取锁定依赖、随包 `r2-v11` 公共目录、248 项封面和缩略图。稳定渠道验证取得 `r2-v16` 后，动作库可使用该目录对应的 SDK 默认缩略图，本地海报作为离线回退，视频由 SDK 按需下载并缓存。
[新机器准备](docs/README.md#新机器拉素材mac--windows)。
