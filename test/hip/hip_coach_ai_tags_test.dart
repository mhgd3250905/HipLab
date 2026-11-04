import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiplab/hip/coach/hip_coach_ai_tags.dart';
import 'package:hiplab/hip/data/hip_action_scope.dart';

class _DraftBundle extends CachingAssetBundle {
  _DraftBundle(this.source);

  final Map<String, Object?> source;
  final loaded = <String>[];

  @override
  Future<ByteData> load(String key) async {
    loaded.add(key);
    final bytes = utf8.encode(jsonEncode(source));
    final padded = Uint8List(bytes.length + 8)
      ..setRange(4, bytes.length + 4, bytes);
    return ByteData.sublistView(padded, 4, bytes.length + 4);
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) =>
      throw StateError('AI tags must use the byte loading path');
}

Map<String, Object?> _draft(Map<String, Object?> actions) => {
  'format': 'hiplab-coach-ai-tags@1',
  'source': {'commit': hipCoachAiTagsSourceCommit},
  'status': 'ai-draft',
  'reviewed': false,
  'actions': actions,
};

Map<String, Object?> _action(String id) => {
  'format': 'pose-hub-ai-tags@1',
  'id': id,
  'status': 'ai-draft',
  'aiSummary': {'zh': 'Unreviewed suggestion'},
  'alternatives': ['out-of-scope-related-action'],
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'loads the pinned original drafts without broadening action scope',
    () async {
      final source =
          jsonDecode(File(hipCoachAiTagsAsset).readAsStringSync())
              as Map<String, dynamic>;
      final bundle = _DraftBundle(source);
      final tags = await loadHipCoachAiTags(bundle: bundle);
      final originals = source['actions'] as Map<String, dynamic>;

      expect(bundle.loaded, [hipCoachAiTagsAsset]);
      expect(source['source']['commit'], hipCoachAiTagsSourceCommit);
      expect(source['reviewed'], isFalse);
      expect(source['status'], 'ai-draft');
      expect(tags, hasLength(209));
      expect(tags.keys.every(hiplabCoachAuthorizedActionIds.contains), isTrue);
      expect(tags.containsKey('h-sleeper-stretch'), isFalse);
      expect(tags.containsKey('scapular-C'), isFalse);
      expect(source['missingAuthorizedIds'], [
        'h-sleeper-stretch',
        'scapular-C',
      ]);
      for (final entry in tags.entries) {
        expect(entry.value, originals[entry.key], reason: entry.key);
        expect(entry.value['status'], 'ai-draft', reason: entry.key);
      }
      expect(
        tags['h-squat']!['source'],
        containsPair(
          'textSha256Lf',
          '2f64c11c89a93f62105bb1f0bee1d52eaa3237c8ecef27e87388d4d254e02dd4',
        ),
      );
    },
  );

  test(
    'caller may narrow scope but cannot admit an unauthorized draft',
    () async {
      final raw = _action('h-squat');
      final bundle = _DraftBundle(
        _draft({
          'h-squat': raw,
          'h-band-row': _action('h-band-row'),
          'not-in-hiplab': _action('not-in-hiplab'),
        }),
      );
      final tags = await loadHipCoachAiTags(
        bundle: bundle,
        allowedActionIds: {'h-squat', 'not-in-hiplab'},
      );

      expect(tags.keys, ['h-squat']);
      // Original draft relationships are retained as data, not auto-admitted IDs.
      expect(tags['h-squat'], raw);
      expect(() => tags['h-band-row'] = {}, throwsUnsupportedError);
      expect(
        () => tags['h-squat']!['status'] = 'reviewed',
        throwsUnsupportedError,
      );
    },
  );

  test('missing tags stay missing instead of being manufactured', () async {
    final tags = await loadHipCoachAiTags(
      bundle: _DraftBundle(_draft({'h-squat': _action('h-squat')})),
      allowedActionIds: {'h-band-row'},
    );
    expect(tags, isEmpty);
  });

  test(
    'rejects changed source or approval status and mismatched action IDs',
    () async {
      final changedSource = _draft({'h-squat': _action('h-squat')})
        ..['source'] = {'commit': 'another-commit'};
      final changedStatus = _draft({'h-squat': _action('h-squat')})
        ..['reviewed'] = true;
      final wrongId = _draft({'h-squat': _action('h-band-row')});
      for (final source in [changedSource, changedStatus, wrongId]) {
        await expectLater(
          loadHipCoachAiTags(bundle: _DraftBundle(source)),
          throwsFormatException,
        );
      }
    },
  );
}
