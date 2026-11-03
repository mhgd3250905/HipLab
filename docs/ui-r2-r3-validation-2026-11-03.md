# UI r2–r3：本机验证与真机候选包

2026-11-03：`feat/ui-r2-pages` 已按重写后的远端直接对齐到 `00feee16ea049e636f3c43f900ce7a5902d10363`，没有 pull merge。基于 main `0737e4e` 的四个 UI 提交保留独立历史。本机验证与内部包完成，无额外代码修复；后续提交只保存回执。用户要求真机通过后再合并，目前未连接手机，按既有安排交用户远程安装。

原 [PR #27](https://github.com/mhgd3250905/HipLab/pull/27) 实际已合并，不能再次转 Ready。本轮四个新提交由 [Draft PR #29](https://github.com/mhgd3250905/HipLab/pull/29) 承接，待用户真机反馈后再 Ready / 合并。

## 检查结果

- Flutter **3.44.7** / Dart **3.12.2**；`flutter pub get --enforce-lockfile` 完成，`pubspec.lock` 没有镜像地址或其他变动。
- 四个实际 SDK 依赖及 coach override 继续锁到 `693cbc02cdf284163409868e117e438515c6a8d8`，即 `ugk_trainer-v0.6.0`。
- `flutter analyze --no-pub --fatal-infos`：**0 问题**。
- `flutter test --no-pub --concurrency=2 --reporter=expanded test/hip`：60 文件完整执行，**434 通过 / 0 失败 / 68 条件跳过**，与沙箱一致。跳过项为 67 个 opt-in 截图及 1 个可选语音导出，没有新增跳过。
- 快速代码核对未发现确定的功能回归：混合组计划/播放/完成保存和存储路径未改，组编辑/添加动作/筛选/自测保留业务回调；聊天加载完成直接使用 SDK CoachChatPage，没有额外宿主返回栏。这些检查不代替真机使用结论。

## arm64 内部包

`E:/AII-3D/hiplab-releases/ui-r2-r3-00feee1-20261103/hiplab-1.1.0+30-00feee1-internal-arm64-release.apk`

| 项目 | 实际结果 |
|---|---|
| 测试/构建源 | `00feee16ea049e636f3c43f900ce7a5902d10363` |
| 版本 / versionCode | **1.1.0+30 / 2030**，未递增 |
| 包名 / 架构 | `com.ugk.hiplab` / arm64-v8a，release、非 debuggable |
| 大小 | **49,954,831 bytes（47.64 MiB）** |
| SHA256 | `86d918792e13ff15f736ca160102ba88e8757c94d0362d7ffe4dc9d811908d69` |
| 测试签名 SHA256 | `3761270a4764157f0e389014a9e5b800b05403bfddce0f4f7f8c039f6a53bdc7` |
| 资源 | 211 公共封面、**0 MP4**，动作范围未改 |

构建复用原上传 keystore 配置的本地链接，没有复制密钥；原上传签名包同目录另存。用户内部包沿用此前手机测试证书，签名、ABI、包名/版本、ZIP CRC 及重签前后运行负载一致性均通过。Worker 配置沿用既有文件。测试/构建日志、`test-summary.json`、`release-apk.json`、`source-commit.txt` 和 APK 都在上述仓库外目录，未提交。

## 待用户真机验证

1. 使用同签名覆盖安装，保留现有数据，不卸载、不清数据；核对旧训练组、设置、自测和记录。
2. 混合组（本地动作 + SDK 动作）完整播放到结束，检查顺序、休息及结束记录。
3. 正常字号查看浅色无投影、圆角与细边；走组编辑、添加动作、筛选、自测流程。
4. AI 聊天页确认仅一个返回键。

本轮未安装、未做上述真机验收，未增加大字号或小屏幕适配/专项验证。SDK TrainingLibraryDetails 的胶囊按钮、16 边距及 r24 图片按 SDK 现状保留；未验收 v3 动作仍不进入 App，首启仍不带返回。

main 保持 `0737e4e`，release/1.0 不动、不打 tag、不提交商店。日常 main 目录及原 WIP stash 未操作。构建后仅保存文档，不重复测试或构建。
