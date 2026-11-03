# SDK ugk_trainer-v0.6.0 本机验证与内部包

2026-11-03：`codex/sdk-pin-v0.6.0` / [Draft PR #28](https://github.com/mhgd3250905/HipLab/pull/28) 完成全量测试与 arm64 内部包，未合 main、未安装。没有 App 或测试修复提交；本轮后续提交仅保存本报告和台账。

## 来源与检查结果

- 测试与构建源：`3a449c33be01dbef35c635a346f35eb26be1154a`。
- SDK tag `ugk_trainer-v0.6.0` 远端解引用为 `693cbc02cdf284163409868e117e438515c6a8d8`。四个实际依赖 `ugk_coach`、`ugk_coach_ui`、`ugk_trainer_runtime`、`ugk_coach_chat` 及 coach override 均保持该完整 pin，没有独立的 `ugk_trainer` 依赖。
- Flutter 3.44.7 / Dart 3.12.2；`flutter pub get --offline --enforce-lockfile` 通过；`flutter analyze --no-pub --fatal-infos` **0 问题**。
- `test/` 的 64 文件按 4 文件一批、concurrency=2 完整执行：**454 通过 / 0 失败 / 68 条件跳过**。跳过沿用既有的 12 首页截图、55 r2 截图和 1 语音导出，没有新增跳过。
- 首批单独覆盖 `hip_library_ui_test`、`hip_m6_sdk_group_test`、`hip_coach_chat_language_timing_test`、`hip_public_training_execution_test`：**24 通过 / 0 失败**。没有调整时长期望值。

SDK 推荐换侧余量为 3 秒，App builder 已传入。该版本 `planSeconds()` 每次换侧加入 3 秒预计余量；`phases()` 与 `executionTiming()` 按实际执行阶段求和，不加预计余量。现有 Coach 执行时长和播放器一致性测试因此无需把实际时长机械增加 3 秒。

## 内部包

`E:/AII-3D/hiplab-releases/sdk-pin-v0.6.0-20261103/hiplab-1.1.0+30-3a449c3-internal-arm64-release.apk`

| 项目 | 核验结果 |
|---|---|
| 版本 / Android versionCode | 1.1.0+30 / 2030，未递增 |
| 包名 / 架构 | com.ugk.hiplab / arm64-v8a，release、非 debuggable |
| 大小 | 49,954,831 bytes（47.64 MiB） |
| SHA256 | `4589119c89ef15c296ffc063a243af6fdc3c54b65c97d1281e239ababa17e169` |
| 测试签名 SHA256 | `3761270a4764157f0e389014a9e5b800b05403bfddce0f4f7f8c039f6a53bdc7` |
| 资源 | 211 公共封面、0 MP4；动作库/训练组选项 210，Coach 范围 211，未改范围 |

复用既有上传 keystore 配置的受忽略本地链接，未复制密钥。原上传签名包同目录另存；用户内部包沿用此前手机测试证书。签名、包名/版本、ABI、ZIP CRC 和重签前后运行负载一致性均通过。release 构建沿用既有 Worker 私有配置，不写入 provider token。

构建与签名回执 `release-apk.json`、`source-commit.txt`、`test-summary.json`、16 批测试日志、`analyze.log` 和 `build-release.log` 均在上述仓库外产物目录；这些本机文件未上传远端。

## 真机项与边界

当前未连接 Android 设备，按用户此前“打包我会远程安装测试”交付，未安装、卸载或清数据；未进行额外大字号或小屏幕验证。

- **动作库语言项目前不可从 App UI 执行**：`hipAppLocale` 与 `supportedLocales` 固定中文，设置中的语言仅改变语音。SDK library strings 已按 App locale 配置，并可接收 languageTag，但没有界面语言切换入口，不能将“切换语言后动作库文案变化”记为通过。本轮只测试和出包，没有扩展界面语言功能。
- 聊天加载完成直接使用 SDK `CoachChatPage`，App 没有额外包裹返回栏；SDK 默认提供唯一 `chat-back-button`。这是代码核对，**真机是否仅一个返回键仍待用户抽查**。

仅普通推送本分支的报告提交，PR 保持 Draft；不合 main、不打 tag、不动 release/1.0、不提交商店。日常目录 WIP 未操作。构建后仅文档变更，不重复测试或重打 APK。
