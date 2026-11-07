# 二级页面转场卡顿：定位、优化与+41交付

运行/构建源 `58aa468c2707361e917cea2b75fc4561a23b4473`，独立分支 `codex/navigation-transition-perf-20261106`；`1.1.0+41` / arm64 `2041`。继承+40动作牌，SDK97eb66d、lock、资源与原生配置不变。

## 问题与改动

用户报告首页→更多较顺，而更多→训练组/设置/训练记录、设置→隐私政策顿挫。检查发现`_HipBarGlass`的三个ShaderMask/BackdropFilter没有显式绘制clip；SizedBox、Stack和RepaintBoundary不能代替真实裁剪。首页来源没有该顶栏，二级页面前后各一套，转场重叠时最多六层大模糊。固定胶囊本身已有44pt ClipOval，不能把主要问题归咎于返回图标。

在条带RepaintBoundary内增加`ClipRect`，使三个滤镜的readback/cull范围限于状态栏+44/52pt标题行+fade。保留34/20/9三层sigma、渐变、44pt固定胶囊、视差和曲线，不将重叠滤镜合并到同一BackdropKey；没有重做导航或取消固定按钮。

将每条顶栏的三层模糊显式裁剪到实际条带，保留固定返回键、三层参数、400ms进入/340ms返回与原曲线。二级路径真机profile暖态对照中，raster超过120Hz阶段预算的帧比例由96.5%降至12.8%；该指标不是实际显示掉帧率。

## 同入口真机profile对照

基线为377c211（运行文件与已装+40/ba40e38一致），候选58aa468。使用相同外部`profile_entry.dart`调用真实`app.main()`，相同Flutter3.44.7、SDK/私有测试配置和手机。只在诊断入口注册`SchedulerBinding.addTimingsCallback`批收FrameTiming，经本地VM服务拉取，没有逐帧log；采样时不录屏。正式release恢复lib/main.dart，验包确认libapp.so没有`ext.hiplab.navSample`。

基线/候选各40个进退样本：5路径×4轮×2方向。r0作为首轮保留，表格只统计r1-r3暖态。每次进入后的UI XML验证实际目的页标题，40次目的页检查全通过；采样静置后开始，等待动画结束后排空200ms批次，再按engine vsyncStart筛入begin/end请求窗口。120.00001Hz，阶段预算约8.333ms，UI和raster分别比较，不相加，也不使用totalSpan反推FPS。

| 路径 | raster中位数ms：前→后 | raster P95 ms：前→后 | 超8.333ms帧数/采样帧：前→后 |
|---|---|---|---|
| 首页→更多 进入 | 6.571→5.466 | 10.824→10.581 | 104/285→24/298 |
| 首页→更多 返回 | 8.551→5.554 | 14.471→17.509 | 73/109→10/112 |
| 更多→训练组 进入 | 10.441→6.020 | 11.442→16.763 | 118/118→19/136 |
| 更多→训练组 返回 | 10.295→5.737 | 14.384→10.664 | 95/102→13/123 |
| 更多→设置 进入 | 10.736→6.087 | 11.714→16.618 | 113/115→21/133 |
| 更多→设置 返回 | 10.362→6.162 | 19.541→12.976 | 95/99→14/123 |
| 更多→训练记录 进入 | 10.554→5.839 | 11.654→14.195 | 115/116→13/137 |
| 更多→训练记录 返回 | 10.326→5.631 | 20.403→10.513 | 92/98→10/124 |
| 设置→隐私政策 进入 | 10.309→5.814 | 12.264→12.973 | 113/116→21/138 |
| 设置→隐私政策 返回 | 10.350→6.336 | 17.828→13.185 | 91/98→21/120 |

四条二级路径合并进入/返回：基线832/862（96.52%），候选132/1034（12.77%）。多数帧渲染耗时由约10.3–10.7ms降至5.6–6.3ms，UI暖态P95也多在1ms附近。

