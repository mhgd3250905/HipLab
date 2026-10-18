# HipLab 文档与开发台账

本目录是主仓库 `mhgd3250905/HipLab`、本地 `E:\AII-3D\3D-Hip` 的文档入口，后续以 `main` 为开发基线。当前手机为初步媒体版 **0.3.2+7 debug / `963db04`**；业务代码 **`9ef59a1`** 已推送 main，#7/#8/#9/#10 均已确认 MERGED，Pose-Hub **v0.1.0** 已接入。CSS 首帧修复的 analyze、116 项测试、APK 构建和 Chrome 原 H.264 探针通过；手机已拔出，最终修复包未安装，原生首帧待补。六个动作（5 训练 + 90/90 自测）真机循环已有证据；用户已验收 0.3.1+6 单屏 UI。Mac 可从当前 main 开始。0.2.0+4 Alpha 的送审、审核及正式上架单独记录。事实快照日期：2026-10-18，北京时间。

| 文档 | 用途 | 何时更新 |
|---|---|---|
| [主干与 Pose-Hub 集成记录](mainline-pose-hub-2026-10-18.md) | 四个 PR 合并、v0.1.0、最终构建与首帧原生待补边界 | 本轮状态变化后 |
| [第一轮 Android 集成验证](android-round1-integration-2026-10-17.md) | 原三阶段构建、真机及当时待合并边界；最新进展见当前状态 | 保留原阶段证据 |
| [Google Play 送审](play-store-release-2026-10-17.md) | 0.2.0+4 / Submission 1 的历史回执 | Console 实际变化后 |
| [Pose-Hub 接入](pose-hub-adoption.md) | v0.1.0 冻结同步、保留素材及两端边界 | 素材发布或同步时 |
| [当前状态](current-state.md) | 当前 App、分支、PR、环境与完成边界 | 状态实际改变后 |
| [版本交付台账](version-ledger.md) | 每次构建、安装、发布的版本和产物身份 | 产生可交付版本时追加 |
| [验证台账](verification.md) | 哪个版本做过哪些检查，哪些尚未验证 | 完成检查后 |
| [开发事项台账](development-roadmap.md) | 缺陷、后续工作与验收条件 | 开工、受阻或验收时 |
| [开发工作流](development-workflow.md) | 主线集成、日常开发、媒体同步和 Android 更新步骤 | 流程或工具变化时 |
| [开发日志](development-log.md) | 关键决策、成果和对应证据 | 有意义的工作检查点 |
| [iOS 运行与上架](ios-setup-and-release.md) | Mac 上运行/归档步骤、iOS 配置清单、真机确认清单 | iOS 配置或验收变化时 |

开始新一轮开发先读当前状态和开发事项，检查实际 Git 分支，再按工作流推进。仅文档修改不增加 App 版本、不重新安装手机；完成业务改动后按影响范围验证并更新台账。PR 和提交保存代码事实，台账保存交付和验收事实，两者互相链接。

## 证据与历史记录

以下文档保留当时的核查过程；阶段性的“待完成”不代表当前状态。

| 文档 | 范围 |
|---|---|
| [接手基线](project-takeover-2026-10-17.md) | 初始代码、环境、48 项测试与已确认计时缺陷 |
| [媒体初始审计](media-audit-2026-10-17.md) | 制作前缺片、静帧和清晰度问题 |
| [语音播报审计](voice-audit-2026-10-18.md) | 播报中途消失的根因（iOS 会话被提前停用）、素材逐条检测前后对比、真机复听清单 |
| [本地高清制作](local-hd-render-2026-10-17.md) | 4080、PR #119、46 项选版、绿幕/透明母帧与制作过程 |
| [Android 实机记录](android-first-run-2026-10-17.md) | 首次安装及 0.1.1+2 保留数据更新、真机播放证据 |
| [主线集成审核](mainline-integration-2026-10-17.md) | #2、#1 固定版本审核、合并身份和本地对齐 |
| [App Icon 运动方向](app-icon-sports-2026-10-17.md) | D-05 用户新要求、两张候选、选版与安卓接入边界 |
| [早期 MVP 设计](hiplab-mvp-2026-10-16.md) | 从 3D-Body 变体拆仓前的设计背景 |

逐条媒体来源以 [hip-media.json](../tools/hip_content/source/hip-media.json) 为准；[hip-content.json](../assets/hip/hip-content.json) 是生成结果。APK、截图、运行日志与设备数据备份在 Git 忽略目录内；文档中的本机路径不代表这些文件已备份到 GitHub。

## 新机器拉素材（Mac / Windows）

