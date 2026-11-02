import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/services.dart';
import 'package:ugk_coach_chat/ugk_coach_chat.dart';
import 'package:ugk_trainer_runtime/engine.dart' as trainer;

import '../../core/storage/local_state_storage.dart';
import '../control/hip_store.dart';
import 'coach_config.dart';
import 'coach_device_id.dart';
import 'hip_coach_chat_storage.dart';
import 'hip_coach_profile.dart';

/// App lifetime and host ports only. The SDK owns the sole conversation.
class HipCoachChat {
  HipCoachChat({
    required this.store,
    this.config = CoachConfig.fromEnvironment,
    this.gateway,
    this.storage,
    this.bundle,
    this.observer,
    this.onRawInput,
    this.beforeNewConversation,
    this.replyDelay = const Duration(milliseconds: 450),
  });

  static const namespace = 'hiplab';
  final HipStore store;
  final CoachConfig config;
  final CoachGatewayBinding? gateway;
  final LocalStateStorage? storage;
  final AssetBundle? bundle;
  final CoachChatObserver? observer;
  final void Function(CoachChatUserInput input)? onRawInput;
  final Future<void> Function(CoachChatSnapshot snapshot)?
  beforeNewConversation;
  final Duration replyDelay;
  CoachChatController? _controller;
  HiplabCoachChatPreferenceStore? _preferences;
  Future<CoachChatController>? _loading;
  bool _closed = false;
  bool get configured => gateway != null || config.configured;
  CoachChatController get controller =>
      _controller ?? (throw StateError('Open the coach first'));

  Future<CoachChatController> load({
    required trainer.SessionBuilder builder,
    required CoachChatHostActions actions,
  }) {
    if (_closed) return Future.error(StateError('Coach host is closed'));
    return _loading ??= _load(builder, actions);
  }

  Future<CoachChatController> _load(
    trainer.SessionBuilder builder,
    CoachChatHostActions actions,
  ) async {
    try {
      if (_closed) throw StateError('Coach host is closed');
      final catalog = bundle == null
          ? store.content.publicCatalog ?? await loadHipCoachCatalog()
          : await loadHipCoachCatalog(bundle: bundle);
      final profile = hiplabCoachAppProfile(
        catalog: catalog,
        coachProfile: hiplabCoachProfile,
        executionTiming: builder.executionTiming,
        content: store.content,
      );
      final history = HiplabCoachChatHistoryStore(store, storage: storage);
      final preferences = HiplabCoachChatPreferenceStore(
        store,
        storage: storage,
      );
      final chat = CoachChatController(
        profile: profile,
        catalog: catalog,
        replyDelay: replyDelay,
        bindings: CoachChatBindings(
          storageNamespace: namespace,
          gateway:
              gateway ??
              CoachGatewayBinding(
                create: () {
                  final client = config.createClient(
                    deviceId: CoachDeviceId.device.load,
                  );
                  return CoachClientLease.owned(client, release: client.close);
                },
              ),
          plans: HiplabCoachPlanStore(
            store,
            catalog: profile.planningCatalog(catalog),
          ),
          history: history,
          preferences: preferences,
          actions: actions,
          observer: (event, detail) {
            if (detail is CoachChatUserInput) onRawInput?.call(detail);
            observer?.call(event, detail);
            developer.log(event, name: 'hiplab.coach');
          },
          beforeNewConversation: (snapshot) async {
            await history.archive(snapshot);
            await beforeNewConversation?.call(snapshot);
          },
        ),
      );
      _preferences = preferences;
      _controller = chat;
      if (_closed) {
        await chat.close();
        throw StateError('Coach host is closed');
      }
      final result = await chat.start();
      if (!result.ok) throw StateError('SDK coach restoration failed');
      return chat;
    } on Object {
      await _controller?.close();
      _preferences?.dispose();
      _controller = null;
      _preferences = null;
      _loading = null;
      rethrow;
    }
  }

  /// The SDK focuses its existing input after a host page is popped.
  void requestCompose() => controller.requestCompose();

  Future<void> close() async {
    _closed = true;
    await _controller?.close();
    _preferences?.dispose();
  }

  void dispose() => unawaited(close());
}
