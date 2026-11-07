# 03 · 设置列表、控件、图标与友善插画

这套列表的重点是稳定的文字列、克制的表面层级和完整的操作反馈。小图标可以有材质体积，按钮和开关仍然清楚、平整；不把每个条目都做成独立浮雕卡片。

参考源固定为 main `84202688b3c43015c0f8c66d8b9d7b07988f3e8b`。本页解释当前实现；项目内数值入口仍为[UI设计规范](../ui-design-standard.md)。[完整控件样例](examples/controls_example.dart)直接调用生产组件，不另画一套相似控件。运行方法见[手册入口](README.md)。

## 组件在哪里，迁移时带走什么

| 合同 | 当前实现 | 复用需要保留的部分 |
|---|---|---|
| 分组、条目、图标槽、开关、滑块、确认框 | [hip_page_kit.dart](../../lib/hip/ui/hip_page_kit.dart)：`HipListGroup`、`HipListRow`、`HipRowIcon`、`HipSwitch`、`HipSlider`、`showHipConfirmDialog` | 颜色、语义、字体、按压、键盘激活；整份文件还包含导航依赖 |
| 分段 | [hip_segmented.dart](../../lib/hip/ui/hip_segmented.dart)：`HipSegmented<T>` | 选中状态、文字/拇指同步插值、拖动、减少动画、选择触感 |
| 按钮、按压与图片边框 | [hip_widgets.dart](../../lib/hip/ui/hip_widgets.dart)：`HipPressable`、`HipPrimaryButton`、`HipSecondaryButton`、`HipMediaFrame` | 按压作用域、字体/颜色、语义、图片裁剪和前景描边；该文件还导入训练媒体，不能当作零依赖组件包 |
| 列表装饰图标 | [hip_row_icons.dart](../../lib/hip/ui/hip_row_icons.dart)：`HipRowSymbol`、`HipRowEmblem` | 原始矢量绘制、深浅/高对比度、静态重绘策略 |
| 主题、语言、按压材质 | [hip_theme.dart](../../lib/hip/ui/hip_theme.dart)、[hip_text.dart](../../lib/hip/ui/hip_text.dart)、[hip_tactile.dart](../../lib/hip/ui/hip_tactile.dart)、[hip_glass.dart](../../lib/hip/ui/hip_glass.dart) | 宿主的主题/locale绑定，不仅是几个色值 |

这些类型尚未成为独立 Pub 包。迁移顺序与依赖裁剪见[05移植与验收](05-adoption-validation.md)。不要把 `hip_app.dart`、业务Store和训练SDK一并复制，只为获得一个设置行。

## 列表几何：让同一列始终对齐

| 项目 | 当前数值与行为 |
|---|---|
| 页面左右边距 | `kHipPageEdge = 20` |
| 条目内边距 | 左右16、上下10 |
| 装饰图标槽 | 30×30；图标后间距12 |
| 有图标的文字起点 | `kHipRowTextInset = 16 + 30 + 12 = 58`，同时用于分隔线起点和下一行选择器缩进 |
| 条目高度 | 单行**最小**52；有subtitle**最小**60，不是固定高度 |
| 分组圆角与表面 | radius10；无额外边框、无投影；深色white α.06，浅色white α.70 |
| 分组内分隔 | 0.5高/0.5粗，文字色α.10，只从文字列开始 |
| 分组间距 | 更多和主要设置分组28；不为每组重复添加小标题 |
| 条目标题 | 17 / w400 / height1.25；中文最多1行、英文最多2行，超出ellipsis |
| 条目副标题 | 与标题间距2；13 / height1.3 / muted，最多2行 |
| 右侧meta | 14 / faint，右对齐；左间距8、右4；中文最大宽140、英文105，单行ellipsis |
| 行箭头 | 15、stroke2、faint；默认只有可点且无trailing的条目显示 |
| 整行交互 | 可点行由`HipPressable`包裹，按下scale .99；非可点行没有伪造按钮语义 |

`HipListGroup`在**每两个children之间**插入分隔线。一个字段若由标题行和下一行控件组成，应先把它们包成一个`Column`，再作为一个child传入；不要把同一字段误分为两项。

图标缺省时，`HipListRow`不会预留30+12槽。因此有图标和无图标条目混在一组时，默认分隔线58未必对应无图标行的起点；确实需要这种混排，应显式选择该组的`inset`和文字列方案，而不是每行手工补不同空白。

### 三种条目只选一种主要动作

