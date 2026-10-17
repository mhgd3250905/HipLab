#!/usr/bin/env python3
"""Generate assets/hip/hip-content.json for the HipLab (hip) app variant.

Sources (copied verbatim from the phase-0 design package into ./source):
  - 髋部动作表.csv   : drill metadata (MVP = "MVP" + "新增P0" rows = 45 drills)
  - 成套训练.md      : 6 routines + the 2-minute reminder routine (tables)
  - 自测设计.md      : 6 assessment items, scoring and safety rules
                       (encoded below by hand; section numbers noted inline)

Run from the repository root:  python3 tools/hip_content/build_hip_content.py
(tools/sync_drill_media.py runs it after refreshing assets/drill_media.)
The output is deterministic (sorted keys, stable order) so diffs stay readable.
"""
import csv
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
APP = os.path.abspath(os.path.join(HERE, '..', '..'))
SRC = os.path.join(HERE, 'source')
OUT = os.path.join(APP, 'assets', 'hip', 'hip-content.json')

DIRECTIONS = [
    # id, 中文, 雷达标签, 一句人话（结果页用）
    ('flexion', '屈', '屈', '大腿后侧'),
    ('extension', '伸', '伸', '髋前侧'),
    ('abduction', '外展', '外展', '大腿内侧'),
    ('adduction', '内收', '内收', '髋外侧'),
    ('internal_rotation', '内旋', '内旋', '髋内旋'),
    ('external_rotation', '外旋', '外旋', '髋外旋'),
]
DIR_BY_ZH = {zh: i for i, zh, _, _ in DIRECTIONS}
METHOD_BY_ZH = {'放松': 'relax', '柔韧': 'flexibility', '主动控制': 'control', '力量': 'strength'}
SCENE_BY_ZH = {'办公椅': 'chair', '居家垫': 'home'}
LEVEL_BY_ZH = {'入门': 'beginner', '进阶': 'advanced'}

# Media that already exists in the repository, in order of preference:
#  1. drill media listed in source/hip-media.json: assets/drill_media/<asset>.mp4
#     + .jpg (asset defaults to hip-<id lower-case>). Mostly HipLab's own
#     drill-anim renders; two entries are FlareLab library clips copied in.
#  2. phase-0 prototype posters (scheme B, jade recolour) in assets/hip/posters
APP_VIDEO_DIR = os.path.join(APP, 'assets', 'drill_media')
POSTER_DIR = os.path.join(APP, 'assets', 'hip', 'posters')
ASSESS_DIR = os.path.join(APP, 'assets', 'hip', 'assessment')
HIP_MEDIA = json.load(open(os.path.join(SRC, 'hip-media.json'), encoding='utf-8'))

# 自测设计 4.4: explicit substitution pairs for the pain ladder.
EXTRA_ALTERNATIVES = {
    's-pigeon': 's-figure4',
    'h-couch-stretch': 's-kneel-hipflex',
    'h-sumo-pry': 'h-wall-straddle',
    'n-half-split': 'o-seated-ham',
    'h-quad-cars': 'h-hip-gate',
    's-lizard': 'o-stand-lunge',
}


def split(value):
    return [v.strip() for v in value.split(';') if v.strip() and v.strip() != '—（二期）']


def hip_media(key):
    meta = HIP_MEDIA['videos'].get(key)
    # the media player only takes lower-case hip-<id>
    name = (meta or {}).get('asset') or 'hip-' + key.lower()
    mp4 = os.path.join(APP_VIDEO_DIR, name + '.mp4')
    jpg = os.path.join(APP_VIDEO_DIR, name + '.jpg')
    if not meta or not (os.path.exists(mp4) and os.path.exists(jpg)):
        return None
    return {
        'status': 'video',
        'video': f'assets/drill_media/{name}.mp4',
        'poster': f'assets/drill_media/{name}.jpg',
        'duration_seconds': meta['duration_seconds'],
        'poster_time_seconds': meta['poster_time_seconds'],
    }


def assess_img(name):
    # 自测对比图: assets/hip/assessment/<item>-<a|b|c|front|back>.webp
    return f'assets/hip/assessment/{name}.webp' if os.path.exists(os.path.join(ASSESS_DIR, name + '.webp')) else None


def media_for(drill_id):
    own = hip_media(drill_id)
    if own:
        return own
    poster = os.path.join(POSTER_DIR, drill_id + '.webp')
    if os.path.exists(poster):
        return {'status': 'poster', 'video': None, 'poster': f'assets/hip/posters/{drill_id}.webp'}
    return {'status': 'pending', 'video': None, 'poster': None}


