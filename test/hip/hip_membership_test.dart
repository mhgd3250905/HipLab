import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiplab/core/storage/local_state_storage.dart';
import 'package:hiplab/hip/control/hip_membership.dart';
import 'package:hiplab/hip/platform/hip_revenuecat.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Store implements MembershipStore {
  late Future<MembershipSnapshot> Function() onRefresh;
  late Future<MembershipSnapshot> Function() onRestore;
  late Future<MembershipSnapshot?> Function(MembershipTerm) onPurchase;
  Future<List<MembershipOffer>> Function()? onOffers;

  @override
  Future<MembershipSnapshot> refresh() => onRefresh();

  @override
  Future<List<MembershipOffer>> offers() async =>
      await onOffers?.call() ?? const [];

  @override
  Future<MembershipSnapshot?> purchase(MembershipTerm term) => onPurchase(term);

  @override
  Future<MembershipSnapshot> restore() => onRestore();
}

class _UnavailableSettings implements LocalStateStorage {
  @override
  Future<String?> read(String key) async {
    throw StateError('Settings read failed');
  }

  @override
  Future<void> write(String key, String value) async {
    throw StateError('Settings write failed');
  }
}

const _localizedPrice = MembershipOffer(
  term: MembershipTerm.monthly,
  price: 4.99,
  currency: 'GBP',
  localizedPrice: '£4.99',
  trialDays: 3,
);

Map<String, Object?> _playProduct({required bool eligible}) {
  const billingPeriod = {'unit': 'MONTH', 'value': 1, 'iso8601': 'P1M'};
  const full = {
    'billingPeriod': billingPeriod,
    'recurrenceMode': 1,
    'billingCycleCount': 0,
    'price': {
      'formatted': '£4.99',
      'amountMicros': 4990000,
      'currencyCode': 'GBP',
    },
  };
  const free = {
    'billingPeriod': {'unit': 'DAY', 'value': 3, 'iso8601': 'P3D'},
    'recurrenceMode': 2,
    'billingCycleCount': 1,
    'price': {'formatted': '£0.00', 'amountMicros': 0, 'currencyCode': 'GBP'},
  };
  const base = {
    'id': 'monthly',
    'productId': 'premium',
    'storeProductId': 'premium:monthly',
    'pricingPhases': [full],
    'tags': <String>[],
    'isBasePlan': true,
    'billingPeriod': billingPeriod,
    'isPrepaid': false,
    'fullPricePhase': full,
  };
  final trial = {
    ...base,
    'id': 'monthly:trial',
    'pricingPhases': [free, full],
    'isBasePlan': false,
    'freePhase': free,
  };
  return {
    'identifier': 'premium:monthly',
    'title': 'HipLab Premium',
    'description': '',
    'price': 4.99,
    'priceString': '£4.99',
    'currencyCode': 'GBP',
    'defaultOption': eligible ? trial : base,
    'subscriptionOptions': [base, if (eligible) trial],
  };
}

