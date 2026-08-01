import 'package:flutter/material.dart';

/// Colour tokens — **A2 Quizlet Navy Indigo**, applied in M3.5b.
///
/// Every name says what the colour *means*, never what it looks like. `danger`
/// survives a redesign that turns it amber; `red` becomes a lie the moment
/// someone changes it, and nobody renames a constant used in forty files.
///
/// **The page is the only place saturated navy is allowed.** [backgroundDark]
/// sits at 70% saturation, which is what gives dark mode its identity. Every
/// surface above it drops to 26–40% while climbing in lightness, so the navy
/// reads as the room the content sits in rather than as a tint applied to the
/// content itself. A palette where card, tile and input are all as navy as the
/// page has no hierarchy left to spend — everything is equally coloured, so
/// nothing is emphasised.
///
/// That band was 20–30% until M4.10aa. Joining the page's colour family is
/// exactly what raised it, and it is the one number the change spends: the card
/// now sits at 40% against a ceiling of 42% (`app_palette_test.dart` allows a
/// surface 60% of the page's saturation). There is no room left above the card,
/// so a future surface that wants more saturation has to take lightness instead.
///
/// **Why the ladder is measured in L\*, not in contrast ratio.** A deep navy
/// page is at luminance 0.004, and down there WCAG's `+0.05` constant compresses
/// every real step into "1.1-something": the card is 3× the page's luminance and
/// still scores 1.17:1. L\* is the perceptual scale and stays honest at the
/// bottom, so `test/core/theme/app_theme_test.dart` asserts the ladder in L\*.
/// The three dark steps are ~6.3, 6.7 and 7.1 L\*.
///
/// **The dark ladder joined the page's colour family at M4.10aa.** It failed to
/// be in it in two ways at once: `#1B1D32` was hue 235 against the page's 243 —
/// a green-leaning slate under a violet — and it carried barely half the page's
/// chroma (0.040 against 0.072). A duller, greener surface stacked on a
/// saturated violet page reads as grey paper laid on the app rather than as
/// part of the same room, and neither difference is large enough to be named
/// when you look at either colour alone. Every surface now sits at OKLCH hue
/// ~285, chroma 0.06–0.074.
///
/// Reaching that inside sRGB cost the rungs ~2 L\* apiece. Every ladder
/// assertion still holds; the tightest is the card's 6.3 L\* off the page,
/// against a 6.0 floor.
///
/// **Why every role is declared.** `ColorScheme.fromSeed` generates ~30 roles,
/// and an audit found it had produced a neutral-grey `surfaceContainer` ladder, a
/// **pink** `tertiary`, and an `error` red competing with `danger` — all in hue
/// families the app never uses. None had surfaced only because the MVP has no
/// Dialog, BottomSheet, NavigationBar, Menu or Chip yet. Leaving them generated
/// meant those screens would render as a different app.
abstract final class AppColors {
  /// Seed for `ColorScheme.fromSeed`. Every role it would generate is
  /// overridden below; the seed remains only because Material requires one.
  static const Color seed = primaryLight;

  // --- Surface ladder ------------------------------------------------------
  //
  // Four tiers. Dark climbs L* 3.9 -> 10.2 -> 16.9 -> 24.0 so a card reads as a
  // card and an inset tile as an inset on the strength of the ladder alone.
  // Light inverts it — the card is white and the rest sit below — which is the
  // same ordering of PROMINENCE, built the only way white allows.
  //
  // **That the ladder can carry the hierarchy is not the same as a rule against
  // shadows**, and this comment was read as one for two milestones. The project
  // owner has since said the app needs real elevation to separate elements; see
  // `shadowLight`/`shadowDark` and MX-VIS-002 rule R6. Nothing here forbids a
  // shadow — it only explains why the ladder was built to work without one.

  /// Page background. The one component allowed a strong navy saturation.
  static const Color backgroundLight = Color(0xFFF4F5F8);
  static const Color backgroundDark = Color(0xFF0A082D);

