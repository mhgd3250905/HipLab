# HipLab 文档与开发台账

## 2026-11-07：导航按钮高度统一 / +58待确认

修复训练组→新建训练组（添加动作）左上返回/关闭胶囊下移：旧44/52pt标题行共用居中公式导致4pt变化，真机+57边界从y152变y165，尺寸143px未变。现在单/双标题的左侧胶囊与右侧操作共用固定44pt控制轨道，副标题只扩展标题和磨砂区域；固定胶囊、随页滑入、正反转场均使用同一纵向锚点。另固定沉浸自测头部的48pt控制轨道，长题不再带动关闭/进度下移，保留原外留白和正文全宽居中。

构建源`5a35be70a8faa915b8b30448a26476f00e52a778`，候选`codex/nav-control-anchor-20261107`，`1.1.0+58` / arm64 `2058`；SDK保持`6fbd7de15dea62c7152eac43df1303b85d887a7c`，lock/Native/首页卡片与文件夹无改动。分析0，相关13文件142通过/14既有跳过（含导航锚点14项）。已同签覆盖安装真机、回读2058；训练组→新建→关闭的实际按钮边界完全一致，返回与副标题排版检查完成，新体验待用户确认。[实现与交付](nav-control-anchor-2026-11-07.md)。

## 2026-11-07：整套立体条目图标 / +57待确认

按用户反馈重画整套18类条目前导图标：训练组卡片、动作书册、髋关节、记录日历、设置齿轮，以及提醒、椅边练习、语音、提示音、语言、音量、外观、安全、隐私、新建、AI、完成/暂停。统一玉绿、浅瓷和金属材质、方向一致的高光与侧壁；深浅主题适配。30pt图标列、52/60pt行高和文字位置保持。

构建源`8e84d1582a6192aee8ab63ba4827bc916566a9aa`，候选`codex/list-icon-craft-20261107`，`1.1.0+57` / arm64 `2057`；SDK保持`6fbd7de15dea62c7152eac43df1303b85d887a7c`，lock/Native/首页牌面与文件夹无改动。分析0，相关12文件128通过/14既有跳过（含新图标5项）。已同签保留数据覆盖安装真机、回读2057并启动成功；更多/设置/训练组现场截图已检查，新的视觉观感待用户确认。[实现与交付](list-icon-craft-2026-11-07.md)。

## 2026-11-07：打卡徽章直达训练记录 / +56

首页右上连续打卡徽章现在可点击，直接进入现有“训练记录”页。保留24pt玻璃徽章，触达区至少44pt，补按钮语义；首页没有返回键，记录页返回胶囊随页面滑入（pinLeading:false）。重复点击防护保持到收起转场完成，返回保留首页当前卡片/视频。空记录页开练使用首页当前所选完整计划。

同包按用户最新反馈将文件夹内部小图圆角恢复6，外框圆角按6pt内边距适配为12；固定四格位置，只有两组时放上排，下排留空，不再居中。仍一组一图、最多预览四组，无假占位图，右下锚点保持。

构建源`863b44ab7d09a8ddbdd87dbe3fbc9d887e472e18`，候选`codex/home-streak-records-20261107`，`1.1.0+56` / arm64 `2056`；SDK保持`6fbd7de15dea62c7152eac43df1303b85d887a7c`，Native/lock/动作牌无改动。相关10文件110通过/14既有跳过，后续文件夹8项另通过，分析0。已同签覆盖安装真机并回读2056、启动ok；入口与返回的现场结果见安装回执，新体验待用户确认。[实现与交付](home-streak-records-2026-11-07.md)。

## 2026-11-07：按真实组数预览与成对圆角 / +55

用户指出办公只有两组、收起却显示四图。已改为**一组一图，最多四组**，只取各组首动作，不再用组内后续动作填格；两组同行居中、三组末项居中、四组2×2，展开仍显示全部实际候选。64pt外框圆角19→14、内部6→8，与6pt内边距成对；静态与过渡共用cell/radius，保留右下角锚定及既有选组功能。

构建源`3aeb2ee30af08774953c7588b99f5e71f2b1383c`，候选`codex/home-routine-folder-preview-20261107`，`1.1.0+55` / arm64 `2055`，SDK保持`6fbd7de15dea62c7152eac43df1303b85d887a7c`，Native/lock/动作牌无改动。相关10文件108通过/14既有跳过，文件夹8项另通过（总116通过），分析0。已同签覆盖安装真机并回读2055、启动ok；数量/圆角观感待用户确认。[实现与交付](home-routine-folder-preview-2026-11-07.md)。

## 2026-11-07：文件夹右下锚定 / +54

按用户对+53的新反馈，文件夹以原按钮**右下角为锚点**，右/下边保持固定，仅向左、向上延展；收起沿原路径回到右下角。取按钮静止中心与尺寸，避免点击按压缩放影响落点。网格样式、选组与关闭交接保持；SDK/Native/动作牌/lock无改动。

构建源`815f878141e3831b753b9dc43a2699d71817c868`，候选`codex/home-routine-folder-anchor-20261107`，`1.1.0+54` / arm64 `2054`，SDK保持`6fbd7de15dea62c7152eac43df1303b85d887a7c`。相关10文件108通过/14既有跳过，文件夹7项另通过（320/394/横屏每16ms核对固定right/bottom和左上单调延展），分析0。已同签覆盖安装真机并回读2054、启动ok；新锚定动画观感待用户确认。[实现与交付](home-routine-folder-anchor-2026-11-07.md)。

## 2026-11-06：推荐训练组文件夹 / +53

构建源`2d46ab1e4fcc0d696ae3748330863ccb93fb94aa`，候选`codex/home-routine-folder-20261106`；`1.1.0+53` / arm64 `2053`，SDK保持`6fbd7de15dea62c7152eac43df1303b85d887a7c`、lock保持。已验收+52保留历史，本轮新增文件夹等待用户确认。

首页“换一套”改64pt四动作封面的玻璃文件夹，原位展开当前场景全部有效推荐组，展示名称/时长/动作数与选中状态，可直接选择。关闭完成再更新首页；取消或重复选择保留预览与视频，办公/居家各自记住本次启动的选择，实际开练使用所选完整计划。只用SDK静态封面，无额外视频节点。相关10文件108通过/14既有跳过，文件夹7项另通过，分析0。已同签覆盖安装真机，包管理器回读2053、MainActivity启动成功。新动效与交互观感待用户确认；本轮无全量、iOS或模型验收。[实现与交付](home-routine-folder-2026-11-06.md)。

