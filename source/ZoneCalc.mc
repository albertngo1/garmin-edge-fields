import Toybox.Lang;

// Pure, testable helpers — no device state, so they run under the unit-test runner.
module ZoneCalc {

    // Determine the HR zone (0-5) for a heart rate given Garmin's zone boundaries.
    //
    // UserProfile.getHeartRateZones() returns 6 numbers:
    //   boundaries[0] = lower bound of Zone 1
    //   boundaries[1] = upper bound of Zone 1 (== lower bound of Zone 2)
    //   ...
    //   boundaries[5] = upper bound of Zone 5 (max HR)
    //
    // Returns:
    //   0  = below Zone 1 (warm-up / recovery, under the Z1 floor)
    //   1..5 = the active HR zone
    function zoneForHr(hr as Number?, boundaries as Array<Number>?) as Number {
        if (hr == null || hr <= 0 || boundaries == null || boundaries.size() < 6) {
            return 0;
        }
        if (hr < boundaries[0]) {
            return 0;
        }
        // boundaries[i] is the TOP of zone i. Walk up until hr fits.
        for (var z = 1; z <= 5; z++) {
            if (hr < boundaries[z]) {
                return z;
            }
        }
        return 5; // at or above the top of Zone 5
    }

    // Format a number of seconds as H:MM:SS (drops the hour when < 1h -> M:SS).
    function formatSeconds(totalSeconds as Number) as String {
        if (totalSeconds < 0) {
            totalSeconds = 0;
        }
        var h = totalSeconds / 3600;
        var m = (totalSeconds % 3600) / 60;
        var s = totalSeconds % 60;
        if (h > 0) {
            return h.format("%d") + ":" + m.format("%02d") + ":" + s.format("%02d");
        }
        return m.format("%d") + ":" + s.format("%02d");
    }
}
