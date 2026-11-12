import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../control/hip_membership.dart';
import 'hip_privacy_page.dart';
import 'hip_routes.dart';
import 'hip_text.dart';
import 'hip_theme.dart';
import 'hip_widgets.dart';

const _paper = Color(0xFFF6F8F7);
const _ink = Color(0xFF14211C);
const _muted = Color(0xFF6B7772);
const _divider = Color(0xFFEEF2F0);
const _p = Color(0xFF17A47E);
const _g2 = Color(0xFF11795E);
const _g1 = Color(0xFF0B4F3E);
const _gl = Color(0xFF3FD3A3);
const _d1 = Color(0xFF0B3D30);
const _d2 = Color(0xFF126B53);
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
          value: SystemUiOverlayStyle.light,
          child: Scaffold(
            backgroundColor: _paper,
            body: active == null
                ? _unsubscribed(context, snapshot)
                : _subscribed(context, active),
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
      headerHeight: 300,
      overlapStart: 196,
      title: text.pick('解锁 HipLab 会员', 'Unlock HipLab Pro'),
      subtitle: text.pick(
        'AI 教练陪你一步步打开髋',
        'Your AI coach for opening your hips',
      ),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _BenefitsCard(text: text),
          const SizedBox(height: 28),
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
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: busy || selected == null
                ? null
                : const LinearGradient(colors: [_g2, _p]),
            color: busy || selected == null ? _muted : null,
            boxShadow: [
              if (!busy && selected != null)
                BoxShadow(
                  color: _p.withValues(alpha: .35),
                  offset: const Offset(0, 6),
                  blurRadius: 16,
                ),
            ],
          ),
          child: TextButton(
            key: const ValueKey('membership-subscribe'),
            onPressed: busy || selected == null
                ? null
                : () => _transact(term: selected.term),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              disabledForegroundColor: Colors.white,
              minimumSize: const Size.fromHeight(56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              textStyle: _style(17, Colors.white, weight: FontWeight.w700),
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
          style: _style(12, _muted, height: 18 / 12),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _subscribed(BuildContext context, MembershipSnapshot active) {
    final text = HipText.of(context);
    return _layout(
      headerHeight: 220,
      overlapStart: MediaQuery.paddingOf(context).top + 68,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _MemberCard(active: active, text: text),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.only(left: 4),
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
        OutlinedButton(
          key: const ValueKey('membership-manage'),
          onPressed: widget.membership.busy ? null : _manage,
          style: OutlinedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: _ink,
            minimumSize: const Size.fromHeight(48),
            side: const BorderSide(color: Color(0xFFC9D2CE)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            textStyle: _style(15, _ink, weight: FontWeight.w600),
          ),
          child: Text(text.pick('管理订阅', 'Manage subscription')),
        ),
      ],
    );
  }

  Widget _layout({
    required double headerHeight,
    required double overlapStart,
    required Widget content,
    required List<Widget> footer,
    String? title,
    String? subtitle,
  }) {
    final text = HipText.of(context);
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            key: const ValueKey('membership-scroll'),
            child: Stack(
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: headerHeight,
                  child: const CustomPaint(painter: _MembershipBackground()),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(16, overlapStart, 16, 20),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: content,
                    ),
                  ),
                ),
                Positioned(
                  top: MediaQuery.paddingOf(context).top + 12,
                  left: 24,
                  right: 24,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _Pill(
                            label: 'HIPLAB PRO',
                            background: Colors.white.withValues(alpha: .16),
                            border: Colors.white.withValues(alpha: .28),
                            style: _style(
                              12,
                              Colors.white,
                              weight: FontWeight.w700,
                              letterSpacing: 1.5,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                          ),
                          IconButton(
                            key: const ValueKey('membership-close'),
                            tooltip: text.pick('关闭', 'Close'),
                            onPressed: () => Navigator.of(context).maybePop(),
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.standard,
                            constraints: const BoxConstraints.tightFor(
                              width: 32,
                              height: 32,
                            ),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.white.withValues(
                                alpha: .16,
                              ),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            icon: const Icon(
                              Icons.close,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      if (title != null) ...[
                        const SizedBox(height: 14),
                        Semantics(
                          header: true,
                          child: _SingleLine(
                            title,
                            style: _style(
                              28,
                              Colors.white,
                              weight: FontWeight.w800,
                              height: 36 / 28,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          subtitle!,
                          style: _style(
                            15,
                            Colors.white.withValues(alpha: .82),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        SafeArea(
          top: false,
          minimum: const EdgeInsets.symmetric(horizontal: 16),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ...footer,
                    const SizedBox(height: 14),
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

class _MembershipBackground extends CustomPainter {
  const _MembershipBackground({this.member = false});

  final bool member;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    final angle = (member ? 135 : 160) * math.pi / 180;
    final direction = Offset(math.sin(angle), -math.cos(angle));
    final halfSpan =
        (direction.dx.abs() * size.width + direction.dy.abs() * size.height) /
        2;
    final gradientOffset = direction * halfSpan;
    final linear = ui.Gradient.linear(
      bounds.center - gradientOffset,
      bounds.center + gradientOffset,
      member ? const [_d1, _d2] : const [_g1, _g2, _p],
      member ? null : const [0, .6, 1],
    );
    canvas.drawRect(bounds, Paint()..shader = linear);

    final glow = member ? _gold.withValues(alpha: .35) : _gl;
    canvas.save();
    canvas.clipRect(bounds);
    canvas.translate(size.width * (member ? 1 : .85), 0);
    canvas.scale(
      size.width * (member ? 1 : 1.2),
      size.height * (member ? 1 : .9),
    );
    final radial = ui.Gradient.radial(
      Offset.zero,
      1,
      [glow, glow.withValues(alpha: 0)],
      [0, member ? .60 : .55],
    );
    canvas.drawCircle(Offset.zero, 1, Paint()..shader = radial);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_MembershipBackground oldDelegate) =>
      oldDelegate.member != member;
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

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.background,
    required this.style,
    required this.padding,
    this.border,
  });

  final String label;
  final Color background;
  final TextStyle style;
  final EdgeInsets padding;
  final Color? border;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(100),
      border: border == null ? null : Border.all(color: border!),
    ),
    child: Padding(
      padding: padding,
      child: Text(label, style: style),
    ),
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
    final benefits = [
      (
        Icons.forum_outlined,
        text.pick('AI 教练问答', 'AI Coach Q&A'),
        text.pick('动作、疼痛、进度，随时问', 'Ask about moves, pain, or progress anytime'),
        text.pick('去提问 ›', 'Ask ›'),
        onCoach,
      ),
      (
        Icons.auto_awesome_outlined,
        text.pick('AI 定制训练计划', 'AI Custom Plans'),
        text.pick('按你的柔韧度和时间生成', 'Built around your flexibility and time'),
        text.pick('去定制 ›', 'Customize ›'),
        onPlan,
      ),
      (
        Icons.playlist_add,
        text.pick('无限自定义训练组', 'Unlimited Custom Workouts'),
        text.pick('248 个动作自由组合', 'Mix and match 248 moves'),
        text.pick('去新建 ›', 'Create ›'),
        onWorkout,
      ),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _g1.withValues(alpha: .10),
            offset: const Offset(0, 8),
            blurRadius: 24,
          ),
        ],
      ),
      child: Column(
        children: [
          for (final (index, benefit) in benefits.indexed) ...[
            if (index > 0)
              const Divider(color: _divider, height: 1, thickness: 1),
            HipPressable(
              onTap: member ? benefit.$5 : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F6F1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(benefit.$1, size: 20, color: _g2),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            benefit.$2,
                            style: _style(16, _ink, weight: FontWeight.w600),
                          ),
                          if (!member) ...[
                            const SizedBox(height: 2),
                            Text(benefit.$3, style: _style(13, _muted)),
                          ],
                        ],
                      ),
                    ),
                    if (member) ...[
                      const SizedBox(width: 8),
                      Text(
                        benefit.$4,
                        textAlign: TextAlign.end,
                        style: _style(13, _g2, weight: FontWeight.w600),
                      ),
                    ],
                  ],
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
    return HipPressable(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: selected ? const Color(0xFFF2FBF7) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? _p : const Color(0xFFE3E7E5),
                width: selected ? 2 : 1,
                strokeAlign: BorderSide.strokeAlignInside,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: _style(16, _ink, weight: FontWeight.w700),
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
                            style: _style(22, _ink, weight: FontWeight.w800),
                          ),
                          if (priceDetail case final detail?)
                            Text(
                              detail,
                              textAlign: TextAlign.end,
                              style: _style(12, _muted),
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
                    border: Border.all(
                      color: selected ? _p : const Color(0xFFC9D2CE),
                      width: selected ? 7 : 2,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (savings case final percent?)
            Positioned(
              left: 14,
              top: -11,
              right: 14,
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: _GoldPill(
                  text.pick('最划算 · 省 $percent%', 'Best value · Save $percent%'),
                  size: 11,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _GoldPill extends StatelessWidget {
  const _GoldPill(this.label, {required this.size});

  final String label;
  final double size;

  @override
  Widget build(BuildContext context) => _Pill(
    label: label,
    background: _gold,
    style: _style(size, const Color(0xFF3A2A00), weight: FontWeight.w800),
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
  );
}

class _MemberCard extends StatelessWidget {
  const _MemberCard({required this.active, required this.text});

  final MembershipSnapshot active;
  final HipText text;

  String? _detail() {
    final term = active.term;
    final expiration = active.expiresAt?.toLocal();
    final date = expiration?.toIso8601String().split('T').first;
    final label = term == null ? null : _termLabel(text, term);
    if (date == null) return label;
    final action = switch (active.willRenew) {
      false => text.pick('$date 到期', 'Expires $date'),
      true when active.isTrial => text.pick(
        '$date 起扣费',
        'Billing starts $date',
      ),
      true => text.pick('$date 自动续订', 'Renews $date'),
      null => date,
    };
    return label == null ? action : '$label · $action';
  }

  @override
  Widget build(BuildContext context) {
    final detail = _detail();
    return Container(
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: _d1.withValues(alpha: .35),
            offset: const Offset(0, 12),
            blurRadius: 28,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            const Positioned.fill(
              child: CustomPaint(painter: _MembershipBackground(member: true)),
            ),
            Positioned(
              right: -40,
              bottom: -60,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: .06),
                    width: 28,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 20,
              left: 20,
              right: 20,
              bottom: 43,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.topStart,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _GoldPill(
                      active.isTrial
                          ? text.pick('试用中', 'In trial')
                          : text.pick('生效中', 'Active'),
                      size: 12,
                    ),
                    const SizedBox(height: 22),
                    Text(
                      text.pick('HipLab 会员', 'HipLab Pro'),
                      style: _style(24, Colors.white, weight: FontWeight.w800),
                    ),
                    if (detail != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        detail,
                        style: _style(14, Colors.white.withValues(alpha: .82)),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Positioned(
              left: 20,
              bottom: 18,
              child: Text(
                'PRO MEMBER',
                style: _style(
                  12,
                  Colors.white.withValues(alpha: .60),
                  letterSpacing: 2,
                ),
              ),
            ),
          ],
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