Map<String, Object?> _playOffering({required bool eligible}) {
  final offering = {
    'identifier': 'default',
    'serverDescription': '',
    'metadata': <String, Object>{},
    'availablePackages': [
      {
        'identifier': r'$rc_monthly',
        'packageType': 'MONTHLY',
        'presentedOfferingContext': {'offeringIdentifier': 'default'},
        'product': _playProduct(eligible: eligible),
      },
    ],
  };
  return {
    'all': {'default': offering},
    'current': offering,
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('premium ends at expiry and a missing identity never grants it', (
    tester,
  ) async {
    var now = DateTime.utc(2030);
    var snapshot = MembershipSnapshot(' ', now.add(const Duration(seconds: 1)));
    final store = _Store()..onRefresh = () async => snapshot;
    final member = HipMembership(store, now: () => now);
    addTearDown(member.dispose);
    expect(member.isPremium, isFalse);
    expect(await member.refresh(), isFalse);
    snapshot = MembershipSnapshot('anon', now.add(const Duration(seconds: 1)));
    expect(await member.refresh(), isTrue);
    expect(member.activeAppUserId, 'anon');
    var expiredNotification = false;
    member.addListener(() => expiredNotification = !member.isPremium);
    now = now.add(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(member.isPremium, isFalse);
    expect(member.activeAppUserId, isNull);
    expect(expiredNotification, isTrue);
  });

  test('a stale refresh cannot overwrite a later restore decision', () async {
    final stale = Completer<MembershipSnapshot>();
    final now = DateTime.utc(2030);
    final store = _Store();
    store.onRefresh = () => stale.future;
    store.onRestore = () async => MembershipSnapshot('anon', null);
    final member = HipMembership(store, now: () => now);
    addTearDown(member.dispose);
    final refresh = member.refresh();
    expect(member.refresh(), same(refresh));
    expect(await member.restore(), isFalse);
    stale.complete(
      MembershipSnapshot('anon', now.add(const Duration(days: 1))),
    );
    expect(await refresh, isFalse);
    expect(member.isPremium, isFalse);
  });

  test(
    'purchase cancellation and a late result cannot unlock premium',
    () async {
      final purchase = Completer<MembershipSnapshot?>();
      final now = DateTime.utc(2030);
      final store = _Store()..onPurchase = (_) => purchase.future;
      final member = HipMembership(store, now: () => now);
      addTearDown(member.dispose);
      final pending = member.purchase(MembershipTerm.monthly);
      expect(member.busy, isTrue);
      expect(await member.purchase(MembershipTerm.annual), isFalse);
      member.rejectPremium();
      purchase.complete(
        MembershipSnapshot('anon', now.add(const Duration(days: 1))),
      );
      expect(await pending, isFalse);
      expect(member.busy, isFalse);
      store.onPurchase = (_) async => null;
      expect(await member.purchase(MembershipTerm.monthly), isFalse);
      expect(member.isPremium, isFalse);
    },
  );

  test(
    'Play caches localized prices across instances without eligibility',
    () async {
      SharedPreferences.setMockInitialValues({});
      final now = DateTime.utc(2030);
      final store = _Store()..onOffers = () async => const [_localizedPrice];
      store.onRefresh = () async => MembershipSnapshot(
        'anon-test-member',
        now.add(const Duration(days: 1)),
      );
      final online = HipMembership(
        store,
        now: () => now,
        playOfflineQuotes: true,
      );
      addTearDown(online.dispose);

      expect(await online.refresh(), isTrue);
      expect((await online.offers()).single.trialDays, 3);
      final prefs = await SharedPreferences.getInstance();
      final serialized = prefs.getString(prefs.getKeys().single)!;
      final payload = jsonDecode(serialized) as Map<String, Object?>;
      final stored = payload['monthly'] as Map<String, Object?>;
      expect(stored['localizedPrice'], '£4.99');
      expect(stored, isNot(contains('trialDays')));
      expect(serialized, isNot(contains('anon-test-member')));

      final offline = HipMembership(
        _Store()
          ..onOffers = () async => throw const MembershipStoreUnavailable(),
        playOfflineQuotes: true,
      );
      addTearDown(offline.dispose);
      final prices = {
        for (final offer in await offline.offlinePlayOffers())
          offer.term: offer,
      };
      final monthly = prices[MembershipTerm.monthly]!;
      expect(monthly.localizedPrice, '£4.99');
      expect(monthly.currency, 'GBP');
      expect(monthly.trialDays, isNull);
      expect(prices[MembershipTerm.annual]?.localizedPrice, r'US$19.99');
      expect(offline.isPremium, isFalse);
      expect(offline.activeAppUserId, isNull);
    },
  );

  test('an empty Play response preserves the last persisted price', () async {
    SharedPreferences.setMockInitialValues({});
    final store = _Store()..onOffers = () async => const [_localizedPrice];
    final online = HipMembership(store, playOfflineQuotes: true);
    addTearDown(online.dispose);
    await online.offers();

    store.onOffers = () async => const [];
    expect(await online.offers(), isEmpty);
    final reopened = HipMembership(_Store(), playOfflineQuotes: true);
    addTearDown(reopened.dispose);
    final prices = await reopened.offlinePlayOffers();
    expect(
      prices
          .singleWhere((offer) => offer.term == MembershipTerm.monthly)
          .localizedPrice,
      _localizedPrice.localizedPrice,
    );
  });

  test(
    'unavailable settings do not hide live Play prices or block purchase',
    () async {
      final store = _Store()..onOffers = () async => const [_localizedPrice];
      MembershipTerm? purchased;
      store.onPurchase = (term) async {
        purchased = term;
        return null;
      };
      final member = HipMembership(
        store,
        playOfflineQuotes: true,
        offerStorage: _UnavailableSettings(),
      );
      addTearDown(member.dispose);

      expect(
        (await member.offlinePlayOffers()).map((offer) => offer.localizedPrice),
        [r'US$19.99', r'US$2.99'],
      );
      expect((await member.offers()).single, same(_localizedPrice));
      expect(await member.purchase(MembershipTerm.monthly), isFalse);
      expect(purchased, MembershipTerm.monthly);
    },
  );

  test('Play quotes purchase the displayed trial or base plan only', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    const channel = MethodChannel('purchases_flutter');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    var eligible = true;
    var playReachable = true;
    var offeringReads = 0;
    final bought = <String>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      switch (call.method) {
        case 'getProductInfo':
          return [if (playReachable) _playProduct(eligible: eligible)];
        case 'getOfferings':
          offeringReads++;
          return _playOffering(eligible: eligible);
        case 'isAnonymous':
          return true;
        case 'getAppUserID':
          return 'anon';
        case 'purchaseSubscriptionOption':
          bought.add((call.arguments as Map)['optionIdentifier'] as String);
          throw PlatformException(code: '1');
        default:
          return null;
      }
    });
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
    final store = HipRevenueCatStore('test-sdk-key');
    final quote = (await store.offers()).single;
    expect(quote.localizedPrice, '£4.99');
    expect(quote.currency, 'GBP');
    expect(quote.trialDays, 3);
    expect(await store.purchase(MembershipTerm.monthly), isNull);
    expect(bought, ['monthly:trial']);

    eligible = false;
    await expectLater(
      store.purchase(MembershipTerm.monthly),
      throwsA(isA<MembershipStoreUnavailable>()),
    );
    expect(bought, ['monthly:trial']);
    expect((await store.offers()).single.trialDays, isNull);
    expect(await store.purchase(MembershipTerm.monthly), isNull);
    expect(bought, ['monthly:trial', 'monthly']);

    playReachable = false;
    final readsBeforeDisconnect = offeringReads;
    expect(await store.offers(), isEmpty);
    await expectLater(
      store.purchase(MembershipTerm.monthly),
      throwsA(isA<MembershipStoreUnavailable>()),
    );
    expect(offeringReads, readsBeforeDisconnect);
    expect(bought, ['monthly:trial', 'monthly']);
  });
}
