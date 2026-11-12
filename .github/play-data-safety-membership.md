# HipLab Android 会员版 Play 数据安全表草案

适用候选为 `com.ugk.hiplab` 的 `1.1.2+67`。Play 当前表单的收集或分享总开关为「否」。将总开关改为「是」，并按下表填写。Google 要求以所有适用分发轨道上的行为合并申报，以下按 +67 进入适用轨道后的数据流拟定。Google Play 直接处理的支付卡资料不会传给 HipLab，无需为该应用申报支付卡资料。[Google Play 填表指南](https://support.google.com/googleplay/android-developer/answer/10787469)

| Play 数据类型 | 收集 | 分享 | 用途 | 用户可选 | 加密传输 | 临时处理 |
| --- | --- | --- | --- | --- | --- | --- |
| 财务信息 → 购买记录 | 是。交易凭证、商品、购买及有效期、试用或续订状态由 RevenueCat 处理，网关按需查询权益 | 否，按 Google Play 和 RevenueCat 作为支付或订阅处理服务、且无额外接收方的当前集成判断 | 应用功能、分析 | 否。按 RevenueCat 指南，会员版的购买记录处理无关闭开关 | 是 | 否 |
| 设备 ID 或其他 ID | 是。RevenueCat 自动生成的应用级标识。AI 网关还处理用于限流的 IP 及其派生键 | 否，按 RevenueCat 和 Cloudflare 受托处理判断。网关不向模型服务转发原始订阅标识或客户端 IP | 应用功能、分析（订阅统计）、防欺诈及安全（限流） | 否。启动与回前台会查会员。AI 所用 IP 限流为主动使用时发生 | 是 | 否 |
| 消息 → 其他应用内消息 | 是。用户输入、相关对话和当前对话上下文随模型请求发送 | 按「是」拟报，待核实模型服务商是否只按 HipLab 指示处理且不用于自身目的。满足 Google 服务提供商例外时可填「否」 | 应用功能。供应商若有独立用途，按核实结果追加 | 是。不使用 AI 仍可训练、自测 | 是 | 按「否」拟报。仅在确认全链路只在内存中、仅为实时响应保留时改为「是」 |
| 健康与健身 → 健康信息 | 是。AI 对话中填写的疼痛、伤病或恢复情况，包含 AI 可能发起的安全追问；应用的本机自测及训练反馈不自动上传 | 与其他应用内消息相同 | 应用功能 | 是 | 是 | 与其他应用内消息相同 |
| 健康与健身 → 健身信息 | 是。AI 对话中主动提供的练习目标、训练背景或限制等健身信息；本机训练记录不自动上传 | 与其他应用内消息相同 | 应用功能 | 是 | 是 | 与其他应用内消息相同 |
| 应用活动 → 应用互动 | 是。网关记录 AI 请求计数、所属时间窗口及派生键，执行每日额度与分钟级防滥用限制 | 否，按 Cloudflare 受托处理判断。计数不发送给模型服务 | 应用功能、防欺诈及安全 | 是。主动使用 AI 时产生 | 是 | 否。计数写入 Durable Objects |

## 送审前核对

- **模型服务。** 从非凭据的服务台账或合同核实实际接收方、保留期限、是否用于训练或其他自身目的，以及删除方式。模型名称不足以确认服务商。将结果补入公开政策并据实敲定表中分享、用途和临时处理项。若在线 AI 对话或健康信息的第三方处理超出用户合理预期，核对应用内在发送前的披露与同意。[Google Play 用户数据政策](https://support.google.com/googleplay/android-developer/answer/10144311)
- **网关和素材托管。** 源码只记录通用错误，版本库配置关闭调用日志和追踪。公开政策已披露服务方可能处理网络或错误元数据。填表前核对线上实际日志、保留和处理方。若另有可关联用户的诊断或素材互动日志，补充相应类型、用途和可选性。[Cloudflare Workers Logs](https://developers.cloudflare.com/workers/observability/logs/workers-logs/)
- **加密和删除。** 当前候选的订阅、AI 和公共素材网络链路使用 HTTPS，设备内媒体回环不向外传输。现有隐私联系邮箱可受理询问。选择 Play 的「提供数据删除请求方式」前，应确认实际流程可验证请求者并定位可删除记录，明确商店保留例外，以及如何处理网关计数和模型服务数据。[RevenueCat 填表指南](https://www.revenuecat.com/docs/platform-resources/google-platform-resources/google-plays-data-safety)

## 源码证据

- [HipLab +67 会员与订阅初始化](https://github.com/mhgd3250905/HipLab/blob/f42b79b7586cae066b7cd6cbc52c94da77d45781/lib/hip/platform/hip_revenuecat.dart) · [启动与回前台的权益检查](https://github.com/mhgd3250905/HipLab/blob/f42b79b7586cae066b7cd6cbc52c94da77d45781/lib/hip/ui/hip_app.dart) · [AI 请求身份](https://github.com/mhgd3250905/HipLab/blob/f42b79b7586cae066b7cd6cbc52c94da77d45781/lib/hip/coach/membership_gateway.dart)
- [固定 SDK 的对话组装](https://github.com/mhgd3250905/ugk-3d-pose-sdk/blob/7cd1c4392dc4114729f8f4301d3df2848524e6a3/lib/src/qa_v2/coach_qa_agent.dart) · [SDK 的健康条件和安全追问规则](https://github.com/mhgd3250905/ugk-3d-pose-sdk/blob/7cd1c4392dc4114729f8f4301d3df2848524e6a3/lib/src/qa_v2/coach_qa_sop.md)
- [网关转发、标识派生与限额](https://github.com/mhgd3250905/ugk-ai-gateway/blob/006e5eaedbfb913f9552bef2c7fa0f9a52838163/src/index.ts) · [权益缓存及计数存储](https://github.com/mhgd3250905/ugk-ai-gateway/blob/006e5eaedbfb913f9552bef2c7fa0f9a52838163/src/counter.ts) · [网关版本库配置](https://github.com/mhgd3250905/ugk-ai-gateway/blob/006e5eaedbfb913f9552bef2c7fa0f9a52838163/wrangler.jsonc)
