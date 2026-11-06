# 首页同一视频牌面 · +44 · 2026-11-06

运行/构建源 `c0798ecc6a9ef5f91bfa0221cee5bb2c42dfad38`，独立分支 `codex/home-card-live-surface-20261106`；`1.1.0+44` / arm64 `2044`。四个实际SDK包及coach override固定 `1c082e9d3e22022f228888fdd1935b1d61371cb9`；hosted锁、Flutter3.44.7及素材内容保持。日常目录仍 `feat/ui-detail-polish@25260b3`，保持clean。

用户在+43交付后反馈展开/收起仍闪，并提出同一视频元素方案。+44将当前前牌常驻root OverlayPortal：初次准备首帧暂停，展开只改变同一牌面的矩阵/大小并播放，关闭立即暂停当前帧并缩回，compact继续显示该帧；再次展开继续播放。移除App快放回首调用、两面交接、截图捕获及专用弹层路由。

前牌媒体层级、Element/State、controller和Texture在拖动、展开、收起期间保持；playing配置恒定，只切paused。说明、剂量、标题和导航在同一face内连续布局。小源牌展开仍展示剂量/提示，关闭重置文字滚动；LocalHistoryEntry/PopScope处理返回，Escape与遮罩关闭共用收起路径，关闭期间再次back不退出Home。展开层用BlockSemantics/FocusScope隔离背景；被覆盖/交互返回期间屏蔽前牌输入并同步遮罩。手势在未变换的viewport坐标内识别，保留透视下跟手和横向阈值。

SDK新增可选 `TrainingActionMedia.prepareFirstFrame`（默认false），首次paused媒体ready后prime一次，Android首帧渲染事件后暂停；native900ms/Dart1200ms上限，仍通过原有真实首帧合成事件揭示视频，不用bool成功伪造hasFrame。展开/收起不再prime、seek、回首或销毁。原可选回首API只保留SDK兼容，App不再调用。初次素材尚未下载/准备完成时沿用公共封面与加载/错误回落；切换动作、离开首页/进入后台仍按SDK生命周期释放，当前前牌回到首帧重新准备，不建立全动作常驻decoder池。

采用Flutter内置[OverlayPortal](https://api.flutter.dev/flutter/widgets/OverlayPortal-class.html)与固定子树，无额外依赖、GlobalKey搬家或外部代码复制；常驻期间不hide portal。原生首帧处理依据[MediaPlayer首帧事件](https://developer.android.com/reference/android/media/MediaPlayer#MEDIA_INFO_VIDEO_RENDERING_START)。

App相关9文件85通过/0失败/12既有截图跳过（牌组34项）；SDK runtime相关29项通过，双方fatal-infos分析0，App严格锁解析通过，lock仅四个Git节点ref变化。未跑全量App/SDK。

逐16ms检查同一HipDrillArt Element/TrainingActionMedia State、surface/controller/texture持续存在，展开/收起无额外create/dispose、seek/return/re-prime；覆盖X/遮罩/back、快速关闭重开、暂停后关闭、小牌长说明滚动归零、Escape后第二次back、空白点击、拖牌/连续补牌/计划顺序/日期/主题。实际字体的浅深widget渲染位于下面证据目录，只检查几何与文字/封面，不模拟原生视频或声称硬件合成通过。

最终+44 release已构建、验签及资源校验，尚未由Agent安装；按用户决定交由用户远程安装测试。同一节点/纹理身份的组件回归和浅深色实际widget绘制检查已完成，原生首帧准备与真实过渡观感等待用户反馈，不能记作真机无闪烁通过。

## 包与证据

| 项目 | 事实 |
|---|---|
| APK | `E:/AII-3D/hiplab-releases/home-card-live-c0798ec-44-20261106/hiplab-1.1.0+44-c0798ec-internal-arm64-release.apk` |
| 大小 / SHA256 | 47628200字节 / `8bbeb76156b1098ab623de6c3a6b40b2222cddf10f6022e3648c9f33265e6e17` |
| 证书SHA256 | `3761270a4764157f0e389014a9e5b800b05403bfddce0f4f7f8c039f6a53bdc7`，与此前内部+43一致 |
| 内容校验 | com.ugk.hiplab/1.1.0/2044/release/仅arm64/非debuggable；789项资源；249目录动作、209授权/封面/未审AI标签，0内置MP4；r2-v1/stable |
| 构建 | 77.0秒；Android/Kotlin新指令已实际编译；重签前后runtime负载一致；原上传签名包仅本地归档 |
| App检查/渲染 | `E:/AII-3D/hiplab-releases/home-card-live-surface-20261106/` |
| SDK检查 | `E:/AII-3D/3D-Pose-SDK-worktrees/home-card-return/3D-Pose-SDK/build/home-card-return/live-surface-*.log` |

APK与签名/配置回执保存在同一交付目录。App和SDK候选分支均已推送，main/release/tag/商店保持；+43观感反馈保留为未解决历史，不改记通过。本轮无本地设备操作、iOS、模型或实际显示FPS结论。
