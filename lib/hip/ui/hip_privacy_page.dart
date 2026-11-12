import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../coach/coach_config.dart';
import '../coach/membership_gateway.dart';
import '../control/hip_ai_consent.dart';
import 'hip_ai_consent_scope.dart';
import 'hip_theme.dart';
import 'hip_icons.dart';
import 'hip_membership_scope.dart';
import 'hip_page_kit.dart';
import 'hip_widgets.dart';
import 'hip_text.dart';

/// Bundled policy remains readable without an internet connection.
class HipPrivacyPage extends StatelessWidget {
  const HipPrivacyPage({super.key, this.aiDisclosure = false});

  final bool aiDisclosure;

  static const policyUrl = 'https://mhgd3250905.github.io/HipLab/';
  static const iosPolicyUrl =
      'https://mhgd3250905.github.io/HipLab/ios/hipinterlude/';

  @override
  Widget build(BuildContext context) {
    final ios = Theme.of(context).platform == TargetPlatform.iOS;
    final publicPolicyUrl = ios ? iosPolicyUrl : policyUrl;
    final membership = HipMembershipScope.of(context) != null;
    final consent = HipAiConsentScope.of(context);
    final configured = aiDisclosure || _coachConfigured(membership);
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
              '开发者：Bboy Ug1yk\n更新日期：2026 年 11 月 12 日',
              'Developer: Bboy Ug1yk\nUpdated: November 12, 2026',
            ),
            style: TextStyle(color: HipColors.muted, height: 1.6),
          ),
          const SizedBox(height: 20),
          _PolicySection(
            title: '我们如何处理你的信息',
            aiConfigured: configured,
            body:
                '本应用无需账号，不含广告或行为分析。'
                '${membership ? (ios ? 'iOS 会员订阅由 App Store 处理。' : '安卓会员订阅由 Google Play 处理。') : '此版本不含支付功能。'}'
                '日常训练和自测记录保存在本机，不会自动上传。'
                '${configured ? '只有你同意 AI 数据共享并主动使用 AI 时，才会向 AI 服务发送请求。' : '此基础版不启用在线 AI 或云端同步，不向开发者服务器发送训练记录。'}',
          ),
          const _PolicySection(
            title: '只在设备上保存的记录',
            body:
                '练习身份（旧版本已保存时）、髋部自测、疼痛或麻木反馈、训练日期与完成记录、自定义训练组、提醒时间和设置，'
                '保存在设备的应用私有存储中，用于训练、查看进度和恢复设置。'
                '本应用没有开发者运营的云端账号或同步服务。',
          ),
          _PolicySection(
            title: '保留、删除与系统备份',
            body:
                '训练、设置和聊天记录保留在设备上，直到你删除相关记录或应用数据。'
                '${ios ? 'iOS 的「删除 App」可移除本机应用数据，「卸载 App」可保留数据。' : 'Android 的清除存储或卸载可移除本机应用数据。'}'
                '系统或设备备份可能根据你的设置保存并恢复应用数据，备份由相应系统或备份服务管理。'
                '${membership ? '\n\n删除应用不会取消商店订阅或自动删除服务端购买记录。购买记录由所用商店及 RevenueCat 按各自适用条款和留存要求处理。' : ''}',
          ),
          if (membership)
            _PolicySection(
              title: ios ? 'iOS 会员订阅' : '安卓会员订阅',
              body: _membershipPolicy(HipText.zh, ios: ios),
              englishBody: _membershipPolicy(HipText.en, ios: ios),
            ),
          if (configured)
            _PolicySection(
              title: 'AI 定制与设备标识',
              body: _aiPolicyBody(HipText.zh, membership: membership, ios: ios),
              englishBody: _aiPolicyBody(
                HipText.en,
                membership: membership,
                ios: ios,
              ),
              action: consent == null
                  ? null
                  : _WithdrawAiConsentButton(consent: consent),
            )
          else
            const _PolicySection(
              title: '在线 AI 未启用',
              body:
                  '此版本未配置 AI 凭据，AI 定制及用量入口均隐藏。'
                  '不会向 AI 服务发送对话，也不会为该功能新建安装标识。',
            ),
          if (configured && membership)
            const _PolicySection(
              title: '权益缓存、次数和服务日志',
              body:
                  '网关最多缓存有效会员权益 5 分钟，且不超过权益到期时间。'
                  '为执行每日额度和防滥用限制，网关用带密钥的哈希从会员标识和 IP 派生计数键，保存时间窗口及请求次数。'
                  '试用每日 30 次，付费会员每日 50 次，按 UTC 日期重置。同一 IP 的请求也有分钟限额。'
                  '每个键只保留最近使用的窗口与次数，由下一窗口的请求覆盖。当前实现没有为停止使用的计数设置固定删除期限。'
                  '计数和权益缓存不保存原始 IP 或原始会员标识。Cloudflare 可能为网络传输、安全和运行诊断处理连接或错误元数据。',
              englishBody:
                  'The gateway caches active membership for up to five minutes and never beyond its expiry. '
                  'For quotas and abuse prevention, it stores a time window and request count under keys derived from the subscriber identifier and IP address using a keyed hash. '
                  'The quota is 30 requests per UTC day during a trial and 50 for paid membership, with a separate per-minute limit per IP. '
                  'Each counter stores its latest window and count, overwritten on a request in a later window. Inactive counters have no fixed deletion deadline. '
                  'Counters and membership caches omit raw IP addresses and subscriber identifiers. Cloudflare may process connection or error metadata for delivery, security and diagnostics.',
            ),
          _PolicySection(
            title: '视频、网络与权限',
            aiConfigured: configured,
            body:
                '动作目录与封面随应用提供。动作视频从公共素材服务按需下载并缓存在设备上；'
                '开始训练前可能需要联网准备视频，尚未缓存的视频在离线时可能无法播放。'
                '网络也用于检查公共动作目录和素材更新。'
                '素材请求包含网络传输所需的 IP 地址及资源路径。播放器可使用只在设备上运行的媒体服务读取素材。'
                '${configured ? '网络权限也用于你主动使用的 AI 定制请求。' : ''}'
                '应用不请求相机、麦克风、位置、联系人或 HealthKit／Health Connect 数据。',
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
                '本应用面向成年人提供一般健身和髋部活动练习，不是医疗器械，'
                '不能诊断、治疗、治愈或预防疾病，不能替代医生的建议。'
                '如有疼痛、麻木或其他不适，请停止练习并咨询医生或专业人士。',
          ),
          _PolicySection(
            title: '政策更新与联系',
            aiConfigured: configured,
            body:
                '如数据处理方式发生变化，我们会更新本页和公开隐私政策。'
                '${membership || configured ? '如需查询或请求删除由 HipLab 管理的服务端数据，请通过下方邮箱联系。' : ''}'
                '${membership ? '商店账单、退款与取消订阅请通过购买所用商店办理。' : ''}'
                '隐私问题请联系开发者：mhgd3250905@gmail.com。\n'
                '也可以通过 HipLab GitHub 仓库 Issues 联系：\n'
                'https://github.com/mhgd3250905/HipLab/issues\n'
                '若你主动联系，相应服务和接收者会处理你提供的内容。请勿在公开 Issues 中发布健康资料、订阅标识或身份信息。',
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
  const _PolicySection({
    required this.title,
    required this.body,
    this.englishBody,
    this.aiConfigured,
    this.action,
  });

  final String title;
  final String body;
  final String? englishBody;
  final bool? aiConfigured;
  final Widget? action;

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
          HipText.of(context).pick(
            body,
            englishBody ?? _privacyBody(context, title, aiConfigured),
          ),
          style: const TextStyle(height: 1.65),
        ),
        ?action,
      ],
    ),
  );
}

