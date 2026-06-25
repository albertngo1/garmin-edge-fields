import Toybox.Activity;
import Toybox.Application.Storage;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

// Carb burn rate — a live estimate of carbohydrate oxidation in grams/hour, so you
// can pace fueling against the ~60-120 g/hr endurance guidance. Derived from power
// and your FTP (intensity sets the carb fraction of energy burned), smoothed over a
// short rolling window like PW:HR. It's a population-average model, not lab
// measurement — a ballpark for fueling decisions. Shares the suite's native styling.
class CarbBurnView extends WatchUi.DataField {

    private const WINDOW = 10; // ~seconds of power smoothing (compute runs ~1 Hz)

    private var _power as Array<Number> = [];
    private var _ftp as Number = 200;
    private var _gPerHr as Float = 0.0;

    function initialize() {
        DataField.initialize();
        loadSettings();
    }

    function loadSettings() as Void {
        var f = Storage.getValue("ftp") as Number?;
        _ftp = (f != null) ? f : 200;
    }

    function compute(info as Activity.Info) as Void {
        loadSettings();
        var timerActive = (info.timerState == Activity.TIMER_STATE_ON);
        var p = info.currentPower;

        if (timerActive && p != null && p >= 0) {
            _power.add(p);
            if (_power.size() > WINDOW) {
                _power = _power.slice(1, null) as Array<Number>;
            }
        }

        var sum = 0;
        for (var i = 0; i < _power.size(); i++) {
            sum += _power[i];
        }
        var avg = (_power.size() > 0) ? (sum / _power.size()) : 0;
        _gPerHr = Fuel.carbGramsPerHour(avg, _ftp);
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        var bg = getBackgroundColor();
        var r = (bg >> 16) & 0xFF;
        var g = (bg >> 8) & 0xFF;
        var b = bg & 0xFF;
        var dark = (r + g + b) < 384;
        var textColor = dark ? Palette.DARK_TEXT : Palette.LIGHT_TEXT;
        Background.clear(dc, dark);

        var full = "CARBS g/h";
        var short = "g/h";
        var value = (_power.size() == 0) ? "--" : _gPerHr.toNumber().format("%d");

        var L = Layout.compute(dc, dc.getWidth(), dc.getHeight(), full, short, value);
        var useFull = L[:useFull] as Boolean;
        dc.setColor(textColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth() / 2, L[:labelY] as Number, L[:labelFont],
            useFull ? full : short, Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(dc.getWidth() / 2, L[:valueY] as Number, L[:valueFont], value,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}
