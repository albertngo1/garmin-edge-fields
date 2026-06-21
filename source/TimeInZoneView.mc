import Toybox.Activity;
import Toybox.Application.Storage;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.UserProfile;
import Toybox.WatchUi;

class TimeInZoneView extends WatchUi.DataField {

    private const MODE_CURRENT = 0; // time in the zone you're in right now (switches live)
    private const MODE_TARGET  = 1; // time in a fixed target zone (e.g. Z2 base minutes)

    private const HEART = "♥ "; // heart glyph + space, prepended like native HR fields

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

        if (timerActive && hr != null && hr > 0) {
            _zoneSeconds[_currentZone] += 1;
        }
    }

    // Garmin's zone colors: <Z1 gray, Z1 gray, Z2 blue, Z3 green, Z4 orange, Z5 red.
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

    // Uppercase to match native field labels (HEART RATE, ZONE, AVERAGE, ...).
    private function textFull(shownZone as Number) as String {
        if (_mode == MODE_TARGET) {
            var zoneText = (shownZone == 0) ? "<Z1" : ("Z" + shownZone.format("%d"));
            return "TIME IN " + zoneText;
        }
        return "TIME IN ZONE";
    }

    private function textShort(shownZone as Number) as String {
        if (_mode == MODE_TARGET) {
            var zoneText = (shownZone == 0) ? "<Z1" : ("Z" + shownZone.format("%d"));
            return zoneText;
        }
        return "TIME";
    }

    // Heart-included strings used by Layout for width sizing.
    private function labelFull(shownZone as Number) as String { return HEART + textFull(shownZone); }
    private function labelShort(shownZone as Number) as String { return HEART + textShort(shownZone); }

    // Text-only (no heart) for drawing, matching whichever Layout selected.
    private function labelTextOnly(shownZone as Number, useFull as Boolean) as String {
        return useFull ? textFull(shownZone) : textShort(shownZone);
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        var bgColor = getBackgroundColor();
        var dark = (bgColor == Graphics.COLOR_BLACK);
        var fgColor = dark ? Graphics.COLOR_WHITE : Graphics.COLOR_BLACK;
        var mutedColor = dark ? Graphics.COLOR_LT_GRAY : Graphics.COLOR_DK_GRAY;

        dc.setColor(bgColor, bgColor);
        dc.clear();

        var shownZone = (_mode == MODE_TARGET) ? _targetZone : _currentZone;
        var valueText = ZoneCalc.formatSeconds(_zoneSeconds[shownZone]);

        var L = Layout.compute(dc, dc.getWidth(), dc.getHeight(),
            labelFull(shownZone), labelShort(shownZone), valueText);

        // Label: heart glyph (zone color) + uppercase text (muted), centered as a group.
        // Built from the same pieces Layout sized, so we never split a multi-byte glyph.
        var labelFont = L[:labelFont];
        var labelY = L[:labelY] as Number;
        var useFull = L[:useFull] as Boolean;
        var rest = labelTextOnly(shownZone, useFull);

        var heartW = dc.getTextWidthInPixels(HEART, labelFont);
        var restW = dc.getTextWidthInPixels(rest, labelFont);
        var startX = (dc.getWidth() - (heartW + restW)) / 2;
        dc.setColor(zoneColor(shownZone), Graphics.COLOR_TRANSPARENT);
        dc.drawText(startX, labelY, labelFont, HEART, Graphics.TEXT_JUSTIFY_LEFT);
        dc.setColor(mutedColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(startX + heartW, labelY, labelFont, rest, Graphics.TEXT_JUSTIFY_LEFT);

        // Value: strong foreground, centered in the region below the label.
        dc.setColor(fgColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth() / 2, L[:valueY] as Number, L[:valueFont], valueText,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}
