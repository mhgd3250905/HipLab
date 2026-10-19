#!/usr/bin/env python3
"""Action kits (action-kit v1) for every HipLab action – build and check.

An action kit is the one place an action's display, media references,
training rhythm and voice script live (docs/action-kit-spec-v1.md). Kits
are keyed by the Pose-Hub action id so the same files can later move
upstream into 3D-Pose-Hub unchanged.

Principle: the training parameters (kit_rules.RULES + the routine dose) are
the single source of truth for reps / seconds / cycle / phases / sides, and
the voice counts by them. The phases measured from the Pose-Hub spec are only
the default pace and are overridden by explicit `phases`; the demo video only
loops as a demonstration and is not synchronised with the voice.

    # (re)build assets/action_kits/<id>.json + index.json; measures the
    # rhythm from the Pose-Hub spec timelines of the frozen release
    python3 tools/action_kits/build_action_kits.py build \
        --pose-hub ../3D-Pose-Hub          # a checkout with drill-anim/specs

    # validate the kits (schema, phase sums, routine coverage, every spoken
    # line fits its phase in zh and en); no Pose-Hub checkout needed
    python3 tools/action_kits/build_action_kits.py check

    # review sheet (CSV + HTML) of all kits
    python3 tools/action_kits/build_action_kits.py overview --out /tmp/kits

Without --pose-hub, `build` keeps each kit's existing `animation` block
(the measurement is stored in the kit together with the spec's SHA-256, so
the kits can be rebuilt offline and the check notices a stale spec).
"""
import argparse
import hashlib
import html
import json
import math
import re
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(Path(__file__).resolve().parent))
sys.path.insert(0, str(ROOT / 'tools/voice'))
import kit_rules as K  # noqa: E402
import voice_lines as VL  # noqa: E402

KITS = ROOT / 'assets/action_kits'
CONTENT = ROOT / 'assets/hip/hip-content.json'
MANIFEST = ROOT / 'tools/pose-hub-manifest.json'
LOCK = ROOT / 'pose-hub.lock.json'
VOICE = ROOT / 'assets/voice/manifest.json'
SCHEMA = 'action-kit@1'
LEAD_SECONDS = 1.0       # "开始" before the first count (language independent)
KINDS = ['rep_updown', 'rep_cycle', 'rep_alternate', 'rep_hold', 'rep_breath', 'hold']
REP_KINDS = KINDS[:-1]
PHASE_IDS = ['go', 'hold', 'back', 'rest']
HOLD_CUE_AT = 1.2      # rep_hold: the hold word comes this far into the hold
STRETCH_TOP = .6       # share of a slowed rep's extra time spent at the top


def r2(x):
    return round(x * 20) / 20  # 0.05 s grid


# ── Pose-Hub ─────────────────────────────────────────────────────────────

def frozen_specs():
    lock = json.loads(LOCK.read_text(encoding='utf-8'))
    version = lock['poseHub']['version']
    man = json.loads(MANIFEST.read_text(encoding='utf-8'))
    out = {}
    for it in man['releases'][version]['items']:
        if it.get('role') == 'video' and it.get('variant') == 'dark':
            out[it['id']] = (version, it['spec']['path'], it['spec']['sha256'])
    return out


NODE_DUMP = r"""
import fs from 'fs';
const [,, list, out] = process.argv;
const res = {};
for (const f of JSON.parse(fs.readFileSync(list))) {
  const m = (await import(f)).default;
  res[f] = { duration: m.timeline.duration, tracks: m.timeline.tracks };
}
fs.writeFileSync(out, JSON.stringify(res));
"""


