import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart' as rc;

import '../control/hip_membership.dart';

typedef _Quote = ({MembershipOffer offer, rc.SubscriptionOption option});

/// The Android store for HipLab's single anonymous RevenueCat identity.
class HipRevenueCatStore implements MembershipStore {
  HipRevenueCatStore([this.publicKey = defaultPublicKey]);

  static const defaultPublicKey = String.fromEnvironment('HIP_RC_ANDROID_KEY');
  final String publicKey;
  Future<void>? _configuration;
  Map<MembershipTerm, _Quote> _quotes = const {};

  bool get isAvailable =>
      !kIsWeb &&
      defaultTargetPlatform == TargetPlatform.android &&
      publicKey.trim().isNotEmpty;

  Future<void> _configure() =>
      _configuration ??= _configureOnce().catchError((Object _) {
        _configuration = null;
        throw const MembershipStoreUnavailable();
      });

  Future<void> _configureOnce() async {
    if (!isAvailable) throw const MembershipStoreUnavailable();
    await rc.Purchases.setLogLevel(rc.LogLevel.warn);
    await rc.Purchases.configure(
      rc.PurchasesConfiguration(publicKey.trim())
        ..entitlementVerificationMode =
            rc.EntitlementVerificationMode.informational
        ..automaticDeviceIdentifierCollectionEnabled = false,
    );
  }

  Future<T> _withStore<T>(Future<T> Function() action) async {
    await _configure();
    try {
      return await action();
    } on Object {
      throw const MembershipStoreUnavailable();
    }
  }

  Future<String> _anonymousUserId() async {
    if (!await rc.Purchases.isAnonymous) {
      throw const MembershipStoreUnavailable();
    }
    final uid = await rc.Purchases.appUserID;
    if (uid.trim().isEmpty) throw const MembershipStoreUnavailable();
    return uid;
  }

  Future<MembershipSnapshot> _snapshot(String uid, rc.CustomerInfo info) async {
    if (await _anonymousUserId() != uid) {
      throw const MembershipStoreUnavailable();
    }
    final entitlement = info.entitlements.active['premium'];
    if (entitlement == null ||
        !entitlement.isActive ||
        entitlement.store != rc.Store.playStore ||
        (entitlement.verification != rc.VerificationResult.verified &&
            entitlement.verification !=
                rc.VerificationResult.verifiedOnDevice)) {
      return MembershipSnapshot(uid, null);
    }
    final expiry = entitlement.expirationDate;
    return MembershipSnapshot(
      uid,
      expiry == null ? null : DateTime.tryParse(expiry),
    );
  }

  @override
  Future<MembershipSnapshot> refresh() => _withStore(() async {
    final uid = await _anonymousUserId();
    await rc.Purchases.invalidateCustomerInfoCache();
    return _snapshot(uid, await rc.Purchases.getCustomerInfo());
  });

  @override
  Future<List<MembershipOffer>> offers() => _withStore(() async {
    _quotes = const {};
    _quotes = await _loadQuotes();
    return List.unmodifiable(_quotes.values.map((quote) => quote.offer));
  });

  Future<Map<MembershipTerm, _Quote>> _loadQuotes() async {
    final offering = (await rc.Purchases.getOfferings()).current;
    if (offering == null || offering.identifier != 'default') return const {};
    final quotes = <MembershipTerm, _Quote>{};
    for (final (term, packageId, trialDays) in const [
      (MembershipTerm.monthly, r'$rc_monthly', 3),
      (MembershipTerm.annual, r'$rc_annual', 7),
    ]) {
      final package = offering.getPackage(packageId);
      if (package == null) continue;
      final quote = _quote(package.storeProduct, term, trialDays);
      if (quote != null) quotes[term] = quote;
    }
    return quotes;
  }