class _WithdrawAiConsentButton extends StatefulWidget {
  const _WithdrawAiConsentButton({required this.consent});

  final HipAiConsent consent;

  @override
  State<_WithdrawAiConsentButton> createState() =>
      _WithdrawAiConsentButtonState();
}

class _WithdrawAiConsentButtonState extends State<_WithdrawAiConsentButton> {
  bool _withdrawing = false;

  Future<void> _withdraw() async {
    if (_withdrawing) return;
    setState(() => _withdrawing = true);
    final text = HipText.of(context);
    String message;
    try {
      await widget.consent.withdraw();
      message = text.pick(
        '已撤回，下次使用 AI 时会再次询问',
        'Consent withdrawn. We’ll ask again the next time you use AI.',
      );
    } catch (_) {
      message = text.pick(
        '未能撤回同意，请重试。',
        'Could not withdraw consent. Try again.',
      );
    }
    if (!mounted) return;
    setState(() => _withdrawing = false);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) => TextButton(
    key: const ValueKey('withdraw-ai-consent'),
    onPressed: _withdrawing ? null : _withdraw,
    style: TextButton.styleFrom(
      foregroundColor: HipColors.jadeText,
      textStyle: const TextStyle(fontSize: 14),
    ),
    child: Text(
      HipText.of(
        context,
      ).pick('撤回 AI 数据共享同意', 'Withdraw AI data sharing consent'),
    ),
  );
}

