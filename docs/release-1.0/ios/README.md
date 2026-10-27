# HipLab iOS 1.0 发布记录

**2026-10-27 更新：** Apple 已拒绝 1.0.0 (20)，涉及 4.3 和 4.2.6；审核员要求说明产品差异、相关 App、测试反馈和内容归属。开哥确认自主开发及仅推进当前记录，并授权向 Apple 回复；九项说明已发送，等待 Apple 反馈，尚未重新提交。详见[拒审与处理记录](review-2026-10-27.md)。以下 2026-10-24 的等待审核状态保留为提交时历史。

更新：2026-10-24 16:05（Asia/Shanghai）。状态：**HipLab 1.0.0 (20) 已正式提交 App Review，Apple 回读 WAITING_FOR_REVIEW（等待审核），审核通过后手动发布，尚未公开发布。** TestFlight 内部测试与真机安装已完成；用户决定后续亲自测试迭代，声音/耳机和完整训练/锁屏验收保留未验。

## 身份与授权

- 基线：`release/1.0@1f9a172`，独立工作分支 `ios/app-store-1.0`。**最终编译源码为 `e7ac0836eb69e1cc81c53660ac4f94e270b46538`**；其后的文档提交不改变本候选。
- App Store Connect：Hip Interlude，Apple ID `6806806172`，Bundle ID `com.ugk.hipinterlude`。已从该 App 的“App 信息”页面确认；另一条“开胯训练助手”记录仅用于只读复用同账号既有审核联系人，未修改或取消其审核。
- 版本：仓库原有 `1.0.0+20`，未改 pubspec 或 Android。只读看到旧草稿 0.5.1、TestFlight 最新旧版本 0.7.0 (13)，本候选高于两者。
- 工具链：Flutter 3.44.7 / Dart 3.12.2，Xcode 26.6 (17F113) / iOS SDK 26.5 (23F81a)；SwiftPM、iOS 15.0、仅 iPhone、竖屏。模拟器 runtime 为 iOS 26.5 (23F77)。
- 用户已授权本机发布准备、自动签名、TestFlight 上传、iOS 改动提交推送到 release 并合回 main；随后明确回复“授权填写资料并提交审核”，覆盖最初第七条。授权目标仅为本条 App 记录及精确候选；保留手动发布，没有执行公开发布。
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
- 后续真机观察：15:12开始测试，退出镜像后确认设备锁定；约9分钟内 App PID 保持10545，未新增 Runner 崩溃报告。重新连接镜像时训练处于暂停，仍在第1/6动作，未自然完成；暂停原因未继续排查。按用户最新要求停止扩展测试并正常结束，保存45秒、0/6、endedEarly=true、full=false的测试记录，不计完成天数；未清除数据，不把这条记录写成整节通过。

## 上传的精确候选

- Bundle ID：`com.ugk.hipinterlude`；版本/Build：`1.0.0 (20)`。
- Xcode 上传包：104,827,002 bytes；SHA-256：`e2203298729d6ced8ec9b09e2a8086a55dfe22c960fc60ac35ab8d0027d5f0ea`。
- 本机保存于 Git 忽略目录 `build/ios-release/upload/HipLab.ipa`；归档在 `build/ios/archive/Runner.xcarchive`。
- `flutter build ipa` 的首次导出为 104,826,944 bytes / `8ba2467f13deb519e154f8869e015419db1060ccdfa31d66da9ce8e99ee1cac5`。Organizer 上传准备会重新签名，因此以上传前复制并再次验包的 e2203298 包为最终身份，两个包没有混记为同一哈希。
- Xcode 13:57 确认 uploaded，ASC 元数据记录 13:58；Apple 后续处理完成，二进制状态“已验证”，非豁免加密“否”，SDK 23F81a、最低 iOS 15.0、arm64 与本机相符。
- Apple Build ID：`97aa451f-dede-40b7-aebf-ef2ad456257a`。现有 Internal Testing 组仅开哥 1 人，已加入此 Build，服务端状态“正在测试”；未新增测试员、未加入外部组、未提交 Beta App Review。
- TestFlight 首次使用条款经用户当次明确同意后接受；使用既有邀请完成兑换，未重发邀请，邀请链接/兑换码不写入 Git。

## 正式审核回执（2026-10-24）

