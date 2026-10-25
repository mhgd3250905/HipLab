import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiplab/hip/ui/hip_theme.dart';
import 'package:hiplab/hip/ui/hip_widgets.dart';
import 'package:hiplab/hip/ui/library/hip_manual_preview.dart';
import 'package:hiplab/hip/ui/library/hip_training_article.dart';

import 'hip_domain_test.dart' show loadContent;

void main() {
  final content = loadContent();
  final steps = [
    HipArticleStep(
      drill: content.drill('s-figure4'),
      dose: '每侧 40 秒',
      section: '放松',
      note: '保持自然呼吸',
    ),
    HipArticleStep(
      drill: content.drill('s-butterfly'),
      dose: '30 秒',
      section: '收尾',
      note: '最后一段真实安排',
    ),
  ];

  Future<void> show(
    WidgetTester tester, {
    double width = 390,
    double scale = 1,
    bool dark = false,
    Future<void> Function(BuildContext?)? onStart,
  }) async {
    tester.view.physicalSize = Size(width, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final palette = dark ? HipPalette.dark : HipPalette.light;
    HipColors.palette = palette;
    addTearDown(() => HipColors.palette = HipPalette.dark);
    await tester.pumpWidget(
      MaterialApp(
        theme: hipTheme(palette),
        home: MediaQuery(
          data: MediaQueryData(
            size: Size(width, 844),
            textScaler: TextScaler.linear(scale),
            viewPadding: const EdgeInsets.only(bottom: 24),
          ),
          child: HipMediaPolicy(
            videoEnabled: false,
            child: Scaffold(
              body: HipTrainingArticle(
                content: content,
                title: '髋部放松',
                introduction: '沿用现有动作包的训练安排。',
                seconds: 180,
                restSeconds: 15,
                steps: steps,
                startKey: const ValueKey('article-start'),
                onStart: onStart,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'article shows real sequence, dose and section with still previews',
    (tester) async {
      await show(tester, onStart: (_) async {});
      expect(find.text('髋部放松'), findsOneWidget);
      expect(find.text('沿用现有动作包的训练安排。'), findsOneWidget);
      expect(find.text('每侧 40 秒'), findsOneWidget);
      expect(find.text('放松'), findsOneWidget);
      final preview = tester.widget<HipManualPreview>(
        find.byType(HipManualPreview).first,
      );
      expect(preview.coordinator.activeId, isNull);
      expect(find.byType(Card), findsNothing);
      await tester.scrollUntilVisible(
        find.text('收尾'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('收尾'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'start hands off after previews are disabled and never auto-resumes',
    (tester) async {
      var starts = 0;
      HipPreviewCoordinator? coordinator;
      await show(
        tester,
        onStart: (_) async {
          starts++;
          expect(coordinator!.enabled, isFalse);
          expect(coordinator.activeId, isNull);
        },
      );
      coordinator = tester
          .widget<HipManualPreview>(find.byType(HipManualPreview).first)
          .coordinator;
      await tester.tap(find.byKey(const ValueKey('article-video-toggle-0')));
      await tester.pump();
      expect(coordinator.activeId, '0');
      await tester.tap(find.byKey(const ValueKey('article-start')));
      await tester.pumpAndSettle();
      expect(starts, 1);
      expect(coordinator.enabled, isTrue);
      expect(coordinator.activeId, isNull);
    },
  );

  testWidgets('blocked start stays disabled', (tester) async {
    await show(tester);
    expect(
      tester
          .widget<HipPrimaryButton>(find.byKey(const ValueKey('article-start')))
          .onPressed,
      isNull,
    );
  });

  for (final dark in [false, true]) {
    testWidgets(
      'narrow ${dark ? 'dark' : 'light'} article clears floating action and system inset',
      (tester) async {
        await show(
          tester,
          width: 320,
          scale: 1.3,
          dark: dark,
          onStart: (_) async {},
        );
        final scroll = tester
            .state<ScrollableState>(find.byType(Scrollable).first)
            .position;
        scroll.jumpTo(scroll.maxScrollExtent);
        await tester.pumpAndSettle();
        final last = tester.getRect(find.text('最后一段真实安排'));
        final start = tester.getRect(
          find.byKey(const ValueKey('article-start')),
        );
        expect(last.bottom, lessThan(start.top));
        expect(start.bottom, lessThanOrEqualTo(844 - 24));
        expect(tester.takeException(), isNull);
      },
    );
  }
}
