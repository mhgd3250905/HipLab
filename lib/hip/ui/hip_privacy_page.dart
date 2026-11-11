import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../coach/coach_config.dart';
import 'hip_theme.dart';
import 'hip_icons.dart';
import 'hip_page_kit.dart';
import 'hip_widgets.dart';
import 'hip_text.dart';

/// Bundled policy remains readable without an internet connection.
class HipPrivacyPage extends StatelessWidget {
  const HipPrivacyPage({super.key});

  static const policyUrl = 'https://mhgd3250905.github.io/HipLab/';
  static const iosPolicyUrl =
      'https://mhgd3250905.github.io/HipLab/ios/hipinterlude/';

  @override
  Widget build(BuildContext context) {
    final ios = Theme.of(context).platform == TargetPlatform.iOS;
    final publicPolicyUrl = ios ? iosPolicyUrl : policyUrl;
    return HipNavPage(
      title: HipText.of(context).pick('隐私政策', 'Privacy policy'),
      leadingKey: const ValueKey('privacy-back'),
      bodyScrollsUnderBar: true,
      body: ListView(
        padding: EdgeInsets.fromLTRB(20, hipNavInset(context) + 12, 20, 32),
        children: [
          Text(
            HipText.of(
              context,
            ).pick('开胯训练助手 HipLab', 'HipLab · Hip mobility training'),
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            HipText.of(context).pick(
              '开发者：Bboy Ug1yk\n更新日期：2026 年 11 月 5 日',
              'Developer: Bboy Ug1yk\nUpdated: November 5, 2026',
            ),
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
          _PolicySection(
            title: '保留、删除与系统备份',
            body:
                '记录会保留在设备上，直到你通过系统设置清除应用存储或卸载应用。'
                '卸载会清除本机应用数据；'
                '${Theme.of(context).platform == TargetPlatform.iOS ? 'iOS' : 'Android'} 系统可能根据设备设置备份并在重新安装时恢复数据。'
                '本应用未禁用系统备份。你可以在设备的系统备份设置中管理相关备份。'
                '我们无法访问或代你删除设备及系统备份中的记录。',
          ),
          if (CoachConfig.fromEnvironment.configured)
            _PolicySection(
              title: 'AI 定制与设备标识',
              body:
                  '使用 AI 定制时，你输入的需求和当前对话会发送给 AI 服务生成计划。'
                  '${ios ? (CoachConfig.fromEnvironment.authMode == 'worker' ? '请求会附带首次使用时随机生成并保存在本机的安装标识，用于识别设备请求。该标识不是手机硬件序列号。' : '此连接模式不附带 AI 安装标识。') : '请求会附带首次启动时随机生成并保存在本机的安装标识，用于识别设备请求。该标识不是手机硬件序列号。'}'
                  'App 不会自动发送本机自测结果或训练历史。',
            )
          else
            const _PolicySection(
              title: '在线 AI 未启用',
              body:
                  '此版本未配置 AI 凭据，AI 定制及用量入口均隐藏。'
                  '不会向 AI 服务发送对话，也不会为该功能新建安装标识。',
            ),
          _PolicySection(
            title: '视频、网络与权限',
            body:
                '动作目录与封面随应用提供。动作视频从公共素材服务按需下载并缓存在设备上；'
                '开始训练前可能需要联网准备视频，尚未缓存的视频在离线时可能无法播放。'
                '网络也用于检查公共动作目录和素材更新。'
                '${ios ? '媒体请求包含网络连接所需的 IP 地址及资源路径，不附带训练记录、自测结果或 AI 安装标识。' : ''}'
                '${CoachConfig.fromEnvironment.configured ? '网络权限也用于你主动使用的 AI 定制请求。' : ''}'
                '应用不访问相机、麦克风、联系人或位置。',
          ),
          _PolicySection(
            title: '训练语音与后台播放',
            body: Theme.of(context).platform == TargetPlatform.iOS
                ? '你主动开始训练或语音自测后，应用使用 iOS 后台音频播放训练口令、倒数和换边提示。'
                      '训练或自测结束、退出后停止播放并释放音频会话；关闭人声和提示音时不启用后台音频。'
                      '设置中的试听只在前台短时播放，完成、离开或切到后台时结束并释放音频会话。'
                      '应用不通过麦克风录制声音，也不读取耳机或蓝牙设备标识。'
                : '你主动开始训练后，应用使用媒体播放前台服务和唤醒锁，'
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
                Text(
                  HipText.of(context).pick('公开隐私政策', 'Public privacy policy'),
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                SelectableText(publicPolicyUrl),
                const SizedBox(height: 8),
                TextButton.icon(
                  key: const ValueKey('copy-privacy-url'),
                  onPressed: () async {
                    await Clipboard.setData(
                      ClipboardData(text: publicPolicyUrl),
                    );
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          HipText.of(
                            context,
                          ).pick('已复制隐私政策链接', 'Privacy policy link copied'),
                        ),
                      ),
                    );
                  },
                  icon: const HipIcon(HipGlyph.copy),
                  label: Text(
                    HipText.of(
                      context,
                    ).pick('复制链接，在浏览器中查看', 'Copy link to open in a browser'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
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
          HipText.of(context).pick(title, _privacyTitles[title] ?? title),
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        SelectableText(
          HipText.of(context).pick(body, _privacyBody(context, title)),
          style: const TextStyle(height: 1.65),
        ),
      ],
    ),
  );
}

const _privacyTitles = <String, String>{
  '我们如何处理你的信息': 'How we handle your information',
  '只在设备上保存的记录': 'Records stored only on your device',
  '保留、删除与系统备份': 'Retention, deletion and system backups',
  'AI 定制与设备标识': 'AI training and installation identifier',
  '在线 AI 未启用': 'Online AI is not enabled',
  '视频、网络与权限': 'Video, network access and permissions',
  '训练语音与后台播放': 'Training audio and background playback',
  '运动与健康提示': 'Exercise and health notice',
  '政策更新与联系': 'Policy updates and contact',
};

String _privacyBody(BuildContext context, String section) {
  final configured = CoachConfig.fromEnvironment.configured;
  final ios = Theme.of(context).platform == TargetPlatform.iOS;
  final platform = ios ? 'iOS' : 'Android';
  return switch (section) {
    '我们如何处理你的信息' =>
      'No account is required. This app contains no advertising, behavioral analytics or payment features. '
          'Your routine training and check-up records stay on your device and are not uploaded automatically. '
          '${configured ? 'Requests are sent to the AI service only when you choose to use AI training.' : 'This basic edition does not enable online AI or cloud sync and does not send training records to a developer server.'}',
    '只在设备上保存的记录' =>
      'Your safety answers, training profile, check-up results (including pain feedback), training dates, '
          'pain and numbness feedback, reminder times and training preferences are stored in the app’s private '
          'on-device storage using SharedPreferences. This information is used locally to suggest exercises, '
          'show progress and adjust your training. The app has no developer-operated cloud account or sync service.',
    '保留、删除与系统备份' =>
      'Records remain on your device until you clear the app’s storage in system settings or uninstall the app. '
          'Uninstalling removes local app data. Depending on your device settings, $platform may back up data '
          'and restore it when you reinstall. This app has not disabled system backups. You can manage backups '
          'in your device’s system backup settings. We cannot access or delete records on your device or '
          'in system backups on your behalf.',
    'AI 定制与设备标识' =>
      'When you use AI training, your request and current conversation are sent to the AI service to generate a plan. '
          '${ios && CoachConfig.fromEnvironment.authMode != 'worker' ? 'This connection mode does not attach an AI installation identifier. ' : 'Requests include an installation identifier generated randomly at first launch and stored locally to identify device requests. It is not your phone’s hardware serial number. '}'
          'The app does not automatically send your local check-up results or training history.',
    '在线 AI 未启用' =>
      'This version has no AI credentials configured, so AI training and usage entries are hidden. '
          'No conversations are sent to an AI service, and no installation identifier is created for this feature.',
    '视频、网络与权限' =>
      'The action catalog and posters are bundled with the app. Exercise videos are downloaded on demand '
          'from a public media service and cached on your device. You may need an internet connection to prepare '
          'videos before training; videos that are not cached may not play offline. Network access also checks '
          'for updates to the public action catalog and media. '
          '${ios ? 'Media requests include the IP address and resource path needed for delivery, without training records, check-up results or AI installation identifiers. ' : ''}'
          '${configured ? 'It is also used for AI requests that you initiate. ' : ''}'
          'The app does not access your camera, microphone, contacts or location.',
    '训练语音与后台播放' =>
      ios
          ? 'After you start training or a voice-guided check-up, the app uses iOS background audio to play '
                'instructions, countdowns and side-change cues. Playback stops and the audio session is released '
                'when training or the check-up ends or you leave it. Background audio is not enabled when both '
                'voice and chimes are off. Settings previews play briefly in the foreground and release the audio '
                'session on completion, navigation or backgrounding. The app does not record through the microphone or read headphone '
                'or Bluetooth device identifiers.'
          : 'After you start training, the app uses a media-playback foreground service and wake lock to keep '
                'training audio playing when the screen is locked or you switch apps, and shows a training notification. '
                'The service stops and the notification is removed when training ends or you leave it. '
                'The app does not record through the microphone or read headphone or Bluetooth device identifiers.',
    '运动与健康提示' =>
      'This app provides general fitness and hip mobility exercises. It is not a medical device and cannot '
          'diagnose, treat, cure or prevent disease or replace advice from a doctor. If you experience pain, '
          'numbness or other discomfort, stop exercising and consult a doctor or qualified professional.',
    '政策更新与联系' =>
      'If our data practices change, we will update this page and the public privacy policy. '
          'For privacy questions, contact the developer at mhgd3250905@gmail.com.\n'
          'You can also contact us through the HipLab GitHub repository’s Issues page:\n'
          'https://github.com/mhgd3250905/HipLab/issues',
    _ => section,
  };
}
