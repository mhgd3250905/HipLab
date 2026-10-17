#!/usr/bin/env python3
"""Deterministic iOS AppIcon + launch-image export from the approved icon.

Run from the repo root:  python3 tools/ios/export_ios_icons.py   (needs Pillow)

Source: design/app-icon/launcher-20261017/foreground-source.png – the same
transparent "B 站姿开髋" foreground the Android launcher icon was exported
from (tools/export_android_icons.cjs). No generative or retouching step.

* AppIcon: the figure is centred by its visible (alpha >= 8) bounds and
  scaled so its farthest visible pixel sits at 128/144 of the half-size –
  the same proportion as the Android 72dp visible square – on the Android
  background #101316. Full-bleed opaque RGB squares: iOS applies its own
  corner mask, and the 1024 App Store icon must have no alpha channel.
  iPhone-only sizes (TARGETED_DEVICE_FAMILY = 1).
* LaunchImage: the figure alone (transparent), 120 pt at 1x/2x/3x, shown
  centred on the LaunchBackground colour, which follows the system
  appearance like the app's default theme (dark #0C0D0F / light #F4F5F3).
"""
from __future__ import annotations

import hashlib
import json
import math
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "design/app-icon/launcher-20261017/foreground-source.png"
ASSETS = ROOT / "ios/Runner/Assets.xcassets"
BACKGROUND = (0x10, 0x13, 0x16)
FILL = 128 / 144  # farthest visible pixel / half-size (Android parity)
ALPHA = 8
LAUNCH_PT = 120

# (size pt, scale) for iPhone + the marketing icon.
ICONS = [
    ("20x20", 2), ("20x20", 3),
    ("29x29", 2), ("29x29", 3),
    ("40x40", 2), ("40x40", 3),
    ("60x60", 2), ("60x60", 3),
]


def visible_geometry(img: Image.Image):
    a = img.getchannel("A")
    w, h = img.size
    px = a.load()
    xs, ys = [], []
    for y in range(h):
        for x in range(w):
            if px[x, y] >= ALPHA:
                xs.append(x)
                ys.append(y)
    cx = (min(xs) + max(xs)) / 2
    cy = (min(ys) + max(ys)) / 2
    radius = max(math.hypot(x - cx, y - cy) for x, y in zip(xs, ys))
    return cx, cy, radius


def place(fg: Image.Image, geo, size: int, fill: float, background):
    cx, cy, radius = geo
    scale = (size / 2) * fill / radius
    w, h = round(fg.width * scale), round(fg.height * scale)
    resized = fg.resize((w, h), Image.LANCZOS)
    canvas = Image.new("RGBA", (size, size), background + (255,) if background else (0, 0, 0, 0))
    left = round(size / 2 - cx * scale)
    top = round(size / 2 - cy * scale)
    canvas.alpha_composite(resized, (left, top))
    return canvas


def save(img: Image.Image, path: Path, manifest: list):
    path.parent.mkdir(parents=True, exist_ok=True)
    img.save(path, optimize=True)
    data = path.read_bytes()
    manifest.append({
        "file": str(path.relative_to(ROOT)),
        "pixels": f"{img.width}x{img.height}",
        "mode": img.mode,
        "bytes": len(data),
        "sha256": hashlib.sha256(data).hexdigest(),
    })


def main():
    fg = Image.open(SOURCE).convert("RGBA")
    geo = visible_geometry(fg)
    manifest: list = []

    icon_dir = ASSETS / "AppIcon.appiconset"
    for old in icon_dir.glob("*.png"):
        old.unlink()
    master = place(fg, geo, 1024, FILL, BACKGROUND).convert("RGB")
    save(master, icon_dir / "AppIcon-1024.png", manifest)
    images = [{
        "idiom": "universal", "platform": "ios", "size": "1024x1024",
        "filename": "AppIcon-1024.png",
    }]
    written = {}
    for size, scale in ICONS:
        px = round(float(size.split("x")[0]) * scale)
        name = f"AppIcon-{px}.png"
        if px not in written:
            # Render each size from the vector-free master by direct resample
            # of the 1024 (one generation, LANCZOS) to keep edges crisp.
            save(master.resize((px, px), Image.LANCZOS), icon_dir / name, manifest)
            written[px] = name
        images.append({"idiom": "iphone", "size": size, "scale": f"{scale}x", "filename": name})
    images.append({"idiom": "ios-marketing", "size": "1024x1024", "scale": "1x",
                   "filename": "AppIcon-1024.png"})
    (icon_dir / "Contents.json").write_text(
        json.dumps({"images": images, "info": {"author": "xcode", "version": 1}},
                   ensure_ascii=False, indent=2) + "\n")

    launch_dir = ASSETS / "LaunchImage.imageset"
    for old in launch_dir.glob("*.png"):
        old.unlink()
    files = []
    for scale in (1, 2, 3):
        px = LAUNCH_PT * scale
        img = place(fg, geo, px, 1.0, None)
        name = "LaunchImage.png" if scale == 1 else f"LaunchImage@{scale}x.png"
        save(img, launch_dir / name, manifest)
        files.append({"idiom": "universal", "filename": name, "scale": f"{scale}x"})
    (launch_dir / "Contents.json").write_text(
        json.dumps({"images": files, "info": {"author": "xcode", "version": 1}},
                   indent=2) + "\n")

    color_dir = ASSETS / "LaunchBackground.colorset"
    color_dir.mkdir(exist_ok=True)

    def rgb(hexstr):
        return {"color-space": "srgb", "components": {
            "red": f"0x{hexstr[0:2]}", "green": f"0x{hexstr[2:4]}",
            "blue": f"0x{hexstr[4:6]}", "alpha": "1.000"}}

    (color_dir / "Contents.json").write_text(json.dumps({
        "colors": [
            {"idiom": "universal", "color": rgb("F4F5F3")},
            {"idiom": "universal", "appearances": [
                {"appearance": "luminosity", "value": "dark"}], "color": rgb("0C0D0F")},
        ],
        "info": {"author": "xcode", "version": 1},
    }, indent=2) + "\n")

    out = ROOT / "design/app-icon/launcher-20261017/ios-export-manifest.json"
    out.write_text(json.dumps({
        "source": str(SOURCE.relative_to(ROOT)),
        "source_sha256": hashlib.sha256(SOURCE.read_bytes()).hexdigest(),
        "background": "#101316",
        "fill_ratio": FILL,
        "alpha_threshold": ALPHA,
        "launch_point_size": LAUNCH_PT,
        "files": manifest,
    }, ensure_ascii=False, indent=2) + "\n")
    print(f"wrote {len(manifest)} images; manifest {out.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
