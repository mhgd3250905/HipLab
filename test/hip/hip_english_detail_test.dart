import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiplab/hip/control/hip_store.dart';
import 'package:hiplab/hip/data/hip_public_media.dart';
import 'package:hiplab/hip/domain/hip_library.dart';
import 'package:hiplab/hip/domain/hip_models.dart';
import 'package:hiplab/hip/domain/hip_settings.dart';
import 'package:hiplab/hip/ui/hip_app.dart';
import 'package:hiplab/hip/ui/hip_content_text.dart';
import 'package:hiplab/hip/ui/hip_home_action_inspect.dart';
import 'package:hiplab/hip/ui/hip_theme.dart';
import 'package:hiplab/hip/ui/library/lib_text.dart';
import 'package:ugk_trainer_runtime/ugk_trainer_runtime.dart' as trainer;

import 'hip_domain_test.dart' show MemoryStorage, loadContent;
import 'home_nav.dart';
import 'public_media_fixture.dart';

void main() {
  final content = loadContent();
  const captureKey = ValueKey('english-detail-capture');
  final artifactDirectory = Platform.environment['HIPLAB_ENGLISH_ARTIFACT_DIR'];
  setUpAll(() async {
    final font = FontLoader(hipFontFamily)
      ..addFont(rootBundle.load('assets/fonts/NotoSansSC.ttf'));
    await font.load();
  });

  Future<HipStore> mount(
    WidgetTester tester,
    HipLanguage language, {
    bool withGroup = false,
  }) async {
    tester.view
      ..physicalSize = const Size(394, 853)
      ..devicePixelRatio = 1
      ..padding = const FakeViewPadding(top: 47, bottom: 34);
    addTearDown(tester.view.reset);
    final previous = HipColors.palette;
    addTearDown(() => HipColors.palette = previous);
    final policy = installPublicMediaFixture(sharedLibrary: true).policy;
    final store = HipStore(
      content: content,
      storage: MemoryStorage(),
      clock: () => DateTime(2026, 11, 7, 9, 30),
    );
    await store.initialize();
    store
      ..language = language
      ..theme = HipThemeChoice.dark
      ..safety = {'pregnancy': false, 'surgery': false, 'acute': false}
      ..identity = HipIdentity.office
      ..scene = HipScene.chair;
    if (withGroup) {
      store.customRoutines.add(
        const CustomRoutine(
          id: 'english-detail-group',
          name: '我的自建中文组',
          steps: [CustomStep('s-kneel-hipflex')],
        ),
      );
    }
    await tester.pumpWidget(
      RepaintBoundary(
        key: captureKey,
        child: HipApp(
          key: ObjectKey(store),
          store: store,
          videoEnabled: false,
          mediaPolicy: policy,
        ),
      ),
    );
    await tester.pumpAndSettle();
    return store;
  }

  Future<void> capture(WidgetTester tester, String name) async {
    expect(tester.takeException(), isNull, reason: name);
    if (artifactDirectory == null) return;
    // Permit the bundled posters to finish decoding outside the fake clock.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 80)),
    );
    await tester.pump();
    await tester.runAsync(() async {
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(captureKey),
      );
      final image = await boundary.toImage(pixelRatio: 2);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      final folder = Directory(artifactDirectory)..createSync(recursive: true);
      File(
        '${folder.path}/$name.png',
      ).writeAsBytesSync(data!.buffer.asUint8List());
      image.dispose();
    });
  }

  testWidgets('localized folder and expanded poster retain their selection', (
    tester,
  ) async {
    for (final language in [HipLanguage.zh, HipLanguage.en]) {
      await mount(tester, language);
      final copy = HipContentText(language.id);
      await tester.tap(find.byKey(const ValueKey('home-rotate')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('home-routine-choice-A')),
        findsOneWidget,
      );
      expect(
        find.text(language == HipLanguage.en ? 'Office workouts' : '办公训练'),
        findsOneWidget,
      );
      await capture(tester, '${language.id}-home-folder-expanded');
      await tester.tap(find.byKey(const ValueKey('home-routine-folder-close')));
      await tester.pumpAndSettle();
      await tester.tapAt(
        tester.getCenter(find.byKey(const ValueKey('home-hero'))),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('home-deck-expanded-close')),
        findsOneWidget,
      );
      final front = find.byWidgetPredicate(
        (widget) =>
            widget is HipHomeActionFace && widget.front && widget.expanded,
      );
      expect(front, findsOneWidget);
      expect(
        find.descendant(
          of: front,
          matching: find.text(copy.drillName(content.drill('n-pelvis-circle'))),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: front,
          matching: find.text(
            language == HipLanguage.en ? 'TECHNIQUE NOTES' : '动作要领',
          ),
        ),
        findsOneWidget,
      );
      await capture(tester, '${language.id}-home-poster-expanded');
      await tester.tap(find.byKey(const ValueKey('home-deck-expanded-close')));
      await tester.pumpAndSettle();
      expect(
        find.text(language == HipLanguage.en ? 'Office Reset' : '工位放松'),
        findsOneWidget,
      );
    }
  });

  testWidgets('recommended routine opens localized authored detail', (
    tester,
  ) async {
    for (final language in [HipLanguage.zh, HipLanguage.en]) {
      await mount(tester, language);
      await openGroups(tester);
      await tester.tap(find.byKey(const ValueKey('practice-1')));
      await tester.pumpAndSettle();
      final card = find.byKey(const ValueKey('routine-card-A'));
      await tester.ensureVisible(card);
      await tester.tap(card);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('routine-back')), findsOneWidget);
      expect(
        find.text(
          HipContentText(language.id).routineAudience(content.routine('A')),
        ),
        findsOneWidget,
      );
      expect(find.text(LibText(language.id).copyAsGroup), findsOneWidget);
      await capture(tester, '${language.id}-routine-detail');
    }
  });

  testWidgets(
    'group editor and dose sheet preserve user-authored Chinese name',
    (tester) async {
      for (final language in [HipLanguage.zh, HipLanguage.en]) {
        final store = await mount(tester, language, withGroup: true);
        final t = LibText(language.id);
        await openGroups(tester);
        await tester.tap(
          find.byKey(const ValueKey('group-card-english-detail-group')),
        );
        await tester.pumpAndSettle();
        expect(find.text(t.editGroup), findsOneWidget);
        final field = tester.widget<TextField>(
          find.byKey(const ValueKey('editor-name')),
        );
        expect(field.controller!.text, '我的自建中文组');
        await capture(tester, '${language.id}-group-editor');
        await tester.tap(find.byKey(const ValueKey('editor-row-0')));
        await tester.pumpAndSettle();
        expect(find.text(t.secondsLabel(true)), findsOneWidget);
        expect(find.byKey(const ValueKey('dose-value-up')), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('dose-value-up')));
        await tester.pump();
        await capture(tester, '${language.id}-group-dose');
        await tester.tap(find.byKey(const ValueKey('dose-done')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('editor-close')));
        await tester.pumpAndSettle();
        expect(find.text(t.discardTitle), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('editor-discard')));
        await tester.pumpAndSettle();
        expect(store.customRoutines.single.name, '我的自建中文组');
        expect(store.customRoutines.single.steps.single.seconds, isNull);
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets(
    'SDK action detail uses exact English instructions and safety copy',
    (tester) async {
      for (final language in [HipLanguage.zh, HipLanguage.en]) {
        await mount(tester, language);
        await openPractice(tester);
        // The search remains bilingual in both interface languages.
        await tester.enterText(find.byKey(const ValueKey('lib-search')), '半跪');
        await tester.pumpAndSettle();
        final card = find.byKey(const ValueKey('drill-card-s-kneel-hipflex'));
        await tester.ensureVisible(card);
        final prepared = await tester.runAsync(
          () => trainer.TrainingPosterImages.prepareAsset(
            tester.element(card),
            HipPublicMedia.current!.posterAssetFor('s-kneel-hipflex')!,
          ),
        );
        expect(prepared, isTrue);
        await tester.tap(card);
        await tester.pumpAndSettle();
        expect(find.byType(trainer.TrainingLibraryDetail), findsOneWidget);
        final detail = find.byType(trainer.TrainingLibraryDetail);
        if (language == HipLanguage.en) {
          expect(
            find.descendant(
              of: detail,
              matching: find.text('Half-Kneeling Hip Stretch'),
            ),
            findsOneWidget,
          );
          expect(
            find.descendant(
              of: detail,
              matching: find.textContaining(
                'Place soft padding under the kneeling knee.',
              ),
            ),
            findsOneWidget,
          );
          expect(
            find.descendant(
              of: detail,
              matching: find.textContaining(
                'Squeeze your glute and slowly shift your body forward.',
              ),
            ),
            findsOneWidget,
          );
          expect(
            find.descendant(
              of: detail,
              matching: find.textContaining('Hip flexors'),
            ),
            findsOneWidget,
          );
          expect(
            find.descendant(of: detail, matching: find.text('半跪髋前侧拉伸')),
            findsNothing,
          );
        }
        await capture(tester, '${language.id}-sdk-action-detail');
      }
    },
  );
}
