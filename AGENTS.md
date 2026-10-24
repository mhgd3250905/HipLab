# HipLab 协作约定

## 2026-10-24 SDK 补丁与直接集成授权

用户已确认 `ugk_coach-v0.4.2`、`ugk_trainer-v0.2.2`、`ugk_coach_ui-v0.1.1`（均3302d62）已推送，并明确授权在候选5c4d32e上改锁、远端pub get、分析和测试通过后直接合入并推送main，无需再请求合并同意。release/1.0不动；若无需App源码适配，沿用已有真机验收，不重做。共用版本保持1.1.0+21。固定Flutter仍3.44.7；本机默认工具已升级，当前可显式使用E:/DevCaches/flutter-3.44.7-hiplab/bin/flutter.bat，避免无关框架及hosted依赖升级。[本轮回执](docs/sdk-tag-patch-2026-10-24.md)。

## 2026-10-24 main 后续 SDK 共用界面接入

本轮用户要求从最新 main 建分支接入正式 tags `ugk_coach-v0.4.1`、`ugk_trainer-v0.2.1`、`ugk_coach_ui-v0.1.0`，不改 SDK、不复制 SmartFit。无 Key 时全部 AI 入口隐藏，覆盖下文基础版“保留现有 AI 入口”的历史决定。此要求仅作用于本轮开发分支；`release/1.0` 不动。测试、编译和训练链路验证完成后，仍须开哥同意才合入 main 并推送，覆盖本轮自动合 main 的一般授权。用户随后明确可以使用当前真机，停止模拟器验证以减少电脑资源占用；真机覆盖安装须保持测试签名和已有数据。

本轮开发共用版本 `1.1.0+21`；送审基础版仍为 `1.0.0+20`。接入和实际验证见 [SDK 共用界面记录](docs/sdk-shared-ui-2026-10-24.md)。

## 2026-10-24 Mac iOS 发布授权

本轮从 `release/1.0` 准备 iOS 1.0.0(20)，复用 Hip Interlude 的 `com.ugk.hipinterlude`（不是独立的 `com.ugk.hiplab` App 记录）。用户已授权自动签名、TestFlight 上传、提交推送 release 并合回 main；2026-10-24 用户随后明确授权填写目标 App 的商店资料并提交 App Review，覆盖原第七条；审核后保留手动发布，尚未授权正式公开发布。本轮 iOS 隐藏 AI 入口且不传 Key，覆盖下文旧的 iOS 禁传及保留 AI 入口限制；Android 仍按其原决定。只改 iOS 配置、iOS 平台界面守卫及发布证据，保持 Android、业务规则、版本、SDK 和依赖不变。真实耳机/锁屏验收不可由模拟器替代。当前证据见 [iOS 发布记录](docs/release-1.0/ios/README.md)。

用户随后明确“声音部分可以不用测试，跳过，我确认 ok，后续自己使用测试反馈”。本轮声音/耳机听感记为用户确认与主动跳过，不再等待耳机就绪，不写成 Agent 实测通过；真机非声音的完整训练、锁屏计时、保存与崩溃检查仍按实际证据记录。

同轮用户再次明确首版不再关注测试细节、优先完成 Apple 商店申请，后续亲自使用测试并迭代。按此要求收束额外验收；完整训练与锁屏持续播放保留未验，不再作为本轮申请准备的阻塞项。用户已明确回复“授权填写资料并提交审核”，目标限定为 Hip Interlude 记录（com.ugk.hipinterlude）的 HipLab 1.0.0 (20)。可更新对应公开隐私/支持页，保留其它 App/Android 政策和另一条等待审核记录。

## 2026-10-24 上架执行追加授权

用户在本轮物料交付后明确授权使用 Playwright MCP 复用其指定浏览器登录态，制作并上传 YouTube 演示、执行 Google Play 上传/填写/送审及完成当前可用发布流程；隐私政策、使用条款等必要公开页面可直接部署，允许使用本机已配置的 Cloudflare。此授权覆盖下文旧“Play 后台由开哥操作”的限制，不包括伪造测试者、绕过正式版权限或虚构审核通过。当前正式版受至少12人连续14天封闭测试门槛限制，先完成现有 Alpha 轨道提交；实际平台状态、账号门槛和本机验证分开记录。

## 2026-10-24 基础版上架分支（用户新授权）

- `release/1.0` 从 main `e456d2a` 建立，只接纳上架和审核修复，完成后合回 main；后续功能在 main 开发。Mac 本轮从 `release/1.0` 开 `ios/…` 分支打 iOS 包，不带入未验收的 AI 0.2 或液态玻璃候选。
- 共用版本为 `1.0.0+20`，Android applicationId 保持 `com.ugk.hiplab`。SDK 固定到完整 commit `d193a703e3a8bef6d41e7705a55ae250e23e6a69`；不传 AI Key。用户同日最新决定保留现有 AI 入口，无 Key 使用本地预设回落，覆盖此前“全部隐藏”的要求。
- 已授权本机修改发布配置、复用并备份既有上传密钥、构建上传签名 release AAB、验证和推送 release 分支；这些是下文旧“发布配置仅版本号”限制的本轮例外。签名凭据、产物和用户数据不进 Git。
- 真机耳机完整训练、锁屏/后台及结束通知清理是本轮明确验收项，优先于下文旧“不扩展耳机/锁屏矩阵”的阶段限制；用户报告与本机实际验证分开记录，不把历史 D-34 改成通过。
- 不在 Google Play 后台执行任何操作，由开哥上传、填写声明和提交审核；不上传 App Store/TestFlight。参阅 [本轮交付](docs/release-1.0/README.md)。

