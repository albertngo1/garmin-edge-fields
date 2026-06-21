import Toybox.Graphics;
import Toybox.Lang;

// Cell layout math, factored out so it can be exercised by unit tests against
// off-screen buffers at every data-field cell size — label on top, value below,
// adaptive fonts so nothing clips or overlaps regardless of how the layout
// engine sizes the field.
module Layout {

    const PAD = 4; // min padding from any cell edge
    const GAP = 2; // min vertical gap between the label and the value

    // Label fonts, largest first.
    function labelFonts() as Array {
        return [Graphics.FONT_SMALL, Graphics.FONT_TINY, Graphics.FONT_XTINY];
    }

    // Value fonts, largest first (number fonts preferred for the time readout).
    function valueFonts() as Array {
        return [
            Graphics.FONT_NUMBER_MEDIUM,
            Graphics.FONT_NUMBER_MILD,
            Graphics.FONT_LARGE,
            Graphics.FONT_MEDIUM,
            Graphics.FONT_SMALL,
            Graphics.FONT_TINY,
            Graphics.FONT_XTINY
        ];
    }

    // Largest font whose text fits both maxWidth and maxHeight; falls back to the
    // smallest candidate if none fit.
    function fitFont(dc as Graphics.Dc, text as String, fonts as Array, maxWidth as Number, maxHeight as Number) as Graphics.FontType {
        for (var i = 0; i < fonts.size(); i++) {
            var f = fonts[i];
            if (dc.getTextWidthInPixels(text, f) <= maxWidth && dc.getFontHeight(f) <= maxHeight) {
                return f;
            }
        }
        return fonts[fonts.size() - 1];
    }

    // Choose label font + whether the full label fits. Prefer the full text at the
    // largest font that fits the width; if even the smallest font can't fit the
    // full text, use the short text. Returns {:useFull, :font}.
    function fitLabel(dc as Graphics.Dc, full as String, short as String, fonts as Array, maxWidth as Number) as Dictionary {
        for (var i = 0; i < fonts.size(); i++) {
            if (dc.getTextWidthInPixels(full, fonts[i]) <= maxWidth) {
                return {:useFull => true, :font => fonts[i]};
            }
        }
        for (var i = 0; i < fonts.size(); i++) {
            if (dc.getTextWidthInPixels(short, fonts[i]) <= maxWidth) {
                return {:useFull => false, :font => fonts[i]};
            }
        }
        return {:useFull => false, :font => fonts[fonts.size() - 1]};
    }

    // Compute the full layout for a cell. `fullLabel`/`shortLabel` are the complete
    // label strings (heart glyph included) used for sizing. Returns the chosen
    // label font, whether the full label was used, value font, and y positions.
    // Label is drawn at y = top of text; value is drawn VCENTER (y = center).
    function compute(dc as Graphics.Dc, width as Number, height as Number, fullLabel as String, shortLabel as String, value as String) as Dictionary {
        var maxW = width - 2 * PAD;
        if (maxW < 1) { maxW = 1; }

        var lbl = fitLabel(dc, fullLabel, shortLabel, labelFonts(), maxW);
        var labelFont = lbl[:font];
        var labelH = dc.getFontHeight(labelFont);
        var labelY = PAD;

        // The value occupies everything below the label (minus padding/gap).
        var regionTop = labelY + labelH + GAP;
        var regionBot = height - PAD;
        var regionH = regionBot - regionTop;
        if (regionH < 1) { regionH = 1; }

        var valueFont = fitFont(dc, value, valueFonts(), maxW, regionH);
        var valueH = dc.getFontHeight(valueFont);
        var valueY = (regionTop + regionBot) / 2;

        return {
            :useFull    => lbl[:useFull],
            :labelFont  => labelFont,
            :labelY     => labelY,
            :labelH     => labelH,
            :valueFont  => valueFont,
            :valueY     => valueY,
            :valueH     => valueH,
            :regionTop  => regionTop,
            :regionBot  => regionBot
        };
    }
}
