# HipLab 协作约定

- 本仓库 `mhgd3250905/HipLab` 是 HipLab App 主仓库，`main` 是开发基线，本目录为日常开发入口；后续动作素材由 `mhgd3250905/3D-Pose-Hub` 按发布版本提供。开工先读 `docs/README.md`、`docs/current-state.md` 和 `docs/development-roadmap.md`，再检查实际 Git 状态；手机已安装、分支已推送、main 已合并分别记录，不能混用。
- 改动走分支 + PR，由仓库主人审核合并，或按其明确授权由代理审核合并；不要直接推 main，不要 force push。推送和合并前先取得用户明确同意；已有明确授权不重复询问。
- 本仓库暂无 CI。提 PR 前本地跑 `flutter analyze` 和 `flutter test`，结果写进 PR 说明。
- 仅文档改动验证事实、链接和 `git diff --check`，不增加 App 版本、不重复构建。功能变更按影响范围测试，涉及原生播放或安装需补真机证据；未执行检查明确写出。
- 状态实际变化更新 `docs/current-state.md`；构建/安装/发布追加 `docs/version-ledger.md`；检查结果维护 `docs/verification.md`；事项进展维护 `docs/development-roadmap.md`；关键成果写入 `docs/development-log.md`。保留历史记录并链接最新状态，不把旧结论改写成新验收。
- `assets/hip/hip-content.json` 是生成文件：改 `tools/hip_content/source/` 后运行 `python3 tools/hip_content/build_hip_content.py`。
- 动作姿态、脚向、高亮和渲染问题去 Pose-Hub 提 issue（App、动作 ID、问题、期望），不在 HipLab 重渲。首版素材发布前保留现有媒体与旧同步工具；发布后另开 `chore/pose-hub-media`，按 `docs/consumers.md` 建 lock、同步并验收，详见 `docs/pose-hub-adoption.md`。
- 高清同步使用已通过 QA 的批次和显式参数，当前流程见 `docs/development-workflow.md`。逐项来源以 `tools/hip_content/source/hip-media.json` 为准；保留绿幕/透明母帧、旧批次与修订来源，不覆盖冻结动作、模型或 QA。
- `lib/core/` 是从 3D-Body 复制的公共代码，文件头注明来源；修改时保留来源注释并说明改了什么。
- 包里只放 HipLab 自己用到的资源（`test/hip/hip_assets_test.dart` 会检查）。
- Android 更新保持包名和签名连续，覆盖安装保留用户数据；不要清数据。用户数据备份、密钥、APK 和运行截图日志留 Git 忽略目录，文档路径不代表已备份到远端。

- Windows 负责 `lib/`、`android/`、`assets/`、`tools/`、媒体 lock、依赖和版本号；Mac 只改 `ios/` 及少量 iOS 专属平台代码，不动 assets、不跑 sync、不升依赖。两端 Flutter 统一 **3.44.7 stable**；版本由 Windows 统一递增。
- 新工作从 main 建分支：Windows `feat/…`、`fix/…`、`android/…`；Mac `ios/…`，均通过 PR 合回 main。跨端共享音视频改动必须补 Android 复查。