  /// Card and sheet — the flashcard surface.
  ///
  /// **Not pure white, since M4.10i.** `#FFFFFF` carries no hue at all, so the
  /// one surface the whole app is built on had no relation to the seed while
  /// every other neutral did — the audit's largest finding, and the reason light
  /// mode read as a different palette from dark. `#FBFBFE` is `seed @ 0.02` over
  /// white: hue 240, chroma 0.012, nowhere near the light canvas's tint budget.
  ///
  /// It costs lightness. A tinted card is a *darker* card, so the surface step
  /// drops from 3.46 L\* to 2.15 — which was the argument for leaving it alone
  /// while the step was the only depth cue light had. It is not any more: the
  /// shadow's alpha was re-solved to 0.07 and the total lift is 8.04 L\* against
  /// dark's 6.58.
  static const Color surfaceLight = Color(0xFFFBFBFE);
  static const Color surfaceDark = Color(0xFF1A1838);

  /// Inset tile, chip, icon container.
  static const Color surfaceMutedLight = Color(0xFFEAECF1);
  static const Color surfaceMutedDark = Color(0xFF28254B);

  /// Top of the ladder: a raised or selected surface.
  ///
  /// `seed @ 0.015` over white — one step lighter than [surfaceLight] and still
  /// carrying the hue. Both were `#FFFFFF` before M4.10i, which made the top two
  /// rungs of the light ladder the same rung.
  static const Color surfaceElevatedLight = Color(0xFFFCFCFE);
  static const Color surfaceElevatedDark = Color(0xFF37345F);

  // --- Text and lines ------------------------------------------------------
  //
  // Neither end is pure. `#EDEDF6` rather than white, `#16182B` rather than
  // black: a pure value buzzes against a tinted ground, and carrying a trace of
  // the surface hue makes text sit *in* the interface rather than on top of it.
  // Which is why both dark values moved with the ladder — a trace of the *old*
  // surface hue is a trace of a hue no surface carries any more.
  static const Color textPrimaryLight = Color(0xFF16182B);
  static const Color textPrimaryDark = Color(0xFFEDEDF6);
  static const Color textSecondaryLight = Color(0xFF565C72);
  static const Color textSecondaryDark = Color(0xFFA8A7C4);

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
  static const Color borderSubtleDark = Color(0xFF403D67);

  /// Input border while focused. Focus shifts *hue*, never stroke width —
  /// Material's default doubles the stroke, which reads as the field shouting.
  static const Color focusRingLight = Color(0xFF4141C0);
  static const Color focusRingDark = Color(0xFF8A8AE0);

  /// The fill and the border of a disabled control — a solid, per MX-VIS-002
  /// rule R7. Material's idiom is the ink at 12% alpha, which composites
  /// against whatever is behind the control at paint time — a card, a sheet, a
  /// dialog — so one token renders as three colours and none of them was
  /// chosen. Flattened over the surface once, here, where the ground is fixed;
  /// `app_semantic_colors_test.dart` pins each back to that blend.
  ///
  /// The kit's `--color-disabled-surface` reads `#E3E3E6` / `#312E4E`, ~3/255
  /// away: a stale transcription of this file rather than a decision of its
  /// own. Recorded in `docs/wbs.md` under M4.10an.
  static const Color disabledSurfaceLight = Color(0xFFE0E0E5);
  static const Color disabledSurfaceDark = Color(0xFF33324F);

  /// A disabled label or glyph — the kit's `--color-on-disabled`, which is the
  /// ink at 38%. Translucent where the fill above is solid, and for a reason: a
  /// disabled fill has one ground, a disabled label has three — the page, a
  /// card, and the disabled fill itself.
  static const Color onDisabledLight = Color(0x6116182B);
  static const Color onDisabledDark = Color(0x61EDEDF6);

  // --- Brand and actions ---------------------------------------------------

  /// The single accent, on hue 240 in both brightnesses.
  ///
  /// It fills the primary action in *both* modes. The dark value is held at
  /// luminance 0.13 — bright enough to read as the brand against the navy page,
  /// far enough below the card's headline text that the CTA never becomes the
  /// brightest thing on screen. That relationship is asserted, not assumed:
  /// `primary` against the page must score lower than `onSurface` against the
  /// page.
  static const Color primaryLight = Color(0xFF4646B4);
  static const Color primaryDark = Color(0xFF5656C9);
  static const Color onPrimaryLight = Color(0xFFFFFFFF);
  static const Color onPrimaryDark = Color(0xFFFFFFFF);

