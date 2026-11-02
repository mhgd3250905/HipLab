// Host regressions retained after SDK library adoption: replay audio, copied
// doses, exact group editing, and scoped detail callbacks with host safety.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiplab/hip/control/hip_store.dart';
import 'package:hiplab/hip/domain/hip_library.dart';
import 'package:hiplab/hip/domain/hip_models.dart';
import 'package:hiplab/hip/ui/hip_app.dart';
import 'package:hiplab/hip/ui/hip_player_page.dart';
import 'package:ugk_trainer_runtime/ugk_trainer_runtime.dart' as trainer;
import 'package:hiplab/hip/ui/library/group_editor_page.dart';
import 'package:hiplab/hip/ui/library/routine_detail_page.dart';
import 'package:hiplab/hip/voice/hip_voice.dart';
import 'package:hiplab/hip/voice/voice_queue.dart';

import 'hip_domain_test.dart' show MemoryStorage, loadContent;
import 'hip_voice_test.dart' show loadVoiceLibrary;
import 'home_nav.dart';
import 'public_media_fixture.dart';

final _now = DateTime(2026, 10, 19, 9, 41);

/// Same session state as JustAudioVoiceOutput: begin() is a no-op while a
/// session is open, end() closes it at once, and speak / chime outside an
/// open session are dropped (lib/hip/voice/just_audio_output.dart).
class NativeLikeOutput implements VoiceOutput {
  bool began = false;
  final events = <String>[];
  final spoken = <List<String>>[];
  int dropped = 0;

  @override
  Future<void> begin() async {
    events.add('begin');
    if (began) return;
    began = true;
  }

  @override
  Future<void> end() async {
    events.add('end');
    began = false;
  }

  @override
  Future<void> speak(List<String> assets) async {
    if (!began) {
      dropped++;
      return;
    }
    spoken.add(assets);
  }

  @override
  Future<void> stopSpeech() async {}
  @override
  Future<void> chime(String asset) async {
    if (!began) dropped++;
  }

  @override
  set volume(double v) {}
}

