import Toybox.Activity;
import Toybox.Application.Storage;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.UserProfile;
import Toybox.WatchUi;

class TimeInZoneView extends WatchUi.DataField {

    private const MODE_CURRENT = 0; // time in the zone you're in right now (switches live)
    private const MODE_TARGET  = 1; // time in a fixed target zone (e.g. Z2 base minutes)

    private const HEART = "♥ "; // heart glyph + space, prepended like native HR fields

    // Accumulated MILLISECONDS per zone. Index 0 = below Z1, indices 1..5 = Z1..Z5.
    // compute() runs at ~1 Hz, so we accumulate real elapsed time via timer deltas
    // (System.getTimer) rather than a flat +1s — this yields the sub-second part.
    private var _zoneMillis as Array<Number> = [0, 0, 0, 0, 0, 0];
    private var _lastMs as Number? = null;     // last getTimer() while actively counting
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

        // Accumulate the real wall-clock delta since the last active sample into the
        // current zone. getTimer() is monotonic ms-since-boot; guard against its
        // ~24.8-day wrap and against large gaps (paused/backgrounded) by ignoring
        // non-positive or implausibly long deltas. When not actively counting we drop
        // the anchor so paused time is never billed to a zone.
        var now = System.getTimer();
        if (timerActive && hr != null && hr > 0) {
            if (_lastMs != null) {
                var delta = now - _lastMs;
                if (delta > 0 && delta < 10000) {
                    _zoneMillis[_currentZone] += delta;
                }
            }
            _lastMs = now;
        } else {
            _lastMs = null;
        }
    }

    // Garmin's zone colors (<Z1 gray, Z1 gray, Z2 blue, Z3 green, Z4 orange, Z5 red),
    // made theme-aware so the heart glyph always has contrast: DK_GRAY and BLUE are
    // too dark against the #17181D dark background (and LT_GRAY too light on the
    // #DCDCDC light one), so swap the grays and blue by theme. Green/orange/red read
    // fine on both.
    private function zoneColor(zone as Number, dark as Boolean) as Graphics.ColorType {
        switch (zone) {
            case 1:  return dark ? Graphics.COLOR_LT_GRAY : Graphics.COLOR_DK_GRAY;
            case 2:  return dark ? 0x4AA3FF : Graphics.COLOR_BLUE;
            case 3:  return Graphics.COLOR_GREEN;
            case 4:  return Graphics.COLOR_ORANGE;
            case 5:  return Graphics.COLOR_RED;
            default: return dark ? Graphics.COLOR_LT_GRAY : Graphics.COLOR_DK_GRAY;
        }
    }

    // Zone number for the label: "<1" below Zone 1, else the digit.
    private function zoneNum(shownZone as Number) as String {
        return (shownZone == 0) ? "<1" : shownZone.format("%d");
    }

    // Dynamic, uppercase to match native labels. In Current mode shownZone is the
    // live zone (label changes as you move zones); in Target mode it's fixed.
    private function textFull(shownZone as Number) as String {
        return "TIME IN ZONE " + zoneNum(shownZone);
    }

    private function textShort(shownZone as Number) as String {
        return "ZONE " + zoneNum(shownZone);
    }

    // Heart-included strings used by Layout for width sizing.
    private function labelFull(shownZone as Number) as String { return HEART + textFull(shownZone); }
    private function labelShort(shownZone as Number) as String { return HEART + textShort(shownZone); }

    // Text-only (no heart) for drawing, matching whichever Layout selected.
    private function labelTextOnly(shownZone as Number, useFull as Boolean) as String {
        return useFull ? textFull(shownZone) : textShort(shownZone);
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        // Native activity text color (from edge1050 personality.mss):
        // #313253 on the light theme, white on dark. Pick by bg luminance.
        var bgColor = getBackgroundColor();
        var r = (bgColor >> 16) & 0xFF;
        var g = (bgColor >> 8) & 0xFF;
        var b = bgColor & 0xFF;
        var dark = (r + g + b) < 384;
        var textColor = dark ? Palette.DARK_TEXT : Palette.LIGHT_TEXT;

        // getBackgroundColor() only reports binary black/white, but each device's
        // native activity background is a specific tint (per personality.mss). Clear
        // with the per-device Palette value so the cell matches native exactly.
        var nativeBg = dark ? Palette.DARK_BG : Palette.LIGHT_BG;
        dc.setColor(nativeBg, nativeBg);
        dc.clear();

        var shownZone = (_mode == MODE_TARGET) ? _targetZone : _currentZone;
        // Split the value: big main M:SS (sizes the font) + small raised hundredths,
        // like the native Timer field — so the hundredths don't shrink the number.
        var ms = _zoneMillis[shownZone];
        var mainStr = ZoneCalc.formatSeconds(ms / 1000);
        var csStr = ((ms % 1000) / 10).format("%02d");

        var L = Layout.compute(dc, dc.getWidth(), dc.getHeight(),
            labelFull(shownZone), labelShort(shownZone), mainStr);

        // Label: heart glyph (zone color) + uppercase text (muted), centered as a group.
        // Built from the same pieces Layout sized, so we never split a multi-byte glyph.
        var labelFont = L[:labelFont];
        var labelY = L[:labelY] as Number;
        var useFull = L[:useFull] as Boolean;
        var rest = labelTextOnly(shownZone, useFull);

        // Centered, like native fields (heart + label as a centered group up top).
        var heartW = dc.getTextWidthInPixels(HEART, labelFont);
        var restW = dc.getTextWidthInPixels(rest, labelFont);
        var startX = (dc.getWidth() - (heartW + restW)) / 2;
        dc.setColor(zoneColor(shownZone, dark), Graphics.COLOR_TRANSPARENT);
        dc.drawText(startX, labelY, labelFont, HEART, Graphics.TEXT_JUSTIFY_LEFT);
        dc.setColor(textColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(startX + heartW, labelY, labelFont, rest, Graphics.TEXT_JUSTIFY_LEFT);

        // Value: big main number + small raised hundredths (native Timer style).
        var valueFont = L[:valueFont];
        var valueY = L[:valueY] as Number;
        var scFont = Graphics.FONT_XTINY;
        var mainW = dc.getTextWidthInPixels(mainStr, valueFont);
        var mainH = dc.getFontHeight(valueFont);
        var scW = dc.getTextWidthInPixels(csStr, scFont);
        var valMaxW = dc.getWidth() - 2 * Layout.PAD;

        dc.setColor(textColor, Graphics.COLOR_TRANSPARENT);
        if (mainW + scW <= valMaxW) {
            // Center the main + superscript pair; hundredths raised to the top of the number.
            var valStartX = (dc.getWidth() - (mainW + scW)) / 2;
            dc.drawText(valStartX, valueY, valueFont, mainStr,
                Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
            dc.drawText(valStartX + mainW, valueY - mainH / 3, scFont, csStr,
                Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        } else {
            // Too tight for the superscript — just center the main number.
            dc.drawText(dc.getWidth() / 2, valueY, valueFont, mainStr,
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }
    }
}