  /// The brand hue as a LABEL rather than as a fill.
  ///
  /// `primaryDark` is deliberately held below the card's headline text so a
  /// filled CTA never outshines it — which also means it measures 3.33:1 as
  /// bare text on the dark page and fails AA at label size. Text that carries
  /// the brand (a text button, a link) uses this instead: the light value is
  /// the fill colour, which passes on light surfaces; the dark value is the
  /// brighter indigo the focus ring already uses, 6.26:1 on the page.
  static const Color primaryAccentLight = Color(0xFF4646B4);
  static const Color primaryAccentDark = Color(0xFF8A8AE0);

  /// Label of a secondary (outlined) action — *End session*, *Cancel*.
  ///
  /// Deliberately neutral (saturation under 20%) rather than the brand colour.
  /// A secondary action sits next to the review verdicts, and anything with a
  /// hue there competes with the two colours carrying the user's actual
  /// decision. Keeping it a separate token from [primaryLight] also stops the
  /// pairing that once shipped a label at 3.09:1 — one colour cannot be both a
  /// fill and a label on a dark surface.
  static const Color secondaryActionLight = Color(0xFF454B5E);
  static const Color secondaryActionDark = Color(0xFFC3C6D2);

  // --- Semantic ------------------------------------------------------------
  //
  // On a chroma budget, `info` the quietest of the four. None reaches full
  // saturation — four hues all shouting is how a study tool starts looking like
  // a game.
  //
  // **These eight values come from `design_system/tokens/colors.css` and the
  // design system is authoritative for them** (project owner's decision, M4.10p).
  // They are louder than the values they replaced — in HSL saturation, light
  // rises 0.299…0.676 → 0.411…0.801 and dark 0.325…0.678 → 0.490…0.814.
  //
  // Two consequences, both measured rather than assumed:
  //
  // - Every one still clears 3.0:1 on both its card and its page, so
  //   `app_theme_test.dart` holds. The tightest is `warningLight` at 4.33:1 on
  //   the page, down from 4.97:1 — still above the 3.0 floor a graphic needs,
  //   and below the 4.5:1 a body-text colour would need. It is not used as body
  //   text anywhere; if it ever is, that is the number to re-check.
  // - `danger` is no longer the loudest in light: `warning` 0.801 and `success`
  //   0.766 both out-saturate it at 0.634. That contradicts the design system's
  //   own readme ("danger carries the most saturation"), so the contradiction is
  //   inside the design project, not between it and this repo. The values won
  //   because values are what was made authoritative; `app_palette_test.dart`
  //   records the whole measurement.

  /// Answer remembered, session completed, saved.
  static const Color successLight = Color(0xFF10795C);
  static const Color successDark = Color(0xFF4FC79B);

  /// Card due soon, streak at risk — informative, not alarming.
  static const Color warningLight = Color(0xFF9A6A11);
  static const Color warningDark = Color(0xFFE0B064);

  /// Answer forgotten, destructive action, reset.
  static const Color dangerLight = Color(0xFFC02B3A);
  static const Color dangerDark = Color(0xFFF2808F);

  // --- Progress -----------------------------------------------------------
  //
  // **Its own family, and not the accent.** A bar drawn in `primary` sits beside
  // a button drawn in `primary` and nothing tells the eye which of the two it
  // can press. These are a lighter tint of the same indigo — related to the
  // brand, not competing with its call to action. Values from
  // `design_system/tokens/colors.css`; they arrived with `MxProgressBar`, the
  // first thing that draws them.
  //
  // There is no `progressComplete`: the design points it at `success`, and a
  // second name for one colour is a second thing to keep in step.

  /// The unfilled part of a progress track.
  static const Color progressTrackLight = Color(0xFFDFE0E9);
  static const Color progressTrackDark = Color(0xFF2E3247);

  /// The filled part, below 100%.
  static const Color progressFillLight = Color(0xFF6E6ECE);
  static const Color progressFillDark = Color(0xFF8A8AE0);

