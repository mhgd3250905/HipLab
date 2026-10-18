#!/usr/bin/env python3
"""Turn transition captures into contact sheets and videos.

Input is what test_screens/hip_transition_capture_test.dart writes: one
folder per transition with f_000.png … and frames.json (60 fps).

  # every capture folder under DIR: <name>-sheet.jpg, <name>.mp4, <name>-slow.mp4
  python3 tools/transitions/render.py DIR

  # before/after comparison for each name present in both
  python3 tools/transitions/render.py --compare BEFORE AFTER OUT

  # one reel of every capture in DIR (normal speed, titled)
  python3 tools/transitions/render.py --reel DIR OUT.mp4

Needs Pillow and ffmpeg. Slow motion is 0.25× (60 fps frames shown at 15).
"""
import argparse
import json
import os
import shutil
import subprocess
import sys
import tempfile

from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
FONT = os.path.join(HERE, '..', '..', 'assets', 'fonts', 'NotoSansSC.ttf')


def font(size):
    try:
        return ImageFont.truetype(FONT, size)
    except OSError:
        return ImageFont.load_default()


def load(folder):
    with open(os.path.join(folder, 'frames.json')) as f:
        meta = json.load(f)
    return meta, [os.path.join(folder, fr['file']) for fr in meta['frames']]


def captures(root):
    return sorted(
        d for d in os.listdir(root)
        if os.path.isfile(os.path.join(root, d, 'frames.json')))


def label(img, text, size=18):
    d = ImageDraw.Draw(img)
    f = font(size)
    box = d.textbbox((0, 0), text, font=f)
    w, h = box[2] - box[0] + 12, box[3] - box[1] + 10
    d.rectangle([0, 0, w, h + 2], fill=(0, 0, 0))
    d.text((6, 3), text, font=f, fill=(255, 220, 60))
    return img


