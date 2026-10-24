// HipLab · 开胯训练助手 entry point (com.ugk.hiplab).
//
//   flutter run
//   flutter build apk --release
import 'dart:async';

import 'package:flutter/material.dart';

import 'hip/coach/coach_config.dart';
import 'hip/coach/coach_device_id.dart';
import 'hip/ui/hip_app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Generate only for an AI-enabled build, before the AI page is opened. A coach
  // request awaits this same operation; storage errors keep offline use working
  // and can be retried before any network request sends a device ID.
  if (CoachConfig.fromEnvironment.configured) {
    unawaited(
      CoachDeviceId.device.load().then<void>(
        (_) {},
        onError: (Object _, StackTrace _) {
          debugPrint(
            'Coach device identity unavailable; will retry on request.',
          );
        },
      ),
    );
  }
  runApp(const HipApp());
}
