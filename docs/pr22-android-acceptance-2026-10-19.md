# PR #22 Android 原生验收

2026-10-19：安装包准备完成，等待用户连接手机。**尚未执行 ADB、覆盖安装、自测或训练；PR 未合并。** iOS 本轮不验收。

## 固定来源与构建

基线 `b12b0f5b52541a6d600578865894ead448a45266`，候选 `9fa0cc09c085df619297c59c886c7bd836a98ff6`。main 当前文档提交 `dd4a0a1` 与该基线的 lib/android/assets/pubspec/lock 无差异。本轮仍按用户指定的准确基线构建。

复用 `E:/AII-3D/3D-Hip-worktrees/pr22-fix-review/3D-Hip`，先切基线再切候选；最终停在候选且 tracked/untracked clean。Flutter 3.44.7 stable，两个来源均执行 `flutter pub get --enforce-lockfile` 与 `flutter build apk --debug --target-platform android-arm64 --no-pub`。没有改源代码、依赖、lock 或版本号。

产物根目录：`E:/AII-3D/hiplab-releases/pr22-android-acceptance-20261019/`。TEMP/TMP 指向其中 tmp，Gradle/Pub 使用既有 `E:/DevCaches/gradle`、`E:/DevCaches/pub`。未创建新副本或 C 盘构建目录。

| APK 文件名 | 字节数 | SHA-256 |
|---|---:|---|
| `hiplab-0.3.6+11-main-b12b0f5-arm64-debug.apk` | 174,333,322 | `5502ec69e77d81ee42309f1265904e963c1c8a45e405ebb50f60153510653a3c` |
| `hiplab-0.3.6+11-pr22-9fa0cc0-arm64-debug.apk` | 174,483,026 | `ce978c5f7ae92fe4ab19587040faf638183bef868dd54e06c572bff01beeca1b` |

两包包名 `com.ugk.hiplab`，版本 `0.3.6+11`，沿用 debug 证书 SHA-256 `3761270a4764157f0e389014a9e5b800b05403bfddce0f4f7f8c039f6a53bdc7`。ZIP 全项 CRC、apksigner、16KB 页对齐均通过；arm64 引擎，打包的 575 个音频（中英各285、提示音5）和94个深浅色视频逐文件与源资源一致。

首次候选增量 APK 有约25MB ZIP 空洞，保留为本机 `candidate-incremental-gap.apk` 调查历史；只移出本轮生成的单个 Gradle APK 后重建，最终交付包无大于1MB的条目间空洞。1478项名称保持，重建生成的 kernel_blob.bin CRC/压缩大小变化，其余条目CRC和大小保持；源码未变。交付包比基线增加149,704字节。

本机证据包括 `baseline-pub-get.log`、`baseline-build.log`、`candidate-pub-get.log`、`candidate-build.log`、`candidate-repack-build.log`、`apk-identity.json`、`apk-audit.log`、两包签名/对齐/badging记录、`repack-comparison.json`。APK与原始证据不入Git，路径不代表远端备份。

## 真机清单与当前状态

Windows 的 present PnP 列表未识别 Android/ADB 手机；用户随后选择“先准备安装包，稍后接手机”。因此本轮没有执行 ADB，不把构建或既有 widget 结果记成原生通过。

| 验收范围 | 当前状态 |
|---|---|
| main 安装、真实自测、完整今日套路，记录连续天数/等级/主题/语音 | 未执行，等待手机 |
| `install -r` 升级，原状态键值保留，只新增 customRoutines/sessions | 未执行 |
| F复制：h-sumo-pry停15秒/步骤60秒，杀进程重启保持 | 未执行 |
| F1计次/保持各两轮，中英文语音/报数/提示音，记录恰增2、连续天数不变 | 未执行 |
| 单练/自定义各锁屏30秒、后台、闹钟或来电、外部音乐ducking，恢复后再来一组 | 未执行 |
| F7深蹲1次×3组疼痛跳过，单练结束、自定义休息/反馈/下一步 | 未执行 |
| §6其余项：三tab、自测卡返回链、45动作/搜索筛选、详情、拖动/左滑删除、360宽最大字号、深浅主题 | 未执行 |
| iOS | 本轮不验收 |

连接后先确认实际设备与签名并备份应用私有偏好，先装基线完成用户要求的准备，再装候选。`shared_prefs/FlutterSharedPreferences.xml` 内准确条目为 `flutter.hiplab.state.v1`；比较原JSON键值语义，正常保存后允许新增两个字段。测试自身产生的自测、训练、疼痛记录另记，不靠注入健康结果制造验收条件。

每项保留截图/录屏、通过或失败和复现步骤、音频报错日志（如有）。日志无错误和焦点状态只作辅助，实际听音与ducking不能省略。最终整理一条PR评论；**全部通过且经开哥同意后再合入main并推送**。
