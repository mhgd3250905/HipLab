import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiplab/core/media/media_controller.dart';
import 'package:hiplab/hip/ui/coach/hip_coach_visuals.dart';
import 'package:hiplab/hip/ui/hip_widgets.dart';

import 'hip_domain_test.dart' show loadContent;

class _TrackedSurface extends StatefulWidget {
  const _TrackedSurface({
    super.key,
    required this.onMount,
    required this.onDispose,
  });
  final VoidCallback onMount, onDispose;

  @override
  State<_TrackedSurface> createState() => _TrackedSurfaceState();
}

class _TrackedSurfaceState extends State<_TrackedSurface> {
  @override
  void initState() {
    super.initState();
    widget.onMount();
  }

  @override
  void dispose() {
    widget.onDispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.expand();
}

void main() {
  testWidgets(
    'retirement waits for surface detach and can restart explicitly',
    (tester) async {
      final drill = loadContent().drill('s-figure4');
      final handle = HipDrillArtHandle();
      final controllers = <DrillMediaController>{};
      var mountedSurfaces = 0;

      Future<void> show(
        bool play, {
        Brightness brightness = Brightness.light,
      }) => tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(brightness: brightness),
          home: SizedBox.square(
            dimension: 240,
            child: HipDrillArt(
              key: handle.key,
              retirementHandle: handle,
              drill: drill,
              play: play,
              mediaViewBuilder: (_, controller) {
                controllers.add(controller);
                return _TrackedSurface(
                  key: ObjectKey(controller),
                  onMount: () => mountedSurfaces++,
                  onDispose: () => mountedSurfaces--,
                );
              },
            ),
          ),
        ),
      );

      await show(true);
      await tester.pump();
      final first = controllers.single;
      expect(mountedSurfaces, 1);
      await show(false);
      expect(first.wantsPlay, isFalse);
      expect(mountedSurfaces, 1, reason: 'ordinary pause retains its frame');

      var retired = false;
      final pending = handle.retire();
      unawaited(pending.then((_) => retired = true));
      expect(handle.retire(), same(pending));
      expect(retired, isFalse);
      expect(mountedSurfaces, 1);
      await tester.pump();
      await pending;
      expect(retired, isTrue);
      expect(mountedSurfaces, 0);

      await show(true);
      expect(controllers, hasLength(2));
      expect(mountedSurfaces, 1);
      final retiringWhilePlaying = handle.retire();
      await tester.pump();
      await retiringWhilePlaying;
      await show(true, brightness: Brightness.dark);
      expect(
        mountedSurfaces,
        0,
        reason: 'a rebuild cannot revive a retired view',
      );
      expect(controllers, hasLength(2));

      await show(false);
      await show(true);
      expect(mountedSurfaces, 1);
      expect(controllers, hasLength(3));
      await tester.pumpWidget(const SizedBox());
      await handle.retire();
      expect(mountedSurfaces, 0);
    },
  );

  testWidgets('retiring handle stays awaitable when its route is removed', (
    tester,
  ) async {
    final handle = HipDrillArtHandle();
    var disposed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: HipDrillArt(
          key: handle.key,
          retirementHandle: handle,
          drill: loadContent().drill('s-figure4'),
          play: true,
          mediaViewBuilder: (_, _) =>
              _TrackedSurface(onMount: () {}, onDispose: () => disposed = true),
        ),
      ),
    );
    final pending = handle.retire();
    await tester.pumpWidget(const SizedBox());
    await pending;
    await handle.retire();
    expect(disposed, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('SDK host retirement releases the exact context and action', (
    tester,
  ) async {
    final visual = hipCoachChatVisuals(loadContent());
    final contexts = <BuildContext>[];
    final mountedSurfaces = <int>{};
    Widget preview(int slot) => SizedBox.square(
      dimension: 160,
      child: Builder(
        builder: (context) {
          if (contexts.length == slot) contexts.add(context);
          final preview =
              visual.previewBuilder!(context, 's-figure4', true) as HipDrillArt;
          return HipDrillArt(
            key: preview.key,
            retirementHandle: preview.retirementHandle,
            drill: preview.drill,
            play: preview.play,
            fit: preview.fit,
            mediaViewBuilder: (_, controller) => _TrackedSurface(
              key: ObjectKey(controller),
              onMount: () => mountedSurfaces.add(slot),
              onDispose: () => mountedSurfaces.remove(slot),
            ),
          );
        },
      ),
    );

    await tester.pumpWidget(
      MaterialApp(home: Column(children: [preview(0), preview(1)])),
    );
    expect(mountedSurfaces, {0, 1});
    final retired = visual.retirePreview!(contexts.first, 's-figure4');
    await tester.pump();
    await retired;
    expect(mountedSurfaces, {1});
    final last = visual.retirePreview!(contexts.last, 's-figure4');
    await tester.pump();
    await last;
    expect(mountedSurfaces, isEmpty);
    await visual.retirePreview!(contexts.last, 'missing-preview');
  });
}
