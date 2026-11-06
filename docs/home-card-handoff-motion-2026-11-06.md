# 连续接牌与纵向惯性 · +51 · 2026-11-06

运行/构建源 `2087649d8c0dc8b34827c8458876886e55330662`，分支 `codex/home-card-handoff-motion-20261106`，`1.1.0+51` / arm64 `2051`；SDK `6fbd7de15dea62c7152eac43df1303b85d887a7c`。用户在本轮确认+50的进入更多闪帧和上下透明异常已修复，归用户反馈，不扩写为Agent原机/FPS实测。日常目录 `feat/ui-detail-polish@25260b3` 保持clean。

## 接牌连续性

旧实现后牌为poster，到顶后新建当前前牌decoder，真实首帧再120ms淡入，产生可见姿态更换。新实现按计划occurrence维持GlobalKey：前牌与前后邻居最多min(3,N)个挂载暂停媒体，反向邻居透明准备；深层/循环reserve仍poster。视频禁用时不加隐藏准备节点。暖牌晋升仅接管原HipDrillArt/TrainingActionMedia/controller/Texture，取消/前后翻保留当前帧；2/3牌和重复action保持各occurrence身份，离开相邻范围异步释放，只有展开前牌播放。

准备以真实hasFrame回调为准，不轮询、不读回截图、不用延时冒充ready。SDK新参数onFrameReadyChanged默认null、revealPausedFrame默认true，普通宿主行为保持；后帧派发及source/listener过时过滤、释放终态false有回归。App按GlobalKey当前身份与mounted处理。冷牌未ready就露出时锁住compact既有poster，迟到真实首帧不突然换面；主动展开解除，仍同一挂载视频，之后收起持当前帧。NativeRGBA/更多覆盖保持及Android实现与已确认+50相同，本轮未改Native/platform/video文件。

## 纵向运动

+50上下不是匀速，但900px/s限速把快甩压成同轨迹，临界阻尼k60的中段速度峰较平。新竖向k70、阻尼比.82，速度保留到2400，方向间连续插值；水平k240/阻尼比1原值保持。仍按实际投影边距+48余量沿释放射线退出，离屏及时交接；轻放有加速/收势，快甩区别保留。中央/反甩取消、全向阈值与减少动画保持。

## 验证

App相关10文件100通过/0失败/14跳过（12既有截图项+2需Impeller）；随后强化同名甩速用例为1200/2200（旧900cap会完全同轨迹），单项1通过；fatal-infos分析0，严格锁解析保持，hosted版本/摘要/来源不变。暖incoming双向晋升/取消时同State/controller/Texture、冷首帧迟到不改poster、短循环重复action、More/设置返回三暂停池、展开/收起持帧等回归通过。

Impeller两项另串行通过：新曲线离屏采样提前终止，共31姿态×两GPU帧=62组RGBA消费对照，均值RGB误差及黑残影全0；不沿用+50的68组计数。SDK相关3文件54通过/分析0；只新增readiness与揭示控制，原生GL代码保持。未跑全量App/SDK、模型、iOS或本地设备。新三暂停资源/接牌和手感仍待远程手机确认，本地fake状态/速度采样/桌面像素不能代替原机验收。

证据：`E:/AII-3D/hiplab-releases/home-card-handoff-motion-20261106/`；SDK在隔离副本packages/ugk_trainer_runtime/build/paused-frame-handoff/。+50历史原始GPU证据保持。

## 交付

| 项目 | 事实 |
|---|---|
| APK | `E:/AII-3D/hiplab-releases/home-card-handoff-2087649-51-20261106/hiplab-1.1.0+51-2087649-internal-arm64-release.apk` |
| 大小 / SHA256 | 47693736字节 / `35af6e9c7c7487510a76365015ba954e926e08e54d90d09e75fd5a1f32fcbe6a` |
| 证书SHA256 | `3761270a4764157f0e389014a9e5b800b05403bfddce0f4f7f8c039f6a53bdc7`，与+50内部包一致 |
| 身份 | com.ugk.hiplab/1.1.0/2051/release/仅arm64/非debuggable；构建83.9秒；重签runtime负载一致 |
| 内容 | 789资源项校验通过；r2-v1/stable、249目录动作、209授权/封面/未审AI标签、0内置MP4 |

App/SDK候选已推送。原上传签名归档、最终内部包和回执留同一E盘目录；Agent未安装，用户远程覆盖验收。main/release/tag/商店和本地设备未操作。
