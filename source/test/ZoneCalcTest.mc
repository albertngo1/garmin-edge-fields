import Toybox.Lang;
import Toybox.Test;

// Boundaries mirror Albert's interim zones (%Max, max 195):
// Z1 98-117, Z2 117-137, Z3 137-156, Z4 156-176, Z5 176-195
// getHeartRateZones() form: [z1Low, z1Top, z2Top, z3Top, z4Top, z5Top]
(:test)
function testZoneForHr(logger as Test.Logger) as Boolean {
    var b = [98, 117, 137, 156, 176, 195] as Array<Number>;

    Test.assertEqual(ZoneCalc.zoneForHr(90, b), 0);   // below Z1 floor
    Test.assertEqual(ZoneCalc.zoneForHr(98, b), 1);   // exactly Z1 floor
    Test.assertEqual(ZoneCalc.zoneForHr(116, b), 1);  // top of Z1
    Test.assertEqual(ZoneCalc.zoneForHr(117, b), 2);  // Z2 lower edge
    Test.assertEqual(ZoneCalc.zoneForHr(130, b), 2);  // mid Z2
    Test.assertEqual(ZoneCalc.zoneForHr(160, b), 4);  // Z4
    Test.assertEqual(ZoneCalc.zoneForHr(180, b), 5);  // Z5
    Test.assertEqual(ZoneCalc.zoneForHr(210, b), 5);  // above max -> still Z5
    return true;
}

(:test)
function testZoneForHrNullSafety(logger as Test.Logger) as Boolean {
    var b = [98, 117, 137, 156, 176, 195] as Array<Number>;
    Test.assertEqual(ZoneCalc.zoneForHr(null, b), 0);
    Test.assertEqual(ZoneCalc.zoneForHr(0, b), 0);
    Test.assertEqual(ZoneCalc.zoneForHr(150, null), 0);
    return true;
}

(:test)
function testFormatSeconds(logger as Test.Logger) as Boolean {
    Test.assertEqual(ZoneCalc.formatSeconds(0), "0:00");
    Test.assertEqual(ZoneCalc.formatSeconds(5), "0:05");
    Test.assertEqual(ZoneCalc.formatSeconds(65), "1:05");
    Test.assertEqual(ZoneCalc.formatSeconds(600), "10:00");
    Test.assertEqual(ZoneCalc.formatSeconds(3661), "1:01:01");
    Test.assertEqual(ZoneCalc.formatSeconds(-10), "0:00");
    return true;
}
