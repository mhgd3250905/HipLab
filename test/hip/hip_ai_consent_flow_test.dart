import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiplab/hip/coach/hip_coach_chat.dart';
import 'package:hiplab/hip/coach/hip_coach_chat_storage.dart';
import 'package:hiplab/hip/control/hip_ai_consent.dart';
import 'package:hiplab/hip/control/hip_membership.dart';
import 'package:hiplab/hip/control/hip_store.dart';
import 'package:hiplab/hip/domain/hip_models.dart';
import 'package:hiplab/hip/ui/coach/hip_coach_chat_page.dart';
import 'package:hiplab/hip/ui/hip_app.dart';
import 'package:hiplab/hip/ui/hip_membership_page.dart';
import 'package:hiplab/hip/ui/hip_privacy_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ugk_coach/ugk_coach.dart' as coach;
import 'package:ugk_coach_chat/ugk_coach_chat.dart';

import 'hip_ai_coach_test.dart' show FileAssetBundle;
import 'hip_domain_test.dart' show MemoryStorage, loadContent;
import 'home_nav.dart';
import 'public_media_fixture.dart';

class _MembershipStore implements MembershipStore {
  const _MembershipStore(this.snapshot);
  final MembershipSnapshot snapshot;

  @override
  Future<List<MembershipOffer>> offers() async => const [];
  @override
  Future<MembershipSnapshot> refresh() async => snapshot;
  @override
  Future<MembershipSnapshot> restore() async => snapshot;
  @override
  Future<MembershipSnapshot?> purchase(MembershipTerm term) async => null;
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  final consentTitle = find.text('使用 AI 前请确认');
  final decline = find.text('暂不使用');
  final approve = find.text('同意并继续');
  final privacyLink = find.text('查看隐私政策');
  final paywall = find.byType(HipMembershipPage);
  final chatPage = find.byType(HipCoachChatPage);
  final chatInput = find.byKey(const ValueKey('chat-input'));
  final groupEntry = find.byKey(const ValueKey('practice-ai-coach'));

  Future<({HipAiConsent consent, coach.FakeLlmClient client})> mount(
    WidgetTester tester, {
    bool premium = true,
  }) async {
    SharedPreferences.setMockInitialValues({});
    tester.view
      ..physicalSize = const Size(390, 844)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final now = DateTime.utc(2026, 11, 12);
    final membership = HipMembership(
      _MembershipStore(
        MembershipSnapshot(
          'test-user',
          premium ? now.add(const Duration(days: 1)) : null,
        ),
      ),
      now: () => now,
    );
    final disk = MemoryStorage();
    disk.values[HiplabCoachChatPreferenceStore.storageKey] =
        '{"safetyAccepted":true,"safetyBlocked":false,"safetyChecking":false}';
    final store = HipStore(content: loadContent(), storage: disk);
    await store.initialize();
    store
      ..safety = {'pregnancy': false, 'surgery': false, 'acute': false}
      ..identity = HipIdentity.office;
    addTearDown(store.dispose);
    final consent = HipAiConsent();
    final client = coach.FakeLlmClient([
      coach.LlmResponse(
        content: '',
        toolCalls: [
          coach.LlmToolCall(
            id: 'fake-safety-answer',
            name: 'reply',
            arguments: '{"text":"在不痛的范围内练习。","chips":[]}',
          ),
        ],
      ),
    ], latency: Duration.zero);
    final host = HipCoachChat(
      store: store,
      membership: membership,
      consent: consent,
      storage: disk,
      bundle: FileAssetBundle(),
      gateway: CoachGatewayBinding.shared(client),
      replyDelay: Duration.zero,
    );
    await tester.pumpWidget(
      HipApp(
        mediaPolicy: installPublicMediaFixture().policy,
        store: store,
        videoEnabled: false,
        membership: membership,
        coach: host,
      ),
    );
    await tester.pumpAndSettle();
    return (consent: consent, client: client);
  }