  // --- Due chip -----------------------------------------------------------
  //
  // The filled pill on a deck card that says how many cards are waiting. The
  // container is `design_system/tokens/colors.css`'s `--color-streak-container`
  // unchanged; the design reuses one warm family for everything time-pressured,
  // and the due chip is the first thing here to draw it.
  //
  // **Dark's container left that warm family at M4.10aa, and only dark's.** It
  // was `#3A2E1C`, an olive-brown at hue 77 — the one hue that cannot sit on a
  // violet page without looking soiled, because the surround tints it toward
  // grey and the chip reads as a stain rather than as a warm accent. It is now
  // a surface at the same L* (19.8 -> 20.2), and the *label* keeps the warm
  // colour, which is where the warmth was doing the work. Light's ground is
  // cream on a near-white page and has no such problem, so it is untouched.
  //
  // **The foreground is not the design's.** `.mx-deck__due` paints its label in
  // `--color-streak` (`#C2731B`), which measures **3.12:1** on its own container
  // at 11px semibold — under the 4.5 small text needs. Dark is fine at 6.65,
  // which is presumably why it went unnoticed. Every other container in this
  // palette has an `on*Container` partner and this family had none, so one is
  // derived here: same hue to within 1.2 degrees, 6.38:1 on the container.
  //
  // `--color-streak` itself is deliberately absent. It belongs to a streak
  // display that does not exist, and a colour with no caller is a colour nobody
  // is checking.
  static const Color streakContainerLight = Color(0xFFFBEBD7);
  static const Color streakContainerDark = Color(0xFF342C4B);
  static const Color onStreakContainerLight = Color(0xFF7A4A10);

  /// Dark needs no correction: the design's own `#E0B064` reads 6.57:1 here —
  /// 6.65 before the container moved onto the surface family, which is close
  /// enough that the move cost the label nothing.
  static const Color onStreakContainerDark = Color(0xFFE0B064);

  /// Status that genuinely carries information: streak, counters, "3 of 20".
  /// Not a decorative accent — plain metadata uses `textSecondary`.
  static const Color infoLight = Color(0xFF3F6E97);
  static const Color infoDark = Color(0xFF8DB4D8);

  // --- Material roles ------------------------------------------------------
  //
  // Declared, not generated. See the class doc for what `fromSeed` produced
  // here before, and why none of it was visible until it would have been
  // expensive to discover.
  static const Color primaryContainerLight = Color(0xFFDCDCF2);
  static const Color primaryContainerDark = Color(0xFF2B2B6E);
  static const Color onPrimaryContainerLight = Color(0xFF1B1B5C);
  // `#D7D5FF` from the design system, replacing `#D8D8F0`. It reads the same on
  // the container (8.87:1 against 8.96:1) and carries more of the seed's hue.
  static const Color onPrimaryContainerDark = Color(0xFFD7D5FF);
  static const Color secondaryLight = Color(0xFF4E5468);

