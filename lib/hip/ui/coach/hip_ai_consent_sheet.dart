import 'package:flutter/material.dart';

import '../../control/hip_ai_consent.dart';
import '../hip_privacy_page.dart';
import '../hip_routes.dart';
import '../hip_text.dart';
import '../hip_theme.dart';

Future<bool> showHipAiConsentSheet(
  BuildContext context,
  HipAiConsent consent,
) async {
  return await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        isDismissible: false,
        enableDrag: false,
        showDragHandle: false,
        useSafeArea: true,
        backgroundColor: HipPalette.dark.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        sheetAnimationStyle: const AnimationStyle(
          duration: Duration(milliseconds: 250),
          reverseDuration: Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeOutCubic,
        ),
        builder: (_) => _HipAiConsentSheet(consent: consent),
      ) ??
      false;
}

class _HipAiConsentSheet extends StatefulWidget {
  const _HipAiConsentSheet({required this.consent});

  final HipAiConsent consent;

  @override
  State<_HipAiConsentSheet> createState() => _HipAiConsentSheetState();
}

class _HipAiConsentSheetState extends State<_HipAiConsentSheet> {
  static const _green = Color(0xff3fd9ae);
  static const _bodyStyle = TextStyle(
    color: Color(0xccffffff),
    fontSize: 15,
    height: 1.5,
  );

  bool _saving = false;
  bool _saveFailed = false;

  Future<void> _agree() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _saveFailed = false;
    });
    try {
      await widget.consent.grant();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _saveFailed = true;
      });
      return;
    }
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final text = HipText.of(context);
    final disclosure = hipAiDisclosure(text);
    return PopScope<bool>(
      canPop: false,
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                header: true,
                child: Text(
                  text.pick('使用 AI 前请确认', 'Before using AI'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(disclosure.intro, style: _bodyStyle),
              const SizedBox(height: 6),
              _bullet(disclosure.conversation),
              const SizedBox(height: 6),
              _bullet(disclosure.details),
              const SizedBox(height: 6),
              Text(disclosure.local, style: _bodyStyle),
              const SizedBox(height: 12),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton(
                  onPressed: _saving
                      ? null
                      : () => Navigator.of(context).push<void>(
                          HipRoute.content<void>(
                            (_) => const HipPrivacyPage(aiDisclosure: true),
                            pinLeading: false,
                          ),
                        ),
                  style: TextButton.styleFrom(
                    foregroundColor: _green,
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    text.pick('查看隐私政策', 'View Privacy Policy'),
                    style: const TextStyle(
                      fontSize: 14,
                      decoration: TextDecoration.underline,
                      decorationColor: _green,
                    ),
                  ),
                ),
              ),
              if (_saveFailed) ...[
                const SizedBox(height: 12),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    text.pick(
                      '未能保存同意，请重试。',
                      'Could not save consent. Try again.',
                    ),
                    style: _bodyStyle,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _saving ? null : _agree,
                style: FilledButton.styleFrom(
                  backgroundColor: _green,
                  foregroundColor: HipPalette.dark.onJade,
                  disabledBackgroundColor: HipPalette.dark.surfaceHigh,
                  disabledForegroundColor: HipPalette.dark.text,
                  minimumSize: const Size(0, 52),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(14)),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: Text(text.pick('同意并继续', 'Agree and continue')),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _saving
                    ? null
                    : () => Navigator.of(context).pop(false),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xb3ffffff),
                  minimumSize: const Size(0, 48),
                  textStyle: const TextStyle(fontSize: 15),
                ),
                child: Text(text.pick('暂不使用', 'Not now')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bullet(String text) => Padding(
    padding: const EdgeInsetsDirectional.only(start: 16),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('•', style: _bodyStyle),
        const SizedBox(width: 6),
        Expanded(child: Text(text, style: _bodyStyle)),
      ],
    ),
  );
}
