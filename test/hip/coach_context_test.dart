import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hiplab/hip/coach/coach_context.dart';
import 'package:hiplab/hip/control/hip_store.dart';
import 'package:hiplab/hip/domain/hip_assessment.dart';
import 'package:hiplab/hip/domain/hip_models.dart';
import 'package:hiplab/hip/domain/hip_pain.dart';
import 'package:ugk_coach/ugk_coach.dart' as uc;

import 'hip_domain_test.dart' show MemoryStorage, all, loadContent;

void main() {
  final content = loadContent();
  final catalog = uc.Catalog.fromJson(
    jsonDecode(File('assets/coach/catalog.json').readAsStringSync()),
  );
  final now = DateTime(2026, 10, 21, 12);

  HipStore store({DateTime Function()? clock}) => HipStore(
    content: content,
    storage: MemoryStorage(),
    clock: clock ?? () => now,
  );

  test('no assessment uses App defaults without inventing equipment', () {
    final context = buildCoachContext(store(), catalog: catalog);
    expect(context.level, 1);
    expect(context.minutes, 10);
    expect(context.scene, 'home');
    expect(context.equipment, isNull);
    expect(context.avoid, isEmpty);
    expect(context.notes, contains('尚未完成自测，使用 App 默认的入门水平。'));
  });

  for (final (score, level) in [(0, 1), (1, 2), (2, 3)]) {
    test('assessment score $score supplies the actual level $level', () {
      final state = store()..assessments.add((at: now, answers: all(score)));
      final context = buildCoachContext(state, catalog: catalog);
      expect(context.level, level);
      expect(context.level, state.profile.level);
      expect(context.notes.any((n) => n.contains('尚未完成自测')), isFalse);
    });
  }

  test('each request reads the currently selected duration and scene', () {
    final state = store();
    for (final minutes in [5, 10, 15]) {
      state.minutes = minutes;
      state.scene = HipScene.chair;
      final office = buildCoachContext(state, catalog: catalog);
      expect(office.minutes, minutes);
      expect(office.scene, 'office');
      state.scene = HipScene.home;
      expect(buildCoachContext(state, catalog: catalog).scene, 'home');
    }
  });

  for (final type in ['pain', 'skip', 'nerve']) {
    test('recent $type protects hip and retains the reported direction', () {
      final state = store()
        ..painEvents.add(
          PainEvent(
            now.subtract(const Duration(days: 1)),
            HipDirection.internalRotation,
            type,
          ),
        );
      final context = buildCoachContext(state, catalog: catalog);
      expect(context.avoid, {'髋'});
      expect(context.notes, contains('最近7天有疼痛反馈的髋方向：内旋。'));
      // The recorded direction cannot establish a knee/waist injury, even
      // though many exercises in the same direction have those cautions.
      expect(context.avoid.intersection({'膝', '腰'}), isEmpty);
      expect(state.profile.lockedDirections, isEmpty);
      expect(context.notes.any((n) => n.contains('已限制为放松')), isFalse);
    });
  }

  test('recent pain includes exactly seven days, then expires', () {
    var clock = now;
    final state = store(clock: () => clock)
      ..painEvents.add(
        PainEvent(
          now.subtract(PainHistory.window),
          HipDirection.flexion,
          'pain',
        ),
      );
    expect(buildCoachContext(state, catalog: catalog).avoid, {'髋'});
    clock = now.add(const Duration(microseconds: 1));
    final expired = buildCoachContext(state, catalog: catalog);
    expect(expired.avoid, isEmpty);
    expect(expired.notes.any((n) => n.contains('最近7天')), isFalse);
  });

  test('future-dated pain does not become a current protection', () {
    final state = store()
      ..painEvents.add(
        PainEvent(
          now.add(const Duration(seconds: 1)),
          HipDirection.extension,
          'pain',
        ),
      );
    final context = buildCoachContext(state, catalog: catalog);
    expect(context.avoid, isEmpty);
    expect(context.notes.any((n) => n.contains('最近7天')), isFalse);
  });

  test('two-skip lock follows App expiry independently of recent pain', () {
    var clock = now;
    final state = store(clock: () => clock)
      ..painEvents.addAll([
        PainEvent(
          now.subtract(const Duration(days: 8)),
          HipDirection.abduction,
          'skip',
        ),
        PainEvent(
          now.subtract(const Duration(days: 6)),
          HipDirection.abduction,
          'skip',
        ),
      ]);
    final active = buildCoachContext(state, catalog: catalog);
    expect(active.avoid, {'髋'});
    expect(active.notes, contains('App 已限制为放松练习的髋方向：外展。'));
    clock = now.add(const Duration(days: 1));
    final atExpiry = buildCoachContext(state, catalog: catalog);
    expect(atExpiry.notes.any((n) => n.contains('已限制为放松')), isFalse);
    expect(atExpiry.avoid, {'髋'}, reason: 'exactly seven days is still recent');
    clock = clock.add(const Duration(microseconds: 1));
    expect(buildCoachContext(state, catalog: catalog).avoid, isEmpty);
  });

  test('assessment pain lasts until a new pain-free assessment', () {
    final answers = all(2)
      ..['butterfly'] = const ItemAnswer.single(SideAnswer.pain());
    final state = store()
      ..assessments.add((
        at: now.subtract(const Duration(days: 30)),
        answers: answers,
      ));
    final context = buildCoachContext(state, catalog: catalog);
    expect(context.avoid, {'髋'});
    expect(context.notes.any((n) => n.contains('已限制为放松')), isTrue);
    expect(context.notes.any((n) => n.contains('最近7天')), isFalse);
    state.assessments.add((at: now, answers: all(2)));
    expect(buildCoachContext(state, catalog: catalog).avoid, isEmpty);
  });

  test('safety answers and numbness follow-up remain factual notes', () {
    final state = store()
      ..safety = {'pregnancy': false, 'surgery': true, 'acute': false}
      ..askNumbness = true;
    final context = buildCoachContext(state, catalog: catalog);
    expect(
      context.notes,
      contains(
        '安全检查“${content.safetyCards.firstWhere((c) => c.id == 'surgery').title}”：有。',
      ),
    );
    expect(context.notes, contains('App 安全检查尚未解除，当前仅供浏览。'));
    expect(context.notes, contains('App 的麻木复查标记尚未解除。'));
    expect(context.notes.any((n) => n.startsWith('安全检查“孕期')), isFalse);
    expect(
      context.avoid,
      isEmpty,
      reason: 'the card does not identify a body part',
    );
  });

  test(
    'protection uses catalog vocabulary without dropping the pain facts',
    () {
      final withoutHip = uc.Catalog(
        version: 'test',
        drills: const [],
        taxonomy: const uc.Taxonomy(cautions: ['膝', '腰']),
      );
      final state = store()
        ..painEvents.add(PainEvent(now, HipDirection.externalRotation, 'pain'));
      final context = buildCoachContext(state, catalog: withoutHip);
      expect(context.avoid, isEmpty);
      expect(context.notes, contains('最近7天有疼痛反馈的髋方向：外旋。'));
      expect(context.notes, contains('当前动作目录没有“髋”保护部位词；上述髋方向反馈仍需保留。'));
    },
  );
}
