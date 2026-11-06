import 'package:flutter/widgets.dart';

import '../domain/hip_models.dart';

/// Display-only translations of authored HipLab content. IDs, doses, safety
/// decisions and user-authored names are never rewritten in stored data.
class HipContentText {
  const HipContentText(this.lang);
  final String lang;
  static const zh = HipContentText('zh');
  static const en = HipContentText('en');
  static HipContentText of(BuildContext context) =>
      Localizations.maybeLocaleOf(context)?.languageCode == 'en' ? en : zh;
  bool get isEn => lang == 'en';

  String routineName(HipRoutine routine) =>
      isEn ? routineNames[routine.id] ?? routine.name : routine.name;
  String routineAudience(HipRoutine routine) => text(routine.audience);
  String drillName(HipDrill drill) =>
      isEn ? drillNames[drill.id] ?? drill.name : drill.name;
  String text(String authored) =>
      isEn ? english[authored] ?? authored : authored;

  static const routineNames = <String, String>{
    'A': 'Office Reset',
    'B': 'Bedtime Unwind',
    'C': 'Morning Mobility',
    'D': 'After-Sitting Relief',
    'E': 'Pre-Workout Activation',
    'F': 'Breaking Hip Mobility',
    'M': 'Chair-Side Break',
  };

  static const drillNames = <String, String>{
    'h-9090-liftoff': '90/90 Rear-Leg Lift-Off',
    'h-adductor-rock': 'Quadruped Adductor Rock-Back',
    'h-band-hip-ir': 'Seated Band Hip Internal Rotation',
    'h-band-leg-out': 'Supine Assisted Leg Opening',
    'h-butterfly-active': 'Supine Butterfly Open and Close',
    'h-couch-stretch': 'Couch Stretch',
    'h-hip-gate': 'Supported Standing Hip Gates',
    'h-quad-cars': 'Quadruped Hip Circles',
    'h-reverse-clam': 'Side-Lying Reverse Clamshell',
    'h-sumo-pry': 'Sumo Squat Pry Hold',
    'h-wall-straddle': 'Supine Wall Straddle',
    'h-knee-hug': 'Supine Knee Hug',
    'h-supine-twist': 'Supine Bent-Knee Twist',
    'h-squat': 'Bodyweight Squat',
    'hip-flexors-A': 'Seated Straight-Leg Compression Lift',
    'glute-max-A': 'Single-Leg Glute Bridge',
    's-9090': '90/90 Hip Switch',
    's-butterfly': 'Butterfly Stretch',
    's-figure4': 'Supine Figure-Four Stretch',
    's-frog': 'Frog Stretch',
    's-kneel-hipflex': 'Half-Kneeling Hip-Flexor Stretch',
    's-lizard': 'Supported Lizard Lunge',
    's-pigeon': 'Supported Upright Pigeon Stretch',
    's-seated-fold': 'Seated Forward Fold',
    'o-seated-fig4': 'Seated Figure-Four Stretch',
    'o-seated-ham': 'Seated Hamstring Reach',
    'o-stand-lunge': 'Chair-Supported Standing Lunge',
    'o-stand-crossreach': 'Chair-Supported Cross-Body Reach',
    'w-clamshell': 'Side-Lying Clamshell',
    'w-feet-on-chair-bridge': 'Feet-on-Chair Glute Bridge',
    't-seated-straddle-lift-1leg': 'Seated Straddle Single-Leg Lift',
    'n-seated-ir-drop': 'Seated Supported Knee Drop',
    'n-windshield': 'Supine Windshield Wipers',
    'n-chair-wiper': 'Seated Chair Windshield Wiper',
    'n-prone-ir': 'Prone Hip Internal Rotation',
    'n-half-split': 'Half-Kneeling Half Split',
    'n-prone-hip-ext': 'Prone Bent-Knee Hip Extension',
    'n-slider-lateral': 'Lateral Slider Lunge',
    'n-wide-fold': 'Supported Wide-Leg Forward Fold',
    'n-straddle-fold': 'Seated Straddle Forward Fold',
    'n-seated-knee-lift': 'Seated Knee-Lift Hold',
    'n-pelvis-circle': 'Standing Pelvic Circles',
    'n-seated-squeeze': 'Seated Block Squeeze',
    'n-squat-shift': 'Low-Squat Side-to-Side Shift',
    'n-leg-circles': 'Supine Straight-Leg Circles',
    'n-thomas-test': 'Supine Single-Knee Hug (Hip-Flexor Check)',
  };