  _Quote? _quote(rc.StoreProduct product, MembershipTerm term, int trialDays) {
    final options =
        product.subscriptionOptions ?? const <rc.SubscriptionOption>[];
    final bases = options
        .where(
          (option) =>
              option.isBasePlan &&
              !option.isPrepaid &&
              option.installmentsInfo == null &&
              _matchesTerm(option.billingPeriod?.iso8601, term),
        )
        .toList();
    if (bases.length != 1) return null;
    final base = bases.single;
    final full = base.fullPricePhase;
    if (full == null ||
        full.recurrenceMode != rc.RecurrenceMode.infiniteRecurring ||
        !_matchesTerm(full.billingPeriod?.iso8601, term) ||
        full.price.amountMicros <= 0 ||
        full.price.formatted.isEmpty ||
        full.price.currencyCode.isEmpty) {
      return null;
    }

    // Use the exact option supplied by Play. The Play trial must be configured
    // with Play-managed eligibility. Developer-determined offers are excluded
    // from automatic selection by tagging them rc-ignore-offer in Play.
    final preferred = product.defaultOption;
    final trial = options
        .where(
          (option) =>
              option.id == preferred?.id &&
              option.storeProductId == base.storeProductId &&
              option.productId == base.productId &&
              _isTrial(option, full, trialDays),
        )
        .firstOrNull;
    final price = full.price.amountMicros / 1000000;
    return (
      offer: MembershipOffer(
        term: term,
        price: price,
        currency: full.price.currencyCode,
        localizedPrice: full.price.formatted,
        localizedMonthlyPrice:
            product.price == price &&
                product.currencyCode == full.price.currencyCode
            ? product.pricePerMonthString
            : null,
        trialDays: trial == null ? null : trialDays,
      ),
      option: trial ?? base,
    );
  }

  bool _matchesTerm(String? period, MembershipTerm term) => switch (term) {
    MembershipTerm.monthly => period == 'P1M',
    MembershipTerm.annual => period == 'P1Y' || period == 'P12M',
  };

  bool _isTrial(rc.SubscriptionOption option, rc.PricingPhase full, int days) {
    final free = option.freePhase;
    if (free == null ||
        option.isBasePlan ||
        option.isPrepaid ||
        option.installmentsInfo != null ||
        option.introPhase != null ||
        option.tags.contains('rc-ignore-offer') ||
        option.tags.contains('rc-customer-center') ||
        option.pricingPhases.length != 2 ||
        option.pricingPhases.first != free ||
        option.pricingPhases.last != option.fullPricePhase ||
        free.price.amountMicros != 0 ||
        free.price.currencyCode != full.price.currencyCode ||
        option.fullPricePhase != full) {
      return false;
    }
    final period = free.billingPeriod?.iso8601;
    final singlePhase = switch (free.recurrenceMode) {
      rc.RecurrenceMode.finiteRecurring => free.billingCycleCount == 1,
      rc.RecurrenceMode.nonRecurring => (free.billingCycleCount ?? 0) == 0,
      _ => false,
    };
    return singlePhase &&
        (period == 'P${days}D' || days == 7 && period == 'P1W');
  }

  @override
  Future<MembershipSnapshot?> purchase(MembershipTerm term) => _withStore(
    () async {
      final shown = _quotes[term];
      final uid = await _anonymousUserId();
      final current = (await _loadQuotes())[term];
      if (shown == null || current == null || shown.option != current.option) {
        // Ask the paywall to reload when pricing or eligibility has changed.
        throw const MembershipStoreUnavailable();
      }
      try {
        final result = await rc.Purchases.purchase(
          rc.PurchaseParams.subscriptionOption(current.option),
        );
        return _snapshot(uid, result.customerInfo);
      } on PlatformException catch (error) {
        if (rc.PurchasesErrorHelper.getErrorCode(error) ==
            rc.PurchasesErrorCode.purchaseCancelledError) {
          return null;
        }
        rethrow;
      }
    },
  );

  @override
  Future<MembershipSnapshot> restore() => _withStore(() async {
    final uid = await _anonymousUserId();
    return _snapshot(uid, await rc.Purchases.restorePurchases());
  });
}

class MembershipStoreUnavailable implements Exception {
  const MembershipStoreUnavailable();
}
