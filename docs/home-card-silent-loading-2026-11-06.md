# 首页动作牌静默加载 · +47 · 2026-11-06

运行/构建源 `bba10fdb98934cea5e9f27c3062a7ad74d79e43c`，候选分支 `codex/home-card-silent-loading-20261106`；`1.1.0+47` / arm64 `2047`。四个实际SDK包及coach override固定 `b4861c5215280c49bffe03b8c203074217dcf995`。日常目录 `feat/ui-detail-polish@25260b3` 保持。

按用户截图移除首页切牌时的加载转圈。SDK新增可选 `showLoadingIndicator`（默认true）；App仅对首页常驻前牌传false。下载和等待真实首帧期间保持公共封面，真实首帧到来后由同一媒体节点接上；展开/收起继续同一视频、关闭持当前帧。没有伪造就绪或更换解码器，实际失败仍提供重试。普通宿主默认提示保留，+46版式与+45透明合成修复继续保留。

## 验证

- SDK runtime相关31项通过，fatal-infos分析0：覆盖慢下载、待首帧不显示进度/直播语义、封面保留、真实首帧揭示、默认宿主及切换开关不重建播放器、真实失败重试。
- App相关10文件88通过/0失败/13跳过（12既有截图项+1需Impeller）；真实shader像素回归另串行运行1通过，fatal-infos分析0。新增第二张牌延迟350ms首帧回归，封面保持、无转圈且同一surface接上。
- 严格锁解析通过；lock只更新四个Git节点ref/resolved-ref，hosted版本、校验和与来源保持。未重跑全量App/SDK，不据此声明原生或实机FPS通过。

原始App检查：`E:/AII-3D/hiplab-releases/home-card-silent-loading-20261106/`；SDK检查：隔离SDK副本的 `packages/ugk_trainer_runtime/build/silent-loading/`。测试与日志不入Git。

## 交付

| 项目 | 事实 |
|---|---|
| APK | `E:/AII-3D/hiplab-releases/home-card-silent-bba10fd-47-20261106/hiplab-1.1.0+47-bba10fd-internal-arm64-release.apk` |
| 大小 / SHA256 | 47628200字节 / `9565860f314149716bb01f521b525c9e2f5b645979bd937228c433cc3914bb35` |
| 证书SHA256 | `3761270a4764157f0e389014a9e5b800b05403bfddce0f4f7f8c039f6a53bdc7`，与+46内部包一致 |
| 身份 | com.ugk.hiplab/1.1.0/2047/release/仅arm64/非debuggable；构建65.2秒；重签runtime负载一致 |
| 内容 | 789资源项校验通过；r2-v1/stable、249目录动作、209授权/封面/未审AI标签、0内置MP4 |

验包回执、原上传签名APK与最终内部包归档于同一交付目录。按用户决定交由用户远程覆盖测试，Agent未安装；连续切牌、展开/关闭与慢网首帧观感待用户反馈。本轮不操作设备、main/release/tag或商店，无iOS、模型调用或本地真机结论。
