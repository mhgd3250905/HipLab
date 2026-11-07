# 主线开发工作流

## 2026-11-07 当前开发入口

日常目录`E:/AII-3D/3D-Hip`已切回`main`，接收完整已验收UI、首页卡片/文件夹、英文和友善安全插画。当前`1.1.0+61`/2061，SDK固定`fa957ff405cc57cd10d53987430313822ff20607`；后续从main继续，按任务建分支即可。旧UI和SDK候选分支保留，不再把`feat/ui-detail-polish`当作最新运行源。Flutter仍3.44.7，媒体r2-v1、209授权动作/封面、0内置MP4；依赖只按现有lock恢复。下方2026-11-04 main +34是历史快照。[本轮回执](ui-main-integration-2026-11-07.md)。

## 2026-11-04 当前主线和媒体准备

日常目录main本次文档收束前为2400b34，已含PR26/27/28/30；当前1.1.0+34/2034、四SDK实际包及coach override固定f7b8a8e（v0.7.2内容），Flutter3.44.7。UI r3 Draft PR29仍在候选分支，与SDK问答v3是不同事项；未经真机反馈不按本轮文档整理推进该UI候选合并。

当前新机器使用Git中的`assets/public_media/`、`assets/public_posters/`、`assets/coach/ai-tags/`和pubspec锁文件准备依赖，再按[文档入口](README.md#新机器拉素材mac--windows)执行严格锁解析，保持当前lock的pub.dev源。+34已验证源码0f0882e与功能集成点同树，本次只改文档，不重复测试/构建。0内置MP4，视频由SDK按需缓存；**下方v0.2.0 ZIP同步仅适用于旧分支，不在当前main执行回填**。本页旧版本、安装与工具默认路径描述均按其日期保留；实际操作先核对工作区与显式Flutter入口，不依据历史快照改动环境。

## 2026-10-24 Windows 固定工具入口

本机默认E:/flutter已为3.47.8；HipLab仍按约定使用3.44.7。本轮独立E盘工具入口为 `E:/DevCaches/flutter-3.44.7-hiplab/bin/flutter.bat`，框架84fc5cbb、Dart3.12.2。执行pub get/analyze/test/build时显式用此入口，避免因默认工具变化升级无关hosted依赖；不切换或重置其它项目的工具。当时三个SDK正式tag及该轮直接合main授权见[补丁回执](sdk-tag-patch-2026-10-24.md)。

本仓库 `mhgd3250905/HipLab` 是 HipLab App 主仓库，本工作目录 `E:\AII-3D\3D-Hip` 用于后续 main 主线开发。开始前读[当前状态](current-state.md)和[开发事项](development-roadmap.md)，核对 Git 实际状态。

## 主线基线与更新

历史基线：2026-10-21，训练包及AI新入口已获准合入并推送两个main：HipLab集成点691ace2，SDK d193a70（coach0.1.3/trainer0.1.4）。当前共用版本与手机均为0.3.9+17，构建运行源79c172d，已保留数据安装；锁屏冻结仍已知失败，交用户后测。本次文档收束不重建/重测/操作手机。见[当前交付与合并](android-lockscreen-fix-2026-10-21.md#主线合并确认2026-10-21)及[版本台账](version-ledger.md)。

2026-10-20早间基线（历史）：main已合PR25，0.3.7+12 AI测试包当时仅构建未安装，手机当时为0.3.6+11；见[历史包身份](android-test-build-0.3.7-2026-10-20.md)。下列其他基线段落亦保留各自日期的历史。

此前2026-10-19的main已合入#22/#24及重播hold适配，业务集成点b33ed21；最新实际安装为0.3.6+11 debug arm64 / 9b22dcc（2026-10-19 23:15:53），安装SHA与数据保持已核验。主线运行代码与该已验源一致，沿用387pass/1条件skip、analyze0及本轮原生结果；文档提交不触发新构建或安装。以[当前状态](current-state.md)、[版本台账](version-ledger.md)、[验证台账](verification.md)区分当前事实与逐次交付。

此前阶段基线（历史）：main基线交付为0.3.6+11修复包（运行源`6dd16ed`），PR #17/#18已合入；2026-10-19本轮审阅包运行源`c7def28`同为0.3.6+11，用户报告已安装且简单真机测试通过，三PR及全部修复已按#19→#20→#21顺序合入并推送main（业务集成点b9646d4）。安装反馈和主线状态分别登记；最新事实见[当前状态](current-state.md)及[修复合并记录](pr17-pr18-fixes-and-merge-2026-10-18.md)。下方0.3.0与Pose-Hub v0.1.0段落保留首次集成历史，不代表当前安装或素材版本。

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

新环境先按 [README](README.md#新机器拉素材mac--windows) 核对当前公共元数据和封面，使用指定 SDK 执行 `flutter pub get --enforce-lockfile`；依赖变动由 Windows 统一处理并审阅锁文件；`--no-pub` 只适用于已有依赖解析的环境。两端固定 Flutter 3.44.7 stable / Dart 3.12.2，本轮已对齐 lock；后续 SDK 升级需两端一起进行。Windows 管理 pubspec 依赖和版本号，Mac 不升依赖。

提交前检查 `git diff --check` 与改动范围。PR 写明结果、检查和限制，随后更新对应事项与开发日志。只有状态变化才改当前状态，只有实际交付才追加版本台账。仅文档改动检查事实与链接即可。共用版本、产物来源和各类状态的登记方式见[版本管理说明](version-management.md)。

## 工作副本与产物位置（2026-10-19 起）

本项目新建 worktree、审核/测试克隆和大体积构建产物一律使用非 C 盘；开始任务先盘点已有副本、分支和用途，优先复用合适的非 C 盘副本。新工作副本默认放在 `E:/AII-3D/3D-Hip-worktrees/<task>/3D-Hip`，APK、构建日志、截图录屏及归档交付物默认放在 `E:/AII-3D/hiplab-releases/<task>/`。构建在 E 盘主仓库或 E 盘工作副本中进行，先确认实际构建输出和大体积临时产物的落点。

禁止默认在 C 盘 `.codex/worktrees`、`.config/superpowers/worktrees` 或 Temp 中创建上述副本和产物。调用创建工具前必须确认实际输出路径；若工具不能指定位置，且其存储配置尚未核实，不继续使用会落在 C 盘的默认创建。说明工具限制后，改用显式指定 E 盘路径的 Git 工作副本；不要把目录名、配置猜测或当前聊天的工作目录当成工具输出位置的保证。这里约束后续创建，不改写历史记录中实际使用过的 C 盘路径。

Codex 托管副本整理前，逐项核对对应任务与聊天附件、Git worktree 登记、分支/提交的合并和推送状态、未提交与未跟踪文件，以及忽略目录中的唯一产物。先将需要保留的唯一产物保存到上述 E 盘交付目录并校验，再使用能保持 Git 登记和聊天附件一致的归档流程；归档工具可能不保存忽略文件，不能据“分支已推送”推断本地证据或构建已备份。若现有工具无法维护关联，保留原副本并说明限制，待有一致的处理方式再执行。不得直接拖动、移动或删除托管副本目录来完成迁移或清理。

## 两端分工与授权

Windows 负责 `lib/`、`android/`、`assets/`、`tools/`、`pose-hub.lock.json`、依赖和共用版本；已获直接提交推送 main 的授权，无需新 PR。Mac 负责 `ios/` 及少量 iOS 专属平台代码，从已推送 main 开 `ios/…` 分支并提 PR；不升级依赖、lock 或素材版本。Mac 新机器按 README 当前main流程准备Git元数据、封面和依赖；`--from-dir`恢复与`--check`仅用于需要旧内置视频布局的分支。禁止 force push，保留未提交工作与用户数据。

## 内容与素材

改内容源 `tools/hip_content/source/`，运行 `python tools/hip_content/build_hip_content.py`；不要直接改 `assets/hip/hip-content.json`。逐项媒体来源维护在 `hip-media.json`，不要另建一份人工 47 行来源表。

以下为旧内置媒体分支历史流程，不在当前 main 执行。旧版取用 Pose-Hub v0.2.0，冻结 lock / manifest 仍保留；后续建模、动作、渲染和 QA 在 Pose-Hub 完成，按 [Pose-Hub 接入约定](pose-hub-adoption.md) 同步。当前视频1080、封面540，不改变原ID/文件名；标准顺序如下，使用 README 中已双重校验并解压的 ZIP：

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

debug 安装和商店发布各自登记；0.2.0+4 正式签名 AAB 送 Alpha 是历史记录，iOS 与商店后续状态仍按发布记录维护。本仓库 Android release 缺少 `android/key.properties` 时构建失败，不自动回退 debug 签名；内部测试包须单独核对实际旧包证书（本轮+34基线为+32），不得标成商店上传包。
