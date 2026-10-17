#!/usr/bin/env python3
"""Sync drill clips from 3D-Body into HipLab and regenerate the content pack.

The drill animations are authored and rendered in the 3D-Body repository
(tools/drill-anim, scheme B / themes/glow-b.json). This script takes the
finished renders from its out/ directory and brings them into this app:

  <out>/<id>.mp4  (1080², qa PASS in <out>/metrics/<id>.json)
     -> assets/drill_media/hip-<id lower-case>.mp4   720×720 H.264 CRF 27, faststart, no audio
     -> assets/drill_media/hip-<id lower-case>.jpg   540×540 poster at the spec's stillAt
     -> tools/hip_content/source/hip-media.json      loop length + poster time + source
  then runs tools/hip_content/build_hip_content.py   -> assets/hip/hip-content.json

Only drills that the content pack knows (tools/hip_content/source/髋部动作表.csv)
are imported, so a 3D-Body out/ full of FlareLab renders is safe to point at.
Entries already in hip-media.json that are not in out/ are kept as they are.

Usage (from the repository root):
  python3 tools/sync_drill_media.py --dry-run                     # show what would change
  python3 tools/sync_drill_media.py                               # default ../3D-Body checkout
  python3 tools/sync_drill_media.py --threed-body ~/src/3D-Body   # another checkout
  python3 tools/sync_drill_media.py --out D:/renders/out --ids n-prone-ir s-pigeon
  python3 tools/sync_drill_media.py --size 1080 --crf 18 --poster-size 1080 --force
                                                                  # replace existing app clips in HD
  python3 tools/sync_drill_media.py --library                     # also refresh the FlareLab
                                                                  # library clips listed with "asset"

Needs ffmpeg and ffprobe on PATH.
Frame timing is preserved from the source; low-FPS renders are not duplicated to 30 FPS.
"""
import argparse
import csv
import hashlib
import io
import json
import os
import re
import shutil
import subprocess
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))
DM = os.path.join(ROOT, 'assets', 'drill_media')
SRC = os.path.join(ROOT, 'tools', 'hip_content', 'source')
MEDIA_JSON = os.path.join(SRC, 'hip-media.json')
CSV_PATH = os.path.join(SRC, '髋部动作表.csv')
BUILD = os.path.join(ROOT, 'tools', 'hip_content', 'build_hip_content.py')

# Self-test demo clips cut out of a longer drill loop: key -> (drill id, start s, end s, poster s).
DEMO_CUTS = {'supine-cross-demo': ('n-leg-circles', 7.2, 12.0, 2.6)}

RENDERED = '有（B 风格成片，第 1 阶段快速渲染）'
HD_MEDIA_NOTE = ('HipLab HD delivery: 46 source-QA-passed self-rendered training-human-v2 drills '
    'plus one dedicated assessment cut. Exact 1080 straight-alpha masters are composed on #101013 '
    'by 3D-Body tools/hiplab-render/export_app_delivery.py; Android clips are 1080x1080, true 30fps, '
    'H.264/yuv420p CRF18 without audio. Per-item metadata binds the selected source batch, result, '
    'alpha frames and delivery SHA. Refresh through tools/sync_drill_media.py --copy-ready --force '
    '--size 1080 --crf 18 --poster-size 1080; accepted ready clips are copied without re-encoding, '
    'and the assessment cut is cropped separately. No legacy library clips remain selected.')


def run(cmd):
    subprocess.check_call(cmd)


def duration(path):
    out = subprocess.check_output(['ffprobe', '-v', 'error', '-show_entries', 'format=duration',
                                   '-of', 'csv=p=0', path])
    return float(out.decode().strip())


def file_sha256(path):
    digest = hashlib.sha256()
    with open(path, 'rb') as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b''):
            digest.update(block)
    return digest.hexdigest()