def measure(pose_hub, specs):
    """id → animation block measured from the spec timeline."""
    files = {i: str(Path(pose_hub) / p) for i, (_, p, _) in specs.items()}
    for i, f in files.items():
        sha = hashlib.sha256(Path(f).read_bytes()).hexdigest()
        if sha != specs[i][2]:
            raise SystemExit(f'{i}: {f} does not match the frozen spec sha256')
    with tempfile.TemporaryDirectory() as td:
        lst, out, js = Path(td) / 'l.json', Path(td) / 'o.json', Path(td) / 'd.mjs'
        lst.write_text(json.dumps(list(files.values())))
        js.write_text(NODE_DUMP)
        subprocess.run(['node', str(js), str(lst), str(out)], check=True)
        dumped = json.loads(out.read_text())
    res = {}
    for i, f in files.items():
        tl = dumped[f]
        rule = K.RULES.get(i, {})
        name = rule.get('track') or next(iter(tl['tracks']))
        res[i] = {'loopSeconds': tl['duration'], 'track': name,
                  'reps': reps_of(tl['tracks'][name], tl['duration'])}
    return res


def reps_of(track, dur):
    """[[rise start, top, fall start, bottom], …] of a 0…1 track."""
    pts = [(p[0], float(p[1])) for p in track]
    n = int(dur * 100) + 1
    ts = [dur * k / (n - 1) for k in range(n)]
    vs, j = [], 0
    for t in ts:
        while j < len(pts) - 2 and pts[j + 1][0] < t:
            j += 1
        (t0, v0), (t1, v1) = pts[j], pts[min(j + 1, len(pts) - 1)]
        vs.append(v0 if t1 == t0 else v0 + (v1 - v0) * max(0, min(1, (t - t0) / (t1 - t0))))
    top = max(vs)
    if top <= 1e-3:
        return []
    hi = [v > .97 * top for v in vs]
    lo = [v < .03 * top for v in vs]
    out, i = [], 0
    while i < n:
        j = i
        while j < n and not hi[j]:
            j += 1
        if j >= n:
            break
        a = j
        while a > 0 and not lo[a - 1]:
            a -= 1
        b = j
        while b < n and hi[b]:
            b += 1
        c = b
        while c < n and not lo[c]:
            c += 1
        out.append([round(ts[a], 2), round(ts[j], 2), round(ts[min(b, n - 1)], 2),
                    round(ts[min(c, n - 1)], 2)])
        i = c + 1
    return out


# ── kit assembly ─────────────────────────────────────────────────────────

def cycle_of(rule, anim):
    """Training cycle (seconds, offset, phases) for a counted kit."""
    if 'phases' in rule:  # training parameters override the measured default
        phases = [{'id': p, 'seconds': s, **({'cue': c} if c else {})}
                  for p, s, c in rule['phases']]
        # the 3-2-1 inside a long hold is spoken by the app; nothing else to add
        return {'seconds': r2(sum(p['seconds'] for p in phases)), 'offset': 0.0,
                'phases': phases, 'source': 'training parameters (kit_rules phases)'}
    reps = anim['reps']
    per_loop = rule.get('loop_reps') or len(reps)
    cyc = anim['loopSeconds'] / per_loop
    a, j, b, c = reps[0]
    go, hold, back = r2(j - a), r2(b - j), r2(c - b)
    rest = r2(cyc - go - hold - back)
    go_cue = rule['go']
    phases = [{'id': 'go', 'seconds': go, 'cue': go_cue},
              {'id': 'hold', 'seconds': hold}]
    if rule['kind'] == 'rep_hold':
        # said a beat into the hold so "一，抬起" has room before it
        phases[1]['cue'] = rule['hold_cue']
        phases[1]['cueAt'] = HOLD_CUE_AT
    phases += [{'id': 'back', 'seconds': back, 'cue': rule['back']}]
    if rest > 0:
        phases.append({'id': 'rest', 'seconds': rest})
    return {'seconds': r2(cyc), 'offset': a, 'phases': phases,
            'source': f"measured: track '{anim['track']}' 3 %/97 % crossings, rep 1 of {per_loop}"}


def words_of(kit):
    keys = []
    for p in (kit['training'].get('cycle') or {}).get('phases', []):
        c = p.get('cue')
        keys += c if isinstance(c, list) else ([c] if c else [])
    return keys


