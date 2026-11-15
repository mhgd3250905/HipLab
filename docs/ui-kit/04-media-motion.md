# 04 · 媒体卡片、文件夹与连续动效

本章从 HipLab 已验收的 +61 实现抽取。核对源码基点为 `84202688b3c43015c0f8c66d8b9d7b07988f3e8b`；参数是这套纸牌比例与页面空间下的实际值，不是所有 App 必须照搬的物理常数。迁移时先保留状态和生命周期约束，再校准尺寸与运动。

目标是“同一张有内容的牌在移动”，不只是两个画面之间的缩放。需要同时连续的有：媒体身份、显示帧、文字排版、局部合成坐标、运动轨迹和提交时机。只把 `duration` 调长不能解决它们。

## 1. 从哪里读、可以复用到哪一层

| 实现层 | 当前源 | 可以直接参考的合同 |
|---|---|---|
| 牌组控制与浮层 | [hip_home_action_deck.dart](../../lib/hip/ui/hip_home_action_deck.dart) | occurrence 身份、冷/暖首帧、OverlayPortal、手势、退场、减少动画 |
| 同一印刷牌面 | [hip_home_action_inspect.dart](../../lib/hip/ui/hip_home_action_inspect.dart) | 同一个 Face、矩形插值、固定文字画布、详情渐显 |
| 媒体适配 | [hip_widgets.dart](../../lib/hip/ui/hip_widgets.dart) 的 `HipDrillArt` | SDK 的准备/暂停/覆盖保持/真实首帧回调/原生 alpha 能力 |
| 计划首封面预热 | [hip_app.dart](../../lib/hip/ui/hip_app.dart) 的 `_warmPlanPosters` | 实际 renderer 相同 bundle、decodeWidth 与 cache key，有界预热 |
| 推荐组文件夹 | [hip_home_routine_folder.dart](../../lib/hip/ui/hip_home_routine_folder.dart) | 右下锚定、缩略图飞行、遮罩揭示、逆向交接与延后提交 |
| 可运行教学 | [media_handoff_example.dart](examples/media_handoff_example.dart) | `MediaHandoffRecipePage`，假媒体的稳定子树与播放门控 |

牌组本身只预览动作，不更改训练计划的动作顺序、剂量或持久化记录。文件夹才产生“选中另一组”的业务结果；它完成关闭后才提交该结果。其他 App 不应把这两个状态写到同一个 index。

教学页复用本仓库的 `HipNavPage` 和色板；它不依赖真实播放器。`ELEMENT` 编号用于观察是否重建，`保留帧`编号用于说明暂停不回首，二者都不是原生 Texture 的替代验证。120ms 延迟只是生成一个可被取消的教学回调，**生产接入不能把延时到点当成真实首帧已呈现**。

## 2. 媒体身份必须先于动画确定

### 2.1 三种身份不要混用

- **计划 identity**：HipLab 为 `日期/场景/训练组`。切语言、主题、路由覆盖不应顺便重置动作位置和媒体。
- **动作 ID**：决定内容和媒体源，但一个计划可以重复同一动作。
- **occurrence 身份**：决定某一个预览位置拥有哪一个媒体 State。重复动作也各有自己的 `GlobalKey`。

实际接入形状：

```dart
HipHomeActionDeck(
  key: const ValueKey('home-deck'), // 不随展开、语言或主题变化。
  identity: '$day/$sceneId/$routineId',
  drills: [for (final step in plan.steps) step.drill],
  doses: [for (final step in plan.steps) localizedDose(step)],
  cues: [for (final step in plan.steps) localizedCue(step)],
  descriptions: [for (final step in plan.steps) localizedDescription(step)],
)
```

上段是绑定位置示例，`day/plan/localizedDose` 等由业务宿主提供，不是样例中的新增全局函数。完整可运行入口见教学页；生产模型类型见实际 Widget 构造器。

禁止用 `ValueKey(expanded)`、`UniqueKey()` 或整组名称的译文作为媒体 key。也不能用 action ID 把两个重复 occurrence 合并成一个节点。

### 2.2 一个有界的暂停池

当前只准备当前、前邻和后邻，最多 `min(3, N)` 个暂停媒体；深层牌与循环补牌仍用公共封面。反向邻牌用透明的暖节点准备，避免等用户选方向后才创建。

