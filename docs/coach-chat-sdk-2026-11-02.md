# 第 5 批：HipLab 接入 SDK 对话模块

候选分支 `codex/coach-chat-sdk`，基于本机 `main@1083b49`；运行代码提交 `60d3c372e853aada88eb8d441f04e733860dfca2`。原日常目录的液态玻璃 WIP、旧 `codex/coach-v2` 和 release 分支均保留；本轮仅推候选分支，不合 main、不打 tag、不提交商店。

分支已普通推送；首次远端回读 `6c30bb911b8700d513d1ee68de389ccb72059489` 与本机一致。后续仅补本推送回执，不改变已验代码或 APK。手机未安装，main 未合入；本机 main 仍为 `1083b49`、release/1.0 仍为 `1f9a172`。

## 交付边界

App 仅装配 `CoachAppProfile`：HipLab 主题、单一 45 动作白名单、存储、训练/导航回调，以及 compose、原话事件、归档三个端口。页面和会话控制直接使用 `ugk_coach_chat`。release 使用无供应商密钥的 Worker 网关；非中文与 iOS 继续隐藏 AI 入口。参考 Sport-Helper `0863e09` 的宿主适配，未复制旧 v2 的对话逻辑。

四个运行依赖 `ugk_coach`、`ugk_coach_ui`、`ugk_trainer_runtime`、`ugk_coach_chat` 统一固定同一 SDK commit；`ugk_coach` override 同步。移除 legacy `ugk_trainer`，避免携带全动作库资源。45 张剪影取自固定 SDK commit，逐项来源及 SHA256 见 `assets/coach/standing-manifest.json`；白名单仅在 `lib/hip/coach/hip_coach_profile.dart` 调整。

SDK pin：`7d9be56a6c02b7a28e3d5d5cd9f6c3f1a23ac723`，为用户确认的 SDK main（上下文 256KB、会话 50 轮，接口保持）。声明与 lock 的 ref/resolved-ref 均已更新。旧 pin `0a6c3aaea9e3890d938799703f97819d5986ee7d` 的结果仅保留历史，不作为新版最终门禁。

## 数据与执行

旧 `hip.coach.session.v2` 源数据保留，由 SDK 导入到独立 envelope；新会话归档追加独立 key。已存计划保存完整 SDK JSON、版本与宿主存储 revision，写入失败不发布、更新使用 CAS，轮次、分段、剂量、侧别和休息结构原样进入 runtime。旧普通组仍可读取。SDK 保存计划通过 SDK 详情与开练入口，禁止旧编辑入口静默降级完整计划。

`coach-v2` 仅选取 App 修复：八条剂量模式修正本机 main 已有，本轮补 `h-sumo-pry` 的 holdSeconds=10、`n-seated-knee-lift`=5，以及真实动作周期投影。冻结 Pose-Hub 媒体未升级。SDK 时长回调与播放器共用 builder（准备 15 秒、转换 15 秒及当前语音换侧余量）；预览通过宿主退役端口等待平台视图卸载。

## 删除清单

- `lib/hip/ui/coach/ai_coach_page.dart`
- `lib/hip/coach/coach_service.dart`
- `lib/hip/coach/template_fallback.dart`
- `lib/hip/coach/plan_mapping.dart`
- `lib/hip/coach/coach_auth.dart`（改用 SDK Worker auth）
- `test_screens/hip_ai_coach_shots_test.dart`（由 SDK 页面状态截图工具替代）

## 验证与产物

新 pin 严格 `flutter analyze --no-pub --fatal-infos` 为零问题；全量 `flutter test --no-pub --concurrency=1` 为 **446 通过、1 条件跳过**（可选 VOICE_TIMELINE_OUT 导出），耗时 4分27秒。Python 全量 **25/25** 通过。最终日志 `analyze-final.log`、`all-tests-final.log`、`python-tests.log` 均在证据目录。

| 连续输入 | 新 pin 结果 |
|---|---|
| 在家拉伸髋部 10 分钟 | 计划 v1，卡片/含准备执行均 587 秒，距 600 秒 −2.17% |
| 推荐几个拉大腿内侧的动作 | 推荐卡 |
| 换一套，缩到 5 分钟 | 新计划 v2，卡片/含准备执行均 313 秒，距 300 秒 +4.33% |
| 练一下胸肌 | SDK 范围外说明与髋部建议，无越界计划 |

四段一次连续通过、零外围重试、零会话重置，全部动作命中白名单；自然时间线回放完整，无手动计时豁免。证据 `live-7d9be56/results.json`。旧 pin 的 `live-1/` 仅为历史记录。

浅/深各空态、等待、计划卡、推荐卡、失败共 10 张截图已生成，使用正式 SDK 页面与模拟状态，未做像素对比；它们不代表真机视觉验收。截图记录的是换 pin 前的 0a6c3aa 页面；本轮按用户要求不重复拍图。证据目录 `E:/AII-3D/hiplab-releases/coach-chat-sdk-20261102/`，联系图 `screens/contact-sheet.png`，逐图来源见 `screens/capture-manifest.json`。

用户最新安排：手机已拔线，本轮不执行 ADB、不安装；交付同签名 APK，由用户自行覆盖安装并验具体对话、训练、旧数据界面与视觉细节。不扩展耳机/蓝牙、锁屏、极端字号等矩阵，不把未验项目记为通过。

APK：`E:/AII-3D/hiplab-releases/coach-chat-sdk-20261102/hiplab-1.1.0+27-coach-chat-sdk-60d3c37-worker-arm64-device-release.apk`，**106,781,267 bytes**，SHA256 `f9ac4b6186c7b665a56c7fe0a0549d3f66b9e0f65ba4b62eef01eb1220c4c0e7`。包名 `com.ugk.hiplab`、versionName `1.1.0`、arm64 split versionCode **2027**（2000+27），可覆盖当前设备此前读回的 2026。同一 release 运行负载重签为原手机测试证书 `3761270a4764157f0e389014a9e5b800b05403bfddce0f4f7f8c039f6a53bdc7`；原上传签名产物保留。签名/CRC/资源闭包/16KB ZIP与ELF/JNI检查通过，Worker endpoint/AppKey存在、外部模型测试凭据不存在；详见 `release-apk.json`。本轮未安装，真实旧数据恢复与视觉仍待用户验收。
