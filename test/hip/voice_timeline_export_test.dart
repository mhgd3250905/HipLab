// Exports the voice timeline of a real session as JSON for
// `tools/voice/build_voice.py demo` (a mixed listening demo of the clips).
// Skipped unless VOICE_TIMELINE_OUT is set:
//
//   VOICE_TIMELINE_OUT=/tmp/tl-zh.json VOICE_LANG=zh VOICE_ROUTINE=A \
//     flutter test test/hip/voice_timeline_export_test.dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hiplab/hip/domain/hip_session.dart';

import 'hip_domain_test.dart' show loadContent;
import 'hip_voice_test.dart' show Sim;

void main() {
  final out = Platform.environment['VOICE_TIMELINE_OUT'];
  test('export voice timeline', () {
    final lang = Platform.environment['VOICE_LANG'] ?? 'zh';
    final content = loadContent();
    final plan = TrainingPlanner(content).planFor([
      content.routine(Platform.environment['VOICE_ROUTINE'] ?? 'A'),
    ], const TrainingProfile(level: 3));
    final sim = Sim(plan, lang: lang)..run();
    final events = <Map<String, Object>>[];
    for (final l in sim.lines) {
      var t = l.start;
      for (final c in l.clips) {
        if (l.cutAt != null && t >= l.cutAt!) break;
        events.add({'t': double.parse(t.toStringAsFixed(3)), 'clip': c});
        t += sim.lib.seconds(c, lang: lang) + .06;
      }
    }
    for (final (t, c) in sim.queue.chimeLog) {
      events.add({'t': t, 'clip': c});
    }
    events.sort((a, b) => (a['t'] as double).compareTo(b['t'] as double));
    File(out!).writeAsStringSync(jsonEncode(events));
  }, skip: out == null ? 'set VOICE_TIMELINE_OUT to export' : false);
}