({String intro, String conversation, String details, String local})
hipAiDisclosure(HipText text) => text.isEn
    ? (
        intro:
            'To generate answers and routines, HipLab sends the following to a third-party large language model provider (currently DeepSeek models):',
        conversation: 'The text you enter and this conversation',
        details:
            'Goals, equipment, physical limitations or discomfort you mention.',
        local:
            'Not sent: your on-device training records or self-check results.',
      )
    : (
        intro: '为了生成回答和训练方案，HipLab 会把以下内容发送给第三方大语言模型服务商（当前使用 DeepSeek 模型）处理：',
        conversation: '你输入的文字和本次对话内容',
        details: '你提到的练习目标、器材、身体限制或不适',
        local: '不会发送：本机训练记录、自测结果。',
      );

String _aiPolicyBody(
  HipText text, {
  required bool membership,
  required bool ios,
}) {
  final disclosure = hipAiDisclosure(text);
  final consent = text.pick(
    '首次使用 AI 前，HipLab 会说明要发送哪些数据，并请求你明确同意。你可以在应用内「隐私政策」选择「撤回 AI 数据共享同意」。撤回后，HipLab 会暂停发送新的 AI 请求，下次使用 AI 时会再次询问，只有你重新同意后才会发送。基础训练和自测可独立使用。',
    'HipLab explains what data will be sent and asks for your explicit consent before your first use of AI. You can choose “Withdraw AI data sharing consent” in the app’s Privacy Policy. After you withdraw, HipLab asks again the next time you use AI and sends new requests only after you consent again. Basic training and self-checks work independently of AI.',
  );
  final details = text.pick(
    '请求还包括用于生成回复的上下文，例如场景、语言和动作候选。你在对话中主动填写的疼痛、伤病或恢复情况也会随请求发送。应用可在本机保留 AI 对话记录，相关上下文可能随后续提问再次发送。第三方服务商按其适用条款和服务设置处理请求与回复，其中可能包括留存。请只提供生成回复所需的信息。',
    'Requests include context needed for the reply, such as your setting, language and exercise candidates. If you describe pain, an injury or recovery in the conversation, that information is sent with your request. The app can keep chat history on your device and may resend relevant context when you ask a follow-up. The third-party provider handles requests and replies under its applicable terms and settings, which may include retention. Provide only the details needed for the reply.',
  );
  final identity = membership
      ? text.pick(
          '应用通过 HTTPS 向运行在 Cloudflare Workers 上的 HipLab 网关发送 AI 请求。网关使用 RevenueCat 的匿名 App 用户 ID 核验会员状态及试用或付费权益，并通过 HTTPS 将生成回复所需的内容转发给第三方模型服务。转发不包含应用传给网关的订阅标识或客户端 IP。网关的数据库和应用日志不保存聊天正文或模型回复。',
          'The app sends AI requests over HTTPS to the HipLab gateway on Cloudflare Workers. The gateway uses the anonymous RevenueCat App User ID to verify membership and trial or paid access. It forwards the content needed for a reply over HTTPS to the third-party model provider. The forwarded request omits the app’s subscription identifier and your client IP. The gateway’s databases and application logs do not store chat text or model replies.',
        )
      : ios && CoachConfig.fromEnvironment.authMode != 'worker'
      ? text.pick(
          '此连接模式不附带 AI 安装标识。',
          'This connection mode does not attach an AI installation identifier.',
        )
      : text.pick(
          'AI 请求会附带随机生成并保存在本机的安装标识，用于识别设备请求。',
          'AI requests include a randomly generated installation identifier stored on your device.',
        );
  return '$consent\n\n'
      '${disclosure.intro}\n'
      '• ${disclosure.conversation}\n'
      '• ${disclosure.details}\n'
      '${disclosure.local}\n\n$details\n\n$identity';
}

String _membershipPolicy(HipText text, {required bool ios}) {
  final store = ios ? 'Apple App Store' : 'Google Play';
  return text.pick(
    '付款和续订由 $store 处理。HipLab 不接收支付卡资料。配置了订阅服务的会员版会在启动和返回应用时检查会员状态，即使你尚未购买。'
        'RevenueCat SDK 自动生成随机的匿名 App 用户 ID，使用该标识和商店交易凭证或购买记录来识别订阅、验证权益、恢复购买并统计订阅情况。'
        '购买记录包括订阅商品、购买日期、试用或续订状态和有效期。你可在购买所用商店中管理或取消订阅。',
    '$store handles payments and renewals. HipLab does not receive your payment card details. Membership releases configured for subscriptions check membership at startup and when you return to the app, including before you buy anything. '
        'The RevenueCat SDK generates a random anonymous App User ID and uses it with store transaction receipts or purchase history to identify subscriptions, verify access, restore purchases and measure subscription activity. '
        'Purchase history includes the subscription product, purchase date, trial or renewal status and expiration. You can manage or cancel a subscription in the store where you bought it.',
  );
}

