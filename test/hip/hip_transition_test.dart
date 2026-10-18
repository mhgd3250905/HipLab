// Transition quality (audit 2026-10-18, docs/transition-audit-2026-10-18.md):
// pages move progressively instead of cutting, the container transform
// grows over its whole duration with the page fading in late, the page
// below only answers quietly, tabs fade through, and "reduce motion"
// swaps every move for a cross-fade.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiplab/hip/ui/hip_routes.dart';
import 'package:hiplab/hip/ui/hip_theme.dart';

const _frame = Duration(microseconds: 16667);

void main() {
  /// A home page with a 100×100 "button" (its own RepaintBoundary) at the
  /// bottom right; [open] pushes the route built from its context.
  Future<NavigatorState> pumpHome(
    WidgetTester tester, {
    bool reduceMotion = false,
  }) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: hipTheme(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(disableAnimations: reduceMotion),
          child: child!,
        ),
        home: Scaffold(
          body: Stack(
            children: [
              const Positioned.fill(child: Text('home')),
              Positioned(
                right: 20,
                bottom: 20,
                width: 100,
                height: 100,
                child: RepaintBoundary(
                  key: const ValueKey('origin'),
                  child: ColoredBox(color: HipColors.jade),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return tester.state<NavigatorState>(find.byType(Navigator));
  }

  Widget page(BuildContext _) =>
      const Scaffold(body: SizedBox.expand(key: ValueKey('page')));

  double pageDx(WidgetTester tester) =>
      tester.getTopLeft(find.byKey(const ValueKey('page'))).dx / 400;

  testWidgets('a push starts gently instead of jumping, then lands', (
    tester,
  ) async {
    final nav = await pumpHome(tester);
    nav.push(HipRoute.push<void>(page));
    await tester.pump();
    await tester.pump(_frame);
    // The old emphasized-decelerate curve covered ~40 % in this frame.
    expect(pageDx(tester), greaterThan(.9));
    await tester.pump(const Duration(milliseconds: 100));
    expect(pageDx(tester), lessThan(.6)); // clearly under way
    await tester.pump(const Duration(milliseconds: 120));
    expect(pageDx(tester), lessThan(.15));
    await tester.pumpAndSettle();
    expect(pageDx(tester), 0);
  });

  testWidgets('a pop leaves promptly (no long still start) and is quicker', (
    tester,
  ) async {
    final nav = await pumpHome(tester);
    nav.push(HipRoute.push<void>(page));
    await tester.pumpAndSettle();
    final route = ModalRoute.of(
      tester.element(find.byKey(const ValueKey('page'))),
    )!;
    expect(route.reverseTransitionDuration < route.transitionDuration, isTrue);
    nav.pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    // The old accelerate curve had moved < 2 % at this point.
    expect(pageDx(tester), greaterThan(.15));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('page')), findsNothing);
  });

  testWidgets('expand grows over its whole duration; the page fades in late', (
    tester,
  ) async {
    final nav = await pumpHome(tester);
    final origin = tester.element(find.byKey(const ValueKey('origin')));
    final route = HipRoute.expandFrom<void>(origin, page, radius: 50);
    expect(route.transition, HipTransition.expand);
    // The control is its own layer, so frame 0 draws a snapshot of it.
    expect(route.originImage, isNotNull);
    nav.push(route);
    await tester.pump();

    double width() => tester.getSize(find.byKey(const ValueKey('page'))).width;
    double pageWidth() =>
        tester.getRect(find.byKey(const ValueKey('page'))).width;

    double opacity() => tester
        .widget<Opacity>(
          find
              .ancestor(
                of: find.byKey(const ValueKey('page')),
                matching: find.byType(Opacity),
              )
              .first,
        )
        .opacity;

    await tester.pump(HipMotion.expand * .2);
    expect(width(), 400); // laid out full size, drawn scaled
    // Not exploded to full screen within the first fifth (the old curve
    // was ~85 % there).
    expect(pageWidth(), lessThan(200));
    expect(opacity(), 0);
    await tester.pump(HipMotion.expand * .4); // t = .6
    expect(opacity(), inExclusiveRange(0, 1));
    expect(pageWidth(), greaterThan(300));
    await tester.pumpAndSettle();
    expect(opacity(), 1);
    expect(pageWidth(), 400);
    // Close: the exact reverse, a little quicker.
    expect(route.reverseTransitionDuration, HipMotion.expandReverse);
    nav.pop();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('page')), findsNothing);
  });

  testWidgets('the page below only dims under an expand (no shrink)', (
    tester,
  ) async {
    final nav = await pumpHome(tester);
    final origin = tester.element(find.byKey(const ValueKey('origin')));
    nav.push(HipRoute.expandFrom<void>(origin, page));
    await tester.pump();
    await tester.pump(HipMotion.expand ~/ 2);
    final home = tester.getRect(find.text('home'));
    expect(home.width, 400);
    expect(home.left, 0);
    await tester.pumpAndSettle();
  });

  testWidgets('reduce motion swaps the moves for a cross-fade', (tester) async {
    final nav = await pumpHome(tester, reduceMotion: true);
    nav.push(HipRoute.push<void>(page));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 5));
    expect(
      find.ancestor(
        of: find.byKey(const ValueKey('page')),
        matching: find.byType(SlideTransition),
      ),
      findsNothing,
    );
    expect(pageDx(tester), 0);
    expect(
      find.ancestor(
        of: find.byKey(const ValueKey('page')),
        matching: find.byType(FadeTransition),
      ),
      findsWidgets,
    );
    await tester.pumpAndSettle();
  });

  testWidgets('tabs fade through: never two half-visible pages', (
    tester,
  ) async {
    var index = 0;
    late StateSetter set;
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            set = setState;
            return HipTabSwitcher(
              index: index,
              direction: 1,
              child: KeyedSubtree(
                key: ValueKey('tab-$index'),
                child: Text('tab $index'),
              ),
            );
          },
        ),
      ),
    );
    double opacityOf(int i) => tester
        .widget<FadeTransition>(
          find
              .ancestor(
                of: find.byKey(ValueKey('tab-$i'), skipOffstage: false),
                matching: find.byType(FadeTransition, skipOffstage: false),
              )
              .first,
        )
        .opacity
        .value;

    set(() => index = 1);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 45));
    expect(opacityOf(0), inExclusiveRange(0, 1)); // going out
    expect(opacityOf(1), 0); // not in yet
    await tester.pump(const Duration(milliseconds: 100));
    expect(opacityOf(0), 0); // gone before the new one shows much
    expect(opacityOf(1), greaterThan(0));
    await tester.pumpAndSettle();
    expect(opacityOf(1), 1);
  });
}
