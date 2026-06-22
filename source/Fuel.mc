import Toybox.Lang;

// Pure, testable fueling math — no device state, so it runs under the unit-test
// runner. This is a population-average model (not individual metabolism): good for
// pacing your fueling, not a lab measurement.
module Fuel {

    // Carbohydrate share of energy expenditure at a given % of FTP. Ramps from ~45%
    // carbs at easy intensity to ~100% near/above threshold (an RER-style curve).
    function carbFraction(pctFtp as Float) as Float {
        if (pctFtp <= 50.0) {
            return 0.45;
        }
        if (pctFtp >= 120.0) {
            return 1.0;
        }
        return 0.45 + (pctFtp - 50.0) * 0.55 / 70.0;
    }

    // Estimated carbohydrate burn in grams/hour for a given power (W) and FTP (W).
    //
    // Energy: kJ of mechanical work ~= kcal of metabolic energy (human gross
    // efficiency ~24% makes the conversion very nearly 1:1), so total energy
    // expenditure ~= watts * 3.6 kcal/hr. The carb fraction of that (by intensity)
    // converts to grams at 4 kcal/g. Returns 0.0 when FTP or power is invalid.
    function carbGramsPerHour(power as Number?, ftp as Number?) as Float {
        if (ftp == null || ftp <= 0 || power == null || power <= 0) {
            return 0.0;
        }
        var pct = power.toFloat() / ftp.toFloat() * 100.0;
        var kcalHr = power.toFloat() * 3.6;
        var carbKcalHr = kcalHr * carbFraction(pct);
        return carbKcalHr / 4.0;
    }
}
