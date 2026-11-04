# AI 教练修复候选：HipLab +32（2026-11-04）

构建源 `c327a90e9946edfe7254075deec91edd749b604e`，分支 `codex/sdk-pin-v0.7.0` / [Draft PR #30](https://github.com/mhgd3250905/HipLab/pull/30)，SDK 固定 `3e949ce6ecd695aa954a012f33474942531324ef`（codex/qa-v2-fixes）。`flutter pub get` 成功且锁文件未变；严格 analyze 0，全部 66 个测试文件 461 通过 / 0 失败 / 68 既有条件跳过。

`com.ugk.hiplab` / release / arm64-v8a，版本 **1.1.0+32 / 2032**，49,590,492 bytes（47.29 MiB）。APK：`E:\AII-3D\hiplab-releases\sdk-qa-fixes-plus32-20261104\hiplab-1.1.0+32-c327a90-internal-arm64-release.apk`；SHA256 `b1a24ae32a64921b5f1e157ce43eefa4648a40a056e2a1cbde11227a6de90379`；证书 SHA256 `3761270a4764157f0e389014a9e5b800b05403bfddce0f4f7f8c039f6a53bdc7`，与 +31 实际 APK 校验一致。211 公共封面、209 未审 AI 标签、0 MP4；CRC、包名/版本/ABI、签名及重签前后运行负载校验通过。

用户随后明确暂无真机，改为打包后远程安装测试。本轮未安装、未卸载、未清数据，也未抓取用户日志；下列 1–4 均不记为实测通过。App/SDK 源码未改，不新增问答适配或绕过。main 保持 4d610f5，release/1.0 不动，不合并、不打 tag、不提交商店。

## 自动验证

- Flutter 3.44.7 / Dart 3.12.2；pub get 保持镜像和已有依赖版本，pubspec.lock 无差异，无需补交锁文件。
- `flutter analyze --no-pub --fatal-infos`：0 问题。
- 全量 `flutter test --no-pub --concurrency=2 --reporter=expanded`，枚举 test/ 全部 66 文件，每批 4 文件、共 17 批；任一批失败即停。本轮全部通过，461/0/68。68 个既有 skip 为可选截图/导出，没有新增跳过。
- 现有聊天回归含 QA 单多选/编号、原保存门禁、对话存储和恢复；不能替代手机上坏记录恢复与即时气泡验收。本轮不复用 +31 的真实模型对话作为新 SDK 的验证。
- APK 外部运行参数沿用 +31 测试网关、deepseek-v4.1-flash/max；凭据不进入仓库或文档。构建源固定 c327a90；后续回执仅改文档。

## 真机验收（待用户远程执行）

| 项目 | 本轮结果 | 用户验收内容 |
|---|---|---|
| 1 旧对话恢复 | 未执行 | 旧对话正常显示，或出现“之前的对话记录无法读取，已开始新的对话。”；记下实际分支 |
| 2 连续 3 轮 | 未执行 | 点击发送即出现用户气泡，教练回复；至少一轮排计划，不再出现“这次未能完成回复” |
| 3 杀进程重启 | 未执行 | 刚才对话保持，可继续发送 |
| 4 失败日志 | 未采集 | 仍失败时抓本地 logcat，保留 coach_chat 事件及 stage/errorType/message/status；用户日志不入 Git |

覆盖安装须使用本次 internal APK、保留已有数据；不得卸载或清数据。没有真机，不能宣称此次故障已被真实复现并修复。

## SDK 代码核查的适用范围

只读核查确认 SDK 恢复可解析但无法还原的快照时发 chat.restore.recovered 并显示提示；原始 JSON 解析抛错发生在该恢复流程前，仍可能为 chat.start.error。QA 发送在等待模型前通知 UI 显示用户消息。以上是代码核查，未作手机结论。

chat.restore.recovered 有 source/stage/errorType、可选 message/issues；chat.turn.result 有 turnId/status/agentMode/errorType、可选 failureKind/contextRequests。该固定源码未找到 ai.turn.end 定义，App 默认 observer 仅记录事件名；不能虚构未采集的详细事件。

## 本地证据

`E:/AII-3D/hiplab-releases/sdk-qa-fixes-plus32-20261104/` 下保存 pub-get.log、analyze.log、run_tests.py、test-batch-01..17.log、test-summary.json、validated-source.json、build-release.log、release-apk.json 及 APK 验包/签名回执。本机路径不代表已上传远端制品；没有用户日志进入本次提交。
