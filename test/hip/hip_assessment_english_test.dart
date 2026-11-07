import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiplab/hip/control/hip_store.dart';
import 'package:hiplab/hip/domain/hip_library.dart';
import 'package:hiplab/hip/domain/hip_progress.dart';
import 'package:hiplab/hip/ui/hip_assessment_page.dart';
import 'package:hiplab/hip/ui/hip_assessment_text.dart';
import 'package:hiplab/hip/ui/hip_content_text.dart';
import 'package:hiplab/hip/ui/hip_privacy_page.dart';
import 'package:hiplab/hip/ui/hip_records_page.dart';
import 'package:hiplab/hip/ui/hip_theme.dart';

import 'hip_domain_test.dart' show MemoryStorage, loadContent;

void main() {
  final han = RegExp(r'[\u3400-\u9fff]');

  test(
    'every frozen check-up display field and route has an English translation',
    () {
      final content = loadContent();
      final fields = <String>[];
      for (final item in content.rules.items) {
        fields.addAll([
          item.title,
          item.question,
          item.cue,
          item.area,
          if (item.aka != null) item.aka!,
          if (item.dancerNote != null) item.dancerNote!,
          if (item.followUpQuestion != null) item.followUpQuestion!,
          for (final option in item.options) ...[
            option.label,
            option.description,
          ],
          for (final option in item.followUp) option.label,
        ]);
      }
      final raw =
          jsonDecode(File('assets/hip/hip-content.json').readAsStringSync())
              as Map;
      final assessment = raw['assessment'] as Map;
      for (final routes in (assessment['recommendations'] as Map).values) {
        for (final route in (routes as Map).values) {
          fields.add((route as Map)['route'] as String);
        }
      }
      for (final field in fields) {
        expect(HipAssessmentText.zh.text(field), field);
        final translated = HipAssessmentText.en.text(field);
        expect(translated, isNotEmpty, reason: field);
        expect(han.hasMatch(translated), isFalse, reason: field);
      }
    },
  );

  Future<void> pumpEnglish(
    WidgetTester tester,
    Widget child, {
    TargetPlatform platform = TargetPlatform.android,
  }) async {
    tester.view
      ..physicalSize = const Size(394, 853)
      ..devicePixelRatio = 1
      ..padding = const FakeViewPadding(top: 47, bottom: 34);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: const [Locale('zh'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        theme: hipTheme(HipPalette.dark).copyWith(platform: platform),
        home: Scaffold(body: child),
      ),
    );
    await tester.pumpAndSettle();
  }

  Iterable<String> renderedText(WidgetTester tester) sync* {
    for (final text in tester.widgetList<Text>(find.byType(Text))) {
      yield text.data ?? text.textSpan?.toPlainText() ?? '';
    }
    for (final text in tester.widgetList<SelectableText>(
      find.byType(SelectableText),
    )) {
      yield text.data ?? text.textSpan?.toPlainText() ?? '';
    }
  }

  testWidgets(
    'English check-up intro shows authored move names without overflow',
    (tester) async {
      final store = HipStore(content: loadContent(), storage: MemoryStorage());
      await pumpEnglish(
        tester,
        HipAssessmentIntro(store: store, onStart: () {}),
      );
      expect(find.text('Hip check-up'), findsOneWidget);
      expect(find.text('Hip flexor check'), findsOneWidget);
      expect(find.text('Start check-up'), findsOneWidget);
      expect(renderedText(tester).where(han.hasMatch), isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
    testWidgets('English offline privacy policy is complete on $platform', (
      tester,
    ) async {
      await pumpEnglish(tester, const HipPrivacyPage(), platform: platform);
      final seen = <String>{};
      for (var i = 0; i < 18; i++) {
        seen.addAll(renderedText(tester));
        expect(renderedText(tester).where(han.hasMatch), isEmpty);
        if (find.text('Public privacy policy').evaluate().isNotEmpty) break;
        await tester.drag(find.byType(ListView), const Offset(0, -500));
        await tester.pumpAndSettle();
      }
      for (final title in [
        'How we handle your information',
        'Records stored only on your device',
        'Retention, deletion and system backups',
        'Video, network access and permissions',
        'Training audio and background playback',
        'Exercise and health notice',
        'Policy updates and contact',
        'Public privacy policy',
      ]) {
        expect(seen, contains(title));
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'English records preserve custom names and translate known built-in IDs',
    (tester) async {
      final now = DateTime(2026, 11, 7, 9);
      final store = HipStore(
        content: loadContent(),
        storage: MemoryStorage(),
        clock: () => now,
      );
      store.doneDays.add(dayKey(now));
      store.sessions.addAll([
        SessionRecord(
          at: now,
          source: PlanSource.routine,
          refId: 'A',
          title: '工位放松',
          seconds: 180,
          completed: true,
        ),
        SessionRecord(
          at: now,
          source: PlanSource.custom,
          title: '我的日常',
          seconds: 300,
          completed: false,
        ),
      ]);
      await pumpEnglish(tester, HipRecordsView(store: store));
      expect(find.text('This week'), findsOneWidget);
      expect(find.text('Last 16 weeks'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('records-recent')),
        300,
        scrollable: find.byType(Scrollable),
      );
      await tester.pumpAndSettle();
      expect(find.text('我的日常'), findsOneWidget);
      expect(
        find.text(HipContentText.en.routineName(store.content.routine('A'))),
        findsOneWidget,
      );
      expect(find.text('Today 09:00 · Unfinished'), findsOneWidget);
      expect(store.sessions[0].title, '工位放松');
      expect(store.sessions[1].title, '我的日常');
      expect(tester.takeException(), isNull);
    },
  );
}