## 2026-11-06：+52用户真机验收通过

用户在+52覆盖安装后明确回复“我已已经验收通过了”，当前`1.1.0+52`（arm64 `2052`，构建源`59ce2b8`）记为**用户真机验收通过**。本轮首页动作卡片及计划切换优化的用户验收项已收束；不另推定未报告的逐项测试或性能指标。安装回执与APK身份保持，未重建或改运行代码；候选分支仍为`codex/home-plan-media-continuity-20261106`，合并状态独立记录。

用户确认回执：`E:/AII-3D/hiplab-releases/home-plan-59ce2b8-52-20261106/user-acceptance-20261106.json`。下方“待验收”保留为交付时历史，当前以本条为准。[实现与交付](home-plan-media-continuity-2026-11-06.md)。

## 2026-11-06：首页计划切换媒体连续性 / +52

运行/构建源 `59ce2b8829d64eec401c743123d31c57e79d4a62`，分支 `codex/home-plan-media-continuity-20261106`；`1.1.0+52` / arm64 `2052`。SDK仍固定 `6fbd7de15dea62c7152eac43df1303b85d887a7c`，hosted锁保持；日常目录 `feat/ui-detail-polish@25260b3` 未改。

针对办公/居家首牌闪动，将冷牌保护统一覆盖初始首牌、场景/换一套/跨日/动作列表重置，以及关闭后迟到首帧。新牌保持封面，主动展开才揭示原视频；同一已就绪当前动作成为新首牌时保留State/controller/Texture与当前帧。提前解码两场景当前可选计划的首封面，精确匹配bundle和显示尺寸，不批量下载视频。新增6项回归；相关10文件106通过/0失败/14既有跳过，分析0；Impeller另2通过、62组RGBA消费对照误差/黑残影0。SDK/Android和+51运动参数未改，本轮未重复SDK测试。

+52 release验包/验签通过，与+51内部包同签。未安装、未跑全量/模型/iOS；远程手机观感待用户确认。[实现与交付](home-plan-media-continuity-2026-11-06.md)。

## 2026-11-06：连续接牌与纵向惯性 / +51

运行/构建源 `2087649d8c0dc8b34827c8458876886e55330662`，分支 `codex/home-card-handoff-motion-20261106`；`1.1.0+51` / arm64 `2051`。SDK固定 `6fbd7de15dea62c7152eac43df1303b85d887a7c`，hosted锁保持。日常目录 `feat/ui-detail-polish@25260b3` 保持。

用户确认+50的更多闪帧/上下透明异常修复。新候选预备current±1最多3挂载暂停媒体，到顶按occurrence GlobalKey接管原State/controller/Texture；冷首帧迟到保持compact既有图，主动展开解除。上下仍用物理曲线，取消900硬限速、竖k70/ζ.82，水平原值保持。相关100通过/14跳过，强化甩速另1通过，Impeller另2通过/62组RGBA像素0误差；SDK54通过，双方分析0。+51 release验包/验签通过，与+50内部包同签；Agent未安装，新接牌及手感待用户远程确认。

[实现、资源范围与交付](home-card-handoff-motion-2026-11-06.md)。

## 2026-11-06：暂停帧覆盖保持与离屏透明合成 / +50

运行/构建源 `981eeaf161c0b896e963d625f9525b69e9bf32b6`，候选分支 `codex/home-card-surface-stability-20261106`；`1.1.0+50` / arm64 `2050`。四个SDK包及coach override固定 `145e3195570f34536c948558e02306a3db5ec2e3`，hosted锁保持；日常目录 `feat/ui-detail-polish@25260b3` 保持。

仅首页前牌启用暂停帧跨覆盖路由保留和原生单decoder RGBA输出：解决进入更多时回封面的明确路径，绕开上下离屏裁剪对packed透明取样的破坏。App相关96通过/14跳过，Impeller另2项通过（68组RGBA消费对照误差/黑残影0）；SDK相关49通过，双方分析0。+50 release及Android原生编译、验包/验签通过，同+49内部证书；Agent未安装，Android OES/SurfaceProducer及原机观感待用户远程确认。

[定位、实现与交付](home-card-surface-stability-2026-11-06.md)。

## 2026-11-06：恢复点按与上下退场节奏 / +49

运行/构建源 `8475c71f2bdb2eb69456c7fe400fe4f594f1d7b0`，候选分支 `codex/home-card-exit-easing-20261106`；`1.1.0+49` / arm64 `2049`。SDK仍 `b4861c5215280c49bffe03b8c203074217dcf995`，lock保持；日常目录 `feat/ui-detail-polish@25260b3` 保持。

按用户最新反馈完整撤回长按识别/吸附动效，恢复原点按展开。全向翻牌保留；退出目标按实际投影边界离屏剩余距离计算，放缓竖向弹簧并限制沿射线的起始速度，离屏后及时交接。相关10文件95通过/13跳过，Impeller像素另1通过，分析0；+49 release验包/验签通过，与+48内部包同签。Agent未安装，手感交用户远程确认。

[实现、节奏回归与包身份](home-card-exit-easing-2026-11-06.md)。

## 2026-11-06：动作牌手势与首展减负 / +48

运行/构建源 `1d89e8916513639b5a56e57997170754ae103404`，候选分支 `codex/home-card-touch-motion-20261106`；`1.1.0+48` / arm64 `2048`。SDK仍 `b4861c5215280c49bffe03b8c203074217dcf995`，lock保持；日常目录 `feat/ui-detail-polish@25260b3` 保持。

短按立即展开，300ms长按轻抬且可继续跟手；任意方向拖出径向区域均可翻牌，并沿原射线离场。持当前视频帧完成展开后自动播放，刊头/编号等改固定画布缩放，以减少首次起播和重复排版与过渡并发。相关10文件94通过/13跳过，Impeller像素另1通过，分析0。+48 release验包/验签通过，与+47内部包同签；Agent未安装，首次展开及手感交用户远程验收，未采集原机性能trace。

[交互、性能边界与包身份](home-card-touch-motion-2026-11-06.md)。

## 2026-11-06：首页切牌静默加载 / +47

运行/构建源 `bba10fdb98934cea5e9f27c3062a7ad74d79e43c`，候选分支 `codex/home-card-silent-loading-20261106`；`1.1.0+47` / arm64 `2047`。SDK固定 `b4861c5215280c49bffe03b8c203074217dcf995`，hosted锁保持；日常目录 `feat/ui-detail-polish@25260b3` 保持。

