# 当前状态

核对日期：2026-10-17，北京时间。此页维护当前事实；过程见[开发日志](development-log.md)，检查范围见[验证台账](verification.md)。

## App 与设备

| 项目 | 当前状态 |
|---|---|
| 产品 / 包名 | 开胯训练助手 HipLab / `com.ugk.hiplab` |
| Android 已安装版本 | **0.1.2+3**，debug 签名，2026-10-17 14:37 保留数据覆盖安装 |
| 已安装代码提交 | `4cf5ca7990949d025e02f13fc83e468f8bab9d07`；后续文档/设计状态提交不改变该安装基线 |
| 正式 Android 图标 | 已选 B 站姿开髋，青玉绿/石墨底；普通、圆形、自适应及单色资源，已查看手机桌面确认彩色图标 |
| 验证设备 | 2602BRT18C，Android 16 / API 36，arm64 |
| 产品范围 | 中文、离线、深色；Android 已运行，iOS 尚未构建与实机验证 |
| 动作素材 | 46 项动作全视频（45 MVP + 1 备选），另有 1 条专用自测剪辑，共 47 对视频/封面，均为 1080 |
| 自测素材 | 6 项自测均解析为视频；20 张评分静图保持原样，并未升级为 1080 |
| 运行验证 | 构建、覆盖安装、冷启动和一条原生 WebView 视频播放通过；数据文件逐字节保持 |

当前 App 使用从透明母帧直接合成的 `#101013` 深色视频，1080×1080 / 真实 30 fps / H.264 yuv420p / CRF18。绿幕与透明母帧已保留，浅色主题和运行时透明视频尚未实现。46 条通过原 QA，不等于逐条完成手机端人工体验验收；坐姿体前屈 r3 保留 63 条历史腕部可达范围警告，详见[验证台账](verification.md)。

## Git 与主线集成

**`mhgd3250905/HipLab` 是 HipLab App 主仓库，`main` 是后续开发基线。** 接手成果通过 #2、#1 合入 main，本机 main 跟踪 origin/main。图标版本 0.1.2+3 的代码提交为 `4cf5ca7`，通过 [PR #5](https://github.com/mhgd3250905/HipLab/pull/5) 集成；业务逻辑和视频资源保持，安装状态独立记录。

| 对象 | 2026-10-17 核对结果 |
|---|---|
| HipLab `main` | 已包含 App、高清素材与台账；首次业务集成提交 `656ee28daf1a0335f28c28fd2ac802e8dd20b6b7`，后续文档提交继续在其上集成 |
| [HipLab #1](https://github.com/mhgd3250905/HipLab/pull/1) | MERGED，`feat/initial-migration` → `main`，2026-10-17 13:59:40，merge `656ee28` |
| [HipLab #2](https://github.com/mhgd3250905/HipLab/pull/2) | MERGED，`codex/project-takeover` → `feat/initial-migration`，2026-10-17 13:59:14，merge `e52b3c2` |
| [HipLab #5](https://github.com/mhgd3250905/HipLab/pull/5) | 0.1.2+3 站姿开髋图标与安卓实机交付；已安装代码 `4cf5ca7`，具体合并 SHA 回读 GitHub |
| [3D-Body #119](https://github.com/mhgd3250905/3D-Body/pull/119) | 已合并，2026-10-17 10:29，merge `ae81d96f271a18129abbf6afc7064cfd9dd1d8c3` |
| [3D-Body #120](https://github.com/mhgd3250905/3D-Body/pull/120) | OPEN / draft，制作工具与修订规格 → `master`，源 `f8b5138` |

本地原先只抓取 `feat/initial-migration`，现已改为抓取所有远端分支。合并前后核验源 SHA、目标 SHA 和完整文件树，main 集成结果与已审核版本一致；原接手分支保留。细节见[主线集成审核](mainline-integration-2026-10-17.md)，日常更新见[工作流](development-workflow.md)。PR 状态是上述日期快照，操作前回读 GitHub。

## 本机环境和素材位置

| 位置 | 用途 |
|---|---|
| `E:\AII-3D\3D-Hip` | Flutter App、内容源、交付视频、开发台账 |
| `E:\AII-3D\3D-Body` | 既有源工程与输出，原工作区未提交文件未动 |
| `E:\AII-3D\3D-Body-worktrees\hiplab-hd-20261017` | 独立制作副本，`codex/hiplab-hd-20261017`，工具代码 `f8b5138fb377ec8cda464cfb08186fd696ca7921` |
| `E:\AII-3D\3D-Body\output\hiplab-delivery-20261017\selected-masters-46.json` | 最终 46 项母版选版清单 |
| `E:\AII-3D\3D-Body\output\hiplab-android-20261017-v2` | 当前 Android 派生片、来源与 SHA 核验 |

实际验收工具链为 Flutter **3.44.7** / Dart **3.12.2**、Android SDK 36、JBR 17；原迁移 PR 声明 Flutter 3.47.7，两者不能混为已统一的团队版本。本机 `pub get` 会改变 7 项 SDK 关联传递依赖；验收后已恢复原锁文件，没有提交降级。现有解析缓存可使用 `--no-pub`，新环境先明确 SDK 并审阅锁文件变化。

路径：Flutter `E:\flutter`，Android SDK `E:\Android\SDK`，ADB `E:\platform-tools\adb.exe`，FFmpeg `D:\ffmpeg-master-latest-win64-gpl\bin`。实际渲染为 **RTX 4080 Laptop GPU 12 GB / ANGLE D3D11**。绿幕、透明帧和大批次输出位于本机忽略目录，未由 Git 备份；制作副本和输出仍需保留。

## 当前限制

已确认的紧侧加练计时分配缺陷尚未修复；系统通知、iOS 图标、正式发布签名、iOS 验证和 CI 尚未完成。Android 彩色图标已实机验证，单色图层未做手机主题切换验证。完整事项和验收要求统一维护在[开发事项台账](development-roadmap.md)，不继续把已完成的缺片或 Android 占位图标作为当前待办。