- 跳转条目：使用`onTap`，通常显示meta与chevron；整行可点。
- 开关/选择条目：传`trailing`，让子控件拥有自己的`onChanged`；默认不加chevron。
- 纯说明条目：不给`onTap`，不伪装成可点击入口。

不要同时让整行`onTap`翻转开关、又让开关`onChanged`翻转一次；这会造成手势竞争和状态看似没有变化。样例开关只由`HipSwitch.onChanged`更新本地State。

真实页面可参考[更多页](../../lib/hip/ui/hip_more_page.dart)的`HipMorePage._list`，以及[设置实现](../../lib/hip/ui/hip_app.dart)的`HipVoiceSettingsPanel`、`_settingsChoice`、`HipLanguagePanel`和`HipAppearancePanel`。

## 开关、分段与滑块：一套视觉家族，三个独立合同

### 开关 `HipSwitch`

视觉胶囊51×31，白色旋钮27，四周内缩2；外部保留51×44热区。开启用jade，关闭用深色`#39393D`或浅色`#E9E9EA`。旋钮只有一层紧凑阴影：深色black α.32/浅色α.16、blur3、y1.5。

滑动为200ms `easeOutCubic`；系统减少动画时为零。组件保留`Semantics(toggled, enabled, onTap, label)`、Enter/Space、FocusNode及选择触感。每个设置开关必须提供**不同且有意义**的`semanticLabel`，不能都叫“开关”。

`value`由宿主持有，回调后必须真正更新状态。当前API的`onChanged`非nullable，没有内建disabled合同；需要禁用场景时，应先明确宿主交互设计，不能只把颜色涂灰却继续响应。

### 分段 `HipSegmented<T>`

设置页使用的参数必须显式写出：

```dart
height: 32,
radius: 9,
inset: 2,
ios: true,
```

普通默认值是height34/radius9/inset3/ios:false，服务于另一套触感组件，不能直接当作设置规格。

设置轨道为系统灰：深色`0x3D767680`、浅色`0x1F767680`；选中块深色`#636366`、浅色white。选中块圆角是`radius - inset`，即7，与外框同心；只有一层轻阴影black α.30/.10、blur4、y1。文字13pt，选中w600、未选w400。

滑块位置与每项前景色共享同一个选择位置插值，380ms `HipMotion.spring`；不是先切字色、过一拍再挪白块。支持点选和沿轨道拖动，选中值不变时不重复提交，选择触感只在切换时触发。减少动画时位置直接到终态，去掉按压缩放。组件保留互斥组选中语义和键盘激活。

`values`应非空且稳定，`selected`必须属于它；当前实现会对索引clamp，但这不是允许宿主长期传入无效状态的合同。`keyPrefix`在同页多个分段之间保持不同，方便可定位的检查与操作。

### 滑块 `HipSlider`

轨道4高，旋钮直径26、白色，活动轨道jade、非活动轨道沿用开关的系统灰。旋钮有blur3/y1/α.18阴影及0.5细边，去掉值气泡、刻度和可见水波覆盖层。

这是带自定义`SliderTheme`的Flutter `Slider`，不是平台原生UISlider。当前API使用0–1值域，`onChanged`回写宿主状态，并提供字段语义名；样例中的百分比只是展示，不擅自改Slider范围。

## 英文长文案如何排，而不是压成细字

中文版选择器可以和标题同一行。英文版的`App language`、`Voice language`、`Appearance`会与三个选项争宽，因此当前`_settingsChoice`让标题占一行，选择器放在下面，左缩进58、右16、底12。这个结构同时保留完整标签和稳定的文字列。

完整样例按相同分支处理英文`Preview mode`；分段内部`FittedBox.scaleDown`只作为最后收纳，不用它代替整体布局。行52/60是最小高度，若把它改成固定`SizedBox(height: 52)`，英文第二行就会被截掉。

界面语言与口令语言分开：`HipText.of(context)`读取Flutter**已解析**locale，`pick`只负责展示。用户自建名称、历史聊天不能因为切语言被写回翻译。`HipApp._shell`配置zh/en与本地化delegates；更换locale时不以locale为Key重建Navigator、页面State或视频节点。

## 按钮与确认框

