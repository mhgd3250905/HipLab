# iOS 0.3.3+8 本地构建与真机验证（2026-10-18）

截至北京时间 2026-10-18 10:33，**Flutter Release 与 Xcode Archive 通过；真机连接准备失败，尚未安装本次构建，11 项真机验收均未完成**。本轮未上传 TestFlight / App Store，未操作旧版本审核或商店配置。

## 基线与边界

- 分支 `ios/device-validation`，从已 fetch 的 `origin/main` / `bb828be30a6d3631538fc732154c5985c44ef2f8` 建立独立 worktree；不切换或覆盖原目录的已有改动。
- 固定 0.3.3+8 / `com.ugk.hiplab`。没有修改业务代码、iOS 工程配置、版本、依赖、lock 或素材；Team 通过 Git 忽略目录内的私有 xcconfig 注入，没有入库。
- Flutter 3.44.7（HEAD 与官方 3.44.7 tag 一致，SDK 工作树干净）、Dart 3.12.2；Xcode 26.6 / iOS SDK 26.5。Flutter 本地 channel 显示 user-branch，但未升级或改动 SDK。
- 使用 Swift Package Manager；没有新建工程、生成 Podfile 或运行 CocoaPods。
- 当前已存在冻结素材，直接 `pose_hub_sync.py --check` 得到 92 matched / 0 drift，没有重新下载 ZIP 或重做素材；不据此声称本次校验了 ZIP 哈希。

交接中“从未构建/上真机”是历史信息滞后。此前 Mac 已完成 0.1.2+3 的 iPhone 基本运行；另一次 0.3.2+7 于 2026-10-18 09:43 提交正式审核，当时回读“等待审核”，用户反馈 TestFlight 下载测试通过。该历史在独立 [PR #12](https://github.com/mhgd3250905/HipLab/pull/12) 的 `ios-store-release-2026-10-18.md` 记录；本分支没有合并该 PR，也未重新查询 Apple 状态。旧反馈不覆盖 #13/#14 后的 0.3.3+8。

## 本地验证

| 检查 | 实际结果 |
|---|---|
| `flutter pub get --enforce-lockfile` | 通过，锁文件无变化 |
| `flutter analyze --no-pub` | 无问题 |
| `flutter test --no-pub --concurrency=1 --reporter expanded` | 156 通过，1 项按设计跳过（未设置 VOICE_TIMELINE_OUT） |
| `python3 tools/ios/check_ios_project.py` | OK |
| `python3 tools/pose_hub_sync.py --lock pose-hub.lock.json --check` | 92 up to date / 0 downloaded / 0 drifted |
| `flutter build ios --release --no-pub` | 成功，58.1 秒；已有开发签名 |
| `xcodebuild -workspace ios/Runner.xcworkspace -scheme Runner -configuration Release -destination generic/platform=iOS -archivePath … archive` | ARCHIVE SUCCEEDED，46.1 秒；本地开发签名，没有导出分发 IPA |
| App / Archive 验包 | `codesign --verify --deep --strict` 通过；Bundle、0.3.3 / 8、arm64 一致；6 份隐私清单均可解析 |

开发签名的 `get-task-allow=true` 是本次真机调试用途，**本归档不是经过分发导出验包的 App Store 候选**。没有上传授权，不进行 IPA 导出或上传。

本机工作目录 `/Users/shengkai/ugk-hiplab-ios-device-validation`，日志、私有签名覆盖文件、验包 JSON 和 Archive 均留 Git 忽略目录 `build/ios-device-validation/`；Flutter App 为 `build/ios/iphoneos/Runner.app`，Archive 为 `build/ios-device-validation/HipLab-0.3.3+8.xcarchive`。Archive 共 248,539,390 bytes，主可执行文件 SHA-256 `1c5a20ff93aab147986b681701545fc82e665e507d50c353615ca208b64c89c0`，此哈希不是 IPA 哈希。产物只保存在本机，不代表已远端备份。

## 真机阻塞

目标设备 iPhone 16 Pro / iOS 26.5。iPhone 镜像可以连接，但 Xcode Devices 显示 CoreDevice 设备准备错误；`devicectl` 分别使用设备列表标识与硬件 UDID 均返回 CoreDeviceError 1011（找不到设备）。两种方式没有进展后停止该路径，已请用户拔插数据线、解锁并处理信任提示，等待实际连接状态改变。

本次未执行 `flutter run --release` 或安装；未卸载 App、未清用户数据，安装前偏好读取也因连接错误未成功，不能声称已备份或校验保留数据。设备标识、原始日志和个人资料不入 Git。

## 11 项真机清单

| 项目 | 0.3.3+8 结果与待做 |
|---|---|
| 1. 安装与外观 | 未执行；图标、中英名称、冷启动、深浅启动页及反向主题切换待查 |
| 2. 安全区 | 未执行；16 Pro 真机待查，15 Pro / SE 真机未提供，不能用 widget 截图替代 |
| 3. 视频首帧 | 未执行；青蛙式、90/90、90/90 抬脚、四足画圈的首帧/循环、深浅主题与原生按钮/灰底/白框待查 |
| 4. 后台语音 | 未执行；整套训练、第二句后长句、准备→三二一→开始、锁屏 3 分钟及计时/示范恢复待查 |
| 5. Ducking | 未执行；音乐按句压低、约 0.7 秒恢复、无截断及训练结束恢复待查 |
| 6. 静音键 | 未执行；静音仍播语音、媒体音量调节待查 |
| 7. 系统中断 | 未执行；来电 / FaceTime / Siri / 闹钟的静默暂停及手动继续待查 |
| 8. 耳机断开 | 未执行；暂停、无突然外放、重连后继续待查 |
| 9. 常亮 | 未执行；训练/自测 2 分钟以上及离开恢复待查 |
| 10. 自测后台 | 未执行；锁屏/后台后倒计时具体表现、5–6 秒指导完整性待查（D-13） |
| 11. 后台音频审核风险 | 保留静音循环保活的既有设计；本次没有运行或新的 Apple 审核结论，不标通过 |

#13 额外复听：中英文音量、句尾与失真，英文 `sec.5`、`a.item.deep_squat`、`drill.h-reverse-clam`。#14 额外观感：开始展开、缩略图 Hero、右滑跟手/回弹、分段触觉、浅色阴影、33ms 倒计时环。均待真实设备安装后完成，不以假平台测试替代。

## 交付与下一步

本阶段仅文档记录，无生产代码修复；不需要重复运行 Flutter 检查或增加版本。设备恢复后先核对精确安装版本并保留数据覆盖安装，再补上述矩阵、截图/录屏与可听证据。系统开关、耳机、来电和实际听感若无法通过镜像完成，需要用户协助，未经观察的项目保持未验收。Windows 负责审查/合并，本分支不合并 main 或他人 PR。

文档提交 `668616f` 已推送 `origin/ios/device-validation`，已创建 [PR #15](https://github.com/mhgd3250905/HipLab/pull/15)，回读为 OPEN / Draft、目标 main；未合并。后续仅补记录的提交不改变构建源码 `bb828be`。
