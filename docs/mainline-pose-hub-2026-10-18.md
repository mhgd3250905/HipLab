# 主干整合与 Pose-Hub v0.1.0（2026-10-18）

用户明确授权本机作为主干端，审核后按 #7 → #8 → #9 → rebased #10 合并，直接推送 main，无需另开 PR。本轮没有 force push、清理工作区或清除手机数据。原 `.playwright-mcp/` 保留。

## 集成与逐步验证

| PR | 固定审核来源 | main 集成 | analyze / Flutter 测试 / APK / 覆盖安装 |
|---|---|---|---|
| [#7](https://github.com/mhgd3250905/HipLab/pull/7) | `44db1fe6bd9145445d4549d5c0b3daf635d44abf` | `ba591bf`，补入已验证修复 `8650d49`，版本保持 0.3.1+6 | 0 问题 / 85 项 / 成功 / 成功 |
| [#8](https://github.com/mhgd3250905/HipLab/pull/8) | `0d0758768fcd5029a395a7cd41927c0e6f91c1e6` | `5bb43f0`，重生成内容并保留深蹲评分图说明修正 | 0 问题 / 85 项 / 成功 / 成功 |
| [#9](https://github.com/mhgd3250905/HipLab/pull/9) | `313b4848ff0a436b9b2c400ea1d95f97c30c308b` | `61979d8`，再合入已验收单屏自测与共享修复 `05ac3d7` | 0 问题 / 115 项 / 成功 / 成功 |
| [#10](https://github.com/mhgd3250905/HipLab/pull/10) | `c20fae57ee9c97e58f0999f13a5ff073f35f5d31` | 实际 rebase 为 `44a6fcf`、`88731a8`，由 `18a084b` 合入 | 0 问题 / 116 项 / 成功 / 成功 |

#10 冲突保留新版音视频、动态主题政策页、0.3.1+6 及当前台账；保留其网络权限说明、政策/复制链接回归及原送审记录。随后正常 merge 原源头为 `60a683c`，完整文件树与已 rebase 结果一致，仅补足原 PR 祖先关系，不重写远端分支。四个原 PR 头均为当前 main 祖先。

各阶段命令为 `flutter analyze --no-pub`、`flutter test --no-pub --concurrency=1 --reporter expanded`、`flutter build apk --debug --target-platform android-arm64 --no-pub`。每步完成后同证书 `adb install -r`，设置文件安装前后逐字节相同。Flutter 为 3.44.7 stable / Dart 3.12.2。

## 冻结素材

上游来源 `3D-Pose-Hub@ee9d7ea71c599037c00d0f0e4a1b7e70a65538e8`；同步脚本除来源头注释外与上游一致，发布清单逐字节一致。锁定 46 个 ID，dark/video 与 dark/poster 均为 1080，目标文件名保持既有 `hip-{id_lower}.mp4/.jpg`。

复用本地同名 ZIP，经校验恰为 **40,153,961 bytes**、SHA-256 **99c6013c4f137e426112db8f46832f2ad2f433ffbd72ff7f1e13670a62867990**。解压缓存位于已忽略 `build/pose-hub/v0.1.0/extracted`；ZIP 不入库。

`--from-dir` dry-run 显示 84 已匹配、8 待复制；正式同步复制 8 文件（青蛙式、90/90、90/90 抬脚、四足画圈各视频/封面），最终 `--check` 为 **92 matched / 0 drift，退出 0**。46 条视频均为 1080² / H.264 / 30fps / 8 秒 / 240 帧，封面均 1080²；元数据、原始文件和 APK 内资源 SHA 一致。

HipLab 自有 `supine-cross-demo` 视频/封面与 20 张自测静图，共 22 文件保持原字节，不进 lock。light 不在本包，浅色主题继续用深色舞台。`hip-content.json` 重生成后逐字节不变。旧 `tools/sync_drill_media.py` 已标弃用，历史来源保留在元数据中。新机器操作见 [README](README.md#新机器拉素材mac--windows)。

## 真机与首帧修复边界

设备 2602BRT18C / Android 16 / API 36 / arm64，初步素材包源码 `963db04`，0.3.2+7 debug。正常 App 流程下录制并检查下列六项；14 次采样均推进跨过完整 8 秒循环，后续采样 readyState 4、error null、1080²。

| 动作 | ID | 采样区间解码帧增加 | 跨循环 |
|---|---|---:|---|
| 四足画圈 | H-quad-cars | 343 | 是 |
| 青蛙式 | S-frog | 318 | 是 |
| 滑垫侧向滑 | N-slider-lateral | 308 | 是 |
| 坐姿分腿体前屈 | N-straddle-fold | 311 | 是 |
| 90/90 后腿主动抬起 | H-9090-liftoff | 310 | 是 |
| 90/90 自测 | S-9090 | 312 | 是 |

海报与人物截图已查看。逐帧复查六段录屏发现约 0.08–0.25 秒的首帧交接变暗，因此这六段只证明循环与资源可用，**不作为首帧无闪验收**。根因是网页视频本身从透明淡入，同时 Flutter 海报淡出；`9ef59a1` 去掉网页淡入，让视频预先不透明绘制在海报后，保留 App 单层海报淡出。

真实 Chrome / 原 H.264 回归通过：首帧前与 first-frame 事件时 opacity 均 1、transition 0s，readyState 4；跨 8 秒循环、暂停时间保持、恢复推进、首帧事件仅一次。相同探针使用旧 CSS 会失败。用户随后拔掉手机并要求改为网页调尺寸测试，因此最终修复 APK **已构建但未覆盖安装，原生首帧最终复验待补**。

测试过程中提前退出会按既有规则计入当天打卡（跳过动作也增加 completed）。测试结束将时长恢复 5 分钟，核对偏好唯一额外差异为本次测试增加的日期后撤回该条记录；重启后原 1356 bytes 偏好逐字节一致，SHA `74f83f14c7ef77da8cdf08e6886a5401ee86aa325a7f653f68a3fea5b6b07c21`。未清数据、未卸载、未改签名。

## 最终产物与交接

最终源码 `9ef59a17819edd22d0c9102f29d723222cc6c872` / **0.3.2+7 debug arm64**；analyze 无问题，Flutter **116 项单并发通过**，APK 构建成功。Python 同步工具 11 项与 iOS 工程静态检查通过；没有 Mac 构建或 iPhone 验收结论。

最终 APK：`E:\AII-3D\hiplab-releases\mainline-20261018\final\hiplab-0.3.2+7-debug-arm64.apk`，**150,742,085 bytes**；SHA-256 **6509ecca36162afc92737e3d3628c075b13c22d2814717763e6142df501fdfe1**。已核对 APK 内 92 个发布资源、22 个保留文件及修复后的 CSS/JS。该 APK 未在拔线后的手机安装，不是 Play 新送审产物。

构建、逐阶段安装、同步、原生录屏及浏览器证据保存在仓库外 `E:\AII-3D\hiplab-releases\mainline-20261018`，未上传 Git；正式 Play 仍沿用 0.2.0+4 / Submission 1 的历史送审记录，本轮未回读 Console。

网页在仓库外临时预览工程测试，未给正式 App 新增 Web 平台：320×568、360×740、390×844、768×1024 四种尺寸下演示区均为正方形，选项和下一项完整处于视口内、无重叠，滚轮不滚动答题页；六项自测切换、点按暂停/播放状态及最后选择答案进入结果页均检查通过。预览使用现有网页 poster stub；原生音频的 `Platform._operatingSystem` UnsupportedError 已单独记录，不据此验收真实视频或音频/系统行为。真实播放器由前述 Chrome/H264 探针另验。

`git push origin main` 已成功，远端回读 `9ef59a17819edd22d0c9102f29d723222cc6c872`。GitHub 四 PR 均回读 **MERGED**，mergedAt 均为北京时间 **2026-10-18 01:01:06**；各 merge commit 分别 `ba591bf` / `5bb43f0` / `61979d8` / `60a683c`。同次推送按祖先顺序进入 main，因此 GitHub 回执时间相同。后续只追加验收文档，不改变 APK 源码身份。

Mac 从最终 main 开始，按冻结 ZIP 恢复素材；Android 首帧最终原生复验、音乐 ducking、完整紧侧跟练、手动锁屏后台语音及 iPhone 系统行为仍各自待验证或后续开发。
