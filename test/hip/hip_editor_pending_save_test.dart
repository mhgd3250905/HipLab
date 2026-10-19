// PR #22 F9 / P2 (Android device retest 2026-10-19): a swipe-left delete
// that the user has already committed must count the moment it commits,
// not only when its slide + resize animation ends (onDismissed). Saving
// 150 ms after the swipe wrote the old step list, so after reopening the
// group the deleted step was back; 1000 ms later it was gone.
//
// Every case uses a real drag on the row (tester.drag: pointer down, move,
// up) and then acts before the ~500 ms animation can finish.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiplab/hip/control/hip_store.dart';
import 'package:hiplab/hip/domain/hip_library.dart';
import 'package:hiplab/hip/domain/hip_models.dart';
import 'package:hiplab/hip/ui/hip_app.dart';
import 'package:hiplab/hip/ui/hip_widgets.dart';
import 'package:hiplab/hip/ui/library/group_editor_page.dart';
import 'package:hiplab/hip/voice/voice_queue.dart';

import 'hip_domain_test.dart' show MemoryStorage, loadContent;

final _now = DateTime(2026, 10, 19, 9, 41);

const _a = 'h-9090-liftoff';
const _b = 'h-adductor-rock';
const _c = 'h-band-hip-ir';

void main() {
  final content = loadContent();

  late MemoryStorage storage;

  Future<HipStore> newStore() async {
    final store = HipStore(
      content: content,
      storage: storage,
      clock: () => _now,
    );
    await store.initialize();
    return store;
  }

  Future<void> openGroup(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey('group-card-c_f9')));
    await tester.pumpAndSettle();
    expect(find.byType(GroupEditorPage), findsOneWidget);
  }

  /// Saves a group [ids] to storage, starts the app and opens its editor.
  Future<HipStore> openEditor(WidgetTester tester, List<String> ids) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    storage = MemoryStorage();
    final store = await newStore();
    store
      ..safety = {'pregnancy': false, 'surgery': false, 'acute': false}
      ..identity = HipIdentity.office
      ..voice = const VoiceSettings(chimes: false);
    await store.saveCustomRoutine(
      CustomRoutine(
        id: 'c_f9',
        name: '三步',
        steps: [for (final id in ids) CustomStep(id)],
      ),
    );
    await tester.pumpWidget(HipApp(store: store, videoEnabled: false));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('tab-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('practice-2')));
    await tester.pumpAndSettle();
    await openGroup(tester);
    return store;
  }

  Finder row(int i) => find.byKey(ValueKey('editor-row-$i'));

  /// A real left swipe past the dismiss threshold; returns right after the
  /// finger lifts, with the slide/resize animation still running.
  Future<void> swipeLeft(WidgetTester tester, int i) async {
    await tester.drag(row(i), const Offset(-180, 0));
    await tester.pump();
  }

  /// The steps as a fresh store reads them back from storage ("reopen").
  Future<List<String>> reopened() async {
    final s = await newStore();
    return [for (final st in s.customRoutines.single.steps) st.kitId];
  }

  int rows() => find.byType(Dismissible).evaluate().length;

  testWidgets('F9 delete the first step, save 150 ms later: reopened group '
      'has [B, C]', (tester) async {
    await openEditor(tester, [_a, _b, _c]);
    await swipeLeft(tester, 0);
    await tester.pump(const Duration(milliseconds: 150));
    await tester.tap(find.byKey(const ValueKey('editor-save')));
    await tester.pumpAndSettle();
    expect(find.byType(GroupEditorPage), findsNothing, reason: 'saved');
    expect(tester.takeException(), isNull);
    expect(await reopened(), [_b, _c]);
    // And in the app: reopening the editor shows two rows.
    await openGroup(tester);
    expect(rows(), 2);
  });

  testWidgets('F9 delete the first step, save in the very next frame: '
      'saves [B, C]', (tester) async {
    await openEditor(tester, [_a, _b, _c]);
    await swipeLeft(tester, 0);
    await tester.tap(find.byKey(const ValueKey('editor-save')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(await reopened(), [_b, _c]);
  });

  testWidgets('F9 delete two steps back to back, save at once: saves [C]', (
    tester,
  ) async {
    await openEditor(tester, [_a, _b, _c]);
    await swipeLeft(tester, 0);
    await tester.pump(const Duration(milliseconds: 60));
    await swipeLeft(tester, 1);
    await tester.pump(const Duration(milliseconds: 150));
    await tester.tap(find.byKey(const ValueKey('editor-save')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(await reopened(), [_c]);
  });

  testWidgets('F9 delete then close at once: asks to discard; discard keeps '
      'the stored [A, B, C]', (tester) async {
    await openEditor(tester, [_a, _b, _c]);
    await swipeLeft(tester, 0);
    await tester.pump(const Duration(milliseconds: 150));
    await tester.tap(find.bySemanticsLabel('取消').first);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('editor-discard')),
      findsOneWidget,
      reason: 'the delete is an unsaved change',
    );
    await tester.tap(find.byKey(const ValueKey('editor-discard')));
    await tester.pumpAndSettle();
    expect(find.byType(GroupEditorPage), findsNothing);
    expect(await reopened(), [_a, _b, _c]);
  });

  testWidgets('F9 delete then system back at once: asks; keep editing, then '
      'save: saves [B, C]', (tester) async {
    await openEditor(tester, [_a, _b, _c]);
    await swipeLeft(tester, 0);
    await tester.pump(const Duration(milliseconds: 150));
    final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
    await nav.maybePop();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('editor-keep')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('editor-keep')));
    await tester.pumpAndSettle();
    expect(rows(), 2);
    await tester.tap(find.byKey(const ValueKey('editor-save')));
    await tester.pumpAndSettle();
    expect(await reopened(), [_b, _c]);
  });

  testWidgets('F9 delete the only step, save at once: same as after the '
      'animation (nothing saved, editor stays, save disabled)', (tester) async {
    await openEditor(tester, [_a]);
    await swipeLeft(tester, 0);
    await tester.pump(const Duration(milliseconds: 150));
    await tester.tap(find.byKey(const ValueKey('editor-save')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(GroupEditorPage), findsOneWidget);
    expect(rows(), 0);
    final save = tester.widget<HipPrimaryButton>(
      find.byKey(const ValueKey('editor-save')),
    );
    expect(save.onPressed, isNull);
    expect(await reopened(), [_a]);
  });

  testWidgets('F9 control: delete, wait for the animation, save: [B, C]', (
    tester,
  ) async {
    await openEditor(tester, [_a, _b, _c]);
    await swipeLeft(tester, 0);
    await tester.pumpAndSettle();
    expect(rows(), 2);
    await tester.tap(find.byKey(const ValueKey('editor-save')));
    await tester.pumpAndSettle();
    expect(await reopened(), [_b, _c]);
  });

  testWidgets('F9 a swipe that snaps back (under the threshold) is not a '
      'delete: save right after keeps [A, B, C]', (tester) async {
    await openEditor(tester, [_a, _b, _c]);
    await tester.timedDrag(
      row(0),
      const Offset(-40, 0),
      const Duration(milliseconds: 400),
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('editor-save')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(await reopened(), [_a, _b, _c]);
  });
}
