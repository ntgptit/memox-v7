import 'package:flutter/material.dart';

/// Colour tokens.
///
/// Every name says what the colour *means*, never what it looks like. `danger`
/// survives a redesign that turns it amber; `red` becomes a lie the moment
/// someone changes it, and nobody renames a constant used in forty files.
///
/// **Where these come from.** The dark palette is sampled pixel-by-pixel from a
/// reference the project owner chose as looking right — not approximated by
/// eye, and not a stock Material scheme. The light palette is *derived* from
/// it rather than picked separately: same hues, lightness ladder mirrored. That
/// is what keeps the two modes recognisably one product instead of two designs
/// that happen to ship together.
///
/// Every pair below is verified by `test/core/theme/app_theme_test.dart`, which
/// computes WCAG contrast. The reference is a starting point, not the authority.
///
/// The identity hue is a deep indigo-navy around 243°, with a cyan accent for
/// informational marks.
abstract final class AppColors {
  /// Source colour for both `ColorScheme.fromSeed` calls.
  ///
  /// Derived from the reference's own hue rather than borrowed from a palette
  /// library, so the seed and the surfaces belong to each other.
  static const Color seed = Color(0xFF5049DF);

  // --- Surface ladder -------------------------------------------------------
  //
  // Three levels, not two. The reference separates page, card and inset tile,
  // and that third step is what lets a chip or an icon container read as raised
  // without a shadow. Two levels forces every inset element to borrow the card
  // colour and vanish into it.
  //
  // Material would derive all of these from the seed, which tints every
  // neutral. That washed lavender cast is exactly what the previous palette was
  // criticised for, so these are declared rather than inherited.

  /// Page background — the deepest, most-used surface. Sampled: 59% of the
  /// reference screens are this exact colour.
  static const Color backgroundDark = Color(0xFF0A082D);

  /// Card and sheet, one step up from the page.
  static const Color surfaceDark = Color(0xFF201F3E);

  /// Inset tile, chip, icon container — one step above the card.
  static const Color surfaceMutedDark = Color(0xFF2E3756);

  /// Page background, light. Mirrors [backgroundDark]'s role: a hair off white,
  /// so a white card still reads as a card.
  static const Color backgroundLight = Color(0xFFF6F6FB);

  /// Card and sheet, light.
  static const Color surfaceLight = Color(0xFFFFFFFF);

  /// Inset tile, chip, icon container, light.
  static const Color surfaceMutedLight = Color(0xFFEAEAF6);

  /// Fill of a primary action.
  ///
  /// In dark this is the **fourth surface tier**, not a coloured object. The
  /// reference's ladder is page 0.004 → card 0.016 → tile 0.040 → action 0.125
  /// in luminance, each step roughly 2.5x the last, all in one neutral family.
  /// A button built that way reads as the top of the stack rather than as a
  /// splash of colour, which leaves every saturated hue free to mean something
  /// — and that matters here, because the review buttons will be colour-coded
  /// `forgotten` / `remembered`. A brand-coloured CTA sitting next to them
  /// would compete with the two colours that carry the actual decision.
  ///
  /// Light cannot use the same device: white is already the top of the ladder,
  /// so there is no tier above the card to promote a button into. There the
  /// brand colour does the job instead. The asymmetry is deliberate — the rule
  /// is "the action is the most prominent surface", and prominence is built
  /// differently at each end.
  static const Color actionFillDark = Color(0xFF58637F);
  static const Color actionFillLight = seed;

  /// Label of a secondary (outlined) action.
  ///
  /// A separate token from [actionFillLight] because one colour cannot do both
  /// jobs. Material 3 asks `primary` to be a *fill* and a *label on a dark
  /// surface* at once, and in dark mode those pull in opposite directions:
  /// fixing the fill so it stops glaring drove the label down to 3.09:1 on the
  /// page and 2.53:1 on a card — unreadable, not merely ugly.
  ///
  /// Dark therefore uses the neutral light end, which also keeps the rule the
  /// action fill follows: saturated colour is reserved for meaning. Light uses
  /// the brand colour, where it has the contrast to earn it.
  static const Color actionOutlineLabelDark = onSurfaceDark;
  static const Color actionOutlineLabelLight = seed;

  // --- Text -----------------------------------------------------------------
  //
  // Neither end of the scale is pure. `#EDECFE` rather than white, `#17162D`
  // rather than black: on a saturated ground a pure value buzzes, and carrying
  // a trace of the surface hue is what makes text sit *in* the interface rather
  // than on top of it.

  static const Color onSurfaceDark = Color(0xFFEDECFE);
  static const Color onSurfaceVariantDark = Color(0xFFABB0C4);

  static const Color onSurfaceLight = Color(0xFF17162D);
  static const Color onSurfaceVariantLight = Color(0xFF585B74);

  // --- Lines ----------------------------------------------------------------

  /// Hairline between rows and around cards.
  static const Color borderSubtleDark = Color(0xFF3B4268);
  static const Color borderSubtleLight = Color(0xFFD9D9E8);

  /// Border of an input while it has focus.
  ///
  /// Focus is signalled by a shift in *hue*, not by a jump in thickness.
  /// Material's default doubles the stroke, which reads as the field shouting;
  /// the reference keeps the stroke and moves the colour to a soft periwinkle.
  static const Color focusRingDark = Color(0xFFA8B1FF);
  static const Color focusRingLight = Color(0xFF5252E0);

  // --- Semantic accents -----------------------------------------------------

  /// Answer remembered, session completed, saved.
  static const Color successLight = Color(0xFF13795B);
  static const Color successDark = Color(0xFF3DDCA5);

  /// Card due soon, streak at risk — informative, not alarming.
  static const Color warningLight = Color(0xFF9A5B00);
  static const Color warningDark = Color(0xFFFFC94D);

  /// Answer forgotten, destructive action, reset.
  static const Color dangerLight = Color(0xFFC32148);
  static const Color dangerDark = Color(0xFFFF8FA3);

  /// Neutral emphasis: counters, hints, "3 of 20".
  ///
  /// Cyan, sampled from the reference's own iconography. It is the one accent
  /// that is not the brand hue, which is exactly why it reads as information
  /// rather than as an action.
  static const Color infoLight = Color(0xFF097FAA);
  static const Color infoDark = Color(0xFF50D0FF);
}
