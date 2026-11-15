import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiplab/hip/control/hip_membership.dart';
import 'package:hiplab/hip/platform/hip_revenuecat.dart';

class _Store implements MembershipStore {
  late Future<MembershipSnapshot> Function() onRefresh;
  late Future<MembershipSnapshot> Function() onRestore;
  late Future<MembershipSnapshot?> Function(MembershipTerm) onPurchase;

  @override
  Future<MembershipSnapshot> refresh() => onRefresh();

  @override
  Future<List<MembershipOffer>> offers() async => const [];

  @override
  Future<MembershipSnapshot?> purchase(MembershipTerm term) => onPurchase(term);

  @override
  Future<MembershipSnapshot> restore() => onRestore();
}

Map<String, Object?> _playOffering({required bool eligible}) {
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
  final offering = {
    'identifier': 'default',
    'serverDescription': '',
    'metadata': <String, Object>{},
    'availablePackages': [
      {
        'identifier': r'$rc_monthly',
        'packageType': 'MONTHLY',
        'presentedOfferingContext': {'offeringIdentifier': 'default'},
        'product': {
          'identifier': 'premium:monthly',
          'title': 'HipLab Premium',
          'description': '',
          'price': 4.99,
          'priceString': '£4.99',
          'currencyCode': 'GBP',
          'defaultOption': eligible ? trial : base,
          'subscriptionOptions': [base, if (eligible) trial],
        },
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

  test('Play quotes purchase the displayed trial or base plan only', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    const channel = MethodChannel('purchases_flutter');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    var eligible = true;
    final bought = <String>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      switch (call.method) {
        case 'getOfferings':
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
  });
}
