// iOS-specific behaviour that can be checked without a Mac:
//
// * audio interruptions (call / Siri / unplugged headphones) pause the
//   training session silently and resuming takes the audio session back;
// * on iPhone safe areas (notch / Dynamic Island / Home indicator) no fixed
//   control or text of the main screens sits under the status bar or the
//   Home indicator, and scrolled lists can bring their last control above
//   the Home indicator. Runs with the iOS target platform (Cupertino page
//   transitions, bouncing scroll physics).
//
// Real-device checks that tests can't do are listed in
// docs/ios-setup-and-release.md.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiplab/hip/control/hip_store.dart';
import 'package:hiplab/hip/domain/hip_assessment.dart';
import 'package:hiplab/hip/domain/hip_models.dart';
import 'package:hiplab/hip/ui/hip_app.dart';
import 'package:hiplab/hip/ui/hip_privacy_page.dart';
import 'package:hiplab/hip/ui/hip_theme.dart';
import 'package:hiplab/hip/voice/hip_voice.dart';
import 'package:hiplab/hip/voice/voice_library.dart';
import 'package:hiplab/hip/voice/voice_queue.dart';
import 'package:ugk_trainer/ugk_trainer.dart' as trainer;

import 'hip_domain_test.dart' show MemoryStorage, loadContent;
import 'checkup_entry.dart';

/// Records what the player asks of the audio layer and lets the test fire
/// OS interruptions.
class FakeInterruptibleOutput implements VoiceOutput, InterruptibleVoiceOutput {
  final events = StreamController<AudioInterruption>.broadcast();
  final spoken = <List<String>>[];
  int reactivations = 0;
  int begins = 0;
  int ends = 0;
  @override
  Stream<AudioInterruption> get interruptions => events.stream;
  @override
  Future<void> reactivate() async => reactivations++;
  @override
  Future<void> begin() async => begins++;
  @override
  Future<void> end() async => ends++;
  @override
  Future<void> speak(List<String> assets) async => spoken.add(assets);
  @override
  Future<void> stopSpeech() async {}
  @override
  Future<void> chime(String asset) async {}
  @override
  set volume(double v) {}
}

/// iPhone screens in logical points with their portrait safe-area insets.
class IPhone {
  const IPhone(this.name, this.size, this.top, this.bottom);
  final String name;
  final Size size;
  final double top;
  final double bottom;
}

const iPhones = [
  IPhone('iPhone 15 Pro (Dynamic Island)', Size(393, 852), 59, 34),
  IPhone('iPhone 15 Pro Max', Size(430, 932), 59, 34),
  IPhone('iPhone 13 mini (notch)', Size(375, 812), 50, 34),
  IPhone('iPhone SE 3 (Home button)', Size(375, 667), 20, 0),
];

final content = loadContent();

Future<HipStore> bootIos(
  WidgetTester tester, {
  IPhone phone = const IPhone('iPhone 15 Pro', Size(393, 852), 59, 34),
  bool onboarded = true,
  HipVoice? voice,
  HipThemeChoice theme = HipThemeChoice.dark,
}) async {
  tester.view.physicalSize = phone.size * 3;
  tester.view.devicePixelRatio = 3;
  final pad = FakeViewPadding(top: phone.top * 3, bottom: phone.bottom * 3);
  tester.view.padding = pad;
  tester.view.viewPadding = pad;
  addTearDown(tester.view.reset);
  final now = DateTime(2026, 10, 16, 9, 41);
  final store = HipStore(
    content: content,
    storage: MemoryStorage(),
    clock: () => now,
  );
  await store.initialize();
  store.theme = theme;
  if (onboarded) {
    store
      ..safety = {'pregnancy': false, 'surgery': false, 'acute': false}
      ..identity = HipIdentity.dancer
      ..minutes = 10
      ..scene = HipScene.home;
    ItemAnswer one(int s) => ItemAnswer.single(SideAnswer.choice(s));
    ItemAnswer two(int l, int r) => ItemAnswer.sided(
      left: SideAnswer.choice(l),
      right: SideAnswer.choice(r),
    );
    store.assessments.add((
      at: now,
      answers: {
        'butterfly': one(1),
        'ninety_ninety': two(1, 1),
        'thomas': two(0, 1),
        'supine_cross': two(1, 1),
        'seated_fold': one(2),
        'deep_squat': one(2),
      },
    ));
  }
  await tester.pumpWidget(
    HipApp(store: store, videoEnabled: false, voice: voice),
  );
  await tester.pumpAndSettle();
  return store;
}

