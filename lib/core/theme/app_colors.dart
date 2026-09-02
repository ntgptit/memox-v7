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
/// **What is not here.** The `ColorScheme` roles this app declares only because
/// `fromSeed` would otherwise invent them — the container ladder, the `tertiary`
/// family, the `inverse*` pair — live in `AppMaterialRoles`. They are colour
/// tokens too, and they answer a different question: not *what a colour means
/// here*, but *what Material will draw if nobody says*. What stays in this file
/// is every role that is a memox decision Material happens to have a slot for —
/// `primary`, `surface`, `outline`, `error`, `shadow`, `scrim`.
abstract final class AppColors {
  /// The palette's declared seed — the hue every neutral in both modes carries
  /// a trace of. Nothing *generates* from it any more (`app_theme.dart` builds
  /// its `ColorScheme`s explicitly, precisely so no generated role can hide
  /// behind the declared ones); it stays because the design system names it
  /// (`--color-seed`) and the parity test pins the two together.
  static const Color seed = primaryLight;

  // --- Text and lines ------------------------------------------------------
  //
  // Neither end is pure. `#EDEDF6` rather than white, `#16182B` rather than
  // black: a pure value buzzes against a tinted ground, and carrying a trace of
  // the surface hue makes text sit *in* the interface rather than on top of it.
  // Which is why both dark values moved with the ladder — a trace of the *old*
  // surface hue is a trace of a hue no surface carries any more.
  static const Color textPrimaryLight = Color(0xFF1C1B1F);
  static const Color textPrimaryDark = Color(0xFFE3E2E7);
  static const Color textSecondaryLight = Color(0xFF474550);
  static const Color textSecondaryDark = Color(0xFFC7C5D2);

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
  static const Color disabledSurfaceLight = Color(0xFFDBDEE6);
  static const Color disabledSurfaceDark = Color(0xFF242840);

  /// A disabled label or glyph — the kit's `--color-on-disabled`, which is the
  /// ink at 38%. Translucent where the fill above is solid, and for a reason: a
  /// disabled fill has one ground, a disabled label has three — the page, a
  /// card, and the disabled fill itself.
  static const Color onDisabledLight = Color(0x610F1638);
  static const Color onDisabledDark = Color(0x61E4E8FA);

  // --- Brand and actions ---------------------------------------------------

  /// The single accent, on hue 240 in both brightnesses.
  ///
  /// **Dark inverts the tone, which is what Material 3 asks for and what this
  /// palette spent two years working around.** M3 puts a dark scheme's
  /// `primary` at tone 80 — a *light* tone — with `onPrimary` at tone 20;
  /// light keeps the fill at tone 40 with white on it. The old dark value was
  /// a mid fill-tone (L\* 42.5) carrying white, and that single deviation is
  /// what made `primary` unusable in every binding M3 gives it: at 2.90:1 on
  /// the card it missed WCAG 1.4.11's 3:1 for a progress indicator, a slider,
  /// a caret or a focus ring, and it was nowhere near the 4.5:1 a tab label
  /// needs. Five component themes reached for a substitute token instead, and
  /// the substitute was the bug — M100.18.
  ///
  /// A single tone cannot be both: bright enough to read as a label on a dark
  /// page *and* dark enough for white to sit on it. Measured, the crossover is
  /// hard — the first hue-240 value clearing 4.5:1 as text drops white on it to
  /// 3.73:1. Inverting resolves it rather than trading one failure for another.
  ///
  /// The rule the old comment protected still holds and is still asserted: the
  /// CTA must never be the brightest thing on screen. `primary` against the
  /// page is 11.36:1 where `onSurface` is 15.84:1, so the headline still wins.
  /// What changed is the mechanism — a tone ceiling rather than a luminance
  /// cap, because a luminance cap is a fill-tone rule and this is no longer a
  /// fill-tone palette.
  static const Color primaryLight = Color(0xFF4E53B6);

  /// Tone 80 at hue 240, chroma 0.154 — the band `secondaryDark` and
  /// `tertiaryDark` already sit in, both of which were M3-shaped all along.
  static const Color primaryDark = Color(0xFFC7BFFF);
  static const Color onPrimaryLight = Color(0xFFFFFFFF);

  /// Tone 20 at the same hue. 7.72:1 under [primaryDark].
  static const Color onPrimaryDark = Color(0xFF002781);

  // --- Semantic ------------------------------------------------------------
  //
  // On a chroma budget, `info` the quietest of the four. None reaches full
  // saturation — four hues all shouting is how a study tool starts looking like
  // a game.
  //
  // **These eight values come from `design_system/tokens/colors.css` and the
  // design system is authoritative for them** (project owner's decision,
  // M4.10p). `warningDark` has since moved, on both sides at once.
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
  ///
  /// **Dark moved off `#E0B064` (owner decision, 2026-08-24)**, the streak
  /// family's accent — the due chip's label, `--color-streak` in the kit.
  /// Warning was set to it on both sides, so two unrelated meanings were one
  /// colour: an edit for "a card is due soon" repainted every due chip.
  ///
  /// **Derived, not chosen.** In light, warning sits 7.4° yellower than the
  /// streak accent and 0.098 darker in L (`#9A6A11` against `#C2731B`); dark
  /// inverts lightness, so the same relationship reads `HSL(44.2, 0.667,
  /// 0.733)`. Saturation is untouched — the chroma ordering
  /// `app_palette_test.dart` pins holds — and contrast rose: 11.24:1 on the
  /// card, 12.75:1 on the page, against a 3.0 floor. **A shade apart, not a
  /// hue:** the semantic hues map light→dark by keeping hue and raising
  /// lightness, and that rule lands warning back on the streak amber.
  static const Color warningLight = Color(0xFF906310);
  static const Color warningDark = Color(0xFFE8D08E);

