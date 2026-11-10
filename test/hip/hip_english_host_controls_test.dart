import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiplab/hip/data/hip_public_text_en.dart';
import 'package:hiplab/hip/domain/hip_models.dart';
import 'package:hiplab/hip/ui/coach/hip_coach_chat_page.dart';
import 'package:hiplab/hip/ui/hip_page_kit.dart';
import 'package:hiplab/hip/ui/hip_theme.dart';
import 'package:hiplab/hip/ui/hip_widgets.dart';
import 'package:hiplab/hip/voice/hip_voice.dart';
import 'package:hiplab/hip/voice/voice_library.dart';
import 'package:hiplab/hip/voice/voice_queue.dart';

void main() {
  const english = Locale('en');
  Widget shell(Widget child, {Locale locale = english}) => MaterialApp(
    locale: locale,
    supportedLocales: const [Locale('zh'), english],
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: Scaffold(body: child),
  );

  test(
    'existing translated actions retain all authored English display lines',
    () {
      final source =
          jsonDecode(
                File(
                  'assets/public_media/catalog/catalog.json',
                ).readAsStringSync(),
              )
              as Map;
      final actions = <String, Map>{
        for (final action in source['drills'] as List)
          if (hipPublicTextEn.containsKey((action as Map)['id']))
            action['id'] as String: action,
      };
      expect(actions.keys.toSet(), hipPublicTextEn.keys.toSet());
      expect(actions, hasLength(209));
      var cues = 0, cautions = 0, contraindications = 0;
      for (final entry in actions.entries) {
        final translated = hipPublicTextEn[entry.key]!;
        expect(
          translated.cues.length,
          ((entry.value['cues'] as Map)['zh'] as List).length,
          reason: entry.key,
        );
        expect(
          translated.cautions.length,
          (entry.value['cautions'] as List).length,
          reason: entry.key,
        );
        expect(
          translated.contraindications.length,
          (entry.value['contraindications'] as List).length,
          reason: entry.key,
        );
        for (final text in [
          translated.purpose,
          ...translated.cues,
          ...translated.cautions,
          ...translated.contraindications,
        ]) {
          expect(text.trim(), isNotEmpty, reason: entry.key);
          expect(
            RegExp(r'[\u4e00-\u9fff]').hasMatch(text),
            isFalse,
            reason: '${entry.key}: $text',
          );
        }
        cues += translated.cues.length;
        cautions += translated.cautions.length;
        contraindications += translated.contraindications.length;
      }
      expect(cues, 689);
      expect(cautions, 289);
      expect(contraindications, 200);
      expect(
        hipPublicTextEn['h-band-hip-extension']!.cautions.last,
        'Do not attach the band to the chair.',
      );
      expect(
        hipPublicTextEn['abs-A']!.cues.last,
        contains('Do not hold your breath'),
      );
      expect(
        hipPublicTextEn['adductors-B']!.cautions.single,
        contains('Stop immediately'),
      );
    },
  );

  test(
    'voice follow-App resolves explicitly without changing old defaults or overrides',
    () {
      expect(VoiceLanguage.app.clipLanguage, 'zh');
      expect(VoiceLanguage.app.resolveClipLanguage('en-US'), 'en');
      expect(VoiceLanguage.app.resolveClipLanguage('zh-Hant'), 'zh');
      expect(VoiceLanguage.zh.resolveClipLanguage('en'), 'zh');
      expect(VoiceLanguage.en.resolveClipLanguage('zh'), 'en');
      expect(const VoiceSettings().toTrainer().language, 'zh');
      expect(
        const VoiceSettings().toTrainer(appLanguageTag: 'en').language,
        'en',
      );
    },
  );

  testWidgets(
    'locale-bound voice keeps resources and reads later preference changes',
    (tester) async {
      var preferences = const VoiceSettings();
      final voice = HipVoice(
        lib: VoiceLibrary.empty,
        output: const MutedVoiceOutput(),
        settingsOf: () => preferences,
      );
      late HipVoice bound;
      await tester.pumpWidget(
        shell(
          HipVoiceScope(
            voice: voice,
            child: Builder(
              builder: (context) {
                bound = HipVoice.of(context);
                return const SizedBox();
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(bound.lib, same(voice.lib));
      expect(bound.output, same(voice.output));
      expect(bound.lang, 'en');
      final queue = bound.queue();
      expect(queue.settings.language, 'en');
      preferences = preferences.copyWith(language: VoiceLanguage.zh);
      expect(bound.lang, 'zh');
      expect(bound.queue().settings.language, 'zh');
    },
  );

  testWidgets(
    'English navigation and default action labels expose English semantics',
    (tester) async {
      await tester.pumpWidget(
        shell(
          Column(
            children: [
              HipNavBackChip(onLeading: () {}),
              HipNavBackChip(leading: HipNavLeading.close, onLeading: () {}),
              HipStartButton(onTap: () {}, stage: HipPalette.dark),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byTooltip('Back'), findsOneWidget);
      expect(find.byTooltip('Close'), findsOneWidget);
      expect(find.text('Start'), findsOneWidget);
      expect(find.text('开始'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('English radar labels and configured coach remain available', (
    tester,
  ) async {
    late bool available;
    await tester.pumpWidget(
      shell(
        Builder(
          builder: (context) {
            available = aiCoachAvailable(context, configured: true);
            return SizedBox(
              width: 330,
              height: 330,
              child: HipRadar(
                values: {
                  for (final direction in HipDirection.values) direction: .5,
                },
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(available, isTrue);
    expect(find.text('Flexion'), findsOneWidget);
    expect(find.text('Ext. rot.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
