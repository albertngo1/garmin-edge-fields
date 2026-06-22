import Toybox.Lang;

// Pure, testable power-zone helpers — no device state, so they run under the
// unit-test runner. Zones are the standard Coggan 7-zone model as % of FTP.
module PowerCalc {

    // Upper bound (inclusive) of zones 1..6 as a % of FTP; zone 7 is anything above.
    //   Z1 Active Recovery <= 55%   Z2 Endurance <= 75%   Z3 Tempo     <= 90%
    //   Z4 Threshold       <= 105%  Z5 VO2max    <= 120%  Z6 Anaerobic <= 150%
    //   Z7 Neuromuscular   > 150%
    function upperPcts() as Array<Number> {
        return [55, 75, 90, 105, 120, 150];
    }

    // Map a power (watts) to its Coggan zone 1..7 for the given FTP. Coasting (0 W /
    // null) and anything up to the Z1 ceiling is Z1. Returns 0 only when FTP is
    // invalid (so the field can show "--" until FTP is configured).
    function zoneForPower(power as Number?, ftp as Number?) as Number {
        if (ftp == null || ftp <= 0) {
            return 0;
        }
        var p = (power != null && power > 0) ? power : 0;
        var pct = p.toFloat() / ftp.toFloat() * 100.0;
        var ups = upperPcts();
        for (var z = 0; z < ups.size(); z++) {
            if (pct <= ups[z]) {
                return z + 1;
            }
        }
        return 7;
    }
}
