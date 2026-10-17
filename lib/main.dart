// HipLab · 开胯训练助手 entry point (com.ugk.hiplab).
//
//   flutter run
//   flutter build apk --release
import 'package:flutter/material.dart';

import 'hip/ui/hip_app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const HipApp());
}
