# Design notes

Technical detail moved out of the README: how the fields copy the native look, how the palette guard works, and the repo layout.

## Matching the native look

The goal is for these fields to look like Garmin's built-in ones. A Connect IQ field draws its own cell, so matching native means copying what the firmware does. Most of that isn't documented. I worked it out from the SDK device profiles.

- **Colors come from the device profile.** Each model's native background and text colors live in its `personality.mss` (`activity_color_*` blocks). They differ by model, so there is one palette per device group in `source-palette/`, picked per device in the `.jungle` files:
  - `e1050` (Edge 1050): dark `#17181D`, light text `#313253`. The light background is pure white `#FFFFFF` by choice, instead of the profile's `#DCDCDC` grey. This is a documented override in `tools/check_native_palette.py`.
  - `x50` (Edge 550 / 850): dark `#191919`, light `#DCDCDC` drawn as a faint top-to-bottom gradient (`#E2E2E2` to `#D2D2D2`) to match the native light-cell sheen.
  - `mono` (Edge 540 / 840 / Explore 2 / MTB): plain black and white.

  `getBackgroundColor()` only reports black or white, so the exact tint has to come from the profile. `source/Background.mc` does the fill for every field.
- **Layout and justification come from `simulator.json`.** The profile's `layouts[].datafields` lists each native field's label/value font, position and justification. Native labels and values are centered, with a small label and a big bold number. These fields do the same.
- **Fonts are fitted to the cell.** `Layout.mc` picks the largest label and value fonts that fit the cell's width and height, and falls back to a shorter label in tight cells. Nothing clips or overlaps from 1-field to 10-field layouts. It uses `FONT_*` constants, not pixel sizes, so it follows the device's own fonts.
- **Timer-style value.** Time in Zone draws the value like the native Timer: a big `M:SS` with hundredths as a small superscript, so the fraction doesn't shrink the main number.
- **Zone-colored heart.** The `♥` glyph takes the current zone's color, adjusted per theme so it never renders dark on dark.
- **Little to go stale.** Positions (from `dc` size), fonts (`FONT_*`) and theme (`getBackgroundColor`) are all read at runtime, so they follow firmware changes. The only baked-in snapshot is the per-device palette, and that is checked (below).

Still imperfect: Garmin doesn't publish the exact label inset or value sizing beyond what `simulator.json` gives, so vertical placement is tuned by eye. It is close, not pixel-perfect.

## Palette drift guard

The per-device colors are a snapshot of each `personality.mss`. `tools/check_native_palette.py` re-reads the native colors from the device profiles and checks that each `source-palette/<variant>/Palette.mc` still matches (allowing for documented overrides). If Garmin changes a native color in a future profile, it fails and tells you which variant to update.

It runs in three places:

- `make palette-check`: locally, against your SDK Manager profiles.
- Pre-commit hook (`make install-hooks`): blocks a commit that would drift the palette. Skips if the SDK isn't installed.
- CI `palette-guard` job: against the committed `.ci/devices/edge-devices.zip`.

Device profiles need a Garmin login to download, so CI can't compare against Garmin's latest. Instead the `sdk-watch` job (also run weekly on a cron) compares the pinned `SDK_VERSION` with the latest published SDK. While they match, nothing upstream can have changed. When a newer SDK ships, the job fails and tells you to refresh the device profiles, regenerate the device zip, run `make palette-check`, and bump `SDK_VERSION`.

## Repo layout

```
source/                     # shared by all fields
  Layout.mc                 # adaptive cell layout (font fit + positions)
  Background.mc             # cell background fill (flat or light-theme gradient)
  ZoneCalc.mc               # pure HR-zone + time helpers (unit-tested)
  PowerCalc.mc              # pure Coggan power-zone helper (unit-tested)
  Decouple.mc               # pure aerobic-decoupling math (unit-tested)
  Fuel.mc                   # pure carb-burn model (unit-tested)
  test/ZoneCalcTest.mc      # logic unit tests
  test/PowerCalcTest.mc     # power-zone unit tests
  test/DecoupleTest.mc      # decoupling unit tests
  test/FuelTest.mc          # carb-burn unit tests
  test/LayoutTest.mc        # off-screen render tests: no clip/overlap + padding
source-tiz/                 # Time in Zone app (App, View, settings menu)
source-pwhr/                # PW:HR app (App, View)
source-decoupling/          # Aerobic Decoupling app (App, View)
source-tipz/                # Time in Power Zone app (App, View, settings menu)
source-carbs/               # Carb Burn app (App, View)
source-palette/             # per-device native palettes (e1050 / x50 / mono)
resources/                  # shared drawable icon
resources-tiz/  resources-pwhr/  resources-decoupling/  resources-tipz/  resources-carbs/   # per-app strings / settings
tools/check_native_palette.py   # palette drift guard
hooks/pre-commit            # runs the guard before each commit (make install-hooks)
.ci/devices/edge-devices.zip    # device profiles for CI builds
manifest.xml        monkey.jungle      # Time in Zone
manifest-pwhr.xml   pwhr.jungle        # PW:HR
manifest-decoupling.xml decoupling.jungle  # Aerobic Decoupling
manifest-tipz.xml   tipz.jungle        # Time in Power Zone
manifest-carbs.xml  carbs.jungle       # Carb Burn
Makefile
```