def ready_deliveries(out, size, crf):
    """Validate the whole bound delivery before copying any App assets."""
    manifest_path = os.path.join(out, 'delivery.json')
    with open(manifest_path, encoding='utf-8') as handle:
        manifest = json.load(handle)
    if manifest.get('kind') != 'hiplab-android-exact-alpha' or manifest.get('all_complete') is not True:
        raise ValueError('--copy-ready requires a completed exact-alpha Android delivery')
    if (size, crf) != (1080, 18) or manifest['recipe'].get('size') != size or manifest['recipe'].get('crf') != crf:
        raise ValueError('--copy-ready requires matching --size 1080 --crf 18')
    if file_sha256(manifest['selection']) != manifest['selection_sha256']:
        raise ValueError('Delivery selection changed')
    with open(manifest['selection'], encoding='utf-8') as handle:
        selected = json.load(handle)
    if set(manifest['items']) != set(selected['app_ids']):
        raise ValueError('Delivery does not contain every selected App drill')
    selected_by_id = {row['id']: row for row in selected['items']}
    manifest_sha = file_sha256(manifest_path)
    entries = {}
    for sid, row in manifest['items'].items():
        if row['id'] != sid or row['video'] != sid + '.mp4' or row.get('pass') is not True or row.get('full_cpu_decode') is not True:
            raise ValueError('Invalid ready delivery identity/QA: ' + sid)
        if row.get('inherited_source_qa_status') != 'pass' or row.get('composition_qa_pass') is not True or row['recipe'] != manifest['recipe']:
            raise ValueError('Ready delivery source/recipe is not accepted: ' + sid)
        path = os.path.join(out, row['video'])
        if file_sha256(path) != row['sha256']:
            raise ValueError('Ready video SHA mismatch: ' + sid)
        with open(os.path.join(out, 'metrics', sid + '.json'), encoding='utf-8') as handle:
            if json.load(handle) != row:
                raise ValueError('Ready metrics differ from bound manifest: ' + sid)
        provenance = row['provenance']
        chosen = selected_by_id[sid]
        if (provenance['source_result_sha256'] != chosen['result_sha256'] or
                provenance['source_alpha_binding_sha256'] != chosen['alpha_binding_sha256'] or
                provenance['source_batch'] != chosen['batch'] or provenance['source_commit'] != chosen['source_commit']):
            raise ValueError('Ready source differs from selected master: ' + sid)
        if file_sha256(provenance['source_result']) != provenance['source_result_sha256']:
            raise ValueError('Ready source result changed: ' + sid)
        with open(provenance['source_result'], encoding='utf-8') as handle:
            source = json.load(handle)
        if (source.get('id') != sid or source.get('frames') != row['frames'] or source.get('fps') != 30 or
                source.get('inherited_source_qa_status') != 'pass' or source.get('inherited_source_qa', {}).get('pass') is not True or
                source.get('composition_qa_pass') is not True or source.get('video_validation', {}).get('full_cpu_decode') is not True):
            raise ValueError('Ready source result is not accepted: ' + sid)
        binding = hashlib.sha256(json.dumps([source['outputs'][f'alpha_{i}']['sha256']
            for i in range(source['frames'])], separators=(',', ':')).encode()).hexdigest()
        if binding != provenance['source_alpha_binding_sha256']:
            raise ValueError('Ready source alpha binding differs: ' + sid)
        probe = json.loads(subprocess.check_output(['ffprobe', '-v', 'error', '-count_frames',
            '-show_entries', 'stream=codec_type,codec_name,pix_fmt,width,height,r_frame_rate,avg_frame_rate,nb_read_frames:format=duration',
            '-of', 'json', path]))
        streams = probe.get('streams', [])
        if len(streams) != 1:
            raise ValueError('Ready clip must contain one video and no audio: ' + sid)
        stream = streams[0]
        keys = ('codec_type', 'codec_name', 'pix_fmt', 'width', 'height', 'r_frame_rate', 'avg_frame_rate', 'nb_read_frames')
        expected = ('video', 'h264', 'yuv420p', 1080, 1080, '30/1', '30/1', str(row['frames']))
        if tuple(stream.get(key) for key in keys) != expected or abs(float(probe['format']['duration']) - row['frames']/30) > .02:
            raise ValueError('Ready video codec/size/frame timing mismatch: ' + sid)
        entries[sid] = dict(row, delivery_sha256=manifest_sha)
    return entries


