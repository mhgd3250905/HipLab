# 版本管理说明

## 事实来源

| 事实 | 维护位置 |
| --- | --- |
| App 共用源码版本 | [pubspec.yaml](../pubspec.yaml) 的 `version` |
| SDK 引用和实际解析版本 | [pubspec.yaml](../pubspec.yaml) 的 Git 引用与 override，[pubspec.lock](../pubspec.lock) 的 `ref`、`resolved-ref` 和版本 |
| 当前主线、设备、渠道和观察日期 | [当前状态](current-state.md) |
| 构建、安装、商店回执 | [版本交付台账](version-ledger.md) |
| 检查结果、执行环境和源码身份 | [验证台账](verification.md) |
| 待验收事项和完成项 | [开发事项](development-roadmap.md) |
| 决策和关键成果 | [开发日志](development-log.md) |
| 分支、工作副本与操作步骤 | [开发工作流](development-workflow.md)和[协作约定](../AGENTS.md) |

## 版本与来源身份

- 共用版本写成 `版本名+构建号`，由 Windows 维护。Android 商店 AAB 以共用构建号为基础，自用 arm64 split APK 使用 Flutter 的 ABI 版本码。iOS 按目标源码和归档结果登记版本与 build。各渠道采用包清单或控制台的实际回读。
- 构建源码、PR 集成点与后续文档提交分别记 SHA。引用已有验证时核对原始源码及其到当前 HEAD 的差异。仅文档变更沿用原构建身份，校验事实、链接和 Git 差异即可。
- App 版本、Pose SDK 和动作目录独立登记。当前 main 的 SDK 固定 `4eb87ceabd39bfd132cd6c79c0474de3be683feb`（0.9.0）。HipLab 随包的 `r2-v11` 目录 SHA-256 为 `6f46c0a3fc0b6546193e2e3d867d90add55ce21bf0b8f3c482edaa507cdcabc0`。Android +71 取得的 stable 目录与真实设备验收见[本轮验证](verification.md#2026-11-16-android-sdk-基准-71)。

## 交付如何登记

1. 确认 Git 基线、完整工作区状态、固定依赖及授权渠道。两端使用 Flutter **3.44.7 stable / Dart 3.12.2**。
2. 构建时记录版本、完整源码 SHA、构建类型和架构、包名、产物路径、SHA-256 及签名。覆盖安装保留用户数据，记录实际安装包版本与回执。
3. 分别记录已构建、已安装、用户或自动化验收、Git 合并与推送。商店分别记轨道、送审、审核、发布的版本与观测时间。权限申请也单独登记。
4. 回读远端分支或渠道状态，再更新对应台账及[当前状态](current-state.md)。构建文件、设备数据和签名材料使用本机约定位置，Git 记录保留来源和证据。

早期版本快照与当时规则见[历史记录](https://github.com/mhgd3250905/HipLab/blob/ba0d0c16ae56d7b679572be3a380969f0679b2dd/docs/version-management.md)。
