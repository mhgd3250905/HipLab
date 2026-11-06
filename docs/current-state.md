# 当前状态

## 2026-11-06：文件夹选组 / +53待用户确认

构建源`2d46ab1e4fcc0d696ae3748330863ccb93fb94aa`，候选`codex/home-routine-folder-20261106`；`1.1.0+53` / arm64 `2053`，SDK保持`6fbd7de15dea62c7152eac43df1303b85d887a7c`、lock保持。已验收+52保留历史，本轮新增文件夹等待用户确认。

首页“换一套”改64pt四动作封面的玻璃文件夹，原位展开当前场景全部有效推荐组，展示名称/时长/动作数与选中状态，可直接选择。关闭完成再更新首页；取消或重复选择保留预览与视频，办公/居家各自记住本次启动的选择，实际开练使用所选完整计划。只用SDK静态封面，无额外视频节点。相关10文件108通过/14既有跳过，文件夹7项另通过，分析0。已同签覆盖安装真机，包管理器回读2053、MainActivity启动成功。新动效与交互观感待用户确认；本轮无全量、iOS或模型验收。[实现与交付](home-routine-folder-2026-11-06.md)。

## 2026-11-06：+52用户真机验收通过

用户在+52覆盖安装后明确回复“我已已经验收通过了”，当前`1.1.0+52`（arm64 `2052`，构建源`59ce2b8`）记为**用户真机验收通过**。本轮首页动作卡片及计划切换优化的用户验收项已收束；不另推定未报告的逐项测试或性能指标。安装回执与APK身份保持，未重建或改运行代码；候选分支仍为`codex/home-plan-media-continuity-20261106`，合并状态独立记录。

用户确认回执：`E:/AII-3D/hiplab-releases/home-plan-59ce2b8-52-20261106/user-acceptance-20261106.json`。下方“待验收”保留为交付时历史，当前以本条为准。[实现与交付](home-plan-media-continuity-2026-11-06.md)。

## 2026-11-06：+52真机覆盖安装与启动回执

用户重新连接手机并明确授权安装。已在`2602BRT18C`（`QSG6Q8IFDMDELVGQ`）执行`install -r --no-incremental`，回执Success；包管理器从2051更新为2052（1.1.0），设备lastUpdateTime为2026-11-06 22:12:14。未卸载、未清数据；原firstInstallTime仍为2026-11-05 22:11:33，未另核验业务数据。`com.ugk.hiplab/.MainActivity`冷启动Status ok；这里只确认安装与启动，卡片切换/展开/播放观感仍待用户使用反馈，不据此宣布视觉或性能验收。

安装包仍为构建源`59ce2b8`，SHA256 `3bac5de8477199360cab68c74cfaa446c1c2f74d3f5117ba752b4a2a203692e9`；无重建、运行代码、SDK或版本变更。安装回执留`E:/AII-3D/hiplab-releases/home-plan-59ce2b8-52-20261106/device-install-20261106-221214.json`。下方交付时“未安装”保留为历史；当前状态以本条为准。

## 2026-11-06：办公/居家首牌稳定 / +52待远程验收

运行/构建源 `59ce2b8829d64eec401c743123d31c57e79d4a62`，分支 `codex/home-plan-media-continuity-20261106`；`1.1.0+52` / arm64 `2052`。SDK仍固定 `6fbd7de15dea62c7152eac43df1303b85d887a7c`，hosted锁保持；日常目录 `feat/ui-detail-polish@25260b3` 未改。

针对办公/居家首牌闪动，将冷牌保护统一覆盖初始首牌、场景/换一套/跨日/动作列表重置，以及关闭后迟到首帧。新牌保持封面，主动展开才揭示原视频；同一已就绪当前动作成为新首牌时保留State/controller/Texture与当前帧。提前解码两场景当前可选计划的首封面，精确匹配bundle和显示尺寸，不批量下载视频。新增6项回归；相关10文件106通过/0失败/14既有跳过，分析0；Impeller另2通过、62组RGBA消费对照误差/黑残影0。SDK/Android和+51运动参数未改，本轮未重复SDK测试。

+52 release验包/验签通过，与+51内部包同签。未安装、未跑全量/模型/iOS；远程手机观感待用户确认。[实现与交付](home-plan-media-continuity-2026-11-06.md)。

## 2026-11-06：连续接牌与纵向惯性 / +51待远程验收

运行/构建源 `2087649d8c0dc8b34827c8458876886e55330662`，分支 `codex/home-card-handoff-motion-20261106`；`1.1.0+51` / arm64 `2051`。SDK固定 `6fbd7de15dea62c7152eac43df1303b85d887a7c`，hosted锁保持。日常目录 `feat/ui-detail-polish@25260b3` 保持。

用户确认+50的更多闪帧/上下透明异常修复。新候选预备current±1最多3挂载暂停媒体，到顶按occurrence GlobalKey接管原State/controller/Texture；冷首帧迟到保持compact既有图，主动展开解除。上下仍用物理曲线，取消900硬限速、竖k70/ζ.82，水平原值保持。相关100通过/14跳过，强化甩速另1通过，Impeller另2通过/62组RGBA像素0误差；SDK54通过，双方分析0。+51 release验包/验签通过，与+50内部包同签；Agent未安装，新接牌及手感待用户远程确认。

[实现、资源范围与交付](home-card-handoff-motion-2026-11-06.md)。

## 2026-11-06：暂停帧覆盖保持与离屏透明合成 / +50待远程验收

运行/构建源 `981eeaf161c0b896e963d625f9525b69e9bf32b6`，候选分支 `codex/home-card-surface-stability-20261106`；`1.1.0+50` / arm64 `2050`。四个SDK包及coach override固定 `145e3195570f34536c948558e02306a3db5ec2e3`，hosted锁保持；日常目录 `feat/ui-detail-polish@25260b3` 保持。

仅首页前牌启用暂停帧跨覆盖路由保留和原生单decoder RGBA输出：解决进入更多时回封面的明确路径，绕开上下离屏裁剪对packed透明取样的破坏。App相关96通过/14跳过，Impeller另2项通过（68组RGBA消费对照误差/黑残影0）；SDK相关49通过，双方分析0。+50 release及Android原生编译、验包/验签通过，同+49内部证书；Agent未安装，Android OES/SurfaceProducer及原机观感待用户远程确认。

[定位、实现与交付](home-card-surface-stability-2026-11-06.md)。

## 2026-11-06：恢复点按与上下退场节奏 / +49待远程验收

运行/构建源 `8475c71f2bdb2eb69456c7fe400fe4f594f1d7b0`，候选分支 `codex/home-card-exit-easing-20261106`；`1.1.0+49` / arm64 `2049`。SDK仍 `b4861c5215280c49bffe03b8c203074217dcf995`，lock保持；日常目录 `feat/ui-detail-polish@25260b3` 保持。

按用户最新反馈完整撤回长按识别/吸附动效，恢复原点按展开。全向翻牌保留；退出目标按实际投影边界离屏剩余距离计算，放缓竖向弹簧并限制沿射线的起始速度，离屏后及时交接。相关10文件95通过/13跳过，Impeller像素另1通过，分析0；+49 release验包/验签通过，与+48内部包同签。Agent未安装，手感交用户远程确认。

[实现、节奏回归与包身份](home-card-exit-easing-2026-11-06.md)。

## 2026-11-06：动作牌手势与首展减负 / +48待远程验收

运行/构建源 `1d89e8916513639b5a56e57997170754ae103404`，候选分支 `codex/home-card-touch-motion-20261106`；`1.1.0+48` / arm64 `2048`。SDK仍 `b4861c5215280c49bffe03b8c203074217dcf995`，lock保持；日常目录 `feat/ui-detail-polish@25260b3` 保持。

短按立即展开，300ms长按轻抬且可继续跟手；任意方向拖出径向区域均可翻牌，并沿原射线离场。持当前视频帧完成展开后自动播放，刊头/编号等改固定画布缩放，以减少首次起播和重复排版与过渡并发。相关10文件94通过/13跳过，Impeller像素另1通过，分析0。+48 release验包/验签通过，与+47内部包同签；Agent未安装，首次展开及手感交用户远程验收，未采集原机性能trace。

[交互、性能边界与包身份](home-card-touch-motion-2026-11-06.md)。

## 2026-11-06：首页切牌静默加载 / +47待远程验收

运行/构建源 `bba10fdb98934cea5e9f27c3062a7ad74d79e43c`，候选分支 `codex/home-card-silent-loading-20261106`；`1.1.0+47` / arm64 `2047`。SDK固定 `b4861c5215280c49bffe03b8c203074217dcf995`，hosted锁保持；日常目录 `feat/ui-detail-polish@25260b3` 保持。

首页下载/待首帧不再显示转圈，保持封面至真实首帧，由同一播放器接上；真实失败重试保留，普通宿主默认提示保持。App相关10文件88通过/13跳过，Impeller像素回归另串行1通过；SDK相关31通过，双方分析0。+47 release验包/验签通过，与+46内部包同签；交用户远程覆盖测试，Agent未安装，实际切牌/首帧观感待反馈。

[实现、检查与包身份](home-card-silent-loading-2026-11-06.md)。

## 2026-11-06：动作专页与接牌连续性 / +46待远程验收

运行/构建源 `21dd048940baef24a4e3d7186163ae626b062fcf`，独立分支 `codex/home-card-editorial-20261106`；`1.1.0+46` / arm64 `2046`。SDK仍 `1c082e9d3e22022f228888fdd1935b1d61371cb9`，lock、shader、媒体与原生代码保持。日常目录 `feat/ui-detail-polish@25260b3` 保持。

按用户两项反馈，移除“左右翻阅”及两侧箭头整个底行和预留；前后牌共用同一Face，标题/视频比例及材质不再在到顶时切换。展开态采用刊头细线、放大单序号、侧栏、强调标题、动作要领和页脚印记的杂志版式，保留原动作分类、方向、剂量和说明内容。

相关10文件87通过/0失败/13跳过（12既有截图项+1需Impeller）；真实shader像素回归另以 --enable-impeller 1通过。fatal-infos分析0，严格锁解析不改lock。未重新跑全量App/SDK。 最终+46 release已构建、验签和资源校验，未由Agent安装，继续交用户远程覆盖测试。Noto字体浅深实际widget渲染已检查，组件逐帧与headless Impeller证据不替代原机滑动/展开观感及帧时长验收。

[版式、连续性与交付](home-card-editorial-2026-11-06.md)。

## 2026-11-06：牌面黑轮廓修复 / +45待远程验收

运行/构建源 `9925e3c58afdea65768875f85ee3a4b60865a6f0`，分支 `codex/home-card-alpha-alignment-20261106`；`1.1.0+45` / arm64 `2045`。SDK仍 `1c082e9d3e22022f228888fdd1935b1d61371cb9`，lock、shader/素材内容及原生代码保持；日常目录 `feat/ui-detail-polish@25260b3` 保持clean。

