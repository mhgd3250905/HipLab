import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:hiplab/core/storage/local_state_storage.dart';
import 'package:hiplab/hip/coach/coach_device_id.dart';

class _Storage implements LocalStateStorage {
  final values = <String, String>{};
  int reads = 0;
  int writes = 0;
  bool failRead = false;
  bool failWrite = false;
  Completer<void>? writing;

  @override
  Future<String?> read(String key) async {
    reads++;
    if (failRead) throw StateError('read unavailable');
    return values[key];
  }

  @override
  Future<void> write(String key, String value) async {
    writes++;
    if (failWrite) throw StateError('write unavailable');
    await writing?.future;
    values[key] = value;
  }
}

void main() {
  test('first launch persists a UUID v4; another launch reuses it', () async {
    final storage = _Storage();
    final first = await CoachDeviceId(storage: storage).load();
    expect(
      first,
      matches(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
      ),
    );
    expect(storage.values[CoachDeviceId.storageKey], first);
    expect(await CoachDeviceId(storage: storage).load(), first);
    expect(storage.writes, 1);
  });

  test('startup and concurrent requests share the persistent write', () async {
    final storage = _Storage()..writing = Completer<void>();
    var generations = 0;
    final identity = CoachDeviceId(
      storage: storage,
      generate: () => 'device-${++generations}',
    );
    var returned = false;
    final startup = identity.load().then((id) {
      returned = true;
      return id;
    });
    final request = identity.load();
    await Future<void>.delayed(Duration.zero);
    expect(returned, isFalse, reason: 'no ephemeral ID before persistence');
    expect(generations, 1);
    expect(storage.writes, 1);
    storage.writing!.complete();
    expect(await Future.wait([startup, request]), ['device-1', 'device-1']);
    expect(await identity.load(), 'device-1');
    expect(storage.reads, 1);
  });

  test('failed write sends no ephemeral identity and can retry', () async {
    final storage = _Storage()..failWrite = true;
    final identity = CoachDeviceId(storage: storage);
    await expectLater(identity.load(), throwsStateError);
    expect(storage.values, isEmpty);
    storage.failWrite = false;
    final saved = await identity.load();
    expect(storage.values[CoachDeviceId.storageKey], saved);
    expect(await identity.load(), saved);
    expect(storage.writes, 2);
  });

  test('failed read does not overwrite an existing ID', () async {
    final storage = _Storage()
      ..values[CoachDeviceId.storageKey] = 'already-persisted'
      ..failRead = true;
    final identity = CoachDeviceId(storage: storage);
    await expectLater(identity.load(), throwsStateError);
    expect(storage.writes, 0);
    storage.failRead = false;
    expect(await identity.load(), 'already-persisted');
    expect(storage.writes, 0);
  });
}
