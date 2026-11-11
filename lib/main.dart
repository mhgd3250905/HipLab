// HipLab · 开胯训练助手 entry point (com.ugk.hiplab).
//
//   flutter run
//   flutter build apk --release
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'hip/coach/coach_config.dart';
import 'hip/coach/coach_device_id.dart';
import 'hip/control/hip_membership.dart';
import 'hip/data/hip_public_catalog.dart';
import 'hip/data/posehub_catalog_updates.dart';
import 'hip/platform/hip_revenuecat.dart';
import 'hip/ui/hip_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Action-library hot update: open the verified cache before the first
  // catalogue load, then check the channel pointer (launch + daily on resume).
  await PoseHubCatalogUpdates.start(loadLocal: loadHipPublicCatalog);
  // Generate only for an AI-enabled build, before the AI page is opened. A coach
  // request awaits this same operation; storage errors keep offline use working
  // and can be retried before any network request sends a device ID.
  final membership = !kIsWeb && defaultTargetPlatform == TargetPlatform.android
      ? HipMembership(HipRevenueCatStore())
      : null;
  if (membership == null && CoachConfig.fromEnvironment.configured) {
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
  runApp(HipApp(membership: membership));
}
