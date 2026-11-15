# HipLab Android 会员版 Play 数据安全勾选清单

适用于 `com.ugk.hiplab` 的 `1.1.2+68`。收集或分享总开关选择「是」，并按下表填写。申报范围覆盖所有适用分发轨道上的版本。支付卡资料由 Google Play 直接处理，无需为 HipLab 申报。[Google Play 填表指南](https://support.google.com/googleplay/android-developer/answer/10787469)

| Play 数据类型 | 收集 | 分享 | 用途 | 用户可选 | 加密传输 | 临时处理 |
| --- | --- | --- | --- | --- | --- | --- |
| 财务信息 → 购买记录 | 是。交易凭证、商品、购买及有效期、试用或续订状态由 RevenueCat 处理，网关按需查询权益 | 否，按 Google Play 和 RevenueCat 作为支付或订阅处理服务、且无额外接收方的当前集成判断 | 应用功能、分析 | 否。按 RevenueCat 指南，会员版的购买记录处理无关闭开关 | 是 | 否 |
| 设备 ID 或其他 ID | 是。RevenueCat 自动生成的应用级标识。AI 网关还处理用于限流的 IP 及其派生键 | 否，按 RevenueCat 和 Cloudflare 受托处理判断。网关不向模型服务转发原始订阅标识或客户端 IP | 应用功能、分析（订阅统计）、防欺诈及安全（限流） | 否。启动与回前台会查会员。AI 所用 IP 限流为主动使用时发生 | 是 | 否 |
| 消息 → 其他应用内消息 | 是。用户输入、相关对话和当前对话上下文随模型请求发送 | 是 | 应用功能 | 是。基础训练和自测可独立使用 | 是 | 否 |
| 健康与健身 → 健康信息 | 是。AI 对话中填写的疼痛、伤病、恢复情况和安全追问的回答。本机自测及训练反馈由应用保存在设备上 | 是 | 应用功能 | 是 | 是 | 否 |
| 健康与健身 → 健身信息 | 是。AI 对话中主动提供的练习目标、训练背景或限制等健身信息。本机训练记录由应用保存在设备上 | 是 | 应用功能 | 是 | 是 | 否 |
| 应用活动 → 应用互动 | 是。网关记录 AI 请求计数、所属时间窗口及派生键，执行每日额度与分钟级防滥用限制 | 否，按 Cloudflare 受托处理判断。计数不发送给模型服务 | 应用功能、防欺诈及安全 | 是。主动使用 AI 时产生 | 是 | 否。计数写入 Durable Objects |

## 填写说明

- **AI 同意与撤回。** 首次使用 AI 前，应用要求用户明确同意。用户可选择暂不使用，或在应用内「隐私政策」撤回同意。撤回后，应用暂停发送新的 AI 请求，下次使用时重新询问。基础训练和自测无需同意 AI 数据共享。
- **模型服务。** AI 对话及其中的健康与健身信息经网关转给第三方大语言模型服务商（当前使用 DeepSeek 模型）。这三项统一填写「分享：是」和「临时处理：否」。[Google Play 用户数据政策](https://support.google.com/googleplay/android-developer/answer/10144311)
- **网关日志。** 源码只记录通用错误，版本库配置关闭调用日志和追踪。公开政策披露 Cloudflare 可能为传输、安全和诊断处理连接或错误元数据。[Cloudflare Workers Logs](https://developers.cloudflare.com/workers/observability/logs/workers-logs/)
- **加密和删除。** 订阅、AI 和公共素材链路使用 HTTPS。设备内媒体回环仅在设备上运行。隐私联系邮箱用于受理查询和删除请求。购买、续订或退款由原商店处理。[RevenueCat 填表指南](https://www.revenuecat.com/docs/platform-resources/google-platform-resources/google-plays-data-safety)

## 源码证据

- [HipLab +68 会员与订阅初始化](https://github.com/mhgd3250905/HipLab/blob/a21cb400843623f437d78dde176780768222f8a0/lib/hip/platform/hip_revenuecat.dart) · [启动与回前台的权益检查](https://github.com/mhgd3250905/HipLab/blob/a21cb400843623f437d78dde176780768222f8a0/lib/hip/ui/hip_app.dart) · [AI 请求身份及同意检查](https://github.com/mhgd3250905/HipLab/blob/a21cb400843623f437d78dde176780768222f8a0/lib/hip/coach/membership_gateway.dart)
- [首次 AI 同意及撤回的本地状态](https://github.com/mhgd3250905/HipLab/blob/a21cb400843623f437d78dde176780768222f8a0/lib/hip/control/hip_ai_consent.dart) · [隐私政策中的撤回入口](https://github.com/mhgd3250905/HipLab/blob/a21cb400843623f437d78dde176780768222f8a0/lib/hip/ui/hip_privacy_page.dart)
- [固定 SDK 的对话组装](https://github.com/mhgd3250905/ugk-3d-pose-sdk/blob/7cd1c4392dc4114729f8f4301d3df2848524e6a3/lib/src/qa_v2/coach_qa_agent.dart) · [SDK 的健康条件和安全追问规则](https://github.com/mhgd3250905/ugk-3d-pose-sdk/blob/7cd1c4392dc4114729f8f4301d3df2848524e6a3/lib/src/qa_v2/coach_qa_sop.md)
- [网关转发、标识派生与限额](https://github.com/mhgd3250905/ugk-ai-gateway/blob/006e5eaedbfb913f9552bef2c7fa0f9a52838163/src/index.ts) · [权益缓存及计数存储](https://github.com/mhgd3250905/ugk-ai-gateway/blob/006e5eaedbfb913f9552bef2c7fa0f9a52838163/src/counter.ts) · [网关版本库配置](https://github.com/mhgd3250905/ugk-ai-gateway/blob/006e5eaedbfb913f9552bef2c7fa0f9a52838163/wrangler.jsonc)
