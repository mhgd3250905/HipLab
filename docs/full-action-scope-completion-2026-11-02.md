# 全动作 +29 交付（2026-11-02，17:14 范围更正）

已按用户最终决定开放 **211 个可浏览 / 211 个可由 Coach 组计划** 的完整公共动作；两者共用 `lib/hip/data/hip_action_scope.dart` 的同一配置。8 个不完整动作不开放，对应封面已移除；之前的 219 浏览方案和等待 SDK 修改的条件作废，历史过程见[预检报告](full-action-scope-2026-11-02.md)。

## 源码与实现

分支 `codex/full-action-scope`，测试/构建源码 **`5072cbb291fe099fbbbd8e673a326e47e21808e8`**，基于已合 +28 的 main `d0c28c59976e32d58e4999b524bb40c60ee3672a`。本次仅普通推送分支，不合 main、不打 tag、不动 release、托管、Flare 或商店。

SDK 实际四包 `ugk_coach`、`ugk_coach_ui`、`ugk_trainer_runtime`、`ugk_coach_chat` 及 coach override 保持完整 pin **`d4502f35b1503d41cd782aa7fb3780c7f6591ad0`**；依赖中无独立 `ugk_trainer`，没有改 SDK 或缓存源码。Flutter **3.44.7 / Dart 3.12.2**，锁文件未升级。

公共 catalog 经 SDK 校验并投影为 211 条；剂量、范围、安全与器械信息沿用原定义，执行使用 SDK 已有节奏，未知节奏不从视频循环推断。App 仅作宿主数据适配：新动作可以保存、恢复、显示封面并交 SDK 播放，不再要求旧 46 个 action kit；没有为新动作编造髋部方向。含非髋部动作的训练使用 SDK 原生不适处理。原有自测题目、计分、课程和剂量保持；release 无密钥 Worker 与非中文/iOS 隐藏 AI 的规则保持。

211 动作清单 SHA256：`2f95a37a379458fbedbbaa6c4940f658d72c75476fd1b4c85b4a65850ee393b9`。全部开放动作媒体描述齐全，缺失排除清单为空；仅排除[8 个不完整定义](full-action-scope-2026-11-02.md#需要-sdk-补齐的-8-个动作)，不补写其元数据。封面共 **5,591,176 bytes**，逐项大小/SHA256 匹配固定 SDK；视频仍由公共 mediaPolicy 按需下载。

## 门禁

| 检查 | 结果 |
|---|---|
| `flutter pub get --offline --enforce-lockfile` | 通过，依赖保持 |
| `flutter analyze --no-pub --fatal-infos` | **0 问题** |
| `flutter test --no-pub --concurrency=1 --reporter expanded` | **437 通过 / 1 既有条件跳过**，5分51秒 |
| `python -m unittest discover -s tools/tests -v` | **25/25 通过** |
| APK 身份、签名、CRC、重签前后运行负载一致性 | 通过；**211 公共封面 / 0 MP4** |

新增/更新测试覆盖 Library/Coach 与 SDK 完整动作集合均为 211、胸部等新动作准入、全部 211 个动作的原剂量单练/存储恢复/执行、8 个 partial 拒绝、非髋部 SDK 播放入口和保存计划封面、自测与旧课程数据保持。本轮没有新增跳过或删除测试；既有条件跳过是可选 `VOICE_TIMELINE_OUT` 导出。一次全量在补齐保存计划封面显示时主动中止，最终以上述完整成功运行作准。

## APK 与工作区

- **用户安装包：** `E:/AII-3D/hiplab-releases/full-action-scope-20261102/completion-1714/hiplab-1.1.0+29-full-action-scope-arm64-device-release.apk`
- **大小：49,954,831 bytes（47.64 MiB）**；`com.ugk.hiplab`、release、arm64、versionName `1.1.0`、**versionCode `2029`**。
- APK SHA256：`186a2c1ff2bb1ffa4dff41d75ec26671a13e02cf892be5080969cfe032f584a0`。
- 连续测试证书 SHA256：`3761270a4764157f0e389014a9e5b800b05403bfddce0f4f7f8c039f6a53bdc7`。原上传签名包同目录另存，未提交商店；密钥没有复制。

在带原签名配置的日常目录按已测试提交 detached 构建，再重签为既有设备测试证书。日常目录已恢复 `codex/liquid-glass-design@71decd211969ca807142520111f7bdf999767651`；40 个 WIP 文件的字节哈希、Git 状态及原有生成依赖配置均与构建前一致，备份 stash 保留。`release-apk.json`、`daily-restored.json` 和门禁/构建日志保存在上述产物目录，不在 Git 中。APK 未安装，本轮真实操作与视觉确认交用户安装后自测；没有执行 ADB。