def copy_ready_video(src, dst, expected_sha256):
    temporary = dst + '.copy-ready.tmp'
    try:
        shutil.copyfile(src, temporary)
        if file_sha256(temporary) != expected_sha256:
            raise ValueError('Ready clip changed during copy: ' + src)
        os.replace(temporary, dst)
    finally:
        if os.path.exists(temporary):
            os.remove(temporary)


def ready_metadata(metadata, row):
    metadata.update(row['provenance'])
    metadata.update(source='Android exact-alpha delivery; ' + row['provenance']['source_batch'],
        source_delivery_sha256=row['delivery_sha256'], source_video_sha256=row['sha256'],
        copy_ready=True, background='#101013', source_frames=row['frames'], source_fps=30)
    return metadata


def encode(src, dst, ss=None, to=None, *, size=720, crf=27):
    cmd = ['ffmpeg', '-y', '-loglevel', 'error']
    if ss is not None:
        cmd += ['-ss', str(ss)]
    if to is not None:
        cmd += ['-to', str(to)]
    cmd += ['-i', src, '-an', '-vf', f'scale={size}:{size}:flags=lanczos',
            '-fps_mode', 'passthrough', '-c:v', 'libx264',
            '-preset', 'slow', '-crf', str(crf), '-pix_fmt', 'yuv420p', '-movflags', '+faststart', dst]
    run(cmd)


def poster(src, t, dst, *, size=540):
    run(['ffmpeg', '-y', '-loglevel', 'error', '-ss', f'{t:.3f}', '-i', src, '-frames:v', '1',
         '-vf', f'scale={size}:{size}:flags=lanczos', '-q:v', '4', dst])


def still_at(specs, drill_id):
    path = os.path.join(specs, drill_id + '.js')
    if not os.path.exists(path):
        return 1.0
    m = re.search(r'stillAt:\s*([0-9.]+)', open(path, encoding='utf-8').read())
    return float(m.group(1)) if m else 1.0


def known_drills():
    rows = csv.DictReader(open(CSV_PATH, encoding='utf-8-sig'))
    return {r['动作id'] for r in rows}


def passed(out, drill_id):
    metrics = os.path.join(out, 'metrics', drill_id + '.json')
    if not os.path.exists(metrics):
        return False
    try:
        return bool(json.load(open(metrics, encoding='utf-8')).get('pass'))
    except ValueError:
        return False


def update_csv(rendered_ids, dry, rendered_status=RENDERED):
    raw = open(CSV_PATH, encoding='utf-8-sig').read()
    rows = list(csv.reader(io.StringIO(raw)))
    head = rows[0]
    ci, ii = head.index('动画状态'), head.index('动作id')
    changed = 0
    for r in rows[1:]:
        if r and r[ii] in rendered_ids and r[ci] != rendered_status:
            r[ci] = rendered_status
            changed += 1
    if changed and not dry:
        buf = io.StringIO()
        csv.writer(buf, lineterminator='\n').writerows(rows)
        open(CSV_PATH, 'w', encoding='utf-8-sig', newline='\n').write(buf.getvalue())
    return changed


def image_size(value):
    try:
        size = int(value)
    except ValueError:
        raise argparse.ArgumentTypeError('size must be an even integer between 128 and 4096')
    if not 128 <= size <= 4096 or size % 2:
        raise argparse.ArgumentTypeError('size must be an even integer between 128 and 4096')
    return size