  /// Moved with [secondaryContainerDark] at M4.10aa, and forced rather than
  /// chosen: `color_system_rules_test.dart` R3 holds a role's fill and its
  /// container within 5 degrees of hue, and taking the container to the page
  /// family while the fill stayed on the old slate opened 18. Same L* (75.2),
  /// now 3.5 degrees off its container.
  static const Color secondaryDark = Color(0xFFB8B7D0);
  static const Color onSecondaryLight = Color(0xFFFFFFFF);
  static const Color onSecondaryDark = Color(0xFF1E2033);
  static const Color secondaryContainerLight = Color(0xFFE4E6EC);
  static const Color secondaryContainerDark = Color(0xFF332F58);
  static const Color onSecondaryContainerLight = Color(0xFF2C3141);
  static const Color onSecondaryContainerDark = Color(0xFFD9DCE7);
  static const Color tertiaryLight = Color(0xFF45647F);
  // `#8DB4D8` from the design system, replacing `#A2BAD0` — and it is the same
  // value as `infoDark`, which is deliberate there: the tertiary role and the
  // `info` semantic are the one blue the palette has.
  static const Color tertiaryDark = Color(0xFF8DB4D8);
  static const Color onTertiaryLight = Color(0xFFFFFFFF);
  static const Color onTertiaryDark = Color(0xFF17232E);
  static const Color tertiaryContainerLight = Color(0xFFE1E9F0);
  static const Color tertiaryContainerDark = Color(0xFF33465A);
  static const Color onTertiaryContainerLight = Color(0xFF22394B);
  static const Color onTertiaryContainerDark = Color(0xFFD5E0EA);
  static const Color onErrorLight = Color(0xFFFFFFFF);
  static const Color onErrorDark = Color(0xFF2C1319);
  static const Color errorContainerLight = Color(0xFFF8DDE1);
  static const Color errorContainerDark = Color(0xFF5E2831);
  static const Color onErrorContainerLight = Color(0xFF641421);
  static const Color onErrorContainerDark = Color(0xFFF5D3D8);
  static const Color surfaceContainerLowestLight = Color(0xFFFCFCFE);
  // The dark half of this ladder moved with the four main tiers at M4.10aa —
  // `surfaceContainerHigh`, `Highest` and `Bright` are the same values as
  // `surfaceMuted`, `secondaryContainer` and `surfaceElevated`, and leaving them
  // on the old slate would have split one ladder into two hue families at
  // exactly the rungs a Dialog and a Menu draw from.
  static const Color surfaceContainerLowestDark = Color(0xFF0A0326);
  static const Color surfaceContainerLowLight = Color(0xFFFAFAFC);
  static const Color surfaceContainerLowDark = Color(0xFF151134);
  static const Color surfaceContainerLight = Color(0xFFF1F2F6);
  static const Color surfaceContainerDark = Color(0xFF221E44);
  static const Color surfaceContainerHighLight = Color(0xFFEAECF1);
  static const Color surfaceContainerHighDark = Color(0xFF28254B);
  static const Color surfaceContainerHighestLight = Color(0xFFE3E5EC);
  static const Color surfaceContainerHighestDark = Color(0xFF332F58);
  static const Color surfaceDimLight = Color(0xFFDEE0E7);
  static const Color surfaceDimDark = Color(0xFF0B0327);
  static const Color surfaceBrightLight = Color(0xFFFCFCFE);
  static const Color surfaceBrightDark = Color(0xFF37345F);
  static const Color inverseSurfaceLight = Color(0xFF2A2C3E);
  static const Color inverseSurfaceDark = Color(0xFFE7E8F0);
  static const Color onInverseSurfaceLight = Color(0xFFF1F2F6);
  static const Color onInverseSurfaceDark = Color(0xFF23253A);
  static const Color inversePrimaryLight = Color(0xFFA9A9E0);
  static const Color inversePrimaryDark = Color(0xFF3A3A9B);

  /// The colour a drop shadow and a modal scrim are drawn from.
  ///
  /// **Both modes derive from the seed, and that stopped being cosmetic at
  /// M4.10g.** Dark was pure `#000000` while light was already `#0B0C18` (hue
  /// 235) — an asymmetry nobody could see, because nothing in the app painted a
  /// shadow. The project owner's decision that surfaces *should* carry elevation
  /// makes it visible on the first switch: light would drop a seed-tinted shadow
  /// and dark a flat black one, from one token name.
  ///
  /// `#04040B` is `seed @ 0.06` over black, which keeps hue 240 at a luminance
  /// low enough to read as a shadow rather than as a navy smear. Pinned by
  /// MX-VIS-002 rule R6.
  /// The letterbox around the phone-sized frame on the web build.
  ///
  /// Outside the app surface entirely — Android never shows it (AD-04) — but it
  /// is still a colour, and a colour in a widget is a colour the theme cannot
  /// change. It has to read as "not the app" rather than as another panel.
  ///
  /// `#6E7288` from `design_system/tokens/colors.css`, replacing `#14162A`. The
  /// design system reaches the same goal from the opposite direction: its own
  /// `ui_kits/memox-app/index.html` paints exactly this grey behind the phone
  /// frame, so the surround is *lighter* than every app surface in dark mode
  /// instead of darker than every one in light. Either reads as "not the app";
  /// this one is the design's.
  static const Color webLetterbox = Color(0xFF6E7288);

  static const Color shadowLight = Color(0xFF0B0C18);
  static const Color shadowDark = Color(0xFF04040B);
  static const Color scrimLight = Color(0xFF0B0C18);
  static const Color scrimDark = Color(0xFF04040B);
}
