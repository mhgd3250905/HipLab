# HipLab iOS 1.0 发布记录

更新：2026-10-24（Asia/Shanghai）。状态：**TestFlight 1.0.0 (20) 已上传、处理完成并启用开哥个人内部测试；已从 TestFlight 安装到真机并启动。完整耳机/锁屏验收仍待完成。** 未提交 App Review，未修改商店信息。

## 身份与授权

- 基线：`release/1.0@1f9a172`，独立工作分支 `ios/app-store-1.0`。**最终编译源码为 `e7ac0836eb69e1cc81c53660ac4f94e270b46538`**；其后的文档提交不改变本候选。
- App Store Connect：Hip Interlude，Apple ID `6806806172`，Bundle ID `com.ugk.hipinterlude`。已从该 App 的“App 信息”页面只读确认，未使用另一条“开胯训练助手”记录。
- 版本：仓库原有 `1.0.0+20`，未改 pubspec 或 Android。只读看到旧草稿 0.5.1、TestFlight 最新旧版本 0.7.0 (13)，本候选高于两者。
- 工具链：Flutter 3.44.7 / Dart 3.12.2，Xcode 26.6 (17F113) / iOS SDK 26.5 (23F81a)；SwiftPM、iOS 15.0、仅 iPhone、竖屏。模拟器 runtime 为 iOS 26.5 (23F77)。
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
- 原生 Release 无签名编译通过，App 111 MB；自动签名 Archive 273.6 MB、App Store IPA 导出通过。
- 上传前对 Xcode Organizer 最终准备的精确 IPA 再次验包：codesign deep/strict、arm64、Bundle ID、1.0.0/20、iOS 15、iPhone-only、audio 能力通过；App Store 分发 profile 无设备列表，get-task-allow=false、beta-reports-active=true。
- 随包 6 份隐私清单均可解析，无 tracking 或 collected data；最终 IPA 凭据模式扫描无匹配。
- 原生模拟器完成“办公室”训练：391 秒、6/6、full=true、endedEarly=false，锁屏后自然结束并保存记录；进程未重启。日志含 CoreMedia/WebKit 系统诊断，未据此宣称音频听感通过；该结果不能代替 iPhone 耳机验收。
- 真机 iPhone 16 Pro / iOS 26.5，USB + iPhone Mirroring：TestFlight 安装后 devicectl 回读 `com.ugk.hipinterlude` / HipLab / 1.0.0 / 20；首次启动、视频示范、练习库、隐藏 AI 入口、无设置试听及包内 iOS 隐私页已实际查看。首次引导使用发布验证测试档案，不代表用户的身体状况。

## 上传的精确候选

- Bundle ID：`com.ugk.hipinterlude`；版本/Build：`1.0.0 (20)`。
- Xcode 上传包：104,827,002 bytes；SHA-256：`e2203298729d6ced8ec9b09e2a8086a55dfe22c960fc60ac35ab8d0027d5f0ea`。
- 本机保存于 Git 忽略目录 `build/ios-release/upload/HipLab.ipa`；归档在 `build/ios/archive/Runner.xcarchive`。
- `flutter build ipa` 的首次导出为 104,826,944 bytes / `8ba2467f13deb519e154f8869e015419db1060ccdfa31d66da9ce8e99ee1cac5`。Organizer 上传准备会重新签名，因此以上传前复制并再次验包的 e2203298 包为最终身份，两个包没有混记为同一哈希。
- Xcode 13:57 确认 uploaded，ASC 元数据记录 13:58；Apple 后续处理完成，二进制状态“已验证”，非豁免加密“否”，SDK 23F81a、最低 iOS 15.0、arm64 与本机相符。
- Apple Build ID：`97aa451f-dede-40b7-aebf-ef2ad456257a`。现有 Internal Testing 组仅开哥 1 人，已加入此 Build，服务端状态“正在测试”；未新增测试员、未加入外部组、未提交 Beta App Review。
- TestFlight 首次使用条款经用户当次明确同意后接受；使用既有邀请完成兑换，未重发邀请，邀请链接/兑换码不写入 Git。

## 待验与处理边界

- 真机完整训练、耳机听感、退出镜像后的真实锁屏/后台、结束后的资源释放与网络行为仍待验；当前不能标记 DEVICE_VERIFIED。
- Xcode 最初缺完整 iOS Platform Support，虽然 SDK 目录存在但 generic iOS destination 不可用；经 Xcode Components 安装完整支持后解决，未降低工程最低版本绕过。安装期间产生的本轮重复 runtime、上传临时副本及构建缓存已回收，保留最终包、归档、截图和证据；不清理用户其他项目。
- App Store Connect 只读显示更新付费协议提示；本轮未接受协议或改变商店配置。如平台要求协议确认，由 Account Holder 处理。
- 商店仍沿用 Hip Interlude 原名称/描述/关键词和旧草稿版本。开哥后续手动替换本目录草稿、选择新 Build，并检查公开隐私政策与兼容运行范围；工程 iPhone-only 不等于自动关闭商店的 Apple 芯片 Mac / Vision Pro 兼容选项。

## 物料

- [中文和英文商店草稿](store-listing.md)
- [隐私标签答案与 iOS 政策补充草稿](privacy-labels.md)
- [中英文审核备注草稿](review-notes.md)
- 原生截图已完成：6.7 英寸 1290×2796、6.5 英寸 1242×2688，各 6 张；首页、练习库、动作详情、自测引导、进度及训练播放器。来自同一源码的 iOS Simulator Debug 原生运行，生产入口，未使用 widget 渲染图。交付 JPEG 均无 alpha；6.7 原始 PNG 另保留。文件及 SHA 在 `build/ios-release/screenshots/manifest.json`，不进 Git。

本地签名配置、ExportOptions、原始日志、设备资料、IPA、归档与截图均不进 Git；公开记录只保存脱敏身份和验证结论。
