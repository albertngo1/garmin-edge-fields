import Toybox.Activity;
import Toybox.Application.Storage;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.UserProfile;
import Toybox.WatchUi;

class TimeInZoneView extends WatchUi.DataField {

    private const MODE_CURRENT = 0; // time in the zone you're in right now (switches live)
    private const MODE_TARGET  = 1; // time in a fixed target zone (e.g. Z2 base minutes)

    // Accumulated seconds per zone. Index 0 = below Z1, indices 1..5 = Z1..Z5.
    private var _zoneSeconds as Array<Number> = [0, 0, 0, 0, 0, 0];
    private var _boundaries as Array<Number>? = null;
    private var _currentZone as Number = 0;

    private var _mode as Number = 0;
    private var _targetZone as Number = 2;

    function initialize() {
        DataField.initialize();
        loadSettings();
        loadZones();
    }

    function loadSettings() as Void {
        var m = Storage.getValue("mode") as Number?;
        _mode = (m != null) ? m : 0;
        var t = Storage.getValue("targetZone") as Number?;
        _targetZone = (t != null) ? t : 2;
    }

    function loadZones() as Void {
        // Pull the user's configured HR zones straight off the device — so this
        // field always matches the Max HR / %Max setup, no hardcoding.
        var z = UserProfile.getHeartRateZones(UserProfile.HR_ZONE_SPORT_GENERIC);
        if (z != null && z.size() >= 6) {
            _boundaries = z as Array<Number>;
        }
    }

    function compute(info as Activity.Info) as Void {
        loadSettings();
        if (_boundaries == null) {
            loadZones();
        }

        var hr = info.currentHeartRate;
        var timerActive = (info.timerState == Activity.TIMER_STATE_ON);

        _currentZone = ZoneCalc.zoneForHr(hr, _boundaries);

        // compute() fires ~once per second; only bank time while the timer runs.
        if (timerActive && hr != null && hr > 0) {
            _zoneSeconds[_currentZone] += 1;
        }
    }

    // Garmin's zone colors, roughly: <Z1 gray, Z1 gray, Z2 blue, Z3 green, Z4 orange, Z5 red.
    private function zoneColor(zone as Number) as Graphics.ColorType {
        switch (zone) {
            case 1:  return Graphics.COLOR_LT_GRAY;
            case 2:  return Graphics.COLOR_BLUE;
            case 3:  return Graphics.COLOR_GREEN;
            case 4:  return Graphics.COLOR_ORANGE;
            case 5:  return Graphics.COLOR_RED;
            default: return Graphics.COLOR_DK_GRAY;
        }
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        var bgColor = getBackgroundColor();
        var fgColor = (bgColor == Graphics.COLOR_BLACK)
            ? Graphics.COLOR_WHITE
            : Graphics.COLOR_BLACK;

        dc.setColor(bgColor, bgColor);
        dc.clear();

        // Which zone are we reporting time for?
        var shownZone = (_mode == MODE_TARGET) ? _targetZone : _currentZone;
        var seconds = _zoneSeconds[shownZone];

        // Label: "Z2 TIME" (target) or "ZONE 2" / "<Z1" (current)
        var zoneText = (shownZone == 0) ? "<Z1" : ("Z" + shownZone.format("%d"));
        var label = (_mode == MODE_TARGET) ? (zoneText + " TIME") : (zoneText + " NOW");

        dc.setColor(zoneColor(shownZone), Graphics.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth() / 2, 4, Graphics.FONT_MEDIUM, label,
            Graphics.TEXT_JUSTIFY_CENTER);

        // Value: accumulated time in that zone
        dc.setColor(fgColor, Graphics.COLOR_TRANSPARENT);
        var valueText = ZoneCalc.formatSeconds(seconds);
        dc.drawText(dc.getWidth() / 2, dc.getHeight() / 2 + 11, Graphics.FONT_NUMBER_MEDIUM, valueText,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}
