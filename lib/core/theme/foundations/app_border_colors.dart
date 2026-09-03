import 'package:flutter/material.dart';

/// Every line the app draws around or inside a component.
///
/// **Split out of `AppColors` at M100.1**, alongside [AppSurfaceColors], for the
/// reason `AppMaterialRoles` was split off at M99.5: one file had six roles in
/// it and had passed the guard's 400-line ceiling again.
///
/// The family is a ladder of its own, and the order is the point — a card's
/// resting edge is quieter than a control's, a control's quieter than a picked
/// one's, and the focus ring is louder than all of them in both modes. Each
/// value carries the measurement that puts it in that order.
///
/// Nothing changed value in that move. M100.26 then moved every value onto
/// Tokyo's: the resting edge is Tokyo's `alpha.black[12]` divider (light) and
/// its `#272C48` divider (dark); the picked edge is Tokyo's `primary.main`
/// light and its dark-theme `primary` dark; the accent and option edges are
/// tints of Tokyo's primary; the control edge is a low-chroma grey at Tokyo's
/// ink hue, because `app_palette_test.dart` holds the light canvas — input
/// border included — under chroma 0.06.
///
/// **The palette is Tokyo's since M100.26.** The owner asked for the theme to
/// match `ntgptit/tokyo-react-admin-dashboard`, and every value in this file is
/// now one of three things: a Tokyo literal, a Tokyo primitive flattened over a
/// Tokyo surface (its `alpha.black`/`primary.lighter` idiom, precomputed as
/// AD-14 requires), or the value this file already had re-hued onto a Tokyo
/// key with its tone and chroma kept — so every L\* step and ratio the tests
/// hold survived without a rule moving. Measurements quoted below that predate
/// M100.26 describe the A2 palette and are kept as the record of *why* a token
/// exists; the current numbers are the tests' output.
abstract final class AppBorderColors {
  /// Hairline between rows, around cards, and an input at rest.
  ///
  /// **The two modes are no longer matched on this number, and that is the
  /// point.** Until M4.10h both stood at 1.82:1 against the card, because the
  /// border was the only depth cue either had. Light now has a shadow
  /// (`AppElevation`), so its border can stand down to 1.50:1; dark has no
  /// shadow — measured, not chosen: at the bottom of the lightness scale a
  /// shadow moves the page by ΔL* 0.26 — so its border keeps carrying the edge,
  /// at 1.69:1 since the ladder moved onto the page's hue (1.82:1 before).
  ///
  /// **That drop is a consequence, not a decision.** Both the border and the
  /// card it is drawn on gained chroma at their new hue, and a border reads
  /// against its card: 1.69 is what holding the border's L* step at the new
  /// saturation produces. It stays well above the 1.40 that was measured as too
  /// weak, and what the tests actually pin — the total lift of a card off its
  /// page — is unaffected, because the border was deliberately taken out of that
  /// measurement at M4.10h.
  ///
  /// Matching the borders was the right rule when the border was everything, and
  /// it is the wrong rule now: it would force light to draw a frame it no longer
  /// needs. What `app_theme_test.dart` pins instead is the **step a card's edge
  /// produces** — ΔL* 8.04 in light against 6.58 in dark — which is the thing a
  /// reader actually perceives, and which stays symmetric while the mechanisms
  /// differ.
  ///
  /// Both values are hue 240 and inside the light canvas's chroma budget. The
  /// history is worth keeping: `#D7DAE3` (1.40:1) was too weak when it was the
  /// only cue, `#BEC0C3` (1.82:1) was right then and too heavy now.
  static const Color borderSubtleLight = Color(0xFFE4E7EA);

  // Lifted from 0xFF403D67 so a fill-less hairline (a divider on the dark page)
  // reads on OLED. Same hue and saturation (0.41), lightness only.
  static const Color borderSubtleDark = Color(0xFF272C48);

  static const Color borderSelectedLight = Color(0xFF5569FF);

  /// See [borderSelectedLight]. Dimmer than the focus indicator on purpose —
  /// that ring is `scheme.primary` at [AppStroke.focus].
  static const Color borderSelectedDark = Color(0xFF8C7CF0);

