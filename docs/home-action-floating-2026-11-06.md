# 首页自由拖牌与悬浮动作卡

运行/构建源 `ba40e38a783975f17fcd682606e8b5bd092b7b25`，独立分支 `codex/home-action-deck-20261105`；`1.1.0+40` / arm64 `2040`。SDK仍固定97eb66d，lock、资源和原生配置未改。

用户已确认[+38连续补牌](home-action-deck-2026-11-06.md)测试通过，本轮在此基础上实现两项新增交互。+39/3c5ef15先在真机完成主体检查，最终+40补齐竖拖轻微横偏时的背牌稳定性；没有将+38用户确认当作+40用户验收。

## 可体验的结果

前牌任意方向跟随手指，进入窗口Overlay浮层，可经过首页标题、计划文字和底部操作栏。松手进入左右区域（横向位移超过窗口宽度26%，且横向主导）才翻页；中央快速甩动、上下或纵向斜拖都回弹。竖拖横向微偏不再改变背牌顺序。新底牌仍连续从底层背后露出。

轻点前牌，从原位置向镜头放大为一张悬浮卡。四周20pt、上下安全区额外24pt，最大460×720；柔和暗化/模糊背景，保留卡片感。动作名、实际剂量、介绍、方向/方法和注意事项在牌上展示，介绍区可滚动。视频默认循环播放，点视频原位暂停/继续；关闭、点外部和系统返回暂停并缩回，反向动画结束后恢复原牌。

视频直接用公开SDK `TrainingActionMedia(playing:..., paused:...)`；没有以`play:false`模拟暂停，没有增加下载、缓存或原生播放器适配层。SDK负责媒体校验缓存、失败重试、前后台和解码器释放。关闭前暂停、关闭完成再销毁；在禁视频策略下仍遵守原门禁。翻阅、拖动、展开都不修改训练计划、顺序或已保存选择。

## 软件与真机证据

交互主体3c5ef15完成8文件71通过/0失败/12既有截图跳过；最后仅修竖拖背牌微偏后，最终源牌组整份27/27复核、fatal-infos分析0、严格锁解析通过。其余7文件未重复跑，不声称本轮全量App测试。

新增交互覆盖全向/越界浮层、中央区域高速拖动不切牌、纵向斜拖不翻页且背牌不换向、展开边距/介绍、同一媒体Element的paused切换、外部收起和打开时卸载；原计划顺序、语义、减少动画、主题、循环及连续补牌检查继续通过。

最终软件日志：`E:/AII-3D/hiplab-releases/home-action-floating-final-20261106/`；主体8文件与开发中的失败现场：`E:/AII-3D/hiplab-releases/home-action-floating-20261106/`。最初Portal在构建期hide、PanCancel零距离弹簧阻挡轻点等问题已修复，失败记录保留。

最终+40同签名覆盖安装成功，回读2040/1.1.0。真机验证任意方向拖动可覆盖上下标题/底栏，纵向及斜纵向释放回位、横向区域切换；展开保留边距，介绍正常，视频默认帧变化、暂停帧相同、继续后帧变化，收起恢复首页。

最终证据在final目录的`native/`：`vertical-rear-stable.png`（竖拖背牌）、`expanded-playing.png`（真实悬浮卡）、`video-pause-checks.json`及对应帧、`floating-video-pause-40.mp4`、`final-home.xml/png`。视频帧比较只裁剪已观察到的媒体内部区域；不把状态栏变化算作播放，也不将录屏当作FPS基准。

+39主体真机的上下越界持指截图`08-drag-over-dock.png` / `09-drag-over-heading.png`和`free-drag-checks.json`单独留在旧目录，源3c5ef15；不会改记为+40实测。最终+40再次核查竖拖稳定、切换、展开及播放/暂停/继续。正常字号小米2602BRT18C；本轮没有iOS设备、真实模型、声音/耳机/锁屏或全量原生训练矩阵结论。

## 最终包身份

| 项目 | 实际结果 |
|---|---|
| APK | `E:/AII-3D/hiplab-releases/home-action-floating-ba40e38-40-20261106/hiplab-1.1.0+40-ba40e38-internal-arm64-release.apk` |
| 包 / 版本 / ABI | com.ugk.hiplab / 1.1.0 / 2040 / release / arm64-v8a / 非debuggable |
| 字节 / SHA-256 | 47628200 / `6b96e88dbf4495762f1ed049fa29f1be9c5f25d9b4194c130c23bb6959e85b46` |
| 证书SHA-256 | `3761270a4764157f0e389014a9e5b800b05403bfddce0f4f7f8c039f6a53bdc7`，与已装+39一致 |
| 验包 | CRC、789资产原字节、249目录/209授权/209封面/209未审标签/0内置MP4；重签前后负载相同 |
| 安装 | install -r Success，保留数据，2040回读；签名和包名连续 |
| 私有配置 | 沿用既有测试配置，经外部临时define文件注入，临时文件已删；凭据、包和设备证据不入Git |

## 参考与集成边界

借鉴官方[Flutter animations/OpenContainer](https://github.com/flutter/packages/blob/main/packages/animations/lib/src/open_container.dart)的源Rect到目标Rect及状态保持思路（[BSD-3-Clause](https://github.com/flutter/packages/blob/main/packages/animations/LICENSE)）；该组件原目标为整屏且新版增加额外依赖，未引入。使用当前Flutter3.44.7已有[OverlayPortal](https://api.flutter.dev/flutter/widgets/OverlayPortal-class.html)实现窗口层，随宿主销毁。水平/垂直手势与翻页规则分离也比较过MIT的[flutter_card_swiper](https://github.com/ricardodalarme/flutter_card_swiper)，未复制源码或新增依赖。

本轮普通推送保存独立候选；main、Draft PR31、release/1.0、tag和商店未由本轮推进。日常目录仍feat/ui-detail-polish@25260b3，使用既有E盘隔离副本；没有清理或重置其它改动。文档收束提交与上述运行/构建源分别登记，不因文档更新重复出包。