  testWidgets('both member AI entries share explicit first-use consent', (
    tester,
  ) async {
    final app = await mount(tester);
    await openMore(tester);
    await _tap(tester, find.byKey(const ValueKey('more-membership')));
    expect(paywall, findsOneWidget);

    await _tap(
      tester,
      find.descendant(of: paywall, matching: find.text('去提问')),
    );
    expect(consentTitle, findsOneWidget);
    expect(chatPage, findsNothing);
    expect(app.client.requests, isEmpty);
    await tester.tapAt(const Offset(16, 16));
    await tester.binding.handlePopRoute();
    await tester.drag(consentTitle, const Offset(0, 250));
    await tester.pumpAndSettle();
    expect(consentTitle, findsOneWidget);

    await _tap(tester, decline);
    expect(consentTitle, findsNothing);
    expect(paywall, findsOneWidget);
    expect(await app.consent.read(), isFalse);
    expect(app.client.requests, isEmpty);

    await _tap(
      tester,
      find.descendant(of: paywall, matching: find.text('去定制')),
    );
    expect(consentTitle, findsOneWidget);
    await _tap(tester, privacyLink);
    expect(find.byType(HipPrivacyPage), findsOneWidget);
    await _tap(tester, find.byKey(const ValueKey('privacy-back')));
    expect(consentTitle, findsOneWidget);
    expect(app.client.requests, isEmpty);

    await _tap(tester, approve);
    expect(consentTitle, findsNothing);
    expect(chatPage, findsOneWidget);
    expect(await HipAiConsent().read(), isTrue);
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getBool(HipAiConsent.key), isTrue);
    expect(
      DateTime.tryParse(preferences.getString(HipAiConsent.timestampKey) ?? ''),
      isNotNull,
    );
    expect(app.client.requests, isEmpty);
    await tester.enterText(chatInput, '拉伸前应注意什么？');
    await _tap(tester, find.byKey(const ValueKey('chat-send')));
    expect(app.client.requests, isNotEmpty);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('withdrawal clears stored consent and reopens the prompt', (
    tester,
  ) async {
    final app = await mount(tester);
    await openGroups(tester);
    await _tap(tester, groupEntry);
    await _tap(tester, approve);
    expect(chatPage, findsOneWidget);
    expect(await HipAiConsent().read(), isTrue);
    final navigator = tester.state<NavigatorState>(
      find.byType(Navigator).first,
    );
    navigator.push<void>(
      MaterialPageRoute<void>(
        builder: (_) => const HipPrivacyPage(aiDisclosure: true),
      ),
    );
    await tester.pumpAndSettle();
    final withdraw = find.text('撤回 AI 数据共享同意');
    final scrollable = find
        .descendant(
          of: find.byType(HipPrivacyPage),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(
      withdraw.hitTestable(),
      300,
      scrollable: scrollable,
    );
    await _tap(tester, withdraw);
    expect(find.text('已撤回，下次使用 AI 时会再次询问'), findsOneWidget);
    expect(await HipAiConsent().read(), isFalse);
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.containsKey(HipAiConsent.key), isFalse);
    expect(preferences.containsKey(HipAiConsent.timestampKey), isFalse);
    await _tap(tester, find.byKey(const ValueKey('privacy-back')));
    expect(chatPage, findsOneWidget);
    expect(chatInput, findsNothing);
    await _tap(tester, find.text('使用 AI'));
    expect(consentTitle, findsOneWidget);
    expect(app.client.requests, isEmpty);
    await _tap(tester, decline);
    expect(groupEntry, findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a nonmember sees the paywall before any AI disclosure', (
    tester,
  ) async {
    final app = await mount(tester, premium: false);
    await openGroups(tester);
    await _tap(tester, groupEntry);
    expect(paywall, findsOneWidget);
    expect(consentTitle, findsNothing);
    expect(chatPage, findsNothing);
    expect(await app.consent.read(), isFalse);
    expect(app.client.requests, isEmpty);
    await _tap(tester, find.byKey(const ValueKey('membership-close')));
    expect(groupEntry, findsOneWidget);
    expect(consentTitle, findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
}
