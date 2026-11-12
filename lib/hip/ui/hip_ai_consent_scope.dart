import 'package:flutter/widgets.dart';

import '../control/hip_ai_consent.dart';

class HipAiConsentScope extends InheritedWidget {
  const HipAiConsentScope({
    super.key,
    required this.consent,
    required super.child,
  });

  final HipAiConsent consent;

  static HipAiConsent? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<HipAiConsentScope>()?.consent;

  @override
  bool updateShouldNotify(HipAiConsentScope oldWidget) =>
      oldWidget.consent != consent;
}
