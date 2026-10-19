// PR #22 F8 (Web acceptance 2026-10-19): the group editor must address a
// step by its stable key, not by the index it had when the dose sheet
// opened. A swipe-left delete that finishes while the sheet is up shifts
// the indexes; writing back by the old index overwrote the next step and
// reused the edited step's key (A, B, C → delete A, edit B → [B, B(2)]).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiplab/hip/control/hip_store.dart';
import 'package:hiplab/hip/domain/hip_library.dart';
import 'package:hiplab/hip/domain/hip_models.dart';
import 'package:hiplab/hip/ui/hip_app.dart';
import 'package:hiplab/hip/ui/library/group_editor_page.dart';
import 'package:hiplab/hip/ui/library/library_widgets.dart';
import 'package:hiplab/hip/voice/voice_queue.dart';

import 'hip_domain_test.dart' show MemoryStorage, loadContent;

final _now = DateTime(2026, 10, 19, 9, 41);

const _a = 'h-9090-liftoff';
const _b = 'h-adductor-rock';
const _c = 'h-band-hip-ir';

void main() {
  final content = loadContent();

  Future<HipStore> openEditor(WidgetTester tester, List<String> ids) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
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
    store.customRoutines.add(
      CustomRoutine(
        id: 'c_race',
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
    await tester.tap(find.byKey(const ValueKey('group-card-c_race')));
    await tester.pumpAndSettle();
    expect(find.byType(GroupEditorPage), findsOneWidget);
    return store;
  }

  Finder row(int i) => find.byKey(ValueKey('editor-row-$i'));

  /// Swipes row [i] far enough left to commit the delete, without waiting
  /// for the slide/resize animation (onDismissed fires at its end).
  Future<void> swipeLeft(WidgetTester tester, int i) async {
    await tester.drag(row(i), const Offset(-180, 0));
    await tester.pump();
  }

  Future<void> setSets2AndSave(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey('dose-sets-up')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('dose-done')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('editor-save')));
    await tester.pumpAndSettle();
  }

  List<(String, int)> saved(HipStore s) => [
    for (final st in s.customRoutines.single.steps) (st.kitId, st.sets ?? 1),
  ];

  String sheetTitle(WidgetTester tester, String id) =>
      drillName(content, content.drill(id), 'zh');

  /// ~1 s of real frames, so a pending delete runs its slide and resize
  /// and fires onDismissed (one long pump only advances a single frame).
  Future<void> settleFrames(WidgetTester tester) async {
    for (var k = 0; k < 10; k++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  /// The open dose sheet's title is [id]'s name.
  void expectSheetFor(String id) => expect(
    find.descendant(
      of: find.byType(BottomSheet),
      matching: find.text(drillName(content, content.drill(id), 'zh')),
    ),
    findsOneWidget,
  );

  int rows() => find.byType(Dismissible).evaluate().length;

  testWidgets('F8 delete A, tap B 150 ms later, A finishes, B → 2 组: '
      'saves [B(2), C]', (tester) async {
    final store = await openEditor(tester, [_a, _b, _c]);
    await swipeLeft(tester, 0);
    await tester.pump(const Duration(milliseconds: 150));
    await tester.tap(row(1));
    await tester.pump();
    await settleFrames(tester);
    expectSheetFor(_b);
    expect(rows(), 2, reason: 'A finished deleting under the sheet');
    await setSets2AndSave(tester);
    expect(saved(store), [(_b, 2), (_c, 1)]);
  });

  testWidgets('F8 two pending deletes (A and B), edit C: saves [C(2)]', (
    tester,
  ) async {
    final store = await openEditor(tester, [_a, _b, _c]);
    await swipeLeft(tester, 0);
    await tester.pump(const Duration(milliseconds: 60));
    await swipeLeft(tester, 1);
    await tester.pump(const Duration(milliseconds: 60));
    await tester.tap(row(2));
    await tester.pump();
    await settleFrames(tester);
    expectSheetFor(_c);
    expect(rows(), 1);
    await setSets2AndSave(tester);
    expect(saved(store), [(_c, 2)]);
  });

  testWidgets('F8 two pending deletes (A and C) around the edited B in '
      'four steps: saves [B(2), D]', (tester) async {
    const d = 's-pigeon';
    final store = await openEditor(tester, [_a, _b, _c, d]);
    await swipeLeft(tester, 0);
    await tester.pump(const Duration(milliseconds: 60));
    await swipeLeft(tester, 2);
    await tester.pump(const Duration(milliseconds: 60));
    await tester.tap(row(1));
    await tester.pump();
    await settleFrames(tester);
    expectSheetFor(_b);
    expect(rows(), 2);
    await setSets2AndSave(tester);
    expect(saved(store), [(_b, 2), (d, 1)]);
  });

  testWidgets('F8 the sheet target is deleted while the sheet is open: '
      'nothing is written back, saves [A, C]', (tester) async {
    final store = await openEditor(tester, [_a, _b, _c]);
    await swipeLeft(tester, 1);
    // B is sliding out; tap its still-visible part, which opens B's sheet.
    await tester.tapAt(Offset(150, tester.getCenter(row(1)).dy));
    await tester.pump();
    await settleFrames(tester);
    expectSheetFor(_b);
    expect(rows(), 2, reason: 'B finished deleting under its own sheet');
    await setSets2AndSave(tester);
    expect(saved(store), [(_a, 1), (_c, 1)]);
  });

  testWidgets('F8 reorder (A to the end) then edit A: saves [B, C, A(2)]', (
    tester,
  ) async {
    final store = await openEditor(tester, [_a, _b, _c]);
    final grip = find.descendant(
      of: row(0),
      matching: find.byType(ReorderableDragStartListener),
    );
    final g = await tester.startGesture(tester.getCenter(grip));
    await tester.pump(const Duration(milliseconds: 50));
    for (var k = 0; k < 10; k++) {
      await g.moveBy(const Offset(0, 25));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await g.up();
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: row(2), matching: find.text(sheetTitle(tester, _a))),
      findsOneWidget,
    );
    await tester.tap(row(2));
    await tester.pumpAndSettle();
    expectSheetFor(_a);
    await setSets2AndSave(tester);
    expect(saved(store), [(_b, 1), (_c, 1), (_a, 2)]);
  });
}
