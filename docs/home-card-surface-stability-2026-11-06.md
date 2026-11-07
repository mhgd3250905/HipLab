# 首页动作牌视频稳定性 · +50 · 2026-11-06

运行/构建源 `981eeaf161c0b896e963d625f9525b69e9bf32b6`，分支 `codex/home-card-surface-stability-20261106`；`1.1.0+50` / arm64 `2050`。SDK最终 `145e3195570f34536c948558e02306a3db5ec2e3`（feature f994840，后续补足获取输出窗口前的renderer所有权登记）。日常目录 `feat/ui-detail-polish@25260b3` 保持clean，SDK/App均仅候选分支。

## 两处原因与修改

点击更多时，SDK收到isCurrent=false立即reload/dispose暂停decoder，牌面转回封面。新增retainPausedSurfaceWhileCovered默认false，仅首页前牌启用；已有真实暂停帧、controller、Texture和pin跨覆盖/返回持续存在。未就绪画面不为隐藏路由新建/起播，后台、动作或policy变化、playing关闭、真正dispose继续释放，普通宿主默认不变。

纵向退场未发生Dart媒体切换，却在GPU像素实验复现alpha/RGB错位，匹配用户03号牌下退场截图中的灰白三角残影/黑底。8种局部Layer、saveLayer、opacity、identity filter和不透明纸背景均未修复。原因与官方已确认的[Flutter ImageFilter.shader离屏输入裁剪问题](https://github.com/flutter/flutter/issues/185175)一致；当前固定3.44.7无unclippedInput，不引入未合入的engine patch或升级框架。

新增nativeAlpha默认false的能力，首页前牌启用：同一MediaPlayer输出OES，Android EGL/GLES将上下RGB/alpha合成premultiplied RGBA给同一SurfaceProducer，Flutter直接绘制一张方形Texture。无截图、CPU逐帧读回、第二decoder、轮询或新依赖。首帧在draw/swap之后通知；GL清理与producer释放完成后才确认dispose并释放pin。Surface重建重画保留的OES图像，第一帧之外不发逐帧通道消息。旧默认packed路径保持，+49交互/速度、单视频和当前帧收起保持。

## 验证及边界

App相关10文件96通过/0失败/14跳过（12既有截图项+2需Impeller），Impeller两项另串行通过，分析0；严格锁解析保持lock，hosted版本/摘要/来源未变。真实HipApp更多→设置→返回逐16ms验证同一媒体Element/controller/Texture、poster opacity0，无dispose/reprime/seek。SDK相关49通过/分析0，覆盖opt-in/native能力/默认兼容、真实首帧、覆盖路由、后台和延迟释放等。

实际native GLSL通过已有ANGLE/GLES对独立CPU oracle的identity/ST-Yflip两例验证，通道最大/均值误差0；使用这些独立GPU输出fixture，经生产UgkPackedAlphaVideo nativeRGBA消费34个四向真实pose，共68组误差和黑残影0。down exit200/280仍分别含17699/5677个有效ink像素，不是空白出屏误过。旧packed对照最大均值RGB误差132.80/黑像素6055，静止对照正常。Synthetic fixture仅测试使用，不加入App资源。

两个Android文件离线Kotlin编译通过；最终App Gradle release编译覆盖完整最终源码；最终DEX确认GL合成器与采样uniform标记存在，synthetic测试fixture未入APK，见交付目录native-dex-check.json。原始证据在 `E:/AII-3D/hiplab-releases/home-card-surface-stability-20261106/`，特别是native-rgba-final/summary.json、native-gl-unpack/；SDK日志位于隔离副本packages/ugk_trainer_runtime/build/surface-stability/和native-alpha/。未跑全量App/SDK，无模型调用或iOS验证。桌面ANGLE算法/Flutter消费通过不能替代Android实际OES、PRIVATE ImageReader/EGL RGBA协商、方向、首帧与性能；本机无设备，均交用户原机远程确认。

## 交付

| 项目 | 事实 |
|---|---|
| APK | `E:/AII-3D/hiplab-releases/home-card-stable-981eeaf-50-20261106/hiplab-1.1.0+50-981eeaf-internal-arm64-release.apk` |
| 大小 / SHA256 | 47628200字节 / `1884f8d7bc2b716a364299366ba1f920487eb4f5c660989615c7879343ed9f37` |
| 证书SHA256 | `3761270a4764157f0e389014a9e5b800b05403bfddce0f4f7f8c039f6a53bdc7`，与+49内部包一致 |
| 身份 | com.ugk.hiplab/1.1.0/2050/release/仅arm64/非debuggable；构建78.1秒；重签runtime负载一致 |
| 内容 | 789资源项校验通过；r2-v1/stable、249目录动作、209授权/封面/未审AI标签、0内置MP4 |

最终内部包、原上传签名归档和回执留同一E盘目录；未上传/安装。用户远程覆盖后重点确认进入更多/返回、上下退场（截图03位置）及展开播放/暂停。App/SDK候选已推送，main/release/tag/商店和本地设备未操作。
