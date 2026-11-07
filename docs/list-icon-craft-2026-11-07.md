# 列表图标整套优化 / 2026-11-07

按用户反馈重画整套18类条目前导图标：训练组卡片、动作书册、髋关节、记录日历、设置齿轮，以及提醒、椅边练习、语音、提示音、语言、音量、外观、安全、隐私、新建、AI、完成/暂停。统一玉绿、浅瓷和金属材质、方向一致的高光与侧壁；深浅主题适配。30pt图标列、52/60pt行高和文字位置保持。

## 实现

`lib/hip/ui/hip_row_icons.dart`内原创64单位矢量造型，统一经`HipRowEmblem`绘制。18个语义角色覆盖17个原始glyph，更多页“设置”显式选择齿轮，设置页“颜色”用明暗球体。提醒、语音、语言与音量等条目自动沿中央映射更新；动作详情“添加到训练组”选择行也接入，保留原40pt外占位、禁用状态和行交互。

立体感来自材质渐变、实体侧壁及细倒角；图标没有图片解码、BackdropFilter、saveLayer、常驻ticker或新增依赖。`ExcludeSemantics`保持装饰性，整行原有点击、键盘和语义保留。导航按钮、重排把手及其它功能性`HipIcon`未改。

对比过维护中的[Fluent System Icons](https://github.com/microsoft/fluentui-system-icons)和[Phosphor Flutter](https://github.com/phosphor-icons/flutter)，二者为MIT许可；借鉴统一视重和语义区分思路。本轮所有轮廓自行绘制，未复制其路径/素材，不引入图标包。预览由真实Flutter绘制与NotoSansSC字体导出，属于组件画板，不冒充真机截图。

## 检查与边界

- Flutter 3.44.7；offline enforce-lockfile pub get成功，锁文件保持；`flutter analyze --no-pub`为0。
- 相关12文件：128通过、14既有跳过、0失败。新5项检查18角色深浅主题静态绘制、实际渲染区分、设置/外观映射、行高/文字起点、图标装饰语义、指针/键盘及完整画板无异常。
- 初次图标测试把整个现有语义树的按钮数写死为2，实际有4个嵌套标记；测试已改为检查图标自身无独立语义和交互节点，生产语义未改。最终12文件运行全部通过。
- 深浅画板和实际30pt列表示例已目视检查；独立只读代码复核未发现绘制越界、资源或布局回归。
- 真机同签覆盖安装2056→2057，启动成功；更多、设置（含下部安全/隐私）、训练组入口的实际图标截图与返回导航已检查，未修改训练组或设置值。最终回首页。
- 本轮未重跑全量App/SDK测试、iOS、模型与连续帧性能测量；新视觉由用户最终确认。

原始检查与组件画板：`E:/AII-3D/hiplab-releases/list-icon-craft-20261107`。真机安装/截图：`E:/AII-3D/hiplab-releases/list-icons-8e84d15-57-20261107`下`device-install.json`、`device-*.png`；原始日志/图片/APK仅本机E盘交付目录保存，不进Git。

## 包身份

- source：`8e84d1582a6192aee8ab63ba4827bc916566a9aa`；候选`codex/list-icon-craft-20261107`；SDK `6fbd7de15dea62c7152eac43df1303b85d887a7c`。
- `1.1.0+57` / `com.ugk.hiplab` / release / arm64 `2057`；仅内部测试，不是商店发布。
- APK：`E:\AII-3D\hiplab-releases\list-icons-8e84d15-57-20261107\hiplab-1.1.0+57-8e84d15-internal-arm64-release.apk`；47759272字节；SHA256 `2686e15c12e39bed6aca6842810061d5817fade4ee629a0e2f4069bc0c80d1f1`。
- 证书SHA256：`3761270a4764157f0e389014a9e5b800b05403bfddce0f4f7f8c039f6a53bdc7`，与实际+56/2056基线一致；重签前后运行payload相同。
- r2-v1/stable，目录249动作，授权/公共封面209，AI标签209未审，内置MP4为0；789项内置资源逐字节核对通过。

本轮提交/推送候选分支，未合入main、未改release、tag或商店。日常项目目录`E:/AII-3D/3D-Hip`的`feat/ui-detail-polish@25260b3`保持。本包运行源已经冻结，后续仅证据文档整理不重复构建。
