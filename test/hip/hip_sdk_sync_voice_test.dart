import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hiplab/hip/trainer/hip_sdk_session_builder.dart';
import 'package:hiplab/hip/voice/hip_voice.dart';
import 'package:hiplab/hip/voice/session_script.dart';
import 'package:hiplab/hip/voice/voice_library.dart';
import 'package:hiplab/hip/voice/voice_queue.dart';
import 'package:ugk_coach/ugk_coach.dart' as coach;
import 'package:ugk_trainer_runtime/ugk_trainer_runtime.dart' as trainer;

import 'hip_domain_test.dart' show loadContent;
import 'hip_voice_test.dart' show loadVoiceLibrary;

class _VoiceHttp implements trainer.PoseHubCatalogHttpClient {
  final requested = <Uri>[];

  @override
  Future<trainer.PoseHubCatalogHttpResponse> get(
    Uri uri, {
    Map<String, String> headers = const {},
    int maxBytes = 64 * 1024 * 1024,
  }) async {
    requested.add(uri);
    return trainer.PoseHubCatalogHttpResponse(
      200,
      Uint8List.fromList([97, 98, 99]),
    );
  }
}

trainer.LayeredVoiceSource _online(
  VoiceLibrary lib,
  _VoiceHttp http,
) => trainer.LayeredVoiceSource(
  primary: lib,
  catalog: trainer.CatalogVoiceIndex.fromCatalogJson({
    'mediaDistribution': {'baseUrl': 'https://media.example/pack/current/'},
    'actions': [
      for (final id in ['chest-A', 's-pigeon'])
        {
          'id': id,
          'nameEn': 'Current catalogue action',
          'cues': {
            'en': ['Current catalogue key point'],
          },
          'voice': {
            'files': [
              for (final clip in ['name', 'primaryCue'])
                {
                  'language': 'en',
                  'clipId': clip,
                  'path': 'voice/$id/en/$clip.m4a',
                  'bytes': 3,
                  'sha256':
                      'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
                  'durationSeconds': 20.0,
                },
            ],
          },
        },
    ],
  }),
  cache: trainer.CatalogVoiceCache(
    store: trainer.MemoryPoseHubCatalogStore(),
    pathOf: (name) => '/verified/$name',
    http: http,
  ),
);

HipSessionScript _script(
  VoiceLibrary lib, {
  String lang = 'en',
  trainer.VoiceSource? online,
  bool sdk = true,
}) => HipSessionScript(
  lib: lib,
  lang: lang,
  steps: const [],
  kits: const {},
  useSdkPhases: sdk,
  online: online,
);

