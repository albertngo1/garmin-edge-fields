import Toybox.Lang;
import Toybox.Test;

// Coggan zones for FTP 200: Z1<=110, Z2<=150, Z3<=180, Z4<=210, Z5<=240, Z6<=300, Z7>300
(:test)
function testZoneForPower(logger as Test.Logger) as Boolean {
    var ftp = 200;
    Test.assertEqual(PowerCalc.zoneForPower(0, ftp), 1);     // coasting -> Z1
    Test.assertEqual(PowerCalc.zoneForPower(100, ftp), 1);   // 50% -> Z1
    Test.assertEqual(PowerCalc.zoneForPower(110, ftp), 1);   // 55% edge -> Z1
    Test.assertEqual(PowerCalc.zoneForPower(120, ftp), 2);   // 60% -> Z2
    Test.assertEqual(PowerCalc.zoneForPower(150, ftp), 2);   // 75% edge -> Z2
    Test.assertEqual(PowerCalc.zoneForPower(180, ftp), 3);   // 90% edge -> Z3
    Test.assertEqual(PowerCalc.zoneForPower(200, ftp), 4);   // 100% -> Z4
    Test.assertEqual(PowerCalc.zoneForPower(210, ftp), 4);   // 105% edge -> Z4
    Test.assertEqual(PowerCalc.zoneForPower(240, ftp), 5);   // 120% edge -> Z5
    Test.assertEqual(PowerCalc.zoneForPower(300, ftp), 6);   // 150% edge -> Z6
    Test.assertEqual(PowerCalc.zoneForPower(400, ftp), 7);   // 200% -> Z7
    return true;
}

(:test)
function testZoneForPowerInvalidFtp(logger as Test.Logger) as Boolean {
    Test.assertEqual(PowerCalc.zoneForPower(200, null), 0);  // no FTP -> unset
    Test.assertEqual(PowerCalc.zoneForPower(200, 0), 0);     // FTP 0 -> unset
    Test.assertEqual(PowerCalc.zoneForPower(null, 200), 1);  // no power -> Z1
    return true;
}
