# HipLab 英文界面 / 2026-11-07

## 2026-11-07 上午：+59 真机覆盖安装

用户重新连接真机后，已在2602BRT18C上执行`adb install -r`，返回Success；安装前2058、安装后2059（`1.1.0+59`），firstInstallTime仍为2026-11-05 22:11:33。未卸载、未清数据；启动MainActivity返回Status: ok并观测到应用进程。这是安装/启动证据，英文页面、语音、视频动画与实际数据完整性仍待用户验收，未记为通过。运行源仍为`1073222`，包SHA256仍为`185c140d0d8c2340c11cc4820dc7e12f969df645df3d36a42db76971af567482`；安装回执位于交付目录`device-install-receipt.json`，原构建时installed:false保留为当时快照。

补齐全 App 英文展示：设置新增独立“界面语言：系统 / 中文 / English”，口令语言独立保留并正确跟随App；旧安装默认中文。首页海报/文件夹、更多、设置、动作库/训练组/编辑/选择器、自测/结果、记录/日历/里程碑、隐私、播放器和SDK聊天/训练指南按当前locale显示。长英文设置选择器分行、首页标题最多两行、牌面方向用紧凑缩写，保留视频身份与既有转场。

## 为什么之前选择 English 没有切换界面

原“语言”位于语音设置，只写入VoiceSettings；MaterialApp.locale固定zh且supportedLocales仅zh。现在语言分为明确的界面语言和口令语言，新增HipStore.language持久化，保留旧声音偏好与全部已有数据。界面切换立即更新已打开页面；系统模式支持en/zh、未知语言回落zh。旧安装默认zh，不擅自将声音偏好迁移成界面偏好。

沿用项目已有LibText双语展示方式，增加HipText、HipContentText、HipAssessmentText与App拥有的公共动作英文表；不重复引入另一套路由或翻译框架。Material/Cupertino/Widgets使用既有官方本地化delegates。新增默认组名可英文，用户自己的中文组名、AI生成的历史计划和历史聊天原文保持；内建训练记录依据source/refId展示对应译名，不写回历史。

## 已覆盖

| 界面 | 实现与检查 |
|---|---|
| 首页 | 星期/问候、场景、天数单复数、推荐标题/受众/时长、动作名/剂量/说明、牌面与文件夹、开始/关闭/拖动语义 |
| 更多和设置 | 各入口/计数/说明、提醒时间、语音开关/试听/音量、独立界面与口令语言、外观、安全复审和隐私 |
| 动作库与训练组 | 搜索/部位/器械/难度/模式、209授权动作名和内容、推荐组、剂量、编辑/复制/放弃/删除、完整英文搜索 |
| 自测 | 6项所有问题/示范要点/对比选项/追问/疼痛与麻木提示、评分展示/方向/级别/12路线推荐，ID和评分规则保持 |
| 记录和隐私 | 星期/月/日期/时长/里程碑/空态/成功文案；完整离线隐私政策及Android/iOS配置分支 |
| 播放与Coach | SDK英语strings、动作详情/肌群/安全信息、typed剂量、加载/错误/重试、菜单/指南、范围回复；当前controller切语言保留消息/计划/agent/lease |
| 原生展示 | Android启动器label默认原中文、英文系统为HipLab；通知标题/正文沿SDK英文strings，已有通知通道仅刷新名称/描述并保留用户设置；iOS已有en品牌资源保持 |

显示译文不改catalog、动作白名单、临床判断、安全门禁、实际剂量、素材/媒体manifest、视频节点或源计划。普通导航锚点和文件夹原交互保持。紧凑牌面抬头必要时等比收纳文字，英文方向标签Flex/Ext/Abd/Add/IR/ER保留全部方向。

## 内容来源与兼容性

7个预设组与46个本地动作、全部预定义dose/tip/caution均有英文展示。公共表`lib/hip/data/hip_public_text_en.dart`覆盖209授权动作，逐动作保留689 cue、289 caution、200部位提示的数量和顺序；固定canonical文件SHA256为`ff9eb70740887752ba81bba0742fccb43d0522c2d810141a5d496228f1fb82c2`。词表覆盖实际肌群/器械/类别；另核对停止、麻木与左右计次等表达。此为当前冻结源的逐句译文；将来目录更新需同步英文，不声称未来内容自动翻译。