void main() {
  final lib = loadVoiceLibrary();

  test('local SDK playback exposes no unnecessary preparation callback', () {
    expect(_script(lib).source, isNot(isA<trainer.PreparableVoiceSource>()));
  });

  test(
    'locale view retains catalogue source and independent sound settings',
    () {
      final online = _online(lib, _VoiceHttp());
      var settings = const VoiceSettings(
        language: VoiceLanguage.app,
        chimes: false,
        volume: .4,
      );
      final voice = HipVoice(
        lib: lib,
        online: online,
        output: const MutedVoiceOutput(),
        settingsOf: () => settings,
      );
      final english = voice.withAppLanguage('en-US');
      expect(english.online, same(online));
      expect(english.lib, same(lib));
      expect(english.output, same(voice.output));
      expect(english.lang, 'en');
      expect(english.settings.chimes, isFalse);
      expect(english.settings.volume, .4);
      settings = settings.copyWith(language: VoiceLanguage.zh);
      expect(english.lang, 'zh');
      expect(english.withAppLanguage('zh').online, same(online));
    },
  );

  test(
    'SDK script prepares verified catalogue voice with local priority',
    () async {
      final http = _VoiceHttp();
      final online = _online(lib, http);
      final script = _script(lib, online: online);
      final source = script.source;
      final name = source.drill('chest-A', trainer.DrillLine.name)!;
      final cue = source.drill('chest-A', trainer.DrillLine.cue1)!;
      expect(name, trainer.LayeredVoiceSource.keyOf('chest-A', 'name'));
      expect(source.expected(name, lang: 'en'), isTrue);
      expect(source.has(name, lang: 'en'), isFalse);
      expect(
        source.drillText('chest-A', trainer.DrillLine.name, lang: 'en'),
        'Current catalogue action',
      );
      expect(
        source.drill('s-pigeon', trainer.DrillLine.name),
        lib.drill('s-pigeon', trainer.DrillLine.name),
      );
      await (source as trainer.PreparableVoiceSource).prepare([
        'chest-A',
      ], lang: 'en');
      expect(source.has(name, lang: 'en'), isTrue);
      expect(source.has(cue, lang: 'en'), isTrue);
      expect(source.asset(name, lang: 'en'), startsWith('/verified/'));
      expect(http.requested, isNotEmpty);
      expect(
        http.requested.every((uri) => uri.path.startsWith('/pack/current/')),
        isTrue,
      );
      final intro = script.cues(
        trainer.SessionPhase(
          kind: trainer.PhaseKind.prep,
          seconds: 60,
          exerciseId: 'chest-A',
          item: const coach.PlanItem(
            exerciseId: 'chest-A',
            mode: coach.DoseMode.time,
            sets: 1,
            perSide: false,
            restSeconds: 0,
            workSeconds: 30,
          ),
        ),
        planSeconds: 90,
      );
      expect(intro.expand((c) => c.clips), containsAll([name, cue]));
    },
  );

  test(
    'expected catalogue intro extends SDK prep before download finishes',
    () {
      final script = _script(lib, online: _online(lib, _VoiceHttp()));
      const item = coach.PlanItem(
        exerciseId: 'chest-A',
        mode: coach.DoseMode.time,
        sets: 1,
        perSide: false,
        restSeconds: 0,
        workSeconds: 30,
      );
      final needed = script.prepSecondsFor(
        item,
        item.exerciseId,
        minimum: 15,
        planSeconds: 45,
      );
      expect(needed, greaterThan(40));
      final builder = hipSdkSessionBuilder(
        loadContent(),
        prepSecondsFor: script.prepSecondsFor,
      );
      final plan = coach.TrainingPlan(
        id: 'catalogue-intro',
        source: 'template',
        title: 'Intro',
        goal: 'training',
        scene: 'home',
        level: 1,
        targetMinutes: 1,
        blocks: [
          coach.PlanBlock(
            id: 'main',
            name: 'Main',
            type: coach.BlockType.main,
            items: [item],
          ),
        ],
      );
      expect(builder.phases(plan).first.seconds, greaterThanOrEqualTo(needed));
    },
  );

  test(
    'legacy script ignores catalogue decoration and never downloads',
    () async {
      final http = _VoiceHttp();
      final source = _script(
        lib,
        online: _online(lib, http),
        sdk: false,
      ).source;
      final name = source.drill('chest-A', trainer.DrillLine.name)!;
      expect(name, lib.drill('chest-A', trainer.DrillLine.name));
      expect(source.has(name, lang: 'en'), isFalse);
      expect(source, isNot(isA<trainer.PreparableVoiceSource>()));
      expect(http.requested, isEmpty);
    },
  );

  for (final lang in ['zh', 'en']) {
    test(
      '$lang records 11-15 and speaks every count in an actual 15-rep phase',
      () {
        final script = _script(lib, lang: lang);
        for (var n = 11; n <= 15; n++) {
          expect(script.source.has('n.$n', lang: lang), isTrue);
          expect(
            File(script.source.asset('n.$n', lang: lang)).existsSync(),
            isTrue,
          );
        }
        final cues = script.cues(
          trainer.SessionPhase(
            kind: trainer.PhaseKind.work,
            seconds: 60,
            exerciseId: 'chest-A',
            reps: 15,
            rhythm: trainer.Rhythm.fromRepSeconds(4),
          ),
          planSeconds: 60,
        );
        final clips = cues.expand((c) => c.clips);
        expect(clips, containsAll(['n.11', 'n.12', 'n.13', 'n.14', 'n.15']));
      },
    );

    test('$lang set and round ordinals use the language word order', () {
      final script = _script(lib, lang: lang);
      final expectedSet = lang == 'en'
          ? ['p.set', 'n.3']
          : ['p.di', 'n.3', 'u.sets'];
      final expectedRound = lang == 'en'
          ? ['p.round', 'n.3']
          : ['p.di', 'n.3', 'u.rounds'];
      expect(script.source.ordinalSet(3, lang: lang), expectedSet);
      expect(script.source.ordinalRound(3, lang: lang), expectedRound);
      for (final key in {...expectedSet, ...expectedRound}) {
        expect(lib.has(key, lang: lang), isTrue, reason: key);
        expect(
          File(lib.asset(key, lang: lang)).existsSync(),
          isTrue,
          reason: key,
        );
      }
      for (final (kind, expected) in [
        (trainer.PhaseKind.rest, expectedSet),
        (trainer.PhaseKind.roundRest, expectedRound),
      ]) {
        final cues = script.cues(
          trainer.SessionPhase(
            kind: kind,
            seconds: 20,
            exerciseId: 'chest-A',
            set: 3,
            sets: 4,
            round: 3,
            rounds: 4,
          ),
          planSeconds: 120,
        );
        expect(cues.map((cue) => cue.clips), contains(equals(expected)));
      }
    });
  }
}
