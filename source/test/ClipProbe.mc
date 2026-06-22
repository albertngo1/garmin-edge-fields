import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.Test;
(:test)
function clipProbe(logger as Test.Logger) as Boolean {
    var dcM = makeDc(300,150);
    if (dcM == null) { return true; }
    var labels = ["PW/HR", "PW/HR Ø", "PW/HR LAP", "PW/HR 30s"];
    System.println("-- pw2hr FONT_MEDIUM label widths --");
    for (var i=0;i<labels.size();i++){
        System.println("  '"+labels[i]+"' = "+dcM.getTextWidthInPixels(labels[i], Graphics.FONT_MEDIUM)+"px");
    }
    System.println("FONT_NUMBER_MEDIUM height = "+dcM.getFontHeight(Graphics.FONT_NUMBER_MEDIUM)+"px; value '0.73' width = "+dcM.getTextWidthInPixels("0.73", Graphics.FONT_NUMBER_MEDIUM)+"px");
    var s=System.getDeviceSettings();
    System.println("SCREEN "+s.screenWidth+"x"+s.screenHeight);
    // representative small cells: half-width 2x2, and 7-field half cell
    var cells=[[s.screenWidth/2, s.screenHeight/2],[s.screenWidth/2, s.screenHeight/5],[s.screenWidth/3, s.screenHeight/3]];
    for (var c=0;c<cells.size();c++){
        System.println("  CELL "+cells[c][0]+"x"+cells[c][1]+" usableW="+(cells[c][0]-8)+" usableH="+(cells[c][1]-8));
    }
    return true;
}
