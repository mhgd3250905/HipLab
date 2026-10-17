# Pose-Hub 后续素材接入约定

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
