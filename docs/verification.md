# 验证台账

## 2026-11-06：文件夹交接、直接选组与返回回归 / +53

构建源`2d46ab1e4fcc0d696ae3748330863ccb93fb94aa`，候选`codex/home-routine-folder-20261106`；`1.1.0+53` / arm64 `2053`，SDK保持`6fbd7de15dea62c7152eac43df1303b85d887a7c`、lock保持。已验收+52保留历史，本轮新增文件夹等待用户确认。

首页“换一套”改64pt四动作封面的玻璃文件夹，原位展开当前场景全部有效推荐组，展示名称/时长/动作数与选中状态，可直接选择。关闭完成再更新首页；取消或重复选择保留预览与视频，办公/居家各自记住本次启动的选择，实际开练使用所选完整计划。只用SDK静态封面，无额外视频节点。相关10文件108通过/14既有跳过，文件夹7项另通过，分析0。已同签覆盖安装真机，包管理器回读2053、MainActivity启动成功。新动效与交互观感待用户确认；本轮无全量、iOS或模型验收。[实现与交付](home-routine-folder-2026-11-06.md)。

## 2026-11-06：+52用户真机验收通过

用户在+52覆盖安装后明确回复“我已已经验收通过了”，当前`1.1.0+52`（arm64 `2052`，构建源`59ce2b8`）记为**用户真机验收通过**。本轮首页动作卡片及计划切换优化的用户验收项已收束；不另推定未报告的逐项测试或性能指标。安装回执与APK身份保持，未重建或改运行代码；候选分支仍为`codex/home-plan-media-continuity-20261106`，合并状态独立记录。

用户确认回执：`E:/AII-3D/hiplab-releases/home-plan-59ce2b8-52-20261106/user-acceptance-20261106.json`。下方“待验收”保留为交付时历史，当前以本条为准。[实现与交付](home-plan-media-continuity-2026-11-06.md)。

## 2026-11-06：+52真机覆盖安装与启动回执

用户重新连接手机并明确授权安装。已在`2602BRT18C`（`QSG6Q8IFDMDELVGQ`）执行`install -r --no-incremental`，回执Success；包管理器从2051更新为2052（1.1.0），设备lastUpdateTime为2026-11-06 22:12:14。未卸载、未清数据；原firstInstallTime仍为2026-11-05 22:11:33，未另核验业务数据。`com.ugk.hiplab/.MainActivity`冷启动Status ok；这里只确认安装与启动，卡片切换/展开/播放观感仍待用户使用反馈，不据此宣布视觉或性能验收。

安装包仍为构建源`59ce2b8`，SHA256 `3bac5de8477199360cab68c74cfaa446c1c2f74d3f5117ba752b4a2a203692e9`；无重建、运行代码、SDK或版本变更。安装回执留`E:/AII-3D/hiplab-releases/home-plan-59ce2b8-52-20261106/device-install-20261106-221214.json`。下方交付时“未安装”保留为历史；当前状态以本条为准。

## 2026-11-06：场景/计划/跨日与迟到帧回归 / +52

运行/构建源 `59ce2b8829d64eec401c743123d31c57e79d4a62`，分支 `codex/home-plan-media-continuity-20261106`；`1.1.0+52` / arm64 `2052`。SDK仍固定 `6fbd7de15dea62c7152eac43df1303b85d887a7c`，hosted锁保持；日常目录 `feat/ui-detail-polish@25260b3` 未改。

针对办公/居家首牌闪动，将冷牌保护统一覆盖初始首牌、场景/换一套/跨日/动作列表重置，以及关闭后迟到首帧。新牌保持封面，主动展开才揭示原视频；同一已就绪当前动作成为新首牌时保留State/controller/Texture与当前帧。提前解码两场景当前可选计划的首封面，精确匹配bundle和显示尺寸，不批量下载视频。新增6项回归；相关10文件106通过/0失败/14既有跳过，分析0；Impeller另2通过、62组RGBA消费对照误差/黑残影0。SDK/Android和+51运动参数未改，本轮未重复SDK测试。

+52 release验包/验签通过，与+51内部包同签。未安装、未跑全量/模型/iOS；远程手机观感待用户确认。[实现与交付](home-plan-media-continuity-2026-11-06.md)。

## 2026-11-06：暖牌接管、冷帧锁图和变速回归 / +51

运行/构建源 `2087649d8c0dc8b34827c8458876886e55330662`，分支 `codex/home-card-handoff-motion-20261106`；`1.1.0+51` / arm64 `2051`。SDK固定 `6fbd7de15dea62c7152eac43df1303b85d887a7c`，hosted锁保持。日常目录 `feat/ui-detail-polish@25260b3` 保持。

用户确认+50的更多闪帧/上下透明异常修复。新候选预备current±1最多3挂载暂停媒体，到顶按occurrence GlobalKey接管原State/controller/Texture；冷首帧迟到保持compact既有图，主动展开解除。上下仍用物理曲线，取消900硬限速、竖k70/ζ.82，水平原值保持。相关100通过/14跳过，强化甩速另1通过，Impeller另2通过/62组RGBA像素0误差；SDK54通过，双方分析0。+51 release验包/验签通过，与+50内部包同签；Agent未安装，新接牌及手感待用户远程确认。

[实现、资源范围与交付](home-card-handoff-motion-2026-11-06.md)。

## 2026-11-06：真实转场同纹理及离屏GPU回归 / +50

运行/构建源 `981eeaf161c0b896e963d625f9525b69e9bf32b6`，候选分支 `codex/home-card-surface-stability-20261106`；`1.1.0+50` / arm64 `2050`。四个SDK包及coach override固定 `145e3195570f34536c948558e02306a3db5ec2e3`，hosted锁保持；日常目录 `feat/ui-detail-polish@25260b3` 保持。

仅首页前牌启用暂停帧跨覆盖路由保留和原生单decoder RGBA输出：解决进入更多时回封面的明确路径，绕开上下离屏裁剪对packed透明取样的破坏。App相关96通过/14跳过，Impeller另2项通过（68组RGBA消费对照误差/黑残影0）；SDK相关49通过，双方分析0。+50 release及Android原生编译、验包/验签通过，同+49内部证书；Agent未安装，Android OES/SurfaceProducer及原机观感待用户远程确认。

[定位、实现与交付](home-card-surface-stability-2026-11-06.md)。

## 2026-11-06：原点按与竖向退场节奏回归 / +49

运行/构建源 `8475c71f2bdb2eb69456c7fe400fe4f594f1d7b0`，候选分支 `codex/home-card-exit-easing-20261106`；`1.1.0+49` / arm64 `2049`。SDK仍 `b4861c5215280c49bffe03b8c203074217dcf995`，lock保持；日常目录 `feat/ui-detail-polish@25260b3` 保持。

按用户最新反馈完整撤回长按识别/吸附动效，恢复原点按展开。全向翻牌保留；退出目标按实际投影边界离屏剩余距离计算，放缓竖向弹簧并限制沿射线的起始速度，离屏后及时交接。相关10文件95通过/13跳过，Impeller像素另1通过，分析0；+49 release验包/验签通过，与+48内部包同签。Agent未安装，手感交用户远程确认。

[实现、节奏回归与包身份](home-card-exit-easing-2026-11-06.md)。

## 2026-11-06：动作牌交互与固定文字画布 / +48

运行/构建源 `1d89e8916513639b5a56e57997170754ae103404`，候选分支 `codex/home-card-touch-motion-20261106`；`1.1.0+48` / arm64 `2048`。SDK仍 `b4861c5215280c49bffe03b8c203074217dcf995`，lock保持；日常目录 `feat/ui-detail-polish@25260b3` 保持。

短按立即展开，300ms长按轻抬且可继续跟手；任意方向拖出径向区域均可翻牌，并沿原射线离场。持当前视频帧完成展开后自动播放，刊头/编号等改固定画布缩放，以减少首次起播和重复排版与过渡并发。相关10文件94通过/13跳过，Impeller像素另1通过，分析0。+48 release验包/验签通过，与+47内部包同签；Agent未安装，首次展开及手感交用户远程验收，未采集原机性能trace。

[交互、性能边界与包身份](home-card-touch-motion-2026-11-06.md)。

## 2026-11-06：静默加载回归 / +47

运行/构建源 `bba10fdb98934cea5e9f27c3062a7ad74d79e43c`，候选分支 `codex/home-card-silent-loading-20261106`；`1.1.0+47` / arm64 `2047`。SDK固定 `b4861c5215280c49bffe03b8c203074217dcf995`，hosted锁保持；日常目录 `feat/ui-detail-polish@25260b3` 保持。

首页下载/待首帧不再显示转圈，保持封面至真实首帧，由同一播放器接上；真实失败重试保留，普通宿主默认提示保持。App相关10文件88通过/13跳过，Impeller像素回归另串行1通过；SDK相关31通过，双方分析0。+47 release验包/验签通过，与+46内部包同签；交用户远程覆盖测试，Agent未安装，实际切牌/首帧观感待反馈。

[实现、检查与包身份](home-card-silent-loading-2026-11-06.md)。

## 2026-11-06：接牌比例与杂志版式 / +46

运行/构建源 `21dd048940baef24a4e3d7186163ae626b062fcf`，独立分支 `codex/home-card-editorial-20261106`；`1.1.0+46` / arm64 `2046`。SDK仍 `1c082e9d3e22022f228888fdd1935b1d61371cb9`，lock、shader、媒体与原生代码保持。日常目录 `feat/ui-detail-polish@25260b3` 保持。

按用户两项反馈，移除“左右翻阅”及两侧箭头整个底行和预留；前后牌共用同一Face，标题/视频比例及材质不再在到顶时切换。展开态采用刊头细线、放大单序号、侧栏、强调标题、动作要领和页脚印记的杂志版式，保留原动作分类、方向、剂量和说明内容。

相关10文件87通过/0失败/13跳过（12既有截图项+1需Impeller）；真实shader像素回归另以 --enable-impeller 1通过。fatal-infos分析0，严格锁解析不改lock。未重新跑全量App/SDK。 最终+46 release已构建、验签和资源校验，未由Agent安装，继续交用户远程覆盖测试。Noto字体浅深实际widget渲染已检查，组件逐帧与headless Impeller证据不替代原机滑动/展开观感及帧时长验收。

[版式、连续性与交付](home-card-editorial-2026-11-06.md)。

## 2026-11-06：真实shader像素回归 / +45

运行/构建源 `9925e3c58afdea65768875f85ee3a4b60865a6f0`，分支 `codex/home-card-alpha-alignment-20261106`；`1.1.0+45` / arm64 `2045`。SDK仍 `1c082e9d3e22022f228888fdd1935b1d61371cb9`，lock、shader/素材内容及原生代码保持；日常目录 `feat/ui-detail-polish@25260b3` 保持clean。

用户+44截图显示坐姿后撑单膝内倒等前牌人物后缘有错位黑轮廓。+45为前牌姿态Transform设置非空filterQuality：先在局部坐标合成视频RGB/alpha，再将整张牌作为GPU滤镜结果做透视/旋转；保留同一直播Texture、当前帧暂停和展开/收起行为。

常规10文件85通过/0失败/13跳过（12既有截图跳过，1项真实shader像素测试需Impeller）；该像素测试另以 --enable-impeller 单独运行1通过。新增像素和实际layer断言在旧路径先失败，修复后通过；fatal-infos分析0，严格锁解析不改lock。 最终+45已构建、验签和资源校验，未由Agent安装。继续交由用户远程覆盖安装，原机视频取样、文字清晰度和帧时长仍待反馈；本机headless Impeller与合成图案不代替手机GPU/SurfaceProducer验收。

[定位、像素对照与交付](home-card-alpha-alignment-2026-11-06.md)。

## 2026-11-06：持久视频牌面 / +44

运行/构建源 `c0798ecc6a9ef5f91bfa0221cee5bb2c42dfad38`，独立分支 `codex/home-card-live-surface-20261106`；`1.1.0+44` / arm64 `2044`。四个实际SDK包及coach override固定 `1c082e9d3e22022f228888fdd1935b1d61371cb9`；hosted锁、Flutter3.44.7及素材内容保持。日常目录仍 `feat/ui-detail-polish@25260b3`，保持clean。

用户在+43交付后反馈展开/收起仍闪，并提出同一视频元素方案。+44将当前前牌常驻root OverlayPortal：初次准备首帧暂停，展开只改变同一牌面的矩阵/大小并播放，关闭立即暂停当前帧并缩回，compact继续显示该帧；再次展开继续播放。移除App快放回首调用、两面交接、截图捕获及专用弹层路由。

App相关9文件85通过/0失败/12既有截图跳过（牌组34项）；SDK runtime相关29项通过，双方fatal-infos分析0，App严格锁解析通过，lock仅四个Git节点ref变化。未跑全量App/SDK。 最终+44 release已构建、验签及资源校验，尚未由Agent安装；按用户决定交由用户远程安装测试。同一节点/纹理身份的组件回归和浅深色实际widget绘制检查已完成，原生首帧准备与真实过渡观感等待用户反馈，不能记作真机无闪烁通过。

[方案、包身份与验收归属](home-card-live-surface-2026-11-06.md)。

## 2026-11-06：动作牌关闭回归 / +43

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

严格锁解析和 fatal-infos 分析0；完整70文件首次501通过/1条旧关闭按钮定位器失败/68既有跳过。仅将该测试改为当前关闭胶囊后，相关整份16/16通过；按测试文件和名称合并最新结果为502通过/0未解决失败/68既有跳过，并非第二次完整全量运行。运行代码在全量后未改变。

新增37项回归（四个新文件），相对465项基线最终502项，跳过仍68。专项覆盖：页面/副标题/路由/路线弹层11，共用组件20及iOS减少动画侧滑1，助手加载失败/重试浅深2，公共组导入3。公共组导入专项在原实现3条全失败、修后3条与原存储8条共11/11通过；未发送模型请求。

本地证据：`E:/AII-3D/hiplab-releases/ui-r4-completion-20261105/` 的`full-test.jsonl`、`ui-round2-recheck.jsonl`、`verification-summary.json`、`analyze.log`、截图说明及最终图集。首次完整运行失败记录保留，不以最终汇总覆盖历史。构建首次主机Java native-memory失败，使用单worker/1GiB堆重试成功，无源码/依赖规避。

最终release验包：非debuggable、仅arm64、CRC/目录/209封面/0MP4/789资产原字节通过、重签前后运行负载相同，签名与当前手机开发包一致。设备覆盖Success、2036回读和冷启动成功；诊断WIP与最终release的截图分开，不把软件/iOS组件检查当作iOS真机。完整页面归属见[审核报告](ui-r4-completion-2026-11-05.md)。

## 2026-11-05：UI r4 / PR #32 本机合并复审

原 head `cb0f0634f1abea346cf9b39bc0cc50d5ff867c89`；实际目标与 PR base 均为 `97cecb12367847e8eeca6297e486cc371b665460`。验证在 E 盘隔离副本执行，主目录按用户要求切换 UI 分支，未改动既有构建副本。

严格锁解析通过且 lock 未变；修复后 `analyze --no-pub --fatal-infos` 为 0。更多→设置双胶囊三条新增回归在原代码全部失败，修复后全部通过，未新增跳过。修复源 `6969425e3b2c13071bd52a6f5ddb8bfa5a5b5ec3` 全部66文件 **465通过 / 0失败 / 68既有跳过**；本地日志见[审核报告](ui-r4-pr32-review-2026-11-05.md)。后续仅文档变化不重复运行整套测试。

本轮没有构建、设备安装/操作或真实模型请求。作者远程阶段的 Pixel 8 +35 debug/nav11/nav12 记录保留原归属，胶囊补丁的组件证据不推广为真机通过；旧 +35/2035 release 包不含本次 UI。

## 2026-11-04：QA v3 / +34 主线及版本文档收束

### Preflight：范围、来源与归属

- 收束scope：SDK问答接入、+31→+34版本/交付与PR #30合入的文档对齐；只改确定的当前摘要、版本/验证/事项/工作流，不改App/SDK/测试/锁，不增版、重建、安装或发布。
- baseline：`4d610f50ee47f2d4de7c19517eb7e99220bb2204`，可核对ref `4d610f5^{commit}`；依据为本会话上一轮文档收束及本阶段建分支的main起点。`git rev-parse --verify`与`git merge-base --is-ancestor 4d610f5 HEAD`均成功。
- 收束前HEAD：`2400b344183e1d57636412309899b4a1481966a7`，与origin/main回读一致，即PR #30合并点。
- stage delta：`git log --oneline 4d610f5..HEAD`共7提交；`git diff --name-status 4d610f5..HEAD`共22路径：10文档、2标签资产、4App源文件、2pubspec、3测试、1probe。主题是SDK pin、qaV2入口/问答v3、模型/max、未审标签传入、版本/测试与交付记录。
- 完整工作区：`git status --porcelain=v1 --untracked-files=all`为空；tracked变更、staged、unstaged、deleted、renamed、untracked各0，无未知归属。阶段差异均来自已提交的上述7提交；本次新增文档修改归本Agent。没有清理/stash/reset其他改动；原stash0fa5c25及候选副本保留。
- GitHub只读回读：PR #30 merged=true，merge_commit_sha为2400b34；PR #29 OPEN/Draft，head447ca1c。release/1.0本地1f9a172、远端a20721e未动；不据此推断商店状态。

