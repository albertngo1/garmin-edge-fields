import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.Test;

// These tests render the field's layout into off-screen buffers at every
// representative Edge data-field cell size and assert the label and value
// never clip the cell edges and never overlap each other — i.e. padding and
// spacing hold up however the layout engine sizes the field.

const HEART_T = "♥ ";

// Build an off-screen Dc of the given size (handles both buffered-bitmap APIs).
function makeDc(w as Number, h as Number) as Graphics.Dc? {
    var bm;
    if (Graphics has :createBufferedBitmap) {
        var ref = Graphics.createBufferedBitmap({:width => w, :height => h});
        bm = ref.get();
    } else {
        bm = new Graphics.BufferedBitmap({:width => w, :height => h});
    }
    if (bm == null) { return null; }
    return bm.getDc();
}

// Representative cell sizes for Edge data screens, derived from the device's
// real screen dimensions: full field, 2/3-field rows, 2x2 quad, and the squat
// cells of the 7- and 10-field layouts (full-width row + half cells).
function cellSizes() as Array {
    var s = System.getDeviceSettings();
    var w = s.screenWidth;
    var h = s.screenHeight;
    return [
        [w, h],                          // 1 field (full screen)
        [w, (h / 2)],                    // 2 fields
        [w, (h / 3)],                    // 3 fields
        [(w / 2), (h / 2)],              // 2x2 quad
        [w, (h / 5)],                    // 7/10-field full-width row
        [(w / 2), (h / 5)],              // 7/10-field half cell
        [(w / 2), (h / 4)]               // narrow half cell
    ];
}

// Core assertion for one cell + one value string.
function checkCell(logger as Test.Logger, w as Number, h as Number, full as String, short as String, value as String) as Void {
    var dc = makeDc(w, h);
    // Fail loudly rather than silently skip — a null buffer would otherwise make
    // these tests pass without ever checking anything.
    Test.assertMessage(dc != null, "no off-screen Dc for " + w + "x" + h);

    var pad = Layout.PAD;
    var maxW = w - 2 * pad;

    var L = Layout.compute(dc, w, h, full, short, value);
    var labelFont = L[:labelFont];
    var useFull = L[:useFull] as Boolean;
    var labelStr = useFull ? full : short;

    var labelW = dc.getTextWidthInPixels(labelStr, labelFont);
    var valueW = dc.getTextWidthInPixels(value, L[:valueFont]);
    var labelY = L[:labelY] as Number;
    var labelBottom = labelY + (L[:labelH] as Number);
    var valueH = L[:valueH] as Number;
    var valueTop = (L[:valueY] as Number) - valueH / 2;
    var valueBottom = (L[:valueY] as Number) + valueH / 2;

    var ctx = w + "x" + h + " '" + value + "'";

    // Horizontal: nothing wider than the padded cell.
    Test.assertMessage(labelW <= maxW, "label clips " + ctx + " (" + labelW + ">" + maxW + ")");
    Test.assertMessage(valueW <= maxW, "value clips " + ctx + " (" + valueW + ">" + maxW + ")");

    // Top/bottom padding respected (1px tolerance for integer rounding).
    Test.assertMessage(labelY >= pad - 1, "label above top pad " + ctx);
    Test.assertMessage(valueBottom <= h - pad + 1, "value below bottom pad " + ctx);

    // No vertical overlap between label and value.
    Test.assertMessage(labelBottom + Layout.GAP <= valueTop + 1, "label/value overlap " + ctx +
        " (labelBottom=" + labelBottom + " valueTop=" + valueTop + ")");
}

(:test)
function testSpacingAcrossCellSizes(logger as Test.Logger) as Boolean {
    var cells = cellSizes();
    // Current-zone mode labels (heart + uppercase), plus both value lengths.
    var full = HEART_T + "TIME IN ZONE";
    var short = HEART_T + "TIME";
    var values = ["0:00", "59:59", "1:23:45"];

    for (var c = 0; c < cells.size(); c++) {
        var w = cells[c][0] as Number;
        var h = cells[c][1] as Number;
        for (var v = 0; v < values.size(); v++) {
            checkCell(logger, w, h, full, short, values[v] as String);
        }
    }
    return true;
}

(:test)
function testSpacingTargetModeLabels(logger as Test.Logger) as Boolean {
    var cells = cellSizes();
    // Target-zone mode labels: "TIME IN Z2" / "Z2".
    var full = HEART_T + "TIME IN Z2";
    var short = HEART_T + "Z2";
    var values = ["0:00", "1:23:45"];

    for (var c = 0; c < cells.size(); c++) {
        var w = cells[c][0] as Number;
        var h = cells[c][1] as Number;
        for (var v = 0; v < values.size(); v++) {
            checkCell(logger, w, h, full, short, values[v] as String);
        }
    }
    return true;
}
