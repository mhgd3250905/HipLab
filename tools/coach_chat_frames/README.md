# HipLab SDK 对话页审阅截图

使用真实 `hiplabCoachAppProfile`、HipLab 配色/字体/本地剪影和未改写的 SDK
`CoachChatController` / `CoachChatPage`，生成浅色与深色各五张 390×844 截图：
空态、等待、计划卡、推荐卡、失败。只用于用户目视审阅，不执行像素对比。

使用 Flutter **3.44.7 stable**，显式加载 NotoSansSC 与 MaterialIcons，
在仓库根目录运行：

```powershell
$env:CHAT_CAPTURE_OUTPUT = 'E:/AII-3D/hiplab-releases/coach-chat-sdk-20261102/screens'
flutter test --no-pub tools/coach_chat_frames/capture_test.dart --reporter expanded
python tools/coach_chat_frames/contact_sheet.py --input $env:CHAT_CAPTURE_OUTPUT
```

可用 `CHAT_CAPTURE_FRAMES` 选择逗号分隔的帧名，例如
`light-empty,dark-plan-card`。工具只写目标目录中的指定 PNG 和
`capture-manifest.json`，不清理其他产物。

等待态来自真正挂起的 `FakeLlmClient` 请求；计划与推荐通过 SDK 正常快照恢复和
门禁，失败态来自明确模拟的 HTTP 400。没有访问真实模型，没有新增 App fixture 分支、
对话逻辑或 controller 子类。所有截图均不是原生设备、性能或真实模型验证证据；
逐帧来源在清单中记录。
