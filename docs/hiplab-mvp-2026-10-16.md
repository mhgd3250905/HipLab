# HipLab · 开胯训练助手 MVP 骨架（2026-10-16）

> **历史文档（2026-10-17 起）**：本文写于 HipLab 还是 3D-Body 里的 hip 变体时（3D-Body PR #118）。拆到本仓库后：入口是 `lib/main.dart`（原 `main_hip.dart`），Android/iOS 包名固定为 `com.ugk.hiplab`，不再有按入口切换的 Gradle 逻辑；共享部件改为复制在 `lib/core/`（清单见仓库 README）；字体族改名 `NotoSansSC`；不再用 `AppLocalizations`。下文第 1 节的变体说明只作背景参考，其余（内容包、自测计分、训练规划、疼痛降级）仍然有效。

方案 A：在本 Flutter 工程里加第二个 App 变体。FlareLab（托马斯）的入口、包名、构建命令、资源和测试都不变。

## 1. 变体怎么切换（"flavor"）

| | FlareLab（原样） | HipLab（新增） |
|---|---|---|
| Dart 入口 | `lib/main.dart` | `lib/main_hip.dart` |
| Android 包名 | `dev.mhgd.flare` | `com.ugk.hiplab` |
| App 名 | Flare 托马斯 | 开胯训练助手 |
| 图标 | `@mipmap/ic_launcher` | `@mipmap/ic_launcher_hip`（占位） |
| 主题 | 原主题 | 石墨底 + 青玉 `#3ccfa4`，只做深色 |

```bash
# FlareLab：命令完全不变
flutter run
flutter build apk --release

# HipLab
flutter run -t lib/main_hip.dart
flutter build apk --release -t lib/main_hip.dart        # → com.ugk.hiplab
flutter build appbundle --release -t lib/main_hip.dart
# 只能传 dart-define 的工具链也可以：--dart-define=APP_VARIANT=hip（仍需 -t lib/main_hip.dart 才会跑 HipLab 的 Dart 代码）
```

**为什么没用 Gradle `productFlavors`**：一旦声明 productFlavors，`flutter build apk` 不带 `--flavor` 会直接报错，FlareLab 现有的构建命令和脚本都得改；而 pubspec 的 `default-flavor` 会让 iOS（目前没有自定义 scheme）报"不能用 --flavor"。所以改为在 `android/app/build.gradle.kts` 里读取 Flutter 传给 Gradle 的 `target` / `dart-defines` 属性：目标是 `lib/main_hip.dart`（或 `APP_VARIANT=hip`）时切换 applicationId、`appLabel`、`appIcon` 两个 manifest 占位符，否则一切和原来一样。

**iOS**：本 PR 没改 Xcode 工程（沙箱里无法用 Xcode 验证 pbxproj/scheme）。`flutter run -t lib/main_hip.dart` 在 iOS 上能跑 HipLab 界面，但 bundle id 仍是 FlareLab 的，**不能用来上架**。上架前要在 Mac 上补：新建 `Hip` scheme + `Debug-Hip/Release-Hip` 配置、`PRODUCT_BUNDLE_IDENTIFIER=com.ugk.hiplab`、`CFBundleDisplayName=开胯训练助手`、独立 AppIcon。

**Web**：`flutter build web -t lib/main_hip.dart` 可用，`web/index.html` 标题仍是 Flare。

## 2. 目录

```
lib/main_hip.dart                 入口
lib/hip/domain/                   纯规则，无 Flutter 依赖，全部单测
  hip_models.dart                 方向/练法/场景/动作/成套/自测定义 + JSON 解析
  hip_assessment.dart             自测计分：左右取低、加权、雷达映射、总分→档位、疼/跳过、推荐、舞者解锁
  hip_session.dart                今日训练：按时长/场景选套、L1 换替代、进阶护栏、疼痛锁定、左右不一样多一组
  hip_pain.dart                   疼痛阶梯（缩小幅度→换动作→跳过方向→结束）+ 7 天内 2 次跳过锁 7 天
  hip_progress.dart               连续天数、近 7 天、久坐提醒时间表 + ReminderScheduler 接口
lib/hip/data/hip_content_loader.dart
lib/hip/control/hip_store.dart    本地持久化（SharedPreferences 单 key `hiplab.state.v1`）
lib/hip/ui/                       安全图卡/身份 → 首页 → 自测 → 结果 → 跟练播放器 → 进度/设置
assets/hip/hip-content.json       内容包（脚本生成）
assets/hip/posters/, assessment/  原型渲染静帧（drill-anim 方案 B，540px webp，共 ~80KB）
tools/hip_content/                生成脚本 + 第 0 阶段源文件（csv / md）
android/app/src/main/res/mipmap-*/ic_launcher_hip.png
```

