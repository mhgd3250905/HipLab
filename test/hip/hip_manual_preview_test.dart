import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiplab/hip/domain/hip_action_media.dart';
import 'package:hiplab/hip/domain/hip_models.dart';
import 'package:hiplab/hip/ui/hip_theme.dart';
import 'package:hiplab/hip/ui/hip_widgets.dart';
import 'package:hiplab/hip/ui/library/hip_manual_preview.dart';
import 'package:ugk_trainer/ugk_trainer.dart' as trainer;

import 'hip_domain_test.dart' show loadContent;

void main() {
  final content = loadContent();
  final first = content.drill('s-figure4');
  final second = content.drill('s-butterfly');
  late HipActionMedia previousMedia;
  late HipPalette previousPalette;

  setUp(() {
    previousMedia = HipMediaVariants.media;
    previousPalette = HipColors.palette;
    HipMediaVariants.media = HipActionMedia.fromJson(
      jsonDecode(File(HipActionMedia.assetPath).readAsStringSync())
          as Map<String, dynamic>,
    );
  });

  tearDown(() {
    HipMediaVariants.media = previousMedia;
    HipColors.palette = previousPalette;
  });

  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    bool video = false,
    bool dark = false,
  }) async {
    final palette = dark ? HipPalette.dark : HipPalette.light;
    HipColors.palette = palette;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        theme: hipTheme(palette),
        home: Scaffold(
          body: HipMediaPolicy(videoEnabled: video, child: child),
        ),
      ),
    );
    await tester.pump();
  }

  Widget preview(
    HipPreviewCoordinator coordinator,
    HipDrill drill,
    String slot,
  ) => SizedBox(
    width: 180,
    child: HipManualPreview(drill: drill, coordinator: coordinator, slot: slot),
  );

  Finder toggle(String slot) =>
      find.byKey(ValueKey('article-video-toggle-$slot'));

  test('coordinator toggles one preview and never auto-resumes', () {
    final coordinator = HipPreviewCoordinator();
    addTearDown(coordinator.dispose);
    expect(coordinator.activeId, isNull);
    expect(coordinator.enabled, isTrue);
    coordinator.toggle('a');
    coordinator.toggle('b');
    expect(coordinator.activeId, 'b');
    coordinator.toggle('b');
    expect(coordinator.activeId, isNull);
    coordinator.toggle('a');
    coordinator.suspend();
    expect(coordinator.enabled, isFalse);
    expect(coordinator.activeId, isNull);
    coordinator.toggle('b');
    expect(coordinator.activeId, isNull);
    coordinator.resume();
    expect(coordinator.enabled, isTrue);
    expect(coordinator.activeId, isNull);
  });

  testWidgets(
    'default stills and explicit mutually exclusive controls honor policy',
    (tester) async {
      final coordinator = HipPreviewCoordinator();
      addTearDown(coordinator.dispose);
      await pump(
        tester,
        Align(
          alignment: Alignment.topCenter,
          child: Column(
            children: [
              preview(coordinator, first, 'first'),
              preview(coordinator, second, 'second'),
            ],
          ),
        ),
      );
      expect(coordinator.activeId, isNull);
      expect(find.byType(trainer.DrillMediaView), findsNothing);
      await tester.tap(toggle('first'));
      await tester.pump();
      expect(coordinator.activeId, 'first');
      await tester.tap(toggle('second'));
      await tester.pump();
      expect(coordinator.activeId, 'second');
      expect(find.byType(trainer.DrillMediaView), findsNothing);
      coordinator.suspend();
      await tester.pump();
      expect(
        tester.widget<HipCircleButton>(toggle('second')).onPressed,
        isNull,
      );
      coordinator.resume();
      await tester.pump();
      expect(coordinator.activeId, isNull);
      expect(tester.takeException(), isNull);
    },
  );

  for (final dark in [false, true]) {
    testWidgets(
      'ordinary ${dark ? 'dark' : 'light'} SDK assets retain paused frame',
      (tester) async {
        final coordinator = HipPreviewCoordinator();
        addTearDown(coordinator.dispose);
        await pump(
          tester,
          Align(
            alignment: Alignment.topCenter,
            child: preview(coordinator, first, 'one'),
          ),
          video: true,
          dark: dark,
        );
        expect(find.byType(trainer.DrillMediaView), findsNothing);
        await tester.tap(toggle('one'));
        await tester.pump();
        var media = tester.widget<trainer.DrillMediaView>(
          find.byType(trainer.DrillMediaView),
        );
        expect(media.playing, isTrue);
        expect(media.paused, isFalse);
        expect(media.media.bundledOnly, isTrue);
        expect(media.media.hasPackedAlpha, isFalse);
        expect(
          media.media.videoFor(light: !dark),
          HipMediaVariants.themed(first.video!, dark: dark),
        );
        expect(
          media.media.posterFor(light: !dark),
          HipMediaVariants.themed(first.poster!, dark: dark),
        );
        expect(File(media.media.videoFor(light: !dark)).existsSync(), isTrue);
        await tester.tap(toggle('one'));
        await tester.pump();
        media = tester.widget<trainer.DrillMediaView>(
          find.byType(trainer.DrillMediaView),
        );
        expect(media.playing, isTrue);
        expect(media.paused, isTrue);
        coordinator.suspend();
        await tester.pump();
        expect(find.byType(trainer.DrillMediaView), findsNothing);
        coordinator.resume();
        await tester.pump();
        expect(find.byType(trainer.DrillMediaView), findsNothing);
        expect(coordinator.activeId, isNull);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'leaving video rectangle stops even while its long article remains',
    (tester) async {
      final coordinator = HipPreviewCoordinator();
      final scroll = ScrollController();
      addTearDown(coordinator.dispose);
      addTearDown(scroll.dispose);
      await pump(
        tester,
        Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: 180,
            height: 300,
            child: ListView(
              controller: scroll,
              children: [
                Column(
                  children: [
                    preview(coordinator, first, 'long'),
                    const SizedBox(
                      height: 1000,
                      child: Text('Long action explanation'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
      await tester.tap(toggle('long'));
      await tester.pump();
      expect(coordinator.activeId, 'long');
      scroll.jumpTo(220);
      await tester.pump();
      await tester.pump();
      expect(coordinator.activeId, isNull);
      scroll.jumpTo(0);
      await tester.pump();
      expect(coordinator.activeId, isNull);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('declared no-video move stays a still with honest copy', (
    tester,
  ) async {
    final coordinator = HipPreviewCoordinator();
    addTearDown(coordinator.dispose);
    final noVideo = HipDrill(
      id: first.id,
      name: first.name,
      directions: first.directions,
      methods: first.methods,
      scenes: first.scenes,
      advanced: first.advanced,
      mvp: first.mvp,
      cautions: first.cautions,
      mediaStatus: HipMediaStatus.poster,
      poster: first.poster,
    );
    await pump(
      tester,
      Align(
        alignment: Alignment.topCenter,
        child: preview(coordinator, noVideo, 'still'),
      ),
    );
    expect(toggle('still'), findsNothing);
    expect(find.text('No video demonstration for this move.'), findsOneWidget);
    expect(find.byType(trainer.DrillMediaView), findsNothing);
    expect(coordinator.activeId, isNull);
    expect(tester.takeException(), isNull);
  });
}