用户+44截图显示坐姿后撑单膝内倒等前牌人物后缘有错位黑轮廓。+45为前牌姿态Transform设置非空filterQuality：先在局部坐标合成视频RGB/alpha，再将整张牌作为GPU滤镜结果做透视/旋转；保留同一直播Texture、当前帧暂停和展开/收起行为。

常规10文件85通过/0失败/13跳过（12既有截图跳过，1项真实shader像素测试需Impeller）；该像素测试另以 --enable-impeller 单独运行1通过。新增像素和实际layer断言在旧路径先失败，修复后通过；fatal-infos分析0，严格锁解析不改lock。 最终+45已构建、验签和资源校验，未由Agent安装。继续交由用户远程覆盖安装，原机视频取样、文字清晰度和帧时长仍待反馈；本机headless Impeller与合成图案不代替手机GPU/SurfaceProducer验收。

[定位、像素对照与交付](home-card-alpha-alignment-2026-11-06.md)。

## 2026-11-06：动作牌同一视频 / +44待远程验收

运行/构建源 `c0798ecc6a9ef5f91bfa0221cee5bb2c42dfad38`，独立分支 `codex/home-card-live-surface-20261106`；`1.1.0+44` / arm64 `2044`。四个实际SDK包及coach override固定 `1c082e9d3e22022f228888fdd1935b1d61371cb9`；hosted锁、Flutter3.44.7及素材内容保持。日常目录仍 `feat/ui-detail-polish@25260b3`，保持clean。

用户在+43交付后反馈展开/收起仍闪，并提出同一视频元素方案。+44将当前前牌常驻root OverlayPortal：初次准备首帧暂停，展开只改变同一牌面的矩阵/大小并播放，关闭立即暂停当前帧并缩回，compact继续显示该帧；再次展开继续播放。移除App快放回首调用、两面交接、截图捕获及专用弹层路由。

App相关9文件85通过/0失败/12既有截图跳过（牌组34项）；SDK runtime相关29项通过，双方fatal-infos分析0，App严格锁解析通过，lock仅四个Git节点ref变化。未跑全量App/SDK。 最终+44 release已构建、验签及资源校验，尚未由Agent安装；按用户决定交由用户远程安装测试。同一节点/纹理身份的组件回归和浅深色实际widget绘制检查已完成，原生首帧准备与真实过渡观感等待用户反馈，不能记作真机无闪烁通过。

[方案、包身份与验收归属](home-card-live-surface-2026-11-06.md)。

## 2026-11-06：首页动作牌收起 / +43待真机

运行/构建源 `32ac1a76e12894f6aedb8218be0b35a591fd3461`，分支 `codex/home-card-return-fix-20261106`；`1.1.0+43` / arm64 `2043`，四个实际 SDK 包及 coach override 固定 `4b9b685788352415fbfce2d8a2651f7f9d207512`。日常目录保持 `feat/ui-detail-polish@25260b3`；本轮在既有 E 盘隔离副本开发。

关闭展开牌时，先复用当前视频有界快放走完剩余循环、回首暂停，再执行原有缩牌；退场期间保留同一视频表面，避免路由失去 current 后过早切成封面。暂停后关闭也走同一流程，重复关闭合并。

App 相关9文件84通过/0失败/12既有截图跳过（牌组33项）；SDK runtime相关26项通过，双方 fatal-infos 分析0。App严格锁解析通过，lock仅四个Git节点ref变化，hosted版本/摘要/来源保持；未重新跑全量App或全量SDK测试。 最终+43包已构建并完成签名/资源校验。用户随后明确本轮没有本地真机，改由用户远程安装测试；安装状态与视频快放、首帧交付及缩牌真实观感均待用户反馈，组件/fake平台通过不等于原生验收。

[实现、包身份和待验](home-card-return-2026-11-06.md)。

## 2026-11-06：二级转场性能优化 / +41

运行/构建源 `58aa468c2707361e917cea2b75fc4561a23b4473`，独立分支 `codex/navigation-transition-perf-20261106`；`1.1.0+41` / arm64 `2041`。继承+40动作牌，SDK97eb66d、lock、资源与原生配置不变。

将每条顶栏的三层模糊显式裁剪到实际条带，保留固定返回键、三层参数、400ms进入/340ms返回与原曲线。二级路径真机profile暖态对照中，raster超过120Hz阶段预算的帧比例由96.5%降至12.8%；该指标不是实际显示掉帧率。

5个相关测试文件47通过/0失败（新增7项真实paint-clip、浅深/副标题/高对比/多层路由回归），fatal-infos分析0，严格锁解析不改lock；未重新跑全量App测试。 最终+41 release同签名覆盖成功，回读2041/1.1.0，冷启动Status ok/191ms。浅色五路径进退、深色设置/隐私及内容滚过顶栏已检查；已恢复原浅色选择、回到首页。按用户要求锁屏，系统回读keyguard showing=true、inputRestricted=true，电源为Dozing（设备常亮显示状态）；不再操作手机。

[本轮定位、性能对照与交付](navigation-jank-2026-11-06.md)。

## 2026-11-06：首页自由拖牌与视频悬浮卡 / +40

运行/构建源 `ba40e38a783975f17fcd682606e8b5bd092b7b25`，独立分支 `codex/home-action-deck-20261105`；`1.1.0+40` / arm64 `2040`。SDK仍固定97eb66d，lock、资源和原生配置未改。

最终+40同签名覆盖安装成功，回读2040/1.1.0。真机验证任意方向拖动可覆盖上下标题/底栏，纵向及斜纵向释放回位、横向区域切换；展开保留边距，介绍正常，视频默认帧变化、暂停帧相同、继续后帧变化，收起恢复首页。

交互主体3c5ef15完成8文件71通过/0失败/12既有截图跳过；最后仅修竖拖背牌微偏后，最终源牌组整份27/27复核、fatal-infos分析0、严格锁解析通过。其余7文件未重复跑，不声称本轮全量App测试。 详见[交互与验证](home-action-floating-2026-11-06.md)。本轮保存独立候选，main/PR31集成另行处理；此前+38获用户测试通过。

## 2026-11-05：UI r4 全界面补全 / +36 真机包

运行/构建源 `6e247aaa7349b9d5cd8c2e626fe3e4a86faba9e3`，分支 `codex/ui-r4-completion-20261105`；`1.1.0+36` / arm64 split `2036`，SDK仍固定 `97eb66d`，lock、媒体及原生配置未改。

用户要求保留同事已经验收的仿iOS设计，审核补全细节与冗余实现。本轮完成副标题间距、键盘底操作区、路线选择弹层、自测说明骨架、开关/复合卡片语义、动画订阅释放和减少动画下iOS边缘返回；删除无调用的旧筛选/网格。真机查实并修复公共动作训练组导入Coach时旧kit空值导致的启动失败。

严格锁解析和 fatal-infos 分析0；完整70文件首次501通过/1条旧关闭按钮定位器失败/68既有跳过。仅将该测试改为当前关闭胶囊后，相关整份16/16通过；按测试文件和名称合并最新结果为502通过/0未解决失败/68既有跳过，并非第二次完整全量运行。运行代码在全量后未改变。

最终内部release包已同当前开发包证书覆盖安装到小米2602BRT18C；实际回读2036/1.1.0，冷启动Status ok（226ms）。公共两动作组保持且Coach正常进入SDK安全确认；正常字号浅深设置、键盘操作条、详情/自测及弹层按[本轮报告](ui-r4-completion-2026-11-05.md)分别登记。没有真实模型请求或iOS设备结论，旧D-34不改记通过。

PR #32此前已合入SDK候选分支`ebdba778`；本轮补全单独推送保存，main仍`6bdf1e9`，不代办Draft PR #31主线集成。日常目录仍`feat/ui-detail-polish@25260b3`，本轮在既有E盘隔离副本完成，无清理/重置其它工作。

## 2026-11-05：UI r4 / PR #32 合并复审

