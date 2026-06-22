#!/usr/bin/env python3
"""Native-palette drift guard.

Reads the Edge device profile's personality.mss (the source of truth for native
activity colors) and asserts that the colors we hardcode in
source/TimeInZoneView.mc still match. If Garmin changes the native palette in a
future SDK/device update, this fails — telling us to update the constants (and
bump the committed device profile / SDK version).

Usage:
    check_native_palette.py [PERSONALITY_MSS_PATH]

Default path is the locally SDK-Manager-installed edge1050 profile. CI passes the
path it extracts from .ci/devices/edge-devices.zip.
"""

import os
import re
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
VIEW = os.path.join(REPO, "source", "TimeInZoneView.mc")

DEFAULT_MSS = os.path.expanduser(
    "~/Library/Application Support/Garmin/ConnectIQ/Devices/edge1050/personality.mss"
)

# personality.mss block -> human role. We check the activity (data-screen) colors,
# which is what a data field renders against.
ROLES = {
    "activity_color_light__background": "light background",
    "activity_color_dark__background": "dark background",
    "activity_color_light__text": "light text",
    "activity_color_dark__text": "dark text",
}


def mss_color(text, block):
    # Find `<block> { ... #RRGGBB ... }` and return the first hex inside the block.
    m = re.search(re.escape(block) + r"\s*\{([^}]*)\}", text)
    if not m:
        return None
    h = re.search(r"#([0-9A-Fa-f]{6})", m.group(1))
    return h.group(1).upper() if h else None


def main():
    mss_path = sys.argv[1] if len(sys.argv) > 1 else DEFAULT_MSS
    if not os.path.exists(mss_path):
        print(f"ERROR: personality.mss not found: {mss_path}", file=sys.stderr)
        return 2
    mss = open(mss_path, encoding="utf-8", errors="replace").read()
    src = open(VIEW, encoding="utf-8", errors="replace").read().upper()

    problems = []
    for block, role in ROLES.items():
        hexval = mss_color(mss, block)
        if hexval is None:
            problems.append(f"  - {role}: block '{block}' not found in personality.mss")
            continue
        token = "0X" + hexval  # e.g. 0X17181D
        # White is referenced via Graphics.COLOR_WHITE rather than a literal.
        ok = token in src or (hexval == "FFFFFF" and "COLOR_WHITE" in src)
        if not ok:
            problems.append(
                f"  - {role}: native is #{hexval} (expected 0x{hexval} in TimeInZoneView.mc) — not found"
            )

    if problems:
        print("NATIVE PALETTE DRIFT — TimeInZoneView.mc colors no longer match the device profile:")
        print("\n".join(problems))
        print(f"\nSource of truth: {mss_path}")
        print("Fix: update the hardcoded colors in source/TimeInZoneView.mc to match,")
        print("then refresh .ci/devices/edge-devices.zip and bump the SDK version if needed.")
        return 1

    print(f"OK — native palette matches ({len(ROLES)} colors checked against {os.path.basename(mss_path)})")
    return 0


if __name__ == "__main__":
    sys.exit(main())