  /// Answer forgotten, destructive action, reset.
  static const Color dangerLight = Color(0xFFBE013A);
  static const Color dangerDark = Color(0xFFFEB3B4);

  // --- Status containers ---------------------------------------------------
  //
  // **The four semantics had a fill and no container, and that gap is what put
  // domain state on accent roles** (M100.21). An import row's status chip
  // needed a filled pill with a label on it; the only container pairs that
  // existed belonged to `primary`, `secondary`, `tertiary` and `error`, so
  // "ready" took `secondaryContainer` and "duplicate" took `tertiaryContainer`
  // — roles M3 defines as accents for balancing an interface, not as a place
  // to keep business meaning.
  //
  // **Derived, not chosen, by the method the existing containers already use.**
  // The four hand-tuned light containers reconstruct as a tint of their own
  // fill over `surface` at alpha 0.127–0.171 (mean 0.142, reconstruction error
  // 0.6–5.4 of 255); these take that mean. The dark containers do *not*
  // reconstruct that way — the error is up to 28/255, so they were hand-placed
  // — and what they share is a band: L\* 21.5–29.0 at chroma 0.153–0.263. So
  // dark is placed at L\* 24.0, chroma 0.20, on each role's own hue.
  //
  // The inks take the tone the existing `on*Container` pairs occupy (L\* 14–23
  // light, 86–89 dark), which lands them at 10.80–10.98:1 and 8.35:1 — inside
  // the app's own band of 9.75–11.46 and 7.24–9.09, rather than at the
  // near-black a bare 4.5:1 search would have produced.
  //
  // **`danger` gets none, and that is the point of `error` being `danger`.**
  // `AppMaterialRoles.errorContainer*` already holds this family's container;
  // `AppSemanticColors.dangerContainer` derives from it rather than declaring
  // a second red, exactly as the class header refuses a second red fill.
  static const Color successContainerLight = Color(0xFFDAE9E7);
  static const Color successContainerDark = Color(0xFF0E412F);
  static const Color onSuccessContainerLight = Color(0xFF003627);
  static const Color onSuccessContainerDark = Color(0xFFBFE3D6);

  static const Color warningContainerLight = Color(0xFFEDE6DC);
  static const Color warningContainerDark = Color(0xFF453812);
  static const Color onWarningContainerLight = Color(0xFF402A00);
  static const Color onWarningContainerDark = Color(0xFFE4DBC1);

  static const Color infoContainerLight = Color(0xFFE0E7EF);
  static const Color infoContainerDark = Color(0xFF213B54);
  static const Color onInfoContainerLight = Color(0xFF073053);
  static const Color onInfoContainerDark = Color(0xFFCBDEEF);

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
  /// **Lighter since M99.95, and the trade is measured.** `#DFE0E9` sat at
  /// L\* 89.34, four steps below the card it lies on — dark enough to read as a
  /// *bar* in its own right, so an empty gauge looked like a filled one drawn
  /// in grey. The reference concept puts its track at `#E9EDF8`: fainter
  /// against the card (1.13:1 against 1.27) and **stronger against the fill**
  /// (3.75:1 against 3.34), which is the pair that carries the number. A track
  /// is a groove, not a second datum.
  static const Color progressTrackLight = Color(0xFFE9EDF8);
  static const Color progressTrackDark = Color(0xFF2E3247);

  /// The filled part, below 100%.
  ///
  /// **Dark *is* `primary`, which is also what M3 asks a progress indicator to
  /// draw with.** It used to be the focus ring's brighter indigo, because the
  /// old dark `primary` was a fill tone measuring 2.90:1 on the card and could
  /// not carry a graphical indicator. Since dark inverted to tone 80 (M100.18)
  /// the substitute has no reason left, and pointing the derivation at
  /// `primaryDark` is what lets this file stop importing the border palette —
  /// the dependency that made the two files circular the moment `focusRing`
  /// became a derivation in the other direction.
  ///
  /// Light keeps its own value: `primaryLight` at tone 40 is the button fill,
  /// and a bar drawn in it reads as a control rather than as progress. That
  /// asymmetry is the tone system working, not a drift — dark's tone 80 is a
  /// label-weight indigo, light's tone 40 is a fill-weight one.
  static const Color progressFillLight = Color(0xFF6E6ECE);
  static const Color progressFillDark = primaryDark;

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

  /// The letterbox around the phone-sized frame on the web build.
  ///
  /// **A non-theme constant, deliberately**: it paints outside `MaterialApp`,
  /// where no `ColorScheme` or extension can reach, and it must not change
  /// with the user's theme — the surround is "not the app" in both modes.
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
  static const Color shadowLight = Color(0xFF000000);
  static const Color shadowDark = Color(0xFF000000);

  /// The scrim is the shadow's colour by definition here — one dark-from-seed
  /// per mode, whether it is cast or laid over — so it derives rather than
  /// repeats the hex.
  static const Color scrimLight = shadowLight;
  static const Color scrimDark = shadowDark;
}
