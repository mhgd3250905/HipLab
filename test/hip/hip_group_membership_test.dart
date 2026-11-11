import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiplab/hip/control/hip_membership.dart';
import 'package:hiplab/hip/control/hip_store.dart';
import 'package:hiplab/hip/domain/hip_library.dart';
import 'package:hiplab/hip/domain/hip_models.dart';
import 'package:hiplab/hip/domain/hip_session.dart';
import 'package:hiplab/hip/ui/hip_membership_page.dart';
import 'package:hiplab/hip/ui/hip_membership_scope.dart';
import 'package:hiplab/hip/ui/hip_theme.dart';
import 'package:hiplab/hip/ui/library/drill_detail_page.dart';
import 'package:hiplab/hip/ui/library/group_editor_page.dart';
import 'package:hiplab/hip/ui/library/library_actions.dart';
import 'package:hiplab/hip/ui/library/practice_page.dart';
import 'package:hiplab/hip/ui/library/routine_detail_page.dart';

import 'hip_domain_test.dart' show MemoryStorage, loadContent;

const _group = CustomRoutine(
  id: 'saved-group',
  name: 'Saved group',
  steps: [CustomStep('h-adductor-rock')],
);

class _MembershipStore implements MembershipStore {
  const _MembershipStore(this.snapshot);
  final MembershipSnapshot snapshot;

  @override
  Future<List<MembershipOffer>> offers() async => const [];
  @override
  Future<MembershipSnapshot> refresh() async => snapshot;
  @override
  Future<MembershipSnapshot> restore() async => snapshot;
  @override
  Future<MembershipSnapshot?> purchase(MembershipTerm term) async => null;
}

void main() {
  final content = loadContent();
  final now = DateTime.utc(2026, 11, 11);
  final paywall = find.byType(HipMembershipPage);

  Future<({HipStore store, HipMembership membership})> mount(
    WidgetTester tester,
    Widget Function(LibraryActions) page, {
    bool premium = false,
    List<TrainingPlan>? started,
  }) async {
    final membership = HipMembership(
      _MembershipStore(
        MembershipSnapshot(
          'test-user',
          premium ? now.add(const Duration(days: 1)) : null,
        ),
      ),
      now: () => now,
    );
    await membership.refresh();
    final store = HipStore(content: content, storage: MemoryStorage());
    await store.initialize();
    store
      ..safety = {'pregnancy': false, 'surgery': false, 'acute': false}
      ..identity = HipIdentity.office;
    await store.saveCustomRoutine(_group);
    addTearDown(membership.dispose);
    addTearDown(store.dispose);
    final actions = LibraryActions(
      store: store,
      startPlan: (plan, {from, radius = 28, originColor}) async {
        started?.add(plan);
      },
    );
    await tester.pumpWidget(
      HipMembershipScope(
        membership: membership,
        child: MaterialApp(theme: hipTheme(), home: page(actions)),
      ),
    );
    await tester.pumpAndSettle();
    return (store: store, membership: membership);
  }

  Widget groups(LibraryActions actions) => PracticePage(
    actions: actions,
    memory: PracticeMemory(),
    onStartAssessment: ({from, radius = 28, color}) {},
  );

  Future<void> tap(WidgetTester tester, String key) async {
    await tester.tap(find.byKey(ValueKey(key)));
    await tester.pumpAndSettle();
  }

  testWidgets('free users can view, start and delete a saved group', (
    tester,
  ) async {
    final started = <TrainingPlan>[];
    final app = await mount(tester, groups, started: started);
    await tap(tester, 'group-card-saved-group');
    expect(find.byKey(const ValueKey('saved-group-details')), findsOneWidget);
    expect(find.byType(GroupEditorPage), findsNothing);
    expect(paywall, findsNothing);
    await tap(tester, 'saved-group-start');
    expect(started.single.refId, _group.id);
    expect(paywall, findsNothing);

    await tap(tester, 'saved-group-edit');
    expect(paywall, findsOneWidget);
    await tap(tester, 'membership-close');
    expect(find.byKey(const ValueKey('saved-group-details')), findsOneWidget);
    expect(find.byType(GroupEditorPage), findsNothing);
    await tap(tester, 'saved-group-delete');
    await tap(tester, 'editor-delete-confirm');
    expect(app.store.customRoutine(_group.id), isNull);
    expect(paywall, findsNothing);
    expect(find.byKey(const ValueKey('saved-group-details')), findsNothing);
  });

  testWidgets(
    'new group and copy require membership before opening an editor',
    (tester) async {
      final started = <TrainingPlan>[];
      final app = await mount(tester, groups, started: started);
      await tap(tester, 'new-group');
      expect(paywall, findsOneWidget);
      await tap(tester, 'membership-close');
      expect(find.byType(DrillPickerPage), findsNothing);

      await tap(tester, 'practice-1');
      final routineCard = find.byKey(
        ValueKey('routine-card-${content.routines.first.id}'),
      );
      await tester.ensureVisible(routineCard);
      await tester.tap(routineCard);
      await tester.pumpAndSettle();
      expect(find.byType(RoutineDetailPage), findsOneWidget);
      expect(paywall, findsNothing);
      await tap(tester, 'routine-start');
      expect(started, hasLength(1));
      await tap(tester, 'routine-copy');
      expect(paywall, findsOneWidget);
      await tap(tester, 'membership-close');
      expect(find.byType(GroupEditorPage), findsNothing);
      expect(app.store.customRoutines.map((group) => group.id), [_group.id]);
    },
  );

  testWidgets('single practice stays free and adding to a group is gated', (
    tester,
  ) async {
    final started = <TrainingPlan>[];
    final app = await mount(
      tester,
      (actions) =>
          DrillDetailPage(actions: actions, drillId: 'h-adductor-rock'),
      started: started,
    );
    await tap(tester, 'detail-start');
    expect(started.single.steps.single.drill.id, 'h-adductor-rock');
    await tap(tester, 'detail-add');
    expect(paywall, findsOneWidget);
    await tap(tester, 'membership-close');
    expect(find.byKey(const ValueKey('add-group-list')), findsNothing);
    expect(app.store.customRoutine(_group.id)!.steps, _group.steps);
  });

  testWidgets('adding to an existing group rechecks access before writing', (
    tester,
  ) async {
    final app = await mount(
      tester,
      (actions) => DrillDetailPage(actions: actions, drillId: 's-pigeon'),
      premium: true,
    );
    await tap(tester, 'detail-add');
    expect(find.byKey(const ValueKey('add-group-list')), findsOneWidget);
    app.membership.rejectPremium();
    await tap(tester, 'add-to-saved-group');
    expect(paywall, findsOneWidget);
    await tap(tester, 'membership-close');
    expect(app.store.customRoutine(_group.id)!.steps, _group.steps);
  });

  testWidgets('the editor rechecks access when saving a draft', (tester) async {
    final app = await mount(tester, groups, premium: true);
    await tap(tester, 'group-card-saved-group');
    expect(find.byType(GroupEditorPage), findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('editor-name')), 'Edited');
    app.membership.rejectPremium();
    await tap(tester, 'editor-save');
    expect(paywall, findsOneWidget);
    await tap(tester, 'membership-close');
    expect(find.byType(GroupEditorPage), findsOneWidget);
    expect(app.store.customRoutine(_group.id)!.name, _group.name);
  });
}
