import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'hip_theme.dart';
import 'hip_icons.dart';
import 'hip_widgets.dart';

/// Bundled policy remains readable without an internet connection.
class HipPrivacyPage extends StatelessWidget {
  const HipPrivacyPage({super.key});

  static const policyUrl = 'https://mhgd3250905.github.io/HipLab/';
  static const iosPolicyUrl = 'https://mhgd3250905.github.io/HipLab/ios/';

  static bool _isIOS(BuildContext context) =>
      Theme.of(context).platform == TargetPlatform.iOS;

  static String _publicPolicyUrl(BuildContext context) =>
      _isIOS(context) ? iosPolicyUrl : policyUrl;

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
                  _isIOS(context)
                      ? '开发者：Bboy Ug1yk\n更新日期：2026 年 10 月 18 日'
                      : '开发者：Bboy Ug1yk\n更新日期：2026 年 10 月 17 日',
                  style: TextStyle(color: HipColors.muted, height: 1.6),
                ),
                const SizedBox(height: 20),
                const _PolicySection(
                  title: '我们如何处理你的信息',
                  body:
                      '本应用无需账号，不含广告、行为分析或支付功能。'
                      '我们不收集、上传、出售或与第三方共享你的个人信息和健康相关记录。',
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
                _PolicySection(
                  title: '保留、删除与系统备份',
                  body: _isIOS(context)
                      ? '记录保存在设备的应用私有存储中。iOS 的“删除 App”会移除应用及其本地相关数据；'
                            '“卸载 App”可能保留文稿与数据。iOS、iCloud 或电脑备份可能根据你的设置包含应用数据，'
                            '重新安装或迁移后可能恢复记录。删除 App 不保证清除已有备份，'
                            '请在对应系统或备份服务中管理。开发者无法读取或代你删除这些备份。'
                      : '记录会保留在设备上，直到你通过系统设置清除应用存储或卸载应用。'
                            '卸载会清除本机应用数据；Android 系统可能根据设备设置备份并在重新安装时恢复数据。'
                            '本应用未禁用系统备份。你可以在设备的系统备份设置中管理相关备份。'
                            '我们无法访问或代你删除设备及系统备份中的记录。',
                ),
                _PolicySection(
                  title: '视频、网络与权限',
                  body: _isIOS(context)
                      ? '动作视频与语音随应用提供，本机媒体服务仅绑定 127.0.0.1，'
                            '供内嵌播放器读取素材，不用于向外部上传记录。iOS 可能显示无线数据使用提示；'
                            '系统弹窗本身不代表向开发者上传数据。应用不请求相机、麦克风、联系人、'
                            '位置或照片访问，也不通过 HealthKit 读取或写入健康数据。'
                      : '动作视频随应用内置，可以离线播放。Android 的网络权限用于 '
                            '127.0.0.1 本机媒体服务，让播放器读取内置素材。'
                            '应用本身不向外部服务器上传你的记录，不访问相机、麦克风、联系人或位置。',
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
                      SelectableText(_publicPolicyUrl(context)),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        key: const ValueKey('copy-privacy-url'),
                        onPressed: () async {
                          await Clipboard.setData(
                            ClipboardData(text: _publicPolicyUrl(context)),
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
