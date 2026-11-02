import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:ugk_coach/ugk_coach.dart' as coach;
import 'package:ugk_coach_chat/ugk_coach_chat.dart';

import '../domain/hip_models.dart';
import '../ui/coach/hip_coach_visuals.dart';

/// SDK 0a6c3aa, docs/coach-chat-module-design/app-profile-isolation.md:
/// HipLab's 45 explicit candidates. This is the single editable authorization
/// list; neither a new catalog nor a broad selector can expand it.
const hiplabCoachAuthorizedActionIds = <String>{
  'glute-max-A',
  'h-9090-liftoff',
  'h-adductor-rock',
  'h-band-hip-ir',
  'h-band-leg-out',
  'h-butterfly-active',
  'h-couch-stretch',
  'h-hip-gate',
  'h-knee-hug',
  'h-quad-cars',
  'h-reverse-clam',
  'h-squat',
  'h-sumo-pry',
  'h-supine-twist',
  'h-wall-straddle',
  'hip-flexors-A',
  'n-chair-wiper',
  'n-half-split',
  'n-leg-circles',
  'n-pelvis-circle',
  'n-prone-hip-ext',
  'n-prone-ir',
  'n-seated-ir-drop',
  'n-seated-knee-lift',
  'n-seated-squeeze',
  'n-slider-lateral',
  'n-squat-shift',
  'n-straddle-fold',
  'n-wide-fold',
  'n-windshield',
  'o-seated-fig4',
  'o-seated-ham',
  'o-stand-crossreach',
  'o-stand-lunge',
  's-9090',
  's-butterfly',
  's-figure4',
  's-frog',
  's-kneel-hipflex',
  's-lizard',
  's-pigeon',
  's-seated-fold',
  't-seated-straddle-lift-1leg',
  'w-clamshell',
  'w-feet-on-chair-bridge',
};

/// Product configuration only. Conversation, action admission, fitting and
/// safety remain in the SDK. No local intent parsing or fallback is installed.
const hiplabCoachProfile = coach.CoachProfile(
  id: 'hiplab',
  appName: '开胯训练助手（HipLab）',
  promptVersion: 'chat-sdk-1',
  focus:
      '以髋部灵活性、拉伸和控制为重点：髋关节屈伸、外展内收、内外旋活动度，'
      '以及臀部、内收肌和髋屈肌控制。只使用 HipLab 白名单动作；'
      '不安排上肢、胸背或腹肌专项训练。',
  rules: [
    '语气温和、耐心，提醒在不痛的范围内慢慢呼吸。',
    '范围外请求由 SDK 范围规则说明或提供相关的髋部建议，'
        '不能把名单外动作加入计划，也不作医疗诊断或康复处方。',
  ],
  select: coach.DrillSelector(ids: hiplabCoachAuthorizedActionIds),
  ambientEquipment: {
    'home': {'equip.mat', 'equip.wall', 'equip.chair'},
    'office': {'equip.chair', 'equip.wall'},
    'gym': {'equip.mat', 'equip.wall', 'equip.chair'},
  },
  ambientEquipmentUnknown: {'equip.wall', 'equip.mat'},
);

const hipCoachCatalogAsset = 'assets/coach/catalog.json';

Future<coach.Catalog> loadHipCoachCatalog({AssetBundle? bundle}) async =>
    coach.Catalog.fromJson(
      jsonDecode(await (bundle ?? rootBundle).loadString(hipCoachCatalogAsset)),
    );

CoachAppProfile hiplabCoachAppProfile({
  required coach.Catalog catalog,
  required coach.CoachProfile coachProfile,
  required coach.PlanExecutionTimingCallback executionTiming,
  required HipContent content,
}) => CoachAppProfile(
  appId: 'hiplab',
  revision: 'chat-sdk-1',
  scopeManifest: coach.CoachActionScopeManifest.fromCatalogBytes(
    appId: 'hiplab',
    catalogBytes: utf8.encode(jsonEncode(catalog.toJson())),
    allowedActionIds: hiplabCoachAuthorizedActionIds,
  ),
  coachProfile: coachProfile,
  conversationPolicy: coach.CoachScopeConversationPolicy(
    specialty: 'HipLab 专注开胯、髋部拉伸与活动度，以及臀部和髋部控制。',
    suggestions: const ['在家拉伸髋部 10 分钟', '推荐几个拉大腿内侧的动作', '来一套 5 分钟髋部放松'],
  ),
  executionTiming: executionTiming,
  strings: const CoachChatStrings(
    invitation: '今天想怎样放松髋部？',
    returningInvitation: '欢迎回来，今天想怎样放松髋部？',
    inputHint: '说说想拉伸哪里、在哪儿、有多久…',
    libraryLabel: '练习库',
    defaultSuggestions: [
      '在家拉伸髋部 10 分钟',
      '推荐几个拉大腿内侧的动作',
      '久坐后放松髋部 5 分钟',
      '睡前轻柔开胯',
    ],
    safetyIntro:
        '你好，我是 HipLab 训练助手。\n告诉我想拉伸哪里、在哪儿、有多少时间，'
        '我帮你安排能直接跟练的髋部训练。',
  ),
  visual: hipCoachChatVisuals(content),
);