bool _inScrollable(Element e) {
  var found = false;
  e.visitAncestorElements((a) {
    if (a.widget is Scrollable) {
      found = true;
      return false;
    }
    return true;
  });
  return found;
}

bool _isControl(Widget w) =>
    (w is InkWell && (w.onTap != null || w.onLongPress != null)) ||
    (w is GestureDetector && w.onTap != null) ||
    (w is ButtonStyleButton && w.onPressed != null) ||
    (w is IconButton && w.onPressed != null);

/// Every fixed (not scrolling) control and text line that is on screen must
/// be inside the safe area; returns the offenders.
List<String> safeAreaOffenders(WidgetTester tester, IPhone phone) {
  final h = phone.size.height;
  final w = phone.size.width;
  final bad = <String>[];
  for (final e
      in find
          .byWidgetPredicate((w) => _isControl(w) || w is Text || w is RichText)
          .evaluate()) {
    final ro = e.renderObject;
    if (ro is! RenderBox || !ro.hasSize || !ro.attached) continue;
    if (_inScrollable(e)) continue;
    final r = ro.localToGlobal(Offset.zero) & ro.size;
    if (r.width == 0 || r.height == 0) continue;
    // Fully off screen (a page behind the current one, a hidden layer).
    if (r.bottom <= 0 || r.top >= h || r.right <= 0 || r.left >= w) continue;
    final tooHigh = r.top < phone.top - .5;
    final tooLow = r.bottom > h - phone.bottom + .5;
    if (tooHigh || tooLow) {
      final label = e.widget is Text
          ? '"${(e.widget as Text).data ?? (e.widget as Text).textSpan?.toPlainText()}"'
          : e.widget.runtimeType.toString();
      bad.add('$label ${r.toString()}');
    }
  }
  return bad;
}

/// After scrolling the main list to its end, its last control must clear
/// the Home indicator (the list's bottom padding includes the inset).
Future<List<String>> scrolledEndOffenders(
  WidgetTester tester,
  IPhone phone,
) async {
  final lists = find.byType(Scrollable);
  if (lists.evaluate().isEmpty) return const [];
  final scrollable = tester.state<ScrollableState>(lists.first);
  scrollable.position.jumpTo(scrollable.position.maxScrollExtent);
  await tester.pumpAndSettle();
  double lastBottom = 0;
  for (final e in find.byWidgetPredicate(_isControl).evaluate()) {
    if (!_inScrollable(e)) continue;
    final ro = e.renderObject;
    if (ro is! RenderBox || !ro.hasSize) continue;
    final r = ro.localToGlobal(Offset.zero) & ro.size;
    if (r.top >= phone.size.height) continue;
    if (r.bottom > lastBottom) lastBottom = r.bottom;
  }
  final limit = phone.size.height - phone.bottom + .5;
  return lastBottom > limit
      ? ['last scrolled control ends at $lastBottom > $limit']
      : const [];
}

