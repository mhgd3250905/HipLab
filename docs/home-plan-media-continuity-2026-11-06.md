# 首页计划切换媒体连续性 · +52 · 2026-11-06

## 当前验收结论

用户在+52覆盖安装后明确回复“我已已经验收通过了”，当前`1.1.0+52`（arm64 `2052`，构建源`59ce2b8`）记为**用户真机验收通过**。本轮首页动作卡片及计划切换优化的用户验收项已收束；不另推定未报告的逐项测试或性能指标。安装回执与APK身份保持，未重建或改运行代码；候选分支仍为`codex/home-plan-media-continuity-20261106`，合并状态独立记录。

用户确认回执：`E:/AII-3D/hiplab-releases/home-plan-59ce2b8-52-20261106/user-acceptance-20261106.json`。下方“待验收”保留为交付时历史，当前以本条为准。

运行/构建源 `59ce2b8829d64eec401c743123d31c57e79d4a62`，分支 `codex/home-plan-media-continuity-20261106`，版本`1.1.0+52` / arm64 `2052`。四个实际SDK包及coach override保持`6fbd7de15dea62c7152eac43df1303b85d887a7c`。日常目录`feat/ui-detail-polish@25260b3`与SDK工作副本保持clean；无main、release、tag、商店或本地设备操作。

## 原因与统一修复

办公/居家、换一套、跨日、profile/安全筛选改变动作列表，共用牌组重置入口。原来清空媒体身份后新首牌未锁住已显示封面，真实首帧迟到会淡入并改变姿态；此外目标封面尚未解码时，TrainerPoster在解码回调前可能为空。

初始冷首牌和重置后的冷首牌现在遵循同一展示规则：封面静止，原视频在其下准备，迟到真实首帧不突然换面；主动展开才解除，同一媒体继续播放，收起保持当前帧。若新首动作就是之前可见且真正就绪的动作，只保留该一个occurrence的GlobalKey、State/controller/Texture与原持图状态，不保留旧计划整套decoder。快速A→B→A由当前key过滤旧回调；metadata ready不能冒充真实hasFrame。compact收到真实失帧/释放回调时重新锁图；打开后首帧未到就关闭也重新锁住，避免关闭完再跳姿态。更多/设置覆盖返回、普通主题重建不重置已揭示帧。

首页还按当前筛选后的两场景可选计划提前解码各自首封面，去重后以`TrainingPosterImages.provider`、同`DefaultAssetBundle`和screen decodeWidth建立与实际TrainerPoster一致的cache key。只涉及有限首封面，不预加载全部209张或视频，不阻塞点击；bundle/尺寸改变重新建立命名空间，失败允许后续实际重建重试。普通卡片实际渲染仍走SDK。Android RGBA实现、SDK生命周期和+51竖向k70/ζ.82及水平参数保持。

## 验证边界

严格offline/enforce-lockfile解析成功，pubspec.lock字节保持；fatal-infos分析0。相关10文件106通过/0失败/14既有跳过（12截图项、2需Impeller），其中新增6项覆盖精确key封面预热、真实Home场景/换一套/跨日逐帧持图、快速切换过时帧、同identity动作列表变化、早关后迟到首帧、非0已就绪动作成为新首牌且不换controller/Texture。测试检查真实回调语义和组件身份，fake native平台不等于手机实测。

Impeller两项另串行通过，31个姿态×两帧共62组RGBA消费对照，RGB误差和黑残影均0。首次像素导出因目标目录未创建中止；创建后同源重跑通过，两次日志均保留。本轮未改Native/SDK，不重复既有SDK54项或原生算法验证。未跑全量App、模型、iOS或手机。+50更多/纵向透明异常保留用户已确认结果；+52场景切换、首次展开和视觉连续性仍待远程确认。封面预热是有限缓存准备，不承诺内存压力驱逐后的零解码延迟。

日志：`E:/AII-3D/hiplab-releases/home-plan-media-continuity-20261106/`；原始+50/+51证据保留。

## 交付

| 项目 | 事实 |
|---|---|
| APK | `E:\AII-3D\hiplab-releases\home-plan-59ce2b8-52-20261106\hiplab-1.1.0+52-59ce2b8-internal-arm64-release.apk` |
| 大小 / SHA256 | 47693736字节 / `3bac5de8477199360cab68c74cfaa446c1c2f74d3f5117ba752b4a2a203692e9` |
| 证书SHA256 | `3761270a4764157f0e389014a9e5b800b05403bfddce0f4f7f8c039f6a53bdc7`，与+51内部包一致 |
| 身份 | com.ugk.hiplab / 1.1.0 / 2052 / release / arm64 / 非debuggable；构建92.6秒；重签runtime负载一致 |
| 内容 | 789资源项校验；r2-v1/stable、249目录动作、209授权/封面/未审AI标签、0内置MP4 |

原上传签名、内部覆盖包和回执留同一E盘交付目录。App候选已推送，未安装，交用户远程覆盖测试。

## 真机安装追加回执

用户重新连接手机并明确授权安装。已在`2602BRT18C`（`QSG6Q8IFDMDELVGQ`）执行`install -r --no-incremental`，回执Success；包管理器从2051更新为2052（1.1.0），设备lastUpdateTime为2026-11-06 22:12:14。未卸载、未清数据；原firstInstallTime仍为2026-11-05 22:11:33，未另核验业务数据。`com.ugk.hiplab/.MainActivity`冷启动Status ok；这里只确认安装与启动，卡片切换/展开/播放观感仍待用户使用反馈，不据此宣布视觉或性能验收。

安装包仍为构建源`59ce2b8`，SHA256 `3bac5de8477199360cab68c74cfaa446c1c2f74d3f5117ba752b4a2a203692e9`；无重建、运行代码、SDK或版本变更。安装回执留`E:/AII-3D/hiplab-releases/home-plan-59ce2b8-52-20261106/device-install-20261106-221214.json`。下方交付时“未安装”保留为历史；当前状态以本条为准。