def build_kit(d, rule, anim, spec, old):
    did = d['id']
    point_zh, name_en, point_en = VL.DRILLS[did]  # seed for a new kit
    if old:  # the kit is the source once it exists
        name_en = old['display']['name']['en']
        point_zh, point_en = old['display']['point']['zh'], old['display']['point']['en']
    kind = rule['kind']
    sided = rule['sided']
    media = d['media']
    training = {
        'kind': kind,
        'unit': 'seconds' if kind == 'hold' else 'reps',
        'sided': sided,
        'leadSeconds': LEAD_SECONDS,
        'defaults': {'reps': rule.get('reps'), 'sets': 1, 'seconds': rule.get('seconds'),
                     'holdSeconds': rule.get('hold'), 'restSeconds': 15},
    }
    if kind == 'hold':
        if anim['reps']:
            a, j, _, _ = anim['reps'][0]
            training['hold'] = {'entrySeconds': r2(j - a)}
        else:
            training['hold'] = {'entrySeconds': 2.0}
    else:
        training['cycle'] = cycle_of(rule, anim)
    methods = d['methods'] or ['relax']
    kit = {
        'schema': SCHEMA,
        'id': did,
        'display': {
            'name': {'zh': d['name'], 'en': name_en},
            'point': {'zh': point_zh, 'en': point_en},
            'cautions': d.get('cautions') or [],
            'targets': d['directions'],
            'methods': d['methods'],
            'level': d['level'],
            'sided': sided,
            'firstSide': 'right' if sided else None,
            'poster': {'dark': media.get('poster'), 'light': None},
        },
        'media': {
            'poseHub': {'version': spec[0], 'spec': spec[1], 'specSha256': spec[2]},
            'video': {
                'dark': {'asset': media.get('video'), 'loopSeconds': media.get('duration_seconds'),
                         'posterTime': media.get('poster_time_seconds')},
                'light': None,
            },
        },
        'animation': {**anim, 'source': 'Pose-Hub spec timeline (measured)'},
        'training': training,
        'voice': {
            'lines': {},
            'prepare': [f'drill.{did}', f'point.{did}'],
            'go': 'p.go',
            'count': 'n.{k}',
            'lastRep': 'p.last_rep',
            'nextSet': 'p.again',
            'end': 'p.release' if kind == 'hold' else 'p.nice',
            'switch': {'left': 'p.switch_left', 'right': 'p.switch_right'},
            'firstSide': 'p.right_first' if sided else None,
            'coach': [f'cue.{methods[0]}.1', f'cue.{methods[0]}.2'],
            'midHold': ({'half': 'p.half', 'last10': 'p.last10', 'countdown': 5}
                        if kind == 'hold' else None),
        },
        'review': {'why': rule['why'], 'flags': [rule['flag']] if rule.get('flag') else []},
    }
    lines = {f'drill.{did}': {'zh': d['name'], 'en': name_en},
             f'point.{did}': {'zh': point_zh, 'en': point_en}}
    for w in words_of(kit):
        zh, en = K.WORDS[w]
        lines[w] = {'zh': zh, 'en': en}
    kit['voice']['lines'] = lines
    return kit


def cmd_build(a):
    content = json.loads(CONTENT.read_text(encoding='utf-8'))
    specs = frozen_specs()
    olds = {p.stem: json.loads(p.read_text(encoding='utf-8'))
            for p in KITS.glob('*.json') if p.stem != 'index'}
    if a.pose_hub:
        anims = measure(a.pose_hub, specs)
    else:
        anims = {}
        for i, (_, _, sha) in specs.items():
            o = olds.get(i)
            if not o or o['media']['poseHub']['specSha256'] != sha:
                raise SystemExit(f'{i}: no stored measurement for the frozen spec; pass --pose-hub')
            anims[i] = {k: v for k, v in o['animation'].items() if k != 'source'}
    KITS.mkdir(parents=True, exist_ok=True)
    ids = []
    for d in content['drills']:
        did = d['id']
        if did not in K.RULES:
            raise SystemExit(f'{did}: missing from kit_rules.RULES')
        kit = build_kit(d, K.RULES[did], anims[did], specs[did], olds.get(did))
        (KITS / f'{did}.json').write_text(json.dumps(kit, ensure_ascii=False, indent=1) + '\n',
                                          encoding='utf-8')
        ids.append(did)
    index = {'schema': 'action-kit-index@1', 'poseHub': specs[ids[0]][0],
             'kits': [f'assets/action_kits/{i}.json' for i in sorted(ids)]}
    (KITS / 'index.json').write_text(json.dumps(index, indent=1) + '\n', encoding='utf-8')
    print(f'wrote {len(ids)} kits to {KITS}')


