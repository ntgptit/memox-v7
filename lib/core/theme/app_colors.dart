import 'package:flutter/material.dart';

/// Colour tokens — **Slate Indigo**, chosen in M3.5a from three candidates
/// rendered side by side under an identical composition.
///
/// Every name says what the colour *means*, never what it looks like. `danger`
/// survives a redesign that turns it amber; `red` becomes a lie the moment
/// someone changes it, and nobody renames a constant used in forty files.
///
/// **Why a neutral canvas.** This is an app opened every day, for a few minutes,
/// for months. Over that horizon what matters is not first-impression appeal but
/// not being tiring, so nothing saturated sits in peripheral vision: the canvas
/// is graphite at 6–16% saturation and the only accent is a single muted indigo.
/// The palette this replaced tinted every surface a saturated navy — striking in
/// a screenshot, wearing by the third session.
///
/// **Why every role is declared.** `ColorScheme.fromSeed` generates ~30 roles,
/// and an audit found it had produced a neutral-grey `surfaceContainer` ladder, a
/// **pink** `tertiary`, and an `error` red competing with `danger` — all in hue
/// families the app never uses. None had surfaced only because the MVP has no
/// Dialog, BottomSheet, NavigationBar, Menu or Chip yet. Leaving them generated
/// meant those screens would render as a different app.
///
/// Contrast for every pair is verified in `test/core/theme/app_theme_test.dart`.
abstract final class AppColors {
  /// Seed for `ColorScheme.fromSeed`. Every role it would generate is
  /// overridden below; the seed remains only because Material requires one.
  static const Color seed = primaryLight;

  // --- Surface ladder ------------------------------------------------------
  //
  // Four tiers. In dark they climb (0.008 -> 0.016 -> 0.031 -> 0.048 luminance)
  // so a card reads as a card and an inset tile as an inset, without a shadow.
  // In light the card is white and the others sit below it — the same ordering
  // of *prominence*, built the only way white allows.

  /// Page background.
  static const Color backgroundLight = Color(0xFFF7F7F8);
  static const Color backgroundDark = Color(0xFF13151B);

