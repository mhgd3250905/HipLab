# 首页杂志动作专页与接牌连续性 · +46 · 2026-11-06

运行/构建源 `21dd048940baef24a4e3d7186163ae626b062fcf`，独立分支 `codex/home-card-editorial-20261106`；`1.1.0+46` / arm64 `2046`。SDK仍 `1c082e9d3e22022f228888fdd1935b1d61371cb9`，lock、shader、媒体与原生代码保持。日常目录 `feat/ui-detail-polish@25260b3` 保持。

按用户两项反馈，移除“左右翻阅”及两侧箭头整个底行和预留；前后牌共用同一Face，标题/视频比例及材质不再在到顶时切换。展开态采用刊头细线、放大单序号、侧栏、强调标题、动作要领和页脚印记的杂志版式，保留原动作分类、方向、剂量和说明内容。

## 实现

删除旧后牌Column海报实现，前后牌统一`HipHomeActionFace`；后牌只保留depth变换和静态公共图，不创建额外decoder，不共享前牌ScrollController。底行不是透明隐藏：文字、箭头、44pt布局预留及旧代码均已移除。滑动、键盘方向键和读屏增减保留，训练顺序和持久化选择不受预览影响。

媒体矩形在固定小牌/大牌端点之间插值。标题/剂量/提示使用固定排版画布按纸张宽度缩放，行数与内容节点不随expanded切换；字体测量按数据、窗口和字号缓存，动画中不反复重排。正文也固定排版宽度，独立滚动；大图高度为说明区预留80pt，避免正常小手机长标题/两行提示时挤没正文。后牌阴影随depth渐变到前牌值。

同一前牌媒体Element/State/controller/Texture在拖动与展开/收起期间持续存在；关闭仍暂停当前帧。+45的`filterQuality: low`局部透明合成后整卡变换保留，未恢复截图、双视频或回首。默认浅深主题使用现有字体和色盘，没有新增资源或业务动作数据。

## 验证

相关10文件87通过/0失败/13跳过（12既有截图项+1需Impeller）；真实shader像素回归另以 --enable-impeller 1通过。fatal-infos分析0，严格锁解析不改lock。未重新跑全量App/SDK。

新增接牌回归以内容到牌面祖先的直接矩阵计算局部归一化比例：从后排静止、progress=1未release到提交后前排，媒体与标题比例一致；避免用3D全局反投影包围盒混淆实际重排。可访问语义继续调整位置，断言没有翻阅行或隐藏箭头节点。

新增360×740正常字号回归：既有长动作名、两行提示均实际排两行且不截断，说明viewport至少60pt并可滚，展开/收起仍同媒体State。原逐16ms同TextureLayer/实际ImageFilterLayer、暂停关闭、返回/遮罩/Escape、补牌循环、日期/主题/计划顺序回归继续通过。

浅深渲染使用仓库NotoSansSC和真实Flutter组件，已恢复软阴影；preview媒体为公共封面，用于几何/字体和版面检查，不能冒充原生视频截图。渲染辅助脚本在忽略的build目录，原始证据留E盘。

最终+46 release已构建、验签和资源校验，未由Agent安装，继续交用户远程覆盖测试。Noto字体浅深实际widget渲染已检查，组件逐帧与headless Impeller证据不替代原机滑动/展开观感及帧时长验收。

## 交付

| 项目 | 事实 |
|---|---|
| APK | `E:/AII-3D/hiplab-releases/home-card-editorial-21dd048-46-20261106/hiplab-1.1.0+46-21dd048-internal-arm64-release.apk` |
| 大小 / SHA256 | 47628200字节 / `a4b0645993f452274618ac03d14401382d7b8add145345ae0024d7ef5badb796` |
| 证书SHA256 | `3761270a4764157f0e389014a9e5b800b05403bfddce0f4f7f8c039f6a53bdc7`，与+45内部包一致 |
| 身份 | com.ugk.hiplab/1.1.0/2046/release/仅arm64/非debuggable；构建49.9秒；重签runtime负载一致 |
| 内容 | 789资源项通过；r2-v1/stable、249目录动作、209授权/封面/未审AI标签、0内置MP4 |
| 检查和预览 | `E:/AII-3D/hiplab-releases/home-card-editorial-20261106/`（light/dark-compact/expanded.png） |

APK、原上传签名归档及验包回执位于同一交付目录；未上传。App候选已推送，main/release/tag/商店保持；本轮无本地设备、iOS、模型或实际显示FPS结论。此前+45原生反馈仍保留其原归属。
