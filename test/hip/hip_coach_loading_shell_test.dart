import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiplab/hip/coach/hip_coach_chat.dart';
import 'package:hiplab/hip/control/hip_store.dart';
import 'package:hiplab/hip/ui/coach/hip_coach_chat_page.dart';
import 'package:hiplab/hip/ui/hip_theme.dart';
import 'package:hiplab/hip/ui/hip_widgets.dart';
import 'package:hiplab/hip/ui/library/library_actions.dart';
import 'package:ugk_coach/ugk_coach.dart' as coach;
import 'package:ugk_coach_chat/ugk_coach_chat.dart';

import 'hip_domain_test.dart' show MemoryStorage, loadContent;

class _PendingCatalog extends CachingAssetBundle {
  final requests = <Completer<ByteData>>[];

  @override
  Future<ByteData> load(String key) {
    final request = Completer<ByteData>();
    requests.add(request);
    return request.future;
  }
}

void main() {
  for (final palette in [HipPalette.light, HipPalette.dark]) {
    testWidgets('${palette.brightness.name} coach loading, failure and retry', (
      tester,
    ) async {
      tester.view
        ..physicalSize = const Size(390, 844)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final disk = MemoryStorage();
      final store = HipStore(content: loadContent(), storage: disk);
      final bundle = _PendingCatalog();
      final host = HipCoachChat(
        store: store,
        storage: disk,
        bundle: bundle,
        gateway: CoachGatewayBinding.shared(coach.FakeLlmClient(const [])),
      );
      addTearDown(() async {
        await host.close();
        store.dispose();
      });
      final actions = LibraryActions(
        store: store,
        coach: host,
        startPlan: (_, {from, radius = 28, originColor}) async {},
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: hipTheme(palette),
          home: HipCoachChatPage(actions: actions),
        ),
      );
      expect(find.text('正在准备训练助手'), findsOneWidget);
      expect(bundle.requests, hasLength(1));
      bundle.requests.single.completeError(StateError('unavailable catalog'));
      await tester.pump();
      await tester.pump();
      expect(find.text('训练助手暂时无法打开'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(tester.getSize(find.byType(HipPrimaryButton)).height, 50);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('重试'));
      await tester.pump();
      expect(find.text('正在准备训练助手'), findsOneWidget);
      expect(find.text('训练助手暂时无法打开'), findsNothing);
      expect(bundle.requests, hasLength(2));
      bundle.requests.last.completeError(StateError('still unavailable'));
      await tester.pump();
      await tester.pump();
      expect(find.text('训练助手暂时无法打开'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
