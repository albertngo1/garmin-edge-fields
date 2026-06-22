import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.Test;
(:test)
function valDiag(logger as Test.Logger) as Boolean {
    var s=System.getDeviceSettings(); var W=s.screenWidth; var H=s.screenHeight;
    var cells=[[W,H],[W,H/3],[W/2,H/2],[W/2,H/5]];
    var lf="♥ TIME IN ZONE 2"; var ls="♥ ZONE 2";
    for (var i=0;i<cells.size();i++){
        var w=cells[i][0] as Number; var h=cells[i][1] as Number;
        var d=makeDc(w,h); if(d==null){continue;}
        var oldL=Layout.compute(d,w,h,lf,ls,"0:00.00");   // OLD: sized on full hundredths
        var newL=Layout.compute(d,w,h,lf,ls,"0:00");       // NEW: sized on main only
        System.println("CELL "+w+"x"+h+" valueFontH OLD(0:00.00)="+(oldL[:valueH] as Number)+"  NEW(0:00)="+(newL[:valueH] as Number)+"  labelY="+(newL[:labelY] as Number));
    }
    return true;
}
