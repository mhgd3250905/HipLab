import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiplab/hip/control/hip_store.dart';
import 'package:hiplab/hip/domain/hip_models.dart';
import 'package:hiplab/hip/ui/hip_app.dart';
import 'package:hiplab/hip/ui/hip_page_kit.dart';
import 'package:hiplab/hip/ui/hip_routes.dart';
import 'package:hiplab/hip/ui/hip_theme.dart';
import 'package:hiplab/hip/ui/hip_widgets.dart';

import 'hip_domain_test.dart' show MemoryStorage, loadContent;
import 'home_nav.dart';
import 'public_media_fixture.dart';

void main() {
  const phone = Size(394, 853);
  const step = Duration(milliseconds: 16);

  setUp(() {
    final previous = HipColors.palette;
    HipColors.palette = HipPalette.dark;
    addTearDown(() => HipColors.palette = previous);
  });

  Future<void> shell(
    WidgetTester tester,
    Widget home, {
    double top = 47,
    bool reduce = false,
  }) async {
    tester.view
      ..physicalSize = phone
      ..devicePixelRatio = 1
      ..padding = FakeViewPadding(top: top, bottom: 34);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: hipTheme(HipPalette.dark),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: reduce),
          child: child!,
        ),
        home: home,
      ),
    );
    await tester.pumpAndSettle();
  }

  void expectChip(
    WidgetTester tester, {
    required double top,
    bool fixedX = true,
    bool allowOverlappingAtZero = false,
  }) {
    final chips = find.byType(HipNavBackChip);
    if (allowOverlappingAtZero) {
      expect(chips.evaluate(), isNotEmpty);
    } else {
      expect(chips, findsOneWidget);
    }
    for (var i = 0; i < chips.evaluate().length; i++) {
      final rect = tester.getRect(chips.at(i));
      expect(rect.top, closeTo(top, .001));
      expect(rect.size, const Size(44, 44));
      if (fixedX) expect(rect.left, closeTo(16, .001));
    }
  }

  for (final top in [0.0, 47.0]) {
    for (final leading in HipNavLeading.values) {
      testWidgets(
        'inline $leading stays on the control rail at safe top $top',
        (tester) async {
          const action = ValueKey('inline-action');
          for (final subtitle in <String?>[null, '加到「我的训练组 3」', null]) {
            await shell(
              tester,
              Align(
                alignment: Alignment.topCenter,
                child: HipNavBar(
                  title: '添加动作',
                  subtitle: subtitle,
                  leading: leading,
                  topInset: top,
                  fade: kHipNavFade,
                  trailing: const SizedBox.square(dimension: 20, key: action),
                ),
              ),
              top: top,
            );
            if (leading == HipNavLeading.none) {
              expect(find.byType(HipNavBackChip), findsNothing);
            } else {
              expectChip(tester, top: top);
            }
            expect(tester.getCenter(find.byKey(action)).dy, top + 22);
            expect(
              tester.getSize(find.byType(HipNavBar)).height,
              top + (subtitle == null ? 44 : 52) + kHipNavFade,
              reason: 'The title caption still receives its extra layout space',
            );
            expect(tester.takeException(), isNull);
          }
        },
      );
    }
  }

  for (final top in [0.0, 47.0]) {
    for (final pin in [true, false]) {
      testWidgets(
        'single-double-single push and pop rail: pin $pin, top $top',
        (tester) async {
          Widget page(int level) => HipNavPage(
            title: ['训练组', '添加动作', '动作说明'][level],
            subtitle: level == 1 ? '加到「我的训练组 3」' : null,
            leading: level == 1 ? HipNavLeading.close : HipNavLeading.back,
            bodyScrollsUnderBar: level != 0,
            body: const SizedBox.expand(),
            trailing: SizedBox.square(
              dimension: 20,
              key: ValueKey('action-$level'),
            ),
          );

          await shell(tester, page(0), top: top);
          final navigator = tester.state<NavigatorState>(
            find.byType(Navigator),
          );
          expectChip(tester, top: top);

          Future<void> sample({required int milliseconds}) async {
            await tester.pump();
            // At the exact zero frame both pages may own coincident controls;
            // any visible control must already use the same vertical geometry.
            expectChip(
              tester,
              top: top,
              fixedX: false,
              allowOverlappingAtZero: true,
            );
            for (var elapsed = 16; elapsed < milliseconds; elapsed += 16) {
              await tester.pump(step);
              expectChip(tester, top: top, fixedX: pin);
            }
            await tester.pumpAndSettle();
            expectChip(tester, top: top);
            expect(tester.takeException(), isNull);
          }

          for (final level in [1, 2]) {
            navigator.push(
              HipRoute.content<void>((_) => page(level), pinLeading: pin),
            );
            await sample(milliseconds: HipMotion.page.inMilliseconds);
            expect(
              tester.getCenter(find.byKey(ValueKey('action-$level'))).dy,
              top + 22,
            );
          }
          for (final level in [1, 0]) {
            navigator.pop();
            await sample(milliseconds: HipMotion.pageReverse.inMilliseconds);
            expect(
              tester.getCenter(find.byKey(ValueKey('action-$level'))).dy,
              top + 22,
            );
          }
        },
      );
    }
  }

  testWidgets(
    'keyboard and reduced motion preserve the subtitle control rail',
    (tester) async {
      await shell(
        tester,
        const HipNavPage(
          title: '添加动作',
          subtitle: '加到「我的训练组 3」',
          leading: HipNavLeading.close,
          body: SizedBox.expand(),
          bottomBar: SizedBox(height: 60),
        ),
        reduce: true,
      );
      expectChip(tester, top: 47);
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      await tester.pumpAndSettle();
      expectChip(tester, top: 47);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('real new-group picker retains the training-group back anchor', (
    tester,
  ) async {
    tester.view
      ..physicalSize = phone
      ..devicePixelRatio = 1
      ..padding = const FakeViewPadding(top: 47, bottom: 34);
    addTearDown(tester.view.reset);
    final fixture = installPublicMediaFixture(sharedLibrary: true);
    final store = HipStore(
      content: loadContent(),
      storage: MemoryStorage(),
      clock: () => DateTime(2026, 11, 7, 9),
    );
    await store.initialize();
    store
      ..safety = {'pregnancy': false, 'surgery': false, 'acute': false}
      ..identity = HipIdentity.office;
    await tester.pumpWidget(
      HipApp(store: store, videoEnabled: false, mediaPolicy: fixture.policy),
    );
    await tester.pumpAndSettle();
    await openGroups(tester);
    expectChip(tester, top: 47);
    await tester.tap(find.byKey(const ValueKey('new-group')));
    await tester.pump();
    for (var elapsed = 16; elapsed < 400; elapsed += 16) {
      await tester.pump(step);
      expectChip(tester, top: 47);
    }
    await tester.pumpAndSettle();
    expect(find.text('添加动作'), findsOneWidget);
    expectChip(tester, top: 47);
    final chip = tester.widget<HipNavBackChip>(find.byType(HipNavBackChip));
    expect(chip.leading, HipNavLeading.close);
    await tester.tap(find.byType(HipNavBackChip));
    await tester.pumpAndSettle();
    expect(find.text('训练组'), findsOneWidget);
    expectChip(tester, top: 47);
    expect(store.customRoutines, isEmpty);
    expect(tester.takeException(), isNull);
  });

  for (final top in [0.0, 47.0]) {
    testWidgets(
      'immersive custom header keeps its own anchor at safe top $top',
      (tester) async {
        const action = ValueKey('immersive-action');
        for (final centerHeight in [20.0, 80.0, 20.0]) {
          await shell(
            tester,
            SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: HipTopBar(
                  leading: const HipNavBackChip(leading: HipNavLeading.close),
                  center: SizedBox(height: centerHeight),
                  trailing: const SizedBox.square(dimension: 20, key: action),
                ),
              ),
            ),
            top: top,
          );
          expectChip(tester, top: top + 10);
          expect(tester.getCenter(find.byKey(action)).dy, top + 8 + 24);
          expect(
            tester.getSize(find.byType(HipTopBar)).height,
            (centerHeight > 48 ? centerHeight : 48) + 16,
            reason: 'Custom content may grow without moving immersive controls',
          );
          expect(tester.takeException(), isNull);
        }
      },
    );
  }
}
