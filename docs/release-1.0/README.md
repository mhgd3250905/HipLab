# HipLab 1.0.0 基础版上架交付

2026-10-24，按开哥授权从远端 main `e456d2a1988d0b5a3d238202d52337ef99e6e585` 建立 `release/1.0`。此分支只做上架/审核修复，完成后合回 main，日常功能继续在 main 开发。原目录 `codex/liquid-glass-design` 的未提交改动完整保留，不带入本版。

## 构建合同

| 项目 | 值 |
|---|---|
| applicationId | `com.ugk.hiplab` |
| 共用版本 | `1.0.0+20`（Android versionName 1.0.0 / versionCode 20） |
| Flutter | 3.44.7 stable / Dart 3.12.2 |
| SDK | coach / trainer 均固定完整 commit `d193a703e3a8bef6d41e7705a55ae250e23e6a69`，lock 同步固定 |
| AI | 构建不传 Key 或私有 define 文件；按用户最新决定保留入口，无 Key 使用本地预设回落，不拉远端 catalog，不初始化 AI 安装标识 |
| 签名 | 沿用既有上传密钥；缺少 `android/key.properties` 时拒绝 release 构建，禁止静默 debug 签名 |
| 证书 SHA-256 | `8f8c114e8e1f8650d3e461abaf2a1c719e11ab390bb0ba285c87bb072433b7ad` |
| Android FGS | `com.ugk.trainer.TrainingSessionService` / `mediaPlayback`，非导出，随任务结束清理 |

密钥与密码位于仓库外；已复制到 F 盘受限备份目录并核对 keystore SHA-256。F 盘副本仍在本机，开哥需另做异机或离线保管。公开证书可以交给平台，keystore 和密码不可放进仓库或物料包。

## 重建

在干净的 `release/1.0` 副本恢复冻结素材，准备本机 `android/key.properties` 后运行：

```powershell
flutter pub get
flutter analyze --no-pub
flutter test --no-pub
flutter build appbundle --release --no-pub
```

不使用 `--dart-define-from-file` 或任何 AI Key。APK 仅用于相应平台本机验证，上传制品是 AAB。AAB、构建日志、公开证书、静态清单/签名/16KB检查和截图放在 `E:/AII-3D/hiplab-releases/1.0.0+20/`，不提交 Git。最终大小、SHA-256、实际编译源 SHA 和检查结果见交付目录的 `release-identity.json` 与[验证台账](../verification.md)。后续只修文档的分支 HEAD 可以晚于实际编译源 SHA。

## Mac 接手

从 `origin/release/1.0` 开 `ios/…` 分支，使用 Flutter 3.44.7 stable 和共用 `1.0.0+20`，不升级 SDK、依赖或素材。按[文档入口](../README.md)用冻结 lock 的 `--from-dir` / `--check` 恢复素材。iOS 构建同样不传 AI Key；修改限 `ios/` 和必要平台代码，通过 PR 返回 `release/1.0`。此 Windows 交付不等于 iOS 已构建或已验证。

## 可审阅物料

- [中文商店文案](listing-zh-CN.md)与[英文商店文案](listing-en-US.md)。英文是商店本地化，App 界面目前为中文，语音有中英文选择。
- [隐私政策正文草稿](privacy-policy.md)，开发者与邮箱沿用此前已授权信息。
- [前台服务、数据安全、健康及权限声明答案](play-declarations.md)，含演示脚本。
- [正式图标、截图与展示图来源清单](materials.md)。

2026-10-24 用户表示“App我已经都测试通过了”，登记为现有 App 的用户验收反馈。该反馈未附测试安装的版本/哈希或逐项耳机锁屏日志，不据此声称本轮新 AAB 已通过同包真机验收。历史 D-34 小米锁屏冻结保留原记录；本轮截图和本机检查各自写明来源。

Play 前台服务声明要求可访问的真实演示视频链接，脚本不能代替视频。开哥负责录制/提供链接并在 Play 填写。所有 Console 操作、AAB 上传、送审与发布均由开哥执行，本轮未操作后台。历史 0.2.0+4 Alpha 记录继续保留，当前审核和分发状态由开哥核对。
