# HipLab UI 实现与复用手册

这套手册把已经在 HipLab 中落地、经逐轮真机反馈修正的界面拆成可阅读的设计规则、组件合同、接入配方和失败案例。通用画廊与迁移配方沿用用户验收的 +61，参考源码为 main `84202688b3c43015c0f8c66d8b9d7b07988f3e8b`。它用 Flutter 绘制仿 iOS 主体界面。会员页 v2 直接参考本仓库当前页面及测试。

先看规则，再运行例子，再按依赖边界迁移。此目录没有发布独立 Pub 包；`.dart` 示例在本仓库中可分析，并通过`gallery.dart`开发入口运行，跨 App 使用前需要迁移它们引用的组件及主题/语言适配。不能只复制一个页面、漏掉它依赖的返回键和动画层。

## 阅读顺序与交付物

| 要解决的问题 | 规则与配方 | 完整样例 |
|---|---|---|
| 色彩、字级、间距、单位、深浅和语言边界 | [01 基础与依赖](01-foundations.md) | [画廊宿主](examples/gallery.dart) |
| 状态栏、Topbar、固定返回键、push/pop/侧滑及模糊性能 | [02 导航与玻璃](02-navigation.md) | [导航路径](examples/navigation_example.dart) |
| 设置分组、开关/分段/滑块、确认框、图标和插画 | [03 列表与控件](03-controls.md) | [设置页](examples/controls_example.dart) |
| 卡片/文件夹、视频持帧、防闪烁与物理退场 | [04 动效与媒体](04-media-motion.md) | [共享媒体子树教学页](examples/media_handoff_example.dart) |
| 其它 App 怎样分批接入、怎样判断做没做歪 | [05 移植与验收](05-adoption-validation.md) | [样例验证](examples/gallery_test.dart) |
| 会员页两态、固定操作区与有效期 | [会员页 v2](../ui-design-standard.md#7-会员页-v2) | [当前页面](../../lib/hip/ui/hip_membership_page.dart)、[组件测试](../../test/hip/hip_membership_page_test.dart) |

HipLab 的当前设计数值仍以[UI 设计规范](../ui-design-standard.md)为项目内唯一规范入口；本手册解释为什么、如何接入及如何复用。以后修改设计，应先改规范，再同步这里的样例/参数，不在两个地方分别发明数值。历史交付报告只说明当时发生了什么。

## 先运行，再迁移

在已有本项目 Flutter 3.44.7 依赖解析的环境中，从仓库根目录运行。画廊是当前工程的另一个开发入口，沿用工程包名/资源，并非独立安装包；设备运行请使用你的测试副本或测试设备。

```bash
flutter pub get --enforce-lockfile
flutter analyze --no-pub docs/ui-kit/examples
flutter test --no-pub docs/ui-kit/examples/gallery_test.dart
flutter run -t docs/ui-kit/examples/gallery.dart -d DEVICE_ID
```

画廊默认中文浅色；用下面的入口配置观察英文深色。`DEVICE_ID` 替换为你自己的设备，手册命令不是本阶段已执行安装的证据。

```bash
flutter run -t docs/ui-kit/examples/gallery.dart -d DEVICE_ID \
  --dart-define=UI_KIT_DARK=true --dart-define=UI_KIT_LANGUAGE=en
```

例子直接使用生产组件，导航页和设置页不是另一套看起来相似的重复实现。媒体教学页用假媒体演示 State 身份、播放时序和取消过期回调；它不解码视频，不代表真实 Android Texture、透明视频合成或原机流畅度已验证。

导航配方的正文保留中文教学标签；English配置用于观察通用导航语义、控件长文案与媒体说明的布局。目标App应接入自己的完整文案来源，不把示例教学文字当作已翻译的业务内容。

## 不要复活的历史方案

| 历史尝试 | 当前采用的规则 |
|---|---|
| 整个顶栏固定，只有正文横移 | 只有返回胶囊可固定；背景/正文/玻璃/标题/右操作/底栏同一表面移动 |
| 返回键在 44/52pt 标题行中分别居中 | 按钮固定在状态栏下 44pt 控制轨道，副标题只扩展文字和背景 |
| 用 SizedBox/RepaintBoundary 当作滤镜裁剪 | 模糊外层必须有真实 paint ClipRect |
| 双播放器、截图交接、快放回第一帧 | 同一个媒体节点展开/收回；关闭暂停当前帧 |
| 后牌到顶才建播放器、首帧到达就自动换面 | 相邻牌有界预备；冷牌锁封面，到用户主动展开才揭示 |
| 长按吸附、竖向匀速或把甩速全部压至900 | 长按专门行为已撤回；当前任意方向拖动和投影离屏弹簧 |
| 文件夹四图凑数、两项居中、外14/内8圆角 | 真实组数、两个在上排、外12/内6，右下锚定 |
| 将功能按钮都画成微型立体插画 | 立体图标用于列表装饰；返回/关闭/播放等功能图形保持简洁 |

## 会员页 v2

会员页的当前规范、色值和布局参数见[会员页 v2](../ui-design-standard.md#7-会员页-v2)。复用时从 [HipMembershipPage](../../lib/hip/ui/hip_membership_page.dart) 查看两种状态如何共用滚动区、固定底栏、权益卡和法律链接。页面从有效 entitlement 展示方案、有效期和续订状态，权益判定、价格与交易由宿主已有的会员和商店层提供。

有效期起止使用 entitlement 的最近购买时间与到期时间，短周期格式和取消续订文案见规范。卡片以 180dp 为最小高度，窄屏放大字号时由内容增高。[组件测试](../../test/hip/hip_membership_page_test.dart) 使用固定时钟和模拟商店覆盖两种页面、续订状态、47/48 小时时间格式以及 Android／iOS 的 360dp、1.5 倍字号。设置 `HIPLAB_MEMBERSHIP_ARTIFACT_DIR` 可在同一测试中导出 1080px 宽的两态截图。

```bash
flutter test --no-pub test/hip/hip_membership_page_test.dart
```

## 源码定位

- [首次 AI 数据共享同意](../ui-design-standard.md#首次-ai-数据共享同意)采用系统底部弹层。会员校验完成后展示说明，应用内隐私页处理撤回，发送层在每次请求前检查同意。

- 导航、分组行、开关/滑块/确认框：[hip_page_kit.dart](../../lib/hip/ui/hip_page_kit.dart)、[hip_routes.dart](../../lib/hip/ui/hip_routes.dart)。
- Token、字体、曲线：[hip_theme.dart](../../lib/hip/ui/hip_theme.dart)；通用按压/按钮/媒体宿主：[hip_widgets.dart](../../lib/hip/ui/hip_widgets.dart)。
- 分段、图标、玻璃：[hip_segmented.dart](../../lib/hip/ui/hip_segmented.dart)、[hip_row_icons.dart](../../lib/hip/ui/hip_row_icons.dart)、[hip_glass.dart](../../lib/hip/ui/hip_glass.dart)。
- 牌组、单牌、文件夹：[hip_home_action_deck.dart](../../lib/hip/ui/hip_home_action_deck.dart)、[hip_home_action_inspect.dart](../../lib/hip/ui/hip_home_action_inspect.dart)、[hip_home_routine_folder.dart](../../lib/hip/ui/hip_home_routine_folder.dart)。
- 主体接入、主题/locale 和插画：[hip_app.dart](../../lib/hip/ui/hip_app.dart)、[hip_text.dart](../../lib/hip/ui/hip_text.dart)。

本手册覆盖主体界面。业务规则、安全准入、动作目录、AI 会话和底层媒体实现各归原模块；复用设计不意味着复制业务数据、素材许可或把 App 私有组件变成 SDK 的公共 API。验证层次见[移植与验收](05-adoption-validation.md)。
