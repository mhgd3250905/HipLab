# 恢复点按与上下翻牌退场 · +49 · 2026-11-06

运行/构建源 `8475c71f2bdb2eb69456c7fe400fe4f594f1d7b0`，分支 `codex/home-card-exit-easing-20261106`；`1.1.0+49` / arm64 `2049`。SDK仍 `b4861c5215280c49bffe03b8c203074217dcf995`，pubspec.lock字节保持。日常目录 `feat/ui-detail-polish@25260b3` 保持clean。

按用户新指令撤回+48第2项：完整删除RawLongPress、300ms识别、contact controller、轻抬/吸附矩阵及相关语义，恢复原GestureDetector/onTapUp。按住不抬升，未拖动松手按原点按处理；按住后仍可普通拖动。+48首展播放门控和固定文字画布、同一视频/当前帧收起、静默准备均保留。

上下退场偏快的源码路径为远处目标对弹簧施加过大初始拉力。改用当前投影AABB沿释放射线到屏幕边缘的剩余距离+48pt余量；保留最后一次move尚未build时的平移补偿。stiffness从水平240连续插值至竖直60，阻尼为2√k，沿射线起始速度上限从2400连续降至900。全向阈值、顺序、补牌和离场射线保持；牌面完全离屏后仍及时提交，不增加看不见的等待尾程。

## 验证

相关10文件95通过/0失败/13跳过（12既有截图项+1需Impeller）；真实shader像素回归另串行1通过，fatal-infos分析0，严格离线锁解析保持lock。牌组44项覆盖按住500ms矩阵不变/松手点按展开/原媒体State保持、按住后普通拖动取消和提交、上下各150pt释放后80/120ms有界推进且200ms仍可见、八方向射线、真实四角投影离屏后两帧内解锁、单牌/减少动画、身份/窗口/主题/顺序等原有回归。

原离屏测试用getRect对角点误判斜牌的可见范围，本轮改为四角投影AABB后重跑通过。原始检查与最终结果在 `E:/AII-3D/hiplab-releases/home-card-exit-easing-20261106/`。未重跑全量App/SDK，SDK本轮未改。组件/fake平台及headless Impeller是本地回归证据，不代替原机实际手感、原生播放/iOS或显示FPS验收。

## 交付

| 项目 | 事实 |
|---|---|
| APK | `E:/AII-3D/hiplab-releases/home-card-eased-8475c71-49-20261106/hiplab-1.1.0+49-8475c71-internal-arm64-release.apk` |
| 大小 / SHA256 | 47628200字节 / `60001fa75ebb74c8e68a75c4b3c195dc8b1f814c1333ff88a1cd0a9a6e6fa8d8` |
| 证书SHA256 | `3761270a4764157f0e389014a9e5b800b05403bfddce0f4f7f8c039f6a53bdc7`，与+48内部包一致 |
| 身份 | com.ugk.hiplab/1.1.0/2049/release/仅arm64/非debuggable；构建67.9秒；重签runtime负载一致 |
| 内容 | 789资源项校验通过；r2-v1/stable、249目录动作、209授权/封面/未审AI标签、0内置MP4 |

验包回执、原上传签名归档和最终内部包留同一E盘目录。Agent未安装；交用户远程覆盖测试，重点确认上/下松手后的连贯退场和恢复后的触摸行为。App候选已推送，main/release/tag/商店及本地设备保持。
