# iOS 与 Android 功能对齐（2026-11-04）

本轮沿用 `ios/main-alignment-20261104`，继续此前 `f961558` 的 Mac 主线适配。用户明确取消 iOS 首版的 AI/试听限制，要求功能对齐，AI Key 随后提供；此决定覆盖旧版 iOS 永久隐藏 AI 的约束。共用版本1.1.0+30、SDK693cbc02、唯一Bundle ID com.ugk.hipinterlude保持。

## 功能与范围

| 功能 | 本轮状态 |
|---|---|
| 首页、动作库、训练组、混合组、髋自测、训练记录与主题/设置 | 沿用已合main的共享实现；210组选项、211完整动作/封面，排除8条partial，未带Draft UI r3 |
| AI 定制入口 | 移除iOS强制禁用；与Android一样，仅已配置凭据且中文界面可用；空Key隐藏入口，不发模型请求 |
| SDK 聊天、计划保存/恢复与开练 | iOS复用Android同一宿主、SDK controller、storage和TrainerLauncher；未复制或新建另一套AI逻辑 |
| 语音设置试听 | iOS恢复入口；两端共用短时前台试听，结束/重复点击/离开/覆盖路由/后台/耳机或系统中断均释放会话；设置改变会停止旧试听 |
| 试听进入训练 | RouteObserver在新页构建前同步释放试听，SDK将音频end/begin串行化，避免旧试听定时器误停新训练 |
| 视频下载、缓存、断网边界 | 两端使用主线公共元数据及按需媒体，首次或缓存清理后需要联网；不回填旧MP4 |
| 训练后台音频 | iOS audio模式与Android前台训练服务按原生机制实现同一用途；这两种机制不要求代码相同，系统实际锁屏行为仍待用户测试 |
| 提醒 | 两端现有提醒偏好和2分钟椅边训练相同；不将尚未接入的系统通知描述成已实现 |

## AI 凭据接入准备

- 延续Android现有 `CoachConfig`：默认Worker中转，用 `UGK_COACH_APP_KEY`；不是新增iOS专用凭据协议。模型提供商的主Key仍留在服务端。
- `config/coach.example.json`只含公开默认值和空App Key。实际本机配置使用 `config/coach.local.json`，已加入Git忽略；本轮未创建或读取真实凭据文件。
- 后续收到Key再复制模板并填入本机私有配置，通过 `--dart-define-from-file=config/coach.local.json` 为iOS构建注入。iOS平台守卫已解除，无需再改源码才开放AI。
- 包内隐私说明按是否配置AI显示请求用途；Worker披露随机安装标识，Bearer模式不虚称发送安装标识；试听说明改为短时前台生命周期。公开政策与Apple标签需在有实际服务配置的发布候选确定后更新。

## 验证

运行/构建源码 `3a54a1bf1b5398ef1523aeda66f7011aa32fbd0d`；此前基线为 `main@4d610f5` 加首轮iOS适配提交。工具链Flutter3.44.7 / Dart3.12.2、Xcode26.6 / iOS SDK26.5，不变更pubspec/lock。

- 严格分析 `flutter analyze --no-pub --fatal-infos --fatal-warnings`：0问题，修改的Dart文件format通过；iOS工程静态检查与diff检查通过。
- 全量65个测试文件分17批、concurrency2：**468通过 / 0失败 / 68既有条件跳过**；比首轮新增14个执行用例（两端AI入口2、两端试听10、iOS隐私按认证模式2），没有删除/新增skip。
- 试听专项10通过：Android/iOS均验证自然结束只释放一次、重启/卸载释放、切后台/耳机中断不自动恢复、设置改变和关闭后不启动。新增路由用例在下一页initState立即begin音频，断言 `begin→end→begin`，且7秒后新会话不被旧定时器终止；首轮测试发现异步路由感知顺序过晚，已改为RouteObserver同步释放后通过。
- AI/隐私专项12通过：两端有配置能进入同一SDK聊天页且进入时无自动模型请求；无配置与英文门禁仍隐藏。宿主原有假模型收发、会话归档/恢复和client释放回归通过；Worker/Bearer的本机请求认证测试仍在全量集合内。UI入口验证与宿主收发验证分开，不冒称真实服务或iPhone实测。
- `flutter build ios --release --no-codesign --no-pub`成功，Xcode42.7秒；`build/ios/iphoneos/Runner.app`为60,607,014 bytes（60.6MB），未签名，不是可安装/上传的IPA。
- 包内身份1.1.0(30)/com.ugk.hipinterlude/arm64/iOS15/iPhone-only/竖屏/audio均符合预期，211公共封面、0MP4；7份隐私清单可解析。
- 非空凭据类dart-define为0，包内私钥和常见Key模式扫描无匹配。空配置模板校验通过，`git check-ignore config/coach.local.json`通过，真实本机配置尚未创建。
- AOT `App.framework/App` SHA256：`b3aa77a464dad71d034d3e1f3c8ac98281cea94ed780dc043adb48c09150ed18`。候选身份、批次、分析与构建日志留在本机忽略目录 `build/ios-parity-20261104/`。
- 前一轮edb464f未签名诊断包另存 `build/ios-alignment-20261104/HipLab-1.1.0-30-edb464f-unsigned.zip`，不与本轮源/哈希混用；该分支尚无任何30号包上传Apple，未复用已上传候选的build身份。
- Python素材校验代码与资源未再变化，沿用首轮25通过，不伪称本轮重新运行。未构建Android原生包，Android共用试听行为由平台变体回归覆盖；未执行本轮iPhone/实际声音与锁屏测试。

## 交付边界

本轮没有真实AI Key，没有向外部模型发请求；没有安装手机、签名IPA、上传TestFlight或操作App Store Connect。当前iPhone新功能、完整混合组和锁屏音频的用户测试边界保持。改动在本地iOS工作分支保存，未push/PR/合main；旧release/1.0及Build20审核记录不改。
