import Toybox.Activity;
import Toybox.Application.Storage;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

// Time in Power Zone — the power twin of Time in Zone. Accumulates time in Coggan
// power zones (derived from your FTP) in two modes: the zone you're in right now
// (live), or a fixed target zone. No HR / UserProfile needed — zones come from the
// FTP setting and power from Activity.Info. Shares the native styling (Palette +
// adaptive Layout) and the Timer-style superscript value with Time in Zone.
class TimeInPowerZoneView extends WatchUi.DataField {

    private const MODE_CURRENT = 0; // time in the zone you're in right now (switches live)
    private const MODE_TARGET  = 1; // time in a fixed target zone

    // Accumulated MILLISECONDS per zone. Index 0 = unset/invalid FTP, 1..7 = Z1..Z7.
    // compute() runs ~1 Hz, so we accumulate real elapsed time via timer deltas
    // (System.getTimer) rather than a flat +1s — this yields the sub-second part.
    private var _zoneMillis as Array<Number> = [0, 0, 0, 0, 0, 0, 0, 0];
    private var _lastMs as Number? = null;     // last getTimer() while actively counting
    private var _currentZone as Number = 0;

    private var _ftp as Number = 200;
    private var _mode as Number = 0;
    private var _targetZone as Number = 2;

    function initialize() {
        DataField.initialize();
        loadSettings();
    }

    function loadSettings() as Void {
        var f = Storage.getValue("ftp") as Number?;
        _ftp = (f != null) ? f : 200;
        var m = Storage.getValue("mode") as Number?;
        _mode = (m != null) ? m : 0;
        var t = Storage.getValue("targetZone") as Number?;
        _targetZone = (t != null) ? t : 2;
        // targetZone comes from GCM/Storage unvalidated; clamp to the valid zone range
        // (1..7) so it can't index _zoneMillis (size 8, indices 0..7) out of bounds.
        if (_targetZone < 1) {
            _targetZone = 1;
        } else if (_targetZone > 7) {
            _targetZone = 7;
        }
    }

    function compute(info as Activity.Info) as Void {
        loadSettings();

        var power = info.currentPower;
        var timerActive = (info.timerState == Activity.TIMER_STATE_ON);

        _currentZone = PowerCalc.zoneForPower(power, _ftp);

        // Accumulate the real wall-clock delta since the last active sample into the
        // current zone. getTimer() is monotonic ms-since-boot; guard against its
        // ~24.8-day wrap and large gaps (paused/backgrounded) by ignoring
        // non-positive or implausibly long deltas. When not actively counting we
        // drop the anchor so paused time is never billed to a zone.
        var now = System.getTimer();
        if (timerActive && _currentZone > 0) {
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

    // Zone number for the label, or "--" when FTP isn't configured yet (zone 0).
    private function zoneNum(shownZone as Number) as String {
        return (shownZone == 0) ? "--" : shownZone.format("%d");
    }

    private function textFull(shownZone as Number) as String {
        return "POWER ZONE " + zoneNum(shownZone);
    }

    private function textShort(shownZone as Number) as String {
        return "PWR Z" + zoneNum(shownZone);
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        var bgColor = getBackgroundColor();
        var r = (bgColor >> 16) & 0xFF;
        var g = (bgColor >> 8) & 0xFF;
        var b = bgColor & 0xFF;
        var dark = (r + g + b) < 384;
        var textColor = dark ? Palette.DARK_TEXT : Palette.LIGHT_TEXT;

        Background.clear(dc, dark);

        var shownZone = (_mode == MODE_TARGET) ? _targetZone : _currentZone;
        var full = textFull(shownZone);
        var short = textShort(shownZone);

        // Split the value: big main M:SS (sizes the font) + small raised hundredths,
        // like the native Timer field — so the hundredths don't shrink the number.
        var ms = _zoneMillis[shownZone];
        var mainStr = ZoneCalc.formatSeconds(ms / 1000);
        var csStr = ((ms % 1000) / 10).format("%02d");

        var L = Layout.compute(dc, dc.getWidth(), dc.getHeight(), full, short, mainStr);
        var useFull = L[:useFull] as Boolean;

        // Label: muted text up top, centered, like native fields.
        dc.setColor(textColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth() / 2, L[:labelY] as Number, L[:labelFont],
            useFull ? full : short, Graphics.TEXT_JUSTIFY_CENTER);

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
            var valStartX = (dc.getWidth() - (mainW + scW)) / 2;
            dc.drawText(valStartX, valueY, valueFont, mainStr,
                Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
            dc.drawText(valStartX + mainW, valueY - mainH / 3, scFont, csStr,
                Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        } else {
            dc.drawText(dc.getWidth() / 2, valueY, valueFont, mainStr,
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }
    }
}
