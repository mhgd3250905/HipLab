// Exports a real session's spoken timeline (not part of `flutter test`):
//   flutter test --no-pub test_screens/voice_timeline_export_test.dart
// → build/voice/timeline-<routine>.json ({t, clip} incl. chimes) and a
//   readable .txt; feed the json to `tools/voice/build_voice.py demo`.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hiplab/hip/domain/hip_session.dart';

import '../test/hip/hip_domain_test.dart' show loadContent;
import '../test/hip/hip_voice_test.dart' show Sim;

void main() {
  final content = loadContent();
  for (final (id, lang) in [('D', 'zh'), ('D', 'en'), ('F', 'zh')]) {
    test('export $id $lang', () {
      final plan = TrainingPlanner(
        content,
      ).planFor([content.routine(id)], const TrainingProfile(level: 3));
      final sim = Sim(plan, lang: lang)..run();
      final events = <Map<String, Object>>[
        for (final l in sim.lines)
          for (final (i, c) in l.clips.indexed)
            {'t': l.start + _offset(sim, l.clips, i), 'clip': c},
        for (final (t, c) in sim.queue.chimeLog) {'t': t, 'clip': c},
      ]..sort((a, b) => (a['t'] as double).compareTo(b['t'] as double));
      Directory('build/voice').createSync(recursive: true);
      File(
        'build/voice/timeline-$id-$lang.json',
      ).writeAsStringSync(jsonEncode(events));
      File('build/voice/timeline-$id-$lang.txt').writeAsStringSync(
        [
          for (final l in sim.lines)
            '${l.toString()}  ${l.clips.map((c) => sim.lib.line(c, lang: lang) ?? c).join('')}',
        ].join('\n'),
      );
    });
  }
}

double _offset(Sim sim, List<String> clips, int i) {
  var t = 0.0;
  for (var k = 0; k < i; k++) {
    t += sim.lib.seconds(clips[k], lang: sim.queue.lang) + .06;
  }
  return t;
}