先拉取 HipLab 的最新 `main`，以下命令均在仓库根目录执行。`pose-hub.lock.json` 和 `tools/pose-hub-manifest.json` 已随主线保存，固定 Pose-Hub **v0.1.0**；新机器直接使用这两个文件，不另取最新版 manifest。两端统一 **Flutter 3.44.7 stable**；Mac 不修改 lock、版本号或依赖，后续素材升级由 Windows 维护。

从公开的 [Google Drive v0.1.0 ZIP](https://drive.google.com/file/d/1cukDvVPetojCo-j0zXlP2zC6Wf5rNJB0/view?usp=drivesdk) 下载 `pose-hub-media-v0.1.0.zip`，保存到仓库中的 `build/pose-hub/v0.1.0/`。也可从 [版本分发文件夹](https://drive.google.com/drive/folders/1oNykkilki_VFEGQepDm3IbAdcpw2Zazy) 获取同名文件。使用浏览器下载即可，不需要安装额外下载工具。

ZIP 必须恰为 **40,153,961 bytes**，SHA-256 必须为：

```text
99c6013c4f137e426112db8f46832f2ad2f433ffbd72ff7f1e13670a62867990
```

Mac：先执行下面的校验与解压。任一断言失败会立即停止，不能跳过校验继续解压或同步。

```bash
python3 - <<'PY'
from pathlib import Path
import hashlib
import zipfile
archive = Path("build/pose-hub/v0.1.0/pose-hub-media-v0.1.0.zip")
assert archive.stat().st_size == 40153961, "ZIP size mismatch"
assert hashlib.sha256(archive.read_bytes()).hexdigest() == "99c6013c4f137e426112db8f46832f2ad2f433ffbd72ff7f1e13670a62867990", "ZIP SHA-256 mismatch"
with zipfile.ZipFile(archive) as bundle:
    bundle.extractall("build/pose-hub/v0.1.0/extracted")
print("ZIP verified and extracted")
PY
```

然后按顺序执行；每条命令退出码为 0 后再执行下一条：

```bash
python3 tools/pose_hub_sync.py --lock pose-hub.lock.json --from-dir build/pose-hub/v0.1.0/extracted --dry-run
python3 tools/pose_hub_sync.py --lock pose-hub.lock.json --from-dir build/pose-hub/v0.1.0/extracted
python3 tools/pose_hub_sync.py --lock pose-hub.lock.json --from-dir build/pose-hub/v0.1.0/extracted --check
python3 tools/hip_content/build_hip_content.py
flutter --version
flutter pub get --enforce-lockfile
flutter analyze
flutter test --concurrency=1
```

Windows PowerShell：同样先通过浏览器把 ZIP 放到上述位置，再执行校验与解压：

```powershell
@'
from pathlib import Path
import hashlib
import zipfile
archive = Path("build/pose-hub/v0.1.0/pose-hub-media-v0.1.0.zip")
assert archive.stat().st_size == 40153961, "ZIP size mismatch"
assert hashlib.sha256(archive.read_bytes()).hexdigest() == "99c6013c4f137e426112db8f46832f2ad2f433ffbd72ff7f1e13670a62867990", "ZIP SHA-256 mismatch"
with zipfile.ZipFile(archive) as bundle:
    bundle.extractall("build/pose-hub/v0.1.0/extracted")
print("ZIP verified and extracted")
'@ | python -
```

确认上一条成功后，逐条执行：

```powershell
python tools/pose_hub_sync.py --lock pose-hub.lock.json --from-dir build/pose-hub/v0.1.0/extracted --dry-run
python tools/pose_hub_sync.py --lock pose-hub.lock.json --from-dir build/pose-hub/v0.1.0/extracted
python tools/pose_hub_sync.py --lock pose-hub.lock.json --from-dir build/pose-hub/v0.1.0/extracted --check
python tools/hip_content/build_hip_content.py
flutter --version
flutter pub get --enforce-lockfile
flutter analyze
flutter test --concurrency=1
```

ZIP 根目录直接包含动作 ID 文件夹，例如 `glute-max-A/`，没有额外的 `v0.1.0/` 层。因此 `--from-dir` 必须指向 `build/pose-hub/v0.1.0/extracted` 本身，不能再加版本子目录。ZIP 内没有 manifest；同步工具读取仓库已提交的冻结 manifest。`build/` 已被 Git 忽略，ZIP 和解压目录不提交。

此包只含 46 个动作的 dark 视频和封面，共 92 个文件。`supine-cross-demo` 为 HipLab 自有剪辑，自测 still 保留既有 `assets/hip/assessment/`，light 素材尚未发布；三者均不在此 ZIP 或当前 lock 中，不删除现有资源，浅色主题继续使用深色舞台素材。首次同步用于恢复已冻结的构建资源，不改变素材版本或 ID；`--check` 必须退出 0，内容重生成后如有意外差异，应先核对来源，Mac 不自行修改 lock 或升级依赖。
