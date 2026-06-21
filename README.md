# Time in Zone — Garmin Connect IQ data field

A single Edge data field that shows **accumulated time in a heart-rate zone**, in two modes:

- **Current Zone (live)** — shows the time banked in whatever zone you're in *right now*, and switches which zone's total it displays as your HR moves between zones.
- **Target Zone** — locks onto one zone (default **Z2**) and shows only that total — for answering *"did I actually get my base minutes?"*

Zones are read straight off the device via `UserProfile.getHeartRateZones()`, so the field always matches your configured Max HR / %Max setup — nothing hardcoded.

Built for the **Edge 1050**. Structure mirrors [bmacher/garmin-pw2hr](https://github.com/bmacher/garmin-pw2hr).

## Layout
```
source/
  TimeInZoneApp.mc          # AppBase: settings storage + view wiring
  TimeInZoneView.mc         # DataField: per-zone accumulation + native-style draw
  ZoneCalc.mc               # pure helpers (zoneForHr, formatSeconds) — unit-tested
  Layout.mc                 # adaptive cell layout (font fit + positions)
  SettingsMenuDelegate.mc   # on-device settings menu
  test/ZoneCalcTest.mc      # logic unit tests
  test/LayoutTest.mc        # renders into off-screen buffers at every cell size,
                            #   asserts no clipping/overlap + padding holds
resources/                  # strings, drawable icon, GCM settings/properties
manifest.xml monkey.jungle Makefile
```

## Build (requires the Connect IQ SDK + JDK 17)
```bash
make key      # once — generates developer_key.der (gitignored)
make build    # -> dev/TimeInZone.prg
make sim      # build + run in the simulator
make tests    # run unit tests
```

## Install (sideload)
Plug the Edge 1050 in via USB and copy `dev/TimeInZone.prg` to `GARMIN/Apps/`.
Eject, then add it on the Edge: **Activity Profile → Data Screens → add field → Connect IQ Fields → Time in Zone**.

## Prerequisite
Set your HR zones on the device first (**Menu → My Stats → User Profile → Heart Rate Zones**, Max 195 / %Max) or the zone boundaries are wrong.