Canonical发现从根AGENTS和README声明的一跳入口完成，docs/AGENTS.md不存在。实际核对如下；旧日期段只作history，不冒充当前来源，也未递归追查旧发布、外部项目或制品。

| 路径 | 分类与判定 | 本阶段核对 |
|---|---|---|
| AGENTS.md、README.md | current项目入口；旧日期段history | 主线、版本、SDK、签名规则和授权边界 |
| docs/README.md | current导航/新机流程；旧ZIP段history | +34、PR30、pub.dev、Git标签资产与来源入口 |
| docs/current-state.md | current事实摘要；旧阶段表history | 功能集成点、自动证据、用户+32与待验范围 |
| docs/version-management.md | current版本规则；旧候选段history | +34/2034、完整SDK pin、包/源码/安装状态分记 |
| docs/version-ledger.md | current交付流水，各日期为当时记录 | 补+33未构建、+34实际包和+32签名/手机来源 |
| docs/verification.md | current验证流水，各轮证据按源限定 | 此Preflight与同树复用、旧实模不外推 |
| docs/development-roadmap.md | current事项索引，旧事项history | D-45代码已集成、设备验收待反馈；PR29/D-34保持 |
| docs/development-log.md | current成果流水，旧日期history | PR30合入、+34交付和此次文档收束 |
| docs/development-workflow.md | current操作规范；旧媒体/发布段history | +34/pin、官方源、签名失败条件及Mac素材准备 |

确定findings：入口仍显示+30/+31/+32候选，缺+33未构建与+34包记录；SDK/依赖源和两个hosted版本变化未记入当前规则；README及工作流误写release缺签名自动回退；旧实模和手机状态需要来源分开。Alignment仅修这些确定文档问题，旧专题报告原文保留。

### 运行验证证据与source state

以下命令/结果来自本会话2026-11-04已返回回执，非本次closeout重跑，也未重新读取日志或APK。

| 命令 | source state | 结果及适用性 |
|---|---|---|
| flutter pub get --enforce-lockfile | main2400b344183e1d57636412309899b4a1481966a7，干净工作树 | 成功，按提交内pub.dev保持lock；本次不改依赖 |
| flutter analyze --no-pub --fatal-infos | 0f0882ede92b796ba53a03df1097f11232cb2d69 | 0问题，可按同树沿用到功能集成点 |
| flutter test --no-pub --concurrency=2 --reporter=expanded（每批最多4文件） | 同上固定0f0882e；完整test/清单与源码哈希已核对 | 66文件/17批，461通过、0失败、68既有截图/导出条件跳过；无失败重跑或测试修补 |
| flutter build apk --release --no-pub --target-platform=android-arm64 --split-per-abi | 同上固定0f0882e，外部测试配置 | +34/2034 arm64 release成功，49,680,947 bytes；构建证据仍归该源，不改写成当前文档HEAD重建 |
| apksigner verify --verbose --print-certs（+32与+34固定APK）及aapt2 dump badging | +32包源c327a90；+34包源0f0882e | 签名通过、证书相同；+34包名com.ugk.hiplab、2034、arm64、非debuggable；SHA/路径见版本台账 |

复用证明：`git rev-parse 0f0882e^{tree} 2400b34^{tree}`均为 `1fd1d1cb2d49d930d4367a1909de4aac71c80af7`，两者完整diff为空且0f0882e为祖先。因此运行源码/锁/测试/资源完全相同，分析和测试可沿用；本次收束提交只改上述十份Markdown，仍需以有限diff核对后提交，不创造新APK或新真机证据。

相对4d610f5，本阶段还包含jni1.1.0→1.1.2、shared_preferences_android2.4.28→2.5.4与hosted源切换pub.dev；这些已包含在0f0882e的检查和构建内，本次不重锁。+31/SDK9dd93163的三段九轮18次实模与计划时长，以及+32/3e949ce的检查仅属于各自历史，不能替代当前f7b8a8e的实模或真机验收。

用户确认+33未出包、手机为+32；本轮没有ADB安装/回读、对话失败日志或+34实机结果。+34仍待旧记录恢复/提示、即时气泡、三轮含排计划及杀进程重启续聊。UI r3 PR29及D-34历史锁屏失败不因文档收束而关闭。

本次必要检查已通过：实际完整状态恰为上述10份Markdown修改，归本Agent，无新增未跟踪项；579个本地链接及71个锚点核对通过、错误0，`git diff --check`通过。运行源码、Android、资产、pubspec/lock、测试与工具的差异为0；原stash与release引用保持。上述确定findings已对齐，未重跑全量检查或构建。后续文档HEAD以本轮Git提交回执为准，下方旧段按历史保留。

## 2026-11-04：SDK 3e949ce / +32 验证