def sheet(folder, out, thumb_w=180, cols=8, every=1):
    meta, files = load(folder)
    frames = meta['frames'][::every]
    files = files[::every]
    first = Image.open(files[0])
    th = round(first.height * thumb_w / first.width)
    rows = (len(files) + cols - 1) // cols
    pad, head = 4, 36
    W = cols * (thumb_w + pad) + pad
    H = head + rows * (th + pad) + pad
    canvas = Image.new('RGB', (W, H), (40, 40, 40))
    ImageDraw.Draw(canvas).text(
        (8, 6), f"{meta['name']}  ·  {len(meta['frames'])} frames @ "
        f"{meta['fps']} fps", font=font(20), fill=(255, 255, 255))
    for i, (fr, path) in enumerate(zip(frames, files)):
        im = Image.open(path).convert('RGB').resize((thumb_w, th), Image.LANCZOS)
        label(im, f"#{fr['index']} {fr['ms']:.0f}ms", 15)
        canvas.paste(im, (pad + (i % cols) * (thumb_w + pad),
                          head + pad + (i // cols) * (th + pad)))
    canvas.save(out, quality=88)


def ffmpeg(args):
    subprocess.run(['ffmpeg', '-y', '-loglevel', 'error', *args], check=True)


def video(folder, out, fps, width=390, title=None):
    """Frames at [fps]; first frame held 0.4 s, last 0.6 s (real time)."""
    _, files = load(folder)
    tmp = tempfile.mkdtemp()
    try:
        for i, f in enumerate(files):
            im = Image.open(f).convert('RGB')
            im = im.resize((width, round(im.height * width / im.width) // 2 * 2),
                           Image.LANCZOS)
            if title:
                label(im, title, 16)
            im.save(os.path.join(tmp, f'{i:04d}.png'))
        ffmpeg(['-framerate', str(fps), '-i', os.path.join(tmp, '%04d.png'),
                '-vf', 'tpad=start_mode=clone:start_duration=0.4:'
                'stop_mode=clone:stop_duration=0.6',
                '-r', '60', '-c:v', 'libx264', '-pix_fmt', 'yuv420p',
                '-crf', '20', out])
    finally:
        shutil.rmtree(tmp)


def render_dir(root):
    for name in captures(root):
        folder = os.path.join(root, name)
        sheet(folder, os.path.join(root, f'{name}-sheet.jpg'))
        video(folder, os.path.join(root, f'{name}.mp4'), 60)
        video(folder, os.path.join(root, f'{name}-slow.mp4'), 15)
        print('rendered', name)


def compare(before, after, out, width=360):
    """Per name: a sheet with before/after rows at matching times, and
    side-by-side MP4s (normal + 0.25×)."""
    os.makedirs(out, exist_ok=True)
    for name in captures(before):
        if not os.path.isdir(os.path.join(after, name)):
            continue
        mb, fb = load(os.path.join(before, name))
        ma, fa = load(os.path.join(after, name))
        # Sheet: every 3rd frame (50 ms) of the longer capture, two rows.
        n = max(len(fb), len(fa))
        idx = list(range(0, n, 3))
        tw = 150
        th = round(Image.open(fb[0]).height * tw / Image.open(fb[0]).width)
        pad, head, side = 4, 34, 70
        W = side + len(idx) * (tw + pad) + pad
        H = head + 2 * (th + pad) + pad
        canvas = Image.new('RGB', (W, H), (40, 40, 40))
        d = ImageDraw.Draw(canvas)
        d.text((8, 6), f'{name}: 上 = 修改前，下 = 修改后（每 50 ms 一格）',
               font=font(19), fill=(255, 255, 255))
        for r, (files, tag) in enumerate([(fb, '修改前'), (fa, '修改后')]):
            d.text((8, head + r * (th + pad) + th // 2 - 10), tag,
                   font=font(17), fill=(255, 220, 60))
            for c, i in enumerate(idx):
                path = files[min(i, len(files) - 1)]
                im = Image.open(path).convert('RGB').resize((tw, th),
                                                            Image.LANCZOS)
                label(im, f'{i * 1000 / 60:.0f}ms', 13)
                canvas.paste(im, (side + pad + c * (tw + pad),
                                  head + pad + r * (th + pad)))
        canvas.save(os.path.join(out, f'{name}-compare.jpg'), quality=88)
        # Side-by-side video.
        tmp = tempfile.mkdtemp()
        try:
            for i in range(n):
                pair = []
                for files, tag in [(fb, '修改前'), (fa, '修改后')]:
                    im = Image.open(files[min(i, len(files) - 1)]).convert('RGB')
                    im = im.resize((width, round(im.height * width / im.width)
                                    // 2 * 2), Image.LANCZOS)
                    pair.append(label(im, f'{tag}  {i * 1000 / 60:.0f}ms', 16))
                both = Image.new('RGB', (width * 2 + 8, pair[0].height),
                                 (255, 255, 255))
                both.paste(pair[0], (0, 0))
                both.paste(pair[1], (width + 8, 0))
                both.save(os.path.join(tmp, f'{i:04d}.png'))
            for fps, suffix in [(60, ''), (15, '-slow')]:
                ffmpeg(['-framerate', str(fps), '-i',
                        os.path.join(tmp, '%04d.png'),
                        '-vf', 'tpad=start_mode=clone:start_duration=0.5:'
                        'stop_mode=clone:stop_duration=0.8',
                        '-r', '60', '-c:v', 'libx264', '-pix_fmt', 'yuv420p',
                        '-crf', '20',
                        os.path.join(out, f'{name}-side-by-side{suffix}.mp4')])
        finally:
            shutil.rmtree(tmp)
        print('compared', name)


def reel(root, out):
    tmp = tempfile.mkdtemp()
    try:
        parts = []
        for name in captures(root):
            p = os.path.join(tmp, f'{name}.mp4')
            video(os.path.join(root, name), p, 60, title=name)
            parts.append(p)
        lst = os.path.join(tmp, 'list.txt')
        with open(lst, 'w') as f:
            f.writelines(f"file '{p}'\n" for p in parts)
        ffmpeg(['-f', 'concat', '-safe', '0', '-i', lst, '-c', 'copy', out])
    finally:
        shutil.rmtree(tmp)
    print('reel', out)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--compare', nargs=3, metavar=('BEFORE', 'AFTER', 'OUT'))
    ap.add_argument('--reel', nargs=2, metavar=('DIR', 'OUT'))
    ap.add_argument('dir', nargs='?')
    a = ap.parse_args()
    if a.compare:
        compare(*a.compare)
    elif a.reel:
        reel(*a.reel)
    elif a.dir:
        render_dir(a.dir)
    else:
        ap.print_help()
        sys.exit(2)


if __name__ == '__main__':
    main()
