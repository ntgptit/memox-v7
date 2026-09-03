import 'package:flutter/material.dart';

/// Colour tokens — **Tokyo's palette under the M3 binding contract**
/// (M100.25–28), on the token structure A2 Quizlet Navy Indigo laid down at
/// M3.5b.
///
/// **The invariant every value here obeys (AD-14, M100.28).** A Material
/// component binds to the canonical M3 role its `_XxxDefaultsM3` names; when a
/// role fails a contrast or hierarchy ratio, the *palette* moves — never a
/// substitute token, never a lowered floor. Tokyo
/// (`ntgptit/tokyo-react-admin-dashboard`) is the visual reference, ranked
/// below that contract and below a coherent family: the page, the card, the
/// ink and the dark statuses are Tokyo's exact hex because nothing depends on
/// them; `primary` is Tokyo's family retuned to the tone every consumer clears.
///
/// **How a value here was chosen.** One of three ways, each named at the token:
/// a Tokyo literal; a Tokyo primitive flattened the way its own theme does
/// (`alpha.black` over paper, `primary.lighter`, precomputed as AD-14 asks);
/// or the previous value re-hued onto a Tokyo key with its tone and chroma
/// kept, so the L\* steps and ratios the tests hold were preserved by
/// construction. Measurements quoted at older tokens describe the state when
/// that token was decided and are kept as the record of *why* it exists; the
/// current numbers are the tests' output.
///
/// Every name says what the colour *means*, never what it looks like. `danger`
/// survives a redesign that turns it amber; `red` becomes a lie the moment
/// someone changes it, and nobody renames a constant used in forty files.
///
/// **The dark page is the most saturated surface, and the ladder climbs above
/// it in lightness.** Tokyo's dark is navy on navy — the card carries 72% of
/// the page's saturation — so hierarchy in dark is lightness plus the card's
/// rim (`AppElevation`), not a saturation drop; `app_palette_test.dart` holds
/// every surface above the card under 0.75 of the page and the ladder's steps
/// in L\*.
///
/// **Why the ladder is measured in L\*, not in contrast ratio.** A deep navy
/// page is at luminance 0.004, and down there WCAG's `+0.05` constant compresses
/// every real step into "1.1-something": the card is 3× the page's luminance and
/// still scores 1.17:1. L\* is the perceptual scale and stays honest at the
/// bottom, so `test/core/theme/app_palette_test.dart` asserts the ladder in L\*.
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
  static const Color textPrimaryLight = Color(0xFF223354);
  static const Color textPrimaryDark = Color(0xFFCBCCD2);
  static const Color textSecondaryLight = Color(0xFF596680);
  static const Color textSecondaryDark = Color(0xFF9395A2);

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
  static const Color disabledSurfaceLight = Color(0xFFE4E7EA);
  static const Color disabledSurfaceDark = Color(0xFF272C46);

  /// A disabled label or glyph — the kit's `--color-on-disabled`, which is the
  /// ink at 38%. Translucent where the fill above is solid, and for a reason: a
  /// disabled fill has one ground, a disabled label has three — the page, a
  /// card, and the disabled fill itself.
  static const Color onDisabledLight = Color(0x61223354);
  static const Color onDisabledDark = Color(0x61CBCCD2);

  // --- Brand and actions ---------------------------------------------------

  /// The single accent — Tokyo's indigo family, at HSL hue 233 in both
  /// brightnesses, **retuned to the canonical M3 contract rather than copied**
  /// (M100.28, owner's invariant).
  ///
  /// **The invariant this value obeys.** A Material component binds to the M3
  /// role its `_XxxDefaultsM3` names, that binding is locked, and when the role
  /// fails a ratio the *palette* moves — never a substitute token, never a
  /// lowered floor. `primary` is the role with the most consumers: the filled
  /// button's fill under white, the text button's label, the outlined label,
  /// the tab label, the focus ring, the caret, the radio, the switch and the
  /// progress indicator. One hex has to serve all of them.
  ///
  /// **Why `#4454CC` and not Tokyo's `primary.main` `#5569FF`.** Measured,
  /// `#5569FF` fails three canonical consumers at once: white on it is 4.33:1
  /// (the filled label), and as a label it reads 4.33 on the card and 3.96 on
  /// the page (text button, outlined button, tab). `#4454CC` is the next value
  /// in Tokyo's own family — its `primary.dark`, `darken(main, 0.2)` — and it
  /// clears every consumer: 6.20 under white, 6.20 / 5.67 as text on card and
  /// page, 5.19 on the inset tile, 4.58 on `secondaryContainer` as a ring,
  /// 5.34 on the progress track, 4.85 on the error band. Tone 41, where M3
  /// puts a light `primary`.
  static const Color primaryLight = Color(0xFF4454CC);

  /// Tone 80 of the palette keyed on [primaryLight] — the M3 dark `primary`,
  /// and one hex with `AppMaterialRoles.primaryFixedDim` by construction.
  ///
  /// **Why not Tokyo's dark `primary` `#8C7CF0`.** At tone 58 it fails the
  /// same contract: white on it is 3.36:1 and as a label on the selected tile
  /// it reads 4.29. Tone 80 of *its* family (`#C8BFFF`) passes every ratio but
  /// sits 15.5° off the light brand, past the 12° `app_palette_test.dart`
  /// holds for one brand across modes; tone 80 of the light family passes the
  /// same ratios — 7.73 under [onPrimaryDark], 11.27 on the page, 10.37 on the
  /// card, 8.43 on the tile, 7.24 on `secondaryContainer`, 7.39 on the track,
  /// 6.74 on the error band — at 1.7°. Coherent family outranks exact hex.
  static const Color primaryDark = Color(0xFFBCC2FF);
  static const Color onPrimaryLight = Color(0xFFFFFFFF);

  /// Tone 20 at the brand hue. 7.73:1 under [primaryDark].
  static const Color onPrimaryDark = Color(0xFF202771);

  /// The 1 px halo a dark card wears instead of a shadow — Tokyo's
  /// `shadows.card` (`0px 0px 2px #6A7199`) in NebulaFighter. The card is
  /// Tokyo's `#111633` on the `#070C27` page — a 4.3 L\* step — and a dark
  /// shade moves that page by under one L\*, so depth in dark comes from an
  /// edge: this reads 4.07:1 against the page and 3.74:1 against the card.
  /// See `shadowsFor` and AD-14 §4.
  static const Color cardRimDark = Color(0xFF6A7199);

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
  static const Color successLight = Color(0xFF2A7800);
  static const Color successDark = Color(0xFF57CA22);

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
  /// **Retuned from `#A46500` at M100.32, and the number was already written
  /// down.** The block above this one has said since M4.10p that warning
  /// measures "4.33:1 on the page ... below the 4.5:1 a body-text colour would
  /// need. It is not used as body text anywhere; if it ever is, that is the
  /// number to re-check." `AppInk.warning` *is* a text ink, so it always was;
  /// what changed is that `ColorScheme.surface` became the page, so
  /// `app_ink_test.dart` finally measured the ground the ink actually lands on.
  ///
  /// The palette moves rather than the floor (AD-14). `#A06200` is the same hue
  /// to within 0.2 degrees and the same saturation, one step darker in HSL
  /// lightness: 4.53:1 on the page and 4.95:1 on the paper, against 4.33 and
  /// 4.73. The chroma ordering `app_palette_test.dart` pins is untouched.
  static const Color warningLight = Color(0xFFA06200);
  static const Color warningDark = Color(0xFFFFA319);

  /// Answer forgotten, destructive action, reset.
  static const Color dangerLight = Color(0xFFCD0031);
  static const Color dangerDark = Color(0xFFFF768F);

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
  static const Color successContainerLight = Color(0xFFDFE9DA);
  static const Color successContainerDark = Color(0xFF273F1C);
  static const Color onSuccessContainerLight = Color(0xFF1E3414);
  static const Color onSuccessContainerDark = Color(0xFFCBE2C0);

  static const Color warningContainerLight = Color(0xFFEDE6DC);
  static const Color warningContainerDark = Color(0xFF4C3513);
  static const Color onWarningContainerLight = Color(0xFF432902);
  static const Color onWarningContainerDark = Color(0xFFEAD9C0);

  static const Color infoContainerLight = Color(0xFFDEE8EC);
  static const Color infoContainerDark = Color(0xFF153D4E);
  static const Color onInfoContainerLight = Color(0xFF003247);
  static const Color onInfoContainerDark = Color(0xFFC7E0EB);

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
  static const Color progressTrackLight = Color(0xFFEBEDFF);
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
  // A tint of the brand, never the brand itself: a bar in the button's own hex
  // beside the button is the failure this token exists to prevent
  // (`mx_progress_bar_test.dart`). `#6E6ECE` re-hued onto Tokyo's indigo with
  // its tone and chroma kept; 3.76:1 on its track.
  static const Color progressFillLight = Color(0xFF6471CF);
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
  static const Color infoLight = Color(0xFF00729A);
  static const Color infoDark = Color(0xFF33C2FF);

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
  static const Color webLetterbox = Color(0xFF6E759F);

  /// The colour a modal scrim is laid over the page in.
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
  static const Color scrimLight = Color(0xFF0A0C18);
  static const Color scrimDark = Color(0xFF03040B);

  /// The colour a **cast** shadow is drawn from — Tokyo's `shadows.card`
  /// (M100.30).
  ///
  /// **It was `scrimLight` until this token existed, and the two meanings had
  /// started to pull apart.** A scrim is laid *over* the page to take it out of
  /// reach, so it has to be dark by definition. A shadow is light passing
  /// *around* an object, and Tokyo draws that as a desaturated blue-grey haze
  /// rather than as a dark smear — which is most of why a Tokyo panel reads as
  /// floating where a near-black drop reads as a cut-out. One name could not
  /// hold both once one of them moved.
  ///
  /// `#9FA2BF` is Tokyo's own literal, and it needs no re-hueing: at HSL hue
  /// **234.4** it already sits on this palette's seed hue (233), so MX-VIS-002
  /// R6 — a shadow must carry a trace of the seed — holds by construction
  /// rather than by adjustment.
  ///
  /// It is far lighter than the value it replaces (L 0.686 against 0.067) and
  /// is drawn at far higher alpha to compensate; the pair is what [shadowsFor]
  /// carries, and the lift it produces is re-measured in `app_theme_test.dart`
  /// rather than asserted here.
  static const Color shadowLight = Color(0xFF9FA2BF);

  /// **Dark casts no shadow, so this is a declared role rather than a painted
  /// one.** `shadowsFor` draws Tokyo's rim in dark and `materialShadowColor`
  /// returns transparent, both because a shade at the bottom of the lightness
  /// scale moves the page by under one L\* — the measurement
  /// `app_elevation_test.dart` re-derives. `ColorScheme.shadow` still has to be
  /// *something*, and the scrim's dark is the value that keeps that measurement
  /// meaningful: it is the darkest thing this palette would ever cast.
  static const Color shadowDark = scrimDark;
}
