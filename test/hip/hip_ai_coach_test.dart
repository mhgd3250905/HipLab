// Host integration only: the SDK owns messages, questions and model policy.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiplab/hip/coach/hip_coach_chat.dart';
import 'package:hiplab/hip/coach/hip_coach_chat_storage.dart';
import 'package:hiplab/hip/coach/hip_coach_profile.dart';
import 'package:hiplab/hip/control/hip_store.dart';
import 'package:hiplab/hip/domain/hip_models.dart';
import 'package:hiplab/hip/ui/coach/hip_coach_chat_page.dart';
import 'package:ugk_coach/ugk_coach.dart' as coach;
import 'package:ugk_coach_chat/ugk_coach_chat.dart';
import 'package:ugk_trainer_runtime/engine.dart' as trainer;

import 'hip_domain_test.dart' show MemoryStorage, loadContent;

class FileAssetBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async =>
      ByteData.sublistView(Uint8List.fromList(File(key).readAsBytesSync()));
}

CoachChatHostActions noopCoachActions() => CoachChatHostActions(
  onStartTraining: (_, _) async => null,
  onOpenAction: (_, _) async {},
  onOpenLibrary: (_, _) async {},
  onOpenSavedPlans: (_) async {},
  onOpenCustomPlan: (_) async {},
  onOpenSettings: (_) async {},
);

trainer.SessionBuilder testSessionBuilder(HipContent content) =>
    trainer.SessionBuilder(
      rhythms: {
        for (final kit in content.kits.values)
          kit.id: trainer.Rhythm.fromActionKitJson(kit.raw),
      },
      prepSeconds: 15,
    );

void main() {
  test(
    'one host loads one SDK controller and releases its client once',
    () async {
      final content = loadContent();
      final disk = MemoryStorage();
      final store = HipStore(content: content, storage: disk);
      addTearDown(store.dispose);
      final client = coach.FakeLlmClient([], latency: Duration.zero);
      var acquired = 0, released = 0;
      final host = HipCoachChat(
        store: store,
        storage: disk,
        bundle: FileAssetBundle(),
        gateway: CoachGatewayBinding(
          create: () {
            acquired++;
            return CoachClientLease.owned(client, release: () => released++);
          },
        ),
      );
      final first = host.load(
        builder: testSessionBuilder(content),
        actions: noopCoachActions(),
      );
      final second = host.load(
        builder: testSessionBuilder(content),
        actions: noopCoachActions(),
      );
      final controllers = await Future.wait([first, second]);
      expect(identical(controllers.first, controllers.last), isTrue);
      expect(identical(host.controller, controllers.first), isTrue);
      expect(acquired, 1);
      expect(
        host.controller.profile.allowedActionIds,
        hiplabCoachAuthorizedActionIds,
      );
      expect(host.controller.profile.allowedActionIds, hasLength(209));
      expect(host.controller.profile.allowedActionIds, contains('chest-A'));
      expect(client.requests, isEmpty);
      await host.close();
      await host.close();
      expect(released, 1);
    },
  );

  test(
    'compose, raw input and archive use the SDK ports and durable history',
    () async {
      final content = loadContent();
      final disk = MemoryStorage();
      disk.values[HiplabCoachChatPreferenceStore.legacyDisclaimerKey] =
          '{"disclaimerAccepted":true}';
      final store = HipStore(content: content, storage: disk);
      addTearDown(store.dispose);
      final raw = <CoachChatUserInput>[];
      final archives = <CoachChatSnapshot>[];
      final events = <String>[];
      final client = coach.FakeLlmClient([
        '可以在不痛的范围内慢慢活动髋部。',
      ], latency: Duration.zero);
      final host = HipCoachChat(
        store: store,
        storage: disk,
        bundle: FileAssetBundle(),
        gateway: CoachGatewayBinding.shared(client),
        replyDelay: Duration.zero,
        onRawInput: raw.add,
        observer: (event, _) => events.add(event),
        beforeNewConversation: (snapshot) async => archives.add(snapshot),
      );
      final chat = await host.load(
        builder: testSessionBuilder(content),
        actions: noopCoachActions(),
      );
      final commands = <CoachChatCommand>[];
      final subscription = chat.actions.listen(commands.add);
      addTearDown(subscription.cancel);
      host.requestCompose();
      await Future<void>.delayed(Duration.zero);
      expect(commands.single.kind, CoachChatCommandKind.compose);
      const input = '  我想了解髋部拉伸注意事项 \n';
      await chat.send(input);
      expect(raw, hasLength(1));
      expect(raw.single.rawText, input);
      expect(raw.single.sentText, input.trim());
      expect(chat.messages.where((m) => m.isUser).single.text, input.trim());
      expect(events, contains('chat.user'));
      await chat.flushPersistence();
      await host.close();

      final restarted = HipCoachChat(
        store: store,
        storage: disk,
        bundle: FileAssetBundle(),
        gateway: CoachGatewayBinding.shared(coach.FakeLlmClient([])),
        beforeNewConversation: (snapshot) async => archives.add(snapshot),
      );
      final restored = await restarted.load(
        builder: testSessionBuilder(content),
        actions: noopCoachActions(),
      );
      expect(
        restored.messages.where((m) => m.isUser).single.text,
        input.trim(),
      );
      expect((await restored.newConversation()).ok, isTrue);
      expect(archives, hasLength(1));
      expect(
        archives.single.messages.any((m) => m['text'] == input.trim()),
        isTrue,
      );
      final archiveKeys =
          jsonDecode(disk.values[HiplabCoachChatHistoryStore.archiveIndexKey]!)
              as List;
      expect(archiveKeys, hasLength(1));
      expect(disk.values[archiveKeys.single], isNotEmpty);
      await restarted.close();
    },
  );

  test('closed host cannot create a new model lease', () async {
    final store = HipStore(content: loadContent(), storage: MemoryStorage());
    addTearDown(store.dispose);
    var leases = 0;
    final host = HipCoachChat(
      store: store,
      bundle: FileAssetBundle(),
      gateway: CoachGatewayBinding(
        create: () {
          leases++;
          return CoachClientLease.shared(coach.FakeLlmClient([]));
        },
      ),
    );
    await host.close();
    await expectLater(
      host.load(
        builder: testSessionBuilder(store.content),
        actions: noopCoachActions(),
      ),
      throwsStateError,
    );
    expect(leases, 0);
  });

  for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
    for (final language in ['zh', 'en']) {
      testWidgets('AI scope for $platform / $language', (tester) async {
        bool? available;
        await tester.pumpWidget(
          MaterialApp(
            locale: Locale(language),
            supportedLocales: const [Locale('zh'), Locale('en')],
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            theme: ThemeData(platform: platform),
            home: Builder(
              builder: (context) {
                available = aiCoachAvailable(context, configured: true);
                expect(aiCoachAvailable(context, configured: false), isFalse);
                return const SizedBox();
              },
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          available,
          platform == TargetPlatform.android && language == 'zh',
        );
      });
    }
  }
}
