#!/usr/bin/env python3
"""Theme-matched action media for HipLab (light stage next to the dark one).

The dark clips/posters in assets/drill_media/ are Pose-Hub v0.2.0 releases
(alpha masters composited on the #101013 stage) and stay untouched. This tool
builds the *light* counterparts from the same alpha masters, so both themes
show frame-identical motion, and writes one manifest for both themes:

  assets/drill_media/light/hip-<id>.mp4   1080², H.264 High, light stage
  assets/drill_media/light/hip-<id>.jpg   540² poster at the drill's poster time
  assets/hip/assessment/light/<name>.webp self-test stills, same size as dark
  assets/hip/action-media.json            per action id: dark + light assets
                                          with SHA-256, bytes, size, duration,
                                          fps, frames and source provenance

Inputs are the transport ZIPs of the private Pose-Hub Drive archive (folder
1SYZ1Ww3LRpMX4MZOSZeV6gpWl0Tc7fJe), pinned by SHA-256 in
tools/media/themed_media_sources.json. Only ffmpeg/ffprobe and the Python
standard library are used; no new dependencies.

  # 1. (re)pin the sources from the archive catalog (catalog.json from Drive)
  python3 tools/media/build_themed_media.py plan --catalog /path/catalog.json
  # 2. download the listed ZIPs into one folder (gws / browser), then
  python3 tools/media/build_themed_media.py build --zips /path/zips [--jobs 2] [--only id,...]
  # 3. verify bundle + manifest (also run by test/hip/hip_action_media_test.dart)
  python3 tools/media/build_themed_media.py check

Re-running build is deterministic for a given ffmpeg/x264 build: same inputs,
same parameters -> same pixels; the manifest records the encoder settings.
"""
from __future__ import annotations

import argparse
import concurrent.futures as cf
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
import zipfile

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
SOURCES = os.path.join(ROOT, 'tools', 'media', 'themed_media_sources.json')
MANIFEST = os.path.join(ROOT, 'assets', 'hip', 'action-media.json')
CONTENT = os.path.join(ROOT, 'assets', 'hip', 'hip-content.json')
LOCK = os.path.join(ROOT, 'pose-hub.lock.json')
POSE_MANIFEST = os.path.join(ROOT, 'tools', 'pose-hub-manifest.json')

DRIVE_FOLDER = '1SYZ1Ww3LRpMX4MZOSZeV6gpWl0Tc7fJe'

# Stage colours. Dark is what Pose-Hub v0.2.0 rendered on (verified per clip
# by PSNR against the released video); light is HipPalette.light.mediaBackdrop.
# The light stage is a *neutral* grey on purpose: for R=G=B the BT.601 and
# BT.709 matrices give the same YCbCr (Cb=Cr=128), so the decoded stage equals
# the Flutter-painted backdrop even on a decoder that ignores the colour tags
# (a tinted #EEF0EE decoded as 601 came out #E7EDE7, a visible green box).
STAGE = {'dark': '101013', 'light': 'EFEFEF'}

# Light stage only: a soft drop shadow of the silhouette (incl. mat/props) so
# the light-grey hands and head keep an edge on the pale stage and the figure
# sits on the ground instead of floating. Values are for a 1080 canvas.
SHADOW = {'opacity': 0.14, 'sigma': 12, 'dy': 10}

VIDEO_ENCODE = {
    'codec': 'libx264', 'profile': 'high', 'preset': 'slow', 'crf': 22,
    'gop': 'whole clip (one keyframe, like the dark release)',
    'pix_fmt': 'yuv420p', 'matrix': 'bt709', 'range': 'tv',
}
POSTER_ENCODE = {'format': 'jpeg', 'size': 540, 'qscale': 4}
STILL_ENCODE = {'format': 'webp', 'quality': 82}

# Light assets sit beside the dark ones in a light/ folder (same file names).
def light_path(dark_asset: str) -> str:
    d, f = os.path.split(dark_asset)
    return f'{d}/light/{f}'


def sha256(path: str) -> str:
    h = hashlib.sha256()
    with open(path, 'rb') as f:
        for chunk in iter(lambda: f.read(1 << 20), b''):
            h.update(chunk)
    return h.hexdigest()


def run(cmd: list[str]) -> str:
    p = subprocess.run(cmd, capture_output=True, text=True)
    if p.returncode != 0:
        raise RuntimeError(f'{cmd[0]} failed ({p.returncode}):\n{p.stderr[-3000:]}')
    return p.stdout + p.stderr


