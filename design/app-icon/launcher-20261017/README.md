# 站姿开髋：安卓正式图标资源

用户于 2026-10-17 认可第二个 B 方案，本目录据此准备 Android 图标。保留站姿抬膝外展、青玉绿、近白髋部转折及细腻立体质感。原始候选见 [B PNG](../sports-20261017/B-standing-hip-mobility.png)。

`foreground-source.png` 是通过内置 ImageGen 对 B 去背景得到的透明派生图，1254×1254，具体模型名未暴露；它不是原图像素完全不变的数学抠图。精确编辑提示见 [edit-prompt.txt](edit-prompt.txt)。前景导出源 SHA 为 `7a47256ed07228d8bf5d845fe95be027854835fd5eecc7648fc05a1954d16356`。

## 交付

- [Android 预览](android-preview.png)：圆形、圆角方形及示意主题配色；下排为 32/48/64px。主题预览不代表用户手机系统已启用主题图标。
- [透明前景](foreground-108dp.png)和[单色前景](monochrome-108dp.png)：432×432，对应 108dp / xxxhdpi。
- [商店图源](store-icon-512.png)：512×512，未发布商店。
- [导出清单](export-manifest.json)：29 个产物及 SHA，含 20 张各 density 资源、4 份 adaptive XML、背景色和预览文件。

遵循 [Android 官方自适应图标文档](https://developer.android.com/develop/ui/compose/system/icon_design_adaptive?hl=en)，在 108dp 图层中保留中央 66dp 安全圆；可见像素测得最大半径约 32.03dp，越界像素为 0。资源包括 API 26 自适应图标、API 33 单色图层和五档 legacy/round 图标，背景 `#101316`。没有伪称提供矢量源，iOS 图标尚未替换。

可重复执行 `node tools/export_android_icons.cjs`（需要 Node.js 与 sharp）。脚本只对已生成的透明图进行居中、尺寸导出、单色 alpha 派生和遮罩预览，不再生成或重绘人物。排布时以 alpha≥8 的可见范围计算位置，不删除或修补原图；具体版本和参数见清单。

App 版本为 0.1.2+3；实际构建、安装与设备检查统一登记在[版本台账](../../../docs/version-ledger.md)，不以资源生成代替实机验收。