首页下载/待首帧不再显示转圈，保持封面至真实首帧，由同一播放器接上；真实失败重试保留，普通宿主默认提示保持。App相关10文件88通过/13跳过，Impeller像素回归另串行1通过；SDK相关31通过，双方分析0。+47 release验包/验签通过，与+46内部包同签；交用户远程覆盖测试，Agent未安装，实际切牌/首帧观感待反馈。

[实现、检查与包身份](home-card-silent-loading-2026-11-06.md)。

## 2026-11-06：杂志动作专页 / +46

运行/构建源 `21dd048940baef24a4e3d7186163ae626b062fcf`，独立分支 `codex/home-card-editorial-20261106`；`1.1.0+46` / arm64 `2046`。SDK仍 `1c082e9d3e22022f228888fdd1935b1d61371cb9`，lock、shader、媒体与原生代码保持。日常目录 `feat/ui-detail-polish@25260b3` 保持。

按用户两项反馈，移除“左右翻阅”及两侧箭头整个底行和预留；前后牌共用同一Face，标题/视频比例及材质不再在到顶时切换。展开态采用刊头细线、放大单序号、侧栏、强调标题、动作要领和页脚印记的杂志版式，保留原动作分类、方向、剂量和说明内容。

相关10文件87通过/0失败/13跳过（12既有截图项+1需Impeller）；真实shader像素回归另以 --enable-impeller 1通过。fatal-infos分析0，严格锁解析不改lock。未重新跑全量App/SDK。 最终+46 release已构建、验签和资源校验，未由Agent安装，继续交用户远程覆盖测试。Noto字体浅深实际widget渲染已检查，组件逐帧与headless Impeller证据不替代原机滑动/展开观感及帧时长验收。

[版式、连续性与交付](home-card-editorial-2026-11-06.md)。

## 2026-11-06：透明视频黑轮廓修复 / +45

运行/构建源 `9925e3c58afdea65768875f85ee3a4b60865a6f0`，分支 `codex/home-card-alpha-alignment-20261106`；`1.1.0+45` / arm64 `2045`。SDK仍 `1c082e9d3e22022f228888fdd1935b1d61371cb9`，lock、shader/素材内容及原生代码保持；日常目录 `feat/ui-detail-polish@25260b3` 保持clean。

用户+44截图显示坐姿后撑单膝内倒等前牌人物后缘有错位黑轮廓。+45为前牌姿态Transform设置非空filterQuality：先在局部坐标合成视频RGB/alpha，再将整张牌作为GPU滤镜结果做透视/旋转；保留同一直播Texture、当前帧暂停和展开/收起行为。

常规10文件85通过/0失败/13跳过（12既有截图跳过，1项真实shader像素测试需Impeller）；该像素测试另以 --enable-impeller 单独运行1通过。新增像素和实际layer断言在旧路径先失败，修复后通过；fatal-infos分析0，严格锁解析不改lock。 最终+45已构建、验签和资源校验，未由Agent安装。继续交由用户远程覆盖安装，原机视频取样、文字清晰度和帧时长仍待反馈；本机headless Impeller与合成图案不代替手机GPU/SurfaceProducer验收。

[定位、像素对照与交付](home-card-alpha-alignment-2026-11-06.md)。

## 2026-11-06：同一视频牌面 / +44

运行/构建源 `c0798ecc6a9ef5f91bfa0221cee5bb2c42dfad38`，独立分支 `codex/home-card-live-surface-20261106`；`1.1.0+44` / arm64 `2044`。四个实际SDK包及coach override固定 `1c082e9d3e22022f228888fdd1935b1d61371cb9`；hosted锁、Flutter3.44.7及素材内容保持。日常目录仍 `feat/ui-detail-polish@25260b3`，保持clean。

用户在+43交付后反馈展开/收起仍闪，并提出同一视频元素方案。+44将当前前牌常驻root OverlayPortal：初次准备首帧暂停，展开只改变同一牌面的矩阵/大小并播放，关闭立即暂停当前帧并缩回，compact继续显示该帧；再次展开继续播放。移除App快放回首调用、两面交接、截图捕获及专用弹层路由。

App相关9文件85通过/0失败/12既有截图跳过（牌组34项）；SDK runtime相关29项通过，双方fatal-infos分析0，App严格锁解析通过，lock仅四个Git节点ref变化。未跑全量App/SDK。 最终+44 release已构建、验签及资源校验，尚未由Agent安装；按用户决定交由用户远程安装测试。同一节点/纹理身份的组件回归和浅深色实际widget绘制检查已完成，原生首帧准备与真实过渡观感等待用户反馈，不能记作真机无闪烁通过。

[方案、包身份与验收归属](home-card-live-surface-2026-11-06.md)。

## 2026-11-06：动作视频回首 / +43

运行/构建源 `32ac1a76e12894f6aedb8218be0b35a591fd3461`，分支 `codex/home-card-return-fix-20261106`；`1.1.0+43` / arm64 `2043`，四个实际 SDK 包及 coach override 固定 `4b9b685788352415fbfce2d8a2651f7f9d207512`。日常目录保持 `feat/ui-detail-polish@25260b3`；本轮在既有 E 盘隔离副本开发。

关闭展开牌时，先复用当前视频有界快放走完剩余循环、回首暂停，再执行原有缩牌；退场期间保留同一视频表面，避免路由失去 current 后过早切成封面。暂停后关闭也走同一流程，重复关闭合并。

App 相关9文件84通过/0失败/12既有截图跳过（牌组33项）；SDK runtime相关26项通过，双方 fatal-infos 分析0。App严格锁解析通过，lock仅四个Git节点ref变化，hosted版本/摘要/来源保持；未重新跑全量App或全量SDK测试。 最终+43包已构建并完成签名/资源校验。用户随后明确本轮没有本地真机，改由用户远程安装测试；安装状态与视频快放、首帧交付及缩牌真实观感均待用户反馈，组件/fake平台通过不等于原生验收。

[实现、包身份和待验](home-card-return-2026-11-06.md)。

## 2026-11-06：导航性能 / +41

运行/构建源 `58aa468c2707361e917cea2b75fc4561a23b4473`，独立分支 `codex/navigation-transition-perf-20261106`；`1.1.0+41` / arm64 `2041`。继承+40动作牌，SDK97eb66d、lock、资源与原生配置不变。