void main() {
  final ios = TargetPlatformVariant.only(TargetPlatform.iOS);

  testWidgets('iOS base release hides both AI entry points', (tester) async {
    await bootIos(tester);
    await tester.tap(find.byKey(const ValueKey('tab-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('我的'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('new-group')), findsOneWidget);
    expect(find.text('AI 定制训练'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('tab-2')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('这是运动练习，不能替代医生的建议。'), 300);
    expect(find.text('AI 定制用量'), findsNothing);
    expect(find.byKey(const ValueKey('voice-preview')), findsNothing);
  }, variant: ios);

  testWidgets('iOS privacy explains the offline audio session', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: TargetPlatform.iOS),
        home: const HipPrivacyPage(),
      ),
    );
    await tester.scrollUntilVisible(
      find.text('训练语音与后台播放'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('iOS 后台音频'), findsOneWidget);
    expect(find.text('AI 入口与本地预设'), findsNothing);
    expect(find.textContaining('媒体播放前台服务'), findsNothing);
  }, variant: ios);

  group('audio interruptions pause the session', () {
    late FakeInterruptibleOutput output;
    late HipVoice voice;
    setUp(() {
      output = FakeInterruptibleOutput();
      final lib = VoiceLibrary.fromJson(
        jsonDecode(File('assets/voice/manifest.json').readAsStringSync())
            as Map<String, dynamic>,
      );
      voice = HipVoice(
        lib: lib,
        output: output,
        settingsOf: () => const VoiceSettings(),
      );
    });

    for (final kind in [AudioInterruption.began, AudioInterruption.unplugged]) {
      testWidgets('${kind.name}: pauses silently, 继续 re-activates audio', (
        tester,
      ) async {
        await bootIos(tester, voice: voice);
        await tester.tap(find.byKey(const ValueKey('start-today')));
        await tester.pump(const Duration(seconds: 2));
        expect(output.begins, 1);
        expect(find.text('已暂停'), findsNothing);
        final spokenBefore = output.spoken.length;

        output.events.add(kind);
        await tester.pump(const Duration(milliseconds: 200));
        expect(find.text('已暂停'), findsOneWidget);
        // No "已暂停" announcement into a phone call.
        expect(output.spoken.length, spokenBefore);

        // Time passes on the call: the ring does not move.
        final ring = find.byKey(const ValueKey('pause'));
        expect(ring, findsOneWidget);
        final pausedCounter = tester
            .widget<trainer.TrainerCountdownDigits>(
              find.byType(trainer.TrainerCountdownDigits),
            )
            .value;
        await tester.pump(const Duration(seconds: 20));
        expect(find.text('已暂停'), findsOneWidget);
        expect(
          tester
              .widget<trainer.TrainerCountdownDigits>(
                find.byType(trainer.TrainerCountdownDigits),
              )
              .value,
          pausedCounter,
          reason: 'the interruption freezes the session counter',
        );

        // The OS ends the interruption: still paused until the user taps.
        output.events.add(AudioInterruption.ended);
        await tester.pump(const Duration(milliseconds: 200));
        expect(find.text('已暂停'), findsOneWidget);
        expect(output.reactivations, 0);

        await tester.tap(ring);
        await tester.pump();
        expect(
          tester
              .widget<trainer.TrainerCountdownDigits>(
                find.byType(trainer.TrainerCountdownDigits),
              )
              .dim,
          isFalse,
          reason: 'the session clock resumed before the old tag fades away',
        );
        await tester.pump(
          trainer.TrainerMotion.calm + const Duration(milliseconds: 20),
        );
        expect(find.text('已暂停'), findsNothing);
        expect(output.reactivations, 1);

        // Leaving the player releases the session.
        await tester.pageBack().catchError((_) {});
        await tester.pumpWidget(const SizedBox());
        expect(output.ends, greaterThanOrEqualTo(1));
      }, variant: ios);
    }

    testWidgets('an interruption while already paused changes nothing', (
      tester,
    ) async {
      await bootIos(tester, voice: voice);
      await tester.tap(find.byKey(const ValueKey('start-today')));
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(seconds: 1));
      await tester.tap(find.byKey(const ValueKey('pause')));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('已暂停'), findsOneWidget);
      output.events.add(AudioInterruption.began);
      await tester.pump(const Duration(milliseconds: 200));
      // The interruption keeps its OS gate even if the user was already
      // paused. Resume is ignored until the platform reports ended.
      await tester.tap(find.byKey(const ValueKey('pause')));
      await tester.pump();
      expect(
        tester
            .widget<trainer.TrainerCountdownDigits>(
              find.byType(trainer.TrainerCountdownDigits),
            )
            .dim,
        isTrue,
      );
      expect(output.reactivations, 0);
      output.events.add(AudioInterruption.ended);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(find.byKey(const ValueKey('pause')));
      await tester.pump();
      await tester.pump(
        trainer.TrainerMotion.calm + const Duration(milliseconds: 20),
      );
      expect(find.text('已暂停'), findsNothing);
      expect(
        tester
            .widget<trainer.TrainerCountdownDigits>(
              find.byType(trainer.TrainerCountdownDigits),
            )
            .dim,
        isFalse,
      );
      expect(output.reactivations, 1);
      await tester.pumpWidget(const SizedBox());
    }, variant: ios);
  });

  group('iPhone safe areas', () {
    for (final phone in iPhones) {
      testWidgets('${phone.name}: onboarding', (tester) async {
        await bootIos(tester, phone: phone, onboarded: false);
        expect(safeAreaOffenders(tester, phone), isEmpty);
        for (var i = 0; i < 3; i++) {
          await tester.tap(find.byKey(const ValueKey('safety-no')));
          await tester.pumpAndSettle();
          expect(safeAreaOffenders(tester, phone), isEmpty, reason: 'card $i');
        }
      }, variant: ios);

      testWidgets('${phone.name}: home, check, progress tabs', (tester) async {
        await bootIos(tester, phone: phone);
        for (final tab in ['tab-0', 'tab-1', 'tab-2']) {
          await tester.tap(find.byKey(ValueKey(tab)));
          await tester.pumpAndSettle();
          expect(safeAreaOffenders(tester, phone), isEmpty, reason: tab);
          expect(
            await scrolledEndOffenders(tester, phone),
            isEmpty,
            reason: tab,
          );
        }
      }, variant: ios);

      testWidgets('${phone.name}: hip check item and result', (tester) async {
        await bootIos(tester, phone: phone);
        await openCheckupIntro(tester);
        await tester.tap(find.byKey(const ValueKey('assessment-start')));
        await tester.pumpAndSettle();
        expect(safeAreaOffenders(tester, phone), isEmpty, reason: 'item 1');
        expect(await scrolledEndOffenders(tester, phone), isEmpty);
        for (var guard = 0; guard < 12; guard++) {
          final option = find.byKey(const ValueKey('option-1'));
          if (option.evaluate().isEmpty) break;
          await tester.ensureVisible(option);
          await tester.pumpAndSettle();
          await tester.tap(option);
          await tester.pump();
          final next = find.byKey(const ValueKey('assessment-next'));
          await tester.ensureVisible(next);
          await tester.pumpAndSettle();
          await tester.tap(next);
          await tester.pumpAndSettle();
        }
        expect(safeAreaOffenders(tester, phone), isEmpty, reason: 'result');
        expect(await scrolledEndOffenders(tester, phone), isEmpty);
      }, variant: ios);

      testWidgets('${phone.name}: player', (tester) async {
        await bootIos(tester, phone: phone);
        await tester.tap(find.byKey(const ValueKey('start-today')));
        await tester.pump(const Duration(seconds: 2));
        await tester.pump(const Duration(milliseconds: 600));
        expect(safeAreaOffenders(tester, phone), isEmpty, reason: 'prep');
        await tester.tap(find.byKey(const ValueKey('skip')));
        await tester.pump(const Duration(seconds: 2));
        await tester.pump(const Duration(milliseconds: 600));
        expect(safeAreaOffenders(tester, phone), isEmpty, reason: 'work');
        await tester.tap(find.byKey(const ValueKey('pause')));
        await tester.pump(const Duration(milliseconds: 600));
        expect(safeAreaOffenders(tester, phone), isEmpty, reason: 'paused');
        await tester.pumpWidget(const SizedBox());
      }, variant: ios);
    }
  });

  for (final (theme, icons) in [
    (HipThemeChoice.dark, Brightness.dark),
    (HipThemeChoice.light, Brightness.light),
  ]) {
    testWidgets('status bar text contrasts with the ${theme.id} theme', (
      tester,
    ) async {
      await bootIos(tester, theme: theme);
      final regions = tester
          .widgetList<AnnotatedRegion<SystemUiOverlayStyle>>(
            find.byType(AnnotatedRegion<SystemUiOverlayStyle>),
          )
          .toList();
      expect(regions, isNotEmpty);
      // iOS reads statusBarBrightness: the brightness of what's *behind*
      // the status bar (dark background → light text).
      expect(regions.first.value.statusBarBrightness, icons);
    }, variant: ios);
  }

  testWidgets('the player cannot be swiped away on iOS mid-session', (
    tester,
  ) async {
    await bootIos(tester);
    await tester.tap(find.byKey(const ValueKey('start-today')));
    await tester.pump(const Duration(seconds: 2));
    // Edge swipe from the left like the iOS back gesture.
    final g = await tester.startGesture(const Offset(2, 400));
    await g.moveBy(const Offset(300, 0));
    await g.up();
    await tester.pump(const Duration(seconds: 1));
    expect(find.byKey(const ValueKey('pause')), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  }, variant: ios);
}
