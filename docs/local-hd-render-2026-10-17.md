# HipLab 本地高清与绿幕制作（2026-10-17）

按用户授权，已在本机开始高清动画制作，并审核合并 3D-Body PR #119。用户随后补充要求绿幕素材，便于后续去背景并适配浅色、深色界面；本批保留深色对照版、透明原始帧，并另出纯绿背景视频。

## PR #119 审核与合并

- 对象：[3D-Body PR #119](https://github.com/mhgd3250905/3D-Body/pull/119)。
- 审核源：`175ff31c29895f5730fc344519da6cbe1108ab30`。
- 审核时目标 master：`bc2b148471ca2e8629457136b4e66078a7e75ade`；PR 报告 base 为 `f4c97da3434f819026ad40298ee4717e2c096144`。
- 23 个文件涉及 21 份新动作/自测规格、SHA 登记与说明文档，不修改旧动作、人体、渲染器或 App。
- 隔离副本 `node tools/drill-anim/verify.mjs` 通过：159 份规格、51 个原 App 动作、13 份人体固定源符合契约，原规格哈希保持。目标分支在 PR base 后没有修改制作工具路径。
- 无查实阻断项。结束复核 head/target 未变化，状态 CLEAN / MERGEABLE。未把无 CI 或源码校验通过解释为全片验收通过。
- 已按明确合并授权于北京时间 2026-10-17 10:29:08 合入 master，合并提交 `ae81d96f271a18129abbf6afc7064cfd9dd1d8c3`；已回读 GitHub 状态 MERGED。

非阻断文档差异：新增规格实际为 15 fps，而文档描述母版 30 fps；90/90 五张自测图的示例漏第 105 帧；深蹲 B 图文档写半蹲、源规格与 App 实为脚跟抬起。制作记录以实际源文件、采样与输出探测为准。

## 制作身份与实际 GPU

制作副本：`E:\AII-3D\3D-Body-worktrees\hiplab-hd-20261017`，分支 `codex/hiplab-hd-20261017`，从审核源提交建立。既有 3D-Body 主目录的分支和未提交文件保持。

输出批次：`E:\AII-3D\3D-Body\output\hiplab-hd-20261017`。

实际探针报告：`ANGLE (NVIDIA, NVIDIA GeForce RTX 4080 Laptop GPU ..., Direct3D11)`，绘图缓冲区 2160×2160。显卡为 12 GB RTX 4080 Laptop GPU；没有使用 SwiftShader 软件渲染。

本批制作参数为：1080×1080 成片、真实 30 fps、`--pr 2`（2160 原始采样）、`training-human-v2` 人体、`alignClavicles: false`、显式 `themes/glow-b.json`。通过额外规格 wrapper 引用原动作文件，只覆盖帧率与指定人体身份，原姿态轨迹、时长、镜头参数和冻结引擎保持。

初始三项关键帧预览为坐椅雨刷、90/90 坐姿换髋、90/90 后腿主动抬起；已查看画面，原 QA 的样本检查通过（3 帧，忽略必然为 false 的全片完整性标记）。完整循环 QA 继续单独执行。高清对比图在 `comparisons/chair-wiper-comparison.png`。

## 运行与恢复

独立隐藏队列已启动，范围为 45 个 MVP 动作和 1 个备选。优先未接入视频的动作，最多两路 3D 渲染，每路 `--jobs 1`。已有深色成品和旧 App 素材保持；已完成或待复核的输出不重复覆盖。

每项先生成关键帧预览，再调用原 QA 阈值预检；预检异常进入 review/error，符合条件才制作全片。全片记录完整帧数、原 QA、完整解码结果；pass 与 review 分开。磁盘空闲低于 15 GiB 时停止新派发。

状态与证据位于批次目录：

| 路径 | 用途 |
|---|---|
| `gpu.json` | GPU 厂商、渲染后端、实际采样尺寸 |
| `source-manifest.json` | 源提交、规格哈希、制作覆盖参数 |
| `queue-status.json` | 总队列、各项状态、活跃进程 |
| `progress-8860.json`、`progress-8861.json` | 两路全片生产结果 |
| `queue-logs/` | 每项预览、预检、全片日志 |
| `master/`、`master/metrics/` | 深色对照视频、接触表及完整 QA |
| `preview-work/` | 关键帧、样本 QA |
| `work/<id>/fr/` | 2160 RGBA 原始主/高亮帧与逐帧指标 |
| `work/<id>/c/place.json` | 合成缩放及位置，供绿幕沿用 |
| `greenscreen/media/master/` | 1080/30fps/CRF14 纯绿背景视频 |
| `greenscreen/alpha/<id>/` | 精确 placement 后的透明 PNG 序列 |
| `greenscreen/jobs/<id>/result.json` | 绿幕最终完成标记、源 QA、逐项输入/输出 SHA、完整解码结果 |
| `greenscreen/delivery-manifest.json` | 已完成绿幕清单与全批次完成标记 |

重新运行队列脚本时，它会读取状态并监控原有 worker，不能在旧 worker 仍运行时另开无约束批次。已有初始 worker 的 PID 只用于首次接管，恢复后以状态文件记录的进程身份为准：

```powershell
python tools/hiplab-render/run_queue.py --app E:/AII-3D/3D-Hip --output E:/AII-3D/3D-Body/output/hiplab-hd-20261017
```

该命令从制作副本运行。状态文件中的 completed_with_issues 表示队列执行结束但仍有需修复/核对动作，不能解释为全部交付通过。

## 绿幕与透明素材

绿幕是从真实 RGBA 原始帧按相同 placement 单次 alpha 合成到 `#00FF00`，沿用人物、肌肉高亮与必要道具。去掉后期渐变背景、地面阴影及外围光晕，避免将这些效果一起抠入新背景。原动作求解和 GPU 主渲染不重复执行。

后续 worker 默认优先制作绿幕版，改用新增的 `composite_alpha.py`；原冻结合成器保持。三组实际预览共 12 帧验证 placement 完全一致、画框边缘 QA 数值误差为零，前景与无 mask 粘贴的原始 RGBA 逐像素一致。同四帧合成实测 1.749 秒，对照深色流程 7.737 秒（只代表合成阶段约 4.42 倍提速）。最初启动的深色参考 worker 保持运行，并由只处理这四项的绿幕导出进程补出绿幕。

保留透明母帧可直接用于后续合成，避免必须从 H.264 绿幕重新恢复边缘。绿幕视频仍需检查编码色度采样、人物边缘、手指、道具细线和肌肉高亮；尤其 B 主题有偏绿色的阴影，不能只扩大去绿阈值。不会把绿底视频直接放进尚未实现去绿的 App 播放器。

坐椅雨刷与 90/90 的真实关键帧已另出绿幕、透明 PNG 和白/暗底对照。90/90 样本中的 158 个青蓝高亮像素在固定 key 下全部保留，背景绿纯度 100%；普通 key 仍有细绿边，精确 alpha 对照保持边缘。该结论只覆盖已检查的关键帧，完整视频会另做时间采样与全片解码。

首条完整交付 `n-chair-wiper` 已完成：1080×1080、30 fps、8 秒、240 帧，绿幕 MP4 为 1,088,204 字节，同时保留 240 张精确透明 PNG。原全片姿态 QA PASS、绿幕合成 QA PASS、完整 CPU 解码 PASS；已检查首帧、海报帧、中点、末帧及白/暗底边缘对照。视频 SHA256 为 `148c8cf3e85483a73fdf1cb3e8b76bbe684c5f19ea3037c797ee1f578e549648`。

`s-9090` 原全片姿态 QA 与深色参考解码均通过；首轮绿幕 4:2:0 编码的一个时间样本青蓝高亮误差为 10.086，超过既定上限 10，未发布完成标记。后续需改善编码色度保真，保持 QA 阈值。关键帧曾通过不代表完整视频通过。

本次状态为制作进行中，46 项全批次尚未完成，成片、绿幕输出与最终验收数量以状态文件和后续检查记录为准。队列在独立隐藏进程中持续运行。

制作工具本地提交为 `6b4bf3a`，随后 `625b016` 修复恢复时 JSON 数值格式变化导致的源清单字节变化，新增不可变清单回归检查；源动作提交仍固定为审核过的 `175ff31c29895f5730fc344519da6cbe1108ab30`。13 项制作工具测试及 7 项 App 同步工具测试通过。

## App 同步工具

`tools/sync_drill_media.py` 已支持 `--size 1080 --crf 18 --poster-size 1080`，保留源帧率，并登记源提交与制作批次；默认 720/CRF27/海报540 继续保留。仅 QA PASS 的视频可导入。内容生成器显式输出 LF，避免 Windows 换行造成整个生成文件变化。

例如在 App 仓库中先预览深色成片同步：

```powershell
python tools/sync_drill_media.py --threed-body E:/AII-3D/3D-Body-worktrees/hiplab-hd-20261017 --out E:/AII-3D/3D-Body/output/hiplab-hd-20261017/master --size 1080 --crf 18 --poster-size 1080 --force --dry-run
```

绿幕制作与 App 深浅模式的播放器接入是不同步骤，本轮没有改变手机已安装 App 的视频或模式。
