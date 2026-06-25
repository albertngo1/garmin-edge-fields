import Toybox.Activity;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

// Power-to-heart-rate ratio (watts per bpm) — a live aerobic-efficiency readout.
// Smoothed over a short rolling window so the instantaneous power jitter doesn't
// make it unreadable. Shares the native styling (Palette colors + adaptive Layout)
// with the Time in Zone field.
class PwHrView extends WatchUi.DataField {

    private const WINDOW = 10; // ~seconds of smoothing (compute runs ~1 Hz)

    private var _power as Array<Number> = [];
    private var _hr as Array<Number> = [];
    private var _ratio as Float = 0.0;

    function initialize() {
        DataField.initialize();
    }

    function compute(info as Activity.Info) as Void {
        var timerActive = (info.timerState == Activity.TIMER_STATE_ON);
        var p = info.currentPower;
        var h = info.currentHeartRate;

        if (timerActive && p != null && h != null && h > 0) {
            _power.add(p);
            _hr.add(h);
            if (_power.size() > WINDOW) {
                _power = _power.slice(1, null) as Array<Number>;
                _hr = _hr.slice(1, null) as Array<Number>;
            }
        }

        // Ratio of the window's summed power to summed HR (== avg power / avg HR).
        var sumP = 0;
        var sumH = 0;
        for (var i = 0; i < _power.size(); i++) {
            sumP += _power[i];
            sumH += _hr[i];
        }
        _ratio = (sumH > 0) ? (sumP.toFloat() / sumH.toFloat()) : 0.0;
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        var bg = getBackgroundColor();
        var r = (bg >> 16) & 0xFF;
        var g = (bg >> 8) & 0xFF;
        var b = bg & 0xFF;
        var dark = (r + g + b) < 384;
        var textColor = dark ? Palette.DARK_TEXT : Palette.LIGHT_TEXT;
        Background.clear(dc, dark);

        var label = "PW:HR";
        var value = (_ratio > 0.0) ? _ratio.format("%.2f") : "--";

        var L = Layout.compute(dc, dc.getWidth(), dc.getHeight(), label, label, value);
        dc.setColor(textColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth() / 2, L[:labelY] as Number, L[:labelFont], label,
            Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(dc.getWidth() / 2, L[:valueY] as Number, L[:valueFont], value,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}
