# ugk_trainer 接入（2026-10-20）

本轮在 `codex/adopt-ugk-trainer` 接入通用训练包。基线 HipLab `99fcc83`，SDK 起点 `9407bf3`，参考 SmartFit `0a40a45`。依赖固定 Git 提交，不使用浮动 main。用户要求完成验证后经开哥同意才合入 main；此前直接推进 main 的通用授权不替代本轮最终同意。

## 实现边界

训练播放界面、活动时钟、相位执行、语音队列/音频输出、Android 前台服务由 `ugk_trainer` 提供。App 删除自身 `TrainingSessionService` 与 `hiplab/training_session` 通道；自测保活适配和屏幕常亮也复用包的 owner/引用计数。

HipLab 保留课程名开场、按剂量文字找台词、D-01 紧侧剂量与整侧多组顺序、自测。`HipSessionBuilder` 将 App 编排转换为包的真实逐组相位，`HipSessionScript` 在包通用脚本上补专有台词。旧语音测试接口保留为适配视图，时钟和播放队列调用包实现。

疼痛阶梯仍在 App，通过 `onDiscomfort` 返回减量后的相位、替代或方向过滤；麻刺放射痛结束训练。动作间感受由包反馈插槽展示，完成页由 `feedbackBuilder` 展示 App 说明。单练再练复用包播放页状态，但使用新的会话 ID 和服务 owner。

训练保存接 `SessionResult`，按 `sessionId` 幂等写入，存储失败保留重试。旧记录格式可读，新记录保留完整 SDK 结果和感受，训练时长使用实际活动时间；全跳过及单练不累计连续天数。

## SDK 修复与扩展

问题在 SDK 仓库分支 `codex/hiplab-trainer-slots` 修复：通用相位构建/脚本/剂量/反馈插槽、疼痛后替换剩余相位、同页再练、实际完成计数及不对称侧组记录。不在 App 复制另一份通用执行器。

## 验证和交付

正在执行原语音时序回归、App 测试和 SDK 回归。最终提交、测试数量、构建、APK 身份、安装与真机耳机锁屏结果在完成后追加；未执行项目不记为通过。用户已确认测试包准备后可配合手机与耳机。

本轮不上传商店，不改商店配置，覆盖安装保留数据；iOS 构建/真机未验。主线合并和推送等待开哥本轮最终同意。
