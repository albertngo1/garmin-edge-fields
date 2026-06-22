import Toybox.Lang;

// Pure, testable aerobic-decoupling math — no device state, so it runs under the
// unit-test runner.
module Decouple {

    // Aerobic decoupling (%) between the first and second half of a ride, computed
    // from per-elapsed-minute summed power and summed HR.
    //
    // Efficiency factor for a half = (summed power) / (summed HR). Because a sample
    // is only ever added to BOTH sums together (when power and HR are both valid),
    // sumP/sumH equals mean(power)/mean(HR) over that half exactly, regardless of
    // how many samples each bucket holds — so the per-bucket counts cancel and
    // aren't needed.
    //
    //   drift = (EF_first - EF_second) / EF_first * 100
    //
    // Positive = efficiency fell in the second half (cardiac drift / fatigue);
    // negative = it rose. Returns null until there are >= 2 buckets and both halves
    // carry HR data.
    function percent(sumP as Array<Number>, sumH as Array<Number>) as Float? {
        var n = sumP.size();
        if (n < 2) {
            return null;
        }
        var mid = n / 2;
        var p1 = 0;
        var h1 = 0;
        var p2 = 0;
        var h2 = 0;
        for (var i = 0; i < mid; i++) {
            p1 += sumP[i];
            h1 += sumH[i];
        }
        for (var i = mid; i < n; i++) {
            p2 += sumP[i];
            h2 += sumH[i];
        }
        if (h1 <= 0 || h2 <= 0) {
            return null;
        }
        var ef1 = p1.toFloat() / h1.toFloat();
        var ef2 = p2.toFloat() / h2.toFloat();
        if (ef1 <= 0.0) {
            return null;
        }
        return (ef1 - ef2) / ef1 * 100.0;
    }
}
