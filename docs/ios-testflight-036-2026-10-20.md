# iOS 0.3.6（11）TestFlight（2026-10-20）

北京时间 **2026-10-20 01:09**，Xcode 回执 `HipLab 0.3.6 (11) uploaded`；随后 Apple 处理完成，测试说明已保存并加入既有内部组。**01:16 独立回读 `HipLab Internal` 的构建列表，0.3.6（11）显示“正在测试”，当前测试员可通过 TestFlight 获取。** 上传、处理、分组及用户实际安装分别记录，本轮没有新 TestFlight 安装反馈。

## 候选身份

| 项目 | 本轮实际值 |
|---|---|
| App / Bundle ID | 开胯训练助手 HipLab / `com.ugk.hiplab`，Apple App ID `6824011384` |
| 分支与构建源 | `ios/main-alignment-20261019@ab85a9f60f45b22567a868a715909b7c1335a0e1`，另有本轮浏览器工作流文档改动 |
| 运行源 / main 基线 | `af651ae7c1798c09312fe24e9deeb1366116b7d7` / `2d47520574ff4160d74d7631cb4efcfc58b2388b`（包含用户指定 cdbb14c）；构建源的 lib 树与运行源相同 |
| 版本 / Build | **0.3.6 / 11**；沿用共用版本，Xcode 自动管理版本号关闭 |
| 工具链 | Flutter 3.44.7 / Dart 3.12.2 / Xcode 26.6；最终 IPA 的 DTSDKName 为 `iphoneos26.5`，SwiftPM |
| Archive | `build/ios/archive/Runner.xcarchive`，Flutter 报告 272.2 MB |
| 精确上传 IPA | `build/ios-testflight-036-20261020/HipLab-XcodeUpload.ipa`，**104,377,339 bytes** |
| 上传 IPA SHA-256 | `339335b9b2939b08e5c6a66f050934c455711ac621d02db26b33dcdc30d67837` |
| 上传路径 | Xcode Organizer → Custom → App Store Connect → Upload，手动选择既有 HipLab App Store profile |
| Apple 上传回执 | Xcode `HipLab 0.3.6 (11) uploaded`；Organizer `Uploaded Today at 01:09` / Build Number 11；Apple 上传列表 01:09 / 正在处理 |
| TestFlight | **01:16 核验可测试**；已手动加入既有 `HipLab Internal`（1 名测试员 / 2 个构建版本），0.3.6（11）正在测试，90 天后过期；旧 0.3.2（7）保留 |

前期 CLI 导出的 `build/ios/ipa/HipLab.ipa` 仅用于本地签名门禁，104,377,327 bytes / SHA-256 `21632d1718339d5e2e9cc00865a16ce57eb145ded3c3e1e7cca3a8bba8b110e9`，**未作为本次上传身份**。Xcode 重新准备的最终包在点击 Upload 前从临时 Packages 目录复制、验签并记录上述实际哈希，上传期间再次确认临时包与已验证副本相同。

## 授权与范围

用户明确要求“发布到 testflight”，随后确认手机已拔线、不需要重复真机测试，并授权跨项目清理可复生的中间产物来腾空间。本轮按该授权完成分发签名、上传及既有内部群组分发；不提交新的正式 App Review、不取消旧审核、不公开发布，也不新增外部 Beta Review、测试员邀请或公开链接。

本轮发布依赖已验的开发签名真机候选，核心检查见[iOS main 对齐与真机记录](ios-main-2d47520-2026-10-20.md)。本轮没有连接或操作手机，也不声称用户已安装精确 TestFlight Build。此前听感、左滑删除手势及扩展系统矩阵的未验边界保持，不扩展全量测试。

## 门禁与产物核验

