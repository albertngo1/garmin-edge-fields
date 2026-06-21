import Toybox.Application;
import Toybox.Application.Properties;
import Toybox.Application.Storage;
import Toybox.Lang;
import Toybox.WatchUi;

class TimeInZoneApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state as Lang.Dictionary?) as Void {
        // mode: 0 = time in CURRENT zone (switches live), 1 = time in a fixed TARGET zone
        if (Storage.getValue("mode") == null) {
            Storage.setValue("mode", 0);
        }
        // targetZone: which zone to track in mode 1 (default Z2 for base-mile tracking)
        if (Storage.getValue("targetZone") == null) {
            Storage.setValue("targetZone", 2);
        }
    }

    // Called when settings are changed via Garmin Connect Mobile
    function onSettingsChanged() as Void {
        var mode = Application.Properties.getValue("mode");
        if (mode != null) {
            Storage.setValue("mode", mode);
        }
        var targetZone = Application.Properties.getValue("targetZone");
        if (targetZone != null) {
            Storage.setValue("targetZone", targetZone);
        }
    }

    function getInitialView() as [WatchUi.Views] or [WatchUi.Views, WatchUi.InputDelegates] {
        return [new TimeInZoneView()];
    }

    function getSettingsView() as [WatchUi.Views] or [WatchUi.Views, WatchUi.InputDelegates] or Null {
        return [new SettingsView(), new SettingsDelegate()];
    }
}
