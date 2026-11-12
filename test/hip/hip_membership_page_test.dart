import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiplab/hip/control/hip_membership.dart';
import 'package:hiplab/hip/ui/hip_membership_page.dart';
import 'package:hiplab/hip/ui/hip_theme.dart';

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

const _monthlyTrial = MembershipOffer(
  term: MembershipTerm.monthly,
  price: 5,
  currency: 'USD',
  localizedPrice: r'$5.00',
  trialDays: 3,
);

const _previewOffers = [
  MembershipOffer(
    term: MembershipTerm.monthly,
    price: 2.99,
    currency: 'USD',
    localizedPrice: r'$2.99',
    trialDays: 3,
  ),
  MembershipOffer(
    term: MembershipTerm.annual,
    price: 19.99,
    currency: 'USD',
    localizedPrice: r'$19.99',
    localizedMonthlyPrice: r'$1.67',
    trialDays: 7,
  ),
];

class _Store implements MembershipStore {
  _Store(this.load);

  Future<List<MembershipOffer>> Function() load;
  MembershipSnapshot snapshot = const MembershipSnapshot('test', null);
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
  Future<MembershipSnapshot> refresh() async => snapshot;

  @override
  Future<MembershipSnapshot> restore() async {
    restores++;
    return snapshot;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final artifactDirectory =
      Platform.environment['HIPLAB_MEMBERSHIP_ARTIFACT_DIR'];
  const captureKey = ValueKey('membership-capture');
  final subscribe = find.byKey(const ValueKey('membership-subscribe'));
  final manage = find.byKey(const ValueKey('membership-manage'));
  final annual = find.byKey(const ValueKey('membership-annual'));
  final monthly = find.byKey(const ValueKey('membership-monthly'));
  final now = DateTime(2026, 11, 12, 12);
  final expiresAt = DateTime(2026, 12, 12, 12);

  setUpAll(() async {
    await (FontLoader(
      hipFontFamily,
    )..addFont(rootBundle.load('assets/fonts/NotoSansSC.ttf'))).load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });

  Future<void> mount(
    WidgetTester tester,
    HipMembership membership, {
    Size size = const Size(390, 900),
    double textScale = 1,
    Locale locale = const Locale('en'),
    VoidCallback? onCoach,
    VoidCallback? onPlan,
    VoidCallback? onWorkout,
  }) async {
    addTearDown(membership.dispose);
    tester.view
      ..physicalSize = size
      ..devicePixelRatio = 1
      ..padding = const FakeViewPadding(top: 24, bottom: 24)
      ..viewPadding = const FakeViewPadding(top: 24, bottom: 24);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      RepaintBoundary(
        key: captureKey,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: hipTheme(HipPalette.light),
          locale: locale,
          supportedLocales: const [Locale('en'), Locale('zh')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
          home: HipMembershipPage(
            membership: membership,
            onCoach: onCoach,
            onPlan: onPlan,
            onWorkout: onWorkout,
          ),
        ),
      ),
    );
  }

  testWidgets(
    'annual appears first and the selected offer determines trial and checkout',
    (tester) async {
      final store = _Store(() async => [_month, _year]);
      await mount(tester, HipMembership(store));
      await tester.pumpAndSettle();

      expect(
        tester.getTopLeft(annual).dy,
        lessThan(tester.getTopLeft(monthly).dy),
      );
      expect(find.text(r'$5.00'), findsOneWidget);
      expect(find.text(r'$30.00'), findsOneWidget);
      expect(find.text('Best value · Save 50%'), findsOneWidget);
      expect(find.text('Start 7-day free trial'), findsOneWidget);
      expect(
        find.textContaining(
          RegExp(r'After the trial, \$30\.00', caseSensitive: false),
        ),
        findsOneWidget,
      );
      expect(tester.getSize(subscribe).height, 56);

      await tester.tap(monthly);
      await tester.pumpAndSettle();
      expect(
        find.descendant(of: subscribe, matching: find.textContaining(r'$5.00')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: subscribe,
          matching: find.textContaining('trial', findRichText: true),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: monthly,
          matching: find.textContaining('trial', findRichText: true),
        ),
        findsNothing,
      );
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
      await tester.tap(subscribe, warnIfMissed: false);
      expect(store.purchases, isEmpty);

      first.completeError(Exception('store unavailable'));
      await tester.pumpAndSettle();
      expect(find.text('The store is unavailable. Try again.'), findsOneWidget);
      store.load = () async => [_monthlyTrial];
      final retry = find.byKey(const ValueKey('membership-retry'));
      await tester.ensureVisible(retry);
      await tester.tap(retry);
      await tester.pumpAndSettle();
      expect(find.text('Start 3-day free trial'), findsOneWidget);
      expect(find.textContaining('Save '), findsNothing);

      final restore = find.byKey(const ValueKey('membership-restore'));
      await tester.tap(restore);
      await tester.pumpAndSettle();
      expect(store.restores, 1);
      expect(find.text('No active subscription was found.'), findsOneWidget);
    },
  );

