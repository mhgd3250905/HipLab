# HipLab Android 会员 1.1.2+65

候选分支 `feat/membership` 从 iOS 动作库基线 `711809583cd8704db820cbcbf7cb7f4100df1131` 创建。安卓客户端参考 Flare `cbdf143`。免费用户可浏览 248 个动作、开练默认组及单个动作，也可查看、开练或删除已保存的训练组。新建、编辑、复制训练组以及 AI 问答和定制计划需要有效会员。

## Play 和 RevenueCat

| 基础方案 | 周期 | 美国定价 | Play 新客优惠 |
|---|---|---|---|
| `monthly` | `P1M` | US$2.99 | 3 天试用 |
| `annual` | `P1Y` | US$19.99 | 7 天试用 |

Play 商品为 `hip_premium`。两种试用均由 Play 判定新客资格，商品地区排除中国大陆。Hip 的 RevenueCat 项目使用匿名 App User ID、`premium` entitlement、当前 `default` offering，以及分别指向两项基础方案的 `$rc_monthly` 和 `$rc_annual`。付费页显示 Play 返回的本地价格和可购买的试用，并以展示的同一报价发起购买。使用已验证的 Play 服务账号前，先为它添加 HipLab 应用权限并在 Hip 的 RevenueCat 项目回读凭据为 Valid。

## Android 构建参数

`HIP_RC_ANDROID_KEY` 为 Hip 项目的 Android 公开 SDK Key。`HIP_AI_GATEWAY_URL` 为已部署的 HTTPS 网关地址，以 `/v1` 结尾。`POSEHUB_CATALOG_CHANNEL` 使用 `stable`。正式内测 AAB 需要真实的 Hip SDK Key 和网关地址。

AI 请求使用 `X-App: hip` 和 RevenueCat 匿名身份。Hip 网关固定 `deepseek-v4.1-flash`。试用、付费配额分别为 30 和 50 次每 UTC 日，客户端区分日配额和频率限制。网关现有 Hip 配置读取独立的 `RC_SECRET_HIP`、`UPSTREAM_BASE_URL_HIP` 和 `UPSTREAM_API_KEY_HIP`。这些值由 Worker 环境配置。远程配置完成后，以无会员身份核实 402，再通过 Play 内部测试验证购买、恢复和实际 AI 请求。

## 本地验证

Flutter 3.44.7 静态分析 0 问题。全量测试 660 通过、70 跳过、0 失败。新增的 14 项覆盖训练组门禁、付费页、购买与恢复状态、权益过期、网关身份隔离及 402/429 响应。

本地调试 AAB 通过 `bundletool validate`，确认包名 `com.ugk.hiplab`、版本码 65、Play Billing 权限。大小 116,239,402 字节，SHA-256 为 `b863ba706b9dc47e476d6f4c951b7e2813829484f3beab9c2b620788ed1e7579`。路径为 `E:/AII-3D/hiplab-releases/membership-65-local/hiplab-1.1.2+65-local-debug.aab`。当前构建的 `purchases_flutter` 仍使用 Kotlin Gradle Plugin，Flutter 3.44.7 构建成功并提示未来升级时检查该依赖。

Play 内测包、RevenueCat 凭据 Valid、Worker Version ID、在线 402 和真机交易待外部配置及验证。

## 2026-11-11 Play 内测和网关部署

构建源 `6c739c372423a911a745d7d8d3012093c9f88119` 已推送。签名 release AAB 为 `E:/AII-3D/hiplab-releases/membership-65-local/hiplab-1.1.2+65-membership-store-release.aab`，大小 99,034,816 字节，SHA-256 为 `77d4f7a51a341eef9f5883c8a99f99fd4593695dc2f2eebe6b0fafe01118936e`。通过 bundletool 和签名验证，匹配 +62 上传证书，包名 `com.ugk.hiplab`、版本码 65。

Play 显示版本 65 已面向内部测试人员发布，名单只选中 `wrist-test`（2 人）。[加入内部测试](https://play.google.com/apps/internaltest/4701079694408471816)

Play 商品 `hip_premium` 的 `monthly` 和 `annual` 已启用。美国价格分别为 US$2.99 和 US$19.99，其他支持地区由 Play 折算。两项基础方案各有 175 个 Play 支持地区，地区列表未列中国大陆。优惠 `trial-3d` 和 `trial-7d` 已启用，资格为从未在 HipLab 订阅过任何内容。

RevenueCat 的 Hip 项目已创建 Android 应用、`premium` 权益及当前 `default` offering。月付和年付分别映射 `hip_premium:monthly` 和 `hip_premium:annual`。已核对 Flare 现有 Play 凭据有效，并在 Play 为该服务账号保存 HipLab 应用范围权限。Hip 端凭据验证见下方 11 月 12 日回执。[HipLab Android 配置](https://app.revenuecat.com/projects/c2e6f2e3/apps/app6666552c0b)

网关本地类型检查通过，8 项测试通过。新版本仅新增三个 Hip secret 绑定，原绑定一致，线上版本 `c05e7d9a-5602-4797-9e67-ff601fb5b5fc` 承接 100% 流量。使用新的无权益匿名身份请求 Hip 路径实测返回 `402 not_premium`。会员模型请求待真机购买后验证。

## 2026-11-12 RevenueCat 凭据验证

已启用 Google Cloud 项目 `symmetric-sylph-514407-b2` 的 Cloud Pub/Sub API。RevenueCat 重新验证 HipLab Android 已保存的凭据，显示 **Valid credentials**，确认可读取 Play 应用内商品目录、订阅目录和基础方案。[HipLab Android 配置](https://app.revenuecat.com/projects/c2e6f2e3/apps/app6666552c0b)

Google Play 实时开发者通知尚未连接。购买、恢复和会员 AI 待真机验证。
