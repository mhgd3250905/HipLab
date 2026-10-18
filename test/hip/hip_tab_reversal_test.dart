import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiplab/hip/ui/hip_routes.dart';

final _captureKey = GlobalKey();

Finder _page(int index) =>
    find.byKey(ValueKey('reversal-page-$index'), skipOffstage: false);

double _opacity(WidgetTester tester, int index) {
  final fade = find
      .ancestor(
        of: _page(index),
        matching: find.byType(FadeTransition, skipOffstage: false),
      )
      .first;
  return tester.renderObject<RenderAnimatedOpacity>(fade).opacity.value;
}

Future<void> _capture(WidgetTester tester, String name) async {
  final evidenceDir = Platform.environment['HIP_REVIEW_EVIDENCE_DIR'];
  if (evidenceDir == null || evidenceDir.isEmpty) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_captureKey),
  );
  await tester.runAsync(() async {
    final directory = Directory(evidenceDir);
    await directory.create(recursive: true);
    final image = await boundary.toImage(pixelRatio: 1);
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await File('${directory.path}/$name.png').writeAsBytes(
        bytes!.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
      );
    } finally {
      image.dispose();
    }
  });
}

Future<void> _beginSwitch(
  WidgetTester tester,
  GlobalKey<_TabHarnessState> key, {
  bool reduceMotion = false,
}) async {
  tester.view.physicalSize = const Size(400, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    RepaintBoundary(
      key: _captureKey,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(disableAnimations: reduceMotion),
          child: child!,
        ),
        home: _TabHarness(key: key),
      ),
    ),
  );
  key.currentState!.select(1);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 150));
}

void main() {
  testWidgets('mid-flight tab reversal preserves rendered opacity', (
    tester,
  ) async {
    final key = GlobalKey<_TabHarnessState>();
    await _beginSwitch(tester, key);
    final before = [for (var i = 0; i < 2; i++) _opacity(tester, i)];
    expect(before[1], inExclusiveRange(0, 1));
    await _capture(tester, 'reversal-before');

    key.currentState!.select(0);
    // No clock time elapses: changing the destination must not replace
    // the current visible frame with the other tab immediately.
    await tester.pump();
    await _capture(tester, 'reversal-after');
    for (var i = 0; i < 2; i++) {
      expect(
        _opacity(tester, i),
        closeTo(before[i], 0.000001),
        reason: 'Tab $i opacity jumped when the animation reversed.',
      );
    }
    await tester.pumpAndSettle();
    expect(_opacity(tester, 0), 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('mid-flight tab reversal preserves rendered position', (
    tester,
  ) async {
    final key = GlobalKey<_TabHarnessState>();
    await _beginSwitch(tester, key);
    final before = [for (var i = 0; i < 2; i++) tester.getRect(_page(i))];
    expect(before[1].left, greaterThan(0));

    key.currentState!.select(0);
    await tester.pump();
    for (var i = 0; i < 2; i++) {
      expect(
        tester.getRect(_page(i)).left,
        closeTo(before[i].left, 0.000001),
        reason: 'Tab $i moved without elapsed time when reversing.',
      );
    }
    await tester.pumpAndSettle();
    expect(tester.getRect(_page(0)).left, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'rapid three-tab retargeting keeps every visible frame continuous',
    (tester) async {
      final key = GlobalKey<_TabHarnessState>();
      await _beginSwitch(tester, key);
      for (final (target, delay) in [
        (2, 45),
        (0, 60),
        (1, 120),
        (2, 140),
        (0, 1),
      ]) {
        final existing = [
          for (var i = 0; i < 3; i++)
            if (_page(i).evaluate().isNotEmpty) i,
        ];
        final opacity = {for (final i in existing) i: _opacity(tester, i)};
        final left = {
          for (final i in existing) i: tester.getRect(_page(i)).left,
        };
        key.currentState!.select(target);
        await tester.pump();
        for (final i in existing) {
          expect(
            _opacity(tester, i),
            closeTo(opacity[i]!, 0.000001),
            reason: 'Tab $i opacity jumped when retargeting to $target.',
          );
          expect(
            tester.getRect(_page(i)).left,
            closeTo(left[i]!, 0.000001),
            reason: 'Tab $i position jumped when retargeting to $target.',
          );
        }
        await tester.pump(Duration(milliseconds: delay));
      }
      await tester.pumpAndSettle();
      expect(_opacity(tester, 0), 1);
      expect(_opacity(tester, 1), 0);
      expect(_opacity(tester, 2), 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('reduced motion never drifts during three-tab retargeting', (
    tester,
  ) async {
    final key = GlobalKey<_TabHarnessState>();
    await _beginSwitch(tester, key, reduceMotion: true);
    for (final target in [2, 0, 1, 2, 0]) {
      key.currentState!.select(target);
      await tester.pump();
      for (var frame = 0; frame < 5; frame++) {
        for (var i = 0; i < 3; i++) {
          if (_page(i).evaluate().isNotEmpty) {
            expect(tester.getRect(_page(i)).left, 0);
          }
        }
        await tester.pump(const Duration(milliseconds: 16));
      }
    }
    await tester.pumpAndSettle();
    expect(_opacity(tester, 0), 1);
    expect(tester.takeException(), isNull);
  });
}

class _TabHarness extends StatefulWidget {
  const _TabHarness({super.key});

  @override
  State<_TabHarness> createState() => _TabHarnessState();
}

class _TabHarnessState extends State<_TabHarness> {
  int _index = 0;
  int _direction = 1;

  void select(int index) {
    setState(() {
      _direction = index > _index ? 1 : -1;
      _index = index;
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: HipTabSwitcher(
      index: _index,
      direction: _direction,
      child: ColoredBox(
        key: ValueKey('reversal-page-$_index'),
        color: _index == 0 ? Colors.red : Colors.blue,
      ),
    ),
  );
}
