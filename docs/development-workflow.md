# 主线开发工作流

本仓库 `mhgd3250905/HipLab` 是 HipLab App 主仓库，本工作目录 `E:\AII-3D\3D-Hip` 用于后续 main 主线开发。开始前读[当前状态](current-state.md)和[开发事项](development-roadmap.md)，核对 Git 实际状态。

## 主线基线与更新

当前App交付为0.3.6+11（源码`66f5da0`），2026-10-18 19:29已保留数据安装；最新事实以[当前状态](current-state.md)和[版本台账](version-ledger.md)为准。下方0.3.0与Pose-Hub v0.1.0段落保留首次集成历史，不代表当前安装或媒体版本。

2026-10-17 已按用户明确授权完成 HipLab #2 → `feat/initial-migration`、#1 → main 的审核合并，首次业务集成提交 `656ee28`，来源与验证见[集成记录](mainline-integration-2026-10-17.md)。本地 main 已跟踪 origin/main，App 与制作成果不再停留在迁移分支。

2026-10-18，main 已顺序集成 #7/#8/#9 及 rebased #10，并接入 Pose-Hub v0.1.0；业务代码 `9ef59a1` 已推送 origin/main，GitHub 确认四个 PR 均 MERGED。CSS 首帧修复已通过 Chrome 原 H.264 探针和构建检查，最终 APK 未重新安装手机，原生首帧复验仍待补。Windows 主干线按用户明确授权验证后直接提交推送 main，无需新 PR；Mac 和其他贡献方仍用分支 + PR。

本地 fetch 为 `+refs/heads/*:refs/remotes/origin/*`。工作区干净时更新主线：

```powershell
git status --short --branch
git fetch origin
git log -5 --oneline origin/main
git switch main
git pull --ff-only
```

不要 reset、丢弃未提交工作或强推；如 `--ff-only` 失败，先检查本地与远端分叉，不自动覆盖任何一方。合并后回读 PR 状态与 main SHA并更新台账。

## 日常开发

Windows 主干线可在 main 推进已授权工作，按事项 ID 记录目标、验收和检查结果，验证后直接提交推送。其他贡献方从同步后的 main 建分支并提 PR，由主干线审核集成，遵循 [AGENTS.md](../AGENTS.md)。已有明确授权不重复询问，执行前仍核对目标和版本。

Dart 改动完成后运行 analyze 和 test，必要时做真机验证。当前本机解析缓存已可运行：

```powershell
flutter analyze --no-pub
flutter test --no-pub --concurrency=1
```

新环境先按 [README](README.md#新机器拉素材mac--windows) 恢复冻结媒体，使用指定 SDK 执行 `flutter pub get --enforce-lockfile`；依赖变动由 Windows 统一处理并审阅锁文件；`--no-pub` 只适用于已有依赖解析的环境。两端固定 Flutter 3.44.7 stable / Dart 3.12.2，本轮已对齐 lock；后续 SDK 升级需两端一起进行。Windows 管理 pubspec 依赖和版本号，Mac 不升依赖。

提交前检查 `git diff --check` 与改动范围。PR 写明结果、检查和限制，随后更新对应事项与开发日志。只有状态变化才改当前状态，只有实际交付才追加版本台账。仅文档改动检查事实与链接即可。

## 两端分工与授权

Windows 负责 `lib/`、`android/`、`assets/`、`tools/`、`pose-hub.lock.json`、依赖和共用版本；已获直接提交推送 main 的授权，无需新 PR。Mac 负责 `ios/` 及少量 iOS 专属平台代码，从已推送 main 开 `ios/…` 分支并提 PR；不升级依赖、lock 或素材版本。Mac 新机器允许按 README 用 `--from-dir` 恢复冻结资源并 `--check`。禁止 force push，保留未提交工作与用户数据。

## 内容与素材

改内容源 `tools/hip_content/source/`，运行 `python tools/hip_content/build_hip_content.py`；不要直接改 `assets/hip/hip-content.json`。逐项媒体来源维护在 `hip-media.json`，不要另建一份人工 47 行来源表。

当前取用 Pose-Hub v0.2.0，冻结 lock / manifest 随 main 保存；后续建模、动作、渲染和 QA 在 Pose-Hub 完成，按 [Pose-Hub 接入约定](pose-hub-adoption.md) 同步。当前视频1080、封面540，不改变原ID/文件名；标准顺序如下，使用 README 中已双重校验并解压的 ZIP：

```powershell
python tools/pose_hub_sync.py --lock pose-hub.lock.json --from-dir build/pose-hub/v0.2.0/extracted --dry-run
python tools/pose_hub_sync.py --lock pose-hub.lock.json --from-dir build/pose-hub/v0.2.0/extracted
python tools/pose_hub_sync.py --lock pose-hub.lock.json --from-dir build/pose-hub/v0.2.0/extracted --check
python tools/hip_content/build_hip_content.py
```

每步退出码为 0 后再继续。保留自有剪辑和既有 still，不从 ZIP 臆造 light 资源。

### 3D-Body 同步旧流程（历史兼容，不用于日常更新）

以下旧流程仅保留作历史追溯，不自动导入新批次。历史上：建模、动作、渲染和 QA 在 3D-Body 完成。新修订用独立源和新输出目录，保留旧规格、模型、检查器与输出；最多两路 3D 渲染、每路 jobs 1。当前配方和三项修订见制作副本 `tools/hiplab-render/` 和[制作记录](local-hd-render-2026-10-17.md)。

历史高清交付曾按已完成的 Android 派生片原字节导入，预览命令如下：

```powershell
python tools/sync_drill_media.py --copy-ready --force --size 1080 --crf 18 --poster-size 1080 --out E:/AII-3D/3D-Body/output/hiplab-android-20261017-v2 --dry-run
```

核对批次、来源和 QA 后移除 `--dry-run` 执行同一命令，再检查内容和差异，运行 `python -m unittest discover -s tools/tests` 与 Flutter 测试。导入其他新批次时替换 `--out`，不要把当前批次名当成永远固定的最新版。

`--copy-ready` 验证交付清单、参数、QA 与 SHA，46 条主片不二次压缩，自测专用剪辑单独生成。旧转码路径默认仍为 720 / CRF27 / 540 封面并保留源帧时序；不能省略参数后声称高清导入。`--library` 是早期迁移兼容项，会从旧 App 库复制素材，不用于当前高清批次。

绿幕和透明帧是后续合成母版；当前 App 不直接播放绿幕。生成输出未入 Git，保留制作副本和母版目录；如需清理，先核对可恢复的备份。

## 更新 Android

完成相关检查后再构建并覆盖安装；保持包名与签名连续，不清 App 数据。设备序列号使用 `adb devices` 实际返回值。

```powershell
flutter devices
flutter build apk --debug --no-pub
Get-FileHash build/app/outputs/flutter-apk/app-debug.apk -Algorithm SHA256
adb devices
$deviceSerial = '替换为 adb devices 返回的序列号'
adb -s $deviceSerial install -r build/app/outputs/flutter-apk/app-debug.apk
```

安装前保留旧 APK 和必要的数据备份，安装后回读包版本、冷启动并检查本轮受影响功能，涉及媒体则验证原生视频播放。记录 APK 字节数/SHA、代码提交、设备、数据保持结果与证据目录到版本/验证台账。用户数据备份、密钥、截图日志留忽略目录，不提交仓库。

debug 安装和商店发布各自登记；0.2.0+4 正式签名 AAB 已送 Alpha 审核，iOS 构建与正式发布仍见待办。没有正式签名配置时 Android release 会退回 debug 签名，不得把这种产物标成正式上架包。
