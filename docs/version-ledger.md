# 版本交付台账

## 2026-11-12 首次 AI 数据共享同意 +68 候选

候选共用版本为 `1.1.2+68`。Android 商店版预期版本码 `68`，iOS 预期为 `1.1.2 (68)`。本条登记源码候选。Android 签名 AAB、Play 内测回执和 iOS 构建身份待各自完成后追加。[本轮验证](verification.md#2026-11-12-首次-ai-数据共享同意-68-候选)

## 2026-11-12 会员阶段收束 +67

### iOS TestFlight 内测

`com.ugk.hipinterlude` 的 `1.1.2 (67)` 从 `feat/membership@f397fdec36bb1cb10e36bb6c743c3470280f9753` 构建，App Store 分发签名验证通过。IPA SHA-256 为 `f32b282d31f5f01952351013839ea32fc35b8833b65800e742e6acad0181c53d`。Apple 构建处理状态为 `VALID`，`Internal Testing` 组状态为 `IN_BETA_TESTING`。

### Android 签名商店包

源码 `1.1.2+67`，Git 标签 `v1.1.2+67`，基线 `f3358005468bc6cb3181e2f80f6d3b29c83c2165`。会员卡按购买起止时间显示有效期，并列出续订、取消或试用状态。标签指向 `f42b79b7586cae066b7cd6cbc52c94da77d45781`。该源码已构建 `com.ugk.hiplab` 商店 AAB，版本码 `67`，大小 99,121,068 字节，SHA-256 为 `b635f3668f5855533be26c2adf9591498feb74ea645070de1abc9bf91c35fb46`。`bundletool validate` 通过，上传证书与 +62 一致。产物位于 `E:/AII-3D/hiplab-releases/membership-67/hiplab-1.1.2+67-membership-store-release.aab`。2026-11-12 11:53（北京时间），Play Console 回读已面向内部测试人员发布，名单仅勾选 `wrist-test` 两人。[加入内测](https://play.google.com/apps/internaltest/4701079694408471816)[验证台账](verification.md#2026-11-12-会员阶段收束-67)

## 2026-11-12 会员卡有效期真机包

`1.1.2+66` 自用 arm64 APK 的版本码为 `2066`，源码为 `f3358005468bc6cb3181e2f80f6d3b29c83c2165` 加会员卡有效期改动，运行差异 SHA-256 为 `c72e5525e17174d3f3fe312cefe64de35c8f4234690c2dec9551c3822454e3e6`。11:02（北京时间）同签覆盖手机的 `2065` 并启动，应用 ID、用户数据目录和首次安装时间均已核对保留。用户已确认会员卡有效期真机验收通过。

APK 路径为 `E:/AII-3D/hiplab-releases/membership-66/validity-device/hiplab-1.1.2+66-validity-device-arm64-release.apk`，大小 56,683,056 字节，SHA-256 为 `2d9d1ea40a6dab898c4919c5a2d58de1b99af1bdecdf418da4711366712b8d6f`。

## 2026-11-12 Android 会员页 v2 +66

签名商店 AAB 来自 `f3358005468bc6cb3181e2f80f6d3b29c83c2165`，包名 `com.ugk.hiplab`，版本码 `66`，大小 99,116,740 字节，SHA-256 为 `6f8e0d660411b5593f97eea146512d87bc8e2c81928ac67eff05baf1ae30f00d`。通过 bundletool 校验，与 +62 上传证书一致。Play Console 回读已面向 `wrist-test` 内部测试人员发布。[加入内测](https://play.google.com/apps/internaltest/4701079694408471816)

## 2026-11-12 iOS 会员 +65

- 候选为 `com.ugk.hipinterlude` `1.1.2 (65)`，构建源为 `feat/membership@44da9c22c161ae9755a61daf4b83b0e4f5b096f6`。
- 已验证 App Store 分发签名。IPA SHA-256 为 `6ff3e9b2926bfcf591961caddcb236e92d69502a455d36df37c2d350b7474aa4`。
- Apple 构建处理状态为 `VALID`，`Internal Testing` 组状态为 `IN_BETA_TESTING`。

## 2026-11-11 Android 会员 +65

Android `1.1.2+65` 签名商店包已发布 Play 内测。构建源为 `6c739c3`，签名匹配 +62 上传证书。[构建与发布证据](android-membership-2026-11-11.md#2026-11-11-play-内测和网关部署)

## 2026-11-10 动作库 +64 上架前候选

`1.1.1+64` 商店 AAB（64）与自用 arm64 APK（2064）均从 `39d70555baa6c3eb30182eec58a03b56462b2566` 构建，分别匹配 +62 上传证书和自用安装证书。[包路径、大小与 SHA-256](library-248-plus64-2026-11-10.md#验证与构建)

## 2026-11-10 r2-v11 动作库候选 +63

`feat/library-248` 基于 `main@98f891b`（+62）。版本为 `1.1.1+63`，Android arm64
为 `2063`，SDK 锁定 `536b4c52c0f665203e7feb82dfde4d76f4815ad8`，stable 渠道。
r2-v11 原目录 249 项，动作库和 AI 定制显式开放 248 项，随包带 248 张封面和
248 张缩略图。静态分析 0 问题，全量 641 通过，70 项既有跳过，0 失败。

运行源 `c40e50f8c4e0b1ff6481981109ffb78fc4c1b66f` 已构建并验签，安装证书与 +62 一致。
APK 为 54,596,512 字节，比 +62 增加 5,243,684 字节。断网软件冷启动及
248 张列表图解码通过，真机播放和覆盖保留用户数据待验收。[交付回执](library-248-r2-v11-2026-11-10.md)

## 2026-11-08：SDK 同步候选 / +62

本轮候选为 `codex/sdk-sync-r1-20261108`，从本地 `main@54471ae` 建立；
版本 `1.1.0+62` / arm64 `2062`，五处 SDK ref 与四实际包锁为
`886ffd50bda196de06674debbf1a8958e3900d2f`，渠道 `stable`。SDK 分支 `codex/hiplab-sync-r1`
已推送并开 Draft PR #26，未合 SDK main。App 同步 r2-v10、肌群检索、目录线上语音、
Set/Round 语序及 11–30 录音，保留 +61 UI、授权 209 / 可浏览 208 与本地优先。

App 最终 analyze 0 问题，全量 638 通过 / 70 既有跳过 / 0 失败；已从
`221312bd51264d85e9e23cc7ba2fe0accb8f6f9a` 构建 stable arm64 release APK，版本 `2062`，
验签与 +61 一致，未安装。本轮只推候选分支，不合 main、不打 tag、不发布。
既有 main/+61 验收保持原归属。范围、验证和最终包身份见
[本轮记录](sdk-sync-r1-2026-11-08.md)。下方日期记录保留历史。

## 2026-11-07：文档/学习样例收束，无新包

当前交付保持`1.1.0+61`/arm64`2061`，实际包源`7ca96179d44e216b79ffbc9b9855986f669552cc`，APK SHA256`1a2e3765b744448a6ebd7937d39fa63b0fb91c4a33c2eaff6bcaae55fcfb2d10`。此前覆盖安装、启动及用户UI接受保持原归属。本次只整理规范/配方/台账，不增版、不构建、不安装、不操作商店；主线接收点8420268之后的文档提交不会产生新APK。[本次范围与证据](ui-documentation-closeout-2026-11-07.md)。

## 2026-11-07：已验收UI接收为main主线 / +61

用户已明确确认截至+61的本轮UI改动全部验收通过，并授权推进main作为后续开发主线。已将main从`6bdf1e9`快进到完整候选`6e49ac7`（67提交），再追加本次文档回执；不重写历史、不拆分已验收内容。共用版本保持`1.1.0+61`，arm64`2061`，四SDK实际依赖及coach override固定`fa957ff405cc57cd10d53987430313822ff20607`，hosted锁版本保持。最终候选全量624通过/70条件跳过/0失败、analyze0、严格离线锁解析及diff检查通过。手机已装+61，运行源`7ca9617`；它与集成候选的非docs文件完全相同。本轮只做集成与文档，不重建、不增版、不再操作手机。用户验收属于本轮日常Android界面体验，不扩大为新iOS、语音听感、锁屏/中断、实模对话或商店发布的Agent实测。

[主线集成范围、证据及边界](ui-main-integration-2026-11-07.md)。下方候选/待验结论按日期保留为历史。

## 2026-11-07：限制活动提示改为年轻男性 / +61已安装

按用户反馈，第二张改为约20岁的年轻男性卡通：黑色短发、卫衣、运动鞋和现代前臂拐杖，保留绿色暂停与膝部标记。只替换第二张，第一/第三张及运行代码/SDK/lock保持。运行源`7ca96179d44e216b79ffbc9b9855986f669552cc`，版本`1.1.0+61`/arm64`2061`。语言页面/首次安全流程及资源共10项通过，深浅第二张测试截图已核对，diff检查通过。纯素材和版本变更，未重复静态分析/全量测试。APK验签匹配+60、资源核对通过，SHA256`1a2e3765b744448a6ebd7937d39fa63b0fb91c4a33c2eaff6bcaae55fcfb2d10`。已覆盖安装真机2060→2061并启动ok，无卸载或清数据；视觉验收待用户。[素材及交付记录](friendly-safety-art-2026-11-07.md)。

## 2026-11-07：友善卡通安全插画 / +60已安装

按用户反馈改为远离真人的卡通人物；孕产期安心休息，术后/限制活动补绿色暂停与关节位置标记，受伤/不适补暖黄色绷带提示。三张透明插画适配深浅主题，完整收纳避免裁掉标记；安全判断和中英文原文保持。运行源`9a4050e7182ecdbcb3e0eaf529bc6a6256e09c46`，`1.1.0+60`/arm64`2060`，SDK/lock保持。相关18项测试通过、analyze0；已核对深浅三步截图。APK签名与+59一致、资源/ZIP检查通过，SHA256`11fa10ed573ac66de9d162e141929a1e4a3e115a642fda0d1bee2d9ccd1b7291`。已在2602BRT18C上覆盖安装（2059→2060）、启动ok，未卸载或清数据；插画实际观感仍待用户验收。[实现及证据](friendly-safety-art-2026-11-07.md)。

## 2026-11-07 上午：+59 真机覆盖安装

用户重新连接真机后，已在2602BRT18C上执行`adb install -r`，返回Success；安装前2058、安装后2059（`1.1.0+59`），firstInstallTime仍为2026-11-05 22:11:33。未卸载、未清数据；启动MainActivity返回Status: ok并观测到应用进程。这是安装/启动证据，英文页面、语音、视频动画与实际数据完整性仍待用户验收，未记为通过。运行源仍为`1073222`，包SHA256仍为`185c140d0d8c2340c11cc4820dc7e12f969df645df3d36a42db76971af567482`；安装回执位于交付目录`device-install-receipt.json`，原构建时installed:false保留为当时快照。

## 2026-11-07：完整英文界面 / +59待真机

补齐全 App 英文展示：设置新增独立“界面语言：系统 / 中文 / English”，口令语言独立保留并正确跟随App；旧安装默认中文。首页海报/文件夹、更多、设置、动作库/训练组/编辑/选择器、自测/结果、记录/日历/里程碑、隐私、播放器和SDK聊天/训练指南按当前locale显示。长英文设置选择器分行、首页标题最多两行、牌面方向用紧凑缩写，保留视频身份与既有转场。

运行源`1073222137d2f6eb5b2fa26c07a70e63ed9862c9`，候选`codex/english-app-20261107`，`1.1.0+59` / arm64 `2059`；四SDK依赖+coach override固定`fa957ff405cc57cd10d53987430313822ff20607`，hosted锁版本保持。App功能基线46f9f8d全量624通过/70条件跳过/0失败；其后启动重试语言作用域和详情分行/标点修正经最终14项中英页面/内容专项通过，最终分析0。SDK聊天89/库11/core scope39项通过，最终库11项复跑通过。209个授权公共动作英文保留689条要领、289条注意、200条部位提示。已准备同签+59APK，未安装/未操作手机；明早真机、语音听感、通知与实际动画观感待用户验收。[实现与交付](english-app-2026-11-07.md)。

## 2026-11-07：导航按钮高度统一 / +58待确认

修复训练组→新建训练组（添加动作）左上返回/关闭胶囊下移：旧44/52pt标题行共用居中公式导致4pt变化，真机+57边界从y152变y165，尺寸143px未变。现在单/双标题的左侧胶囊与右侧操作共用固定44pt控制轨道，副标题只扩展标题和磨砂区域；固定胶囊、随页滑入、正反转场均使用同一纵向锚点。另固定沉浸自测头部的48pt控制轨道，长题不再带动关闭/进度下移，保留原外留白和正文全宽居中。

构建源`5a35be70a8faa915b8b30448a26476f00e52a778`，候选`codex/nav-control-anchor-20261107`，`1.1.0+58` / arm64 `2058`；SDK保持`6fbd7de15dea62c7152eac43df1303b85d887a7c`，lock/Native/首页卡片与文件夹无改动。分析0，相关13文件142通过/14既有跳过（含导航锚点14项）。已同签覆盖安装真机、回读2058；训练组→新建→关闭的实际按钮边界完全一致，返回与副标题排版检查完成，新体验待用户确认。[实现与交付](nav-control-anchor-2026-11-07.md)。

## 2026-11-07：整套立体条目图标 / +57待确认

按用户反馈重画整套18类条目前导图标：训练组卡片、动作书册、髋关节、记录日历、设置齿轮，以及提醒、椅边练习、语音、提示音、语言、音量、外观、安全、隐私、新建、AI、完成/暂停。统一玉绿、浅瓷和金属材质、方向一致的高光与侧壁；深浅主题适配。30pt图标列、52/60pt行高和文字位置保持。

构建源`8e84d1582a6192aee8ab63ba4827bc916566a9aa`，候选`codex/list-icon-craft-20261107`，`1.1.0+57` / arm64 `2057`；SDK保持`6fbd7de15dea62c7152eac43df1303b85d887a7c`，lock/Native/首页牌面与文件夹无改动。分析0，相关12文件128通过/14既有跳过（含新图标5项）。已同签保留数据覆盖安装真机、回读2057并启动成功；更多/设置/训练组现场截图已检查，新的视觉观感待用户确认。[实现与交付](list-icon-craft-2026-11-07.md)。

## 2026-11-07：打卡徽章训练记录 / +56测试包

首页右上连续打卡徽章现在可点击，直接进入现有“训练记录”页。保留24pt玻璃徽章，触达区至少44pt，补按钮语义；首页没有返回键，记录页返回胶囊随页面滑入（pinLeading:false）。重复点击防护保持到收起转场完成，返回保留首页当前卡片/视频。空记录页开练使用首页当前所选完整计划。

同包按用户最新反馈将文件夹内部小图圆角恢复6，外框圆角按6pt内边距适配为12；固定四格位置，只有两组时放上排，下排留空，不再居中。仍一组一图、最多预览四组，无假占位图，右下锚点保持。

构建源`863b44ab7d09a8ddbdd87dbe3fbc9d887e472e18`，候选`codex/home-streak-records-20261107`，`1.1.0+56` / arm64 `2056`；SDK保持`6fbd7de15dea62c7152eac43df1303b85d887a7c`，Native/lock/动作牌无改动。相关10文件110通过/14既有跳过，后续文件夹8项另通过，分析0。已同签覆盖安装真机并回读2056、启动ok；入口与返回的现场结果见安装回执，新体验待用户确认。[实现与交付](home-streak-records-2026-11-07.md)。

## 2026-11-07：真实组数预览 / +55测试包

用户指出办公只有两组、收起却显示四图。已改为**一组一图，最多四组**，只取各组首动作，不再用组内后续动作填格；两组同行居中、三组末项居中、四组2×2，展开仍显示全部实际候选。64pt外框圆角19→14、内部6→8，与6pt内边距成对；静态与过渡共用cell/radius，保留右下角锚定及既有选组功能。

构建源`3aeb2ee30af08774953c7588b99f5e71f2b1383c`，候选`codex/home-routine-folder-preview-20261107`，`1.1.0+55` / arm64 `2055`，SDK保持`6fbd7de15dea62c7152eac43df1303b85d887a7c`，Native/lock/动作牌无改动。相关10文件108通过/14既有跳过，文件夹8项另通过（总116通过），分析0。已同签覆盖安装真机并回读2055、启动ok；数量/圆角观感待用户确认。[实现与交付](home-routine-folder-preview-2026-11-07.md)。

## 2026-11-07：右下角锚定文件夹 / +54测试包

按用户对+53的新反馈，文件夹以原按钮**右下角为锚点**，右/下边保持固定，仅向左、向上延展；收起沿原路径回到右下角。取按钮静止中心与尺寸，避免点击按压缩放影响落点。网格样式、选组与关闭交接保持；SDK/Native/动作牌/lock无改动。

构建源`815f878141e3831b753b9dc43a2699d71817c868`，候选`codex/home-routine-folder-anchor-20261107`，`1.1.0+54` / arm64 `2054`，SDK保持`6fbd7de15dea62c7152eac43df1303b85d887a7c`。相关10文件108通过/14既有跳过，文件夹7项另通过（320/394/横屏每16ms核对固定right/bottom和左上单调延展），分析0。已同签覆盖安装真机并回读2054、启动ok；新锚定动画观感待用户确认。[实现与交付](home-routine-folder-anchor-2026-11-07.md)。

## 2026-11-06：推荐训练组文件夹 / +53测试包

构建源`2d46ab1e4fcc0d696ae3748330863ccb93fb94aa`，候选`codex/home-routine-folder-20261106`；`1.1.0+53` / arm64 `2053`，SDK保持`6fbd7de15dea62c7152eac43df1303b85d887a7c`、lock保持。已验收+52保留历史，本轮新增文件夹等待用户确认。

首页“换一套”改64pt四动作封面的玻璃文件夹，原位展开当前场景全部有效推荐组，展示名称/时长/动作数与选中状态，可直接选择。关闭完成再更新首页；取消或重复选择保留预览与视频，办公/居家各自记住本次启动的选择，实际开练使用所选完整计划。只用SDK静态封面，无额外视频节点。相关10文件108通过/14既有跳过，文件夹7项另通过，分析0。已同签覆盖安装真机，包管理器回读2053、MainActivity启动成功。新动效与交互观感待用户确认；本轮无全量、iOS或模型验收。[实现与交付](home-routine-folder-2026-11-06.md)。

## 2026-11-06：+52用户真机验收通过

用户在+52覆盖安装后明确回复“我已已经验收通过了”，当前`1.1.0+52`（arm64 `2052`，构建源`59ce2b8`）记为**用户真机验收通过**。本轮首页动作卡片及计划切换优化的用户验收项已收束；不另推定未报告的逐项测试或性能指标。安装回执与APK身份保持，未重建或改运行代码；候选分支仍为`codex/home-plan-media-continuity-20261106`，合并状态独立记录。

用户确认回执：`E:/AII-3D/hiplab-releases/home-plan-59ce2b8-52-20261106/user-acceptance-20261106.json`。下方“待验收”保留为交付时历史，当前以本条为准。[实现与交付](home-plan-media-continuity-2026-11-06.md)。

## 2026-11-06：+52真机覆盖安装与启动回执

用户重新连接手机并明确授权安装。已在`2602BRT18C`（`QSG6Q8IFDMDELVGQ`）执行`install -r --no-incremental`，回执Success；包管理器从2051更新为2052（1.1.0），设备lastUpdateTime为2026-11-06 22:12:14。未卸载、未清数据；原firstInstallTime仍为2026-11-05 22:11:33，未另核验业务数据。`com.ugk.hiplab/.MainActivity`冷启动Status ok；这里只确认安装与启动，卡片切换/展开/播放观感仍待用户使用反馈，不据此宣布视觉或性能验收。

安装包仍为构建源`59ce2b8`，SHA256 `3bac5de8477199360cab68c74cfaa446c1c2f74d3f5117ba752b4a2a203692e9`；无重建、运行代码、SDK或版本变更。安装回执留`E:/AII-3D/hiplab-releases/home-plan-59ce2b8-52-20261106/device-install-20261106-221214.json`。下方交付时“未安装”保留为历史；当前状态以本条为准。

## 2026-11-06：计划切换首牌稳定 / +52远程测试包

运行/构建源 `59ce2b8829d64eec401c743123d31c57e79d4a62`，分支 `codex/home-plan-media-continuity-20261106`；`1.1.0+52` / arm64 `2052`。SDK仍固定 `6fbd7de15dea62c7152eac43df1303b85d887a7c`，hosted锁保持；日常目录 `feat/ui-detail-polish@25260b3` 未改。

针对办公/居家首牌闪动，将冷牌保护统一覆盖初始首牌、场景/换一套/跨日/动作列表重置，以及关闭后迟到首帧。新牌保持封面，主动展开才揭示原视频；同一已就绪当前动作成为新首牌时保留State/controller/Texture与当前帧。提前解码两场景当前可选计划的首封面，精确匹配bundle和显示尺寸，不批量下载视频。新增6项回归；相关10文件106通过/0失败/14既有跳过，分析0；Impeller另2通过、62组RGBA消费对照误差/黑残影0。SDK/Android和+51运动参数未改，本轮未重复SDK测试。

+52 release验包/验签通过，与+51内部包同签。未安装、未跑全量/模型/iOS；远程手机观感待用户确认。[实现与交付](home-plan-media-continuity-2026-11-06.md)。

## 2026-11-06：连续接牌与惯性 / +51远程测试包

运行/构建源 `2087649d8c0dc8b34827c8458876886e55330662`，分支 `codex/home-card-handoff-motion-20261106`；`1.1.0+51` / arm64 `2051`。SDK固定 `6fbd7de15dea62c7152eac43df1303b85d887a7c`，hosted锁保持。日常目录 `feat/ui-detail-polish@25260b3` 保持。

用户确认+50的更多闪帧/上下透明异常修复。新候选预备current±1最多3挂载暂停媒体，到顶按occurrence GlobalKey接管原State/controller/Texture；冷首帧迟到保持compact既有图，主动展开解除。上下仍用物理曲线，取消900硬限速、竖k70/ζ.82，水平原值保持。相关100通过/14跳过，强化甩速另1通过，Impeller另2通过/62组RGBA像素0误差；SDK54通过，双方分析0。+51 release验包/验签通过，与+50内部包同签；Agent未安装，新接牌及手感待用户远程确认。

[实现、资源范围与交付](home-card-handoff-motion-2026-11-06.md)。

## 2026-11-06：牌面视频稳定性 / +50远程测试包

运行/构建源 `981eeaf161c0b896e963d625f9525b69e9bf32b6`，候选分支 `codex/home-card-surface-stability-20261106`；`1.1.0+50` / arm64 `2050`。四个SDK包及coach override固定 `145e3195570f34536c948558e02306a3db5ec2e3`，hosted锁保持；日常目录 `feat/ui-detail-polish@25260b3` 保持。

仅首页前牌启用暂停帧跨覆盖路由保留和原生单decoder RGBA输出：解决进入更多时回封面的明确路径，绕开上下离屏裁剪对packed透明取样的破坏。App相关96通过/14跳过，Impeller另2项通过（68组RGBA消费对照误差/黑残影0）；SDK相关49通过，双方分析0。+50 release及Android原生编译、验包/验签通过，同+49内部证书；Agent未安装，Android OES/SurfaceProducer及原机观感待用户远程确认。

[定位、实现与交付](home-card-surface-stability-2026-11-06.md)。

## 2026-11-06：上下翻牌节奏 / +49远程测试包

运行/构建源 `8475c71f2bdb2eb69456c7fe400fe4f594f1d7b0`，候选分支 `codex/home-card-exit-easing-20261106`；`1.1.0+49` / arm64 `2049`。SDK仍 `b4861c5215280c49bffe03b8c203074217dcf995`，lock保持；日常目录 `feat/ui-detail-polish@25260b3` 保持。

按用户最新反馈完整撤回长按识别/吸附动效，恢复原点按展开。全向翻牌保留；退出目标按实际投影边界离屏剩余距离计算，放缓竖向弹簧并限制沿射线的起始速度，离屏后及时交接。相关10文件95通过/13跳过，Impeller像素另1通过，分析0；+49 release验包/验签通过，与+48内部包同签。Agent未安装，手感交用户远程确认。

[实现、节奏回归与包身份](home-card-exit-easing-2026-11-06.md)。

## 2026-11-06：动作牌手势 / +48远程测试包

运行/构建源 `1d89e8916513639b5a56e57997170754ae103404`，候选分支 `codex/home-card-touch-motion-20261106`；`1.1.0+48` / arm64 `2048`。SDK仍 `b4861c5215280c49bffe03b8c203074217dcf995`，lock保持；日常目录 `feat/ui-detail-polish@25260b3` 保持。

短按立即展开，300ms长按轻抬且可继续跟手；任意方向拖出径向区域均可翻牌，并沿原射线离场。持当前视频帧完成展开后自动播放，刊头/编号等改固定画布缩放，以减少首次起播和重复排版与过渡并发。相关10文件94通过/13跳过，Impeller像素另1通过，分析0。+48 release验包/验签通过，与+47内部包同签；Agent未安装，首次展开及手感交用户远程验收，未采集原机性能trace。

[交互、性能边界与包身份](home-card-touch-motion-2026-11-06.md)。

## 2026-11-06：首页静默加载 / +47远程测试包

运行/构建源 `bba10fdb98934cea5e9f27c3062a7ad74d79e43c`，候选分支 `codex/home-card-silent-loading-20261106`；`1.1.0+47` / arm64 `2047`。SDK固定 `b4861c5215280c49bffe03b8c203074217dcf995`，hosted锁保持；日常目录 `feat/ui-detail-polish@25260b3` 保持。

首页下载/待首帧不再显示转圈，保持封面至真实首帧，由同一播放器接上；真实失败重试保留，普通宿主默认提示保持。App相关10文件88通过/13跳过，Impeller像素回归另串行1通过；SDK相关31通过，双方分析0。+47 release验包/验签通过，与+46内部包同签；交用户远程覆盖测试，Agent未安装，实际切牌/首帧观感待反馈。

[实现、检查与包身份](home-card-silent-loading-2026-11-06.md)。

## 2026-11-06：杂志动作专页 / +46远程测试包

运行/构建源 `21dd048940baef24a4e3d7186163ae626b062fcf`，独立分支 `codex/home-card-editorial-20261106`；`1.1.0+46` / arm64 `2046`。SDK仍 `1c082e9d3e22022f228888fdd1935b1d61371cb9`，lock、shader、媒体与原生代码保持。日常目录 `feat/ui-detail-polish@25260b3` 保持。

APK `E:/AII-3D/hiplab-releases/home-card-editorial-21dd048-46-20261106/hiplab-1.1.0+46-21dd048-internal-arm64-release.apk`，47628200字节，SHA256 `a4b0645993f452274618ac03d14401382d7b8add145345ae0024d7ef5badb796`，证书 `3761270a4764157f0e389014a9e5b800b05403bfddce0f4f7f8c039f6a53bdc7`；与+45内部包同签。构建49.9秒，包身份、789资源项及重签runtime负载通过，原上传签名APK仅归档。

最终+46 release已构建、验签和资源校验，未由Agent安装，继续交用户远程覆盖测试。Noto字体浅深实际widget渲染已检查，组件逐帧与headless Impeller证据不替代原机滑动/展开观感及帧时长验收。

[版式与验证](home-card-editorial-2026-11-06.md)。

## 2026-11-06：透明视频取样修复 / +45远程测试包

运行/构建源 `9925e3c58afdea65768875f85ee3a4b60865a6f0`，分支 `codex/home-card-alpha-alignment-20261106`；`1.1.0+45` / arm64 `2045`。SDK仍 `1c082e9d3e22022f228888fdd1935b1d61371cb9`，lock、shader/素材内容及原生代码保持；日常目录 `feat/ui-detail-polish@25260b3` 保持clean。

APK `E:/AII-3D/hiplab-releases/home-card-alpha-9925e3c-45-20261106/hiplab-1.1.0+45-9925e3c-internal-arm64-release.apk`，47628200字节，SHA256 `cab9c19e4b3fe17d1d3bc8f2d79f5cee28701cbd77e4f9bb7b54875fefb118d5`，证书 `3761270a4764157f0e389014a9e5b800b05403bfddce0f4f7f8c039f6a53bdc7`；与+44内部包同签。构建56.4秒，包身份、789资源项和重签runtime负载通过。原上传签名APK仅归档。

最终+45已构建、验签和资源校验，未由Agent安装。继续交由用户远程覆盖安装，原机视频取样、文字清晰度和帧时长仍待反馈；本机headless Impeller与合成图案不代替手机GPU/SurfaceProducer验收。

[修复与验证](home-card-alpha-alignment-2026-11-06.md)。

## 2026-11-06：持久视频牌面 / +44远程测试包

运行/构建源 `c0798ecc6a9ef5f91bfa0221cee5bb2c42dfad38`，独立分支 `codex/home-card-live-surface-20261106`；`1.1.0+44` / arm64 `2044`。四个实际SDK包及coach override固定 `1c082e9d3e22022f228888fdd1935b1d61371cb9`；hosted锁、Flutter3.44.7及素材内容保持。日常目录仍 `feat/ui-detail-polish@25260b3`，保持clean。

APK `E:/AII-3D/hiplab-releases/home-card-live-c0798ec-44-20261106/hiplab-1.1.0+44-c0798ec-internal-arm64-release.apk`，47628200字节，SHA256 `8bbeb76156b1098ab623de6c3a6b40b2222cddf10f6022e3648c9f33265e6e17`，证书 `3761270a4764157f0e389014a9e5b800b05403bfddce0f4f7f8c039f6a53bdc7`；与+43内部包验签一致。构建77.0秒，包身份、789资源项、重签runtime负载通过。原上传签名包仅本地归档。

最终+44 release已构建、验签及资源校验，尚未由Agent安装；按用户决定交由用户远程安装测试。同一节点/纹理身份的组件回归和浅深色实际widget绘制检查已完成，原生首帧准备与真实过渡观感等待用户反馈，不能记作真机无闪烁通过。

[实现、检查与证据](home-card-live-surface-2026-11-06.md)。

## 2026-11-06：动作牌视频回首 / +43待真机

运行/构建源 `32ac1a76e12894f6aedb8218be0b35a591fd3461`，分支 `codex/home-card-return-fix-20261106`；`1.1.0+43` / arm64 `2043`，四个实际 SDK 包及 coach override 固定 `4b9b685788352415fbfce2d8a2651f7f9d207512`。日常目录保持 `feat/ui-detail-polish@25260b3`；本轮在既有 E 盘隔离副本开发。

APK `E:/AII-3D/hiplab-releases/home-card-return-32ac1a7-43-20261106/hiplab-1.1.0+43-32ac1a7-internal-arm64-release.apk`，47628200字节，SHA256 `e44ef9447eab5f8f502d149b795ba04a954b62fb96907c1d5e7a7f67f6f1ce9c`，证书 `3761270a4764157f0e389014a9e5b800b05403bfddce0f4f7f8c039f6a53bdc7`；release/非debuggable/仅arm64、包名/版本/签名/789资源项及重签负载校验通过。构建73.6秒。原上传签名包仅本地归档。

+42/2042（3c0a1a0）此前已安装并获用户“好多了”的有限反馈；+43含牌底和SDK回首新行为。最终+43包已构建并完成签名/资源校验。用户随后明确本轮没有本地真机，改由用户远程安装测试；安装状态与视频快放、首帧交付及缩牌真实观感均待用户反馈，组件/fake平台通过不等于原生验收。

[实现与证据](home-card-return-2026-11-06.md)。

## 2026-11-06：二级转场优化 / +41最终内部release

运行/构建源 `58aa468c2707361e917cea2b75fc4561a23b4473`，独立分支 `codex/navigation-transition-perf-20261106`；`1.1.0+41` / arm64 `2041`。继承+40动作牌，SDK97eb66d、lock、资源与原生配置不变。

包 `E:/AII-3D/hiplab-releases/navigation-58aa468-41-20261106/hiplab-1.1.0+41-58aa468-internal-arm64-release.apk`，47628200字节，SHA256 `b3e96c61334e77a1e82ee3b45d6d199356b4fc19e68990c231865c37d98bb13f`，证书 `3761270a4764157f0e389014a9e5b800b05403bfddce0f4f7f8c039f6a53bdc7`；同签覆盖Success、回读2041/1.1.0、冷启动191ms。验包/资源/运行负载通过，正式libapp.so无诊断入口。

最终+41 release同签名覆盖成功，回读2041/1.1.0，冷启动Status ok/191ms。浅色五路径进退、深色设置/隐私及内容滚过顶栏已检查；已恢复原浅色选择、回到首页。按用户要求锁屏，系统回读keyguard showing=true、inputRestricted=true，电源为Dozing（设备常亮显示状态）；不再操作手机。 profile计时制品与最终release分别归属，完整[量化、包身份和现场记录](navigation-jank-2026-11-06.md)。

## 2026-11-06：动作牌 / +40最终内部包

运行/构建源 `ba40e38a783975f17fcd682606e8b5bd092b7b25`，独立分支 `codex/home-action-deck-20261105`；`1.1.0+40` / arm64 `2040`。SDK仍固定97eb66d，lock、资源和原生配置未改。

最终包 `E:/AII-3D/hiplab-releases/home-action-floating-ba40e38-40-20261106/hiplab-1.1.0+40-ba40e38-internal-arm64-release.apk`，47628200字节，SHA256 `6b96e88dbf4495762f1ed049fa29f1be9c5f25d9b4194c130c23bb6959e85b46`；证书 `3761270a4764157f0e389014a9e5b800b05403bfddce0f4f7f8c039f6a53bdc7` 与+39一致。install-r Success、2040/1.1.0回读，未清数据。原上传签名包只归档、未上传。

+37/cf46dce、+38/70e1929、+39/3c5ef15均为本轮此前已安装的内部候选；+38有用户确认，+39主体证据与+40最终证据分目录保留，见[最终报告](home-action-floating-2026-11-06.md)和[+38报告](home-action-deck-2026-11-06.md)。

## 2026-11-05：UI r4 全界面补全 / +36 真机包

运行/构建源 `6e247aaa7349b9d5cd8c2e626fe3e4a86faba9e3`，分支 `codex/ui-r4-completion-20261105`；`1.1.0+36` / arm64 split `2036`，SDK仍固定 `97eb66d`，lock、媒体及原生配置未改。

| 项目 | 实际事实 |
|---|---|
| 包 | com.ugk.hiplab / 1.1.0 / 2036 / release / arm64-v8a / 非debuggable |
| 内部安装APK | `E:/AII-3D/hiplab-releases/ui-r4-completion-6e247aa-36-20261105/hiplab-1.1.0+36-6e247aa-internal-arm64-release.apk` |
| 字节数 / SHA256 | 47628200 / `24b769b5ca5f67186f082d9da0bb58a58f2723e08038585dd122ac7c2ae63000` |
| 证书SHA256 | `3761270a4764157f0e389014a9e5b800b05403bfddce0f4f7f8c039f6a53bdc7`，与当前+35开发包一致 |
| 原上传签名APK | 同目录`hiplab-1.1.0+36-6e247aa-upload-signed.apk`，仅归档，未上传 |
| 资源 | r2-v1目录249、授权209、封面209、未审AI标签209、0内置MP4；stable |
| 安装 | 2026-11-05 23:32:13设备时钟，小米2602BRT18C，`install -r` Success；本次+36升级未清数据 |
| 回读/冷启 | versionCode2036 / versionName1.1.0 / Status ok / 226ms |
| 配置 | Flutter3.44.7，原私有测试配置经外部临时define文件提供；临时文件已删，凭据/密钥/包不入Git |

本会话此前+35 UI基线是用户自行卸载旧签名包后全新安装；用户明确开发数据不必保留，之后以合成UI数据审查。本轮不声称旧历史数据恢复成功。+36只继承当前开发状态；没有商店、tag、release/1.0或main集成动作。软件与真机范围见[本轮报告](ui-r4-completion-2026-11-05.md)，同目录`release-apk.json`和`installation-receipt.json`是本地回执。

## 2026-11-05：UI r4 / PR #32 审核补记（无新包）

本轮切换 `feat/ui-detail-polish`，审核并修复返回胶囊覆盖状态，版本保持 `1.1.0+35`、SDK `97eb66d`，不生成 APK 或执行安装。源码/检查与合并身份见[审核报告](ui-r4-pr32-review-2026-11-05.md)。下方远程 debug 打磨中的“尚未提交/未 push”属于当时快照，最终远程源为 `cb0f063`；本轮另有审核补丁，不能沿用旧 debug 包宣称该补丁真机通过。

此前 `97cecb1` 的 +35/2035 release 交付包不含 UI r4 和本轮补丁。本次源码合并不会改变已有包的内容、签名或安装事实。

## 2026-11-05：1.1.0+35 顶栏调试包（debug，非交付）

| 项目 | 已登记事实 |
|---|---|
| 分支 / 构建源 | `feat/ui-detail-polish`，基线 `97cecb1`，上一轮已提交 `7cd5f44`；本段全量 UI 扫描改动仍在工作区，构建源为工作区，尚未提交 |
| 包身份 | com.ugk.hiplab / versionName 1.1.0 / versionCode 35 / **debug** / 非签名交付包 |
| 产物 | `build/app/outputs/flutter-apk/app-debug.apk`（本机构建目录，Git 忽略；不是交付制品） |
| 安装 | Pixel 8 `38011FDJH00940`：`install -r` 覆盖，冷启动 Status ok；2026-11-05 11:53、12:17、12:43（设备时钟）先后覆盖安装返回胶囊版/手感版/首页无胶囊版 +35 debug，未清数据；2602BRT18C `QSG6Q8IFDMDELVGQ`：首次全新安装成功，之后 16:37、16:52、17:31、17:33 多次 `install -r` 前序 +35 包，均未清数据；最终版安装前设备断开，未在该机回读 |
| 设备回读 | 小米机 `dumpsys package` 回读 versionName 1.1.0 / versionCode 35；crash buffer 无 FATAL |
| 检查 | 最终代码 `flutter analyze --no-pub` 为 0；首页无胶囊版全量 `flutter test --no-pub` **462 通过 / 0 失败 / 68 既有跳过**，定向 13/13；已截图更多、设置浅/深、练习分段、套路详情（新间距）、组编辑、iOS 确认弹窗、加动作选择器、安全复审（新按钮）；Pixel 8 `nav11.mp4` 验证更多↔设置（胶囊固定、单一），`nav12.mp4` 验证首页→更多（胶囊随页面滑入/滑出） |
| 未做 | 扫描改动未提交、未 push、未合 main、无 release/arm64 split 产物、未动 release/1.0 与商店、未递增版本号 |

本条目只记录调试安装事实，不构成交付或验收结论；顶栏规格见 [UI 设计规范](ui-design-standard.md)。

## 2026-11-04：1.1.0+34 / 2034 问答 v3 内部包与主线集成

| 项目 | 已登记事实 |
|---|---|
| 测试/构建源 | `0f0882ede92b796ba53a03df1097f11232cb2d69`，分支codex/sdk-pin-v0.7.0；SDK `f7b8a8e4853e9f50fc93888e1768ec1dbc75b588`（v0.7.2内容） |
| 主线 | PR #30已合并，功能集成点 `2400b344183e1d57636412309899b4a1481966a7`；与构建源完整文件树相同，后续本次提交只改文档 |
| 包身份 | com.ugk.hiplab / versionName1.1.0 / versionCode2034 / release / arm64-v8a / 非debuggable |
| 文件 | `E:/AII-3D/3D-Sport-AI/deliveries/hiplab-qa-v3-f7b8a8e-34-20261104/hiplab-1.1.0+34-0f0882e-internal-arm64-release.apk`（用户指定交付目录） |
| 字节数 | 49,680,947 bytes（47.38MiB） |
| APK SHA-256 | `4190cb0b88ce239f59b12a802b49d06e12efa3b7548aed45ede56c5f779e1e32` |
| +34证书SHA-256 | `3761270a4764157f0e389014a9e5b800b05403bfddce0f4f7f8c039f6a53bdc7` |
| +32实际基线证书SHA-256 | `3761270a4764157f0e389014a9e5b800b05403bfddce0f4f7f8c039f6a53bdc7`，与+34完全一致，两包均验签通过 |
| 检查 | Flutter3.44.7；严格pub get、analyze0、全部66文件461通过/0失败/68既有跳过；包名/版本/ABI/CRC/资源和重签前后负载通过 |
| 配置/资源 | SDK聊天问答v3、deepseek-v4.1-flash/max；209未审标签、211公共封面、0内置MP4。测试配置由外部提供，凭据不入Git |
| 安装/验收 | +34已交付，未安装、未做真机或新SDK实模验收；用户确认手机现装+32，Agent本轮未回读设备 |

以上来自本会话2026-11-04已返回的固定源构建、验包和双包验签回执；交付时另有同目录REPORT.md。本次closeout只补记，不读取仓库外报告/制品、不重建或安装。签名基线是实际+32包 `hiplab-1.1.0+32-c327a90-internal-arm64-release.apk`，不能写成+33；原上传签名包另存，不作为这次手机安装包。本机路径不是已上传远端制品的证明。验证适用性见[验证台账](verification.md)。

## 2026-11-04：+33 只有源码版本，未出包

源码 `f3983ce8ce93fdc901a3e33bd18b66f612b228c4` 的pubspec为1.1.0+33，SDK固定 `e7a11625497f9744a4e06f06310b4f1e5bca8d42`。用户明确确认HipLab +33从未出过包，手机仍为+32，因此不登记+33 APK、文件摘要、实际versionCode或安装通过。后续版本接续到+34，不回退构建号。

## 2026-11-04：手机 +32 的用户确认与历史边界

用户在+34打包时确认手机现装+32；这是用户报告，不是本次Agent安装/ADB验证。下方+32条目“未安装”保留其构建当时的现场，不改写历史；本次没有新增“数据保持”或“AI故障已修复”的真机结论。旧+31的SDK0.7.1真实对话也不能替代当前f7b8a8e验收。

下方为各次原始交付记录，版本、构建源和当时状态分别保留。

## 2026-11-04：1.1.0+32 / 2032 修复内部包（未安装）

`com.ugk.hiplab` / release / arm64-v8a，版本 **1.1.0+32 / 2032**，49,590,492 bytes（47.29 MiB）。APK：`E:\AII-3D\hiplab-releases\sdk-qa-fixes-plus32-20261104\hiplab-1.1.0+32-c327a90-internal-arm64-release.apk`；SHA256 `b1a24ae32a64921b5f1e157ce43eefa4648a40a056e2a1cbde11227a6de90379`；证书 SHA256 `3761270a4764157f0e389014a9e5b800b05403bfddce0f4f7f8c039f6a53bdc7`，与 +31 实际 APK 校验一致。211 公共封面、209 未审 AI 标签、0 MP4；CRC、包名/版本/ABI、签名及重签前后运行负载校验通过。

用户随后明确暂无真机，改为打包后远程安装测试。本轮未安装、未卸载、未清数据，也未抓取用户日志；下列 1–4 均不记为实测通过。App/SDK 源码未改，不新增问答适配或绕过。main 保持 4d610f5，release/1.0 不动，不合并、不打 tag、不提交商店。 构建/测试源 c327a90，详细回执见 [sdk-qa-fixes-plus32-2026-11-04.md](sdk-qa-fixes-plus32-2026-11-04.md)。

## 2026-11-04：1.1.0+31 / 2031 QA v2 内部包（未安装）

分支codex/sdk-pin-v0.7.0，构建源 `2c13e8a119409c857508c6c3e79dc27241e8e702`，SDK9dd93163。com.ugk.hiplab / arm64-v8a release，49,393,884 bytes (47.11 MiB)，211封面/0MP4/209未审标签，沿用连续测试签名。APK `E:\AII-3D\hiplab-releases\sdk-pin-v0.7.1-20261104\hiplab-1.1.0+31-2c13e8a-internal-arm64-release.apk`，SHA256 `676a1df79cb40f244ef459d27a3e196d423728d09b84b3e8bccaacb0698a7d15`；证书 `3761270a4764157f0e389014a9e5b800b05403bfddce0f4f7f8c039f6a53bdc7`。真实SDK聊天入口qaV2、模型4.1-flash/max启用；本轮仅构建和静态验包，没有安装/清数据/商店动作。全部66文件461/0/68和实模3段9轮通过，原上传签名包另存、本机路径不代表远端已有制品。[完整接入与验证](sdk-qa-v0.7.1-validation-2026-11-04.md)。+31接续HipLab自己的+30，不使用其他App的+18。

## 2026-11-04：+30 包身份与集成状态补记（无新构建）

本次只整理已有交付，App 仍 `1.1.0+30`，arm64 split `2030`。同版本号的三个包对应不同源码，不能互相替代：

| 包 / 来源 | 验证 / 包体 | 已知安装与主线状态 |
|---|---|---|
| PR #26 首页主题；`a7e371eb71df29af3929ac4a98098371c3c8928f` | 47.70 MiB；444/0/13及截图4通过归属于合并前验证源683eb81；构建点另列 | 11月2日同测试签名保留数据安装，快速走查通过；PR26合并点a201fd5，SDK当时d4502f3 |
| SDK0.6主线内部包；`3a449c33be01dbef35c635a346f35eb26be1154a` | 47.64 MiB；analyze0、454/0/68及重点24通过；SDK693cbc02 | 11月3日已构建、记录中未安装；PR28已合入main0737e4e，后续仅docs |
| UI r3 内部包；`00feee16ea049e636f3c43f900ce7a5902d10363` | 47.64 MiB；analyze0、test/hip 434/0/68；SDK693cbc02 | 11月3日已构建、记录中未安装；分支回执447ca1c，PR29仍OPEN/Draft，待用户远程反馈 |

主线 SDK0.6 包 SHA256 `4589119c89ef15c296ffc063a243af6fdc3c54b65c97d1281e239ababa17e169`，路径及完整身份见[原回执](sdk-pin-v0.6.0-validation-2026-11-03.md)。UI r3 包 SHA256 `86d918792e13ff15f736ca160102ba88e8757c94d0362d7ffe4dc9d811908d69`，本机路径 `E:/AII-3D/hiplab-releases/ui-r2-r3-00feee1-20261103/hiplab-1.1.0+30-00feee1-internal-arm64-release.apk`，完整来源见[候选报告](https://github.com/mhgd3250905/HipLab/blob/447ca1ca3471aa6504e43179cdedeaa1fb8120d0/docs/ui-r2-r3-validation-2026-11-03.md)。二者均com.ugk.hiplab、arm64 release、非debuggable、211公共封面/0MP4，沿用测试证书 `3761270a4764157f0e389014a9e5b800b05403bfddce0f4f7f8c039f6a53bdc7`；本轮仅引用已提交报告，未重新读取或核验产物。

GitHub 11月4日回读 #27合并点 `2647d4c60b8410ccbf0cc558c7fff88e816835bc`，#28合并点 `0737e4e3e34cc7116e03554e977a0d8e65b39267`。UI r2/SDK0.6旧“未合main”文字是当时快照。release/1.0远端为 `a20721e25044f87399ec633c93fb04d6d55c6ff4`，本轮未改、未上传商店、未更新发布状态。本机路径不代表产物已上传GitHub。

## 2026-11-03：SDK v0.6.0 候选测试与内部包完成

`codex/sdk-pin-v0.6.0` / Draft PR #28 的测试与构建源 `3a449c3`，SDK pin `693cbc02`。严格 analyze 0；全量 64 文件分 16 批共 454 通过 / 0 失败 / 68 既有条件跳过，四个重点文件 24 通过，无代码修复。1.1.0+30/2030 arm64 内部包 47.64 MiB、同测试签名、0 MP4，文件名含 3a449c3，未安装。App 界面固定中文，语音语言切换不能验收动作库界面切换；聊天单返回键仅代码核对，真机由用户远程安装抽查。不合 main、不动 release/商店，日常 WIP 未操作。[完整回执](sdk-pin-v0.6.0-validation-2026-11-03.md)。以下保留历史阶段。

## 2026-11-03：PR #27 r2候选验证完成，待用户远程安装

保留已确认的r2结构，仅修每日训练分钟重复取整，补混合组实际SDK阶段/组间休息/完成保存回归。验证构建源`f4714c6`；analyze0，64文件按4文件/批全部通过，含新增回归去重454通过/0失败/68条件跳过（opt-in截图/导出）。47.64MiB release候选保持+30/2030、同测试签名/0MP4，交用户远程安装验混合组和旧数据，本轮未安装。只正常字体，不合main、不升版、不动release/商店。[交付与APK身份](ui-r2-pages-integration-2026-11-03.md)。以下为历史阶段。

## 2026-11-02：PR #26 首页主题合入，+30 已保留数据安装

用户确认设计并授权合并，PR26在同步最新main后验证通过，合并点`a201fd5`；1.1.0+30/2030构建源`a7e371e`，47.70MiB release APK已同签名覆盖安装。analyze0、全量444通过/0失败/13条件跳过，额外截图4通过。正常字号浅深快速走查无新增显示问题，6天训练汇总、自测10/12、2组及主要设置保持；详细使用交用户。SDK仍d4502f3/211动作，日常40个WIP未变，release/tag/商店不动。[交付、脚本删除清单与验收边界](home-calm-r1-2026-11-02.md)。下方为历史阶段。

## 2026-11-02：1.1.0+29 全动作候选 APK（未安装）

分支codex/full-action-scope，构建/验证源`5072cbb291fe099fbbbd8e673a326e47e21808e8`；SDK四实际包/coach override完整pin d4502f35b1503d41cd782aa7fb3780c7f6591ad0，Flutter3.44.7/Dart3.12.2。1.1.0+29，com.ugk.hiplab，release arm64 split，versionCode2029，浏览/计划均211。严格analyze0、437通过/1既有条件跳过、Python25/25。日常原签名配置构建后连续测试重签，40个WIP逐字节恢复；未复制密钥、未安装或提交商店。

交用户APK：`E:/AII-3D/hiplab-releases/full-action-scope-20261102/completion-1714/hiplab-1.1.0+29-full-action-scope-arm64-device-release.apk`，**49,954,831 bytes（47.64MiB）**；SHA256`186a2c1ff2bb1ffa4dff41d75ec26671a13e02cf892be5080969cfe032f584a0`。证书SHA256`3761270a4764157f0e389014a9e5b800b05403bfddce0f4f7f8c039f6a53bdc7`，与既有测试安装连续。211公共封面、0 MP4、CRC/身份/签名及重签前后运行负载一致性通过；原上传签名包同目录另存。只推分支、不合main、不打tag、不动release。[完整交付](full-action-scope-completion-2026-11-02.md)。

## 2026-11-02：+28 用户真机通过并合入 main（无新制品）

用户确认已交付的1.1.0+28/2028真机测试通过并批准集成，main快进并普通推送到 `d0c28c59976e32d58e4999b524bb40c60ee3672a`，远端回读一致。沿用下方43.40MiB原APK，不重建、不重新安装、不提交商店。后续 `codex/full-action-scope` 受SDK8项训练元数据缺失阻塞；版本尚未递增到+29，未产生+29 APK。[回执与缺项](full-action-scope-2026-11-02.md)。

## 2026-11-02：1.1.0+28 共享体验最终候选 APK（未安装）

构建源`2d3070d375b546bad0dcc453b548ecb0ace818d9`、分支codex/sdk-shared-experience，SDK完整固定d4502f35b1503d41cd782aa7fb3780c7f6591ad0；Flutter3.44.7/Dart3.12.2、com.ugk.hiplab、release arm64 split、versionName1.1.0/versionCode2028。在日常目录使用原签名配置和Worker外部defines构建，未复制密钥；原上传签名包另存，同运行负载重签为此前手机连续测试证书。

交用户包：`E:/AII-3D/hiplab-releases/sdk-shared-experience-20261102/hiplab-1.1.0+28-shared-experience-arm64-device-release.apk`，**45508800 bytes（43.40MiB）**，SHA256`d0ee06277e37753d00020de937ad8706bc2ea21d122c5411df9a7f7d4ab061e0`。证书SHA256`3761270a4764157f0e389014a9e5b800b05403bfddce0f4f7f8c039f6a53bdc7`，可连续保留数据覆盖升级；不得卸载/清数据。验包确认0 MP4、46公共poster、CRC/签名/身份正确，重签前后运行负载一致。

用户16:19授权删除11条2倍字号用例后，严格analyze0、全量428通过/1既有条件跳过；门禁通过后才构建本包。手机已拔线，本轮未安装，视觉/旧数据界面/真实操作待用户自行验证；不把静态验包记为真机通过。不合main、不动release、不tag、不上传商店。[报告与删除清单](sdk-shared-experience-completion-2026-11-02.md)。下方首次诊断包仍为NOT-ACCEPTED历史。

## 2026-11-02：+28 启动修复，未重建 APK

`codex/sdk-shared-experience`启动修复源`1f76e745da30133b8b38986d27c2f1b9e5df7791`，共用版本仍1.1.0+28，arm64 versionCode仍2028，SDK仍完整pin d4502f35b1503d41cd782aa7fb3780c7f6591ad0。最小/断网启动通过、analyze0；全量385通过/19失败时确认SDK动作库键盘布局问题，按边界停止，**没有重建或交付新APK，包体无新值**。下方46604271 bytes的0 MP4诊断包仍不是交付包，不将旧包改记为新修复包。手机未安装，main/release/商店不操作。[启动诊断](sdk-shared-experience-2026-11-02.md#启动定位更新2026-11-02)。

## 2026-11-02：1.1.0+28 首次诊断构建（未验收、非交付包）

codex/sdk-shared-experience基于main0f507a3，SDK统一d4502f3，固定Flutter3.44.7，在日常目录复用原签名配置构建release arm64 split（共用+28，对应versionCode2028）。首次APK为46604271 bytes（44.45MiB），包内0 MP4，保存为`E:/AII-3D/hiplab-releases/sdk-shared-experience-20261102/hiplab-1.1.0+28-pass1-upload-signed-NOT-ACCEPTED.apk`。

首次包早于单练按钮/自测点击层修复及旧剪影退包；两轮Flutter门禁仍失败，按用户要求停止，没有最终候选APK、设备签名重签或安装。不用此包代表最终分支验证，不更新手机安装身份；main/release/商店均未操作。[本轮报告](sdk-shared-experience-2026-11-02.md)。

## 2026-11-02：1.1.0+27 SDK 对话模块候选 APK（未安装）

分支 `codex/coach-chat-sdk`，运行源 `60d3c372e853aada88eb8d441f04e733860dfca2`，SDK 统一固定 `7d9be56a6c02b7a28e3d5d5cd9f6c3f1a23ac723`。Flutter 3.44.7 / Dart 3.12.2 release arm64，versionName1.1.0 / versionCode2027（split ABI偏移2000+27），包名com.ugk.hiplab。原上传签名 APK 与同运行负载的手机测试证书重签 APK 均保存于非C盘证据目录。

交用户安装包：`E:/AII-3D/hiplab-releases/coach-chat-sdk-20261102/hiplab-1.1.0+27-coach-chat-sdk-60d3c37-worker-arm64-device-release.apk`，106781267 bytes，SHA256 `f9ac4b6186c7b665a56c7fe0a0549d3f66b9e0f65ba4b62eef01eb1220c4c0e7`。证书 SHA256 `3761270a4764157f0e389014a9e5b800b05403bfddce0f4f7f8c039f6a53bdc7` 与此前从手机读取的+26一致，可保留数据覆盖升级；不卸载、不清数据。

最终 analyze0、Flutter446通过/1条件跳过、Python25/25、四段真实模型通过；签名/资源/CRC/16KB/JNI及 Worker 配置静态核对通过。用户已拔线，明确由本人安装并测试真实操作/旧数据界面/视觉，本轮**未安装、未进行真机验收**。main/release不动、不tag、不上传商店。[一页报告](coach-chat-sdk-2026-11-02.md)。

## 2026-10-24：SDK 修复 tag 更新，未重建或安装

已合入并推送main的功能集成点88d8802，从5c4d32e改锁coach0.4.2 / trainer0.2.2 / coach_ui0.1.1（同3302d62），共用App版本保持1.1.0+21；本轮未生成新APK/IPA/AAB，手机仍是源429eaf5/SDK旧tags的已验5d292388…测试包。用户明确允许无需源码适配时沿用真机证据，本轮不冒充新tag原生安装。release/1.0的1.0.0+20及已送审产物身份不动。[补丁及主线回执](sdk-tag-patch-2026-10-24.md)。

## 2026-10-24：1.1.0+21 SDK 共用界面待审包

运行源 `429eaf5c0e952d60199ca95362bd3dd2880f8606`，分支 `codex/sdk-shared-ui-20261024`；后续测试/文档提交不改运行代码。coach0.4.1 / trainer0.2.1 / coach_ui0.1.0均锁正式tag，Pose-Hub仍v0.2.0；release/1.0保持1.0.0+20。

| 产物 | 身份与用途 |
|---|---|
| `E:/AII-3D/hiplab-releases/sdk-shared-ui-20261024/hiplab-1.1.0+21-arm64-release.apk` | 104134291 bytes；SHA256 `9fa080472102ad6c42cb4fc2fb76ff93daf4ac4494b65a7b9ac848a3ccedc685`；上传证书签名的本地编译结果，未上传任何商店 |
| 同目录 `hiplab-1.1.0+21-device-test.apk` | 104240666 bytes；SHA256 `5d2923880587bf9c57e3493bb5de136c575384f2b1beaa67f6e4491d3827ee0a`；同一release运行负载重签为原手机测试证书，以保留数据覆盖安装 |

包名 `com.ugk.hiplab`，versionName1.1.0、versionCode21、min24/target36、arm64-v8a，无AI Key。真机证书SHA256 `3761270a4764157f0e389014a9e5b800b05403bfddce0f4f7f8c039f6a53bdc7`与原0.3.10+19完全相同；不卸载、不清数据。首个缺插件注册的试装失败已留档；最终补Flutter生成后重编译，正常覆盖启动。签名密钥和key.properties不入仓库。

分析0、完整测试集合451通过/1跳过，分批证据和未验范围见[验证台账](verification.md#2026-10-24sdk-共用界面候选验证)；安装、真机完整训练及数据保持的实际结果见[接入报告](sdk-shared-ui-2026-10-24.md)。当前未合main、未推送开发分支或商店；合main/推送等待开哥同意。


## 2026-10-24：iOS 1.0.0(20) TestFlight

- App：HipLab，复用 Hip Interlude / `com.ugk.hipinterlude`；编译源 `e7ac0836eb69e1cc81c53660ac4f94e270b46538`。
- 最终 Organizer 上传 IPA：104,827,002 bytes，SHA-256 `e2203298729d6ced8ec9b09e2a8086a55dfe22c960fc60ac35ab8d0027d5f0ea`；Archive、IPA 与原生截图在本机 Git 忽略目录。
- 13:57 Xcode 上传完成、ASC 记录13:58；Apple处理完成，Build `97aa451f-dede-40b7-aebf-ef2ad456257a`，开哥个人内部组“正在测试”。未新增测试员或外部分发，未提交正式审核、未改商店资料。
- 真机iPhone16Pro/iOS26.5从TestFlight安装，回读1.0.0/20；启动、视频和平台入口已验。后续锁屏观察进程未重启、无新Runner崩溃，重连时训练为暂停，手动结束保存45秒/0-of-6/未完成测试记录。用户明确声音专项跳过，首版优先申请，完整训练/锁屏持续播放由其后续使用反馈，不记为实测通过。两尺寸各6张原生截图及文案/隐私/审核备注草稿已准备。[完整候选及边界](release-1.0/ios/README.md)。

## 2026-10-24 13:09：1.0.0+20 Alpha 已提交审核

沿用本页下方已核验的4b56b82编译AAB，139,920,761字节 / SHA256 51e3ebe86e23189067e6defe033a041b60934fca98a4e7f58ea62e6eea4a4478，不重建、不递增版本。Google识别20(1.0.0)、min24/target36/3ABI，估算新装下载91.3MB；仅有体积增大警告，无阻塞版本错误。

Alpha Release2及商店5项更改已送审，提交ID2、状态审核中；mediaPlayback声明已更新并含[YouTube演示](https://youtube.com/shorts/GRzBK2GvXRU)。当前无Production发布或审核通过结果，测试者0/12和14天门槛仍待用户后续组织。隐私gh-pages发布7ecda06/HTTP200，128秒原生模拟器视频已不公开列出。新证据在E盘play-submission-20261024目录，不进Git；原手机安装未变。[完整回执](play-store-release-2026-10-24.md)。

## 2026-10-24：1.0.0+20 上传签名 AAB

构建源码 `4b56b827cf635e05ac55281bc37e7bd9dff7fa09`，由main e456d2a的基础版派生，未带入AI0.2或液态玻璃候选。Flutter3.44.7 stable，SDK固定d193a703e3a8bef6d41e7705a55ae250e23e6a69。执行 `flutter build appbundle --release --no-pub`，183.9秒成功，无Key/私有define文件；版本1.0.0+20，包名com.ugk.hiplab，min24/target36、non-debuggable。

AAB：`E:/AII-3D/hiplab-releases/1.0.0+20/hiplab-1.0.0+20-release.aab`，**139,920,761字节**，SHA-256 **51e3ebe86e23189067e6defe033a041b60934fca98a4e7f58ea62e6eea4a4478**。上传证书SHA-256 **8f8c114e8e1f8650d3e461abaf2a1c719e11ab390bb0ba285c87bb072433b7ad**，与旧Play上传证书一致；密钥/密码未入Git，F盘受限备份与原件SHA匹配，同机备份不代表异地备份。

bundletool1.18.3 validate、jarsigner验证、合并清单/单mediaPlayback服务、三ABI native ELF 16KB及universal APK zipalign16KB通过。证书自签名/无时间戳为上传密钥的常见jarsigner提示，不是采用debug证书。当前只构建/本机验证，未操作Play、未上传或送审。新包未覆盖用户真机；用户报告现有App已测试通过。最终身份和截图来源见交付目录release-identity.json及[本轮说明](release-1.0/README.md)。

## 2026-10-21：训练包复核 Web 临时构建

App 源 `cb7ae4f2c50ce40243dbba0537ec0fa1aefdb637`，固定 SDK d193a70，版本保持 0.3.9+17。在 `build/trainer-recheck-20261021/web-preview/` 以 Flutter 3.44.7 release 编译真实 main.dart，45.1 秒成功；main.dart.js 3,729,931 字节，CanvasKit wasm 7,229,467 字节。58 个 lib 文件及 pubspec/lock 与工作区逐字节相同，原资产通过 E 盘 junction 使用。临时预览 `http://127.0.0.1:8769/` 仅供本机测试，没有部署网站或上传商店。

Web 核心路径与全量 440 项通过，证据见[验证台账](verification.md#2026-10-21-训练包接力复核)。本条只登记 Web 构建，不是新 APK、安装或原生验收；没有 ADB/手机操作。以下最近一次 Android 构建与安装历史保持，锁屏失败仍保留。

**最新构建与安装：0.3.9+17 / debug arm64。** 运行源 `79c172d9a83d248f23e136cffe825f3bd016e16b`，SDK `d193a703e3a8bef6d41e7705a55ae250e23e6a69`（coach0.1.3/trainer0.1.4）；175258975字节，SHA256 `09e11efd96f284aeb642e0b46b05843916b061d0e06e40160089cbeeca08ce51`。已保留数据安装，21记录/4组/UUID保持；锁屏冻结仍失败，由用户后测。SDK main d193a70及HipLab集成点691ace2已获准合入并推送，无商店发布。[当前交付与合并](android-lockscreen-fix-2026-10-21.md#主线合并确认2026-10-21)。

以下逐次构建、安装与失败记录保留当时状态，后续追加不改写原始观察。

**2026-10-20 +15安装及失败快照（历史）：** 来源f8f0ec8、夹具ab963d7、SDK8ef37a9；175257947字节，SHA256 `34e337b8760cb1bd709824282ab6d8b88efe2f19d2959b5f9d98714c14d52829`。保留数据安装、UUID及手机AI生成保存通过；失败课程主动结束后现20记录/4组，训练服务已释放。main未合，无商店发布。[本轮完整证据](ai-relay-migration-2026-10-20.md)。

**早间0.3.7+12构建快照（历史）：** 来源55d99b3，debug arm64，175043055bytes，SHA256 `4846f335c4a8f100b17c6b9548a46d950011baa57e93c035e9735e3d24c8e052`；当时只构建未安装，包名/签名连续、876个资源匹配、CRC通过。[早间产物身份](android-test-build-0.3.7-2026-10-20.md)。

**2026-10-20 PR25修复审核构建（未安装）：** 运行源8c985c4，0.3.6+11带令牌debug arm64，200749347bytes，SHA256 `33f54f20f47b3b25357b4ee83bb6a57620b1d3167b1a878e15a8a3f8a09b3636`，原debug证书连续。PR25现已获准合main并推送；产物只构建未安装，版本未递增、未发布，手机仍按10月19日最后已验记录。[复审及合并](pr25-reaudit-2026-10-20.md)。

仅登记实际产生的构建、安装或发布。文档提交不增加 App 版本；“安装成功”“PR 合并”“商店发布”分别记录。时间均为北京时间。版本来源和各状态维护规则见[版本管理说明](version-management.md)。

**此前最后已验安装：0.3.6+11 debug / arm64**，构建源码 `9b22dccc2bf2ca269a67b408198b9e3e9dbb742b`；2026-10-19 23:15:53保留数据安装。APK为174,518,862bytes，SHA256 `f40f5956fa3bdae49872e525fced310257102c6b4f7638eb28911e18ec4b91bd`；身份及安装过程见本页末尾“PR22 F9 / PR24组合复审包”。该运行内容已随b33ed21合入main，该次#22/#24合并收束未新增构建、安装、版本或商店发布记录。

此前0.3.6首轮交付摘要（历史）：源码 `66f5da034c0cdac3341f3e80a57e3ddae5f95dce`，2026-10-18 19:29保留数据安装。下表为2026-10-17早期交付历史。

| 版本 | 交付日期 | 状态 | 内容与证据 |
|---|---|---|---|
| 0.1.0+1 | 2026-10-17 | Android debug 首次安装、启动通过 | 原迁移基线 `2865ed7`，首次安全引导截图；[首次运行记录](android-first-run-2026-10-17.md)下半部分 |
| 0.1.1+2 | 2026-10-17 13:15 | Android debug 保留数据覆盖安装、冷启动、视频播放通过 | 应用提交 `35f2a977530bdcc6ab7e7caa9aa1d76dfe0bc53d`；46 动作 + 1 自测剪辑、47 张封面升级至 1080；[更新记录](android-first-run-2026-10-17.md)上半部分 |
| **0.1.2+3** | **2026-10-17 14:37** | **Android debug 保留数据安装、冷启动与桌面图标确认通过** | 应用提交 `4cf5ca7990949d025e02f13fc83e468f8bab9d07`；用户选 B 站姿开髋，普通/圆形/Adaptive/Monochrome 资源；[图标交付](app-icon-sports-2026-10-17.md)、[PR #5](https://github.com/mhgd3250905/HipLab/pull/5) |
| **0.2.0+4** | **2026-10-17 20:59** | **正式签名 release 已上传；Alpha Submission ID 1 状态“审核中”；尚未审核通过或正式上架，用户真机仍为旧版** | `codex/play-store-release` / `19aa388`，已推送并创建 [PR #10](https://github.com/mhgd3250905/HipLab/pull/10)，main 未合并；analyze 无问题、50 项测试及 API 35 模拟器实播/断网政策通过；[送审回执](play-store-release-2026-10-17.md) |

以上版本均非商店发布。0.1.1+2 通过 [HipLab #2](https://github.com/mhgd3250905/HipLab/pull/2)、[HipLab #1](https://github.com/mhgd3250905/HipLab/pull/1) 集成至 main（首次业务集成 `656ee28`），该次安装基线为 `35f2a97`。后续图标版本 0.1.2+3 由 PR #5 记录；不能将文档提交或合并当成重新构建、安装。

## 本轮追加：送审与本地集成

| 版本 | 日期 | 状态 | 身份与边界 |
|---|---|---|---|
| 0.2.0+4 | 2026-10-17 20:59 | Alpha 已送审 | 正式上传证书，Submission 1 当时为审核中；源码 `19aa388`，#10 未合并；[送审回执](play-store-release-2026-10-17.md) |
| **0.3.0+5** | **2026-10-17** | **三阶段 debug APK 构建、保留数据安装通过** | #7 + 修复 `3eb175d` → 加 #8 `025f675` → 加 #9 `c8057ad`；本地验证分支未推送/未合并/未送审；[本轮记录与三个 SHA](android-round1-integration-2026-10-17.md) |

最终 APK：`E:\AII-3D\hiplab-releases\round1-validation-20261017\stage3-pr7-pr8-pr9\hiplab-0.3.0+5-debug-arm64.apk`，176,624,651 bytes，SHA256 `28143d19339b9d28c3ec65c5e200423a8b76a05e0acd2427dd596f5bf80a66d7`。原 0.1.2+3 debug 证书一致；安装前后 1359 bytes 设置文件一致。音乐实测用户选择稍后；该 APK 不是新的 Play 产物。

## 0.1.1+2 产物身份

| 项目 | 值 |
|---|---|
| 包名 / versionCode | `com.ugk.hiplab` / `2` |
| APK 归档路径 | `build/apk-history/hiplab-0.1.1+2.apk`，相对于仓库根目录 |
| 类型 / 大小 | debug 通用多 ABI / 203,896,543 字节 |
| SHA256 | `a9dcd836a91452a309154ae6b1a4da7db5c72e086c8bb44e123cfaecad69a2ce` |
| 原始动作源 | `175ff31c29895f5730fc344519da6cbe1108ab30`，已由 3D-Body #119 合并；三项派生修订及工具见 #120 `f8b5138` |
| 最终母版选择 | `E:\AII-3D\3D-Body\output\hiplab-delivery-20261017\selected-masters-46.json` |
| Android 派生批次 | `E:\AII-3D\3D-Body\output\hiplab-android-20261017-v2`；逐条元数据见 [hip-media.json](../tools/hip_content/source/hip-media.json) |
| 设备 / 数据 | 2602BRT18C / Android 16；覆盖安装前后 609 字节设置文件逐字节一致 |
| 验证 | 静态分析无问题、Flutter 49 项、同步工具 11 项、原生 WebView 一条实播；详见[验证台账](verification.md) |
| 本地证据 | `build/android-update-20261017/`；`build/media-audit/assessment-hd-sync-audit.json` |

APK 会被下次构建覆盖，以上 SHA 用于识别本次产物。旧版 APK 已归档到 `build/apk-history/hiplab-0.1.0+1.apk`，95,489,848 字节，SHA256 `efa0efd7e65e51a7c9f40d51937c83804411b4545cdf5248190425a9c48864f8`。本地 APK、截图和设置备份不在 Git 中；用户数据备份不得提交仓库。

## 0.1.2+3 产物身份

| 项目 | 值 |
|---|---|
| 包名 / versionCode | `com.ugk.hiplab` / `3`，旧版与新版 debug 证书 SHA 一致，均通过签名验证 |
| 代码提交 | `4cf5ca7990949d025e02f13fc83e468f8bab9d07`，其后的文档/设计状态更新不改变已安装应用 |
| APK / 归档 | `build/app/outputs/flutter-apk/app-debug.apk` / `build/apk-history/hiplab-0.1.2+3.apk` |
| 大小 / SHA256 | 204,100,257 字节 / `1790469a46ac1b0195599a92c419baa3bb1c4b143dd8027bfd79d93d7a840c64` |
| 图标 | 用户认可 B 站姿开髋；五档普通/圆形，v26 Adaptive，v33 Monochrome；[原图、前景与导出](../design/app-icon/launcher-20261017/README.md) |
| 构建与检查 | analyze 无问题，49 项 Flutter 测试通过，Gradle 18.8 秒；29 文件 SHA、20 PNG 尺寸、4 XML 和编译入包层核验通过 |
| 安装与显示 | 2026-10-17 14:37，`adb install -r` 成功，Android 16 冷启动正常；`com.miui.home` 桌面已查看新图标，App 首页正常 |
| 用户验收 | 2026-10-17，用户在本次更新后反馈“测试通过了” |
| 数据保持 | 本次安装前设置为 1195 字节，安装后、冷启动后、桌面检查后逐字节一致；SHA `21bee487722bef25928b8541a26dc1959773ee6be5db42b487f6adc77c292255` |
| 本地证据 | `build/android-icon-20261017/`：APK/安装/桌面核验 JSON、编译图标 XML、日志与截图；用户数据与截图不入 Git |
| 未验证 | iOS 图标/构建、正式矢量、商店发布、设备端主题图标切换；单色资源已做导出/离线预览 |

## 0.2.0+4 Play 准备阶段（2026-10-17）

正式上传 key 的 release 构建已产生，包名 `com.ugk.hiplab` / versionCode `4`。源码已提交为 `codex/play-store-release` / `19aa388`，开工 HEAD `9aeb268`；该代码提交对应本次最终构建源码，包含正常网络权限用于 loopback 媒体读取及离线隐私政策入口。analyze 无问题、50 项 Flutter 测试通过；API 35 模拟器 host GPU 的 release 实际播放及断网隐私页验证通过，用户真机仍安装 `0.1.2+3` debug。

| 项目 | 最终产物身份 |
|---|---|
| 本地归档目录 | `E:\AII-3D\hiplab-releases\0.2.0+4`，仓库外部本机目录 |
| AAB | `hiplab-0.2.0+4-release.aab`，102,859,951 字节；SHA256 `36468F42FAED30F98C56E4F229BE41B92C744745C81BA2F66E5C0C9ABC3AE747` |
| APK | `hiplab-0.2.0+4-release.apk`，103,992,845 字节；SHA256 `75ED33E237D0CF5B74ED14F5BC7DC6BBE45BC208A64A5C6FE2BE472928C07902` |
| 签名核验 | AAB `jarsigner`、APK `apksigner` 通过；上传证书 SHA256 `8f8c114e8e1f8650d3e461abaf2a1c719e11ab390bb0ba285c87bb072433b7ad` |
| 验证设备 | `emulator-5554` / API 35 / host RTX 4080 GPU；用户真机未覆盖 |
| 非敏感运行证据 | 上述目录下 `release-verification-20261017`，详情见[验证台账](verification.md) |
| 16 KB 页对齐静态检查 | SDK 36 `zipalign -c -P 16 -v 4` 通过；三种 ABI 共 9 个 `.so` 的 ELF 对齐及 AAB/APK 库身份检查通过；未做 16 KB 内核设备运行验收 |

产物和签名材料保存在本机，不代表已备份到远端。Play 商店资料、素材和内容声明已保存，Alpha AAB 平台处理完成；20:59 确认将 15 项更改送审，提交活动回读 **Submission ID 1 / 状态“审核中”**。尚未审核通过或正式上架。详见 [Play 送审记录](play-store-release-2026-10-17.md)，本节不把构建、安装、送审和正式发布互相替代。

## 后续登记模板

新交付在版本表追加一行，并按下列字段记录；未执行项写“未执行”，不能用预计结果填充。

```text
版本 / versionCode：
时间 / 构建类型 / 签名类型：
代码提交 / PR / main 是否已集成：
改动与关联事项 ID：
APK 或 AAB 路径 / 字节数 / SHA256：
媒体批次（如有变化）：
检查命令、结果与证据路径：
安装设备、数据保留结果（如执行）：
已知问题、未验证范围：
商店发布状态（如执行）：
```

## 0.3.1+6 / 0.3.2+7 主干交付（2026-10-18）

| 版本 / 源码 | 产物与状态 | 验证 |
|---|---|---|
| 0.3.1+6 / `6177cc1` | 单屏自测 debug arm64 已安装，用户确认看过、验证通过；后由 `05ac3d7` 合入 main | 固定正方形 contain、标题置顶、去圆点/进度条、点击暂停继续；115 项测试及 analyze / APK 通过 |
| 0.3.2+7 / `963db04` | Pose-Hub 初步 APK，同证书保留数据安装，当前手机仍为此源码 | 116 项测试、analyze、APK；六动作完整循环通过，录屏发现首帧交接变暗 |
| **0.3.2+7 / `9ef59a1`** | **首帧修复最终 APK 已构建并推送 main；用户拔手机，尚未覆盖安装此修复** | **116 项单并发通过、analyze 0、Chrome/H264 回归通过；四尺寸网页单屏检查通过，原生首帧复验待补** |

单屏 0.3.1+6 APK：`E:\AII-3D\hiplab-releases\assessment-demo-20261018\single-screen\hiplab-0.3.1+6-debug-arm64.apk`，150,802,408 bytes；SHA256 `618da12ec15a304c28920fb5c669c3ddfc7b00a90c794d409c763e24d685568d`。

| 0.3.2+7 产物 | 字节数 / SHA256 |
|---|---|
| 已安装初步版：`E:\AII-3D\hiplab-releases\mainline-20261018\posehub\hiplab-0.3.2+7-debug-arm64.apk` | 150,739,180 / `d1fcb0843b0078034db8ef0143708ec54d912b1d14b015cef7262b7c8f42ed18` |
| 最终修复版：`E:\AII-3D\hiplab-releases\mainline-20261018\final\hiplab-0.3.2+7-debug-arm64.apk` | **150,742,085 / `6509ecca36162afc92737e3d3628c075b13c22d2814717763e6142df501fdfe1`** |

包名 `com.ugk.hiplab`，versionCode 7，最终 APK apksigner 核验成功，debug 证书 SHA256 `3761270a4764157f0e389014a9e5b800b05403bfddce0f4f7f8c039f6a53bdc7` 与手机既有版本一致。安装阶段原 1356 bytes 设置逐字节保持；六动作测试产生的当天打卡已单独撤回，重启后原设置 SHA `74f83f14c7ef77da8cdf08e6886a5401ee86aa325a7f653f68a3fea5b6b07c21`。

main 按 #7/#8/#9/rebased #10 集成，四 PR 均回读 MERGED；素材固定 Pose-Hub v0.1.0、`--check` 92 / 0 drift；详见[主干交付记录](mainline-pose-hub-2026-10-18.md)。本节是本机 debug 交付，未生成或上传新的 Play release；0.2.0+4 / Submission 1 保留其原始送审状态。

## 第二轮 APK 交付（2026-10-18）

| 项目 | 实际结果 |
|---|---|
| 版本 / 类型 | 0.3.3+8 / debug arm64 |
| APK 运行源码 | `1b35657dec153741e25ca095ac2764b18d14ac29` |
| 行为检查源码 | `162a4e6b78a8640d367cac13ef5e1ae6cfa9b33a`：analyze 0，Flutter 156 项通过、1 项按设计跳过 |
| APK 路径 | `E:/AII-3D/hiplab-releases/round2-20261018/final/hiplab-0.3.3+8-debug-arm64.apk` |
| 字节数 / SHA-256 | 151,888,384 / `9ec9dbe4df19f625f38ffabb6448c479525b21dc138c60e8ca16e23afa688506` |
| 包与签名 / 资源核验 | 包名 com.ugk.hiplab、versionCode 8、预期 debug 证书及 488 条语音 / 92 个 Pose-Hub 资源 / 22 个保留文件核验通过；内容重生成无变化；Python 11 项及 iOS 工程静态检查通过。最终构建 26.96 秒，未安装手机 |
| 安装 | 未安装；手机仍为 `963db04` / 0.3.2+7，本轮无 ADB |
| 远端 | 业务代码 `1b35657dec153741e25ca095ac2764b18d14ac29` 已于 2026-10-18 10:04 北京时间推送 main；PR #13：MERGED（a41e7e0）；PR #14：MERGED（4c563f9） |

PR #13 阶段源码 `a41e7e0`、C 盘两次缓存失败及 E 盘同 SHA 构建成功保留在[第二轮集成记录](round2-integration-2026-10-18.md)，不覆盖其 151,821,564 bytes 阶段 APK，也不混用早期候选 APK。没有新商店上传或审核回执。

阶段产物均未安装：#13 `a41e7e0` / 0.3.2+7（151,821,564 bytes），#14 `4c563f9` / 0.3.2+7（176,826,741 bytes），后续候选 `162a4e6` / 0.3.2+7（176,826,917 bytes）；各 SHA-256 与检查结果见[第二轮集成记录](round2-integration-2026-10-18.md)。

## Pose-Hub v0.2.0 App 产物（2026-10-18）

| 项目 | 结果 |
|---|---|
| App版本 / 源码 | 0.3.4+9 / `03c3b5bcd1ebc0157e3789af21a4bf0188f52468` |
| APK | `E:\AII-3D\hiplab-releases\posehub-v020-20261018\validation\hiplab-0.3.4+9-debug-arm64.apk` |
| 字节数 / SHA | 150,880,644 / `ded02ba1f26c263c6e0d8c88d62a4b0fe43f6e6a5dba9a29baf6ba21773d4e75` |
| 媒体 | v0.2.0，46视频1080 /46封面540 |
| 核验 | 包名com.ugk.hiplab、versionCode9/versionName0.3.4、既有debug证书匹配；包内92新素材、22自有文件、488语音及共享播放器与源码匹配；未安装 |
| 安装 / 远端 | 未安装，无ADB；业务代码 `03c3b5bcd1ebc0157e3789af21a4bf0188f52468` 已于 2026-10-18 11:40 北京时间推送 main |

上一轮0.3.3+8及手机0.3.2+7记录保留；不是商店包，不新上传商店。详见[Pose-Hub v0.2.0 接入](posehub-v020-integration-2026-10-18.md)。

## 指定媒体分支合入后的复打包（2026-10-18 11:55）

| 项目 | 实际结果 |
|---|---|
| 分支 / 起点 | `media/pose-hub-v0.2.0` / `bb828be`；已快进集成原有 v0.2.0 成果并合回、推送 main |
| 构建源码 / 版本 | `1a1657da91ea4b2d2a189e1439f370ed6d083e24` / **0.3.4+9 debug arm64** |
| APK 路径 | `E:\AII-3D\hiplab-releases\posehub-v020-request-20261018\final\hiplab-0.3.4+9-debug-arm64.apk` |
| 字节数 / SHA-256 | 150,880,644 / `ded02ba1f26c263c6e0d8c88d62a4b0fe43f6e6a5dba9a29baf6ba21773d4e75` |
| 实际构建 | 合入并推送 main 后执行 `flutter build apk --debug --target-platform android-arm64 --no-pub`，exit 0，17.42 秒 |
| 包与资源核验 | 包名 `com.ugk.hiplab`、versionCode 9、既有 debug 证书匹配；92 新素材、22 自有文件、488 语音及共享播放器匹配源码 |
| 与前包关系 | 与 `03c3b5b` 的 0.3.4+9 APK 逐字节一致；本次只恢复未变工具的原来源头并补分支/文档，按版本规则不再次递增 |
| 安装 / 发布 | 未安装、无 ADB；未上传商店或 TestFlight |


## Android 0.3.4+9 保留数据覆盖安装（2026-10-18 17:15）

| 项目 | 实际结果 |
|---|---|
| 设备 / 包名 | 2602BRT18C / Android 16 / arm64；`com.ugk.hiplab` |
| 更新 | 0.3.2+7 → **0.3.4+9 debug**，`adb install -r` 返回 Success，设备回读 versionName 0.3.4 / versionCode 9 |
| APK 源 / 主线 | `1a1657da91ea4b2d2a189e1439f370ed6d083e24` / `5c7dc8e`（后者仅文档收尾） |
| APK | `E:\AII-3D\hiplab-releases\posehub-v020-request-20261018\final\hiplab-0.3.4+9-debug-arm64.apk`，150,880,644 bytes；SHA-256 `ded02ba1f26c263c6e0d8c88d62a4b0fe43f6e6a5dba9a29baf6ba21773d4e75` |
| 签名连续 | 新旧 APK 均为既有 debug 证书，SHA-256 `3761270a4764157f0e389014a9e5b800b05403bfddce0f4f7f8c039f6a53bdc7` |
| 数据备份与保持 | 安装前备份 shared_prefs/files/databases/no_backup 中实际存在目录，tar 4,204,032 bytes、可读取；偏好 1356 bytes，安装后及启动后逐字节一致，SHA-256 `74f83f14c7ef77da8cdf08e6886a5401ee86aa325a7f653f68a3fea5b6b07c21` |
| 启动 | COLD / Status ok，TotalTime 1677 ms；App 前台，首页已查看，当前进程 crash 日志未见 FATAL EXCEPTION |
| 检查范围 | 仅安装与启动；未进入训练/自测，未测试原生首帧或系统音频，未上传商店 |
| 本机证据 | `E:\AII-3D\hiplab-releases\android-install-20261018-171428`；含原包、签名、数据备份、安装与启动日志、版本回读、截图，均留本机，不代表 Git 备份 |

## Android 0.3.5+10：静音场景语音修复与安装（2026-10-18 17:36）

源码 `b3bd499a6eba1b2c4c72dc6625b6257d9288a5f7`；修复 Android 音频 usage，版本0.3.4+9 → **0.3.5+10**。APK `E:\AII-3D\hiplab-releases\android-audio-fix-20261018\validation\hiplab-0.3.5+10-debug-arm64.apk`，150,885,612 bytes，SHA-256 `9aec5a354e2a521ea791822cb64b403c293d901c41849efe137645b562e51a33`。同包名/同debug证书覆盖安装成功，设备回读versionCode10；安装、启动、试听后1355字节偏好保持（以安装前当前数据为基线）。用户确认完整试听恢复；未上传商店。构建和检查、原生证据及未验范围见[Android 静音模式语音修复](android-voice-media-routing-2026-10-18.md)。

## 0.3.6+11：浅色控件与文字、隐私顶栏（2026-10-18）

业务源码 `66f5da034c0cdac3341f3e80a57e3ddae5f95dce`。`flutter build apk --debug --target-platform android-arm64 --no-pub` 成功（Gradle 23.1秒）；同包名、既有debug证书，versionName0.3.6/versionCode11。APK `E:/AII-3D/hiplab-releases/theme-polish-20261018/hiplab-0.3.6+11-debug-arm64.apk`，150,886,340 bytes，SHA-256 `78e766d76a083a519d703a88001a26cbfe8d8193d55125b2393f5a1d80ceb4f8`。包名/签名/ABI与114媒体/488语音+5提示音核验通过。analyze0；158pass/1条件skip；网页复查通过。**构建完成时尚未安装**，手机当时为0.3.5+10；19:29安装见下一节。未上传/发布商店。见[样式修复记录](theme-polish-2026-10-18.md)。

## 0.3.6+11 安装追加（2026-10-18 19:29）

同上已归档APK（源码`66f5da0`，SHA-256 `78e766d76a083a519d703a88001a26cbfe8d8193d55125b2393f5a1d80ceb4f8`）经`adb install -r`返回Success，从0.3.5+10更新至0.3.6+11，设备2602BRT18C / Android16，冷启动首页及浅色滑块已查看。当前偏好1356字节在安装/启动/截图后保持，SHA-256 `b4ac5a3817155431b4a0b445fd12d8941852ea99fafd86956f0da153a505a5a4`；完整数据tar已备份且可读。本次未重构建、未修改版本、未上传商店。

## 0.3.6+11初审组合验证包（2026-10-18，历史）

源5711b42，150,894,768bytes，SHA256 `e79052fd4015935ed6f1e72b230213d2f9814846919d3ff0bbad5c26be225847`，曾保留数据安装用于#17/#18初审。发现两项P2，当时未合main；该包已被下述修复包替代。[原审核与数据边界](https://github.com/mhgd3250905/HipLab/blob/be782b74b3eefe782803aebf26b5224c33c0c3d7/docs/pr17-pr18-device-review-2026-10-18.md)。

## 0.3.6+11转场与按钮修复包（2026-10-18）

源码 `6dd16eda246657d1de8ddf9e92b8e91d992c3a80`；包名与debug签名连续，Gradle49s构建。APK `E:/AII-3D/hiplab-releases/pr17-pr18-fixes-20261018/hiplab-0.3.6+11-pr17-pr18-fixed-debug-arm64.apk`，150,903,412bytes，SHA256 `34bae5ac3a17a1906f390336e17292a5ba7078d0f822413c9a2a25e822286c0a`。`install -r`成功，设备0.3.6/code11，冷启动1316ms；测试前/安装后/复查后1356字节偏好相同。#17/#18随后23:35:52/23:36:26顺序合入main，运行内容保持。本轮版本未递增、不上传商店；[完整证据](pr17-pr18-fixes-and-merge-2026-10-18.md)。

## 0.3.6+11 PR #19/#20/#21 隔离构建与模拟器安装（2026-10-19，未合main）

两份APK均源于 `e3fb1d31d3d490dbe46afe5f0461f6d273dba404`，包名 `com.ugk.hiplab`，版本仍0.3.6+11。使用 `flutter build apk --debug --no-pub --target-platform android-arm64` / `android-x64` 构建，Gradle分别125.9秒、46.3秒。仅命令环境 `GRADLE_OPTS` 关闭Kotlin增量编译，未为构建修改项目配置、依赖或lock。

| 产物 | 字节数 / SHA-256 | 当前安装边界 |
|---|---|---|
| `hiplab-0.3.6+11-pr19-pr21-arm64-debug.apk` | 174,333,226 / `fb959b061a09f907e826a846dae2badca397f735d02603621b3841b834e2e785` | 已构建，未安装手机；较上一轮150,903,412bytes增加23,429,814bytes |
| `hiplab-0.3.6+11-pr19-pr21-x64-debug.apk` | 213,174,642 / `292c7b4fb7aa0a5e85546d8d642e46ae0e9eb9b6eaf57ec52dd524eed4f33051` | 已安装专用AVD `codex_hiplab_pr19_21_api35`；不代表手机更新 |

两份签名证据均为既有debug证书SHA-256 `3761270a4764157f0e389014a9e5b800b05403bfddce0f4f7f8c039f6a53bdc7`。本机目录 `E:/AII-3D/hiplab-releases/pr19-pr21-review-20261019/` 保存上述APK、`apk-identity.json`、`apk-build-arm64.log`、`apk-build-x64.log`、`apk-arm64-signature.txt`、`apk-x64-signature.txt`；不代表远端备份。

构建之后仅补主题媒体工具的封面时刻防漂移check及mutation回归，最终Python19通过，themed-media/action-kit检查均通过；没有改变App或资产，APK来源仍为e3fb1d3，不因工具/文档改动重新构建。两段录屏698帧未发现全卡黑屏/中部单色空白候选，逐秒图与原图未见内容脱离圆角；录屏和模拟器GPU色差限制见[审核报告](pr19-pr21-review-2026-10-19.md)，不作为物理真机或iOS结论。

用户本轮改用模拟器。专用AVD为Android15/API35、1080×2400/density420，WebView124.0.6367.219；原有 `codex_api35` 正式0.2.0包未覆盖。手机安装状态沿用上次源6dd16ed的记录，原记录本轮未操作。原生训练、主题切换与休息反馈已进行，模拟器9个合成场景后已停止，按用户最新安排转Web复核、晚上再真机；最终模拟器验收由[审核报告](pr19-pr21-review-2026-10-19.md)补记。尚未合main或推送，需本轮最后同意；未上传商店。

### 最终晚间arm64候选（c7def28）

`hiplab-0.3.6+11-pr19-pr21-c7def28-arm64-debug-repacked.apk`：**174,329,762 bytes**，SHA-256 `7fdbdf81f567d064d2dcab356494087a552913a32812f3a4c80c091a767ec678`，包名com.ugk.hiplab、0.3.6+11，沿用上述debug证书。构建含字体运行修复，未安装手机/AVD。命令仍debug/no-pub/android-arm64；首次构建69.1秒，发现增量APK含37,584,896 bytes ZIP空洞（总211,931,209 bytes）后，仅删除隔离副本的单个生成APK并重建33.2秒。重新打包的1478条ZIP项大小/CRC与原c7包完全一致，Flutter引擎仅arm64，未改源码、依赖或配置；APK v2签名校验、16KB页对齐检查通过。异常包保留为本地调查历史，不作为晚间安装候选。

本轮晚间候选比上一轮6dd16ed包增加23,426,350 bytes；与早期本轮e3arm64差−3,464 bytes，不能把含空洞的增长归因素材/字体。候选保存在本机`E:/AII-3D/hiplab-releases/pr19-pr21-review-20261019/`，不入Git；身份与打包日志也在该目录。晚上仅在确认连接、备份及身份后覆盖安装，保留现有记录，不清数据。

## 用户真机安装及简单测试反馈（2026-10-19）

本会话向用户交付`hiplab-0.3.6+11-pr19-pr21-c7def28-arm64-debug-repacked.apk`，用户随后报告“真机安装、简单测试通过”。运行源`c7def2869b789357b303d69d66eb8c18a0a748ae`，包名com.ugk.hiplab、0.3.6+11 / debug arm64 engine，174,329,762bytes，SHA256 `7fdbdf81f567d064d2dcab356494087a552913a32812f3a4c80c091a767ec678`，沿用既有debug证书。本次未重新构建、重命名版本或发布商店；APK本身继续留本机忽略目录，Git仅保存身份和记录。

证据来源是用户在当前会话的安装及简单测试反馈，非Agent再次ADB安装或仪器核验；设备型号/WebView、本机安装后版本、测试明细、备份及用户数据保持未重新核对，不推断这些项目已通过。原“未安装”段落保留为构建时历史；本轮交付现更新为用户报告已安装/简单测试通过。main仍`6020d8e8bf26700e56785b029ef8d5ef4a379f2c`，审阅分支`codex/pr19-pr21-validation`保存组合修复；尚未合入main或上传商店。

## 0.3.6+11 对应代码合入main（2026-10-19）

用户随后明确要求推进合并，#19→#20→#21及五项修复随已审核合并链普通push至main；业务集成点`b9646d4a15b4e3727d8e11ea5ee3106f0e396603`。GitHub于2026-10-19 14:00:39北京时间（06:00:39Z）确认三PR均MERGED，merge依次2b552fd/18bf4ce/b6fd55e；[完整合并身份](pr19-pr21-review-2026-10-19.md#pr-19--20--21-主线合并确认2026-10-19)。运行内容与上述用户收到的c7def28 APK一致，本次没有新构建/安装/版本递增/商店上传；用户简单真机通过和完整专项未验范围保持独立。

## 0.3.6+11 PR #22 原生验收包准备（2026-10-19）

准确源b12b0f5基线及9fa0cc0候选均已构建debug arm64，包名/版本/debug证书连续，CRC/16KB对齐和575音频/94视频校验通过。基线174,333,322bytes，SHA256 `5502ec69e77d81ee42309f1265904e963c1c8a45e405ebb50f60153510653a3c`；最终候选174,483,026bytes，SHA256 `ce978c5f7ae92fe4ab19587040faf638183bef868dd54e06c572bff01beeca1b`。两包位于`E:/AII-3D/hiplab-releases/pr22-android-acceptance-20261019/`，完整文件名及打包过程见[验收准备](pr22-android-acceptance-2026-10-19.md)。用户安排先准备包、稍后接手机；两包均未安装，无ADB操作，未递增版本或上传商店。

### PR #22 Web验收构建追加（2026-10-19）

同样准确两源在E盘临时Web壳构建真实lib/main.dart，未替换产品lib/依赖/入口；字号专项另包裹2.0 TextScaler，产品哈希不变。版本仍0.3.6+11，没有新APK、手机安装或商店动作。Web补测发现F8/P2待修，前述9fa APK不记验收通过；修复后需新候选来源与包身份。[来源/结果/证据](pr22-web-acceptance-2026-10-19.md)。

## 0.3.6+11 PR #24 Android编译验证包（2026-10-19，未安装）

源e3655e50e2ff7868d9d381489df90efe9cf208f1，debug arm64；E:/AII-3D/hiplab-releases/pr24-review-20261019/hiplab-0.3.6+11-pr24-e3655e5-arm64-debug.apk，174,483,026bytes，SHA256 `d8a2e01329d3f140dd5ca1ae861fc4d29ddd10da43528ff73bbab7a456edfe2a`。包名com.ugk.hiplab、versionCode11，debug证书SHA256 `3761270a4764157f0e389014a9e5b800b05403bfddce0f4f7f8c039f6a53bdc7`连续；Gradle20.6秒，新Kotlin服务/Manifest已入包，CRC/16KB对齐和575音频/94视频一致；最大ZIP间隙138,313bytes。版本、依赖、发布配置保持。4项P2待作者修，当前不是验收通过包；未ADB、未安装、未商店上传，手机安装记录不变。[完整身份和问题](pr24-review-2026-10-19.md)。

## 0.3.6+11 PR #22 / 2cc40e3 真机复测包（2026-10-19）

源2cc40e3e51730d14f87056afe76e2b0c51dfcb19，debug arm64；E:/AII-3D/hiplab-releases/pr22-2cc40e3-retest-20261019/hiplab-0.3.6+11-pr22-2cc40e3-arm64-debug.apk，174,481,110bytes，SHA256 `46dd0d0c4819ab4e29883fcdadcb3ccd2e6489d78d3f3f7395b6fc79f4f60342`。初编14.9秒，单个生成APK移出后重打15.0秒消除ZIP空洞；签名连续、CRC/16KB对齐、575音频/94视频一致。20:44:23向2602BRT18C / Android16 install-r成功，安装包hash相同；原安装包为9fa0cc0（ce978c5f…），原偏好备份且升级JSON相同。F8真机原场景通过，新F9及后台/锁屏待修，候选尚未验收或合main；版本未增、未上传商店。[完整记录](pr22-native-retest-2026-10-19.md)。


## 0.3.6+11 PR #22/#24组合正常播放包（2026-10-19）

组合源5725c3668baddbe844a9943ed81c9374bc7aa3f1（22的2cc40e3 + 24的0ccef6b + 本机重播hold适配），验证分支已推送，main未合入。APK `E:/AII-3D/hiplab-releases/pr24-0ccef6b-reaudit-20261019/hiplab-0.3.6+11-pr22-pr24-combined-arm64-debug.apk`，174512710bytes，SHA256 `922ca6a7e1fa6da07ad96479dde2e9fa32a218515d8d0a0a3235a6ce664f643e`；com.ugk.hiplab/versionCode11，既有debug证书连续、资源/CRC/16KB对齐通过。初编19.9秒、ZIP空洞单APK重打16.9秒；21:56:37向2602BRT18C / Android16覆盖安装成功，安装SHA相同、14键状态JSON保持。两轮正常播放及服务释放通过，用户现场听感正常；F9仍待修。没有增加版本、修改发布配置或上传商店。[本轮记录](pr24-reaudit-and-pr22-integration-2026-10-19.md)。


## 0.3.6+11 PR22 F9 / PR24组合复审包（2026-10-19）

准确组合9b22dccc2bf2ca269a67b408198b9e3e9dbb742b（a586de3+既有PR24/重播hold修复），已推验证分支；APK位于E:/AII-3D/hiplab-releases/pr22-a586de3-f9-reaudit-20261019/hiplab-0.3.6+11-pr22-pr24-f9-arm64-debug.apk，174518862bytes，SHA256 `f40f5956fa3bdae49872e525fced310257102c6b4f7638eb28911e18ec4b91bd`。Gradle41.8秒，证书连续、资源/CRC/16KB对齐通过，间隙0；23:15:53对2602BRT18C / Android16覆盖安装成功，安装SHA匹配、14键state相同。F9编辑与键盘原生通过，尚未合main，未改版本或上传商店。[报告](pr22-f9-reaudit-2026-10-19.md)。


### PR22/24合并状态追加（2026-10-19 23:32）

开哥同意后，已安装9b22dcc的运行代码随b33ed21合入并推送main；GitHub22/24均MERGED。版本保持0.3.6+11，APK仍为上述174518862bytes / SHA f40f5956…，23:15:53安装事实保持。本次无新构建、无重新安装、无商店上传；主线SHA变化不冒称新APK。[合并确认](pr22-f9-reaudit-2026-10-19.md)。


## 0.3.7+12 Android AI测试包（2026-10-20，仅构建）

按用户要求从main构建，源55d99b3（在8c61893上只递增pubspec版本）；Flutter3.44.7 / Dart3.12.2。`hiplab-0.3.7+12-ai-arm64-debug.apk`，175043055bytes，SHA256 `4846f335c4a8f100b17c6b9548a46d950011baa57e93c035e9735e3d24c8e052`，保留com.ugk.hiplab及既有debug证书，versionCode12。AI令牌来自本机私有参数，凭据不入Git。包位于 `E:/AII-3D/hiplab-releases/hiplab-0.3.7+12-test-20261020/`。

构建50.7秒，APK元数据/签名/CRC/876资产通过；本轮无ADB/安装/清数据或商店操作。沿用业务源8c985c4的414pass/1skip和analyze/API结果，不冒称本次重复运行业务测试。手机最后已验安装继续0.3.6+11；保留数据升级与AI原生流程须实际安装后核验。[交付记录](android-test-build-0.3.7-2026-10-20.md)。


## 0.3.8+13 ugk_trainer 首轮包（2026-10-20，锁屏未通过）

分支`codex/adopt-ugk-trainer`，构建源`7dd40b061a6316195bea656d1f9d4bd1b7f09108`，SDK固定`7a84dc0830fa039f89f5e74f919d59f18d6602cd`/ugk_trainer0.1.1。Flutter3.44.7，Android debug arm64、带既有AI配置，Gradle58.3秒。`hiplab-0.3.8+13-trainer-arm64-debug.apk`，175247923bytes，SHA256 `64ac542cd754bd1e33445fe9451f4a4b5b4b5ae84eb758d42b5e026ea186dc98`。包名com.ugk.hiplab/code13，原debug证书连续；CRC及876个App资产逐字节匹配，APK只有com.ugk.trainer.TrainingSessionService一个服务。

手机实际安装前已为0.3.7+12；本轮先备份shared_prefs/files与原APK，再adb install -r，回读0.3.8/code13，冷启动1228ms。安装和启动后7154字节偏好与备份逐字节保持，18条旧记录、3个训练组保留；未清数据或回写备份。用户先报告锁屏口令初时正常，随后停声、解锁恢复；系统实际为扬声器路由，不能记作耳机通过。系统日志22:42:09.005明确Greeze冻结并禁用训练唤醒锁，22:42:31.326解锁后解冻。该原生验收失败，不能以429pass/1skip、analyze或构建通过替代。失败课程按提前结束保存（endedEarly=true/full=false/70s），自然测试记录保留，现19条。

产物、原APK备份、偏好、截图与系统日志在本机`E:/AII-3D/hiplab-releases/hiplab-0.3.8+13-trainer-20261020/`，不随Git推送。SDK修复与复测继续见[接入记录](ugk-trainer-adoption-2026-10-20.md)；main未合、App分支未推、未上传商店。

## 0.3.8+14 锁屏修复复测包（2026-10-20，已安装、未验收）

App源`f702164559526c0073ad2f26734a91badb7e2b94`，固定SDK`7348f0cdcccf564fbddb73fef41c08e3bf30f0fa`/trainer0.1.2；SDK118/118及analyze0。Git锁校验成功，Android debug arm64带既有AI配置，Gradle35.4秒。包`hiplab-0.3.8+14-trainer-lockscreen-arm64-debug.apk`位于`E:/AII-3D/hiplab-releases/hiplab-0.3.8+14-trainer-lockscreen-20261020/`，175254439bytes，SHA256 `c5f1b5e75dbf1b1da126fa35687b4138504e9c96c266b926a467d497b71f6bc6`。回读com.ugk.hiplab/code14/0.3.8；既有debug证书SHA256 `3761270a4764157f0e389014a9e5b800b05403bfddce0f4f7f8c039f6a53bdc7`连续，CRC、876源资产及仅包内一份服务通过。

23:02前后对同一2602BRT18C/Android16覆盖安装成功，安装前再次备份shared_prefs/files，安装和启动后9882字节偏好逐字节一致（SHA256 `27b4f738f20db3ac9edc107716fc741a228adf8a06e4d27a9e6fe8bf85f0eabd`），保留19记录/3组/3个完成日，无清数据或回写备份。冷启动1192ms。用户随后明确改为扬声器复测；测试闹钟已不在屏幕，但开练前用户要求暂用其他App，因此课程未启动、停止手机操作待通知。App该固定依赖全量429过/1条件跳（4分33秒）、analyze0；原生锁屏仍待复测，不以本包修复或单测改写+13失败。main未合、未上传商店。


## 0.3.9+15 AI新中转包（2026-10-20，已安装，整节锁屏失败）

| 身份 | 已核对事实 |
|---|---|
| App运行源 / 回归夹具 | `f8f0ec8af94d67149612574070c11094eeb80900` / `ab963d7`；夹具提交仅测试，不改变包运行代码 |
| SDK冻结来源 | `8ef37a92bcc9e701fbe454ba98aa2100406287fb`，ugk_coach0.1.3 / ugk_trainer0.1.2 |
| APK | `E:/AII-3D/hiplab-releases/hiplab-0.3.9+15-relay-20261020/hiplab-0.3.9+15-relay-arm64-debug.apk` |
| 字节数 / SHA256 | **175257947** / `34e337b8760cb1bd709824282ab6d8b88efe2f19d2959b5f9d98714c14d52829` |
| 包身份 / 构建 | `com.ugk.hiplab` / versionName0.3.9 / versionCode15 / debug arm64；Gradle27.6秒 |
| 签名与内容 | 既有debug签名连续；CRC、876源资产逐字节及仅一份包内训练服务通过；新入口/模型/App Key编译绑定核对，未输出凭据 |
| 本机代码验证 | App439pass/1条件skip、analyze0；SDK根168/训练118全过、两包analyze0；不替代真机锁屏结论 |

23:37对2602BRT18C/Android16保留数据覆盖安装，安装前备份9882字节旧偏好与files；启动只新增独立随机UUID偏好键，旧键值逐项保持。首次冷启动1242ms，再次冷启动1019ms后UUID与偏好保持。原3个自定义组保留；手机AI36.595秒首轮生成8动作并保存第4组，开练前19条记录保持。

23:44:39从已保存AI组 `c_20261020_9eb3` 开练，23:45:06关屏；扬声器口令初时继续。23:50:15系统判音频非活动，23:50:21.914小米Greeze冻结、随后训练锁disabled=true；FGS仍在，零音量音轨仍started/clientVolume。用户亮屏后声音恢复，本轮整节锁屏FAILED，不记耳机验证或完整课程通过。

23:53用户通过正常结束流程退出失败课程，保存SessionResult.activeSeconds528秒、完成6/8、full=false、endedEarly=true；训练记录19→20，训练组4个保持。随后确认TrainingSessionService已消失，仅WebView服务保留。这是主动提前结束及终态释放证据，不是锁屏自然结束。证据：上述交付目录 `native/lockscreen-logcat.txt`、`native/monitor/`、`native/failed-course-result.json`及退出后的服务快照；原始用户数据与标识留本机，不写入台账。

下一修复候选尚未验证；不预登记未发生的版本。运行源/夹具及SDK开发分支已推送，两个main均未合本轮，仍待实际验收与开哥最终同意；未上传商店或修改商店配置，不清数据。


## 0.3.9+16 Android音轨分类修复包（2026-10-21，已安装、锁屏失败）

App源38bce474723d45d4b025e7def52dfe935ed40fda，固定SDK8fb0aacff2072b31c4abaea10e101075fb9a2e9a/trainer0.1.3。debug arm64构建Gradle27.9秒，产物175258187bytes，SHA256 `a5a5bc30cd69cf74fed1fe0a4166bf2844dc5d439fa06d3ef80f8022b13941c2`，包名/签名连续、CRC/876资产/唯一服务通过。14250字节偏好和23552字节files/prefs备份后install-r，启动1338ms、偏好逐字节一致（20记录/4组/3完成日/同一UUID）。App439过/1条件skip、analyze0，SDK训练119/119及analyze0。00:02从保存AI组启动、关屏，用户确认口令继续；整节与释放尚待观察。main未合、不上传商店。完整身份与本机证据目录见[本轮记录](android-lockscreen-fix-2026-10-21.md)。


### +16锁屏失败追加（00:08）

00:07:47.193关屏约5分25.7秒后仍被Greeze冻结；FGS和started/mutedState:none音轨存活、训练锁DISABLED，媒体会话栈0。上一节“整节待验收”是安装阶段快照，本轮现判FAILED。安全锁屏待用户回来解锁正常结束，尚无本轮结果保存结论。[现场与后续](android-lockscreen-fix-2026-10-21.md#本轮结果失败继续sdk修复)。


## 0.3.9+17 媒体会话候选（2026-10-21，已构建，未安装）

来源App79c172d9a83d248f23e136cffe825f3bd016e16b，SDKd193a703e3a8bef6d41e7705a55ae250e23e6a69/trainer0.1.4。debug arm64原生构建26.8秒，175258975bytes，SHA256 `09e11efd96f284aeb642e0b46b05843916b061d0e06e40160089cbeeca08ce51`。原包名/签名、code17/0.3.9、CRC/876资产/唯一包内服务及新AI编译配置核对通过。App analyze0、保活专项8/8；SDK增量接口验证通过，旧全量不重复跑。手机仍+16失败现场且安全锁屏，待用户解锁后结束/备份/install-r和整节验收；本条不代表安装、原生通过或合main。[完整路径与证据](android-lockscreen-fix-2026-10-21.md)。


### +17安装追加（00:23–00:24）

用户解锁后+16挂钟补算为8/8/1210秒，仍记冻结失败；原20记录完整并追加为21，4组/UUID保持。正常完成退出后备份17637字节偏好及files，install-r17成功、冷启动1271ms，启动后偏好逐字节保持。原生MediaSession PLAYING→PAUSED→PLAYING及MediaStyle token通过，00:24:34关屏开始整节。尚未验收或合main。[真实现场](android-lockscreen-fix-2026-10-21.md)。


### +17用户后测与当前交付（00:34）

用户最新明确停止后台排查、后续自己测试，故+17锁屏仍记FAILED，不改为通过。+17失败尝试未新增记录，当前保存的1210秒8/8属于+16解锁补算；原21记录/4组/UUID核对保持。保存当前偏好后只停止HipLab测试进程，训练服务已释放；没有清数据、改省电设置、再构建/复测或商店操作。已安装包仍79c172d/d193a70/0.3.9+17，代码交付和主线集成待最终同意。[交付边界](android-lockscreen-fix-2026-10-21.md)。


### 0.3.9+17主线集成确认（2026-10-21 00:39）

用户明确同意“合并并推送，保留锁屏已知问题”。SDK main已快进并推d193a70，PR #2于00:39:10确认MERGED；HipLab主线集成点691ace2于00:39:31普通推送。运行代码仍79c172d，手机APK0.3.9+17/SHA256 09e11efd96f284aeb642e0b46b05843916b061d0e06e40160089cbeeca08ce51不变；后续只补合并文档，不增版本或重新构建/安装、不再测试/操作手机、不上传商店。锁屏冻结仍已知失败、用户后测；安装/合并/推送分别登记。[主线确认](android-lockscreen-fix-2026-10-21.md#主线合并确认2026-10-21)。
