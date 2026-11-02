import 'package:flutter/services.dart';
import 'package:ugk_coach/ugk_coach.dart' as coach;
import 'package:ugk_coach_chat/ugk_coach_chat.dart';

import '../domain/hip_models.dart';
import '../data/hip_public_media.dart';
import '../data/hip_public_catalog.dart';
import '../data/hip_action_scope.dart';
import '../data/hip_shared_library.dart';
export '../data/hip_action_scope.dart' show hiplabCoachAuthorizedActionIds;
import '../ui/coach/hip_coach_visuals.dart';

/// Product configuration only. Conversation, action admission, fitting and
/// safety remain in the SDK. No local intent parsing or fallback is installed.
const hiplabCoachProfile = coach.CoachProfile(
  id: 'hiplab',
  appName: '开胯训练助手（HipLab）',
  promptVersion: 'chat-sdk-full-1',
  focus:
      '提供全身力量、核心、低冲击有氧、灵活性和拉伸训练，按用户目标组合。'
      '只使用 HipLab 已授权且训练说明完整的公共动作；'
      '徒手可使用当前场景的环境物，额外器械须由用户或 App 明确提供。'
      '办公室仅站姿和坐姿，不安排趴、躺或跪姿动作。'
      '全身训练注意推拉、上下肢和前后侧平衡。',
  rules: [
    '语气温和、耐心，提醒在不痛的范围内慢慢呼吸。',
    '范围外请求由 SDK 范围规则说明或提供库内相关动作建议，'
        '不能把名单外或训练说明待补的动作加入计划，也不作医疗诊断或康复处方。',
  ],
  select: coach.DrillSelector(ids: hiplabCoachAuthorizedActionIds),
  ambientEquipment: {
    'home': {'equip.mat', 'equip.wall', 'equip.chair'},
    'office': {'equip.chair', 'equip.wall'},
    'gym': {'equip.mat', 'equip.wall', 'equip.chair'},
  },
  ambientEquipmentUnknown: {'equip.wall', 'equip.mat'},
);

const hipCoachCatalogAsset = hipPublicCatalogAsset;

Future<coach.Catalog> loadHipCoachCatalog({AssetBundle? bundle}) async =>
    hipCoachCatalogFromPublic(await loadHipPublicCatalog(bundle: bundle));

CoachAppProfile hiplabCoachAppProfile({
  required coach.Catalog catalog,
  required coach.CoachProfile coachProfile,
  required coach.PlanExecutionTimingCallback executionTiming,
  required HipContent content,
}) => CoachAppProfile(
  appId: 'hiplab',
  mediaPolicy: HipPublicMedia.current,
  library: hipSharedLibraryConfig(
    hipActionScope(content.publicCatalog ?? catalog),
  ),
  revision: 'chat-sdk-full-1',
  scopeManifest: hipActionScope(content.publicCatalog ?? catalog),
  coachProfile: coachProfile,
  conversationPolicy: coach.CoachScopeConversationPolicy(
    specialty: 'HipLab 提供全身力量、核心、有氧、灵活性和拉伸训练，保留开胯与髋部训练特色。',
    suggestions: const ['在家拉伸髋部 10 分钟', '推荐几个拉大腿内侧的动作', '来一套 5 分钟全身训练'],
  ),
  executionTiming: executionTiming,
  strings: const CoachChatStrings(
    invitation: '今天想练哪里？',
    returningInvitation: '欢迎回来，今天想练哪里？',
    inputHint: '说说想练哪里、在哪儿、有多久…',
    libraryLabel: '练习库',
    defaultSuggestions: [
      '在家拉伸髋部 10 分钟',
      '推荐几个拉大腿内侧的动作',
      '久坐后放松髋部 5 分钟',
      '在家练一下胸肌',
    ],
    safetyIntro:
        '你好，我是 HipLab 训练助手。\n告诉我想练哪里、在哪儿、有多少时间，'
        '我帮你安排能直接跟练的训练。',
  ),
  visual: hipCoachChatVisuals(
    content,
    catalog: content.publicCatalog ?? catalog,
  ),
);
