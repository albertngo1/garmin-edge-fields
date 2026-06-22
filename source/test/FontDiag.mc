import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.Test;
(:test)
function fontDiag(logger as Test.Logger) as Boolean {
    var d0 = makeDc(200, 120);
    if (d0 == null) { return true; }
    System.println("FONTS XTINY="+d0.getFontHeight(Graphics.FONT_XTINY)+" TINY="+d0.getFontHeight(Graphics.FONT_TINY)+" SMALL="+d0.getFontHeight(Graphics.FONT_SMALL));
    var s=System.getDeviceSettings(); var W=s.screenWidth; var H=s.screenHeight;
    var cells=[[W,H],[W,H/3],[W/2,H/5],[W/2,H/7]];
    for (var i=0;i<cells.size();i++){
        var w=cells[i][0] as Number; var h=cells[i][1] as Number;
        var d=makeDc(w,h);
        var L=Layout.compute(d,w,h,"♥ TIME IN ZONE 2","♥ ZONE 2","0:00");
        System.println("CELL "+w+"x"+h+" topPad(labelY)="+(L[:labelY] as Number)+" labelH="+(L[:labelH] as Number)+" labelMaxH="+(h*22/100)+" useFull="+L[:useFull]+" valueY="+(L[:valueY] as Number)+" valueH="+(L[:valueH] as Number));
    }
    return true;
}
