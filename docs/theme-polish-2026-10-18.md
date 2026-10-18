# 浅色 / 深色样式统一（2026-10-18）

版本 **0.3.6+11**，业务源码 `66f5da034c0cdac3341f3e80a57e3ddae5f95dce`。此前审查见[验证台账](verification.md#浅色--深色样式核对2026-10-18main-a60b623)。本轮4项代码修复和网页复查已完成，Android debug arm64 APK 已构建，**未安装手机、未上传商店**；手机仍为用户确认试听正常的0.3.5+10。

## 改动

- 首页时长/场景选择器去掉 standalone 浅绿平铺特例，使用浅灰轨道、白色滑块、接触与环境两层轻阴影；保留同心圆角、弹性滑动、点击/拖动/键盘选择。设置语言/外观继续使用同一控件，深色滑块和轨道保持原配色。
- 隐私政策使用 SafeArea + HipTopBar + Expanded(ListView)，统一返回图标、标题和页背景；顶部固定，正文仍可滚动，保留系统返回、“返回”语义和复制链接。隐私文字及链接未变。
- 新增 HipColors.jadeText：浅色用既有 jadeDeep，深色用原 jade。用于普通背景上的引导/自测标题、选项、序号、推荐说明、进度摘要、底部选中标签和文字按钮；媒体上的文字、jade 填充和亮色装饰保持。
- 引导和设置的12px运动说明由 faint 改为 muted。浅色绿色文字对白底对比约6.23、选项浅绿底约5.47；说明对背景约5.43。禁用控件仍保留禁用表现。

## 验证

`flutter analyze --no-pub` 0问题；`flutter test --no-pub --concurrency=1 --reporter expanded` **158 pass / 1条件skip**（VOICE_TIMELINE_OUT未设置）。现有流程包含主题实时切换、选择器滑动/拖动/键盘、自测六项单屏和大字号、隐私滚到底复制再返回；隐私专项8项通过。独立静态复核确认隐私原文和媒体叠层保留。

网页预览从本轮33个Dart源码构建，和主线逐文件一致（入口注入 HipVoice.silent，媒体为项目原有web海报stub）。390×844核对浅/深首页、浅色设置、引导和隐私；自测选中态在 **320×568、360×740、390×844、768×1024** 截图中均完整单屏、方形示范不裁切。隐私页另做320窄屏检查，返回功能由既有测试验证。网页复查不代替Android/iPhone真机、原生视频/声音及完整无障碍验收。

本轮不改音频播放代码、pubspec.lock、依赖、素材版本或ios配置；不执行ADB。此前0.3.5+10完整试听的用户确认保持历史，不算0.3.6+11已安装验收。

## APK 身份

| 项目 | 结果 |
|---|---|
| 版本 / ABI | 0.3.6+11 / debug arm64-v8a |
| 包名 | com.ugk.hiplab |
| 源码 | 66f5da034c0cdac3341f3e80a57e3ddae5f95dce |
| APK | `E:/AII-3D/hiplab-releases/theme-polish-20261018/hiplab-0.3.6+11-debug-arm64.apk` |
| 大小 / SHA-256 | 150,886,340 bytes / `78e766d76a083a519d703a88001a26cbfe8d8193d55125b2393f5a1d80ceb4f8` |
| 签名 | apksigner验证通过；debug证书 `3761270a4764157f0e389014a9e5b800b05403bfddce0f4f7f8c039f6a53bdc7`，与既有安装连续 |
| 资源 | 包内114媒体/静图、zh244/en244语音和5提示音逐文件SHA与源码资源一致 |
| 安装 / 发布 | 未安装 / 未上传 |

本机截图及日志：`E:/AII-3D/3D-Hip/build/theme-fix-20261018/`，包括 analyze.log、test.log、web-build.log、apk-build.log、apk-identity.json及截图；属于忽略目录，不在Git远端备份。

## 安装追加（2026-10-18）

19:29按用户明确要求把上述APK覆盖安装到2602BRT18C / Android16；安装返回Success，versionName0.3.6/versionCode11回读通过，MainActivity resumed，冷启动首页浅色浮起滑块已查看。此前“未安装”保留为构建阶段历史，此处补齐实际安装状态；未重新构建或上传。

安装前备份当前1356字节偏好及4,204,032字节可读数据tar（shared_prefs, files, no_backup），安装/启动/截图后偏好逐字节保持，SHA-256 `b4ac5a3817155431b4a0b445fd12d8941852ea99fafd86956f0da153a505a5a4`。没有恢复旧备份、清数据或进入训练/自测；未切换用户主题。旧0.3.5+10的听音确认不能替代本版重新听音。用户数据、截图与报告保存在`E:/AII-3D/hiplab-releases/theme-polish-20261018/install-20261018/`，不在Git远端备份。
