# 首页动作海报牌组与连续补牌

运行与构建源 `70e192981a06aaee6b87b3b8893afc5674e40771`，独立分支 `codex/home-action-deck-20261105`；版本 `1.1.0+38` / arm64 `2038`。本轮从 +36 UI 补全候选继续，先交付 +37，再按用户反馈修复底牌补入闪现。main、Draft PR #31、release/1.0 与商店未随此候选推进。

用户随后明确反馈“测试通过”，并在此基础上追加全向拖动和点牌悬浮展开的需求；该确认归属于 +38，后续交互增强另记交付证据。

## 设计结果

当前实际训练计划的每个步骤都有独立牌面，重复动作保留各自位置；图、动作名、实际剂量及可用提示同属牌面，跟随整张牌移动。保留首页计划标题、场景切换和开始训练；翻阅不改变计划、训练顺序或已保存选择。

用户逐轮反馈已落实：强化旋转/透视/错位形成手持扇形层次；动作说明移入海报牌面；编号只显示 `01` 等单序号；背牌延伸到物理屏幕边缘；去掉灰色底部硬台阶，使用轻接触阴影。规范见 [UI 设计标准](ui-design-standard.md#6-首页动作海报牌组)。

最后一项问题是 +37 在翻页提交时才创建新底牌，因此瞬间补出。+38 在拖动中提前把新牌放到原底牌背后，由上层向前递进逐渐揭开，并在最初一小段辅助渐显。提交前新牌已到达最终位置，Positioned、Opacity、动作图及 SDK 媒体组件保持连续；取消时弹簧结束后精确归零。2/3 动作循环的重复索引用独立备用位置处理，避免重复 key。

静止最多三张，过渡临时最多四张；单动作不补牌。不新增依赖、不复制开源代码、不改 SDK、锁文件、媒体或原生配置。首页继续使用现有静态封面，不因翻阅请求视频。

## 软件检查

- Flutter 3.44.7，`pub get --enforce-lockfile` 通过且 lock 不变，`analyze --no-pub --fatal-infos` 无问题。
- 影响范围 8 文件：65 通过 / 0 失败 / 12 既有可选截图跳过。这是定向回归，未重新运行全量 App 测试。
- 新牌组文件共 21 项，其中补牌新增 3 项：渐显与提交前后几何/媒体 Element 连续；双向取消；2/3 动作循环无重复 key。其余覆盖顺序/重复动作、训练入口不变、语义、主题、减少动画、身份/视口变化、销毁及真实首页边缘裁剪。
- 证据位于 `E:/AII-3D/hiplab-releases/home-action-deck-replenish-20261106/`：`targeted-tests.jsonl`、`test-summary.json`、`analyze.log`、`pub-get.log`。之前 +37 的 62 项结果与早期失败现场保留于 `home-action-deck-20261106/`，不覆盖。

## Android 交付与现场

APK：`E:/AII-3D/hiplab-releases/home-action-deck-70e1929-38-20261106/hiplab-1.1.0+38-70e1929-internal-arm64-release.apk`。

| 项目 | 结果 |
|---|---|
| 包 / ABI | com.ugk.hiplab / release / arm64-v8a / 非 debuggable |
| 字节 / SHA-256 | 47628200 / `3290f4f7e6f7289fa8db9a75935b675a1258af40c4edb408b569f8a56c7d4664` |
| 证书 SHA-256 | `3761270a4764157f0e389014a9e5b800b05403bfddce0f4f7f8c039f6a53bdc7`，与已安装 +37 一致 |
| 验包 | CRC、789 资产原字节、r2-v1 目录249 / 授权209 / 封面209 / 未审标签209 / 0 MP4；重签前后运行负载相同 |
| 安装 | 小米2602BRT18C，`install -r` Success；回读2038/1.1.0；未清数据 |
| 冷启动 | Status ok / COLD / TotalTime208ms，仅是本次启动读数 |
| 配置 | SDK97eb66d，stable目录，既有私有测试配置经外部临时define文件提供，临时文件已删除 |

`native/deck-replenish-38.mp4` 是实际 Android 录屏；`first-swipe-frames.png` / `replenish-frames.png` 为其抽帧图集。浅色正常字号下检查到新底牌在前牌离开过程中露出，动作图与文字共同移动；边缘没有16pt白缝，底部没有灰色硬边。录屏是视觉证据，不是帧率或性能基准。

独立逐步读回的 `native/gesture-verification.json` 确认序号 `02→03→02→02→01→09`：快速下一张、上一张、短划取消、反向翻阅和循环边界。测试脚本首次把起点固定假设为03，而实际读回01，导致预期错误；该记录单独保留为 `gesture-verification-initial-assumption.json`，改为按实际起点计算后全部通过，不把初次脚本假设错误记作 App 动画失败。

最终截图及 XML 在同目录 `native/06-final-home-first.*`，手机留在首页第一张。深色/减少动画有组件回归，本轮未补新深色 Android 录屏，未进行 iOS 设备、真实模型、声音、耳机或锁屏验收。

## 实现参考

开工先比较维护、许可证和依赖，借鉴有界渲染、分层变换、手势/取消及销毁保护的思路；采用本地轻量组件，不引入第三方牌组依赖。

- [flutter_card_swiper](https://github.com/ricardodalarme/flutter_card_swiper)：MIT，重点参考水平手势与取消/销毁边界；[PR70](https://github.com/ricardodalarme/flutter_card_swiper/pull/70) 的较新修复不能假定已包含在旧发布包。
- [Appinio Swiper](https://github.com/appinioGmbH/flutter_packages/tree/main/packages/appinio_swiper)：MIT，评估包自身维护情况，不把整个 monorepo 的新提交当作该包更新。
- [card_stack_swiper](https://github.com/Politanskyi/card_stack_swiper)：MIT，分层角度/错位可借鉴，但额外依赖没有必要引入本项目。

文档收束提交与构建源分别归属；不因文档更新重复出包。日常目录 `E:/AII-3D/3D-Hip` 仍为 `feat/ui-detail-polish@25260b3`，本轮使用既有 E 盘隔离副本，未清理或重置其它改动。
