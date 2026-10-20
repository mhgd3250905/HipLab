// PR #24 review F24-3 / F24-4 (docs/pr24-review-2026-10-19.md): the Android
// training keep-alive is owned per session. START / STOP carry a session id,
// a stale STOP is never sent for a session that was replaced, and the CPU
// wake-lock cap follows the planned length. The native side applies the same
// rule (ugk_trainer's TrainingSessionService.kt); these tests cover the Dart
// half, including ownership handoff between HipLab self-check and trainer.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiplab/core/platform/screen_awake.dart';
import 'package:hiplab/core/platform/training_service.dart';
import 'package:hiplab/hip/control/hip_store.dart';
import 'package:hiplab/hip/domain/hip_models.dart';
import 'package:hiplab/hip/domain/hip_session.dart';
import 'package:hiplab/hip/ui/hip_app.dart';
import 'package:hiplab/hip/ui/hip_player_page.dart';
import 'package:ugk_trainer/ugk_trainer.dart' as trainer;

import 'hip_domain_test.dart' show MemoryStorage, loadContent;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final calls = <MethodCall>[];
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late bool Function() originalIsAndroid;

  setUp(() {
    calls.clear();
    originalIsAndroid = TrainingService.isAndroid;
    TrainingService.isAndroid = () => true;
    messenger.setMockMethodCallHandler(TrainingService.channel, (call) async {
      calls.add(call);
      return true;
    });
  });
  tearDown(() {
    messenger.setMockMethodCallHandler(TrainingService.channel, null);
    TrainingService.isAndroid = originalIsAndroid;
  });

  List<String> methods() => [for (final c in calls) c.method];
  Object? sessionOf(MethodCall c) => (c.arguments as Map?)?['session'];

  test('the self-check and package player share one service owner', () async {
    expect(TrainingService.channel.name, 'ugk_trainer/training_session');
    final check = TrainingHold.begin(const Duration(minutes: 5));
    final player = trainer.TrainingHold.begin(const Duration(minutes: 10));
    expect(check.active, isFalse);
    check.release();
    await pumpEventQueue();
    expect(methods(), ['start', 'start']);
    expect(sessionOf(calls[0]), isNot(sessionOf(calls[1])));
    player.release();
    await pumpEventQueue();
    expect(methods(), ['start', 'start', 'stop']);
    expect(sessionOf(calls[2]), sessionOf(calls[1]));

    final next = TrainingHold.begin(const Duration(minutes: 5));
    player.release();
    await pumpEventQueue();
    expect(next.active, isTrue);
    expect(methods(), ['start', 'start', 'stop', 'start']);
    next.release();
    await pumpEventQueue();
    expect(sessionOf(calls.last), next.session);
  });

  test('the self-check keeps HipLab notification text and icon', () async {
    final hold = TrainingHold.begin(const Duration(minutes: 5));
    await pumpEventQueue();
    final args = calls.single.arguments as Map;
    expect(args['title'], '开胯训练进行中');
    expect(args['icon'], 'mipmap/ic_launcher_monochrome');
    hold.release();
    await pumpEventQueue();
  });

  test('stop carries the session it ends; a stale stop after a quick '
      're-entry is not sent', () async {
    final a = TrainingHold.begin(const Duration(minutes: 10));
    a.release(); // page 1 closed …
    final b = TrainingHold.begin(const Duration(minutes: 10)); // … page 2
    a.release(); // dispose of page 1 again: idempotent
    await pumpEventQueue();
    expect(methods(), ['start', 'stop', 'start']);
    expect(sessionOf(calls[1]), sessionOf(calls[0]));
    expect(sessionOf(calls[2]), isNot(sessionOf(calls[0])));
    b.release();
    await pumpEventQueue();
    expect(methods(), ['start', 'stop', 'start', 'stop']);
    expect(sessionOf(calls[3]), sessionOf(calls[2]));
  });

  test('overlapping pages: the old page releasing does not stop the new '
      'session', () async {
    final a = TrainingHold.begin(const Duration(minutes: 10));
    final b = TrainingHold.begin(const Duration(minutes: 10));
    a.release();
    await pumpEventQueue();
    expect(methods(), ['start', 'start']);
    b.release();
    await pumpEventQueue();
    expect(methods(), ['start', 'start', 'stop']);
    expect(sessionOf(calls[2]), sessionOf(calls[1]));
  });

  test('the wake-lock cap follows the planned length', () async {
    final h = TrainingHold.begin(const Duration(minutes: 12));
    await pumpEventQueue();
    final cap = (calls.single.arguments as Map)['maxMs'] as int;
    expect(cap, greaterThan(const Duration(minutes: 12).inMilliseconds));
    expect(cap, lessThanOrEqualTo(const Duration(minutes: 30).inMilliseconds));
    h.release();
    final long = TrainingHold.begin(const Duration(hours: 5));
    await pumpEventQueue();
    expect(
      (calls.last.arguments as Map)['maxMs'],
      TrainingHold.maxCap.inMilliseconds,
    );
    long.release();
  });

  test('the screen hold alone no longer drives the service', () async {
    ScreenAwake.acquire();
    ScreenAwake.release();
    await pumpEventQueue();
    expect(calls, isEmpty);
  });

  test('not on iOS / web; a missing platform side never throws', () async {
    TrainingService.isAndroid = () => false;
    TrainingHold.begin(const Duration(minutes: 5)).release();
    await pumpEventQueue();
    expect(calls, isEmpty);
    TrainingService.isAndroid = () => true;
    messenger.setMockMethodCallHandler(TrainingService.channel, null);
    TrainingHold.begin(const Duration(minutes: 5)).release();
    await pumpEventQueue();
  });

  testWidgets('a training that finishes on its own (screen locked, page '
      'left open) stops the service', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final store = HipStore(
      content: loadContent(),
      storage: MemoryStorage(),
      clock: () => DateTime(2026, 10, 19, 10),
    );
    await store.initialize();
    store
      ..safety = {'pregnancy': false, 'surgery': false, 'acute': false}
      ..identity = HipIdentity.office
      ..scene = HipScene.chair
      ..minutes = 5;
    final micro = store.microPlan!;
    final plan = TrainingPlan(
      routines: micro.routines,
      steps: [micro.steps.first],
      transitionSeconds: micro.transitionSeconds,
    );
    await tester.pumpWidget(HipApp(store: store, videoEnabled: false));
    await tester.pumpAndSettle();
    tester
        .state<NavigatorState>(find.byType(Navigator))
        .push<void>(
          MaterialPageRoute(
            builder: (_) => HipPlayerPage(store: store, plan: plan),
          ),
        );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(methods(), ['start']);
    // Let the clock run the whole session out (no taps).
    for (var i = 0; i < plan.seconds + 40; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
    expect(find.byKey(const ValueKey('finish')), findsOneWidget);
    expect(methods(), [
      'start',
      'stop',
    ], reason: 'service and wake lock must go with the training');
    expect(sessionOf(calls[1]), sessionOf(calls[0]));
    // Leaving the finished page later does not stop anything twice.
    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();
    expect(methods(), ['start', 'stop']);
  });
}
