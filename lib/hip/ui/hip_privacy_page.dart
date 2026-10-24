import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../coach/coach_config.dart';
import 'hip_theme.dart';
import 'hip_icons.dart';
import 'hip_widgets.dart';

/// Bundled policy remains readable without an internet connection.
class HipPrivacyPage extends StatelessWidget {
  const HipPrivacyPage({super.key});

  static const policyUrl = 'https://mhgd3250905.github.io/HipLab/';

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Column(
        children: [
          const HipTopBar(title: '隐私政策', icon: HipGlyph.back, tooltip: '返回'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: [
                const Text(
                  '开胯训练助手 HipLab',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  '开发者：Bboy Ug1yk\n更新日期：2026 年 10 月 24 日',
                  style: TextStyle(color: HipColors.muted, height: 1.6),
                ),
                const SizedBox(height: 20),
                _PolicySection(
                  title: '我们如何处理你的信息',
                  body:
                      '本应用无需账号，不含广告、行为分析或支付功能。'
                      '日常训练和自测记录保存在本机，不会自动上传。'
                      '${CoachConfig.fromEnvironment.configured ? '只有你主动使用 AI 定制时，才会向 AI 服务发送请求。' : '此基础版不启用在线 AI 或云端同步，不向开发者服务器发送训练记录。'}',
                ),
                const _PolicySection(
                  title: '只在设备上保存的记录',
                  body:
                      '安全提示的回答、训练身份选择、自测结果（包括疼痛反馈）、'
                      '训练日期、疼痛与麻木反馈、提醒时间和训练偏好，'
                      '通过 SharedPreferences 保存在设备的应用私有存储中。'
                      '这些信息用于本机生成练习建议、显示进度和调整训练安排。'
                      '本应用没有开发者运营的云端账号或同步服务。',
                ),
                const _PolicySection(
                  title: '保留、删除与系统备份',
                  body:
                      '记录会保留在设备上，直到你通过系统设置清除应用存储或卸载应用。'
                      '卸载会清除本机应用数据；Android 系统可能根据设备设置备份并在重新安装时恢复数据。'
                      '本应用未禁用系统备份。你可以在设备的系统备份设置中管理相关备份。'
                      '我们无法访问或代你删除设备及系统备份中的记录。',
                ),
                if (CoachConfig.fromEnvironment.configured)
                  const _PolicySection(
                    title: 'AI 定制与设备标识',
                    body:
                        '使用 AI 定制时，你输入的需求和当前对话会发送给 AI 服务生成计划。'
                        '请求会附带首次启动时随机生成并保存在本机的安装标识，用于识别设备请求。'
                        '该标识不是手机硬件序列号。App 不会自动发送本机自测结果或训练历史。',
                  )
                else
                  const _PolicySection(
                    title: 'AI 入口与本地预设',
                    body:
                        '此基础版保留 AI 定制入口，但不启用在线 AI。'
                        '你在该页面输入的需求仅在本机匹配内置预设方案和安全提示，'
                        '不会向 AI 服务发送对话，也不会为该功能新建安装标识。'
                        '本地预设会明确标注，不是 AI 生成的计划。',
                  ),
                _PolicySection(
                  title: '视频、网络与权限',
                  body:
                      '动作视频随应用内置，可以离线播放。Android 的网络权限用于 '
                      '127.0.0.1 本机媒体服务，让播放器读取内置素材。'
                      '${CoachConfig.fromEnvironment.configured ? '网络权限也用于你主动使用的 AI 定制请求。' : ''}'
                      '应用不访问相机、麦克风、联系人或位置。',
                ),
                const _PolicySection(
                  title: '训练语音与后台播放',
                  body:
                      '你主动开始训练后，应用使用媒体播放前台服务和唤醒锁，'
                      '让训练语音在锁屏或切换应用时继续播放，并显示训练通知。'
                      '训练结束或退出训练后停止服务并移除训练通知。'
                      '应用不通过麦克风录制声音，也不读取耳机或蓝牙设备标识。',
                ),
                const _PolicySection(
                  title: '运动与健康提示',
                  body:
                      '本应用提供一般健身和髋部活动练习，不是医疗器械，'
                      '不能诊断、治疗、治愈或预防疾病，不能替代医生的建议。'
                      '如有疼痛、麻木或其他不适，请停止练习并咨询医生或专业人士。',
                ),
                const _PolicySection(
                  title: '政策更新与联系',
                  body:
                      '如数据处理方式发生变化，我们会更新本页和公开隐私政策。'
                      '隐私问题请联系开发者：mhgd3250905@gmail.com。\n'
                      '也可以通过 HipLab GitHub 仓库 Issues 联系：\n'
                      'https://github.com/mhgd3250905/HipLab/issues',
                ),
                HipPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '公开隐私政策',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const SelectableText(policyUrl),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        key: const ValueKey('copy-privacy-url'),
                        onPressed: () async {
                          await Clipboard.setData(
                            const ClipboardData(text: policyUrl),
                          );
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('已复制隐私政策链接')),
                          );
                        },
                        icon: const HipIcon(HipGlyph.copy),
                        label: const Text('复制链接，在浏览器中查看'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _PolicySection extends StatelessWidget {
  const _PolicySection({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        SelectableText(body, style: const TextStyle(height: 1.65)),
      ],
    ),
  );
}
