#!/usr/bin/env python3
"""Import the safety-card hero art (issue #11) into assets/hip/onboarding/.

    python3 tools/onboarding_art/import_onboarding_art.py <art_dir> [A|B]

Expects `{01-pregnancy,02-surgery,03-injury}-{dark,light}-{A,B}.png` in
<art_dir> and writes `assets/hip/onboarding/<card id>-<dark|light>.webp`
(card ids from the content pack: pregnancy / surgery / acute). Switching to
set B is just re-running with `B`; the app code does not change.
"""
import sys
from pathlib import Path
from PIL import Image

CARDS = {'01-pregnancy': 'pregnancy', '02-surgery': 'surgery', '03-injury': 'acute'}

def main():
    src = Path(sys.argv[1])
    variant = (sys.argv[2] if len(sys.argv) > 2 else 'A').upper()
    out = Path(__file__).resolve().parents[2] / 'assets/hip/onboarding'
    out.mkdir(parents=True, exist_ok=True)
    for stem, card in CARDS.items():
        for theme in ('dark', 'light'):
            img = Image.open(src / f'{stem}-{theme}-{variant}.png').convert('RGB')
            if img.width > 1080:
                img = img.resize((1080, round(img.height * 1080 / img.width)), Image.LANCZOS)
            dst = out / f'{card}-{theme}.webp'
            img.save(dst, 'WEBP', quality=82, method=6)
            print(dst.name, img.size, dst.stat().st_size // 1024, 'KB')

if __name__ == '__main__':
    main()