将每条顶栏的三层模糊显式裁剪到实际条带，保留固定返回键、三层参数、400ms进入/340ms返回与原曲线。二级路径真机profile暖态对照中，raster超过120Hz阶段预算的帧比例由96.5%降至12.8%；该指标不是实际显示掉帧率。 最终release已安装，用户要求的锁屏已完成。[定位、量化与验收](navigation-jank-2026-11-06.md)。

## 2026-11-06：首页动作牌 / +40

运行/构建源 `ba40e38a783975f17fcd682606e8b5bd092b7b25`，独立分支 `codex/home-action-deck-20261105`；`1.1.0+40` / arm64 `2040`。SDK仍固定97eb66d，lock、资源和原生配置未改。

最终+40同签名覆盖安装成功，回读2040/1.1.0。真机验证任意方向拖动可覆盖上下标题/底栏，纵向及斜纵向释放回位、横向区域切换；展开保留边距，介绍正常，视频默认帧变化、暂停帧相同、继续后帧变化，收起恢复首页。 [交互与验证](home-action-floating-2026-11-06.md)。+38确认与+39/+40增强证据分别归属。

## 2026-11-05：UI r4 全界面补全 / +36 真机包

本轮补全使用独立分支`codex/ui-r4-completion-20261105`，源码`6e247aa`，+36/2036内部release已安装到连接的小米设备。保留已批准设计，修页面/状态遗漏、无调用旧界面及公共组导入Coach错误。详细[审核与验证](ui-r4-completion-2026-11-05.md)、[包身份](version-ledger.md)、[当前状态](current-state.md)。本分支SDK仍97eb66d，main/PR31集成另行处理；下方+35/+34文字保留各阶段归属。

## 2026-11-05：UI r4 / PR #32 合并复审

