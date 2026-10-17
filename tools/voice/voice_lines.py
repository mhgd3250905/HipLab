"""Every line HipLab can say, in Chinese and English (issue #13).

Keys are stable ids the app looks up in assets/voice/manifest.json; the
build script (build_voice.py) turns each (key, text) into one clip per
language. Change wording here and re-run the script; the app code does not
change. Content-driven lines (drill names, doses, assessment items, routine
names) are added by build_voice.py from assets/hip/hip-content.json, with
the English wording from the tables below.
"""

# ── fixed phrases ────────────────────────────────────────────────────────
PHRASES = {
    # session
    'p.welcome': ('开始训练', "Let's begin"),
    'p.total': ('全程大约', 'about'),
    'p.steps': ('个动作', 'moves'),
    'p.first': ('第一个动作', 'First up'),
    'p.next': ('下一个', 'Next up'),
    'p.last': ('最后一个动作', 'Last one'),
    'p.ready': ('准备', 'Get ready'),
    'p.go': ('开始', 'Go'),
    'p.go_right': ('先做右边，开始', 'Right side first. Go'),
    'p.half': ('过半了，保持住', 'Halfway there. Hold it'),
    'p.last10': ('还剩 10 秒', '10 seconds left'),
    'p.switch_left': ('换左边', 'Switch to the left side'),
    'p.switch_right': ('换右边', 'Switch to the right side'),
    'p.rest': ('休息', 'Rest for'),
    'p.nice': ('很好', 'Nice work'),
    'p.paused': ('已暂停', 'Paused'),
    'p.resume': ('继续', "Let's continue"),
    'p.skip': ('跳过', 'Skipped'),
    'p.finish': ('太棒了，今天的训练完成了。记得多喝水，慢慢起身。',
                 "Great job, today's session is done. Drink some water and get up slowly."),
    'p.stop': ('先停下来。麻、刺或往下窜的感觉不该出现在练习里。',
               'Stop here. Numbness or a shooting feeling should not happen in practice.'),
    'p.each_side': ('每侧', 'each side'),
    # coach cues by method (two variants each, played at about 1/3 and 2/3)
    'cue.relax.1': ('慢慢呼吸，放松', 'Breathe slowly and relax'),
    'cue.relax.2': ('肩膀放松，别憋气', 'Shoulders loose, keep breathing'),
    'cue.flexibility.1': ('呼气，再沉一点', 'Breathe out and sink a little deeper'),
    'cue.flexibility.2': ('保持住，不要弹震', 'Hold still, no bouncing'),
    'cue.control.1': ('慢一点，控制住', 'Slow down, stay in control'),
    'cue.control.2': ('骨盆稳住，只动髋', 'Keep the pelvis still, move from the hip'),
    'cue.strength.1': ('稳住，别憋气', 'Stay steady, keep breathing'),
    'cue.strength.2': ('用力的时候呼气', 'Breathe out as you push'),
    'cue.extra_right': ('右边多做一组', 'One extra set on the right'),
    'cue.extra_left': ('左边多做一组', 'One extra set on the left'),
    'cue.half_range': ('幅度减半，只做到不疼的位置', 'Half the range, only go where it does not hurt'),
    # assessment
    'a.intro': ('开胯体检，一共 6 项。每项跟着做一遍，再选一张最像你的图。',
                'Hip check, six moves. Follow each one, then pick the picture that looks most like you.'),
    'a.left_first': ('先测左边', 'Left side first'),
    'a.hold': ('保持住，感受一下', 'Hold it and notice how it feels'),
    'a.choose': ('好，看看你像哪一张，选一个', 'Okay. Which picture looks like you? Pick one'),
    'a.switch_right': ('左边记好了，换右边', 'Left side saved. Now the right side'),
    'a.done': ('自测完成，来看看你的结果', 'Check complete. Here are your results'),
}

# Spoken numbers. Countdown uses 1–5 (and 10), counting uses 1–10.
NUMBERS_ZH = ['零', '一', '二', '三', '四', '五', '六', '七', '八', '九', '十']
NUMBERS_EN = ['zero', 'one', 'two', 'three', 'four', 'five', 'six', 'seven',
              'eight', 'nine', 'ten']


