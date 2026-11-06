import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
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
    for (final language in ['zh', 'en']) {
      testWidgets(
        '${palette.brightness.name} $language coach loading, failure and retry',
        (tester) async {
          final preparing = language == 'en'
              ? 'Preparing your coach'
              : '正在准备训练助手';
          final unavailable = language == 'en'
              ? 'Coach is unavailable'
              : '训练助手暂时无法打开';
          final retry = language == 'en' ? 'Retry' : '重试';
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
              locale: Locale(language),
              supportedLocales: const [Locale('zh'), Locale('en')],
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
              theme: hipTheme(palette),
              home: HipCoachChatPage(actions: actions),
            ),
          );
          expect(find.text(preparing), findsOneWidget);
          expect(bundle.requests, hasLength(1));
          bundle.requests.single.completeError(
            StateError('unavailable catalog'),
          );
          await tester.pump();
          await tester.pump();
          expect(find.text(unavailable), findsOneWidget);
          expect(find.byType(CircularProgressIndicator), findsNothing);
          expect(tester.getSize(find.byType(HipPrimaryButton)).height, 50);
          expect(tester.takeException(), isNull);

          await tester.tap(find.text(retry));
          await tester.pump();
          expect(find.text(preparing), findsOneWidget);
          expect(find.text(unavailable), findsNothing);
          expect(bundle.requests, hasLength(2));
          bundle.requests.last.completeError(StateError('still unavailable'));
          await tester.pump();
          await tester.pump();
          expect(find.text(unavailable), findsOneWidget);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
        },
      );
    }
  }
}
