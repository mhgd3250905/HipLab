import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'hip_icons.dart';
import 'hip_theme.dart';

/// Sculpted category marks for list-leading artwork. Functional controls keep
/// the shared line glyphs; these are decorative, static vector miniatures.
enum HipRowSymbol {
  groups,
  library,
  assessment,
  records,
  settings,
  reminder,
  chair,
  voice,
  sound,
  language,
  volume,
  appearance,
  safety,
  privacy,
  addGroup,
  coach,
  completed,
  paused,
}

HipRowSymbol? hipRowSymbolForGlyph(HipGlyph glyph) => switch (glyph) {
  HipGlyph.grip => HipRowSymbol.groups,
  HipGlyph.library => HipRowSymbol.library,
  HipGlyph.radar => HipRowSymbol.assessment,
  HipGlyph.progress => HipRowSymbol.records,
  HipGlyph.contrast => HipRowSymbol.appearance,
  HipGlyph.bell => HipRowSymbol.reminder,
  HipGlyph.chair => HipRowSymbol.chair,
  HipGlyph.voice => HipRowSymbol.voice,
  HipGlyph.today => HipRowSymbol.sound,
  HipGlyph.subtitles => HipRowSymbol.language,
  HipGlyph.volume => HipRowSymbol.volume,
  HipGlyph.shield => HipRowSymbol.safety,
  HipGlyph.clipboard => HipRowSymbol.privacy,
  HipGlyph.plus => HipRowSymbol.addGroup,
  HipGlyph.bolt => HipRowSymbol.coach,
  HipGlyph.checkCircle => HipRowSymbol.completed,
  HipGlyph.pause => HipRowSymbol.paused,
  _ => null,
};

class HipRowEmblem extends StatelessWidget {
  const HipRowEmblem({super.key, required this.symbol, this.size = 30});
  final HipRowSymbol symbol;
  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: RepaintBoundary(
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(
          painter: HipRowEmblemPainter(
            symbol: symbol,
            dark: HipColors.isDark,
            highContrast: MediaQuery.maybeHighContrastOf(context) ?? false,
          ),
        ),
      ),
    ),
  );
}

enum _Finish { jade, pearl, steel, graphite, plate }

/// Original 64-unit artwork. Depth comes from shaped sidewalls, continuous
/// material gradients and fine bevels, without filters, bitmaps or animation.
class HipRowEmblemPainter extends CustomPainter {
  const HipRowEmblemPainter({
    required this.symbol,
    required this.dark,
    this.highContrast = false,
  });
  final HipRowSymbol symbol;
  final bool dark;
  final bool highContrast;

  List<Color> _colors(_Finish finish) => switch (finish) {
    _Finish.jade => const [
      Color(0xffb4f9dc),
      Color(0xff42cba5),
      Color(0xff147b5d),
    ],
    _Finish.pearl => const [
      Color(0xffffffff),
      Color(0xffeaf2ee),
      Color(0xffadbfba),
    ],
    _Finish.steel => const [
      Color(0xffedf8f3),
      Color(0xff9fb4ab),
      Color(0xff526d60),
    ],
    _Finish.graphite => const [
      Color(0xff647c70),
      Color(0xff304c3e),
      Color(0xff142d22),
    ],
    _Finish.plate =>
      dark
          ? const [Color(0xff40554a), Color(0xff273a30), Color(0xff18291f)]
          : const [Color(0xfffbfffc), Color(0xffe9f1ec), Color(0xffcdded3)],
  };

