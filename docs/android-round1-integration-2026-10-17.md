# 第一轮 Android 集成验证（2026-10-17）

> 本页保留当时的未合并预演。用户随后于 2026-10-18 授权主干整合并直接推送，#7–#10 已合并；最新源码、Pose-Hub 和验收边界见[后续主干记录](mainline-pose-hub-2026-10-18.md)。

本轮完成本地代码修复、三阶段 analyze / test / APK 构建和安卓真机覆盖安装。**尚未推送或远端合并**。用户交接明确要求“推送/合并前先经用户同意”；先提供本页与本地差异供审核，再执行最后一步。音乐实测由用户明确选择“先完成代码和 APK，音乐实测稍后”。

## 固定来源与工作区

| 对象 | 核对值 |
|---|---|
| main | `9aeb2683b19f1b064be1e72b3369f7e47ebde6a7` |
| [PR #7](https://github.com/mhgd3250905/HipLab/pull/7) | `44db1fe6bd9145445d4549d5c0b3daf635d44abf`，OPEN |
| [PR #8](https://github.com/mhgd3250905/HipLab/pull/8) | `0d0758768fcd5029a395a7cd41927c0e6f91c1e6`，OPEN |
| [PR #9](https://github.com/mhgd3250905/HipLab/pull/9) | `313b4848ff0a436b9b2c400ea1d95f97c30c308b`，OPEN，已包含 #7 / #8 原始头 |
| 原目录 | `E:\AII-3D\3D-Hip`，保持 `codex/play-store-release` / `c20fae5`；已有 `.playwright-mcp/` 未动 |
| 隔离 worktree | `C:\Users\29485\.codex\worktrees\hiplab-round1-android\3D-Hip`，本地 `fix/android-round1-validation` |
| 最终 APK 源码 | `c8057ad74c5a4cf60daad9419f6825dc53bad93c`，后续仅更新文档不改变 APK |
| 工具链 | Flutter 3.44.7 stable / Dart 3.12.2，SDK 36 / JBR 17 |

本地用固定来源的三方补丁预演集成；本地线性提交不等于远端 PR 已合并。授权后仍需回读各 PR 头，按 #7 → #8 → #9 集成并核对最终树。不能把当前验证分支直接强推覆盖旧分支。

## 已修复问题

- 媒体从 `play: false` 切到 `true` 时，立即 toggle 和帧回调各执行一次，可能重新暂停。帧回调现在只在控制器仍未请求播放时执行；新增暂停/恢复 widget 回归。
- 首次语音可能在 AudioSession 异步初始化完成前开始，未正确请求焦点。现在等待共享初始化 future；结束会话立即使旧请求失效，再等待原生初始化收尾，防止退出后旧播报启动。
- 耳机拔出会取消延迟释放计时，却没有释放 ducking。现在停止语音和提示音，并释放音乐焦点；新增回归验证。
- #8 新深蹲评分图与原描述不符：一般为“大腿接近水平，还不能蹲到底”，紧为“只能半蹲，大腿还高于水平”。修改内容源后重生成 `hip-content.json`，未手改生成文件。
- 保留已送审 #10 的隐私页和设置入口，适配动态主题的非 const 颜色；新增入口可达及联系信息回归，避免合入 #9 时丢失政策页。
- 版本统一为 `0.3.0+5`，避免回退已经上传的 `0.2.0+4`。#7 lock 的 Dart 3.13 下限与实际 3.12.2 不兼容；显式对齐 13 项 SDK 相关传递依赖，未升级 Flutter。

## 三阶段实际检查

三次均执行 `flutter analyze --no-pub`、`flutter test --no-pub --reporter expanded`、`flutter build apk --debug --target-platform android-arm64 --no-pub`，再 `adb install -r`。这是远端合并前预演。按用户要求，授权后每步实际合并仍须重新 analyze、test、build APK 和真机覆盖安装，记录实际 main 提交。

| 阶段 | 本地提交 | analyze / 测试 | APK 大小 / SHA256 |
|---|---|---|---|
| #7 + 播放/初始化修复 | `3eb175dcecf422197e57fa11166c193644e1c6bf` | 无问题 / 85 项通过 | 150,625,216 bytes / `1cf83d44891b2a6b0b5edd2644ca669f03b81f614a433dd88d33f86dd7c74dd8` |
| 再加 #8 + 评分描述修复 | `025f6756f55b5f3a9ecaec81f7ed27da69b556e5` | 无问题 / 85 项通过 | 151,692,271 bytes / `45ff55c240d60d462ba8f501a54a8cafd05a7c0547eaf0082e5e4363b94d9125` |
| 再加 #9 + 拔耳机/隐私回归 | `c8057ad74c5a4cf60daad9419f6825dc53bad93c` | 无问题 / 109 项通过 | 176,624,651 bytes / `28143d19339b9d28c3ec65c5e200423a8b76a05e0acd2427dd596f5bf80a66d7` |

`python tools/ios/check_ios_project.py` 通过；属于静态验证，没有 Xcode 构建或 iPhone 真机结论。内容生成器已重跑；#8 的 114 个资源引用、4 条替换视频和 11 张静图已审阅。四足画圈高亮历史问题不宣称根治。

首次从 C 盘 worktree 构建遇到 Kotlin 增量缓存与 E 盘 pub cache 不同根路径错误；保留失败日志，改为将 Git 源文件复制到同一 E 盘独立构建目录后成功，未修改全局 Gradle 配置、未清理原工程或重置用户改动。最终 APK 是 debug 增量构建产物，大小不代表正式商店包体。

## 真机结果与边界

设备 2602BRT18C / Android 16 / API 36 / arm64，包名 `com.ugk.hiplab`。三次安装均回读 `0.3.0 / code 5`，证书 SHA256 与原 0.1.2+3 debug 一致：`3761270a4764157f0e389014a9e5b800b05403bfddce0f4f7f8c039f6a53bdc7`。没有卸载或清数据。

第一阶段安装前后 SharedPreferences 为 1195 bytes，SHA256 `21bee487722bef25928b8541a26dc1959773ee6be5db42b487f6adc77c292255`。启动新功能后增加主题/语音偏好，后两阶段各自安装前后均为 1359 bytes，SHA256 `c1530be3a8726a21d3ae0a356c9342d49772e7f90909b20754090bc6d57db1f9`，均逐字节一致；不能写成所有交互后文件永远不变。原有雷达图和连续训练记录仍显示。

| 检查 | 实际结果 |
|---|---|
| 第一、二阶段四足画圈实播 | 1080²、readyState 4、error null，1.5 秒分别增加 44 / 45 帧 |
| 第三阶段训练与暂停恢复 | 实播增加 44 帧；暂停 1.5 秒增加 0 帧；继续后增加 46 帧，未重新暂停 |
| 第三阶段自测示范 | 蝴蝶式 1080²、readyState 4、error null，1.5 秒增加 46 帧；未完成新的自测以免覆盖原结果 |
| 首页与播放器首帧 | 查看首页、准备态海报与原生播放；保存切换录屏及 24 帧抽样，无明显空白框。抽样不能证明没有任何亚秒级闪帧 |
| 页面、安全区与入口 | Android 真机查看首页、自测、训练、设置和政策；隐私页可达、支持邮箱及公开链接显示；iPhone 安全区由 widget 回归覆盖，仍待 Mac 真机 |
| 中英语音试听 | 设置分别选择中文 / English，观察到本 App AudioTrack 和焦点请求，之后恢复“跟随 App”；素材清单确认为 Xiaoxiao / Jenny。未以此代替人工听感或音乐实测 |
| 音乐 ducking / 恢复 | **未完成**；用户明确选择稍后真机测试。被手机取消的临时焦点工具安装未重试 |
| 手动锁屏与完整跟练 | **未作为通过项**；Android 只保持屏幕常亮，前台服务另开 `android/foreground-audio`；完整跟练、逐条媒体与主观流畅度仍待验收 |

证据根目录 `E:\AII-3D\hiplab-releases\round1-validation-20261017`，下含 `stage1-pr7`、`stage2-pr7-pr8`、`stage3-pr7-pr8-pr9`。各阶段 APK、检查日志与 `phone-install.json`，最终 `phone-video-paused.json`、`phone-video-resumed.json`、`phone-assess-video.json`、`phone-voice-focus.json`、`phone-transition.mp4`、`transition-contact.jpg` 和手机截图保留本机；用户数据、截图和日志不入 Git，路径不代表远端备份。

## 待授权的集成步骤

将本轮修复分别追加到适当 PR 分支，保持旧提交和正常快进推送；回读固定头并按 #7 → #8 → #9 合并，必要时重跑内容生成器解决 JSON 冲突。每步合并后重新 analyze、test、build APK 和真机覆盖安装，核对最终树和 main SHA，更新“已推送 / 已合并”事实后再通知 Mac 从 main 开始。#10 原隐私功能已纳入本地集成，但 #10 自身仍未合并或关闭，需要按实际主线差异另行处理。

本轮不重新提交 Play，不影响已经上传的 0.2.0+4 / Submission 1；审核状态未再次回读。Pose-Hub 尚无首版素材发布，本轮不迁移 lock / sync，见[后续接入约定](pose-hub-adoption.md)。
