# HipLab 文档与开发台账

## 当前使用入口

| 文档 | 维护内容 |
| --- | --- |
| [当前状态](current-state.md) | 主线、设备和商店渠道最近可核对的事实 |
| [版本管理](version-management.md) | 事实来源、版本号、构建与渠道的登记规则 |
| [版本交付台账](version-ledger.md) | 构建、安装和渠道回执 |
| [验证台账](verification.md) | 检查结果、对应源码及未覆盖范围 |
| [开发事项](development-roadmap.md) | 待验收事项与后续工作 |
| [开发日志](development-log.md) | 关键改动、决策和阶段记录 |
| [开发工作流](development-workflow.md) | Git、工作副本、构建与素材操作 |
| [iOS 运行与上架](ios-setup-and-release.md) | Mac 构建、签名与渠道证据 |
| [UI 设计规范](ui-design-standard.md) · [UI 复用手册](ui-kit/README.md) | 当前设计数值、实现配方和 Flutter 画廊 |

历史交付和专题索引见[收束前的文档索引](https://github.com/mhgd3250905/HipLab/blob/ba0d0c16ae56d7b679572be3a380969f0679b2dd/docs/README.md)，版本及验证流水继续保存在相应台账。

## 新机器拉素材（Mac / Windows）

从 Git 获取 `pubspec.lock`、随包目录 `assets/public_media/`、静态图 `assets/public_posters/` 和 AI 标签 `assets/coach/ai-tags/`。动作库开放 248 项，另有自测演示。素材版本、构建与验收对应同一份记录。[版本与素材身份](version-ledger.md#2026-11-18-android-2077-展示素材候选)

App 启动后检查渠道指针。发现新版时，SDK 先校验目录和展示图，再激活整批素材并保存在应用支持目录。失败时继续使用现有素材，弹窗可重试。已有文件按 SHA-256 复用。打开动作后才准备其视频或动作语音，离线可用范围取决于本机已有素材。

两端使用 Flutter **3.44.7 / Dart 3.12.2**。执行 `flutter pub get --enforce-lockfile`，保持锁文件的 `pub.dev` 源。已有依赖解析时可用 `--no-pub`。完整 SDK 固定版本和目录 SHA-256 见[版本管理](version-management.md#版本与来源身份)。

### 冻结 v0.2.0 ZIP 恢复（仅旧分支历史）

[旧版 ZIP 来源、校验及恢复命令](https://github.com/mhgd3250905/HipLab/blob/ba0d0c16ae56d7b679572be3a380969f0679b2dd/docs/README.md#冻结-v020-zip-恢复仅旧分支历史)仅适用需要原内置视频布局的旧提交。
