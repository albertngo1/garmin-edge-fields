import Toybox.Graphics;
import Toybox.Lang;

// Cell layout math, factored out so it can be exercised by unit tests against
// off-screen buffers at every data-field cell size — label on top, value below,
// adaptive fonts so nothing clips or overlaps regardless of how the layout
// engine sizes the field.
module Layout {

    const PAD = 4;  // min padding from the cell edges
    const GAP = 2;  // min vertical gap between the label and the value

    // Label fonts, largest first. Native data-field labels are small Roboto-Medium
    // (~14-18pt), so we stay in TINY/XTINY — never the larger FONT_SMALL.
    function labelFonts() as Array {
        return [Graphics.FONT_TINY, Graphics.FONT_XTINY];
    }

    // Value fonts, largest first. Native value is a big bold number font
    // (Garmin_Roboto_Bold ~44-48pt) → the FONT_NUMBER_* family, biggest first.
    function valueFonts() as Array {
        return [
            Graphics.FONT_NUMBER_HOT,
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
    // largest font that fits BOTH the width and a height cap (so the label stays
    // small like native fields, not a tall FONT_SMALL in a short cell). Falls back
    // to the short text, then the smallest font. Returns {:useFull, :font}.
    function fitLabel(dc as Graphics.Dc, full as String, short as String, fonts as Array, maxWidth as Number, maxHeight as Number) as Dictionary {
        for (var i = 0; i < fonts.size(); i++) {
            if (dc.getFontHeight(fonts[i]) <= maxHeight && dc.getTextWidthInPixels(full, fonts[i]) <= maxWidth) {
                return {:useFull => true, :font => fonts[i]};
            }
        }
        for (var i = 0; i < fonts.size(); i++) {
            if (dc.getFontHeight(fonts[i]) <= maxHeight && dc.getTextWidthInPixels(short, fonts[i]) <= maxWidth) {
                return {:useFull => false, :font => fonts[i]};
            }
        }
        var smallest = fonts[fonts.size() - 1];
        var fullFits = dc.getTextWidthInPixels(full, smallest) <= maxWidth;
        return {:useFull => fullFits, :font => smallest};
    }

    // Label top inset as a fraction of cell height. Native data fields float the
    // label near the top with real breathing room above it (not pinned to the
    // edge, and NOT centered as a block with the value). The firmware's exact
    // datafield label geometry isn't published in the SDK, so this is a
    // proportional inset tuned to match native — the one knob to adjust by eye.
    const LABEL_TOP_PCT = 12;

    // Compute the full layout for a cell. `fullLabel`/`shortLabel` are the complete
    // label strings (heart glyph included) used for sizing. Returns the chosen
    // label font, whether the full label was used, value font, and y positions.
    // Label is drawn at y = top of text; value is drawn VCENTER (y = center).
    //
    // Native single-field structure: the label sits at a fixed top inset, and the
    // value fills the whole region below it (sized as large as fits, like native's
    // big timer number) and is centered in that region — not label+value centered
    // as one block, and not shrunk to a slice about the cell midline.
    function compute(dc as Graphics.Dc, width as Number, height as Number, fullLabel as String, shortLabel as String, value as String) as Dictionary {
        var maxW = width - 2 * PAD;
        if (maxW < 1) { maxW = 1; }

        // Cap the label at ~22% of cell height so it stays small/native-like.
        var labelMaxH = height * 22 / 100;
        var lbl = fitLabel(dc, fullLabel, shortLabel, labelFonts(), maxW, labelMaxH);
        var labelFont = lbl[:font];
        var labelH = dc.getFontHeight(labelFont);

        // Label floats at a native-style top inset (not pinned to the edge).
        var labelY = height * LABEL_TOP_PCT / 100;
        if (labelY < PAD) { labelY = PAD; }
        var labelBottom = labelY + labelH;

        // Value fills the whole region BELOW the label (down to the bottom padding)
        // so it renders as large as native's big timer number, then sits centered
        // in that region. Using the full region — not a symmetric slice about the
        // cell centre — is what keeps the timer big and properly spaced.
        var regionTop = labelBottom + GAP;
        var regionBot = height - PAD;
        var valueMaxH = regionBot - regionTop;
        if (valueMaxH < 1) { valueMaxH = 1; }
        var valueFont = fitFont(dc, value, valueFonts(), maxW, valueMaxH);
        var valueH = dc.getFontHeight(valueFont);
        var valueY = (regionTop + regionBot) / 2;   // VCENTER in the region below the label

        return {
            :useFull    => lbl[:useFull],
            :labelFont  => labelFont,
            :labelY     => labelY,
            :labelH     => labelH,
            :valueFont  => valueFont,
            :valueY     => valueY,
            :valueH     => valueH
        };
    }
}