暖牌晋升时，occurrence 的同一媒体 `GlobalKey` 随它从后排移动到前排，继续使用原 State/controller/texture。离开相邻范围才异步释放；新计划只复用确有资格的当前 occurrence，不保留历次计划的整个 decoder 池。

```text
                    当前前牌
                  [暂停媒体 B]
                 /            \
       [暖暂停媒体 A]          [暖暂停媒体 C]

深层 D/E：封面，不创建更多 decoder
```

在当前 SDK 合同里，`Offstage`/`TickerMode` 会触发媒体可见性或生命周期变化，不能拿它们替换这里保持节点的透明准备层。透明节点也不是“任意后台视频无限保活”：这是有限、暂停、仅邻牌的资源预算。

## 3. 展开与收回：同一父树，而非双面交班

当前前牌一直在 root `OverlayPortal` 内绘制，portal 自初始化就显示。小牌时它对齐原槽位；拖动时越过首页标题和底部操作栏；展开时在同一位置树中放大。背景槽位并不再绘制一张相同的前牌。

```text
Home 路由
├─ 原牌组槽位：后牌、补牌、布局锚点
└─ 常驻 root OverlayPortal
   └─ 同一前牌 Transform / 尺寸
      └─ 同一 HipHomeActionFace
         └─ 同一媒体子树（key、State、controller、texture）
```

这比“缩略图 Hero 到另一路由的视频”多一条硬约束：**媒体本身不参与换班**。动画改变的是矩阵和布局端点，而不是把 Poster Widget 替换成 Video Widget。

### 3.1 当前状态和时序

| 状态/事件 | 媒体配置与画面 | 下一步 |
|---|---|---|
| 首次冷小牌 | 封面可见，视频在下面准备真实首帧，暂停 | 首帧回调只记 ready，不能擅自换面 |
| 主动点击展开 | 解除当前 occurrence 的封面锁，仍暂停 | 380ms 变形到大牌 |
| 展开动画完成且可播放 | 同一媒体自动播放 | 点击媒体可切暂停/继续 |
| 点击关闭/遮罩/返回/Escape | 立即暂停当前帧，重置文字滚动，不 seek | 同一牌反向缩回 |
| 收回完成 | 继续显示该暂停帧 | 再次展开沿用同一媒体 |
| 首帧未到就关闭 | 重新锁住封面 | 晚到回调不能在关闭后突然换姿态 |
| 被更多/设置覆盖 | 已有暂停帧继续保持，屏蔽卡片输入 | 返回时不重建媒体 |

展开值 `t = easeOutCubic(controller.value)`，380ms；关闭使用同一个 controller 的反向变化。大牌宽为 `min(460, 屏宽−40)`，高为 `min(720, 屏高−上下安全区−48)`，仍是一张悬浮卡，而不是全屏页面。

“展开后默认播放”并不要求在第一帧变形时立刻给原生播放器发 play。当前把 play 推迟到变形完成，隔离第一次排版/模糊/合成与原生起播的并发成本。它是可证明的减负策略，不能单凭代码承诺所有机器首次展开均无卡顿。

### 3.2 关闭不是回到第一帧

已经淘汰：先截图、双视频交接、快放回第一帧、seek(0)、缩回后恢复另一张静帧。它们都会增加异步交接点，或让图中的人物姿态在关闭时跳变。

最终规则很简单：**在哪一帧关闭，就在哪一帧暂停并收回**。只有宿主业务明确换动作/计划或真实生命周期释放时，才重新准备新源。

关闭路径要统一：LocalHistoryEntry、PopScope、关闭按钮、遮罩、Escape 共用收回方法；还原之前的焦点，关闭过程再次返回不能直接把首页弹掉。展开时用 FocusScope/BlockSemantics 隔离背景；背景路线当前不允许交互时，前牌同样 IgnorePointer。

### 3.3 教学代码与生产媒体的界线

教学页使用固定 child 槽位：

```dart
AnimatedBuilder(
  animation: morph,
  child: mediaChild, // key 和父树槽位不变。
  builder: (context, child) => Positioned.fromRect(
    rect: Rect.lerp(compactRect, expandedRect, t)!,
    child: child!,
  ),
)
```