按用户要求，日常目录 `E:/AII-3D/3D-Hip` 已切换到 `feat/ui-detail-polish`。本轮合并对象是 [PR #32](https://github.com/mhgd3250905/HipLab/pull/32)，目标保持 `codex/sdk-r2-v1-hot-update`；main 仍为 `6bdf1e9`，PR #31 的主线集成另行处理。

原 UI 源 `cb0f063` 上补了一项返回胶囊修复：更多页的内嵌胶囊和后续页面的固定胶囊都在被覆盖期间隐藏，防止更多→设置转场出现双胶囊。新增三条回归在原源码全部失败，修复后全部通过；验证源 `6969425` 严格分析 0、全部66文件465通过/0失败/68既有跳过，详见[本轮审核](ui-r4-pr32-review-2026-11-05.md)。练习主页保留固定头部，其它穿透/固定页面按实际接入记录，不笼统称为每页穿透。

版本保持 `1.1.0+35`、SDK `97eb66d`，依赖和 lock 不变。本轮不出新包、不安装；此前 `97cecb1` 的 +35/2035 release APK 不含本次 UI。PR 作者的远程 Pixel 8 debug/录屏记录与本轮组件回归分别归属，新增补丁未做新真机验收；UI r3 PR #29、D-34、release/1.0 与商店边界不变。

下方“未提交/未 push”等为远程打磨阶段快照；本次保存与合并身份见本轮审核和 GitHub PR #32 回执。

## 2026-11-05：全量 UI 规范扫描（`feat/ui-detail-polish`，未提交）

用户要求按已确认的 iOS 规范扫一遍所有界面。本段替代下方“顶栏改造”段里的未接入清单。

| 对象 | 当前事实 |
|---|---|
| 顶栏 | 所有推入页面已使用 `HipNavPage`，无直接 `HipNavBar`；内容穿透：更多、设置、训练记录、隐私政策、动作详情、套路详情、加动作选择器、自测结果；固定头部：组编辑、安全提示复审、Coach 加载壳。`hipNavInset` 已计入 24pt 过渡段，静止内容不会被渐变遮挡；安全复审正文顶部留 12 |
| 底部操作 | `HipNavPage.bottomBar` 承载库页 LibFooter；动作详情、套路详情、组编辑、加动作、自测结果均已接入 |
| 列表 | 行 17pt/w400、图标 30×30/圆角 7、单行 52 / 双行 60、卡片圆角 10、右侧留白 16；设置与更多页移除分组小标题，组间距 28 |
| 控件 | 原生 `Switch` / `Slider` 已清零；`HipSwitch` 51×31、`HipSegmented(ios:true)` 32 高系统样式、`HipSlider` 4pt 轨道 + 白色滑块；练习页分组与组编辑休息段已切换 |
| 按钮 / 弹窗 | 主按钮 50 高 / 圆角 14 / 17pt w600，次按钮 50 / 14 / 17pt w500；组编辑放弃/删除与练习跳过提示统一为 `showHipConfirmDialog` iOS 卡片 |
| 路由过渡 | 全部 `HipNavPage` 目的页改用 `HipRoute.content`：整页（背景/body/bottomBar/顶栏玻璃/标题/右侧操作）横向滑入，返回反向滑出并露出上一页；**前后两页都有胶囊时**仅返回胶囊固定（`HipNavBackChip` 画在滑动层外，`HipNavBar` 用 `showLeading:false`，被覆盖页隐藏自己的胶囊）；**从首页等无返回键页面进入时** `pinLeading:false`，胶囊随顶栏滑入/滑出；下层 -28% 视差；缓动 `HipMotion.enter/exit`，边缘拖动线性跟手；无双重胶囊、无空背景闪烁 |
| 改动文件 | `hip_app.dart`、`hip_more_page.dart`、`hip_page_kit.dart`（新增 `HipNavBackChip`）、`hip_routes.dart`、`hip_segmented.dart`、`hip_assessment_page.dart`、`library/{drill_detail,group_editor,practice,routine_detail}_page.dart`、`coach/hip_coach_chat_page.dart`；测试 `hip_tactile_budget_test.dart`、`hip_ui_round1_test.dart`、`hip_ui_round2_test.dart`；规范 `docs/ui-design-standard.md` |
| 真机 | 2602BRT18C `QSG6Q8IFDMDELVGQ` 覆盖安装前序 +35 debug（未清数据），已截图更多、设置浅/深、练习分段、套路详情（含新间距）、组编辑、新确认弹窗、加动作选择器、安全复审（含新按钮）；最终版覆盖安装 Pixel 8 `38011FDJH00940`：`nav11.mp4` 2.40s/4.50s 验证更多↔设置（两侧有胶囊，固定且单一），`nav12.mp4` 2.60s/4.60s 验证首页→更多（胶囊随页面滑入/滑出） |
| 验证 | `flutter analyze --no-pub` 0；最终 pinLeading 版全量 `flutter test --no-pub` **462 通过 / 0 失败 / 68 既有跳过**（新增 1 条首页无胶囊用例）；定向 13/13；真机 `nav11/nav12` 中间帧已验证 |
| 未做 | 未提交、未 push、未合 main；自测结果与本地动作详情未单独截图（有测试覆盖）；无 release、未动商店 |

## 2026-11-05：UI 顶栏改造分支 `feat/ui-detail-polish`（+35，上一轮已提交）

用户逐屏确认顶栏与状态栏背景设计（"完美！"），设计已固化为 [UI 设计规范](ui-design-standard.md)。本轮是**开发分支上的真机调试**，不是交付版本。

| 对象 | 当前事实 |
|---|---|
| 分支 / 基线 | `feat/ui-detail-polish`，基线提交 `97cecb1`；本轮 UI 改动与文档已作为一次提交保存在分支上，具体哈希以 `git log` 为准，未 push |
| 版本 | `1.1.0+35`（沿用分支既有版本号，本轮未再递增）；仅 debug 包，无 release 产物 |
| 改动文件 | `lib/hip/ui/hip_page_kit.dart`（HipNavBar/玻璃/胶囊、`kHipNavFade=24`、`hipNavInset`）、`hip_app.dart`、`hip_more_page.dart`、`hip_privacy_page.dart`、`hip_records_page.dart`；新增 `docs/ui-design-standard.md`；`docs/README.md` 索引 |
| 顶栏形制 | 带高 = 状态栏 + 44 行 + 24 过渡；页面背景色渐变（顶 α1 → 60% 处 .86 → 抛物线归零）+ σ34/20/9 三层模糊；返回胶囊 44pt/字形 32，平整磨砂玻璃（浅色填充 `white @ .38`、深色 `white @ .12` + σ12 真实模糊 + 0.75pt 细边，无渐变、无投影） |
| 内容穿透 | `bodyScrollsUnderBar` 已开：更多、设置、训练记录、隐私政策；视口顶到 y=0，页面用 `hipNavInset(context)` 留状态栏 + 44 |
| 未接入 | 动作详情、套路详情、组编辑×2、安全提示、自测结果（仍是旧 `HipNavBar`，无穿透/过渡） |
| 真机 | Pixel 8 `38011FDJH00940` 与 2602BRT18C `QSG6Q8IFDMDELVGQ` 均已覆盖安装 debug +35；最终胶囊版本在小米机多次 `-r` 升级，浅色与深色均已截图，未清数据 |
| 验证 | 最终 `flutter analyze --no-pub` 为 0；受影响测试最近一次 42/42 通过（顶栏几何定稿前），其后曲线与胶囊材质改动未重跑；**全量测试按用户要求暂缓** |
| 未做 | 仅本地提交；未 push、未合 main、未做 release 构建、5 个页面接入、版本递增、深色主题全页检查和商店/手机发布动作 |

下方 2026-11-04 及更早段落保留历史快照，不作为本分支状态。

## 2026-11-04：QA v3 / +34 主线对齐与版本收束

本轮文档收束前，`E:/AII-3D/3D-Hip` 的 main 与 origin/main 已对齐到功能集成点 `2400b344183e1d57636412309899b4a1481966a7`，即 PR #30 合并点。后续本次提交只更新文档，具体文档 HEAD 以 Git 为准。

| 对象 | 当前事实 |
|---|---|
| App / SDK | `1.1.0+34` / arm64 `2034`；四个实际依赖及 coach override 固定 `f7b8a8e4853e9f50fc93888e1768ec1dbc75b588`（v0.7.2 内容）；Flutter 3.44.7 / Dart 3.12.2 |
| AI 接线 | 原 SDK 聊天页的 qaV2 入口使用固定 SDK 问答 v3；App 传 `appAiTags`，不新增问答适配。模型 deepseek-v4.1-flash / max，原安全、保存与开练门禁保留 |
| 标签及资源 | 209 条未审 ai-draft，来源固定 Pose-Hub `5d17c24`，2 条缺标签按目录回退；Coach211、动作库/组选项210、211公共封面、0内置MP4，8条partial不开放 |
| 依赖来源 | 当前 lock 使用 pub.dev；相对上轮 SDK0.6 基线还包含 jni 1.1.0→1.1.2、shared_preferences_android 2.4.28→2.5.4，不能统称“只改 SDK” |
| 自动验证 | 2026-11-04 在 `0f0882ede92b796ba53a03df1097f11232cb2d69`：analyze0，全部66文件461通过/0失败/68既有跳过。该源与2400b34完整树相同，按同树沿用；本轮未重跑 |
| 最新测试包 | +34/2034，运行源0f0882e，47.38MiB arm64 release，实际与+32证书一致；路径、文件SHA256及证书见[版本台账](version-ledger.md)，本轮不重建 |
| 手机 / +33 | 用户确认手机现装+32；+33只有源码版本、从未出包。此为用户报告，本轮未做ADB回读或安装+34 |
| PR 状态 | GitHub回读PR #30已合并；UI r3 PR #29仍OPEN/Draft，head447ca1c，不因问答v3合入而验收或合并该UI候选 |
| 待验边界 | +34旧对话恢复/提示、即时用户气泡、三轮含排计划、杀进程重启续聊待用户验收；没有新SDK实模对话或真机通过结论，旧+31对话不作替代。D-34历史锁屏失败保持 |
| 保留范围 | 完整工作区在收束前为空；原stash `0fa5c25ff66a2aec4770dca6a579a6b57a3ffb70`及候选副本保留；release/1.0本地1f9a172、远端a20721e未动，未回读或操作商店 |

本次仅对齐版本文档、提交和普通push main，不增版、不改锁、不重建或安装。详见[版本规则](version-management.md)、[验证及Preflight](verification.md)和[开发事项](development-roadmap.md)。下方均为各阶段历史快照，不作为当前main或手机状态。

## 2026-11-04：AI 教练修复 +32 候选（历史，验收结果仍待反馈）

构建源 `c327a90e9946edfe7254075deec91edd749b604e`，分支 `codex/sdk-pin-v0.7.0` / [Draft PR #30](https://github.com/mhgd3250905/HipLab/pull/30)，SDK 固定 `3e949ce6ecd695aa954a012f33474942531324ef`（codex/qa-v2-fixes）。`flutter pub get` 成功且锁文件未变；严格 analyze 0，全部 66 个测试文件 461 通过 / 0 失败 / 68 既有条件跳过。

用户随后明确暂无真机，改为打包后远程安装测试。本轮未安装、未卸载、未清数据，也未抓取用户日志；下列 1–4 均不记为实测通过。App/SDK 源码未改，不新增问答适配或绕过。main 保持 4d610f5，release/1.0 不动，不合并、不打 tag、不提交商店。 交付详情见 [sdk-qa-fixes-plus32-2026-11-04.md](sdk-qa-fixes-plus32-2026-11-04.md)。

## 2026-11-04：SDK 0.7.1 QA v2 / +31 候选（历史）

`codex/sdk-pin-v0.7.0` 已接正式SDK `9dd93163`：原SDK聊天页打开qaV2并传App的209条未审AI标签，模型deepseek-v4.1-flash/max；App无问答适配层，原211范围及保存/开练门禁保留。1.1.0+31/2031内部包构建源 `2c13e8a119409c857508c6c3e79dc27241e8e702`。严格analyze0，全部66个test文件461通过/0失败/68既有条件跳过；真实宿主3段9轮18次请求与计划保存通过。

测试APK已备好，同签名、211封面/0MP4，交用户远程安装；本轮未安装，候选不合main、release/商店不动。两条缺标签按目录回退、无替换候选时保留原动作，详细边界见[完整接入与验证](sdk-qa-v0.7.1-validation-2026-11-04.md)。当前main仍4d610f5，UIr3 PR29另行待验，下方main快照保留历史。

## 2026-11-04：SDK 0.6 主线与 UI r3 候选快照（历史）

核对目录 `E:/AII-3D/3D-Hip`。收束前本机 main 与 origin/main 均为 `0737e4e3e34cc7116e03554e977a0d8e65b39267`，完整 tracked/untracked 状态为空。GitHub 回读 PR #26/#27/#28 均已合并；#29 OPEN / Draft。以下旧“未合 main”描述保留为对应日期历史。

| 对象 | 当前事实 |
|---|---|
| App / SDK | `1.1.0+30`，arm64 split `2030`；四个实际依赖及 coach override pin `693cbc02cdf284163409868e117e438515c6a8d8`（ugk_trainer-v0.6.0），无独立 ugk_trainer 依赖 |
| 已入主线 | 共享 Launcher/媒体策略、冷启动读取修复、211 完整动作范围；PR #26 首页主题；PR #27 页面/动作库/混合组/训练记录与每日分钟修复；PR #28 SDK pin/换侧预计余量/中文 strings |
| 当前动作/媒体 | Coach 211，动作库及训练组选项 210（排除自测演示）；211 公共封面，视频按需缓存，0 内置 MP4。8 条 partial 不开放；旧 v0.2.0 ZIP 为历史恢复来源 |
| UI 与语言 | 简约扁平分层玻璃/紧凑控件；正常字号与日常设备范围。UI 固定中文，设置语言只改语音；SDK 页面边界保持 |
| 主线验证 | 2026-11-03 源 `3a449c33be01dbef35c635a346f35eb26be1154a`：严格 analyze 0，64 文件分批 454 通过 / 0 失败 / 68 条件跳过，重点 24 通过；到本次收束前 HEAD 仅 6 份文档变化，沿用而非本轮重跑 |
| 主线内部包 | `3a449c3` 的 +30/2030，47.64 MiB，同测试签名、0 MP4；已构建，记录中未安装，详见[原回执](sdk-pin-v0.6.0-validation-2026-11-03.md) |
| UI r3 候选 | `feat/ui-r2-pages@447ca1ca3471aa6504e43179cdedeaa1fb8120d0`，测试/构建源 `00feee16ea049e636f3c43f900ce7a5902d10363`；四个 UI 提交与一份文档提交，尚未入 main；434 通过 / 68 条件跳过仅属于该候选 |
| 最后已核验安装 | 2026-11-02，PR #26 的 `a7e371eb71df29af3929ac4a98098371c3c8928f` +30/2030 同签名覆盖安装；快速检查旧训练组/6天汇总/自测10/12/设置保持。11月3日两个新内部包未有安装确认 |
| 待用户反馈 | UI r3 混合组完整播放/顺序/所选休息/结束记录；旧组与重启保存、自测/设置/筛选、正常字号浅色层级、聊天唯一返回键。无新真机结论；D-34 历史锁屏失败仍保留 |
| 工作区保留 | 原日常 WIP 接力时已存为 stash `0fa5c25ff66a2aec4770dca6a579a6b57a3ffb70`；本轮未恢复、清理或修改 stash/其他工作副本 |
| 发布边界 | 远端 release/1.0 回读 `a20721e25044f87399ec633c93fb04d6d55c6ff4`，本轮不改；未回读商店状态，无发布/审核通过新结论 |

UI r3 的浅色去投影、圆角/细边/meta、玻璃导航圆钮、统一动作行、组编辑单面板、选择/筛选与自测布局优化见 [Draft PR #29](https://github.com/mhgd3250905/HipLab/pull/29) 及[候选验证报告](https://github.com/mhgd3250905/HipLab/blob/447ca1ca3471aa6504e43179cdedeaa1fb8120d0/docs/ui-r2-r3-validation-2026-11-03.md)。待用户真机确认后才按既有条件授权推进 Ready/合并，本轮只整理文档。

包身份详见[版本台账](version-ledger.md)，验证适用性见[验证台账](verification.md)，剩余事项见[开发事项](development-roadmap.md)。下方无新日期的旧表也仅是历史现场。

## 2026-11-03：SDK v0.6.0 候选测试与内部包完成

`codex/sdk-pin-v0.6.0` / Draft PR #28 的测试与构建源 `3a449c3`，SDK pin `693cbc02`。严格 analyze 0；全量 64 文件分 16 批共 454 通过 / 0 失败 / 68 既有条件跳过，四个重点文件 24 通过，无代码修复。1.1.0+30/2030 arm64 内部包 47.64 MiB、同测试签名、0 MP4，文件名含 3a449c3，未安装。App 界面固定中文，语音语言切换不能验收动作库界面切换；聊天单返回键仅代码核对，真机由用户远程安装抽查。不合 main、不动 release/商店，日常 WIP 未操作。[完整回执](sdk-pin-v0.6.0-validation-2026-11-03.md)。以下保留历史阶段。

## 2026-11-03：PR #27 r2候选验证完成，待用户远程安装

保留已确认的r2结构，仅修每日训练分钟重复取整，补混合组实际SDK阶段/组间休息/完成保存回归。验证构建源`f4714c6`；analyze0，64文件按4文件/批全部通过，含新增回归去重454通过/0失败/68条件跳过（opt-in截图/导出）。47.64MiB release候选保持+30/2030、同测试签名/0MP4，交用户远程安装验混合组和旧数据，本轮未安装。只正常字体，不合main、不升版、不动release/商店。[交付与APK身份](ui-r2-pages-integration-2026-11-03.md)。以下为历史阶段。

## 2026-11-02：PR #26 首页主题合入，+30 已保留数据安装

用户确认设计并授权合并，PR26在同步最新main后验证通过，合并点`a201fd5`；1.1.0+30/2030构建源`a7e371e`，47.70MiB release APK已同签名覆盖安装。analyze0、全量444通过/0失败/13条件跳过，额外截图4通过。正常字号浅深快速走查无新增显示问题，6天训练汇总、自测10/12、2组及主要设置保持；详细使用交用户。SDK仍d4502f3/211动作，日常40个WIP未变，release/tag/商店不动。[交付、脚本删除清单与验收边界](home-calm-r1-2026-11-02.md)。下方为历史阶段。

## 2026-11-02：211 全动作 +29 完成，APK 待用户安装

用户17:14改为SDK当前完整211动作，浏览/Coach共用同一集合，8partial不开、不改SDK。分支codex/full-action-scope，测试/构建源`5072cbb291fe099fbbbd8e673a326e47e21808e8`，SDK仍完整pin d4502f3。公共元数据、单练/保存恢复/SDK执行和新动作封面已接通，自测与原课程保持。严格analyze0、全量437通过/1既有条件跳过、Python25/25；+29/2029 arm64 release APK49,954,831 bytes（47.64MiB），211封面、0 MP4。日常40个WIP及生成依赖配置逐字节恢复；只推本分支，不合main、不打tag、不动release/托管/Flare/商店。未安装，真机/视觉交用户自测。[报告与路径](full-action-scope-completion-2026-11-02.md)。下方219范围等待记录为已替代历史。

## 2026-11-02：219 浏览已获同意，共享动作库仍需 SDK 支持

用户明确219浏览/211规划、8partial只浏览后继续核查；SDK d4502f3的Library列表、facets筛选和详情均硬性排除partial，无公开浏览开关。此前SF219授权等同219实际可浏览的表述已更正。已补173张封面，总219张逐项哈希通过；scope/profile/运行/存储尚未改，版本仍+28，未构建+29。按SDK问题先报告边界停止，仅推送准备资源与记录，日常WIP未动。[具体SDK位置与后续条件](full-action-scope-2026-11-02.md#用户明确-219-浏览--211-规划后的-sdk-界面阻塞)。

## 2026-11-02：+28 已合 main；全动作范围预检受阻

用户确认 +28 真机测试通过并批准合入。main 以 ff-only 从 `0f507a3` 到 `d0c28c59976e32d58e4999b524bb40c60ee3672a`，普通 push 后远端一致；未重建 APK。随后从新 main 建立 `codex/full-action-scope`，发现固定 SDK 219 个动作中8条缺训练元数据，依“若 SDK 缺，停下报告”停止。SF同样为219可浏览/211可组计划，媒体缺失0；本轮未改动作范围、版本或自测，未出+29。仅预检文档推送分支，日常目录原40个WIP保持不动。[详细缺项与证据](full-action-scope-2026-11-02.md)。以下为历史快照。

## 2026-11-02：共享体验 +28 候选通过门禁，APK 待用户安装

用户16:19明确超大字号不在支持范围，授权删除2倍字号用例，先前SDK溢出不再阻塞。`codex/sdk-shared-experience`验证/构建源`2d3070d375b546bad0dcc453b548ecb0ace818d9`，SDK仍完整固定d4502f35b1503d41cd782aa7fb3780c7f6591ad0。App启动bytes读取修复保持，本轮仅适配测试的真实图片解码、Launcher可操作门禁、纵向viewport和SDK图标归属；删除11条2倍字号用例，未新增skip。严格analyze0、全量428通过/1既有条件跳过。

1.1.0+28/versionCode2028 release arm64 APK为45508800 bytes（43.40MiB），包内0 MP4、46公共海报，签名/CRC/身份和连续测试证书核验通过。原上传签名包与同负载设备测试包均保存，路径、SHA和删除清单见[本轮交付](sdk-shared-experience-completion-2026-11-02.md)。原日常WIP单独保存，按字节哈希恢复；用户自测安装和视觉/真实操作，本轮未执行ADB。只普通推送候选分支，不合main、不打tag、不动release、托管或Flare、不提交商店。下方暂停记录均保留历史。

## 2026-11-02：启动根因已修，SDK 动作库布局问题待确认

继续`codex/sdk-shared-experience@1b2399e`，启动修复源`1f76e745da30133b8b38986d27c2f1b9e5df7791`。临时逐步日志确认`HipApp._load`没有等待网络或抛错，而是276253字节的内置coach catalog经`loadString`触发isolate，主界面断言先于其完成。App改用bytes/UTF-8解码，仍由SDK`Catalog.fromJson`校验，删除测试预热；最小失败用例与新增断网冷启动各1通过，严格analyze0。

全量执行到385通过/19失败时停止：单条诊断确认SDK`training_library_browser.dart:221`在2倍字号/320px键盘inset下溢出20px（可用高度301px）。极大字号原不列日常验收门槛，但本任务要求全量通过，不能把失败记为通过或在App绕过。其余入场/图片解码/滚动辅助失配尚未逐条复验。保持SDK d4502f3、1.1.0+28/2028，不重建APK；手机、main、release、托管与Flare均未操作。详见[诊断报告](sdk-shared-experience-2026-11-02.md#启动定位更新2026-11-02)。下方前轮未定位记录保留历史。

## 2026-11-02：共享体验接线已保存，门禁未通过

`codex/sdk-shared-experience` 从 main `0f507a3` 开发，四个实际 SDK 包及 coach override 均固定 `d4502f35b1503d41cd782aa7fb3780c7f6591ad0`。Launcher、公用媒体、SDK动作库/详情/自测接线及94内置MP4移除已实现，版本1.1.0+28。严格analyze0、Python25/25；Flutter首轮310通过/128失败/1条件跳过，第二轮同类加载失败，234通过/116失败时按用户“两次卡住停止”结束。首次构建44.45MiB、0 MP4仅诊断用，早于两处入口修复，不是最终交付包。完整[结果和后续定位点](sdk-shared-experience-2026-11-02.md)。main/release不合不动，不tag、不商店、不操作托管或Flare；手机未操作，原日常WIP保留。

## 2026-11-02：第 5 批 SDK 对话模块候选

**主线集成确认（2026-11-02）：** 用户已批准第 5 批合入 main。本机 main 从 `1083b49` 快进至 `origin/main@1b94fc3`，再以 `--no-ff` 合入固定候选 `c8cf82f`，合并点 `9054932a982a9b41eaf540a4281af1e069c2f456`。合并后严格analyze为0问题、全量446通过/1条件跳过，与候选一致。下方候选状态为批准前快照；10月27日 iOS 章节原文保留。合并复核见[验证台账](verification.md)。release/1.0仍为`1f9a172`，既有APK不重打，不tag、不提交商店。

候选分支已普通推送，首次远端回读 `6c30bb9` 与本机一致；后续仅补推送回执。手机未安装，main 未合入，release 未操作。

`codex/coach-chat-sdk` 基于本机 main `1083b49` 接入 SDK `7d9be56a6c02b7a28e3d5d5cd9f6c3f1a23ac723`（256KB/50轮）；运行源 `60d3c37`。App 仅提供 profile、45 动作配置和宿主端口，旧对话页面/服务/回退/映射已删除。旧会话导入和完整计划保存恢复已有回归；Flutter446通过/1条件跳过、Python25/25、四段真实模型与严格 analyze 通过。1.1.0+27同签名Worker网关APK已备好、静态验包通过，完整身份见[一页报告](coach-chat-sdk-2026-11-02.md)及[版本台账](version-ledger.md)。用户已拔掉手机，由用户安装并验收视觉/真实操作，本轮未安装、不做 ADB。只推候选分支，不合 main、不动 release、不打 tag、不上传商店；原日常目录 WIP 和旧 v2 分支保留。以下均为历史记录。

## 2026-10-27：iOS 拒审后已向 Apple 回复

HipLab `com.ugk.hipinterlude` / 1.0.0 (20) 被以 4.3 和 4.2.6 相关问题拒绝；用户确认自主开发、同产品旧记录及仅推进当前记录，并授权对外答复。2026-10-27 约 08:59 已发送 Apple 要求的九项说明，消息列表回读为 2 条；当前仍显示被拒绝/问题未解决，等待 Apple 后续意见，**未重新提交或上传新包**。详细事实与证据范围见 [iOS 拒审记录](release-1.0/ios/review-2026-10-27.md)。

## 2026-10-24：Controller 已获批准并合入 main

开哥明确同意固定候选 `448f1096a96746a235913a58a172826431b3ec13` 后，main从64daf6a快进到448f109并普通推送，远端回读一致。coach0.5.0/trainer0.2.3@d7e0b8f、UI0.1.1@3302d62保持；分析0、全量454通过/1条件跳过、专项44通过沿用已验候选。后续回执仅文档，不重建/安装或重复真机。release/1.0仍8880c71，原目录31项WIP保留。下方待审文字保留批准前状态。[集成回执](sdk-conversation-controller-2026-10-24.md#主线集成回执)。

## 2026-10-24：对话 controller 候选，待本轮同意

在 main64daf6a 上建立 `codex/coach-conversation-050-20261024`，复用现有E盘干净工作副本；原目录未提交改动保留。coach0.5.0/trainer0.2.3固定d7e0b8f，UI0.1.1@3302d62保持。自有会话、问题与取消/历史状态代码已删除，SDK controller接管，App门禁/映射/开练和无Key隐藏保持。严格锁文件解析成功，分析0、全量454通过/1条件跳过、AI专项44通过，候选已完成待审；本轮不需真机，无新包/安装，版本仍1.1.0+21。main64daf6a和release/1.0 8880c71保持，合入与推送main等待开哥本轮同意。[本轮记录](sdk-conversation-controller-2026-10-24.md)。

## 2026-10-24：SDK 修复 tag 改锁

用户已确认三个新tag并授权直接集成；检查全部通过后，已快进合入并普通推送main，功能集成点88d8802，远端回读一致。后续仅文档回执，不改变已验代码。候选5c4d32e已改锁coach0.4.2 / trainer0.2.2 / coach_ui0.1.1（均3302d62）；App源码、版本1.1.0+21及其余hosted依赖未改。分析0、窄屏专项13通过，全量451通过/1条件跳过。无源码适配，按用户要求不重复真机；手机仍为原429eaf5已验包，不能记作3302d62新安装。release/1.0不动。[本轮记录](sdk-tag-patch-2026-10-24.md)。

## 2026-10-24：SDK 共用界面开发分支

从最新 origin/main 8880c71 建立 `codex/sdk-shared-ui-20261024`，开发版本 1.1.0+21，采用 coach0.4.1 / trainer0.2.1 / coach_ui0.1.0 正式 tags。聊天呈现交给 SDK、同一 Agent 多轮澄清、无 Key 隐藏全部 AI 入口；release/1.0 不动。分析0、完整测试集合451通过/1跳过、Android release编译及真机M自然4/4/保存/服务通知释放通过，原数据保持；用户已确认语音正常。当前等待开哥同意，未合 main。用户已授权使用当前真机，模拟器已关闭。[接入记录](sdk-shared-ui-2026-10-24.md)。

## 2026-10-24 16:05：iOS 1.0 已正式提交 App Review

复用 Hip Interlude（`com.ugk.hipinterlude`），**1.0.0 (20)** 已正式送审，Apple 回执与服务端状态 **WAITING_FOR_REVIEW（等待审核）**，提交 ID `5f1196c4-3a44-4105-9833-4175e0fca7c5`；保留手动发布，尚未公开发布。中英文商店资料、三尺寸各 6 张原生截图、无登录审核备注、隐私“未收集数据”及公开政策/支持链接均已完成。免费下载，供应保留中国大陆；Mac / Vision 兼容分发关闭。旧草稿 4 张失效 iPad 截图移除后通过提交校验。

编译源仍 e7ac083，上传 IPA SHA256 e2203298…，未重建；既有 442 过/1 条件跳、analyze0、验签及 TestFlight 安装结果保持。用户主动暂缓声音/耳机和完整锁屏专项，不改写为通过。此阶段只改发布文档及已授权外部资料，不改 Android、业务逻辑、SDK、依赖或版本。[完整回执和证据范围](release-1.0/ios/README.md)。

## 2026-10-24 13:09：1.0 Alpha 已送审

用户追加授权后，已通过 Playwright MCP 上传既有1.0.0+20 AAB、保存前台服务与中英商店资料，并提交5项更改；提交ID **2**，Google后台状态 **审核中**。视频已[非公开列出](https://youtube.com/shorts/GRzBK2GvXRU)，[隐私政策](https://mhgd3250905.github.io/HipLab/)已更新生效，应用内容无待注意声明。正式版权限仍需12名真实测试者连续14天，本轮0人，用户选择稍后组织。当前不是Production已发布或审核通过。App编译源4b56b82、SDK d193a70、版本和AAB SHA保持；原液态玻璃WIP未改。[完整回执](play-store-release-2026-10-24.md)。

**主线集成确认（2026-10-24）：** release/1.0 的上架修复及验证文档已按用户授权快进合回并普通推送 main，集成节点 `30d24f7a1cd179d50e27af7fc452d0769e1538ac`，两条远端分支回读一致。后续本回执仅改文档；AAB 编译源仍为4b56b82、版本1.0.0+20和制品SHA均保持，不重建。后续功能从main开发，release分支仅审核修复。

## 2026-10-24：1.0 基础版上架候选

从远端 main e456d2a 建立 `release/1.0`，上架修复源 `4b56b827cf635e05ac55281bc37e7bd9dff7fa09` 已推送。共用版本 **1.0.0+20**，包名 com.ugk.hiplab；SDK 固定 d193a70。按用户最新决定保留 AI 入口，不传 Key，无 Key 本地预设回落，不初始化 AI 安装 UUID/远端目录。上传证书沿用8f8c114e…，已做F盘受限备份；原液态玻璃候选和未提交改动保留。AAB及校验身份在非C盘交付目录；本轮 analyze0、440通过/1条件跳过、签名/清单/API36/16KB静态检查通过。用户报告现有App测试通过，本轮原生模拟器另验，不将旧D-34改成通过。Play后台完全由开哥操作。详见[本轮交付](release-1.0/README.md)。以下为历史状态。

**2026-10-21 10:47：本轮复核记录已获准合入并推送 main。** 用户明确“推进合并”后，main 从 cb7ae4f 快进到 `354d0f12be52109ebeca5a02969cc478ba94b492`，普通 push 成功，`git ls-remote` 回读一致。集成内容仅为六份复核文档，App 运行代码/依赖/版本和已验证来源不变；后续只补本次合并回执。440 项与 Web 核心验证保持通过，真机耳机暂缓、D-34 锁屏失败保留。下方接力复核中的“未合 main”是合并前快照。

**2026-10-21 接力后复核：** 新开 `codex/verify-ugk-trainer-20261021` 核对重复交接，现有训练包接入符合要求。SDK main 09a392b 与固定 d193a70 的训练包 tree 完全相同，继续固定 d193a70；本轮没有运行代码、依赖或版本变化。analyze 0、全量 440/440（含时间线导出），Web 自测/暂停恢复/自然完成/再练/疼痛/反馈/刷新保存核心路径通过，按用户开发阶段要求就此收束。用户明确目前无真机，耳机锁屏暂缓；D-34 历史失败保持。证据见[验证台账](verification.md#2026-10-21-训练包接力复核)与[逐项复核](ugk-trainer-adoption-2026-10-20.md#2026-10-21-接力复核本机检查真机暂缓)。本轮记录留审阅分支，未合入或推送 main；仅编译临时 Web 预览，没有新原生构建或安装。

**已获同意，两个main均已合入并推送。** 2026-10-21用户明确“合并并推送，保留锁屏已知问题”；SDK main为d193a70（PR #2已MERGED，00:39:10），HipLab主线集成点691ace2（00:39:31）。已安装包保持0.3.9+17/79c172d、21原记录/4组/UUID保持；锁屏冻结仍是已知失败，由用户后测，不重建/重测、不改手机省电设置、不上传商店。[合并与边界](android-lockscreen-fix-2026-10-21.md#主线合并确认2026-10-21)。

以下按日期保留的候选、安装与失败段落均为历史快照，其中“当前”“未合main”“待解锁”描述当时现场；当前交付与授权以页首最新结论及对应台账为准。

**00:08失败阶段快照：0.3.9+16锁屏仍失败。** 00:07:47.193 Greeze冻结（关屏5分25.7秒），服务和started/mutedState:none音轨仍在、训练锁DISABLED；系统媒体会话栈为0。不能把正常音量修正记为锁屏通过。当前安全锁屏，待用户回来解锁后正常结束本轮；SDK正在补真实媒体会话与释放，main未合。[完整现场](android-lockscreen-fix-2026-10-21.md)。

**00:02安装快照：0.3.9+16 / 38bce47，开始锁屏复测。** 固定SDK8fb0aac/trainer0.1.3，Android音轨已为started/mutedState:none，用户确认口令继续。App439过/1跳、analyze0，训练包119/119及analyze0；备份并保留数据安装，20记录/4组/UUID保持。+13/+15失败历史不改，两个main未合。[最新证据](android-lockscreen-fix-2026-10-21.md)。

**上一轮安装0.3.9+15 / f8f0ec8，AI通过、整节锁屏失败。** 固定SDK8ef37a9（coach0.1.3/trainer0.1.2），夹具ab963d7；App439过/1条件跳、analyze0，SDK168/118及两包analyze0。保留数据覆盖安装与UUID冷启动通过，手机AI36.595秒首轮生成8动作并保存第4组。23:50:21.914 Greeze再次冻结并禁用训练锁，亮屏后声音恢复。23:53用户正常结束失败课程，结果528秒、6/8、full=false、endedEarly=true，记录19→20，4组保持，TrainingSessionService已退出。main未合，待SDK修复与整节复验，不把提前结束释放算作锁屏通过。[新中转与失败证据](ai-relay-migration-2026-10-20.md)。

**上一轮修复候选：0.3.8+14 已保留数据覆盖安装。** App源f702164，固定SDK7348f0c/trainer0.1.2；SDK118/118、analyze0，Android编译及签名/CRC/876资产/单服务检查通过。升级前9882字节偏好备份，安装后逐字节一致，19条记录/3组/3个完成日保留。Android间隙静音保活与终态释放已有回归；新包App analyze0、全量429过/1条件跳（4分33秒）。用户明确改用扬声器复测，随后因需使用其他App要求稍等，课程未启动，待用户通知；尚未接受新原生结果，main未合。

**2026-10-20 分支真机验收未通过：** `codex/adopt-ugk-trainer` / `7dd40b0` / `0.3.8+13` 已保留数据覆盖安装，固定 SDK `7a84dc0` / ugk_trainer 0.1.1。App analyze0、429pass/1条件skip，SDK111pass；签名连续、876资产及单一包内服务通过。用户锁屏后出现无声、解锁恢复；系统日志确认小米 Greeze 在语音间隙冻结 UID 并禁用唤醒锁。首轮系统实际为扬声器路由，不能记耳机通过。正在 SDK 分支修复，未合 main；只有重新验收通过并获开哥本轮最终同意才合并。[接入与现场记录](ugk-trainer-adoption-2026-10-20.md)。

**2026-10-20 早间主线构建快照（历史）：0.3.7+12 Android测试包已生成，带AI配置，来源55d99b3，签名连续、资源/包校验通过；该阶段未安装、未发布。** main仅递增共用版本，业务内容保持已验PR25；晚间本轮实际已观察手机0.3.7+12并覆盖安装0.3.8+13，当前安装见下表。[早间测试包](android-test-build-0.3.7-2026-10-20.md)。

**2026-10-20 早间主线快照（历史）：** 开哥明确授权后，PR25来源8c985c4及审核文档ce7ab74已合入并推送main，GitHub于11:24:56确认MERGED；SDK0.1.2，原5P2闭环，414过/1条件skip、analyze/Android构建/API通过。此次以已完成的代码和本机验证推进合并，真机未验不改记通过。没有安装/发布，手机仍为10月19日最后已验包；[合并记录](pr25-reaudit-2026-10-20.md#主线合并确认2026-10-20)。

以下表格核对日期：2026-10-21，北京时间，保留为历史快照；当前事实见页首。此页维护当前事实；过程见[开发日志](development-log.md)，检查范围见[验证台账](verification.md)。

## App 与设备（2026-10-21 历史快照）

| 项目 | 当前状态 |
|---|---|
| 产品 / 包名 | 开胯训练助手 HipLab / `com.ugk.hiplab` |
| 共用 App 版本 | 当前main `pubspec.yaml`：**0.3.9+17**；已获准集成，维护规则见[版本管理说明](version-management.md) |
| Android 已安装版本 | **0.3.9+17 / debug arm64 / 79c172d**，SDKd193a70；17637字节偏好备份后install-r，启动后逐字节一致，21记录/4组/UUID在安装时保持；锁屏失败交用户后测，测试进程已停止 |
| 合并前已验基线包（历史） | **0.3.6+11 debug**，源 `6dd16eda246657d1de8ddf9e92b8e91d992c3a80`；150,903,412bytes，已保留数据安装 |
| 本轮交付运行源码 | 运行源79c172d / SDKd193a70，已构建并安装0.3.9+17；HipLab主线集成点691ace2、SDK主线d193a70。锁屏冻结保留、用户后测；未发布商店 |
| 正式 Android 图标 | 已选 B 站姿开髋，青玉绿/石墨底；普通、圆形、自适应及单色资源，已查看手机桌面确认彩色图标 |
| 历史用户验收（本轮见下） | 2026-10-17，0.1.2+3 更新测试通过；2026-10-18，用户已验收 0.3.1+6 单屏自测 UI。此验收不覆盖后来 CSS 修复的原生首帧 |
| 验证设备 | 2026-10-20已核验2602BRT18C / Android16 / API36，物理密度520/font_scale1.0；本轮未改设备设置，WebView版本未重新取证 |
| 产品范围 | 中文；基础训练离线、可配置AI生成及预设回落。共享训练包、App业务插槽、SessionResult保存、新AI中转/App Key/持久UUID均已合main；手机AI生成保存已验。锁屏冻结已知，iOS未验 |
| 动作素材 | 当前冻结 Pose-Hub v0.2.0：46 条 1080 视频 / 46 张 540 封面，ID 和文件名保持；自有 supine-cross-demo 与20张 still 保留 |
| 自测素材 | 既有 20 张自测 still 保留（含 #8 修订），不在 v0.2.0 ZIP / lock；不重新渲染 |
| 当前运行验证 | 精确来源见验证台账：38bce47全量439过/1条件跳及原语音时序保留；79c172d按新接口范围验证，+17 analyze0/保活专项8过、原生构建与保留数据安装通过。锁屏冻结未通过；用户明确后测并同意保留问题合入main，未重复已过测试 |
| main基线运行验证（历史） | 组合analyze0、191pass/1条件skip，gallery2pass；两项P2首轮修复与当前Android复查通过。完整课程/ducking/低端帧时/强光/新结果页/iPhone仍待验；[证据](pr17-pr18-fixes-and-merge-2026-10-18.md) |

当前素材按仓库冻结 lock / manifest 取用 v0.2.0。同步：dry-run 92项计划；首次92 copied；check 92 matched /0 drift；重复同步0 copied；元数据：本机92文件大小/SHA全匹配；46视频H264/yuv420p/1080²/30fps/无音轨，11220帧；完整CPU解码通过；46封面均540²JPEG；保护文件：hip-supine-cross-demo.mp4/.jpg +20张自测still，共22文件SHA保持。该冻结ZIP仅深色；当前main/App包已含PR #20的47套light视频/封面及20张浅色自测图；旧批次QA和历史验收保留，不能作为本轮全量真机结论。

## Git 与主线集成（2026-10-21 历史快照）

用户明确同意“合并并推送，保留锁屏已知问题”后，SDK main从9407bf3快进到d193a70并推送，PR #2于00:39:10确认MERGED；HipLab main从99fcc83快进到691ace2并于00:39:31推送。两棵集成树均与已批准来源逐字一致；后续只补文档，不重建/重装、不重复测试。两个本机日常目录均已回main，原开发分支保留，旧Playwright未跟踪目录未动。

**`mhgd3250905/HipLab` 是 HipLab App 主仓库，`main` 是后续开发基线。** 接手成果通过 #2、#1 合入 main，本机 main 跟踪 origin/main。图标版本 0.1.2+3 的代码提交为 `4cf5ca7`，通过 [PR #5](https://github.com/mhgd3250905/HipLab/pull/5) 集成；业务逻辑和视频资源保持，安装状态独立记录。

| 对象 | 核对结果（逐项日期另列，旧轮保留历史） |
|---|---|
| HipLab `main` | 2026-10-21 00:39:31快进并普通推送691ace2，含共享训练包及新AI入口；用户明确同意保留锁屏已知问题，后续仅补合并文档。此前PR25及#22/#24等历史保持 |
| [HipLab #7](https://github.com/mhgd3250905/HipLab/pull/7) | MERGED，merge `ba591bf`；并合入 Android 首轮验证修复 |
| [HipLab #8](https://github.com/mhgd3250905/HipLab/pull/8) | MERGED，merge `5bb43f0`；保留修订媒体与配套评分说明 |
| [HipLab #9](https://github.com/mhgd3250905/HipLab/pull/9) | MERGED，merge `61979d8`；保留 iOS 配置及共享音视频安全处理 |
| [HipLab #10](https://github.com/mhgd3250905/HipLab/pull/10) | MERGED，GitHub merge `60a683c`；本地 rebase 内容先由 `18a084b` 集成，再保留原 PR 祖先。隐私政策、复制链接测试及送审历史均保留 |
| [HipLab #1](https://github.com/mhgd3250905/HipLab/pull/1) | MERGED，`feat/initial-migration` → `main`，2026-10-17 13:59:40，merge `656ee28` |
| [HipLab #2](https://github.com/mhgd3250905/HipLab/pull/2) | MERGED，`codex/project-takeover` → `feat/initial-migration`，2026-10-17 13:59:14，merge `e52b3c2` |
| [HipLab #5](https://github.com/mhgd3250905/HipLab/pull/5) | 0.1.2+3 站姿开髋图标与安卓实机交付；已安装代码 `4cf5ca7`，具体合并 SHA 回读 GitHub |
| [3D-Body #119](https://github.com/mhgd3250905/3D-Body/pull/119) | 已合并，2026-10-17 10:29，merge `ae81d96f271a18129abbf6afc7064cfd9dd1d8c3` |
| [3D-Body #120](https://github.com/mhgd3250905/3D-Body/pull/120) | OPEN / draft，制作工具与修订规格 → `master`，源 `f8b5138` |

四个 PR 均已由 GitHub 回读确认 MERGED，合并时间为 2026-10-18 **01:01:06 北京时间**（UTC 2026-10-17T17:01:06Z）；推送与手机安装分别记录。

本地原先只抓取 `feat/initial-migration`，现已改为抓取所有远端分支。合并前后核验源 SHA、目标 SHA 和完整文件树，main 集成结果与已审核版本一致；原接手分支保留。细节见[主线集成审核](mainline-integration-2026-10-17.md)，日常更新见[工作流](development-workflow.md)。PR 状态是上述日期快照，操作前回读 GitHub。

## 本机环境和素材位置（历史快照，当前工具入口见工作流）

| 位置 | 用途 |
|---|---|
| `E:\AII-3D\3D-Hip` | Flutter App、内容源、交付视频、开发台账 |
| `E:\AII-3D\3D-Body` | 既有源工程与输出，原工作区未提交文件未动 |
| `E:\AII-3D\3D-Body-worktrees\hiplab-hd-20261017` | 独立制作副本，`codex/hiplab-hd-20261017`，工具代码 `f8b5138fb377ec8cda464cfb08186fd696ca7921` |
| `E:\AII-3D\3D-Body\output\hiplab-delivery-20261017\selected-masters-46.json` | 最终 46 项母版选版清单 |
| `E:\AII-3D\3D-Body\output\hiplab-android-20261017-v2` | 历史 Android 派生片与 SHA，保留追溯；日常素材已改用 Pose-Hub |

两端按用户交接统一 Flutter **3.44.7 stable / Dart 3.12.2**。本轮显式对齐该 SDK 的 13 项传递依赖与 lock 的 Dart 下限（原 #7 lock 要求 Dart 3.13），已通过分析、测试和构建；不是使用 3.47.7 或继续保留不兼容的 lock。Android SDK 36、JBR 17。

路径：Flutter `E:\flutter`，Android SDK `E:\Android\SDK`，ADB `E:\Android\SDK\platform-tools\adb.exe`，FFmpeg `D:\ffmpeg-master-latest-win64-gpl\bin`。实际渲染为 **RTX 4080 Laptop GPU 12 GB / ANGLE D3D11**。绿幕、透明帧和大批次输出位于本机忽略目录，未由 Git 备份；制作副本和输出仍需保留。

## 第一轮修改历史（2026-10-17，原分支 `feat/polish-round1`）

用户 14 条问题中，本分支完成 1（全 App 媒体圆角框）、2（自测首页重排）、3（视频首帧占位不闪）、4（「托马斯测试」改「屈髋肌测试」+ 大字体不重叠）、5（分侧项明确「现在测右边」、防重复点击）、7（标题并入顶栏）、9（无分侧动作不留空行；脚部渲染另修）、11（引导页专属主视觉 A 套）、12（统一过渡动效与预加载）、13（中英语音播报，edge-tts Xiaoxiao / Jenny 预生成 244+244 条）、14（浅色/深色/跟随系统）及 D-01 紧侧加练。问题 6、8、10 与 9 的脚部朝向属于媒体重做，在 `fix/motion-media` 分支。此为 PR 原阶段记录；之后已在本轮逐次构建、覆盖安装并抽查，完整跟练与音乐 ducking 仍待补测，见下节集成记录。

## iOS 版本历史（2026-10-17，原分支 `feat/ios`）

`feat/ios` 从 `feat/polish-round1`（#7，tag `round1-app-v1` → `44db1fe`）切出，合入 `fix/motion-media`（#8，tag `round1-media-v1` → `0d07587`，无冲突，`hip-content.json` 重新生成无差异），因此包含第一轮全部成果。iOS 里程碑 tag：`ios-v0.1-config`（工程身份）、`ios-v0.2-icon-launch`（图标与启动页）、`ios-v0.3-audio`（音频会话与中断）、`ios-v0.4-video`（WKWebView 示范）、`ios-v0.5-safearea`（安全区截图自查）、`ios-v0.6-docs`（说明与台账）。

Bundle ID `com.ugk.hiplab`、iOS 15.0、仅 iPhone 竖屏、中英显示名、SwiftPM（无 Podfile），站姿开髋 AppIcon、跟随系统的启动页，playback + 按句 duckOthers、中断自动暂停，WKWebView 示范锁屏回来继续。只做了静态检查与 iOS 目标平台 widget 测试，**未在 Mac/Xcode 构建，未上真机**；Mac 步骤与真机确认清单见 [iOS 运行与上架说明](ios-setup-and-release.md)。

## 第一轮集成与送审历史（2026-10-18）

用户已明确授权 Windows 主干线审核集成贡献 PR，后续验证后直接提交和推送 main，无需另开 PR；禁止 force push。原目录 `E:\AII-3D\3D-Hip` 已回到 main，`963db04` 完成 Pose-Hub 接入，随后 `9ef59a1` 修复视频 CSS 双重淡入；两者与四个 PR 已推送 main，GitHub 已确认四 PR 合并。手机仍为 `963db04` 初步 APK，最终修复包只完成构建，手机拔出后没有再次 ADB 安装；手机安装与远端合并分别登记。原有 `.playwright-mcp/` 保持不动。

Play Alpha **0.2.0+4 / Submission ID 1** 于 2026-10-17 20:59 送审，当时为“审核中”；本轮未再次操作或回读 Console。当前 **0.3.2+7 debug** 是同证书真机验证包，不是新送审版本。隐私页、支持邮箱和复制链接测试均保留。送审历史见[送审记录](play-store-release-2026-10-17.md)，此前三阶段过程见[第一轮集成记录](android-round1-integration-2026-10-17.md)。

Pose-Hub 首版已发布并接入，版本冻结为 **v0.1.0**。新机器从已推送 main 按 [README 新机器拉素材](README.md#新机器拉素材mac--windows)恢复公开 ZIP 并执行 `sync --from-dir` / `--check`。Mac 从最终 main 开 `ios/…` 分支，只做 iOS 构建与真机验证；不升级素材、依赖、lock 或共用版本。

## 第一轮临时网页预览边界

独立预览在 320×568、360×740、390×844、768×1024 四个尺寸检查了正方形示范区、按钮 bounds、无滚动、六项自测切换及结果完成。该预览使用 poster stub，原生音频在网页会抛 `UnsupportedError`；系统行为与真实 H.264 媒体另由 Chrome 探针检查，不能将这些结果写为 HipLab 正式支持 Web。完整过程见[主干与 Pose-Hub 记录](mainline-pose-hub-2026-10-18.md)。

## 历史限制（最新待验范围见页首）

紧侧加练、主题、iOS 配置和隐私入口已在 main 集成并推送，不再作为未合入功能。六个动作的逐帧证据均显示短暂淡入变暗；去除视频 CSS 双重淡入后，Chrome 原 H.264 新旧对照及循环/暂停/恢复通过，最终 Android 原生首帧仍待单独复验。完整训练、音乐 ducking 与全量媒体体验仍待验收；系统通知、iOS Mac 构建/真机和 CI 尚未完成。Android前台服务/TrainingHold现由ugk_trainer唯一实现，App旧服务及hiplab/training_session通道已移除；PR24及后续正常播放、终态释放证据按来源保留。+17锁屏冻结仍是已知失败（D-34），用户明确后测并同意保留问题合main；耳机/蓝牙/ducking等扩展矩阵未执行，不改记通过。正式上传签名已在0.2.0+4验证；Play状态仅保留2026-10-17历史送审回执，本阶段未重新回读或上传。Android 彩色图标已实机验证，单色图层未做手机主题切换验证。事项统一维护在[开发事项台账](development-roadmap.md)。

## 第二轮集成快照（2026-10-18）

业务代码 `1b35657dec153741e25ca095ac2764b18d14ac29` 已于 2026-10-18 10:04 北京时间推送 main。运行源码 `1b35657dec153741e25ca095ac2764b18d14ac29`，版本 **0.3.3+8 debug**；行为检查源码 `162a4e6b78a8640d367cac13ef5e1ae6cfa9b33a`：analyze 0，Flutter 单并发 156 项通过、1 项按设计跳过。最终 APK 已构建，手机拔线未安装；Android 原生及 iOS 待验。PR #13：MERGED（a41e7e0）；PR #14：MERGED（4c563f9）。

临时独立网页预览在 320×568、360×740、390×844、768×1024 上检查正方形示范区、按钮 bounds、无滚动、六项自测及结果完成；点按暂停/继续、键盘、分段拖动、快速 Tab 和训练暂停/继续通过。预览使用 silent-voice fixture 与 poster stub；普通 DOM locator 仍因 Flutter semantics root 空白而超时，保留失败证据。坐标 page.mouse 操作通过且未使用 force；原生 widget hitTest 回归通过。这不构成原生媒体、H.264、系统音频或正式 Web 支持验收，也不据此诊断透明旧页遮挡。倒计时改为 33 ms tick；Chrome 18 屏的 17 个相邻环区域中，完全相同对数由旧 100 ms 的 5 对降至 0 对，采样约 47–79 ms，不代表真机帧时或帧率

[第二轮集成记录](round2-integration-2026-10-18.md)。本轮不上传商店，不改版本号以外的发布配置；没有新的手机安装或 native/iOS 通过结论。

## Pose-Hub v0.2.0 接入时快照（历史，2026-10-18）

Pose-Hub v0.2.0，视频 1080² / 封面 540²，46 个原 ID 与文件名保持。App 0.3.4+9，源码 `03c3b5bcd1ebc0157e3789af21a4bf0188f52468`，已构建但未安装；业务代码 `03c3b5bcd1ebc0157e3789af21a4bf0188f52468` 已于 2026-10-18 11:40 北京时间推送 main。手机仍为 `963db04` / 0.3.2+7，本轮无 ADB 或商店操作。

ZIP、云端冻结 manifest 已下载核验，安全解压 92 文件完成；App 同步：dry-run 92项计划；首次92 copied；check 92 matched /0 drift；重复同步0 copied。[Pose-Hub v0.2.0 接入](posehub-v020-integration-2026-10-18.md)。人工观感、原生首帧/音频与 Mac/iPhone 仍待验收。

## Android 安装历史（2026-10-18 17:15）

用户重新连接 2602BRT18C 后，核验旧包 0.3.2+7 与新包使用同一 debug 证书；备份 App 用户数据目录和 1356 字节偏好，执行 `adb install -r` 成功。设备回读 0.3.4 / versionCode 9；冷启动 Status ok（1677 ms），App 在前台、首页截图已查看，当前进程 crash 日志未见 FATAL EXCEPTION。安装后及启动后偏好均与备份逐字节一致。本次只安装和启动，未进入训练或自测，没有写回/清除数据；原生首帧、完整语音和系统音频仍待单独验证。

## Android 语音修复验收历史（0.3.5+10，2026-10-18）

0.3.4+9试听无声的原因是错误使用系统提示音通道；已改MEDIA并更新至0.3.5+10，铃声仍静音时原生轨道已 started / mutedState:none，用户确认完整口令可听。安装前当前偏好1355字节，与安装/启动/试听后逐字节一致；没有回写旧备份。详见[Android 静音模式语音修复](android-voice-media-routing-2026-10-18.md)。

## 样式修复构建阶段记录（安装前，2026-10-18）

0.3.6+11已完成浅色首页滑块、绿色小字和运动说明、隐私页共用顶栏；源码 `66f5da0`，analyze0、158pass/1条件skip、四尺寸网页自测及APK核验通过。该构建阶段尚未安装，手机当时仍为0.3.5+10；19:29安装事实见下一节。未发布商店。见[样式修复记录](theme-polish-2026-10-18.md)。

## 0.3.6+11 安装确认（2026-10-18 19:29）

已保留数据覆盖安装至2602BRT18C，设备回读versionName0.3.6/versionCode11，冷启动首页已查看浅色新滑块。安装前当前1356字节偏好在安装/启动/截图后逐字节保持，先备份再安装，未回写旧数据。仅验证本次安装和首页；未进入训练/自测或更改用户主题，未将旧版试听确认当成本版重新听音。证据见[样式修复记录](theme-polish-2026-10-18.md#安装追加2026-10-18)。

## PR #17/#18修复与集成（2026-10-18）

用户在初审后明确授权修复后直接推进合并。F1 Tab中途反向连续性、F2分段共享滑块下沉均首轮修复通过；#17独立169pass/1skip，组合191pass/1skip。23:35:52/23:36:26按顺序合入，源6dd16ed修复包已保留数据安装，本地main已对齐。原有自测和打卡保持，测试后1356字节偏好与测试前相同，浅色与系统动画值还原。本轮未新增假记录、未清数据/恢复备份或上传商店。剩余硬件/跨端边界见[本轮记录](pr17-pr18-fixes-and-merge-2026-10-18.md)。

## PR #19/#20/#21 隔离审核交付快照（历史；最新合并见末节）

main保持`6020d8e8bf26700e56785b029ef8d5ef4a379f2c`，原手机最后已记录源6dd16ed/0.3.6+11，本轮未操作手机及原记录。隔离分支`codex/pr19-pr21-validation`按#19→#20→#21组合：四项原PR问题在e3fb1d3首轮修复，另一本地组合反馈字体问题在c7def28首轮修复；最终analyze0、254pass/1条件skip、Python19通过，themed-media/action-kit检查通过。依赖、lock、版本未改。

按用户最新安排停止模拟器，Web复核已完成：实际Chrome共用播放器51/51、重点循环/暂停恢复7/7、核心脚本1/1；页面深浅、自测到结果/训练、88自测/追问+8结果尺寸组合、360×740字号1.5、设置与交互通过。最终字体增量深浅冷上下文复测通过。预览采用合成内存、静音输出及视频封面替身；不代替真机声音、原生合成、锁屏恢复或性能。47浅色视频技术审计及46动作包light引用检查通过。

早期e3fb1d3 x64包仅安装专用AVD，原AVD正式0.2.0未覆盖；9/14个合成场景后已停止，不能记为完整语音验收。最终c7def28 arm64候选身份见[版本台账](version-ledger.md)，未装手机。晚上继续真机、再按本轮同意顺序合入；当前未合main、未推送main、未上传商店。完整事实、截图与未验证边界见[审核报告](pr19-pr21-review-2026-10-19.md)。

## 本轮用户安装及简单测试反馈（2026-10-19）

用户收到本会话交付APK后反馈真机安装及简单测试通过。交付源`c7def2869b789357b303d69d66eb8c18a0a748ae`，版本0.3.6+11，174,329,762bytes，SHA256 `7fdbdf81f567d064d2dcab356494087a552913a32812f3a4c80c091a767ec678`；身份见[版本台账](version-ledger.md)。本次Agent未连接手机或执行ADB，未获取新设备版本、截图、WebView、逐项测试清单、备份或数据完整性证据。

当前状态为“已交付、用户报告安装及简单测试通过、审阅分支已推送、main未合入”。完整中英14项试听、原生切主题/退出专项、锁屏恢复、低端机/强光及iPhone等仍按实际未验范围保留；不把简单通过扩展为全部验收。本次只更新版本/验收记录，版本不递增、依赖/lock不改、不重构建、不上传商店。

## PR #19 → #20 → #21 主线合并确认（2026-10-19）

用户明确要求推进合并后，先回读原PR head与main，均与审核对象一致。将main从6020d8e快进至已审核合并链`b9646d4a15b4e3727d8e11ea5ee3106f0e396603`并普通push；GitHub于2026-10-19 14:00:39北京时间（06:00:39Z）确认三PR均MERGED。该时间为一次push后GitHub统一确认时间，Git第一父链实际顺序为#19→#20→#21：

| PR | GitHub确认的merge commit |
|---|---|
| [#19](https://github.com/mhgd3250905/HipLab/pull/19) | `2b552fd684a1a366433cf6544f1c721d4cd6209f` |
| [#20](https://github.com/mhgd3250905/HipLab/pull/20) | `18bf4ce2f211c6593cc9322a0776d9aa1e1aba43` |
| [#21](https://github.com/mhgd3250905/HipLab/pull/21) | `b6fd55ef1e00602a886d6bc62b2268b618639019` |

五项首轮运行修复、封面时刻工具guard、46动作包light引用和全部审核证据一并进入main。逐路径比较`lib/android/assets/tools/test/pubspec.yaml/pubspec.lock`，main与已验证源`c7def2869b789357b303d69d66eb8c18a0a748ae`无差异，因此本次不重跑全量或重构建APK；复用analyze0、254pass/1条件skip、Python19、媒体/动作包check及原arm64构建证据。用户报告安装及简单测试通过；完整原生14项试听、锁屏恢复、低端帧时/强光/iPhone等未验范围继续保留，不因合并自动通过。

版本仍0.3.6+11，依赖/lock无新改动，未操作手机或上传商店；原目录4个`.playwright-cli/`、`.playwright-mcp/`未跟踪文件保持。本次业务集成点为b9646d4，之后只追加实际合并文档记录。

## PR #22 审核（2026-10-19）

练习库 PR #22（head `a7992a6`）已按最新 main `243a812` 隔离审核，结论需要修改：7个合并冲突文件，查实1项P1与5项P2。原PR analyze0、286pass/1条件skip、Python18及两工具check通过；专项复现证实缺陷，未修复、未合并、未提交GitHub review，未构建安装或扩大真机验收。详见[审核报告](pr22-review-2026-10-19.md)。原main运行版本与设备记录保持。

### PR #22 修复复审（2026-10-19）

作者反馈新head `f7271f6`已合入目标main243a812，GitHub可合并。Windows复审原F1–F6闭环，analyze0、310pass/1skip、Python19、两工具check及49步骤独立剂量比对通过；另复现F7/P2：多组计次动作疼痛减半保护仍按1/2组判断，深蹲1次×3组减至8秒空转而不skip。结论仍需修改，未合并、无APK/真机新验收。[复审报告](pr22-reaudit-2026-10-19.md)。审核副本和新产物均在E盘。

### PR #22 F7复核（2026-10-19）

9fa0cc0对齐b12b0f5，F1–F7代码问题均关闭；Windows analyze0、322pass/1skip、Python19、两工具check通过，原F7独立复现由失败变通过。代码审核通过，D-29转待Android原生验收；尚未合并、无新APK/手机结果。[最新复核](pr22-reaudit-2026-10-19.md#最新f7复核通过2026-10-19)。

### PR #22 Android包已准备（2026-10-19）

准确基线b12b0f5及候选9fa0cc0的0.3.6+11 debug arm64 APK已在E盘构建并通过身份/签名/CRC/16KB对齐与音视频资源核对。用户安排先准备包、稍后接手机；本轮无ADB/安装/原生通过项，设备已安装事实保持原记录。D-29继续待原生验收，全部通过后仍需开哥同意才合并。[包身份与清单](pr22-android-acceptance-2026-10-19.md)。

### PR #22 Web补测发现F8（2026-10-19，待修复）

真实Web入口补齐非空状态升级、练习库/编辑、F3/F4/安全/F7、重复单练计时/记录与360宽2.0字号检查；新增P2：删除前项动画中打开后项剂量，返回按旧索引写回，覆盖第三动作，独立三步实测已确认并[评论PR](https://github.com/mhgd3250905/HipLab/pull/22#issuecomment-6266421023)。D-29转待修F8，尚未合并。Web口令循环初始片段在main基线也复现，声音内容不记通过；字号有P3截断。真实手机数据/语音/视频及系统矩阵仍待验，旧APK暂不作验收通过包。[完整结果与精简手测](pr22-web-acceptance-2026-10-19.md)。

## PR #24 Android后台语音审核（2026-10-19，待修复）

head e3655e5 / target main fcffded，Windows独立analyze0、277pass/1条件skip及debug arm64构建通过。专项复现两项P2：疼痛/暂停漏取消尾音与排队倒数、异步调音量缓存错误；main队列/控制器对照通过。另查实终态仍持有服务/CPU锁及旧STOP关闭新START的两项P2。GitHub OPEN/CONFLICTING，当前仅verification文档冲突。APK已在E盘校验，未安装/未ADB，无原生/iOS新增通过项，未合并；用户安排PR22 F8交作者处理。[完整审核与包身份](pr24-review-2026-10-19.md)。

## PR #22 / 2cc40e3 Android阶段复测（2026-10-19）

用户确认手机连接后已保留数据安装准确新head，原安装包9fa0cc0及偏好已留E盘；安装前后state JSON完全一致。Windows335pass/1skip、analyze0；F8主场景真机保存[B(2组),C]正确，连续双删稳定后编辑也正确，严格动画窗口点击边界单列未证实。另查实F9/P2：删除动画内立即保存使已删项重新出现，真机和150ms组件专项均失败、等待动画控制组通过。中文计次/保持各两轮记录准确；后台和英文锁屏的完成事件延迟到恢复后，不能记持续运行通过。当前手机安全锁屏需用户解锁，剩余英文/中断/ducking及实际听音待补。用户取消极大字号验收，显示已恢复，原中文/深色设置仍待解锁后恢复；不合并PR。[复测证据](pr22-native-retest-2026-10-19.md)。

## PR #24修复与#22组合进展（2026-10-19 22:00）

PR24固定0ccef6b原4项P2在源码/原失败专项闭环；与PR22 2cc40e3组合，并补同State重播的新TrainingHold交接。验证分支codex/pr22-pr24-validation的5725c36已推送；373pass/1条件skip、analyze0、Kotlin/APK身份检查通过。21:56:37组合包已保留数据安装，14键升级状态相同；正常单练两轮及再来一组完成，恰增2条记录，原8条/两组/设置/连续天数保持；两轮服务和CPU锁在收尾后释放，用户听音确认正常。当前手机中文、深色、正常字号，已回今日页。

PR22 F8关闭，F9删除后立即保存仍待作者修；PR22/24均未合并main、未approve，main本轮只推进文档。用户将当前原生门槛收窄为正常播放，不再扩展耳机/蓝牙/ducking/锁屏中断矩阵；旧失败不改记通过，iOS未验。已解锁、英文保持第二轮/闹铃中断/第三轮重播及原设置恢复均补齐，旧等待解锁描述为历史快照。[本轮精确身份与证据](pr24-reaudit-and-pr22-integration-2026-10-19.md)。


## PR22 F9复审完成（2026-10-19）

a586de3的F9原失败专项、8项新增与F8/键盘回归通过，组合9b22dcc的387pass/1skip、analyze0、APK及保留数据安装通过；真机唯一项/立即保存/连删/放弃关闭正确，正常字号搜索首次及视频详情返回均实际弹IME。全部非训练组字段、10条记录与另一测试组保持，仅既有测试组1按操作变化。F1–F9代码问题均关闭，当前验收范围内无已知阻断；仍未合main，等待开哥最终合并同意。旧“F9待修”均为历史快照，iOS与扩展矩阵不冒称通过。[复审报告](pr22-f9-reaudit-2026-10-19.md)。


## PR #22 / #24 主线集成完成（2026-10-19 23:32）

开哥明确同意后，main从ab1425b快进至已验候选b33ed21并普通推送；GitHub23:32:51确认22/24均MERGED（各mergeCommit为9b22dcc/5725c36）。来源a586de3/0ccef6b保持，主线运行内容与已安装9b22dcc相同。当前开发基线已包含练习库、自定义训练组/单练历史、PR24语音与按会话保活、重播hold适配和F1–F9修复。无新构建/安装/版本或商店动作；387pass/1skip及原生结果沿用，iOS未验。旧“待最终同意”均为历史快照。[合并确认](pr22-f9-reaudit-2026-10-19.md)。
