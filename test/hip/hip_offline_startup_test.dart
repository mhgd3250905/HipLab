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
import 'package:hiplab/hip/ui/library/action_filter.dart';
import 'package:hiplab/hip/ui/library/lib_text.dart';

import 'hip_domain_test.dart' show MemoryStorage, loadContent;
import 'home_nav.dart' show openPractice;

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

Future<void> _decodeBundledImage(String asset) async {
  final data = await rootBundle.load(asset);
  final codec = await ui.instantiateImageCodec(
    data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
  );
  try {
    final frame = await codec.getNextFrame();
    try {
      expect(frame.image.width, greaterThan(0), reason: asset);
      expect(frame.image.height, greaterThan(0), reason: asset);
    } finally {
      frame.image.dispose();
    }
  } finally {
    codec.dispose();
  }
}

void main() {
  testWidgets('offline cold startup opens all 248 moves with bundled art', (
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
        await tester.runAsync(() => _decodeBundledImage(poster!));

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
        expect(find.byKey(const ValueKey('home-more')), findsOneWidget);
        expect(find.byKey(const ValueKey('start-today')), findsOneWidget);
        expect(HipSharedLibrary.current, isNotNull);

        await openPractice(tester);
        final count = find.byKey(const ValueKey('actions-count'));
        expect(tester.widget<Text>(count).data, '248 个动作');
        final items = hipActionItems(
          store.content,
          LibText.of(tester.element(count)),
        );
        expect(items, hasLength(248));
        expect(
          items.map((item) => item.id).toSet(),
          hiplabCoachAuthorizedActionIds,
        );
        expect(items.map((item) => item.id), isNot(contains('n-thomas-test')));

        // The grid is lazy. Decode the asset selected for every row, including
        // the rows below the fold, inside the same offline zone.
        await tester.runAsync(() async {
          for (final item in items) {
            final asset =
                'assets/public_posters/r2-v11/thumbnail/${item.id}.webp';
            expect(item.poster, asset, reason: item.id);
            await _decodeBundledImage(asset);
          }
        });
        await tester.pumpAndSettle();
        final firstCard = find.byType(ActionCard).first;
        final firstItem = tester.widget<ActionCard>(firstCard).item;
        final cardImage = find.descendant(
          of: firstCard,
          matching: find.byType(Image),
        );
        expect(
          tester.widget<Image>(cardImage).image,
          isA<AssetImage>().having(
            (image) => image.assetName,
            'assetName',
            firstItem.poster,
          ),
        );
        expect(tester.takeException(), isNull);
        // Startup and browsing stay offline with a configured coach and
        // prefetch enabled.
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
