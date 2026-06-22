import Toybox.Lang;
import Toybox.Test;

(:test)
function testDecoupleNeedsTwoBuckets(logger as Test.Logger) as Boolean {
    Test.assert(Decouple.percent([] as Array<Number>, [] as Array<Number>) == null);
    Test.assert(Decouple.percent([200] as Array<Number>, [150] as Array<Number>) == null);
    return true;
}

(:test)
function testDecouplePositiveDrift(logger as Test.Logger) as Boolean {
    // First half EF = 200/150 = 1.333; second half EF = 200/160 = 1.250.
    // drift = (1.333 - 1.250) / 1.333 * 100 ~= 6.25%
    var d = Decouple.percent([200, 200] as Array<Number>, [150, 160] as Array<Number>) as Float;
    Test.assert(d > 6.0 && d < 6.5);
    return true;
}

(:test)
function testDecoupleNegativeWhenEfficiencyImproves(logger as Test.Logger) as Boolean {
    // Second half makes more power at lower HR -> efficiency rose -> negative drift.
    var d = Decouple.percent([200, 220] as Array<Number>, [160, 150] as Array<Number>) as Float;
    Test.assert(d < 0.0);
    return true;
}

(:test)
function testDecoupleNullWhenHalfHasNoHr(logger as Test.Logger) as Boolean {
    Test.assert(Decouple.percent([200, 200] as Array<Number>, [150, 0] as Array<Number>) == null);
    return true;
}
