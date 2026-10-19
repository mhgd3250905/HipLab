import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// HipLab's own (not from 3D-Body): starts / stops the Android training
/// session foreground service (android/…/TrainingSessionService.kt) while a
/// timed session page is open – driven by [ScreenAwake].
///
/// Android voice fix (2026-10-19): with the app in the background the
/// process was an ordinary cached process – background CPU group, free to
/// suspend between voice lines, and on Android 15+ refused audio focus for
/// every line. The service (type `mediaPlayback`, partial wake lock, one
/// quiet notification) keeps the session clock and the voice on time. No
/// plugin dependency: a plain method channel to MainActivity.
///
/// Errors are swallowed: in tests, on iOS / web and when the system refuses
/// the start, the session simply runs as before.
class TrainingService {
  TrainingService._();

  static const channel = MethodChannel('hiplab/training_session');

  /// Test hook: the platform this runs on.
  @visibleForTesting
  static bool Function() isAndroid = () =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static void set(bool on) {
    if (!isAndroid()) return;
    try {
      unawaited(
        channel
            .invokeMethod<bool>(on ? 'start' : 'stop')
            .then((_) {}, onError: (Object _) {}),
      );
    } catch (_) {
      // No engine / channel (unit tests): nothing to keep alive.
    }
  }
}