| 组件 | 当前主体规格 | 有意保留的例外 |
|---|---|---|
| `HipPrimaryButton` | 全宽50高、radius14、17w600；平面jade，无渐变/投影；按下填充加深约10% | 图标18，图文间8，末尾符号17 |
| `HipSecondaryButton` | 全宽50高、radius14、17w500；深色white α.10，浅色track | `sdkScale:true`用于SDK宿主，56高/18pt/stadium，不能扩成主体默认 |
| `HipPressable` | 按下100ms、恢复180ms、常规scale .97；键盘、语义、按下作用域同步 | 可覆盖scale；列表行.99、确认操作.98；减少动画时不缩放 |
| `showHipConfirmDialog` | 最大宽320/最大高屏高.78；radius14；文字居中；正文可滚动 | 关闭遮罩返回null、取消false、确认true |

确认框遮罩black α.36，180ms淡入与scale .96→1；减少动画时直接终态。标题17w600，正文14/height1.45，标题与正文间6；操作区50高，0.5分隔线，取消w400、确认w600。破坏性确认使用pain色，其它确认用jadeText。

这里存在**明确的一层轻阴影**：black α.18、blur28、y12；它不是Material默认Dialog整套装饰，但也不是“完全无阴影”。内部必须有transparent `Material`，否则独立dialog route里的裸`Text`可能继承WidgetsApp错误样式而出现黄色下划线。

完整样例的确认框只更新本页结果，不执行删除、存储、语音或网络操作。业务页处理时应写成`result == true`才提交动作；不能把遮罩关闭的null当作确认。

需要破坏性文案时，保留完整返回合同：

```dart
Future<bool?> askToRemove(BuildContext context) {
  final text = HipText.of(context);
  return showHipConfirmDialog(
    context,
    title: text.pick('删除这一项？', 'Delete this item?'),
    message: text.pick('删除后无法恢复。', 'This cannot be undone.'),
    cancelLabel: text.pick('取消', 'Cancel'),
    confirmLabel: text.pick('删除', 'Delete'),
    destructive: true,
  );
}
```

上段是使用片段，需放在已经导入`flutter/material.dart`、`hip_text.dart`和`hip_page_kit.dart`的宿主文件中。可直接分析/运行的页面以[controls_example.dart](examples/controls_example.dart)为准。

## 图标：列表可以精致，功能控制继续清楚

`HipRowSymbol`当前有18种角色：训练组、动作库、自测、记录、设置、提醒、椅子、口令、声音、语言、音量、外观、安全、隐私、新建组、Coach、完成和暂停。`HipRowEmblemPainter`使用64单位画布，通过侧壁位移、连续材质渐变和细倒角画出青玉、珍珠、钢灰和石墨体积，最终收在30pt列内。

这种体积感不是给图标套一个大圆角色块或外加黑色阴影。它不加载bitmap、不用BackdropFilter、不挂持续动画；每个图标有`RepaintBoundary`，只有symbol/theme/highContrast变化才需要重绘。高对比度加强边界，不能只在默认深色查看。

图标是**装饰**，用`ExcludeSemantics`排除重复读屏，不单独抢点击。用户点图标和点文字均属于同一条目；语义名与键盘动作由整行负责。返回、关闭、播放等功能控制仍用共享线性`HipGlyph`，不能全部换成雕塑小画。

默认glyph→symbol映射是为了兼容老调用；有语义歧义必须显式指定。例：`HipGlyph.contrast`默认表示外观，更多页“设置”则传`rowSymbol: HipRowSymbol.settings`，两者应能凭形状分辨，而不是只靠颜色。

## 友善插画：人被欢迎，注意事项也要清楚

安全提示最终采用三张友善卡通插画，避免真人肖像感和无脸灰色模型。孕产期画安心休息；限制活动画年轻男性休息与绿色暂停/关节虚线；近期受伤画休息与暖黄色绷带/局部提示。局部标记说明需要留意的位置，不把整个人画成禁止对象。

三张资源位于`assets/hip/onboarding/*-friendly.webp`，960×960 RGBA；实际pubspec只声明三张friendly素材，旧深浅六张留在源中追溯但不再入包。原图和生成过程不是组件库的运行依赖，素材替换仍应检查来源及使用权。

容器用`HipMediaFrame(radius: 28)`和当前surface提供背景，图片`BoxFit.contain`，不要用cover裁掉暂停或绷带标记；保留`ValueKey(asset)`、`gaplessPlayback`，并提前预缓存三个步骤。深浅主题共享透明图，避免为适配深色简单整图压黑导致肤色发灰。图像没有文字，中文/英文提示仍由页面文本承担，安全问题及训练判断不是图片资产的职责。

