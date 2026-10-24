# SDK 套路卡补丁与 main 集成

用户确认三个修复 tag 已推送，要求在候选 `5c4d32e24f664186aa811044f585069a525d5465` 上改锁、从远端重新 pub get、分析和测试；通过后直接合入 main 并推送，`release/1.0` 不动。本轮不需要再次请求合并同意。

## 依赖与改动边界

| 包 | 正式 tag | 远端及 lock resolved-ref |
|---|---|---|
| ugk_coach 0.4.2 | ugk_coach-v0.4.2 | 3302d6235a39e2c2b4b51fa196cc32b37c31b54c |
| ugk_trainer 0.2.2 | ugk_trainer-v0.2.2 | 3302d6235a39e2c2b4b51fa196cc32b37c31b54c |
| ugk_coach_ui 0.1.1 | ugk_coach_ui-v0.1.1 | 3302d6235a39e2c2b4b51fa196cc32b37c31b54c |

远端 tag 用 `git ls-remote --tags` 核验，随后正常在线执行 Flutter `pub get`；package_config 也指向 Pub Git 缓存中的同一完整 SHA。没有本地 path、main 引用或 dependency override，SDK 仓库源码未改。

本轮 App 只改三个依赖 ref、对应 lock 和文档；`lib/`、`android/`、`ios/`、资源、测试文件及版本号相对候选均未改。版本保持 `1.1.0+21`。其余 hosted 依赖逐项对比候选，版本及校验值保持不变。

SDK 的 coach 运行代码相对88da65a相同，trainer 引擎、原生服务和资源相对f0ea064相同。UI 仅修改私有套路卡布局：按父约束、字体及 TextScaler 量测名称和剂量，窄屏大字体时换行或上下排列并增加行高，同时同步展开/收起的媒体动画位置；公开 CoachPlanCard、DTO 与 CoachUiTheme 接口未改，HipLab 无需源码适配。

## 工具与验证

本机默认 `E:/flutter` 已由其它工作切为3.47.8，第一次解析带入了5项无关依赖更新，未提交；随后恢复候选的 hosted 锁定，并在 E 盘独立工作副本 `E:/DevCaches/flutter-3.44.7-hiplab` 使用官方3.44.7 tag（84fc5cbb223bc12f83d65b647ff8a56caf779ffd / Dart3.12.2）重新在线 pub get。没有切换或重置机器默认 Flutter，也未修改其现有工作副本。

- `E:/DevCaches/flutter-3.44.7-hiplab/bin/flutter.bat analyze --no-pub`：0 issues。
- 从 App 项目直接执行远端 tag 的 `packages/ugk_coach_ui/test/plan_card_overflow_test.dart`：13通过；含320px/2倍字体、深浅色、长中文/循环/多段剂量、实际父宽度、动画往返、RTL和减少动画，390px/1倍的常规行高也通过。测试源码未复制到 App 或修改。
- App 全量测试：**451通过 / 1条件跳过，5分58秒**，本轮完整执行、无失败；条件跳过仅为未设置VOICE_TIMELINE_OUT的时间线导出。

按用户要求，不重复已验过的真机流程：App 无源码适配，coach/trainer运行实现未变。沿用[原生验收](sdk-shared-ui-2026-10-24.md)的训练、保存、数据保持、服务/通知释放和用户语音确认；这不是3302d62的新原生安装记录。本轮未重建或安装APK、不操作手机或模拟器；既有APK仍保持原编译身份。

日志位于 `E:/AII-3D/hiplab-releases/sdk-shared-ui-20261024/sdk-0.4.2-0.2.2-0.1.1/`。本轮开始时远端 main 和 release/1.0 均为 `8880c71645163809b18c1829247c83e79bb99842`；main 集成和推送后追加实际回执，release 分支不接纳本轮改动。