日常目录按用户要求切换到 `feat/ui-detail-polish`；本轮修复更多→设置的双返回胶囊边界并补回归。审核、源码和证据归属见 [PR #32 复审报告](ui-r4-pr32-review-2026-11-05.md)。合并目标保持 SDK 候选分支，main/PR #31 单独处理；版本保持 +35，无新 APK 或本轮真机验收。

## 2026-11-04：QA v3 / +34 主线与交付

PR #30 已合入 main，功能集成点 `2400b34`，版本 **1.1.0+34 / 2034**，SDK `f7b8a8e`（v0.7.2 内容）。测试/构建源 `0f0882e` 与集成点同树，analyze 0、全部 66 文件 461/0/68；+34 已交付、未安装。本轮只做版本文档收束，复用有效证据，不增版或重建。

用户确认 +33 未出包、手机现装 +32，+34 已与实际 +32 验签一致；包路径、文件/证书 SHA-256 见[版本台账](version-ledger.md)，同树证明和未验边界见[验证台账](verification.md)。旧 +31 的实模对话仅是旧 SDK 历史。下方 +32/+31 保留当时状态，不能用于判断当前 main 或手机。

## 2026-11-04：AI 教练修复测试包 +32（历史）

SDK 3e949ce / c327a90，1.1.0+32（arm64 2032），analyze 0、全量 461/0/68。同 +31 签名测试包已备好，用户远程安装验坏记录恢复、三轮含排计划与重启续聊；本轮未安装，不合 main。详见 [sdk-qa-fixes-plus32-2026-11-04.md](sdk-qa-fixes-plus32-2026-11-04.md)。

## 2026-11-04：SDK 0.7.1 QA v2 / +31 候选（历史）

`codex/sdk-pin-v0.7.0` 已接正式SDK `9dd93163`：原SDK聊天页打开qaV2并传App的209条未审AI标签，模型deepseek-v4.1-flash/max；App无问答适配层，原211范围及保存/开练门禁保留。1.1.0+31/2031内部包构建源 `2c13e8a119409c857508c6c3e79dc27241e8e702`。严格analyze0，全部66个test文件461通过/0失败/68既有条件跳过；真实宿主3段9轮18次请求与计划保存通过。

测试APK已备好，同签名、211封面/0MP4，交用户远程安装；本轮未安装，候选不合main、release/商店不动。两条缺标签按目录回退、无替换候选时保留原动作，详细边界见[完整接入与验证](sdk-qa-v0.7.1-validation-2026-11-04.md)。当前main仍4d610f5，UIr3 PR29另行待验，下方main快照保留历史。

## 2026-11-04：当前导航

当前 main 已含 PR #26/#27/#28/#30，版本 **1.1.0+34 / 2034**、SDK pin `f7b8a8e`；UI r3 [PR #29](https://github.com/mhgd3250905/HipLab/pull/29) 仍为 Draft，待用户真机反馈。旧“PR30 候选未合 main”等文字是当时快照。

| 要查什么 | 当前来源 |
|---|---|
| 近期成果、分支与验收边界 | [当前状态](current-state.md) |
| +34 交付、+33 未构建、用户报告 +32 与旧 UI r3 包的区别 | [版本台账](version-ledger.md) |
| 主线同树沿用 461/0/68、旧 SDK 对话及候选 434/68 的适用范围 | [验证台账](verification.md) |
| 已完成事项及剩余真机反馈 | [开发事项](development-roadmap.md) |
| App/SDK 版本和媒体来源规则 | [版本管理](version-management.md)、[开发工作流](development-workflow.md) |

本次只对齐文档并保存提交，不增版、不构建、不安装、不合并 UI r3。日期专题报告是历史证据，不能替代以上当前台账。

## 2026-11-03：PR #27 r2候选验证完成，待用户远程安装

保留已确认的r2结构，仅修每日训练分钟重复取整，补混合组实际SDK阶段/组间休息/完成保存回归。验证构建源`f4714c6`；analyze0，64文件按4文件/批全部通过，含新增回归去重454通过/0失败/68条件跳过（opt-in截图/导出）。47.64MiB release候选保持+30/2030、同测试签名/0MP4，交用户远程安装验混合组和旧数据，本轮未安装。只正常字体，不合main、不升版、不动release/商店。[交付与APK身份](ui-r2-pages-integration-2026-11-03.md)。以下为历史阶段。

## 2026-11-02：PR #26 首页主题合入，+30 已保留数据安装

用户确认设计并授权合并，PR26在同步最新main后验证通过，合并点`a201fd5`；1.1.0+30/2030构建源`a7e371e`，47.70MiB release APK已同签名覆盖安装。analyze0、全量444通过/0失败/13条件跳过，额外截图4通过。正常字号浅深快速走查无新增显示问题，6天训练汇总、自测10/12、2组及主要设置保持；详细使用交用户。SDK仍d4502f3/211动作，日常40个WIP未变，release/tag/商店不动。[交付、脚本删除清单与验收边界](home-calm-r1-2026-11-02.md)。下方为历史阶段。

**2026-11-02 17:14 更正后的 +29 完成：** 浏览/Coach同一211动作集合，8partial及未用封面排除；analyze0、全量437通过/1既有条件跳过、Python25/25，47.64MiB release APK/2029、211封面/0 MP4。日常40个WIP逐字节恢复，普通推送分支、不合main。[最终交付](full-action-scope-completion-2026-11-02.md)。以下219方案与SDK等待条件保留历史，已由211决定替代。

**2026-11-02 全动作继续核查：** 用户已确认219浏览/211规划，但固定SDK共享动作库列表、筛选和详情均拒绝8个partial，没有公开开关。此前将SF219授权等同实际浏览的结论已更正。219张封面准备完成，按SDK问题边界停止，尚未改scope/运行接线或出+29。[SDK阻塞与准备成果](full-action-scope-2026-11-02.md#用户明确-219-浏览--211-规划后的-sdk-界面阻塞)。

**2026-11-02 主线合入与全动作预检：** 用户确认 +28 真机通过，main 已快进并普通推送到 `d0c28c5`。新分支 `codex/full-action-scope` 预检发现 SDK 8 条训练元数据缺项，依授权边界停止；SF 实际为219可浏览/211可组计划，媒体缺失0。本轮仅记录文档，未改功能、未生成+29。[合入回执与8项清单](full-action-scope-2026-11-02.md)。以下待用户验收等为历史状态。

**2026-11-02 共享体验 +28 候选完成：** 用户16:19授权删除2倍字号用例，共11条；其余失败按真实SDK入场/图片/滚动契约适配，严格analyze0、全量428通过/1既有条件跳过。43.40MiB release APK、0 MP4、连续测试签名已备好，待用户安装自测。[最终交付与删除清单](sdk-shared-experience-completion-2026-11-02.md)。不合main、不动release、托管或Flare；下方为历史。

**2026-11-02 启动定位更新：** App 大型 catalog 读取已修复，最小/断网启动各1通过，严格analyze0；全量385通过/19失败时确认SDK动作库键盘布局溢出，按边界停止，不绕过SDK、不重建APK。[根因与后续交接](sdk-shared-experience-2026-11-02.md#启动定位更新2026-11-02)。以下为前轮历史。

**2026-11-02 共享体验接入暂缓：** `codex/sdk-shared-experience` 基于 main `0f507a3`，统一 pin SDK `d4502f3`、Launcher / public mediaPolicy / SDK library 已接线，移除94内置MP4，版本+28。严格analyze0、Python25/25、首次构建0 MP4；Flutter两轮仍失败，按约停止，无最终交付APK。[本轮报告](sdk-shared-experience-2026-11-02.md)。

**2026-11-02 第5批主线集成：** 用户已批准将固定候选`c8cf82f`非快进合入main，合并点`9054932`；main的10月27日iOS审核文档原文保留。合并复核见[验证台账](verification.md)，下方“不合main”等为候选阶段历史约束。release不动、不tag、不重打APK、不提交商店。

**2026-11-02 第 5 批对话模块候选：** `codex/coach-chat-sdk` 基于本机 main，固定用户确认的 SDK `7d9be56`，旧对话实现已删除，App 仅保留 profile 和宿主端口。APK、门禁、删除清单、pin 与用户安装验收边界见[一页报告](coach-chat-sdk-2026-11-02.md)。不合 main、不动 release、不打 tag、不提交商店。以下为历史状态。

**2026-10-24 Controller 已合入 main：** 固定候选448f109已获开哥同意，快进合入并普通推送main、远端回读一致。既有分析0、全量454通过/1条件跳过和专项44通过保持；release/1.0不动。以下待审记录为批准前历史。[集成回执](sdk-conversation-controller-2026-10-24.md#主线集成回执)。

**2026-10-24 对话 controller 候选：** `codex/coach-conversation-050-20261024` 基于 main64daf6a，采用 coach0.5.0 / trainer0.2.3@d7e0b8f，UI0.1.1保持；SDK接管消息、问题、回答整理和取消/重置/恢复。严格锁解析完成，分析0、全量454通过/1条件跳过、AI专项44通过，候选已完成待审，main合推等待本轮同意。release/1.0不动。[接入与删除范围](sdk-conversation-controller-2026-10-24.md)。

**2026-10-24 SDK 修复 tag：** coach0.4.2 / trainer0.2.2 / coach_ui0.1.1均固定3302d62，远端解析完成；分析0、窄屏专项13通过，全量451通过/1条件跳过。本轮已合入并推送main（功能集成点88d8802），release/1.0不动，真机沿用既有证据。[补丁与集成回执](sdk-tag-patch-2026-10-24.md)。以下为先前阶段记录。

**2026-10-24 SDK 共用界面候选：** 开发版 1.1.0+21 位于 `codex/sdk-shared-ui-20261024`，coach 0.4.1 / trainer 0.2.1 / coach_ui 0.1.0 正式 tag 固定。无 Key 隐藏 AI，本轮分析0、451通过/1跳过、release编译及真机M自然完成通过，语音用户确认正常；等待最终合并同意；release/1.0 保持基础版。[接入与验证](sdk-shared-ui-2026-10-24.md)。

**2026-10-24 13:09：** 1.0.0(20)已提交Alpha审核，Submission ID2状态审核中；前台服务演示和公开隐私已补齐。正式版仍需12名真实测试者连续14天，用户选择稍后组织。[执行回执](play-store-release-2026-10-24.md)。以下上架准备段落保留历史。

**2026-10-24 基础版上架准备：** `release/1.0` 从 main e456d2a 建立，1.0.0+20 / SDK固定d193a70，无Key本地预设、保留AI入口。上传签名AAB和商店/FGS材料已准备；Play由开哥操作，Mac从release分支接iOS。[本轮交付](release-1.0/README.md)。以下日期条目为历史记录。

**已获同意，两个main均已合入并推送。** 2026-10-21用户明确“合并并推送，保留锁屏已知问题”；SDK main为d193a70（PR #2已MERGED，00:39:10），HipLab主线集成点691ace2（00:39:31）。已安装包保持0.3.9+17/79c172d、21原记录/4组/UUID保持；锁屏冻结仍是已知失败，由用户后测，不重建/重测、不改手机省电设置、不上传商店。[合并与边界](android-lockscreen-fix-2026-10-21.md#主线合并确认2026-10-21)。

以下按日期保留的候选、安装与失败段落均为历史快照，其中“当前”“未合main”“待解锁”描述当时现场；当前交付与授权以页首最新结论及对应台账为准。

**00:08失败阶段快照：0.3.9+16锁屏仍失败。** 00:07:47.193 Greeze冻结（关屏5分25.7秒），服务和started/mutedState:none音轨仍在、训练锁DISABLED；系统媒体会话栈为0。不能把正常音量修正记为锁屏通过。当前安全锁屏，待用户回来解锁后正常结束本轮；SDK正在补真实媒体会话与释放，main未合。[完整现场](android-lockscreen-fix-2026-10-21.md)。

**00:02安装快照：0.3.9+16已保留数据安装。** SDK8fb0aac/trainer0.1.3将Android全零采样音轨设正常播放器音量；119训练包测试和App439过/1跳、analyze均通过。20记录/4组/UUID保持；当前8动作整节锁屏观察中，main未合。[本轮修复与结果](android-lockscreen-fix-2026-10-21.md)。

**2026-10-20 23:53阶段快照：0.3.9+15已安装，但整节锁屏再次失败：** [AI新中转](ai-relay-migration-2026-10-20.md)的App Key、UUID及手机AI生成/保存通过，439项过/1条件跳、analyze0；23:50:21.914小米Greeze再次冻结并禁用训练锁。亮屏恢复后用户正常结束，528秒、6/8、提前结束，现20记录/4组，训练服务已释放。main未合，待SDK修复、整节复验和最终同意。[训练包接入与失败历史](ugk-trainer-adoption-2026-10-20.md)。

**上一轮修复候选快照：** [ugk_trainer 接入](ugk-trainer-adoption-2026-10-20.md)在 `codex/adopt-ugk-trainer`。首轮0.3.8+13锁屏失败，SDK7348f0c/trainer0.1.2已补Android间隙保活与终态释放，118测试通过；新包0.3.8+14已保留数据覆盖安装，analyze0，App全量429过/1条件跳。用户已改为扬声器锁屏复测，现因需使用其他App暂缓，待用户恢复；main未合，待验收与最终同意。

**2026-10-20 早间主线构建快照：0.3.7+12，带AI配置、debug arm64，同包名/签名；该阶段只构建未安装、未发布。** 来源55d99b3，业务沿用PR25已验8c985c4；当前安装已变化，见页首主线交付。[早间APK身份与交付边界](android-test-build-0.3.7-2026-10-20.md)。

**2026-10-20 11:24:56：PR #25已获开哥明确同意，合入并普通推送main，GitHub确认MERGED。** 来源8c985c4 / SDK0.1.2，集成点ce7ab74；原5P2闭环，414过/1条件skip、analyze/构建/API通过。真机未验仍保留，手机未更新、不发布；[合并与复审](pr25-reaudit-2026-10-20.md#主线合并确认2026-10-20)，[首轮历史](pr25-review-2026-10-20.md)。

**此前主线集成：2026-10-19 23:32，PR #22/#24及集成修复已获开哥同意，合入并推送main（b33ed21），GitHub均MERGED。** 387项通过/1条件跳过，F1–F9及PR24四P2闭环，Android正常播放与编辑/键盘已验；手机已安装运行内容保持，版本仍0.3.6+11。[合并身份与验收边界](pr22-f9-reaudit-2026-10-19.md)。

此前阶段记录：**2026-10-19：本轮c7def28 / 0.3.6+11审阅包已交付，用户报告真机安装及简单测试通过；三PR及修复已按#19→#20→#21顺序合入并推送main（业务集成点b9646d4）。** 完整试听/锁屏/性能等待验范围见[本轮审核](pr19-pr21-review-2026-10-19.md)。以下#17/#18事实为此前主线交付历史。**PR #17/#18 已修复两项P2并顺序合入main，Android当时已保留数据安装0.3.6+11修复包（源码6dd16ed）**；analyze0、191pass/1条件skip，深浅及减少动画分段下沉、快速Tab、原生视频退出已复查，偏好逐字节保持，见[修复与合并记录](pr17-pr18-fixes-and-merge-2026-10-18.md)。此前[0.3.6样式安装](theme-polish-2026-10-18.md)和[0.3.5语音试听](android-voice-media-routing-2026-10-18.md)保留历史；当前冻结Pose-Hub v0.2.0（46条1080视频/46张540封面）。完整课程、音乐ducking、低端帧时、强光及iPhone仍待补。

| 文档 | 用途 | 何时更新 |
|---|---|---|
| [训练包接入](ugk-trainer-adoption-2026-10-20.md) | 训练执行/播放/语音/唯一服务归包，App保留业务插槽；首轮及候选失败历史 | 接口或集成事实变化时 |
| [AI新中转迁移](ai-relay-migration-2026-10-20.md) | App Key、持久UUID、新入口及手机生成保存证据；不存凭据 | 配置约定或验证结果变化时 |
| [Android锁屏复测与主线确认](android-lockscreen-fix-2026-10-21.md) | 0.3.9+17已安装、两main已合推；锁屏已知失败交用户后测 | 实际验收或集成事实变化时 |
| [0.3.7+12 Android测试包](android-test-build-0.3.7-2026-10-20.md) | 55d99b3，AI配置debug arm64；仅构建、未安装、未发布 | 实际交付状态变化时 |
| [PR #25修复复审与合并](pr25-reaudit-2026-10-20.md) | 8c985c4 / SDK0.1.2，414过/1跳，已合main；真机未验保留 | 验证或集成事实变化时 |
| [PR #22 F9返回复审](pr22-f9-reaudit-2026-10-19.md) | F9关闭；387项及原生编辑/键盘通过；#22/#24已合main并推送，GitHub均MERGED | 集成时 |
| [PR #24修复与#22组合验证](pr24-reaudit-and-pr22-integration-2026-10-19.md) | 0ccef6b原4P2闭环；正常播放及用户听音通过；F9后续关闭并随#22/#24合main | 作者F9修复及集成时 |
| [PR #22 Android真机复测](pr22-native-retest-2026-10-19.md) | 2cc40e3阶段F8通过、新增F9后续已修复合入；解锁后英文保持/闹铃已补，扩展系统矩阵及极大字号退出本阶段门槛 | 真机结果及作者修复后 |
| [PR #24 Android后台语音审核](pr24-review-2026-10-19.md) | e3655e5首轮历史；四P2后续在0ccef6b关闭并合main，最新见组合与F9复审记录 | 保留首轮证据 |
| [PR #22 Web补充验收](pr22-web-acceptance-2026-10-19.md) | 9fa0cc0界面/迁移/F3/F4/F7及重复单练记录补测；首轮发现F8/P2，后续已关闭合main；该页保留当时Web证据与原生边界 | 修复版本及验收证据变化后 |
| [PR #22 修复复审](pr22-reaudit-2026-10-19.md) | F1–F7在9fa0cc0代码闭环、Windows322过/1跳；[Android包准备](pr22-android-acceptance-2026-10-19.md)及原生待验；[首轮报告](pr22-review-2026-10-19.md)保留 | 修复版本及验收证据变化后 |
| [练习库实现](training-library-2026-10-19.md) | 拍板四条、动作大全/单练/套路/训练组的实现范围、custom_routines v1、PR #22 审核 F1–F6、复审 F7、Web 补充验收 F8/P3 修复、测试与真机清单（PR22现已合main，历史阶段记录保留） | 练习库变化时 |
| [PR #19/#20/#21隔离审核](pr19-pr21-review-2026-10-19.md) | 五项首轮修复、254过/1跳、Python19、Web复核及arm64交付；用户报告安装/简单真机测试通过；已顺序合入main | 本轮审核与原生证据变化后 |
| [轻拟物有选择引入：审美考据](tactile-design-rationale-2026-10-19.md) | 引用 HIG / M3 / Refactoring UI / NN/g / Rams 推导的 6 条规则、逐控件判定、预算回归测试（#19已合main） | 拟物使用范围变化时 |
| [PR #17/#18修复与合并](pr17-pr18-fixes-and-merge-2026-10-18.md) | 两项P2、191项回归、真机数据保持与合并身份 | 本轮实际状态变化后 |
| [0.3.6样式与阶段收束](theme-polish-2026-10-18.md) | 4项修复、源码/证据绑定、APK和19:29安装、验收边界 | 本阶段事实变化后 |
| [Pose-Hub v0.2.0 接入](posehub-v020-integration-2026-10-18.md) | 当前冻结资源、App 产物及验收边界 | 同步或实际结果变化后 |
| [第二轮集成记录](round2-integration-2026-10-18.md) | #13/#14 固定审核、语音生命周期、UI 回归、APK 与网页/原生边界 | 本轮事实变化后 |
| [动作素材浅/深主题](action-media-audit-2026-10-19.md) | 8 个展示位置盘点、方案比较、管线、体积、动作包对接（#20已合main） | 素材或方案变化后 |
| [主干与 Pose-Hub 集成记录](mainline-pose-hub-2026-10-18.md) | 四个 PR 合并、v0.1.0、最终构建与首帧原生待补边界 | 本轮状态变化后 |
| [第一轮 Android 集成验证](android-round1-integration-2026-10-17.md) | 原三阶段构建、真机及当时待合并边界；最新进展见当前状态 | 保留原阶段证据 |
| [Google Play 送审](play-store-release-2026-10-17.md) | 0.2.0+4 / Submission 1 的历史回执 | Console 实际变化后 |
| [Pose-Hub 接入](pose-hub-adoption.md) | v0.2.0 冻结同步、保留素材及两端边界 | 素材发布或同步时 |
| [UI 设计规范](ui-design-standard.md) | 顶栏/状态栏材质、几何、透明度曲线与页面接入方式；界面按标准实现，改标准先改这里 | 设计标准变化时 |
| [当前状态](current-state.md) | 当前 App、分支、PR、环境与完成边界 | 状态实际改变后 |
| [版本管理说明](version-management.md) | 版本来源、构建/安装/合并/推送/发布状态及台账维护规则 | 版本管理约定变化时 |
| [版本交付台账](version-ledger.md) | 每次构建、安装、发布的版本和产物身份 | 产生可交付版本时追加 |
| [验证台账](verification.md) | 哪个版本做过哪些检查，哪些尚未验证 | 完成检查后 |
| [开发事项台账](development-roadmap.md) | 缺陷、后续工作与验收条件 | 开工、受阻或验收时 |
| [开发工作流](development-workflow.md) | 主线集成、日常开发、媒体同步和 Android 更新步骤 | 流程或工具变化时 |
| [开发日志](development-log.md) | 关键决策、成果和对应证据 | 有意义的工作检查点 |
| [iOS 运行与上架](ios-setup-and-release.md) | Mac 上运行/归档步骤、iOS 配置清单、真机确认清单 | iOS 配置或验收变化时 |

开始新一轮开发先读当前状态和开发事项，检查实际 Git 分支，再按工作流推进。仅文档修改不增加 App 版本、不重新安装手机；完成业务改动后按影响范围验证并更新台账。PR 和提交保存代码事实，台账保存交付和验收事实，两者互相链接。

## 证据与历史记录

以下文档保留当时的核查过程；阶段性的“待完成”不代表当前状态。

| 文档 | 范围 |
|---|---|
| [接手基线](project-takeover-2026-10-17.md) | 初始代码、环境、48 项测试与已确认计时缺陷 |
| [媒体初始审计](media-audit-2026-10-17.md) | 制作前缺片、静帧和清晰度问题 |
| [语音播报审计](voice-audit-2026-10-18.md) | 播报中途消失的根因（iOS 会话被提前停用）、素材逐条检测前后对比、真机复听清单 |
| [本地高清制作](local-hd-render-2026-10-17.md) | 4080、PR #119、46 项选版、绿幕/透明母帧与制作过程 |
| [Android 实机记录](android-first-run-2026-10-17.md) | 首次安装及 0.1.1+2 保留数据更新、真机播放证据 |
| [主线集成审核](mainline-integration-2026-10-17.md) | #2、#1 固定版本审核、合并身份和本地对齐 |
| [App Icon 运动方向](app-icon-sports-2026-10-17.md) | D-05 用户新要求、两张候选、选版与安卓接入边界 |
| [早期 MVP 设计](hiplab-mvp-2026-10-16.md) | 从 3D-Body 变体拆仓前的设计背景 |

逐条媒体来源以 [hip-media.json](../tools/hip_content/source/hip-media.json) 为准；[hip-content.json](../assets/hip/hip-content.json) 是生成结果。APK、截图、运行日志与设备数据备份在 Git 忽略目录内；文档中的本机路径不代表这些文件已备份到 GitHub。

## 新机器拉素材（Mac / Windows）

### 当前 main：公共元数据、封面与 SDK 按需视频

从 Git 获取 `pubspec.yaml` / `pubspec.lock`、`assets/public_media/`、`assets/public_posters/` 和 `assets/coach/ai-tags/`。当前 main 已移除 94 个内置 MP4，`pubspec.yaml` 不打包 `assets/drill_media/`；**不要运行下方旧 ZIP 同步来回填视频**。公共目录/语义与 211 张封面、209 条未审 AI 标签随仓库保存；SDK 不自带 App 标签。`HipPublicMedia` 从这些元数据创建 SDK 媒体策略，视频按需获取并缓存，训练前是否可离线播放取决于所需媒体是否已缓存。

两端固定 Flutter **3.44.7 / Dart 3.12.2**，先用该版本执行 `flutter pub get --enforce-lockfile`，保持锁文件当前的 `pub.dev` 源，已有解析时才用 `--no-pub` 验证；不要为使用旧镜像缓存重写 lock。Mac 不升级依赖、版本或媒体。SDK pin、范围和已验结果见[当前状态](current-state.md)及[验证台账](verification.md)。

### 冻结 v0.2.0 ZIP 恢复（仅旧分支历史）

以下保留旧内置视频版本的来源、校验及恢复命令，适用于需要该资源布局的旧提交；其中“当前包/main”均指当时版本。当前主线使用上节流程。

先拉取 HipLab 的最新 `main`，以下命令均在仓库根目录执行。`pose-hub.lock.json` 和 `tools/pose-hub-manifest.json` 已随主线保存，固定 Pose-Hub **v0.2.0**；新机器直接使用这两个文件，不另取最新版 manifest。两端统一 **Flutter 3.44.7 stable**；Mac 不修改 lock、版本号或依赖，后续素材升级由 Windows 维护。

从公开的 [Google Drive v0.2.0 ZIP](https://drive.google.com/file/d/17M0oMpWIqWQJ19sMEOEsDF7H7AU9meqF/view?usp=drivesdk) 下载 `pose-hub-media-v0.2.0.zip`，保存到仓库中的 `build/pose-hub/v0.2.0/`。也可从 [版本分发文件夹](https://drive.google.com/drive/folders/12M4g7bpomaCjY7qdgYdfoUHuA2xla9lH) 获取同名文件。使用浏览器下载即可，不需要安装额外下载工具。

ZIP 必须恰为 **39,151,634 bytes**，SHA-256 必须为：

```text
f422c051eab2b4e973fe637d5f2a3dec07207e21b960f10800efe77dd317c772
```

Mac：先执行下面的校验与解压。任一断言失败会立即停止，不能跳过校验继续解压或同步。

```bash
python3 - <<'PY'
from pathlib import Path
import hashlib
import zipfile
archive = Path("build/pose-hub/v0.2.0/pose-hub-media-v0.2.0.zip")
assert archive.stat().st_size == 39151634, "ZIP size mismatch"
assert hashlib.sha256(archive.read_bytes()).hexdigest() == "f422c051eab2b4e973fe637d5f2a3dec07207e21b960f10800efe77dd317c772", "ZIP SHA-256 mismatch"
with zipfile.ZipFile(archive) as bundle:
    bundle.extractall("build/pose-hub/v0.2.0/extracted")
print("ZIP verified and extracted")
PY
```

然后按顺序执行；每条命令退出码为 0 后再执行下一条：

```bash
python3 tools/pose_hub_sync.py --lock pose-hub.lock.json --from-dir build/pose-hub/v0.2.0/extracted --dry-run
python3 tools/pose_hub_sync.py --lock pose-hub.lock.json --from-dir build/pose-hub/v0.2.0/extracted
python3 tools/pose_hub_sync.py --lock pose-hub.lock.json --from-dir build/pose-hub/v0.2.0/extracted --check
python3 tools/hip_content/build_hip_content.py
flutter --version
flutter pub get --enforce-lockfile
flutter analyze
flutter test --concurrency=1
```

Windows PowerShell：同样先通过浏览器把 ZIP 放到上述位置，再执行校验与解压：

```powershell
@'
from pathlib import Path
import hashlib
import zipfile
archive = Path("build/pose-hub/v0.2.0/pose-hub-media-v0.2.0.zip")
assert archive.stat().st_size == 39151634, "ZIP size mismatch"
assert hashlib.sha256(archive.read_bytes()).hexdigest() == "f422c051eab2b4e973fe637d5f2a3dec07207e21b960f10800efe77dd317c772", "ZIP SHA-256 mismatch"
with zipfile.ZipFile(archive) as bundle:
    bundle.extractall("build/pose-hub/v0.2.0/extracted")
print("ZIP verified and extracted")
'@ | python -
```

确认上一条成功后，逐条执行：

```powershell
python tools/pose_hub_sync.py --lock pose-hub.lock.json --from-dir build/pose-hub/v0.2.0/extracted --dry-run
python tools/pose_hub_sync.py --lock pose-hub.lock.json --from-dir build/pose-hub/v0.2.0/extracted
python tools/pose_hub_sync.py --lock pose-hub.lock.json --from-dir build/pose-hub/v0.2.0/extracted --check
python tools/hip_content/build_hip_content.py
flutter --version
flutter pub get --enforce-lockfile
flutter analyze
flutter test --concurrency=1
```

ZIP 根目录直接包含动作 ID 文件夹，例如 `glute-max-A/`，没有额外的 `v0.2.0/` 层。因此 `--from-dir` 必须指向 `build/pose-hub/v0.2.0/extracted` 本身，不能再加版本子目录。ZIP 内没有 manifest；同步工具读取仓库已提交的冻结 manifest。`build/` 已被 Git 忽略，ZIP 和解压目录不提交。

当前包为 **46 条 1080×1080 dark 视频 + 46 张 540×540 JPG 封面**。封面 540 是 v0.2.0 发布规格，不能继续写成 1080 封面；视频与封面均按 manifest SHA 校验。

此包只含 46 个动作的 dark 视频和封面，共 92 个文件。`supine-cross-demo` 为 HipLab 自有剪辑，实际文件为 `assets/drill_media/hip-supine-cross-demo.mp4` 与 `hip-supine-cross-demo.jpg`，自测 still 保留既有 `assets/hip/assessment/`，light不在此冻结ZIP；main现由PR #20另带47套浅色视频/封面与20张浅色自测图。三者均不在此ZIP或当前lock中，不删除现有资源；冻结ZIP不代表本次App包只含深色素材。首次同步用于恢复已冻结的构建资源，不改变素材版本或 ID；`--check` 必须退出 0，内容重生成后如有意外差异，应先核对来源，Mac 不自行修改 lock 或升级依赖。
