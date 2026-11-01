// Reproducible UI review frames, not live-model or native-device evidence.
// Uses HipLab's production profile and the unmodified SDK controller/page.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiplab/hip/coach/hip_coach_profile.dart';
import 'package:hiplab/hip/data/hip_action_media_loader.dart';
import 'package:hiplab/hip/data/hip_content_loader.dart';
import 'package:hiplab/hip/domain/hip_models.dart';
import 'package:hiplab/hip/trainer/hip_sdk_session_builder.dart';
import 'package:hiplab/hip/ui/hip_theme.dart';
import 'package:hiplab/hip/ui/hip_widgets.dart';
import 'package:ugk_coach/ugk_coach.dart' as coach;
import 'package:ugk_coach_chat/ugk_coach_chat.dart';
import 'package:ugk_coach_ui/ugk_coach_ui.dart' show CoachTaskBubble;
import 'package:ugk_trainer_runtime/engine.dart'
    show SessionBuilderPlanExecutionTiming;

const _namespace = 'hiplab.capture';
final _captureAt = DateTime(2026, 11, 2, 10);

class _Plans extends CoachPlanStorageAdapter {
  @override
  Future<List<CoachSavedPlanSnapshot>> load() async => const [];
  @override
  Future<CoachPlanWriteResult> save(CoachPlanWriteRequest request) async =>
      const CoachPlanWriteResult.failure(CoachPlanWriteStatus.readOnly);
}

class _History extends CoachChatHistoryStore {
  @override
  Future<CoachChatSnapshot?> load(String namespace) async => null;
  @override
  Future<void> write(String namespace, CoachChatSnapshot snapshot) async {}
}

class _Preferences extends CoachChatPreferenceStore {
  @override
  Future<CoachChatPreferences> load() async => const CoachChatPreferences(
    safetyAccepted: true,
    starfield: false,
    enableUserMemory: false,
  );
  @override
  Future<void> update(CoachChatPreferences preferences) async {}
}

final _hostActions = CoachChatHostActions(
  onStartTraining: (_, _) async => null,
  onOpenAction: (_, _) async {},
  onOpenLibrary: (_, _) async {},
  onOpenSavedPlans: (_) async {},
  onOpenCustomPlan: (_) async {},
  onOpenSettings: (_) async {},
);

