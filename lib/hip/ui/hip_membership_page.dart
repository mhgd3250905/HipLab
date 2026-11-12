import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../control/hip_membership.dart';
import 'hip_icons.dart';
import 'hip_page_kit.dart';
import 'hip_text.dart';
import 'hip_theme.dart';
import 'hip_widgets.dart';

final _playSubscriptions = Uri.https(
  'play.google.com',
  '/store/account/subscriptions',
  {'sku': 'hip_premium', 'package': 'com.ugk.hiplab'},
);

final _appStoreSubscriptions = Uri.https(
  'apps.apple.com',
  '/account/subscriptions',
);

bool get _usesAppStore =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

class HipMembershipPage extends StatefulWidget {
  const HipMembershipPage({super.key, required this.membership});

  final HipMembership membership;

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
        // The store may have returned a different quote or trial eligibility.
        if (term != null) _reloadOffers();
        _showMessage(_storeUnavailable);
      }
    }
  }

  Future<void> _manage() async {
    try {
      if (await launchUrl(
        _usesAppStore ? _appStoreSubscriptions : _playSubscriptions,
        mode: LaunchMode.externalApplication,
      )) {
        return;
      }
    } on Exception {
      // A store or browser handler may be unavailable.
    }
    if (mounted) _showMessage(_storeUnavailable);
  }

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
  Widget build(BuildContext context) {
    final text = HipText.of(context);
    return HipNavPage(
      leading: HipNavLeading.close,
      leadingKey: const ValueKey('membership-close'),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              kHipPageEdge,
              16,
              kHipPageEdge,
              32,
            ),
            children: [
              Semantics(
                header: true,
                child: Text(
                  text.pick('解锁 HipLab 会员', 'Unlock HipLab Premium'),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: HipColors.text,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              for (final benefit in [
                text.pick('AI 教练问答', 'AI coach questions and answers'),
                text.pick('AI 定制训练计划', 'AI-built training plans'),
                text.pick('无限自定义训练组', 'Unlimited custom workouts'),
              ])
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      HipIcon(
                        HipGlyph.checkCircle,
                        size: 20,
                        color: HipColors.jadeText,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          benefit,
                          style: TextStyle(fontSize: 15, color: HipColors.text),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 14),
              FutureBuilder<List<MembershipOffer>>(
                future: _offers,
                builder: (context, snapshot) => ListenableBuilder(
                  listenable: widget.membership,
                  builder: (context, _) => _options(context, snapshot),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _options(
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
    final monthly = offers[MembershipTerm.monthly];
    final annual = offers[MembershipTerm.annual];
    final selected = offers[_selected] ?? annual ?? monthly;
    final busy = widget.membership.busy;
    final active = widget.membership.isPremium;
    final trialDays = selected?.trialDays;
    final trial = !active && trialDays != null && trialDays > 0
        ? trialDays
        : null;
    final manageLabel = text.pick('管理订阅', 'Manage subscription');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (term, offer, label) in [
          (MembershipTerm.monthly, monthly, text.pick('月付', 'Monthly')),
          (MembershipTerm.annual, annual, text.pick('年付', 'Yearly')),
        ]) ...[
          if (term == MembershipTerm.annual) const SizedBox(height: 12),
          _OfferCard(
            key: ValueKey('membership-${term.name}'),
            label: label,
            price:
                offer?.localizedPrice ??
                (loading ? null : text.pick('暂不可用', 'Unavailable')),
            monthlyPrice: term == MembershipTerm.annual
                ? offer?.localizedMonthlyPrice
                : null,
            savings: term == MembershipTerm.annual
                ? _annualSavings(monthly, annual)
                : null,
            selected: (selected?.term ?? _selected) == term,
            onTap: busy || active || offer == null
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
            child: Text(
              _storeUnavailable,
              style: TextStyle(color: HipColors.muted),
            ),
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
        const SizedBox(height: 18),
        FilledButton(
          key: const ValueKey('membership-subscribe'),
          onPressed: busy
              ? null
              : active
              ? _manage
              : selected == null
              ? null
              : () => _transact(term: selected.term),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            backgroundColor: HipColors.jade,
            foregroundColor: HipColors.onJade,
            disabledBackgroundColor: HipColors.surfaceHigh,
            disabledForegroundColor: HipColors.muted,
            textStyle: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: Text(
            busy
                ? text.pick('正在处理…', 'Processing…')
                : active
                ? manageLabel
                : trial == null
                ? text.pick('订阅', 'Subscribe')
                : text.pick('免费试用 $trial 天', 'Start $trial-day free trial'),
          ),
        ),
        const SizedBox(height: 8),
        if (trial != null && selected != null) ...[
          Text(
            selected.term == MembershipTerm.annual
                ? text.pick(
                    '试用结束后 ${selected.localizedPrice}/年',
                    'After the trial, ${selected.localizedPrice} per year.',
                  )
                : text.pick(
                    '试用结束后 ${selected.localizedPrice}/月',
                    'After the trial, ${selected.localizedPrice} per month.',
                  ),
            style: TextStyle(fontSize: 13, color: HipColors.text),
          ),
          const SizedBox(height: 4),
        ],
        Text(
          _usesAppStore
              ? text.pick(
                  '除非在当前周期结束前至少 24 小时取消，否则订阅将自动续订；可在 App Store 账户设置中管理或取消。',
                  'Subscription renews automatically unless canceled at least 24 hours before the end of the current period. Manage or cancel in your App Store account settings.',
                )
              : text.pick(
                  '订阅将自动续订，可随时在 Google Play 取消。${trial == null ? '' : '在试用结束前取消则不会扣费。'}',
                  'Subscription renews automatically. Cancel anytime in Google Play.'
                      '${trial == null ? '' : " Cancel before the trial ends and you won’t be charged."}',
                ),
          style: TextStyle(fontSize: 12, height: 1.4, color: HipColors.muted),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 16,
          children: [
            TextButton(
              key: const ValueKey('membership-restore'),
              onPressed: busy ? null : () => _transact(),
              child: Text(text.pick('恢复购买', 'Restore purchases')),
            ),
            if (!active)
              TextButton(
                key: const ValueKey('membership-manage'),
                onPressed: busy ? null : _manage,
                child: Text(manageLabel),
              ),
          ],
        ),
      ],
    );
  }
}

class _OfferCard extends StatelessWidget {
  const _OfferCard({
    super.key,
    required this.label,
    required this.price,
    required this.monthlyPrice,
    required this.savings,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String? price;
  final String? monthlyPrice;
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
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: HipColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? HipColors.jade : HipColors.line,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: HipColors.text,
                        ),
                      ),
                      if (savings case final percent?)
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: HipColors.jade.withValues(alpha: .12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            child: Text(
                              text.pick('省 $percent%', 'Save $percent%'),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: HipColors.jadeText,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (price case final value?) ...[
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: HipColors.text,
                      ),
                    ),
                  ],
                  if (monthlyPrice case final value?)
                    Text(
                      text.pick('约 $value/月', 'About $value/month'),
                      style: TextStyle(fontSize: 13, color: HipColors.muted),
                    ),
                ],
              ),
            ),
            if (selected) ...[
              const SizedBox(width: 12),
              HipIcon(
                HipGlyph.checkCircle,
                size: 22,
                color: HipColors.jadeText,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
