import 'package:uuid/uuid.dart';

import '../../core/storage/local_state_storage.dart';

/// Installation identity, stored separately from training and coach history.
/// Never publish a newly generated ID until its persistent write succeeds.
class CoachDeviceId {
  CoachDeviceId({LocalStateStorage? storage, String Function()? generate})
    : _storage = storage ?? SharedPreferencesLocalStateStorage(),
      _generate = generate ?? const Uuid().v4;

  static final device = CoachDeviceId();
  static const storageKey = 'hip.coach.device-id.v1';

  final LocalStateStorage _storage;
  final String Function() _generate;
  Future<String>? _loading;
  String? _value;

  /// Shared by first-launch setup and every AI request. Failed persistence
  /// does not cache an ephemeral ID; a later request can retry storage.
  Future<String> load() {
    if (_value case final value?) return Future.value(value);
    return _loading ??= _load().whenComplete(() => _loading = null);
  }

  Future<String> _load() async {
    final saved = await _storage.read(storageKey);
    if (saved != null && saved.isNotEmpty) return _value = saved;
    final generated = _generate();
    await _storage.write(storageKey, generated);
    return _value = generated;
  }
}
