// PR22 + PR24 integration: replay uses the same player State but starts a
// new Android keep-alive session, including before the old closing timer.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiplab/core/platform/training_service.dart';
import 'package:hiplab/hip/control/hip_store.dart';
import 'package:hiplab/hip/domain/hip_library.dart';
import 'package:hiplab/hip/domain/hip_models.dart';
import 'package:hiplab/hip/domain/hip_session.dart';
import 'package:hiplab/hip/ui/hip_app.dart';
import 'package:hiplab/hip/ui/hip_player_page.dart';
import 'package:hiplab/hip/voice/voice_queue.dart';

import 'hip_domain_test.dart' show MemoryStorage, loadContent;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final originalPlatform = TrainingService.isAndroid;
  final calls = <MethodCall>[];
  var screenToggles = 0;
  const screenChannel =
      'dev.flutter.pigeon.wakelock_plus_platform_interface.WakelockPlusApi.toggle';

  setUp(() {
    calls.clear();
    screenToggles = 0;
    TrainingService.isAndroid = () => true;
    messenger.setMockMethodCallHandler(TrainingService.channel, (call) async {
      calls.add(call);
      return true;
    });
    // Count the actual screen plugin messages without importing the plugin's
    // transitive Pigeon types. Its void reply is the standard [null] envelope.
    messenger.setMockMessageHandler(screenChannel, (message) async {
      screenToggles++;
      return const StandardMessageCodec().encodeMessage(<Object?>[null]);
    });
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(TrainingService.channel, null);
    messenger.setMockMessageHandler(screenChannel, null);
    TrainingService.isAndroid = originalPlatform;
  });

  List<String> methods() => [for (final call in calls) call.method];
  Object? token(MethodCall call) => (call.arguments as Map)['session'];

  Future<void> finishRound(WidgetTester tester) async {
    // A one-rep squat plus its normal preparation takes well under a minute.
    // Stop pumping when completion appears, preserving the six-second grace.
    for (var i = 0; i < 60; i++) {
      if (find.byKey(const ValueKey('player-again')).evaluate().isNotEmpty) {
        break;
      }
      await tester.pump(const Duration(seconds: 1));
    }
    expect(find.byKey(const ValueKey('player-again')), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 300));
  }

  for (final replayDelay in [Duration.zero, const Duration(seconds: 7)]) {
    testWidgets('single replay after ${replayDelay.inSeconds}s gets a fresh '
        'keep-alive; old completion timer cannot stop round two', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      // Also clean up after the intentionally failing pre-fix run, so neither
      // a live hold nor ScreenAwake's private reference count leaks to a test.
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      });
      final content = loadContent();
      final store = HipStore(
        content: content,
        storage: MemoryStorage(),
        clock: () => DateTime(2026, 10, 19, 10),
      );
      await store.initialize();
      store
        ..safety = {'pregnancy': false, 'surgery': false, 'acute': false}
        ..identity = HipIdentity.office
        ..voice = const VoiceSettings(voice: false, chimes: false);
      final plan = store.planner.singlePlan(
        content.drill('h-squat'),
        const LibraryDose(reps: 1),
        const TrainingProfile(),
      )!;
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
      expect(screenToggles, 1);
      final firstToken = token(calls.single);
      final player = tester.state(find.byType(HipPlayerPage));

      await finishRound(tester);
      await tester.pump(replayDelay);
      expect(
        methods(),
        replayDelay == Duration.zero ? ['start'] : ['start', 'stop'],
      );
      await tester.tap(find.byKey(const ValueKey('player-again')));
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.state(find.byType(HipPlayerPage)), same(player));
      expect(methods(), [
        'start',
        'stop',
        'start',
      ], reason: 'Every replay needs a new Android session hold');
      final secondToken = token(calls[2]);
      expect(secondToken, isNot(firstToken));
      expect(token(calls[1]), firstToken);
      expect(TrainingService.currentSession, secondToken);
      expect(
        screenToggles,
        1,
        reason: 'Replaying the same page must not acquire another screen hold',
      );

      // Round two remains in its normal preparation during this interval.
      // In the immediate case this crosses round one's old release deadline.
      await tester.pump(const Duration(seconds: 7));
      expect(find.byKey(const ValueKey('player-again')), findsNothing);
      expect(methods(), [
        'start',
        'stop',
        'start',
      ], reason: 'The old six-second timer must not stop the new token');
      expect(TrainingService.currentSession, secondToken);

      await finishRound(tester);
      await tester.pump(const Duration(seconds: 7));
      expect(methods(), ['start', 'stop', 'start', 'stop']);
      expect(token(calls.last), secondToken);
      expect(TrainingService.currentSession, isNull);
      expect(store.sessions.where((s) => s.completed).length, 2);
      expect(store.doneDays, isEmpty);
      await tester.tap(find.byKey(const ValueKey('finish')));
      await tester.pumpAndSettle();
      expect(find.byType(HipPlayerPage), findsNothing);
      expect(methods(), [
        'start',
        'stop',
        'start',
        'stop',
      ], reason: 'Leaving an already finished round must not stop twice');
      expect(
        screenToggles,
        2,
        reason:
            'The one page hold must disable the screen on disposal; '
            'an extra acquire during replay would leak the reference count',
      );
      expect(tester.takeException(), isNull);
    });
  }
}
