// PR #22 review (2026-10-19) UI regressions: F1 再来一组 keeps the shared
// audio output open (real route + a fake with JustAudioVoiceOutput's state
// semantics), F2 the editor shows a copied hold, F3 加入训练组 scrolls with
// many groups, F4 看放松 travels back through a routine / an easier move.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiplab/hip/control/hip_store.dart';
import 'package:hiplab/hip/domain/hip_library.dart';
import 'package:hiplab/hip/domain/hip_models.dart';
import 'package:hiplab/hip/domain/hip_pain.dart';
import 'package:hiplab/hip/ui/hip_app.dart';
import 'package:hiplab/hip/ui/hip_player_page.dart';
import 'package:hiplab/hip/ui/library/drill_detail_page.dart';
import 'package:hiplab/hip/ui/library/group_editor_page.dart';
import 'package:hiplab/hip/ui/library/routine_detail_page.dart';
import 'package:hiplab/hip/voice/hip_voice.dart';
import 'package:hiplab/hip/voice/voice_queue.dart';

import 'hip_domain_test.dart' show MemoryStorage, loadContent;
import 'hip_voice_test.dart' show loadVoiceLibrary;

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
    await tester.tap(find.byKey(const ValueKey('tab-1')));
    await tester.pumpAndSettle();
    if (segment != 0) {
      await tester.tap(find.byKey(ValueKey('practice-$segment')));
      await tester.pumpAndSettle();
    }
  }

  Finder practiceScrollable() => find
      .descendant(
        of: find.byKey(const ValueKey('practice-list')),
        matching: find.byType(Scrollable),
      )
      .first;

  Future<void> openDrill(WidgetTester tester, String id) async {
    final card = find.byKey(ValueKey('drill-card-$id'));
    await tester.scrollUntilVisible(
      card,
      400,
      scrollable: practiceScrollable(),
    );
    await tester.ensureVisible(card);
    await tester.pumpAndSettle();
    await tester.tap(card);
    await tester.pumpAndSettle();
    expect(find.byType(DrillDetailPage), findsOneWidget);
  }

  int relaxCount(HipDirection dir) => libraryDrills(
    content,
  ).where((d) => d.directions.contains(dir) && d.isRelax).length;

  group('F1 再来一组 audio', () {
    testWidgets('F1 再来一组 restarts in the same player; output stays active '
        'and round 2 speaks (real route, native-like output)', (tester) async {
      final out = NativeLikeOutput();
      final store = await pumpApp(tester, output: out);
      await toPractice(tester);
      await openDrill(tester, 's-figure4');
      await tester.tap(find.byKey(const ValueKey('detail-start')));
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
      expect(find.byType(DrillDetailPage), findsOneWidget);
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

  group('F3 加入训练组 with many groups', () {
    for (final (size, scale) in [
      (const Size(390, 844), 1.0),
      (const Size(390, 844), 1.5),
      (const Size(320, 568), 1.3),
    ]) {
      testWidgets('F3 12 groups at $size ×$scale: no overflow, the last group '
          'scrolls into reach and takes the move', (tester) async {
        final store = await pumpApp(
          tester,
          size: size,
          textScale: scale,
          setup: (s) {
            for (var i = 1; i <= 12; i++) {
              s.customRoutines.add(
                CustomRoutine(
                  id: 'g$i',
                  name: '训练组 $i',
                  steps: const [CustomStep('h-squat')],
                ),
              );
            }
          },
        );
        await toPractice(tester);
        await openDrill(tester, 's-figure4');
        final add = find.byKey(const ValueKey('detail-add'));
        await tester.ensureVisible(add);
        await tester.pumpAndSettle();
        await tester.tap(add);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final list = find.byKey(const ValueKey('add-group-list'));
        expect(list, findsOneWidget);
        final last = find.byKey(const ValueKey('add-to-g12'));
        await tester.scrollUntilVisible(
          last,
          120,
          scrollable: find
              .descendant(of: list, matching: find.byType(Scrollable))
              .first,
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.tap(last);
        await tester.pumpAndSettle();
        expect(store.customRoutine('g12')!.steps.map((s) => s.kitId), [
          'h-squat',
          's-figure4',
        ]);
      });
    }
  });

  group('F4 看放松 result reaches 动作大全', () {
    testWidgets('F4 recent extension pain → 套路 A → 站姿弓步 → 看放松: back on '
        '动作 filtered to extension relax', (tester) async {
      await pumpApp(
        tester,
        setup: (s) => s.painEvents.add(
          PainEvent(DateTime(2026, 10, 17), HipDirection.extension, 'pain'),
        ),
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
      expect(find.byType(DrillDetailPage), findsOneWidget);
      expect(find.byKey(const ValueKey('notice-pain')), findsOneWidget);
      await tester.tap(find.text('看放松'));
      await tester.pumpAndSettle();
      expect(find.byType(DrillDetailPage), findsNothing);
      expect(find.byType(RoutineDetailPage), findsNothing);
      expect(
        find.textContaining('${relaxCount(HipDirection.extension)} 个动作'),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('drill-card-o-stand-lunge')),
        findsNothing,
      );
    });

    testWidgets('F4 recent internalRotation pain → h-9090-liftoff → 侧卧反向蚌式 '
        '→ 看放松: direction = internalRotation', (tester) async {
      await pumpApp(
        tester,
        setup: (s) => s.painEvents.add(
          PainEvent(
            DateTime(2026, 10, 17),
            HipDirection.internalRotation,
            'pain',
          ),
        ),
      );
      await toPractice(tester);
      await openDrill(tester, 'h-9090-liftoff');
      expect(find.byKey(const ValueKey('notice-advanced')), findsOneWidget);
      await tester.tap(find.textContaining('侧卧反向蚌式').last);
      await tester.pumpAndSettle();
      expect(find.byType(DrillDetailPage), findsOneWidget);
      expect(
        tester.widget<DrillDetailPage>(find.byType(DrillDetailPage)).drillId,
        'h-reverse-clam',
      );
      await tester.tap(find.text('看放松'));
      await tester.pumpAndSettle();
      expect(find.byType(DrillDetailPage), findsNothing);
      expect(
        find.textContaining('${relaxCount(HipDirection.internalRotation)} 个动作'),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('drill-card-h-9090-liftoff')),
        findsNothing,
      );
    });
  });
}
