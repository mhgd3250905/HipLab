import 'package:flutter/material.dart';
import 'package:hiplab/hip/ui/hip_icons.dart';
import 'package:hiplab/hip/ui/hip_page_kit.dart';
import 'package:hiplab/hip/ui/hip_segmented.dart';
import 'package:hiplab/hip/ui/hip_text.dart';
import 'package:hiplab/hip/ui/hip_theme.dart';
import 'package:hiplab/hip/ui/hip_widgets.dart';

enum _PreviewMode { standard, quiet }

/// A UI recipe only: state is local and no storage, audio or deletion runs.
class ControlsRecipePage extends StatefulWidget {
  const ControlsRecipePage({super.key});

  @override
  State<ControlsRecipePage> createState() => _ControlsRecipePageState();
}

class _ControlsRecipePageState extends State<ControlsRecipePage> {
  bool _enabled = true;
  double _volume = .6;
  _PreviewMode _mode = _PreviewMode.standard;
  bool? _confirmed;

  Future<void> _confirm() async {
    final text = HipText.of(context);
    final result = await showHipConfirmDialog(
      context,
      title: text.pick('确认这次选择？', 'Confirm this choice?'),
      message: text.pick(
        '这个样例只记录本页确认结果，不执行外部操作。',
        'This example only records the result on this page.',
      ),
      cancelLabel: text.pick('取消', 'Cancel'),
      confirmLabel: text.pick('确认', 'Confirm'),
    );
    if (mounted) setState(() => _confirmed = result);
  }

  @override
  Widget build(BuildContext context) {
    final text = HipText.of(context);
    final modeControl = HipSegmented<_PreviewMode>(
      keyPrefix: 'recipe-mode',
      height: 32,
      radius: 9,
      inset: 2,
      ios: true,
      values: _PreviewMode.values,
      selected: _mode,
      label: (mode) => switch (mode) {
        _PreviewMode.standard => text.pick('标准', 'Standard'),
        _PreviewMode.quiet => text.pick('安静', 'Quiet'),
      },
      onChanged: (mode) => setState(() => _mode = mode),
    );

    return HipNavPage(
      title: text.pick('控件样例', 'Controls recipe'),
      bodyScrollsUnderBar: true,
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          kHipPageEdge,
          hipNavInset(context) + 12,
          kHipPageEdge,
          24,
        ),
        children: [
          HipListGroup(
            children: [
              HipListRow(
                glyph: HipGlyph.voice,
                title: text.pick('口令预览', 'Cue preview'),
                subtitle: text.pick(
                  '开关与条目共享一套平整表面',
                  'A switch shares the row surface.',
                ),
                trailing: HipSwitch(
                  key: const ValueKey('recipe-switch'),
                  semanticLabel: text.pick('口令预览', 'Cue preview'),
                  value: _enabled,
                  onChanged: (enabled) => setState(() => _enabled = enabled),
                ),
              ),
              if (text.isEn)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const HipListRow(
                      glyph: HipGlyph.contrast,
                      title: 'Preview mode',
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        kHipRowTextInset,
                        0,
                        16,
                        12,
                      ),
                      child: modeControl,
                    ),
                  ],
                )
              else
                HipListRow(
                  glyph: HipGlyph.contrast,
                  title: '预览模式',
                  trailing: SizedBox(width: 196, child: modeControl),
                ),
            ],
          ),
          const SizedBox(height: 28),
          HipListGroup(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  HipListRow(
                    glyph: HipGlyph.volume,
                    title: text.pick('音量', 'Volume'),
                    meta: '${(_volume * 100).round()}%',
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: HipSlider(
                      key: const ValueKey('recipe-slider'),
                      semanticLabel: text.pick('预览音量', 'Preview volume'),
                      value: _volume,
                      onChanged: (volume) => setState(() => _volume = volume),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 28),
          HipPrimaryButton(
            key: const ValueKey('recipe-confirm'),
            label: text.pick('打开确认框', 'Open confirmation'),
            onPressed: _confirm,
          ),
          const SizedBox(height: 12),
          Text(
            _confirmed == null
                ? text.pick('尚未确认', 'No confirmation yet')
                : _confirmed!
                ? text.pick('已确认', 'Confirmed')
                : text.pick('已取消', 'Cancelled'),
            key: const ValueKey('recipe-result'),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: HipColors.muted),
          ),
        ],
      ),
    );
  }
}
