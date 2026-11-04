# iOS 对齐 main（2026-11-04）

本页记录首轮Mac主线对齐与 `edb464f` 构建；随后用户已追加授权iOS全功能对齐，取消AI/试听限制。当前接线与验证见[后续功能对齐报告](ios-feature-parity-2026-11-04.md)。下方为前一轮事实，旧未签名包已另存本地ZIP以免与新构建混用。

## 基线与范围

- 本地分支 `ios/main-alignment-20261104`，独立 worktree；基于远端 `main@4d610f50ee47f2d4de7c19517eb7e99220bb2204`。
- 原主 worktree 保留 `main@1b94fc3`，旧 iOS 发布 worktree 保留 `ios/app-store-1.0@a20721e`；没有覆盖其中的产物或工作状态。
- 远端 `release/1.0@a20721e25044f87399ec633c93fb04d6d55c6ff4` 不变。当前 main 比它多 61 个提交；当前任务是准备后续 iOS 开发版本，不是将全部新功能回灌基础版审核分支。
- 共用版本沿用 `1.1.0+30`，四个 SDK 依赖及 override 固定 `693cbc02cdf284163409868e117e438515c6a8d8`；未修改 pubspec、lock、Android、SDK 或素材。
- main 已含 PR #26/#27/#28；Draft PR #29（UI r3）未纳入。

## 这次从 main 带来的行为

1. 新首页/更多/设置与 UI r2 页面、训练成就记录、按日累计后取整的分钟统计。
2. Coach 211 完整动作、动作库及组选项 210（排除自测演示）、混合组统一 SDK 计划与组内休息；旧 45 动作组兼容路径保留。
3. `ugk_trainer_runtime`、SDK 公用播放器/动作库/详情和对话宿主；SDK 0.6.0 的换侧预计余量与中文界面。iOS 仍隐藏 AI，不提供任何 AI 凭据。
4. 211 公共封面和公共元数据随包，0 内置 MP4；视频按需下载并校验后缓存。首次使用/缓存被清理后需要联网，已有缓存才可离线播放。不能沿用旧版“视频随包、首次即可完整离线”的说明或旧 ZIP 回填步骤。

## iOS 适配

- 继续使用唯一 App 身份 `com.ugk.hipinterlude`；iOS 15、iPhone-only、竖屏、SwiftPM（无 Podfile）、训练 `audio` 后台能力保持。
- 桌面默认/英文名称为 `HipLab`，中文名称为 `HipLab开髋训练`，与最终产品名称对齐。
- iOS 包内隐私页说明媒体 HTTPS 下载、IP/资源路径和本机缓存；不再声称视频全部内置。iOS 使用专属 `ios/hipinterlude/` 政策链接及复制值，AI 文案服从 iOS 关闭规则；Android 原有文案与链接保持。
- 隐私清单只修正过期的纯离线注释；未凭源码把 Apple 隐私问卷重新确认成“未收集”。后续上传前仍须核对媒体服务/CDN 的实际日志、保留用途与最终设备网络行为。
- 修复素材验证脚本解析 macOS `file:///Users/...` 时错误移除根斜杠的问题；使用标准 `url2pathname`，兼容 Windows 本地文件 URI。

## 本轮验证

运行源码提交 `edb464ff970973ae140c214da953afd8075833db`，工具链 Flutter3.44.7 / Dart3.12.2、Xcode26.6（17F113）。

- `PUB_HOSTED_URL=https://pub.flutter-io.cn flutter pub get --enforce-lockfile` 成功，pubspec/lock 无变化。
- `flutter analyze --no-pub --fatal-infos --fatal-warnings`：0问题；修改文件 Dart format 通过。
- `flutter test --no-pub`：64文件按4文件/批、concurrency2执行，**454通过 / 0失败 / 68既有条件跳过**（12首页截图、55r2截图、1语音导出）。没有删除或新增跳过。
- iOS/隐私专项：**25通过**，包括四档iPhone安全区、音频中断/显式恢复、侧滑退出守卫、AI/设置试听隐藏，以及按需视频/缓存/专属政策链接。
- `python3 -m unittest discover -s tools/tests -v`：**25通过**。首轮24通过/1错误来自macOS文件URI根路径丢失，修复后全量通过；可选jsonschema未安装，仅该步骤未执行，不能宣称完成JSON Schema专项。
- `python3 tools/ios/check_ios_project.py`、`git diff --check`、发布预检通过。
- 生成配置确认1.1.0/30、SwiftPM，非空Key/Token/Secret类dart-define为0；没有读取或复制旧发布签名配置。
- 本轮日志与批次汇总留在Git忽略目录 `build/ios-alignment-20261104/`，原始命令日志另存本机，不进入Git。

原生Release首次因本机缺iOS平台支持失败；按[Apple组件安装流程](https://developer.apple.com/documentation/xcode/downloading-and-installing-additional-xcode-components)通过Xcode Components恢复iOS支持与26.5 runtime后解决，未降低最低iOS或绕过平台配置。最终 `flutter build ios --release --no-codesign --no-pub` 成功，Xcode编译57秒。

- 产物：`build/ios/iphoneos/Runner.app`，60,590,429 bytes（Flutter报告60.6MB），**未签名，不是可安装/可上传的IPA**。
- 包内：`com.ugk.hipinterlude` / `1.1.0 (30)` / arm64 / MinimumOS15.0 / iPhone-only / 竖屏 / audio后台能力；211公共封面、0内置MP4。
- 7份随包隐私清单均可解析，均无tracking/collected-data声明；这只是包内静态结果，不能替代CDN日志或Apple隐私问卷核对。
- 包内私钥、OpenAI/GitHub/Google Key模式扫描无匹配；没有向构建传入AI凭据。扫描不是对任意形式秘密的绝对证明。
- 本地 `build/ios-alignment-20261104/candidate.json` 固定运行源、体积、身份、二进制哈希及未签名/未上传/未真机状态。`App.framework/App` SHA256为 `e1ec3ece6bde0d57000ab9967ad342fb54ac5b139f9b4fbce1314e243eeb45b7`。
- 完成时只读回查远端main仍4d610f5、release仍a20721e。源码提交后只补本轮文档，不重建或重复跑代码测试。

## 后续 iPhone 与发布工作

- 当前 iPhone 未连接；未安装/覆盖手机，未把旧 Build 20 的证据套到本版本。后续抽查正常字号的新首页/混合组、旧组和记录升级保存、首次下载及缓存后断网、WKWebView 视频/透明舞台，以及训练退出后音频释放。完整锁屏与听感仍按用户自行测试反馈的既有决定保留未验。
- 本轮没有访问 App Store Connect，不对 10 月 27 日后审核状态作新结论。没有上传 TestFlight、新建版本、修改商店、发送审核回复或重新送审。
- 准备下一次商店候选时，需根据实际 Apple 回复选择版本及 build，重拍新版截图、更新公开隐私政策/商店“离线”表述并复核隐私标签；当前公开政策链接仍是旧版页面，本轮未部署新文案。
- 4.3/4.2.6 的回复属于旧 1.0.0 (20) 候选。升级 SDK/扩大通用动作库不等于解决产品重复问题；后续需按 Apple 实际回复说明 HipLab 的髋自测、定向训练与进度价值。
- 改动仅本地保存；本轮尚未 push、创建 PR 或合入 main。发布记录与旧候选身份保留原文。
