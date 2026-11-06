// UI r2 M4: 训练记录 achievement rules (pure) and the page's sections.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiplab/hip/control/hip_store.dart';
import 'package:hiplab/hip/domain/hip_library.dart';
import 'package:hiplab/hip/domain/hip_progress.dart';
import 'package:hiplab/hip/ui/hip_records_page.dart';
import 'package:hiplab/hip/ui/hip_widgets.dart';

import 'hip_domain_test.dart' show MemoryStorage, loadContent;

void main() {
  test('streakHistory: best run and the day each milestone was reached', () {
    final days = {
      for (var d = 1; d <= 4; d++) dayKey(DateTime(2026, 10, d)),
      for (var d = 20; d <= 27; d++) dayKey(DateTime(2026, 10, d)),
    };
    final h = streakHistory(days);
    expect(h.best, 8);
    expect(h.earned[3], DateTime(2026, 10, 3));
    expect(h.earned[7], DateTime(2026, 10, 26));
    expect(h.earned.containsKey(14), isFalse);
    expect(streakHistory({}).best, 0);
  });

  test('heatLevel by minutes; trained without a timed record is 1', () {
    expect(heatLevel(trained: false, minutes: 0), 0);
    expect(heatLevel(trained: true, minutes: 0), 1);
    expect(heatLevel(trained: true, minutes: 7), 2);
    expect(heatLevel(trained: true, minutes: 30), 4);
  });

  testWidgets('records: streak, milestones marked, no radar; celebrated once', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(393 * 3, 1800 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final now = DateTime(2026, 11, 2, 9);
    final store = HipStore(
      content: loadContent(),
      storage: MemoryStorage(),
      clock: () => now,
    );
    store.doneDays.addAll([
      for (var i = 0; i < 8; i++) dayKey(DateTime(2026, 11, 2 - i)),
    ]);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh'),
        supportedLocales: const [Locale('zh'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(body: HipRecordsView(store: store)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('records-streak')), findsOneWidget);
    expect(find.text('8'), findsOneWidget);
    expect(find.text('还差 6 天'), findsOneWidget);
    expect(find.byType(HipRadar), findsNothing);
    expect(store.celebratedMilestone, 7);
  });

  testWidgets('records sums daily seconds before rounding heatmap minutes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(393 * 3, 1800 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final now = DateTime(2026, 11, 2, 9);
    final store = HipStore(
      content: loadContent(),
      storage: MemoryStorage(),
      clock: () => now,
    );
    store.doneDays.add(dayKey(now));
    store.sessions.addAll([
      for (var i = 0; i < 2; i++)
        SessionRecord(
          at: now.add(Duration(hours: i)),
          source: PlanSource.custom,
          title: '训练 ${i + 1}',
          seconds: 271,
          completed: true,
        ),
    ]);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh'),
        supportedLocales: const [Locale('zh'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(body: HipRecordsView(store: store)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('9 分钟', findRichText: true), findsOneWidget);
    final heatmap = find.byKey(const ValueKey('records-heatmap'));
    final paint = tester.widget<CustomPaint>(
      find.descendant(of: heatmap, matching: find.byType(CustomPaint)),
    );
    final dynamic painter = paint.painter;
    expect(painter.levels[15][now.weekday - 1], 2);
  });

  testWidgets('records empty state offers one start action', (tester) async {
    final store = HipStore(content: loadContent(), storage: MemoryStorage());
    var started = 0;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh'),
        supportedLocales: const [Locale('zh'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
          body: HipRecordsView(store: store, onStartPractice: () => started++),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('records-empty')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('records-start')));
    expect(started, 1);
  });
}
