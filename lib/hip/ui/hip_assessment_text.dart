import 'package:flutter/widgets.dart';

import '../domain/hip_models.dart';
import 'hip_text.dart';

/// Display-only translations for the frozen check-up content. Scores, option
/// IDs, timing, media and safety decisions continue to use the original model.
class HipAssessmentText {
  const HipAssessmentText(this.isEn);
  final bool isEn;
  static const zh = HipAssessmentText(false);
  static const en = HipAssessmentText(true);
  static HipAssessmentText of(BuildContext context) =>
      HipText.of(context).isEn ? en : zh;

  String text(String original) =>
      isEn ? english[original] ?? original : original;

  String direction(HipDirection direction) => isEn
      ? switch (direction) {
          HipDirection.flexion => 'Flexion',
          HipDirection.extension => 'Extension',
          HipDirection.abduction => 'Abduction',
          HipDirection.adduction => 'Adduction',
          HipDirection.internalRotation => 'Internal rotation',
          HipDirection.externalRotation => 'External rotation',
        }
      : direction.zh;

  String area(HipDirection direction) => text(switch (direction) {
    HipDirection.flexion => '大腿后侧',
    HipDirection.extension => '髋前侧',
    HipDirection.abduction => '大腿内侧',
    HipDirection.adduction => '髋外侧',
    HipDirection.internalRotation => '髋内旋',
    HipDirection.externalRotation => '髋外旋',
  });

  static const english = <String, String>{
    '蝴蝶式': 'Butterfly',
    '膝盖多高？': 'How high are your knees?',
    '脚心对脚心，坐直，让膝盖自己往下落。':
        'Sit tall with the soles of your feet together. Let your knees lower naturally.',
    '大腿内侧': 'Inner thighs',
    '膝盖明显高于脚踝': 'Knees clearly above your ankles',
    '膝盖和脚踝差不多高': 'Knees about level with your ankles',
    '膝盖低于脚踝、接近地面': 'Knees below your ankles, close to the floor',
    '90/90': '90/90',
    '能坐直吗？': 'Can you sit upright?',
    '两条腿都摆成直角，手离开地面，坐直。':
        'Bend both legs to right angles. Lift your hands off the floor and sit tall.',
    '髋部': 'Hips',
    '有一个膝盖明显翘起来': 'One knee lifts clearly off the floor',
    '要用手撑或后仰才坐得住': 'You need hand support or must lean back',
    '手离地也能坐直，两膝贴地': 'You can sit tall with hands lifted and both knees down',
    '哪条腿的膝盖翘？': 'Which knee lifts off the floor?',
    '前面那条腿': 'Front leg',
    '后面那条腿': 'Back leg',
    '屈髋肌测试': 'Hip flexor check',
    '膝窝能塞进什么？': 'What fits under your knee?',
    '抱住一边膝盖，另一条腿放松伸直，把手塞到膝盖下面试试。':
        'Hug one knee. Relax and straighten the other leg, then try sliding your hand under that knee.',
    '又称托马斯测试（Thomas test），测髋前侧屈髋肌紧不紧':
        'Also called the Thomas test: a check for tight hip flexors at the front of the hip.',
    '这项（Thomas test）和托马斯全旋没关系，但髋前侧松不松，会影响你的 L 撑。':
        'The Thomas test is unrelated to flares, but hip flexor mobility can affect your L-sit.',
    '髋前侧': 'Front of hip',
    '拳头能塞进去，或大腿抬起': 'A fist fits underneath, or your thigh lifts',
    '手掌能塞进去': 'A flat hand fits underneath',
    '手塞不进去，整条腿贴地': 'No hand fits; the whole leg rests on the floor',
    '仰卧横跨': 'Supine crossover',
    '脚能跨多远？': 'How far can your foot cross?',
    '一条腿伸直抬起来，往另一边跨过去。手按胯骨，胯骨一动就停。':
        'Lift one straight leg and cross it over. Keep a hand on your pelvis and stop as soon as it moves.',
    '髋外侧': 'Outer hip',
    '没到另一条腿上方，胯骨就翻了':
        'Your pelvis rolls before your foot reaches the other leg',
    '刚好到另一条腿正上方': 'Your foot reaches directly above the other leg',
    '越过另一条腿外侧一个脚掌': 'Your foot crosses a foot-width beyond the other leg',
    '坐姿体前屈': 'Seated forward fold',
    '手摸到哪里？': 'How far can your hands reach?',
    '膝盖别弯，从屁股那里往前折，手顺着腿往前走。':
        'Keep your knees straight. Hinge forward at your hips and slide your hands along your legs.',
    '大腿后侧': 'Hamstrings',
    '手只到膝盖附近': 'Your hands reach around your knees',
    '手到小腿或脚踝': 'Your hands reach your shins or ankles',
    '摸到脚尖或更远': 'Your hands reach your toes or beyond',
    '深蹲到底': 'Deep squat',
    '能蹲多深？': 'How deep can you squat?',
    '脚跟踩稳，慢慢蹲到最低，停 3 秒。旁边放把椅子，不稳就扶。':
        'Keep your heels down. Squat as low as you can and hold for 3 seconds. Keep a chair nearby for support if needed.',
    '只能半蹲，大腿还高于水平': 'You can only partly squat; thighs stay above horizontal',
    '大腿接近水平，还不能蹲到底': 'Thighs approach horizontal, but you cannot squat fully',
    '蹲到底，脚跟贴地': 'You can squat fully with your heels down',
    '紧': 'Tight',
    '一般': 'Fair',
    '松': 'Free',
    '入门': 'Starter',
    '基础': 'Basic',
    '进阶': 'Advanced',
    '髋内旋': 'Internal rotation',
    '髋外旋': 'External rotation',
    'Breaking 开胯 · 分腿（风车 / 托马斯腿部绕环）':
        'Breaking mobility · Straddle (windmills / flare leg circles)',
    'Breaking 开胯 · 髋外侧': 'Breaking mobility · Outer hip',
    'Breaking 开胯 · 先补髋前侧（L 撑）': 'Breaking mobility · Hip flexors first (L-sit)',
    'Breaking 开胯 · 分腿': 'Breaking mobility · Straddle',
    'Breaking 开胯 · 压缩（L 撑 / V 撑）':
        'Breaking mobility · Compression (L-sit / V-sit)',
    'Breaking 开胯 · 内旋补强': 'Breaking mobility · Internal rotation',
    '盘腿自如 → 横叉': 'Easy cross-legged sitting → Side split',
    '髋外侧放松': 'Outer hip release',
    '久坐解压（髋前侧）': 'Sitting reset (hip flexors)',
    '盘腿自如': 'Easy cross-legged sitting',
    '内旋补强': 'Internal rotation support',
  };
}