- 本仓库 `mhgd3250905/HipLab` 是 HipLab App 主仓库，`main` 是开发基线，本目录为日常开发入口；后续动作素材由 `mhgd3250905/3D-Pose-Hub` 按发布版本提供。开工先读 `docs/README.md`、`docs/current-state.md` 和 `docs/development-roadmap.md`，再检查实际 Git 状态；手机已安装、分支已推送、main 已合并分别记录，不能混用。
- 本机 Windows 是主干线：按用户 2026-10-18 明确授权审核合并贡献 PR，验证后直接提交和推送 main，无需再开 PR；不要 force push。其他贡献方仍走分支 + PR。已有明确授权不重复询问。
- 本仓库暂无 CI。提 PR 前本地跑 `flutter analyze` 和 `flutter test`，结果写进 PR 说明。
- 本项目新建 worktree、审核/测试克隆及大体积构建产物一律放非 C 盘，先检查并优先复用已有非 C 盘副本。新工作副本默认 `E:/AII-3D/3D-Hip-worktrees/<task>/3D-Hip`，交付产物默认 `E:/AII-3D/hiplab-releases/`；禁止默认使用 C 盘 `.codex/worktrees`、`.config/superpowers/worktrees` 或 Temp。创建前核对工具的实际输出路径；工具不能指定位置且尚未核实其配置时，不使用会落到 C 盘的默认创建，改用显式指定 E 盘路径的 Git 工作副本，并说明工具限制。
- 整理 Codex 托管副本前核对聊天绑定、Git 登记、未提交/未跟踪文件及忽略目录中的唯一产物；先在非 C 盘保存唯一产物，再通过可保持 Git 登记和聊天附件一致的流程归档。不得直接拖动或删除目录来迁移托管副本。具体执行流程见 `docs/development-workflow.md`。
- 仅文档改动验证事实、链接和 `git diff --check`，不增加 App 版本、不重复构建。功能变更按影响范围测试，涉及原生播放或安装需补真机证据；未执行检查明确写出。
- 当前阶段按用户2026-10-19最新要求，以正常字号和日常设备使用为兼容性验收范围；极大系统字号等极端显示环境不列为当前合并门槛，不为其继续扩展实现或验收。已有记录保留历史，常规数据正确性继续验证。按用户同日最新要求，本轮原生验收以正常播放无误为门槛，不再扩展耳机/蓝牙、外部音乐ducking及锁屏/系统中断矩阵；未验项目与历史失败如实保留，不改记为通过。
- 状态实际变化更新 `docs/current-state.md`；构建/安装/发布追加 `docs/version-ledger.md`；检查结果维护 `docs/verification.md`；事项进展维护 `docs/development-roadmap.md`；关键成果写入 `docs/development-log.md`。保留历史记录并链接最新状态，不把旧结论改写成新验收。
- `assets/hip/hip-content.json` 是生成文件：改 `tools/hip_content/source/` 后运行 `python3 tools/hip_content/build_hip_content.py`。
- 动作姿态、脚向、高亮和渲染问题去 Pose-Hub 提 issue（App、动作 ID、问题、期望），不在 HipLab 重渲。Pose-Hub v0.2.0 为当前冻结版本（视频1080、封面540）；使用仓库冻结的 pose-hub.lock.json / tools/pose-hub-manifest.json，按 docs/README.md 下载校验 ZIP 后用 --from-dir 恢复并 --check。后续升级由 Windows 更新冻结版本，保留旧母版、规格和 QA；旧 tools/sync_drill_media.py 仅保留历史兼容。
- 高清同步使用已通过 QA 的批次和显式参数，当前流程见 `docs/development-workflow.md`。逐项来源以 `tools/hip_content/source/hip-media.json` 为准；保留绿幕/透明母帧、旧批次与修订来源，不覆盖冻结动作、模型或 QA。
- `lib/core/` 是从 3D-Body 复制的公共代码，文件头注明来源；修改时保留来源注释并说明改了什么。
- 包里只放 HipLab 自己用到的资源（`test/hip/hip_assets_test.dart` 会检查）。
- Android 更新保持包名和签名连续，覆盖安装保留用户数据；不要清数据。用户数据备份、密钥、APK 和运行截图日志留 Git 忽略目录，文档路径不代表已备份到远端。

- Windows 负责 `lib/`、`android/`、`assets/`、`tools/`、媒体 lock、依赖和版本号；Mac 只改 `ios/` 及少量 iOS 专属平台代码，不升级依赖或素材版本。Mac 新机器可按 `docs/README.md` 用冻结 lock 执行 `sync --from-dir` / `--check` 恢复素材。两端 Flutter 统一 **3.44.7 stable**；版本由 Windows 统一递增。
- Mac 从最新 main 开 `ios/…` 分支并提 PR，本机主干线负责审核集成；Windows 可直接在 main 推进已授权工作。跨端共享音视频改动必须补 Android 复查。
- 本轮及后续未另获授权前，不上传 Play / App Store / TestFlight，不调整商店或发布配置；发布配置变更当前只允许 pubspec.yaml 共用版本号递增；本机完成本轮开发与验证后推送 main 已授权。手机拔线时不执行 ADB，网页结果不代替 native/iOS 验收。
