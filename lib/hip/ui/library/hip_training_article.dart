// Interaction design reviewed against SmartFit's phone-feedback follow-up.
// HipLab owns these article rows and its existing dose/safety/navigation rules.
import 'package:flutter/material.dart';

import '../../domain/hip_models.dart';
import '../hip_icons.dart';
import '../hip_theme.dart';
import '../hip_widgets.dart';
import 'hip_manual_preview.dart';
import 'lib_text.dart';
import 'library_widgets.dart';

class HipArticleStep {
  const HipArticleStep({
    required this.drill,
    required this.dose,
    this.section = '',
    this.note = '',
    this.detailKey,
  });

  final HipDrill drill;
  final String dose;
  final String section;
  final String note;
  final Key? detailKey;
}

/// A scrollable article, with one explicit preview and a floating start action.
/// No training plan, clock, voice or safety decisions are made by this widget.
class HipTrainingArticle extends StatefulWidget {
  const HipTrainingArticle({
    super.key,
    required this.content,
    required this.title,
    required this.introduction,
    required this.seconds,
    required this.restSeconds,
    required this.steps,
    required this.onStart,
    this.startKey,
    this.startLabel,
    this.listKey = const ValueKey('training-article'),
    this.notices = const [],
    this.secondaryLabel,
    this.secondaryKey,
    this.onSecondary,
    this.onOpenDrill,
  });

  final HipContent content;
  final String title;
  final String introduction;
  final int seconds;
  final int restSeconds;
  final List<HipArticleStep> steps;
  final Future<void> Function(BuildContext? from)? onStart;
  final Future<void> Function(HipDrill drill)? onOpenDrill;
  final Key? startKey;
  final String? startLabel;
  final Key listKey;
  final List<Widget> notices;
  final String? secondaryLabel;
  final Key? secondaryKey;
  final Future<void> Function()? onSecondary;

  @override
  State<HipTrainingArticle> createState() => _HipTrainingArticleState();
}

class _HipTrainingArticleState extends State<HipTrainingArticle> {
  final _preview = HipPreviewCoordinator();
  final _start = GlobalKey();
  bool _opening = false;

  @override
  void dispose() {
    _preview.dispose();
    super.dispose();
  }

  Future<void> _handoff(Future<void> Function() next) async {
    if (_opening) return;
    setState(() => _opening = true);
    _preview.suspend();
    // Unmount every demonstration surface before a player/detail route mounts.
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    try {
      await next();
    } finally {
      if (mounted) {
        _preview.resume();
        setState(() => _opening = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = LibText.of(context);
    final bottom = MediaQuery.viewPaddingOf(context).bottom;
    return Stack(
      children: [
        ListView(
          key: widget.listKey,
          padding: EdgeInsets.fromLTRB(20, 8, 20, 112 + bottom),
          children: [
            Text(
              widget.title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 16,
              runSpacing: 6,
              children: [
                Text('${(widget.seconds / 60).ceil()} ${t.statMinutes}'),
                Text('${widget.steps.length} ${t.statMoves}'),
                Text('${widget.restSeconds} ${t.statRest}'),
              ],
            ),
            if (widget.introduction.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                widget.introduction,
                style: TextStyle(height: 1.6, color: HipColors.muted),
              ),
            ],
            for (final notice in widget.notices) ...[
              const SizedBox(height: 12),
              notice,
            ],
            if (widget.secondaryLabel case final label?) ...[
              const SizedBox(height: 12),
              HipSecondaryButton(
                key: widget.secondaryKey,
                label: label,
                onPressed: _opening || widget.onSecondary == null
                    ? null
                    : () => _handoff(widget.onSecondary!),
              ),
            ],
            for (final (i, step) in widget.steps.indexed) ...[
              if (step.section.isNotEmpty &&
                  (i == 0 || step.section != widget.steps[i - 1].section)) ...[
                const SizedBox(height: 30),
                Text(
                  step.section,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
              const SizedBox(height: 18),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  key: step.detailKey,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    foregroundColor: HipColors.text,
                    alignment: Alignment.centerLeft,
                  ),
                  onPressed: _opening || widget.onOpenDrill == null
                      ? null
                      : () => _handoff(() => widget.onOpenDrill!(step.drill)),
                  child: Text(
                    '${i + 1}. ${drillName(widget.content, step.drill, t.lang)}',
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              HipManualPreview(
                drill: step.drill,
                coordinator: _preview,
                slot: '$i',
              ),
              const SizedBox(height: 12),
              Text(
                step.dose,
                style: TextStyle(
                  color: HipColors.jadeText,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (drillPoint(
                widget.content,
                step.drill,
                t.lang,
              ).isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  drillPoint(widget.content, step.drill, t.lang),
                  style: const TextStyle(fontSize: 16, height: 1.6),
                ),
              ],
              if (step.note.isNotEmpty &&
                  step.note !=
                      drillPoint(widget.content, step.drill, t.lang)) ...[
                const SizedBox(height: 8),
                Text(
                  step.note,
                  style: TextStyle(height: 1.6, color: HipColors.muted),
                ),
              ],
              if (step.drill.cautions.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  '${t.cautions}：${step.drill.cautions.join('、')}',
                  style: TextStyle(height: 1.5, color: HipColors.tight),
                ),
              ],
            ],
          ],
        ),
        Positioned(
          right: 20,
          width: 180,
          bottom: 16 + bottom,
          child: KeyedSubtree(
            key: _start,
            child: HipPrimaryButton(
              key: widget.startKey,
              label: widget.startLabel ?? (t.isEn ? 'Go to training' : '前往训练'),
              icon: widget.onStart == null ? null : HipGlyph.play,
              onPressed: _opening || widget.onStart == null
                  ? null
                  : () =>
                        _handoff(() => widget.onStart!(_start.currentContext)),
            ),
          ),
        ),
      ],
    );
  }
}
