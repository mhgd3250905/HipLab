import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../control/hip_membership.dart';
import '../data/hip_shared_library.dart';
import 'hip_icons.dart';
import 'hip_privacy_page.dart';
import 'hip_routes.dart';
import 'hip_text.dart';
import 'hip_theme.dart';
import 'hip_widgets.dart';

Color get _ink => HipColors.text;
Color get _muted => HipColors.muted;
Color get _p => HipColors.jade;
Color get _g2 => HipColors.jadeText;
const _brandGold = Color(0xFFF5C45C);
const _gold = Color(0xFFF5B83D);

final _playSubscriptions = Uri.https(
  'play.google.com',
  '/store/account/subscriptions',
  {'sku': 'hip_premium', 'package': 'com.ugk.hiplab'},
);

class HipMembershipPage extends StatefulWidget {
  const HipMembershipPage({
    super.key,
    required this.membership,
    this.onCoach,
    this.onPlan,
    this.onWorkout,
  });

  final HipMembership membership;
  final VoidCallback? onCoach;
  final VoidCallback? onPlan;
  final VoidCallback? onWorkout;

  @override
  State<HipMembershipPage> createState() => _HipMembershipPageState();
}

class _HipMembershipPageState extends State<HipMembershipPage> {
  MembershipTerm _selected = MembershipTerm.annual;
  late Future<List<MembershipOffer>> _offers = _loadOffers();

  Future<List<MembershipOffer>> _loadOffers() =>
      Future.sync(widget.membership.offers);

  void _reloadOffers() {
    final offers = _loadOffers();
    setState(() {
      _offers = offers;
    });
  }