这套插画是安全引导的表达规则，不代表动作示范视频也应改为卡通人物。动作素材仍归原媒体/SDK合同，不在UI组件提炼时重绘。

## 深浅主题与可访问性边界

列表不能整体反色了事：浅色正文`#121614`、muted`#5D6661`，深色正文`#F2F3F5`、muted`#8C9096`。小字号强调文本通过`HipColors.jadeText`使用浅色jadeDeep`#0D6E53`、深色jade`#3CCFA4`；浅色jade填充`#14A37B`配白字，深色填充`#3CCFA4`配深字`#07261D`。

当前`HipColors.palette`是App内静态访问口，`HipApp._PaletteScope`在主题变化时同步重建已有路由/弹层并更新透明状态栏图标亮度。跨App应接入自己的主题scope，不要只复制静态变量：多窗口若需要各自独立主题，就不能共享一个全局可变palette。详情见[基础与依赖](01-foundations.md)。

可访问性不止给`Text`加名称。要保留：开关toggled、分段selected/互斥组、字段名、Enter/Space、FocusNode、44pt级热区，以及减少动画后下一帧就能操作的终态。复合卡片若含独立子按钮，需保留子语义，不能用整个卡片的MergeSemantics吞掉开始/编辑动作。

## 常见做歪方式

| 反例 | 会出现什么 | 当前配方 |
|---|---|---|
| 照抄文件头旧注释：radius12、图标32、标题16w500 | 新旧列宽和字级混用 | 以类实现/现有测试及当前规范为准：10/30/17w400 |
| 每行加圆角、描边和外阴影 | 页面像一排浮起的盒子 | 分组拥有一个表面，内部只画文字起点分隔 |
| 开关只有31高点击区 | 视觉对了，边缘点击难用 | 51×31视觉放进51×44热区 |
| 设置分段只传`ios:true` | 默认高度34/内缩3悄悄混入 | 显式32/9/2/ios参数 |
| 英文标题与三段控件强塞同一行 | 压字、截断或overflow | 标题一行、控件下一行，沿58文字列对齐 |
| 复制自带业务Store的设置页 | UI复用变成跨App业务耦合 | 像完整样例一样由宿主传value/onChanged |
| 18个图标各挂动画或滤镜 | 列表滚动和转场负担增加 | 静态CustomPainter＋RepaintBoundary |
| 把装饰图标设为独立按钮/读屏节点 | 同一项被读两次，点按区域碎裂 | 图标ExcludeSemantics，整行负责动作 |
| 切主题/语言给MaterialApp或Navigator换Key | 路由、媒体State被重建，容易闪 | 复用现有Navigator/State，更新主题和locale依赖 |
| 确认框null也执行操作 | 点遮罩竟然提交 | 只有`result == true`才执行 |
| 图片cover放大 | 局部注意符号被切掉 | contain完整收纳图像和标记 |

## 怎样检查这部分有没有复用偏

[完整样例](examples/controls_example.dart)包含公开`ControlsRecipePage`，本地State演示开关、两段选择、滑块和确认框。可定位Key为`recipe-switch`、`recipe-slider`、`recipe-confirm`、`recipe-result`；没有业务Store、网络、播放或真实删除。画廊检查只证明示例的行为和布局，不能替代新App原生设备验收。

| 已有验证入口 | 值得迁移的断言 |
|---|---|
| [hip_row_icons_test.dart](../../test/hip/hip_row_icons_test.dart) | 18角色在两主题均30pt；静态零定时callback；无Image/Texture/BackdropFilter；设置/外观图形不同；装饰语义不吞整行点击和键盘 |
| [hip_ui_shared_completion_test.dart](../../test/hip/hip_ui_shared_completion_test.dart) | 减少动画下一帧到位；开关名称/toggled/Enter/Space；三个设置开关名称不同；小视觉图标仍保留44热区 |
| [hip_app_locale_test.dart](../../test/hip/hip_app_locale_test.dart) | 切语言后仍停留已打开设置路由；持久化与系统locale；深浅完整页面；三个安全步骤与后续身份流程 |
| [gallery_test.dart](examples/gallery_test.dart) | 本次文档样例自身的可运行检查，结果以阶段收束记录为准，不预写为已通过 |

推荐人工对照中文浅色与英文深色各走一次：读完整标题和选择器、点开关边缘、拖分段再拖出区域取消、以键盘操作、改变系统减少动画、点确认框遮罩/取消/确认。测试范围按目标App支持的正常字号和设备决定；不要把一个截图或组件测试写成全部原生体验通过。
