import Toybox.Application.Storage;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

// On-device settings (Menu button on the data field preview). Mirrors the
// Garmin-Connect-Mobile settings in resources/properties.xml so either path works.

class SettingsView extends WatchUi.View {

    function initialize() {
        View.initialize();
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth() / 2, dc.getHeight() / 2 - 30,
            Graphics.FONT_SMALL, "Press Menu\nfor settings",
            Graphics.TEXT_JUSTIFY_CENTER);
    }
}

class SettingsDelegate extends WatchUi.BehaviorDelegate {

    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onMenu() as Boolean {
        var menu = new WatchUi.Menu2({:title => "Settings"});
        menu.addItem(new WatchUi.MenuItem("Mode", null, "mode", null));
        menu.addItem(new WatchUi.MenuItem("Target Zone", null, "targetZone", null));
        WatchUi.pushView(menu, new SettingsMenuDelegate(), WatchUi.SLIDE_IMMEDIATE);
        return true;
    }
}

class SettingsMenuDelegate extends WatchUi.Menu2InputDelegate {

    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(menuItem as WatchUi.MenuItem) as Void {
        var id = menuItem.getId();
        if (!(id instanceof Lang.String)) { return; }
        var idStr = id as String;

        if (idStr.equals("mode")) {
            var menu = new WatchUi.Menu2({:title => "Mode"});
            menu.addItem(new WatchUi.MenuItem("Current Zone", null, "mode_0", null));
            menu.addItem(new WatchUi.MenuItem("Target Zone", null, "mode_1", null));
            WatchUi.pushView(menu, new ModeMenuDelegate(), WatchUi.SLIDE_IMMEDIATE);
        } else if (idStr.equals("targetZone")) {
            var menu = new WatchUi.Menu2({:title => "Target Zone"});
            for (var z = 1; z <= 5; z++) {
                menu.addItem(new WatchUi.MenuItem("Zone " + z, null, "zone_" + z, null));
            }
            WatchUi.pushView(menu, new TargetZoneMenuDelegate(), WatchUi.SLIDE_IMMEDIATE);
        }
    }
}

class ModeMenuDelegate extends WatchUi.Menu2InputDelegate {
    function initialize() { Menu2InputDelegate.initialize(); }

    function onSelect(menuItem as WatchUi.MenuItem) as Void {
        var id = menuItem.getId();
        if (id instanceof Lang.String) {
            var idStr = id as String;
            if (idStr.substring(0, 5).equals("mode_")) {
                var modeNum = idStr.substring(5, 6).toNumber();
                if (modeNum != null) {
                    Storage.setValue("mode", modeNum);
                }
            }
        }
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
    }
}

class TargetZoneMenuDelegate extends WatchUi.Menu2InputDelegate {
    function initialize() { Menu2InputDelegate.initialize(); }

    function onSelect(menuItem as WatchUi.MenuItem) as Void {
        var id = menuItem.getId();
        if (id instanceof Lang.String) {
            var idStr = id as String;
            if (idStr.substring(0, 5).equals("zone_")) {
                var z = idStr.substring(5, idStr.length()).toNumber();
                if (z != null) {
                    Storage.setValue("targetZone", z);
                }
            }
        }
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
    }
}
