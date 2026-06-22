import Toybox.Application;
import Toybox.Application.Properties;
import Toybox.Application.Storage;
import Toybox.Lang;
import Toybox.WatchUi;

class TimeInZoneApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    // Setting keys -> default values. mode: 0 = time in CURRENT zone (switches
    // live), 1 = time in a fixed TARGET zone. targetZone: zone tracked in mode 1.
    private function settingDefaults() as Lang.Dictionary {
        return {"mode" => 0, "targetZone" => 2};
    }

    // Seed any unset setting with its default.
    function onStart(state as Lang.Dictionary?) as Void {
        var defs = settingDefaults();
        var keys = defs.keys();
        for (var i = 0; i < keys.size(); i++) {
            var k = keys[i];
            if (Storage.getValue(k) == null) {
                Storage.setValue(k, defs[k]);
            }
        }
    }

    // Mirror Garmin-Connect-Mobile property edits into Storage (the live source).
    function onSettingsChanged() as Void {
        var keys = settingDefaults().keys();
        for (var i = 0; i < keys.size(); i++) {
            var k = keys[i];
            var v = Application.Properties.getValue(k);
            if (v != null) {
                Storage.setValue(k, v);
            }
        }
    }

    function getInitialView() as [WatchUi.Views] or [WatchUi.Views, WatchUi.InputDelegates] {
        return [new TimeInZoneView()];
    }

    function getSettingsView() as [WatchUi.Views] or [WatchUi.Views, WatchUi.InputDelegates] or Null {
        return [new SettingsView(), new SettingsDelegate()];
    }
}