def read_drills():
    rows = list(csv.DictReader(open(os.path.join(SRC, '髋部动作表.csv'), encoding='utf-8-sig')))
    drills = {}
    for r in rows:
        drills[r['动作id']] = {
            'id': r['动作id'],
            'name': r['动作名'],
            'directions': [DIR_BY_ZH[d] for d in split(r['髋部方向'])],
            'methods': [METHOD_BY_ZH[m] for m in split(r['练法'])],
            'scenes': [SCENE_BY_ZH[s] for s in split(r['场景']) if s in SCENE_BY_ZH],
            'level': LEVEL_BY_ZH[r['难度']],
            'mvp': r['MVP状态'] in ('MVP', '新增P0'),
            'tier': r['MVP状态'],
            'source': r['来源'],
            'animation_note': r['动画状态'],
            'cautions': split(r['注意部位']),
            'note': r['备注'],
            'alternative': None,
        }
    return drills


ROUTINE_HEADER = re.compile(r'^## 套 ([A-Z]) · (.+)$')
SECONDS = re.compile(r'(\d+) 秒')
ALT = re.compile(r'L1 替代：([a-z0-9-]+(?:-[A-Z])?)')


def read_routines(drills):
    text = open(os.path.join(SRC, '成套训练.md'), encoding='utf-8').read().splitlines()
    routines = []
    current = None
    for line in text:
        m = ROUTINE_HEADER.match(line)
        if m:
            current = {'id': m.group(1), 'name': m.group(2), 'audience': '', 'scene': None, 'steps': []}
            routines.append(current)
            continue
        if current is None:
            continue
        if line.startswith('- **给谁**：'):
            current['audience'] = line.split('：', 1)[1].strip()
        elif line.startswith('- **场景**：'):
            current['scene'] = 'chair' if '办公椅' in line else 'home'
        elif line.startswith('| ') and re.match(r'^\| \d+ \|', line):
            cells = [c.strip() for c in line.strip().strip('|').split('|')]
            _, name, drill_id, dose, seconds, level, status, tip = (cells + [''] * 8)[:8]
            drill_id = drill_id.strip('`')
            if drill_id not in drills:
                sys.exit(f'routine {current["id"]} references unknown drill {drill_id}')
            alt = ALT.search(tip)
            alt_id = alt.group(1) if alt else None
            if alt_id:
                if alt_id not in drills:
                    sys.exit(f'unknown alternative {alt_id}')
                drills[drill_id]['alternative'] = drills[drill_id]['alternative'] or alt_id
            current['steps'].append({
                'drill': drill_id,
                'dose': dose,
                'seconds': int(SECONDS.search(seconds).group(1)),
                'sided': '每侧' in dose,
                'alternative': alt_id,
                'tip': '' if tip.startswith('L1 替代') else tip,
            })
        elif line.startswith('## ') and not line.startswith('## 套'):
            current = None
    for r in routines:
        r['transition_seconds'] = 5
        r['seconds'] = sum(s['seconds'] for s in r['steps']) + 5 * (len(r['steps']) - 1)
        r['kind'] = 'micro' if r['id'] == 'M' else 'routine'
    return routines


def demo_clip(key, drill_id, name):
    # A self-test demo cut from a drill loop (assets/drill_media/hip-<key>.mp4); None until rendered.
    media = hip_media(key)
    if not media:
        return None
    return {'id': f'{drill_id}#{key}', 'name': name, 'directions': [], 'methods': [], 'scenes': [],
            'level': 'beginner', 'mvp': False, 'cautions': [], 'media': media}