def seconds_text(s):
    """Duration as spoken: 45 秒 / 1 分钟 / 1 分 15 秒."""
    m, r = divmod(s, 60)
    if m == 0:
        zh = f'{s} 秒'
    elif r == 0:
        zh = f'{m} 分钟'
    else:
        zh = f'{m} 分 {r} 秒'
    if m == 0:
        en = f'{s} seconds'
    elif r == 0:
        en = f'{m} minute' + ('s' if m > 1 else '')
    else:
        en = f'{m} minute' + ('s' if m > 1 else '') + f' {r}'
    return zh, en


# ── drills: English name + one short key point in each language ──────────
# (zh point, en name, en point). The zh name comes from the content pack.
DRILLS = {
    'h-9090-liftoff': ('坐直，后腿膝盖慢慢抬离地面，再慢慢放下', 'Ninety-ninety rear-leg lift-off',
                       'Sit tall, lift the back knee slowly, then lower it slowly'),
    'h-adductor-rock': ('一条腿向侧面伸直，臀部慢慢往后坐', 'Quadruped adductor rock-back',
                        'One leg out to the side, sit your hips back slowly'),
    'h-band-hip-ir': ('膝盖不动，小腿向外转', 'Seated band hip internal rotation',
                      'Keep the knee still, turn the shin outward'),
    'h-band-leg-out': ('腿伸直，慢慢向外侧落下', 'Supine band leg lower-out',
                       'Keep the leg straight and lower it out to the side'),
    'h-butterfly-active': ('脚心相对，膝盖慢慢打开再收回', 'Active supine butterfly',
                           'Soles together, open the knees slowly and bring them back'),
    'h-couch-stretch': ('后脚搭高，收紧臀部，髋往前送', 'Couch stretch',
                        'Back foot up, squeeze your glutes, hips forward'),
    'h-hip-gate': ('扶住椅子，膝盖抬高，向外画圈打开', 'Standing hip gate',
                   'Hold the chair, lift the knee and circle it open'),
    'h-quad-cars': ('四点跪姿，膝盖画一个尽量大的圈，腰不要动', 'Quadruped hip circles',
                    'On all fours, draw a big circle with the knee, keep the low back still'),
    'h-reverse-clam': ('膝盖并拢，小腿慢慢向上抬', 'Side-lying reverse clam',
                       'Knees together, lift the shin up slowly'),
    'h-sumo-pry': ('蹲低，手肘把膝盖轻轻向外推', 'Sumo squat elbow pry',
                   'Sit low and gently press the knees out with your elbows'),
    'h-wall-straddle': ('腿靠墙，让双腿自然向两侧打开', 'Wall straddle',
                        'Legs up the wall, let them fall open to the sides'),
    'h-knee-hug': ('双手抱膝，慢慢呼吸', 'Supine knee hug', 'Hug your knees and breathe slowly'),
    'h-supine-twist': ('双膝倒向一侧，肩膀贴地', 'Supine bent-knee twist',
                       'Drop both knees to one side, shoulders stay down'),
    'h-squat': ('脚跟踩稳，膝盖对准脚尖', 'Bodyweight squat',
                'Heels down, knees track over the toes'),
    'hip-flexors-A': ('坐直，腿伸直抬起，停一下再放下', 'Seated straight-leg lift',
                      'Sit tall, lift the straight leg, pause, then lower'),
    'glute-max-A': ('一条腿抬起，用臀部把身体推高', 'Single-leg glute bridge',
                    'One leg up, drive your hips up with your glutes'),
    's-9090': ('两条腿都成直角，坐直，再左右换', 'Ninety-ninety hip switch',
               'Both legs at right angles, sit tall, then switch sides'),
    's-butterfly': ('脚心对脚心，坐直，让膝盖自然落下', 'Butterfly',
                    'Soles together, sit tall, let the knees drop'),
    's-figure4': ('脚踝搭在另一侧膝盖上，把腿拉向胸口', 'Supine figure four',
                  'Ankle over the other knee, pull the legs toward your chest'),
    's-frog': ('膝盖向两侧打开，脚尖朝外，臀部慢慢往后坐', 'Frog stretch',
               'Knees wide, toes out, sit your hips back slowly'),
    's-kneel-hipflex': ('后侧臀部收紧，髋慢慢往前推', 'Kneeling hip flexor stretch',
                        'Squeeze the back glute and ease the hips forward'),
    's-lizard': ('前脚放在手外侧，髋往下沉', 'Lizard lunge',
                 'Front foot outside your hand, sink the hips'),
    's-pigeon': ('上身立直，手扶砖，髋往下沉', 'Upright pigeon',
                 'Stay upright, hands on the blocks, sink the hips'),
    's-seated-fold': ('膝盖伸直，从髋部往前折', 'Seated forward fold',
                      'Knees straight, fold forward from the hips'),
    'o-seated-fig4': ('脚踝搭在膝盖上，背挺直往前压', 'Seated figure four',
                      'Ankle on the knee, keep the back straight and lean forward'),
    'o-seated-ham': ('腿伸直，脚尖勾起，背挺直往前', 'Seated hamstring reach',
                     'Leg straight, toes up, lean forward with a straight back'),
    'o-stand-lunge': ('扶住椅子，后侧臀部收紧，髋往前推', 'Standing lunge hip flexor stretch',
                      'Hold the chair, squeeze the back glute, hips forward'),
    'o-stand-crossreach': ('一条腿交叉到后面，手臂向上向侧面伸', 'Standing cross-reach',
                           'Cross one leg behind and reach up and over'),
    'w-clamshell': ('脚跟并拢，膝盖像贝壳一样打开', 'Side-lying clamshell',
                    'Heels together, open the knee like a clamshell'),
    'w-feet-on-chair-bridge': ('脚踩椅面，用臀部把身体推高', 'Feet-on-chair bridge',
                               'Feet on the chair, drive your hips up'),
    't-seated-straddle-lift-1leg': ('分腿坐直，一条腿抬离地面', 'Seated straddle single-leg lift',
                                    'Sit tall in a straddle and lift one leg off the floor'),
    'n-seated-ir-drop': ('手在身后撑地，一侧膝盖向内倒', 'Seated knee drop-in',
                         'Hands behind you, drop one knee inward'),
    'n-windshield': ('双膝一起慢慢左右倒，肩膀贴地', 'Supine windshield wipers',
                     'Let both knees fall side to side, shoulders down'),
    'n-chair-wiper': ('坐在椅子上，小腿向外摆，膝盖向内倒', 'Chair windshield wipers',
                      'Seated, swing the shin out and let the knee fall in'),
    'n-prone-ir': ('趴着，屈膝，小腿向外侧摆', 'Prone hip internal rotation',
                   'Lying face down, knees bent, let the shins fall outward'),
    'n-half-split': ('前腿伸直，从髋部往前折，手扶砖', 'Half split',
                     'Front leg straight, fold from the hips, hands on the blocks'),
    'n-prone-hip-ext': ('趴着，屈膝，大腿慢慢抬离地面', 'Prone bent-knee hip lift',
                        'Lying face down, knee bent, lift the thigh slowly'),
    'n-slider-lateral': ('一只脚向侧面滑出去，再收回来', 'Lateral slider',
                         'Slide one foot out to the side and pull it back'),
    'n-wide-fold': ('双脚分开，扶住椅子，从髋部往前折', 'Wide-stance forward fold',
                    'Feet wide, hold the chair, fold from the hips'),
    'n-straddle-fold': ('分腿坐直，从髋部慢慢往前倾', 'Seated straddle fold',
                        'Sit tall in a straddle and lean forward from the hips'),
    'n-seated-knee-lift': ('坐直，膝盖抬起，悬停住', 'Seated knee lift hold',
                           'Sit tall, lift the knee and hold it there'),
    'n-pelvis-circle': ('双脚不动，骨盆慢慢画圈', 'Standing pelvic circles',
                        'Feet still, draw slow circles with your pelvis'),
    'n-seated-squeeze': ('双膝夹住瑜伽砖，用力夹紧', 'Seated block squeeze',
                         'Squeeze the block between your knees'),
    'n-squat-shift': ('低蹲，重心慢慢左右移', 'Deep squat side shift',
                      'Stay low and shift your weight side to side'),
    'n-leg-circles': ('腿伸直，慢慢画圈，骨盆不动', 'Supine leg circles',
                      'Leg straight, draw slow circles, pelvis still'),
    'n-thomas-test': ('抱住一边膝盖，另一条腿放松伸直', 'Supine single knee hug',
                      'Hug one knee, let the other leg rest straight'),
}

