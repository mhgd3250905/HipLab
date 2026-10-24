# HipLab 文档与开发台账

**2026-10-24 Controller 已合入 main：** 固定候选448f109已获开哥同意，快进合入并普通推送main、远端回读一致。既有分析0、全量454通过/1条件跳过和专项44通过保持；release/1.0不动。以下待审记录为批准前历史。[集成回执](sdk-conversation-controller-2026-10-24.md#主线集成回执)。

**2026-10-24 对话 controller 候选：** `codex/coach-conversation-050-20261024` 基于 main64daf6a，采用 coach0.5.0 / trainer0.2.3@d7e0b8f，UI0.1.1保持；SDK接管消息、问题、回答整理和取消/重置/恢复。严格锁解析完成，分析0、全量454通过/1条件跳过、AI专项44通过，候选已完成待审，main合推等待本轮同意。release/1.0不动。[接入与删除范围](sdk-conversation-controller-2026-10-24.md)。

**2026-10-24 SDK 修复 tag：** coach0.4.2 / trainer0.2.2 / coach_ui0.1.1均固定3302d62，远端解析完成；分析0、窄屏专项13通过，全量451通过/1条件跳过。本轮已合入并推送main（功能集成点88d8802），release/1.0不动，真机沿用既有证据。[补丁与集成回执](sdk-tag-patch-2026-10-24.md)。以下为先前阶段记录。

**2026-10-24 SDK 共用界面候选：** 开发版 1.1.0+21 位于 `codex/sdk-shared-ui-20261024`，coach 0.4.1 / trainer 0.2.1 / coach_ui 0.1.0 正式 tag 固定。无 Key 隐藏 AI，本轮分析0、451通过/1跳过、release编译及真机M自然完成通过，语音用户确认正常；等待最终合并同意；release/1.0 保持基础版。[接入与验证](sdk-shared-ui-2026-10-24.md)。

**2026-10-24 13:09：** 1.0.0(20)已提交Alpha审核，Submission ID2状态审核中；前台服务演示和公开隐私已补齐。正式版仍需12名真实测试者连续14天，用户选择稍后组织。[执行回执](play-store-release-2026-10-24.md)。以下上架准备段落保留历史。

**2026-10-24 基础版上架准备：** `release/1.0` 从 main e456d2a 建立，1.0.0+20 / SDK固定d193a70，无Key本地预设、保留AI入口。上传签名AAB和商店/FGS材料已准备；Play由开哥操作，Mac从release分支接iOS。[本轮交付](release-1.0/README.md)。以下日期条目为历史记录。

**已获同意，两个main均已合入并推送。** 2026-10-21用户明确“合并并推送，保留锁屏已知问题”；SDK main为d193a70（PR #2已MERGED，00:39:10），HipLab主线集成点691ace2（00:39:31）。已安装包保持0.3.9+17/79c172d、21原记录/4组/UUID保持；锁屏冻结仍是已知失败，由用户后测，不重建/重测、不改手机省电设置、不上传商店。[合并与边界](android-lockscreen-fix-2026-10-21.md#主线合并确认2026-10-21)。

以下按日期保留的候选、安装与失败段落均为历史快照，其中“当前”“未合main”“待解锁”描述当时现场；当前交付与授权以页首最新结论及对应台账为准。

**00:08失败阶段快照：0.3.9+16锁屏仍失败。** 00:07:47.193 Greeze冻结（关屏5分25.7秒），服务和started/mutedState:none音轨仍在、训练锁DISABLED；系统媒体会话栈为0。不能把正常音量修正记为锁屏通过。当前安全锁屏，待用户回来解锁后正常结束本轮；SDK正在补真实媒体会话与释放，main未合。[完整现场](android-lockscreen-fix-2026-10-21.md)。

**00:02安装快照：0.3.9+16已保留数据安装。** SDK8fb0aac/trainer0.1.3将Android全零采样音轨设正常播放器音量；119训练包测试和App439过/1跳、analyze均通过。20记录/4组/UUID保持；当前8动作整节锁屏观察中，main未合。[本轮修复与结果](android-lockscreen-fix-2026-10-21.md)。

**2026-10-20 23:53阶段快照：0.3.9+15已安装，但整节锁屏再次失败：** [AI新中转](ai-relay-migration-2026-10-20.md)的App Key、UUID及手机AI生成/保存通过，439项过/1条件跳、analyze0；23:50:21.914小米Greeze再次冻结并禁用训练锁。亮屏恢复后用户正常结束，528秒、6/8、提前结束，现20记录/4组，训练服务已释放。main未合，待SDK修复、整节复验和最终同意。[训练包接入与失败历史](ugk-trainer-adoption-2026-10-20.md)。

**上一轮修复候选快照：** [ugk_trainer 接入](ugk-trainer-adoption-2026-10-20.md)在 `codex/adopt-ugk-trainer`。首轮0.3.8+13锁屏失败，SDK7348f0c/trainer0.1.2已补Android间隙保活与终态释放，118测试通过；新包0.3.8+14已保留数据覆盖安装，analyze0，App全量429过/1条件跳。用户已改为扬声器锁屏复测，现因需使用其他App暂缓，待用户恢复；main未合，待验收与最终同意。

**2026-10-20 早间主线构建快照：0.3.7+12，带AI配置、debug arm64，同包名/签名；该阶段只构建未安装、未发布。** 来源55d99b3，业务沿用PR25已验8c985c4；当前安装已变化，见页首主线交付。[早间APK身份与交付边界](android-test-build-0.3.7-2026-10-20.md)。

**2026-10-20 11:24:56：PR #25已获开哥明确同意，合入并普通推送main，GitHub确认MERGED。** 来源8c985c4 / SDK0.1.2，集成点ce7ab74；原5P2闭环，414过/1条件skip、analyze/构建/API通过。真机未验仍保留，手机未更新、不发布；[合并与复审](pr25-reaudit-2026-10-20.md#主线合并确认2026-10-20)，[首轮历史](pr25-review-2026-10-20.md)。

**此前主线集成：2026-10-19 23:32，PR #22/#24及集成修复已获开哥同意，合入并推送main（b33ed21），GitHub均MERGED。** 387项通过/1条件跳过，F1–F9及PR24四P2闭环，Android正常播放与编辑/键盘已验；手机已安装运行内容保持，版本仍0.3.6+11。[合并身份与验收边界](pr22-f9-reaudit-2026-10-19.md)。

此前阶段记录：**2026-10-19：本轮c7def28 / 0.3.6+11审阅包已交付，用户报告真机安装及简单测试通过；三PR及修复已按#19→#20→#21顺序合入并推送main（业务集成点b9646d4）。** 完整试听/锁屏/性能等待验范围见[本轮审核](pr19-pr21-review-2026-10-19.md)。以下#17/#18事实为此前主线交付历史。**PR #17/#18 已修复两项P2并顺序合入main，Android当时已保留数据安装0.3.6+11修复包（源码6dd16ed）**；analyze0、191pass/1条件skip，深浅及减少动画分段下沉、快速Tab、原生视频退出已复查，偏好逐字节保持，见[修复与合并记录](pr17-pr18-fixes-and-merge-2026-10-18.md)。此前[0.3.6样式安装](theme-polish-2026-10-18.md)和[0.3.5语音试听](android-voice-media-routing-2026-10-18.md)保留历史；当前冻结Pose-Hub v0.2.0（46条1080视频/46张540封面）。完整课程、音乐ducking、低端帧时、强光及iPhone仍待补。

| 文档 | 用途 | 何时更新 |
|---|---|---|
| [训练包接入](ugk-trainer-adoption-2026-10-20.md) | 训练执行/播放/语音/唯一服务归包，App保留业务插槽；首轮及候选失败历史 | 接口或集成事实变化时 |
| [AI新中转迁移](ai-relay-migration-2026-10-20.md) | App Key、持久UUID、新入口及手机生成保存证据；不存凭据 | 配置约定或验证结果变化时 |
| [Android锁屏复测与主线确认](android-lockscreen-fix-2026-10-21.md) | 0.3.9+17已安装、两main已合推；锁屏已知失败交用户后测 | 实际验收或集成事实变化时 |
| [0.3.7+12 Android测试包](android-test-build-0.3.7-2026-10-20.md) | 55d99b3，AI配置debug arm64；仅构建、未安装、未发布 | 实际交付状态变化时 |
| [PR #25修复复审与合并](pr25-reaudit-2026-10-20.md) | 8c985c4 / SDK0.1.2，414过/1跳，已合main；真机未验保留 | 验证或集成事实变化时 |
| [PR #22 F9返回复审](pr22-f9-reaudit-2026-10-19.md) | F9关闭；387项及原生编辑/键盘通过；#22/#24已合main并推送，GitHub均MERGED | 集成时 |
| [PR #24修复与#22组合验证](pr24-reaudit-and-pr22-integration-2026-10-19.md) | 0ccef6b原4P2闭环；正常播放及用户听音通过；F9后续关闭并随#22/#24合main | 作者F9修复及集成时 |
| [PR #22 Android真机复测](pr22-native-retest-2026-10-19.md) | 2cc40e3阶段F8通过、新增F9后续已修复合入；解锁后英文保持/闹铃已补，扩展系统矩阵及极大字号退出本阶段门槛 | 真机结果及作者修复后 |
| [PR #24 Android后台语音审核](pr24-review-2026-10-19.md) | e3655e5首轮历史；四P2后续在0ccef6b关闭并合main，最新见组合与F9复审记录 | 保留首轮证据 |
| [PR #22 Web补充验收](pr22-web-acceptance-2026-10-19.md) | 9fa0cc0界面/迁移/F3/F4/F7及重复单练记录补测；首轮发现F8/P2，后续已关闭合main；该页保留当时Web证据与原生边界 | 修复版本及验收证据变化后 |
| [PR #22 修复复审](pr22-reaudit-2026-10-19.md) | F1–F7在9fa0cc0代码闭环、Windows322过/1跳；[Android包准备](pr22-android-acceptance-2026-10-19.md)及原生待验；[首轮报告](pr22-review-2026-10-19.md)保留 | 修复版本及验收证据变化后 |
| [练习库实现](training-library-2026-10-19.md) | 拍板四条、动作大全/单练/套路/训练组的实现范围、custom_routines v1、PR #22 审核 F1–F6、复审 F7、Web 补充验收 F8/P3 修复、测试与真机清单（PR22现已合main，历史阶段记录保留） | 练习库变化时 |
| [PR #19/#20/#21隔离审核](pr19-pr21-review-2026-10-19.md) | 五项首轮修复、254过/1跳、Python19、Web复核及arm64交付；用户报告安装/简单真机测试通过；已顺序合入main | 本轮审核与原生证据变化后 |
| [轻拟物有选择引入：审美考据](tactile-design-rationale-2026-10-19.md) | 引用 HIG / M3 / Refactoring UI / NN/g / Rams 推导的 6 条规则、逐控件判定、预算回归测试（#19已合main） | 拟物使用范围变化时 |
| [PR #17/#18修复与合并](pr17-pr18-fixes-and-merge-2026-10-18.md) | 两项P2、191项回归、真机数据保持与合并身份 | 本轮实际状态变化后 |
| [0.3.6样式与阶段收束](theme-polish-2026-10-18.md) | 4项修复、源码/证据绑定、APK和19:29安装、验收边界 | 本阶段事实变化后 |
| [Pose-Hub v0.2.0 接入](posehub-v020-integration-2026-10-18.md) | 当前冻结资源、App 产物及验收边界 | 同步或实际结果变化后 |
| [第二轮集成记录](round2-integration-2026-10-18.md) | #13/#14 固定审核、语音生命周期、UI 回归、APK 与网页/原生边界 | 本轮事实变化后 |
| [动作素材浅/深主题](action-media-audit-2026-10-19.md) | 8 个展示位置盘点、方案比较、管线、体积、动作包对接（#20已合main） | 素材或方案变化后 |
| [主干与 Pose-Hub 集成记录](mainline-pose-hub-2026-10-18.md) | 四个 PR 合并、v0.1.0、最终构建与首帧原生待补边界 | 本轮状态变化后 |
| [第一轮 Android 集成验证](android-round1-integration-2026-10-17.md) | 原三阶段构建、真机及当时待合并边界；最新进展见当前状态 | 保留原阶段证据 |
| [Google Play 送审](play-store-release-2026-10-17.md) | 0.2.0+4 / Submission 1 的历史回执 | Console 实际变化后 |
| [Pose-Hub 接入](pose-hub-adoption.md) | v0.2.0 冻结同步、保留素材及两端边界 | 素材发布或同步时 |
| [当前状态](current-state.md) | 当前 App、分支、PR、环境与完成边界 | 状态实际改变后 |
| [版本管理说明](version-management.md) | 版本来源、构建/安装/合并/推送/发布状态及台账维护规则 | 版本管理约定变化时 |
| [版本交付台账](version-ledger.md) | 每次构建、安装、发布的版本和产物身份 | 产生可交付版本时追加 |
| [验证台账](verification.md) | 哪个版本做过哪些检查，哪些尚未验证 | 完成检查后 |
| [开发事项台账](development-roadmap.md) | 缺陷、后续工作与验收条件 | 开工、受阻或验收时 |
| [开发工作流](development-workflow.md) | 主线集成、日常开发、媒体同步和 Android 更新步骤 | 流程或工具变化时 |
| [开发日志](development-log.md) | 关键决策、成果和对应证据 | 有意义的工作检查点 |
| [iOS 运行与上架](ios-setup-and-release.md) | Mac 上运行/归档步骤、iOS 配置清单、真机确认清单 | iOS 配置或验收变化时 |

开始新一轮开发先读当前状态和开发事项，检查实际 Git 分支，再按工作流推进。仅文档修改不增加 App 版本、不重新安装手机；完成业务改动后按影响范围验证并更新台账。PR 和提交保存代码事实，台账保存交付和验收事实，两者互相链接。

## 证据与历史记录

以下文档保留当时的核查过程；阶段性的“待完成”不代表当前状态。

| 文档 | 范围 |
|---|---|
| [接手基线](project-takeover-2026-10-17.md) | 初始代码、环境、48 项测试与已确认计时缺陷 |
| [媒体初始审计](media-audit-2026-10-17.md) | 制作前缺片、静帧和清晰度问题 |
| [语音播报审计](voice-audit-2026-10-18.md) | 播报中途消失的根因（iOS 会话被提前停用）、素材逐条检测前后对比、真机复听清单 |
| [本地高清制作](local-hd-render-2026-10-17.md) | 4080、PR #119、46 项选版、绿幕/透明母帧与制作过程 |
| [Android 实机记录](android-first-run-2026-10-17.md) | 首次安装及 0.1.1+2 保留数据更新、真机播放证据 |
| [主线集成审核](mainline-integration-2026-10-17.md) | #2、#1 固定版本审核、合并身份和本地对齐 |
| [App Icon 运动方向](app-icon-sports-2026-10-17.md) | D-05 用户新要求、两张候选、选版与安卓接入边界 |
| [早期 MVP 设计](hiplab-mvp-2026-10-16.md) | 从 3D-Body 变体拆仓前的设计背景 |

逐条媒体来源以 [hip-media.json](../tools/hip_content/source/hip-media.json) 为准；[hip-content.json](../assets/hip/hip-content.json) 是生成结果。APK、截图、运行日志与设备数据备份在 Git 忽略目录内；文档中的本机路径不代表这些文件已备份到 GitHub。

## 新机器拉素材（Mac / Windows）

先拉取 HipLab 的最新 `main`，以下命令均在仓库根目录执行。`pose-hub.lock.json` 和 `tools/pose-hub-manifest.json` 已随主线保存，固定 Pose-Hub **v0.2.0**；新机器直接使用这两个文件，不另取最新版 manifest。两端统一 **Flutter 3.44.7 stable**；Mac 不修改 lock、版本号或依赖，后续素材升级由 Windows 维护。

从公开的 [Google Drive v0.2.0 ZIP](https://drive.google.com/file/d/17M0oMpWIqWQJ19sMEOEsDF7H7AU9meqF/view?usp=drivesdk) 下载 `pose-hub-media-v0.2.0.zip`，保存到仓库中的 `build/pose-hub/v0.2.0/`。也可从 [版本分发文件夹](https://drive.google.com/drive/folders/12M4g7bpomaCjY7qdgYdfoUHuA2xla9lH) 获取同名文件。使用浏览器下载即可，不需要安装额外下载工具。

ZIP 必须恰为 **39,151,634 bytes**，SHA-256 必须为：

```text
f422c051eab2b4e973fe637d5f2a3dec07207e21b960f10800efe77dd317c772
```

Mac：先执行下面的校验与解压。任一断言失败会立即停止，不能跳过校验继续解压或同步。

```bash
python3 - <<'PY'
from pathlib import Path
import hashlib
import zipfile
archive = Path("build/pose-hub/v0.2.0/pose-hub-media-v0.2.0.zip")
assert archive.stat().st_size == 39151634, "ZIP size mismatch"
assert hashlib.sha256(archive.read_bytes()).hexdigest() == "f422c051eab2b4e973fe637d5f2a3dec07207e21b960f10800efe77dd317c772", "ZIP SHA-256 mismatch"
with zipfile.ZipFile(archive) as bundle:
    bundle.extractall("build/pose-hub/v0.2.0/extracted")
print("ZIP verified and extracted")
PY
```

然后按顺序执行；每条命令退出码为 0 后再执行下一条：

```bash
python3 tools/pose_hub_sync.py --lock pose-hub.lock.json --from-dir build/pose-hub/v0.2.0/extracted --dry-run
python3 tools/pose_hub_sync.py --lock pose-hub.lock.json --from-dir build/pose-hub/v0.2.0/extracted
python3 tools/pose_hub_sync.py --lock pose-hub.lock.json --from-dir build/pose-hub/v0.2.0/extracted --check
python3 tools/hip_content/build_hip_content.py
flutter --version
flutter pub get --enforce-lockfile
flutter analyze
flutter test --concurrency=1
```

Windows PowerShell：同样先通过浏览器把 ZIP 放到上述位置，再执行校验与解压：

```powershell
@'
from pathlib import Path
import hashlib
import zipfile
archive = Path("build/pose-hub/v0.2.0/pose-hub-media-v0.2.0.zip")
assert archive.stat().st_size == 39151634, "ZIP size mismatch"
assert hashlib.sha256(archive.read_bytes()).hexdigest() == "f422c051eab2b4e973fe637d5f2a3dec07207e21b960f10800efe77dd317c772", "ZIP SHA-256 mismatch"
with zipfile.ZipFile(archive) as bundle:
    bundle.extractall("build/pose-hub/v0.2.0/extracted")
print("ZIP verified and extracted")
'@ | python -
```

确认上一条成功后，逐条执行：

```powershell
python tools/pose_hub_sync.py --lock pose-hub.lock.json --from-dir build/pose-hub/v0.2.0/extracted --dry-run
python tools/pose_hub_sync.py --lock pose-hub.lock.json --from-dir build/pose-hub/v0.2.0/extracted
python tools/pose_hub_sync.py --lock pose-hub.lock.json --from-dir build/pose-hub/v0.2.0/extracted --check
python tools/hip_content/build_hip_content.py
flutter --version
flutter pub get --enforce-lockfile
flutter analyze
flutter test --concurrency=1
```

ZIP 根目录直接包含动作 ID 文件夹，例如 `glute-max-A/`，没有额外的 `v0.2.0/` 层。因此 `--from-dir` 必须指向 `build/pose-hub/v0.2.0/extracted` 本身，不能再加版本子目录。ZIP 内没有 manifest；同步工具读取仓库已提交的冻结 manifest。`build/` 已被 Git 忽略，ZIP 和解压目录不提交。

当前包为 **46 条 1080×1080 dark 视频 + 46 张 540×540 JPG 封面**。封面 540 是 v0.2.0 发布规格，不能继续写成 1080 封面；视频与封面均按 manifest SHA 校验。

此包只含 46 个动作的 dark 视频和封面，共 92 个文件。`supine-cross-demo` 为 HipLab 自有剪辑，实际文件为 `assets/drill_media/hip-supine-cross-demo.mp4` 与 `hip-supine-cross-demo.jpg`，自测 still 保留既有 `assets/hip/assessment/`，light不在此冻结ZIP；main现由PR #20另带47套浅色视频/封面与20张浅色自测图。三者均不在此ZIP或当前lock中，不删除现有资源；冻结ZIP不代表本次App包只含深色素材。首次同步用于恢复已冻结的构建资源，不改变素材版本或 ID；`--check` 必须退出 0，内容重生成后如有意外差异，应先核对来源，Mac 不自行修改 lock 或升级依赖。
