# Pose-Hub v0.2.0 接入（2026-10-18）

原 main `bb828be30a6d3631538fc732154c5985c44ef2f8`；上游固定 `59fb7b9c68867ef57ff6d2fe5c8b72da3022fac4`，soft-v1 dark发布。Pose-Hub v0.2.0，视频 1080² / 封面 540²，46 个原 ID 与文件名保持。App 0.3.4+9，源码 `03c3b5bcd1ebc0157e3789af21a4bf0188f52468`，已构建但未安装；业务代码 `03c3b5bcd1ebc0157e3789af21a4bf0188f52468` 已于 2026-10-18 11:40 北京时间推送 main。手机仍为 `963db04` / 0.3.2+7，本轮无 ADB 或商店操作。

## 固定分发与范围

[ZIP](https://drive.google.com/file/d/17M0oMpWIqWQJ19sMEOEsDF7H7AU9meqF/view?usp=drivesdk) / [目录](https://drive.google.com/drive/folders/12M4g7bpomaCjY7qdgYdfoUHuA2xla9lH)；39,151,634 bytes，SHA `f422c051eab2b4e973fe637d5f2a3dec07207e21b960f10800efe77dd317c772`。云端冻结manifest SHA `76be4160b48f1a8d658d558b30418fe11e686a241bdfd63d2b7ee8fa45012889`；均已下载核验，安全解压92文件。ZIP不含manifest、绿幕、透明母帧或light，根直接是动作ID文件夹。视频1080²、封面540²，46个ID/目标文件名保持；44条8秒/240帧，n-leg-circles为12秒/360帧，t-seated-straddle-lift-1leg为10秒/300帧，与旧元数据时长完全一致，poster_time亦未变。实际自有文件hip-supine-cross-demo.mp4/.jpg及20张still保留，不从HipLab重渲。

制作源码 `cf2c6bdffcb8a9d9bd7dc3afd0a6ddbf57aef618` 与发布快照 `59fb7b9c68867ef57ff6d2fe5c8b72da3022fac4` 分开登记。仓库完整manifest SHA `ec05dee9508a58d1ea8c1e9c95eee77189afc141b0e03f32cf48185ce3c85acd`；云端单版本manifest与完整清单的0.2.0 release对象精确一致。替换前每项来源完整快照存于prior_sources，已有prior数组亦保留。

同步脚本与原 main `bb828be` 逐字节一致，保留原 `ee9d7ea` 来源注释；已核对其正文与发布提交 `59fb7b9` 相同；dry-run只校验选择/映射，不能冒充完整文件校验。

45 项规格路径和哈希继承 v0.1.0，只有 `h-quad-cars` 从 r2 回到原规格。`s-frog-r2`、`s-9090-r2`、`h-9090-liftoff-r2`、`h-knee-hug-r2`、`h-supine-twist-r2`、`s-seated-fold-r3` 六项修订均保留。soft-v1 大面积高亮分段线等上游已知限制仍见[固定发布说明](https://github.com/mhgd3250905/3D-Pose-Hub/blob/59fb7b9c68867ef57ff6d2fe5c8b72da3022fac4/media/releases/0.2.0.md)。

## 本机检查与交付

| 检查 | 实际结果 |
|---|---|
| dry-run → sync → check | dry-run 92项计划；首次92 copied；check 92 matched /0 drift；重复同步0 copied |
| 46 视频 / 46 封面元数据 | 本机92文件大小/SHA全匹配；46视频H264/yuv420p/1080²/30fps/无音轨，11220帧；完整CPU解码通过；46封面均540²JPEG |
| 自有剪辑 /20张 still | hip-supine-cross-demo.mp4/.jpg +20张自测still，共22文件SHA保持 |
| 内容重生成 | 来源metadata更新后重生成hip-content.json逐字节不变；时长与poster_time均保持；旧来源完整快照及prior数组保留 |
| analyze | exit 0，无问题 |
| Flutter | 单并发156通过、1条件跳过（未设置VOICE_TIMELINE_OUT），exit 0 |
| Python | 本轮未重复；上一轮11项已通过，Python工具逻辑未改变 |
| iOS 静态 | 本轮未重复静态检查，ios/文件未改；Mac构建与iPhone仍待验 |
| APK 内容 / 身份 | 包名com.ugk.hiplab、versionCode9/versionName0.3.4、既有debug证书匹配；包内92新素材、22自有文件、488语音及共享播放器与源码匹配；未安装 |
| 临时网页 | Chrome实际共享player.html/player.js，青蛙式、90/90、抬脚、四足画圈、臀大肌、屈髋肌测试共6动作：首帧事件/opacity1/contain、至少一次循环、暂停无时间漂移和恢复通过，截图已查看；独立App预览换入新封面，320×568/360×740/390×844/768×1024正方形示范、按钮完整与无滚动、6项自测和结果完成通过。App预览仍为poster stub+静音fixture；键盘启用可访问性后坐标操作，非原生验收；未证明原生无黑闪或系统音频通过。 |

| 项目 | 结果 |
|---|---|
| App版本 / 源码 | 0.3.4+9 / `03c3b5bcd1ebc0157e3789af21a4bf0188f52468` |
| APK | `E:\AII-3D\hiplab-releases\posehub-v020-20261018\validation\hiplab-0.3.4+9-debug-arm64.apk` |
| 字节数 / SHA | 150,880,644 / `ded02ba1f26c263c6e0d8c88d62a4b0fe43f6e6a5dba9a29baf6ba21773d4e75` |
| 媒体 | v0.2.0，46视频1080 /46封面540 |
| 核验 | 包名com.ugk.hiplab、versionCode9/versionName0.3.4、既有debug证书匹配；包内92新素材、22自有文件、488语音及共享播放器与源码匹配；未安装 |
| 安装 / 远端 | 未安装，无ADB；业务代码 `03c3b5bcd1ebc0157e3789af21a4bf0188f52468` 已于 2026-10-18 11:40 北京时间推送 main |

本轮无ADB和商店上传；不调整版本号以外发布配置。手机保留原安装，native/iOS人工观感、系统行为仍待验。未登记项不当作通过。v0.1.0和#7/#8/#9/#10/#13/#14历史记录保留，见 [前轮主干记录](mainline-pose-hub-2026-10-18.md)、[第二轮记录](round2-integration-2026-10-18.md)。

本机证据目录：`E:/AII-3D/hiplab-releases/posehub-v020-20261018/`。包含发布差异、完整解码、92 文件哈希、22 个保护文件、APK 核验、共享播放器与网页尺寸报告；本机路径不代表远端备份。

## 指定分支与合入后复打包（2026-10-18）

用户本次指令到达前，素材已按原授权随 `03c3b5b` / `a70df11` 推送 main。本次补建 `media/pose-hub-v0.2.0`，起点为 `bb828be`，快进接入上述已有提交，按“脚本未变就不动”恢复同步工具与基线逐字节一致，再合回 main。没有重写已推送历史。Dart、资源、依赖及 `pubspec.lock` 未新增变化；沿用已递增的 0.3.4+9。合入后重新执行 Android debug arm64 构建，实际产物追加版本台账，并向 Mac 的 `ios/device-validation` / PR #15 同步新 main 基线。

合入后复打已完成：源码 `1a1657da91ea4b2d2a189e1439f370ed6d083e24`，0.3.4+9，17.42 秒；APK `E:\AII-3D\hiplab-releases\posehub-v020-request-20261018\final\hiplab-0.3.4+9-debug-arm64.apk`，150,880,644 bytes / `ded02ba1f26c263c6e0d8c88d62a4b0fe43f6e6a5dba9a29baf6ba21773d4e75`，包与资源核验通过，未安装。原有运行检查内容未变，具体边界见[复核台账](verification.md)。Mac 交接通过 `ios/device-validation` 的 [PR #15](https://github.com/mhgd3250905/HipLab/pull/15)同步最终新 main。
