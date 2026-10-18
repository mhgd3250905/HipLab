# Pose-Hub 素材接入约定

更新日期：2026-10-18。HipLab 只有 [mhgd3250905/HipLab](https://github.com/mhgd3250905/HipLab) 一个 App 仓库，包含 Android 和 iOS；动作由 [3D-Pose-Hub](https://github.com/mhgd3250905/3D-Pose-Hub) 发布，App 按冻结版本取用。

## 当前接入：v0.2.0

Pose-Hub v0.2.0，视频 1080² / 封面 540²，46 个原 ID 与文件名保持。App 0.3.4+9，源码 `03c3b5bcd1ebc0157e3789af21a4bf0188f52468`，已构建但未安装；业务代码 `03c3b5bcd1ebc0157e3789af21a4bf0188f52468` 已于 2026-10-18 11:40 北京时间推送 main。手机仍为 `963db04` / 0.3.2+7，本轮无 ADB 或商店操作。

上游固定 `59fb7b9c68867ef57ff6d2fe5c8b72da3022fac4`；1080 dark视频、540 JPG封面，同46个ID及文件名。新机器步骤见 [README](README.md#新机器拉素材mac--windows)，`--from-dir build/pose-hub/v0.2.0/extracted`；ZIP根直接ID文件夹。自有supine-cross-demo与20张still、旧母版/QA保留，light不在包内。同步结果：dry-run 92项计划；首次92 copied；check 92 matched /0 drift；重复同步0 copied。[Pose-Hub v0.2.0 接入](posehub-v020-integration-2026-10-18.md)。

## v0.1.0 首次接入（历史，已由 v0.2.0 接续）

首版已发布，HipLab `963db04` 完成素材接入，后续 CSS 修复 `9ef59a1` 已随 main 推送：`pose-hub.lock.json` 固定 0.1.0，`tools/pose-hub-manifest.json` 保存发布清单，`tools/pose_hub_sync.py` 头部记录上游来源 commit。分发采用公开 Google Drive ZIP；当时的下载链接、40,153,961 bytes / SHA-256 断言与 Mac/Windows 命令保存在 [v0.1.0 阶段 README](https://github.com/mhgd3250905/HipLab/blob/bb828be30a6d3631538fc732154c5985c44ef2f8/docs/README.md#新机器拉素材mac--windows)；当前 README 已切为 v0.2.0。先校验 ZIP 再解压到 `build/pose-hub/v0.1.0/extracted`，按 `--from-dir` dry-run → 同步 → `--check` 执行；ZIP 根直接是动作 ID 文件夹，没有额外版本层。缓存与解压目录受 Git 忽略。

本版同步 46 项 dark 视频和封面，共 92 文件。92 文件 check、46 条 ffprobe、22 个保留文件及 APK 内容检查通过；六个动作（5 训练 + 90/90 自测）真机循环已有证据。逐帧均有 0.08–0.25 秒淡入变暗，`9ef59a1` 去除 CSS 双重淡入后已通过 Chrome 原 H.264 新旧对照、循环和暂停恢复，但用户已拔出手机，最终 APK 只构建、未安装，Android 原生首帧待补。接入已完成，不等于全量体验验收；具体结果见[版本台账](version-ledger.md)、[验证台账](verification.md)及[主干集成记录](mainline-pose-hub-2026-10-18.md)。

`supine-cross-demo` 是 HipLab 自有剪辑，继续保留且不进 lock；20 张既有自测 still（含 #8 修订）继续保留，未包含在本版 ZIP；light 尚未发布，浅色主题仍用深色舞台。不删除旧母版、冻结规格、模型或 QA。旧 `tools/sync_drill_media.py` 仅保留历史兼容，不能作为新素材的日常来源。

Windows 维护媒体版本、lock、清单、依赖和共用版本号。Mac 新机器可用冻结 lock 执行 `sync --from-dir` / `--check` 恢复已发布资源，不自行升级素材或依赖。后续发布由 Windows 更新 lock / manifest、同步并验证，按用户已授权的主干流程提交；姿态、脚向、高亮与渲染问题到 Pose-Hub 提 issue，写明 App、动作 ID、问题及期望，不在 HipLab 重渲。

## 首版发布前的准备计划（2026-10-17，历史）

以下保留当时尚未发布时的迁移计划；其中“等待首版”“另开 PR”及 Mac 不跑 sync 的限制已由上面的 v0.1.0 接入和用户主干授权更新，不能当作当前状态。

2026-10-17 用户交接：HipLab 只有 `mhgd3250905/HipLab` 一个 App 仓库（Android / iOS）。动作素材由 [3D-Pose-Hub](https://github.com/mhgd3250905/3D-Pose-Hub) 发布，HipLab 按版本取用；姿态、脚向、高亮和渲染问题到上游提 issue，写明 App、动作 ID、问题和期望。#8 的姿态源见 [Pose-Hub #1](https://github.com/mhgd3250905/3D-Pose-Hub/pull/1)。

本轮检查未见已发布素材版本，不能用 import tag 代替发布清单。首版发布前保留现有媒体和旧工具，不创建占位 lock、不使用示例 URL 同步。

## 首版发布后单独开 PR

从 main 开 `chore/pose-hub-media`，以发布时的 `docs/consumers.md` 为准：

1. 复制上游 `media/tools/sync.py` 为 `tools/pose_hub_sync.py`，文件头标明来源 commit。
2. 新建 `pose-hub.lock.json`。视频选 `variant: dark`、`role: video`、`width: 1080`，目标 `assets/drill_media`，命名 `hip-{id_lower}.mp4`。封面选 dark / poster，同目录，命名 `hip-{id_lower}{ext}`。
3. 自测静图选 `role: still`，目标 `assets/hip/assessment`，按发布清单 tag 映射到现有 `<项目>-<a|b|c|front|back>.webp`；动作 IDs 取 `tools/hip_content/source/hip-media.json` 的 key，不臆造上游 ID。
4. 按下面顺序预览、同步、验证和生成内容。确认新工具稳定后删除旧 `tools/sync_drill_media.py` 或明确弃用。

```powershell
python tools/pose_hub_sync.py --lock pose-hub.lock.json --dry-run
python tools/pose_hub_sync.py --lock pose-hub.lock.json
python tools/pose_hub_sync.py --lock pose-hub.lock.json --check
python tools/hip_content/build_hip_content.py
flutter test
flutter analyze
```

`supine-cross-demo` 是既有剪辑，暂留 HipLab、不进 lock，在 PR 明列遗留。验收要求：`--check` 退出码 0，重生成后动作与文件名不变，安卓真机抽查 3 个动作及 1 个自测结果页。以后新版本只改 lock 的 version / ids 并 sync，记录来源、结果与差异。

Windows 负责 assets、工具、lock、依赖和共用版本；Mac 不改素材、不跑同步、不升依赖。保留绿幕、透明母帧与旧批次；本地路径不代表远端已备份。

## 当前遗留

四足画圈高亮根治等待上游新人物；浅色/绿幕发布前浅色主题继续用深色舞台卡片。左右侧目前共用未镜像视频，水平镜像另开 App PR。本轮没有重渲或清理源工程。
