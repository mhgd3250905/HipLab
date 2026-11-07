# iOS 同步已验收主线（2026-11-07）

## 集成范围

在原独立工作副本 `ios-main-alignment` 创建本地分支 `ios/main-alignment-20261107`，保留原分支 `ios/main-alignment-20261104@fe9d735`。将远端 `main@54471ae2038d6ce2033aed77180a3663f23da450` 完整合入，未选择性拼接候选分支。同步主线 `1.1.0+61` 与四实际 SDK 包及 coach override 的 `fa957ff405cc57cd10d53987430313822ff20607`，pubspec/lock 与远端完全一致。

包含 r2-v1 公共目录、问答 v3、UI r4、新首页持久视频动作牌与拖动/展开/收起、推荐文件夹、导航性能与按钮锚点、立体条目图标、中英文界面及友善安全插画。公共目录249项、授权封面209张；不恢复旧内置视频。主线未收录的独立 SDK 语音/计数候选没有混入。

## iOS 差异处理

- 保留 `com.ugk.hipinterlude`、iOS15、iPhone-only、SwiftPM 和后台 audio 能力及中文桌面名。
- 保留上一轮 iOS AI 开放授权；跟随主线中英文支持，只以有效配置判断 AI 入口。未配置时继续隐藏。保留 SDK 现有问答、计划保存和开练流程，不重写 SDK。
- 新版设置界面接入既有短时试听组件；保留自然结束、重复点击、设置改变、路由退出/覆盖、后台与音频中断释放；增加试听中英文标签。
- 隐私页使用新版导航和中英文布局，保留 iOS 专属政策 URL、媒体按需下载及网络披露、试听释放说明。Worker/Bearer 的安装标识披露跟随实际注入配置，中英文均覆盖。
- 更新既有实模探针的 SDK 身份常量，但本轮没有向付费模型发请求；历史实模证据不作为当前 SDK 的验证。
- 文档冲突合并保留两端历史，页首最新说明作为当前事实。

## 验证

- 最终严格静态分析0问题；Flutter全量 **640通过 / 0失败 / 70既有条件跳过**（截图、导出或需Impeller的专项未启用）。首轮2项旧中文隐私fixture因英文默认locale失败，显式指定中文后修复；中英文Worker/Bearer隐私专项5项通过，随后完整复跑通过。没有删除或增加跳过。

- 固定 Flutter3.44.7 / Dart3.12.2。首次沿用旧镜像解析因远端已切 `pub.dev` 被严格锁检查拒绝；改用远端原有 `pub.dev` 后 `pub get --enforce-lockfile` 成功，锁文件未改。
- iOS 项目静态检查通过；相对远端 main 的 diff 检查通过。合并引入的上游 fixture receipt 使用CRLF，默认staged检查将其判为空白；允许CR行尾的staged检查通过，未改写上游fixture。
- `flutter build ios --release --no-codesign --no-pub --config-only` 成功，生成配置为1.1.0/61，非空Key/Token/Secret类define为0；此项仅验证工程配置，不代表原生编译。
- Python 25项中22通过、1失败、2错误：旧剂量投影来源摘要未随英文 action-kit 变化同步（另一个 check 因此失败），旧素材检查仍引用 SDK 已删除的 `app-test-pack-r1` 并断言211张封面。这些输入、脚本及旧断言均来自 main，本轮没有改写主线生成目录或补旧资源以绕过检查。可选 jsonschema 未安装。
- 未签名 Release 构建已尝试，但 Xcode26.6 报 `iOS 26.5 is not installed`，generic iOS destination 不可用；`simctl` 无已注册 runtime，scan-and-mount 未发现可恢复项。虽然 showsdks 列有 SDK，原生构建仍不具备可用目的地。本轮没有生成新 Runner.app/IPA。

## 产物和后续

旧带内部凭据的 +30 原生构建完整移至 Git 忽略目录 `build/ios-ai-configured-20261104/native-build-preserved-20261107/`，未删除；其中 `iphoneos/Runner.app` 仍是旧构建。原有候选身份和 ZIP 保留。

本轮构建命令显式将两个 AI 凭据 define 置空，仅用于无凭据编译验证；不读取、复制或输出私有配置，没有新配置包。源码已支持有配置时的 iOS AI；带配置的新版构建及真实模型/iPhone验证仍待进行。

先在 Xcode Settings > Components 恢复 iOS26.5 平台支持，再重跑本地 Release 构建并验包，随后准备签名/设备安装。当前可用磁盘约9GiB，不自动下载大体积组件或清理用户文件。真机首页视频纹理/着色器、转场、旧数据、中英文和AI均未新增实测证据。原release/1.0、远端main、商店、TestFlight均未写入，未push/PR或公开发布。