  /// Exact, reviewed copy only: callers must not pass free-form user text.
  static const english = <String, String>{
    '': '',
    '久坐上班族；工位上做，不躺不坐地':
        'For desk workers. Stay at your desk; no floor work needed.',
    '所有人；全程躺着，越做越慢；只有最后一个动作要挪到墙边（不想挪就换成仰卧蝴蝶停留）':
        'For everyone. Stay lying down and gradually slow your pace. Only the last move needs a wall; use a supine butterfly hold if you prefer to stay put.',
    '所有人；以主动控制为主，把髋"叫醒"':
        'For everyone. Wake up your hips with active control.',
    '上班族下班后；重点髋前侧 + 臀部 + 内旋':
        'After a day at your desk. Focus on the front of the hips, glutes and internal rotation.',
    '跑步 / 健身 / 跳舞之前；不做长时间静态拉伸':
        'Before running, working out or dancing. No long static holds.',
    '舞者；面向 L 撑 / 风车 / 托马斯腿部绕环':
        'For dancers working on L-sits, windmills and flare leg circles.',
    '提醒弹出后一键进入；站起来就能做':
        'A quick break from your reminder. Stand up and get moving.',
    '6 次': '6 reps',
    '8 次': '8 reps',
    '正反各 3 圈': '3 circles each direction',
    '正反各 4 圈': '4 circles each direction',
    '每侧 1 次 × 停 5 秒': '1 rep per side · hold 5s',
    '每侧 3 次 × 停 5 秒': '3 reps per side · hold 5s',
    '每侧 3 次': '3 reps per side',
    '每侧 4 次': '4 reps per side',
    '每侧 5 次': '5 reps per side',
    '每侧 6 次': '6 reps per side',
    '每侧 8 次': '8 reps per side',
    '每侧 10 次': '10 reps per side',
    '每侧 15 秒': '15s per side',
    '每侧 20 秒': '20s per side',
    '每侧 25 秒': '25s per side',
    '每侧 30 秒': '30s per side',
    '每侧 35 秒': '35s per side',
    '每侧 40 秒': '40s per side',
    '每侧 40 秒（用毛巾）': '40s per side · use a towel',
    '每侧 3 圈': '3 circles per side',
    '每侧 正反各 4 圈': '4 circles each direction per side',
    '每侧 开 3 + 关 3': '3 opens + 3 closes per side',
    '每侧 开 3 次 + 关 3 次': '3 opens + 3 closes per side',
    '停 3 次 × 10 秒': '3 holds × 10s',
    '停 3 次 × 15 秒': '3 holds × 15s',
    '停 40 秒': 'Hold 40s',
    '停 60 秒': 'Hold 60s',
    '停 75 秒': 'Hold 75s',
    '停 60 秒（床头靠墙也可以）': 'Hold 60s · a wall by your bed works too',
    '慢呼吸 6 次': '6 slow breaths',
    '慢开慢合 6 次': '6 slow opens and closes',
    '不想挪位置：换成仰卧蝴蝶停留': 'Prefer to stay put? Use a supine butterfly hold.',
    '没有毛巾：手扶大腿内侧': 'No towel? Support the inner thigh with your hand.',
    '膝不舒服：只把脚踝搭上、不前压':
        'If your knee feels uncomfortable, rest the ankle on top without leaning forward.',
    '膝': 'Knee',
    '腰': 'Lower back',
    '内收肌根': 'Groin / upper adductors',
    '髋前侧夹痛': 'Pinching at the front of the hip',
    '屈': 'Flexion',
    '伸': 'Extension',
    '外展': 'Abduction',
    '内收': 'Adduction',
    '内旋': 'Internal rotation',
    '外旋': 'External rotation',
    '放松': 'Relax',
    '柔韧': 'Mobility',
    '主动控制': 'Control',
    '力量': 'Strength',
  };
}
