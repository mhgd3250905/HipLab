import 'dart:convert';
import 'package:ugk_coach/ugk_coach.dart' as coach;

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

coach.CoachActionScopeManifest hipActionScope(coach.Catalog catalog) =>
    coach.CoachActionScopeManifest.fromCatalogBytes(
      appId: 'hiplab',
      catalogBytes: utf8.encode(jsonEncode(catalog.toJson())),
      allowedActionIds: hiplabCoachAuthorizedActionIds,
    );
