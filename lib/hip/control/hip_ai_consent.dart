import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The current disclosure version has no default grant.
class HipAiConsent extends ChangeNotifier {
  static const key = 'hip_ai_consent_v1';
  static const timestampKey = '${key}_at';

  bool _granted = false;
  bool get granted => _granted;

  int _revision = 0;
  Future<void>? _initialRead;
  Future<void> _writes = Future<void>.value();
  Future<bool>? _prompt;

  Future<bool> read() async {
    await (_initialRead ??= _load());
    return granted;
  }

  Future<void> _load() async {
    final revision = _revision;
    try {
      final preferences = await SharedPreferences.getInstance();
      if (revision != _revision || revision != 0) return;
      final timestamp = preferences.getString(timestampKey);
      _setGranted(
        preferences.getBool(key) == true &&
            timestamp != null &&
            DateTime.tryParse(timestamp) != null,
      );
    } on Object {
      // A failed read leaves the gate closed. The user can try granting again.
    }
  }

  Future<bool> request(Future<bool> Function() showDisclosure) async {
    if (await read()) return true;
    return _prompt ??= Future<bool>.sync(showDisclosure)
        .then((accepted) => accepted && granted)
        .whenComplete(() => _prompt = null);
  }

  Future<void> grant() {
    final revision = ++_revision;
    return _enqueue(() async {
      final preferences = await SharedPreferences.getInstance();
      if (!await preferences.setString(
            timestampKey,
            DateTime.now().toUtc().toIso8601String(),
          ) ||
          !await preferences.setBool(key, true)) {
        throw StateError('Could not save AI data sharing consent.');
      }
      if (revision == _revision) _setGranted(true);
    });
  }

  Future<void> withdraw() {
    ++_revision;
    _setGranted(false);
    return _enqueue(() async {
      final preferences = await SharedPreferences.getInstance();
      if (!await preferences.remove(key) ||
          !await preferences.remove(timestampKey)) {
        throw StateError('Could not clear AI data sharing consent.');
      }
    });
  }

  Future<void> _enqueue(Future<void> Function() write) {
    final operation = _writes.then((_) => write());
    _writes = operation.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return operation;
  }

  void _setGranted(bool value) {
    if (_granted == value) return;
    _granted = value;
    notifyListeners();
  }
}
