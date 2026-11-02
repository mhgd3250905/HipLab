import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiplab/hip/control/hip_store.dart';
import 'package:hiplab/hip/domain/hip_models.dart';
import 'package:hiplab/hip/ui/hip_app.dart';
import 'package:hiplab/hip/ui/hip_assessment_page.dart';
import 'package:ugk_trainer_runtime/ugk_trainer_runtime.dart' as trainer;

import 'hip_domain_test.dart' show MemoryStorage, loadContent;
import 'checkup_entry.dart';
import 'public_media_fixture.dart';

Future<void> openDemo(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final store = HipStore(content: loadContent(), storage: MemoryStorage());
  await store.initialize();
  store.safety = {'pregnancy': false, 'surgery': false, 'acute': false};
  store.identity = HipIdentity.office;
  await tester.pumpWidget(
    HipApp(
      mediaPolicy: installPublicMediaFixture().policy,
      store: store,
      videoEnabled: false,
    ),
  );
  await tester.pumpAndSettle();
  await openCheckupIntro(tester);
  await tester.tap(find.byKey(const ValueKey('assessment-start')));
  await tester.pumpAndSettle();
}

Finder get demo => find.byKey(const ValueKey('assessment-demo'));
Finder get toggle => find.byKey(const ValueKey('assessment-demo-toggle'));
Finder get art => find.descendant(
  of: demo,
  matching: find.byType(trainer.TrainingActionMedia),
);

void main() {
  setUpAll(warmHipAppAssets);
  for (final size in [
    const Size(360, 740),
    const Size(390, 844),
    const Size(768, 1024),
  ]) {
    testWidgets('demo stays square and delegates public artwork at $size', (
      tester,
    ) async {
      await openDemo(tester, size);
      final bounds = tester.getRect(demo);
      expect(bounds.width, closeTo(bounds.height, .01));
      expect(bounds.width, lessThanOrEqualTo(520));
      expect(bounds.left, greaterThanOrEqualTo(20));
      expect(bounds.right, lessThanOrEqualTo(size.width - 20));
      final media = tester.widget<trainer.TrainingActionMedia>(art);
      final poster = tester.widget<trainer.TrainerPoster>(
        find.descendant(of: art, matching: find.byType(trainer.TrainerPoster)),
      );
      expect(poster.asset, 'assets/public_posters/${media.actionId}.webp');
      expect(media.playing, isFalse, reason: 'videoEnabled is false');
      expect(
        find.descendant(
          of: find.byType(HipAssessmentPage),
          matching: find.byType(Scrollable),
        ),
        findsNothing,
      );
      final heading = tester.getRect(
        find.byKey(const ValueKey('assessment-question')),
      );
      expect(heading.bottom, lessThanOrEqualTo(bounds.top));
      final option = tester.getRect(find.byKey(const ValueKey('option-2')));
      final pain = tester.getRect(
        find.byKey(const ValueKey('assessment-pain')),
      );
      expect(option.bottom, lessThanOrEqualTo(pain.top));
      expect(
        find.descendant(
          of: demo,
          matching: find.byType(LinearProgressIndicator),
        ),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    });
  }

  for (final (size, scale) in [
    (const Size(320, 568), 1.0),
    (const Size(360, 740), 1.5),
  ]) {
    testWidgets('all six items remain on one screen at $size, text $scale', (
      tester,
    ) async {
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await openDemo(tester, size);
      for (var i = 0; i < 6; i++) {
        final box = tester.getRect(demo);
        for (final media in tester.widgetList<trainer.TrainingActionMedia>(
          art,
        )) {
          expect(
            media.playing,
            isFalse,
            reason: 'item ${i + 1} respects videoEnabled',
          );
        }
        expect(box.width, closeTo(box.height, .01));
        final pain = tester.getRect(
          find.byKey(const ValueKey('assessment-pain')),
        );
        for (var score = 0; score < 3; score++) {
          final rect = tester.getRect(find.byKey(ValueKey('option-$score')));
          expect(rect.top, greaterThanOrEqualTo(box.bottom));
          expect(rect.bottom, lessThanOrEqualTo(pain.top));
        }
        expect(tester.takeException(), isNull, reason: 'item ${i + 1}');
        if (i < 5) {
          await tester.tap(find.byKey(const ValueKey('assessment-skip')));
          await tester.pumpAndSettle();
        }
      }
    });
  }

  testWidgets('tap toggles intent while the host video guard stays disabled', (
    tester,
  ) async {
    await openDemo(tester, const Size(390, 844));
    final initial = tester.widget<trainer.TrainingActionMedia>(art).actionId;
    expect(tester.widget<trainer.TrainingActionMedia>(art).playing, isFalse);
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(tester.widget<trainer.TrainingActionMedia>(art).playing, isFalse);
    expect(find.text('点击播放'), findsOneWidget);
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(tester.widget<trainer.TrainingActionMedia>(art).playing, isFalse);
    expect(find.text('点击暂停'), findsOneWidget);
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    final option = find.byKey(const ValueKey('option-2'));
    await tester.ensureVisible(option);
    await tester.pumpAndSettle();
    await tester.tap(option);
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('assessment-next')));
    await tester.pumpAndSettle();
    expect(
      tester.widget<trainer.TrainingActionMedia>(art).actionId,
      isNot(initial),
    );
    expect(tester.widget<trainer.TrainingActionMedia>(art).playing, isFalse);
    expect(find.text('点击暂停'), findsOneWidget);
  });
}
