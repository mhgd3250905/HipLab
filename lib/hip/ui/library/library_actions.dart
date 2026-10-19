// What the library pages need from the home shell: start a plan (player
// grows out of the tapped control) and the shared store.
import 'package:flutter/widgets.dart';

import '../../control/hip_store.dart';
import '../../domain/hip_models.dart';
import '../../domain/hip_session.dart';
import 'library_widgets.dart';

typedef StartPlan =
    Future<void> Function(
      TrainingPlan plan, {
      BuildContext? from,
      double radius,
      Color? originColor,
    });

class LibraryActions {
  const LibraryActions({required this.store, required this.startPlan});
  final HipStore store;
  final StartPlan startPlan;
}

/// Returned by a detail page to send 动作大全 to a pre-set filter
/// (「看放松」: this direction, relax only).
class LibraryJump {
  const LibraryJump(this.direction);
  final HipDirection direction;

  LibraryFilter get filter =>
      LibraryFilter(direction: direction, methods: const {HipMethod.relax});
}

/// What the practice tab remembers while the user moves between tabs.
class PracticeMemory {
  int segment = 0;
  LibraryFilter filter = const LibraryFilter();
}
