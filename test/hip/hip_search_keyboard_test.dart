// PR #22 user report (Android device, 2026-10-19): tapping the 练习 page
// search field focused it (cursor) but no soft keyboard came up.
//
// These lock the Flutter side of the contract at 1× and 2.0× text: a tap
// attaches a text input client and sends TextInput.show, the field keeps
// both once the keyboard's inset arrives, a tap after the keyboard was
// put away shows it again, and typed text filters the list. Whether the
// Android IME then actually appears is outside what a widget test sees;
// see docs/training-library-2026-10-19.md for the device checks.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiplab/hip/control/hip_store.dart';
import 'package:hiplab/hip/domain/hip_library.dart';
import 'package:hiplab/hip/domain/hip_models.dart';
import 'package:hiplab/hip/ui/hip_app.dart';
import 'package:hiplab/hip/ui/library/group_editor_page.dart';
import 'package:hiplab/hip/voice/voice_queue.dart';

import 'hip_domain_test.dart' show MemoryStorage, loadContent;

final _now = DateTime(2026, 10, 19, 9, 41);

void main() {
  final content = loadContent();
  final search = find.byKey(const ValueKey('lib-search'));

  Future<HipStore> openPractice(WidgetTester tester, double scale) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = scale;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final store = HipStore(
      content: content,
      storage: MemoryStorage(),
      clock: () => _now,
    );
    await store.initialize();
    store
      ..safety = {'pregnancy': false, 'surgery': false, 'acute': false}
      ..identity = HipIdentity.office
      ..voice = const VoiceSettings(chimes: false);
    await tester.pumpWidget(HipApp(store: store, videoEnabled: false));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('tab-1')));
    await tester.pumpAndSettle();
    expect(tester.testTextInput.hasAnyClients, isFalse);
    return store;
  }

  bool focused(WidgetTester tester) => tester
      .widget<EditableText>(
        find.descendant(of: search, matching: find.byType(EditableText)),
      )
      .focusNode
      .hasFocus;

  void expectKeyboard(WidgetTester tester, String when) {
    expect(focused(tester), isTrue, reason: '$when: focused');
    expect(
      tester.testTextInput.hasAnyClients,
      isTrue,
      reason: '$when: input connection attached',
    );
    expect(
      tester.testTextInput.isVisible,
      isTrue,
      reason: '$when: TextInput.show sent',
    );
  }

  String countText(WidgetTester tester) =>
      tester.widget<Text>(find.byKey(const ValueKey('actions-count'))).data!;

  for (final scale in [1.0, 2.0]) {
    testWidgets('search ×$scale: tap shows the keyboard, keeps it when the '
        'inset arrives, typing filters', (tester) async {
      await openPractice(tester, scale);
      final field = tester.widget<EditableText>(
        find.descendant(of: search, matching: find.byType(EditableText)),
      );
      expect(field.readOnly, isFalse);
      expect(field.maxLines, 1);
      expect(field.keyboardType, TextInputType.text);

      final before = countText(tester);
      await tester.tap(search);
      await tester.pump();
      expectKeyboard(tester, 'after tap');
      expect(
        tester.testTextInput.log.map((c) => c.method),
        containsAllInOrder(['TextInput.setClient', 'TextInput.show']),
      );

      // The keyboard slides in (adjustResize): the page shrinks under it.
      for (final inset in [120.0, 240.0, 320.0]) {
        tester.view.viewInsets = FakeViewPadding(bottom: inset);
        await tester.pump(const Duration(milliseconds: 16));
      }
      await tester.pumpAndSettle();
      expectKeyboard(tester, 'with the keyboard inset');

      tester.testTextInput.enterText('鸽');
      await tester.pumpAndSettle();
      expect(tester.testTextInput.hasAnyClients, isTrue);
      // Keyboard away again so the (lazily built) count line is on screen.
      tester.view.viewInsets = FakeViewPadding.zero;
      await tester.pumpAndSettle();
      expect(countText(tester), isNot(before), reason: 'filtered');
      expect(find.byKey(const ValueKey('drill-card-s-pigeon')), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('search ×$scale: keyboard put away (back), tap again shows '
        'it again', (tester) async {
      await openPractice(tester, scale);
      await tester.tap(search);
      await tester.pump();
      expectKeyboard(tester, 'first tap');
      tester.testTextInput.hide();
      await tester.pump();
      expect(tester.testTextInput.isVisible, isFalse);
      expect(focused(tester), isTrue, reason: 'cursor stays, as on Android');
      await tester.tap(search);
      await tester.pump();
      expectKeyboard(tester, 'second tap');
    });
  }

  testWidgets('search: leave for another tab and come back, tap shows the '
      'keyboard', (tester) async {
    await openPractice(tester, 1);
    await tester.tap(search);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('tab-2')));
    await tester.pumpAndSettle();
    expect(tester.testTextInput.hasAnyClients, isFalse);
    await tester.tap(find.byKey(const ValueKey('tab-1')));
    await tester.pumpAndSettle();
    await tester.tap(search);
    await tester.pump();
    expectKeyboard(tester, 'after coming back');
  });

  testWidgets('添加动作 picker search ×2.0: tap shows the keyboard', (
    tester,
  ) async {
    final store = await openPractice(tester, 2.0);
    store.customRoutines.add(
      CustomRoutine(
        id: 'c_kb',
        name: '键盘',
        steps: [CustomStep('h-9090-liftoff')],
      ),
    );
    await tester.tap(find.byKey(const ValueKey('practice-2')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('group-card-c_kb')));
    await tester.pumpAndSettle();
    expect(find.byType(GroupEditorPage), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('editor-add')));
    await tester.pumpAndSettle();
    expect(find.byType(DrillPickerPage), findsOneWidget);
    await tester.tap(search);
    await tester.pump();
    expectKeyboard(tester, 'picker');
    tester.testTextInput.enterText('鸽');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('pick-s-pigeon')), findsOneWidget);
  });
}