部分进入路径的P95仍有尖峰、个别P95高于基线，原始数据与表格照实保留；不宣称所有帧达120fps或所有设备零卡顿。结论是可重复的双页模糊负载显著下降，正式release实际转场与外观复查正常。一次早期零时长ADB点按没有发生转场、仅收1帧，保留为diagnostic-home-more.json并排除；正式采样统一使用100ms真实按压。

证据根目录：`E:/AII-3D/hiplab-releases/navigation-jank-20261106/`。`baseline/samples/`、`candidate/samples/`为80个原始窗口，`profile-comparison.json`为汇总；外部入口和采样脚本均留在Git外。只移除了本轮创建的两个ADB端口转发及私有VM地址文件，不清空系统日志或其它会话转发。Perfetto FrameTimeline/Android HWUI对Flutter SurfaceView的覆盖边界不足以代替本次Flutter阶段计时，因此未将它们冒充FPS。

## 检查与最终设备验收

5个相关测试文件47通过/0失败（新增7项真实paint-clip、浅深/副标题/高对比/多层路由回归），fatal-infos分析0，严格锁解析不改lock；未重新跑全量App测试。

最终+41 release同签名覆盖成功，回读2041/1.1.0，冷启动Status ok/191ms。浅色五路径进退、深色设置/隐私及内容滚过顶栏已检查；已恢复原浅色选择、回到首页。按用户要求锁屏，系统回读keyguard showing=true、inputRestricted=true，电源为Dozing（设备常亮显示状态）；不再操作手机。

`release-native/navigation-release-41.mp4`、`transition-frames.png`显示固定返回键保持原位置且只有一个，页面整体滑入；`light-route-contact.png`覆盖五条浅色路径，`07-settings-dark.png`/`08-privacy-dark.png`/`09-privacy-dark-scroll.png`补深色与顶部透视滚动。录屏只用于视觉，和未录屏的profile量化分开。没有新增iOS设备、原生训练/声音、模型或锁屏持续播放结论；末尾锁屏只是用户明确要求的设备操作。

## APK身份

| 项目 | 实际结果 |
|---|---|
| APK | `E:/AII-3D/hiplab-releases/navigation-58aa468-41-20261106/hiplab-1.1.0+41-58aa468-internal-arm64-release.apk` |
| 包 / 模式 / ABI | com.ugk.hiplab / 1.1.0 / 2041 / release / arm64-v8a / 非debuggable |
| 字节 / SHA256 | 47628200 / `b3e96c61334e77a1e82ee3b45d6d199356b4fc19e68990c231865c37d98bb13f` |
| 证书SHA256 | `3761270a4764157f0e389014a9e5b800b05403bfddce0f4f7f8c039f6a53bdc7`，与本机现装开发包连续 |
| 验包 | CRC、789资产原字节、249目录/209授权/209封面/209未审标签/0MP4，重签前后负载一致；无诊断入口 |
| 配置 | 外部临时define提供既有私有配置，临时文件已删；原上传签名包只归档、未上传 |

本轮普通推送独立候选；日常目录feat/ui-detail-polish@25260b3保留，main、PR31、release/1.0、tag及商店未由本轮推进。文档提交与上述构建源分开，不因文档变化重复出包。

## 官方依据

[BackdropFilter](https://api.flutter.dev/flutter/widgets/BackdropFilter-class.html)说明无clip时作用于全屏，并说明重叠filter不能共用BackdropKey；[Flutter源码](https://github.com/flutter/flutter/blob/3.44.7/packages/flutter/lib/src/rendering/stack.dart)显示Stack只在几何溢出条件成立时裁剪，因此现有布局边界不够。使用当前Flutter BSD-3-Clause实现，无新包或复制第三方代码。[FrameTiming回调](https://api.flutter.dev/flutter/scheduler/SchedulerBinding/addTimingsCallback.html)用于阶段计时；[Perfetto FrameTimeline](https://perfetto.dev/docs/data-sources/frametimeline)的SurfaceView限制保留为测量边界。
