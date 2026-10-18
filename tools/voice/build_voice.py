#!/usr/bin/env python3
"""Pre-recorded voice coaching clips for HipLab (issue #13).

Offline and free: Microsoft neural voices via `edge-tts` (pip install
edge-tts; also pip install numpy), post-processed with ffmpeg + numpy:
cut leading/trailing silence only (40 ms lead, 80 ms tail kept, never cut
inside a line), one fixed gain per clip to -16 LUFS, look-ahead peak limit
at -2.5 dBFS, mono AAC in .m4a. Check the result with
tools/voice/audit_voice.py --raw (docs/voice-audit-2026-10-18.md).

    # 1) listen to candidate voices (writes a short coaching sample per voice)
    python3 tools/voice/build_voice.py samples --out /tmp/voice-samples

    # 2) build every clip the app needs into assets/voice/<lang>/ + manifest
    python3 tools/voice/build_voice.py build \
        --zh-voice zh-CN-XiaoxiaoNeural --en-voice en-US-JennyNeural

    # 3) a ~60 s mixed demo of a real session timeline (voice + chimes)
    python3 tools/voice/build_voice.py demo --lang zh --out /tmp/demo-zh.mp3

Changing voice = re-run `build` with other --*-voice values. Wording lives
in tools/voice/voice_lines.py; content lines (drill names, doses, routine
names, assessment items) come from assets/hip/hip-content.json. Only clips
whose text or voice changed are regenerated (cache in .voice-cache/).
"""
import argparse
import asyncio
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(Path(__file__).resolve().parent))
import voice_lines as L  # noqa: E402

CONTENT = ROOT / 'assets/hip/hip-content.json'
OUT = ROOT / 'assets/voice'
CACHE = ROOT / 'tools/voice/.voice-cache'
RAW_CACHE = ROOT / 'tools/voice/.raw-cache'
CHIMES = ROOT / 'assets/voice/chime'

DEFAULT_VOICE = {'zh': 'zh-CN-XiaoxiaoNeural', 'en': 'en-US-JennyNeural'}
RATE = {'zh': '+6%', 'en': '+4%'}
REST_SECONDS = 15


def _no_proxy_env():
    env = dict(os.environ)
    for k in list(env):
        if k.lower() in ('http_proxy', 'https_proxy', 'all_proxy'):
            env.pop(k)
    return env


# ── script ──────────────────────────────────────────────────────────────

def spoken_name(zh):
    zh = re.sub(r'(\d+)/(\d+)', r'\1 \2', zh)
    return re.sub(r'（(.*?)）', r'，\1', zh).replace('/', '、').strip('，')


