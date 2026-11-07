# UI知识抽取与阶段文档收束 / 2026-11-07

## 本阶段结果与范围

用户要求两项成果：把最近已验收的仿iOS界面整理成其它App可读、可参考实现的规范/样例；按cockpit-closeout整理本项目当前文档台账并保存提交、普通push。

收束scope为本仓库最近UI/媒体交互/英文/安全插画及其已接收main的事实、现有设计规则、文档/学习样例与验证来源。只改README/AGENTS和docs内的规范、示例、台账，不改App运行代码、配置、依赖、版本、业务数据或手机；不涉及SDK仓库、release/1.0、tag、商店、跨仓迁移或发布独立组件包。

## Preflight：写入前已完成的只读检查

| 字段 | 实际结果 |
|---|---|
| 授权目录/仓库边界 | `git rev-parse --show-toplevel` = `E:/AII-3D/3D-Hip`；当前分支main |
| baseline | `6bdf1e9c1d115c0bcfc6bef1da8979e1dbd7e435`；是根入口直接链接的主线回执记录的UI接收前main（+34文档基线），不是按“最近提交”猜测 |
| ref/祖先核对 | `git rev-parse --verify 6bdf1e9c1d115c0bcfc6bef1da8979e1dbd7e435^{commit}`返回同SHA；`git merge-base --is-ancestor <baseline> HEAD`退出0 |
| HEAD | `84202688b3c43015c0f8c66d8b9d7b07988f3e8b`，本地main与远端main回读相同；提交时间2026-11-07 10:33:46 +08:00 |
| stage delta | 同一baseline到HEAD：68提交、392路径，M303/A73/D16；通过`git log`与完整name-status解析核对 |
| 路径类别 | 根4、Android3、assets262、docs33、lib44、test43、test_screens1、tools2；无iOS变更 |
| 完整工作区 | `git status --porcelain=v1 --untracked-files=all`结果为空并核对结束标记；staged/unstaged/deleted/renamed/untracked均0 |
| 改动归属 | Preflight无本地待归属改动；stage delta是已提交/已由用户验收并接收main的本轮来源。阶段二的新文档由本次Agent及被委派的文档子任务创建/修改，按明确路径管理 |
| 最近适用规则 | 根AGENTS.md；docs、docs/ui-kit路径上没有额外AGENTS.md。先读根规则、根README，再核对入口直接声明的来源 |

392路径是当前有限阶段delta的数量，不是把整个仓库历史当作本次改动。assets中211个poster路径包含209项替换和2项移除；当前实际封面数为209。

### Canonical discovery与主题映射

根AGENTS/README明确声明当前状态、版本、交付、验证、事项、日志、工作流的职责。以下为实际核对的有界来源；没有递归追踪历史报告链，也没有读取其它项目、凭据、浏览器profile、构建产物或外部日志。

