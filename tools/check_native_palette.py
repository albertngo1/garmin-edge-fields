#!/usr/bin/env python3
"""Native-palette drift guard (per device).

Each Edge model's native activity colors live in its device-profile
personality.mss. We mirror them in a per-device Palette.mc (source-palette/<variant>),
selected per device in monkey.jungle. This script verifies every device's Palette
still matches that device's profile, so if Garmin changes a native color on an
SDK/device-profile refresh, the build fails — telling us to update the variant.

Usage:
    check_native_palette.py [DEVICES_DIR]

DEVICES_DIR holds <device>/personality.mss. Default = the locally SDK-Manager-
installed profiles. CI passes the dir it extracts from .ci/devices/edge-devices.zip.
If the dir is absent (e.g. a fresh clone with no SDK), the check skips cleanly.
"""

import os
import re
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
JUNGLE = os.path.join(REPO, "monkey.jungle")
DEFAULT_DEVICES = os.path.expanduser(
    "~/Library/Application Support/Garmin/ConnectIQ/Devices"
)

# personality.mss block  ->  Palette.mc constant
ROLE_MAP = {
    "activity_color_light__background": "LIGHT_BG",
    "activity_color_dark__background": "DARK_BG",
    "activity_color_light__text": "LIGHT_TEXT",
    "activity_color_dark__text": "DARK_TEXT",
}

# Intentional, documented deviations from the device profile's personality.mss.
# Keyed by (device, Palette constant) -> expected hex (uppercase, no 0x).
#
# edge1050 LIGHT_BG: Garmin's edge1050 profile declares activity_color_light__background
# as #DCDCDC (grey), but the physical Edge 1050 renders native datafield backgrounds
# pure white. We match the real hardware, not the (stale) simulator profile. The guard
# pins this to FFFFFF here so a profile refresh can't silently drag it back to grey.
OVERRIDES = {
    ("edge1050", "LIGHT_BG"): "FFFFFF",
}


def mss_color(text, block):
    m = re.search(re.escape(block) + r"\s*\{([^}]*)\}", text)
    if not m:
        return None
    h = re.search(r"#([0-9A-Fa-f]{6})", m.group(1))
    return h.group(1).upper() if h else None


def palette_consts(path):
    text = open(path, encoding="utf-8", errors="replace").read()
    out = {}
    for const in ROLE_MAP.values():
        m = re.search(const + r"\s*=\s*0x([0-9A-Fa-f]{6})", text)
        out[const] = m.group(1).upper() if m else None
    return out


def device_variant_map():
    # Parse `edgeXXX.sourcePath = ...;source-palette/<variant>` from the jungle.
    text = open(JUNGLE, encoding="utf-8", errors="replace").read()
    m = {}
    for dev, variant in re.findall(r"(\w+)\.sourcePath\s*=.*?source-palette/(\w+)", text):
        m[dev] = variant
    return m


def main():
    devices_dir = sys.argv[1] if len(sys.argv) > 1 else DEFAULT_DEVICES
    if not os.path.isdir(devices_dir):
        print(f"SKIP — no device profiles at {devices_dir} (install the SDK to enable)")
        return 0

    variants = device_variant_map()
    if not variants:
        print("ERROR: no per-device palette mapping found in monkey.jungle", file=sys.stderr)
        return 2

    problems = []
    checked = 0
    for dev, variant in sorted(variants.items()):
        mss_path = os.path.join(devices_dir, dev, "personality.mss")
        pal_path = os.path.join(REPO, "source-palette", variant, "Palette.mc")
        if not os.path.exists(mss_path):
            print(f"·  {dev}: profile not present, skipped")
            continue
        if not os.path.exists(pal_path):
            problems.append(f"{dev}: palette variant '{variant}' file missing ({pal_path})")
            continue
        native = open(mss_path, encoding="utf-8", errors="replace").read()
        pal = palette_consts(pal_path)
        checked += 1
        for block, const in ROLE_MAP.items():
            nat = mss_color(native, block)
            ours = pal.get(const)
            expected = OVERRIDES.get((dev, const), nat)
            if expected != ours:
                if (dev, const) in OVERRIDES:
                    problems.append(
                        f"{dev} ({variant}): {const} is 0x{ours} but documented override expects #{expected}"
                    )
                else:
                    problems.append(
                        f"{dev} ({variant}): {const} is 0x{ours} but native {block} is #{nat}"
                    )
        print(f"{'✗' if any(dev in p for p in problems) else '✓'}  {dev}  ({variant})")

    if problems:
        print("\nNATIVE PALETTE DRIFT:")
        for p in problems:
            print("  - " + p)
        print("\nFix: update the relevant source-palette/<variant>/Palette.mc to match,")
        print("then refresh .ci/devices/edge-devices.zip and bump the SDK version if needed.")
        return 1

    print(f"\nOK — {checked} device palette(s) match their profile.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
