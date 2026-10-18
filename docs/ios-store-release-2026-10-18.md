# iOS 首轮商店准备与 TestFlight（2026-10-18）

北京时间 2026-10-18 **09:43**，独立 HipLab **0.3.2（Build 7）已提交正式 App Review，Apple 回读状态“等待审核”**，共 1 个项目，保持审核通过后手动发布。用户已反馈本次 TestFlight 下载并“测试通过”，Apple 测试员状态也已变为“已安装”；不将该简短反馈扩写为完整 11 项或网络抓包验收。App 尚未审核通过或公开发布。

## 候选身份

| 项目 | 实际值 |
|---|---|
| Bundle ID / Apple ID | `com.ugk.hiplab` / `6824011384` |
| 主线基线 | `12f1438`；从当时最新 origin/main 创建 `ios/store-release-032`，未沿用旧 feat/ios |
| 构建源提交 | `9c2802f1701b3d13d608db6a098548c0cca24d0b`，后续文档提交不改变产物 |
| 版本 / Build | `0.3.2` / `7`，取自 Windows 维护的 pubspec.yaml，Mac 未递增 |
| SDK | Flutter 3.44.7 stable / Dart 3.12.2；Xcode 26.6 / iOS SDK 26.5；SwiftPM |
| 实际上传 IPA | `build/ios/ipa/HipLab-XcodeUpload.ipa`，81,120,270 bytes |
| 上传 IPA SHA-256 | `d751608eb74508d4115908c3e64da420a28cd56c2a7c7b034828a0ac661caade` |
| 上传回执 | Xcode Organizer 显示 `HipLab 0.3.2 (7) uploaded`，北京时间约 01:32；Apple 列表上传时间显示 01:36 |
| TestFlight | `HipLab Internal` 含 1 个构建、1 名当前账号测试员，Apple 状态已安装；用户报告下载并测试通过，自动分发关闭 |
| 正式提交 | `bdabb199-9caf-4aea-8f39-0332b70e69bf`，2026-10-18 09:43 北京时间，1 个项目 / 0.3.2（7），状态等待审核 |

本机 release worktree 为 `/Users/shengkai/ugk-hiplab-ios-release`。Archive 在 `build/ios/archive/HipLab-0.3.2+7.xcarchive`，脱敏候选记录和原始私密日志在忽略目录 `build/ios-store/`。证书、描述文件、账号和设备标识不入 Git。

自动导出首次报 `No Accounts`，随后通过已登录 Developer 网站生成 HipLab 专用 App Store profile，使用已有有效 Apple Distribution identity 手动导出。之后 Xcode Organizer 成功识别现有团队账号，关闭版本管理并用同一 profile 重新准备最终上传包；该包再次验签通过后才上传。较早的 CLI 导出包 `HipLab.ipa` 未上传，其 SHA 不作为本次 TestFlight 身份。

## 代码与验证

本次只调整 iOS 隐私页及其测试：iOS 使用独立政策链接，明确删除 App 与卸载 App 的差异、Apple 系统备份及本地媒体访问；Android 文案和链接保持原状。未修改依赖、pubspec.lock、版本号、assets、tools 或素材 lock。

| 检查 | 结果 / 范围 |
|---|---|
| `flutter pub get --enforce-lockfile` | 通过，lock 无差异 |
| `flutter analyze --no-pub` | No issues found |
| `flutter test --no-pub --concurrency=1` | 117 项通过，含 iOS 隐私文案/复制链接回归 |
| 冻结素材校验 | 92 个 Pose-Hub 文件 SHA 匹配，未运行素材同步 |
| Release Archive / 分发导出 | 成功；未新建工程、未使用 CocoaPods、未提交 Team ID |
| 最终上传 IPA | deep/strict codesign 通过，Bundle/版本/Build 精确匹配、arm64、get-task-allow=false；embedded profile 为 App Store 分发，6 份隐私清单可解析，均无追踪和收集声明 |
| iOS 原生模拟器 | 同源 Debug 构建成功；iPhone 16 Pro Max 与 iPhone 17 Pro / iOS 26.5 运行、引导、首页、自测示范、训练视频和暂停可操作；当前抽查未见原生播放按钮/灰底/白框，不能替代全量首帧或真机检查 |
| 商店截图 | iPhone 17 Pro 原生 `simctl` 截图 4 张，1206×2622；首页、自测总览、自测示范、训练，已在独立页面回读确认 4/10 持久保存。另保留 1320×2868 原始截图，未上传 |
| TestFlight 真机反馈 | 用户在本次 Build 7 下载验收请求后回复“我下载了 测试通过”，Apple 内部测试员状态回读为已安装；本轮未重新提供设备型号/iOS，未提供逐项 11 项或网络抓包结果，按用户报告的基本验收记录 |

