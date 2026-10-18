import 'dart:convert';

import 'package:flutter/services.dart';

import '../domain/hip_action_media.dart';

/// Loads the theme-matched media manifest (assets/hip/action-media.json).
/// A missing or unreadable manifest only costs the light renders: every
/// picture then falls back to its dark-stage asset.
Future<HipActionMedia> loadHipActionMedia([AssetBundle? bundle]) async {
  try {
    // Raw bytes + a synchronous decode: loadString hands strings > 50 KB to
    // an isolate, which never completes inside widget tests' fake clock.
    final data = await (bundle ?? rootBundle).load(HipActionMedia.assetPath);
    final text = utf8.decode(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    );
    return HipActionMedia.fromJson(jsonDecode(text) as Map<String, dynamic>);
  } on Object {
    return HipActionMedia.empty;
  }
}