coach.TrainingPlan _plan() => const coach.TrainingPlan(
  id: 'hiplab-review-plan',
  source: 'ai',
  title: '轻柔髋部拉伸',
  summary: '在不痛的范围内，慢慢呼吸，放松大腿内侧和髋部。',
  goal: 'mobility',
  scene: 'home',
  equipment: ['mat'],
  level: 1,
  targetMinutes: 5,
  blocks: [
    coach.PlanBlock(
      id: 'main',
      name: '髋部拉伸',
      type: coach.BlockType.main,
      items: [
        coach.PlanItem(
          exerciseId: 's-butterfly',
          mode: coach.DoseMode.time,
          sets: 2,
          workSeconds: 60,
          perSide: false,
          restSeconds: 15,
        ),
        coach.PlanItem(
          exerciseId: 's-frog',
          mode: coach.DoseMode.time,
          sets: 1,
          workSeconds: 60,
          perSide: false,
          restSeconds: 15,
        ),
        coach.PlanItem(
          exerciseId: 's-9090',
          mode: coach.DoseMode.time,
          sets: 1,
          workSeconds: 30,
          perSide: true,
          restSeconds: 15,
        ),
      ],
    ),
  ],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final output = Directory(
    Platform.environment['CHAT_CAPTURE_OUTPUT'] ??
        'E:/AII-3D/hiplab-releases/coach-chat-sdk-20261102/screens',
  );
  final requested = (Platform.environment['CHAT_CAPTURE_FRAMES'] ?? '')
      .split(',')
      .where((value) => value.isNotEmpty)
      .toSet();
  final captures = <Map<String, Object?>>[];
  late HipContent content;
  late coach.Catalog catalog;

  setUpAll(() async {
    content = await loadHipContent();
    catalog = await loadHipCoachCatalog();
    HipMediaVariants.media = await loadHipActionMedia();
    await (FontLoader(
      hipFontFamily,
    )..addFont(rootBundle.load('assets/fonts/NotoSansSC.ttf'))).load();
    // Widget tests otherwise replace fonts with Ahem. The host uses Material's
    // "more" glyph alongside HipLab's own drawn icon family.
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    await output.create(recursive: true);
  });

  tearDownAll(() async {
    await File('${output.path}/capture-manifest.json').writeAsString(
      const JsonEncoder.withIndent('  ').convert({
        'schema': 'hiplab-chat-review-frames@1',
        'sdkCommit': '7d9be56a6c02b7a28e3d5d5cd9f6c3f1a23ac723',
        'flutter': '3.44.7 stable',
        'font': hipFontFamily,
        'iconFont': 'MaterialIcons',
        'viewport': {'width': 390, 'height': 844, 'pixelRatio': 1},
        'profileFactory': 'hiplabCoachAppProfile',
        'page': 'SDK CoachChatPage',
        'isLiveModelEvidence': false,
        'isNativeDeviceEvidence': false,
        'pixelComparisonPerformed': false,
        'frames': captures,
      }),
      flush: true,
    );
  });

  for (final dark in [false, true]) {
    final mode = dark ? 'dark' : 'light';
    testWidgets('HipLab shared chat review frames: $mode', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      tester.view.padding = const FakeViewPadding(top: 24, bottom: 24);
      tester.view.viewPadding = const FakeViewPadding(top: 24, bottom: 24);
      addTearDown(tester.view.reset);
      final palette = dark ? HipPalette.dark : HipPalette.light;
      HipColors.palette = palette;
      final profile = hiplabCoachAppProfile(
        catalog: catalog,
        coachProfile: hiplabCoachProfile,
        executionTiming: hipSdkSessionBuilder(content).executionTiming,
        content: content,
      );
      final gate = Completer<coach.LlmResponse>();
      final waitingClient = coach.FakeLlmClient([
        (coach.LlmRequest _) => gate.future,
      ], latency: Duration.zero);
      final controllers = <CoachChatController>[];

      bool wanted(String name) =>
          requested.isEmpty || requested.contains('$mode-$name');

      Future<({CoachChatController chat, GlobalKey key})> mount({
        coach.LlmClient? client,
      }) async {
        final controller = CoachChatController(
          profile: profile,
          catalog: catalog,
          replyDelay: Duration.zero,
          clock: () => _captureAt,
          bindings: CoachChatBindings(
            storageNamespace: _namespace,
            gateway: CoachGatewayBinding.shared(
              client ?? coach.FakeLlmClient(const [], latency: Duration.zero),
            ),
            plans: _Plans(),
            history: _History(),
            preferences: _Preferences(),
            actions: _hostActions,
          ),
        );
        controllers.add(controller);
        final started = await controller.start();
        expect(started.ok, isTrue, reason: '${started.error}');
        final key = GlobalKey();
        await tester.pumpWidget(
          MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: hipTheme(palette),
            locale: const Locale('zh'),
            supportedLocales: const [Locale('zh'), Locale('en')],
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            builder: (_, child) => HipMediaPolicy(
              videoEnabled: false,
              child: RepaintBoundary(key: key, child: child!),
            ),
            home: CoachChatPage(
              controller: controller,
              clock: () => _captureAt,
            ),
          ),
        );
        await tester.pumpAndSettle();
        return (chat: controller, key: key);
      }

      Future<void> capture(
        ({CoachChatController chat, GlobalKey key}) host,
        String state, {
        required String source,
      }) async {
        if (!wanted(state)) return;
        expect(find.byType(CoachChatPage), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.runAsync(() async {
          final boundary =
              host.key.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          final image = await boundary.toImage(pixelRatio: 1);
          try {
            final data = await image.toByteData(format: ui.ImageByteFormat.png);
            await File('${output.path}/$mode-$state.png').writeAsBytes(
              data!.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
              flush: true,
            );
          } finally {
            image.dispose();
          }
          captures.add({
            'file': '$mode-$state.png',
            'state': state,
            'theme': mode,
            'scenarioSource': source,
            'isLiveModelEvidence': false,
            'messages': [for (final row in host.chat.messages) row.toJson()],
          });
        });
      }

      Future<void> restoreRows(
        CoachChatController controller,
        List<Map<String, Object?>> messages,
      ) async {
        final current = controller.exportSnapshot();
        final result = await controller.restoreSnapshot(
          CoachChatSnapshot(
            appId: profile.appId,
            storageNamespace: _namespace,
            session: current.session,
            messages: messages,
          ),
        );
        expect(result.ok, isTrue, reason: '${result.error} ${result.issues}');
        await tester.pumpAndSettle();
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        await tester.pumpAndSettle();
      }

      try {
        final host = await mount(client: waitingClient);
        await capture(host, 'empty', source: 'Normal fresh SDK controller');
        if (wanted('waiting')) {
          final pending = host.chat.send('在家拉伸髋部 10 分钟');
          await tester.pump();
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 50)),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 250));
          expect(host.chat.typing, isTrue);
          expect(find.byType(CoachTaskBubble), findsOneWidget);
          await capture(
            host,
            'waiting',
            source: 'FakeLlmClient stalled response; actual SDK pending turn',
          );
          host.chat.cancelRequest();
          gate.complete(const coach.LlmResponse(content: '已取消。'));
          await tester.runAsync(() async => await pending);
          await tester.pumpAndSettle();
        }
        if (wanted('plan-card')) {
          final plan = _plan();
          await restoreRows(host.chat, [
            ChatMessage(
              id: 'review-user-plan',
              role: ChatRole.user,
              at: _captureAt,
              text: '来一套 5 分钟髋部拉伸',
            ).toJson(),
            ChatMessage(
              id: 'review-plan',
              role: ChatRole.assistant,
              at: _captureAt,
              text: '这套轻柔拉伸可以在家完成。请保持缓慢呼吸，避免疼痛。',
              plan: plan,
              request: requestForPlan(plan),
              aiVisible: true,
            ).toJson(),
          ]);
          expect(host.chat.messages.last.validatedPlan, isNotNull);
          await capture(
            host,
            'plan-card',
            source: 'Authored fixture through normal SDK snapshot admission',
          );
        }
        if (wanted('recommendations')) {
          await restoreRows(host.chat, [
            ChatMessage(
              id: 'review-user-actions',
              role: ChatRole.user,
              at: _captureAt,
              text: '推荐几个拉大腿内侧的动作',
            ).toJson(),
            {
              'id': 'review-actions',
              'role': 'assistant',
              'at': _captureAt.toIso8601String(),
              'text': '可以从这些动作开始，在不痛的范围内慢慢打开髋部。',
              'actionIds': ['s-butterfly', 'h-adductor-rock', 's-frog'],
              'aiVisible': true,
            },
          ]);
          expect(host.chat.messages.last.actions, isNotNull);
          await capture(
            host,
            'recommendations',
            source: 'Authored action IDs through SDK recommendation restore',
          );
        }
        if (wanted('failure')) {
          final failedHost = await mount(
            client: coach.FakeLlmClient(const [
              coach.LlmException(
                coach.LlmErrorKind.http,
                'Simulated HTTP 400 for screenshot review only',
                statusCode: 400,
              ),
            ], latency: Duration.zero),
          );
          await tester.runAsync(() => failedHost.chat.send('在家拉伸髋部 10 分钟'));
          await tester.pumpAndSettle();
          expect(
            failedHost.chat.messages.any(
              (message) => message.isPlanningFailure,
            ),
            isTrue,
          );
          await capture(
            failedHost,
            'failure',
            source: 'Simulated FakeLlmClient HTTP 400; actual SDK failure UI',
          );
        }
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        for (final controller in controllers) {
          await tester.runAsync(controller.close);
        }
      }
    });
  }
}
