import Toybox.Lang;

// Native activity palette for the Edge 1050 (from its personality.mss).
// Verified against the device profile by tools/check_native_palette.py.
module Palette {
    const LIGHT_BG   = 0xDCDCDC;
    const DARK_BG    = 0x17181D;
    const LIGHT_TEXT = 0x313253;
    const DARK_TEXT  = 0xFFFFFF;

    // Subtle native light-cell sheen: faint top-lighter -> bottom-darker tint a
    // flat fill can't match. Background.clear() gradients between these.
    const LIGHT_BG_TOP = 0xE2E2E2;
    const LIGHT_BG_BOT = 0xD2D2D2;
}