def assessment():
    # 自测设计 §2 / §3. Options are scored A=2 (松) / B=1 (一般) / C=0 (紧).
    # UI order follows the prototype (s2-assessment.png): 紧 · 一般 · 松.
    def opt(score, label, desc, image=None):
        return {'score': score, 'label': label, 'description': desc, 'image': image}

    return {
        'radar_map': {'0': 25, '1': 60, '2': 90},
        'skip_score': 1,
        'level_bands': [
            {'level': 1, 'name': '入门', 'min': 0, 'max': 5, 'mix': {'relax': 30, 'flexibility': 50, 'control': 15, 'strength': 5}},
            {'level': 2, 'name': '基础', 'min': 6, 'max': 9, 'mix': {'relax': 20, 'flexibility': 40, 'control': 25, 'strength': 15}},
            {'level': 3, 'name': '进阶', 'min': 10, 'max': 12, 'mix': {'relax': 10, 'flexibility': 30, 'control': 35, 'strength': 25}},
        ],
        'dancer_unlock_total': 10,
        'tie_priority': ['extension', 'internal_rotation', 'abduction', 'flexion', 'external_rotation', 'adduction'],
        # direction -> [[item, part, weight]]; part is the sub-score (9090 has front/back).
        'weights': {
            'flexion': [['seated_fold', 'score', 0.6], ['deep_squat', 'score', 0.4]],
            'extension': [['thomas', 'score', 1.0]],
            'abduction': [['butterfly', 'score', 0.7], ['deep_squat', 'score', 0.3]],
            'adduction': [['supine_cross', 'score', 1.0]],
            'internal_rotation': [['ninety_ninety', 'back', 1.0]],
            'external_rotation': [['ninety_ninety', 'front', 0.6], ['butterfly', 'score', 0.4]],
        },
        'items': [
            {
                'id': 'butterfly', 'order': 1, 'title': '蝴蝶式', 'question': '膝盖多高？',
                'cue': '脚心对脚心，坐直，让膝盖自己往下落。', 'demo_drill': 's-butterfly',
                'seconds': 12, 'sided': False, 'directions': ['abduction', 'external_rotation'],
                'glow': '大腿内侧',
                'options': [
                    opt(0, '紧', '膝盖明显高于脚踝', assess_img('butterfly-c')),
                    opt(1, '一般', '膝盖和脚踝差不多高', assess_img('butterfly-b')),
                    opt(2, '松', '膝盖低于脚踝、接近地面', assess_img('butterfly-a')),
                ],
            },
            {
                'id': 'ninety_ninety', 'order': 2, 'title': '90/90', 'question': '能坐直吗？',
                'cue': '两条腿都摆成直角，手离开地面，坐直。', 'demo_drill': 's-9090',
                'seconds': 15, 'sided': True, 'directions': ['external_rotation', 'internal_rotation'],
                'glow': '髋部',
                'options': [
                    opt(0, '紧', '有一个膝盖明显翘起来', assess_img('9090-c')),
                    opt(1, '一般', '要用手撑或后仰才坐得住', assess_img('9090-b')),
                    opt(2, '松', '手离地也能坐直，两膝贴地', assess_img('9090-a')),
                ],
                # Only shown after "紧" (C). 自测设计 §2②.
                'follow_up': {
                    'question': '哪条腿的膝盖翘？',
                    'options': [
                        {'id': 'front', 'label': '前面那条腿', 'front': 0, 'back': 1, 'image': assess_img('9090-front')},
                        {'id': 'back', 'label': '后面那条腿', 'front': 1, 'back': 0, 'image': assess_img('9090-back')},
                    ],
                },
            },
            {
                'id': 'thomas', 'order': 3, 'title': '托马斯测试', 'question': '膝窝能塞进什么？',
                'cue': '抱住一边膝盖，另一条腿放松伸直，把手塞到膝盖下面试试。', 'demo_drill': 'n-thomas-test',
                'seconds': 15, 'sided': True, 'directions': ['extension'], 'glow': '髋前侧',
                'note_for_dancer': '这项和托马斯全旋没关系，但髋前侧松不松，会影响你的 L 撑。',
                'options': [
                    opt(0, '紧', '拳头能塞进去，或大腿抬起', assess_img('thomas-c')),
                    opt(1, '一般', '手掌能塞进去', assess_img('thomas-b')),
                    opt(2, '松', '手塞不进去，整条腿贴地', assess_img('thomas-a')),
                ],
            },
            {
                'id': 'supine_cross', 'order': 4, 'title': '仰卧横跨', 'question': '脚能跨多远？',
                'cue': '一条腿伸直抬起来，往另一边跨过去。手按胯骨，胯骨一动就停。', 'demo_drill': 'n-leg-circles',
                'demo_media': demo_clip('supine-cross-demo', 'n-leg-circles', '仰卧单腿横跨（演示）'),
                'seconds': 15, 'sided': True, 'directions': ['adduction'], 'glow': '髋外侧',
                'options': [
                    opt(0, '紧', '没到另一条腿上方，胯骨就翻了', assess_img('supine-cross-c')),
                    opt(1, '一般', '刚好到另一条腿正上方', assess_img('supine-cross-b')),
                    opt(2, '松', '越过另一条腿外侧一个脚掌', assess_img('supine-cross-a')),
                ],
            },
            {
                'id': 'seated_fold', 'order': 5, 'title': '坐姿体前屈', 'question': '手摸到哪里？',
                'cue': '膝盖别弯，从屁股那里往前折，手顺着腿往前走。', 'demo_drill': 's-seated-fold',
                'seconds': 12, 'sided': False, 'directions': ['flexion'], 'glow': '大腿后侧',
                'options': [
                    opt(0, '紧', '手只到膝盖附近', assess_img('seated-fold-c')),
                    opt(1, '一般', '手到小腿或脚踝', assess_img('seated-fold-b')),
                    opt(2, '松', '摸到脚尖或更远', assess_img('seated-fold-a')),
                ],
            },
            {
                'id': 'deep_squat', 'order': 6, 'title': '深蹲到底', 'question': '能蹲多深？',
                'cue': '脚跟踩稳，慢慢蹲到最低，停 3 秒。旁边放把椅子，不稳就扶。', 'demo_drill': 'h-squat',
                'seconds': 12, 'sided': False, 'directions': ['flexion', 'abduction'], 'glow': '髋部',
                'options': [
                    opt(0, '紧', '大腿到水平附近就下不去', assess_img('deep-squat-c')),
                    opt(1, '一般', '脚跟抬起或要扶东西', assess_img('deep-squat-b')),
                    opt(2, '松', '蹲到底，脚跟贴地', assess_img('deep-squat-a')),
                ],
            },
        ],
        # 自测设计 §3.2: route = identity × lowest direction. MVP maps a route
        # onto one of the preset routines (8-week routes are phase 2).
        'recommendations': {
            'office': {
                'extension': {'route': '久坐解压（髋前侧）', 'routine': 'D'},
                'flexion': {'route': '深蹲到底', 'routine': 'E'},
                'abduction': {'route': '盘腿自如 → 横叉', 'routine': 'B'},
                'external_rotation': {'route': '盘腿自如', 'routine': 'B'},
                'internal_rotation': {'route': '内旋补强', 'routine': 'D'},
                'adduction': {'route': '髋外侧放松', 'routine': 'A'},
            },
            'dancer': {
                'extension': {'route': 'Breaking 开胯 · 先补髋前侧（L 撑）', 'routine': 'F'},
                'flexion': {'route': 'Breaking 开胯 · 压缩（L 撑 / V 撑）', 'routine': 'F'},
                'abduction': {'route': 'Breaking 开胯 · 分腿（风车 / 托马斯腿部绕环）', 'routine': 'F'},
                'external_rotation': {'route': 'Breaking 开胯 · 分腿', 'routine': 'F'},
                'internal_rotation': {'route': 'Breaking 开胯 · 内旋补强', 'routine': 'F'},
                'adduction': {'route': 'Breaking 开胯 · 髋外侧', 'routine': 'F'},
            },
        },
        'adduction_focus_drills': ['o-stand-crossreach', 'h-supine-twist', 'n-seated-squeeze'],
    }