  Shader _gradient(Rect bounds, List<Color> colors) => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: colors,
    stops: const [0, .48, 1],
  ).createShader(bounds);

  void _raised(Canvas c, Path path, _Finish finish, {double depth = 1.6}) {
    final colors = _colors(finish);
    final rect = path.getBounds();
    if (depth > 0) {
      c.drawPath(path.shift(Offset(.65, depth)), Paint()..color = colors.last);
    }
    c.drawPath(path, Paint()..shader = _gradient(rect, colors));
    c.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = highContrast ? 1.25 : .75
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: highContrast ? .85 : .60),
            colors.last.withValues(alpha: .50),
          ],
        ).createShader(rect),
    );
  }

  void _box(
    Canvas c,
    double x,
    double y,
    double w,
    double h,
    _Finish finish, {
    double radius = 4,
    double depth = 1.6,
  }) => _raised(
    c,
    Path()..addRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, w, h),
        Radius.circular(radius),
      ),
    ),
    finish,
    depth: depth,
  );

  void _orb(Canvas c, double x, double y, double r, _Finish finish) => _raised(
    c,
    Path()..addOval(Rect.fromCircle(center: Offset(x, y), radius: r)),
    finish,
    depth: 1,
  );

  void _stroke(Canvas c, Path path, Color color, double width) => c.drawPath(
    path,
    Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round,
  );

  void _line(
    Canvas c,
    double x1,
    double y1,
    double x2,
    double y2,
    Color color, {
    double width = 2.6,
  }) => _stroke(
    c,
    Path()
      ..moveTo(x1, y1)
      ..lineTo(x2, y2),
    color,
    width,
  );

  void _rod(
    Canvas c,
    double x1,
    double y1,
    double x2,
    double y2,
    _Finish finish, {
    double width = 5,
  }) {
    final p = Path()
      ..moveTo(x1, y1)
      ..lineTo(x2, y2);
    final colors = _colors(finish);
    _stroke(c, p.shift(const Offset(.6, 1.3)), colors.last, width + .3);
    c.drawPath(
      p,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..shader = _gradient(
          Rect.fromPoints(Offset(x1, y1), Offset(x2, y2)).inflate(width),
          colors,
        ),
    );
  }

  Color get _ink => dark ? const Color(0xffb9f7df) : const Color(0xff176c50);
  Color get _white => const Color(0xfff5fff9);
  Color get _deep => const Color(0xff174c39);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 64, size.height / 64);
    // One quiet enamel plinth, with a thin physical lower edge. The face is
    // independently lit from the object; it is never an extra glass filter.
    _box(canvas, 2, 1, 60, 59, _Finish.plate, radius: 14, depth: 2);
    switch (symbol) {
      case HipRowSymbol.groups:
        _groups(canvas);
      case HipRowSymbol.library:
        _library(canvas);
      case HipRowSymbol.assessment:
        _assessment(canvas);
      case HipRowSymbol.records:
        _records(canvas);
      case HipRowSymbol.settings:
        _settings(canvas);
      case HipRowSymbol.reminder:
        _reminder(canvas);
      case HipRowSymbol.chair:
        _chair(canvas);
      case HipRowSymbol.voice:
        _voice(canvas);
      case HipRowSymbol.sound:
        _sound(canvas);
      case HipRowSymbol.language:
        _language(canvas);
      case HipRowSymbol.volume:
        _volume(canvas);
      case HipRowSymbol.appearance:
        _appearance(canvas);
      case HipRowSymbol.safety:
        _safety(canvas);
      case HipRowSymbol.privacy:
        _privacy(canvas);
      case HipRowSymbol.addGroup:
        _addGroup(canvas);
      case HipRowSymbol.coach:
        _coach(canvas);
      case HipRowSymbol.completed:
        _status(canvas, true);
      case HipRowSymbol.paused:
        _status(canvas, false);
    }
    canvas.restore();
  }

  void _groups(Canvas c) {
    c.save();
    c.translate(30, 31);
    c.rotate(-.16);
    c.translate(-30, -31);
    _box(c, 13, 12, 29, 35, _Finish.pearl, radius: 5);
    _line(c, 19, 20, 34, 20, const Color(0xff8ca89b), width: 2);
    c.restore();
    _box(c, 22, 19, 29, 35, _Finish.jade, radius: 5, depth: 2);
    _box(c, 27, 25, 18, 4, _Finish.pearl, radius: 2, depth: .6);
    _box(c, 27, 35, 7, 10, _Finish.pearl, radius: 2, depth: .5);
    _box(c, 38, 35, 7, 10, _Finish.pearl, radius: 2, depth: .5);
  }

  void _library(Canvas c) {
    _box(c, 13, 18, 10, 33, _Finish.jade, radius: 3);
    _box(c, 26, 12, 11, 39, _Finish.pearl, radius: 3);
    _box(c, 40, 20, 10, 31, _Finish.jade, radius: 3);
    _line(c, 16, 25, 20, 25, _white, width: 1.8);
    _line(c, 29, 20, 34, 20, _deep, width: 2);
    _line(c, 43, 27, 47, 27, _white, width: 1.8);
    _line(c, 16, 44, 20, 44, _deep, width: 1.5);
    _line(c, 29, 44, 34, 44, const Color(0xff809b8d), width: 1.5);
    _line(c, 43, 44, 47, 44, _deep, width: 1.5);
  }

  void _assessment(Canvas c) {
    final pelvis = Path()
      ..moveTo(12, 20)
      ..cubicTo(12, 12, 20, 12, 25, 18)
      ..quadraticBezierTo(32, 25, 39, 18)
      ..cubicTo(44, 12, 52, 12, 52, 20)
      ..cubicTo(52, 30, 48, 37, 42, 39)
      ..lineTo(36, 33)
      ..quadraticBezierTo(32, 29, 28, 33)
      ..lineTo(22, 39)
      ..cubicTo(16, 37, 12, 30, 12, 20)
      ..close();
    _raised(c, pelvis, _Finish.jade, depth: 2);
    _rod(c, 23, 36, 20, 49, _Finish.pearl, width: 7);
    _rod(c, 41, 36, 44, 49, _Finish.pearl, width: 7);
    _orb(c, 23, 33, 6, _Finish.pearl);
    _orb(c, 41, 33, 6, _Finish.pearl);
    _line(c, 17, 20, 23, 24, _white, width: 1.4);
  }

  void _records(Canvas c) {
    _box(c, 14, 16, 37, 36, _Finish.pearl, radius: 6, depth: 2);
    _box(c, 14, 16, 37, 11, _Finish.jade, radius: 5, depth: .8);
    _rod(c, 23, 12, 23, 20, _Finish.steel, width: 3.8);
    _rod(c, 42, 12, 42, 20, _Finish.steel, width: 3.8);
    _stroke(
      c,
      Path()
        ..moveTo(23, 37)
        ..lineTo(30, 43)
        ..lineTo(42, 32),
      _deep,
      4.2,
    );
  }

  void _settings(Canvas c) {
    final gear = Path();
    for (var i = 0; i < 48; i++) {
      final angle = i * math.pi * 2 / 48 - math.pi / 2;
      final radius = i % 4 == 1 || i % 4 == 2 ? 19.0 : 15.5;
      final x = 32 + math.cos(angle) * radius,
          y = 32 + math.sin(angle) * radius;
      if (i == 0) {
        gear.moveTo(x, y);
      } else {
        gear.lineTo(x, y);
      }
    }
    gear.close();
    _raised(c, gear, _Finish.steel, depth: 2);
    _orb(c, 32, 32, 10, _Finish.jade);
    _orb(c, 32, 32, 5.1, _Finish.graphite);
    _line(c, 27, 24, 31, 23, _white, width: 1.3);
  }

  void _reminder(Canvas c) {
    _orb(c, 32, 47, 4.5, _Finish.jade);
    _orb(c, 32, 14, 3.3, _Finish.steel);
    final bell = Path()
      ..moveTo(19, 30)
      ..cubicTo(19, 12, 45, 12, 45, 30)
      ..lineTo(46, 37)
      ..quadraticBezierTo(47, 40, 50, 42)
      ..quadraticBezierTo(51, 45, 47, 45)
      ..lineTo(17, 45)
      ..quadraticBezierTo(13, 45, 14, 42)
      ..quadraticBezierTo(18, 39, 18, 36)
      ..close();
    _raised(c, bell, _Finish.pearl, depth: 2);
    _line(c, 24, 27, 24, 34, Colors.white.withValues(alpha: .9), width: 2);
    _box(c, 18, 41, 28, 3, _Finish.jade, radius: 1.5, depth: .5);
  }

  void _chair(Canvas c) {
    _rod(c, 31, 37, 31, 49, _Finish.steel, width: 4);
    _rod(c, 31, 47, 20, 51, _Finish.steel, width: 3.3);
    _rod(c, 31, 47, 43, 51, _Finish.steel, width: 3.3);
    _box(c, 23, 12, 20, 22, _Finish.jade, radius: 6, depth: 2);
    _box(c, 17, 32, 29, 7, _Finish.pearl, radius: 3.5, depth: 2);
    _rod(c, 17, 28, 17, 34, _Finish.steel, width: 2.4);
    _rod(c, 46, 28, 46, 34, _Finish.steel, width: 2.4);
    _line(c, 14, 27, 20, 27, _ink, width: 2.5);
    _line(c, 43, 27, 49, 27, _ink, width: 2.5);
    _line(c, 28, 17, 28, 25, _white, width: 1.4);
  }

  void _voice(Canvas c) {
    _rod(c, 32, 43, 32, 51, _Finish.steel, width: 3.5);
    _box(c, 23, 49, 18, 4, _Finish.jade, radius: 2);
    _stroke(
      c,
      Path()
        ..moveTo(18, 28)
        ..lineTo(18, 32)
        ..cubicTo(18, 49, 46, 49, 46, 32)
        ..lineTo(46, 28),
      _ink,
      3.3,
    );
    _box(c, 24, 11, 16, 29, _Finish.pearl, radius: 8, depth: 2);
    for (var y = 19.0; y <= 29; y += 5) {
      _line(c, 28, y, 35, y, const Color(0xff4b8c71), width: 1.7);
    }
  }

  void _sound(Canvas c) {
    _rod(c, 30, 19, 30, 43, _Finish.jade, width: 4);
    _rod(c, 45, 15, 45, 37, _Finish.jade, width: 4);
    _raised(
      c,
      Path()
        ..moveTo(29, 17)
        ..lineTo(47, 12)
        ..lineTo(47, 21)
        ..lineTo(29, 26)
        ..close(),
      _Finish.jade,
    );
    _raised(
      c,
      Path()..addOval(const Rect.fromLTWH(18, 38, 14, 11)),
      _Finish.pearl,
    );
    _raised(
      c,
      Path()..addOval(const Rect.fromLTWH(33, 32, 14, 11)),
      _Finish.pearl,
    );
  }

  void _language(Canvas c) {
    _box(c, 29, 13, 24, 29, _Finish.jade, radius: 5, depth: 2);
    _line(c, 35, 23, 47, 23, _white, width: 2);
    _line(c, 40, 19, 41, 20, _white, width: 2);
    _stroke(
      c,
      Path()
        ..moveTo(37, 26)
        ..quadraticBezierTo(41, 32, 48, 35),
      _white,
      2,
    );
    _stroke(
      c,
      Path()
        ..moveTo(46, 24)
        ..quadraticBezierTo(42, 32, 36, 35),
      _white,
      2,
    );
    _box(c, 11, 22, 26, 29, _Finish.pearl, radius: 5, depth: 2);
    _stroke(
      c,
      Path()
        ..moveTo(17, 43)
        ..lineTo(24, 29)
        ..lineTo(31, 43),
      _deep,
      2.8,
    );
    _line(c, 20, 39, 28, 39, _deep, width: 2.4);
  }

  void _volume(Canvas c) {
    _box(c, 12, 26, 12, 16, _Finish.jade, radius: 3);
    _raised(
      c,
      Path()
        ..moveTo(22, 26)
        ..lineTo(34, 17)
        ..quadraticBezierTo(37, 15, 37, 19)
        ..lineTo(37, 47)
        ..quadraticBezierTo(37, 51, 34, 49)
        ..lineTo(22, 41)
        ..close(),
      _Finish.pearl,
      depth: 2,
    );
    _line(c, 33, 24, 33, 42, Colors.white.withValues(alpha: .9), width: 1.5);
    for (final r in [11.0, 17.0]) {
      _stroke(
        c,
        Path()..addArc(
          Rect.fromCircle(center: const Offset(32, 33), radius: r),
          -.72,
          1.44,
        ),
        _ink,
        2.7,
      );
    }
  }

  void _appearance(Canvas c) {
    _orb(c, 32, 32, 19, _Finish.pearl);
    final half = Path()
      ..moveTo(32, 13)
      ..arcTo(const Rect.fromLTWH(13, 13, 38, 38), -math.pi / 2, math.pi, false)
      ..cubicTo(43, 40, 21, 24, 32, 13)
      ..close();
    _raised(c, half, _Finish.graphite, depth: 0);
    _line(c, 22, 20, 25, 18, Colors.white.withValues(alpha: .9), width: 2);
    _orb(c, 43, 31, 2.4, _Finish.jade);
  }

  void _safety(Canvas c) {
    _raised(
      c,
      Path()
        ..moveTo(32, 11)
        ..lineTo(49, 18)
        ..lineTo(49, 32)
        ..cubicTo(49, 44, 39, 51, 32, 54)
        ..cubicTo(25, 51, 15, 44, 15, 32)
        ..lineTo(15, 18)
        ..close(),
      _Finish.jade,
      depth: 2,
    );
    _stroke(
      c,
      Path()
        ..moveTo(23, 32)
        ..lineTo(29, 38)
        ..lineTo(42, 25),
      _white,
      4.2,
    );
  }

  void _privacy(Canvas c) {
    _raised(
      c,
      Path()
        ..moveTo(14, 12)
        ..lineTo(36, 12)
        ..lineTo(47, 23)
        ..lineTo(47, 51)
        ..lineTo(14, 51)
        ..close(),
      _Finish.pearl,
      depth: 2,
    );
    _raised(
      c,
      Path()
        ..moveTo(36, 12)
        ..lineTo(36, 23)
        ..lineTo(47, 23)
        ..close(),
      _Finish.steel,
      depth: .5,
    );
    _line(c, 20, 22, 28, 22, const Color(0xff6c9c86), width: 2);
    _line(c, 20, 28, 26, 28, const Color(0xff6c9c86), width: 2);
    _stroke(
      c,
      Path()
        ..moveTo(33, 35)
        ..lineTo(33, 28)
        ..cubicTo(33, 18, 47, 18, 47, 28)
        ..lineTo(47, 35),
      _deep,
      3.5,
    );
    _box(c, 28, 33, 24, 20, _Finish.jade, radius: 5, depth: 2);
    c.drawCircle(const Offset(40, 41), 2.3, Paint()..color = _deep);
    _line(c, 40, 42, 40, 46, _deep, width: 2.1);
  }

  void _addGroup(Canvas c) {
    _box(c, 12, 16, 25, 16, _Finish.pearl, radius: 4);
    _raised(
      c,
      Path()
        ..moveTo(12, 23)
        ..lineTo(27, 23)
        ..lineTo(31, 27)
        ..lineTo(50, 27)
        ..lineTo(48, 50)
        ..lineTo(14, 50)
        ..close(),
      _Finish.jade,
      depth: 2,
    );
    _orb(c, 38, 38, 11, _Finish.pearl);
    _line(c, 38, 32, 38, 44, _deep, width: 2.9);
    _line(c, 32, 38, 44, 38, _deep, width: 2.9);
  }

  void _coach(Canvas c) {
    _raised(
      c,
      Path()
        ..moveTo(30, 12)
        ..quadraticBezierTo(33, 26, 47, 31)
        ..quadraticBezierTo(33, 35, 30, 51)
        ..quadraticBezierTo(26, 35, 12, 31)
        ..quadraticBezierTo(26, 26, 30, 12)
        ..close(),
      _Finish.pearl,
      depth: 2,
    );
    _orb(c, 30, 31, 4.8, _Finish.jade);
    _raised(
      c,
      Path()
        ..moveTo(48, 12)
        ..quadraticBezierTo(49, 18, 55, 20)
        ..quadraticBezierTo(49, 22, 48, 28)
        ..quadraticBezierTo(46, 22, 41, 20)
        ..quadraticBezierTo(46, 18, 48, 12)
        ..close(),
      _Finish.jade,
    );
  }

  void _status(Canvas c, bool completed) {
    _orb(c, 32, 32, 19, completed ? _Finish.jade : _Finish.pearl);
    if (completed) {
      _stroke(
        c,
        Path()
          ..moveTo(22, 32)
          ..lineTo(29, 39)
          ..lineTo(43, 25),
        _white,
        4.5,
      );
    } else {
      _box(c, 24, 23, 5.5, 18, _Finish.graphite, radius: 2, depth: .5);
      _box(c, 35, 23, 5.5, 18, _Finish.graphite, radius: 2, depth: .5);
    }
  }

  @override
  bool shouldRepaint(HipRowEmblemPainter oldDelegate) =>
      oldDelegate.symbol != symbol ||
      oldDelegate.dark != dark ||
      oldDelegate.highContrast != highContrast;
}
