# 首页推荐训练组文件夹 · +53 · 2026-11-06

构建源`2d46ab1e4fcc0d696ae3748330863ccb93fb94aa`，分支`codex/home-routine-folder-20261106`，版本`1.1.0+53` / arm64 `2053`；四个实际SDK包及coach override仍固定`6fbd7de15dea62c7152eac43df1303b85d887a7c`。日常目录`feat/ui-detail-polish@25260b3`保持，+52用户已验收记录保留。无main/release/tag/商店操作。

## 用户结果

原循环“换一套”改为64pt圆角玻璃文件夹，2×2显示四个真实动作封面。预览先取每组首动作，办公只有两组时用同组后续动作补足四格；展开数量仍是当前sceneRoutines返回的实际有效训练组，不虚构四组。使用与首页相同的筛选、名称和计划分钟数，舞蹈组仍受原profile规则控制。

点按后玻璃面与四个缩略图由原位展开成有四周留白的两列网格，显示当前选中勾选、组名、时长和动作数。仅静态TrainerPoster，沿用已暖的精确bundle/decodeWidth缓存，不新增播放器或修改SDK。选择结果在整个300ms收起动画结束后提交；打开、取消、重复选择不换首页动作、不自动开练，选择各scene本次启动记忆，开始按钮走原完整计划。保持+52已验收的首页持帧/冷帧保护与运动参数。

## 连续性与关闭

展开360ms、收起300ms；网格固定排版画布，圆角面和图片矩形连续插值，不在每帧重排文字。源图在动画dismissed同帧恢复，结果仍等route.completed，避免浮层移除后源图空一帧。滚动后仅完整可见的封面按实际坐标回飞，未完整展示项在源格末段淡回，防止裁剪图突然完整出现。关闭键、外部、系统返回、Escape均可关闭；关闭期间Home的PopScope拦住第二次返回，避免退出App。减少动画零时长，失效场景/计划快照自动关闭；源组件销毁安全移除对应route。

设计前对照了Flutter维护的[animations容器变换源码](https://github.com/flutter/packages/blob/main/packages/animations/lib/src/open_container.dart)及[BSD许可证](https://github.com/flutter/packages/blob/main/packages/animations/LICENSE)：借鉴原位容器和内容交接思路，没有复制代码。OpenContainer面向铺满Navigator的页面，本轮是有边距的文件夹；沿用本项目PopupRoute/玻璃组件，不引入其依赖或升级锁文件。相关[官方变更记录](https://pub.dev/packages/animations/changelog)的裁剪/阴影边界用于审查参考，本轮以自身截图和回归为准。

## 验证与边界

严格offline/enforce-lockfile成功、pubspec.lock字节保持，fatal-infos分析0。原相关10文件108通过/0失败/14既有跳过（12历史截图、2需Impeller）；文件夹新文件7项另通过，总计11文件115通过/0失败/14跳过。新增两项Home集成验证取消保持原State/Texture和非相邻直选、按scene选择及真实开始计划；组件覆盖四封面无video、360ms逐帧有界与固定排版、源图交接、多种关闭/连续返回、延后且单次选择、320/394双主题与横屏滚动、减少动画和失效清理。首次核心测试的SemanticsHandle清理问题已修正后重跑通过；旧失败日志保留。

两张组件截图加载真实NotoSansSC字体后人工查看，暗浅色标题、封面、选中标识和版式正常；Ahem首轮截图保留。组件图使用合成五组数据和测试用平阴影，不能替代手机视觉验收。代码最后仅将body的矩形裁剪补为随面板圆角裁剪以约束滚动边缘，组件7项与截图重跑通过。SDK/Native/动作牌算法无改动，不重复已有Impeller/SDK/全量/模型/iOS测试。

本地证据`E:/AII-3D/hiplab-releases/home-routine-folder-20261106/`，暗/浅图在folder-previews，原始安装和包验证日志在交付目录；这些本地文件未作为Git附件上传。

## 包与安装

| 项目 | 事实 |
|---|---|
| APK | `E:\AII-3D\hiplab-releases\home-folder-2d46ab1-53-20261106\hiplab-1.1.0+53-2d46ab1-internal-arm64-release.apk` |
| 大小 / SHA256 | 47693736字节 / `f0093ea6babb6068c61d2f0f2846d9e2ac483158967efa55586950ea72582878` |
| 证书SHA256 | `3761270a4764157f0e389014a9e5b800b05403bfddce0f4f7f8c039f6a53bdc7`，与已验收+52内部包一致 |
| 身份 | com.ugk.hiplab / 1.1.0 / 2053 / release / 仅arm64 / 非debuggable；重签负载一致 |
| 内容 | 789资源项校验；r2-v1/stable、249目录动作、209授权/封面/未审AI标签、0内置MP4 |

已同签覆盖安装真机，包管理器回读2053、MainActivity启动成功。新文件夹观感待用户确认，自动检查与手机验收分别记录。

安装回执：`E:\AII-3D\hiplab-releases\home-folder-2d46ab1-53-20261106\device-install.json`。未卸载或清数据；这里只按实际结果记录安装/启动，现场操作证据另列，不扩大为整App验收。
