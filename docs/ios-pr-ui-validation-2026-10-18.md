# iOS 共用界面 PR 验证与本轮收尾（2026-10-18）

结论：本轮 iOS 平台适配、签名构建、基础真机验证及旧 PR 收拢已交付到 [PR #16](https://github.com/mhgd3250905/HipLab/pull/16)，状态待主线审核。另对 #17/#18 固定版本完成 Mac 构建与部分原生交互验证，未发现本次覆盖范围内的明确 iOS 功能异常；不代表全量代码审核或所有真机清单通过。

## 固定对象与远端状态

22:38 北京时间回读 GitHub，以下源和目标未变化；均无 CI 或已提交 GitHub review。本次未发布 approval、review 或评论。

| PR | 固定源提交 | 实际目标 HEAD / PR 报告 baseRefOid | 状态 |
|---|---|---|---|
| [#17](https://github.com/mhgd3250905/HipLab/pull/17) | `e7cb11eda77cfbe14c968b643419daf9538b69e6` | main `fce7ad84baf5dd364afa23dd08572976792c21e4`，两者相同 | OPEN / CONFLICTING |
| [#18](https://github.com/mhgd3250905/HipLab/pull/18) | `5711b4215ee26f35a20a342168fcf91747020ecf` | fix/transition-quality `e7cb11eda77cfbe14c968b643419daf9538b69e6`，两者相同 | OPEN / MERGEABLE |

在独立 detached worktree `/Users/shengkai/ugk-hiplab-ios-ui-pr-validation` 检查并执行 #18 精确 HEAD，已含 #17 的转场实现；没有合并其他分支或修改其跟踪文件。此源**尚未包含 #16 的 iOS 隐私适配**。原始 #17/#18 的主线冲突与共用代码集成仍由 Windows 主线处理；本报告作为 Mac 验证证据，不替代合入后组合候选重测。

## 构建与候选身份

固定 Flutter 3.44.7 stable / Dart 3.12.2，Swift Package Manager；没有 CocoaPods、依赖升级、版本递增或素材同步改版。

| 检查 | 结果 |
|---|---|
| pub get --enforce-lockfile | 通过，pubspec.lock 未变 |
| flutter analyze | 通过，无问题 |
| flutter test --concurrency=1 | 178 pass / 1 按设计 skip，含转场/按钮/截图回归 |
| iOS 工程静态检查 | check_ios_project.py 通过 |
| 冻结素材 | Pose-Hub v0.2.0，92 项一致 / 0 drift |
| flutter build ios --release --no-pub | 开发签名成功，45.1 秒 |
| 包核验 | com.ugk.hiplab / 0.3.6+11 / arm64；严格深度验签通过，6 份隐私清单可解析，611 个随包文件与源 SHA 相符 |

两份 App 的显示版本相同，用源提交和 AOT SHA 区分，不能把临时 QA 包当成主线集成或商店更新：

| 用途 | 源提交 | App.framework/App SHA-256 |
|---|---|---|
| 临时 #17+#18 QA | `5711b4215ee26f35a20a342168fcf91747020ecf` | `5d1a122f74efea8d723bd80451e9fdc54295ea04b80aa94bbcefab756e18afdb` |
| 最终恢复的 #16 候选 | `2f8aeb099fae965e764fc41fd38c2c3154064766` | `5dc696ac43ee9e96c5f313667d39c383221dc75c7b21a7ae1ee044a5bf557838` |

#16 候选既有 Release / Archive、160 pass /1 skip 和隐私专项证据见 [0.3.6 对齐记录](ios-main-ui-036-2026-10-18.md)。本轮 #18 仅构建用于真机 QA 的 Release App，未为其 Archive、导出 IPA 或上传。

## 原生交互与证据边界

设备 iPhone 16 Pro / iOS 26.5，开发签名 Release，经系统 iPhone 镜像操作：

| 项目 | 实际结果 |
|---|---|
| 深色首页、新按钮/分段控件/底部分页 | 可见可操作，抽样未见遮挡 |
| 训练进入、暂停/继续、跳步、播放中关闭 | 状态切换及返回首页正常，视频可显示；未完成课程 |
| 浅色设置/首页、按钮与分段控件 | 可读、可点按，主题切换生效 |
| 隐私页右滑取消 | 左缘短拖动后仍在隐私页，取消路径可操作 |
| 隐私页右滑完成 | 左缘长拖动返回设置；非逐帧跟手/帧率测量 |
| 六项自测总览 | 六项及开始按钮同屏 |
| 自测蝴蝶式 | 原生视频可见、App 暂停控件与初始禁用的下一项状态可见，随后退出；没有填写评分或保存结果 |
| iOS 隐私正文 | 原始 #18 源仍为 Android 文案，属于已知缺少 #16；恢复 #16 后保留 iOS 文案修复 |

两种截图采样方式均未取得动画有效中间帧：串行首帧约 834/836 ms；并发请求得到操作前样本及约 915/769 ms 后样本，错过 500/420 ms 转场区间。因此只确认开始/结束状态与交互，**不判定连续无闪、WebView 变换中每帧正确、60/120 fps 或性能通过**。未继续第三次相同路径。

本轮未切换系统“减弱动态效果”做真机验收，只有代码/测试证据；未验触觉主观质量、SE/其他尺寸、强光可读性、低端设备性能。没有重做物理锁屏、ducking、静音、来电/Siri/闹钟、耳机或全课听音。历史已听部分反馈仍只覆盖当时 0.3.6 候选，不能扩为全矩阵。

## 数据保留与设备最终状态

安装前重新读取即时偏好 753 字节，原设置深色 / 15 分钟 / 英语语音。临时安装 #18 后偏好完全一致；QA 只通过 App 临时改浅色，结束后恢复深色，时长和英语选择保持。没有伪造自测结果、输入疼痛答案或清除数据。

随后成功覆盖装回已保留的 #16 候选 `2f8aeb0`，打开首页确认原界面。QA 结束、恢复安装后及再次启动后的偏好均与本轮最初的 753 字节逐字节一致；没有直接写回旧备份。手机最终运行包含 iOS 隐私修复的 #16 候选，未留下 #18 临时 QA 版本。镜像已退出，库存回读 isRunning=false。

## PR 收拢与集成边界

[#12](https://github.com/mhgd3250905/HipLab/pull/12) 和 [#15](https://github.com/mhgd3250905/HipLab/pull/15) 已关闭，未合并、未删除分支。关闭前核对：#12 的隐私功能已在 #16 按新版布局重做并补两平台测试，63 行商店历史除新增历史标记外保留；#15 的 125 行真机报告逐字节保留，clock/Timer 说明也已补齐。不要再整分支合入旧布局或旧状态台账。

#16 隐私页与 #18 对同文件的修改另用 git merge-file -p 做文本投影，退出 0，同时保留 iosPolicyUrl 和 HipChipButton。此为兼容性预检，**没有实际集成或构建组合候选**，不代替 Windows 解决 #17 与最新 main 冲突后重测。

本轮 Mac 本地适配与验证工作收束为待审核（D-25），剩余系统矩阵及未来共用 UI 合入后的重测单列 D-26。main 未合并；#17/#18 保持原目标和状态。

## Apple 与证据保存

只读访问既有 App Store Connect 审核详情，跳转登录页并返回 authResult=FAILED：会话已过期，**未取得当前审核状态**。0.3.2+7 在 09:43 送审及当时 Waiting for Review 只作历史；本轮没有商店写入、取消/重提审核、上传或发布。

构建日志、candidate.json、build-result.json、app-verification.json 在隔离 worktree 的 build/ios-pr-ui-1718/；截图、采样时间、安装/恢复日志、私有偏好和 restoration.json 在 `/Users/shengkai/ugk-hiplab-ios-device-validation/build/ios-pr-ui-1718/`。均为 Git 忽略的本机证据，未声称备份到远端；设备标识、Team 和用户原始数据不入库。原候选 App、Archive、历史 IPA 及签名资源保留。