const _privacyTitles = <String, String>{
  '我们如何处理你的信息': 'How we handle your information',
  '只在设备上保存的记录': 'Records stored only on your device',
  '保留、删除与系统备份': 'Retention, deletion and system backups',
  '安卓会员订阅': 'Android membership',
  'iOS 会员订阅': 'iOS membership',
  'AI 定制与设备标识': 'AI training and installation identifier',
  '在线 AI 未启用': 'Online AI is not enabled',
  '权益缓存、次数和服务日志': 'Membership cache, usage limits and service logs',
  '视频、网络与权限': 'Video, network access and permissions',
  '训练语音与后台播放': 'Training audio and background playback',
  '运动与健康提示': 'Exercise and health notice',
  '政策更新与联系': 'Policy updates and contact',
};

bool _coachConfigured(bool membership) => membership
    ? MembershipGateway.baseUrl != null
    : CoachConfig.fromEnvironment.configured;

String _privacyBody(BuildContext context, String section, bool? aiConfigured) {
  final membership = HipMembershipScope.of(context) != null;
  final configured = aiConfigured ?? _coachConfigured(membership);
  final ios = Theme.of(context).platform == TargetPlatform.iOS;
  return switch (section) {
    '我们如何处理你的信息' =>
      'No account is required. This app contains no advertising or behavioral analytics. '
          '${membership ? (ios ? 'The App Store processes iOS subscriptions. ' : 'Google Play processes Android subscriptions. ') : 'This version has no payment features. '}'
          'Your routine training and check-up records stay on your device and are not uploaded automatically. '
          '${configured ? 'Requests are sent to the AI service only after you consent to AI data sharing and choose to use AI.' : 'This basic edition does not enable online AI or cloud sync and does not send training records to a developer server.'}',
    '只在设备上保存的记录' =>
      'Practice profiles saved in earlier versions, hip self-checks, pain or numbness feedback, practice dates, completed sessions, custom routines, '
          'reminder times and settings are stored in the app’s private storage. They support training, progress '
          'and settings on your device. The app has no developer-operated cloud account or sync service.',
    '保留、删除与系统备份' =>
      'Training records, settings and chat history remain on your device until you remove the relevant records or app data. '
          '${ios ? 'Choosing Delete App removes local app data. Offload App may keep it. ' : 'Clearing storage or uninstalling on Android removes local app data. '}'
          'Your operating system or backup provider may back up and restore app data according to your settings and manages those backups.'
          '${membership ? '\n\nDeleting the app does not cancel your store subscription or automatically remove server-side purchase records. The store and RevenueCat handle purchase records under their applicable terms and retention requirements.' : ''}',
    '在线 AI 未启用' =>
      'This version has no AI credentials configured, so AI training and usage entries are hidden. '
          'No conversations are sent to an AI service, and no installation identifier is created for this feature.',
    '视频、网络与权限' =>
      'The action catalog and posters are bundled with the app. Exercise videos are downloaded on demand '
          'from a public media service and cached on your device. You may need an internet connection to prepare '
          'videos before training; videos that are not cached may not play offline. Network access also checks '
          'for updates to the public action catalog and media. '
          'Media requests include the IP address and resource path used for network delivery. The player can use an on-device media service to read assets. '
          '${configured ? 'It is also used for AI requests that you initiate. ' : ''}'
          'The app does not request camera, microphone, location, contacts, HealthKit or Health Connect data.',
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
      'This app provides general fitness and hip mobility exercises for adults. It is not a medical device and cannot '
          'diagnose, treat, cure or prevent disease or replace advice from a doctor. If you experience pain, '
          'numbness or other discomfort, stop exercising and consult a doctor or qualified professional.',
    '政策更新与联系' =>
      'If our data practices change, we will update this page and the public privacy policy. '
          '${membership || configured ? 'To ask about or request deletion of server-side data managed by HipLab, contact us using the email below. ' : ''}'
          '${membership ? 'For billing, refunds and cancellations, use the store where you bought your subscription. ' : ''}'
          'For privacy questions, contact the developer at mhgd3250905@gmail.com.\n'
          'You can also contact us through the HipLab GitHub repository’s Issues page:\n'
          'https://github.com/mhgd3250905/HipLab/issues\n'
          'The relevant service and recipient process the information you choose to provide. '
          'Keep health information, subscription identifiers and identifying details out of public issues.',
    _ => section,
  };
}