def probe(path: str) -> dict:
    out = run(['ffprobe', '-v', 'error', '-print_format', 'json', '-show_streams',
               '-show_format', path])
    d = json.loads(out[:out.rindex('}') + 1])
    s = d['streams'][0]
    info = {'width': s['width'], 'height': s['height']}
    if s.get('codec_type') == 'video' and 'duration' in d['format'] and \
            s.get('codec_name') not in ('mjpeg', 'png', 'webp'):
        num, den = s['r_frame_rate'].split('/')
        info.update(durationSec=round(float(d['format']['duration']), 3),
                    fps=round(int(num) / int(den), 3),
                    frames=int(s.get('nb_frames') or 0))
    return info


def file_entry(rel: str, **extra) -> dict:
    path = os.path.join(ROOT, rel)
    e = {'asset': rel, 'sha256': sha256(path), 'bytes': os.path.getsize(path)}
    e.update(probe(path))
    e.update(extra)
    return e


def load_json(path: str):
    with open(path, encoding='utf-8') as f:
        return json.load(f)


def write_json(path: str, data) -> None:
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=1)
        f.write('\n')


# --------------------------------------------------------------------- plan

STILL_ORDER = ['a', 'b', 'c', 'front', 'back']  # pose-01.. in archive order


def cmd_plan(args) -> None:
    """Pin one ZIP per action used by the app from the Drive catalog."""
    catalog = load_json(args.catalog)
    lock = load_json(LOCK)
    ids = sorted({i for t in lock['targets'] for i in t['ids']})
    content = load_json(CONTENT)
    stills = {}  # archive id -> [still names]
    for item in content['assessment']['items']:
        for opt in item['options'] + item.get('follow_up', {}).get('options', []):
            name = os.path.splitext(os.path.basename(opt['image']))[0]
            stem, suffix = name.rsplit('-', 1)
            stills.setdefault(f'a-{stem}', {})[suffix] = opt['image']
    release = load_json(POSE_MANIFEST)['releases'][lock['poseHub']['version']]
    green = {i['id']: i['sha256'] for i in release['items']
             if i['variant'] == 'greenscreen'}
    alpha = {i['id']: i for i in release['items'] if i['variant'] == 'alpha'}
    out = {'schema': 'hiplab/themed-media-sources@1',
           'driveFolder': DRIVE_FOLDER, 'poseHub': lock['poseHub']['version'],
           'note': 'kind=registered entries of the Pose-Hub private archive; '
                   'video entries must match the frozen v0.2.0 greenscreen '
                   'master (same alpha masters as the dark release).',
           'videos': {}, 'stills': {}}
    reg = {e['actionId']: e for e in catalog['entries'] if e['kind'] == 'registered'}
    for i in ids:
        e = reg[i]
        if green.get(i) not in {g['sha256'] for g in e.get('greens', [])}:
            sys.exit(f'{i}: archive entry is not the frozen v{lock["poseHub"]["version"]} render')
        out['videos'][i] = {
            'zips': [{'file': t['fileName'], 'driveId': t['driveId'],
                      'sha256': t['sha256'], 'bytes': t['bytes']}
                     for t in sorted(e['transportFiles'], key=lambda t: t['partIndex'])],
            'alphaFrames': alpha[i]['frames'], 'alphaSha256': alpha[i]['sha256'],
            'greenSha256': green[i],
        }
    for sid, names in sorted(stills.items()):
        e = reg[sid]
        out['stills'][sid] = {
            'zips': [{'file': t['fileName'], 'driveId': t['driveId'],
                      'sha256': t['sha256'], 'bytes': t['bytes']}
                     for t in sorted(e['transportFiles'], key=lambda t: t['partIndex'])],
            'map': {f'pose-{n + 1:02d}': names[s]
                    for n, s in enumerate(STILL_ORDER) if s in names},
        }
    media_src = load_json(os.path.join(ROOT, 'tools', 'hip_content', 'source', 'hip-media.json'))
    out['cuts'] = {}
    for cid, m in sorted(_walk_cuts(media_src)):
        parent = m['source'].split('cut from ', 1)[1].split()[0]
        a, b = m['source_cut_seconds']
        fps = m.get('source_fps', 30)
        out['cuts'][cid] = {
            'parent': parent, 'startFrame': round(a * fps), 'frames': round((b - a) * fps),
            # The bundled dark cut came from an earlier 3D-Body batch of the
            # same spec (same timing, older highlight style): ~33 dB, not ~54.
            'minDarkPsnrDb': 30,
            'note': f'dark cut is {m["source"]} of an earlier batch '
                    f'({m.get("source_batch", "?").split(chr(92))[-1]}); light cut uses '
                    f'the same frames of the v{lock["poseHub"]["version"]} alpha masters',
        }
    write_json(SOURCES, out)
    print(f'pinned {len(out["videos"])} clips + {len(out["stills"])} still sets -> {SOURCES}')


