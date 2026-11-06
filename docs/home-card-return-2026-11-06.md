# 首页动作卡片收起连续性 · 2026-11-06

运行/构建源 `32ac1a76e12894f6aedb8218be0b35a591fd3461`，分支 `codex/home-card-return-fix-20261106`；`1.1.0+43` / arm64 `2043`，四个实际 SDK 包及 coach override 固定 `4b9b685788352415fbfce2d8a2651f7f9d207512`。日常目录保持 `feat/ui-detail-polish@25260b3`；本轮在既有 E 盘隔离副本开发。

关闭展开牌时，先复用当前视频有界快放走完剩余循环、回首暂停，再执行原有缩牌；退场期间保留同一视频表面，避免路由失去 current 后过早切成封面。暂停后关闭也走同一流程，重复关闭合并。

前一轮+42（`3c0a1a0` / SDK97eb66d）已安装，用户反馈“好多了”，但指出动作播放后收起仍有姿态闪变，不能把该反馈记作+43通过。+42修正来源快照的完整投影/阴影、展开布局到原牌面的交接和value已0但status尚reverse时的同帧恢复；+43还加入不透明牌底，防止互补Opacity叠加仍透出背牌。`30d729f`是+43牌底中间提交，未单独出包。

## 实现与约束

App关闭、外部点击与系统返回统一先等待SDK操作。SDK增加独立可选 `DrillMediaPlaybackControl`，不修改只读handle合同。Android临时1–12倍正向播放剩余循环，完成后seek0确认并暂停，恢复1倍与循环；目标400ms，native上限1100ms、Dart1400ms。不可用/超时按false结束，仍能关牌；不把可选控制失败记成媒体损坏。当前片段为8秒，目标时长是软目标，实际需真机测量。

`retainSurfaceDuringRouteExit`默认false，只在展开牌开启。仅保留退出前已有表面；普通覆盖/后台/实际销毁按原规则释放。不新增视频、模型、训练状态或播放器依赖。SDK独立候选 `4b9b685788352415fbfce2d8a2651f7f9d207512` 已推送，未合main/tag；App main、release与商店未改。

先检索维护中的Flutter官方[video_player实现](https://github.com/flutter/packages/tree/main/packages/video_player)及[BSD许可](https://github.com/flutter/packages/blob/main/packages/video_player/video_player_android/LICENSE)，其控制层支持倍速/seek，但替换现有packed-alpha表面会扩大解码/透明合成变更。本次保留既有MediaPlayer/SurfaceProducer与shader，仅加入可选指令；原生状态按[Android MediaPlayer文档](https://developer.android.com/reference/android/media/MediaPlayer)处理。未复制外部实现。

## 已执行验证与待验

App 相关9文件84通过/0失败/12既有截图跳过（牌组33项）；SDK runtime相关26项通过，双方 fatal-infos 分析0。App严格锁解析通过，lock仅四个Git节点ref变化，hosted版本/摘要/来源保持；未重新跑全量App或全量SDK测试。

新增App回归使用真实TrainingActionMedia/Controller/桥接，只替换文件传输和native平台：pending期间路由保持current、重复close仅一次、native成功后才paused/pop、同一surface在reverse180ms后仍在、末端才dispose；paused关闭先恢复再发请求，避免sync取消。已有逐帧快照/交接/无空帧与减少动画路径继续通过。SDK覆盖控制请求、取消/超时/过期响应与退场保留/实际释放。

最终+43包已构建并完成签名/资源校验，尚未安装。2026-11-06 08:13起本机ADB未列出设备，已请用户重连；视频快放、停在首帧后的真实Surface交付及最终缩牌仍待Android真机验证，组件/fake平台通过不等于原生观感验收。

真机补验：动作播放到不同位置后X关闭、暂停后关闭、空白处/系统返回、换动作/快速重开；观察真实快速播放→首帧停稳→缩回，确认无黑帧/闪变及无残留播放器。没有iOS、实际显示FPS、真实模型或耳机结论。旧+41导航实测保持其原归属。

## 包与原始证据

- APK：`E:/AII-3D/hiplab-releases/home-card-return-32ac1a7-43-20261106/hiplab-1.1.0+43-32ac1a7-internal-arm64-release.apk`；47628200字节；SHA256 `e44ef9447eab5f8f502d149b795ba04a954b62fb96907c1d5e7a7f67f6f1ce9c`。
- 证书SHA256 `3761270a4764157f0e389014a9e5b800b05403bfddce0f4f7f8c039f6a53bdc7`，与此前内部+41/+42证书一致；签名及重签前后runtime负载校验通过。原上传签名包仅本地归档。
- SDK媒体r2-v1/stable：249目录动作、209授权/封面/未审AI标签、0内置MP4，789项包资源字节校验通过，素材内容未改。
- App原始检查：`E:/AII-3D/hiplab-releases/home-card-return-final-20261106/`；构建/签名/包身份：`E:/AII-3D/hiplab-releases/home-card-return-32ac1a7-43-20261106/`。
- SDK原始26项测试/分析：`E:/AII-3D/3D-Pose-SDK-worktrees/home-card-return/3D-Pose-SDK/build/home-card-return/`。
- +42先前录屏/快照：`E:/AII-3D/hiplab-releases/home-card-return-20261106/candidate/`，不冒充+43原生证据。