复用的共享部件：`LocalStateStorage`、`DrillMedia` 清单与 `DrillMediaPlatformView`（播放仓库已有的成片）、FlareSans 字体、`AppLocalizations`（只为让共享组件取到文案）。HipLab 不加载 3D 场景/WebView 场景。

## 3. 内容包

`python3 tools/hip_content/build_hip_content.py` 从 `tools/hip_content/source/` 生成：

- 45 个 MVP 动作（30 复用 + 15 新增 P0）+ 1 个被成套训练引用的备选替代（`w-feet-on-chair-bridge`）。
- 6 个方向；6 套成套训练 + 套 M（久坐 2 分钟），时长与文档一致（5/8/6/10/7/12/2 分钟）。
- 6 项自测定义、权重、雷达映射 0→25 / 1→60 / 2→90、档位 0–5 / 6–9 / 10–12、并列优先级、身份×最低方向的推荐。
- 媒体状态：`video` 2 个（`glute-max-A`、`hip-flexors-A`，用 App 已有成片）、`poster` 9 个（原型静帧）、其余 34 个 `pending`，界面显示"动画待渲染"占位。自测对比图只有蝴蝶式 3 张（原型静帧，占位），其余 17 张显示"对比图待渲染"。

## 4. 本 PR 里定下的小决策（可改）

1. 对比图从左到右按原型 `紧 · 一般 · 松` 排（自测设计.md 写的是 A 松在左；计分只看选项，不看位置）。
2. 推荐路线 → MVP 预置成套：上班族/都不是：伸→D、屈→E、外展→B、外旋→B、内旋→D、内收→A；舞者：全部→F（路线名按文档区分"先补髋前侧/压缩/分腿"）。
3. 疼的方向不参与"最低方向"，推荐从其余方向里选；全部都疼则不推荐。
4. 90/90 选"紧"但没答追问时，前后腿都按 0 计（保守）。
5. 15 分钟没有对应的套：主套 + 一套补足剩余时长（不重复动作）；办公椅 10/15 分钟 = 套 A + 套 M。非舞者不会被分到 F 套，除非推荐就是 F。
6. 未做自测按 L1 入门出训练（进阶动作换替代）。
7. 训练中途关闭，只要完成了 ≥1 个动作就算当天练过（连续天数）。
8. 疼痛"缩小幅度"在播放器里实现为：当前动作重来、时长减半、字幕"幅度小一点，别勉强"（动画幅度减半需要渲染素材，二期）。
9. 久坐提醒：MVP 不引入 `flutter_local_notifications`（会改 FlareLab 的 Android 构建：desugaring、权限），只做设置开关 + 45/60 分钟 + 工作日 9–18 点时间表 + `ReminderScheduler` 接口；界面写明"接入通知组件后生效"，并提供"2 分钟椅边放松"入口。
10. 二期再做：语音口令、每周复测对比、照片对比、8 周路线。

## 5. 验证

- `flutter analyze`：No issues found。
- `flutter test test/hip`：26 项通过（计分/推荐/今日训练/疼痛阶梯/连续天数/提醒/持久化 + 6 个界面流程）。
- FlareLab 原测试：与 master 同环境对比，失败集合完全相同（`flow_regressions` 3 条、`polish_round2` 1 条、`ios_layout` 横屏 8 条在本沙箱 master 上也失败），无新增。
- 截图：`flutter test --no-pub test_screens/hip_shots_test.dart` → `test/_shots/hip/`（不提交），与 phase0 原型 4 屏对照。
- 未在沙箱执行 Gradle/Xcode 构建（按约定不打包）；`build.gradle.kts` 的变体切换需在本机 `flutter build apk -t lib/main_hip.dart` 验一次。