def _walk_cuts(node):
    if isinstance(node, dict):
        for k, v in node.items():
            if isinstance(v, dict) and str(v.get('source', '')).startswith('cut from '):
                yield k, v
            else:
                yield from _walk_cuts(v)


# -------------------------------------------------------------------- build

def open_parts(zdir: str, zips: list[dict]) -> list[zipfile.ZipFile]:
    files = []
    for z in zips:
        p = os.path.join(zdir, z['file'])
        if not os.path.exists(p):
            raise FileNotFoundError(f'missing ZIP {z["file"]} (Drive id {z["driveId"]})')
        if os.path.getsize(p) != z['bytes'] or sha256(p) != z['sha256']:
            raise ValueError(f'{z["file"]}: SHA-256/size mismatch')
        files.append(zipfile.ZipFile(p))
    return files


def extract(zips: list[zipfile.ZipFile], want, dest: str) -> list[str]:
    """Extract members matching `want` and verify them against SHA256SUMS."""
    sums = {}
    for z in zips:
        for name in z.namelist():
            if name.endswith('SHA256SUMS.txt'):
                for line in z.read(name).decode().splitlines():
                    h, _, f = line.partition('  ')
                    sums[f.strip()] = h
    got = []
    for z in zips:
        for name in z.namelist():
            if want(name):
                z.extract(name, dest)
                p = os.path.join(dest, name)
                if sums.get(name) != sha256(p):
                    raise ValueError(f'{name}: not covered by / mismatching SHA256SUMS')
                got.append(name)
    return sorted(got)


def composite_graph(stage: str, shadow: bool, size: int = 1080) -> str:
    """Alpha master over a flat stage, composited in RGB (straight alpha).

    Everything stays RGB until the single final RGB->YUV conversion, so the
    stage lands on exact code values (a YUV overlay path shifted #EFEFEF to
    Y=219/V=127 instead of 221/128)."""
    bg = f'color=0x{stage}:s={size}x{size}:r=30,format=rgba[bg]'
    if not shadow:
        return f'{bg};[0]format=rgba[fg];[bg][fg]overlay=0:0:shortest=1:format=rgb'
    s = SHADOW
    return (f'[0]format=rgba,split[fg][m];[m]alphaextract,gblur=sigma={s["sigma"]}[sa];'
            f'color=black:s={size}x{size}:r=30,format=rgba[blk];[blk][sa]alphamerge,'
            f'colorchannelmixer=aa={s["opacity"]}[sh];{bg};'
            f'[bg][sh]overlay=0:{s["dy"]}:shortest=1:format=rgb,format=rgba[b2];'
            f'[b2][fg]overlay=0:0:shortest=1:format=rgb')


def psnr(a: str, b: str, frames: int | None = None) -> float:
    cmd = ['ffmpeg', '-v', 'info', '-i', a, '-i', b, '-lavfi', '[0][1]psnr']
    if frames:
        cmd += ['-frames:v', str(frames)]
    out = run(cmd + ['-f', 'null', '-'])
    m = re.search(r'PSNR y:([\d.inf]+)', out)
    return float(m.group(1)) if m and m.group(1) != 'inf' else 99.0