  /// The hairline a panel wears when it is the screen's *answer* rather than
  /// one row among many — today the Library's Today card.
  ///
  /// **The brand at 38% over the surface, resolved here rather than at paint
  /// time.** `primaryContainer` was tried and is a fill: against `surface` it
  /// is a step of ΔL* 4, which reads as a slightly different white rather than
  /// as an edge (owner review, 2026-08-20). Blending keeps the hue and buys
  /// the contrast, and a resolved constant is what MX-VIS-002 rule R7 asks
  /// for — a translucent border composites against whatever is behind it, and
  /// the audit cannot read it back.
  static const Color borderAccentLight = Color(0xFFAAB4FF);

  /// Same recipe as [borderAccentLight], over the dark surface.
  /// **Solved against the one rule that matters here, and it is not the same
  /// recipe as [borderAccentLight]** (M99.98). It shipped as `#31306F`, which
  /// measures **1.33:1** on `MxCard.accent`'s own fill while the plain hairline
  /// every other card used to wear measured **2.04:1** — the one recipe whose
  /// job is emphasis had the faintest edge on the screen. Worse, the ranking
  /// flipped between modes: in light the accent edge is 1.89:1 against the
  /// hairline's 1.45, so the same recipe read "emphasised" in one mode and
  /// "receded" in the other.
  ///
  /// `#6560B8` measures **2.93:1** on that fill — above the old hairline in both
  /// modes, and still short of the focus ring, which has to stay the loudest
  /// edge a card can wear.
  static const Color borderAccentDark = Color(0xFF7063C0);

  /// The resting edge of a selectable **card** — `MxCard.option`.
  ///
  /// **Split off `borderControl` at M100.2, and the split is the point.** The
  /// owner's review asked why a card that must draw a border draws it in a
  /// colour unrelated to the brand. The answer for the *input* border is a
  /// recorded rule — `app_palette_test.dart`'s "the light canvas carries no
  /// lavender tint" names `input` explicitly and caps the tint at 0.06 — and
  /// that rule is right: an empty text field is canvas, and putting the accent
  /// on every one of them is the density problem M99.98 just took off Library.
  ///
  /// But that rule names the *input*, not every consumer of one token. An
  /// option card is a card, sitting on a page, next to other cards whose edges
  /// M99.99 already moved into the brand family. It was borrowing canvas
  /// furniture, and the borrowing is what made it look wrong.
  ///
  /// `#8887CE` measures **3.18:1** on a card and **3.01** on the page — above
  /// the 3:1 WCAG 1.4.11 asks of a control boundary, where `borderControl`
  /// managed 3.19 and 3.02 — at chroma **0.105**, roughly nine times the grey
  /// it replaces. It is deliberately **1.34 quieter than
  /// [borderSelectedLight]**, so a picked option still wins its own row.
  ///
  /// **Two things it does not touch, and both are deliberate.** The input
  /// border keeps `borderControl` and its canvas rule. So does
  /// `guess_option_item_widget`, which writes down that its row "is a control
  /// (WCAG 1.4.11), not a card" — the same distinction from the other side.
  static const Color borderOptionLight = Color(0xFF8896FF);

  /// See [borderOptionLight]. Measured on the fill `.option` actually has in
  /// dark (`surface`, since the recipe is flat): **3.22:1**, chroma 0.120, and
  /// 1.37 quieter than [borderSelectedDark].
  static const Color borderOptionDark = Color(0xFF5B65B2);