def collect_lines():
    """key -> (zh, en), plus text lookups the app needs."""
    c = json.loads(CONTENT.read_text(encoding='utf-8'))
    lines = dict(L.PHRASES)
    for k in range(0, 11):
        lines[f'n.{k}'] = (L.NUMBERS_ZH[k], L.NUMBERS_EN[k])
    secs = {REST_SECONDS, 5, 10}
    doses, tips = {}, {}
    for r in c['routines']:
        base = re.sub(r'\s*\d+\s*分钟$', '', r['name'])
        lines[f"routine.{r['id']}"] = (spoken_name(base), L.ROUTINES_EN[r['id']])
        for s in r['steps']:
            secs.add(s['seconds'])
            if s['sided']:
                secs.add(s['seconds'] // 2)
                # tight-side extra (+50 %): half + extra
                secs.add(s['seconds'] // 2 + s['seconds'] // 2)
            d = s['dose']
            if d not in doses:
                doses[d] = f'dose.{len(doses) + 1:02d}'
                lines[doses[d]] = (L.dose_zh_spoken(d), L.dose_en(d))
            t = s.get('tip') or ''
            if t and t not in tips:
                tips[t] = f'tip.{len(tips) + 1:02d}'
                lines[tips[t]] = L.TIPS[t]
    for s in sorted(secs):
        lines[f'sec.{s}'] = L.seconds_text(s)
    for m in range(1, 31):
        lines[f'min.{m}'] = (f'{m} 分钟', f'{m} minute' + ('s' if m > 1 else ''))
    for d in c['drills']:
        point_zh, name_en, point_en = L.DRILLS[d['id']]
        lines[f"drill.{d['id']}"] = (spoken_name(d['name']), name_en)
        lines[f"point.{d['id']}"] = (point_zh, point_en)
    for i, item in enumerate(c['assessment']['items']):
        title_en, cue_en = L.ASSESSMENT_EN[item['id']]
        lines[f"a.item.{item['id']}"] = (
            f"{L.ASSESSMENT_ORDER_ZH[i]}，{item['title'].replace('/', ' ')}",
            f'{L.ASSESSMENT_ORDER_EN[i]}: {title_en}')
        lines[f"a.cue.{item['id']}"] = (item['cue'], cue_en)
    return lines, {'dose': doses, 'tip': tips}


# ── synthesis ───────────────────────────────────────────────────────────

async def _tts(text, voice, rate, mp3):
    import edge_tts
    for attempt in range(4):
        try:
            await edge_tts.Communicate(text, voice, rate=rate).save(str(mp3))
            if mp3.stat().st_size > 500:
                return
        except Exception as e:  # network hiccups
            if attempt == 3:
                raise RuntimeError(f'edge-tts failed for {text!r}: {e}')
        await asyncio.sleep(1.5 * (attempt + 1))


def _decoded_ms(path):
    return int(round(len(_decode(path)) / SR * 1000))


def _ffprobe_ms(path):
    out = subprocess.run(['ffprobe', '-v', 'error', '-show_entries', 'format=duration',
                          '-of', 'csv=p=0', str(path)], capture_output=True, text=True).stdout
    return int(round(float(out.strip()) * 1000))


# ── post-processing ──────────────────────────────────────────────────────
#
# History (docs/voice-audit-2026-10-18.md): v3 trimmed with silenceremove and
# normalised with loudnorm "linear" – which silently falls back to *dynamic*
# mode whenever the linear gain would break the true-peak limit, so volume
# rode up and down inside a phrase – and single words went through
# dynaudnorm (a frame-by-frame AGC). Result: −21…−13 LUFS across the set,
# peaks up to +2.3 dBTP (clipping after AAC), tails as short as 15 ms, and
# container lengths up to 90 ms longer than the audio.
#
# v4: cut only before the first and after the last sound (never inside),
# keep a short lead and a ~80 ms tail with tiny fades in the silence, one
# fixed gain per clip to −16 LUFS (measured on the clip looped to ≥ 3 s so
# single words get a real reading), then a look-ahead limiter at −2.5 dBFS
# that only touches the odd consonant peak. tools/voice/audit_voice.py gates
# the result.

SR = 44100
SILENCE_DB = -50.0   # 10 ms window below this = silence (only at the edges)
LEAD_S = 0.04        # silence kept before the first sound
TAIL_S = 0.08        # silence kept after the last sound
FADE_IN_S = 0.005
FADE_OUT_S = 0.02
TARGET_LUFS = -16.0
LIMIT_DB = -2.5
PROCESS_VERSION = 'v4.1'


def _decode(path):
    import numpy as np
    raw = subprocess.run(['ffmpeg', '-v', 'error', '-i', str(path), '-f', 'f32le', '-ac', '1',
                          '-ar', str(SR), '-'], capture_output=True, check=True).stdout
    return np.frombuffer(raw, dtype=np.float32).copy()


def edge_trim(x):
    """Cut the silence before the first and after the last sound only."""
    import numpy as np
    n = SR // 100
    k = len(x) // n
    w = x[:k * n].reshape(k, n)
    lvl = 20 * np.log10(np.maximum(np.sqrt(np.mean(w ** 2, axis=1)), 1e-9))
    loud = np.where(lvl > SILENCE_DB)[0]
    if len(loud) == 0:
        raise RuntimeError('clip has no audio')
    a = max(0, loud[0] * n - int(LEAD_S * SR))
    b = (loud[-1] + 1) * n + int(TAIL_S * SR)
    y = x[a:b]
    if b > len(x):  # source tail shorter than TAIL_S: pad with silence
        y = np.concatenate([y, np.zeros(b - len(x), dtype=np.float32)])
    fi, fo = int(FADE_IN_S * SR), int(FADE_OUT_S * SR)
    y[:fi] *= np.linspace(0, 1, fi, dtype=np.float32)
    y[-fo:] *= np.linspace(1, 0, fo, dtype=np.float32)
    return y


def loop_lufs(wav, seconds):
    """(integrated LUFS, true peak dBTP) of the clip repeated to ≥ 3 s (EBU R128 gates in
    400 ms blocks, so a single word measured once reads as nothing)."""
    loops = max(0, int(3 / max(seconds, .05)))
    err = subprocess.run(['ffmpeg', '-v', 'info', '-nostats', '-stream_loop', str(loops),
                          '-i', str(wav), '-af', 'ebur128=peak=true', '-f', 'null', '-'],
                         capture_output=True, text=True).stderr
    summ = err[err.rfind('Summary:'):]
    i = re.search(r'I:\s+(-?[\d.]+) LUFS', summ)
    p = re.search(r'Peak:\s+(-?[\d.]+|-inf) dBFS', summ)
    return float(i.group(1)), float(p.group(1)) if p and p.group(1) != '-inf' else -99.0


def _process(src, dst):
    """Edge-trim, one fixed gain to −16 LUFS, peak-limit, encode mono AAC."""
    y = edge_trim(_decode(src))
    with tempfile.TemporaryDirectory() as td:
        wav = Path(td) / 'a.wav'
        subprocess.run(['ffmpeg', '-v', 'error', '-y', '-f', 'f32le', '-ar', str(SR), '-ac', '1',
                        '-i', '-', '-c:a', 'pcm_f32le', str(wav)], input=y.tobytes(), check=True)
        gain = TARGET_LUFS - loop_lufs(wav, len(y) / SR)[0]
        limit_db = LIMIT_DB
        # Peak limiting can pull a peaky clip (a hissy final "s") a little
        # under target and the encoder can add a bit of peak: measure the
        # encoded clip and correct – still one fixed gain per clip.
        best = None
        for _ in range(6):
            limit = 10 ** (limit_db / 20)
            # The native AAC encoder at 64 kbit/s quantises the band above
            # ~12 kHz coarsely and overshoots peaks by ~3 dB on sibilants;
            # speech has nothing up there, so band-limit before the limiter
            # and the encoder.
            af = (f'volume={gain:.2f}dB,lowpass=f=12000:p=2,'
                  f'alimiter=limit={limit:.4f}:attack=5:release=50:level=0:latency=1')
            out = Path(td) / f'try{_}.m4a'
            subprocess.run(['ffmpeg', '-v', 'error', '-y', '-i', str(wav), '-af', af,
                            '-ar', str(SR), '-ac', '1', '-c:a', 'aac', '-b:a', '64k',
                            '-cutoff', '12000', '-movflags', '+faststart', str(out)], check=True)
            lufs, tp = loop_lufs(out, len(y) / SR)
            # score: loudness error, heavily penalising a peak over −1.2 dBTP
            score = abs(lufs - TARGET_LUFS) + 10 * max(0.0, tp + 1.2)
            if best is None or score < best[0]:
                best = (score, out)
            if abs(lufs - TARGET_LUFS) <= .3 and tp <= -1.2:
                break
            if tp > -1.2:
                limit_db -= tp + 1.6
            gain += TARGET_LUFS - lufs
        shutil.copyfile(best[1], dst)


def raw_path(text, voice, rate):
    """Unprocessed edge-tts render (shared with audit_voice.py)."""
    h = hashlib.sha1(f'{voice}|{rate}|{text}'.encode()).hexdigest()[:16]
    return RAW_CACHE / f'{h}.mp3'


async def synth_all(jobs, concurrency=6):
    """jobs: list of (text, voice, rate, dst). The raw render is cached in
    .raw-cache (re-processing needs no network), the processed clip in
    .voice-cache keyed by the processing version."""
    sem = asyncio.Semaphore(concurrency)
    CACHE.mkdir(parents=True, exist_ok=True)
    RAW_CACHE.mkdir(parents=True, exist_ok=True)
    done = 0

    def key(text, voice, rate):
        return hashlib.sha1(f'{voice}|{rate}|{text}|{PROCESS_VERSION}'.encode()).hexdigest()[:16]

    async def make(text, voice, rate):
        nonlocal done
        cached = CACHE / f'{key(text, voice, rate)}.m4a'
        if not cached.exists():
            raw = raw_path(text, voice, rate)
            async with sem:
                if not raw.exists() or raw.stat().st_size <= 500:
                    part = raw.with_suffix('.part.mp3')
                    await _tts(text, voice, rate, part)
                    os.replace(part, raw)
                tmp = cached.with_suffix('.tmp.m4a')
                await asyncio.to_thread(_process, raw, tmp)
                os.replace(tmp, cached)  # an interrupted build never caches half a clip
        done += 1
        if done % 50 == 0:
            print(f'  {done} unique clips', flush=True)

    # the same text can back two keys (e.g. a dose and a duration): make it once
    unique = {key(t, v, r): (t, v, r) for t, v, r, _ in jobs}
    await asyncio.gather(*(make(*u) for u in unique.values()))
    for t, v, r, dst in jobs:
        dst.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(CACHE / f'{key(t, v, r)}.m4a', dst)


# ── chimes (synthesised, no licensing questions) ────────────────────────

def build_chimes():
    CHIMES.mkdir(parents=True, exist_ok=True)
    specs = {
        # short tick under each countdown number
        'tick': 'sine=f=1320:d=0.07,afade=t=out:st=0.02:d=0.05,volume=0.5',
        # start: rising two-tone
        'start': ('sine=f=880:d=0.12[a];sine=f=1320:d=0.22[b];[a][b]concat=n=2:v=0:a=1,'
                  'afade=t=out:st=0.22:d=0.12,volume=0.6'),
        # end of a set: falling two-tone
        'end': ('sine=f=1320:d=0.12[a];sine=f=880:d=0.26[b];[a][b]concat=n=2:v=0:a=1,'
                'afade=t=out:st=0.24:d=0.14,volume=0.6'),
        # whole session finished: three-note arpeggio
        # 2 s of digital silence, looped during a session to keep the audio
        # session (and with it the training clock) alive in the background.
        'silence': 'anullsrc=r=44100:cl=mono,atrim=0:2',
        'finish': ('sine=f=784:d=0.14[a];sine=f=988:d=0.14[b];sine=f=1318:d=0.42[c];'
                   '[a][b][c]concat=n=3:v=0:a=1,afade=t=out:st=0.4:d=0.3,volume=0.6'),
    }
    for name, graph in specs.items():
        dst = CHIMES / f'{name}.m4a'
        subprocess.run(['ffmpeg', '-v', 'error', '-y', '-filter_complex', graph,
                        '-ar', '44100', '-ac', '1', '-c:a', 'aac', '-b:a', '64k', str(dst)],
                       check=True)
    return {n: _ffprobe_ms(CHIMES / f'{n}.m4a') for n in specs}


# ── commands ────────────────────────────────────────────────────────────

def cmd_build(a):
    lines, texts = collect_lines()
    voices = {'zh': a.zh_voice, 'en': a.en_voice}
    jobs = []
    for lang, idx in (('zh', 0), ('en', 1)):
        d = OUT / lang
        if d.exists():
            for f in d.glob('*.m4a'):
                f.unlink()
        for key, pair in lines.items():
            text = pair[idx]
            jobs.append((text, voices[lang], RATE[lang], d / f'{key}.m4a'))
    print(f'{len(lines)} lines × 2 languages')
    asyncio.run(synth_all(jobs))
    # the length the app schedules with = what actually decodes
    clips = {lang: {k: _decoded_ms(OUT / lang / f'{k}.m4a') for k in lines}
             for lang in ('zh', 'en')}
    chimes = build_chimes()
    manifest = {
        'schema': 1,
        'generated_by': 'tools/voice/build_voice.py',
        'voices': voices,
        'rest_seconds': REST_SECONDS,
        'clips': clips,
        'chimes': chimes,
        'texts': texts,
        'lines': {k: {'zh': v[0], 'en': v[1]} for k, v in sorted(lines.items())},
    }
    (OUT / 'manifest.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=1,
                                                  sort_keys=True) + '\n', encoding='utf-8')
    size = sum(f.stat().st_size for f in OUT.rglob('*.m4a'))
    print(f'wrote {OUT}/manifest.json, {size / 1024 / 1024:.1f} MB of clips')


SAMPLE = {
    'zh': ('下一个，青蛙式，停 60 秒。膝盖向两侧打开，脚尖朝外，臀部慢慢往后坐。'
           '准备，三，二，一，开始！呼气，再沉一点。还剩 10 秒。五，四，三，二，一。很好，休息 10 秒。'),
    'en': ('Next up, frog stretch, hold for 60 seconds. Knees wide, toes out, sit your hips back slowly. '
           'Get ready. Three, two, one, go! Breathe out and sink a little deeper. 10 seconds left. '
           'Five, four, three, two, one. Nice work. Rest for 10 seconds.'),
}
SAMPLE_VOICES = {
    'zh': ['zh-CN-XiaoxiaoNeural', 'zh-CN-YunxiNeural', 'zh-CN-YunjianNeural', 'zh-CN-XiaoyiNeural'],
    'en': ['en-US-AriaNeural', 'en-US-GuyNeural', 'en-US-JennyNeural', 'en-US-AndrewNeural'],
}


def cmd_samples(a):
    out = Path(a.out)
    out.mkdir(parents=True, exist_ok=True)

    async def run():
        for lang, voices in SAMPLE_VOICES.items():
            for v in voices:
                dst = out / f'sample-{v}.mp3'
                await _tts(SAMPLE[lang], v, RATE[lang], dst)
                print(dst)
    asyncio.run(run())


def cmd_demo(a):
    """Mix a real timeline (voice + chimes) into one mp3 using the clips."""
    manifest = json.loads((OUT / 'manifest.json').read_text(encoding='utf-8'))
    sys.path.insert(0, str(Path(__file__).resolve().parent))
    timeline = json.loads(Path(a.timeline).read_text(encoding='utf-8'))
    lang = a.lang
    inputs, filters = [], []
    end = a.start + a.seconds
    for i, ev in enumerate(e for e in timeline if a.start <= e['t'] <= end):
        path = (CHIMES / f"{ev['clip'][6:]}.m4a" if ev['clip'].startswith('chime.')
                else OUT / lang / f"{ev['clip']}.m4a")
        inputs += ['-i', str(path)]
        ms = int((ev['t'] - a.start) * 1000)
        filters.append(f'[{i}:a]adelay={ms}|{ms}[d{i}]')
    n = len(inputs) // 2
    graph = ';'.join(filters) + ';' + ''.join(f'[d{i}]' for i in range(n)) + \
        f'amix=inputs={n}:normalize=0:dropout_transition=0,atrim=0:{a.seconds},volume=1.0[out]'
    subprocess.run(['ffmpeg', '-v', 'error', '-y', *inputs, '-filter_complex', graph,
                    '-map', '[out]', '-ac', '2', '-ar', '44100', '-b:a', '128k', a.out], check=True)
    print(a.out)


def main():
    p = argparse.ArgumentParser()
    sub = p.add_subparsers(dest='cmd', required=True)
    b = sub.add_parser('build')
    b.add_argument('--zh-voice', default=DEFAULT_VOICE['zh'])
    b.add_argument('--en-voice', default=DEFAULT_VOICE['en'])
    s = sub.add_parser('samples')
    s.add_argument('--out', required=True)
    d = sub.add_parser('demo')
    d.add_argument('--lang', default='zh')
    d.add_argument('--timeline', required=True,
                   help='JSON list of {t, clip} from test/hip/voice_timeline_export_test.dart')
    d.add_argument('--start', type=float, default=0)
    d.add_argument('--seconds', type=float, default=60)
    d.add_argument('--out', required=True)
    a = p.parse_args()
    os.environ.clear()
    os.environ.update(_no_proxy_env())
    {'build': cmd_build, 'samples': cmd_samples, 'demo': cmd_demo}[a.cmd](a)


if __name__ == '__main__':
    main()