def crf_value(value):
    try:
        crf = int(value)
    except ValueError:
        raise argparse.ArgumentTypeError('CRF must be an integer between 0 and 51')
    if not 0 <= crf <= 51:
        raise argparse.ArgumentTypeError('CRF must be an integer between 0 and 51')
    return crf


def video_metadata(previous, secs, pt, source, encoded, args):
    # Keeping an existing video must not relabel it with a different render batch.
    metadata = {} if encoded else dict(previous or {})
    metadata.update(duration_seconds=secs, poster_time_seconds=pt,
                    source=source if encoded else metadata.get('source') or source)
    if encoded:
        metadata.update(encode_size=args.size, encode_crf=args.crf,
                        poster_size=args.poster_size, frame_timing='source')
        for name in ('source_commit', 'source_batch', 'source_pixel_ratio'):
            value = getattr(args, name)
            if value is not None:
                metadata[name] = value
    else:
        metadata['poster_size'] = args.poster_size
    return metadata


def parse_args(argv=None):
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--threed-body', default=os.path.join(ROOT, '..', '3D-Body'),
                    help='3D-Body checkout (default: ../3D-Body next to this repository)')
    ap.add_argument('--out', help='drill-anim render directory (default: <3D-Body>/tools/drill-anim/out)')
    ap.add_argument('--specs', help='drill-anim specs, for poster times (default: <3D-Body>/tools/drill-anim/specs)')
    ap.add_argument('--ids', nargs='*', help='only these drill ids')
    ap.add_argument('--force', action='store_true', help='re-encode even when the app copy is newer')
    ap.add_argument('--copy-ready', action='store_true',
                    help='validate delivery.json and copy accepted 1080/30fps CRF18 Android clips without re-encoding')
    ap.add_argument('--size', type=image_size, default=720,
                    help='square video size in pixels (even, 128-4096; default: 720); use --force to replace existing clips')
    ap.add_argument('--crf', type=crf_value, default=27,
                    help='H.264 CRF (0-51, lower is better; default: 27); use --force to replace existing clips')
    ap.add_argument('--poster-size', type=image_size, default=540,
                    help='square poster size in pixels (even, 128-4096; default: 540)')
    ap.add_argument('--source-commit', help='source Git commit recorded for newly encoded clips')
    ap.add_argument('--source-batch', help='render batch identity recorded for newly encoded clips')
    ap.add_argument('--source-pixel-ratio', help='source pixel ratio (for example 2), recorded for newly encoded clips')
    ap.add_argument('--library', action='store_true',
                    help='also copy the FlareLab library clips listed with "asset" from <3D-Body>/app/assets/drill_media')
    ap.add_argument('--dry-run', action='store_true', help='report only; change nothing')
    return ap.parse_args(argv)


