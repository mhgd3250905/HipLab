# HipLab 协作约定

## 当前入口

先核对实际工作树、分支和 HEAD，再从[文档入口](docs/README.md)、[当前状态](docs/current-state.md)和[开发事项](docs/development-roadmap.md)确认范围。`main` 是开发基线。构建、安装和商店记录见[版本台账](docs/version-ledger.md)。界面以[UI 设计规范](docs/ui-design-standard.md)为准，实现配方见[UI 复用手册](docs/ui-kit/README.md)。

各历史阶段的约束和当次授权见[历史协作约定](https://github.com/mhgd3250905/HipLab/blob/ba0d0c16ae56d7b679572be3a380969f0679b2dd/AGENTS.md)。本轮范围按当前用户指令执行。

## 工作区与交付

- 动作素材按 `mhgd3250905/3D-Pose-Hub` 的明确版本接入。
- 本机 Windows 是主干线：按用户 2026-10-18 明确授权审核合并贡献 PR，验证后直接提交和推送 main，无需再开 PR；不要 force push。其他贡献方仍走分支 + PR。已有明确授权不重复询问。
- 本仓库暂无 CI。提 PR 前本地跑 `flutter analyze` 和 `flutter test`，结果写进 PR 说明。
- 本项目新建 worktree、审核/测试克隆及大体积构建产物一律放非 C 盘，先检查并优先复用已有非 C 盘副本。新工作副本默认 `E:/AII-3D/3D-Hip-worktrees/<task>/3D-Hip`，交付产物默认 `E:/AII-3D/hiplab-releases/`；禁止默认使用 C 盘 `.codex/worktrees`、`.config/superpowers/worktrees` 或 Temp。创建前核对工具的实际输出路径；工具不能指定位置且尚未核实其配置时，不使用会落到 C 盘的默认创建，改用显式指定 E 盘路径的 Git 工作副本，并说明工具限制。
- 整理 Codex 托管副本前核对聊天绑定、Git 登记、未提交/未跟踪文件及忽略目录中的唯一产物；先在非 C 盘保存唯一产物，再通过可保持 Git 登记和聊天附件一致的流程归档。不得直接拖动或删除目录来迁移托管副本。具体执行流程见 `docs/development-workflow.md`。
- 仅文档改动验证事实、链接和 `git diff --check`，不增加 App 版本、不重复构建。功能变更按影响范围测试，涉及原生播放或安装需补真机证据；未执行检查明确写出。
- 验收范围取当前任务的明确要求，尚未执行的场景和历史失败按原证据记录。
- 状态实际变化更新 `docs/current-state.md`；构建/安装/发布追加 `docs/version-ledger.md`；检查结果维护 `docs/verification.md`；事项进展维护 `docs/development-roadmap.md`；关键成果写入 `docs/development-log.md`。保留历史记录并链接最新状态，不把旧结论改写成新验收。
- `assets/hip/hip-content.json` 是生成文件：改 `tools/hip_content/source/` 后运行 `python3 tools/hip_content/build_hip_content.py`。
- 动作姿态、脚向、高亮和渲染问题去 Pose-Hub 提 issue（App、动作 ID、问题、期望）。当前素材按 [文档入口](docs/README.md#新机器拉素材mac--windows) 准备。v0.2.0 ZIP 与旧同步工具用于历史分支追溯。
- 公共媒体按[新机器准备](docs/README.md#新机器拉素材mac--windows)与[开发工作流](docs/development-workflow.md#内容与素材)接入。旧媒体导入和 QA 来源留在历史记录。保留既有动作 ID、母版和修订证据。
- `lib/core/` 是从 3D-Body 复制的公共代码，文件头注明来源；修改时保留来源注释并说明改了什么。
- 包里只放 HipLab 自己用到的资源（`test/hip/hip_assets_test.dart` 会检查）。
- Android 更新保持包名和签名连续，覆盖安装保留用户数据；不要清数据。用户数据备份、密钥、APK 和运行截图日志留 Git 忽略目录，文档路径不代表已备份到远端。

- Windows 负责 `lib/`、`android/`、`assets/`、`tools/`、媒体 lock、依赖和版本号；Mac 只改 `ios/` 及少量 iOS 专属平台代码，不升级依赖或素材版本。新环境按 [文档入口](docs/README.md#新机器拉素材mac--windows) 恢复锁定依赖和随 Git 提供的公共媒体。两端 Flutter 统一 **3.44.7 stable**；版本由 Windows 统一递增。
- Mac 从核对后的 main 开 `ios/…` 分支并提 PR，Windows 主干线负责审核集成。跨端共享音视频改动补 Android 复查。
- 商店上传、送审和发布按各自授权执行。实机验收按实际设备和对应包记录。