截图是原生模拟器实际渲染；引导和页面状态为本次专用模拟器示例，不是真实用户健康资料。没有修改截图 UI 或伪造训练历史。Apple 2026-10-15 更新后的[截图要求](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications)以中等显示屏灵动岛 iPhone 为必填，本轮按当前页面采集。

## 商店记录

旧 Hip Interlude 已有上传历史，Bundle ID 为 `com.ugk.hipinterlude`，无法改为本项目身份；按用户“可复用则复用，否则独立”的授权新建 HipLab，旧 App 未修改。新条目名为「开胯训练助手」，主要语言简体中文，分类健康健美，SKU `HipLab001`。

- 商店名称、副标题、描述、关键词、版本 0.3.2 与手动发布策略已保存。
- 价格为免费；174 个国家/地区在发布时供应，未启用未来地区自动供应。暂无 ICP 备案号，首轮不选中国大陆；见 [Apple 备案状态说明](https://developer.apple.com/cn/help/app-store-connect/reference/app-information/app-and-submission-statuses)。
- 已关闭 Apple 芯片 Mac 与 Apple Vision Pro 供应。仅 iPhone 工程不新增 iPad 目标。
- 年龄问卷如实声明健康健身主题，成人目标人群覆盖到 18+；无医疗治疗信息、UGC、广告、聊天、赌博或暴力内容。受监管医疗设备声明为否。内容版权声明已填写，使用现有授权素材和字体。
- App Privacy 的“不收集数据”答复已发布，重新打开页面确认草稿发布按钮消失、未收集数据声明保留。依据源码、本机回环媒体路径、最终 IPA 的 SDK/隐私清单与用户本次测试反馈；未声称进行了真机网络抓包。
- 审核说明已解释离线内容、无需登录、本机回环媒体服务及后台语音间隔的静音片段用途，不把静音保活写成音乐播放。2.5.4 风险仍保留。
- 正式版本已选择 Build 7、取消“需要登录”并保存成功；正式/Beta 联系人后来按用户明确提供的资料更新，重新打开页面核验一致，资料不写入仓库。提交预检发现内容版权原先未持久保存，补充保存后独立回读确认拥有第三方内容必要权利；18+、健康健美及非受监管医疗设备声明均再次确认。最终正式审核已提交。

iOS 专属[隐私政策](https://mhgd3250905.github.io/HipLab/ios/)与[支持页](https://mhgd3250905.github.io/HipLab/ios/support.html)由 [PR #11](https://github.com/mhgd3250905/HipLab/pull/11) 发布到 gh-pages，merge `29d983b`，Pages built 与两页 HTTP 200 均已核验；原 Android 政策不变。

## 正式送审结果与后续

1. 此前约 02:04 Mac 无法连接 iPhone，候选因此等待用户验收；用户随后通过 TestFlight 下载并报告测试通过，Apple 显示已安装，已记录为本次 Build 的用户基本验收，旧 0.1.2+3 结论未挪用。
2. 对精确 Build、商店必填资料、隐私答复和手动发布设置复核后，先“添加以供审核”，核对唯一项目为 0.3.2（7），再按用户既有正式送审授权提交。Apple 显示“已提交 1 个项目”；[审核详情](https://appstoreconnect.apple.com/apps/6824011384/distribution/reviewsubmissions/details/bdabb199-9caf-4aea-8f39-0332b70e69bf)独立回读为**等待审核**。没有取消或重复提交。
3. 后续等待 Apple 审核结果。“等待审核”不等于“审核中”或“已批准”；即使通过也保留手动发布，本次没有点击正式公开发布。未邀请外部测试员、未提交 Beta Review、未建立公开链接。
4. 完整 11 项系统行为、精确设备型号/iOS 复核及隐私网络抓包仍没有逐项证据，后续质量验证继续保留在[验证台账](verification.md)，不作为已经全量通过的结论。

用户已授权本轮自动签名、必要 Apple 注册/更新，以及按建议推进商店准备、上传与正式审核；随后明确提供审核联系人，并反馈本次 TestFlight 测试通过。本轮建档、上传和正式送审已实际完成，审核决定与公开发布属于后续状态。