- 用户当次明确授权填写资料并提交审核，已按该授权执行，不再沿用原“仅交付草稿”边界。
- 提交时间：**2026-10-24 16:05:07 +08:00**（Apple `2026-10-24T08:05:07.745Z`）。
- 提交 ID：`5f1196c4-3a44-4105-9833-4175e0fca7c5`；版本 ID：`ea625cfe-13fb-481a-aa94-a1f2671a9695`。
- [App Review 回执](https://appstoreconnect.apple.com/apps/6806806172/distribution/reviewsubmissions/details/5f1196c4-3a44-4105-9833-4175e0fca7c5)显示已提交 1 个项目，`iOS App 1.0.0 / 1.0.0 (20)`、等待审核；提交响应和服务端回读均为 `WAITING_FOR_REVIEW`。未停留在草稿或“添加以供审核”。
- 英语（美国）与简体中文的名称、副标题、推广文本、描述、关键词、支持链接已保存；主语言仍为英语（美国），如实说明主界面中文、无在线 AI、无账号及提醒功能范围。内容见 [已提交文案](store-listing.md)。
- 审核信息取消“需要登录”，复用同账号既有审核联系方式，加入离线使用、后台音频训练用途、复现步骤及非医疗说明。个人联系方式仅留在 Apple，不写入 Git。
- 隐私标签确认为“未收集数据”；双语政策指向[当前 iOS 隐私政策](https://mhgd3250905.github.io/HipLab/ios/hipinterlude/)，支持指向[当前 iOS 支持页](https://mhgd3250905.github.io/HipLab/ios/hipinterlude/support.html)。两页公开 HTTP 200 且正文逐字匹配 `gh-pages@5071c13e877b5c60963beef11c50244479332944`；保留原 Android 和另一 Bundle ID 的政策。
- 内容版权按包内 `assets/licenses/Drill-media-ATTRIBUTION.md` 的 Snow 衍生素材许可，填写“包含第三方内容且拥有相应必要版权”；受监管医疗设备填写“否”。保留原有年龄分级、分类和非交易商状态。
- 设置首版免费下载（基准 USD $0.00，各地区对应免费）；供应范围保留原中国大陆 1 个地区，未扩大地区。关闭 Mac 和 Vision Pro 兼容分发，保留公开分发方式与**手动发布**。
- Apple 提交校验发现旧草稿的 4 张 iPad 截图处理失败；已从本版本移除这些过时素材关系，素材库保留。iPhone 三组共 18 张当前截图均已处理并生成有效缩略图，中文使用主语言截图；随后校验及正式提交成功。
- 本阶段只修改商店/政策与发布文档，未重建、未再次上传 IPA，候选源码和 IPA SHA 均保持不变。声音/完整锁屏测试的用户暂缓决定未改写成通过。

## 待验与处理边界

- 用户明确“声音部分可以不用测试，跳过，我确认ok，后续自己使用测试反馈”，随后要求首版优先完成申请、后续亲自测试迭代。因此声音/耳机专项主动跳过，完整训练与锁屏持续播放保留未验，由用户后续反馈；不再等待耳机就绪，不标记 DEVICE_VERIFIED 或听感实测通过。结束后的资源释放及隐私网络行为也不扩写为已完成真机专项。
- Xcode 最初缺完整 iOS Platform Support，虽然 SDK 目录存在但 generic iOS destination 不可用；经 Xcode Components 安装完整支持后解决，未降低工程最低版本绕过。安装期间产生的本轮重复 runtime、上传临时副本及构建缓存已回收，保留最终包、归档、截图和证据；不清理用户其他项目。
- App Store Connect 曾提示更新付费协议；本轮没有接受新合同。免费候选已成功提交，该提示没有阻塞本次送审。
- 商店文案与版本已替换、精确 Build 20 已选入；Apple 芯片 Mac / Vision Pro 兼容分发均已关闭。等待 Apple 实际审核结果；如需公开发布，再由用户明确决定。

## 物料

- [已提交的中文和英文商店文案](store-listing.md)
- [隐私标签答案与已公开 iOS 政策](privacy-labels.md)
- [中英文审核备注](review-notes.md)
- 原生截图已完成并上传：6.7 英寸 1290×2796、6.5 英寸 1242×2688，以及按 ASC 新必填项补拍的 6.3 英寸 1206×2622，各 6 张；首页、练习库、动作详情、自测引导、进度及训练播放器。来自同一源码的 iOS Simulator Debug 原生运行，生产入口，未使用 widget 渲染图。交付 JPEG 均无 alpha；原始 PNG 另保留。文件及 SHA 在 `build/ios-release/screenshots/manifest.json`，不进 Git。

本地签名配置、ExportOptions、原始日志、设备资料、IPA、归档与截图均不进 Git；公开记录只保存脱敏身份和验证结论。
