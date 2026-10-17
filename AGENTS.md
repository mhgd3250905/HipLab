# HipLab 协作约定

- 本目录是 HipLab 后续 main 主线开发入口。开工先读 `docs/README.md`、`docs/current-state.md` 和 `docs/development-roadmap.md`，再检查实际 Git 状态；手机已安装、分支已推送、main 已合并分别记录，不能混用。
- 改动走分支 + PR，由仓库主人审核合并；不要直接推 main，不要 force push。
- 本仓库暂无 CI。提 PR 前本地跑 `flutter analyze` 和 `flutter test`，结果写进 PR 说明。
- 仅文档改动验证事实、链接和 `git diff --check`，不增加 App 版本、不重复构建。功能变更按影响范围测试，涉及原生播放或安装需补真机证据；未执行检查明确写出。
- 状态实际变化更新 `docs/current-state.md`；构建/安装/发布追加 `docs/version-ledger.md`；检查结果维护 `docs/verification.md`；事项进展维护 `docs/development-roadmap.md`；关键成果写入 `docs/development-log.md`。保留历史记录并链接最新状态，不把旧结论改写成新验收。
- `assets/hip/hip-content.json` 是生成文件：改 `tools/hip_content/source/` 后运行 `python3 tools/hip_content/build_hip_content.py`。
- 动作成片在 3D-Body 渲染，用 `tools/sync_drill_media.py` 同步，不在这里渲染。
- 高清同步使用已通过 QA 的批次和显式参数，当前流程见 `docs/development-workflow.md`。逐项来源以 `tools/hip_content/source/hip-media.json` 为准；保留绿幕/透明母帧、旧批次与修订来源，不覆盖冻结动作、模型或 QA。
- `lib/core/` 是从 3D-Body 复制的公共代码，文件头注明来源；修改时保留来源注释并说明改了什么。
- 包里只放 HipLab 自己用到的资源（`test/hip/hip_assets_test.dart` 会检查）。
- Android 更新保持包名和签名连续，覆盖安装保留用户数据；不要清数据。用户数据备份、密钥、APK 和运行截图日志留 Git 忽略目录，文档路径不代表已备份到远端。
