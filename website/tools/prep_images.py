"""One-off: convert app screenshots + real drill posters into small WebP files in website/src/img.
Screenshots come from the UI review renders (outside the repo); posters come from assets/drill_media in this repo."""
import os, sys
from PIL import Image
HERE = os.path.dirname(os.path.abspath(__file__)); WEB = os.path.dirname(HERE); REPO = os.path.dirname(WEB)
OUT = os.path.join(WEB, 'src', 'img'); os.makedirs(OUT, exist_ok=True)
UI = os.environ.get('UI_DIR', '/workspace/work/hiplab-ui-review/r2')
SHOTS = {  # name: (path, crop height of 786x1704 phone frame)
 'ui-check': 'm4/intro-radar-light.png', 'ui-routine': 'final/routine-light.png', 'ui-library': 'final/library-light.png',
 'ui-library-dark': 'final/library-dark.png', 'ui-groups': 'final/groups-light.png', 'ui-editor': 'final/editor-light.png',
 'ui-records': 'm4/records-light.png', 'ui-settings': 'final/settings-light.png'}
POSTERS = ['s-pigeon','s-lizard','s-frog','h-couch-stretch','o-seated-fig4','n-half-split','w-clamshell','h-9090-liftoff',
 'n-windshield','h-hip-gate','n-chair-wiper','glute-max-A','s-butterfly','s-9090','n-thomas-test','s-seated-fold','h-squat']
def save(im, name, w):
    im = im.copy(); im.thumbnail((w, 10000), Image.LANCZOS)
    p = os.path.join(OUT, f'{name}-{w}.webp'); im.save(p, 'WEBP', quality=80, method=6); return p, im.size
for n, rel in SHOTS.items():
    im = Image.open(os.path.join(UI, rel)).convert('RGB').crop((0, 0, 786, 1704))
    for w in (360, 640): print(save(im, n, w))
for d in POSTERS:
    im = Image.open(os.path.join(REPO, 'assets/drill_media', f'hip-{d.lower()}.jpg')).convert('RGB')
    for w in (280, 540): print(save(im, 'p-' + d.lower(), w))
# supine cross-over test demo poster
im = Image.open(os.path.join(REPO, 'assets/drill_media/hip-supine-cross-demo.jpg')).convert('RGB'); print(save(im, 'p-supine-cross', 280))
ic = Image.open(os.environ.get('ICON', '/workspace/work/sites/hiplab-draft/img/icon.png')).convert('RGBA')
for w in (96, 192):
    i2 = ic.resize((w, w), Image.LANCZOS); i2.save(os.path.join(OUT, f'icon-{w}.png'), optimize=True)