def main(argv=None):
    a = parse_args(argv)

    print(f'video {a.size}x{a.size}, H.264 CRF {a.crf}, source frame timing; '
          f'poster {a.poster_size}x{a.poster_size}')

    tb = os.path.abspath(a.threed_body)
    out = os.path.abspath(a.out or os.path.join(tb, 'tools', 'drill-anim', 'out'))
    specs = os.path.abspath(a.specs or os.path.join(tb, 'tools', 'drill-anim', 'specs'))
    if not os.path.isdir(out):
        sys.exit(f'render directory not found: {out}')
    for tool in ('ffmpeg', 'ffprobe'):
        if not shutil.which(tool):
            sys.exit(f'{tool} is required on PATH')

    media = json.load(open(MEDIA_JSON, encoding='utf-8'))
    if a.copy_ready:
        media['_note'] = HD_MEDIA_NOTE
    videos = media['videos']
    wanted = known_drills()
    if a.ids:
        wanted &= set(a.ids)
    ready = ready_deliveries(out, a.size, a.crf) if a.copy_ready else {}

    rendered, skipped = [], []
    for drill_id in sorted(wanted):
        src = os.path.join(out, drill_id + '.mp4')
        if not os.path.exists(src):
            continue
        if not passed(out, drill_id):
            skipped.append(drill_id)
            continue
        name = 'hip-' + drill_id.lower()
        mp4, jpg = os.path.join(DM, name + '.mp4'), os.path.join(DM, name + '.jpg')
        stale = a.force or not os.path.exists(mp4) or os.path.getmtime(mp4) < os.path.getmtime(src)
        if a.copy_ready:
            stale = a.force or not os.path.exists(mp4) or file_sha256(mp4) != ready[drill_id]['sha256']
        print(f"{('copy  ' if a.copy_ready else 'encode') if stale else 'keep  '} {drill_id} -> assets/drill_media/{name}.mp4")
        rendered.append(drill_id)
        if a.dry_run:
            continue
        if stale:
            if a.copy_ready:
                copy_ready_video(src, mp4, ready[drill_id]['sha256'])
            else:
                encode(src, mp4, size=a.size, crf=a.crf)
        secs = round(duration(mp4), 2)
        pt = round(min(ready[drill_id]['poster_time_seconds'] if a.copy_ready else still_at(specs, drill_id), secs - 0.1), 2)
        poster(mp4, pt, jpg, size=a.poster_size)
        videos[drill_id] = video_metadata(videos.get(drill_id), secs, pt,
            f'3D-Body tools/drill-anim specs/{drill_id}.js, glow-B', stale, a)
        if a.copy_ready and file_sha256(mp4) == ready[drill_id]['sha256']:
            ready_metadata(videos[drill_id], ready[drill_id])

    for key, (drill_id, start, end, pt) in DEMO_CUTS.items():
        if drill_id not in rendered:
            continue
        print(f'cut    {key} from {drill_id} {start}-{end} s')
        if a.dry_run:
            continue
        src = os.path.join(out, drill_id + '.mp4')
        mp4, jpg = os.path.join(DM, f'hip-{key}.mp4'), os.path.join(DM, f'hip-{key}.jpg')
        encode(src, mp4, start, end, size=a.size, crf=a.crf)
        poster(mp4, pt, jpg, size=a.poster_size)
        videos[key] = video_metadata(videos.get(key), round(duration(mp4), 2), pt,
                                     f'cut from {drill_id} {start}-{end} s', True, a)
        if a.copy_ready:
            ready_metadata(videos[key], ready[drill_id])
            videos[key].update(copy_ready=False, source=f'cut from {drill_id} {start}-{end} s',
                               source_cut_seconds=[start, end], source_video_sha256=file_sha256(mp4),
                               assessment_cut_parent_video_sha256=ready[drill_id]['sha256'])

    if a.library:
        lib = os.path.join(tb, 'app', 'assets', 'drill_media')
        for drill_id, meta in sorted(videos.items()):
            asset = meta.get('asset')
            if not asset:
                continue
            for ext in ('mp4', 'jpg'):
                src = os.path.join(lib, f'{drill_id}.{ext}')
                if not os.path.exists(src):
                    print(f'missing library clip {src}')
                    continue
                print(f'copy   {drill_id}.{ext} -> assets/drill_media/{asset}.{ext}')
                if not a.dry_run:
                    shutil.copy2(src, os.path.join(DM, f'{asset}.{ext}'))

    if skipped:
        print('not qa PASS, left out:', ' '.join(skipped))
    if a.copy_ready:
        changed = update_csv(set(rendered), a.dry_run, '有（本机高清成片，1080×1080 / 30fps）')
    else:
        changed = update_csv(set(rendered), a.dry_run)
    print(f'{len(rendered)} drill-anim clips, {changed} action-table rows marked rendered')
    if a.dry_run:
        return
    with open(MEDIA_JSON, 'w', encoding='utf-8', newline='\n') as f:
        json.dump(media, f, ensure_ascii=False, indent=2, sort_keys=True)
        f.write('\n')
    run([sys.executable, BUILD])


if __name__ == '__main__':
    main()
