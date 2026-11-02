import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiplab/hip/coach/coach_config.dart';
import 'package:hiplab/hip/coach/hip_coach_chat.dart';
import 'package:hiplab/hip/coach/hip_coach_profile.dart';
import 'package:hiplab/hip/control/hip_store.dart';
import 'package:hiplab/hip/data/hip_public_media.dart';
import 'package:hiplab/hip/data/hip_shared_library.dart';
import 'package:hiplab/hip/domain/hip_models.dart';
import 'package:hiplab/hip/ui/hip_app.dart';

import 'hip_domain_test.dart' show MemoryStorage, loadContent;

class _NetworkDown extends HttpOverrides {
  int clients = 0;
  int connections = 0;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    clients++;
    final client = super.createHttpClient(context);
    client.findProxy = (_) => 'DIRECT';
    client.connectionFactory = (uri, proxyHost, proxyPort) {
      connections++;
      return Future<ConnectionTask<Socket>>.error(
        const SocketException('Offline startup test'),
      );
    };
    return client;
  }
}

void main() {
  testWidgets('offline cold startup reaches home with bundled catalog/poster', (
    tester,
  ) async {
    final network = _NetworkDown();
    await HttpOverrides.runWithHttpOverrides(() async {
      // Verify that this zone really blocks HTTP before exercising startup.
      await tester.runAsync(() async {
        final probe = HttpClient();
        try {
          await expectLater(
            probe.getUrl(Uri.parse('https://media.uuugk.win/offline-probe')),
            throwsA(isA<SocketException>()),
          );
        } finally {
          probe.close(force: true);
        }
      });
      expect(network.connections, 1);
      network.clients = 0;
      network.connections = 0;

      // Real SDK disk setup belongs outside the widget fake clock. Only its
      // native support-directory lookup is replaced with an isolated test path.
      final tempParent = Directory('build/test-offline-startup').absolute;
      final root = await tester.runAsync(() async {
        await tempParent.create(recursive: true);
        return tempParent.createTemp('offline-startup-');
      });
      final oldPolicy = HipPublicMedia.current;
      final oldLibrary = HipSharedLibrary.current;
      final store = HipStore(content: loadContent(), storage: MemoryStorage());
      await store.initialize();
      store.safety = {'pregnancy': false, 'surgery': false, 'acute': false};
      store.identity = HipIdentity.office;
      final coach = HipCoachChat(
        store: store,
        config: const CoachConfig(appKey: 'offline-test'),
      );
      final policy = await tester.runAsync(
        () => HipPublicMedia.load(rootDirectory: root!.path),
      );
      try {
        expect(policy!.prefetchBeforeTraining, isTrue);
        final poster = policy.posterAssetFor('n-leg-circles');
        expect(poster, isNotNull);
        await tester.runAsync(() async {
          final data = await rootBundle.load(poster!);
          final codec = await ui.instantiateImageCodec(
            data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
          );
          final frame = await codec.getNextFrame();
          expect(frame.image.width, greaterThan(0));
          frame.image.dispose();
          codec.dispose();
        });

        // Do not warm the coach catalog: this also guards the large-asset race.
        rootBundle.evict(hipCoachCatalogAsset);
        await tester.pumpWidget(
          HipApp(
            store: store,
            coach: coach,
            mediaPolicy: policy,
            videoEnabled: false,
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('tab-1')), findsOneWidget);
        expect(find.byKey(const ValueKey('start-today')), findsOneWidget);
        expect(HipSharedLibrary.current, isNotNull);
        expect(tester.takeException(), isNull);
        // Catalog setup, media prefetch and Worker access must not be startup
        // dependencies, even with a configured coach and prefetch enabled.
        expect(network.clients, 0);
        expect(network.connections, 0);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await coach.close();
        policy?.repository.dispose();
        HipPublicMedia.current = oldPolicy;
        HipSharedLibrary.current = oldLibrary;
        store.dispose();
        // root is created by createTemp inside this explicit artifact folder.
        expect(
          root!.absolute.path,
          startsWith('${tempParent.path}${Platform.pathSeparator}'),
        );
        await tester.runAsync(() => root.delete(recursive: true));
      }
    }, network);
  });
}
