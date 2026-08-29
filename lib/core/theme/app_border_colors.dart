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
/// Nothing here changed value. This file is a move.
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
  static const Color borderSubtleLight = Color(0xFFD2D2DD);

  // Lifted from 0xFF403D67 so a fill-less hairline (a divider on the dark page)
  // reads on OLED. Same hue and saturation (0.41), lightness only.
  static const Color borderSubtleDark = Color(0xFF4C487A);

  /// Inset tile, chip, icon container.
  /// The callout surface: a panel the screen wants noticed, at the quietest
  /// weight that still reads as *noticed*.
  ///
  /// **A whisper of brand, not a step of grey** (M99.98). `MxCard.tonal` shipped
  /// on `secondaryContainer`, which is `#E4E6EC` — chroma 0.0084, effectively
  /// neutral, and **5.24 L\* below the page**. A callout that sits back and
  /// carries no hue is indistinguishable from a disabled block, and Study Home's
  /// resume card — the screen's primary action — was the greyest thing on it.
  ///
  /// The proportions come from the owner's reference concept, measured: its
  /// callout sits **0.89 L\* below its page** with **1.6× the page's chroma**.
  /// `#F1F1FC` is 1.11 below this page with **3.6×** its chroma, so what marks
  /// it is hue rather than weight. Body ink measures 15.61:1 on it.
  /// The edge a *picked* card wears.
  ///
  /// **Brand family, and the measurement that ruled it out no longer
  /// applies** (M99.99). This was `ColorScheme.secondary` — `#4E5468`, chroma
  /// **0.0337**, roughly a fifth of what the brand colours carry (focus ring
  /// 0.1928, primary 0.1699). A slate line around a brand-tinted fill is the
  /// card saying two different things about the same state, which is what
  /// M99.98 left behind when it moved the fill and not the edge.
  ///
  /// `secondary` was chosen for a real reason, written down: dark `primary` on
  /// `surface` measures 2.90:1, under WCAG 1.4.11's 3:1. **That measurement is
  /// against `surface`**, and since M99.98 a selected card's edge does not sit
  /// on `surface` — it sits on [surfaceSelectedLight]. On that ground `#6E6ECE`
  /// measures **3.72:1**, and the dark pair **3.21:1** on `#332F58`.
  ///
  /// **Why not `primary` or `focusRing` themselves.** Today the ring is told
  /// apart from the selected edge by *hue* alone: `#4E5468` and `#4141C0` are
  /// **1.02:1** apart in luminance. Give the edge the brand hue and that
  /// distinction is gone, so these two are picked to differ from the ring by
  /// weight instead — lighter than it in light, dimmer in dark. The ring stays
  /// the loudest edge a card can wear, in both modes.
  /// The hairline *inside* a card, between the rows of one list.
  ///
  /// **Only inside** (M100.0). Cards stopped drawing an outer edge at M99.94
  /// because a screen of framed boxes reads as frames rather than surfaces;
  /// this is the opposite case — rows that belong to one list need to be told
  /// apart *from each other*, and the reference concept divides exactly those:
  /// its `RESULT BREAKDOWN` and `MASTERY BY DECK` rows, never the card around
  /// them.
  ///
  /// `#E9ECF5` is the concept's own value, measuring **1.14:1** on this app's
  /// card fill against 1.18:1 on the pure white it was drawn for. Far below
  /// the 1.45:1 `borderSubtle` used to draw around every card — a divider that
  /// competed with content would just be the frame again, one level in.
  static const Color borderDividerLight = Color(0xFFE9ECF5);

  /// **Derived by matching the light ratio, not guessed.** The concept is
  /// light-only, so the dark value is solved for the same contrast on the fill
  /// a divided card actually has in dark (`surfaceContainer` `#221E44`, since
  /// these cards are `.raised`): `#2E2A54` measures **1.178:1** there against
  /// the concept's 1.181 in light.
  static const Color borderDividerDark = Color(0xFF2E2A54);

  static const Color borderSelectedLight = Color(0xFF6E6ECE);

  /// See [borderSelectedLight]. Dimmer than `focusRingDark` on purpose.
  static const Color borderSelectedDark = Color(0xFF7C79C8);

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
  static const Color borderAccentLight = Color(0xFFB6B6E2);

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
  static const Color borderAccentDark = Color(0xFF6560B8);

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
  static const Color borderOptionLight = Color(0xFF8887CE);

  /// See [borderOptionLight]. Measured on the fill `.option` actually has in
  /// dark (`surface`, since the recipe is flat): **3.22:1**, chroma 0.120, and
  /// 1.37 quieter than [borderSelectedDark].
  static const Color borderOptionDark = Color(0xFF5D65B2);

  /// A control's edge at the 3:1 WCAG 1.4.11 asks — cleared against every
  /// neighbour it touches. Why a control and not a card, and the measurements:
  /// `AppSemanticColors.borderControl`.
  static const Color borderControlLight = Color(0xFF8D8D95);

  static const Color borderControlDark = Color(0xFF66628D);

  /// Input border while focused. Focus shifts *hue*, never stroke width —
  /// Material's default doubles the stroke, which reads as the field shouting.
  static const Color focusRingLight = Color(0xFF4141C0);

  static const Color focusRingDark = Color(0xFF8A8AE0);
}