def render_light(pattern: str, start: int, n: int, poster_idx: int,
                 out_video: str, out_poster: str, alpha_sha: str) -> None:
    """Encode alpha frames [start, start+n) on the light stage + its poster."""
    os.makedirs(os.path.join(ROOT, os.path.dirname(out_video)), exist_ok=True)
    graph = (composite_graph(STAGE['light'], True) +
             f',scale=out_color_matrix={VIDEO_ENCODE["matrix"]}:out_range={VIDEO_ENCODE["range"]},'
             f'format={VIDEO_ENCODE["pix_fmt"]}')
    run(['ffmpeg', '-v', 'error', '-y', '-start_number', str(start), '-framerate', '30',
         '-i', pattern, '-filter_complex', graph, '-frames:v', str(n),
         '-c:v', 'libx264', '-profile:v', 'high', '-preset', VIDEO_ENCODE['preset'],
         '-crf', str(VIDEO_ENCODE['crf']), '-g', str(n), '-keyint_min', str(n),
         '-sc_threshold', '0', '-threads', '1',
         '-colorspace', 'bt709', '-color_primaries', 'bt709', '-color_trc', 'bt709',
         '-color_range', 'tv', '-movflags', '+faststart', '-an',
         '-metadata', f'comment=HipLab light stage #{STAGE["light"]} from Pose-Hub '
                      f'v0.2.0 alpha {alpha_sha[:12]}',
         os.path.join(ROOT, out_video)])
    size = probe(os.path.join(ROOT, light_to_dark(out_poster)))['width']
    run(['ffmpeg', '-v', 'error', '-y', '-i', pattern.replace('%04d', f'{poster_idx:04d}'),
         '-filter_complex', composite_graph(STAGE['light'], True).replace(':r=30', '') +
         f',scale={size}:{size}:flags=lanczos,format=yuvj420p',
         '-frames:v', '1', '-q:v', str(POSTER_ENCODE['qscale']),
         os.path.join(ROOT, out_poster)])


def light_to_dark(light_asset: str) -> str:
    return light_asset.replace('/light/', '/', 1)


def dark_psnr_of(pattern: str, start: int, dark_video: str, frames: int = 30) -> float:
    """Alpha frames over the dark stage vs the bundled dark clip (provenance)."""
    with tempfile.TemporaryDirectory(dir=os.path.dirname(os.path.dirname(pattern))) as t:
        recon = os.path.join(t, 'recon-dark.mp4')
        run(['ffmpeg', '-v', 'error', '-y', '-start_number', str(start), '-framerate', '30',
             '-i', pattern, '-filter_complex',
             composite_graph(STAGE['dark'], False) + ',format=yuv420p',
             '-frames:v', str(frames), '-c:v', 'libx264', '-preset', 'ultrafast', '-crf', '0',
             recon])
        return psnr(recon, os.path.join(ROOT, dark_video), frames)


def media_entry(media: dict, src_info: dict) -> dict:
    t = float(media.get('poster_time_seconds') or 0)
    dv, dp = media['video'], media['poster']
    return {
        'kind': 'video', 'source': src_info,
        'dark': {'video': file_entry(dv), 'poster': file_entry(dp, timeSec=t)},
        'light': {'video': file_entry(light_path(dv)),
                  'poster': file_entry(light_path(dp), timeSec=t)},
    }


def build_video(pid: str, src: dict, media: dict, cuts: list, zdir: str,
                work: str) -> dict:
    """One Pose-Hub clip (and any cuts the app takes from it)."""
    tmp = os.path.join(work, pid)
    shutil.rmtree(tmp, ignore_errors=True)
    os.makedirs(tmp)
    parts = open_parts(zdir, src['zips'])
    frames = extract(parts, lambda n: '/alpha/m-' in n and n.endswith('.png'), tmp)
    if len(frames) != src['alphaFrames']:
        raise ValueError(f'{pid}: {len(frames)} alpha frames, expected {src["alphaFrames"]}')
    pattern = os.path.join(tmp, os.path.dirname(frames[0]), 'm-%04d.png')
    n = len(frames)
    base = {'zips': [z['file'] for z in src['zips']],
            'zipSha256': [z['sha256'] for z in src['zips']],
            'alphaSha256': src['alphaSha256']}
    # Provenance: the alpha masters over the dark stage must reproduce the
    # released dark clip (same render, same timing).
    p = dark_psnr_of(pattern, 0, media['video'])
    if p < 40:
        raise ValueError(f'{pid}: alpha masters do not match the dark release (PSNR {p:.1f})')
    t = float(media.get('poster_time_seconds') or 0)
    render_light(pattern, 0, n, min(n - 1, round(t * 30)), light_path(media['video']),
                 light_path(media['poster']), src['alphaSha256'])
    out = {pid: media_entry(media, {**base, 'alphaFrames': n,
                                    'darkReleasePsnrDb': round(p, 1)})}
    for cut, cmedia in cuts:
        s0, cn = cut['startFrame'], cut['frames']
        if s0 + cn > n:
            raise ValueError(f'{cut["id"]}: cut beyond {pid} ({s0}+{cn}>{n})')
        cp = dark_psnr_of(pattern, s0, cmedia['video'])
        if cp < cut.get('minDarkPsnrDb', 40):
            raise ValueError(f'{cut["id"]}: cut does not match its dark clip (PSNR {cp:.1f})')
        ct = float(cmedia.get('poster_time_seconds') or 0)
        render_light(pattern, s0, cn, s0 + min(cn - 1, round(ct * 30)),
                     light_path(cmedia['video']), light_path(cmedia['poster']),
                     src['alphaSha256'])
        out[cut['id']] = media_entry(cmedia, {**base, 'cutOf': pid, 'startFrame': s0,
                                              'alphaFrames': cn,
                                              'darkReleasePsnrDb': round(cp, 1),
                                              'note': cut.get('note')})
    shutil.rmtree(tmp, ignore_errors=True)
    return out


