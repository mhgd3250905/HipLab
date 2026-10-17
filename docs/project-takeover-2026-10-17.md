# HipLab 接手基线（2026-10-17）

> 历史快照：本页记录接手初期，文中的未安装、媒体缺口和 48 项测试属于当时阶段。后续已完成高清制作与 Android 0.1.1+2 更新；当前事实见[当前状态](current-state.md)和[文档台账](README.md)。下文保留原始核查，不作为当前待办。

已从 [PR #1](https://github.com/mhgd3250905/HipLab/pull/1) 建立本地开发副本并验证现有工程。此次接手完成代码、资源和测试基线核对，未修改业务逻辑，未发布 GitHub 评论或 review，未合并、运行 CI、打包或安装 App。

## 版本与工作位置

| 项目 | 记录 |
|---|---|
| 仓库 | `mhgd3250905/HipLab` |
| 本地目录 | `E:\AII-3D\3D-Hip` |
| PR 分支 | `feat/initial-migration` |
| PR 源提交 | `2865ed737ea7265a480c0e9b172355b299698053` |
| PR 基准提交 | `f983950e505fce01b16aeb1d329c65da21e7ac02` |
| 本地接手分支 | `codex/project-takeover`，从 PR 源提交建立 |
| 检查时 PR 状态 | OPEN，源提交未变化 |
| App 版本 | `0.1.0+1` |
| Android / iOS 标识 | `com.ugk.hiplab` |

后续业务修改从此基线另行推进，遵循根目录 `AGENTS.md` 的分支与 PR 约定。`docs/hiplab-mvp-2026-10-16.md` 是拆仓前历史设计，目录和入口以 README、现行代码为准。

## 当前产品与代码入口

产品是中文、深色、离线的 Android / iOS Flutter App，无后端。已有流程为：安全图卡与身份选择 → 今日训练；6 项自测 → 评分、雷达图与路线推荐；跟练 → 倒计时、换边、暂停/跳过、疼痛降级；进度 → 连续天数、提醒设置。本地状态存于 SharedPreferences 的 `hiplab.state.v1`。

| 内容 | 入口 |
|---|---|
| 启动、页面与导航 | `lib/main.dart`、`lib/hip/ui/hip_app.dart` |
| 本地状态与规则编排 | `lib/hip/control/hip_store.dart` |
| 自测、训练计划、疼痛、进度 | `lib/hip/domain/` |
| 跟练播放器 | `lib/hip/ui/hip_player_page.dart` |
| 离线媒体服务与 WebView | `lib/core/media/`、`assets/drill_media/player.*` |
| 内容源与生成器 | `tools/hip_content/source/`、`tools/hip_content/build_hip_content.py` |
| 成片导入 | `tools/sync_drill_media.py` |

`lib/core/` 复制自 `3D-Body@a83a0f4`，保留来源注释。动作制作和渲染继续属于 3D-Body，HipLab 负责 App、内容与成片导入。

资源已核对：45 个 MVP 动作中，18 个为视频、9 个为静帧、18 个待渲染，另有 1 个引用的备选动作；7 套训练（含 2 分钟微训练）；20 张自测对比图；19 组成片及封面（含自测示范片）；字体文件 17,772,300 字节。

## 本机验证结果与复现

环境：Windows、PowerShell，`E:\flutter` 的 Flutter **3.44.7** / Dart **3.12.2**。PR 原报告使用 Flutter **3.47.7**，因此本次是另一 SDK 版本上的验证，不能视为原环境复现。

| 检查 | 本次结果 |
|---|---|
| `flutter pub get` | 成功 |
| `flutter analyze --no-pub` | No issues found |
| `flutter test --no-pub` | 48 项全部通过 |
| `flutter test --no-pub test_screens/hip_shots_test.dart` | 4 项全部通过，已查看四张截图 |
| 内容包重新生成 | 45 MVP / 7 套训练，规范化换行后与提交版本全文一致 |
| `python tools/sync_drill_media.py --dry-run` | 未完成：默认源目录 `../3D-Body/tools/drill-anim/out` 不存在 |

四张截图位于 `test/_shots/hip/s1-home.png`、`s2-assessment.png`、`s2-result.png`、`s3-player.png`，已被 Git 忽略。没有原工程同环境截图，未验证 PR 所述“逐像素一致”。Widget 截图不能证明 Android/iOS 原生 WebView 的视频播放正常；实机、Gradle、Xcode 与发布签名均未验证。

本机复现命令：

```powershell
flutter pub get
flutter analyze --no-pub
flutter test --no-pub
$env:FLUTTER_ROOT = 'E:\flutter'
flutter test --no-pub test_screens/hip_shots_test.dart
```

本机 SDK 的 `flutter pub get` 会重新解析 7 项 SDK 关联的传递依赖：clock、intl、matcher、meta、stack_trace、test_api、vector_math。上述检查使用本机解析结果；检查后已恢复仓库原始 `pubspec.lock`，此次没有提交依赖降级。后续在本机重新获取依赖时仍会出现该差异，应先确定团队 SDK 版本再决定是否更新锁文件。

Python 生成器在 Windows 上会把输出写成 CRLF；仓库 `*.json -text` 保留字节，所以即使内容一致也会出现整文件差异。此次生成检查后已恢复原内容包。后续修改生成器时应显式输出 LF，避免平台换行噪声。

媒体同步的后续入口：取得真实渲染目录后使用 `python tools/sync_drill_media.py --out <目录> --dry-run`。本次没有替换资源或在其他仓库生成成片。

## 已确认问题与后续顺序

首个功能修复建议是**让紧侧加练实际生效**：`lib/hip/domain/hip_session.dart:196` 将不对称动作的总时长增加 50%，但 `lib/hip/ui/hip_player_page.dart:104` 的 `_side` 仍按总时长一半切换，`extraSide` 仅用于字幕。例：原 70 秒变成 105 秒后仍近似均分两侧，没有把额外一组分配给紧侧。现有 `test/hip/hip_domain_test.dart` 只校验总时长与 `extraSide`，没有覆盖播放器两侧时长。修复应同时覆盖左紧、右紧、正常换边，并检查暂停、跳过和疼痛降级后的计时行为。本次只记录，未修复。

后续按以下顺序推进：

1. 修复紧侧加练，并补与实际换边行为有关的回归验证。
2. 按训练套使用情况补齐 18 个待渲染动作；另外 9 个静帧动作仍需后续视频替换。
3. 接入系统通知；当前 `ReminderScheduler` 默认实现只计算、记录计划，设置页已说明接入通知组件后生效。
4. 发布准备：正式图标、iOS 团队与商店信息、Android 正式签名、CI；字体子集瘦身可后置。

以上是接手时的建议队列，不表示这些功能、发布或跨仓库外部动作已执行。PR #1 与 3D-Body #118 的合并、关闭和发布由后续明确任务决定。
