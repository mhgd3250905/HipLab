import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiplab/hip/control/hip_store.dart';
import 'package:hiplab/hip/ui/hip_app.dart';
import 'package:hiplab/hip/voice/hip_voice.dart';
import 'package:hiplab/hip/voice/voice_queue.dart';

import 'hip_domain_test.dart' show MemoryStorage, loadContent;
import 'hip_voice_test.dart' show loadVoiceLibrary;

class PreviewOutput implements VoiceOutput, InterruptibleVoiceOutput {
  final events = StreamController<AudioInterruption>.broadcast();
  final spoken = <List<String>>[];
  final calls = <String>[];
  int begins = 0;
  int ends = 0;

  @override
  Stream<AudioInterruption> get interruptions => events.stream;
  @override
  Future<void> begin() async {
    calls.add('begin');
    begins++;
  }

  @override
  Future<void> end() async {
    calls.add('end');
    ends++;
  }

  @override
  Future<void> reactivate() async {}
  @override
  Future<void> speak(List<String> assets) async => spoken.add(assets);
  @override
  Future<void> stopSpeech() async {}
  @override
  Future<void> chime(String asset) async {}
  @override
  set volume(double value) {}
}

class WorkoutAudio extends StatefulWidget {
  const WorkoutAudio({super.key, required this.output});
  final VoiceOutput output;
  @override
  State<WorkoutAudio> createState() => _WorkoutAudioState();
}

class _WorkoutAudioState extends State<WorkoutAudio> {
  @override
  void initState() {
    super.initState();
    unawaited(widget.output.begin());
  }

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Text('Next workout'));
}

void main() {
  final ios = TargetPlatformVariant.only(TargetPlatform.iOS);
  final preview = find.byKey(const ValueKey('voice-preview'));
  late PreviewOutput output;
  late HipStore store;
  late GlobalKey<NavigatorState> navigator;

  Future<void> boot(WidgetTester tester) async {
    output = PreviewOutput();
    store = HipStore(content: loadContent(), storage: MemoryStorage());
    await store.initialize();
    navigator = GlobalKey<NavigatorState>();
    addTearDown(() async {
      store.dispose();
      await output.events.close();
    });
    await tester.pumpWidget(
      HipVoiceScope(
        voice: HipVoice(
          lib: loadVoiceLibrary(),
          output: output,
          settingsOf: () => store.voice,
        ),
        child: MaterialApp(
          navigatorKey: navigator,
          navigatorObservers: [RouteObserver<ModalRoute<dynamic>>()],
          home: Scaffold(
            body: SingleChildScrollView(
              child: ListenableBuilder(
                listenable: store,
                builder: (_, _) => HipVoiceSettingsPanel(store: store),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('preview finishes and releases audio once', (tester) async {
    await boot(tester);
    await tester.tap(preview);
    expect(output.begins, 1);
    await tester.pump(const Duration(seconds: 7));
    expect(output.spoken, isNotEmpty);
    expect(output.ends, 1);
    await tester.pumpWidget(const SizedBox());
    expect(output.ends, 1);
  }, variant: ios);

  testWidgets('restarting and removing preview release each session', (
    tester,
  ) async {
    await boot(tester);
    await tester.tap(preview);
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(preview);
    expect(output.begins, 2);
    expect(output.ends, 1);
    await tester.pumpWidget(const SizedBox());
    expect(output.ends, 2);
    await tester.pump(const Duration(seconds: 7));
    expect(output.ends, 2);
  }, variant: ios);

  testWidgets('covered settings cannot later end the next workout audio', (
    tester,
  ) async {
    await boot(tester);
    await tester.tap(preview);
    unawaited(
      navigator.currentState!.push(
        MaterialPageRoute<void>(builder: (_) => WorkoutAudio(output: output)),
      ),
    );
    await tester.pumpAndSettle();
    expect(output.ends, 1);
    expect(output.calls, ['begin', 'end', 'begin']);
    await tester.pump(const Duration(seconds: 7));
    expect(output.ends, 1);
    await output.end();
    await tester.pumpWidget(const SizedBox());
  }, variant: ios);

  testWidgets('background and interruptions stop preview without resuming it', (
    tester,
  ) async {
    await boot(tester);
    await tester.tap(preview);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(output.ends, 1);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(output.begins, 1);
    await tester.tap(preview);
    output.events.add(AudioInterruption.unplugged);
    await tester.pump();
    expect(output.ends, 2);
    output.events.add(AudioInterruption.ended);
    await tester.pump(const Duration(seconds: 7));
    expect(output.begins, 2);
    expect(output.ends, 2);
    await tester.pumpWidget(const SizedBox());
  }, variant: ios);

  testWidgets(
    'changed settings stop preview and disabled audio cannot start it',
    (tester) async {
      await boot(tester);
      await tester.tap(preview);
      await store.setVoice(store.voice.copyWith(voice: false, chimes: false));
      await tester.pump();
      expect(output.ends, 1);
      await tester.tap(preview);
      await tester.pump();
      expect(output.begins, 1);
      await tester.pumpWidget(const SizedBox());
    },
    variant: ios,
  );
}
