import Toybox.Lang;
import Toybox.Graphics;

// Shared cell-background fill for every custom DataField in the suite.
//
// getBackgroundColor() only reports binary black/white (not the native theme
// tint), so each field clears manually with its per-device Palette values. The
// native LIGHT cell isn't a flat fill though — it carries a faint top-lighter →
// bottom-darker sheen that a flat #DCDCDC can't match (the custom cell reads
// noticeably flatter than the native ones in light theme). Background.clear()
// paints a subtle vertical gradient between Palette.LIGHT_BG_TOP/BOT so the
// custom fields sit consistently next to native cells.
//
// Dark theme stays a flat clear (no observed mismatch there). Mono profiles set
// TOP == BOT, so the gradient degenerates to a flat fill = native pure white.
module Background {

    // Clear `dc` to the native cell background. `dark` is the theme already
    // resolved by the caller from getBackgroundColor() luminance.
    function clear(dc as Graphics.Dc, dark as Boolean) as Void {
        if (dark) {
            dc.setColor(Palette.DARK_BG, Palette.DARK_BG);
            dc.clear();
            return;
        }

        var top = Palette.LIGHT_BG_TOP;
        var bot = Palette.LIGHT_BG_BOT;

        // Flat fast-path when there's no gradient to draw (mono devices).
        if (top == bot) {
            dc.setColor(top, top);
            dc.clear();
            return;
        }

        var w = dc.getWidth();
        var h = dc.getHeight();
        var tr = (top >> 16) & 0xFF;
        var tg = (top >> 8) & 0xFF;
        var tb = top & 0xFF;
        var dr = ((bot >> 16) & 0xFF) - tr;
        var dg = ((bot >> 8) & 0xFF) - tg;
        var db = (bot & 0xFF) - tb;
        var span = (h > 1) ? (h - 1) : 1;

        // One 1px row per scanline, colour lerped top→bottom. onUpdate runs ~1 Hz
        // and h is at most a few hundred px, so the per-frame cost is negligible.
        for (var y = 0; y < h; y++) {
            var r = tr + (dr * y) / span;
            var g = tg + (dg * y) / span;
            var b = tb + (db * y) / span;
            var col = (r << 16) | (g << 8) | b;
            dc.setColor(col, col);
            dc.fillRectangle(0, y, w, 1);
        }
    }
}
