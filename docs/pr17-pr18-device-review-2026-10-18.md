# PR #17 / #18 Windows 审核与 Android 真机验证

2026-10-18，北京时间。**本次审核未通过，两个 PR 均未合入 main。** 查实两项 P2：#17 的中途切回 Tab 跳变；#18 的分段控件无按压下沉。当前手机安装的是下述 PR 组合验证包，版本仍为 0.3.6+11，不能把同版本号理解为 main 原包。

## 固定审核对象与隔离集成

| 对象 | 固定提交 / 目标 |
|---|---|
| [PR #17](https://github.com/mhgd3250905/HipLab/pull/17) | `e7cb11eda77cfbe14c968b643419daf9538b69e6` → main `fce7ad84baf5dd364afa23dd08572976792c21e4`；PR baseRefOid 同 main |
| [PR #18](https://github.com/mhgd3250905/HipLab/pull/18) | `5711b4215ee26f35a20a342168fcf91747020ecf` → fix/transition-quality `e7cb11eda77cfbe14c968b643419daf9538b69e6`；PR baseRefOid 同目标 |
| 隔离组合 | `codex/pr17-pr18-validation`：本地 `f85c3e3` 集成 #17，`d4ebfc5` 再集成 #18；运行代码、测试、Android/iOS、依赖及素材相对 `5711b42` 完全一致 |
| 合并边界 | #17 对 main 有 `docs/verification.md` 追加冲突；再叠 #18 有 `docs/development-log.md` 追加冲突。隔离副本保留双方历史，无运行代码冲突。源 PR、main 均未写入 |

GitHub 入场状态：#17 OPEN / CONFLICTING，#18 OPEN / MERGEABLE；两者没有 CI 检查或已提交审核结论。本报告是本次 AI 审核，不代表 GitHub approval。用户本轮要求全部通过后再征得同意，按 #17 → #18 合入，优先于 AGENTS 的一般直接推主线授权。

## 查实问题

### F1 / P2 / PR #17：中途切回 Tab 时画面不连续

`lib/hip/ui/hip_routes.dart:639–647` 依据新的 incoming/outgoing 身份，用两套函数重新解释同一个动画进度 `v`。切至另一页 150ms 后立即切回，零时间重建就使原页透明度从 **0 跳到 0.3525625914**、横坐标从 **0 跳到 −7.101837px**（测试宽 400）。这是可见内容突然替换，原有“单次完整切换不叠影”测试未覆盖中途反向。真机快速点 Tab 无崩溃；上述定点回归证实连续性失败，不能标作转场质量通过。

复现：`flutter test --no-pub test_screens/review/hip_tab_reversal_review_test.dart`，2 项按预期失败。修复建议是先采样当前各页 opacity / dx，再从这些值开始下一段 fade-through，避免切换身份时重新映射旧进度。此轮仅审核取证，尚未改动该实现，修复轮次 0。

| 同一虚拟时刻，切回前 | 切回后（未推进时钟） |
|---|---|
| ![切回前](images/pr17-pr18-device-review-2026-10-18/reversal-before.png) | ![切回后](images/pr17-pr18-device-review-2026-10-18/reversal-after.png) |

### F2 / P2 / PR #18：分段控件无按压反馈

`lib/hip/ui/hip_segmented.dart:75–76, 108–118, 140–146`：选中滑块 `HipTactile` 在 Stack 的兄弟分支，读不到各段 `HipPressable` 内部的 `HipPressedScope`，段本身又是 `scale: 1`。首页时长/场景、语言、外观和 45/60 提醒长按时没有材质下沉；系统移除动画后也一样。

正常及减少动画测试中，持按 240ms 后高光 alpha 都仍是 **0.1411764705882353**，idle / held 截图完全相同；真机首页选中分段裁剪区域也逐像素相同。对照普通小按钮可看到真实按压变化，排除了输入未生效。建议将按压与取消/拖动状态传给选中滑块，补正常及减少动画的回归。此轮未修改运行代码，修复轮次 0。

| 真机选中块：松开 | 真机选中块：按住 |
|---|---|
| ![松开](images/pr17-pr18-device-review-2026-10-18/native-segment-idle.png) | ![按住](images/pr17-pr18-device-review-2026-10-18/native-segment-held.png) |

另有轻微时序不一致：`HipTactile` 恢复材质固定 100ms，`HipPressable` 松开缩放为 180ms。未将此单独升级为阻断问题。长按「开始」/「开始自测」后的首帧怀疑经实际绘制像素回归均通过，不作为缺陷。

## 本地验证与已修的小问题

- Flutter 3.44.7 stable / Dart 3.12.2；`flutter pub get --enforce-lockfile` 成功，依赖、`pubspec.lock`、版本、发布配置无变化；冻结 Pose-Hub 92 matched / 0 drift。
- 原样组合：`flutter analyze --no-pub` 0 问题；`flutter test --no-pub --concurrency=1 --reporter expanded` **178 pass / 1 条件 skip**（未设置 VOICE_TIMELINE_OUT）。原四尺寸布局回归包含其中。
- 审核补测放在 `test_screens/review/`，与日常全量区分。最终 6 项中 **2 pass / 4 fail**：两项持按松开实际首帧通过；分段正常/减少动画各失败；Tab 透明度/位置各失败。未把预期暴露缺陷的失败算成通过。
- 已将 `test_screens/hip_button_gallery_test.dart` 的提醒 45/60 模拟区改为小号 `HipSegmented`，并将旁边试听改为实际 `HipChipButton`。深/浅 gallery 2 项通过，修后 analyze 0；没有改动正式 App 运行代码。

## APK、安装与数据保持

| 项目 | 实际结果 |
|---|---|
| 构建源码 | `d4ebfc5`，运行内容等于 `5711b42`；后续仅审核测试、gallery 工具和文档 |
| 版本 / 包名 | 0.3.6+11 debug / `com.ugk.hiplab` |
| APK | `E:/AII-3D/hiplab-releases/pr17-pr18-20261018/hiplab-0.3.6+11-pr17-pr18-debug-arm64.apk` |
| 大小 / SHA-256 | 150,894,768 bytes / `e79052fd4015935ed6f1e72b230213d2f9814846919d3ff0bbad5c26be225847` |
| 签名 / ABI | apksigner 验证通过；既有 debug 证书 SHA-256 `3761270a4764157f0e389014a9e5b800b05403bfddce0f4f7f8c039f6a53bdc7`；Flutter engine 为 arm64，APK 还含插件的其他 ABI JNI 库 |
| 真机 | 2602BRT18C / Android 16 API36 / 1280×2772 / density 520；MT6991，非低端机 |
| 安装 / 启动 | `adb install -r` Success；versionName0.3.6/code11；冷启动 Status ok，1189ms |
| 安装数据 | 先备份可读 4,204,032 bytes tar 和当前偏好；安装/启动后 1356 bytes XML 与安装前逐字节一致 |
| 测试收尾 | 原有 1 条自测记录、疼痛记录及所有偏好保持。跳过动作测试产生的唯一今日 doneDays 标记已单独撤回；不是整份恢复备份。浅色及系统动画设置还原；重新启动后偏好再次逐字节等于测试前，SHA-256 `b4ac5a3817155431b4a0b445fd12d8941852ea99fafd86956f0da153a505a5a4` |

新隔离副本位于 C 盘、pub cache 位于 E 盘，常规 Flutter build 遇到 Kotlin incremental cache 不同根错误。最终在同一 SDK 下，直接 Gradle assembleDebug，以临时命令参数 `-Pkotlin.incremental=false -Pkotlin.compiler.execution.strategy=in-process -Ptarget-platform=android-arm64 -Ptarget=lib/main.dart` 构建成功；没有为此修改 gradle.properties 或项目依赖。

## 真机清单结果与边界

| 清单 | 结果 |
|---|---|
| #18 深浅外观覆盖 | 首页开始、自测入口、引导有/没有、顶栏、播放器暂停/继续/跳过、休息反馈、设置试听/语言/外观、底部 Tab 均已查看。无原开始按钮彩色光晕；细高光和贴身暗影可见。F2 分段反馈不合格 |
| #18 持按 / 系统移除动画 | 开始按钮 native 直径 337→327 px（0.9703）；减少动画时 337→337，材质仍改变。普通主/次/小按钮有按压变化。分段例外见 F2；100/180ms、无回弹的时序由组件测试/代码核对，录屏不作为精确帧时测量 |
| #17-1 开始展开 | 深浅均进入训练；原样按钮快照和持按释放首帧像素测试通过；录屏未观察到图标飞行或首帧明显跳色，不据录屏证明每个刷新帧都被捕获 |
| #17-2 准备及视频中关闭 | 准备阶段关闭、浅色首页计划播放中关闭、深色椅边微课播放中关闭均录制并抽帧查看；未见视频区黑块或移出裁剪区。不是 iOS 平台视图验收 |
| #17-3 椅边放松 | 深浅从该行展开，准备态及深色播放态返回正常，未观察到起始行变亮闪块 |
| #17-4 自测入口 | 深浅“开始自测”展开及返回完成；当前已有自测记录，因此未覆盖无记录“我的髋部”磁贴入口 |
| #17-5 右推返回 | 深浅隐私政策及重新看安全提示进入、系统返回已录制，功能正常 |
| #17-6 快速 Tab | 无崩溃；中途反向跳变 F1，未通过 |
| #17-7 新结果页开始训练 | 用户选择保留现有记录，不新增假自测。已有结果影响的首页训练入口可用；现有进度页没有“结果页开始训练”的原生入口，不能代替该上升转场，仍待补验 |
| #17-8 减少动画 | 临时把系统三个动画 scale 设为0并回读；训练/自测/Tab功能正常，开始按钮不再缩放但材质变化。结束后原值完全还原 |
| #17-9 / #18 性能 | 已采集 debug gfxinfo 和设置滚动/播放录屏。设置纯 Flutter 页面 Total frames=0；播放样本 Total270 / Janky3（1.11%）且无可用逐帧序列，不能证明连续卡顿≤2帧，更不能代替 Flutter raster 或低端机结论。性能待补 |
| 实际密度 / 亮环境 | density520 下截图可分辨白按钮边界与顶边高光，没有明显糊成光晕。绘制1逻辑像素在该密度约3.25物理像素，并非1物理像素；强光环境下的实屏辨识度未测，需用户实看 |

公开入库图片仅为合成回归图和不含健康记录的原生局部裁剪。完整截图、录屏、日志、用户备份和 APK 均在上述 Git 忽略的本机证据目录，未上传；不能把文档本机路径写成远端备份。

## 下一步

分别在 #17 / #18 修复 F1 / F2 后，按每问题最多两轮的限制复测，补低端机/有效 Flutter 帧时及强光实看。保护现有自测记录，#17-7 需要可隔离的原生测试数据方案或用户允许新增测试记录。通过后先向用户汇报并等待同意，再按 #17 → #18 合入；不 force push、不上传商店。