def build_stills(sid: str, src: dict, zdir: str, work: str) -> dict:
    tmp = os.path.join(work, sid)
    shutil.rmtree(tmp, ignore_errors=True)
    os.makedirs(tmp)
    parts = open_parts(zdir, src['zips'])
    got = extract(parts, lambda n: '/stills/' in n and '/alpha/' in n, tmp)
    items = {}
    for name in got:
        pose = os.path.splitext(os.path.basename(name))[0]
        dark = src['map'].get(pose)
        if dark is None:
            continue
        size = probe(os.path.join(ROOT, dark))['width']
        out = light_path(dark)
        os.makedirs(os.path.join(ROOT, os.path.dirname(out)), exist_ok=True)
        run(['ffmpeg', '-v', 'error', '-y', '-i', os.path.join(tmp, name),
             '-filter_complex', composite_graph(STAGE['light'], True).replace(':r=30', '') +
             f',scale={size}:{size}:flags=lanczos',
             '-frames:v', '1', '-c:v', 'libwebp', '-quality', str(STILL_ENCODE['quality']),
             '-compression_level', '6', os.path.join(ROOT, out)])
        key = os.path.splitext(os.path.basename(dark))[0]
        items[key] = {'dark': file_entry(dark), 'light': file_entry(out),
                      'sourcePose': pose}
    missing = set(src['map'].values()) - {v['dark']['asset'] for v in items.values()}
    if missing:
        raise ValueError(f'{sid}: stills missing for {sorted(missing)}')
    shutil.rmtree(tmp, ignore_errors=True)
    return {'kind': 'stills', 'source': {'zips': [z['file'] for z in src['zips']],
                                        'zipSha256': [z['sha256'] for z in src['zips']]},
            'items': items}


def content_media(content: dict) -> dict:
    """video file name -> media block, for drills and assessment demo cuts."""
    out = {}
    for d in content['drills']:
        if d['media'].get('video'):
            out[os.path.basename(d['media']['video'])] = d['media']
    for item in content['assessment']['items']:
        m = (item.get('demo_media') or {}).get('media') or {}
        if m.get('video'):
            out[os.path.basename(m['video'])] = m
    return out


def cmd_build(args) -> None:
    src = load_json(SOURCES)
    by_video = content_media(load_json(CONTENT))
    only = set(args.only.split(',')) if args.only else None
    old = load_json(MANIFEST) if os.path.exists(MANIFEST) else {}
    actions = dict(old.get('actions', {}))
    stills = dict(old.get('stills', {}))
    os.makedirs(args.work, exist_ok=True) if args.work else None
    work = tempfile.mkdtemp(prefix='themed-media-', dir=args.work)
    jobs = []
    with cf.ThreadPoolExecutor(max_workers=args.jobs) as pool:
        for pid, s in src['videos'].items():
            cuts = [(dict(c, id=cid), by_video[f'hip-{cid}.mp4'])
                    for cid, c in src.get('cuts', {}).items() if c['parent'] == pid]
            if only and pid not in only and not any(c[0]['id'] in only for c in cuts):
                continue
            media = by_video[f'hip-{pid.lower()}.mp4']
            jobs.append((pid, 'v', pool.submit(build_video, pid, s, media, cuts,
                                               args.zips, work)))
        for sid, s in src['stills'].items():
            if only and sid not in only:
                continue
            jobs.append((sid, 's', pool.submit(build_stills, sid, s, args.zips, work)))
        failed = []
        for key, kind, fut in jobs:
            try:
                if kind == 'v':
                    actions.update(fut.result())
                else:
                    stills[key] = fut.result()
                print('ok', key, flush=True)
            except Exception as e:  # report all, fail at the end
                failed.append(key)
                print('FAIL', key, e, flush=True)
    shutil.rmtree(work, ignore_errors=True)
    write_manifest(src, actions, stills)
    if failed:
        sys.exit(f'{len(failed)} failed: {failed}')