  /// Card and sheet.
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF20222A);

  /// Inset tile, chip, icon container.
  static const Color surfaceMutedLight = Color(0xFFEDEEF0);
  static const Color surfaceMutedDark = Color(0xFF2E313B);

  /// The most prominent surface: fill of a primary action in dark.
  static const Color surfaceElevatedLight = Color(0xFFFFFFFF);
  static const Color surfaceElevatedDark = Color(0xFF4C5161);

  // --- Text and lines ------------------------------------------------------
  //
  // Neither end is pure. `#EEEFF2` rather than white, `#191C24` rather than
  // black: a pure value buzzes against a tinted ground, and carrying a trace of
  // the surface hue makes text sit *in* the interface rather than on top of it.
  static const Color textPrimaryLight = Color(0xFF191C24);
  static const Color textPrimaryDark = Color(0xFFEEEFF2);
  static const Color textSecondaryLight = Color(0xFF555B6D);
  static const Color textSecondaryDark = Color(0xFFB0B4BF);

  /// Hairline between rows, around cards, and an input at rest.
  static const Color borderSubtleLight = Color(0xFFDADCE2);
  static const Color borderSubtleDark = Color(0xFF434856);

  /// Input border while focused. Focus shifts *hue*, never stroke width —
  /// Material's default doubles the stroke, which reads as the field shouting.
  static const Color focusRingLight = Color(0xFF3B3BC4);
  static const Color focusRingDark = Color(0xFF9E9ED1);

  // --- Brand and actions ---------------------------------------------------

  /// The single accent. Muted on purpose.
  static const Color primaryLight = Color(0xFF3D3DA4);
  static const Color primaryDark = Color(0xFF4444A7);
  static const Color onPrimaryLight = Color(0xFFFFFFFF);
  static const Color onPrimaryDark = Color(0xFFF3F4F6);

  /// Label of a secondary (outlined) action.
  ///
  /// A separate token from [primaryLight] because one colour cannot be both a
  /// fill and a label on a dark surface; in dark those pull opposite ways, and
  /// conflating them once shipped a label at 3.09:1.
  static const Color secondaryActionLight = Color(0xFF3F3F8D);
  static const Color secondaryActionDark = Color(0xFFB8B8D5);

  // --- Semantic ------------------------------------------------------------
  //
  // On a chroma budget, and deliberately not equal: `danger` is the alarm and
  // carries the most, `info` is only an indicator and carries the least. None
  // reaches full saturation — four hues all shouting is how a study tool starts
  // looking like a game.

  /// Answer remembered, session completed, saved.
  static const Color successLight = Color(0xFF227758);
  static const Color successDark = Color(0xFF72CAAA);

  /// Card due soon, streak at risk — informative, not alarming.
  static const Color warningLight = Color(0xFF8C6521);
  static const Color warningDark = Color(0xFFDCB674);

  /// Answer forgotten, destructive action, reset.
  static const Color dangerLight = Color(0xFFAB2B3C);
  static const Color dangerDark = Color(0xFFDD8894);

  /// Neutral emphasis: counters, hints, "3 of 20".
  static const Color infoLight = Color(0xFF38688A);
  static const Color infoDark = Color(0xFF92B2C9);

  // --- Material roles ------------------------------------------------------
  //
  // Declared, not generated. See the class doc for what `fromSeed` produced
  // here before, and why none of it was visible until it would have been
  // expensive to discover.
  static const Color primaryContainerLight = Color(0xFFDDDDEE);
  static const Color primaryContainerDark = Color(0xFF32325D);
  static const Color onPrimaryContainerLight = Color(0xFF1E1E52);
  static const Color onPrimaryContainerDark = Color(0xFFD8D8E8);
  static const Color secondaryLight = Color(0xFF535A6E);
  static const Color secondaryDark = Color(0xFFB9BECA);
  static const Color onSecondaryLight = Color(0xFFFFFFFF);
  static const Color onSecondaryDark = Color(0xFF1F2129);
  static const Color secondaryContainerLight = Color(0xFFE8E9ED);
  static const Color secondaryContainerDark = Color(0xFF3A3E4A);
  static const Color onSecondaryContainerLight = Color(0xFF2F3441);
  static const Color onSecondaryContainerDark = Color(0xFFDDDFE4);
  static const Color tertiaryLight = Color(0xFF4B6681);
  static const Color tertiaryDark = Color(0xFFABBDCE);
  static const Color onTertiaryLight = Color(0xFFFFFFFF);
  static const Color onTertiaryDark = Color(0xFF1C242C);
  static const Color tertiaryContainerLight = Color(0xFFE6EBEF);
  static const Color tertiaryContainerDark = Color(0xFF384757);
  static const Color onTertiaryContainerLight = Color(0xFF283848);
  static const Color onTertiaryContainerDark = Color(0xFFD9E0E8);
  static const Color onErrorLight = Color(0xFFFFFFFF);
  static const Color onErrorDark = Color(0xFF281518);
  static const Color errorContainerLight = Color(0xFFF7DEE2);
  static const Color errorContainerDark = Color(0xFF5D282F);
  static const Color onErrorContainerLight = Color(0xFF621822);
  static const Color onErrorContainerDark = Color(0xFFF1D0D4);
  static const Color surfaceContainerLowestLight = Color(0xFFFFFFFF);
  static const Color surfaceContainerLowestDark = Color(0xFF0F1015);
  static const Color surfaceContainerLowLight = Color(0xFFF9FAFA);
  static const Color surfaceContainerLowDark = Color(0xFF1A1C23);
  static const Color surfaceContainerLight = Color(0xFFF4F4F6);
  static const Color surfaceContainerDark = Color(0xFF23262F);
  static const Color surfaceContainerHighLight = Color(0xFFEEEFF1);
  static const Color surfaceContainerHighDark = Color(0xFF2F323D);
  static const Color surfaceContainerHighestLight = Color(0xFFE9EAED);
  static const Color surfaceContainerHighestDark = Color(0xFF3A3E4A);
  static const Color surfaceDimLight = Color(0xFFE0E2E6);
  static const Color surfaceDimDark = Color(0xFF111318);
  static const Color surfaceBrightLight = Color(0xFFFFFFFF);
  static const Color surfaceBrightDark = Color(0xFF434856);
  static const Color inverseSurfaceLight = Color(0xFF2E3038);
  static const Color inverseSurfaceDark = Color(0xFFE9EAEC);
  static const Color onInverseSurfaceLight = Color(0xFFF1F2F3);
  static const Color onInverseSurfaceDark = Color(0xFF292C32);
  static const Color inversePrimaryLight = Color(0xFFA5A5D5);
  static const Color inversePrimaryDark = Color(0xFF34348D);
  static const Color shadowLight = Color(0xFF0C0E12);
  static const Color shadowDark = Color(0xFF000000);
  static const Color scrimLight = Color(0xFF0C0E12);
  static const Color scrimDark = Color(0xFF000000);
}
