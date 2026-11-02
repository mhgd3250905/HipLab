# HipLab 共享体验收束（2026-11-02）

用户16:19明确超大字号不在支持范围，授权删除2.0倍字号用例；此前SDK键盘溢出不再阻塞本轮，也未在App加绕过。继续分支`codex/sdk-shared-experience`，不合main、不打tag、不动release、托管或Flare、不提交商店。

## 本轮修改与删除清单

启动修复沿用`1f76e745da30133b8b38986d27c2f1b9e5df7791`：大型内置coach catalog改为bytes/UTF-8读取，仍由SDK校验；冷启动不依赖网络，断网进入主界面有回归。本轮只改测试：真实海报解码在runAsync中等待，训练断言等待SDK入场完成且播放控件实际可操作；滚动测试选择纵向viewport并等布局完成，图标断言限定App拥有的控件。音频、侧别、剂量、疼痛、存储及正常字号键盘断言保留。

按授权删除**11条**2.0倍字号用例，没有新增skip：

| 文件 | 删除的用例 | 数量 |
|---|---|---:|
| `test/hip/hip_search_keyboard_test.dart` | `search ×2.0: tap shows the keyboard, keeps it when the inset arrives, typing filters`；`search ×2.0: keyboard put away (back), tap again shows it again` | 2 |
| 同上 | `添加动作 picker search ×2.0: tap shows the keyboard` | 1 |
| `test/hip/hip_practice_large_text_test.dart`（整文件删除） | `P3 360×780 ×2.0`下，自测卡标题/说明，以及动作/套路/我的文本两类；各覆盖light/dark × 已自测/未自测四种组合 | 8 |

完整11条名称保存在证据目录`removed-tests.json`。正常字号搜索三条保留，既有1.3/1.5倍用例未扩展或删除。

## 验证与 APK

构建/验证源为`2d3070d375b546bad0dcc453b548ecb0ace818d9`。严格`flutter analyze --no-pub --fatal-infos`为**0问题**；`flutter test --no-pub --concurrency=1 --reporter expanded`全量**428通过/1既有条件跳过**（6分21秒，跳过为可选VOICE_TIMELINE_OUT导出）。原失败所在定向集合均首轮通过；首轮全量发现ui_round1另一个同类入场等待遗漏，在391通过/1失败时停止以节省语音等待，补齐该入口及flow同类入口后，本次第二轮全量全部通过，未开第三轮。Python沿用前轮25/25，相关代码未变，本轮未重复。

版本保持**1.1.0+28**，arm64 split **versionCode2028**。`ugk_coach`、`ugk_coach_ui`、`ugk_trainer_runtime`、`ugk_coach_chat`及coach override的ref/resolved-ref固定**d4502f35b1503d41cd782aa7fb3780c7f6591ad0**，没有legacy `ugk_trainer`。HipLab用**Flutter3.44.7/Dart3.12.2**；SDK验证用3.47.8/Dart3.13.7，两者满足SDK声明，相关asset解码机制一致，本轮未升级工具链或修改SDK。

全量通过后在日常带签名配置目录构建release，56.4秒成功；未复制密钥。交付APK：`E:/AII-3D/hiplab-releases/sdk-shared-experience-20261102/hiplab-1.1.0+28-shared-experience-arm64-device-release.apk`，**45,508,800 bytes（43.40 MiB）**，SHA256 **d0ee06277e37753d00020de937ad8706bc2ea21d122c5411df9a7f7d4ab061e0**。上传签名原包另存；设备连续测试证书SHA256为`3761270a4764157f0e389014a9e5b800b05403bfddce0f4f7f8c039f6a53bdc7`，重签前后运行负载一致。验包确认`com.ugk.hiplab`、release arm64、2028、**0 MP4、46公共poster**，CRC与签名通过。

手机已拔线，没有执行ADB或安装；安装及视觉/真实操作交用户自测。日常原分支40个WIP文件另存了字节副本与哈希，收束时恢复并核对状态；不把候选推送、APK构建或静态验包记为真机验收。

证据目录：`E:/AII-3D/hiplab-releases/sdk-shared-experience-20261102/completion-1619/`。此前停止及诊断包历史保留在[启动定位报告](sdk-shared-experience-2026-11-02.md)，不将旧包记为新交付。
