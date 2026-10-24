#!/usr/bin/env python3
"""Static checks for the HipLab iOS project (no Xcode needed).

Run from the repo root:  python3 tools/ios/check_ios_project.py

What it checks (the parts of `plutil -lint` / Xcode project loading that can
be reproduced on Linux):

* every XML plist under ios/ parses (Info.plist, PrivacyInfo.xcprivacy, ...),
  and Info.plist carries the keys the App Store build needs;
* InfoPlist.strings files are valid `"key" = "value";` strings tables;
* project.pbxproj is a well-formed OpenStep plist: balanced, unique object
  ids, every referenced id exists, every file reference resolves to a file
  in the repo (generated/ignored files excepted), resources are in the
  Runner target, and the build settings HipLab relies on are consistent;
* the asset catalog: AppIcon entries exist with the right pixel sizes and the
  1024 marketing icon has no alpha channel; colorsets are valid JSON;
* LaunchScreen.storyboard is well-formed XML and only names images/colors
  that exist in the asset catalog.

Exit code 0 = all good; failures are printed one per line.
"""
from __future__ import annotations

import json
import plistlib
import re
import struct
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
IOS = ROOT / "ios"
RUNNER = IOS / "Runner"
problems: list[str] = []


def fail(msg: str) -> None:
    problems.append(msg)


# ───────────────────────── OpenStep plist (pbxproj) ─────────────────────────

_TOKEN = re.compile(
    r"""\s*(?:
        (?P<comment>/\*.*?\*/|//[^\n]*)
      | (?P<punct>[{}()=;,])
      | "(?P<quoted>(?:[^"\\]|\\.)*)"
      | (?P<bare>[A-Za-z0-9_$/.:\-+<>]+)
    )""",
    re.S | re.X,
)


def tokenize(text: str):
    pos = 0
    if text.startswith("// !$*UTF8*$!"):
        pos = text.index("\n")
    while True:
        m = _TOKEN.match(text, pos)
        if not m or m.end() == pos:
            rest = text[pos:].strip()
            if rest:
                raise ValueError(f"unexpected text at offset {pos}: {rest[:40]!r}")
            return
        pos = m.end()
        if m.group("comment"):
            continue
        if m.group("punct"):
            yield ("p", m.group("punct"))
        elif m.group("quoted") is not None:
            yield ("s", m.group("quoted"))
        else:
            yield ("s", m.group("bare"))


def parse_openstep(text: str):
    toks = list(tokenize(text))
    i = 0

    def value():
        nonlocal i
        kind, tok = toks[i]
        if kind == "p" and tok == "{":
            i += 1
            d = {}
            while toks[i] != ("p", "}"):
                k = toks[i][1]
                if toks[i][0] != "s":
                    raise ValueError(f"bad key {toks[i]}")
                i += 1
                if toks[i] != ("p", "="):
                    raise ValueError(f"expected = after {k}")
                i += 1
                if k in d:
                    raise ValueError(f"duplicate key {k}")
                d[k] = value()
                if toks[i] != ("p", ";"):
                    raise ValueError(f"expected ; after value of {k}")
                i += 1
            i += 1
            return d
        if kind == "p" and tok == "(":
            i += 1
            arr = []
            while toks[i] != ("p", ")"):
                arr.append(value())
                if toks[i] == ("p", ","):
                    i += 1
                elif toks[i] != ("p", ")"):
                    raise ValueError("expected , or ) in array")
            i += 1
            return arr
        if kind == "s":
            i += 1
            return tok
        raise ValueError(f"unexpected token {tok!r}")

    root = value()
    if i != len(toks):
        raise ValueError("trailing tokens after root dictionary")
    return root


def ids_in(value, out: set[str]):
    if isinstance(value, dict):
        for v in value.values():
            ids_in(v, out)
    elif isinstance(value, list):
        for v in value:
            ids_in(v, out)
    elif isinstance(value, str) and re.fullmatch(r"[0-9A-F]{24}", value):
        out.add(value)


# Files Xcode references that `flutter` generates or that are git-ignored.
GENERATED = {
    "Flutter/Generated.xcconfig",
    "GeneratedPluginRegistrant.h",
    "GeneratedPluginRegistrant.m",
    "Flutter/ephemeral/Packages/FlutterGeneratedPluginSwiftPackage",
    "Runner.app",
    "RunnerTests.xctest",
}


