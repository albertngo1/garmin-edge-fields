import Toybox.Lang;

// Native activity palette for Edge 540 / 840 / Explore 2 / MTB — plain
// black/white high-contrast (these profiles use no tinted background/text).
module Palette {
    const LIGHT_BG   = 0xFFFFFF;
    const DARK_BG    = 0x000000;
    const LIGHT_TEXT = 0x000000;
    const DARK_TEXT  = 0xFFFFFF;

    // Mono profiles render a flat native background — no sheen. Top == bottom so
    // Background.clear() degenerates to a flat fill (matches native pure white).
    const LIGHT_BG_TOP = 0xFFFFFF;
    const LIGHT_BG_BOT = 0xFFFFFF;
}
