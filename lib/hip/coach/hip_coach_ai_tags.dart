import 'dart:convert';

import 'package:flutter/services.dart';

import '../data/hip_action_scope.dart';

const hipCoachAiTagsAsset = 'assets/coach/ai-tags/actions.json';
const hipCoachAiTagsSourceCommit = '5d17c24af859d905dbbdee4b1d623b99881ac618';

/// Unreviewed Pose-Hub drafts supplied to the SDK, not approval of an action.
/// The original per-action draft is passed unchanged to the SDK; HipLab's
/// existing authorization list remains the upper bound, including when callers
/// provide a narrower allowed set. Missing tags are not synthesized.
Future<Map<String, Map<String, Object?>>> loadHipCoachAiTags({
  AssetBundle? bundle,
  Set<String> allowedActionIds = hiplabCoachAuthorizedActionIds,
}) async {
  // Keep the byte path used by the other large bundled catalogs. loadString's
  // isolate decoding can race Flutter widget tests' fake clock.
  final data = await (bundle ?? rootBundle).load(hipCoachAiTagsAsset);
  final decoded = jsonDecode(
    utf8.decode(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    ),
  );
  if (decoded is! Map<String, dynamic> ||
      decoded['format'] != 'hiplab-coach-ai-tags@1' ||
      decoded['status'] != 'ai-draft' ||
      decoded['reviewed'] != false ||
      decoded['source'] is! Map ||
      (decoded['source'] as Map)['commit'] != hipCoachAiTagsSourceCommit ||
      decoded['actions'] is! Map<String, dynamic>) {
    throw const FormatException('Invalid HipLab AI tag draft source');
  }
  final actions = decoded['actions'] as Map<String, dynamic>;
  final tags = <String, Map<String, Object?>>{};
  for (final entry in actions.entries) {
    if (!hiplabCoachAuthorizedActionIds.contains(entry.key) ||
        !allowedActionIds.contains(entry.key)) {
      continue;
    }
    final value = entry.value;
    if (value is! Map<String, dynamic> ||
        value['id'] != entry.key ||
        value['format'] != 'pose-hub-ai-tags@1' ||
        value['status'] != 'ai-draft') {
      throw FormatException('Invalid AI tag draft for ${entry.key}');
    }
    tags[entry.key] = Map<String, Object?>.unmodifiable(value);
  }
  return Map<String, Map<String, Object?>>.unmodifiable(tags);
}