SAFETY_CARDS = [
    {'id': 'pregnancy', 'title': '孕期或产后 6 个月内', 'icon': 'pregnant_woman'},
    {'id': 'surgery', 'title': '髋、膝、腰做过手术或关节置换，或医生让你限制活动', 'icon': 'healing'},
    {'id': 'acute', 'title': '最近摔伤、扭伤，或髋部、腰部、大腿正在疼、肿', 'icon': 'personal_injury'},
]


def main():
    drills = read_drills()
    routines = read_routines(drills)
    for k, v in EXTRA_ALTERNATIVES.items():
        drills[k]['alternative'] = drills[k]['alternative'] or v
    used = {s['drill'] for r in routines for s in r['steps']} | {
        s['alternative'] for r in routines for s in r['steps'] if s['alternative']}
    used |= {d['alternative'] for d in drills.values() if d['mvp'] and d['alternative']}
    keep = [d for d in drills.values() if d['mvp'] or d['id'] in used]
    for d in keep:
        d['media'] = media_for(d['id'])
    mvp = [d for d in keep if d['mvp']]
    assert len(mvp) == 45, len(mvp)
    data = {
        'schema_version': 1,
        'generated_by': 'tools/hip_content/build_hip_content.py',
        'directions': [{'id': i, 'zh': zh, 'radar': r, 'area': a} for i, zh, r, a in DIRECTIONS],
        'safety_cards': SAFETY_CARDS,
        'drills': keep,
        'routines': routines,
        'assessment': assessment(),
    }
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with open(OUT, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=1, sort_keys=True)
        f.write('\n')
    media = {}
    for d in mvp:
        media[d['media']['status']] = media.get(d['media']['status'], 0) + 1
    print(f'{len(mvp)} MVP drills (+{len(keep) - len(mvp)} referenced alternatives), '
          f'{len(routines)} routines, media {media}')
    for r in routines:
        print(f"  {r['id']} {r['name']} {r['scene']} {r['seconds']}s steps={len(r['steps'])}")


if __name__ == '__main__':
    main()
