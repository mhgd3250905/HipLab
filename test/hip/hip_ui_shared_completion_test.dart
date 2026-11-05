import 'dart:ui' show SemanticsAction, Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiplab/hip/control/hip_store.dart';
import 'package:hiplab/hip/ui/hip_app.dart';
import 'package:hiplab/hip/ui/hip_glass.dart';
import 'package:hiplab/hip/ui/hip_page_kit.dart';
import 'package:hiplab/hip/ui/hip_routes.dart';
import 'package:hiplab/hip/ui/hip_segmented.dart';
import 'package:hiplab/hip/ui/hip_theme.dart';
import 'package:hiplab/hip/ui/hip_widgets.dart';

import 'hip_domain_test.dart' show MemoryStorage, loadContent;

class _TrackedAnimation extends ProxyAnimation {
  _TrackedAnimation([Animation<double>? parent])
    : super(parent ?? const AlwaysStoppedAnimation(.4));

  final _statusListeners = <AnimationStatusListener>{};
  int get statusListenerCount => _statusListeners.length;

  @override
  void addStatusListener(AnimationStatusListener listener) {
    _statusListeners.add(listener);
    super.addStatusListener(listener);
  }

  @override
  void removeStatusListener(AnimationStatusListener listener) {
    _statusListeners.remove(listener);
    super.removeStatusListener(listener);
  }
}

class _TrackedContentRoute extends HipRoute<void> {
  _TrackedContentRoute(WidgetBuilder builder)
    : super(builder: builder, transition: HipTransition.content);

  late _TrackedAnimation clock;

  @override
  Animation<double> createAnimation() {
    clock = _TrackedAnimation(super.createAnimation());
    return clock;
  }
}

Widget _host(Widget child, {bool reduced = false, double top = 0}) =>
    MaterialApp(
      theme: hipTheme(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          disableAnimations: reduced,
          padding: EdgeInsets.only(top: top),
        ),
        child: child!,
      ),
      home: child,
    );

