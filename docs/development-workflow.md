# 主线开发工作流

## UI实现与文档维护

设计数值由[UI规范](ui-design-standard.md)维护；实现、依赖边界、跨App配方及完整画廊见[UI复用手册](ui-kit/README.md)。代码/设计变动时同步规范与对应样例，历史交付报告只追加事实，不把已淘汰方案当作当前接入方式。文档收束仅检查相关事实、链接、示例与diff；不因整理文档重复构建或增加版本。历史 UI 阶段见[收束报告](ui-documentation-closeout-2026-11-07.md)。

## 工作区与版本

`main` 是开发基线。先核对工作树、分支和 HEAD，再查[当前状态](current-state.md)和[版本台账](version-ledger.md)。素材准备见[文档入口](README.md#新机器拉素材mac--windows)。

Windows 固定 Flutter 3.44.7 入口为 `E:/DevCaches/flutter-3.44.7-hiplab/bin/flutter.bat`，Mac 也使用 3.44.7。

旧版主线协作和工具快照见[历史工作流](https://github.com/mhgd3250905/HipLab/blob/ba0d0c16ae56d7b679572be3a380969f0679b2dd/docs/development-workflow.md)。

## 主线基线与更新

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

Dart 改动完成后运行 analyze 和 test，必要时做真机验证。已有依赖解析缓存时可执行：

```powershell
flutter analyze --no-pub
flutter test --no-pub --concurrency=1
```

新环境从 Git 恢复随包目录、静态图和依赖锁，再按文档入口执行严格依赖解析。已有依赖解析时可用 `--no-pub`。依赖变动由 Windows 统一审阅，两端使用同一 Flutter 版本与锁文件。[新机器准备](README.md#新机器拉素材mac--windows)

提交前检查 `git diff --check` 与改动范围。PR 写明结果、检查和限制，随后更新对应事项与开发日志。只有状态变化才改当前状态，只有实际交付才追加版本台账。仅文档改动检查事实与链接即可。共用版本、产物来源和各类状态的登记方式见[版本管理说明](version-management.md)。

## 工作副本与产物位置（2026-10-19 起）

本项目新建 worktree、审核/测试克隆和大体积构建产物一律使用非 C 盘；开始任务先盘点已有副本、分支和用途，优先复用合适的非 C 盘副本。新工作副本默认放在 `E:/AII-3D/3D-Hip-worktrees/<task>/3D-Hip`，APK、构建日志、截图录屏及归档交付物默认放在 `E:/AII-3D/hiplab-releases/<task>/`。构建在 E 盘主仓库或 E 盘工作副本中进行，先确认实际构建输出和大体积临时产物的落点。

禁止默认在 C 盘 `.codex/worktrees`、`.config/superpowers/worktrees` 或 Temp 中创建上述副本和产物。调用创建工具前必须确认实际输出路径；若工具不能指定位置，且其存储配置尚未核实，不继续使用会落在 C 盘的默认创建。说明工具限制后，改用显式指定 E 盘路径的 Git 工作副本；不要把目录名、配置猜测或当前聊天的工作目录当成工具输出位置的保证。这里约束后续创建，不改写历史记录中实际使用过的 C 盘路径。

Codex 托管副本整理前，逐项核对对应任务与聊天附件、Git worktree 登记、分支/提交的合并和推送状态、未提交与未跟踪文件，以及忽略目录中的唯一产物。先将需要保留的唯一产物保存到上述 E 盘交付目录并校验，再使用能保持 Git 登记和聊天附件一致的归档流程；归档工具可能不保存忽略文件，不能据“分支已推送”推断本地证据或构建已备份。若现有工具无法维护关联，保留原副本并说明限制，待有一致的处理方式再执行。不得直接拖动、移动或删除托管副本目录来完成迁移或清理。

## 两端分工与授权

Windows 负责 `lib/`、`android/`、`assets/`、`tools/`、`pose-hub.lock.json`、依赖和共用版本；已获直接提交推送 main 的授权，无需新 PR。Mac 负责 `ios/` 及少量 iOS 专属平台代码，从已推送 main 开 `ios/…` 分支并提 PR；不升级依赖、lock 或素材版本。Mac 新机器按 README 当前main流程准备Git元数据、封面和依赖；`--from-dir`恢复与`--check`仅用于需要旧内置视频布局的分支。禁止 force push，保留未提交工作与用户数据。

## 内容与素材

改内容源 `tools/hip_content/source/`，运行 `python tools/hip_content/build_hip_content.py`；不要直接改 `assets/hip/hip-content.json`。逐项媒体来源维护在 `hip-media.json`，不要另建一份人工 47 行来源表。

主线在 Git 中维护随包目录、语义、封面、缩略图和站位图。发布素材按已经审核的 Pose-Hub 版本和目录 SHA-256 对齐。随包基线用于离线回退，在线展示素材由 SDK 验证后一起切换。源问题在 Pose-Hub 对应动作上解决。[新机器准备](README.md#新机器拉素材mac--windows)

### 3D-Body 同步旧流程（历史兼容，不用于日常更新）

旧 ZIP 和 3D-Body 导入命令已归入历史工作流，可按对应旧分支回溯。[Pose-Hub ZIP 恢复](README.md#冻结-v020-zip-恢复仅旧分支历史) · [旧导入及 QA 记录](https://github.com/mhgd3250905/HipLab/blob/60b16181e9d0002b9a8f44404db728df74fb5bef/docs/development-workflow.md#3d-body-同步旧流程历史兼容不用于日常更新)

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

安装和商店发布按[版本台账](version-ledger.md)分别登记。Android release 使用配置的发布签名，内部测试 APK 覆盖前核对实际旧安装包证书。