ROUTINES_EN = {
    'A': 'Office', 'B': 'Bedtime', 'C': 'Morning wake-up', 'D': 'Desk-sitting relief',
    'E': 'Pre-workout activation', 'F': 'Breaking hip opener', 'M': 'Chair break',
}

# Conditional tips in the routines, rephrased to be spoken.
TIPS = {
    '膝不舒服：只把脚踝搭上、不前压': ('如果膝盖不舒服，只把脚踝搭上，不往前压',
                         'If your knee complains, just rest the ankle on it and do not lean forward'),
    '没有毛巾：手扶大腿内侧': ('没有毛巾的话，用手扶住大腿内侧', 'No towel? Hold the inner thigh with your hand'),
    '不想挪位置：换成仰卧蝴蝶停留': ('不想挪位置，也可以换成仰卧蝴蝶停留',
                        'Rather not move? Hold a lying butterfly instead'),
}

ASSESSMENT_EN = {
    # id: (title en, cue en)
    'butterfly': ('Butterfly', 'Soles together, sit tall and let the knees drop on their own.'),
    'ninety_ninety': ('Ninety ninety', 'Both legs at right angles, hands off the floor, sit tall.'),
    'thomas': ('Hip flexor test', 'Hug one knee, let the other leg rest straight, and slide your hand under that knee.'),
    'supine_cross': ('Lying leg cross', 'Lift one straight leg and cross it over. Hand on your hip bone, stop as soon as it moves.'),
    'seated_fold': ('Seated forward fold', 'Knees straight, fold from the hips and walk your hands down your legs.'),
    'deep_squat': ('Deep squat', 'Heels down, squat as low as you can and hold for three seconds. Keep a chair nearby.'),
}
ASSESSMENT_ORDER_ZH = ['第一项', '第二项', '第三项', '第四项', '第五项', '第六项']
ASSESSMENT_ORDER_EN = ['Move one', 'Move two', 'Move three', 'Move four', 'Move five', 'Move six']