| 相对路径 | 类别/判定 | 实际核对与对齐范围 |
|---|---|---|
| AGENTS.md | current协作入口；下方日期段为history | +61 main、权限、证据边界、文档职责 |
| README.md | current项目摘要；日期交付段为history | 主线入口、版本/SDK、语言、结构、媒体和引导素材描述 |
| docs/README.md | current文档入口/恢复流程；旧日期段为history | 事实源职责、当前素材准备、规范入口 |
| docs/current-state.md | current状态canonical；旧交付段为history | main接收、+61安装、用户UI接受与独立未验边界 |
| docs/version-management.md | current版本规则；带日期快照为history | pubspec为共用版本源、SDK pin、通用段当前数字 |
| docs/version-ledger.md | current交付台账；各次包按当时source记录 | +61/2061、7ca9617构建源与安装来源；本次不新增包 |
| docs/verification.md | current验证台账；历史结果按原source使用 | 624/70/0、analyze0的来源及到HEAD的有限差异 |
| docs/development-roadmap.md | current事项canonical；2026-11-04索引为history | 本轮UI验收/合入已完成，独立D-34等不误关闭 |
| docs/development-log.md | current关键成果记录；每项保留日期 | UI主线接收、知识抽取、文档修正 |
| docs/development-workflow.md | current操作入口；旧主线/ZIP段为history | main开发入口、3.44.7、r2-v1与恢复方式 |
| docs/ui-main-integration-2026-11-07.md | current阶段集成/验证记录，由根入口直接链接 | baseline、完整候选、软件检查、+61同运行内容与合入范围 |
| docs/ui-design-standard.md | current设计工作产物，入口表声明的规范；本阶段delta包含该文件 | 依本次独立UI抽取要求核对实际实现/样例；不把旧交付方案当作当前规则 |
| pubspec.yaml / pubspec.lock | current版本/依赖配置 | +61；四实际SDK及coach override固定fa957ff完整SHA，未改锁 |
| assets/public_media/catalog.json、assets/public_posters、lib/hip/data/hip_action_scope.dart | current阶段公共配置/资源集合 | r2-v1、249目录项、209授权项/封面；只核对公共元数据/文件数量，不读媒体产物内容 |

主题映射：代码行为/视觉规范由当前状态+UI标准及本次检查的有限源码支持；版本/依赖由版本管理和pubspec/lock支持；构建/安装由版本台账支持；验证与未验由verification支持；事项、操作、成果分别对应roadmap/workflow/log。当前canonical不存在未消歧的平行事实源。

### 验证证据绑定

| 证据/命令 | 时间/来源与结果 | source state及适用性 |
|---|---|---|
| `flutter test --no-pub --concurrency=1 --reporter=json` | 2026-11-07本会话前序主线接收，624通过/70条件跳过/0失败，555251ms；已记录在主线回执与验证台账 | 完整源`6e49ac7f7c22370c54f4d1c5068166c7f200c0bb`；它到Preflight HEAD仅13个文档/README/AGENTS路径，运行文件/资源/测试/锁完全相同，可沿用，不声称8420268重新跑过 |
| `flutter analyze --no-pub` | 同次主线接收，0问题 | 同一6e49ac7；适用性同上 |
| `flutter pub get --offline --enforce-lockfile` | 同次候选检查及日常main依赖恢复通过 | 候选6e49ac7和main8420268锁文件相同；本次不升级依赖 |
| +61 APK/覆盖安装/启动 | 既有版本台账和本会话前序回执：2061，同签覆盖、启动ok；本次只引用记录，不打开构建产物或回读手机 | 包源`7ca96179d44e216b79ffbc9b9855986f669552cc`；到6e49ac7只差5个docs；到8420268仍只差文档/协作说明。不是HEAD新构建证明 |
| 用户接受 | 本会话明确“验收通过”“都验证ok”，授权推进main | 本轮日常Android UI体验；不扩展为Agent执行iOS/语音/锁屏等独立测试 |

上述source关系已用`git diff --name-status 6e49ac7..8420268`和`7ca9617..8420268`核对；无未提交代码影响证据。Preflight不重跑昂贵全量，不以“grep没匹配”宣称所有文档正确。

### 确定的alignment findings

1. 根README顶部已写+61，但通用正文还写+34/旧SDK、仅中文、211封面、旧三Tab和旧六张引导图导入方式。
2. 版本管理的无日期通用规则段仍称“当前+34/2034、f7b8a8e”；与pubspec/lock和最新交付不一致。
3. 文档入口的新机器当前恢复段仍写211封面；旧“当前导航/事项索引”需清楚标作其日期历史。
4. 当前UI规范仍把旧首页“换一套”描述为32pt按钮、以固定估计高度概括顶栏滤镜，首页章节的适用版本仍写+56；应按实际64pt文件夹、动态真实paint clip和已验收+61说明。
5. 用户要求的可复用知识尚缺完整接入样例、依赖边界、当前/淘汰方案区分与验证配方。只补规范与学习样例，不借机重构业务或发布包。

