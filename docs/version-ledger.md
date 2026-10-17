# 版本交付台账

仅登记实际产生的构建、安装或发布。文档提交不增加 App 版本；“安装成功”“PR 合并”“商店发布”分别记录。时间均为北京时间。

| 版本 | 交付日期 | 状态 | 内容与证据 |
|---|---|---|---|
| 0.1.0+1 | 2026-10-17 | Android debug 首次安装、启动通过 | 原迁移基线 `2865ed7`，首次安全引导截图；[首次运行记录](android-first-run-2026-10-17.md)下半部分 |
| **0.1.1+2** | **2026-10-17 13:15** | **Android debug 保留数据覆盖安装、冷启动、视频播放通过** | 应用提交 `35f2a977530bdcc6ab7e7caa9aa1d76dfe0bc53d`；46 动作 + 1 自测剪辑、47 张封面升级至 1080；[更新记录](android-first-run-2026-10-17.md)上半部分 |

两版均非商店发布。0.1.1+2 尚在 [HipLab #2](https://github.com/mhgd3250905/HipLab/pull/2)，没有将手机已安装等同于 main 已合并。

## 0.1.1+2 产物身份

| 项目 | 值 |
|---|---|
| 包名 / versionCode | `com.ugk.hiplab` / `2` |
| APK 路径 | `build/app/outputs/flutter-apk/app-debug.apk`，相对于仓库根目录 |
| 类型 / 大小 | debug 通用多 ABI / 203,896,543 字节 |
| SHA256 | `a9dcd836a91452a309154ae6b1a4da7db5c72e086c8bb44e123cfaecad69a2ce` |
| 原始动作源 | `175ff31c29895f5730fc344519da6cbe1108ab30`，已由 3D-Body #119 合并；三项派生修订及工具见 #120 `f8b5138` |
| 最终母版选择 | `E:\AII-3D\3D-Body\output\hiplab-delivery-20261017\selected-masters-46.json` |
| Android 派生批次 | `E:\AII-3D\3D-Body\output\hiplab-android-20261017-v2`；逐条元数据见 [hip-media.json](../tools/hip_content/source/hip-media.json) |
| 设备 / 数据 | 2602BRT18C / Android 16；覆盖安装前后 609 字节设置文件逐字节一致 |
| 验证 | 静态分析无问题、Flutter 49 项、同步工具 11 项、原生 WebView 一条实播；详见[验证台账](verification.md) |
| 本地证据 | `build/android-update-20261017/`；`build/media-audit/assessment-hd-sync-audit.json` |

APK 会被下次构建覆盖，以上 SHA 用于识别本次产物。旧版 APK 已归档到 `build/apk-history/hiplab-0.1.0+1.apk`，95,489,848 字节，SHA256 `efa0efd7e65e51a7c9f40d51937c83804411b4545cdf5248190425a9c48864f8`。本地 APK、截图和设置备份不在 Git 中；用户数据备份不得提交仓库。

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