- 发布只读 preflight 通过；本地既有 Apple Distribution identity 与专用 App Store profile 有效且互相匹配，无新建证书或 profile。
- 沿用相同运行源已执行的 `analyze` 无问题、**395 pass / 1 条件 skip**，不冒称本轮文档改动后重新跑全量；本轮 `python3 tools/ios/check_ios_project.py` 通过。
- 最终 Archive/导出成功：总耗时 62.2 秒，其中 Xcode Archive 45.6 秒、IPA 导出 7.2 秒。前期磁盘满和平台目标不可用的尝试保留失败记录，不算成功。
- CLI 与实际上传 IPA 均执行 skill 的 `verify_ipa.sh`：strict/deep codesign、Bundle/版本/Build、arm64、`get-task-allow=false`、6 份隐私清单语法和 SHA-256 全通过。
- App Store profile 的 `beta-reports-active=true`、无设备名单/企业分发标记；手动签名沿用现有资源，关闭 Xcode 自动管理版本。
- 实际上传包的 **874 份对应源资源逐字节一致**。Dart AOT 的 3 个有文件内容的 Mach-O section 与 CLI 导出及此前真机候选完全一致；分发重签会改变完整 Mach-O 哈希，不把签名差异误记成运行代码变化。
- 实际上传包的 AOT 完整 SHA-256：`fa9b3d5959d39ae7b54cb195ee375770636b6e0789278abb41f91fd32e10ce68`。代码、版本、依赖和素材未因发布改变。
- 发布台账及浏览器约定共 11 份仓库文档，329 处本地链接引用无缺失，`git diff --check` 通过；全局浏览器约定另存本机 AGENTS。后续仅文档提交不重新构建 App。

## 本机环境恢复与浏览器方式

经用户授权，清理 35 处可重建的编译/测试/DerivedData/SwiftPM artifact 缓存，名义大小约 1.56 GiB；清理前后涉及项目的 tracked status 与 diff 哈希一致。源码、未提交改动、历史 Archive/IPA、证书、profile、手机备份和既有签名候选保留。之后实际可用空间曾回升至约 28 GiB，本报告不将全部空间变化归于上述清理。

归档遇到 Xcode 将 generic iOS 目标列为“iOS 26.5 is not installed”；SDK 文件本身存在，检查组件更新显示无新 Device Support 更新。Components 页确认 iOS 平台支持未安装，通过 Xcode 官方 Get 恢复 `iOS 26.5.1 + iOS 26.5 Simulator`（界面下载 8.52 GB）；恢复后 `Any iOS Device` 重新可用，再完成归档。此为本机构建环境恢复，没有新增 App 依赖或真机测试要求。

按用户指定，网页操作已改为 **Playwright MCP**，复用 `~/.local/share/ugk-browser/chrome-profile` 的现有登录态，实际进入 HipLab TestFlight 并核对当前 App。方式写入本机全局 `~/.codex/AGENTS.md`、项目 AGENTS 和[工作流](development-workflow.md#mac-浏览器登录态2026-10-20-用户指定)。profile、Cookies、密码、token、账号字段和原始网页快照不入 Git。

## 证据位置与后续状态

本机验证副本为 `/Users/shengkai/ugk-hiplab-ios-device-validation`。忽略目录 `build/ios-testflight-036-20261020/` 保留候选 manifest、两份 IPA 验证结果、有效代码段/资源对比、Xcode 上传回执截图、构建日志和私密环境记录。上传 IPA 与 Archive 保留；这些本机文件不代表已备份到 Git 远端。

Apple 已处理完成；0.3.6（11）测试说明独立回读为“已保存”，既有内部组包含该 Build，群组构建列表显示“正在测试”。最终界面截图在 `~/.local/share/ugk-browser/playwright-output/hiplab-testflight-036-11-ready-20261020.png`，仅截取群组构建区域，不含账号或测试员个人字段。用户可打开 TestFlight 刷新升级；本轮未代用户安装，既有开发签名真机结果不冒称为 TestFlight 分发包实测。

原 0.3.2（7）的[首轮正式送审记录](ios-store-release-2026-10-18.md)保持历史，本轮不查询或修改其正式审核流程。发布记录和浏览器约定随 PR #23 交付，main 集成与 TestFlight 可用是两个独立事实。
