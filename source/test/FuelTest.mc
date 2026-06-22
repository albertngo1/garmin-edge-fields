import Toybox.Lang;
import Toybox.Test;

(:test)
function testCarbFraction(logger as Test.Logger) as Boolean {
    Test.assert((Fuel.carbFraction(40.0) - 0.45).abs() < 0.001);   // easy floor
    Test.assert((Fuel.carbFraction(50.0) - 0.45).abs() < 0.001);   // floor edge
    Test.assert((Fuel.carbFraction(130.0) - 1.0).abs() < 0.001);   // above ceiling
    var f = Fuel.carbFraction(100.0);                              // ~0.843 at threshold
    Test.assert(f > 0.84 && f < 0.85);
    return true;
}

(:test)
function testCarbGramsPerHour(logger as Test.Logger) as Boolean {
    // 200 W @ FTP 200 (100%): kcal/hr=720, carbFrac~0.843 -> ~607 carb kcal -> ~152 g/hr
    var g = Fuel.carbGramsPerHour(200, 200);
    Test.assert(g > 148.0 && g < 156.0);
    return true;
}

(:test)
function testCarbGramsPerHourInvalid(logger as Test.Logger) as Boolean {
    Test.assertEqual(Fuel.carbGramsPerHour(null, 200), 0.0);   // no power
    Test.assertEqual(Fuel.carbGramsPerHour(200, 0), 0.0);      // FTP 0
    Test.assertEqual(Fuel.carbGramsPerHour(200, null), 0.0);   // no FTP
    Test.assertEqual(Fuel.carbGramsPerHour(0, 200), 0.0);      // coasting
    return true;
}