这段是结构摘要，需要放在 Stack 直接子节点中；可运行样例使用 AnimatedBuilder 在内部返回 Stack，避免 Positioned 的 ParentData 使用错误。

生产适配还必须提供：真实首帧呈现通知、暂停持帧、覆盖路由保持、source变更时释放、资源能力检查。单靠 stable key 不能修复原生渲染器释放或 GPU 的采样坐标问题。

当前 `HipDrillArt` 对首页传给 SDK 的合同为：

```dart
trainer.TrainingActionMedia(
  actionId: drill.id,
  policy: policy,
  playing: (play || holdVideo) && !retired && videoEnabled,
  paused: !play,
  prepareFirstFrame: holdVideo,
  showLoadingIndicator: !holdVideo,
  retainPausedSurfaceWhileCovered: holdVideo,
  nativeAlpha: holdVideo,
  revealPausedFrame: revealPausedFrame,
  onFrameReadyChanged: onFrameReadyChanged,
  radius: 0,
  stage: HipColors.mediaBackdrop,
)
```

这是从当前 App 适配抽取的配置摘要，其他 App 需要实现/接入同等能力；这些可选参数的 SDK 默认行为并不都与首页一致。不要为达到同样视觉而复制或改写 SDK 私有原生实现。本手册没有读取或导出外仓原生代码，也不把 Android 能力推广成已验收的 iOS 合同。

## 4. 防止“下一张到顶闪一下”

画面有两个状态：`ready` 表示真实媒体已准备；`reveal` 表示这个时刻允许把它展示出来。它们不能合并成一个 bool。

```text
                 尚未到顶                   已到顶
暖邻牌：       同一暂停视频 ─────晋升────→ 同一暂停视频
冷邻牌：       封面＋底下准备 ──晋升────→ 继续封面
                                            │
                                    用户主动展开
                                            ↓
                                    解除锁，揭示同一视频
```

当前 `_posterLocked` 的必要性：即便晚到的首帧是真的，也不一定是封面姿态。若用户已经看到这张小牌，首帧自动淡入仍会造成“闪一下”。先在后面准备、在合适的交互边界揭示，才是连续展示。

准备状态回调必须检查：`mounted`、当前 occurrence key、generation/source 仍对应本次请求。快速 A→B→A 时，旧 A 的晚回调不能误认成新 A 的当前状态。不要只比较 action ID，也不要轮询截图看有没有画面。

计划变更时若“新首动作 == 旧当前动作”且旧媒体真实 ready，可复用那一个已可见 occurrence 和它的封面锁状态。其它情况重置到新首牌并锁封面。locale、主题和更多覆盖不属于计划变化。

## 5. 封面预热必须与实际缓存键一致

当前 `_warmPlanPosters` 只预热两场景实际可选计划的首封面，去重后调用与 `TrainerPoster` 一致的 `TrainingPosterImages.provider(asset, decodeWidth, bundle: bundle)`。

需要同时一致的有：资源路径、DefaultAssetBundle 的身份、decodeWidth，以及真实 renderer 的 provider 类型。只在另一个 bundle 或尺寸下调用过 `precacheImage`，不等于下一次实际渲染能够命中。

窗口尺寸/bundle改变时重建预热命名空间；失败移除本轮预热标记，允许后续实际重建重试。不预载209张封面、不下载所有视频、不阻塞用户点击。内存压力仍可能驱逐缓存，不能承诺绝对零解码等待。

## 6. 任意方向拖拽：先处理坐标，再处理速度

前牌带透视，但手势识别必须放在透视变换外的屏幕坐标层。否则 GestureDetector 的局部delta会随牌面角度改变，看起来手指和牌脱节。

当前参数：

