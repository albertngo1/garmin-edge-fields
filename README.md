# Garmin Edge data fields

A suite of native-look Connect IQ data fields for current-generation Garmin Edge
computers (540 / 550 / 840 / 850 / 1050 / Explore 2 / MTB). Each field is its own
Connect IQ app (one CIQ data-field app exposes exactly one field, so each builds to
its own `.prg`), but they all share the adaptive `Layout`, per-device `Palette`,
device matrix, and CI — and a common goal of **blending in with Garmin's built-in
data fields** rather than looking bolted-on (see [Matching the native look](#matching-the-native-look)).

## Fields

### Time in Zone — `source-tiz` (`monkey.jungle` / `manifest.xml`)

Shows **accumulated time in a heart-rate zone**, in two modes:

- **Current Zone (live)** — shows the time banked in whatever zone you're in *right now*, and switches which zone's total it displays as your HR moves between zones.
- **Target Zone** — locks onto one zone (default **Z2**) and shows only that total — for answering *"did I actually get my base minutes?"*

Zones are read straight off the device via `UserProfile.getHeartRateZones()`, so the field always matches your configured Max HR / %Max setup — nothing hardcoded.

### PW:HR — `source-pwhr` (`pwhr.jungle` / `manifest-pwhr.xml`)

A live **power-to-heart-rate ratio** (watts per bpm), smoothed over a short rolling
window — an aerobic-efficiency readout.

## Matching the native look

A core goal of these fields is to **blend in with Garmin's built-in data fields** rather than look like a bolted-on third-party field. A Connect IQ field draws its *own* cell, so matching native means reproducing what the firmware does — and most of that isn't documented, so it was reverse-engineered from the SDK device profiles:

- **Colors come from the device profile.** Each model's native activity background/text colors live in its `personality.mss` (`activity_color_*` blocks). They differ across models, so there are **per-device palettes** in `source-palette/` (e.g. Edge 1050 uses `#17181D`/`#DCDCDC`/`#313253`; 540/840 use plain black/white). The right one is compiled in per device via `monkey.jungle`. `getBackgroundColor()` only reports binary black/white, so the exact tint has to come from the profile.
- **Layout/justification from `simulator.json`.** The device profile's `layouts[].datafields` lists each native field's label/value font, position and justification. Native labels and values are **centre-justified**, with the label small and the value a big bold number font — so this field does the same.
- **Adaptive font fit.** `Layout.mc` picks the largest label/value fonts that fit the actual cell (width *and* height), falling back to a shorter label in tight cells, so nothing clips or overlaps in any layout (1-field … 10-field). `FONT_*` constants are used (not pixel sizes) so they track whatever the device's fonts are.
- **Native Timer-style value.** The value is rendered like the native Timer: a big `M:SS` with the hundredths as a small **superscript**, so the fraction doesn't shrink the main number.
- **Theme-aware zone heart.** The `♥` glyph is colored by the current zone, with the palette adjusted per theme so it never renders dark-on-dark.
- **Drift-resistant by construction.** Positions (from `dc` size), fonts (`FONT_*`), and theme (`getBackgroundColor`) are all resolved at runtime, so they follow firmware changes automatically. The only baked snapshot is the per-device color palette — which is guarded (see below).

What's still imperfect: the firmware's exact label inset / value sizing isn't published beyond what `simulator.json` gives, so the vertical placement is tuned by eye and isn't a pixel-perfect match.

## Native-palette drift guard

Because the per-device colors are a snapshot of each `personality.mss`, `tools/check_native_palette.py` re-derives the native colors from the device profiles and asserts each `source-palette/<variant>/Palette.mc` still matches. If Garmin changes a native color in a future profile, it fails and tells you to update the variant.

It runs in three places:

- **`make palette-check`** — locally, against your live SDK-Manager profiles (catches drift the moment you update profiles).
- **Pre-commit hook** (`make install-hooks`) — blocks a commit that would drift the palette; skips cleanly if the SDK isn't installed.
- **CI `palette-guard`** — against the committed `.ci/devices/edge-devices.zip`.

Device profiles are Garmin-auth-gated (not publicly fetchable), so CI can't compare against Garmin's *live* latest. Instead, the **`sdk-watch`** CI job (also a weekly cron) compares the pinned `SDK_VERSION` to the latest published SDK: while they match, nothing upstream can have changed (fast pass); when a newer SDK ships it **fails and flags** you to refresh the device profiles, regenerate the device zip, run `make palette-check`, and bump `SDK_VERSION`.

## License & credits

MIT — see [LICENSE](LICENSE). All code is original. The overall project structure
(a data field with on-device + Garmin-Connect settings) was *inspired by*
[bmacher/garmin-pw2hr](https://github.com/bmacher/garmin-pw2hr); no code was copied
from it.

## Layout
```
source/                     # SHARED across both fields
  Layout.mc                 # adaptive cell layout (font fit + positions)
  ZoneCalc.mc               # pure helpers (zoneForHr, formatSeconds) — unit-tested
  test/ZoneCalcTest.mc      # logic unit tests
  test/LayoutTest.mc        # off-screen-buffer render tests: no clip/overlap + padding
source-tiz/                 # Time in Zone app (App, View, settings menu)
source-pwhr/                # PW:HR app (App, View)
source-palette/             # per-device native color palettes (e1050 / x50 / mono)
resources/                  # shared drawable icon
resources-tiz/  resources-pwhr/   # per-app strings / settings
tools/check_native_palette.py   # palette drift guard
hooks/pre-commit            # runs the guard before each commit (make install-hooks)
.ci/devices/edge-devices.zip    # device profiles for CI builds
manifest.xml      monkey.jungle  # Time in Zone
manifest-pwhr.xml pwhr.jungle    # PW:HR
Makefile
```

## Build (requires the Connect IQ SDK + JDK 17)
```bash
make key            # once — generates developer_key.der (gitignored)
make install-hooks  # once — enables the pre-commit palette guard
make build          # -> dev/TimeInZone.prg + dev/PwHr.prg
make tests          # run unit tests
make palette-check  # verify per-device colors vs the device profiles
```

## Install (sideload)
Plug the Edge in via USB and copy the field(s) you want — `dev/TimeInZone.prg` and/or `dev/PwHr.prg` — to `GARMIN/Apps/`.
Eject, then add each on the Edge: **Activity Profile → Data Screens → add field → Connect IQ Fields → Time in Zone / PW:HR**.

## Prerequisite
Set your HR zones on the device first (**Menu → My Stats → User Profile → Heart Rate Zones**, e.g. Max 195 / %Max) or the zone boundaries are wrong.
