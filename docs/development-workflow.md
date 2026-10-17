# 主线开发工作流

本仓库 `mhgd3250905/HipLab` 是 HipLab App 主仓库，本工作目录 `E:\AII-3D\3D-Hip` 用于后续 main 主线开发。开始前读[当前状态](current-state.md)和[开发事项](development-roadmap.md)，核对 Git 实际状态。

## 主线基线与更新

2026-10-17 已按用户明确授权完成 HipLab #2 → `feat/initial-migration`、#1 → main 的审核合并，首次业务集成提交 `656ee28`，来源与验证见[集成记录](mainline-integration-2026-10-17.md)。本地 main 已跟踪 origin/main，App 与制作成果不再停留在迁移分支。

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

从同步后的 main 建功能/修复分支，按事项 ID 记录目标与验收条件。遵循 [AGENTS.md](../AGENTS.md) 的分支 + PR 约定，由仓库主人审核合并或按其明确授权由代理执行。已有明确授权不重复询问，执行前仍核对目标和版本。

Dart 改动完成后运行 analyze 和 test，必要时做真机验证。当前本机解析缓存已可运行：

```powershell
flutter analyze --no-pub
flutter test --no-pub
```

新环境或依赖变动时先选择 SDK、执行 `flutter pub get` 并审阅锁文件；`--no-pub` 只适用于已有依赖解析的环境。实际验收 SDK 3.44.7 与源 PR 3.47.7 差异详见当前状态，不在日常功能修复中顺带升级或提交降级。

提交前检查 `git diff --check` 与改动范围。PR 写明结果、检查和限制，随后更新对应事项与开发日志。只有状态变化才改当前状态，只有实际交付才追加版本台账。仅文档改动检查事实与链接即可。

## 内容与素材

改内容源 `tools/hip_content/source/`，运行 `python tools/hip_content/build_hip_content.py`；不要直接改 `assets/hip/hip-content.json`。逐项媒体来源维护在 `hip-media.json`，不要另建一份人工 47 行来源表。

建模、动作、渲染和 QA 在 3D-Body 完成。新修订用独立源和新输出目录，保留旧规格、模型、检查器与输出；最多两路 3D 渲染、每路 jobs 1。当前配方和三项修订见制作副本 `tools/hiplab-render/` 和[制作记录](local-hd-render-2026-10-17.md)。

当前高清交付推荐按已完成的 Android 派生片原字节导入，先预览：

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

debug 安装和商店发布各自登记；正式签名、AAB、iOS 和商店资料仍见待办。没有正式签名配置时 Android release 会退回 debug 签名，不得把这种产物标成正式上架包。
