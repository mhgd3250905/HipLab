// Action kits (docs/action-kit-spec-v1.md): every action a HipLab routine
// can play – the routine drills, their L1 alternatives and pain-ladder
// substitutes – has a complete kit, aligned with the frozen Pose-Hub
// release, whose every spoken line fits the phase it announces in zh and
// en; routines reference kits and only override the dose.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hiplab/hip/domain/hip_models.dart';

import 'hip_domain_test.dart' show loadContent;
import 'hip_voice_test.dart' show loadVoiceLibrary;

Map<String, dynamic> readJson(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

void main() {
  final content = loadContent();
  final lib = loadVoiceLibrary();
  final raw = readJson('assets/hip/hip-content.json');

  Set<String> playable() {
    final out = <String>{};
    for (final r in content.routines) {
      for (final s in r.steps) {
        out.add(s.drillId);
        final alt = s.alternative ?? content.drill(s.drillId).alternative;
        if (alt != null) out.add(alt);
      }
    }
    // pain ladder substitutes of anything playable
    for (final id in [...out]) {
      final alt = content.drill(id).alternative;
      if (alt != null) out.add(alt);
    }
    return out;
  }

  test('every playable action has a kit; kits = Pose-Hub frozen ids', () {
    for (final id in playable()) {
      expect(content.kit(id), isNotNull, reason: '$id has no action kit');
    }
    final lock = readJson('pose-hub.lock.json');
    final manifest = readJson('tools/pose-hub-manifest.json');
    final version = (lock['poseHub'] as Map)['version'] as String;
    final specs = <String, String>{
      for (final it
          in ((manifest['releases'] as Map)[version] as Map)['items'] as List)
        if ((it as Map)['role'] == 'video' && it['variant'] == 'dark')
          it['id'] as String: (it['spec'] as Map)['sha256'] as String,
    };
    for (final k in content.kits.values) {
      final media = (k.raw['media'] as Map)['poseHub'] as Map;
      expect(specs.keys, contains(k.id));
      expect(media['version'], version, reason: k.id);
      expect(media['specSha256'], specs[k.id], reason: '${k.id} stale');
    }
  });

  test('kits are complete: display, media slots, training, voice', () {
    for (final k in content.kits.values) {
      final j = k.raw;
      expect(j['schema'], 'action-kit@1');
      final d = j['display'] as Map;
      for (final f in ['name', 'point']) {
        expect((d[f] as Map)['zh'], isNotEmpty, reason: '${k.id} $f.zh');
        expect((d[f] as Map)['en'], isNotEmpty, reason: '${k.id} $f.en');
      }
      expect(d['targets'], isNotEmpty);
      expect(d['sided'], k.sided);
      final video = (j['media'] as Map)['video'] as Map;
      expect((video['dark'] as Map)['asset'], isNotNull, reason: k.id);
      expect(
        File((video['dark'] as Map)['asset'] as String).existsSync(),
        isTrue,
      );
      expect(video.containsKey('light'), isTrue, reason: 'light slot');
      if (k.kind.counted) {
        expect(k.phases, isNotEmpty);
        expect(k.phases.first.id, 'go');
        expect(k.phases.first.cues, isNotEmpty, reason: '${k.id} go word');
        expect(k.defaultReps, isNotNull);
      } else {
        expect(k.defaultSeconds, isNotNull);
      }
      // every clip a kit can say exists in both languages
      final v = k.voice;
      final clips = <String>{
        ...v.prepare,
        v.go,
        v.lastRep,
        v.nextSet,
        v.end,
        ...v.coach,
        ?v.firstSide,
        ?v.half,
        ?v.last10,
        for (final p in k.phases) ...p.cues,
        for (var n = 1; n <= 10; n++) v.countClip(n),
      };
      for (final lang in ['zh', 'en']) {
        for (final c in clips) {
          expect(lib.has(c, lang: lang), isTrue, reason: '${k.id}: $lang/$c');
        }
      }
    }
  });

  test('every spoken line fits its phase window (zh and en)', () {
    for (final k in content.kits.values.where((k) => k.kind.counted)) {
      final dose = KitDose(holdSeconds: k.defaultHold);
      final ph = k.phasesFor(dose);
      final cueAt = <(int, double)>[];
      var t = 0.0;
      for (final (i, p) in ph.indexed) {
        if (p.cues.isNotEmpty) cueAt.add((i, t + p.cueAt));
        t += p.seconds;
      }
      final cycle = t;
      for (final lang in ['zh', 'en']) {
        double len(List<String> c) => lib.total(c, lang: lang);
        for (final (n, (i, at)) in cueAt.indexed) {
          final next = n + 1 < cueAt.length ? cueAt[n + 1].$2 : cycle;
          for (final word in ph[i].cues) {
            final heads = i == 0
                ? [
                    for (var r = 1; r <= 10; r++) [k.voice.countClip(r)],
                    [k.voice.lastRep],
                  ]
                : [<String>[]];
            for (final h in heads) {
              expect(
                len([...h, word]),
                lessThanOrEqualTo(next - at - .1),
                reason: '${k.id} $lang ${[...h, word]} in ${next - at}s',
              );
            }
          }
        }
      }
    }
  });

  test('routines reference kits and only override the dose', () {
    for (final r in raw['routines'] as List) {
      for (final s in (r as Map)['steps'] as List) {
        final step = s as Map;
        final ref = step['kit'] as Map?;
        expect(ref, isNotNull, reason: '${r['id']} ${step['drill']}');
        expect(ref!['id'], step['drill']);
        expect(
          ref.keys.toSet().difference({'id', 'reps', 'holdSeconds', 'seconds'}),
          isEmpty,
          reason: 'a routine step only overrides the dose',
        );
        final kit = content.kit(step['drill'] as String)!;
        final sided = step['sided'] as bool;
        final secs = step['seconds'] as int;
        expect(
          content.stepSeconds(
            kit.id,
            KitDose.fromJson(ref.cast()),
            sided,
            secs,
          ),
          secs,
          reason: '${r['id']} ${kit.id}: content seconds ≠ kit rhythm',
        );
        expect(sided, kit.sided, reason: '${r['id']} ${kit.id} sided');
      }
    }
  });

  test('routine lengths still match their names', () {
    for (final r in content.routines) {
      final m = RegExp(r'(\d+) 分钟').firstMatch(r.name);
      if (m == null) continue;
      expect(r.minutes, int.parse(m[1]!), reason: r.name);
    }
  });
}