def dose_en(zh):
    """English for the content pack's dose strings."""
    import re
    s = re.sub(r'（.*?）', '', zh).strip()
    rules = [
        (r'^每侧 正反各 (\d+) 圈$', r'\1 circles each way, each side'),
        (r'^正反各 (\d+) 圈$', r'\1 circles each way'),
        (r'^每侧 (\d+) 圈$', r'\1 circles each side'),
        (r'^每侧 开 (\d+)(?: 次)? \+ 关 (\d+)(?: 次)?$', r'\1 open and \2 close, each side'),
        (r'^每侧 (\d+) 次 × 停 (\d+) 秒$', r'\1 reps with a \2 second hold, each side'),
        (r'^每侧 (\d+) 次$', r'\1 reps each side'),
        (r'^每侧 (\d+) 秒$', r'\1 seconds each side'),
        (r'^停 (\d+) 次 × (\d+) 秒$', r'\1 holds of \2 seconds'),
        (r'^停 (\d+) 秒$', r'hold for \1 seconds'),
        (r'^慢呼吸 (\d+) 次$', r'\1 slow breaths'),
        (r'^左右交替 (\d+) 次$', r'\1 reps, alternating sides'),
        (r'^左右慢慢倒 (\d+) 次$', r'\1 slow drops side to side'),
        (r'^左右 (\d+) 次$', r'\1 reps side to side'),
        (r'^慢开慢合 (\d+) 次$', r'\1 slow open and close'),
        (r'^(\d+) 次$', r'\1 reps'),
    ]
    for pat, rep in rules:
        if re.match(pat, s):
            return re.sub(pat, rep, s)
    raise ValueError(f'no English for dose {zh!r}')


def dose_zh_spoken(zh):
    import re
    s = re.sub(r'（.*?）', '', zh).strip()
    return s.replace(' × ', '，').replace('+', '加')
