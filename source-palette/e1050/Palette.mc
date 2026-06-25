import Toybox.Lang;

// Native activity palette for the Edge 1050 (from its personality.mss).
// Verified against the device profile by tools/check_native_palette.py.
// LIGHT_BG overrides the profile's #DCDCDC grey to pure white by preference
// (brighter than native) — see OVERRIDES in tools/check_native_palette.py.
module Palette {
    const LIGHT_BG   = 0xFFFFFF;
    const DARK_BG    = 0x17181D;
    const LIGHT_TEXT = 0x313253;
    const DARK_TEXT  = 0xFFFFFF;

    // Pure-white preference: flat (top == bot) so Background.clear() fills solid
    // white with no native grey sheen.
    const LIGHT_BG_TOP = 0xFFFFFF;
    const LIGHT_BG_BOT = 0xFFFFFF;
}
