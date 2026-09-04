/// The glyph register (A20.1 P2-19, A13 §7.2).
///
/// **One meaning, one glyph, one drawing style** — outlined Material, never
/// `_rounded`, which was three files' habit rather than a policy. Recorded as
/// prose next to the tokens because the decisions are what a scan cannot
/// infer; `glyph_register_test.dart` pins the ones a scan *can* see.
///
/// | meaning | glyph |
/// |---|---|
/// | tag | `sell_outlined` |
/// | flag set / flag action / unflag action | `flag` / `flag_outlined` / `flag` |
/// | not started (New filter) | `circle_outlined` — the only use of the glyph |
/// | row picked (multi-select) | `check_box_outlined` / `check_box_outline_blank` |
/// | one option chosen (pick-one) | `radio_button_checked` / `radio_button_unchecked`, or the pill's tick |
/// | your answer was wrong | `close` |
/// | history | `history` |
/// | due / when | `schedule` |
/// | restore | `restore` |
/// | share | `share` — `ios_share` on an Android-only target was a platform lie |
/// | folded / more | `more_horiz` in the strip; `…` in a header line (argued, A13 §8) |
library;
