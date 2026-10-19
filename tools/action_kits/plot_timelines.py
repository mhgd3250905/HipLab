#!/usr/bin/env python3
"""Gantt charts of exported rhythm timelines (voice events vs. phases).

    flutter test --no-pub test_screens/rhythm_timeline_export_test.dart \\
        --dart-define=OUT=/tmp/rhythm
    python3 tools/action_kits/plot_timelines.py /tmp/rhythm --out /tmp/charts

One PNG per case and language: the session phases, the rep phases the kit
schedules (go / hold / back / rest) and every spoken line, before (main)
and after (action kits) on the same time axis. Needs Pillow only.
"""
import argparse
import json
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]
FONT = str(ROOT / 'assets/fonts/NotoSansSC.ttf')
PX = 26            # pixels per second
LEFT = 150
LANE = 30
COL = {
    'prep': (120, 120, 140), 'work': (60, 207, 164), 'switchSide': (240, 170, 60),
    'rest': (110, 150, 220), 'done': (160, 160, 160),
    'go': (60, 207, 164), 'hold': (40, 140, 110), 'back': (240, 130, 90), 'rest_': (215, 215, 215),
    'count': (30, 30, 30), 'call': (190, 60, 60), 'info': (60, 90, 200), 'coach': (130, 130, 130),
}
PHASE_ZH = {'prep': '准备', 'work': '训练', 'switchSide': '换边', 'rest': '休息', 'done': '完成'}
REP_ZH = {'go': '起/开', 'hold': '停', 'back': '落/回', 'rest': '间歇'}


def window(j):
    """From the first work phase of step 0 to 8 s into the next step's work."""
    ph = j['phases']
    a = next(p['start'] for p in ph if p['kind'] == 'work' and p['step'] == 0) - 3
    nxt = [p for p in ph if p['step'] >= 1 and p['kind'] == 'work']
    b = (nxt[0]['start'] + 8) if nxt else max(p['start'] + p['seconds'] for p in ph) + 6
    return max(0, a), b


def draw_block(d, font, small, y, label, j, a, b, title_fill):
    d.text((10, y + 4), label, font=font, fill=title_fill)
    # session phases
    for p in j['phases']:
        s, e = p['start'], p['start'] + p['seconds']
        if e < a or s > b or p['seconds'] == 0:
            continue
        x0, x1 = LEFT + (max(s, a) - a) * PX, LEFT + (min(e, b) - a) * PX
        d.rectangle([x0, y, x1, y + LANE - 6], fill=COL[p['kind']], outline=(255, 255, 255))
        txt = PHASE_ZH[p['kind']] + (f" {p['side'][0].upper()}" if p.get('side') else '') + f" {p['seconds']:.0f}s"
        d.text((x0 + 4, y + 3), txt, font=small, fill=(255, 255, 255))
        # end-of-phase marker
        d.line([x1, y - 4, x1, y + 5 * LANE], fill=(200, 60, 60), width=1)
    y += LANE
    # rep phases (after only)
    for p in j['phases']:
        for r in p.get('reps', []):
            t = r['start']
            for ph in r['phases']:
                s, e = t, t + ph['seconds']
                t = e
                if e < a or s > b:
                    continue
                x0, x1 = LEFT + (max(s, a) - a) * PX, LEFT + (min(e, b) - a) * PX
                c = COL['rest_'] if ph['id'] == 'rest' else COL[ph['id']]
                d.rectangle([x0, y, x1, y + LANE - 8], fill=c)
                if x1 - x0 > 26:
                    d.text((x0 + 2, y + 2), REP_ZH[ph['id']], font=small, fill=(20, 20, 20))
    y += LANE
    # voice lines, staggered on two lanes
    for i, l in enumerate(x for x in j['lines'] if a <= x['start'] <= b):
        s, e = l['start'], l['end']
        lane = y + (i % 2) * LANE
        x0, x1 = LEFT + (s - a) * PX, LEFT + (min(e, b) - a) * PX
        c = COL[l['priority']]
        d.rectangle([x0, lane, max(x1, x0 + 3), lane + LANE - 8], fill=c)
        text = ''.join(t for t in l['text'] if not t.startswith('chime')).replace('，', ' ')
        d.text((x0 + 2, lane + LANE - 9), text[:14], font=small, fill=(40, 40, 40))
    return y + 3 * LANE


def plot(case, tl_dir, out, lang):
    before = json.loads((tl_dir / f'{case}.before.{lang}.json').read_text(encoding='utf-8'))
    after = json.loads((tl_dir / f'{case}.after.{lang}.json').read_text(encoding='utf-8'))
    a1, b1 = window(before)
    a2, b2 = window(after)
    span = max(b1 - a1, b2 - a2)
    W = int(LEFT + span * PX + 40)
    H = 2 * 6 * LANE + 120
    img = Image.new('RGB', (W, H), (250, 250, 248))
    d = ImageDraw.Draw(img)
    font = ImageFont.truetype(FONT, 18)
    small = ImageFont.truetype(FONT, 13)
    s0 = after['steps'][0]
    d.text((10, 8), f"{case} · {s0['name']} · {s0['dose']} · {lang}  （红线 = 阶段结束；下两行 = 语音，黑=报数/相位词，红=口令，蓝=预告，灰=要点）",
           font=font, fill=(20, 20, 20))
    # time axis
    for k in range(0, int(span) + 1, 5):
        x = LEFT + k * PX
        d.line([x, 40, x, H - 10], fill=(232, 232, 232))
        d.text((x + 2, 40), f'{k}s', font=small, fill=(150, 150, 150))
    y = 62
    y = draw_block(d, font, small, y, '改前 main', before, a1, a1 + span, (180, 40, 40))
    draw_block(d, font, small, y + 10, '改后 动作包', after, a2, a2 + span, (20, 120, 90))
    p = out / f'{case}.{lang}.png'
    img.save(p)
    return p


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('timelines')
    ap.add_argument('--out', required=True)
    a = ap.parse_args()
    tl = Path(a.timelines)
    out = Path(a.out)
    out.mkdir(parents=True, exist_ok=True)
    cases = sorted({p.name.split('.')[0] for p in tl.glob('*.after.zh.json')})
    for c in cases:
        for lang in ('zh', 'en'):
            print(plot(c, tl, out, lang))


if __name__ == '__main__':
    main()
