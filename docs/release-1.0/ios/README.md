# HipLab iOS 1.0 发布记录

更新：2026-10-24（Asia/Shanghai）。状态：候选准备，尚未上传 TestFlight。

## 身份与授权

- 来源：`release/1.0@1f9a172`，独立工作分支 `ios/app-store-1.0`。
- App Store Connect：Hip Interlude，Apple ID `6806806172`，Bundle ID `com.ugk.hipinterlude`。已从该 App 的“App 信息”页面只读确认，未使用另一条“开胯训练助手”记录。
- 版本：仓库原有 `1.0.0+20`，未改 pubspec 或 Android。只读看到旧草稿 0.5.1、TestFlight 最新旧版本 0.7.0 (13)，本候选高于两者。
- 工具链：Flutter 3.44.7 / Dart 3.12.2，Xcode 26.6 / iOS SDK 26.5；SwiftPM、iOS 15.0、仅 iPhone、竖屏。
- 用户已授权本机发布准备、自动签名、TestFlight 上传、iOS 改动提交推送到 release 并合回 main；不提交 App Review、不修改商店信息。
- 本轮用户明确要求 iOS 隐藏 AI 入口，优先于仓库旧文档“保留入口”的 Android 决定；无 Key、不传私有 define 文件，SDK 仍固定 d193a703e3a8bef6d41e7705a55ae250e23e6a69。

## iOS 范围内的调整

- Runner / RunnerTests 的 Bundle ID 改用既有 Hip Interlude 身份。
- Debug/Release/Profile 可加载被 Git 忽略的 `ios/Flutter/Signing.local.xcconfig`；本机证书团队已与当前 Apple Developer 会员信息匹配，团队配置不入库。
- 通过 iOS 平台判断隐藏练习页 AI 和用量入口；其他平台入口行为保持原样。
- 设置页旧试听会调用 begin 而没有匹配的 end；iOS 基础版隐藏该无会话试听，避免从设置页开启后台保活。训练和语音自测沿用冻结 SDK 的会话启动/结束逻辑。
- 包内隐私说明按 iOS 描述备份、本机媒体播放与会话释放，不再显示 iOS 不存在的 AI 回落入口说明及 Android 前台服务文案。
- 更新 iOS 工程静态检查与 iOS 专项回归。没有修改 Android、训练规则、SDK、依赖、素材版本或共用版本。

## 已完成检查

- 按 lock 中的 `PUB_HOSTED_URL=https://pub.flutter-io.cn` 执行 `flutter pub get --enforce-lockfile` 成功，pubspec.lock 未变化。
- 冻结 Pose-Hub v0.2.0：92 文件校验一致，无漂移。
- iOS 工程静态检查及 git diff --check 通过；SwiftPM 启用，未生成 Podfile。
- 源码凭据模式扫描未发现私钥、OpenAI Key、GitHub token 或 Google API Key。
- 最终全量测试：442 通过、1 条件跳过；iOS/AI/隐私专项 58 通过，analyze 无问题。此前首轮 441/1 为增加第二项 iOS 专测前的结果。

## 当前门槛

- Xcode 首次构建未进入编译：generic iOS destination 报 iOS 26.5 未安装。检查 SDK 目录和工具路径正常，正在安装 Xcode Components 中的完整 iOS 平台支持；不通过修改工程最低版本绕过。
- 真机：已有 iPhone 当前不可用，等待接线解锁；尚未进行完整训练、耳机听感、锁屏、崩溃和网络检查，不能标记 DEVICE_VERIFIED。
- IPA、签名验包、TestFlight Build 与远程 SHA 尚待构建和后续回读确认。
- App Store Connect 只读显示更新付费协议提示；本轮未接受协议或改变商店配置。如平台要求协议确认，由 Account Holder 处理。

## 物料

- [中文和英文商店草稿](store-listing.md)
- [隐私标签答案与 iOS 政策补充草稿](privacy-labels.md)
- [中英文审核备注草稿](review-notes.md)
- 原生截图计划：6.7 英寸 1290×2796、6.5 英寸 1242×2688；产物保存在 Git 忽略目录，不将 widget 测试图冒充原生截图。

后续上传记录必须绑定源提交、版本、Build、Bundle ID 与精确 IPA SHA-256，区分已构建、已上传、Apple 已处理和已真机验收。