def check_pbxproj():
    path = IOS / "Runner.xcodeproj" / "project.pbxproj"
    try:
        proj = parse_openstep(path.read_text(encoding="utf-8"))
    except Exception as e:  # noqa: BLE001
        fail(f"project.pbxproj does not parse: {e}")
        return
    objects = proj["objects"]
    referenced: set[str] = set()
    ids_in({k: v for k, v in proj.items() if k != "objects"}, referenced)
    for obj in objects.values():
        ids_in(obj, referenced)
    for ref in sorted(referenced - set(objects)):
        fail(f"pbxproj: id {ref} referenced but not defined")

    # Resolve group paths to check that file references exist on disk.
    parent: dict[str, str] = {}
    for oid, obj in objects.items():
        for child in obj.get("children", []):
            if child in parent:
                fail(f"pbxproj: {child} has two parent groups")
            parent[child] = oid

    def disk_path(oid: str) -> Path | None:
        parts = []
        cur = oid
        while cur in objects:
            o = objects[cur]
            if o.get("sourceTree") not in ("<group>", None):
                if o.get("sourceTree") == "BUILT_PRODUCTS_DIR":
                    return None
            if "path" in o:
                parts.append(o["path"])
            cur = parent.get(cur)
        return IOS.joinpath(*reversed(parts)) if parts else None

    for oid, obj in objects.items():
        if obj.get("isa") != "PBXFileReference":
            continue
        rel = obj.get("path", "")
        if rel in GENERATED or Path(rel).name in GENERATED:
            continue
        if obj.get("sourceTree") == "BUILT_PRODUCTS_DIR":
            continue
        p = disk_path(oid)
        if p is not None and not p.exists():
            fail(f"pbxproj: file reference {rel} → {p.relative_to(ROOT)} missing")

    for oid, obj in objects.items():
        if obj.get("isa") == "PBXBuildFile":
            ref = obj.get("fileRef") or obj.get("productRef")
            if ref not in objects:
                fail(f"pbxproj: build file {oid} points at missing {ref}")

    # The Runner target and its resources.
    runner = next(
        (o for o in objects.values()
         if o.get("isa") == "PBXNativeTarget" and o.get("name") == "Runner"),
        None,
    )
    if runner is None:
        fail("pbxproj: no Runner target")
        return
    resources = []
    for phase_id in runner["buildPhases"]:
        phase = objects[phase_id]
        if phase["isa"] == "PBXResourcesBuildPhase":
            for bf in phase["files"]:
                ref = objects[objects[bf]["fileRef"]]
                resources.append(ref.get("name") or ref.get("path"))
    for need in ("Assets.xcassets", "LaunchScreen.storyboard", "Main.storyboard",
                 "PrivacyInfo.xcprivacy", "InfoPlist.strings"):
        if need not in resources:
            fail(f"pbxproj: {need} is not in the Runner Copy Bundle Resources phase")

    # Variant groups (localized files) exist for every declared language.
    for obj in objects.values():
        if obj.get("isa") == "PBXVariantGroup" and obj.get("name") == "InfoPlist.strings":
            langs = {objects[c]["name"] for c in obj["children"]}
            if langs != {"zh-Hans", "en"}:
                fail(f"pbxproj: InfoPlist.strings languages {sorted(langs)}")
    project = next(o for o in objects.values() if o.get("isa") == "PBXProject")
    if "zh-Hans" not in project.get("knownRegions", []):
        fail("pbxproj: zh-Hans missing from knownRegions")

    # Build settings for the Runner target configurations.
    cfg_list = objects[runner["buildConfigurationList"]]
    seen = {}
    for cid in cfg_list["buildConfigurations"]:
        cfg = objects[cid]
        bs = cfg["buildSettings"]
        name = cfg["name"]
        seen[name] = bs
        if bs.get("PRODUCT_BUNDLE_IDENTIFIER") != "com.ugk.hipinterlude":
            fail(f"pbxproj: {name} bundle id {bs.get('PRODUCT_BUNDLE_IDENTIFIER')}")
        if bs.get("INFOPLIST_FILE") != "Runner/Info.plist":
            fail(f"pbxproj: {name} INFOPLIST_FILE {bs.get('INFOPLIST_FILE')}")
        if bs.get("ASSETCATALOG_COMPILER_APPICON_NAME") != "AppIcon":
            fail(f"pbxproj: {name} app icon set {bs.get('ASSETCATALOG_COMPILER_APPICON_NAME')}")
    if set(seen) != {"Debug", "Release", "Profile"}:
        fail(f"pbxproj: Runner configurations {sorted(seen)}")
    targets = set()
    families = set()
    for o in objects.values():
        if o.get("isa") == "XCBuildConfiguration":
            bs = o["buildSettings"]
            if "IPHONEOS_DEPLOYMENT_TARGET" in bs:
                targets.add(bs["IPHONEOS_DEPLOYMENT_TARGET"])
            if "TARGETED_DEVICE_FAMILY" in bs:
                families.add(bs["TARGETED_DEVICE_FAMILY"])
    if targets != {MIN_IOS}:
        fail(f"pbxproj: IPHONEOS_DEPLOYMENT_TARGET values {sorted(targets)} != {MIN_IOS}")
    if families != {"1"}:
        fail(f"pbxproj: TARGETED_DEVICE_FAMILY {sorted(families)} (expected iPhone only)")