| 量 | 当前值/规则 | 原因 |
|---|---|---|
| 牌宽 | `min(可用宽*.78, max(156, 可用高/1.62))` | 明确纸牌比例与后排可见空间 |
| 切牌判定 | 径向位移 > 屏宽*.26 | 纵向/斜向与横向共用同一距离合同 |
| 预选方向 | 位移>8后取主轴符号，上/左下一张，下/右上一张 | 背牌已露出后不随最后一瞬速度换成另一张 |
| 反甩取消 | 已越阈值但沿位移方向速度 < −650px/s | 用户主动往回甩可取消 |
| 退场速度 | 沿位移射线投影，夹到0..2400px/s | 保留快甩与轻放差异 |
| 横向退场 | mass1，stiffness240，阻尼比1 | 维持既有横向手感 |
| 纵向退场 | mass1，stiffness70，阻尼比.82 | 有可辨识的起步与收势，不是匀速平移 |
| 方向插值 | 按射线 `abs(dy)` 连续插值 k 和阻尼比 | 斜向不突然跳到另一套曲线 |
| 回弹 | mass1，stiffness310，damping29 | 两轴回原位，可抓住回弹继续拖 |
| 回弹速度 | 每轴±1800px/s | 极端速度有界 |

退场不用一个很远的屏外终点：弹簧目标过远，会把竖向初始拉力放大，导致松手就飞走。当前使用真正投影后的四角包围盒，沿释放射线算到最近屏幕边缘的剩余距离，再加48pt余量。

两轴共用一条标量 simulation：`x = direction.dx * distance`，`y = direction.dy * distance`。不要各自用不同时间曲线，否则斜甩轨迹会弯。

提交按“已绘制的牌面AABB不再与窗口相交”尽早完成，不等待不可见的弹簧尾段结束。注意倾斜牌的包围盒必须用真实四角投影，不能只拿两个对角点或一个未变换的getRect作证明。

回弹完成时显式把两轴归零，避免spring只到容差值而留下隐藏reserve。新拖拽先停当前spring并从它当前的位置继续，不先跳回原位。

单牌只能回弹，不切牌。减少动画时立即落到确定终态。长按吸附/轻抬已经按用户要求删除；不要把历史300ms长按方案重新移植进来。

## 7. 底层补牌：先在被遮挡的位置存在

可见牌数最多3。后牌统一使用与前牌同一个 `HipHomeActionFace`，只增加depth变换，不能为后牌用一个更矮的Column；否则到顶时会重排标题和视频区域。

当前后排每层几何：向右16pt、向上26pt、旋转增量.105弧度、scale减.045；前牌基础倾角−.025弧度，透视系数.0012。它们构成整套牌的视觉，不应只拷贝阴影。

首页正文虽有16pt水平inset，扇形牌叠不能在这个inset边缘被截断后留一条白缝。当前 `_DeckViewportClip` 把局部裁剪左右各向外扩到窗口边缘；浮动前牌在root overlay内以真正窗口为最后边界。它不是无限取消所有clip：保留窗口边界与后排的有限裁剪，媒体还必须先完成正确的alpha合成。

补牌在 `progress>0` 时放到最后一张的**静止姿态**下方，opacity为 `easeOut(clamp(progress/.3,0,1))`，上层移开时顺势露出。不是前牌退出/业务index提交后才append新牌。取消拖动时该reserve随进度回退，不能留一个多余节点。

前后牌共用标题、剂量、提示的同一尺寸合同；“左右翻阅”一行已完整移除，没有隐藏占位。序号只显示当前数字，视觉上不显示总数；读屏仍可讲完整位置和总数。

## 8. 杂志式展开的排版如何连续

不要在动画里从 `fontSize:30` 每帧插到另一个字号，再让整段文字重排。当前先以固定版心测量标题/剂量/提示，缓存键包含文本、版心宽、字号缩放和文本方向，再缩放已排版的画布。

- 当前标题30/w700/行高1.18，剂量16/w600/行高1.35，提示13/行高1.5；标题和提示最多两行，剂量一行。
- 牌面圆角从22插到28，内边距从普通小牌22（紧凑10）插到26。
- 媒体Rect从小牌端点向大牌端点插值。大牌正文至少预留80pt预算，避免长标题把说明完全挤掉。
- 刊头、序号、分类先保留最终文字的自然尺寸，再缩放画布，避免逐帧重新shape字体。
- 详情在t=.45..1渐显，不换掉共用媒体/标题节点。说明独立滚动，关闭只复位说明滚动位置。

这一段的数值依赖当前 NotoSansSC 字体与中英文长短。移植时需要本 App 的实际字体测量；Flutter测试默认Ahem字体会制造与真字体不同的断行/溢出，不能拿它作最终视觉验收。

