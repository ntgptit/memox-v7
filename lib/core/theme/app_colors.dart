import 'package:flutter/material.dart';

/// Colour tokens — **A2 Quizlet Navy Indigo**, applied in M3.5b.
///
/// Every name says what the colour *means*, never what it looks like. `danger`
/// survives a redesign that turns it amber; `red` becomes a lie the moment
/// someone changes it, and nobody renames a constant used in forty files.
///
/// **The page is the only place saturated navy is allowed.** [backgroundDark]
/// sits at 70% saturation, which is what gives dark mode its identity. Every
/// surface above it drops to 20–30% while climbing in lightness, so the navy
/// reads as the room the content sits in rather than as a tint applied to the
/// content itself. A palette where card, tile and input are all as navy as the
/// page has no hierarchy left to spend — everything is equally coloured, so
/// nothing is emphasised.
///
/// **Why the ladder is measured in L\*, not in contrast ratio.** A deep navy
/// page is at luminance 0.004, and down there WCAG's `+0.05` constant compresses
/// every real step into "1.1-something": the card is 3× the page's luminance and
/// still scores 1.17:1. L\* is the perceptual scale and stays honest at the
/// bottom, so `test/core/theme/app_theme_test.dart` asserts the ladder in L\*.
/// The three dark steps are ~7.4 L\* each.
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
  // Four tiers. Dark climbs L* 3.9 -> 11.6 -> 19.0 -> 26.3 so a card reads as a
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
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1B1D32);

  /// Inset tile, chip, icon container.
  static const Color surfaceMutedLight = Color(0xFFEAECF1);
  static const Color surfaceMutedDark = Color(0xFF292D42);

  /// Top of the ladder: a raised or selected surface.
  static const Color surfaceElevatedLight = Color(0xFFFFFFFF);
  static const Color surfaceElevatedDark = Color(0xFF383D55);

  // --- Text and lines ------------------------------------------------------
  //
  // Neither end is pure. `#EDEEF5` rather than white, `#16182B` rather than
  // black: a pure value buzzes against a tinted ground, and carrying a trace of
  // the surface hue makes text sit *in* the interface rather than on top of it.
  static const Color textPrimaryLight = Color(0xFF16182B);
  static const Color textPrimaryDark = Color(0xFFEDEEF5);
  static const Color textSecondaryLight = Color(0xFF565C72);
  static const Color textSecondaryDark = Color(0xFFA6ABC2);

  /// Hairline between rows, around cards, and an input at rest.
  ///
  /// **This carries the whole depth model today**, and only because nothing yet
  /// paints a shadow: a surface sits one step from the page it lies on — 1.09:1
  /// in light, 1.17:1 in dark — so the border is currently the only boundary.
  ///
  /// "Currently" is the load-bearing word. That the app is flat was never a
  /// decision written anywhere — no AD, no BR, no test — and the project owner
  /// has since said elevation *is* wanted. Once a shadow exists this token stops
  /// being the only cue and the values below should be re-measured downward:
  /// 1.82:1 is a border doing two jobs.
  ///
  /// The light value was `#D7DAE3` until M4.10e and was measurably too weak for
  /// that job: 1.40:1 against the card it outlined and 1.28:1 against the page,
  /// where dark's border already stood at 1.82:1 and 2.12:1. The two modes were
  /// using one mechanism at two strengths, which is why light read as flat while
  /// dark read as correct. `#BEC0C3` puts light at **1.82:1** against the card,
  /// matching dark to two decimal places — the modes now agree by measurement
  /// rather than merely sharing a token name.
  ///
  /// It is a near-neutral grey where the old value was blue-grey. The first
  /// candidate at this luminance was `#B9BECD`, and `app_palette_test.dart`
  /// rejected it: a light surface has a chroma budget, and that value spends more
  /// of it than the page itself does. The tint rule is real, not a preference.
  ///
  /// Not pushed to the 3.0:1 non-text floor: at that strength (around `#8A92AC`)
  /// every card, chip and input reads as a ruled table. WCAG 1.4.11 covers
  /// graphics *required to understand the content*, and the content inside these
  /// surfaces is legible on its own — the border is a boundary aid, and it is
  /// pinned by `app_theme_test.dart` rather than left to whoever edits this next.
  static const Color borderSubtleLight = Color(0xFFBEC0C3);
  static const Color borderSubtleDark = Color(0xFF414762);

  /// Input border while focused. Focus shifts *hue*, never stroke width —
  /// Material's default doubles the stroke, which reads as the field shouting.
  static const Color focusRingLight = Color(0xFF4141C0);
  static const Color focusRingDark = Color(0xFF8A8AE0);

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
  // On a chroma budget, and deliberately not equal: `danger` is the alarm and
  // carries the most saturation, `info` is only an indicator and carries the
  // least. None reaches full saturation — four hues all shouting is how a study
  // tool starts looking like a game.

  /// Answer remembered, session completed, saved.
  static const Color successLight = Color(0xFF1E7156);
  static const Color successDark = Color(0xFF68BB9C);

  /// Card due soon, streak at risk — informative, not alarming.
  static const Color warningLight = Color(0xFF856520);
  static const Color warningDark = Color(0xFFD2AC76);

  /// Answer forgotten, destructive action, reset.
  static const Color dangerLight = Color(0xFFB02233);
  static const Color dangerDark = Color(0xFFE88794);

  /// Status that genuinely carries information: streak, counters, "3 of 20".
  /// Not a decorative accent — plain metadata uses `textSecondary`.
  static const Color infoLight = Color(0xFF456480);
  static const Color infoDark = Color(0xFF8FAEC6);

  // --- Material roles ------------------------------------------------------
  //
  // Declared, not generated. See the class doc for what `fromSeed` produced
  // here before, and why none of it was visible until it would have been
  // expensive to discover.
  static const Color primaryContainerLight = Color(0xFFDCDCF2);
  static const Color primaryContainerDark = Color(0xFF2B2B6E);
  static const Color onPrimaryContainerLight = Color(0xFF1B1B5C);
  static const Color onPrimaryContainerDark = Color(0xFFD8D8F0);
  static const Color secondaryLight = Color(0xFF4E5468);
  static const Color secondaryDark = Color(0xFFB4B9CC);
  static const Color onSecondaryLight = Color(0xFFFFFFFF);
  static const Color onSecondaryDark = Color(0xFF1E2033);
  static const Color secondaryContainerLight = Color(0xFFE4E6EC);
  static const Color secondaryContainerDark = Color(0xFF333852);
  static const Color onSecondaryContainerLight = Color(0xFF2C3141);
  static const Color onSecondaryContainerDark = Color(0xFFD9DCE7);
  static const Color tertiaryLight = Color(0xFF45647F);
  static const Color tertiaryDark = Color(0xFFA2BAD0);
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
  static const Color surfaceContainerLowestLight = Color(0xFFFFFFFF);
  static const Color surfaceContainerLowestDark = Color(0xFF07061F);
  static const Color surfaceContainerLowLight = Color(0xFFFAFAFC);
  static const Color surfaceContainerLowDark = Color(0xFF12142B);
  static const Color surfaceContainerLight = Color(0xFFF1F2F6);
  static const Color surfaceContainerDark = Color(0xFF1F2237);
  static const Color surfaceContainerHighLight = Color(0xFFEAECF1);
  static const Color surfaceContainerHighDark = Color(0xFF292D42);
  static const Color surfaceContainerHighestLight = Color(0xFFE3E5EC);
  static const Color surfaceContainerHighestDark = Color(0xFF333852);
  static const Color surfaceDimLight = Color(0xFFDEE0E7);
  static const Color surfaceDimDark = Color(0xFF08061F);
  static const Color surfaceBrightLight = Color(0xFFFFFFFF);
  static const Color surfaceBrightDark = Color(0xFF383D55);
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
  static const Color shadowLight = Color(0xFF0B0C18);
  static const Color shadowDark = Color(0xFF04040B);
  static const Color scrimLight = Color(0xFF0B0C18);
  static const Color scrimDark = Color(0xFF04040B);
}