## Alignment成果

新增[UI实现与复用手册](ui-kit/README.md)：基础、导航、控件、媒体动效、移植验收五章，配套可运行Flutter画廊、三个配方页面和验证样例。精确参数、分层/状态时序、失败原因、改法、原测试入口均有来源。媒体教学页明确使用假媒体，不冒充真实纹理或设备性能证明。

修正上述确定的当前摘要/规则/入口错误；当前状态、版本交付、验证、事项、日志及工作流明确本轮已接受与main接收。历史报告和独立未验事项保留，源码旧注释不作为新规范数值来源。本次没有App版本/依赖/资源变更。

新示例的实际分析、测试、链接与差异检查结果在提交前追加下节。最终commit由Git回执及唯一一次非终态Cockpit progress指向，不在文档里编造自指SHA。

## 本次文档与样例验证

实际执行日期：2026-11-07。显式工具入口`E:/DevCaches/flutter-3.44.7-hiplab/bin/`，现场核对Flutter3.44.7 / framework84fc5cbb / Dart3.12.2。以下结果归属于`8420268`基础上、本次仅文档与示例的工作树，不冒充旧App测试或真机证据。

- `dart format docs/ui-kit/examples`：5文件最终检查0变更。
- `flutter analyze --no-pub docs/ui-kit/examples`：0问题。
- `flutter test --no-pub --concurrency=1 docs/ui-kit/examples/gallery_test.dart`：6通过、0失败。覆盖zh/en×深浅设置交互、确认/取消、导航单/双标题及push中间帧44pt锚点；深浅媒体教学子树展开/收起保持同一Element。
- 新增/变化Markdown本地链接按文件去重核对：98个目标全部可解析；仅检查本次新增链接，不将未检查的历史链接称为通过。
- `git diff --check`及新文件尾空白核对通过；完整工作区逐路径归属已核对，无不明路径。
- `git diff --name-only 8420268 -- lib android ios assets test test_screens tools pubspec.yaml pubspec.lock`为空：App运行代码、原生、资源、原有测试、依赖和版本保持。

新样例实际源的SHA256如下；提交前逐一核对，不在通过之后改变样例。后续仅改文档结论不影响这些结果。

| 样例文件 | SHA256 |
|---|---|
| [controls_example.dart](ui-kit/examples/controls_example.dart) | `e5aa35b50e9345f078d28fa2ff1fa39803abe6f55815526a5239f8c0ba95f052` |
| [gallery.dart](ui-kit/examples/gallery.dart) | `0a4c75024ab22070a87ffd10fee52e15c696a1c68d48b1267d61fb85a189bc58` |
| [gallery_test.dart](ui-kit/examples/gallery_test.dart) | `4e8d5b70c2c45b33a8c34ebbda5f20cd56944bb3640407ec0700d78803aa8cd4` |
| [media_handoff_example.dart](ui-kit/examples/media_handoff_example.dart) | `e35745dd635f96bdf0177b611ba426408988354c0ef79c00cc172683bb59ddea` |
| [navigation_example.dart](ui-kit/examples/navigation_example.dart) | `f3283219a4543f63505be157287afd8ca7d85fdf621c75c321ec89b64be2d0c6` |

完整状态归属：Preflight为0项；阶段二最终为11个tracked文档修改、12个新增文档/样例（共23路径）。无删除/重命名或其它来源的WIP；根Agent负责入口/基础/移植/画廊/验证/台账，三个明确授权的文档子任务分别负责导航、控件、媒体章节及其样例。仅按这些明确路径暂存。

Agent-reported alignment：五项确定finding均已对齐；样例与生产API核对，额外修正无图标导航行分隔线缩进及独立开发入口的措辞。未新增未解决语义、依赖或架构变更。当前运行内容/版本仍为+61，用户验收与软件/构建/设备证据分层保持。