def write_manifest(src: dict, actions: dict, stills: dict) -> None:
    data = {
        'schema': 'hiplab/action-media@1',
        'generatedBy': 'tools/media/build_themed_media.py',
        'poseHub': src['poseHub'],
        'driveFolder': src['driveFolder'],
        'stage': {k: f'#{v}' for k, v in STAGE.items()},
        'lightShadow': SHADOW,
        'encode': {'video': VIDEO_ENCODE, 'poster': POSTER_ENCODE, 'still': STILL_ENCODE},
        'actions': dict(sorted(actions.items())),
        'stills': dict(sorted(stills.items())),
    }
    write_json(MANIFEST, data)
    print('manifest ->', os.path.relpath(MANIFEST, ROOT))


# -------------------------------------------------------------------- check

def cmd_check(args) -> None:
    m = load_json(MANIFEST)
    content = load_json(CONTENT)
    problems = []
    entries = []
    for pid, a in m['actions'].items():
        for theme in ('dark', 'light'):
            for role in ('video', 'poster'):
                entries.append((f'{pid}.{theme}.{role}', a[theme][role]))
    for sid, s in m['stills'].items():
        for key, it in s['items'].items():
            for theme in ('dark', 'light'):
                entries.append((f'{sid}/{key}.{theme}', it[theme]))
    for label, e in entries:
        p = os.path.join(ROOT, e['asset'])
        if not os.path.exists(p):
            problems.append(f'{label}: missing {e["asset"]}')
        elif os.path.getsize(p) != e['bytes'] or sha256(p) != e['sha256']:
            problems.append(f'{label}: sha/bytes differ from manifest')
    videos = {a[t]['video']['asset'] for a in m['actions'].values() for t in ('dark', 'light')}
    for name, media in content_media(content).items():
        v = media['video']
        if v not in videos or light_path(v) not in videos:
            problems.append(f'{name}: no dark+light clip in manifest')
    still_assets = {it[t]['asset'] for s in m['stills'].values()
                    for it in s['items'].values() for t in ('dark', 'light')}
    for item in content['assessment']['items']:
        for opt in item['options'] + item.get('follow_up', {}).get('options', []):
            if opt['image'] not in still_assets or light_path(opt['image']) not in still_assets:
                problems.append(f'assessment {opt["image"]}: no dark+light still')
    for pid, a in m['actions'].items():
        dv, lv = a['dark']['video'], a['light']['video']
        for k in ('width', 'height', 'frames', 'durationSec', 'fps'):
            if dv.get(k) != lv.get(k):
                problems.append(f'{pid}: light {k}={lv.get(k)} != dark {dv.get(k)}')
    total = {t: sum(e['bytes'] for label, e in entries if f'.{t}' in label)
             for t in ('dark', 'light')}
    print(f'{len(m["actions"])} clips, {sum(len(s["items"]) for s in m["stills"].values())} stills; '
          f'bytes dark={total["dark"]:,} light={total["light"]:,}')
    if problems:
        print('\n'.join(problems))
        sys.exit(1)
    print('check ok')


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest='cmd', required=True)
    p = sub.add_parser('plan')
    p.add_argument('--catalog', required=True)
    p.set_defaults(fn=cmd_plan)
    b = sub.add_parser('build')
    b.add_argument('--zips', required=True)
    b.add_argument('--jobs', type=int, default=2)
    b.add_argument('--only')
    b.add_argument('--work', default=None, help='scratch dir (default: system temp)')
    b.set_defaults(fn=cmd_build)
    c = sub.add_parser('check')
    c.set_defaults(fn=cmd_check)
    args = ap.parse_args()
    args.fn(args)


if __name__ == '__main__':
    main()