必要SDK候选`codex/coach-english-ui-20261107` / `fa957ff405cc57cd10d53987430313822ff20607`：Strings.english/forLanguage、controller.updateLocalization与ScopePolicy.languageTag、可选TrainingLibraryConfig.displayText（默认null逐字段回退）。旧中文默认/训练准入保持，没有复制SDK界面到App。SDK的core展示policy缓存更新不改变scopeManifest或临床规则。

## 验证及真实边界

- Flutter3.44.7；临时path override已移除，四SDK Git依赖与coach override锁同一个完整SHA；正常解析仅改变Git refs，随后offline enforce-lockfile通过，hosted版本保持。
- App功能基线46f9f8d全量：624通过、70条件跳过、0失败。随后修正启动重试页面在正确Localizations作用域读取语言并保留已读选择，以及英文动作详情句子分行/重复标点和部位提示标签；最终源经语言/页面/内容14项专项通过、analyze0，不重复全量。新英文测试覆盖实时切换及重启持久化、系统locale、深浅主题正常394宽、完整页面流程、首次安全确认、自测/记录/隐私、前牌展开与文件夹、推荐/自建组编辑/放弃/剂量、真实SDK详情、209内容与独立声音偏好。
- SDK聊天全套89（含5英文）通过，库11（含显示覆盖/回退/英文独有词搜索）通过，core范围/会话/清单39通过；详情标点修正后库11项复跑通过、trainer分析0。相关分析0。
- 使用真实NotoSansSC字体导出35张组件/页面截图，已目视检查深浅首页/更多/设置/记录/隐私及细节；这是Flutter测试渲染，不能冒充手机截图或持续帧性能。
- 初轮失败包括旧独立MaterialApp未声明locale的中文假设、新finder把底层卡片一并计数，以及卡片头3.6px和中文结果短标题回归。已明确zh/en宿主、限定真实前牌/详情、保留全部原业务断言并修布局/短标题后复跑；没有隐藏失败或把英文测试改回中文。
- 用户已拿走手机，本轮未执行ADB、未安装、未锁屏；实际视频切换/首次展开流畅度、保留数据覆盖、英文语音听感、Android通知通道与iOS真机仍待验。未运行新的真实AI模型请求，不把mock controller语言验证称作模型英文质量验收。

检查/截图：`E:/AII-3D/hiplab-releases/english-app-20261107`；APK/包身份/脱敏构建日志：`E:/AII-3D/hiplab-releases/english-app-1073222-59-20261107`。原始产物和凭据不进Git。

## +59 包身份

运行源`1073222137d2f6eb5b2fa26c07a70e63ed9862c9`；`1.1.0+59` / `com.ugk.hiplab` / release / arm64 `2059`。

APK：`E:/AII-3D/hiplab-releases/english-app-1073222-59-20261107/hiplab-1.1.0+59-1073222-internal-arm64-release.apk`；48086952字节；SHA256 `185c140d0d8c2340c11cc4820dc7e12f969df645df3d36a42db76971af567482`。证书SHA256 `3761270a4764157f0e389014a9e5b800b05403bfddce0f4f7f8c039f6a53bdc7`，与实际+58/2058基线一致；重签前后运行payload一致。只作为内部测试包，不是商店发布。

r2-v1/stable、249目录动作、209授权/公共封面、209未审AI标签、0内置MP4；789项资源逐字节检查通过。Android构建编译了必要通知文案补丁；编译/ZIP/签名通过不代表真机验收。

晨间安装入口：连接真机后安装本包；设置→界面语言→English，口令可选跟随App或独立中英。建议先验首页牌面/文件夹、更多→训练组/新建/详情/返回、设置→隐私、自测/结果、训练记录与完整英文训练/通知；自建中文名保持原文。

候选源与证据均普通推送对应分支，未合main、未改release/tag/商店。日常`E:/AII-3D/3D-Hip`仍为`feat/ui-detail-polish@25260b3`；包冻结后仅整理文档，不重复构建。


## 后续用户验收与主线接收

2026-11-07用户确认截至+61的本轮UI全部验收通过，授权接收main。本页此前“待用户验收/未合main”保留为当时状态；当前以[主线回执](ui-main-integration-2026-11-07.md)为准，历史独立未验项仍按回执边界区分。