# ── routine overrides (shared with build_hip_content.py) ─────────────────

def override_of(dose, kit):
    """Routine step dose → kit override {reps, holdSeconds, seconds}."""
    s = re.sub(r'（.*?）', '', dose).strip()
    kind = kit['training']['kind']
    m = re.search(r'停 (\d+) 秒$', s)
    hold = int(m.group(1)) if m and '次' in s else None
    m = re.search(r'(\d+) 次 × (\d+) 秒$', s)  # 停 3 次 × 10 秒
    if m:
        return {'reps': int(m.group(1)), 'holdSeconds': int(m.group(2))}
    m = re.search(r'开 (\d+)(?: 次)? \+ 关 (\d+)', s)
    if m:
        return {'reps': int(m.group(1)) + int(m.group(2))}
    m = re.search(r'正反各 (\d+) 圈$', s) or re.search(r'(\d+) (?:次|圈)', s)
    if m and kind != 'hold':
        out = {'reps': int(m.group(1))}
        if hold:
            out['holdSeconds'] = hold
        return out
    m = re.search(r'(\d+) 秒$', s)
    if m:
        return {'seconds': int(m.group(1))}
    return {}


def cycle_seconds(kit, hold=None):
    cyc = kit['training']['cycle']
    total = 0.0
    for p in cyc['phases']:
        total += hold if (hold is not None and p['id'] == 'hold') else p['seconds']
    return total


def side_seconds(kit, ov, budget):
    """Seconds of one side (or the whole unsided set). Holds: the dose
    seconds (or the budget). Counted kits keep the routine's time when every
    rep fits in it at the kit's training pace – the reps are then slowed
    down to fill it (stretch, see stretch_phases) – and grow to the lead plus
    every rep in full when they do not (the dose is never cut). The demo
    video does not enter this: it only loops. Same formula as
    ActionKit.sideSeconds in lib/hip/domain/action_kit.dart."""
    t = kit['training']
    if t['kind'] == 'hold':
        return ov.get('seconds') or budget
    reps = ov.get('reps') or t['defaults']['reps']
    hold = ov.get('holdSeconds') or t['defaults'].get('holdSeconds')
    need = math.ceil(t['leadSeconds'] + reps * cycle_seconds(kit, hold) - 1e-9)
    return max(budget, need)


def stretch_phases(kit, phases, target):
    """Phases slowed to a cycle of `target` seconds (≥ their sum). The
    movements (go / back) keep the kit's training speed; the extra time goes to the
    pause at the top (60 %) and at the bottom (40 %). A loop (rep_cycle) is
    one continuous movement and slows down evenly. Mirrors
    ActionKit.stretch in Dart."""
    base = sum(p['seconds'] for p in phases)
    extra = target - base
    if extra <= 1e-9:
        return phases
    if kit['training']['kind'] == 'rep_cycle':
        f = target / base
        return [{**p, 'seconds': p['seconds'] * f} for p in phases]
    has_rest = any(p['id'] == 'rest' for p in phases)
    top = 0.0 if kit['training']['kind'] == 'rep_hold' else STRETCH_TOP  # 停 N 秒 stays N
    out = []
    for p in phases:
        add = 0.0
        if p['id'] == 'hold':
            add = extra * (top if has_rest else 1.0)
        elif p['id'] == 'rest' and has_rest:
            add = extra * (1 - top)
        out.append({**p, 'seconds': p['seconds'] + add})
    return out


# ── check ────────────────────────────────────────────────────────────────

def load_kits():
    idx = json.loads((KITS / 'index.json').read_text(encoding='utf-8'))
    return {Path(p).stem: json.loads((ROOT / p).read_text(encoding='utf-8')) for p in idx['kits']}