构建源 `c327a90e9946edfe7254075deec91edd749b604e`，分支 `codex/sdk-pin-v0.7.0` / [Draft PR #30](https://github.com/mhgd3250905/HipLab/pull/30)，SDK 固定 `3e949ce6ecd695aa954a012f33474942531324ef`（codex/qa-v2-fixes）。`flutter pub get` 成功且锁文件未变；严格 analyze 0，全部 66 个测试文件 461 通过 / 0 失败 / 68 既有条件跳过。

APK 签名与 +31 一致，身份/负载校验通过；无真机，验收 1–4 待用户执行。本轮没有手机或新 SDK 真实对话结论；日志与命令保存在本地，见 [sdk-qa-fixes-plus32-2026-11-04.md](sdk-qa-fixes-plus32-2026-11-04.md)。

## 2026-11-04：SDK 0.7.1 QA v2 验证

运行源码 `2c13e8a119409c857508c6c3e79dc27241e8e702`，SDK9dd93163，Flutter3.44.7/Dart3.12.2。严格锁解析和analyze0；65文件分批458/0/68，加新增SDK端到端回归3/0/0，精确覆盖test/全部66文件，合计461通过/0失败/68既有条件跳过。真实生产Host→SDK控制器3段9轮18次请求，全为deepseek-v4.1-flash/max，单多选/编号/原门禁及计划保存通过。三个计划真实610/626/296s，卡片与phase求和一致。release构建/身份/2031/签名/CRC/资源和重签负载通过；未安装，真机由用户远程验收。新增回归/文档相对运行源无runtime变化，不重复已过检查。完整命令、工作树绑定、原文路径与有限边界见[完整接入与验证](sdk-qa-v0.7.1-validation-2026-11-04.md)；旧0.7.0直接Agent试跑不作为本轮证据。

## 2026-11-04：近期文档收束与证据适用性

### Preflight（只读）

- 收束 scope：共享体验→211完整动作→首页/主题→UI r2/混合组→SDK0.6的已入主线成果，并补记UI r3候选及未验边界；只修文档。不含功能修改、SDK升级、候选合并、构建/手机/商店操作。第5批Coach是阶段前背景。
- baseline：`0f507a3124436d29e8e3fbb7e2769a1d7d3c9018`（可核对引用`0f507a3^{commit}`），来源为根README及共享体验报告明确的main起点；`git rev-parse --verify`成功，`git merge-base --is-ancestor 0f507a3 HEAD`退出0。
- HEAD：`0737e4e3e34cc7116e03554e977a0d8e65b39267`；fetch后等于origin/main。`git log 0f507a3..HEAD`为46提交；同基线diff为420路径：assets308、lib37、test43、test_screens7、tools7、docs14、android1、根README1、pubspec.yaml/lock各1。已核对SDK/版本、媒体/冷启动、页面/混合组/计时、测试与构建配置主题；Android已有`kotlin.incremental=false`用于跨盘依赖编译，本轮不改配置。
- 完整工作区：`git status --porcelain=v1 --untracked-files=all`返回空；staged/unstaged/deleted/renamed/untracked均0，无未知归属。阶段delta是既有已提交来源；本次文档编辑归本Agent，原WIP stash和其他工作副本保留，不读取其内容。
- GitHub只读回读：PR26/27/28均merged=true；PR29为open/draft，head447ca1c。远端release/1.0为a20721e；不以此推定商店状态。

| 实际检查来源 | current / archive 判定与核对 |
|---|---|
| `AGENTS.md`、`README.md`、`docs/README.md` | current入口/规则；发现已合PR仍写候选、旧素材恢复仍被当默认流程 |
| `docs/current-state.md` | current状态源；发现版本/安装/SDK/主线旧表未明确降为历史、缺PR29候选索引 |
| `docs/version-management.md`、`docs/version-ledger.md` | current版本规则/交付源；发现0.3.9+17和旧SDK仍写当前、同号+30身份需区分 |
| `docs/verification.md` | current验证源；补充454主线与434候选的source state适用性，不混用 |
| `docs/development-roadmap.md`、`docs/development-log.md` | current事项/成果源；补齐已集成、待真机与候选状态 |
| `docs/development-workflow.md` | current工作流；旧冻结ZIP恢复步骤与主线0MP4冲突，需标历史 |
| `pubspec.yaml`、`pubspec.lock` | current配置；1.1.0+30、四个实际SDK包/override均693cbc02，lock ref/resolved-ref一致；本轮不改 |
| `lib/hip/data/hip_action_scope.dart`、`hip_public_media.dart`、`hip_shared_library.dart` | current实现来源；211授权、按需媒体、UI locale zh；配置与报告一致 |
| `assets/public_media/catalog.json`、`assets/public_media/catalog/catalog.json`、Git资源路径清单 | current元数据；目录含219定义但授权仍211、公共封面211、tracked MP4为0；目录数量不等于App可用数量 |
| `docs/coach-chat-sdk-2026-11-02.md`、`sdk-shared-experience-completion-2026-11-02.md`、`full-action-scope-completion-2026-11-02.md`、`home-calm-r1-2026-11-02.md`、`ui-r2-pages-integration-2026-11-03.md`、`sdk-pin-v0.6.0-validation-2026-11-03.md` | archive/history专题证据，分别保留当时source/结果/包与验收；不作当前分支状态源 |
| `origin/feat/ui-r2-pages:docs/ui-r2-r3-validation-2026-11-03.md` | 候选分支history证据；从已恢复relay明确指向的同仓库ref读取，不是main已验事实 |

### 验证绑定

| source state / 执行日期及来源 | 命令与结果 | 当前适用性 |
|---|---|---|
| `3a449c33be01dbef35c635a346f35eb26be1154a`；2026-11-03，[SDK报告](sdk-pin-v0.6.0-validation-2026-11-03.md) | `flutter pub get --offline --enforce-lockfile`通过；`flutter analyze --no-pub --fatal-infos`0；报告记录逐批`flutter test --no-pub`，64文件、4文件/批、concurrency=2：454通过/0失败/68条件跳过，重点24通过 | `git diff --name-status 3a449c3 HEAD`仅6份docs，无运行/依赖/资源/测试差异，故可沿用主线；不是本轮重跑。报告未提供精确执行时刻或完整分批shell，不补造 |
| `00feee16ea049e636f3c43f900ce7a5902d10363`；2026-11-03，[候选报告](https://github.com/mhgd3250905/HipLab/blob/447ca1ca3471aa6504e43179cdedeaa1fb8120d0/docs/ui-r2-r3-validation-2026-11-03.md) | `flutter pub get --enforce-lockfile`通过；严格analyze0；`flutter test --no-pub --concurrency=2 --reporter=expanded test/hip`60文件434通过/0失败/68既有条件跳过 | 到候选447ca1c仅6份docs；不属于main祖先，不能写成main测试。非本轮重跑 |
| `f4714c6630205afdd85fd4c4655bd51ee814b0b0`及更早来源 | 原命令/454与各阶段结果仍保留在日期报告 | f4714c6到当前HEAD有5个非docs路径变化，SDK已升级；更早测试均仅作各阶段历史，不叠加为当前全量 |
| 本轮文档工作树（基于0737e4e） | 完整Git状态、来源/版本/PR核对；必要验证为`git diff --check`、本轮新增/修改本地链接与一致性检查 | 只改Markdown，主线运行源码仍等同3a449c3；无需重跑Flutter测试/构建，无真机新增结论 |

68条件跳过在主线为12首页截图+55 r2截图+1可选语音导出，候选为67截图+1可选导出；保留原统计范围，不把434与454当同一次全量。SDK换侧3秒是预计余量，`phases/executionTiming`按真实阶段；不机械增加执行时长断言。App UI固定中文，语音切换不能作为动作库UI切换验收。旧D-34失败、混合组完整真机、数据保持与聊天返回键抽查仍未关闭。

### Alignment

确定finding为：已合PR的当前状态滞后、旧App/SDK版本和内置媒体恢复步骤仍作当前口径、同号包/候选与主线验证混用风险、UI r3候选缺当前索引。按已核对来源在入口、当前状态、版本/验证/事项/日志及工作流中修正，并明确历史边界；原报告/包SHA/历史失败保留。检查不读凭据、日志、构建产物，不扫描其他仓库。本次提交自身即为文档source state，最终commit SHA及push回读由Git和Cockpit回执记录。

本轮完成结果（2026-11-04）：`git diff --check`退出0；Python只读校验通过53处新增/修改本地链接及锚点、版本/SDK pin/lock与source delta一致性；完整状态为10份明确Markdown未暂存、staged0/untracked0，无其他路径；独立只读复审无新增finding。改动全部归本Agent，确定alignment findings已清零。仅文档，未重复Flutter analyze/test、APK构建或设备检查。

## 2026-11-03：SDK v0.6.0 候选测试与内部包完成

`codex/sdk-pin-v0.6.0` / Draft PR #28 的测试与构建源 `3a449c3`，SDK pin `693cbc02`。严格 analyze 0；全量 64 文件分 16 批共 454 通过 / 0 失败 / 68 既有条件跳过，四个重点文件 24 通过，无代码修复。1.1.0+30/2030 arm64 内部包 47.64 MiB、同测试签名、0 MP4，文件名含 3a449c3，未安装。App 界面固定中文，语音语言切换不能验收动作库界面切换；聊天单返回键仅代码核对，真机由用户远程安装抽查。不合 main、不动 release/商店，日常 WIP 未操作。[完整回执](sdk-pin-v0.6.0-validation-2026-11-03.md)。以下保留历史阶段。

## 2026-11-03：PR #27 r2候选验证完成，待用户远程安装

保留已确认的r2结构，仅修每日训练分钟重复取整，补混合组实际SDK阶段/组间休息/完成保存回归。验证构建源`f4714c6`；analyze0，64文件按4文件/批全部通过，含新增回归去重454通过/0失败/68条件跳过（opt-in截图/导出）。47.64MiB release候选保持+30/2030、同测试签名/0MP4，交用户远程安装验混合组和旧数据，本轮未安装。只正常字体，不合main、不升版、不动release/商店。[交付与APK身份](ui-r2-pages-integration-2026-11-03.md)。以下为历史阶段。

## 2026-11-02：PR #26 首页主题合入，+30 已保留数据安装

用户确认设计并授权合并，PR26在同步最新main后验证通过，合并点`a201fd5`；1.1.0+30/2030构建源`a7e371e`，47.70MiB release APK已同签名覆盖安装。analyze0、全量444通过/0失败/13条件跳过，额外截图4通过。正常字号浅深快速走查无新增显示问题，6天训练汇总、自测10/12、2组及主要设置保持；详细使用交用户。SDK仍d4502f3/211动作，日常40个WIP未变，release/tag/商店不动。[交付、脚本删除清单与验收边界](home-calm-r1-2026-11-02.md)。下方为历史阶段。

## 2026-11-02：211 动作 +29 门禁通过

验证/构建源`5072cbb291fe099fbbbd8e673a326e47e21808e8`；Flutter3.44.7/Dart3.12.2、SDK d4502f3。严格analyze0，全量Flutter437通过/1既有条件跳过（5分51秒），Python25/25。211浏览=211Coach准入、全部完整动作剂量/保存恢复/执行、8partial拒绝、新胸部动作SDK播放和已存计划封面均有回归；自测与原课程保持。release APK身份2029、签名/CRC/重签前后运行负载一致、211封面及0 MP4通过；WIP40文件哈希/状态与原生成依赖配置恢复通过。未执行ADB或新增真机/视觉验收。[门禁与制品](full-action-scope-completion-2026-11-02.md)。

## 2026-11-02：全量封面准备与 SDK 浏览门禁核查

219公共封面与固定SDK索引大小/SHA256逐项一致，共5,813,392 bytes，缺媒体描述0、未加入MP4；资源测试已改为核对完整集合，Flutter资产专项3/3、Python themed_media 5/5及diff检查通过。SDK Library列表/筛选/详情均拒partial，无公开开关，按边界停止；未运行本轮严格analyze、全量Flutter测试或APK构建。此前SF219是授权/目录数量，不代表实际UI浏览219；更正与源码位置见[报告](full-action-scope-2026-11-02.md#用户明确-219-浏览--211-规划后的-sdk-界面阻塞)。

## 2026-11-02：主线快进回读与全动作只读预检

用户反馈 +28 真机通过；本轮未新增设备验证。远端候选精确核对为 `d0c28c59976e32d58e4999b524bb40c60ee3672a`，main由 `0f507a3` ff-only到该提交并普通push，远端回读一致。SDK公共目录219、完整训练定义211、partial8；视频/封面描述缺失0，standing219张大小/哈希/首帧绑定通过。SF main亦219浏览/211规划，没有补齐8项。命中用户SDK缺项即停边界，仅文档检查，不重复analyze/全量测试或构建；+29验收未进行。见[完整预检与字段清单](full-action-scope-2026-11-02.md)。

## 2026-11-02：16:19 范围调整后全量通过

用户确认2倍字号超出支持范围，授权删除11条，具体用例列于[最终报告](sdk-shared-experience-completion-2026-11-02.md)，不是新增skip。验证/构建源`2d3070d375b546bad0dcc453b548ecb0ace818d9`；Flutter3.44.7/Dart3.12.2、SDK d4502f3与依赖锁不变。图片解码用真实async等待，训练断言等待SDK实际可点且播放状态已更新；safe-area辅助逐个选择纵向viewport并滚底，g12卡滚动后完成布局，图标检查仅限制App自己的控件。业务、音频、剂量与安全断言保留，App/SDK生产代码本轮未变。

定向集合：library19/19、iOS24/24、launcher44/44、正常键盘3/3均首轮通过。首轮全量在391通过/1失败时停止：ui_round1尚有一个同类入场等待遗漏，补齐后单文件13/13；同时补齐flow两处同类入口。随后严格`flutter analyze --no-pub --fatal-infos`为**0问题**，第二轮`flutter test --no-pub --concurrency=1 --reporter expanded`完整**428通过/1既有条件跳过**（6分21秒，可选VOICE_TIMELINE_OUT导出），无第三轮。Python相关代码未变，沿用前轮25/25，本轮未重复。

门禁通过后release构建56.4秒成功；交付APK45508800 bytes，身份com.ugk.hiplab/1.1.0/2028/release/arm64正确，**0 MP4、46公共poster**、CRC与签名通过，设备连续证书与原上传签名包运行负载一致。未进行安装/真机/视觉验收，不重写以前的失败记录。日志在`E:/AII-3D/hiplab-releases/sdk-shared-experience-20261102/completion-1619/`，包括`analyze.log`、未完成的`all-tests-pass1.log`、成功的`all-tests.log`、各定向日志和`build-release.log`；父目录`release-apk.json`保存制品回执。此后仅补文档，不重跑测试或构建。

## 2026-11-02：启动最小/断网通过，全量遇 SDK 布局问题停止

修复源`1f76e745da30133b8b38986d27c2f1b9e5df7791`，Flutter3.44.7/Dart3.12.2、SDK d4502f3不变。先只跑`hip_flow_test.dart`的`a no-key build hides AI training and usage entries`并给`_load`逐步临时日志，定位大型内置catalog的`loadString` isolate完成晚于断言；无网络等待或异常。改bytes解码后该条1通过，日志已移除。新增`hip_offline_startup_test.dart`：真实SDK媒体仓库、冷coach catalog、HTTP连接全部失败、prefetch开启且coach已配置，仍有tab-1/start-today，内置公共poster可解码，初始化/进首页0 HTTP client与0连接；1通过。

`flutter analyze --no-pub --fatal-infos`为0问题。随后`flutter test --no-pub --concurrency=1 --reporter expanded`执行到385通过/19失败；确认SDK问题后停止进程，**未全量完成、门禁未通过**。其中搜索2倍字号/320px键盘inset的单条诊断再次失败，完整FlutterError定位SDK`packages/ugk_trainer_runtime/lib/src/library/training_library_browser.dart:221`的Column，390×301约束下底部溢出20px。其余失败仍有launcher/图片解码等待和旧滚动容器辅助问题，未进一步修复或重复全量。未对2倍字号放宽断言/新增skip，未在App绕过SDK。

证据在`E:/AII-3D/hiplab-releases/sdk-shared-experience-20261102/startup-fix/`：`minimal-trace.log`、`minimal-fixed.log`、`offline-startup.log`、`analyze.log`、未完成的`all-tests.log`、`sdk-layout-trace.log`。临时错误日志与测试诊断注入均已移除。Flutter3.47.8/Dart3.13.7仅只读对比源码，没有另跑一套测试；两者asset阈值和机制一致，详见[版本结论](sdk-shared-experience-2026-11-02.md#启动定位更新2026-11-02)。Python沿用前轮25/25，本轮未重复；没有新APK、安装或视觉验收。

## 2026-11-02：共享体验接入两轮未通过，停止重试

固定Flutter3.44.7/Dart3.12.2、SDK d4502f35b1503d41cd782aa7fb3780c7f6591ad0，分支codex/sdk-shared-experience，基于main0f507a3。严格`flutter analyze --no-pub --fatal-infos`为0，Python全量25/25。`flutter test --no-pub --concurrency=1 --reporter expanded`首轮310通过/128失败/1条件跳过（4分29秒）；修复测试夹具、旧视频存在断言和主题插值后，第二轮仍有主界面finder为空，在234通过/116失败时依用户“两次仍卡住就停止”结束该测试进程。第二轮未全量完成，不再修复或第三次重试，最终门禁未通过。

首次release构建成功，46604271 bytes、ZIP内0 MP4；此包早于单练按钮/自测点击层修复及旧剪影退包，只有诊断用途。未构建最终APK、未重签/安装、未作真机或视觉验收。记录、失败表象、APK身份和日志见[本轮报告](sdk-shared-experience-2026-11-02.md)，不得用此前446/1的旧pin结果替代本轮。

## 2026-11-02：第 5 批 SDK 对话模块

**main合并后复核（2026-11-02）：** 用户批准后，本机main快进至`1b94fc3`并以`--no-ff`合入固定候选`c8cf82f`，合并点`9054932a982a9b41eaf540a4281af1e069c2f456`。两处文档冲突保留全部章节，按11月2日、10月27日、10月24日排序，iOS章节文字未改；冲突标记已去除，`git diff --check`干净。固定Flutter3.44.7运行合并后`flutter analyze --no-pub --fatal-infos`为**0问题**，`flutter test --no-pub --concurrency=1`为**446通过/1条件跳过**（可选VOICE_TIMELINE_OUT导出，5分25秒），与候选一致。日志在`E:/AII-3D/hiplab-releases/coach-chat-sdk-20261102/main-9054932/`。运行代码、测试及依赖锁与候选一致；后续只补文档回执，不重跑App测试或构建。release/1.0保留`1f9a172`，不tag、不商店、不重打APK。

固定 Flutter 3.44.7 / Dart 3.12.2、SDK `7d9be56`。严格 `flutter analyze --no-pub --fatal-infos` 为 0 问题；Flutter 全量 446 通过/1 条件跳过（可选语音时间线导出），Python 全量 25/25；新 pin 四段真实模型连续全部通过（零会话重置、零外围重试），计划卡片/含准备执行均为 587 秒与 313 秒，距目标 −2.17% / +4.33%，全部白名单且自然回放完整。APK 静态检查登记在[一页报告](coach-chat-sdk-2026-11-02.md)。浅深 10 张模拟状态截图供用户目视审阅，未像素比对；依用户最新要求不重复拍图、不做 ADB 或真机操作，旧数据真实界面恢复、训练与视觉验收待用户自测。旧锁屏等历史未验/失败项不改记通过。

## 2026-10-27：iOS 拒审后已向 Apple 回复

HipLab `com.ugk.hipinterlude` / 1.0.0 (20) 被以 4.3 和 4.2.6 相关问题拒绝；用户确认自主开发、同产品旧记录及仅推进当前记录，并授权对外答复。2026-10-27 约 08:59 已发送 Apple 要求的九项说明，消息列表回读为 2 条；当前仍显示被拒绝/问题未解决，等待 Apple 后续意见，**未重新提交或上传新包**。详细事实与证据范围见 [iOS 拒审记录](release-1.0/ios/review-2026-10-27.md)。

## 2026-10-24：Controller 获准合入后的核对

固定候选448f109已获用户明确同意并快进合入、普通推送main，远端回读448f109；release/1.0仍8880c71。本轮合入未改已验App代码、依赖和版本，沿用下方严格锁解析、分析0、完整454通过/1条件跳过及AI/接口44通过。后续提交仅为文档回执，验证改动范围、链接及git diff --check，不重复App测试或构建。[集成回执](sdk-conversation-controller-2026-10-24.md#主线集成回执)。

## 2026-10-24：CoachConversationController 候选

分支 `codex/coach-conversation-050-20261024`，基于main64daf6a。coach0.5.0/trainer0.2.3@d7e0b8f，UI0.1.1@3302d62；固定Flutter3.44.7/Dart3.12.2的 `pub get --enforce-lockfile` 成功，其余依赖未变。分析0、最终全量454通过/1条件跳过、AI专项44通过。按用户本轮范围不构建/安装/真机测试，旧手机身份和原生验收边界保持。[本轮检查与日志](sdk-conversation-controller-2026-10-24.md)。

## 2026-10-24：SDK 0.4.2 / 0.2.2 / UI 0.1.1

基于5c4d32e，三个tag均3302d62，正常在线pub get完成，固定Flutter3.44.7/Dart3.12.2；其余hosted锁定未变，App运行代码/测试未改。分析0，SDK原始套路卡溢出回归13项通过（320px/2倍字体、父约束、长剂量、RTL、深浅色及动画），App全量451通过/1条件跳过。按用户要求沿用原真机，不构建/安装新包。完整输出与结果见[本轮证据](sdk-tag-patch-2026-10-24.md)。下方451项分批结果为此前旧tag阶段。

## 2026-10-24：SDK 共用界面候选验证

分支 `codex/sdk-shared-ui-20261024`，运行源码 `429eaf5c0e952d60199ca95362bd3dd2880f8606`，版本 `1.1.0+21`。三个正式 tag 的 resolved-ref 见[接入报告](sdk-shared-ui-2026-10-24.md)。后续测试断言迁移不改运行代码或重建身份。

- `flutter analyze --no-pub`：0 issues。
- 全部测试文件最终覆盖 **451 通过 / 1 条件跳过**：未变化的 `hip_voice_pr24_review_test.dart` 10项在本轮首轮全量通过；其余全部文件在最后一轮重新执行，**441通过 / 1跳过，2分24秒**。分批结果覆盖完整集合，没有未解决失败。
- 首次全量为441通过/10失败/1跳过（6分38秒）。10项旧SDK界面/时序假设已迁移：新的准备标签、500ms淡出、舞台布局、再练welcome基线；OS中断仍活跃时不能手动恢复，等待ended后才能恢复。保留并加强计时冻结、两轮实际语音、疼痛、休息和幂等保存断言。
- AI与共用聊天专项41项通过：含SDK真实门禁、三轮澄清、同agent、原选项及顺序、防重复、取消/新对话/销毁/历史恢复失效、长20动作详情滚动、7模板门禁、无Key零请求/零UUID及入口隐藏。
- `flutter pub get --offline --enforce-lockfile`通过；Android arm64 release编译98.1秒通过，不传AI Key。首个试装包曾因只执行Dart pub get缺少Flutter生成的插件注册文件而启动失败，已保留失败证据；补正常Flutter pub get后重编译并验证APK内注册类存在，最终正常启动。
- `python tools/pose_hub_sync.py ... --check`：92匹配，0漂移；App目录归一化工具重复运行字节一致，46个快照ID未增删，运行时白名单仍45。
- `git diff --check`通过。真实训练、数据与服务释放另见接入报告最终真机段；iOS原生编译/安装、真实模型端到端、耳机/锁屏矩阵未执行，不以widget测试代替。

日志位于 `E:/AII-3D/hiplab-releases/sdk-shared-ui-20261024/`：`flutter-test-full.log`、`flutter-test-final-rest.log`、`flutter-test-trainer-final.log`、`flutter-analyze.log`、`android-release-build-final.log`。首轮失败保留，不改写为首次全量通过。


## 2026-10-24 16:05：iOS 1.0 已正式提交 App Review

复用 Hip Interlude（`com.ugk.hipinterlude`），**1.0.0 (20)** 已正式送审，Apple 回执与服务端状态 **WAITING_FOR_REVIEW（等待审核）**，提交 ID `5f1196c4-3a44-4105-9833-4175e0fca7c5`；保留手动发布，尚未公开发布。中英文商店资料、三尺寸各 6 张原生截图、无登录审核备注、隐私“未收集数据”及公开政策/支持链接均已完成。免费下载，供应保留中国大陆；Mac / Vision 兼容分发关闭。旧草稿 4 张失效 iPad 截图移除后通过提交校验。

编译源仍 e7ac083，上传 IPA SHA256 e2203298…，未重建；既有 442 过/1 条件跳、analyze0、验签及 TestFlight 安装结果保持。用户主动暂缓声音/耳机和完整锁屏专项，不改写为通过。此阶段只改发布文档及已授权外部资料，不改 Android、业务逻辑、SDK、依赖或版本。[完整回执和证据范围](release-1.0/ios/README.md)。

## 2026-10-24：Play 与 YouTube 远程回执

Playwright MCP正常复用用户授权的浏览器登录态，未读取/导出凭据。Google接收既有AAB20/1.0.0/min24/target36/3ABI；预览仅体积增大警告。中英商店与6张1.0原生截图保存，原图标AI标签保留；数据安全只读核对为不收集/不分享、政策URL正确。mediaPlayback声明保存实际视频URL，送审后应用内容显示无待注意声明。

YouTube不公开视频GRzBK2GvXRU已保存，版权检查无问题；匿名浏览器载入正确标题、约128秒元数据且无播放不可用错误。视频为原生API35实际画面与内部音轨，完整解码及抽帧检查通过，剪辑跳转与模拟器来源标明，不替代真机耳机。公开隐私页gh-pages7ecda06构建成功/HTTP200/正文SHA匹配。

北京时间13:09提交5项更改，活动详情确认ID2、Alpha1.0(20)、审核中。未取得Production权限或审核通过；平台要求12人连续14天、当前0人，用户选择稍后组织。此次仅文档与外部发布，不重跑Flutter、不重建；编译源4b56b82与原440通过/1条件跳过证据保持，旧D-34不改写。[回执与边界](play-store-release-2026-10-24.md)。

## 2026-10-24：1.0 基础版候选验证

源4b56b82 / SDK固定d193a70 / App1.0.0+20。`flutter analyze --no-pub`：0问题；`flutter test --no-pub --reporter expanded`：**440通过、1条件跳过，5分08秒**；`git diff --check`通过。新增回归验证无Key不访问远端模型/目录、不为请求加载UUID；保留现有AI入口与本地预设回落。冻结Pose-Hub lock check为92匹配/0漂移。

release AAB编译183.9秒成功；签名证书与旧上传证书一致，bundletool validate、non-debuggable、包名/版本/min24/target36、单一mediaPlayback前台服务、实际权限核验通过。最终权限另含播放依赖ACCESS_NETWORK_STATE与应用自有signature动态接收器权限，已补入声明；没有POST_NOTIFICATIONS、录音、定位等敏感权限。ELF16KB/BundleConfig PAGE_ALIGNMENT_16K及universal APK zipalign16KB通过，非16KB真机运行证明。缺key.properties时Gradle dry-run明确拒绝release构建并恢复本机配置，原密钥不动。

同AAB派生universal APK安装原生API35模拟器，冷启动和当前截图已采集；完整运行「久坐提醒·椅边」4动作短训练，界面自然完成4/4、3分钟；后台媒体会话PLAYING，锁屏Asleep期间mediaPlayback服务保持，未唤醒前训练已自然结束，服务/训练通知和媒体会话均已移除。App日志无FATAL EXCEPTION。模拟器以no-audio启动，此证据不声称人耳听音或真机耳机通过。2026-10-24用户表示App已都测试通过，作为用户报告保留，未据此虚构新AAB同包耳机日志。旧D-34失败历史保留，iOS未验。所有新日志、截图、APK/AAB在非C盘交付目录，不进Git；不访问Play后台。[声明草稿](release-1.0/play-declarations.md)。

## 2026-10-21 10:47：本轮复核记录合并确认

用户明确“推进合并”。fetch 后本地与远端 main 均为 cb7ae4f；来源 `354d0f12be52109ebeca5a02969cc478ba94b492` 仅修改六份复核文档，diff 检查通过。`git merge --ff-only` 后与来源树逐字一致，普通 push 成功，`git ls-remote origin refs/heads/main` 回读同一完整 SHA。以下本轮检查继续绑定原 App cb7ae4f / SDK d193a70；合并及回执不改运行代码，未重复测试或构建。下文“留审阅分支、未合 main”保留为授权前快照，当前合并事实以此处为准。

## 2026-10-21 训练包接力复核

本轮在 `codex/verify-ugk-trainer-20261021` 重新执行本机检查，来源为 App `cb7ae4f2c50ce40243dbba0537ec0fa1aefdb637` 与固定 SDK `d193a703e3a8bef6d41e7705a55ae250e23e6a69`（coach 0.1.3 / trainer 0.1.4）。测试期间仅补本文等复核文档，运行代码、依赖和测试没有变化。工具为 Flutter 3.44.7 stable / Dart 3.12.2。

| 检查 | 本轮实际结果 |
|---|---|
| `flutter pub get --enforce-lockfile` | 成功，pubspec 与 lock 无变化；两个 Git 依赖解析同一固定来源 |
| `flutter analyze --no-pub` | No issues，7.5 秒；日志 `build/trainer-recheck-20261021/analyze.log` |
| `flutter test --no-pub --concurrency=1 --reporter expanded` | 440 项全部通过，0 失败、0 跳过，5 分 10 秒；设置 `VOICE_TIMELINE_OUT`、`VOICE_LANG=zh`、`VOICE_ROUTINE=A` 后包含原条件导出项；日志 `build/trainer-recheck-20261021/test.log`，时间线 `timeline-zh-A.json` 位于同目录 |
| 依赖来源 | fetch 后 SDK main 为 09a392b，d193a70 是其祖先；两者训练包 tree 同为 `f34eb764eb26fe54ffefbde64c6da8346d36dcf9`，保留现有合法固定引用 |
| 原有语音测试保留 | `99fcc83..cb7ae4f` 的 `hip_voice_test.dart`、`hip_voice_playback_test.dart`、`hip_voice_android_fix_test.dart`、`hip_voice_android_timeline_test.dart`、`hip_voice_pr24_review_test.dart`、`voice_timeline_export_test.dart` 六文件差异为空 |
| 接口及唯一服务 | 生产 `TrainerPlayer`、疼痛/感受插槽、SessionResult 保存及业务保留边界符合交接；App 无旧服务类/通道；[逐项证据](ugk-trainer-adoption-2026-10-20.md#2026-10-21-接力复核本机检查真机暂缓) |

### Web 核心功能（本轮实际操作）

按用户“可以先用 Web 测试”“核心功能验证通过就行，现在还在功能开发阶段”执行后收束。E 盘忽略目录中的临时 Web 壳编译真实 `lib/main.dart`；58 个 lib 文件及 pubspec/lock 与工作区逐字节相同，与 cb7ae4f Git blob 仅行尾归一差异。资产通过 E 盘 junction 使用原文件，保持真实 HipStore / SharedPreferences / JustAudio，不注入业务状态或 AI 凭据；HTML 仅启用 Flutter 语义。`flutter build web --release --no-pub --no-web-resources-cdn --no-wasm-dry-run --target lib/main.dart` 成功，45.1 秒，本地 CanvasKit；保留既有 CupertinoIcons 字体声明警告。

Playwright 在新 origin `http://127.0.0.1:8769/`、390×844、正常字号操作真实按钮，结果如下。

| 核心路径 | 已观察结果 |
|---|---|
| 首启与自测 | 三项安全确认、身份选择、完整六项评分、左右分侧及 90/90 追问均可操作；结果与推荐显示，刷新后同一条自测仍在 |
| 单练与暂停恢复 | 仰卧蝴蝶主动开合调整为 3 次×1 组；暂停后倒计时 10 秒在 3.5 秒观察内不变，继续后 1/3→2/3→3/3，自然完成 1/1，保存 full=true、activeSeconds=28 |
| 再练与关节痛减量 | 同页“再来一组”产生新 sessionId；关节夹痛返回 continueEasier，显示 1/1 次和“幅度小一点”，自然结束并保存疼痛事件 |
| 休息感受与麻刺结束 | 推荐训练跳过首动作后进入休息；点“舒服”显示已记录，倒计时 10→8 继续。点“疼”并选麻刺后立即结束，显示 App 停止提示、本次感受；保存 full=false、endedEarly=true、0/6、nerve 事件及反馈，不伪装完整课程 |
| 保存与刷新 | 共 3 个唯一 sessionId、1 条自测；两次单练及提前结束均未增加打卡日。刷新前后两个 localStorage 键的原始值逐值相同，没有重复记录 |
| 浏览器错误 | 未观察到应用异常；只有临时预览站 favicon.ico 的两次 404。自动化中一次漏答 90/90 追问造成按钮禁用等待、一次短动作自然完成造成旧 ref 失效，按新快照继续；不作为 App 故障或成功步骤 |

来源、构建、截图和原始存储留本机 `build/trainer-recheck-20261021/`：`web-source-identity.json`、`web-build.log`、`web-core-summary.json`、`web-{home,assessment-result,natural-complete,pain-end-feedback}.png`、`web-final-storage-{before,after}-refresh.json`、`web-console-final.log`。Web 媒体保留产品既有封面替身；这次未做人工听音、AI 调用或原生后台验收。核心范围已完成，不追加显示或系统矩阵。

本轮没有 SDK 代码修改，未重复运行 SDK 全量；训练包 tree 相同不代表锁屏冻结修复。用户明确“先不做耳机测试，现在没有真机”，故未运行 ADB、原生构建、安装或耳机锁屏课程，D-34 继续已知失败；历史 +17 单服务、数据保留及安装结论仅按原日期来源复用。日志与导出留 E 盘 Git 忽略目录，不代表远端备份。本轮仅在审阅分支保存复核记录，不自动合入或推送 main、不递增版本或上传商店。

以下为此前各阶段验证历史。

**已获同意，两个main均已合入并推送。** 2026-10-21用户明确“合并并推送，保留锁屏已知问题”；SDK main为d193a70（PR #2已MERGED，00:39:10），HipLab主线集成点691ace2（00:39:31）。已安装包保持0.3.9+17/79c172d、21原记录/4组/UUID保持；锁屏冻结仍是已知失败，由用户后测，不重建/重测、不改手机省电设置、不上传商店。[合并与边界](android-lockscreen-fix-2026-10-21.md#主线合并确认2026-10-21)。

以下按日期保留的候选、安装与失败段落均为历史快照，其中“当前”“未合main”“待解锁”描述当时现场；当前交付与授权以页首最新结论及对应台账为准。

**00:08失败阶段快照：0.3.9+16锁屏仍失败。** 00:07:47.193 Greeze冻结（关屏5分25.7秒），服务和started/mutedState:none音轨仍在、训练锁DISABLED；系统媒体会话栈为0。不能把正常音量修正记为锁屏通过。当前安全锁屏，待用户回来解锁后正常结束本轮；SDK正在补真实媒体会话与释放，main未合。[完整现场](android-lockscreen-fix-2026-10-21.md)。

**2026-10-21 00:02安装快照：** App38bce47/0.3.9+16固定SDK8fb0aac/trainer0.1.3；App439pass/1条件skip（3分39秒）、analyze0（6秒），训练包119/119及analyze0。APK签名/CRC/876资产/单服务、新AI编译配置和保留数据安装通过；当前8动作整节锁屏中，仅阶段音轨分类及用户听音正常，不先写通过。[本轮证据](android-lockscreen-fix-2026-10-21.md)。

**2026-10-20 新中转候选快照（+15当时运行源）：** App f8f0ec8、夹具ab963d7 / SDK8ef37a9 / 0.3.9+15。App最终439pass/1条件skip（5分19秒）和analyze0；SDK根168/训练118全过、两包analyze0。新入口真实主机完整计划31.279秒/5动作通过，前两次HTTP回落保留。手机保留数据安装、只新增UUID偏好、原数据保持且冷启动UUID复用；新AI36.595秒首轮生成8动作并保存为第4组，开练前19记录保持。该组扬声器整节锁屏失败：23:50:21.914 Greeze冻结并禁用训练锁，静音音轨仍started/clientVolume；亮屏恢复后23:53用户正常结束，结果528秒、6/8、full=false、endedEarly=true，记录增至20、4组保持，训练服务已退出。未合main。[本轮证据与失败边界](ai-relay-migration-2026-10-20.md)。

**2026-10-20 上一轮+14候选快照（当时状态）：** App f702164 / SDK7348f0c / trainer0.1.2 / 0.3.8+14，固定Git锁校验成功；SDK118/118（20秒）、analyze0；App新依赖全量429过/1条件skip（4分33秒）和analyze0（5.6秒）。Android35.4秒构建，签名/CRC/876资产/唯一包内服务通过；已保留数据安装并启动，9882字节偏好逐字节保持。+13原生失败保留，+14尚未开练；用户改为扬声器复测后要求暂用其他App，当前停止手机操作，待其通知。未合main，不把单测/安装当作原生修复通过。[第二轮候选](ugk-trainer-adoption-2026-10-20.md#第二轮修复候选已安装原生待复测)。

**2026-10-20 ugk_trainer分支首轮：** App7dd40b0 / SDK7a84dc0（trainer0.1.1），固定Git锁校验、analyze0、全量429pass/1条件skip（4分57秒），SDK111pass/analyze0。原语音129项专项及生产适配6例中英文时序、疼痛插槽2例通过。Android0.3.8+13构建/单服务/签名/CRC/876资产通过，已备份并保留数据安装；安装启动后7154字节prefs一致。实际锁屏中途失声、解锁恢复：系统Greeze冻结并禁用唤醒锁，**原生验收失败**，SDK修复后重测。首轮系统实际扬声器路由，不能记耳机通过。[完整现场证据](ugk-trainer-adoption-2026-10-20.md)。

**2026-10-20 PR25修复复审并合main：** 源8c985c4 / SDK26e3255，analyze0、全量414pass/1条件skip（6分47秒）；原6独立复现逐字节未改且6/6通过，作者8项新增回归通过；带令牌Android/Kotlin、APK身份和真实API13.695秒/7动作通过。用户随后明确授权推进，GitHub已MERGED；真机仍未验，无ADB/安装/听音。[复审与合并](pr25-reaudit-2026-10-20.md)。

PR25之前的已验安装基线为 **0.3.6+11 debug / arm64**，构建源 `9b22dccc2bf2ca269a67b408198b9e3e9dbb742b`，2026-10-19 23:15:53保留数据安装；F9编辑/键盘原生通过，正常播放与用户听音确认见上一轮记录。当前已安装0.3.9+17，锁屏仍未通过且已获准保留问题合main，以页首结论及文末证据绑定为准；旧包真机证据不推广为新功能通过。原66f5da0/0.3.6首轮及0.3.5+10试听、V-01～V-13等均按日期保留历史。

| 编号 | 范围 / 命令 | 已执行结果 | 证据与边界 |
|---|---|---|---|
| V-01 | `flutter analyze --no-pub` | 无问题 | 2026-10-17早期 App 代码基线，后续检查见按日期追加记录 |
| V-02 | `flutter test --no-pub --reporter expanded` | 49 项通过 | 规则、界面、内容资源边界；不代表原生视频全量验收 |
| V-03 | `python -m unittest discover -s tools/tests` | 11 项通过 | 媒体同步、copy-ready 来源/SHA、帧率与参数保护 |
| V-04 | `flutter build apk --debug --no-pub` | 成功，Gradle 约 27.5 秒 | APK 大小/哈希见[版本台账](version-ledger.md)；未验证正式签名 |
| V-05 | 真机 `adb install -r`、包信息、冷启动 | 0.1.1 / code 2 正常启动 | `build/android-update-20261017/install-verification.json` |
| V-06 | 安装前后及播放后数据对比 | 设置文件 609 字节逐字节一致 | `smoke-preservation.json`；备份含用户数据，留本机忽略目录 |
| V-07 | 真机原生 WebView 播放 | `hip-n-pelvis-circle.mp4`：1080×1080、8 秒、readyState 4、error null；1.5 秒内呈现帧 155→200，掉帧数 2 不增 | `player-probe.json`，查看首页与训练页截图；仅一条实际播放样本 |
| V-08 | 全部交付片与 App 引用 | 46 主片逐条来源 SHA 相同；另有 1 自测剪辑，共 47 对 1080 视频/封面；6 项自测为视频，20 张评分图未变 | `build/media-audit/assessment-hd-sync-audit.json`、制作批次 `app-sync-verification.json` |
| V-09 | Android 派生片 | 46 条完整解码、138 次首中末像素检查通过 | `hiplab-android-20261017-v2/verification/`；不替代人工观感检查 |
| V-10 | 动作原 QA 与母版 | 最终选版 46/46 PASS | 原批次 43 PASS / 3 REVIEW，后续三项修订通过；选版清单排除旧失败候选 |
| V-11 | 3D-Body 冻结源验证 `node tools/drill-anim/verify.mjs` | 159 规格 / 51 原 App 动作 / 13 人体固定源通过 | 原规格、人体和 QA 保持；见[制作记录](local-hd-render-2026-10-17.md) |
| V-12 | 制作工具回归 | 前期 22 项通过；后续来源/不可变性/覆盖规格相关 6 项通过 | 属于分阶段记录，不能相加宣称一次最终全套 28 项通过 |
| V-13 | 初次接手截图测试 | 4 项通过，已查看四图 | 仅 0.1.0+1 接手阶段；高清更新后未重跑，不是当前版本的全量截图回归 |

具体实机过程见 [Android 记录](android-first-run-2026-10-17.md)。当前没有完成 iOS 构建/实机、商店上架、长期运行或 46 条手机端逐条人工观感验收。

## 媒体已知观察

最终坐姿体前屈使用 `hiplab-fix-fold-20261017-r3`：完整 240 帧原 QA 通过，穿透/触边为 0，左右手接触间隙在原门槛内。**63 条历史腕部可达范围警告仍保留**；原 QA 不把该警告计数作为失败门槛。不能写成“所有动作零警告”。抱膝 r1 与屈膝扭转 r1 各 240 帧通过且警告为 0。旧批次与 r1/r2 失败候选保留，未装进 App。

## 后续按改动验证

| 改动 | 必要验证 |
|---|---|
| 仅文档 | 相对链接、Git 差异和事实一致性；不重复构建 App |
| Dart 规则 / UI | 静态分析、相关回归和 Flutter 测试；涉及原生行为补真机 |
| 内容 / 媒体同步 | 来源和 QA、完整解码/参数、内容生成、资源边界测试；替换片真机播放 |
| Android 版本交付 | 构建、SHA、覆盖安装、版本回读、冷启动；核对数据和核心功能 |
| 计时修复 | 左紧/右紧/正常分配及暂停、跳过、疼痛降级回归；详见 D-01 |

检查失败先记录事实并修复；未完成检查留在事项台账，不能标“已验收”。本机 SDK 差异及 `--no-pub` 使用条件见[当前状态](current-state.md)。

## 文档管理建立检查（2026-10-17）

README、AGENTS 和 docs 共 14 份 Markdown 的 66 个相对文件链接均存在；版本 0.1.1+2、47 对视频/封面、47 条媒体元数据、当前 APK 字节数/SHA 和最终母版/Android 派生清单路径均已与本机文件核对。`git diff --check` 通过。本轮仅修改文档，没有重跑 Flutter、重建或重新安装 App；V-01 至 V-13 保持各自原始验证范围。

## 主线集成检查（2026-10-17）

#2、#1 合并前回读固定源和最新目标 SHA，合并后文件树均与已审 `14d754d` 完全一致。47 条视频 SHA 与元数据逐条一致，资源引用完整。状态跟进文档共 15 份 Markdown、76 个相对链接通过，`git diff --check` 通过；App、素材、工具、依赖锁与测试文件相对已验收 `35f2a97` 均无差异，沿用既有验证，无重复构建或安装。审核对象与回执记录在 `docs/mainline-integration-2026-10-17.md`。

## 0.1.2+3 图标与实机检查（2026-10-17）

代码基线 `4cf5ca7`：重新执行 `flutter analyze --no-pub` 无问题，`flutter test --no-pub --reporter expanded` 49 项通过，`flutter build apk --debug --no-pub` 成功（Gradle 18.8 秒）。29 个导出文件 SHA、20 张 density PNG 尺寸、4 份 Adaptive XML 及 APK 编译资源核验通过；旧/新 APK 签名验证及证书一致。

alpha≥8 阈值下，各 density 主体半径约 32.02–32.14dp，中央 66dp 安全圆越界数为 0；少量 alpha 1–7 的透明残留在圆外，如实保留。单色前景与彩色前景 alpha 各档一致。已查看圆形、圆角方形、主题色和 32/48/64px 预览。

Android 16 上 `adb install -r` 更新至 versionCode 3 / 0.1.2，冷启动正常、未观察到运行致命错误。安装前后、冷启动后和桌面检查后，1195 字节设置文件逐字节一致。查看 App 首页和 `com.miui.home` 桌面截图，确认新图标完整显示。证据位于 `build/android-icon-20261017/`；未切换手机系统主题，未做 iOS、商店或矢量验收。媒体及业务代码未改，本轮没有重复媒体解码与同步工具测试。

用户验收反馈（2026-10-17）：本次 Android 0.1.2+3 更新后，用户确认“测试通过了”。该反馈已登记至版本台账；其他独立待办的状态保持各自记录。本次台账更新没有新增自动测试结果或重新构建、安装。

## 第一轮修改检查（2026-10-17，`feat/polish-round1`）

沙箱 Linux，Flutter 3.44.7（`/workspace/work/hiplab-env.sh`），未做 Android 构建或真机安装。

| 范围 / 命令 | 结果 | 边界 |
|---|---|---|
| `flutter analyze` | 无问题 | 全仓库 |
| `flutter test --concurrency=1` | **82 项全部通过**（含 hip_flow 6、hip_ui_round1 13、hip_voice 23；main 基线 49 项全过，无基线遗留失败） | 不含 `test_screens/` 截图生成 |
| `hip_ui_round1` #4 | 360×740 文本 ×1.0/1.3/1.5、390×844 ×1.5，6 项自测底栏不重叠、无溢出 | 360×1.5 首页「我的髋部」卡 4px 溢出已真修：卡高随系统字号伸缩，空态内容 scaleDown |
| `hip_domain` 套 A 时长 | 断言更新为 350 秒 / 6 分钟 | 15 秒语音休息带来的预期变化，产品待定（D-12） |
| iOS `Info.plist` | `UIBackgroundModes = [audio]`，plistlib 解析通过 | 未在 iOS 上构建 |
| Android 常亮 | `wakelock_plus 1.8.1`，Gradle 配置 JVM 17 / compileSdk 跟随 Flutter，与 App 一致 | **未在本环境构建 APK**；下次 `flutter build apk` 时确认 |

需真机确认：视频首帧不闪、页面过渡流畅度、语音 ducking 与锁屏/后台（iOS 锁屏继续；Android 常亮期间继续、手动锁屏行为）、浅色主题观感。

## iOS 配置检查（2026-10-17，`feat/ios`）

沙箱 Linux arm64，Flutter 3.44.7 / Dart 3.12.2，**无 macOS/Xcode：未执行 `flutter build ios`、未上模拟器或真机**。分支含 #7、#8 全部内容。

| 范围 / 命令 | 结果 | 边界 |
|---|---|---|
| `flutter analyze --no-pub` | 无问题 | 全仓库 |
| `flutter test --no-pub --concurrency=1` | **104 项全部通过**（第一轮 82 + 新增 `hip_ios_test` 22） | 不含 `test_screens/` |
| `python3 tools/ios/check_ios_project.py` | OK | plist/xcprivacy/strings 解析，pbxproj OpenStep 结构、对象引用、文件存在、资源阶段、Bundle ID、iOS 15.0、仅 iPhone、AppIcon 尺寸与 1024 无 alpha、LaunchScreen 引用；不等于 Xcode 能编译 |
| `hip_ios_test`（iOS 目标平台） | 22 项通过 | 来电/拔耳机静默暂停、中断结束不自动继续、继续时 reactivate；4 种 iPhone 安全区（含反向验证探测器）；状态栏随主题；侧滑不能退出训练。系统音频行为用假输出模拟 |
| `test_screens/hip_ios_shots_test.dart` | iPhone 15 Pro / SE × 深浅主题共 72 张截图，已人工查看 | 叠加画的状态栏、灵动岛、Home 条为示意，不是系统渲染 |
| `player.js` 行为探针（Playwright Chromium，VP9 转码副本） | 静音自动播放、首帧事件、隐藏暂停、可见继续、宿主暂停后不自动播放均符合预期 | Chromium 而非 WebKit；未验证 H.264 / WKWebView |
| 合并 #8 后 `build_hip_content.py` | 生成结果与提交一致，无差异 | — |

需在 Mac/真机确认的项目见 [iOS 运行与上架说明](ios-setup-and-release.md#真机确认清单)。

## 第一轮 Android 集成验证（2026-10-17，本地未合并）

按 #7 → #8 → #9 固定源预演集成，三阶段分别无静态问题、85 / 85 / 109 项测试通过，debug arm64 APK 均构建并覆盖安装成功。最终代码 `c8057ad`，版本 `0.3.0+5`；安装前后同证书、数据逐字节一致。iOS 工程静态检查通过，没有 Mac 构建或 iPhone 实机结论。源 SHA、APK SHA 与设备证据见[本轮集成验证](android-round1-integration-2026-10-17.md)。

真机四足画圈训练：暂停时 1.5 秒帧数增加 0，继续后增加 46，确认恢复未再次暂停；蝴蝶式自测示范增加 46 帧，切换到青蛙式后增加 44 帧，均 1080² / readyState 4 / error null。首页到训练与动作切换保存录屏及接触表抽查，不代表全量逐帧或完整跟练验收。政策页和公开邮箱可见；中英语音试听观察到本 App AudioTrack / 焦点请求，未据此断言人工听感通过。

用户明确选择音乐实测稍后：ducking、恢复和实际听感仍待补测。安卓只屏幕常亮，手动锁屏后的后台语音不保证；前台服务另开 `android/foreground-audio`。四足画圈高亮、全量动作人工观感、完整紧侧跟练与 iPhone 系统行为仍保留待验收。授权后每步实际合并仍重新 analyze、test、build APK 与覆盖安装，不能把本轮预演当作远端已合并。

## 主干、单屏自测与 Pose-Hub 验证（2026-10-18）

已按用户新授权实际集成并推送 main。GitHub 于北京时间 **01:01:06** 回读 #7/#8/#9/#10 均为 MERGED，源码 `9ef59a1`；四个原 PR 源头均是 main 祖先。每步合并后的 analyze 无问题、Flutter 单并发测试 **85 / 85 / 115 / 116** 项通过，debug arm64 APK 各构建成功并同证书保留数据覆盖安装。源头、合并及 rebase 细节见[整合记录](mainline-pose-hub-2026-10-18.md)。

单屏自测 `6177cc1` / 0.3.1+6 已获用户“我看过了，验证通过”。演示固定 1:1、视频和海报 contain，点按暂停/继续；标题置顶、去顶部圆点和视频进度条，选项及底部控件随可用高度布局。Flutter 回归包含 320×568、360×740、390×844、768×1024，以及大字号和六项自测；不滚动、不裁掉底栏，下一项恢复播放。

| 检查 | 结果 | 范围与证据 |
|---|---|---|
| ZIP 与 92 个资源 | 40,153,961 bytes、指定 SHA 一致；dry-run → 同步 → `--check` 退出 0，92 matched / 0 drift | v0.1.0 冻结清单，上游 `ee9d7ea`；缓存/ZIP 在忽略目录 |
| 媒体元数据 | 46 视频与 46 封面尺寸、SHA 均一致；视频 1080² / H.264 / 30fps / 8s / 240帧 | 8 个媒体文件实际更新，其他 84 个已匹配；无文件名/时长变动 |
| 保留文件与生成器 | 自有剪辑一对 + 20 张 still 共 22 文件逐字节不变；`hip-content.json` 重生成无差异 | light 不在包内，未删除或重渲媒体 |
| 真机六动作循环 | 四足画圈、青蛙式、滑垫侧向滑、分腿体前屈、90/90 抬脚及 90/90 自测均跨完整循环，error null | 初步 APK `963db04`；帧数增加分别 343/318/308/311/310/312；**首帧另见下文** |
| 最终源码检查与 APK | `9ef59a1`：analyze 0；`flutter test --no-pub --concurrency=1` 116 项通过；APK 成功 | 0.3.2+7 debug arm64，最终修复未在拔线后覆盖安装 |
| 原 H.264 浏览器回归 | 旧 CSS 红、修复绿；首帧 opacity 1 / transition 0s / readyState 4，跨循环、暂停稳定、继续推进 | `test/core/drill_media_first_frame_browser_test.cjs`，真实 Chrome；不代替 Android / WKWebView 合成验收 |
| 网页尺寸与交互 | 320×568、360×740、390×844、768×1024：正方形示范，选项/下一项均在屏内、无重叠，滚轮不改变答题页位置；六项切换、暂停/播放状态及结果页通过 | 仓库外临时 Flutter web 预览；网页视频是既有 poster stub；原生音频出现 `Platform._operatingSystem` UnsupportedError，未据此验收音频/系统行为 |
| 最终 APK 内容 | 92 个发布资源 + 22 个保留文件及修复后的 CSS/JS 均与源码一致 | 150,742,085 bytes，SHA 见[版本台账](version-ledger.md) |
| 工具与 iOS 静态 | Python 同步工具 11 项通过；`tools/ios/check_ios_project.py` OK | 未做 Mac/Xcode 构建或 iPhone 实机 |

原六段手机录屏逐帧复查发现 0.08–0.25 秒的交接变暗。`9ef59a1` 取消视频自身透明淡入，仅由 Flutter 海报淡出，Chrome 回归已通过。用户明确拔手机并改用网页测试，故 **Android 原生首帧最终复验待补**；不把解码正常或网页探针当作无闪验收。此前约 0.8 秒的口头估计已由逐帧时间校正。

测试结束恢复 5 分钟选择；只撤回测试生成的当天打卡，重启后原 1356 bytes 偏好逐字节一致、SHA `74f83f14c7ef77da8cdf08e6886a5401ee86aa325a7f653f68a3fea5b6b07c21`。证据位于仓库外 `E:\AII-3D\hiplab-releases\mainline-20261018`。音乐 ducking 按用户选择稍后；完整紧侧跟练、Android 手动锁屏后台、iPhone 系统行为继续保留待办。本轮没有新 Play 上传或 Console 状态回读。

## 语音播报审计检查（2026-10-18，`fix/voice-audit`，叠在 `feat/ios` 之上）

沙箱 Linux arm64，Flutter 3.44.7 / Dart 3.12.2，ffmpeg 7.1.5，edge-tts 7.3.1；**无 macOS/Xcode、无真机：iPhone 截断修复只经假平台单元测试验证，需真机复听**。详见[语音审计](voice-audit-2026-10-18.md)。

| 范围 / 命令 | 结果 | 边界 |
|---|---|---|
| `python3 tools/voice/audit_voice.py --raw`（分 10 片后 `--merge`） | 修复前 264/488 不通过（响度 197、真峰值 64、尾巴过短 41、长度不一致 21、manifest 偏差 21；截断/句中静音/骤降 0）；**修复后 0/488** | 对照同文本 edge-tts 原始输出；数据在 `docs/voice-audit-2026-10-18/` |
| 修复后响度 / 峰值 | zh -16.2…-15.9、en -16.5…-15.9 LUFS；真峰值 ≤ -1.2 dBTP | 循环到 ≥3 s 测量 |
| `flutter analyze --no-pub` | 无问题 | 全仓库 |
| `flutter test --no-pub --concurrency=1` | **115 项通过、1 项按设计跳过**（iOS 基线 104 + `hip_voice_playback_test` 11；`voice_timeline_export_test` 未设环境变量时跳过） | 沙箱单条命令限时 120 s，按文件逐个运行（12 个文件全部通过），不含 `test_screens/` |
| `hip_voice_playback_test` | 11 项通过 | 假平台模拟会话/播放器时序；不等于 AVAudioSession 真机行为 |
| `build_voice.py demo --lang zh --seconds 60` | 生成套 A 开头 60 秒混音（-17.1 LUFS 整段） | 仅混音示意，不经过 App 播放链路 |

真机复听清单见[语音审计 §5](voice-audit-2026-10-18.md#5-需要真机复听的条目)。

## 第二轮 UI 打磨检查（2026-10-18，`feat/polish-round2`）

沙箱 Linux arm64，Flutter 3.44.7 / Dart 3.12.2，基于 `feat/ios` `313b484`（含 #7/#8/#9）。**无 macOS/Xcode、无 Android 设备：未构建、未安装、未在真机看动画。**

| 范围 / 命令 | 结果 | 边界 |
|---|---|---|
| `flutter analyze` | 无问题 | 全仓库 |
| `flutter test --concurrency=1` | **116 项全部通过**（基线 104 全过，无遗留失败；新增 `hip_ui_round2_test` 12 项） | 不含 `test_screens/` |
| `hip_ui_round2_test` | 分段控件（深浅色）：滑块圆角 = 外圆角 − 内边距、选中无描边、切换中途滑块在移动、两个首页控件同尺寸同风格、沿轨道拖动可选；32 个图标描边/填充两态都有笔迹且不出 24 栅格、继承 IconTheme；主要页面不再出现 Material `Icon`；倒计时环 0% 顶部无点、50% 有弧；体检行内无媒体框、缩略图圆角与卡片同心；开始→播放页为容器展开且首页反向变化；Tab 按方向滑；右推进详情、iOS 左缘右滑返回；Hero tag 首页↔播放页、体检缩略图/标题↔自测页往返无报错 | 动画只能断言几何与类型，**观感与帧率需真机** |
| `test_screens/hip_ios_shots_test.dart` | iPhone 15 Pro / SE × 深浅主题 72 张，已逐张查看（无截断/溢出，对比度正常） | 叠加的状态栏/灵动岛为示意；**截图时不画阴影**（见下） |
| `test_screens/hip_icons_sheet_test.dart` | 图标总览与组件总览（倒计时环 0/35/80/准备 50%、开始按钮、圆形按钮、分段控件） | [图标/组件总览](images/polish-round2/icons-sheet.jpg) |
| `test_screens/hip_transitions_frames_test.dart` | 7 段过渡各 6 帧（展开、缩回、Tab 右/左、右推、返回、自测展开 + Hero） | [帧序列](images/polish-round2/transitions-frames.jpg)；帧按测试时钟均分，不代表真机帧率 |

截图说明：`flutter_tester` 渲染 `BoxShadow` 时不做模糊（画成硬边偏移色块，已用单独探针确认），之前浅色截图里卡片下的灰条就是这个伪影。截图脚本现在设 `HipColors.flatShadows = true` 不画阴影；App 本身不受影响，真机仍有柔和阴影。[改前/改后对比](images/polish-round2/compare.jpg)里“改前”仍带伪影。

**需真机确认：**
- 页面过渡与 Hero 的流畅度（120Hz ProMotion / 60Hz Android 各看一次），尤其“开始”容器展开与缩略图 Hero 同时进行时是否掉帧；
- iOS 左缘右滑返回：跟手、松手回弹/完成、与系统手势无冲突（目前仅“重新看安全提示”页是右推页；播放器/自测页本就禁止手势返回）；
- 分段控件拖动与轻触觉（`HapticFeedback.selectionClick`）；
- 浅色主题真机阴影观感（截图里看不到阴影）；
- 倒计时环每 100ms 重绘一次是否足够顺滑（如有阶梯感可把播放器节拍提到 33ms）。

## 第二轮主干集成复核（2026-10-18）

固定原 main `12f143868959187047ff7f7aaeff9f469dca0039`；#13 `d2e0286ffc0e402e0ddf0f80426536dc7192bca7`，#14 `217e058061325244de74f3155287b673e3247a57`，目标均 main。

| 检查 | 结果 | 限制 |
|---|---|---|
| PR #13 | analyze 0，136 pass / 1 skip；23 targeted 通过 | 导出测试未设置 VOICE_TIMELINE_OUT，未执行导出 |
| PR #14 初次合入 `4c563f9` | analyze 0，153 pass / 1 skip；APK 构建通过 | 后续控制语义及 33ms 更新另按 `162a4e6` 检查 |
| 独立素材 | 488 条，0 失败；UTF-8/cp936 报告往返通过 | 未重跑 --raw；一位小数 −1.2 不等于严格≤−1.2，实际 TP 门槛≤−1.0 |
| 行为检查源 `162a4e6b78a8640d367cac13ef5e1ae6cfa9b33a` | analyze 0；Flutter 156 项通过、1 项按设计跳过 | 不自动扩展到之后的代码变动 |
| 最终 APK | `1b35657dec153741e25ca095ac2764b18d14ac29` / 0.3.3+8；151,888,384 bytes / `9ec9dbe4df19f625f38ffabb6448c479525b21dc138c60e8ca16e23afa688506` | 未装手机；包名 com.ugk.hiplab、versionCode 8、预期 debug 证书及 488 条语音 / 92 个 Pose-Hub 资源 / 22 个保留文件核验通过；内容重生成无变化；Python 11 项及 iOS 工程静态检查通过。最终构建 26.96 秒，未安装手机 |

临时独立网页预览在 320×568、360×740、390×844、768×1024 上检查正方形示范区、按钮 bounds、无滚动、六项自测及结果完成；点按暂停/继续、键盘、分段拖动、快速 Tab 和训练暂停/继续通过。预览使用 silent-voice fixture 与 poster stub；普通 DOM locator 仍因 Flutter semantics root 空白而超时，保留失败证据。坐标 page.mouse 操作通过且未使用 force；原生 widget hitTest 回归通过。这不构成原生媒体、H.264、系统音频或正式 Web 支持验收，也不据此诊断透明旧页遮挡。倒计时改为 33 ms tick；Chrome 18 屏的 17 个相邻环区域中，完全相同对数由旧 100 ms 的 5 对降至 0 对，采样约 47–79 ms，不代表真机帧时或帧率

本轮没有 ADB、Android 原生复验或 iOS 系统行为新结论。详见[第二轮集成记录](round2-integration-2026-10-18.md)。

## Pose-Hub v0.2.0 接入验证（2026-10-18）

ZIP 39,151,634 bytes / `f422c051eab2b4e973fe637d5f2a3dec07207e21b960f10800efe77dd317c772`；下载云端冻结 manifest SHA `76be4160b48f1a8d658d558b30418fe11e686a241bdfd63d2b7ee8fa45012889`，均核验，安全解压92文件完成。

| 检查 | 本轮实际结果 |
|---|---|
| dry-run → sync → check | dry-run 92项计划；首次92 copied；check 92 matched /0 drift；重复同步0 copied |
| 46 视频 / 46 封面元数据 | 本机92文件大小/SHA全匹配；46视频H264/yuv420p/1080²/30fps/无音轨，11220帧；完整CPU解码通过；46封面均540²JPEG |
| 自有剪辑 /20张 still | hip-supine-cross-demo.mp4/.jpg +20张自测still，共22文件SHA保持 |
| 内容重生成 | 来源metadata更新后重生成hip-content.json逐字节不变；时长与poster_time均保持；旧来源完整快照及prior数组保留 |
| analyze | exit 0，无问题 |
| Flutter | 单并发156通过、1条件跳过（未设置VOICE_TIMELINE_OUT），exit 0 |
| Python | 本轮未重复；上一轮11项已通过，Python工具逻辑未改变 |
| iOS 静态 | 本轮未重复静态检查，ios/文件未改；Mac构建与iPhone仍待验 |
| APK 内容 / 身份 | 包名com.ugk.hiplab、versionCode9/versionName0.3.4、既有debug证书匹配；包内92新素材、22自有文件、488语音及共享播放器与源码匹配；未安装 |
| 临时网页 | Chrome实际共享player.html/player.js，青蛙式、90/90、抬脚、四足画圈、臀大肌、屈髋肌测试共6动作：首帧事件/opacity1/contain、至少一次循环、暂停无时间漂移和恢复通过，截图已查看；独立App预览换入新封面，320×568/360×740/390×844/768×1024正方形示范、按钮完整与无滚动、6项自测和结果完成通过。App预览仍为poster stub+静音fixture；键盘启用可访问性后坐标操作，非原生验收；未证明原生无黑闪或系统音频通过。 |

未登记结果不能视为通过。网页不等于 Android / WKWebView 原生合成、音频或 iPhone 验收；没有本轮 ADB。详见[Pose-Hub v0.2.0 接入](posehub-v020-integration-2026-10-18.md)。

## 指定媒体分支复核与合入后构建（2026-10-18）

`media/pose-hub-v0.2.0` 起于 `bb828be`，接入已推送成果后按本次要求将 sync 单文件保持为原基线逐字节一致，再快进合入 main。`1a1657d` 与已验证的 `03c3b5b` 在 `lib/`、`assets/`、`android/`、`ios/`、`pubspec.lock`、共用版本、媒体 lock 和 manifest 上无差异；未升级依赖。同步工具正文与发布提交 59fb7b9 相同，保留原 ee9d7ea 来源注释。

合入/推送后重新 `--check` 为 92 up to date / 0 drift，并重新构建 debug arm64 APK，exit 0，17.42 秒。包名/证书/92 媒体/22 自有文件/488 语音再次核验，APK 字节与上一份相同；来源及路径见版本台账。沿用同一运行内容已通过的 analyze 0、Flutter 单并发 156 pass / 1 条件 skip，以及四尺寸单屏正方形示范、无滚动、六项自测和结果、实际共享播放器六动作循环/暂停恢复记录；没有重复声称新执行全套测试。原生合成/听感与本轮 v0.2.0 iPhone 验收仍待补。


## Android 最新版安装与启动（2026-10-18 17:15）

用户重连真机并要求先安装最新版。2602BRT18C 从 0.3.2+7 保留数据覆盖更新至 0.3.4+9，`adb install -r` 成功；新旧 APK 签名一致，设备版本及前台进程均回读确认。安装后和首次启动后，1356 字节偏好分别与安装前备份逐字节比较一致；备份 tar 可读取，未清数据或回写偏好。冷启动 Status ok / 1677 ms，首页截图已查看，当前进程 crash 缓冲未见 FATAL EXCEPTION。

本次未点击训练、自测或设置，不把安装成功扩展为原生首帧、循环、完整语音、ducking、锁屏或 iOS 验收。此前“手机拔线未安装”是该阶段历史，本次安装事实以本节及版本台账为准。证据 `E:/AII-3D/hiplab-releases/android-install-20261018-171428/` 留本机。

## Android 静音场景语音修复（2026-10-18）

修复前试听轨道为 SONIFICATION 且被 streamVolume/portVolume 静音；修复后 MEDIA / SPEECH 活跃轨道无静音标记，手机铃声仍静音，用户确认“已经能完整听到了”。新增2项旧红新绿回归；适配层8通过，全套analyze0 / 158 pass / 1条件skip，debug arm64构建通过。0.3.5+10覆盖安装、启动、试听后偏好1355字节均与安装前当前备份一致。完整课程、长句、背景音乐ducking和系统矩阵没有因此标通过。证据及版本身份见[Android 静音模式语音修复](android-voice-media-routing-2026-10-18.md)。

## 浅色 / 深色样式核对（2026-10-18，main a60b623）

本轮为样式审查，未修改 App 代码、版本、依赖或安装手机。独立网页预览重新构建成功，33 个 lib/ Dart 文件与当前主线一致（入口仅注入静音语音）。390×844 实际查看安全引导、今日首页、进度/语音/外观、自测列表与选中态、浅色六项自测/补充选项/结果/路线弹层、播放准备/暂停以及隐私政策；主题 dark→light→dark 后缓存页配色更新。

确认待完善：① 首页时长/场景共用 HipSegmented 的 standalone 浅色特例没有浮起滑块阴影；② 隐私政策仍用默认 AppBar，返回图标、标题与共用 HipTopBar 不一致；③ 浅色部分绿色小字对比偏弱（jade 对白底3.204、选项浅绿底2.814，建议小字用 jadeDeep）；④ 引导/设置底部12px运动说明使用 faint，对浅色背景2.390，建议用 muted。自测选中边框/勾选/补充选项、方形示范及单屏布局存在；深色媒体舞台为既定素材约定，不计为遗漏。

本机完整报告与17张接受截图：`E:/AII-3D/3D-Hip/build/theme-audit-20261018/report.md`；颜色计算/源码比对：同目录 `audit-data.json`。均在忽略目录，未备份到远端。11/19截图未达稳定状态，不作缺陷证据；浅色播放页用12。网页使用海报stub/静音语音，未覆盖原生视频/声音、全部系统字号与屏幕尺寸、深色整页结果和完整无障碍检查，不替代此前待补的真机验收。本轮不新增版本、不重打APK。

## 0.3.6+11 样式修复复查（构建阶段，2026-10-18）

此前样式审查中的4项已完成代码修复：浅色首页浮起滑块、隐私共用顶栏、浅色绿色小字、底部说明。源码 `66f5da034c0cdac3341f3e80a57e3ddae5f95dce`。analyze 0；158 pass /1条件skip；隐私专项8通过；四尺寸网页自测选中态完整单屏；新debug arm64 APK构建及包名/签名/资源SHA核验通过。当时尚未安装，19:29安装结果见下一节；不将旧0.3.5+10试听确认当作本版真机验收。详细范围、产物和未验边界见[样式修复记录](theme-polish-2026-10-18.md)。

## 0.3.6+11 Android 安装复查（2026-10-18 19:29）

设备回读0.3.6+11，HipLab处于resumed，冷启动首页和浅色浮起滑块原生截图已查看。当前1356字节偏好与安装前一致；数据tar备份可读。没有执行训练/自测/试听或主题切换，完整功能及iPhone验收仍保持此前待验范围。报告及截图：`E:/AII-3D/hiplab-releases/theme-polish-20261018/install-20261018/`，用户数据和截图不入Git。

## 转场质量返工（2026-10-18，分支 fix/transition-quality）

基于 main `ee83628`。新增逐帧捕获工具（widget test 60 fps 截帧 + 拼图/MP4），14 个转场修改前后同场景录制并逐帧审阅，缺陷与修改见[转场审计](transition-audit-2026-10-18.md)。`flutter analyze` 0；全量 165 pass / 1 条件 skip（main 158 + 新增 7）；四尺寸单屏自测回归包含在全量内通过。仅在沙盒无头环境验证；未构建 APK、未安装手机，GPU 掉帧、原生视频视图参与容器变换、iOS 右滑手感待真机按审计文末清单验收。未合入 main。

## 按钮轻拟物统一（2026-10-18，分支 feat/tactile-buttons）

叠在 `fix/transition-quality`（PR #17）之上。从设置页分段控件选中块提炼共享材质 `HipTactile`，统一主 CTA、「开始」、次按钮、圆形图标按钮、分段选中块、底部 Tab 选中态、卡片内小按钮、播放器反馈按钮，去掉全部彩色外发光，详见[按钮样式审计](button-style-audit-2026-10-18.md)。`flutter analyze` 0；全量 178 pass / 1 条件 skip（165 + 新增 13）；四尺寸单屏自测回归在全量内通过；「开始」容器展开首帧截图与新按钮逐像素一致（新增测试）。仅沙盒无头 widget 测试截图验证；未构建 APK、未安装手机，真机渲染与掉帧待查。未合入 main。

## 0.3.6+11阶段收束检查（2026-10-18）

基线`9c0401505ed6d9e56715f3cce307406e38f68ed1`→入场`ee83628aaa1b9a53d545bbb061a0e203a6db8c40`。只读Preflight核对canonical、完整状态与证据源码后修正文档；`66f5da0`之后运行代码/测试/配置未变，复用前序analyze0、158pass/1条件skip、APK与19:29安装证据，不把本次文档HEAD说成新构建。本次必要检查为链接、事实、Git差异及完整状态；未重跑Flutter或操作手机。范围与依据见[阶段收束说明](theme-polish-2026-10-18.md#阶段收束2026-10-18)。

收束文档独立复核通过：9份Markdown未发现剩余确定finding，147处相对链接目标为Git已跟踪路径，选中文档内锚点匹配；代码相对已验证源`66f5da0`保持，完整工作区仅本轮9份文档和两项原有未跟踪文件，后者不纳入提交。

## 动作素材浅/深主题（2026-10-19，分支 feat/themed-action-media，沙盒，未合并、未安装）

| 范围 / 命令 | 结果 | 边界 |
|---|---|---|
| `flutter analyze --no-pub` | 0 问题 | |
| `flutter test --no-pub` | 198 通过 / 1 条件跳过（新增 `hip_action_media_test.dart` 7 项） | 含清单 SHA-256 逐文件校验、两主题素材齐全、主题切换重建视频 |
| `python3 -m unittest discover -s tools/tests` | 15 通过（新增 4 项） | `build_themed_media.py check` 通过：47 视频 + 47 封面 + 20 自测图 |
| `test_screens/hip_shots_test.dart` 深/浅截图 | 深色 18 张与改前逐像素一致；浅色无深色块 | `large text 1.5 on 360` 改前即溢出，未改 |
| 原生 WebView 播放浅色视频 | **未执行** | 沙盒 Chromium 无 H.264；待 Android/iOS 真机 |

## Windows复核修订：中途反向Tab连续性（2026-10-18）

按用户直接修复并推进合并授权处理F1，第1轮将Tab改为共享时钟，每次重定向从实际当前透明度和位移采样；保留持久slot、fade-through及媒体/焦点/语义策略。新增4项：零时间透明度与位移连续、三Tab快速重定向、减少动画无漂移。此固定分支analyze0，独立全量169pass/1条件skip；相关22项targeted通过。原失败证据在PR #17评论6251531461，修复后的组合Android原生验证与#18一起完成，不将本段写成已安装结论。未改依赖、lock、版本或商店配置。

## Windows复核修订：共享滑块按压（2026-10-18）

用户已授权修复后直接合并。F2第1轮让分段控件显式持有共享滑块按压/拖动/取消状态，滑块和文字同步缩放；减少动画仅保留材质下沉。材质释放与缩放统一180ms。新增9项回归覆盖正常/减少动画、移出/取消、拖动取消、纵向滚动、键盘选中语义、180ms释放及两个开始入口实际首帧。相关34项通过；组合analyze0、全量191pass/1条件skip（F1新增4、F2新增9），原审核6项现由日常回归覆盖。gallery 45/60模拟区改为小号分段与实际试听按钮，先前深浅2项生成通过。未改依赖、lock、版本或商店配置；后续组合APK与真机检查另记，不将本段当作已安装。

## PR #17/#18修复后验收与合并（2026-10-18）

初审两项P2及2pass/4fail保留为[历史审核](https://github.com/mhgd3250905/HipLab/blob/be782b74b3eefe782803aebf26b5224c33c0c3d7/docs/pr17-pr18-device-review-2026-10-18.md)。F1/F2均首轮运行修复；#17独立analyze0、169pass/1条件skip，组合6dd16ed analyze0、191pass/1条件skip，合并main另生成深浅gallery2pass。新回归共13项，两个原失败类别已转通过；零时间Tab前后图相同，深浅/移除动画的原生分段持按有变化、松开回原像素。连续单指流采样、快速Tab录屏及播放中关闭抽帧完成，当前进程无FATAL/E/flutter标记。保留数据覆盖安装，用户偏好1356字节与原始相同；未新增自测/打卡，系统设置还原。main顺序merge e98d0f1/aac4b1d与已安装6dd16ed运行内容相同，仅文档不重构建。低端帧时、强光、新结果页/iPhone仍保持待验，不扩大旧结论。[逐项与证据](pr17-pr18-fixes-and-merge-2026-10-18.md)。

## 轻拟物有选择引入（2026-10-19，分支 fix/tactile-curation）

基于 main `6020d8e`。按[审美考据](tactile-design-rationale-2026-10-19.md)收敛 #18：只保留分段控件滑块（neutral）与首页「开始」（accent）两处轻拟物；底部 Tab 完全恢复 #18 前样式；主 / 次 / 圆形 / 卡片内 / 播放器按钮回到改前扁平外观（主按钮去掉 jade 外发光，浅色圆形按钮以细描边替代旧柔阴影）；删除 `HipChipButton` 与 `glass` / `flat` 令牌。新增 `hip_tactile_budget_test`（深浅两主题、首页 / 自测 / 进度 / 设置滚动，断言拟物只在分段控件内、accent ≤ 1、Tab 无拟物且实心 / 描边图标正确），该测试在 #18 版本上运行会失败（已验证）。`flutter analyze` 0；全量 194 pass / 1 条件 skip；四尺寸单屏回归在全量内通过；「开始」与「开始自测」按住→松手容器展开首帧连续性测试通过（第一轮直接退回 Material 按钮导致「开始自测」首帧快照丢失，第二轮改为共享 HipPressable 平涂面后通过）。仅沙盒无头验证；未构建 APK、未安装手机。未改依赖、lock、版本或商店配置；未合入 main。


## 动作节奏与语音 + 动作包 v1（2026-10-19，分支 feat/rep-rhythm-voice）

基于 main `6020d8e`，沙盒 Linux、Flutter 3.44.7（本地 `.dart_tool/package_config.json` 的 `shared_preferences_android` 路径改为 lock 对应的 2.4.28，不入库；未改 pubspec.lock/依赖/版本号）。详见[节奏审计](rep-rhythm-audit-2026-10-19.md)与[动作包规格](action-kit-spec-v1.md)。

| 范围 / 命令 | 结果 | 边界 |
|---|---|---|
| `flutter analyze --no-pub` | 无问题 | 首轮 3 error + 1 warning：测试共享函数名 `loadLibrary` 与 Dart 延迟加载保留名冲突，改名 `loadVoiceLibrary` 后为 0 |
| `flutter test --no-pub test` | **236 pass / 1 条件 skip**（main 191 + 新增 45：`hip_rep_rhythm_test` 33、`action_kit_test` 5、`hip_player_transition_test` 7） | skip 为 `voice_timeline_export_test`（需环境变量）；不含 `test_screens/` |
| `python3 tools/action_kits/build_action_kits.py check` | 0 问题（含 JSON Schema 校验，jsonschema 4.26） | 46 个动作包结构、Pose-Hub 冻结 SHA、语音齐全、每句话放得进相位窗口、路线引用与秒数 |
| `python3 -m unittest discover -s tools/tests` | 13 项通过 | 含 `test_action_kits.py` |
| 四尺寸单屏（320×568、360×740×1.5、390×844、430×932） | 准备 + 休息期无溢出，在全量内通过 | 修复 360×740×1.5 “下一个”卡片训练期溢出 8 px（main 已存在） |
| 语音新条目 `audit_voice.py` | 92 条中 1 条提示（`en/sec.66` 尾音偏轻，兜底条目） | 原有条目未重生成 |

未执行：APK 构建、真机安装与试听、iOS。画面与语音只对齐周期未对齐起点（播放器无重播/倍速指令），需真机按 PR 内试听清单确认。

## PR #19/#20/#21 Windows隔离组合复核（2026-10-19，早期检查；最终追加见下）

固定main `6020d8e`，原始三PR head与顺序组合见[审核报告](pr19-pr21-review-2026-10-19.md)。运行修复源 `e3fb1d31d3d490dbe46afe5f0461f6d273dba404`：四项缺陷均首轮修复——#19媒体按钮角色、#20切主题实际遮罩及首页展开起点色、#21疼痛减半不足完整一次。用户批准不足一次skip；7项新增默认回归覆盖语义、实际opacity/像素、颜色、短周期口令与播放器后续休息/反馈。组合analyze **0**、全量 **253pass/1条件skip**，最终Python **19项通过**（初验18，后补1项mutation回归）；条件跳过不计为通过。原始失败证据未改写。

46动作包的light引用已按媒体清单重建，其他JSON语义保持且使用LF；action-kit/themed-media检查通过。47条浅色视频真实ffprobe参数、字节/SHA、首尾角块检查全部通过，376角块均RGB238中性灰；两关键封面对应帧量化及sheet见报告。88条新增语音均可解码且时长与manifest匹配；`en/sec.66`后半偏轻9.8dB提示未豁免，不能把这些技术结果写成人耳跟练已通过。

构建期防漂移check新增比较poster_time_seconds与深/浅清单poster.timeSec；mutation测试仅在内存改变时刻，确认check退出1并提示重建。此工具补充不改变App或资产，已构建APK仍源e3fb1d3。两段原生录屏共698帧技术检查未发现全卡黑屏或中部单色空白候选，13+8逐秒样本及三原图未见明显额外偏色框或脱离圆角；只有native-theme-switch-playing证明切主题，另一历史命名片仅浅色播放。视频截图浅色240/238/240、深色17/15/19，不能声称等于Flutterstage或据模拟器色差重调素材。屏录可漏刷新，逐秒目视不是所有刷新帧验收；[相对证据索引](pr19-pr21-review-2026-10-19.md#原生录屏与边界)保留限制。

两份debug APK已构建，x64已在专用AVD安装，arm64未装手机；产物身份见[版本台账](version-ledger.md)。用户改用Android15/API35专用AVD `codex_hiplab_pr19_21_api35`（1080×2400，density420，WebView124.0.6367.219），host NVIDIA GPU、禁用Vulkan后已进行原生训练、切主题和休息反馈操作；旧 `codex_api35` 正式0.2.0包未覆盖，原手机记录未操作。模拟器已完成9个合成场景后按用户最新安排停止，现转Web复核，晚上再真机，**尚不能记为14项全通过**；完整原生矩阵和听音留待晚上真机，不用模拟器代替低端真机/强光/iOS。没有main合并或推送授权，完成验证后仍待本轮最后同意；未上传商店。

### Web交付追加（2026-10-19）

第五项为本地组合反馈按钮独立14px样式丢失主题字体，真实RenderParagraph回归先红后绿，c7def28首轮修复；最终analyze0、254pass/1条件skip。Python19及两媒体工具check通过。实际Chrome共用播放器51/51、重点循环暂停7/7、核心脚本1/1；88自测/追问+8结果四尺寸组合、完整深浅自测→结果→训练、设置和按压/减少动态/暂停/疼痛skip/快速Tab通过。最终字体增量深浅冷上下文360×740×1.5复核通过，休息起无新增字体请求。基线矩阵源e3fb1d3，仅字体增量在c7def28重测，详见[报告及证据](pr19-pr21-review-2026-10-19.md#本轮web复核按最新安排)。

按用户最新安排停止模拟器；Web采用合成存储、静音输出与封面替身，共用JS播放器另验实际H.264。保留语义locator父层拦截、启动Roboto网络、原生视频/声音/锁屏/性能待验边界；未宣称14项原生全通过。最终arm64候选未装手机，晚上继续真机；未合入或推送main。

## 用户真机简单测试追加（2026-10-19）

用户收到本轮c7def28 arm64 debug交付包后报告安装和简单测试通过；仅登记此范围。身份见[版本台账](version-ledger.md#用户真机安装及简单测试反馈2026-10-19)。本次没有Agent ADB、截图、设备版本/WebView回读或逐项测试证据；不推断现有记录保持、完整14项中英试听、原生切主题/退出、锁屏恢复、帧时/强光或iOS全部通过。

复用已记录的运行源`c7def2869b789357b303d69d66eb8c18a0a748ae`验证：`flutter analyze --no-pub` 0问题、默认`flutter test --no-pub`全量254pass/1条件skip、`python -m unittest discover -s tools/tests`19过、`python tools/media/build_themed_media.py check`及`python tools/action_kits/build_action_kits.py check`通过。2026-10-19本会话执行；c7def28至收束前HEAD`8d8cb9d168adf27c08e5bcd4c060979143877687`仅文档/证据delta，本次也只改文档，故原代码验证继续适用，不将其冒称在新文档提交重新跑过。构建命令为`flutter build apk --debug --no-pub --target-platform android-arm64`，构建及签名结果按其原source state引用，不重构建。

## 合并后验证适用性（2026-10-19）

GitHub已确认#19/#20/#21均MERGED，第一父链顺序19→20→21，merge为2b552fd/18bf4ce/b6fd55e；已推main业务集成点`b9646d4a15b4e3727d8e11ea5ee3106f0e396603`。运行/工具/测试/资产/配置与`c7def2869b789357b303d69d66eb8c18a0a748ae`逐路径diff为空，之后仅文档更新。因此复用该source的analyze0、254pass/1条件skip、Python19、两工具check和arm64构建，本轮不重复全量/构建。合并记录文档执行链接存在性与git diff --check；不增加手机、听音或性能验收结论。原4个未跟踪文件保留。

## PR #22 固定head审核（2026-10-19）

对象`a7992a6fd9367df749db49ab25b4aa8c21dfa9c0`，目标main `243a8128eabb8e955329d6ed015c559be963b988`，隔离副本执行Flutter3.44.7：analyze0、Flutter286pass/1条件skip、Python18pass、action-kit0问题、themed-media check通过；不是冲突解决后的组合验证。9条专项中，6条正确期望失败（复制剂量两条、紧侧间隔、多组面板、两条看放松），2条已知错误行为断言通过（重复单练音频失活、错误左侧提示），1条小屏键盘无缺陷通过。替换详情导航另修正复现控件定位后重跑，确认direction仍null。结论1P1+5P2需修改，7文件冲突；无原生/APK/手机操作，不将已有简单真机反馈算作本PR证据。完整复现、SHA、日志位置及检查范围见[审核报告](pr22-review-2026-10-19.md)。

## PR #22 f7271f6 修复复审（2026-10-19）

固定head f7271f6be2a838592f97768cb9cc6a815af48597，target243a812。E盘副本Windows Flutter3.44.7 analyze0、默认全量310pass/1条件skip、Python19、action-kit含jsonschema检查0问题、themed-media check通过。独立49步骤时长/相位、JSON往返和6种紧侧预算通过；新增播放器专项1pass（两轮自然完成/中断恢复）+1fail（F7多组疼痛减半漏skip，仍倒计时8秒）。原F1–F6已闭环，但F7及Android原生证据待补。无APK、ADB、手机或iOS操作，完整[复审记录](pr22-reaudit-2026-10-19.md)。

## PR #22 9fa0cc0 F7复核（2026-10-19）

对象9fa0cc09c085df619297c59c886c7bd836a98ff6，目标b12b0f5；E盘副本Windows Flutter3.44.7 analyze0、默认全量322pass/1条件skip、Python19pass、含jsonschema的action-kit0问题、themed-media和diff check通过。原独立播放器脚本2pass（F7旧失败变通过，F1自然两轮/中断恢复保持通过），领域49步骤及6种紧侧预算通过。F1–F7全部关闭，仍无APK、Android原生听音/中断/锁屏/保留数据升级或iOS证据。[完整记录](pr22-reaudit-2026-10-19.md)。

## PR #22 Android包准备（2026-10-19）

b12b0f5和9fa0cc0均enforce-lockfile pub get/debug arm64构建通过；两包CRC、既有debug签名、包名/0.3.6+11、16KB对齐通过，575音频/94视频逐文件与源一致。候选增量打包空洞经单个生成APK重建消除，最终174,483,026bytes。无源码变更，不重复已通过的322项测试。手机尚未连接，用户安排先备包；未执行ADB、安装、自测、训练或中断试听，iOS本轮未验。[完整身份与原生待验清单](pr22-android-acceptance-2026-10-19.md)。

## Android 语音播报修复沙盒验证（2026-10-19）

分支 `fix/android-voice-playback`，基于 main `d9338ea`，沙盒 Linux Flutter 3.44.7：`flutter analyze` 0 问题；`flutter test` 277 pass / 1 条件 skip（同机 main 基线 254 / 1，新增 23 项、改 1 项）；`python3 -m unittest discover -s tools/tests` 19 OK；`build_action_kits.py check` 0 problem（无 jsonschema）；`audit_voice.py` 570 条 1 条既有不合格（en `sec.66`，未改素材）。时间线复现前后对比见[Android语音记录](android-voice-playback-2026-10-19.md)。**未执行**：Kotlin/APK 构建、安装、真机听音、logcat——按该记录的真机清单由本机补。

## PR #22 Web补充验收（2026-10-19）

真实main.dart及38/46文件身份核对通过；非空旧12键迁移仅增2键、复制F刷新剂量保持/自然约60秒、搜索筛选、常规编辑、F3/F4、安全、F7单练与自定义、8轮中英单练计时/记录通过。独立实测新增F8/P2动作覆盖，故不合并。Web音频实际哈希显示循环初始口令，准确main基线也复现；内容未通过。21张360宽2.0字号深浅截图中主按钮可达，P3文字截断保留。全部证据226文件/94PNG/5WebM约20.1MB在E盘，手机/iOS未操作，未改实现或重跑全量。[完整表与边界](pr22-web-acceptance-2026-10-19.md)。

## PR #24 Windows独立审核（2026-10-19）

固定e3655e5与实际main fcffded；pub get enforce-lockfile成功、analyze0、277pass/1条件skip，debug arm64 Gradle20.6秒成功，新service/权限实际入包，debug签名/CRC/16KB对齐及575音频/94视频逐字节检查通过。独立手动暂停/真实D英文疼痛取消专项均失败；疼痛case替回main Queue/Controller通过。异步音量专项head失败，main Controller音量对照通过。另查实两项原生生命周期P2，无设备时序或耗电量实测。merge-tree仅verification.md冲突，未合并。未执行ADB、安装、锁屏/耳机/ducking或iOS；作者的旧PR22组合测试不冒充本轮执行。[精确链路、复现与日志](pr24-review-2026-10-19.md)。

## PR #22 / 2cc40e3 Android阶段复测（2026-10-19）

Windows锁定依赖/analyze0/335pass1skip；APK签名、CRC、16KB对齐、575音频/94视频逐字节通过，install-r成功且安装SHA匹配，原state JSON语义保持。真机F8主场景[B2,C]正确；F9删除动画内保存失败，独立150ms失败/1000ms通过。中文计次和保持各两轮新增记录准确、doneDays保持；保持第二轮后台约50秒前无第二条、回前台才入账，英文保持首轮锁屏也在唤醒才入账，持续运行未通过。实际听音、系统中断、ducking及剩余英文待补，当前安全锁屏需解锁；原字号/密度已恢复，原语音/主题待恢复。极大字号按用户新要求取消门槛。未将无日志错误或最终追上进度作原生全通过。[细节和证据](pr22-native-retest-2026-10-19.md)。

## PR #24 审核四项P2修复沙盒验证（2026-10-19 晚）

分支 `fix/android-voice-playback` 同步 main `6299a38` 后修 F24-1～4，沙盒 Linux Flutter 3.44.7：pub get enforce-lockfile 成功；analyze 0；`flutter test` 290 pass / 1 条件 skip；`build_action_kits.py check` 0 problem（无 jsonschema）；`build_themed_media.py check` ok；Python 19 OK；`git diff --check origin/main HEAD` 干净。新增 16 项回归测试，其中 14 项在 e3655e5 代码上失败或编译不过（另 2 项为守护项）（明细见[Android语音记录第二轮](android-voice-playback-2026-10-19.md)）。**未执行**：Kotlin 编译（无 Android SDK）、APK、安装、真机；补充复测点见同一记录。


## PR #24返回修复与#22组合验证（2026-10-19）

固定24=0ccef6b、22=2cc40e3、actual main=2d91688；组合5725c36。原暂停/疼痛取消/异步音量三独立专项均通过；新增0秒/7秒重播保活回归均先失败、修后通过；enforce-lockfile成功、analyze0、全量373pass/1条件skip，Gradle/Kotlin成功。APK证书连续、CRC/16KB对齐、575音频/94视频逐字节通过，ZIP空洞重打后最大间隙0。21:56:37保留数据安装且SHA匹配，升级14键JSON相同；中文h-squat 1次×1组两轮自然完成/再来一组通过、恰增2记录、其余数据保持、连续1天不变。两轮前台服务/CPU锁在、结束收尾后释放；用户正常听到/无播放异常。App PID日志383017bytes未检出播放/致命异常；自定义服务tag未采到，释放取dumpsys/Power快照。扩展系统矩阵按最新要求不再续测，iOS未验；F9仍待修，未合main。[完整报告](pr24-reaudit-and-pr22-integration-2026-10-19.md)。


## PR #22 a586de3 / F9返回复审（2026-10-19）

原独立150ms/1000ms保存两项通过；作者F9 8项+F8 5项+键盘6项，共21专项通过，组合9b22dcc全量387pass/1条件skip、analyze0、enforce-lockfile成功。Gradle41.8秒、APK签名/CRC/16KB对齐/575音频94视频逐字节通过。23:15:53保留数据安装、APK SHA与14键state一致。真机唯一项禁止空保存、ABC立即保存得[B,C]、BCA连删立即保存得[A]、立即取消提示并放弃保留存储均通过；另一组/10条记录/非组字段保持。新包正常字号首次/视频详情返回键盘真实出现；未认定硬件键盘或WebView根因。F9关闭，无新阻断，iOS及扩展系统矩阵未验。[全部来源与证据](pr22-f9-reaudit-2026-10-19.md)。


## PR #22 / #24 合入main核验（2026-10-19 23:32）

用户明确同意后核对远端main=ab1425b、候选=b33ed21、PR22=a586de3、PR24=0ccef6b均未变；两来源都是候选祖先。main快进b33ed21并push成功，GitHub两PR均MERGED。合入树与已验9b22dcc在lib/android/assets/pubspec/lock/tests无差异，沿用387pass/1skip、analyze0及原生F9/键盘与上一轮正常播放证据；本次仅合并与文档，没有重跑SDK或安装。文档diff --check及本地链接核对通过。[精确身份](pr22-f9-reaudit-2026-10-19.md)。

## PR22/24合并后文档收束：Preflight与证据绑定（2026-10-19）

收束scope仅为#22/#24合并后的入口、当前状态、版本/验证/事项/日志/工作流对齐；不改运行代码、依赖、素材、版本、商店配置或副本位置，不重跑原生/SDK矩阵。

- baseline `ab1425baeec1dd76a214652989864278434aa9a2`：本会话记录的main合并前起点，无另立基线ref；对象可解析且是收束前HEAD祖先。
- 收束前HEAD `cdbb14c5bc973885aeb507f063144a0db9a7d411`；有限delta为43提交/65路径，36修改/29新增，分类android3、lib22、test25、test_screens5、docs10。
- canonical discovery从根AGENTS.md、README.md一跳确认：docs/README.md为索引，docs/current-state.md为当前事实，docs/version-ledger.md为交付事实，docs/verification.md为检查记录，docs/development-roadmap.md为事项状态，docs/development-log.md为关键成果，docs/development-workflow.md为流程；pubspec.yaml提供版本事实。已标明日期的旧轮段落按archive/history使用，不能覆盖当前摘要。
- 归属：完整porcelain/all结果为tracked/staged/unstaged/deleted/renamed均0，untracked4（.playwright-cli与.playwright-mcp各2）。它们已在阶段前记录为旧网页审核产物，路径集合本轮保持；未读内容、未暂存、未清理。65路径已提交delta来自获准集成的PR22/24及本机审核/合并文档，后续本次文档修改由本Agent负责。
- findings：根README/工作流基线仍指旧阶段，交付及验证页首仍指66f5da0，当前限制仍称Android前台音频未完成，事项表复用了D-25并留待审状态；已对齐到合并事实，Android问题统一D-30，旧转场D-25和日期快照保留。

| 既有证据命令 / 观察 | 结果、来源与source state | 对当前树的适用性 |
|---|---|---|
| `flutter pub get --enforce-lockfile` | 本会话2026-10-19 Windows，成功；最终组合源9b22dccc2bf2ca269a67b408198b9e3e9dbb742b | lock/版本无改动 |
| `flutter analyze --no-pub` | 同一组合运行树，无问题；其后固化为9b22dcc | 到收束前HEAD仅9个docs路径有差异，运行与测试内容相同 |
| `flutter test --no-pub --concurrency=1 --reporter expanded` | 同一组合树，387pass/1条件skip，6分10秒；条件skip为timeline导出 | 本轮继续只改文档，不影响该检查 |
| `flutter build apk --debug --target-platform android-arm64 --no-pub` | 9b22dcc，Gradle41.8秒；包身份/资源/签名检查通过 | 这是9b22dcc的既有构建，不声称当前文档HEAD重新构建 |
| `adb -s <当次核验设备> install -r hiplab-0.3.6+11-pr22-pr24-f9-arm64-debug.apk`及原生回读 | 2026-10-19 23:15:53，包SHA匹配、14键升级state保持；F9与键盘通过 | 既有设备观察，本次不重装/不重新读取用户数据；合并不扩大其强度 |
| `gh pr view 22 --repo mhgd3250905/HipLab --json number,state,mergedAt,mergeCommit,headRefOid`，同参数查24 | 本次只读再核对，两PR均MERGED，来源a586de3/0ccef6b，UTC15:32:51合并 | 与当前Git祖先及主线集成点b33ed21一致；没有商店状态观察 |

本次必要验证为文档事实、8份修改文档中261处本地链接引用（0缺失）、`git diff --check`、证据源到HEAD的有限差异及完整状态/归属复核；修改后只有本Agent的8份文档和原有4个未跟踪产物，没有新未知路径；不读取构建产物、原生日志、凭据或未跟踪产物内容。SDK/原生证据仅由本会话既有执行及已提交台账绑定，不能当成closeout重新执行。


## 0.3.7+12 测试包核验（2026-10-20）

来源55d99b3，相对已验PR25业务内容仅共用版本递增；依赖锁校验成功，锁文件未改。Android/Kotlin debug arm64构建50.7秒通过；回读com.ugk.hiplab / 0.3.7 / code12、min24/target36正确，debug证书连续，CRC通过，876个打包源资源逐字节匹配，AI配置绑定通过。与旧审核包ZIP条目集合一致；Flutter引擎等库相同，libdartjni.so仅build-id节变化，其余节一致，差异清单留本机。

本轮未重跑Flutter业务测试/analyze或真实模型，沿用同业务源8c985c4本机414过/1跳、原6复现、analyze0与13.695秒/7动作真实API结果。没有ADB/安装/听感或数据升级结论；打包通过不代表真机验收完成。[产物与证据](android-test-build-0.3.7-2026-10-20.md)。

## 版本管理与台账阶段收束（2026-10-20）

用户明确要求新增版本管理说明、对齐台账并提交推送，显式使用cockpit-closeout。scope为0.3.7+12打包阶段的文档收束；不修改运行代码、依赖、素材、共用版本或发布配置，不重建/重装、不清理旧审核文件。

- baseline：`8c6189353f619cd434cf91259ecd034c088d8fc4`，取自本会话上一轮“打包新版App测试”的已记录main起点，使用同SHA引用核验对象；不是按远端最新点猜选。
- 收束前HEAD：`2c5049eac270e526a682e7a326d56f8901ada829`。`rev-parse --verify <SHA>^{commit}`及`merge-base --is-ancestor <baseline> HEAD`通过；本地main与当次`ls-remote origin refs/heads/main`一致。
- stage delta：`git log <baseline>..HEAD`为55d99b3、2c5049e两提交；`git diff --name-status <baseline>..HEAD`为9路径：8份docs（7修改/1新增）和pubspec版本递增。运行代码、原生、资源及锁未改。
- canonical discovery：从根AGENTS.md及README.md一跳确认并实际核对docs/README.md（入口）、current-state.md（当前事实）、version-ledger.md（交付）、verification.md（检查）、development-roadmap.md（事项）、development-log.md（关键成果）、development-workflow.md（流程）和pubspec.yaml（共用版本），均为各主题current来源；其中旧日期段落为archive/history。阶段新增打包报告作为证据，不代替这些事实源。docs下无更近AGENTS.md。
- 完整归属：Preflight执行`git status --porcelain=v1 --untracked-files=all`，tracked/staged/unstaged/deleted/renamed均0；untracked4，.playwright-cli和.playwright-mcp各2，均为阶段前明确记录的旧审核产物，仅核对路径、分类和数量，未读内容。阶段提交来自本Agent上轮获准打包/记录，本次9份文档的新增修改归本Agent；旧文件保持不纳入。
- findings及修正：根README仍把main指向9b22dcc及387项旧基线；文档索引/事项页日期滞后、D-31未进当前索引；历史“最新/本次连接/本次收束”有歧义。现统一为0.3.7+12/55d99b3仅构建、旧0.3.6+11/9b22dcc最后已核验安装、PR25已合main及原生未验。新增[版本管理说明](version-management.md)按用户要求解释来源与状态，逐次交付仍只写既有版本台账，不新增平行流水。

| 既有命令 / 观察 | 执行时间、来源与结果 | source state及本次适用性 |
|---|---|---|
| `flutter analyze --no-pub` | 本会话2026-10-20 Windows，无问题（6.5秒） | `8c985c4c6dcff4207db616e759910ea03820ad79`；到收束前HEAD只有docs及共用版本变化，业务/测试/锁保持 |
| `flutter test --no-pub --concurrency=1 --reporter expanded` | 同日本机11:13–11:20，414pass/1条件skip（6分47秒） | 同一8c985c4；本轮继续只改文档，按原source引用，不称新HEAD重跑 |
| 本会话SDK真实API主机调用 | 同日11:14:20，13.695秒、7动作、无预设回落；原6独立复现也已通过 | 同一8c985c4 / SDK0.1.2；主机观察仅按[既有复审](pr25-reaudit-2026-10-20.md)引用，不扩为真机结论 |
| `flutter pub get --enforce-lockfile`及`flutter build apk --debug --target-platform android-arm64 --no-pub --dart-define-from-file=<本机私有参数文件>` | 同日13:17，锁校验成功且lock未改，构建50.7秒；身份/签名/CRC/876资产通过 | `55d99b3d097afc815fa16e165362cf4703c440d5`；核验此SHA是祖先，到收束前HEAD仅8份docs不同；这是原包证据，本轮未读取产物或重建 |

证据SHA均通过commit对象和祖先核验；有限差异完整列出文件名并核对pubspec仅0.3.6+11→0.3.7+12。原生命令、用户数据和商店状态本轮不重新观察。本次9份文档事实复核通过，320处本地链接引用0缺失，`git diff --check`、版本/范围断言与完整状态及归属复核通过；仅本Agent的8份tracked文档修改、1份新说明和4个保留的旧未跟踪文件，staged/deleted/renamed均0。以明确9路径提交，提交及普通push身份由Git记录。本次不读取凭据、原生日志、构建或旧未跟踪文件内容，不结束Cockpit会话。


## 2026-10-20 0.3.9+15整节锁屏复测：失败

绑定App运行源f8f0ec8 / 夹具ab963d7 / SDK8ef37a9；此前439pass/1条件skip及analyze0是代码检查，不替代本轮原生结论。23:44:39从AI保存组c_20261020_9eb3开练，23:45:06关屏；23:50:15系统判音频非活动，23:50:21.914 Greeze冻结、下一毫秒禁用训练锁。FGS仍在，静音AudioTrack仍started但mutedState=clientVolume，不能当成OEM有效音频活动。用户亮屏声音恢复，本轮FAILED。

锁屏中每约45秒系统只读快照及持续logcat采证，未用run-as读私有数据；失败后停止循环。23:53用户正常结束，再读结果：SessionResult.activeSeconds=528、completedExercises=6/8、full=false、endedEarly=true；记录19→20，训练组4个保持，结束后TrainingSessionService不在（仅WebView服务）。证据位于 `E:/AII-3D/hiplab-releases/hiplab-0.3.9+15-relay-20261020/native/` 的lockscreen-logcat.txt、monitor/、failed-course-result.json及退出后服务快照。只核验扬声器；不记耳机或自然完成通过。

SDK候选方向为Android保活音轨volume=1且使用全零采样素材，尚未验证。素材检查89088个PCM16采样全0，证据 `E:/AII-3D/ugk-trainer-verification-20261020/silence-pcm-check.json`；该检查只证明素材静音，不证明锁屏已修复。不新增版本、不重复构建来验证本次文档，main仍待实际通过与最终同意。


## 训练包与新中转阶段收束（2026-10-21）

本节为用户显式调用cockpit-closeout后的文档收束，未重新执行App/SDK测试、API调用、构建、安装或手机操作。版本仍为0.3.9+17；既有锁屏失败与用户后测决定保持，未上传商店。

### Preflight与归属

- 仓库边界：`E:/AII-3D/3D-Hip`，分支main。baseline为本阶段已记录的起始main `99fcc8356baf1a30d2a703e763ac01b5de4bef52`，无命名ref；`git rev-parse --verify <SHA>^{commit}`及`git merge-base --is-ancestor <SHA> HEAD`均通过。发现时HEAD为 `83130a23c73f8a29e42cce00f569a03547c0bf0f`。
- 有限delta：`git log baseline..HEAD`共12提交；`git diff --name-status baseline..HEAD`共54路径（M42/A11/D1）：根配置3、android3、docs10、lib18、test19、test_screens1，均为本会话已授权训练包/AI迁移及交付记录。收束范围仅为这些主题的文档一致性，不改代码、配置、版本、媒体或发布设置。
- 先读取适用根AGENTS及根README；按受影响路径核对22个可能的下级AGENTS位置，无嵌套文件。入口直接声明的来源如下；未递归跟随二级文档，未读取其他仓库、凭据、日志、产物或未跟踪文件内容。

| 实际canonical路径 | 类别及当前/历史判定 | 核对结果 |
|---|---|---|
| `README.md`、`docs/README.md` | current：项目/文档入口；旧日期段落为history | 当前包、职责及本阶段索引已对齐 |
| `docs/current-state.md` | current：设备/主线事实；旧日期快照为history | +17安装、两main合推、D-34失败分开登记 |
| `docs/version-management.md` | current：版本规则与快照 | 共用版本17、coach0.1.3/trainer0.1.4及状态边界已对齐 |
| `docs/version-ledger.md` | current：最新摘要；逐次构建/安装流水为history | 摘要改为+17；+15/+16/+17原始流水保留 |
| `docs/verification.md` | current：检查台账；各来源检查为history | 纠正安装摘要，补本节证据绑定，不冒充全量复测 |
| `docs/development-roadmap.md` | current：事项索引；过程段落为history | D-32/D-33已集成，D-34仍失败/用户后测 |
| `docs/development-log.md` | current：成果记录；旧阶段日志为history | 追加本次整理，候选现场明确为历史 |
| `docs/development-workflow.md` | current：操作规则和最新基线；旧基线为history | 最新基线由+12仅构建改为+17已安装/已合推 |
| `docs/android-lockscreen-fix-2026-10-21.md` | current：页首及最终合并确认；中间过程为history | 保留失败与合并事实，补过程时态说明 |

代码/配置事实另与已授权delta内的`pubspec.yaml`、`pubspec.lock`及训练/语音/AI适配核对：两包固定SDK `d193a703e3a8bef6d41e7705a55ae250e23e6a69`；App不再持有旧服务/通道，疼痛与反馈走包插槽、结果走SessionResult；课程名、剂量台词、D-01和自测仍归App。AI使用新Base URL、默认模型、仅dart-define App Key及持久UUID，无Authorization；未读取密钥值。

完整`git status --porcelain=v1 --untracked-files=all`发现tracked/staged/unstaged/deleted/renamed各0、untracked4。下列均为阶段前已由会话及本页旧收束记录明确保存的Web审核快照，路径归属已核对，仅保留、不读内容、不纳入提交：

- `.playwright-cli/page-2026-10-19T02-40-08-297Z.yml`
- `.playwright-cli/page-2026-10-19T03-12-59-813Z.yml`
- `.playwright-mcp/page-2026-10-17T07-26-38-832Z.yml`
- `.playwright-mcp/page-2026-10-17T07-29-48-965Z.yml`

### 既有证据与source state

以下均来自本会话2026-10-21执行结果，按实际来源复用，未重跑；构建参数中的私有文件路径不写入文档。

| 命令 / 观察 | 结果 | 绑定source state与适用范围 |
|---|---|---|
| `flutter pub get --enforce-lockfile` | 固定Git依赖锁校验成功 | App `79c172d9a83d248f23e136cffe825f3bd016e16b`，SDK d193a70 |
| `flutter analyze --no-pub` | No issues，6.5秒 | 同一App完整SHA；覆盖当时最终App接口适配 |
| `flutter test --no-pub --reporter expanded test/hip/hip_training_keepalive_test.dart` | 8/8，约1秒 | 同一App完整SHA；仅保活适配专项 |
| `flutter build apk --debug --target-platform android-arm64 --no-pub --dart-define-from-file=<私有参数文件>` | 成功，26.8秒；包身份/签名连续、CRC/876资产/唯一训练服务通过 | 同一App完整SHA；产物身份仍归实际构建源，不写为文档HEAD新构建 |
| 保留数据覆盖安装、冷启动及媒体会话状态观察 | +17安装成功，21记录/4组/UUID保持；PLAYING/PAUSED/恢复及token可见 | 同一App完整SHA；仅为已发生的原生观察，不推断整节锁屏通过 |
| +17整节锁屏观察 | 00:29:50.582被Greeze冻结，训练锁被禁用；FAILED | 同一App完整SHA；用户随后要求停止排查、后测，并同意保留问题合main |

`git rev-parse --verify`与祖先检查确认上述App源有效；`git diff --name-status 79c172d9a83d248f23e136cffe825f3bd016e16b 83130a23c73f8a29e42cce00f569a03547c0bf0f`仅11份Markdown变化，无运行代码、依赖或测试变化。本次亦仅修正文档，故上述范围内检查仍适用，未宣称重新执行。

历史439pass/1条件skip及analyze0绑定App `38bce474723d45d4b025e7def52dfe935ed40fda`；原语音时序保留。其至79c172d除文档还有`pubspec.yaml`/`pubspec.lock`变化，SDK升级至d193a70。因此439只作先前全量基线，不作为最终依赖的全量重跑证明；SDK119/168及后续增量结果也只按原来源报告保留，本次未跨仓核验。+16解锁补算8/8、1210秒不等于锁屏自然完成。

### 本次确定性修正与验证

已修正旧包“当前/最新”摘要、SDK版本、目录职责、漏列的本阶段文档入口、验证来源及历史/当前时态。安装、合并、推送和验收独立登记；锁屏问题没有关闭。2026-10-21提交前，以发现时HEAD加本次10份Markdown改动的工作树执行`python -`有限文档核查：368处本地链接存在、22处已读取canonical锚点有效，版本/依赖/失败边界与配置及来源一致；`git diff --check`通过。完整状态复核为tracked未暂存修改10（全部本Agent文档）、staged/deleted/renamed各0、原有untracked4（保留），无其他路径；HEAD仍为发现时来源。随后仅以明确文档路径提交，不把文档提交写为新构建或真机通过。
