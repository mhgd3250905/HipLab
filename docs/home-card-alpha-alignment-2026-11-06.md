# 前牌透明视频错位黑轮廓 · +45 · 2026-11-06

运行/构建源 `9925e3c58afdea65768875f85ee3a4b60865a6f0`，分支 `codex/home-card-alpha-alignment-20261106`；`1.1.0+45` / arm64 `2045`。SDK仍 `1c082e9d3e22022f228888fdd1935b1d61371cb9`，lock、shader/素材内容及原生代码保持；日常目录 `feat/ui-detail-polish@25260b3` 保持clean。

用户+44截图显示坐姿后撑单膝内倒等前牌人物后缘有错位黑轮廓。+45为前牌姿态Transform设置非空filterQuality：先在局部坐标合成视频RGB/alpha，再将整张牌作为GPU滤镜结果做透视/旋转；保留同一直播Texture、当前帧暂停和展开/收起行为。

## 定位和修复

packed视频把RGB和alpha竖向装在同一幅图像的上下半幅。当前shader使用固定半幅位移取样，要求输入保持局部对齐；[Flutter3.44.7 Impeller runtime filter](https://github.com/flutter/flutter/blob/3.44.7/engine/src/flutter/impeller/entity/contents/filters/runtime_effect_filter_contents.cc)会将带变换的snapshot重栅格化。原前牌直接pushTransform，旋转/透视进入取样前，两半形状已发生不同的屏幕偏移，形成与用户截图一致的黑边。普通RepaintBoundary已存在，不能完成这里的坐标隔离；无需改动作素材或去掉牌面透视。

[Transform.filterQuality官方合同](https://api.flutter.dev/flutter/widgets/Transform/filterQuality.html)和本机固定Flutter3.44.7 RenderTransform.paint均确认：非null走ImageFilterLayer/矩阵滤镜，子树按原局部矩阵绘制；null才pushTransform重绘变换子树。本次运行改动仅这一项配置与版本号，shader、SDK、依赖和视频不变。该GPU图层消费现有视频纹理，没有Dart截图、第二播放器或帧切换。

## 验证

常规10文件85通过/0失败/13跳过（12既有截图跳过，1项真实shader像素测试需Impeller）；该像素测试另以 --enable-impeller 单独运行1通过。新增像素和实际layer断言在旧路径先失败，修复后通过；fatal-infos分析0，严格锁解析不改lock。

本机探针确认 `ImageFilter.isShaderFilterSupported=true`，真实加载SDK生产shader，经实际Impeller/ImageFilter管线处理非对称人物形状、细线和底边；使用独立透明矢量参考，非CPU模拟shader公式。固定同一透视/旋转条件：

| 指标 | 原取样路径 | 先合成后变换 |
|---|---:|---:|
| 异常近黑像素（RGB各小于30） | 501 | 0 |
| 非白区域平均RGB绝对误差（0–255） | 35.956 | 0.327 |

永久像素回归从真实前牌Widget读取filterQuality并加载当前SDK shader，与独立透明参考比对；旧配置实际断言501失败，新配置通过。逐16ms生命周期回归检查真正paint后的已attached ImageFilterLayer，递归包住唯一TextureLayer101，展开/收起前后同媒体State/controller，未新增create/dispose/seek/re-prime。未重新跑全量App；SDK源码无变化，+44的runtime29项作为原归属记录，不称本轮重跑。

最终+45已构建、验签和资源校验，未由Agent安装。继续交由用户远程覆盖安装，原机视频取样、文字清晰度和帧时长仍待反馈；本机headless Impeller与合成图案不代替手机GPU/SurfaceProducer验收。

## 包和证据

- APK：`E:/AII-3D/hiplab-releases/home-card-alpha-9925e3c-45-20261106/hiplab-1.1.0+45-9925e3c-internal-arm64-release.apk`；47628200字节；SHA256 `cab9c19e4b3fe17d1d3bc8f2d79f5cee28701cbd77e4f9bb7b54875fefb118d5`。
- 证书SHA256 `3761270a4764157f0e389014a9e5b800b05403bfddce0f4f7f8c039f6a53bdc7`，与+44内部包一致。com.ugk.hiplab/1.1.0/2045/release/仅arm64/非debuggable；构建56.4秒，重签runtime负载一致。
- 789项资源校验通过；r2-v1/stable、249目录动作、209授权/封面/未审AI标签、0内置MP4；原上传签名包仅本地归档。
- 检查、预期失败/修复后日志及before/after/reference PNG：`E:/AII-3D/hiplab-releases/home-card-alpha-align-20261106/`。
- 构建、验签和包回执：`E:/AII-3D/hiplab-releases/home-card-alpha-9925e3c-45-20261106/`。

+44用户报告保留为真实未解决历史，+45等待远程视觉反馈。分支已推送；main/release/tag/商店保持，本轮无设备操作、iOS、模型或实际显示FPS结论。