def problems():
    errs = []
    kits = load_kits()
    try:  # optional: pip install jsonschema
        import jsonschema
        schema = json.loads((Path(__file__).parent / 'action-kit-v1.schema.json').read_text())
        v = jsonschema.Draft202012Validator(schema)
        for i, k in kits.items():
            for err in v.iter_errors(k):
                errs.append(f"{i}: schema: {'/'.join(map(str, err.path))}: {err.message}")
    except ImportError:
        print('(jsonschema not installed: JSON-Schema step skipped, structural checks only)')
    specs = frozen_specs()
    voice = json.loads(VOICE.read_text(encoding='utf-8'))
    clips = voice['clips']
    content = json.loads(CONTENT.read_text(encoding='utf-8'))

    def ln(key, lang):
        ms = clips[lang].get(key)
        if ms is None:
            errs.append(f'voice clip {lang}/{key} missing')
            return 9.9
        return ms / 1000

    for i, k in kits.items():
        e = lambda m: errs.append(f'{i}: {m}')  # noqa: E731
        for f in ['schema', 'id', 'display', 'media', 'animation', 'training', 'voice', 'review']:
            if f not in k:
                e(f'missing {f}')
        if k.get('schema') != SCHEMA:
            e('schema')
        if k['id'] != i:
            e('id ≠ file name')
        if i not in specs:
            e('not a Pose-Hub action of the frozen release')
        elif k['media']['poseHub']['specSha256'] != specs[i][2]:
            e('stale: Pose-Hub spec changed, rebuild with --pose-hub')
        dsp = k['display']
        for f in ['name', 'point']:
            if not (dsp[f].get('zh') and dsp[f].get('en')):
                e(f'display.{f} needs zh and en')
        if not dsp['targets']:
            e('display.targets empty')
        if not k['media']['video']['dark']['asset']:
            e('no dark video')
        if 'light' not in k['media']['video']:
            e('video.light slot missing')
        t = k['training']
        if t['kind'] not in KINDS:
            e(f"kind {t['kind']}")
        v = k['voice']
        for key in v['prepare']:
            ln(key, 'zh'), ln(key, 'en')
        if t['kind'] == 'hold':
            if not t['defaults']['seconds']:
                e('hold without default seconds')
            continue
        cyc = t['cycle']
        s = sum(p['seconds'] for p in cyc['phases'])
        if abs(s - cyc['seconds']) > .051:
            e(f"phases sum {s:.2f} ≠ cycle {cyc['seconds']}")
        ids = [p['id'] for p in cyc['phases']]
        if ids[0] != 'go' or any(x not in PHASE_IDS for x in ids):
            e(f'phase ids {ids}')
        if not t['defaults']['reps']:
            e('counted kit without default reps')
        # every spoken line fits the window up to the next cue
        hold_over = t['defaults'].get('holdSeconds')
        phases = [dict(p) for p in cyc['phases']]
        for p in phases:
            if p['id'] == 'hold' and hold_over:
                p['seconds'] = hold_over
        starts, t0 = [], 0.0
        for p in phases:
            starts.append(t0)
            t0 += p['seconds']
        cycle = t0
        cue_times = [(n, starts[n] + phases[n].get('cueAt', 0)) for n, p in enumerate(phases)
                     if p.get('cue')]
        for lang in ('zh', 'en'):
            for idx, (n, at) in enumerate(cue_times):
                p = phases[n]
                nxt = cue_times[idx + 1][1] if idx + 1 < len(cue_times) else cycle
                window = nxt - at
                cues = p['cue'] if isinstance(p['cue'], list) else [p['cue']]
                for c in cues:
                    heads = [[]]
                    if n == 0:
                        heads = [[f'n.{r}'] for r in range(1, 11)] + [['p.last_rep']]
                    for h in heads:
                        need = sum(ln(x, lang) for x in h + [c]) + .06 * len(h)
                        if need > window - .1:
                            e(f"{lang} '{'+'.join(h + [c])}' {need:.2f}s > window {window:.2f}s")
                if p['id'] == 'hold' and p['seconds'] >= 6:
                    for c in cues:
                        if p.get('cueAt', 0) + ln(c, lang) + .2 > p['seconds'] - 3:
                            e(f'{lang} hold cue overlaps the 3-2-1')
    # routine coverage + durations
    drills = {d['id']: d for d in content['drills']}
    playable = set()
    for r in content['routines']:
        for st in r['steps']:
            playable.add(st['drill'])
            for alt in (st.get('alternative'), drills[st['drill']].get('alternative')):
                if alt:
                    playable.add(alt)
            kitref = st.get('kit')
            if not kitref or kitref.get('id') != st['drill']:
                errs.append(f"routine {r['id']} {st['drill']}: step has no kit reference")
                continue
            k = kits.get(st['drill'])
            if not k:
                continue
            want = side_seconds(k, kitref, st['seconds'] // (2 if st['sided'] else 1))
            got = st['seconds'] // (2 if st['sided'] else 1)
            if want != got:
                errs.append(f"routine {r['id']} {st['drill']}: step seconds {got}/side ≠ kit {want}")
            if st['sided'] != k['training']['sided']:
                errs.append(f"routine {r['id']} {st['drill']}: sided differs from kit")
    for i in sorted(playable):
        if i not in kits:
            errs.append(f'{i}: playable in a routine but has no action kit')
    return errs


def cmd_check(a):
    errs = problems()
    for x in errs:
        print('✗', x)
    print(f'{len(errs)} problem(s)')
    sys.exit(1 if errs else 0)


# ── overview ─────────────────────────────────────────────────────────────

KIND_ZH = {'rep_updown': '计数·双相起落', 'rep_cycle': '计数·正反循环', 'rep_alternate': '计数·左右交替',
           'rep_hold': '计数·带停留', 'rep_breath': '计数·呼吸配合', 'hold': '保持计时'}


def voice_summary(k, lang):
    t = k['training']
    L = k['voice']['lines']
    word = lambda w: L[w][lang] if w in L else w  # noqa: E731
    if t['kind'] == 'hold':
        return ('开始 → 要点 → 过半/还剩10秒 → 5-4-3-2-1 → 慢慢还原' if lang == 'zh'
                else 'Go → coaching → halfway / 10 s left → 5-4-3-2-1 → come out slowly')
    parts = []
    for p in t['cycle']['phases']:
        c = p.get('cue')
        label = '/'.join(word(x) for x in c) if isinstance(c, list) else (word(c) if c else '')
        head = ('{n}，' if lang == 'zh' else '{n}, ') if p['id'] == 'go' else ''
        if label:
            parts.append(f"{head}{label}({p['seconds']:.1f}s)")
        else:
            parts.append(f"…({p['seconds']:.1f}s)")
    return ' '.join(parts)


def cmd_overview(a):
    kits = load_kits()
    content = json.loads(CONTENT.read_text(encoding='utf-8'))
    uses = {}
    kits0 = load_kits()
    for r in content['routines']:
        for st in r['steps']:
            k = kits0[st['drill']]
            ov = st['kit']
            sides = 2 if st['sided'] else 1
            per = st['seconds'] // sides
            if k['training']['kind'] == 'hold':
                desc = f"{per}s"
            else:
                reps = ov.get('reps') or k['training']['defaults']['reps']
                hold = ov.get('holdSeconds') or k['training']['defaults'].get('holdSeconds')
                ph = [dict(p, seconds=hold if (hold and p['id'] == 'hold') else p['seconds'])
                      for p in k['training']['cycle']['phases']]
                cyc = sum(p['seconds'] for p in stretch_phases(k, ph, (per - LEAD_SECONDS) / reps))
                desc = f"{reps}×{cyc:.1f}s"
            uses.setdefault(st['drill'], []).append(
                f"{r['id']} {st['dose']} → {desc}{'/侧' if st['sided'] else ''}")
    out = Path(a.out)
    out.mkdir(parents=True, exist_ok=True)
    rows = []
    for i, k in sorted(kits.items()):
        t = k['training']
        cyc = t.get('cycle')
        rows.append({
            'id': i, 'name': k['display']['name']['zh'], 'name_en': k['display']['name']['en'],
            'kind': t['kind'], 'kind_zh': KIND_ZH[t['kind']], 'sided': '每侧' if t['sided'] else '双侧',
            'cycle_s': cyc['seconds'] if cyc else '',
            'phases': ' / '.join(f"{p['id']} {p['seconds']:.2f}" for p in cyc['phases']) if cyc else
            f"entry {t['hold']['entrySeconds']}",
            'default': (f"{t['defaults']['reps']} 次" if cyc else f"{t['defaults']['seconds']} 秒")
            + (f" × 停 {t['defaults']['holdSeconds']} 秒" if t['defaults'].get('holdSeconds') else ''),
            'voice_zh': voice_summary(k, 'zh'), 'voice_en': voice_summary(k, 'en'),
            'video_dark': k['media']['video']['dark']['asset'] or '',
            'video_light': k['media']['video']['light'] or '(待补)',
            'spec': k['media']['poseHub']['spec'],
            'routines': '; '.join(uses.get(i, [])) or '—',
            'why': k['review']['why'], 'flags': '; '.join(k['review']['flags']),
        })
    import csv
    with open(out / 'action-kits-overview.csv', 'w', newline='', encoding='utf-8-sig') as f:
        w = csv.DictWriter(f, fieldnames=list(rows[0]))
        w.writeheader()
        w.writerows(rows)
    cols = [('id', '动作 ID'), ('name', '名称'), ('kind_zh', '类型'), ('sided', '单双侧'),
            ('cycle_s', '每次周期 s'), ('phases', '相位（秒）'), ('default', '默认剂量'),
            ('voice_zh', '语音模板（中）'), ('voice_en', 'Voice (en)'), ('routines', '路线引用（覆盖参数）'),
            ('video_dark', '深色视频'), ('video_light', '浅色视频'), ('why', '依据'), ('flags', '待定')]
    th = ''.join(f'<th>{html.escape(c[1])}</th>' for c in cols)
    trs = ''.join('<tr>' + ''.join(f'<td>{html.escape(str(r[c[0]]))}</td>' for c in cols) + '</tr>'
                  for r in rows)
    (out / 'action-kits-overview.html').write_text(f"""<!doctype html><meta charset=utf-8>
<title>HipLab 动作包总览 · action-kit v1</title>
<style>body{{font:13px -apple-system,'PingFang SC','Noto Sans SC',sans-serif;margin:16px;color:#222}}
table{{border-collapse:collapse}}td,th{{border:1px solid #ddd;padding:4px 6px;vertical-align:top}}
th{{background:#f2f5f4;position:sticky;top:0}}tr:nth-child(even){{background:#fafafa}}
td:nth-child(8),td:nth-child(9){{min-width:260px}}</style>
<h2>HipLab 动作包总览（action-kit v1，{len(rows)} 个，Pose-Hub {kits[rows[0]['id']]['media']['poseHub']['version']}）</h2>
<p>每个动作一行：类型、每次周期与相位、默认剂量、语音模板、路线覆盖参数、视频引用。</p>
<p><b>原则</b>：训练参数（次数/时长/周期/相位/侧别）是唯一真源，语音按训练参数报；Pose-Hub 动画实测的相位只作缺省参考，可被训练参数覆盖；演示视频只循环示范，不要求与语音逐次对齐，也不因动画改剂量。“待定”列只记其他需人工决定的问题。</p>
<table><tr>{th}</tr>{trs}</table>""", encoding='utf-8')
    print(out / 'action-kits-overview.html')


def main():
    p = argparse.ArgumentParser()
    sub = p.add_subparsers(dest='cmd', required=True)
    b = sub.add_parser('build')
    b.add_argument('--pose-hub', help='3D-Pose-Hub checkout (drill-anim/specs)')
    sub.add_parser('check')
    o = sub.add_parser('overview')
    o.add_argument('--out', required=True)
    a = p.parse_args()
    {'build': cmd_build, 'check': cmd_check, 'overview': cmd_overview}[a.cmd](a)


if __name__ == '__main__':
    main()