MIN_IOS = "15.0"

# ───────────────────────── plists and strings ─────────────────────────


def check_plists():
    for p in sorted(IOS.rglob("*")):
        if any(part in ("Pods", "ephemeral", ".symlinks", "build") for part in p.parts):
            continue
        if p.suffix not in (".plist", ".xcprivacy", ".xcsettings"):
            continue
        try:
            with p.open("rb") as f:
                plistlib.load(f)
        except Exception as e:  # noqa: BLE001
            fail(f"{p.relative_to(ROOT)}: not a valid plist ({e})")

    info = plistlib.loads((RUNNER / "Info.plist").read_bytes())
    want = {
        "CFBundleIdentifier": "$(PRODUCT_BUNDLE_IDENTIFIER)",
        "CFBundleShortVersionString": "$(FLUTTER_BUILD_NAME)",
        "CFBundleVersion": "$(FLUTTER_BUILD_NUMBER)",
        "CFBundleDisplayName": "开胯训练助手",
        "ITSAppUsesNonExemptEncryption": False,
        "LSRequiresIPhoneOS": True,
        "UILaunchStoryboardName": "LaunchScreen",
        "UIRequiresFullScreen": True,
        "UIViewControllerBasedStatusBarAppearance": True,
    }
    for k, v in want.items():
        if info.get(k) != v:
            fail(f"Info.plist: {k} = {info.get(k)!r}, expected {v!r}")
    if info.get("UIBackgroundModes") != ["audio"]:
        fail(f"Info.plist: UIBackgroundModes {info.get('UIBackgroundModes')}")
    if info.get("UISupportedInterfaceOrientations") != ["UIInterfaceOrientationPortrait"]:
        fail("Info.plist: orientations are not portrait-only")
    if "UISupportedInterfaceOrientations~ipad" in info:
        fail("Info.plist: iPad orientations listed for an iPhone-only app")
    if set(info.get("CFBundleLocalizations", [])) != {"zh-Hans", "en"}:
        fail(f"Info.plist: CFBundleLocalizations {info.get('CFBundleLocalizations')}")
    # No usage-description strings: HipLab asks for no permission.
    for k in info:
        if k.startswith("NS") and k.endswith("UsageDescription"):
            fail(f"Info.plist: unexpected permission string {k}")

    privacy = plistlib.loads((RUNNER / "PrivacyInfo.xcprivacy").read_bytes())
    if privacy.get("NSPrivacyTracking") is not False:
        fail("PrivacyInfo: NSPrivacyTracking must be false")
    apis = {d["NSPrivacyAccessedAPIType"]: d["NSPrivacyAccessedAPITypeReasons"]
            for d in privacy.get("NSPrivacyAccessedAPITypes", [])}
    if apis.get("NSPrivacyAccessedAPICategoryUserDefaults") != ["CA92.1"]:
        fail(f"PrivacyInfo: UserDefaults reason {apis.get('NSPrivacyAccessedAPICategoryUserDefaults')}")

    strings_re = re.compile(r'^\s*"((?:[^"\\]|\\.)+)"\s*=\s*"((?:[^"\\]|\\.)*)"\s*;\s*$')
    expected_names = {"zh-Hans": "开胯训练助手", "en": "HipLab"}
    for lang, name in expected_names.items():
        p = RUNNER / f"{lang}.lproj" / "InfoPlist.strings"
        if not p.exists():
            fail(f"{p.relative_to(ROOT)} missing")
            continue
        text = re.sub(r"/\*.*?\*/", "", p.read_text(encoding="utf-8"), flags=re.S)
        table = {}
        for line in text.splitlines():
            if not line.strip():
                continue
            m = strings_re.match(line)
            if not m:
                fail(f"{p.relative_to(ROOT)}: bad line {line!r}")
                continue
            table[m.group(1)] = m.group(2)
        if table.get("CFBundleDisplayName") != name:
            fail(f"{p.relative_to(ROOT)}: CFBundleDisplayName {table.get('CFBundleDisplayName')!r}")