## 9. 文件夹：右下锚定和反向交接

文件夹是一个受限的推荐选组器，不是另建一个训练器或视频牌组。收起与展开都用缓存封面。

### 9.1 缩略图真实表达数量

少于两组时收起外框为64×36，单排两列，点击区域高度至少44。两组及以上为64×64，两排两列。外圆角12，内图圆角6，内边距6，封面24，列/行步长28。最多预览四组，每组只显示首动作，按行填充。

`_FolderPreview.cell(i)` 同时驱动静止小图和飞行起点，圆角也共享。若只改收起态位置/圆角而忘记飞行层，点击的第一帧就会跳。

### 9.2 右下角固定，不重新居中

先取源控件静止中心和未缩放尺寸组成origin，避免点击时 `.95` 按压缩放污染落点。目标Rect由同一个bottomRight倒推宽高，因此 `Rect.lerp(origin, target, t)` 的right/bottom全程不动，左/上单调扩展。

当前展开360ms、收起300ms，`easeInOutCubic`；目标宽最大420，安全区留20，网格两列、间距14，单张卡片占第一列，header76，封面宽高比1.2。内容实际超过可用高时可滚动。仅当窗口/键盘变化使旧锚点越界时clamp，不把普通打开改成居中弹窗。

外层圆角沿12→32插值，飞行缩略图沿6→18插值；起点必须与收起面共享，终点与展开封面一致。不要只改某一层的半径。

展示分三层：

1. 原小文件夹source在route存在时透明，保留自身布局。
2. 共享文件夹surface沿Rect变形；panel在目标尺寸提前布局，用当前圆角Rect裁剪揭示，避免内容随着小框反复挤压重排。
3. 小图单独沿起终Rect飞行，reveal区间`.28..82`，handover区间`.65..94`。reverse时从实际可见封面坐标返回；已滚出视口的图不能从一个虚构位置穿过面板飞回来。

回到dismissed的**同一帧**恢复source，不能等route disposal的下一次microtask才出现，否则落点会闪空。

### 9.3 关闭完成后才选中新的训练组

```dart
final selected = await Navigator.of(context).push<String>(route);
await route.completed;
if (!mounted) return;
if (selected != null && currentChoices.any((c) => c.id == selected)) {
  onSelected(selected);
}
```

`push` 的Future在pop时返回，不等于reverse动画已结束。若立刻换首页计划，文件夹还在缩回，背后牌面已经换动作，用户会看到内容跳变。

可编译的通用版本是样例中的 `commitSelectionAfterReverse<T>`；生产宿主还需要检查选择仍属于当前可选列表。profile/安全筛选或场景使打开快照失效时，应关闭旧route，不让过期选项开练。

## 10. 闪烁因果表：症状相近，机制不同

| 症状 | 要确认的机制 | 最终处理 | 容易做错 |
|---|---|---|---|
| 展开/收起闪一帧 | 是否在换Poster/Video子树、route或decoder | 常驻同一媒体、只变矩阵和paused | 加淡入掩盖双视频交接 |
| 收起时动作跳回 | 是否seek/快放回首/恢复静帧 | 暂停当前位置并保留 | 把第一帧当唯一正确小牌图 |
| 下一张到顶闪 | 后牌只有poster，到顶才建视频；或迟到首帧换姿态 | occurrence暖池；冷牌ready/reveal分离 | 无条件ready后120ms淡入 |
| 办公/居家切换闪 | 媒体键被全清、目标封面未解码 | 冷首牌锁图、同首动作有限复用、相同cache key预热 | 整计划永久缓存，或只比较action ID |
| 进入更多闪 | 覆盖路由触发暂停decoder释放 | opt-in保留已暂停surface，覆盖只叠遮罩 | 仅给Flutter widget加Key |
| 人体黑色错位影 | packed RGB/alpha受透视前后坐标影响 | 局部先合成；当前首页nativeAlpha路径 | RepaintBoundary当成坐标隔离保证 |
| 纵向离屏三角残影 | packed shader离屏输入裁剪使采样失配 | 当前SDK原生RGBA合成再交给Flutter | 只改alpha透明度、换封面、去掉姿态 |
| 首次展开心理上“卡一下” | 文字重排、变形/模糊与原生play并发 | 固定文字画布、测量缓存、变形后起播 | 只延长动画或断言唯一根因已定位 |
| 竖甩像匀速/突然飞走 | 过远目标、速度硬cap过低、统一临界阻尼 | 屏边目标、保留甩速、方向连续spring参数 | 只改固定duration，不看位移/速度曲线 |
| 底层新牌突然闪现 | commit后才插入reserve | 被最后一张遮住时就开始揭示 | opacity从0瞬间切1 |
| 文件夹返回落点闪空 | source恢复晚于reverse dismissed帧 | 同帧handover，完成后再选组 | await push后立即改计划 |

