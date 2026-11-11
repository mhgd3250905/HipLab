import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiplab/hip/control/hip_membership.dart';
import 'package:hiplab/hip/ui/hip_membership_page.dart';

const _month = MembershipOffer(
  term: MembershipTerm.monthly,
  price: 5,
  currency: 'USD',
  localizedPrice: r'$5.00',
);

const _year = MembershipOffer(
  term: MembershipTerm.annual,
  price: 30,
  currency: 'USD',
  localizedPrice: r'$30.00',
  localizedMonthlyPrice: r'$2.50',
  trialDays: 7,
);

class _Store implements MembershipStore {
  _Store(this.load);

  Future<List<MembershipOffer>> Function() load;
  final purchases = <MembershipTerm>[];
  var restores = 0;

  @override
  Future<List<MembershipOffer>> offers() => load();

  @override
  Future<MembershipSnapshot?> purchase(MembershipTerm term) async {
    purchases.add(term);
    return null;
  }

  @override
  Future<MembershipSnapshot> refresh() async =>
      const MembershipSnapshot('test', null);

  @override
  Future<MembershipSnapshot> restore() async {
    restores++;
    return const MembershipSnapshot('test', null);
  }
}

void main() {
  final subscribe = find.byKey(const ValueKey('membership-subscribe'));

  Future<void> mount(WidgetTester tester, HipMembership membership) async {
    addTearDown(membership.dispose);
    await tester.pumpWidget(
      MaterialApp(home: HipMembershipPage(membership: membership)),
    );
  }

  testWidgets(
    'annual is selected first and only an eligible offer shows a trial',
    (tester) async {
      final store = _Store(() async => [_month, _year]);
      await mount(tester, HipMembership(store));
      await tester.pumpAndSettle();

      expect(find.text(r'$5.00'), findsOneWidget);
      expect(find.text(r'$30.00'), findsOneWidget);
      expect(find.text('Save 50%'), findsOneWidget);
      expect(find.text('Start 7-day free trial'), findsOneWidget);
      expect(find.text(r'After the trial, $30.00 per year.'), findsOneWidget);
      expect(tester.getSize(subscribe).height, 52);

      await tester.tap(find.byKey(const ValueKey('membership-monthly')));
      await tester.pumpAndSettle();
      expect(find.text('Subscribe'), findsOneWidget);
      expect(find.textContaining('trial'), findsNothing);
      await tester.ensureVisible(subscribe);
      await tester.tap(subscribe);
      await tester.pumpAndSettle();
      expect(store.purchases, [MembershipTerm.monthly]);
      expect(find.byType(HipMembershipPage), findsOneWidget);
    },
  );

  testWidgets(
    'offer loading can retry and restore reports no active subscription',
    (tester) async {
      final first = Completer<List<MembershipOffer>>();
      final store = _Store(() => first.future);
      await mount(tester, HipMembership(store));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(tester.widget<FilledButton>(subscribe).onPressed, isNull);

      first.completeError(Exception('store unavailable'));
      await tester.pumpAndSettle();
      expect(find.text('The store is unavailable. Try again.'), findsOneWidget);
      store.load = () async => const [
        MembershipOffer(
          term: MembershipTerm.monthly,
          price: 5,
          currency: 'USD',
          localizedPrice: r'$5.00',
          trialDays: 3,
        ),
      ];
      final retry = find.byKey(const ValueKey('membership-retry'));
      await tester.ensureVisible(retry);
      await tester.tap(retry);
      await tester.pumpAndSettle();
      expect(find.text('Start 3-day free trial'), findsOneWidget);
      expect(find.text('Save 50%'), findsNothing);

      final restore = find.byKey(const ValueKey('membership-restore'));
      await tester.ensureVisible(restore);
      await tester.tap(restore);
      await tester.pumpAndSettle();
      expect(store.restores, 1);
      expect(find.text('No active subscription was found.'), findsOneWidget);
    },
  );
}