  @override
  void didUpdateWidget(HipMembershipPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.membership != widget.membership) {
      _selected = MembershipTerm.annual;
      _offers = _loadOffers();
    }
  }

  String get _storeUnavailable => HipText.of(
    context,
  ).pick('暂时无法连接商店，请重试。', 'The store is unavailable. Try again.');

  void _showMessage(String message) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));

  Future<void> _transact({MembershipTerm? term}) async {
    final membership = widget.membership;
    if (membership.busy) return;
    try {
      final active = await (term == null
          ? membership.restore()
          : membership.purchase(term));
      if (!mounted ||
          membership != widget.membership ||
          ModalRoute.of(context)?.isCurrent != true) {
        return;
      }
      if (active) {
        Navigator.of(context).pop<bool>(true);
      } else if (term == null) {
        _showMessage(
          HipText.of(
            context,
          ).pick('未找到有效订阅。', 'No active subscription was found.'),
        );
      }
    } on Exception {
      if (mounted &&
          membership == widget.membership &&
          ModalRoute.of(context)?.isCurrent == true) {
        // Play may have returned a different quote or trial eligibility.
        if (term != null) _reloadOffers();
        _showMessage(_storeUnavailable);
      }
    }
  }

  bool get _isIos => Theme.of(context).platform == TargetPlatform.iOS;

  Future<void> _openExternal(Uri url) async {
    try {
      if (await launchUrl(url, mode: LaunchMode.externalApplication)) return;
    } on Exception {
      // A store or browser handler may be unavailable.
    }
    if (mounted) _showMessage(_storeUnavailable);
  }

  Future<void> _manage() => _openExternal(
    _isIos
        ? Uri.https('apps.apple.com', '/account/subscriptions')
        : _playSubscriptions,
  );

  Future<void> _terms() => _openExternal(
    _isIos
        ? Uri.https(
            'www.apple.com',
            '/legal/internet-services/itunes/dev/stdeula/',
          )
        : Uri.https('play.google.com', '/about/play-terms/'),
  );

  int? _annualSavings(MembershipOffer? monthly, MembershipOffer? annual) {
    if (monthly == null ||
        annual == null ||
        monthly.currency != annual.currency ||
        !monthly.price.isFinite ||
        !annual.price.isFinite ||
        monthly.price <= 0 ||
        annual.price <= 0) {
      return null;
    }
    final savings = 100 * (1 - annual.price / (12 * monthly.price));
    if (!savings.isFinite) return null;
    final percent = savings.round();
    return percent > 0 ? percent : null;
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.membership,
    builder: (context, _) {
      final active = widget.membership.activeSnapshot;
      return FutureBuilder<List<MembershipOffer>>(
        future: _offers,
        builder: (context, snapshot) => AnnotatedRegion<SystemUiOverlayStyle>(
          value: HipColors.isDark
              ? SystemUiOverlayStyle.light
              : SystemUiOverlayStyle.dark,
          child: Scaffold(
            body: Stack(
              fit: StackFit.expand,
              children: [
                const HipPageBackdrop(),
                active == null
                    ? _unsubscribed(context, snapshot)
                    : _subscribed(context, active),
              ],
            ),
          ),
        ),
      );
    },
  );

  Widget _unsubscribed(
    BuildContext context,
    AsyncSnapshot<List<MembershipOffer>> snapshot,
  ) {
    final text = HipText.of(context);
    final loading = snapshot.connectionState == ConnectionState.waiting;
    final offers = {
      if (!loading)
        for (final offer in snapshot.data ?? const <MembershipOffer>[])
          offer.term: offer,
    };
    final annual = offers[MembershipTerm.annual];
    final monthly = offers[MembershipTerm.monthly];
    final selected = offers[_selected] ?? annual ?? monthly;
    final busy = widget.membership.busy;
    final trial = _trialDays(selected);
    final price = selected == null ? null : _cyclePrice(selected);
    return _layout(
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _MemberCard(text: text),
          const SizedBox(height: 18),
          _BenefitsCard(text: text),
          const SizedBox(height: 26),
          for (final (term, offer) in [
            (MembershipTerm.annual, annual),
            (MembershipTerm.monthly, monthly),
          ]) ...[
            if (term == MembershipTerm.monthly) const SizedBox(height: 10),
            _OfferCard(
              key: ValueKey('membership-${term.name}'),
              label: _termLabel(text, term),
              price:
                  offer?.localizedPrice ??
                  (loading ? null : text.pick('暂不可用', 'Unavailable')),
              priceDetail: switch (term) {
                MembershipTerm.monthly when offer != null => text.pick(
                  '每月',
                  'Per month',
                ),
                MembershipTerm.annual => switch (offer?.localizedMonthlyPrice) {
                  final value? => text.pick('约 $value/月', 'About $value/month'),
                  null => null,
                },
                _ => null,
              },
              trial: _trialDays(offer),
              savings: term == MembershipTerm.annual
                  ? _annualSavings(monthly, annual)
                  : null,
              selected: (selected?.term ?? _selected) == term,
              onTap: busy || offer == null
                  ? null
                  : () => setState(() => _selected = term),
            ),
          ],
          if (loading)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Center(
                child: SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(
                    color: _g2,
                    strokeWidth: 2,
                    semanticsLabel: text.pick('正在加载价格', 'Loading prices'),
                  ),
                ),
              ),
            )
          else if (offers.isEmpty) ...[
            const SizedBox(height: 10),
            Semantics(
              liveRegion: true,
              child: Text(_storeUnavailable, style: _style(13, _muted)),
            ),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton(
                key: const ValueKey('membership-retry'),
                onPressed: busy ? null : _reloadOffers,
                child: Text(text.pick('重试', 'Retry')),
              ),
            ),
          ],
        ],
      ),
      footer: [
        _MembershipMaterial(
          radius: 16,
          button: true,
          enabled: !busy && selected != null,
          child: TextButton(
            key: const ValueKey('membership-subscribe'),
            onPressed: busy || selected == null
                ? null
                : () => _transact(term: selected.term),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              disabledForegroundColor: Colors.white,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              textStyle: _style(16.5, Colors.white, weight: FontWeight.w700),
            ),
            child: Text(
              busy
                  ? text.pick('正在处理…', 'Processing…')
                  : trial != null
                  ? text.pick('免费试用 $trial 天', 'Start $trial-day free trial')
                  : price != null
                  ? text.pick('订阅 ${price.zh}', 'Subscribe ${price.en}')
                  : text.pick('订阅', 'Subscribe'),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          [
            if (price != null && trial != null)
              text.pick(
                '试用结束后 ${price.zh}，自动续订',
                'After the trial, ${price.en}. Renews automatically.',
              ),
            if (price != null && trial == null)
              text.pick('订阅将自动续订。', 'Subscription renews automatically.'),
            _renewalDisclosure(text, trial != null),
          ].join('\n'),
          style: _style(11.5, _muted, height: 1.35),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _subscribed(BuildContext context, MembershipSnapshot active) {
    final text = HipText.of(context);
    return _layout(
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _MemberCard(active: active, text: text),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.only(left: 6),
            child: Text(
              text.pick('你的会员权益', 'Your member benefits'),
              style: _style(13, _muted, weight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 10),
          _BenefitsCard(
            text: text,
            member: true,
            onCoach: widget.onCoach,
            onPlan: widget.onPlan,
            onWorkout: widget.onWorkout,
          ),
        ],
      ),
      footer: [
        HipCard(
          radius: 14,
          child: TextButton(
            key: const ValueKey('membership-manage'),
            onPressed: widget.membership.busy ? null : _manage,
            style: TextButton.styleFrom(
              foregroundColor: _ink,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              textStyle: _style(15, _ink, weight: FontWeight.w700),
            ),
            child: Text(text.pick('管理订阅', 'Manage subscription')),
          ),
        ),
      ],
    );
  }

  Widget _layout({required Widget content, required List<Widget> footer}) {
    final text = HipText.of(context);
    final safe = MediaQuery.paddingOf(context);
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16, safe.top + 8, 10, 8),
          child: Align(
            alignment: AlignmentDirectional.centerEnd,
            child: Tooltip(
              message: text.pick('关闭', 'Close'),
              child: HipPressable(
                key: const ValueKey('membership-close'),
                semanticLabel: text.pick('关闭', 'Close'),
                onTap: () => Navigator.of(context).maybePop(),
                child: SizedBox.square(
                  dimension: 44,
                  child: Center(
                    child: HipCard(
                      radius: 16,
                      shadows: const [
                        BoxShadow(
                          color: Color(0x1214281F),
                          offset: Offset(0, 3),
                          blurRadius: 12,
                        ),
                      ],
                      child: SizedBox.square(
                        dimension: 32,
                        child: Center(
                          child: HipIcon(
                            HipGlyph.close,
                            size: 19,
                            color: _ink,
                            strokeWidth: 1.8,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            key: const ValueKey('membership-scroll'),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: content,
              ),
            ),
          ),
        ),
        SafeArea(
          top: false,
          minimum: const EdgeInsets.symmetric(horizontal: 16),
          child: Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 4),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ...footer,
                    const SizedBox(height: 8),
                    _LegalLinks(
                      restore: widget.membership.busy
                          ? null
                          : () => _transact(),
                      terms: _terms,
                      privacy: () => Navigator.of(
                        context,
                      ).push(HipRoute.content((_) => const HipPrivacyPage())),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _renewalDisclosure(HipText text, bool trial) {
    if (_isIos) {
      return text.pick(
        '除非在当前周期结束前至少 24 小时取消，否则将自动续订；可在 App Store 账户设置中管理或取消。',
        'Renews unless canceled at least 24 hours before the current period ends. Manage or cancel in App Store account settings.',
      );
    }
    return trial
        ? text.pick(
            '可随时在 Google Play 取消，试用期内取消不扣费',
            'Cancel anytime in Google Play. Cancel during the trial and you won’t be charged.',
          )
        : text.pick('可随时在 Google Play 取消', 'Cancel anytime in Google Play.');
  }
}

TextStyle _style(
  double size,
  Color color, {
  FontWeight? weight,
  double? height,
  double? letterSpacing,
}) => TextStyle(
  fontFamily: hipFontFamily,
  fontSize: size,
  color: color,
  fontWeight: weight,
  height: height,
  letterSpacing: letterSpacing,
);

int? _trialDays(MembershipOffer? offer) {
  final days = offer?.trialDays;
  return days != null && days > 0 ? days : null;
}

String _termLabel(HipText text, MembershipTerm term) => switch (term) {
  MembershipTerm.annual => text.pick('年付', 'Yearly'),
  MembershipTerm.monthly => text.pick('月付', 'Monthly'),
};

({String zh, String en}) _cyclePrice(MembershipOffer offer) =>
    switch (offer.term) {
      MembershipTerm.annual => (
        zh: '${offer.localizedPrice}/年',
        en: '${offer.localizedPrice} per year',
      ),
      MembershipTerm.monthly => (
        zh: '${offer.localizedPrice}/月',
        en: '${offer.localizedPrice} per month',
      ),
    };

class _MembershipMaterial extends StatelessWidget {
  const _MembershipMaterial({
    required this.radius,
    required this.child,
    this.button = false,
    this.enabled = true,
  });

  final double radius;
  final Widget child;
  final bool button;
  final bool enabled;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: enabled ? null : _muted,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: enabled
          ? HipColors.shadows([
              BoxShadow(
                color: const Color(
                  0xFF0B3D30,
                ).withValues(alpha: button ? .24 : .27),
                offset: Offset(0, button ? 8 : 12),
                blurRadius: button ? 24 : 32,
              ),
            ])
          : null,
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: CustomPaint(
        painter: enabled
            ? _MembershipBackground(radius: radius, ring: !button)
            : null,
        child: child,
      ),
    ),
  );
}

class _MembershipBackground extends CustomPainter {
  const _MembershipBackground({required this.radius, required this.ring});

  final double radius;
  final bool ring;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    final direction = Offset(
      math.sin(135 * math.pi / 180),
      -math.cos(135 * math.pi / 180),
    );
    final halfSpan =
        (direction.dx.abs() * size.width + direction.dy.abs() * size.height) /
        2;
    final gradientOffset = direction * halfSpan;
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = ui.Gradient.linear(
          bounds.center - gradientOffset,
          bounds.center + gradientOffset,
          const [Color(0xFF093026), Color(0xFF126852)],
        ),
    );

    canvas.save();
    canvas.translate(size.width, 0);
    canvas.scale(size.width, size.height);
    canvas.drawCircle(
      Offset.zero,
      1,
      Paint()
        ..shader = ui.Gradient.radial(
          Offset.zero,
          1,
          const [Color(0x42ECC470), Color(0x00ECC470)],
          const [0, .55],
        ),
    );
    canvas.restore();

    if (ring) {
      canvas.drawCircle(
        Offset(size.width - 42, size.height - 2),
        96,
        Paint()
          ..color = const Color(0x09FFFFFF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 22,
      );
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(bounds.deflate(.3), Radius.circular(radius)),
      Paint()
        ..color = const Color(0x2EFFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = .6,
    );
    canvas.drawLine(
      Offset(radius, .3),
      Offset(size.width - radius, .3),
      Paint()
        ..color = const Color(0x59FFFFFF)
        ..strokeWidth = .6,
    );
  }

  @override
  bool shouldRepaint(_MembershipBackground oldDelegate) =>
      oldDelegate.radius != radius || oldDelegate.ring != ring;
}

class _SingleLine extends StatelessWidget {
  const _SingleLine(this.value, {required this.style});

  final String value;
  final TextStyle style;

  @override
  Widget build(BuildContext context) => FittedBox(
    fit: BoxFit.scaleDown,
    alignment: AlignmentDirectional.centerStart,
    child: Text(value, maxLines: 1, style: style),
  );
}

class _BenefitsCard extends StatelessWidget {
  const _BenefitsCard({
    required this.text,
    this.member = false,
    this.onCoach,
    this.onPlan,
    this.onWorkout,
  });

  final HipText text;
  final bool member;
  final VoidCallback? onCoach;
  final VoidCallback? onPlan;
  final VoidCallback? onWorkout;

  @override
  Widget build(BuildContext context) {
    final moveCount = HipSharedLibrary.current?.allowedActionIds.length;
    final benefits = [
      (
        Icons.chat_bubble_outline_rounded,
        text.pick('AI 教练问答', 'AI Coach Q&A'),
        text.pick('动作、疼痛、进度，随时问', 'Ask about moves, pain, or progress anytime'),
        text.pick('去提问', 'Ask'),
        onCoach,
      ),
      (
        Icons.auto_awesome_outlined,
        text.pick('AI 定制训练计划', 'AI Custom Plans'),
        text.pick('按你的柔韧度和时间生成', 'Built around your flexibility and time'),
        text.pick('去定制', 'Customize'),
        onPlan,
      ),
      (
        Icons.playlist_add,
        text.pick('无限自定义训练组', 'Unlimited Custom Workouts'),
        moveCount == null
            ? text.pick('自由组合动作', 'Mix and match moves')
            : text.pick('$moveCount 个动作自由组合', 'Mix and match $moveCount moves'),
        text.pick('去新建', 'Create'),
        onWorkout,
      ),
    ];
    return HipCard(
      radius: 18,
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Column(
        children: [
          for (final (index, benefit) in benefits.indexed) ...[
            if (index > 0)
              Divider(
                color: HipColors.cardDivider,
                height: .5,
                thickness: .5,
                indent: 68,
              ),
            HipPressable(
              onTap: member ? benefit.$5 : null,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 60),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: _p.withValues(alpha: .09),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Icon(benefit.$1, size: 20, color: _g2),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        flex: 9,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              benefit.$2,
                              style: _style(
                                15,
                                _ink,
                                weight: FontWeight.w700,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              benefit.$3,
                              style: _style(12.5, _muted, height: 1.25),
                            ),
                          ],
                        ),
                      ),
                      if (member) ...[
                        const SizedBox(width: 8),
                        Flexible(
                          flex: 4,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Flexible(
                                child: Text(
                                  benefit.$4,
                                  textAlign: TextAlign.end,
                                  style: _style(
                                    13,
                                    _g2,
                                    weight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 3),
                              HipIcon(
                                HipGlyph.chevronRight,
                                size: 14,
                                color: _g2,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _OfferCard extends StatelessWidget {
  const _OfferCard({
    super.key,
    required this.label,
    required this.price,
    required this.priceDetail,
    required this.trial,
    required this.savings,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String? price;
  final String? priceDetail;
  final int? trial;
  final int? savings;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = HipText.of(context);
    final content = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 72),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: _style(15.5, _ink, weight: FontWeight.w700),
                  ),
                  if (trial case final days?) ...[
                    const SizedBox(height: 3),
                    Text(
                      text.pick('$days 天免费试用', '$days-day free trial'),
                      style: _style(12, _g2),
                    ),
                  ],
                ],
              ),
            ),
            if (price case final value?)
              Flexible(
                child: Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _SingleLine(
                        value,
                        style: _style(21, _ink, weight: FontWeight.w700),
                      ),
                      if (priceDetail case final detail?)
                        Text(
                          detail,
                          textAlign: TextAlign.end,
                          style: _style(11.5, _muted),
                        ),
                    ],
                  ),
                ),
              ),
            const SizedBox(width: 12),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? _p : null,
                border: selected
                    ? null
                    : Border.all(color: const Color(0xFFC9D2CE), width: 1.5),
              ),
              child: selected
                  ? const Center(
                      child: HipIcon(
                        HipGlyph.check,
                        size: 15,
                        color: Colors.white,
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
    return HipPressable(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (selected)
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: HipColors.isDark
                      ? [HipColors.surfaceHigh, HipColors.surface]
                      : const [Color(0xFFFCFFFD), Color(0xFFF4FBF8)],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _p, width: 1.5),
                boxShadow: HipColors.shadows([
                  BoxShadow(
                    color: _p.withValues(alpha: .08),
                    offset: const Offset(0, 6),
                    blurRadius: 24,
                  ),
                ]),
              ),
              child: content,
            )
          else
            HipCard(child: content),
          if (savings case final percent?)
            Positioned(
              left: 14,
              top: -10,
              right: 14,
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: _GoldPill(
                  text.pick('最划算 · 省 $percent%', 'Best value · Save $percent%'),
                  size: 10.5,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _GoldPill extends StatelessWidget {
  const _GoldPill(this.label, {this.size = 11});

  final String label;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 20),
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
    decoration: BoxDecoration(
      color: _gold,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Center(
      widthFactor: 1,
      heightFactor: 1,
      child: Text(
        label,
        style: _style(size, const Color(0xFF3A2A00), weight: FontWeight.w700),
      ),
    ),
  );
}

class _MemberCard extends StatelessWidget {
  const _MemberCard({required this.text, this.active});

  final MembershipSnapshot? active;
  final HipText text;

  String _subtitle(MembershipSnapshot active) {
    final expiry = active.expiresAt!
        .toLocal()
        .toIso8601String()
        .split('T')
        .first;
    final term = switch (active.term) {
      MembershipTerm.annual => text.pick('年付', 'Annual'),
      MembershipTerm.monthly => text.pick('月付', 'Monthly'),
      null => null,
    };
    final timing = switch (active.willRenew) {
      false => text.pick('$expiry 到期', 'Ends on $expiry'),
      true when active.isTrial => text.pick(
        '$expiry 起扣费',
        'Billing starts $expiry',
      ),
      true => text.pick('$expiry 自动续订', 'Renews on $expiry'),
      null => expiry,
    };
    return term == null ? timing : '$term · $timing';
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = active;
    return _MembershipMaterial(
      radius: 22,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: snapshot == null ? 166 : 192),
        child: IntrinsicHeight(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (snapshot == null)
                  Text(
                    'HIPLAB PRO',
                    style: _style(
                      11,
                      _brandGold,
                      weight: FontWeight.w700,
                      letterSpacing: 1.8,
                    ),
                  )
                else
                  _GoldPill(
                    snapshot.isTrial
                        ? text.pick('试用中', 'In trial')
                        : text.pick('生效中', 'Active'),
                  ),
                SizedBox(height: snapshot == null ? 8 : 20),
                Semantics(
                  header: true,
                  child: Text(
                    snapshot == null
                        ? text.pick('解锁 HipLab 会员', 'Unlock HipLab Pro')
                        : text.pick('HipLab 会员', 'HipLab Pro'),
                    style: _style(
                      25,
                      Colors.white,
                      weight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                if (snapshot == null)
                  Text(
                    text.pick(
                      'AI 教练陪你一步步打开髋',
                      'Your AI coach for opening your hips',
                    ),
                    style: _style(13.5, const Color(0xCCFFFFFF)),
                  ),
                if (snapshot != null)
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _subtitle(snapshot),
                      maxLines: 1,
                      softWrap: false,
                      style: _style(13.5, const Color(0xCCFFFFFF), height: 1.2),
                    ),
                  ),
                const Spacer(),
                const SizedBox(height: 8),
                Text(
                  'PRO MEMBER',
                  style: _style(
                    9.5,
                    const Color(0x78FFFFFF),
                    letterSpacing: 2.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LegalLinks extends StatelessWidget {
  const _LegalLinks({
    required this.restore,
    required this.terms,
    required this.privacy,
  });

  final VoidCallback? restore;
  final VoidCallback terms;
  final VoidCallback privacy;

  @override
  Widget build(BuildContext context) {
    final text = HipText.of(context);
    final style = _style(12, _g2);
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      runSpacing: 2,
      children: [
        for (final (index, link) in [
          (
            const ValueKey('membership-restore'),
            text.pick('恢复购买', 'Restore'),
            restore,
          ),
          (
            const ValueKey('membership-terms'),
            text.pick('使用条款', 'Terms'),
            terms,
          ),
          (
            const ValueKey('membership-privacy'),
            text.pick('隐私政策', 'Privacy'),
            privacy,
          ),
        ].indexed) ...[
          if (index > 0) Text('·', style: style),
          TextButton(
            key: link.$1,
            onPressed: link.$3,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              minimumSize: const Size(0, 28),
              foregroundColor: _g2,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              textStyle: style,
            ),
            child: Text(link.$2),
          ),
        ],
      ],
    );
  }
}
