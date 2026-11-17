# iOS 运行与上架说明

## 工程身份

- Runner 使用 `com.ugk.hipinterlude`，对应 App Store Connect 的 Hip Interlude / HipLab 记录。最低 iOS 15.0。[Xcode 工程](../ios/Runner.xcodeproj/project.pbxproj)
- `CFBundleShortVersionString` 与 `CFBundleVersion` 取 Flutter 的构建变量，源自 [pubspec.yaml](../pubspec.yaml)。Windows 维护共用版本，Mac 从核对后的基线执行 iOS 工作。[版本管理](version-management.md)
- iOS 独立候选、TestFlight 与 App Review 对应不同记录。本轮候选和历史送审源码见[当前状态](current-state.md)，实际上传和渠道回执见[版本台账](version-ledger.md)。

## 在 Mac 上跑起来

1. 核对分支、构建源码和 Bundle ID，按[新机器准备](README.md#新机器拉素材mac--windows)恢复锁定依赖和素材。
2. 运行 `python3 tools/ios/check_ios_project.py`，按构建范围执行 Flutter 与真机检查。下载依赖后可用 `flutter run -d <device-id>` 走本机控制台。
3. 在 Xcode 核对 Runner 签名团队。归档可按目标配置使用 `flutter build ipa --release`。权限、隐私和商店声明以实际构建、已批准材料及对应版本的后台记录为准。[基础版历史发布材料](release-1.0/ios/README.md)
4. 将构建、实际安装、TestFlight、App Review 和公开发布逐项记入[版本台账](version-ledger.md)。原生播放、听感、后台与系统中断的未验范围记入[验证台账](verification.md)。

早期的工程说明、旧 Bundle ID 和验收矩阵可查[历史快照](https://github.com/mhgd3250905/HipLab/blob/ba0d0c16ae56d7b679572be3a380969f0679b2dd/docs/ios-setup-and-release.md)。
