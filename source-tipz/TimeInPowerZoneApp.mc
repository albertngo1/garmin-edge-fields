import Toybox.Application;
import Toybox.Application.Properties;
import Toybox.Application.Storage;
import Toybox.Lang;
import Toybox.WatchUi;

class TimeInPowerZoneApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    // mode: 0 = time in CURRENT power zone (switches live), 1 = time in a fixed
    // TARGET zone. ftp: functional threshold power (watts) the zones are derived
    // from. targetZone: which zone to track in mode 1.
    function onStart(state as Lang.Dictionary?) as Void {
        seed("ftp", 200);
        seed("mode", 0);
        seed("targetZone", 2);
    }

    // Mirror Garmin-Connect-Mobile property edits into Storage (the live source).
    function onSettingsChanged() as Void {
        syncProp("ftp");
        syncProp("mode");
        syncProp("targetZone");
    }

    private function seed(key as String, def as Lang.Number) as Void {
        if (Storage.getValue(key) == null) {
            Storage.setValue(key, def);
        }
    }

    private function syncProp(key as String) as Void {
        var v = Application.Properties.getValue(key);
        if (v != null) {
            Storage.setValue(key, v);
        }
    }

    function getInitialView() as [WatchUi.Views] or [WatchUi.Views, WatchUi.InputDelegates] {
        return [new TimeInPowerZoneView()];
    }

    function getSettingsView() as [WatchUi.Views] or [WatchUi.Views, WatchUi.InputDelegates] or Null {
        return [new SettingsView(), new SettingsDelegate()];
    }
}