  testWidgets(
    'both states fit 360dp at 1.5x with pinned actions',
    (tester) async {
      final store = _Store(() async => [_monthlyTrial, _year]);
      final membership = HipMembership(store, now: () => now);
      await mount(
        tester,
        membership,
        size: const Size(360, 720),
        textScale: 1.5,
      );
      await tester.pumpAndSettle();
      final subscribeBottom = tester.getBottomLeft(subscribe).dy;
      expect(subscribe.hitTestable(), findsOneWidget);
      final platform = Theme.of(tester.element(subscribe)).platform;
      expect(
        find.textContaining(
          platform == TargetPlatform.iOS ? 'App Store' : 'Google Play',
        ),
        findsOneWidget,
      );
      await tester.dragFrom(const Offset(180, 340), const Offset(0, -200));
      await tester.pumpAndSettle();
      expect(tester.getBottomLeft(subscribe).dy, subscribeBottom);
      expect(tester.takeException(), isNull);

      try {
        store.snapshot = MembershipSnapshot(
          'test',
          expiresAt,
          term: MembershipTerm.annual,
          willRenew: true,
        );
        await membership.refresh();
        await tester.pumpAndSettle();
        final manageBottom = tester.getBottomLeft(manage).dy;
        expect(manage.hitTestable(), findsOneWidget);
        await tester.dragFrom(const Offset(180, 340), const Offset(0, -200));
        await tester.pumpAndSettle();
        expect(tester.getBottomLeft(manage).dy, manageBottom);
        expect(tester.takeException(), isNull);
      } finally {
        membership.rejectPremium();
      }
    },
    variant: const TargetPlatformVariant({
      TargetPlatform.android,
      TargetPlatform.iOS,
    }),
  );

  testWidgets('active member sees renewal status and can open each benefit', (
    tester,
  ) async {
    final store = _Store(() async => [_month, _year]);
    final membership = HipMembership(store, now: () => now);
    final actions = <String>[];
    await mount(
      tester,
      membership,
      locale: const Locale('zh'),
      onCoach: () => actions.add('coach'),
      onPlan: () => actions.add('plan'),
      onWorkout: () => actions.add('workout'),
    );

    Future<void> update({required bool willRenew, bool isTrial = false}) async {
      store.snapshot = MembershipSnapshot(
        'test',
        expiresAt,
        term: MembershipTerm.annual,
        willRenew: willRenew,
        isTrial: isTrial,
      );
      await membership.refresh();
      await tester.pumpAndSettle();
    }

    try {
      await update(willRenew: true);
      expect(find.text('生效中'), findsOneWidget);
      expect(find.textContaining('2026-12-12 自动续订'), findsOneWidget);
      expect(find.text('管理订阅'), findsOneWidget);
      expect(tester.getSize(manage).height, 48);
      expect(find.text('恢复购买'), findsOneWidget);
      expect(find.text('使用条款'), findsOneWidget);
      expect(find.text('隐私政策'), findsOneWidget);
      expect(subscribe, findsNothing);
      for (final label in ['去提问', '去定制', '去新建']) {
        await tester.tap(find.textContaining(label));
      }
      expect(actions, ['coach', 'plan', 'workout']);

      await update(willRenew: false);
      expect(find.textContaining('2026-12-12 到期'), findsOneWidget);

      await update(willRenew: true, isTrial: true);
      expect(find.text('试用中'), findsOneWidget);
      expect(find.textContaining('2026-12-12 起扣费'), findsOneWidget);
    } finally {
      membership.rejectPremium();
    }
  });

  testWidgets('export the two 1080-wide membership screens', (tester) async {
    final store = _Store(() async => _previewOffers);
    final membership = HipMembership(store, now: () => now);
    Future<void> capture(String name) async {
      expect(tester.takeException(), isNull);
      await tester.runAsync(() async {
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(captureKey),
        );
        final image = await boundary.toImage(pixelRatio: 3);
        try {
          expect(image.width, 1080);
          final bytes = (await image.toByteData(
            format: ui.ImageByteFormat.png,
          ))!;
          final folder = Directory(artifactDirectory!)
            ..createSync(recursive: true);
          File('${folder.path}/$name.png').writeAsBytesSync(
            bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
          );
        } finally {
          image.dispose();
        }
      });
    }

    final previousDisableShadows = debugDisableShadows;
    debugDisableShadows = false;
    try {
      await mount(
        tester,
        membership,
        size: const Size(360, 820),
        locale: const Locale('zh'),
        onCoach: () {},
        onPlan: () {},
        onWorkout: () {},
      );
      await tester.pumpAndSettle();

      await capture('hiplab-membership-unsubscribed-1080');
      store.snapshot = MembershipSnapshot(
        'test',
        expiresAt,
        term: MembershipTerm.annual,
        willRenew: true,
      );
      await membership.refresh();
      await tester.pumpAndSettle();
      await capture('hiplab-membership-subscribed-1080');
    } finally {
      debugDisableShadows = previousDisableShadows;
      membership.rejectPremium();
    }
  }, skip: artifactDirectory == null);
}
