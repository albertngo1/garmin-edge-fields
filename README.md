# Garmin Edge data fields

Five Connect IQ data fields for riders on current Garmin Edge computers: Edge 540, 550, 840, 850, 1050, Explore 2 and MTB. They track time in HR and power zones, power-to-HR efficiency, aerobic drift and carb burn, and are drawn to look like Garmin's built-in fields.

Each field is a separate Connect IQ app (one app can only hold one field), so each builds to its own `.prg`. They share layout code, per-device colors and CI.

## Install (sideload)

You need the Connect IQ SDK and JDK 17.

```bash
make key            # once: generates developer_key.der (gitignored)
make build          # -> dev/{TimeInZone,PwHr,PwHrDrift,TimeInPowerZone,CarbBurn}.prg
```

1. Plug the Edge in over USB.
2. Copy the `.prg` files you want from `dev/` to `GARMIN/Apps/` on the Edge, then eject.
3. On the Edge, go to **Activity Profile → Data Screens → add field → Connect IQ Fields**.

Set your HR zones on the device first (**Menu → My Stats → User Profile → Heart Rate Zones**), or Time in Zone will use the wrong boundaries.

The four power fields need a power meter. Time in Power Zone and Carb Burn also use your FTP, set in Garmin Connect Mobile (default 200 W).

## Fields

| Field | File | What it shows |
|---|---|---|
| Time in Zone | `TimeInZone.prg` | Time spent in a heart-rate zone |
| PW:HR | `PwHr.prg` | Watts per bpm, smoothed over about 10 seconds |
| Pw:Hr Drift | `PwHrDrift.prg` | Aerobic decoupling, first half vs second half of the ride |
| Time in Power Zone | `TimeInPowerZone.prg` | Time spent in a Coggan power zone (Z1 to Z7) |
| Carb Burn | `CarbBurn.prg` | Estimated carbohydrate burn in grams per hour |

### Time in Zone

Two modes. **Current Zone** shows the time banked in whatever zone you're in now, and switches as your HR moves. **Target Zone** sticks to one zone (Z2 by default), so you can see whether you got your base minutes in. Change the mode in Garmin Connect Mobile or with the Menu button on the device.

Zones come from the device (`UserProfile.getHeartRateZones()`), so they match your Max HR / %Max setup.

### PW:HR

Average power divided by average heart rate over a 10-second rolling window. Higher means more watts for the same heart rate.

### Pw:Hr Drift (aerobic decoupling)

How much your power-to-HR ratio drops from the first half of the ride to the second: `(EF_first − EF_second) / EF_first`, as a percent. Under 5% is the usual sign of a solid aerobic base. The number is green under 5%, orange from 5 to 10%, and red above 10%.

Power and HR are summed into one bucket per minute, so the halves are recomputed as the ride grows without storing every second. A 6-hour ride is about 360 buckets.

### Time in Power Zone

The power version of Time in Zone. Same two modes, with Coggan zones Z1 to Z7 based on your FTP. FTP, mode and target zone can be set in Garmin Connect Mobile or with the Menu button on the device.

### Carb Burn

A rough estimate of carbs burned per hour, to pace your fueling against the usual 60 to 120 g/hr guidance. Energy comes from power (kJ of work is about equal to kcal burned, since people are about 24% efficient). The share of that energy from carbs rises with intensity: 45% at or below 50% of FTP, up to 100% at 120% of FTP. Power is smoothed over 10 seconds.

This is a population-average model, not a lab measurement. Treat it as a ballpark.

## Development

```bash
make install-hooks  # once: enables the pre-commit palette check
make tests          # run unit tests in the simulator
make palette-check  # compare per-device colors to the device profiles
```

[docs/DESIGN.md](docs/DESIGN.md) covers how the fields copy the native look, the palette drift check and CI, and the repo layout.

## License and credits

MIT. See [LICENSE](LICENSE). All code is original. The project structure (a data field with on-device and Garmin Connect settings) was inspired by [bmacher/garmin-pw2hr](https://github.com/bmacher/garmin-pw2hr). No code was copied from it.
