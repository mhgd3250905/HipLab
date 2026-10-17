# 开发日志

只记有意义的结果和决策，完整事实分别归当前状态、版本、验证和事项台账。时间均为北京时间。

| 日期 / 阶段 | 结果与决定 | 关联证据 |
|---|---|---|
| 2026-10-17 / 接手 | 从 HipLab #1 源 `2865ed7` 建立独立接手分支；初始 48 项测试、4 项截图通过；确认紧侧计时缺陷，留 D-01 | [接手基线](project-takeover-2026-10-17.md) |
| 2026-10-17 / Android 首跑 | 首次 debug 安装 0.1.0+1，安全引导显示正常 | [Android 记录](android-first-run-2026-10-17.md) |
| 2026-10-17 10:29 / 动作源 | 按明确授权审核合并 3D-Body #119，merge `ae81d96`；原规格、模型与 QA 不改 | [制作记录](local-hd-render-2026-10-17.md) |
| 2026-10-17 / 高清制作 | RTX 4080 Laptop GPU 制作；首轮 43 PASS/3 REVIEW，三项独立修订后最终 46/46 原 QA PASS；保留绿幕与 alpha，体前屈 63 条历史警告留档 | 最终母版选择清单；3D-Body #120 `f8b5138` |
| 2026-10-17 13:15 / 高清 Android | `35f2a97`：47 对 1080 素材、6 项自测均视频，0.1.1+2 保留数据安装与真机播放通过 | [版本台账](version-ledger.md)、HipLab #2 |
| 2026-10-17 / 主线文档管理 | 建立统一文档入口和四类台账/工作流；修正 README 旧缺片状态，标明历史记录；补齐远端分支抓取，无切分支或合并 | [文档入口](README.md)、[当前状态](current-state.md)、[AGENTS.md](../AGENTS.md) |
| 2026-10-17 13:59 / 主线集成 | 用户指定本仓库为主仓库并明确授权审核合并、提交推送；固定版本复核后先合 #2（`e52b3c2`），再合 #1（`656ee28`）；每次合并文件树与审核版一致；建立本地 main 跟踪 origin/main，保持原分支 | [集成审核](mainline-integration-2026-10-17.md)，D-02 已完成；应用和已安装 APK 保持 |
| 2026-10-17 / Icon 方向重做 | 用户否决前轮六个角色候选，PR #4 关闭并保留原分支；当前聊天直接用 ImageGen 生成坐姿舒展、站姿开髋两张运动符号，侧弓步输出被服务拦截未生成；本轮原图与提示已保存，待用户选版，未改 App | [新设计说明](app-icon-sports-2026-10-17.md)，D-05 进行中 |
| 2026-10-17 14:37 / Android 图标落地 | 用户认可第二个 B；`4cf5ca7` 采用站姿开髋图标，导出五档/圆形/Adaptive/Monochrome，0.1.2+3 重新 analyze/49 测试/构建通过；同签名保留数据安装、冷启动和手机桌面确认，1195 字节设置逐字节保持 | [版本台账](version-ledger.md)、[图标资源](../design/app-icon/launcher-20261017/README.md)，PR #5；iOS/矢量尚未完成 |
| 2026-10-17 / 用户验收 | 用户在 Android 0.1.2+3 更新后确认“测试通过了”；已将反馈记入当前状态、版本与验证台账，版本号和已安装 APK 保持 | 本聊天用户反馈；本轮仅台账更新 |
| 2026-10-17 / 第一轮修改 | 按用户 14 条问题在 `feat/polish-round1` 完成 1/2/3/4/5/7/9(UI)/11/12/13/14 与 D-01；收尾修掉 360 宽 × 字号 1.5 首页卡溢出，iOS 加后台音频，Android 选屏幕常亮（前台服务列 D-10 待办）；决定保留 15 秒语音休息，5 分钟套 A 显示 6 分钟待确认（D-12）；analyze 无问题、82 项测试通过；媒体问题 6/8/10 在 `fix/motion-media` | [验证台账](verification.md)末节、[事项台账](development-roadmap.md) D-01/D-10/D-12；PR 见 GitHub |
| 2026-10-17 / iOS 版本 | 给第一轮两个 PR 打 tag（`round1-app-v1`、`round1-media-v1`），从 #7 切 `feat/ios` 并合入 #8（无冲突）；完成 iOS 工程身份（中英显示名、仅 iPhone 竖屏、zh-Hans 开发区域）、同源站姿开髋 AppIcon 与跟随系统启动页、playback + 按句 ducking + 来电/Siri/拔耳机自动暂停、WKWebView 示范锁屏回来继续、安全区测试与截图；决定沿用 SwiftPM（不加 Podfile）、保留 WebView 不换 video_player、仅支持 iPhone；analyze 无问题、104 项测试通过，未在 Mac 构建或真机验证 | [iOS 说明](ios-setup-and-release.md)、[验证台账](verification.md)末节、D-07/D-13；tag `ios-v0.1`–`ios-v0.6`，PR #9 |
| 2026-10-18 / 语音审计 | 用户 iPhone 实测 #9 播报中途消失、长词只听到一两个字、音量不稳。查明主因在播放链路：just_audio `play()` 在播放器仍处 playing（上一条播完不会自动变 false）时立即返回，代码误判一句已结束，700 ms 后释放 duck 时停用 iOS 音频会话，切断正在播的句子；素材无截断（逐条对照 edge-tts 原始输出），但 loudnorm linear 回退动态模式 + 短句 dynaudnorm 导致 -21…-13 LUFS、64 条真峰值超 -1 dBTP。新增 `VoiceLineController`（播完才算结束、无声才释放、会话操作串行、不剪上一句尾巴）、`audit_voice.py` 检测工具，后处理改为只裁首尾 + 固定增益 + 限幅并重新生成 488 条，检测 0 失败；analyze 无问题、115 项测试通过；版本号不变，待真机复听 | [语音审计](voice-audit-2026-10-18.md)、[验证台账](verification.md)末节；分支 `fix/voice-audit`，PR #13 |

## 后续检查点模板

```text
日期 / 事项 ID：
实际完成与关键决定：
分支 / 提交 / PR：
验证（已执行及未执行）：
台账更新：
剩余工作与下一步：
```
