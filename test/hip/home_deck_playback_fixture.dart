import 'dart:async';

import 'package:ugk_coach/ugk_coach.dart' as coach;
import 'package:ugk_trainer_runtime/ugk_trainer_runtime.dart' as trainer;

import 'public_media_fixture.dart';

/// Resolves the existing public catalog into synthetic URIs. The production
/// TrainingActionMedia/controller/command bridge still runs in these tests;
/// only file transport and the native decoder are replaced.
class HomeDeckPlaybackRepository extends PublicMediaFixture {
  @override
  Future<Uri> ensureFile(coach.PoseHubPackFile file) {
    requested.add(file.path);
    return Future.value(file.resolve(mediaBaseUri));
  }
}

class HomeDeckPlaybackPlatform extends trainer.PackedAlphaPlatform
    implements trainer.PackedAlphaUriPlatform {
  final eventsController = StreamController<Map<Object?, Object?>>.broadcast(
    sync: true,
  );
  final sources = <Uri>[];
  final commands = <(int, String, Object?)>[];

  @override
  bool get isSupported => true;
  @override
  Stream<Map<Object?, Object?>> get events => eventsController.stream;
  @override
  Future<({int playerId, int textureId})> create(String asset) =>
      throw StateError('Public media must use its resolved source URI');
  @override
  Future<({int playerId, int textureId})> createUri(Uri source) async {
    sources.add(source);
    final id = sources.length;
    return (playerId: id, textureId: id + 100);
  }

  void emit(int id, String type) =>
      eventsController.add({'playerId': id, 'type': type});

  @override
  Future<Object?> command(int playerId, String type, [Object? value]) async {
    commands.add((playerId, type, value));
    if (type == 'prime-first-frame') return true;
    return null;
  }

  Future<void> dispose() => eventsController.close();
}