## 11. 排查顺序与验证层级

先把一次可复现触发定义清楚，例如“冷启动第一张→展开→播放一秒→关闭”“办公→居家”“More→返回”“下甩03号牌”。再逐层检查，别一上来修改素材或同时引入另一套动画。

1. **身份层**：记录媒体Element/State、controller、texture ID，比较事件前后及动画每16ms采样。看create/dispose/prime/seek有没有意外发生。
2. **呈现层**：检查poster opacity、ready回调、锁图状态，区分“decoder存在”和“真实帧已呈现”。检查晚回调及快速A→B→A。
3. **几何层**：量真实四角投影、裁剪矩形、文字局部归一化位置。静态终态截图相同，不代表中途没重排或没裁掉内容。
4. **GPU层**：静止正常、纵向/透视才异常时，检查packed-alpha采样/输入裁剪/Surface方向。独立像素参考不能只是把被测shader公式复制成同一份计算。
5. **设备层**：真实Surface/OES/方向/首帧、第一次展开和连续动作体验，在最终签名APK与实际手机上验收；组件fake通过不是原生验收。
6. **性能层**：查profile帧时间、UI/raster与原生播放并发，不用肉眼“感觉顺了”替代可量化FPS。当前用户日常体验验收与旧阶段逐项设备证据仍分开。

仓库现有回归入口：

```powershell
flutter test --no-pub test/hip/hip_home_action_deck_test.dart
flutter test --no-pub test/hip/hip_home_routine_folder_test.dart
flutter test --no-pub --enable-impeller test/hip/hip_home_card_alpha_filter_test.dart
```

上面是复现入口，不表示本次文档整理重新执行。使用本项目固定Flutter与已解析lock，真实像素测试需要支持Impeller/runtime filter；不支持时应明确跳过并保留设备验证，不把skip当pass。

建议保留的验收场景：首牌首次展开、播放后缩回、早关晚帧、暖/冷邻牌双向晋升、重复动作短循环、抓住回弹反向拖、八方向轻放/快甩、真正离屏后解锁、More/设置覆盖返回、场景/日期/筛选/主题/语言改变、文件夹取消/选择/过期快照、系统减少动画。

## 12. 历史方案只作为演进背景

以下报告保留当时源码与证据，阅读时必须按版本区分，不能视作当前额外约束：

- [+44同一视频表面](../home-card-live-surface-2026-11-06.md)：当时后牌仍封面；当前已增加occurrence暖池，GlobalKey会随晋升搬移。
- [+45局部合成](../home-card-alpha-alignment-2026-11-06.md)：说明Transform坐标隔离，但不能替代后续nativeRGBA对离屏裁剪的修复。
- [+50原生RGBA与覆盖保持](../home-card-surface-stability-2026-11-06.md)、[+51接牌与竖向惯性](../home-card-handoff-motion-2026-11-06.md)、[+52计划切换连续性](../home-plan-media-continuity-2026-11-06.md)：当前防闪策略的主要形成过程。
- [+48长按轻抬](../home-card-touch-motion-2026-11-06.md)：该路径已撤回；不要恢复300ms识别与吸附。
- [+49退场缓和](../home-card-exit-easing-2026-11-06.md)：其竖向k60/cap900已被当前k70/ζ.82/cap2400取代。
- [+55文件夹预览](../home-routine-folder-preview-2026-11-07.md)：两项居中/外14内8是历史；当前两项上排、外12内6。

这套案例可证明具体状态机和回归覆盖，也能解释已遇到的问题。它不提供“任意视频后端、任意GPU都零闪烁/零卡顿”的保证；真正可复用的是身份、时序、合成边界及证据分层。