void main() {
  final content = loadContent();

  Future<HipStore> pumpApp(
    WidgetTester tester, {
    Size size = const Size(390, 844),
    double textScale = 1,
    void Function(HipStore)? setup,
    VoiceOutput? output,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final fixture = installPublicMediaFixture(sharedLibrary: true);
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
    setup?.call(store);
    await tester.pumpWidget(
      HipApp(
        store: store,
        videoEnabled: false,
        mediaPolicy: fixture.policy,
        voice: output == null
            ? null
            : HipVoice(
                lib: loadVoiceLibrary(),
                output: output,
                settingsOf: () => store.voice,
              ),
      ),
    );
    await tester.pumpAndSettle();
    return store;
  }

  Future<void> toPractice(WidgetTester tester, {int segment = 0}) async {
    await openPractice(tester);
    await tester.pumpAndSettle();
    if (segment != 0) {
      await tester.tap(find.byKey(ValueKey('practice-$segment')));
      await tester.pumpAndSettle();
    }
  }

  Future<void> openDrill(WidgetTester tester, String id) async {
    final page = tester.widget<trainer.TrainingLibraryPage>(
      find.byType(trainer.TrainingLibraryPage),
    );
    await tester.enterText(
      find.byKey(const ValueKey('posehub-search')),
      page.mediaPolicy.actionFor(id)!.nameZh,
    );
    await tester.pumpAndSettle();
    final card = find.byKey(ValueKey('posehub-action-$id'));
    await tester.ensureVisible(card);
    await tester.pumpAndSettle();
    final prepared = await tester.runAsync(
      () => trainer.TrainingPosterImages.prepareAsset(
        tester.element(card),
        page.mediaPolicy.posterAssetFor(id)!,
      ),
    );
    expect(prepared, isTrue);
    await tester.tap(card);
    await tester.pumpAndSettle();
    expect(find.byType(trainer.TrainingLibraryDetail), findsOneWidget);
  }

  group('F1 再来一组 audio', () {
    testWidgets('F1 再来一组 restarts in the same player; output stays active '
        'and round 2 speaks (real route, native-like output)', (tester) async {
      final out = NativeLikeOutput();
      final store = await pumpApp(tester, output: out);
      await toPractice(tester);
      await openDrill(tester, 's-figure4');
      final start = find.byKey(const ValueKey('library-detail-start'));
      await tester.ensureVisible(start);
      await tester.tap(start);
      await tester.pumpAndSettle(const Duration(milliseconds: 100));
      expect(find.byType(HipPlayerPage), findsOneWidget);
      expect(out.began, isTrue);
      await tester.pump(const Duration(seconds: 2));
      expect(out.spoken, isNotEmpty, reason: 'round 1 speaks');
      // Let both sides finish naturally so this is completed practice,
      // rather than a skipped session that must not count as completed.
      for (var i = 0; i < 180; i++) {
        if (find.byKey(const ValueKey('player-again')).evaluate().isNotEmpty) {
          break;
        }
        await tester.pump(const Duration(seconds: 1));
      }
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('player-again')), findsOneWidget);
      expect(store.sessions.where((s) => s.completed).length, 1);
      final player = tester.state(find.byType(HipPlayerPage));

      // Replay starts its welcome cue immediately. Measure from before the
      // tap, rather than requiring another cue in an arbitrary later 3s gap.
      final beforeRound2 = out.spoken.length;
      await tester.tap(find.byKey(const ValueKey('player-again')));
      await tester.pumpAndSettle(const Duration(milliseconds: 100));
      // The output is still open for round 2 (was: begin → begin → end).
      expect(find.byType(HipPlayerPage), findsOneWidget);
      expect(out.events.where((e) => e == 'end'), isEmpty);
      expect(out.began, isTrue);
      await tester.pump(const Duration(seconds: 3));
      expect(out.dropped, 0);
      expect(
        out.spoken.length,
        greaterThan(beforeRound2),
        reason: 'round 2 speaks through the still-open shared output',
      );
      expect(
        out.spoken.skip(beforeRound2).expand((assets) => assets),
        contains(loadVoiceLibrary().asset('p.welcome', lang: 'zh')),
        reason: 'the new round schedules its own welcome voice',
      );
      // Same page: no second route whose old page would end() the output.
      expect(tester.state(find.byType(HipPlayerPage)), same(player));
      expect(find.byKey(const ValueKey('player-again')), findsNothing);
      expect(find.byKey(const ValueKey('skip')), findsOneWidget);

      // Round 2 finishes and logs a 2nd single session; 完成 ends audio once.
      for (var i = 0; i < 180; i++) {
        if (find.byKey(const ValueKey('player-again')).evaluate().isNotEmpty) {
          break;
        }
        await tester.pump(const Duration(seconds: 1));
      }
      await tester.pumpAndSettle();
      expect(store.sessions.where((s) => s.completed).length, 2);
      expect(store.doneDays, isEmpty);
      await tester.tap(find.byKey(const ValueKey('finish')));
      await tester.pumpAndSettle();
      expect(find.byType(HipPlayerPage), findsNothing);
      expect(find.byType(trainer.TrainingLibraryPage), findsOneWidget);
      expect(out.events.where((e) => e == 'end').length, 1);
      expect(out.began, isFalse);
    });
  });

  group('F2 editor shows the copied hold', () {
    testWidgets('F2 copy F → editor row says 停 15 秒 for h-sumo-pry', (
      tester,
    ) async {
      final g = copyRoutine(
        content.routine('F'),
        content,
        id: 'f-copy',
        name: 'F（我的）',
        at: _now,
      );
      await pumpApp(tester, setup: (s) => s.customRoutines.add(g));
      await toPractice(tester, segment: 2);
      await tester.tap(find.byKey(const ValueKey('group-card-f-copy')));
      await tester.pumpAndSettle();
      expect(find.byType(GroupEditorPage), findsOneWidget);
      final i = g.steps.indexWhere((s) => s.kitId == 'h-sumo-pry');
      final row = find.byKey(ValueKey('editor-row-$i'));
      await tester.scrollUntilVisible(
        row,
        200,
        scrollable: find
            .descendant(
              of: find.byKey(const ValueKey('editor-steps')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(
        find.descendant(of: row, matching: find.text('3 次 × 停 15 秒')),
        findsOneWidget,
      );
    });
  });

  testWidgets('ordinary group editing targets the chosen group among twelve', (
    tester,
  ) async {
    final store = await pumpApp(
      tester,
      setup: (store) {
        for (var index = 1; index <= 12; index++) {
          store.customRoutines.add(
            CustomRoutine(
              id: 'g$index',
              name: '训练组 $index',
              steps: const [CustomStep('h-squat')],
            ),
          );
        }
      },
    );
    await toPractice(tester, segment: 2);
    final group = find.byKey(const ValueKey('group-card-g12'));
    await tester.scrollUntilVisible(
      group,
      300,
      scrollable: find
          .descendant(
            of: find.byKey(const ValueKey('practice-list')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
    await Scrollable.ensureVisible(tester.element(group), alignment: .5);
    await tester.pumpAndSettle();
    expect(group.hitTestable(), findsOneWidget);
    await tester.tap(group);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('editor-add')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('pick-h-9090-liftoff')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('picker-add')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('editor-save')));
    await tester.pumpAndSettle();
    expect(store.customRoutine('g12')!.steps.map((step) => step.kitId), [
      'h-squat',
      'h-9090-liftoff',
    ]);
    expect(store.customRoutine('g11')!.steps.map((step) => step.kitId), [
      'h-squat',
    ]);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'routine step opens scoped SDK detail and keeps host safety gate',
    (tester) async {
      await pumpApp(
        tester,
        setup: (store) => store.safety = {
          'pregnancy': true,
          'surgery': false,
          'acute': false,
        },
      );
      await toPractice(tester, segment: 1);
      await tester.tap(find.byKey(const ValueKey('routine-card-A')));
      await tester.pumpAndSettle();
      expect(find.byType(RoutineDetailPage), findsOneWidget);
      final step = find.byKey(const ValueKey('routine-step-o-stand-lunge'));
      await tester.scrollUntilVisible(
        step,
        200,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(step);
      await tester.pumpAndSettle();
      final detail = tester.widget<trainer.TrainingLibraryDetail>(
        find.byType(trainer.TrainingLibraryDetail),
      );
      expect(detail.action.id, 'o-stand-lunge');
      expect(detail.canStart, isFalse);
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const ValueKey('library-detail-start')),
            )
            .onPressed,
        isNull,
      );
      Navigator.of(
        tester.element(find.byType(trainer.TrainingLibraryDetail)),
      ).pop();
      await tester.pumpAndSettle();
      expect(find.byType(RoutineDetailPage), findsOneWidget);
    },
  );
}