# ───────────────────────── asset catalog ─────────────────────────


def png_info(p: Path):
    data = p.read_bytes()
    if data[:8] != b"\x89PNG\r\n\x1a\n":
        raise ValueError("not a PNG")
    w, h, depth, color = struct.unpack(">IIBB", data[16:26])
    has_trns = b"tRNS" in data[:4096]
    return w, h, color, has_trns


def check_assets():
    icon_dir = RUNNER / "Assets.xcassets" / "AppIcon.appiconset"
    contents = json.loads((icon_dir / "Contents.json").read_text())
    have_marketing = False
    for img in contents["images"]:
        fn = img.get("filename")
        if not fn:
            fail(f"AppIcon: entry without file {img}")
            continue
        p = icon_dir / fn
        if not p.exists():
            fail(f"AppIcon: {fn} missing")
            continue
        size = float(img["size"].split("x")[0])
        scale = int(img.get("scale", "1x").rstrip("x"))
        w, h, color, trns = png_info(p)
        if (w, h) != (round(size * scale),) * 2:
            fail(f"AppIcon: {fn} is {w}x{h}, entry wants {size}@{scale}x")
        if img.get("idiom") == "ios-marketing" or (
            img.get("idiom") == "universal" and img["size"] == "1024x1024"
        ):
            have_marketing = True
            if color in (4, 6) or trns:
                fail(f"AppIcon: {fn} has an alpha channel (App Store rejects it)")
    if not have_marketing:
        fail("AppIcon: no 1024 marketing icon")
    idioms = {i.get("idiom") for i in contents["images"]}
    if "ipad" in idioms:
        fail("AppIcon: iPad entries in an iPhone-only app")

    names = {"image": set(), "color": set()}
    for d in (RUNNER / "Assets.xcassets").iterdir():
        if d.suffix == ".imageset":
            names["image"].add(d.stem)
        if d.suffix == ".colorset":
            names["color"].add(d.stem)
            try:
                json.loads((d / "Contents.json").read_text())
            except Exception as e:  # noqa: BLE001
                fail(f"{d.name}: bad Contents.json ({e})")

    for sb in ("LaunchScreen", "Main"):
        p = RUNNER / "Base.lproj" / f"{sb}.storyboard"
        try:
            tree = ET.parse(p)
        except ET.ParseError as e:
            fail(f"{sb}.storyboard: {e}")
            continue
        if sb != "LaunchScreen":
            continue
        for el in tree.iter():
            if el.tag == "image" and el.get("name") not in names["image"]:
                fail(f"LaunchScreen: image {el.get('name')} not in Assets.xcassets")
            if el.tag == "namedColor" and el.get("name") not in names["color"]:
                fail(f"LaunchScreen: color {el.get('name')} not in Assets.xcassets")
            if el.tag == "imageView" and el.get("image") not in names["image"]:
                fail(f"LaunchScreen: imageView image {el.get('image')} missing")


def main() -> int:
    check_plists()
    check_pbxproj()
    check_assets()
    if problems:
        print("\n".join(f"FAIL {p}" for p in problems))
        return 1
    print("iOS project static checks: OK")
    return 0


if __name__ == "__main__":
    sys.exit(main())