  /// A control's edge at the 3:1 WCAG 1.4.11 asks. Why a control and not a
  /// card, and the measurements: `AppSemanticColors.borderControl`.
  ///
  /// **"Cleared against every neighbour it touches" is what this comment used
  /// to say, and it was not true.** It had been measured on two grounds — the
  /// page and `surface` — because those are the two a token review naturally
  /// reaches for. The outlined button and the empty text field spend most of
  /// their life on a third: `surfaceContainer`, the fill of every card that
  /// holds a row.
  ///
  /// Both modes were raised at M100.3, for the same reason and by very
  /// different amounts. Light was at **2.94** on `surfaceContainer` and is now
  /// **3.06**: two steps darker, chroma untouched at 0.031 — far under the 0.06
  /// the light-canvas rule caps an input border at, which is the constraint
  /// that makes darkening the only direction available here.
  ///
  /// **Light draws 0 px on that ground today** — the census found the light
  /// card is `surface`, not `surfaceContainer`, so this is debt rather than a
  /// live defect. It is paid anyway: a rule that holds in one mode and is
  /// waived in the other stops being a rule and becomes a note, and the next
  /// screen to put an outlined button on a light `surfaceContainer` would
  /// inherit the failure with nothing objecting.
  /// Darkened from `#8A8A92` at M100.22 by the switch, which is the first
  /// component to read this role against the *top* of the surface ladder.
  ///
  /// M3's unselected switch is `outline` on `surfaceContainerHighest`, and the
  /// app had been avoiding that pairing — thumb re-pointed to
  /// `onSurfaceVariant`, track to `surfaceMuted` — because `#8A8A92` scores
  /// **2.72:1** on `#E3E5EC`, under the 3:1 WCAG 1.4.11 asks of the visual
  /// information identifying a control's state. On a switch the thumb *is* the
  /// state, so the exemption does not apply.
  ///
  /// `#7D7D85` is the same hue (240) at the same chroma (0.031), 5.07 L\*
  /// lower, and it clears the pairing at **3.24:1**. Every other ground this
  /// role is drawn on improves, because all of them are lighter than it:
  ///
  /// | ground | was | now |
  /// |---|---|---|
  /// | `surfaceContainerHighest` | 2.72 | 3.24 |
  /// | `surface` | 3.32 | 3.95 |
  /// | page | 3.14 | 3.74 |
  /// | `surfaceContainer` | 3.06 | 3.65 |
  ///
  /// Darkening was the only lever available: the alternative is lowering
  /// `surfaceContainerHighest`, and it is the top rung — pushing it down
  /// compresses it into `surfaceContainerHigh` and breaks the ladder to fix a
  /// control.
  static const Color borderControlLight = Color(0xFF6F727B);

  /// Raised from `#66628D` at M100.3, and the census is the reason.
  ///
  /// Every one of the 51 dark goldens was scanned for pixels of this colour and
  /// asked which colour each one *touches*. Four grounds, and the third is the
  /// one two years of review never measured:
  ///
  /// | ground | px adjacent | old `#66628D` | now `#6E6A98` |
  /// |---|---|---|---|
  /// | page `#0A082D` | 40 342 | 3.41 | 3.85 |
  /// | `surface` `#1A1838` | 8 012 | 3.00 | 3.39 |
  /// | **`surfaceContainer` `#221E44`** | **5 858** | **2.76** | **3.12** |
  /// | `surfaceMuted`, `primaryContainer` | 0 | — | — |
  ///
  /// The same census in light returns 0 px on `surfaceContainer`, because a
  /// light card is `surface` and a dark one is `surfaceContainer` — an
  /// asymmetry in the palette that is exactly why one mode shipped the defect
  /// and the other only carried it as debt.
  ///
  /// **A card's edge would have been exempt; a control's is not.**
  /// `app_high_contrast_test.dart` writes the distinction down — "a card is
  /// identified by its content and its edge is decoration, which is the
  /// exemption WCAG grants". The two components reading this token are an
  /// outlined button and a text field, and a control's boundary is the
  /// information 1.4.11 exists to protect.
  ///
  /// The rise is 0.44 of a ratio point on the page and keeps the ladder in
  /// order: `borderSubtle` 2.32 → this 3.85 → `borderSelected` 5.00 →
  /// `focusRing` 6.26. The two grounds at 0 px are left failing on purpose —
  /// sizing a token to a pairing nothing draws is how a palette drifts bright.
  /// Raised again at M100.22, for the mirror of the reason light was lowered:
  /// `#6E6A98` scored **2.47:1** on `surfaceContainerHighest`, which in dark is
  /// `#332F58`. `#7D79A2` holds hue 245 and clears it at **3.04:1**, and every
  /// other ground improves because all of them are darker than it:
  ///
  /// | ground | was | now |
  /// |---|---|---|
  /// | `surfaceContainerHighest` | 2.47 | 3.04 |
  /// | `surface` | 3.39 | 4.16 |
  /// | page | 3.85 | 4.72 |
  /// | `surfaceContainer` | 3.12 | 3.84 |
  ///
  /// It stays well under `onSurfaceVariant` (L\* 52.56 against 69.43), so the
  /// edge is still quieter than the secondary label it sits beside — the
  /// ordering the M100.3 census established, kept while the number moved.
  static const Color borderControlDark = Color(0xFF747BA3);
}
