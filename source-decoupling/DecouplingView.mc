import Toybox.Activity;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

// Aerobic decoupling — how much your power-to-heart-rate efficiency drifts from the
// first half of the ride to the second. Low drift = aerobic durability; rising
// drift = cardiac drift / fatigue. The classic aerobic-base benchmark is < 5%.
//
// Power and HR are summed into one bucket per elapsed minute, so the first/second
// half can be re-split as the ride grows without storing every second (a 6-hour
// ride is ~360 buckets). Shares the native styling (Palette + adaptive Layout)
// with the rest of the suite — and the power+HR basis of PW:HR.
class DecouplingView extends WatchUi.DataField {

    private var _sumP as Array<Number> = [];   // summed power per elapsed minute
    private var _sumH as Array<Number> = [];   // summed HR per elapsed minute
    private var _drift as Float? = null;

    function initialize() {
        DataField.initialize();
    }

    function compute(info as Activity.Info) as Void {
        var timerActive = (info.timerState == Activity.TIMER_STATE_ON);
        var p = info.currentPower;
        var h = info.currentHeartRate;
        var t = info.timerTime;   // elapsed timer time, ms

        if (timerActive && p != null && h != null && h > 0 && t != null) {
            var idx = (t / 1000) / 60;   // minute bucket index
            while (_sumP.size() <= idx) {
                _sumP.add(0);
                _sumH.add(0);
            }
            _sumP[idx] = _sumP[idx] + p;
            _sumH[idx] = _sumH[idx] + h;
        }
        _drift = Decouple.percent(_sumP, _sumH);
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        var bg = getBackgroundColor();
        var r = (bg >> 16) & 0xFF;
        var g = (bg >> 8) & 0xFF;
        var b = bg & 0xFF;
        var dark = (r + g + b) < 384;
        var textColor = dark ? Palette.DARK_TEXT : Palette.LIGHT_TEXT;
        Background.clear(dc, dark);

        var full = "PW:HR DRIFT %";
        var short = "DRIFT %";

        var value;
        var valColor = textColor;
        if (_drift == null) {
            value = "--";
        } else {
            var d = _drift as Float;
            value = d.format("%.1f");
            // Color by aerobic durability: < 5% well-coupled (good), 5-10% moderate,
            // > 10% significant drift. Negative drift (efficiency rose) is good too.
            if (d < 5.0) {
                valColor = dark ? Graphics.COLOR_GREEN : Graphics.COLOR_DK_GREEN;
            } else if (d < 10.0) {
                valColor = Graphics.COLOR_ORANGE;
            } else {
                valColor = Graphics.COLOR_RED;
            }
        }

        var L = Layout.compute(dc, dc.getWidth(), dc.getHeight(), full, short, value);
        var useFull = L[:useFull] as Boolean;
        dc.setColor(textColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth() / 2, L[:labelY] as Number, L[:labelFont],
            useFull ? full : short, Graphics.TEXT_JUSTIFY_CENTER);
        dc.setColor(valColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth() / 2, L[:valueY] as Number, L[:valueFont], value,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}