void main() {
  testWidgets(
    'a pressable card preserves independent child semantics actions',
    (tester) async {
      final semantics = tester.ensureSemantics();
      var edits = 0;
      var starts = 0;
      await tester.pumpWidget(
        _host(
          Center(
            child: SizedBox(
              width: 300,
              child: HipPressable(
                key: const ValueKey('card'),
                semanticLabel: 'Edit Plan',
                preserveChildSemantics: true,
                onTap: () => edits++,
                child: Row(
                  children: [
                    const Expanded(child: Text('Plan')),
                    HipPressable(
                      key: const ValueKey('start'),
                      semanticLabel: 'Start Plan',
                      onTap: () => starts++,
                      child: const SizedBox.square(
                        dimension: 44,
                        child: Icon(Icons.play_arrow),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      final card = tester.getSemantics(find.byKey(const ValueKey('card')));
      final start = find.semantics.byLabel('Start Plan').evaluate().single;
      expect(card.id, isNot(start.id));
      expect(card.label, 'Edit Plan');
      expect(start.label, 'Start Plan');
      final startTarget = tester.getSemantics(
        find.byKey(const ValueKey('start')),
      );
      startTarget.owner!.performAction(startTarget.id, SemanticsAction.tap);
      expect(starts, 1);
      expect(edits, 0);
      card.owner!.performAction(card.id, SemanticsAction.tap);
      expect(edits, 1);
      expect(starts, 1);
      semantics.dispose();
    },
  );

  testWidgets('enabling reduced motion on an open route makes pop immediate', (
    tester,
  ) async {
    var reduced = false;
    late StateSetter setMotion;
    await tester.pumpWidget(
      MaterialApp(
        theme: hipTheme(),
        builder: (context, child) => StatefulBuilder(
          builder: (context, set) {
            setMotion = set;
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
              child: child!,
            );
          },
        ),
        home: const Scaffold(),
      ),
    );
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.push(
      HipRoute.push<void>((_) => const Scaffold(body: Text('Page'))),
    );
    await tester.pumpAndSettle();
    setMotion(() => reduced = true);
    await tester.pump();
    navigator.pop();
    await tester.pump();
    await tester.pump();
    expect(find.text('Page'), findsNothing);
  });

  testWidgets(
    'reduced iOS content keeps edge back without moving its surface',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: hipTheme().copyWith(platform: TargetPlatform.iOS),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          ),
          home: const Scaffold(body: Text('Root')),
        ),
      );
      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      navigator.push(
        HipRoute.content<void>(
          (_) => const HipNavPage(
            title: 'Page',
            body: Center(child: Text('Body')),
          ),
          pinLeading: false,
        ),
      );
      await tester.pumpAndSettle();
      final rect = tester.getRect(find.text('Body'));
      final gesture = await tester.startGesture(const Offset(5, 300));
      await gesture.moveBy(const Offset(240, 0));
      await tester.pump();
      expect(navigator.userGestureInProgress, isTrue);
      expect(tester.getRect(find.text('Body')), rect);
      await gesture.up();
      await tester.pump();
      await tester.pump();
      expect(find.text('Body'), findsNothing);
      expect(find.text('Root'), findsOneWidget);
      expect(navigator.userGestureInProgress, isFalse);
      expect(tester.takeException(), isNull);
    },
  );

  for (final keyboard in [0.0, 320.0, 350.0]) {
    testWidgets('shared footer remains operable above a $keyboard keyboard', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      var saves = 0;
      var adds = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: hipTheme(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              padding: EdgeInsets.only(top: 24, bottom: keyboard == 0 ? 34 : 0),
              viewPadding: const EdgeInsets.only(top: 24, bottom: 34),
              viewInsets: EdgeInsets.only(bottom: keyboard),
            ),
            child: child!,
          ),
          home: HipNavPage(
            title: 'Edit group',
            body: Column(
              children: [
                const SizedBox(
                  height: 60,
                  child: TextField(
                    decoration: InputDecoration(labelText: 'Name'),
                  ),
                ),
                Expanded(
                  child: ListView(
                    key: const ValueKey('body-list'),
                    children: [for (var i = 0; i < 30; i++) Text('Move $i')],
                  ),
                ),
              ],
            ),
            bottomBar: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: HipSecondaryButton(
                        label: 'Add',
                        onPressed: () => adds++,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: HipPrimaryButton(
                        label: 'Save',
                        onPressed: () => saves++,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      final save = tester.getRect(find.byType(HipPrimaryButton));
      expect(save.bottom, lessThanOrEqualTo(844 - keyboard));
      // A single inset: the footer's normal 12pt spacing remains the same.
      expect(save.bottom, 844 - keyboard - (keyboard == 0 ? 34 : 0) - 12);
      expect(
        tester.getRect(find.byKey(const ValueKey('body-list'))).bottom,
        lessThanOrEqualTo(save.top),
      );
      await tester.tap(find.text('Save'));
      await tester.tap(find.text('Add'));
      expect(saves, 1);
      expect(adds, 1);
    });
  }
  testWidgets(
    'covered-page curves stay bounded, rebind and release listeners',
    (tester) async {
      final first = _TrackedAnimation();
      final second = _TrackedAnimation();
      Widget frame(_TrackedAnimation clock, int revision) => _host(
        HipCoveredTransition(
          animation: clock,
          kind: HipTransition.content,
          child: Text('revision $revision'),
        ),
      );
      await tester.pumpWidget(frame(first, 0));
      expect(first.statusListenerCount, 1);
      for (var i = 1; i <= 20; i++) {
        await tester.pumpWidget(frame(first, i));
        expect(first.statusListenerCount, 1);
      }
      await tester.pumpWidget(frame(second, 21));
      expect(first.statusListenerCount, 0);
      expect(second.statusListenerCount, 1);
      await tester.pumpWidget(const SizedBox());
      expect(second.statusListenerCount, 0);
    },
  );

  testWidgets(
    'fallback page curves stay bounded, rebind and release listeners',
    (tester) async {
      final first = _TrackedAnimation();
      final second = _TrackedAnimation();
      final route = MaterialPageRoute<void>(builder: (_) => const SizedBox());
      Widget frame(_TrackedAnimation clock, int revision) => _host(
        Builder(
          builder: (context) =>
              const HipPageTransitionsBuilder().buildTransitions<void>(
                route,
                context,
                clock,
                kAlwaysDismissedAnimation,
                Text('revision $revision'),
              ),
        ),
      );
      await tester.pumpWidget(frame(first, 0));
      for (var i = 1; i <= 20; i++) {
        await tester.pumpWidget(frame(first, i));
        expect(first.statusListenerCount, 1);
      }
      await tester.pumpWidget(frame(second, 21));
      expect(first.statusListenerCount, 0);
      expect(second.statusListenerCount, 1);
      await tester.pumpWidget(const SizedBox());
      expect(second.statusListenerCount, 0);
    },
  );

  testWidgets(
    'content-page rebuilds do not accumulate route status listeners',
    (tester) async {
      await tester.pumpWidget(_host(const Scaffold(body: Text('home'))));
      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      late StateSetter rebuild;
      var revision = 0;
      final route = _TrackedContentRoute(
        (_) => StatefulBuilder(
          builder: (context, set) {
            rebuild = set;
            return HipNavPage(
              title: 'Page $revision',
              body: const Text('content'),
            );
          },
        ),
      );
      navigator.push(route);
      await tester.pumpAndSettle();
      final initial = route.clock.statusListenerCount;
      for (var i = 0; i < 20; i++) {
        rebuild(() => revision++);
        await tester.pump();
        expect(route.clock.statusListenerCount, initial);
      }
      navigator.pop();
      await tester.pumpAndSettle();
      expect(route.clock.statusListenerCount, lessThan(initial));
    },
  );

  for (final transition in HipTransition.values) {
    testWidgets(
      'reduced $transition is fully visible and operable immediately',
      (tester) async {
        await tester.pumpWidget(_host(const Scaffold(), reduced: true));
        final navigator = tester.state<NavigatorState>(find.byType(Navigator));
        var taps = 0;
        final page = HipNavPage(
          body: Center(
            child: TextButton(
              key: const ValueKey('action'),
              onPressed: () => taps++,
              child: const Text('Continue'),
            ),
          ),
        );
        final route = HipRoute<void>(
          builder: (_) => page,
          transition: transition,
          origin: transition == HipTransition.expand
              ? const Rect.fromLTWH(20, 300, 100, 60)
              : null,
        );
        navigator.push(route);
        await tester.pump();
        await tester.pump();
        expect(route.transitionDuration, Duration.zero);
        expect(route.reverseTransitionDuration, Duration.zero);
        expect(find.byType(SlideTransition), findsNothing);
        expect(find.byType(FadeTransition), findsNothing);
        await tester.tap(find.byKey(const ValueKey('action')));
        expect(taps, 1);
        navigator.pop();
        await tester.pump();
        await tester.pump();
        expect(find.byKey(const ValueKey('action')), findsNothing);
      },
    );
  }

  testWidgets('reduced controls reach their new positions on the next frame', (
    tester,
  ) async {
    var selected = 0;
    var enabled = false;
    await tester.pumpWidget(
      _host(
        Scaffold(
          body: StatefulBuilder(
            builder: (context, set) => Column(
              children: [
                SizedBox(
                  width: 200,
                  child: HipSegmented<int>(
                    ios: true,
                    values: const [0, 1],
                    selected: selected,
                    label: (value) => 'Option $value',
                    onChanged: (value) => set(() => selected = value),
                  ),
                ),
                HipSwitch(
                  value: enabled,
                  semanticLabel: 'Guidance',
                  onChanged: (value) => set(() => enabled = value),
                ),
              ],
            ),
          ),
        ),
        reduced: true,
      ),
    );
    await tester.tap(find.byKey(const ValueKey('seg-1')));
    await tester.pump();
    expect(selected, 1);
    expect(
      tester.getCenter(find.byKey(const ValueKey('seg-thumb'))).dx,
      closeTo(tester.getCenter(find.byKey(const ValueKey('seg-1'))).dx, .01),
    );
    await tester.tap(find.byType(HipSwitch));
    await tester.pump();
    expect(enabled, isTrue);
    final track = find.descendant(
      of: find.byType(HipSwitch),
      matching: find.byType(AnimatedContainer),
    );
    final knob = find.descendant(
      of: find.byType(AnimatedAlign),
      matching: find.byType(Container),
    );
    expect(
      tester.getRect(knob).right,
      closeTo(tester.getRect(track).right - 2, .01),
    );
  });

  testWidgets(
    'switch exposes its name, toggled state and keyboard activation',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final focus = FocusNode();
      addTearDown(focus.dispose);
      var enabled = false;
      await tester.pumpWidget(
        _host(
          Scaffold(
            body: StatefulBuilder(
              builder: (context, set) => HipSwitch(
                focusNode: focus,
                value: enabled,
                semanticLabel: 'Guidance',
                onChanged: (value) => set(() => enabled = value),
              ),
            ),
          ),
        ),
      );
      expect(tester.getSemantics(find.byType(HipSwitch)).label, 'Guidance');
      focus.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(focus.hasFocus, isTrue);
      expect(enabled, isTrue);
      expect(
        tester.getSemantics(find.byType(HipSwitch)).flagsCollection.isToggled,
        Tristate.isTrue,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(enabled, isFalse);
      await tester.tap(find.byType(HipSwitch));
      await tester.pump();
      expect(enabled, isTrue);
      semantics.dispose();
    },
  );

  testWidgets('all three settings switches have distinct accessible names', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final store = HipStore(content: loadContent(), storage: MemoryStorage());
    await store.initialize();
    await tester.pumpWidget(_host(HipSettingsPage(store: store)));
    await tester.pumpAndSettle();
    for (final (key, label) in [
      ('reminder-switch', '久坐提醒'),
      ('voice-switch', '人声口令'),
      ('chime-switch', '提示音'),
    ]) {
      expect(tester.getSemantics(find.byKey(ValueKey(key))).label, label);
    }
    semantics.dispose();
  });

  testWidgets(
    'a title passes scroll gestures through while back remains live',
    (tester) async {
      final scroll = ScrollController();
      addTearDown(scroll.dispose);
      var backs = 0;
      await tester.pumpWidget(
        _host(
          HipNavPage(
            title: 'Settings title',
            onLeading: () => backs++,
            bodyScrollsUnderBar: true,
            body: ListView(
              controller: scroll,
              padding: const EdgeInsets.only(top: 100),
              children: [for (var i = 0; i < 40; i++) Text('Row $i')],
            ),
          ),
          top: 24,
        ),
      );
      await tester.dragFrom(
        tester.getCenter(find.text('Settings title')),
        const Offset(0, -40),
      );
      await tester.pumpAndSettle();
      expect(scroll.offset, greaterThan(0));
      await tester.tap(find.byType(HipNavBackChip));
      expect(backs, 1);
    },
  );

  testWidgets(
    'a 32pt glass icon keeps its visual size inside a 44pt hit target',
    (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(
          Center(
            child: HipGlassRoundButton(
              key: const ValueKey('shuffle'),
              size: 32,
              semanticLabel: 'Shuffle',
              onTap: () => taps++,
              child: const Icon(Icons.shuffle, size: 16),
            ),
          ),
        ),
      );
      final target = tester.getRect(find.byKey(const ValueKey('shuffle')));
      expect(target.size, const Size(44, 44));
      expect(tester.getSize(find.byType(HipGlass)), const Size(32, 32));
      await tester.tapAt(target.topLeft + const Offset(2, 22));
      expect(taps, 1);
    },
  );

  for (final subtitle in [false, true]) {
    testWidgets('content clears the entire nav band (subtitle=$subtitle)', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          Builder(
            builder: (context) => HipNavPage(
              title: 'Page',
              subtitle: subtitle ? 'Caption' : null,
              bodyScrollsUnderBar: true,
              body: ListView(
                padding: EdgeInsets.only(
                  top: hipNavInset(context, hasSubtitle: subtitle),
                ),
                children: const [
                  SizedBox(height: 44, key: ValueKey('first-row')),
                ],
              ),
            ),
          ),
          top: 24,
        ),
      );
      expect(
        tester.getRect(find.byKey(const ValueKey('first-row'))).top,
        tester.getRect(find.byType(HipNavBar)).bottom,
      );
    });
  }

  testWidgets(
    'reduced state changes and confirmations expose no moving layer',
    (tester) async {
      late StateSetter rebuild;
      var revision = 0;
      await tester.pumpWidget(
        _host(
          Scaffold(
            body: StatefulBuilder(
              builder: (context, set) {
                rebuild = set;
                return Column(
                  children: [
                    HipFadeSwitcher(
                      child: Text(
                        'revision $revision',
                        key: ValueKey(revision),
                      ),
                    ),
                    TextButton(
                      onPressed: () => showHipConfirmDialog(
                        context,
                        title: 'Confirm',
                        cancelLabel: 'Cancel',
                        confirmLabel: 'Save',
                      ),
                      child: const Text('Open'),
                    ),
                  ],
                );
              },
            ),
          ),
          reduced: true,
        ),
      );
      rebuild(() => revision++);
      await tester.pump();
      expect(find.text('revision 0'), findsNothing);
      expect(find.text('revision 1'), findsOneWidget);
      expect(find.byType(SlideTransition), findsNothing);
      expect(find.byType(FadeTransition), findsNothing);
      await tester.tap(find.text('Open'));
      await tester.pump();
      await tester.pump();
      expect(find.text('Confirm'), findsOneWidget);
      expect(find.byType(FadeTransition), findsNothing);
      await tester.tap(find.text('Save'));
      await tester.pump();
      await tester.pump();
      expect(find.text('Confirm'), findsNothing);
    },
  );
}
