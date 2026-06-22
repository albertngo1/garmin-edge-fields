import Toybox.Application;
import Toybox.Application.Properties;
import Toybox.Application.Storage;
import Toybox.Lang;
import Toybox.WatchUi;

class CarbBurnApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    // ftp: functional threshold power (watts); the carb-fraction curve is keyed off
    // intensity as a % of it. Set in Garmin Connect Mobile.
    function onStart(state as Lang.Dictionary?) as Void {
        seed("ftp", 200);
    }

    function onSettingsChanged() as Void {
        syncProp("ftp");
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
        return [new CarbBurnView()];
    }
}
