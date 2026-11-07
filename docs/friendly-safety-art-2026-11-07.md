# 安全提示：友善卡通插画 / 2026-11-07

用三张明确的卡通插画替换安全提示中的无脸灰色模型。用户希望人物友善、远离真人感，同时术后/限制活动与近期受伤的含义清楚可见。

- 孕产期：卡通人物坐在扶手椅安心休息，简化五官和手部，无训练示范或问题部位标记。
- 手术/限制活动：坐姿人物、辅助拐杖、膝部柔和虚线标记和绿色暂停符号。
- 近期受伤/不适：沙发休息人物、局部小绷带、暖黄色提示线和绷带符号。

素材由imagegen生成，用户先认可温暖色调，随后要求进一步卡通化并强化第二、三张的提示。首轮偏写实方案未接入。新素材在`assets/hip/onboarding/*-friendly.webp`，960×960 RGBA，保留透明背景；深浅主题共用完整人物，背景由现有页面surface提供，BoxFit.contain避免裁掉标记。三张总计251498字节。原始PNG和生成中间稿留本地交付目录，不进Git。

旧六张素材留在仓库中供追溯，但pubspec只声明新的三张，不重复打包。旧导入脚本仍适用于历史A/B方案，不能用它覆盖本轮friendly素材。

安全问题、选择结果、训练阻断和继续浏览规则、中英文文案及布局尺寸均保持；本次不是安全门禁重设计。版本递增为`1.1.0+60`，SDK/依赖lock保持。

验证：Flutter3.44.7，offline enforce-lockfile通过；语言/页面、原首次启动与安全阻断流程、资源检查共18项通过，analyze0，git diff --check通过。检查六张深浅主题三步骤的测试渲染截图，人物与标记均完整；测试图片不是手机截图。未重跑全量或iOS原生验收。

本地原图、检查和预览：`E:/AII-3D/hiplab-releases/friendly-safety-art-20261107/`。构建/安装证据另追加，不将生成或组件测试当作用户验收。


## 构建和安装回执

运行源`9a4050e7182ecdbcb3e0eaf529bc6a6256e09c46`，APK`E:/AII-3D/hiplab-releases/friendly-safety-art-9a4050e-60-20261107/hiplab-1.1.0+60-9a4050e-internal-arm64-release.apk`，48230000字节，SHA256`11fa10ed573ac66de9d162e141929a1e4a3e115a642fda0d1bee2d9ccd1b7291`。签名与+59一致，重签payload相同；APK中安全图仅三张friendly素材，逐字节匹配源文件，旧六图未打包。

真机2602BRT18C覆盖安装Success，2059→2060，启动Status: ok并观测到应用进程；无卸载/清数据。未代替用户选择安全问题或宣称插画已验收。包回执和设备日志位于`E:/AII-3D/hiplab-releases/friendly-safety-art-9a4050e-60-20261107`。代码与文档保存候选分支`codex/friendly-safety-art-20261107`，未合main。


## 2026-11-07：限制活动提示改为年轻男性 / +61已安装

按用户反馈，第二张改为约20岁的年轻男性卡通：黑色短发、卫衣、运动鞋和现代前臂拐杖，保留绿色暂停与膝部标记。只替换第二张，第一/第三张及运行代码/SDK/lock保持。运行源`7ca96179d44e216b79ffbc9b9855986f669552cc`，版本`1.1.0+61`/arm64`2061`。语言页面/首次安全流程及资源共10项通过，深浅第二张测试截图已核对，diff检查通过。纯素材和版本变更，未重复静态分析/全量测试。APK验签匹配+60、资源核对通过，SHA256`1a2e3765b744448a6ebd7937d39fa63b0fb91c4a33c2eaff6bcaae55fcfb2d10`。已覆盖安装真机2060→2061并启动ok，无卸载或清数据；视觉验收待用户。[素材及交付记录](friendly-safety-art-2026-11-07.md)。

最终素材：`assets/hip/onboarding/surgery-friendly.webp`，960×960 RGBA，89498字节。使用内置imagegen编辑原图；提示词重点：约20岁年轻成年男性、全黑短发、卫衣/运动鞋、现代前臂拐杖，保留坐姿构图、透明背景、友善卡通风格、绿色暂停符号和膝部虚线标记；不加文字或真人质感。原PNG与预览留`E:/AII-3D/hiplab-releases/safety-young-man-20261107`。APK：`E:/AII-3D/hiplab-releases/safety-young-man-7ca9617-61-20261107/hiplab-1.1.0+61-7ca9617-internal-arm64-release.apk`；安装日志/回执留`E:/AII-3D/hiplab-releases/safety-young-man-7ca9617-61-20261107`。


## 后续用户验收与主线接收

2026-11-07用户确认截至+61的本轮UI全部验收通过，授权接收main。本页此前“待用户验收/未合main”保留为当时状态；当前以[主线回执](ui-main-integration-2026-11-07.md)为准，历史独立未验项仍按回执边界区分。
